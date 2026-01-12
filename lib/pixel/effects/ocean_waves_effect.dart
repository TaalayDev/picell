part of 'effects.dart';

/// Realistic ocean surface:
/// - Multi-layer waves + FBM micro ripples
/// - Proper normals from height derivatives
/// - Fresnel reflections + sun specular “glitter”
/// - Whitecaps/foam from crestness + noise breakup
/// - Faster ARGB math (no HSV/HSL per pixel)
class OceanWavesEffect extends Effect {
  OceanWavesEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.oceanWaves,
          parameters ??
              const {
                'waveHeight': 0.6,
                'waveFrequency': 0.5,
                'waveSpeed': 0.5,
                'windDirection': 0.3, // 0..1 => 0..2π
                'waterDepth': 0.7,
                'foamIntensity': 0.4,
                'surfaceReflection': 0.6,
                'waterClarity': 0.8,
                'deepWaterColor': 0xFF003366,
                'shallowWaterColor': 0xFF00AACC,
                'foamColor': 0xFFFFFFFF,
                'skyReflectionColor': 0xFF87CEEB,
                'waveComplexity': 0.6,
                'surfaceRoughness': 0.3,
                'sunAngle': 0.4, // 0..1 => azimuth
                'sunElevation': 0.25, // NEW: 0..1
                'randomSeed': 42, // NEW
                'time': 0.0, // treat as seconds or continuous time
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'waveHeight': 0.6,
        'waveFrequency': 0.5,
        'waveSpeed': 0.5,
        'windDirection': 0.3,
        'waterDepth': 0.7,
        'foamIntensity': 0.4,
        'surfaceReflection': 0.6,
        'waterClarity': 0.8,
        'deepWaterColor': 0xFF003366,
        'shallowWaterColor': 0xFF00AACC,
        'foamColor': 0xFFFFFFFF,
        'skyReflectionColor': 0xFF87CEEB,
        'waveComplexity': 0.6,
        'surfaceRoughness': 0.3,
        'sunAngle': 0.4,
        'sunElevation': 0.25,
        'randomSeed': 42,
        'time': 0.0,
      };

  @override
  Map<String, dynamic> getMetadata() {
    final m = <String, dynamic>{};

    // Keep yours; add these two:
    m['sunElevation'] = {
      'label': 'Sun Elevation',
      'description': 'Height of the sun above the horizon.',
      'type': 'slider',
      'min': 0.0,
      'max': 1.0,
      'divisions': 100,
    };
    m['randomSeed'] = {
      'label': 'Random Seed',
      'description': 'Changes micro-variation and foam breakup pattern.',
      'type': 'slider',
      'min': 1,
      'max': 999,
      'divisions': 998,
    };

    // You can merge with your existing map; omitted here for brevity.
    return m;
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final waveHeight = (parameters['waveHeight'] as double).clamp(0.0, 1.0);
    final waveFrequency = (parameters['waveFrequency'] as double).clamp(0.0, 1.0);
    final waveSpeed = (parameters['waveSpeed'] as double).clamp(0.0, 1.0);
    final windDirection = (parameters['windDirection'] as double).clamp(0.0, 1.0);
    final waterDepth = (parameters['waterDepth'] as double).clamp(0.0, 1.0);
    final foamIntensity = (parameters['foamIntensity'] as double).clamp(0.0, 1.0);
    final surfaceReflection = (parameters['surfaceReflection'] as double).clamp(0.0, 1.0);
    final waterClarity = (parameters['waterClarity'] as double).clamp(0.0, 1.0);
    final deepWater = parameters['deepWaterColor'] as int;
    final shallowWater = parameters['shallowWaterColor'] as int;
    final foamColor = parameters['foamColor'] as int;
    final skyColor = parameters['skyReflectionColor'] as int;
    final complexity = (parameters['waveComplexity'] as double).clamp(0.0, 1.0);
    final roughness = (parameters['surfaceRoughness'] as double).clamp(0.0, 1.0);
    final sunAngle = (parameters['sunAngle'] as double).clamp(0.0, 1.0);
    final sunElev = (parameters['sunElevation'] as double? ?? 0.25).clamp(0.0, 1.0);
    final seed = (parameters['randomSeed'] as int? ?? 42).clamp(1, 1000000);
    final time = (parameters['time'] as double);

    final out = Uint32List(width * height);

    // Treat time as continuous seconds; map waveSpeed to angular velocity
    final t = time * (0.4 + waveSpeed * 2.6);
    final wind = windDirection * 2.0 * pi;

    // Sun direction in 3D (azimuth + elevation)
    final az = sunAngle * 2.0 * pi;
    final elev = 0.10 + sunElev * 1.30; // 0.10..1.40 rad-ish
    final sunDx = cos(az) * cos(elev);
    final sunDy = sin(az) * cos(elev);
    final sunDz = sin(elev).clamp(0.05, 1.0);

    // Scale mapping
    final baseFreq = 0.6 + waveFrequency * 2.8; // spatial frequency
    final amp = 0.02 + waveHeight * 0.12; // height amplitude in normalized units
    final microAmp = amp * (0.15 + roughness * 0.50);

    for (int y = 0; y < height; y++) {
      final v = y / max(1, height - 1); // 0..1
      for (int x = 0; x < width; x++) {
        final u = x / max(1, width - 1);

        // --- Heightfield + derivatives ---
        final wave = _oceanHeightAndDerivatives(
          u,
          v,
          baseFreq,
          amp,
          microAmp,
          complexity,
          wind,
          t,
          seed,
        );

        final H = wave.h;
        final dHx = wave.dhx;
        final dHy = wave.dhy;

        // Normal from derivatives: N = normalize(-dHx, -dHy, 1)
        var nx = -dHx;
        var ny = -dHy;
        var nz = 1.0;
        final invLen = 1.0 / sqrt(nx * nx + ny * ny + nz * nz);
        nx *= invLen;
        ny *= invLen;
        nz *= invLen;

        // --- Depth gradient (simple: deeper toward bottom) + wave displacement ---
        final depthBase = (waterDepth + v * 0.35).clamp(0.0, 1.0);
        final depth = (depthBase + H * 0.25).clamp(0.0, 1.0);

        // Water color (no HSV): shallow->deep based on depth, modulated by clarity
        // clarity reduces “milky” look (more clarity => stronger saturation/contrast)
        final depthT = depth;
        var water = _lerpArgb(shallowWater, deepWater, depthT);
        // add a tiny “subsurface” lift in shallow water
        final subsurface = (1.0 - depthT) * (0.08 + waterClarity * 0.06);
        water = _shadeArgb(water, subsurface);

        // --- Fresnel + specular ---
        // View direction ~ camera facing the surface: V=(0,0,1)
        final ndv = nz.clamp(0.0, 1.0);

        // Schlick Fresnel: F = F0 + (1-F0)(1-ndv)^5
        final F0 = 0.02 + surfaceReflection * 0.06; // water ~2%, boosted by slider
        final oneMinus = 1.0 - ndv;
        final fresnel = (F0 + (1.0 - F0) * pow(oneMinus, 5.0)).clamp(0.0, 1.0);

        // Sun specular (Blinn-Phong)
        final ndl = (nx * sunDx + ny * sunDy + nz * sunDz).clamp(0.0, 1.0);
        // Half-vector H = normalize(L + V) with V=(0,0,1)
        var hx = sunDx;
        var hy = sunDy;
        var hz = sunDz + 1.0;
        final hInv = 1.0 / sqrt(hx * hx + hy * hy + hz * hz);
        hx *= hInv;
        hy *= hInv;
        hz *= hInv;

        final ndh = (nx * hx + ny * hy + nz * hz).clamp(0.0, 1.0);
        final gloss = 30.0 + (1.0 - roughness) * 140.0; // rough => wider, less intense
        final spec = pow(ndh, gloss) * (0.15 + surfaceReflection * 0.9) * ndl;

        // Reflection mix: skyColor * fresnel + sun glitter
        var reflected = _lerpArgb(water, skyColor, (fresnel * (0.25 + surfaceReflection * 0.75)).clamp(0.0, 1.0));
        if (spec > 0) {
          // add glitter as a bright lift (not pure white)
          final specAmt = (spec * 0.9).clamp(0.0, 0.9);
          reflected = _shadeArgb(reflected, specAmt);
        }

        // --- Foam / whitecaps ---
        // Crestness from gradient magnitude (steep areas) + a little curvature-ish term.
        final crest = wave.crest; // already 0..1-ish
        // Break up foam with noise so it clusters
        final foamNoise = _fbm2D(u * 7.0, v * 7.0, 3, 0.55, seed + 901) * 0.5 + 0.5;
        var foam = 0.0;
        if (foamIntensity > 0) {
          // threshold makes foam appear only on stronger crests
          final thr = 0.55 + (1.0 - foamIntensity) * 0.35; // 0.55..0.90
          foam = ((crest - thr) / max(0.0001, (1.0 - thr))).clamp(0.0, 1.0);
          foam *= (0.55 + foamNoise * 0.65);
          // slightly less foam in very deep water
          foam *= (1.0 - depth * 0.25);
        }

        // --- Final combine ---
        var finalC = _lerpArgb(water, reflected, (fresnel * 0.85 + spec * 0.35).clamp(0.0, 1.0));
        if (foam > 0) {
          finalC = _lerpArgb(finalC, foamColor, foam.clamp(0.0, 1.0));
        }

        out[y * width + x] = finalC;
      }
    }

    return out;
  }

  // --------------------------------------------
  // Heightfield + derivatives
  // --------------------------------------------

  _OceanSample _oceanHeightAndDerivatives(
    double u,
    double v,
    double baseFreq,
    double amp,
    double microAmp,
    double complexity,
    double windAngle,
    double t,
    int seed,
  ) {
    // 3 wave trains + micro FBM ripples
    // Direction set around windAngle with slight offsets.
    final dir1x = cos(windAngle);
    final dir1y = sin(windAngle);

    final dir2x = cos(windAngle + 0.55);
    final dir2y = sin(windAngle + 0.55);

    final dir3x = cos(windAngle - 0.38);
    final dir3y = sin(windAngle - 0.38);

    // Frequencies
    final f1 = baseFreq * 0.65;
    final f2 = baseFreq * 1.30;
    final f3 = baseFreq * 2.10;

    // Weights by complexity
    final w2 = (complexity).clamp(0.0, 1.0);
    final w3 = ((complexity - 0.35) / 0.65).clamp(0.0, 1.0);

    // Each wave contributes to height and derivatives
    final a1 = amp;
    final a2 = amp * 0.55 * w2;
    final a3 = amp * 0.28 * w3;

    final s1 = _sineWave(u, v, dir1x, dir1y, f1, a1, t * 0.9);
    final s2 = _sineWave(u, v, dir2x, dir2y, f2, a2, t * 1.2 + 3.0);
    final s3 = _sineWave(u, v, dir3x, dir3y, f3, a3, t * 1.7 + 7.0);

    var h = s1.h + s2.h + s3.h;
    var dhx = s1.dhx + s2.dhx + s3.dhx;
    var dhy = s1.dhy + s2.dhy + s3.dhy;

    // Micro ripples via FBM (adds detail without “grid sin” artifacts)
    final n = _fbm2D(u * 18.0 + t * 0.15, v * 18.0 + t * 0.10, 4, 0.55, seed + 1337);
    final nx = _fbm2D(u * 18.0 + 13.7 + t * 0.15, v * 18.0 + t * 0.10, 4, 0.55, seed + 1447);
    final ny = _fbm2D(u * 18.0 + t * 0.15, v * 18.0 + 19.2 + t * 0.10, 4, 0.55, seed + 1557);

    h += n * microAmp * 0.35;
    // approximate derivatives from correlated noises
    dhx += (nx - n) * microAmp * 1.2;
    dhy += (ny - n) * microAmp * 1.2;

    // Crestness: use gradient magnitude (steep areas = foamy)
    final grad = sqrt(dhx * dhx + dhy * dhy);
    final crest = (grad * (6.0 + baseFreq * 2.0)).clamp(0.0, 1.0);

    return _OceanSample(h: h, dhx: dhx, dhy: dhy, crest: crest);
  }

  _SineSample _sineWave(
    double u,
    double v,
    double dx,
    double dy,
    double freq,
    double amp,
    double t,
  ) {
    // phase along direction
    final p = (u * dx + v * dy) * (freq * 2.0 * pi) - t;
    final s = sin(p);
    final c = cos(p);

    final h = s * amp;

    // Derivatives: d/du sin(k*(u*dx+v*dy) - t) = cos(...) * k * dx
    final k = freq * 2.0 * pi;
    final dhx = c * amp * k * dx;
    final dhy = c * amp * k * dy;

    return _SineSample(h: h, dhx: dhx, dhy: dhy);
  }

  // --------------------------------------------
  // Fast ARGB helpers
  // --------------------------------------------

  int _lerpArgb(int a, int b, double t) {
    final tt = t.clamp(0.0, 1.0);
    final aA = (a >>> 24) & 0xFF;
    final aR = (a >>> 16) & 0xFF;
    final aG = (a >>> 8) & 0xFF;
    final aB = a & 0xFF;

    final bA = (b >>> 24) & 0xFF;
    final bR = (b >>> 16) & 0xFF;
    final bG = (b >>> 8) & 0xFF;
    final bB = b & 0xFF;

    final oA = (aA + (bA - aA) * tt).round();
    final oR = (aR + (bR - aR) * tt).round();
    final oG = (aG + (bG - aG) * tt).round();
    final oB = (aB + (bB - aB) * tt).round();
    return (oA << 24) | (oR << 16) | (oG << 8) | oB;
  }

  int _shadeArgb(int argb, double amount) {
    // amount > 0 brightens, < 0 darkens
    final a = (argb >>> 24) & 0xFF;
    var r = (argb >>> 16) & 0xFF;
    var g = (argb >>> 8) & 0xFF;
    var b = argb & 0xFF;

    if (amount >= 0) {
      r = (r + (255 - r) * amount).round().clamp(0, 255);
      g = (g + (255 - g) * amount).round().clamp(0, 255);
      b = (b + (255 - b) * amount).round().clamp(0, 255);
    } else {
      final k = (1.0 + amount).clamp(0.0, 1.0);
      r = (r * k).round().clamp(0, 255);
      g = (g * k).round().clamp(0, 255);
      b = (b * k).round().clamp(0, 255);
    }

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  // --------------------------------------------
  // Seeded noise (value noise + FBM)
  // --------------------------------------------

  double _noise2D(double x, double y, int seed) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    final a = _hash01(seed, ix, iy);
    final b = _hash01(seed, ix + 1, iy);
    final c = _hash01(seed, ix, iy + 1);
    final d = _hash01(seed, ix + 1, iy + 1);

    final u = fx * fx * (3 - 2 * fx);
    final v = fy * fy * (3 - 2 * fy);

    final i1 = a * (1 - u) + b * u;
    final i2 = c * (1 - u) + d * u;

    return ((i1 * (1 - v) + i2 * v) * 2.0) - 1.0; // -1..1
  }

  double _fbm2D(double x, double y, int octaves, double gain, int seed) {
    var sum = 0.0;
    var amp = 0.5;
    var freq = 1.0;
    var norm = 0.0;

    for (int i = 0; i < octaves; i++) {
      sum += _noise2D(x * freq, y * freq, seed + i * 131) * amp;
      norm += amp;
      freq *= 2.0;
      amp *= gain;
    }
    return norm == 0 ? 0.0 : (sum / norm);
  }

  double _hash01(int seed, int x, int y) {
    var h = seed;
    h ^= x * 0x27d4eb2d;
    h ^= y * 0x165667b1;
    h = (h ^ (h >> 15)) * 0x85ebca6b;
    h = (h ^ (h >> 13)) * 0xc2b2ae35;
    h ^= (h >> 16);
    return (h & 0xFFFFFF) / 0xFFFFFF;
  }
}

class _OceanSample {
  final double h;
  final double dhx;
  final double dhy;
  final double crest;
  const _OceanSample({required this.h, required this.dhx, required this.dhy, required this.crest});
}

class _SineSample {
  final double h;
  final double dhx;
  final double dhy;
  const _SineSample({required this.h, required this.dhx, required this.dhy});
}
