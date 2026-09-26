part of 'effects.dart';

/// Procedural mountain ranges with:
/// - Multi-layer depth parallax with dynamic timeline scrolling
/// - Fractal noise (FBM) + ridged noise for sharp craggy peaks
/// - Diurnal sun transit and dynamic directional height-field lighting
/// - Atmospheric haze, altitude snow caps, and wind-blown valley mist
/// - Strongly-typed UIField controls and custom color palettes
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
                'colorScheme': 0, // 0=blue, 1=sunset, 2=mono, 3=forest, 4=desert, 5=arctic
                'atmosphericHaze': 0.5, // (0-1)
                'skyGradient': true,
                'sunPosition': 0.7, // (0-1)
                'sunElevation': 0.35, // (0-1)
                'sunSize': 0.06, // (0-0.2)
                'sunStrength': 0.25, // (0-1)
                'mistIntensity': 0.3, // (0-1)
                'mistHeight': 0.28, // (0.05-0.6)
                'snowCaps': 0.2, // (0-1)
                'detailLevel': 0.6, // (0-1)
                'ridgeStrength': 0.55, // (0-1)
                'edgeSoftness': 0.7, // (0-1)
                'parallaxScroll': true,
                'time': 0.0, // (0-1)
                'preserveAlpha': false,
                'randomSeed': 42,
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
        'skyGradient': true,
        'sunPosition': 0.7,
        'sunElevation': 0.35,
        'sunSize': 0.06,
        'sunStrength': 0.25,
        'mistIntensity': 0.3,
        'mistHeight': 0.28,
        'snowCaps': 0.2,
        'detailLevel': 0.6,
        'ridgeStrength': 0.55,
        'edgeSoftness': 0.7,
        'parallaxScroll': true,
        'time': 0.0,
        'preserveAlpha': false,
        'randomSeed': 42,
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
          'description': 'Depth via atmospheric perspective on far layers.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'snowCaps': {
          'label': 'Snow Caps',
          'description': 'Amount of snow coverage on high peaks.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'mistIntensity': {
          'label': 'Mist Intensity',
          'description': 'Amount of low-lying windblown valley fog.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'skyGradient': {
          'label': 'Sky Gradient',
          'description': 'Renders atmospheric sky background behind mountains.',
          'type': 'bool',
        },
        'sunPosition': {
          'label': 'Sun Position',
          'description': 'Sun horizontal position across the sky.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'parallaxScroll': {
          'label': 'Parallax Scrolling',
          'description': 'Scroll layers with multi-plane depth parallax over time.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress for parallax scroll and mist drift.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict mountain range to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SliderField(
          key: 'layers',
          label: 'Mountain Layers',
          description: 'Number of depth layers.',
          min: 1,
          max: 5,
          divisions: 4,
          isInteger: true,
        ),
        const SelectField(
          key: 'style',
          label: 'Mountain Style',
          description: 'Peak and ridge morphology.',
          options: {
            0: 'Smooth Ridges',
            1: 'Jagged Peaks',
            2: 'Rolling Hills',
            3: 'Sharp Alpine',
            4: 'Volcanic',
          },
        ),
        const SliderField(
          key: 'heightVariation',
          label: 'Height Variation',
          description: 'Peak elevation disparity.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(
          key: 'baseHeight',
          label: 'Mountain Height',
          description: 'Overall ridge elevation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SelectField(
          key: 'colorScheme',
          label: 'Color Scheme',
          description: 'Atmospheric color palette.',
          options: {
            0: 'Blue Gradient',
            1: 'Sunset',
            2: 'Monochrome',
            3: 'Forest Green',
            4: 'Desert',
            5: 'Arctic',
          },
        ),
        const SliderField(
          key: 'atmosphericHaze',
          label: 'Atmospheric Haze',
          description: 'Far layer depth mist.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(
          key: 'snowCaps',
          label: 'Snow Caps',
          description: 'Alpine summit snowline.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(
          key: 'mistIntensity',
          label: 'Mist Intensity',
          description: 'Valley fog and clouds.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'skyGradient',
          label: 'Sky Gradient',
          description: 'Atmospheric sky background.',
        ),
        const SliderField(
          key: 'sunPosition',
          label: 'Sun Position',
          description: 'Sun horizontal transit.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'parallaxScroll',
          label: 'Parallax Scrolling',
          description: 'Multi-plane camera scroll.',
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Parallax and mist animation cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return pixels;

    final layers = ((parameters['layers'] as num?)?.toInt() ?? 3).clamp(1, 5);
    final style = (parameters['style'] as num?)?.toInt() ?? 0;
    final heightVariation = ((parameters['heightVariation'] as num?)?.toDouble() ?? 0.55).clamp(0.0, 1.0);
    final baseHeight = ((parameters['baseHeight'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final colorScheme = (parameters['colorScheme'] as num?)?.toInt() ?? 0;
    final atmosphericHaze = ((parameters['atmosphericHaze'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final skyGradient = parameters['skyGradient'] as bool? ?? true;
    final baseSunPosition = ((parameters['sunPosition'] as num?)?.toDouble() ?? 0.7).clamp(0.0, 1.0);
    final sunElevation = ((parameters['sunElevation'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final sunSize = ((parameters['sunSize'] as num?)?.toDouble() ?? 0.06).clamp(0.0, 0.2);
    final sunStrength = ((parameters['sunStrength'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 1.0);
    final mistIntensity = ((parameters['mistIntensity'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final mistHeight = ((parameters['mistHeight'] as num?)?.toDouble() ?? 0.28).clamp(0.05, 0.6);
    final randomSeed = ((parameters['randomSeed'] as num?)?.toInt() ?? 42).clamp(1, 1000000);
    final snowCaps = ((parameters['snowCaps'] as num?)?.toDouble() ?? 0.2).clamp(0.0, 1.0);
    final detailLevel = ((parameters['detailLevel'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final ridgeStrength = ((parameters['ridgeStrength'] as num?)?.toDouble() ?? 0.55).clamp(0.0, 1.0);
    final edgeSoftness = ((parameters['edgeSoftness'] as num?)?.toDouble() ?? 0.7).clamp(0.0, 1.0);
    final parallaxScroll = parameters['parallaxScroll'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final result = Uint32List(pixels.length);
    final cycleTime = time - time.floorToDouble();

    // Calculate dynamic sun transit
    final sunPosition = (baseSunPosition + cycleTime * 0.3) % 1.0;

    final colors = _getColorScheme(colorScheme);

    // 1) Sky background
    if (skyGradient) {
      _fillSkyGradient(result, width, height, colors.skyTop, colors.skyBottom);
    } else {
      result.setAll(0, pixels);
    }

    if (sunStrength > 0 && sunSize > 0) {
      _addSunDiscAndGlow(result, width, height, colors.sun, sunPosition, sunElevation, sunSize, sunStrength);
    }

    // 2) Height profiles with depth parallax scrolling
    final profiles = List<List<double>>.generate(
      layers,
      (layer) {
        // Foreground layers scroll faster than distant layers
        final depth = layers == 1 ? 0.0 : layer / (layers - 1);
        final scrollSpeed = parallaxScroll ? (1.0 - depth * 0.75) * cycleTime * width : 0.0;

        return _generateHeightProfile(
          width,
          layer,
          layers,
          style,
          heightVariation,
          baseHeight,
          detailLevel,
          ridgeStrength,
          randomSeed,
          scrollSpeed,
        );
      },
    );

    // 3) Render mountain layers from back to front
    for (int layer = layers - 1; layer >= 0; layer--) {
      final depth = layers == 1 ? 0.0 : layer / (layers - 1); // 0 front, 1 back

      final baseLayerColor = _lerpColorInt(colors.mountainNear, colors.mountainFar, depth.clamp(0.0, 1.0));
      final hazeLayerColor =
          _lerpColorInt(baseLayerColor, colors.atmosphericHaze, (depth * atmosphericHaze).clamp(0.0, 1.0));

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

    // 4) Windblown valley mist and fog
    if (mistIntensity > 0) {
      _addMistEffect(
        result,
        width,
        height,
        mistIntensity,
        mistHeight,
        colors.mist,
        randomSeed,
        cycleTime,
      );
    }

    // 5) If preserveAlpha is requested, mask against original silhouette
    if (preserveAlpha) {
      for (int i = 0; i < pixels.length; i++) {
        final origA = (pixels[i] >>> 24) & 0xFF;
        if (origA == 0) {
          result[i] = 0x00000000;
        } else if (origA < 255) {
          result[i] = (origA << 24) | (result[i] & 0x00FFFFFF);
        }
      }
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
    double scrollOffsetX,
  ) {
    final profile = List<double>.filled(width, 0.0);

    final depth = totalLayers == 1 ? 0.0 : layer / (totalLayers - 1);
    final layerHeight = baseHeight * (1.0 - depth * 0.35);

    final baseFreq = 0.0015 + detailLevel * 0.0035;
    final fineFreq = 0.006 + detailLevel * 0.018;
    final amp = 0.65 + heightVariation * 0.85;

    final layerSeed = seed + layer * 104729;

    for (int x = 0; x < width; x++) {
      final nx = (x + scrollOffsetX).toDouble();

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

      final macro = _fbm1D(nx * baseFreq * 0.35, 4, 0.55, layerSeed + 17);
      var height = layerHeight + (h + macro * 0.25) * heightVariation;
      height = _lerpDouble(height, layerHeight, depth * 0.18);

      profile[x] = height;
    }

    double minH = double.infinity;
    double maxH = double.negativeInfinity;
    for (final v in profile) {
      if (v < minH) minH = v;
      if (v > maxH) maxH = v;
    }

    final shift = minH < 0 ? -minH : 0.0;
    final shiftedMax = maxH + shift;
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
    final wave = math.sin(x * baseFreq * 1.9) * 0.35 + math.sin(x * baseFreq * 0.55 + 1.3) * 0.25;
    final n = _fbm1D(x * (baseFreq * 0.7), 3, 0.6, seed);
    final softRidged = _ridged1D(x * (fineFreq * 0.6), 3, 0.6, seed + 31) * ridge;
    return (wave + n * 0.45 + softRidged) * amp;
  }

  double _mountainAlpine(double x, double baseFreq, double fineFreq, double amp, double ridge, int seed) {
    final ridged = _ridged1D(x * fineFreq, 6, 0.5, seed) * (0.7 + ridge);
    final micro = _fbm1D(x * (fineFreq * 2.2), 2, 0.5, seed + 101) * 0.18;
    final n = _fbm1D(x * baseFreq, 4, 0.55, seed + 19) * 0.4;
    return (ridged + n + micro) * amp;
  }

  double _mountainVolcanic(double x, double baseFreq, double fineFreq, double amp, double ridge, int seed) {
    const coneSpacing = 0.055;
    final cone = math.cos(x * coneSpacing).abs();
    final coneShape = math.pow(cone, 2.2).toDouble() * 0.55;
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
    final snowAmount = (snowCaps * (1.0 - depth * 0.25)).clamp(0.0, 1.0);
    final edgeAlpha = (edgeSoftness * 255).round().clamp(0, 255);

    for (int x = 0; x < width; x++) {
      final mh = profile[x].clamp(0.0, 1.0);
      final pixelHeight = (mh * height).round().clamp(1, height);
      final startY = (height - pixelHeight).clamp(0, height - 1);

      final slope = _slopeAt(profile, x, width).abs();
      final slopePenalty = (slope * 3.0).clamp(0.0, 0.35);
      final snowLine = (1.0 - snowAmount + slopePenalty).clamp(0.0, 1.0);
      final snowNoise = (_hash01(seed, x, 19) - 0.5) * 0.08;

      if (edgeAlpha > 0 && startY > 0) {
        final idx = (startY - 1) * width + x;
        final under = pixels[idx];
        pixels[idx] = _alphaBlend(under, layerColor, (edgeAlpha * 0.5).round());
      }

      for (int y = startY; y < height; y++) {
        final idx = y * width + x;
        final t = pixelHeight <= 1 ? 1.0 : (y - startY) / (pixelHeight - 1);
        final altitude = 1.0 - t;

        final snowMask = (altitude + snowNoise) >= snowLine;

        int c = layerColor;
        if (snowMask) {
          final snow = _lerpColorInt(0xFFF2FAFF, 0xFFE7F3FF, (depth * 0.35).clamp(0.0, 1.0));
          c = snow;
        }

        final baseDarken = (t * 0.22 + depth * 0.08).clamp(0.0, 0.35);
        final lit = _applyLightingInt(c, lighting[x], baseDarken);

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
    final dx = (sunX - 0.5) * 2.0;
    final dy = (sunY - 0.5) * 2.0;

    final len = math.sqrt(dx * dx + dy * dy);
    final sdx = len == 0 ? 1.0 : dx / len;
    final sdy = len == 0 ? -0.2 : dy / len;

    for (int x = 0; x < width; x++) {
      final slope = _slopeAt(profile, x, width);

      var nx = -slope;
      var ny = 1.0;
      final nLen = math.sqrt(nx * nx + ny * ny);
      nx /= nLen;
      ny /= nLen;

      var dot = nx * sdx + ny * (-sdy);
      dot = dot.clamp(-1.0, 1.0);

      const ambient = 0.62;
      const diffuse = 0.55;
      final lit = (ambient + math.max(0.0, dot) * diffuse).clamp(0.35, 1.25);

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
    final minDim = math.min(width, height).toDouble();
    final cx = sunX * (width - 1);
    final cy = sunY * (height - 1);

    final rDisc = max(1.0, size * minDim);
    final rGlow = rDisc * 3.5;

    final minX = max(0, (cx - rGlow).floor());
    final maxX = min(width - 1, (cx + rGlow).ceil());
    final minY = max(0, (cy - rGlow).floor());
    final maxY = min(height - 1, (cy + rGlow).ceil());

    for (int y = minY; y <= maxY; y++) {
      final dy = y - cy;
      final row = y * width;
      for (int x = minX; x <= maxX; x++) {
        final dx = x - cx;
        final d = math.sqrt(dx * dx + dy * dy);

        if (d <= rDisc) {
          final t = (d / rDisc).clamp(0.0, 1.0);
          final a = ((1.0 - t * 0.15) * strength * 255).round().clamp(0, 255);
          final idx = row + x;
          pixels[idx] = _alphaBlend(pixels[idx], sunColor, a);
        } else if (d <= rGlow) {
          final t = ((d - rDisc) / (rGlow - rDisc)).clamp(0.0, 1.0);
          final falloff = math.pow(1.0 - t, 2.0).toDouble();
          final a = (falloff * strength * 160).round().clamp(0, 255);
          if (a > 0) {
            final idx = row + x;
            pixels[idx] = _alphaBlend(pixels[idx], sunColor, a);
          }
        }
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
    int seed,
    double cycleTime,
  ) {
    final startY = (height * (1.0 - bandHeight)).round().clamp(0, height - 1);
    final mistDriftX = cycleTime * 2.0;

    for (int y = startY; y < height; y++) {
      final row = y * width;
      final tY = (y - startY) / math.max(1, (height - startY - 1));
      final base = (1.0 - tY).clamp(0.0, 1.0);

      for (int x = 0; x < width; x++) {
        final n = _fbm2D((x * 0.01 + mistDriftX), y * 0.008, 4, 0.55, seed + 5003);
        final swirl = math.sin((x * 0.02 + mistDriftX * 3.0) + (y * 0.01)) * 0.04;
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

    final oR = (overlay >>> 16) & 0xFF;
    final oG = (overlay >>> 8) & 0xFF;
    final oB = overlay & 0xFF;

    final r = ((bR * inv) + (oR * a)) ~/ 255;
    final g = ((bG * inv) + (oG * a)) ~/ 255;
    final b = ((bB * inv) + (oB * a)) ~/ 255;

    return (bA << 24) | (r << 16) | (g << 8) | b;
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  // -----------------------------
  // Seeded value noise + FBM
  // -----------------------------

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

  double _ridged1D(double x, int octaves, double gain, int seed) {
    var freq = 1.0;
    var amp = 0.5;
    var sum = 0.0;
    var norm = 0.0;

    for (int i = 0; i < octaves; i++) {
      final n = _noise2D(x * freq, 0.0, seed + i * 199);
      final r = 1.0 - n.abs();
      final rr = r * r;
      sum += (rr * 2.0 - 1.0) * amp;
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
