part of 'effects.dart';

/// Improved procedural forest generator:
/// - Seeded value-noise + FBM (stable, realistic variation)
/// - Faster rendering using ARGB ints + small helper ops (no HSL per pixel)
/// - Better placement: stratified/blue-noise-ish + min spacing
/// - Better lighting: canopy shading + trunk shading + optional rim light
/// - Better atmosphere: per-layer haze, mist with low-frequency noise, sky noise
/// - Optional: sun disc/glow, god rays (cheap), and ground micro texture
///
/// This keeps your public API mostly intact but adds a few useful params.
class ForestEffect extends Effect {
  ForestEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.forest,
          parameters ??
              const {
                'layers': 4,
                'treeDensity': 0.5,
                'treeType': 2, // 0=pine, 1=deciduous, 2=mixed, 3=birch, 4=willow
                'sizeVariation': 0.4,
                'baseHeight': 0.45,
                'colorScheme': 0, // 0=summer,1=autumn,2=winter,3=night,4=misty_morning,5=sunset
                'atmosphericHaze': 0.5,
                'renderSky': true,
                'skyGradient': true,
                'skyNoise': 0.15,
                'sunPosition': 0.75, // 0..1
                'sunElevation': 0.25, // 0..1
                'sunSize': 0.05, // 0..0.2
                'sunStrength': 0.15, // 0..1
                'groundLevel': 0.82,
                'randomSeed': 42,
                'enableShadows': true,
                'shadowDirection': 0.3, // -1..1 (negative=left)
                'shadowSoftness': 0.55, // 0..1
                'enableUndergrowth': true,
                'undergrowthDensity': 0.6,
                'lightingAngle': 0.7, // 0=noon, 1=dawn/dusk
                'rimLight': 0.18, // 0..1 (nice at dusk)
                'enableMist': false,
                'mistHeight': 0.3,
                'mistIntensity': 0.35,
                'treeSpacing': 0.5, // 0..1
                'groundTexture': 0.25, // 0..1
                'godRays': 0.0, // 0..1
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'layers': 4,
        'treeDensity': 0.5,
        'treeType': 2,
        'sizeVariation': 0.4,
        'baseHeight': 0.45,
        'colorScheme': 0,
        'atmosphericHaze': 0.5,
        'renderSky': true,
        'skyGradient': true,
        'skyNoise': 0.15,
        'sunPosition': 0.75,
        'sunElevation': 0.25,
        'sunSize': 0.05,
        'sunStrength': 0.15,
        'groundLevel': 0.82,
        'randomSeed': 42,
        'enableShadows': true,
        'shadowDirection': 0.3,
        'shadowSoftness': 0.55,
        'enableUndergrowth': true,
        'undergrowthDensity': 0.6,
        'lightingAngle': 0.7,
        'rimLight': 0.18,
        'enableMist': false,
        'mistHeight': 0.3,
        'mistIntensity': 0.35,
        'treeSpacing': 0.5,
        'groundTexture': 0.25,
        'godRays': 0.0,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        // Keep your existing metadata keys; add the new ones.
        'layers': {
          'label': 'Forest Layers',
          'description': 'Number of depth layers for parallax effect.',
          'type': 'slider',
          'min': 1,
          'max': 6,
          'divisions': 5,
        },
        'treeDensity': {
          'label': 'Tree Density',
          'description': 'How densely packed the trees are.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'treeType': {
          'label': 'Tree Type',
          'description': 'Style of trees to generate.',
          'type': 'select',
          'options': {
            0: 'Pine/Conifer',
            1: 'Deciduous (Oak/Maple)',
            2: 'Mixed Forest',
            3: 'Birch',
            4: 'Willow',
          },
        },
        'sizeVariation': {
          'label': 'Size Variation',
          'description': 'Randomness in tree sizes.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'divisions': 80,
        },
        'baseHeight': {
          'label': 'Tree Height',
          'description': 'Average height of trees relative to canvas.',
          'type': 'slider',
          'min': 0.2,
          'max': 0.7,
          'divisions': 50,
        },
        'colorScheme': {
          'label': 'Season/Time',
          'description': 'Color palette and mood.',
          'type': 'select',
          'options': {
            0: 'Summer',
            1: 'Autumn',
            2: 'Winter',
            3: 'Night',
            4: 'Misty Morning',
            5: 'Sunset',
          },
        },
        'atmosphericHaze': {
          'label': 'Atmospheric Depth',
          'description': 'How much distant objects fade.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'renderSky': {
          'label': 'Render Sky',
          'description': 'Paints a sky background behind the forest.',
          'type': 'bool',
        },
        'skyGradient': {
          'label': 'Sky Gradient',
          'description': 'Enable gradient sky background.',
          'type': 'bool',
        },
        'skyNoise': {
          'label': 'Sky Noise',
          'description': 'Subtle sky texture (thin clouds/grain).',
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
        'groundLevel': {
          'label': 'Horizon Position',
          'description': 'Where the ground meets the sky.',
          'type': 'slider',
          'min': 0.5,
          'max': 0.95,
          'divisions': 45,
        },
        'enableShadows': {
          'label': 'Tree Shadows',
          'description': 'Enable shadow casting.',
          'type': 'bool',
        },
        'shadowDirection': {
          'label': 'Shadow Direction',
          'description': 'Direction of shadows (-1=left, 1=right).',
          'type': 'slider',
          'min': -1.0,
          'max': 1.0,
          'divisions': 200,
        },
        'shadowSoftness': {
          'label': 'Shadow Softness',
          'description': 'Softness of shadows (0=hard, 1=soft).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'enableUndergrowth': {
          'label': 'Undergrowth',
          'description': 'Add bushes and ground vegetation.',
          'type': 'bool',
        },
        'undergrowthDensity': {
          'label': 'Undergrowth Density',
          'description': 'Amount of ground vegetation.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'lightingAngle': {
          'label': 'Time of Day',
          'description': '0=noon, 1=dawn/dusk (warmer + longer shadows).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'rimLight': {
          'label': 'Rim Light',
          'description': 'Adds a subtle rim highlight facing the sun.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'enableMist': {
          'label': 'Ground Mist',
          'description': 'Add low-lying mist effect.',
          'type': 'bool',
        },
        'mistHeight': {
          'label': 'Mist Height',
          'description': 'How high the mist rises.',
          'type': 'slider',
          'min': 0.1,
          'max': 0.6,
          'divisions': 50,
        },
        'mistIntensity': {
          'label': 'Mist Intensity',
          'description': 'Opacity of mist.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'treeSpacing': {
          'label': 'Tree Spacing',
          'description': 'Minimum distance between trees.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'groundTexture': {
          'label': 'Ground Texture',
          'description': 'Adds noise texture to the ground.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'godRays': {
          'label': 'God Rays',
          'description': 'Cheap sun rays through canopy (works best with mist).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'randomSeed': {
          'label': 'Random Seed',
          'description': 'Change for different forest layouts.',
          'type': 'slider',
          'min': 1,
          'max': 999,
          'divisions': 998,
        },
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final layers = (parameters['layers'] as int).clamp(1, 6);
    final treeDensity = (parameters['treeDensity'] as double).clamp(0.1, 1.0);
    final treeType = parameters['treeType'] as int;
    final sizeVariation = (parameters['sizeVariation'] as double).clamp(0.0, 0.8);
    final baseHeight = (parameters['baseHeight'] as double).clamp(0.2, 0.7);
    final colorScheme = parameters['colorScheme'] as int;
    final atmosphericHaze = (parameters['atmosphericHaze'] as double).clamp(0.0, 1.0);
    final renderSky = parameters['renderSky'] as bool;
    final skyGradient = parameters['skyGradient'] as bool;
    final skyNoise = (parameters['skyNoise'] as double).clamp(0.0, 1.0);
    final sunPosition = (parameters['sunPosition'] as double).clamp(0.0, 1.0);
    final sunElevation = (parameters['sunElevation'] as double).clamp(0.0, 1.0);
    final sunSize = (parameters['sunSize'] as double).clamp(0.0, 0.2);
    final sunStrength = (parameters['sunStrength'] as double).clamp(0.0, 1.0);
    final groundLevelPx = ((parameters['groundLevel'] as double).clamp(0.5, 0.95) * height).round();
    final randomSeed = (parameters['randomSeed'] as int).clamp(1, 1000000);
    final enableShadows = parameters['enableShadows'] as bool;
    final shadowDirection = (parameters['shadowDirection'] as double).clamp(-1.0, 1.0);
    final shadowSoftness = (parameters['shadowSoftness'] as double).clamp(0.0, 1.0);
    final enableUndergrowth = parameters['enableUndergrowth'] as bool;
    final undergrowthDensity = (parameters['undergrowthDensity'] as double).clamp(0.1, 1.0);
    final lightingAngle = (parameters['lightingAngle'] as double).clamp(0.0, 1.0);
    final rimLight = (parameters['rimLight'] as double).clamp(0.0, 1.0);
    final enableMist = parameters['enableMist'] as bool;
    final mistHeight = (parameters['mistHeight'] as double).clamp(0.1, 0.6);
    final mistIntensity = (parameters['mistIntensity'] as double).clamp(0.0, 1.0);
    final treeSpacing = (parameters['treeSpacing'] as double).clamp(0.0, 1.0);
    final groundTexture = (parameters['groundTexture'] as double).clamp(0.0, 1.0);
    final godRays = (parameters['godRays'] as double).clamp(0.0, 1.0);

    final result = Uint32List(pixels.length);

    final pal = _getPalette(colorScheme, lightingAngle);

    // 1) Sky
    if (renderSky) {
      _fillSky(result, width, height, groundLevelPx, pal.skyTop, pal.skyBottom, skyGradient);
      if (sunStrength > 0 && sunSize > 0) {
        _addSun(result, width, height, pal.sun, sunPosition, sunElevation, sunSize, sunStrength);
      }
      if (skyNoise > 0) {
        _addSkyNoise(result, width, height, groundLevelPx, skyNoise, randomSeed);
      }
    } else {
      result.setAll(0, pixels);
    }

    // 2) Optional far silhouette hills for depth (cheap + looks good)
    if (layers >= 4) {
      _renderFarHills(result, width, height, groundLevelPx, pal.haze, pal.skyBottom, randomSeed);
    }

    // 3) Forest layers back to front
    for (int layer = layers - 1; layer >= 0; layer--) {
      final depth = layers == 1 ? 0.0 : layer / (layers - 1); // 0 front, 1 back

      // distant layers sit slightly higher
      final layerGroundOffset = (depth * height * 0.15).round();
      final layerGround = groundLevelPx - layerGroundOffset;

      final layerPal = _layerize(pal, depth, atmosphericHaze);

      _renderForestLayer(
        result,
        width,
        height,
        layer,
        layers,
        treeDensity,
        treeType,
        sizeVariation,
        baseHeight,
        layerGround,
        layerPal,
        depth,
        enableShadows,
        shadowDirection,
        shadowSoftness,
        treeSpacing,
        rimLight,
        sunPosition,
        randomSeed,
      );

      if (enableUndergrowth && layer <= 1) {
        _renderUndergrowth(result, width, height, layerGround, layerPal, undergrowthDensity, depth, randomSeed + 7777);
      }
    }

    // 4) Ground
    _renderGround(result, width, height, groundLevelPx, pal.ground, pal.groundDark, groundTexture, randomSeed);

    // 5) Mist + god rays
    if (enableMist && mistIntensity > 0) {
      _renderMist(result, width, height, groundLevelPx, mistHeight, mistIntensity, pal.mist, randomSeed);
      if (godRays > 0) {
        _renderGodRays(result, width, height, groundLevelPx, sunPosition, sunElevation, godRays, pal.sun, randomSeed);
      }
    }

    // 6) Vignette (subtle)
    _vignette(result, width, height, 0.14);

    return result;
  }

  // ----------------------------
  // Layer rendering
  // ----------------------------

  void _renderForestLayer(
    Uint32List px,
    int w,
    int h,
    int layer,
    int totalLayers,
    double density,
    int treeType,
    double sizeVar,
    double baseHeight,
    int groundY,
    _LayerPalette pal,
    double depth,
    bool shadows,
    double shadowDir,
    double shadowSoft,
    double spacing,
    double rimLight,
    double sunX,
    int seed,
  ) {
    // density: more trees in far layers, but smaller
    final scaled = density * (0.65 + (depth) * 0.55);
    final count = (w * scaled * 0.42).round().clamp(1, w);

    // Blue-noise-ish placement: stratified bins
    final bins = max(8, (count / 2).round());
    final binW = max(1, w ~/ bins);

    // min spacing in pixels (front layers need bigger separation)
    final minSpacing = (spacing * w * (0.05 + (1.0 - depth) * 0.07)).round();
    final positions = <int>[];

    for (int i = 0; i < count; i++) {
      final bin = i % bins;
      final baseX = bin * binW;
      // jitter within bin
      final jitter = (_hash01(seed, layer * 131 + i, 17) * binW).round();
      var x = (baseX + jitter).clamp(0, w - 1);

      // enforce spacing (few attempts)
      var attempts = 0;
      while (attempts < 6 && _tooClose(x, positions, minSpacing)) {
        x = (baseX + ((_hash01(seed + 19, layer * 131 + i, 37) * binW).round())).clamp(0, w - 1);
        attempts++;
      }
      if (_tooClose(x, positions, minSpacing)) continue;
      positions.add(x);

      // Type
      var type = treeType;
      if (treeType == 2) {
        // Mixed (avoid recursive 2)
        type = (_hash01(seed + 101, x, layer) * 4.999).floor();
        if (type == 2) type = 0;
      }

      // Size scaling: far = smaller
      final depthScale = 0.35 + (1.0 - depth) * 0.75;
      final r = _hash01(seed + 333, x, layer * 17);
      final randomScale = 1.0 - (sizeVar * r);

      final treeH = (h * baseHeight * depthScale * randomScale).round().clamp(6, h);
      final treeW = max(2, (treeH * (0.30 + _hash01(seed + 444, x, layer * 19) * 0.22)).round());

      // Small vertical jitter
      final yJ = ((_hash01(seed + 555, x, layer * 23) - 0.5) * (h * 0.03)).round();
      final y = (groundY + yJ).clamp(0, h - 1);

      // Shadow
      if (shadows && depth < 0.75) {
        _shadow(px, w, h, x, y, treeW, treeH, shadowDir, shadowSoft, pal.shadow);
      }

      // Draw
      switch (type) {
        case 0:
          _pine(px, w, h, x, y, treeW, treeH, pal, rimLight, sunX, seed + i * 97);
          break;
        case 1:
          _deciduous(px, w, h, x, y, treeW, treeH, pal, rimLight, sunX, seed + i * 97);
          break;
        case 3:
          _birch(px, w, h, x, y, treeW, treeH, pal, rimLight, sunX, seed + i * 97);
          break;
        case 4:
          _willow(px, w, h, x, y, treeW, treeH, pal, rimLight, sunX, seed + i * 97);
          break;
        default:
          _deciduous(px, w, h, x, y, treeW, treeH, pal, rimLight, sunX, seed + i * 97);
      }
    }
  }

  bool _tooClose(int x, List<int> xs, int minSpacing) {
    for (final v in xs) {
      if ((x - v).abs() < minSpacing) return true;
    }
    return false;
  }

  // ----------------------------
  // Tree drawing (fast ARGB)
  // ----------------------------

  void _pine(
      Uint32List px, int w, int h, int x, int y, int tw, int th, _LayerPalette pal, double rim, double sunX, int seed) {
    final trunkW = max(1, (tw * 0.14).round());
    final trunkH = (th * 0.24).round();

    // trunk
    for (int j = 0; j < trunkH; j++) {
      final py = y - j;
      if (py < 0 || py >= h) continue;
      final t = j / max(1, trunkH - 1);
      final shade = -0.10 * t;
      final c = _shade(pal.trunk, shade);

      for (int i = -trunkW ~/ 2; i <= trunkW ~/ 2; i++) {
        final pxX = x + i;
        if (pxX < 0 || pxX >= w) continue;
        // bark noise
        final n = (_hash01(seed, pxX, py) - 0.5) * 0.12;
        px[py * w + pxX] = _shade(c, n);
      }
    }

    // foliage sections
    final foliageH = th - trunkH;
    final sections = th > 30 ? 4 : 3;
    final secH = max(3, foliageH ~/ sections);

    for (int s = 0; s < sections; s++) {
      final bottom = y - trunkH - (s * secH * 0.72).round();
      final top = bottom - secH;
      final sectionW = (tw * (1.0 - s * 0.14)).round().clamp(2, w);

      for (int yy = bottom; yy >= top; yy--) {
        if (yy < 0 || yy >= h) continue;
        final t = (bottom - yy) / max(1, secH - 1);
        final rowW = max(2, (sectionW * (1.0 - t * 0.85)).round());
        final half = rowW ~/ 2;

        for (int i = -half; i <= half; i++) {
          final xx = x + i;
          if (xx < 0 || xx >= w) continue;

          // jagged edge mask
          final edge = i.abs() / max(1, half);
          if (edge > 0.75 && _hash01(seed + 31, xx, yy) < (edge - 0.75) * 1.35) continue;

          var c = pal.leaves;
          // center darkening
          c = _shade(c, -edge * 0.10);
          // micro variation
          c = _shade(c, (_hash01(seed + 7, xx, yy) - 0.5) * 0.10);

          // rim light
          if (rim > 0) {
            final facing = (sunX - 0.5) * 2.0;
            final side = i.sign.toDouble();
            final rimMask = max(0.0, (side * facing));
            final amt = rim * rimMask * 0.18 * (1.0 - t);
            if (amt > 0) c = _lerp(c, pal.leafHighlight, amt);
          }

          px[yy * w + xx] = c;
        }
      }
    }
  }

  void _deciduous(
      Uint32List px, int w, int h, int x, int y, int tw, int th, _LayerPalette pal, double rim, double sunX, int seed) {
    final trunkW = max(1, (tw * 0.18).round());
    final trunkH = (th * 0.36).round();

    // trunk taper
    for (int j = 0; j < trunkH; j++) {
      final py = y - j;
      if (py < 0 || py >= h) continue;
      final t = j / max(1, trunkH - 1);
      final curW = max(1, (trunkW * (1.0 - t * 0.35)).round());

      for (int i = -curW ~/ 2; i <= curW ~/ 2; i++) {
        final xx = x + i;
        if (xx < 0 || xx >= w) continue;
        var c = pal.trunk;
        c = _shade(c, (_hash01(seed, xx, py) - 0.5) * 0.10 - t * 0.06);
        px[py * w + xx] = c;
      }
    }

    // canopy blobs (3-4 clusters)
    final r = max(5, (tw * 0.60).round());
    final cy = y - trunkH - r;

    _canopy(px, w, h, x, cy, r, pal, rim, sunX, seed + 101);
    _canopy(px, w, h, x - r ~/ 2, cy + r ~/ 3, (r * 0.75).round(), pal, rim, sunX, seed + 202);
    _canopy(px, w, h, x + r ~/ 2, cy + r ~/ 3, (r * 0.75).round(), pal, rim, sunX, seed + 303);
    _canopy(px, w, h, x, cy - r ~/ 3, (r * 0.65).round(), pal, rim, sunX, seed + 404);
  }

  void _birch(
      Uint32List px, int w, int h, int x, int y, int tw, int th, _LayerPalette pal, double rim, double sunX, int seed) {
    final trunkW = max(1, (tw * 0.10).round());
    final trunkH = (th * 0.52).round();

    for (int j = 0; j < trunkH; j++) {
      final py = y - j;
      if (py < 0 || py >= h) continue;

      for (int i = -trunkW ~/ 2; i <= trunkW ~/ 2; i++) {
        final xx = x + i;
        if (xx < 0 || xx >= w) continue;

        // birch marks pattern
        final mark = _hash01(seed + 17, xx, py) < 0.14;
        var c = mark ? pal.birchMark : pal.birchBark;
        c = _shade(c, (_hash01(seed, xx, py) - 0.5) * 0.06);
        px[py * w + xx] = c;
      }
    }

    // lighter canopy
    final r = max(4, (tw * 0.50).round());
    final cy = y - trunkH - r;
    _canopy(px, w, h, x, cy, r, pal.copy(leaves: _lerp(pal.leaves, pal.leafHighlight, 0.25)), rim, sunX, seed + 88,
        sparse: true);
  }

  void _willow(
      Uint32List px, int w, int h, int x, int y, int tw, int th, _LayerPalette pal, double rim, double sunX, int seed) {
    final trunkW = max(1, (tw * 0.16).round());
    final trunkH = (th * 0.42).round();

    // trunk
    for (int j = 0; j < trunkH; j++) {
      final py = y - j;
      if (py < 0 || py >= h) continue;
      final t = j / max(1, trunkH - 1);
      final curW = max(1, (trunkW * (1.0 - t * 0.22)).round());

      for (int i = -curW ~/ 2; i <= curW ~/ 2; i++) {
        final xx = x + i;
        if (xx < 0 || xx >= w) continue;
        var c = pal.trunk;
        c = _shade(c, (_hash01(seed, xx, py) - 0.5) * 0.08 - t * 0.06);
        px[py * w + xx] = c;
      }
    }

    // dome canopy
    final canopyH = (th * 0.30).round();
    final canopyW = tw;
    final topY = y - trunkH - canopyH;

    for (int dy = 0; dy < canopyH; dy++) {
      final py = topY + dy;
      if (py < 0 || py >= h) continue;

      final t = dy / max(1, canopyH - 1);
      final rowW = max(2, (canopyW * (1.0 - t * 0.5)).round());
      final half = rowW ~/ 2;

      for (int i = -half; i <= half; i++) {
        final xx = x + i;
        if (xx < 0 || xx >= w) continue;
        if (_hash01(seed + 13, xx, py) < 0.25) continue;

        var c = pal.leaves;
        c = _shade(c, (_hash01(seed + 5, xx, py) - 0.5) * 0.10 - t * 0.08);

        if (rim > 0) {
          final facing = (sunX - 0.5) * 2.0;
          final side = i.sign.toDouble();
          final rimMask = max(0.0, (side * facing));
          final amt = rim * rimMask * 0.16 * (1.0 - t);
          if (amt > 0) c = _lerp(c, pal.leafHighlight, amt);
        }

        px[py * w + xx] = c;
      }
    }

    // hanging strands
    final strands = 6 + (_hash01(seed + 31, x, y) * 6).round();
    for (int s = 0; s < strands; s++) {
      final sx = x + ((_hash01(seed + 111, s, x) - 0.5) * canopyW).round();
      final startY = topY + canopyH ~/ 2;
      final len = (th * (0.30 + _hash01(seed + 222, s, y) * 0.25)).round();

      for (int j = 0; j < len; j++) {
        final py = startY + j;
        if (py < 0 || py >= h) continue;
        final sway = (sin(j * 0.24 + s) * 2.0).round();
        final xx = sx + sway;
        if (xx < 0 || xx >= w) continue;
        if (_hash01(seed + 9, xx, py) < 0.2) continue;

        var c = pal.leaves;
        c = _shade(c, (_hash01(seed + 3, xx, py) - 0.5) * 0.12 - (j / max(1, len - 1)) * 0.08);
        px[py * w + xx] = c;
      }
    }
  }

  void _canopy(
    Uint32List px,
    int w,
    int h,
    int cx,
    int cy,
    int radius,
    _LayerPalette pal,
    double rim,
    double sunX,
    int seed, {
    bool sparse = false,
  }) {
    final r2 = radius * radius;
    for (int dy = -radius; dy <= radius; dy++) {
      final py = cy + dy;
      if (py < 0 || py >= h) continue;

      for (int dx = -radius; dx <= radius; dx++) {
        final xx = cx + dx;
        if (xx < 0 || xx >= w) continue;

        final d2 = dx * dx + dy * dy;
        if (d2 > r2) continue;

        // edge thinning
        final edgeT = sqrt(d2 / r2);
        if (edgeT > 0.72) {
          final keep = (1.0 - edgeT) * 3.2;
          if (_hash01(seed, xx, py) > keep) continue;
        }

        if (sparse && _hash01(seed + 19, xx, py) < 0.35) continue;

        var c = pal.leaves;

        // darker bottom-inside
        final depthDark = (dy > 0 ? (dy / radius) : 0.0) * 0.18;
        c = _shade(c, (_hash01(seed + 7, xx, py) - 0.5) * 0.12 - depthDark);

        // rim
        if (rim > 0) {
          final facing = (sunX - 0.5) * 2.0;
          final side = dx.sign.toDouble();
          final rimMask = max(0.0, (side * facing));
          final amt = rim * rimMask * 0.16 * (1.0 - edgeT);
          if (amt > 0) c = _lerp(c, pal.leafHighlight, amt);
        }

        px[py * w + xx] = c;
      }
    }
  }

  void _shadow(Uint32List px, int w, int h, int x, int y, int tw, int th, double dir, double soft, int shadowColor) {
    // shadow length based on tree height
    final baseLen = th * 0.45;
    // softer shadows are also longer
    final len = (baseLen * (0.75 + soft * 0.6)).round();
    final off = (dir * len).round();

    final shadowW = (tw + len.abs()).clamp(4, w);
    final shadowH = max(2, (tw * (0.28 + soft * 0.22)).round());

    // max alpha lower for soft shadows
    final maxA = (90 * (1.0 - soft) + 45).round();

    for (int sy = 0; sy < shadowH; sy++) {
      final py = y + sy;
      if (py < 0 || py >= h) continue;

      final ny = sy / max(1, shadowH - 1);
      final rowA = (maxA * (1.0 - ny) * 0.9).round();

      for (int sx = -shadowW ~/ 2; sx <= shadowW ~/ 2; sx++) {
        final xx = x + sx + off;
        if (xx < 0 || xx >= w) continue;

        final nx = sx / max(1.0, shadowW / 2);
        if (nx * nx + ny * ny > 1.0) continue;

        // extra softness falloff
        final fall = 1.0 - (nx.abs() * 0.7 + ny * 0.55);
        final a = (rowA * fall).round().clamp(0, 255);
        if (a <= 0) continue;

        final idx = py * w + xx;
        px[idx] = _alphaBlend(px[idx], shadowColor, a);
      }
    }
  }

  // ----------------------------
  // Undergrowth + ground
  // ----------------------------

  void _renderUndergrowth(
      Uint32List px, int w, int h, int groundY, _LayerPalette pal, double density, double depth, int seed) {
    final count = (w * density * (0.20 + (1.0 - depth) * 0.20)).round().clamp(0, w);

    for (int i = 0; i < count; i++) {
      final x = (_hash01(seed, i, 11) * (w - 1)).round();
      final bh = (2 + _hash01(seed + 7, x, i) * (h * 0.05)).round();
      final bw = (bh + _hash01(seed + 13, x, i) * bh).round();

      for (int dy = 0; dy < bh; dy++) {
        final py = groundY - dy;
        if (py < 0 || py >= h) continue;

        final t = dy / max(1, bh - 1);
        final rowW = max(2, (bw * (1.0 - t)).round());
        final half = rowW ~/ 2;

        for (int dx = -half; dx <= half; dx++) {
          final xx = x + dx;
          if (xx < 0 || xx >= w) continue;
          if (_hash01(seed + 17, xx, py) < 0.28) continue;

          var c = pal.undergrowth;
          c = _shade(c, (_hash01(seed + 19, xx, py) - 0.5) * 0.14 - t * 0.10);
          px[py * w + xx] = c;
        }
      }
    }
  }

  void _renderGround(Uint32List px, int w, int h, int groundY, int ground, int groundDark, double texture, int seed) {
    for (int y = groundY; y < h; y++) {
      final t = (y - groundY) / max(1, (h - groundY - 1));
      var base = _lerp(ground, groundDark, (t * 0.85).clamp(0.0, 1.0));

      for (int x = 0; x < w; x++) {
        var c = base;
        if (texture > 0) {
          final n = _fbm2D(x * 0.035, y * 0.030, 3, 0.55, seed + 9001);
          final amt = (n * 0.5 + 0.5) * texture;
          c = _shade(c, (amt - texture * 0.5) * 0.18);
        }
        px[y * w + x] = c;
      }
    }
  }

  // ----------------------------
  // Sky + atmosphere
  // ----------------------------

  void _fillSky(Uint32List px, int w, int h, int groundY, int top, int bottom, bool gradient) {
    final endY = groundY.clamp(0, h);
    for (int y = 0; y < endY; y++) {
      final t = gradient ? (y / max(1, endY - 1)) : 1.0;
      final c = gradient ? _lerp(top, bottom, t) : bottom;
      final row = y * w;
      for (int x = 0; x < w; x++) {
        px[row + x] = c;
      }
    }
  }

  void _addSun(Uint32List px, int w, int h, int sunColor, double sunX, double sunY, double size, double strength) {
    final minDim = min(w, h).toDouble();
    final cx = sunX * (w - 1);
    final cy = sunY * (h - 1);
    final r = (size * minDim).clamp(0.0, minDim * 0.5);
    final glow = r * 3.2;
    if (r < 0.5) return;

    for (int y = 0; y < h; y++) {
      final dy = y - cy;
      final row = y * w;
      for (int x = 0; x < w; x++) {
        final dx = x - cx;
        final d = sqrt(dx * dx + dy * dy);
        if (d > glow) continue;

        double a;
        if (d <= r) {
          a = 0.85;
        } else {
          final t = (d - r) / max(0.001, (glow - r));
          a = (1.0 - t);
          a = a * a * 0.55;
        }
        a *= strength;
        final aa = (a * 255).round().clamp(0, 255);
        if (aa <= 0) continue;

        final idx = row + x;
        px[idx] = _alphaBlend(px[idx], sunColor, aa);
      }
    }
  }

  void _addSkyNoise(Uint32List px, int w, int h, int groundY, double amount, int seed) {
    final endY = groundY.clamp(0, h);
    final maxA = (amount * 70).round().clamp(0, 70);
    if (maxA <= 0) return;

    for (int y = 0; y < endY; y++) {
      final ny = y / max(1, endY - 1);
      final strength = (1.0 - ny) * 0.9;
      final row = y * w;

      for (int x = 0; x < w; x++) {
        final n = _fbm2D(x * 0.010, y * 0.007, 3, 0.55, seed + 7001);
        final band = sin(y * 0.03 + _fbm2D(x * 0.006, y * 0.002, 2, 0.6, seed + 7009) * 3.0) * 0.5 + 0.5;
        final cloud = max(0.0, band - 0.70) * 1.2;

        final mix = (n * 0.60 + cloud * 0.40);
        final a = (maxA * strength * (mix * 0.5 + 0.5)).round().clamp(0, 80);
        if (a <= 0) continue;

        px[row + x] = _alphaBlend(px[row + x], 0xFFFFFFFF, a);
      }
    }
  }

  void _renderFarHills(Uint32List px, int w, int h, int groundY, int haze, int skyBottom, int seed) {
    final hillColor = _lerp(haze, skyBottom, 0.45);
    final hillH = (h * 0.22).round();

    var prev = 0.0;
    for (int x = 0; x < w; x++) {
      // low-frequency profile
      final n = _fbm2D(x * 0.004, 0.0, 4, 0.6, seed + 500) * 0.6;
      prev = _lerpDouble(prev, n, 0.08);

      final peak = groundY - hillH + (prev * hillH * 0.35).round();
      for (int y = peak; y < groundY && y < h; y++) {
        if (y < 0) continue;
        final t = (y - peak) / max(1, (groundY - peak));
        final c = _lerp(hillColor, haze, (t * 0.25));
        px[y * w + x] = c;
      }
    }
  }

  void _renderMist(
      Uint32List px, int w, int h, int groundY, double heightRatio, double intensity, int mistColor, int seed) {
    final topY = (groundY - (h * heightRatio).round()).clamp(0, h - 1);
    for (int y = groundY.clamp(0, h - 1); y >= topY; y--) {
      final t = (groundY - y) / max(1, (groundY - topY));
      final baseA = (1.0 - t);

      final row = y * w;
      for (int x = 0; x < w; x++) {
        final n = _fbm2D(x * 0.012, y * 0.010, 4, 0.55, seed + 6001);
        final fog = (n * 0.55 + 0.45) * baseA;
        final a = (fog * intensity * 160).round().clamp(0, 200);
        if (a < 6) continue;
        px[row + x] = _alphaBlend(px[row + x], mistColor, a);
      }
    }
  }

  void _renderGodRays(
      Uint32List px, int w, int h, int groundY, double sunX, double sunY, double strength, int sunColor, int seed) {
    // Cheap ray mask in sky area, stronger near the sun.
    final endY = groundY.clamp(0, h);
    final cx = sunX * (w - 1);
    final cy = sunY * (h - 1);

    for (int y = 0; y < endY; y++) {
      final row = y * w;
      final dy = y - cy;

      for (int x = 0; x < w; x++) {
        final dx = x - cx;
        final ang = atan2(dy, dx);

        // rays: angular stripes + noise
        final stripes = (sin(ang * 12.0 + _fbm2D(x * 0.01, y * 0.01, 2, 0.6, seed + 8101) * 2.0) * 0.5 + 0.5);
        final mask = max(0.0, stripes - 0.55) * 2.0;

        final dist = sqrt(dx * dx + dy * dy);
        final fall = 1.0 / (1.0 + dist * 0.01);

        final a = (mask * fall * strength * 70).round().clamp(0, 90);
        if (a <= 0) continue;

        px[row + x] = _alphaBlend(px[row + x], sunColor, a);
      }
    }
  }

  void _vignette(Uint32List px, int w, int h, double amount) {
    if (amount <= 0) return;
    final cx = (w - 1) / 2.0;
    final cy = (h - 1) / 2.0;
    final maxD = sqrt(cx * cx + cy * cy);

    for (int y = 0; y < h; y++) {
      final dy = y - cy;
      final row = y * w;
      for (int x = 0; x < w; x++) {
        final dx = x - cx;
        final t = (sqrt(dx * dx + dy * dy) / maxD).clamp(0.0, 1.0);
        if (t <= 0.62) continue;
        final v = ((t - 0.62) / 0.38).clamp(0.0, 1.0);
        final dark = (v * v) * amount;
        px[row + x] = _shade(px[row + x], -dark);
      }
    }
  }

  // ----------------------------
  // Palettes
  // ----------------------------

  _ForestPalette _getPalette(int scheme, double lightingAngle) {
    // warm shift during dawn/dusk
    int warm(int c, double w) => _lerp(c, 0xFFFFD700, (w * 0.12).clamp(0.0, 0.12));
    final w = (lightingAngle > 0.5) ? (lightingAngle - 0.5) * 2.0 : 0.0;

    switch (scheme) {
      case 1: // Autumn
        return _ForestPalette(
          skyTop: warm(0xFFE8A87C, w),
          skyBottom: warm(0xFFF8E9D6, w),
          sun: 0xFFFFF1B8,
          ground: 0xFF6B4423,
          groundDark: 0xFF3D2914,
          leaves: warm(0xFFD35400, w),
          leafHighlight: warm(0xFFE67E22, w),
          trunk: 0xFF4A3728,
          undergrowth: warm(0xFFC0392B, w),
          haze: 0xFFD5C4A1,
          shadow: 0xFF2C1810,
          mist: 0xFFF5E6D3,
          birchBark: 0xFFF5F5F0,
          birchMark: 0xFF3D3D3D,
        );
      case 2: // Winter
        return const _ForestPalette(
          skyTop: 0xFFB8C5D1,
          skyBottom: 0xFFE8EEF2,
          sun: 0xFFFFFFFF,
          ground: 0xFFE8E8E8,
          groundDark: 0xFFCCCCCC,
          leaves: 0xFF2E5D4E,
          leafHighlight: 0xFF3D7A68,
          trunk: 0xFF4A4A4A,
          undergrowth: 0xFF5D7A6E,
          haze: 0xFFD4DDE4,
          shadow: 0xFF6B7B8A,
          mist: 0xFFFFFFFF,
          birchBark: 0xFFFFFFFF,
          birchMark: 0xFF555555,
        );
      case 3: // Night
        return const _ForestPalette(
          skyTop: 0xFF0A1628,
          skyBottom: 0xFF1A2F4A,
          sun: 0xFFE6F1FF,
          ground: 0xFF0D1B0D,
          groundDark: 0xFF050A05,
          leaves: 0xFF1A3D1A,
          leafHighlight: 0xFF2E5B2E,
          trunk: 0xFF1A1512,
          undergrowth: 0xFF153015,
          haze: 0xFF1A2840,
          shadow: 0xFF000000,
          mist: 0xFF2A3D5A,
          birchBark: 0xFF8A8A8A,
          birchMark: 0xFF2A2A2A,
        );
      case 4: // Misty Morning
        return const _ForestPalette(
          skyTop: 0xFFA0B8C8,
          skyBottom: 0xFFD8E4EC,
          sun: 0xFFFFF9D6,
          ground: 0xFF3D5A3D,
          groundDark: 0xFF2A3D2A,
          leaves: 0xFF4A7A5A,
          leafHighlight: 0xFF5D8D6D,
          trunk: 0xFF3D3530,
          undergrowth: 0xFF5A7A6A,
          haze: 0xFFCAD8E0,
          shadow: 0xFF4A5A5A,
          mist: 0xFFE8F0F4,
          birchBark: 0xFFE8E8E0,
          birchMark: 0xFF505050,
        );
      case 5: // Sunset
        return const _ForestPalette(
          skyTop: 0xFF1A0A2E,
          skyBottom: 0xFFE86A17,
          sun: 0xFFFFF1B8,
          ground: 0xFF2D1F15,
          groundDark: 0xFF1A1210,
          leaves: 0xFF1F4A2E,
          leafHighlight: 0xFF2E6B3D,
          trunk: 0xFF2A1F18,
          undergrowth: 0xFF3D5A3D,
          haze: 0xFFE8965A,
          shadow: 0xFF150A05,
          mist: 0xFFE8B88A,
          birchBark: 0xFFE8D8C8,
          birchMark: 0xFF4A3A2A,
        );
      case 0:
      default: // Summer
        return _ForestPalette(
          skyTop: warm(0xFF5DADE2, w),
          skyBottom: warm(0xFF85C1E9, w),
          sun: 0xFFFFF6C7,
          ground: 0xFF3D6B2D,
          groundDark: 0xFF2A4A1F,
          leaves: warm(0xFF27AE60, w),
          leafHighlight: warm(0xFF2ECC71, w),
          trunk: 0xFF5D4037,
          undergrowth: 0xFF229954,
          haze: 0xFFA8D8EA,
          shadow: 0xFF1A3D1A,
          mist: 0xFFE8F4F8,
          birchBark: 0xFFF5F5F0,
          birchMark: 0xFF3D3D3D,
        );
    }
  }

  _LayerPalette _layerize(_ForestPalette p, double depth, double hazeIntensity) {
    final haze = (depth * hazeIntensity).clamp(0.0, 1.0);

    // haze fade
    final leaves = _lerp(p.leaves, p.haze, haze);
    final leafHi = _lerp(p.leafHighlight, p.haze, haze);
    final trunk = _lerp(p.trunk, p.haze, haze);
    final under = _lerp(p.undergrowth, p.haze, haze);

    // distant layers darker & less contrast
    final darken = (depth * 0.18);

    return _LayerPalette(
      leaves: _shade(leaves, -darken),
      leafHighlight: _shade(leafHi, -darken * 0.6),
      trunk: _shade(trunk, -darken * 1.1),
      undergrowth: _shade(under, -darken * 0.8),
      haze: p.haze,
      shadow: p.shadow,
      mist: p.mist,
      birchBark: _lerp(p.birchBark, p.haze, haze * 0.35),
      birchMark: _lerp(p.birchMark, p.haze, haze * 0.25),
    );
  }

  // ----------------------------
  // Fast color + noise helpers
  // ----------------------------

  int _lerp(int a, int b, double t) {
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

  int _shade(int argb, double amount) {
    // amount in [-1..1], small recommended.
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

  int _alphaBlend(int base, int overlay, int a) {
    final alpha = a.clamp(0, 255);
    if (alpha == 0) return base;
    if (alpha == 255) return overlay;

    final inv = 255 - alpha;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final oR = (overlay >>> 16) & 0xFF;
    final oG = (overlay >>> 8) & 0xFF;
    final oB = overlay & 0xFF;

    final r = ((bR * inv) + (oR * alpha)) ~/ 255;
    final g = ((bG * inv) + (oG * alpha)) ~/ 255;
    final b = ((bB * inv) + (oB * alpha)) ~/ 255;

    return (bA << 24) | (r << 16) | (g << 8) | b;
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

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

class _ForestPalette {
  final int skyTop;
  final int skyBottom;
  final int sun;
  final int ground;
  final int groundDark;
  final int leaves;
  final int leafHighlight;
  final int trunk;
  final int undergrowth;
  final int haze;
  final int shadow;
  final int mist;
  final int birchBark;
  final int birchMark;

  const _ForestPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.ground,
    required this.groundDark,
    required this.leaves,
    required this.leafHighlight,
    required this.trunk,
    required this.undergrowth,
    required this.haze,
    required this.shadow,
    required this.mist,
    required this.birchBark,
    required this.birchMark,
  });
}

class _LayerPalette {
  final int leaves;
  final int leafHighlight;
  final int trunk;
  final int undergrowth;
  final int haze;
  final int shadow;
  final int mist;
  final int birchBark;
  final int birchMark;

  const _LayerPalette({
    required this.leaves,
    required this.leafHighlight,
    required this.trunk,
    required this.undergrowth,
    required this.haze,
    required this.shadow,
    required this.mist,
    required this.birchBark,
    required this.birchMark,
  });

  _LayerPalette copy({
    int? leaves,
    int? leafHighlight,
    int? trunk,
    int? undergrowth,
    int? birchBark,
    int? birchMark,
  }) {
    return _LayerPalette(
      leaves: leaves ?? this.leaves,
      leafHighlight: leafHighlight ?? this.leafHighlight,
      trunk: trunk ?? this.trunk,
      undergrowth: undergrowth ?? this.undergrowth,
      haze: haze,
      shadow: shadow,
      mist: mist,
      birchBark: birchBark ?? this.birchBark,
      birchMark: birchMark ?? this.birchMark,
    );
  }
}
