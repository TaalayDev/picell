part of 'effects.dart';

/// More realistic procedural mountain ranges with:
/// - Fractal noise (FBM) + ridged noise for sharp features
/// - Seeded noise (stable per randomSeed)
/// - Layer-specific palettes, haze, and fog
/// - Better lighting via a height-field normal approximation
/// - Optional sun disc + subtle sky noise
///
/// Notes:
/// - Colors are written as ARGB ints for speed inside hot loops.
/// - Handles layers==1 safely.
class MountainRangeEffect extends Effect {
  MountainRangeEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.mountainRange,
          parameters ??
              const {
                'layers': 3, // (1-5)
                'style': 0, // 0=smooth, 1=jagged, 2=rolling, 3=alpine, 4=volcanic
                'heightVariation': 0.55, // (0-1)
                'baseHeight': 0.0, // (0-1)
                'colorScheme': 0, // 0=blue,1=sunset,2=mono,3=forest,4=desert,5=arctic
                'atmosphericHaze': 0.5, // (0-1)
                'skyGradient': false,
                'sunPosition': 0.7, // (0-1)
                'sunElevation': 0.35, // (0-1)
                'sunSize': 0.06, // (0-0.2) relative to min(width,height)
                'sunStrength': 0.25, // (0-1)
                'mistIntensity': 0.3, // (0-1)
                'mistHeight': 0.28, // (0-1) bottom portion of image
                'randomSeed': 42,
                'snowCaps': 0.2, // (0-1)
                'detailLevel': 0.6, // (0-1)
                'ridgeStrength': 0.55, // (0-1) extra sharpness
                'edgeSoftness': 0.7, // (0-1) anti-alias on silhouette
                'skyNoise': 0.15, // (0-1)
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'layers': 3,
        'style': 0,
        'heightVariation': 0.55,
        'baseHeight': 0.0,
        'colorScheme': 0,
        'atmosphericHaze': 0.5,
        'skyGradient': false,
        'sunPosition': 0.7,
        'sunElevation': 0.35,
        'sunSize': 0.06,
        'sunStrength': 0.25,
        'mistIntensity': 0.3,
        'mistHeight': 0.28,
        'randomSeed': 42,
        'snowCaps': 0.2,
        'detailLevel': 0.6,
        'ridgeStrength': 0.55,
        'edgeSoftness': 0.7,
        'skyNoise': 0.15,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'layers': {
          'label': 'Mountain Layers',
          'description': 'Number of mountain layers for depth effect.',
          'type': 'slider',
          'min': 1,
          'max': 5,
          'divisions': 4,
        },
        'style': {
          'label': 'Mountain Style',
          'description': 'Style of mountain peaks and ridges.',
          'type': 'select',
          'options': {
            0: 'Smooth Ridges',
            1: 'Jagged Peaks',
            2: 'Rolling Hills',
            3: 'Sharp Alpine',
            4: 'Volcanic',
          },
        },
        'heightVariation': {
          'label': 'Height Variation',
          'description': 'How much mountain heights vary across the range.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'baseHeight': {
          'label': 'Mountain Height',
          'description': 'Overall height of the mountain range.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'detailLevel': {
          'label': 'Detail Level',
          'description': 'Higher = more small-scale ridges and micro features.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'ridgeStrength': {
          'label': 'Ridge Strength',
          'description': 'Sharpness of ridges (ridged noise contribution).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'colorScheme': {
          'label': 'Color Scheme',
          'description': 'Color palette for the mountain range.',
          'type': 'select',
          'options': {
            0: 'Blue Gradient',
            1: 'Sunset',
            2: 'Monochrome',
            3: 'Forest Green',
            4: 'Desert',
            5: 'Arctic',
          },
        },
        'atmosphericHaze': {
          'label': 'Atmospheric Haze',
          'description': 'Depth via atmospheric perspective (stronger on far layers).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'mistIntensity': {
          'label': 'Mist Intensity',
          'description': 'Amount of low-lying fog.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'mistHeight': {
          'label': 'Mist Height',
          'description': 'Vertical size of the mist band (bottom portion).',
          'type': 'slider',
          'min': 0.05,
          'max': 0.6,
          'divisions': 55,
        },
        'snowCaps': {
          'label': 'Snow Caps',
          'description': 'Amount of snow at high altitude.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'sunPosition': {
          'label': 'Sun Position',
          'description': 'Sun horizontal position (0=left, 1=right).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'sunElevation': {
          'label': 'Sun Elevation',
          'description': 'Sun vertical position (0=top, 1=bottom).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'sunSize': {
          'label': 'Sun Size',
          'description': 'Sun disc radius relative to canvas.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.2,
          'divisions': 100,
        },
        'sunStrength': {
          'label': 'Sun Glow',
          'description': 'Strength of sun glow in the sky.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'skyGradient': {
          'label': 'Sky Gradient',
          'description': 'Adds a gradient sky background.',
          'type': 'bool',
        },
        'skyNoise': {
          'label': 'Sky Noise',
          'description': 'Subtle sky texture (grain + thin clouds).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'edgeSoftness': {
          'label': 'Edge Softness',
          'description': 'Softens the mountain silhouette edge (anti-alias look).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'randomSeed': {
          'label': 'Random Seed',
          'description': 'Changes the mountain pattern and layout.',
          'type': 'slider',
          'min': 1,
          'max': 100,
          'divisions': 99,
        },
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final layers = (parameters['layers'] as int).clamp(1, 5);
    final style = parameters['style'] as int;
    final heightVariation = (parameters['heightVariation'] as double).clamp(0.0, 1.0);
    final baseHeight = (parameters['baseHeight'] as double).clamp(0.0, 1.0);
    final colorScheme = parameters['colorScheme'] as int;
    final atmosphericHaze = (parameters['atmosphericHaze'] as double).clamp(0.0, 1.0);
    final skyGradient = parameters['skyGradient'] as bool;
    final sunPosition = (parameters['sunPosition'] as double).clamp(0.0, 1.0);
    final sunElevation = (parameters['sunElevation'] as double).clamp(0.0, 1.0);
    final sunSize = (parameters['sunSize'] as double).clamp(0.0, 0.2);
    final sunStrength = (parameters['sunStrength'] as double).clamp(0.0, 1.0);
    final mistIntensity = (parameters['mistIntensity'] as double).clamp(0.0, 1.0);
    final mistHeight = (parameters['mistHeight'] as double).clamp(0.05, 0.6);
    final randomSeed = (parameters['randomSeed'] as int).clamp(1, 1000000);
    final snowCaps = (parameters['snowCaps'] as double).clamp(0.0, 1.0);
    final detailLevel = (parameters['detailLevel'] as double).clamp(0.0, 1.0);
    final ridgeStrength = (parameters['ridgeStrength'] as double).clamp(0.0, 1.0);
    final edgeSoftness = (parameters['edgeSoftness'] as double).clamp(0.0, 1.0);
    final skyNoise = (parameters['skyNoise'] as double).clamp(0.0, 1.0);

    final result = Uint32List(pixels.length);
    final rng = Random(randomSeed);

    final colors = _getColorScheme(colorScheme);

    // 1) Sky
    if (skyGradient) {
      _fillSkyGradient(result, width, height, colors.skyTop, colors.skyBottom);
    } else {
      // If no sky gradient, copy original pixels.
      result.setAll(0, pixels);
    }

    if (sunStrength > 0 && sunSize > 0) {
      _addSunDiscAndGlow(result, width, height, colors.sun, sunPosition, sunElevation, sunSize, sunStrength);
    }

    if (skyNoise > 0) {
      _addSkyNoise(result, width, height, skyNoise, randomSeed);
    }

    // 2) Height profiles (front layer index 0, back layer index layers-1)
    final profiles = List<List<double>>.generate(
      layers,
      (layer) => _generateHeightProfile(
        width,
        layer,
        layers,
        style,
        heightVariation,
        baseHeight,
        detailLevel,
        ridgeStrength,
        randomSeed,
      ),
    );

    // 3) Render from back to front
    for (int layer = layers - 1; layer >= 0; layer--) {
      final depth = layers == 1 ? 0.0 : layer / (layers - 1); // 0 front, 1 back

      final baseLayerColor = _lerpColorInt(colors.mountainNear, colors.mountainFar, depth.clamp(0.0, 1.0));
      final hazeLayerColor =
          _lerpColorInt(baseLayerColor, colors.atmosphericHaze, (depth * atmosphericHaze).clamp(0.0, 1.0));

      // Precompute lighting for this layer (per x) for speed.
      final lighting = Float32List(width);
      _computeLightingField(lighting, profiles[layer], width, sunPosition, sunElevation);

      _renderMountainLayer(
        result,
        width,
        height,
        profiles[layer],
        hazeLayerColor,
        colors.shadow,
        lighting,
        snowCaps,
        depth,
        edgeSoftness,
        randomSeed + layer * 1013,
      );
    }

    // 4) Mist/fog (applied after mountains)
    if (mistIntensity > 0) {
      _addMistEffect(
        result,
        width,
        height,
        mistIntensity,
        mistHeight,
        colors.mist,
        rng,
        randomSeed,
      );
    }

    return result;
  }

  // -----------------------------
  // Height profile generation
  // -----------------------------

  List<double> _generateHeightProfile(
    int width,
    int layer,
    int totalLayers,
    int style,
    double heightVariation,
    double baseHeight,
    double detailLevel,
    double ridgeStrength,
    int seed,
  ) {
    final profile = List<double>.filled(width, 0.0);

    // Far layers shorter + smoother.
    final depth = totalLayers == 1 ? 0.0 : layer / (totalLayers - 1);
    final layerHeight = baseHeight * (1.0 - depth * 0.35);

    // Noise params
    final baseFreq = 0.0015 + detailLevel * 0.0035;
    final fineFreq = 0.006 + detailLevel * 0.018;
    final amp = 0.65 + heightVariation * 0.85;

    // Layer seed offset
    final layerSeed = seed + layer * 104729; // big prime

    for (int x = 0; x < width; x++) {
      final nx = x.toDouble();

      double h;
      switch (style) {
        case 1:
          h = _mountainJagged(nx, baseFreq, fineFreq, amp, ridgeStrength, layerSeed);
          break;
        case 2:
          h = _mountainRolling(nx, baseFreq, fineFreq, amp, ridgeStrength * 0.35, layerSeed);
          break;
        case 3:
          h = _mountainAlpine(nx, baseFreq, fineFreq, amp, ridgeStrength, layerSeed);
          break;
        case 4:
          h = _mountainVolcanic(nx, baseFreq, fineFreq, amp, ridgeStrength * 0.8, layerSeed);
          break;
        case 0:
        default:
          h = _mountainSmooth(nx, baseFreq, fineFreq, amp, ridgeStrength * 0.5, layerSeed);
      }

      // Add subtle macro-shape so ranges don't look flat.
      final macro = _fbm1D(nx * baseFreq * 0.35, 4, 0.55, layerSeed + 17);

      // Combine
      var height = layerHeight + (h + macro * 0.25) * heightVariation;

      // Depth flattens detail a bit.
      height = _lerpDouble(height, layerHeight, depth * 0.18);

      profile[x] = height;
    }

    // Normalize gently: keep shape but ensure within [0,1] with minimal distortion.
    double minH = double.infinity;
    double maxH = double.negativeInfinity;
    for (final v in profile) {
      if (v < minH) minH = v;
      if (v > maxH) maxH = v;
    }

    // Shift up if negative.
    final shift = minH < 0 ? -minH : 0.0;
    final shiftedMax = maxH + shift;

    // If too tall, scale down slightly.
    final scale = shiftedMax > 1 ? 1.0 / shiftedMax : 1.0;

    for (int i = 0; i < width; i++) {
      profile[i] = (profile[i] + shift) * scale;
    }

    return profile;
  }

  double _mountainSmooth(double x, double baseFreq, double fineFreq, double amp, double ridge, int seed) {
    final n1 = _fbm1D(x * baseFreq, 5, 0.55, seed);
    final n2 = _fbm1D(x * fineFreq, 3, 0.5, seed + 11) * 0.35;
    final ridged = _ridged1D(x * (fineFreq * 0.9), 4, 0.52, seed + 23) * ridge;
    return (n1 * 0.9 + n2 + ridged) * amp;
  }

  double _mountainJagged(double x, double baseFreq, double fineFreq, double amp, double ridge, int seed) {
    final ridged = _ridged1D(x * fineFreq, 5, 0.5, seed) * (0.85 + ridge * 0.9);
    final n = _fbm1D(x * baseFreq, 4, 0.55, seed + 7) * 0.55;
    return (ridged + n) * amp;
  }

  double _mountainRolling(double x, double baseFreq, double fineFreq, double amp, double ridge, int seed) {
    final wave = sin(x * baseFreq * 1.9) * 0.35 + sin(x * baseFreq * 0.55 + 1.3) * 0.25;
    final n = _fbm1D(x * (baseFreq * 0.7), 3, 0.6, seed);
    final softRidged = _ridged1D(x * (fineFreq * 0.6), 3, 0.6, seed + 31) * ridge;
    return (wave + n * 0.45 + softRidged) * amp;
  }

  double _mountainAlpine(double x, double baseFreq, double fineFreq, double amp, double ridge, int seed) {
    // Alpine: sharper peaks + micro detail.
    final ridged = _ridged1D(x * fineFreq, 6, 0.5, seed) * (0.7 + ridge);
    final micro = _fbm1D(x * (fineFreq * 2.2), 2, 0.5, seed + 101) * 0.18;
    final n = _fbm1D(x * baseFreq, 4, 0.55, seed + 19) * 0.4;
    return (ridged + n + micro) * amp;
  }

  double _mountainVolcanic(double x, double baseFreq, double fineFreq, double amp, double ridge, int seed) {
    // Volcanic: periodic cones + noise breakup.
    final coneSpacing = 0.055; // smaller => more cones
    final cone = cos(x * coneSpacing).abs();
    final coneShape = pow(cone, 2.2).toDouble() * 0.55;
    final breakup = _fbm1D(x * baseFreq * 1.1, 4, 0.55, seed) * 0.35;
    final ridged = _ridged1D(x * fineFreq * 0.8, 4, 0.55, seed + 41) * ridge * 0.45;
    return (coneShape + breakup + ridged) * amp;
  }

  // -----------------------------
  // Rendering
  // -----------------------------

  void _renderMountainLayer(
    Uint32List pixels,
    int width,
    int height,
    List<double> profile,
    int layerColor,
    int shadowColor,
    Float32List lighting,
    double snowCaps,
    double depth,
    double edgeSoftness,
    int seed,
  ) {
    // Snow tuning: far layers slightly less contrasty.
    final snowAmount = (snowCaps * (1.0 - depth * 0.25)).clamp(0.0, 1.0);

    // Edge softness: 0 => hard edge, 1 => soft. We'll do a 1px blend band.
    final edgeAlpha = (edgeSoftness * 255).round().clamp(0, 255);

    for (int x = 0; x < width; x++) {
      final mh = profile[x].clamp(0.0, 1.0);
      final pixelHeight = (mh * height).round().clamp(1, height);
      final startY = (height - pixelHeight).clamp(0, height - 1);

      // Precompute snow threshold for this column using altitude + slope.
      final slope = _slopeAt(profile, x, width).abs();
      final slopePenalty = (slope * 3.0).clamp(0.0, 0.35);
      final snowLine = (1.0 - snowAmount + slopePenalty).clamp(0.0, 1.0);

      // A tiny per-column variation to break uniform snow.
      final snowNoise = (_hash01(seed, x, 19) - 0.5) * 0.08;

      // Silhouette AA: blend the top pixel with sky using alpha.
      if (edgeAlpha > 0 && startY > 0) {
        final idx = (startY - 1) * width + x;
        final under = pixels[idx];
        pixels[idx] = _alphaBlend(under, layerColor, (edgeAlpha * 0.5).round());
      }

      for (int y = startY; y < height; y++) {
        final idx = y * width + x;

        // Height in [0,1] within the mountain body.
        final t = pixelHeight <= 1 ? 1.0 : (y - startY) / (pixelHeight - 1);
        final altitude = 1.0 - t;

        // Snow mask: altitude above snowLine.
        final snowMask = (altitude + snowNoise) >= snowLine;

        int c = layerColor;

        if (snowMask) {
          // Snow color: slightly bluish; far layers more hazy.
          final snow = _lerpColorInt(0xFFF2FAFF, 0xFFE7F3FF, (depth * 0.35).clamp(0.0, 1.0));
          c = snow;
        }

        // Ambient occlusion-ish darkening near base for depth.
        final baseDarken = (t * 0.22 + depth * 0.08).clamp(0.0, 0.35);

        // Apply lighting field + base darken.
        final lit = _applyLightingInt(c, lighting[x], baseDarken);

        // Add subtle shadow color in creases (uses slope + noise).
        final crease = (_hash01(seed, x, y) * 0.6 + _hash01(seed + 7, x, y + 13) * 0.4);
        final creaseAmount = ((slope.abs() * 1.6) * (1.0 - altitude) * 0.6 + crease * 0.08).clamp(0.0, 0.35);
        final finalC = _lerpColorInt(lit, shadowColor, creaseAmount);

        pixels[idx] = finalC;
      }
    }
  }

  void _computeLightingField(
    Float32List out,
    List<double> profile,
    int width,
    double sunX,
    double sunY,
  ) {
    // Sun direction in screen space.
    final dx = (sunX - 0.5) * 2.0;
    final dy = (sunY - 0.5) * 2.0;

    // Normalize.
    final len = sqrt(dx * dx + dy * dy);
    final sdx = len == 0 ? 1.0 : dx / len;
    final sdy = len == 0 ? -0.2 : dy / len;

    for (int x = 0; x < width; x++) {
      final slope = _slopeAt(profile, x, width);

      // Height field normal approx: n = normalize((-slope, 1)).
      var nx = -slope;
      var ny = 1.0;
      final nLen = sqrt(nx * nx + ny * ny);
      nx /= nLen;
      ny /= nLen;

      // Light dot normal.
      var dot = nx * sdx + ny * (-sdy); // invert y since up is negative in screen space
      dot = dot.clamp(-1.0, 1.0);

      // Bias: keep a minimum ambient.
      final ambient = 0.62;
      final diffuse = 0.55;
      final lit = (ambient + max(0.0, dot) * diffuse).clamp(0.35, 1.25);

      out[x] = lit;
    }
  }

  double _slopeAt(List<double> profile, int x, int width) {
    final l = x > 0 ? profile[x - 1] : profile[x];
    final r = x < width - 1 ? profile[x + 1] : profile[x];
    return (r - l) * 2.2;
  }

  // -----------------------------
  // Sky + atmosphere
  // -----------------------------

  void _fillSkyGradient(Uint32List pixels, int width, int height, int topColor, int bottomColor) {
    for (int y = 0; y < height; y++) {
      final t = y / (height - 1);
      final c = _lerpColorInt(topColor, bottomColor, t);
      final row = y * width;
      for (int x = 0; x < width; x++) {
        pixels[row + x] = c;
      }
    }
  }

  void _addSunDiscAndGlow(
    Uint32List pixels,
    int width,
    int height,
    int sunColor,
    double sunX,
    double sunY,
    double size,
    double strength,
  ) {
    final minDim = min(width, height).toDouble();
    final cx = sunX * (width - 1);
    final cy = sunY * (height - 1);
    final radius = (size * minDim).clamp(0.0, minDim * 0.5);
    final glowR = radius * 3.0;

    if (radius <= 0.5 || strength <= 0) return;

    for (int y = 0; y < height; y++) {
      final dy = (y - cy);
      final row = y * width;
      for (int x = 0; x < width; x++) {
        final dx = (x - cx);
        final d = sqrt(dx * dx + dy * dy);

        if (d > glowR) continue;

        double a;
        if (d <= radius) {
          // Disc: mostly solid.
          a = 0.85;
        } else {
          // Glow falloff.
          final t = (d - radius) / (glowR - radius);
          a = (1.0 - t);
          a = a * a * 0.55;
        }

        a *= strength;
        if (a <= 0.001) continue;

        final idx = row + x;
        final alpha = (a * 255).round().clamp(0, 255);
        pixels[idx] = _alphaBlend(pixels[idx], sunColor, alpha);
      }
    }
  }

  void _addSkyNoise(Uint32List pixels, int width, int height, double amount, int seed) {
    // Adds subtle banded noise + thin cloud wisps.
    final a = (amount * 0.25).clamp(0.0, 0.25);
    if (a <= 0) return;

    for (int y = 0; y < height; y++) {
      final row = y * width;
      final ny = y / max(1, height - 1);

      // stronger noise higher in the sky.
      final strength = (1.0 - ny).clamp(0.0, 1.0) * a;

      for (int x = 0; x < width; x++) {
        // FBM-ish noise
        final n = _fbm2D(x * 0.006, y * 0.004, 3, 0.55, seed + 991);
        // thin cloud bands
        final band = sin(y * 0.03 + _fbm1D(x * 0.01, 2, 0.6, seed + 123) * 3.0) * 0.5 + 0.5;
        final cloud = max(0.0, band - 0.65) * 0.9;

        final mix = (n * 0.55 + cloud * 0.45);
        final alpha = (mix * strength * 255).round().clamp(0, 70);

        if (alpha <= 0) continue;
        final idx = row + x;
        // Slightly lighten sky with white-ish overlay
        pixels[idx] = _alphaBlend(pixels[idx], 0xFFFFFFFF, alpha);
      }
    }
  }

  void _addMistEffect(
    Uint32List pixels,
    int width,
    int height,
    double intensity,
    double bandHeight,
    int mistColor,
    Random rng,
    int seed,
  ) {
    final startY = (height * (1.0 - bandHeight)).round().clamp(0, height - 1);

    for (int y = startY; y < height; y++) {
      final row = y * width;
      final tY = (y - startY) / max(1, (height - startY - 1));
      // denser near the bottom, but not fully uniform
      final base = (1.0 - tY).clamp(0.0, 1.0);

      for (int x = 0; x < width; x++) {
        // soft rolling fog noise (low frequency)
        final n = _fbm2D(x * 0.01, y * 0.008, 4, 0.55, seed + 5003);
        final swirl = sin((x * 0.02) + (y * 0.01) + rng.nextDouble() * 0.15) * 0.04;
        final fog = (n * 0.85 + swirl) * base;

        final alpha = (fog * intensity * 170).round().clamp(0, 170);
        if (alpha < 8) continue;

        final idx = row + x;
        pixels[idx] = _alphaBlend(pixels[idx], mistColor, alpha);
      }
    }
  }

  // -----------------------------
  // Palette
  // -----------------------------

  MountainColors _getColorScheme(int scheme) {
    switch (scheme) {
      case 1: // Sunset
        return const MountainColors(
          skyTop: 0xFF1E3C72,
          skyBottom: 0xFFFFEAA7,
          sun: 0xFFFFF1A8,
          mountainNear: 0xFF2D3436,
          mountainFar: 0xFF4A3B3B,
          atmosphericHaze: 0xFFFFD28A,
          mist: 0xFFFFD1A6,
          shadow: 0xFF1C1F22,
        );
      case 2: // Monochrome
        return const MountainColors(
          skyTop: 0xFF2C3E50,
          skyBottom: 0xFFBDC3C7,
          sun: 0xFFF5F7FA,
          mountainNear: 0xFF34495E,
          mountainFar: 0xFF58666E,
          atmosphericHaze: 0xFFB0B6BA,
          mist: 0xFFF0F2F4,
          shadow: 0xFF1F2A33,
        );
      case 3: // Forest
        return const MountainColors(
          skyTop: 0xFF74B9FF,
          skyBottom: 0xFFE7F3FF,
          sun: 0xFFFFF6C7,
          mountainNear: 0xFF0B6B4F,
          mountainFar: 0xFF1B7A60,
          atmosphericHaze: 0xFF9FD1FF,
          mist: 0xFFD1F2EB,
          shadow: 0xFF063828,
        );
      case 4: // Desert
        return const MountainColors(
          skyTop: 0xFFE17055,
          skyBottom: 0xFFFFEAA7,
          sun: 0xFFFFF0C0,
          mountainNear: 0xFFB24A3E,
          mountainFar: 0xFFD07B5F,
          atmosphericHaze: 0xFFFFD08A,
          mist: 0xFFFFD7C6,
          shadow: 0xFF6E2A22,
        );
      case 5: // Arctic
        return const MountainColors(
          skyTop: 0xFF74B9FF,
          skyBottom: 0xFFFFFFFF,
          sun: 0xFFFFFFFF,
          mountainNear: 0xFFCFD8DC,
          mountainFar: 0xFFEEF3F6,
          atmosphericHaze: 0xFFFFFFFF,
          mist: 0xFFFFFFFF,
          shadow: 0xFF90A4AE,
        );
      case 0: // Blue gradient
      default:
        return const MountainColors(
          skyTop: 0xFF87CEEB,
          skyBottom: 0xFFE0F6FF,
          sun: 0xFFFFF6C7,
          mountainNear: 0xFF2F6FA5,
          mountainFar: 0xFF6A8FB3,
          atmosphericHaze: 0xFFB0C4DE,
          mist: 0xFFF0F8FF,
          shadow: 0xFF1D3E5A,
        );
    }
  }

  // -----------------------------
  // Fast color ops (ARGB ints)
  // -----------------------------

  int _applyLightingInt(int argb, double lighting, double baseDarken) {
    // lighting ~ [0.35..1.25]
    // baseDarken ~ [0..0.35]
    final a = (argb >>> 24) & 0xFF;
    var r = (argb >>> 16) & 0xFF;
    var g = (argb >>> 8) & 0xFF;
    var b = argb & 0xFF;

    final mul = (lighting * (1.0 - baseDarken)).clamp(0.0, 1.4);

    r = (r * mul).round().clamp(0, 255);
    g = (g * mul).round().clamp(0, 255);
    b = (b * mul).round().clamp(0, 255);

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  int _lerpColorInt(int a, int b, double t) {
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

  int _alphaBlend(int base, int overlay, int alpha255) {
    final a = alpha255.clamp(0, 255);
    if (a == 0) return base;
    if (a == 255) return overlay;

    final inv = 255 - a;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final oA = (overlay >>> 24) & 0xFF;
    final oR = (overlay >>> 16) & 0xFF;
    final oG = (overlay >>> 8) & 0xFF;
    final oB = overlay & 0xFF;

    final r = ((bR * inv) + (oR * a)) ~/ 255;
    final g = ((bG * inv) + (oG * a)) ~/ 255;
    final b = ((bB * inv) + (oB * a)) ~/ 255;

    // Keep base alpha (most buffers are opaque anyway)
    return (bA << 24) | (r << 16) | (g << 8) | b;
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  // -----------------------------
  // Seeded value noise + FBM
  // -----------------------------

  // Value noise in [-1,1]
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

    return ((i1 * (1 - v) + i2 * v) * 2.0) - 1.0;
  }

  double _fbm1D(double x, int octaves, double gain, int seed) {
    var freq = 1.0;
    var amp = 0.5;
    var sum = 0.0;
    var norm = 0.0;

    for (int i = 0; i < octaves; i++) {
      sum += _noise2D(x * freq, 0.0, seed + i * 101) * amp;
      norm += amp;
      freq *= 2.0;
      amp *= gain;
    }

    return norm == 0 ? 0.0 : (sum / norm);
  }

  double _fbm2D(double x, double y, int octaves, double gain, int seed) {
    var freq = 1.0;
    var amp = 0.5;
    var sum = 0.0;
    var norm = 0.0;

    for (int i = 0; i < octaves; i++) {
      sum += _noise2D(x * freq, y * freq, seed + i * 131) * amp;
      norm += amp;
      freq *= 2.0;
      amp *= gain;
    }

    return norm == 0 ? 0.0 : (sum / norm);
  }

  // Ridged noise in roughly [-1,1]
  double _ridged1D(double x, int octaves, double gain, int seed) {
    var freq = 1.0;
    var amp = 0.5;
    var sum = 0.0;
    var norm = 0.0;

    for (int i = 0; i < octaves; i++) {
      final n = _noise2D(x * freq, 0.0, seed + i * 199);
      // ridges: 1 - abs(noise)
      final r = 1.0 - n.abs();
      // sharpen
      final rr = r * r;
      // map to [-1,1]
      sum += (rr * 2.0 - 1.0) * amp;
      norm += amp;
      freq *= 2.0;
      amp *= gain;
    }

    return norm == 0 ? 0.0 : (sum / norm);
  }

  // Hash that returns [0,1]
  double _hash01(int seed, int x, int y) {
    var h = seed;
    h ^= x * 0x27d4eb2d;
    h ^= y * 0x165667b1;
    h = (h ^ (h >> 15)) * 0x85ebca6b;
    h = (h ^ (h >> 13)) * 0xc2b2ae35;
    h ^= (h >> 16);
    // keep 24 bits
    return (h & 0xFFFFFF) / 0xFFFFFF;
  }
}

/// Color scheme for mountain ranges (ARGB ints for speed)
class MountainColors {
  final int skyTop;
  final int skyBottom;
  final int sun;
  final int mountainNear;
  final int mountainFar;
  final int atmosphericHaze;
  final int mist;
  final int shadow;

  const MountainColors({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.mountainNear,
    required this.mountainFar,
    required this.atmosphericHaze,
    required this.mist,
    required this.shadow,
  });
}
