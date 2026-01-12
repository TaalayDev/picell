part of 'effects.dart';

/// Effect that procedurally generates a city skyline with buildings
class CityEffect extends Effect {
  CityEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.city,
          parameters ??
              const {
                'buildingDensity': 0.7, // How packed the buildings are (0-1)
                'heightVariation': 0.8, // Variation in building heights (0-1)
                'minHeight': 0.2, // Minimum building height (0-1)
                'maxHeight': 0.9, // Maximum building height (0-1)
                'buildingStyle': 0, // 0=modern, 1=classic, 2=futuristic, 3=mixed
                'windowDensity': 0.6, // How many windows buildings have (0-1)
                'colorScheme': 0, // 0=realistic, 1=neon, 2=monochrome, 3=sunset
                'perspective': 0.3, // 3D perspective effect (0-1)
                'weatherEffect': 0, // 0=clear, 1=fog, 2=rain, 3=night
                'randomSeed': 42, // Seed for procedural generation
                'backgroundMode': 0, // 0=transparent, 1=sky, 2=gradient
                'antennasAndDetails': 0.4, // Rooftop details density (0-1)
                'buildingWidth': 0.5, // Average building width (0-1)
                'litWindowRatio': 0.7, // Ratio of lit windows at night (0-1)
                'windowStyle': 0, // 0=standard, 1=floor-to-ceiling, 2=small, 3=mixed
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'buildingDensity': 0.7,
      'heightVariation': 0.8,
      'minHeight': 0.2,
      'maxHeight': 0.9,
      'buildingStyle': 0,
      'windowDensity': 0.6,
      'colorScheme': 0,
      'perspective': 0.3,
      'weatherEffect': 0,
      'randomSeed': 42,
      'backgroundMode': 0,
      'antennasAndDetails': 0.4,
      'buildingWidth': 0.5,
      'litWindowRatio': 0.7,
      'windowStyle': 0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'buildingDensity': {
        'label': 'Building Density',
        'description': 'How densely packed the buildings are in the city.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'heightVariation': {
        'label': 'Height Variation',
        'description': 'How much building heights vary across the skyline.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'minHeight': {
        'label': 'Minimum Height',
        'description': 'Minimum height of buildings relative to image height.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'maxHeight': {
        'label': 'Maximum Height',
        'description': 'Maximum height of buildings relative to image height.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'buildingStyle': {
        'label': 'Building Style',
        'description': 'Architectural style of the buildings.',
        'type': 'select',
        'options': {
          0: 'Modern',
          1: 'Classic',
          2: 'Futuristic',
          3: 'Mixed Styles',
        },
      },
      'windowDensity': {
        'label': 'Window Density',
        'description': 'How many windows appear on building facades.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorScheme': {
        'label': 'Color Scheme',
        'description': 'Color palette for the city.',
        'type': 'select',
        'options': {
          0: 'Realistic',
          1: 'Neon/Cyberpunk',
          2: 'Monochrome',
          3: 'Sunset',
        },
      },
      'perspective': {
        'label': 'Perspective Effect',
        'description': 'Adds 3D perspective depth to buildings.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'weatherEffect': {
        'label': 'Weather Effect',
        'description': 'Atmospheric effects on the city.',
        'type': 'select',
        'options': {
          0: 'Clear',
          1: 'Foggy',
          2: 'Rainy',
          3: 'Night',
        },
      },
      'randomSeed': {
        'label': 'Random Seed',
        'description': 'Changes the procedural city layout.',
        'type': 'slider',
        'min': 1,
        'max': 100,
        'divisions': 99,
      },
      'backgroundMode': {
        'label': 'Background',
        'description': 'Background behind the city.',
        'type': 'select',
        'options': {
          0: 'Transparent',
          1: 'Sky',
          2: 'Gradient',
        },
      },
      'antennasAndDetails': {
        'label': 'Rooftop Details',
        'description': 'Density of antennas and rooftop details.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'buildingWidth': {
        'label': 'Building Width',
        'description': 'Average width of buildings.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'litWindowRatio': {
        'label': 'Lit Window Ratio',
        'description': 'Percentage of windows that are lit up.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'windowStyle': {
        'label': 'Window Style',
        'description': 'Style of windows on buildings.',
        'type': 'select',
        'options': {
          0: 'Standard',
          1: 'Floor-to-Ceiling',
          2: 'Small/Classic',
          3: 'Mixed',
        },
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final buildingDensity = parameters['buildingDensity'] as double;
    final heightVariation = parameters['heightVariation'] as double;
    final minHeight = parameters['minHeight'] as double;
    final maxHeight = parameters['maxHeight'] as double;
    final buildingStyle = parameters['buildingStyle'] as int;
    final windowDensity = parameters['windowDensity'] as double;
    final colorScheme = parameters['colorScheme'] as int;
    final perspective = parameters['perspective'] as double;
    final weatherEffect = parameters['weatherEffect'] as int;
    final randomSeed = parameters['randomSeed'] as int;
    final backgroundMode = parameters['backgroundMode'] as int;
    final antennasAndDetails = parameters['antennasAndDetails'] as double;
    final buildingWidth = parameters['buildingWidth'] as double;
    final litWindowRatio = (parameters['litWindowRatio'] as double?) ?? 0.7;
    final windowStyle = (parameters['windowStyle'] as int?) ?? 0;

    final result = Uint32List(pixels.length);
    final random = Random(randomSeed);

    // Calculate scale factor based on canvas size for proper scaling
    final scaleFactor = _calculateScaleFactor(width, height);

    // Step 1: Create background if needed
    _createBackground(result, width, height, backgroundMode, colorScheme, weatherEffect);

    // Step 2: Generate building layout
    final buildings = _generateBuildings(
      width,
      height,
      buildingDensity,
      heightVariation,
      minHeight,
      maxHeight,
      buildingWidth,
      scaleFactor,
      random,
    );

    // Step 3: Sort buildings by depth for proper layering (back to front)
    buildings.sort((a, b) => a.depth.compareTo(b.depth));

    // Step 4: Draw buildings
    for (final building in buildings) {
      _drawBuilding(
        result,
        width,
        height,
        building,
        buildingStyle,
        windowDensity,
        colorScheme,
        perspective,
        litWindowRatio,
        windowStyle,
        weatherEffect,
        scaleFactor,
        random,
      );
    }

    // Step 5: Add rooftop details
    _addRooftopDetails(result, width, height, buildings, antennasAndDetails, colorScheme, scaleFactor, random);

    // Step 6: Apply weather effects
    _applyWeatherEffect(result, width, height, weatherEffect, colorScheme, random);

    return result;
  }

  /// Calculate scale factor based on canvas dimensions
  double _calculateScaleFactor(int width, int height) {
    // Base reference is 64x64, scale proportionally
    final avgDimension = (width + height) / 2;
    return (avgDimension / 64).clamp(0.5, 4.0);
  }

  /// Create background based on background mode
  void _createBackground(
      Uint32List pixels, int width, int height, int backgroundMode, int colorScheme, int weatherEffect) {
    if (backgroundMode == 0) return; // Transparent

    final isNight = weatherEffect == 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        Color bgColor;

        switch (backgroundMode) {
          case 1: // Sky
            final skyProgress = y / height;
            bgColor = _getSkyColor(skyProgress, colorScheme, isNight);
            break;
          case 2: // Gradient
            final gradientProgress = y / height;
            bgColor = _getGradientColor(gradientProgress, colorScheme, isNight);
            break;
          default:
            continue;
        }

        pixels[index] = bgColor.value;
      }
    }
  }

  /// Get sky color based on height and color scheme
  Color _getSkyColor(double progress, int colorScheme, bool isNight) {
    if (isNight) {
      return Color.lerp(
        const Color(0xFF0a0a1a), // Very dark blue
        const Color(0xFF1a1a2e), // Dark blue
        1.0 - progress,
      )!;
    }

    switch (colorScheme) {
      case 0: // Realistic
        return Color.lerp(
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFFE0F6FF), // Light blue
          1.0 - progress,
        )!;
      case 1: // Neon
        return Color.lerp(
          const Color(0xFF000011), // Dark blue
          const Color(0xFF330055), // Purple
          1.0 - progress,
        )!;
      case 2: // Monochrome
        final gray = (200 - progress * 50).round();
        return Color.fromARGB(255, gray, gray, gray);
      case 3: // Sunset
        // More realistic sunset gradient with multiple color stops
        if (progress < 0.3) {
          return Color.lerp(
            const Color(0xFF1a0a2e), // Deep purple
            const Color(0xFFFF4500), // Orange-red
            progress / 0.3,
          )!;
        } else if (progress < 0.6) {
          return Color.lerp(
            const Color(0xFFFF4500), // Orange-red
            const Color(0xFFFF8C00), // Dark orange
            (progress - 0.3) / 0.3,
          )!;
        } else {
          return Color.lerp(
            const Color(0xFFFF8C00), // Dark orange
            const Color(0xFFFFD700), // Gold
            (progress - 0.6) / 0.4,
          )!;
        }
      default:
        return const Color(0xFF87CEEB);
    }
  }

  /// Get gradient background color
  Color _getGradientColor(double progress, int colorScheme, bool isNight) {
    if (isNight) {
      return Color.lerp(const Color(0xFF000008), const Color(0xFF101020), 1.0 - progress)!;
    }

    switch (colorScheme) {
      case 0: // Realistic
        return Color.lerp(Colors.grey.shade300, Colors.grey.shade100, 1.0 - progress)!;
      case 1: // Neon
        return Color.lerp(const Color(0xFF001122), const Color(0xFF004488), 1.0 - progress)!;
      case 2: // Monochrome
        final value = (150 + progress * 100).round();
        return Color.fromARGB(255, value, value, value);
      case 3: // Sunset
        return Color.lerp(const Color(0xFFFF8C42), const Color(0xFFFFF3A0), 1.0 - progress)!;
      default:
        return Colors.grey.shade200;
    }
  }

  /// Generate building layout with improved distribution
  List<_Building> _generateBuildings(
    int width,
    int height,
    double density,
    double heightVariation,
    double minHeight,
    double maxHeight,
    double avgWidth,
    double scaleFactor,
    Random random,
  ) {
    final buildings = <_Building>[];

    // Calculate minimum building width based on scale (ensures windows fit)
    final minBuildingWidth = max(4, (6 * scaleFactor).round());
    final maxBuildingWidth = max(minBuildingWidth + 4, (width * 0.25).round());

    // Calculate number of buildings based on density and width
    final avgBuildingWidth = minBuildingWidth + (maxBuildingWidth - minBuildingWidth) * avgWidth;
    final estimatedBuildings = (width / avgBuildingWidth * density).round().clamp(2, width ~/ minBuildingWidth);

    var currentX = 0;
    final gapRange = max(1, (3 * scaleFactor * (1 - density)).round());

    for (int i = 0; i < estimatedBuildings && currentX < width - minBuildingWidth; i++) {
      // Calculate building width with variation
      final widthVariation = 0.6 + random.nextDouble() * 0.8;
      final targetWidth = avgBuildingWidth * widthVariation;
      final buildingWidthValue =
          targetWidth.round().clamp(minBuildingWidth, min(maxBuildingWidth, width - currentX)).toInt();

      if (currentX + buildingWidthValue > width) break;

      // Calculate building height with bell-curve like distribution for more natural skyline
      final heightRange = maxHeight - minHeight;
      final baseHeight = minHeight + random.nextDouble() * heightRange;

      // Add some clustering - taller buildings tend to be in the middle
      final centerBias = 1.0 - (2.0 * (currentX + buildingWidthValue / 2) / width - 1.0).abs();
      final heightWithBias = baseHeight + centerBias * heightRange * 0.2 * heightVariation;

      final buildingHeight = (heightWithBias.clamp(minHeight, maxHeight) * height).round().clamp(
            (minBuildingWidth * 2),
            height - 2,
          );

      // Assign depth for layering (slight variation for visual interest)
      final depth = i % 3; // 0, 1, 2 for front, mid, back

      final building = _Building(
        x: currentX,
        y: height - buildingHeight,
        width: buildingWidthValue,
        height: buildingHeight,
        style: random.nextInt(4),
        depth: depth,
        floors: _calculateFloors(buildingHeight, scaleFactor),
      );

      buildings.add(building);

      // Variable gap between buildings
      final gap = gapRange > 0 ? random.nextInt(gapRange) : 0;
      currentX += buildingWidthValue + gap;
    }

    return buildings;
  }

  /// Calculate number of floors based on building height
  int _calculateFloors(int buildingHeight, double scaleFactor) {
    final floorHeight = max(3, (4 * scaleFactor).round());
    return max(1, buildingHeight ~/ floorHeight);
  }

  /// Draw a single building with improved window rendering
  void _drawBuilding(
    Uint32List pixels,
    int width,
    int height,
    _Building building,
    int buildingStyle,
    double windowDensity,
    int colorScheme,
    double perspective,
    double litWindowRatio,
    int windowStyle,
    int weatherEffect,
    double scaleFactor,
    Random random,
  ) {
    // Create a seeded random for this specific building for consistency
    final buildingRandom = Random(building.x * 1000 + building.y);

    // Get building colors
    final colors = _getBuildingColors(colorScheme, buildingRandom, weatherEffect == 3);

    // Apply depth-based color adjustment
    final depthDarken = building.depth * 0.1;
    final adjustedMainColor = Color.lerp(colors.main, Colors.black, depthDarken)!;

    // Draw main building structure
    _drawBuildingStructure(pixels, width, height, building, adjustedMainColor, perspective);

    // Draw windows with proper grid alignment
    if (windowDensity > 0.05) {
      _drawWindowsImproved(
        pixels,
        width,
        height,
        building,
        windowDensity,
        colors,
        litWindowRatio,
        windowStyle,
        weatherEffect,
        scaleFactor,
        buildingRandom,
      );
    }

    // Draw architectural details based on style
    final effectiveStyle = buildingStyle == 3 ? building.style : buildingStyle;
    _drawArchitecturalDetails(pixels, width, height, building, effectiveStyle, colors, scaleFactor, buildingRandom);
  }

  /// Draw main building structure
  void _drawBuildingStructure(
    Uint32List pixels,
    int width,
    int height,
    _Building building,
    Color mainColor,
    double perspective,
  ) {
    for (int y = building.y; y < building.y + building.height; y++) {
      for (int x = building.x; x < building.x + building.width; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = y * width + x;

          // Apply perspective shading (left side darker, right side lighter)
          var color = mainColor;
          if (perspective > 0.1) {
            final xProgress = (x - building.x) / building.width;
            final shadeFactor = (xProgress - 0.5) * perspective * 0.4;
            color = _adjustBrightness(color, shadeFactor);
          }

          pixels[index] = color.value;
        }
      }
    }
  }

  /// Improved window drawing with proper grid alignment and realistic appearance
  void _drawWindowsImproved(
    Uint32List pixels,
    int width,
    int height,
    _Building building,
    double density,
    _BuildingColors colors,
    double litRatio,
    int windowStyle,
    int weatherEffect,
    double scaleFactor,
    Random random,
  ) {
    // Calculate window dimensions based on scale and style
    final windowConfig = _getWindowConfig(windowStyle, scaleFactor, random);

    final windowWidth = windowConfig.width;
    final windowHeight = windowConfig.height;
    final horizontalSpacing = windowConfig.horizontalSpacing;
    final verticalSpacing = windowConfig.verticalSpacing;
    final marginX = windowConfig.marginX;
    final marginY = windowConfig.marginY;

    // Calculate available space
    final availableWidth = building.width - (marginX * 2);
    final availableHeight = building.height - (marginY * 2);

    if (availableWidth < windowWidth || availableHeight < windowHeight) return;

    // Calculate how many windows fit
    final windowsPerRow = max(1, (availableWidth + horizontalSpacing) ~/ (windowWidth + horizontalSpacing));
    final numRows = max(1, (availableHeight + verticalSpacing) ~/ (windowHeight + verticalSpacing));

    // Calculate actual spacing to distribute windows evenly
    final actualHSpacing =
        windowsPerRow > 1 ? (availableWidth - windowsPerRow * windowWidth) / (windowsPerRow - 1) : 0.0;
    final actualVSpacing = numRows > 1 ? (availableHeight - numRows * windowHeight) / (numRows - 1) : 0.0;

    // Determine if it's night for lighting effects
    final isNight = weatherEffect == 3;
    final isNeon = colors.main.computeLuminance() < 0.2;

    // Pre-generate which windows are lit (per window, not per pixel)
    final litWindows = List.generate(
      numRows * windowsPerRow,
      (i) => random.nextDouble() < (isNight ? litRatio : litRatio * 0.3),
    );

    // Pre-generate window colors for variation
    final windowColors = List.generate(numRows * windowsPerRow, (i) {
      if (!litWindows[i]) {
        // Unlit window - dark reflection
        return isNight ? colors.window.withOpacity(0.3) : _adjustBrightness(colors.window, -0.3);
      }

      // Lit window with color variation
      final variation = random.nextDouble();
      if (isNeon) {
        // Neon windows with vibrant colors
        final neonColors = [
          const Color(0xFF00FFFF),
          const Color(0xFFFF00FF),
          const Color(0xFFFFFF00),
          const Color(0xFF00FF00),
          const Color(0xFFFF6600),
        ];
        return neonColors[random.nextInt(neonColors.length)];
      } else if (variation < 0.6) {
        return colors.window; // Standard warm light
      } else if (variation < 0.8) {
        return Color.lerp(colors.window, const Color(0xFFFFE4B5), 0.5)!; // Warmer
      } else {
        return Color.lerp(colors.window, const Color(0xFFE6E6FA), 0.3)!; // Cooler/bluish
      }
    });

    // Draw windows
    for (int row = 0; row < numRows; row++) {
      // Skip some rows based on density
      if (random.nextDouble() > density + 0.3) continue;

      for (int col = 0; col < windowsPerRow; col++) {
        // Skip some windows based on density
        if (random.nextDouble() > density) continue;

        final windowIndex = row * windowsPerRow + col;
        final windowX = building.x + marginX + (col * (windowWidth + actualHSpacing)).round();
        final windowY = building.y + marginY + (row * (windowHeight + actualVSpacing)).round();

        final windowColor = windowColors[windowIndex];
        final isLit = litWindows[windowIndex];

        _drawSingleWindow(
          pixels,
          width,
          height,
          windowX,
          windowY,
          windowWidth,
          windowHeight,
          windowColor,
          isLit,
          isNight,
          windowStyle,
          scaleFactor,
        );
      }
    }
  }

  /// Get window configuration based on style
  _WindowConfig _getWindowConfig(int style, double scaleFactor, Random random) {
    final baseSize = max(1, scaleFactor.round());

    switch (style) {
      case 1: // Floor-to-ceiling
        return _WindowConfig(
          width: max(1, (baseSize * 1.5).round()),
          height: max(2, (baseSize * 3).round()),
          horizontalSpacing: max(1, baseSize),
          verticalSpacing: max(1, baseSize),
          marginX: max(1, baseSize),
          marginY: max(1, baseSize),
        );
      case 2: // Small/Classic
        return _WindowConfig(
          width: max(1, baseSize),
          height: max(1, baseSize),
          horizontalSpacing: max(1, (baseSize * 1.5).round()),
          verticalSpacing: max(1, (baseSize * 2).round()),
          marginX: max(1, (baseSize * 1.5).round()),
          marginY: max(1, (baseSize * 1.5).round()),
        );
      case 3: // Mixed - randomize per building
        final subStyle = random.nextInt(3);
        return _getWindowConfig(subStyle, scaleFactor, random);
      case 0: // Standard
      default:
        return _WindowConfig(
          width: max(1, baseSize),
          height: max(1, (baseSize * 1.5).round()),
          horizontalSpacing: max(1, (baseSize * 1.2).round()),
          verticalSpacing: max(1, (baseSize * 1.5).round()),
          marginX: max(1, (baseSize * 1.2).round()),
          marginY: max(1, (baseSize * 1.2).round()),
        );
    }
  }

  /// Draw a single window with proper appearance
  void _drawSingleWindow(
    Uint32List pixels,
    int canvasWidth,
    int canvasHeight,
    int x,
    int y,
    int windowWidth,
    int windowHeight,
    Color color,
    bool isLit,
    bool isNight,
    int style,
    double scaleFactor,
  ) {
    for (int wy = 0; wy < windowHeight; wy++) {
      for (int wx = 0; wx < windowWidth; wx++) {
        final pixelX = x + wx;
        final pixelY = y + wy;

        if (pixelX >= 0 && pixelX < canvasWidth && pixelY >= 0 && pixelY < canvasHeight) {
          final index = pixelY * canvasWidth + pixelX;

          // Add subtle gradient/reflection effect to windows
          var finalColor = color;

          if (isLit && isNight) {
            // Glow effect for lit windows at night - brighter in center
            final centerX = windowWidth / 2;
            final centerY = windowHeight / 2;
            final distFromCenter =
                sqrt(pow(wx - centerX, 2) + pow(wy - centerY, 2)) / sqrt(pow(centerX, 2) + pow(centerY, 2));
            finalColor = Color.lerp(color, Colors.white, (1 - distFromCenter) * 0.3)!;
          } else if (!isLit) {
            // Reflection gradient for unlit windows
            final reflectionGradient = wy / windowHeight;
            finalColor = Color.lerp(color, Colors.white.withOpacity(0.1), reflectionGradient * 0.2)!;
          }

          // Add window frame for larger windows
          if (scaleFactor >= 1.5 && windowWidth >= 2 && windowHeight >= 2) {
            final isFrame = wx == 0 || wx == windowWidth - 1 || wy == 0 || wy == windowHeight - 1;
            if (isFrame) {
              finalColor = _adjustBrightness(finalColor, -0.3);
            }
          }

          pixels[index] = finalColor.value;
        }
      }
    }
  }

  /// Draw architectural details based on building style
  void _drawArchitecturalDetails(
    Uint32List pixels,
    int width,
    int height,
    _Building building,
    int style,
    _BuildingColors colors,
    double scaleFactor,
    Random random,
  ) {
    switch (style) {
      case 0: // Modern - clean lines
        _drawModernDetails(pixels, width, height, building, colors, scaleFactor);
        break;
      case 1: // Classic - decorative elements
        _drawClassicDetails(pixels, width, height, building, colors, scaleFactor, random);
        break;
      case 2: // Futuristic - sleek design
        _drawFuturisticDetails(pixels, width, height, building, colors, scaleFactor);
        break;
      case 3: // Mixed - combination
        if (random.nextBool()) {
          _drawModernDetails(pixels, width, height, building, colors, scaleFactor);
        } else {
          _drawClassicDetails(pixels, width, height, building, colors, scaleFactor, random);
        }
        break;
    }
  }

  /// Draw modern architectural details
  void _drawModernDetails(
    Uint32List pixels,
    int width,
    int height,
    _Building building,
    _BuildingColors colors,
    double scaleFactor,
  ) {
    final lineWidth = max(1, scaleFactor.round());

    // Draw roof line
    final roofY = building.y;
    for (int x = building.x; x < building.x + building.width; x++) {
      for (int ly = 0; ly < lineWidth && roofY + ly < height; ly++) {
        if (x >= 0 && x < width && roofY + ly >= 0) {
          pixels[(roofY + ly) * width + x] = colors.accent.value;
        }
      }
    }

    // Draw vertical accent lines (only if building is wide enough)
    if (building.width >= 12 * scaleFactor) {
      for (int i = 1; i < 3; i++) {
        final lineX = building.x + (building.width * i ~/ 3);
        for (int y = building.y; y < building.y + building.height; y++) {
          if (lineX >= 0 && lineX < width && y >= 0 && y < height) {
            pixels[y * width + lineX] = colors.accent.value;
          }
        }
      }
    }
  }

  /// Draw classic architectural details
  void _drawClassicDetails(
    Uint32List pixels,
    int width,
    int height,
    _Building building,
    _BuildingColors colors,
    double scaleFactor,
    Random random,
  ) {
    final decorHeight = max(2, (3 * scaleFactor).round());

    // Draw decorative cornice at top
    for (int y = building.y; y < building.y + decorHeight && y < height; y++) {
      for (int x = building.x; x < building.x + building.width; x++) {
        if (x >= 0 && x < width && y >= 0) {
          pixels[y * width + x] = colors.accent.value;
        }
      }
    }

    // Draw columns or pilasters (only if building is wide enough)
    if (building.width >= 8 * scaleFactor) {
      final numColumns = (building.width / (6 * scaleFactor)).round().clamp(2, 5);
      for (int i = 0; i < numColumns; i++) {
        final columnX = building.x + (building.width * i ~/ (numColumns - 1)).clamp(0, building.width - 1);
        for (int y = building.y + decorHeight; y < building.y + building.height; y++) {
          if (columnX >= 0 && columnX < width && y >= 0 && y < height) {
            pixels[y * width + columnX] = colors.accent.value;
          }
        }
      }
    }
  }

  /// Draw futuristic architectural details
  void _drawFuturisticDetails(
    Uint32List pixels,
    int width,
    int height,
    _Building building,
    _BuildingColors colors,
    double scaleFactor,
  ) {
    final lineThickness = max(1, scaleFactor.round());

    // Draw sleek horizontal accent lines
    final numLines = max(2, (building.height / (15 * scaleFactor)).round());
    for (int i = 0; i < numLines; i++) {
      final lineY = building.y + (building.height * (i + 1) ~/ (numLines + 1));
      for (int x = building.x + 2; x < building.x + building.width - 2; x++) {
        for (int ly = 0; ly < lineThickness && lineY + ly < height; ly++) {
          if (x >= 0 && x < width && lineY + ly >= 0) {
            pixels[(lineY + ly) * width + x] = colors.accent.value;
          }
        }
      }
    }

    // Draw glowing corner accents
    final cornerSize = max(2, (3 * scaleFactor).round());
    final corners = [
      [building.x, building.y], // Top-left
      [building.x + building.width - cornerSize, building.y], // Top-right
    ];

    for (final corner in corners) {
      for (int y = corner[1]; y < corner[1] + cornerSize && y < height; y++) {
        for (int x = corner[0]; x < corner[0] + cornerSize && x < width; x++) {
          if (x >= 0 && y >= 0) {
            pixels[y * width + x] = colors.accent.value;
          }
        }
      }
    }
  }

  /// Add rooftop details like antennas with proper scaling
  void _addRooftopDetails(
    Uint32List pixels,
    int width,
    int height,
    List<_Building> buildings,
    double density,
    int colorScheme,
    double scaleFactor,
    Random random,
  ) {
    for (final building in buildings) {
      if (random.nextDouble() < density) {
        final detailType = random.nextInt(4);
        final detailX = building.x + building.width ~/ 2;
        final detailColor = _getDetailColor(colorScheme);

        switch (detailType) {
          case 0: // Antenna
            _drawAntenna(pixels, width, height, detailX, building.y, detailColor, scaleFactor);
            break;
          case 1: // Satellite dish
            _drawSatelliteDish(pixels, width, height, detailX, building.y, detailColor, scaleFactor);
            break;
          case 2: // Small structure / AC unit
            _drawRooftopStructure(pixels, width, height, detailX, building.y, detailColor, scaleFactor, random);
            break;
          case 3: // Water tower (for larger buildings)
            if (building.width >= 10 * scaleFactor) {
              _drawWaterTower(pixels, width, height, detailX, building.y, detailColor, scaleFactor);
            } else {
              _drawAntenna(pixels, width, height, detailX, building.y, detailColor, scaleFactor);
            }
            break;
        }
      }
    }
  }

  /// Draw antenna detail with scaling
  void _drawAntenna(Uint32List pixels, int width, int height, int x, int y, Color color, double scaleFactor) {
    final antennaHeight = max(3, (8 * scaleFactor).round());
    for (int i = 0; i < antennaHeight; i++) {
      final pixelY = y - i - 1;
      if (x >= 0 && x < width && pixelY >= 0 && pixelY < height) {
        pixels[pixelY * width + x] = color.value;
      }
    }

    // Add blinking light at top
    final topY = y - antennaHeight - 1;
    if (x >= 0 && x < width && topY >= 0 && topY < height) {
      pixels[topY * width + x] = const Color(0xFFFF0000).value; // Red light
    }
  }

  /// Draw satellite dish with scaling
  void _drawSatelliteDish(Uint32List pixels, int width, int height, int x, int y, Color color, double scaleFactor) {
    final dishSize = max(2, (3 * scaleFactor).round());
    final dishHeight = max(1, (2 * scaleFactor).round());

    for (int dy = 0; dy < dishHeight; dy++) {
      for (int dx = -dishSize; dx <= dishSize; dx++) {
        final pixelX = x + dx;
        final pixelY = y - 2 - dy;
        if (pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height) {
          pixels[pixelY * width + pixelX] = color.value;
        }
      }
    }
  }

  /// Draw small rooftop structure with scaling
  void _drawRooftopStructure(
    Uint32List pixels,
    int width,
    int height,
    int x,
    int y,
    Color color,
    double scaleFactor,
    Random random,
  ) {
    final structWidth = max(2, (2 + random.nextInt(3)) * scaleFactor).round();
    final structHeight = max(2, (2 + random.nextInt(4)) * scaleFactor).round();

    for (int dy = 0; dy < structHeight; dy++) {
      for (int dx = -structWidth ~/ 2; dx <= structWidth ~/ 2; dx++) {
        final pixelX = x + dx;
        final pixelY = y - dy - 1;
        if (pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height) {
          pixels[pixelY * width + pixelX] = color.value;
        }
      }
    }
  }

  /// Draw water tower
  void _drawWaterTower(Uint32List pixels, int width, int height, int x, int y, Color color, double scaleFactor) {
    final towerWidth = max(3, (4 * scaleFactor).round());
    final towerHeight = max(4, (6 * scaleFactor).round());
    final legHeight = max(2, (3 * scaleFactor).round());

    // Draw legs
    final leftLegX = x - towerWidth ~/ 2;
    final rightLegX = x + towerWidth ~/ 2;
    for (int dy = 0; dy < legHeight; dy++) {
      final pixelY = y - dy - 1;
      if (pixelY >= 0 && pixelY < height) {
        if (leftLegX >= 0 && leftLegX < width) {
          pixels[pixelY * width + leftLegX] = color.value;
        }
        if (rightLegX >= 0 && rightLegX < width) {
          pixels[pixelY * width + rightLegX] = color.value;
        }
      }
    }

    // Draw tank
    for (int dy = legHeight; dy < legHeight + towerHeight; dy++) {
      for (int dx = -towerWidth ~/ 2; dx <= towerWidth ~/ 2; dx++) {
        final pixelX = x + dx;
        final pixelY = y - dy - 1;
        if (pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height) {
          pixels[pixelY * width + pixelX] = color.value;
        }
      }
    }
  }

  /// Apply weather effects
  void _applyWeatherEffect(
      Uint32List pixels, int width, int height, int weatherEffect, int colorScheme, Random random) {
    switch (weatherEffect) {
      case 1: // Fog
        _applyFogEffect(pixels, width, height);
        break;
      case 2: // Rain
        _applyRainEffect(pixels, width, height, random);
        break;
      case 3: // Night - already handled in building colors
        _addStars(pixels, width, height, random);
        break;
      case 0: // Clear
      default:
        break;
    }
  }

  /// Apply fog effect with depth-based intensity
  void _applyFogEffect(Uint32List pixels, int width, int height) {
    final fogColor = const Color(0xFFCCCCCC);

    for (int y = 0; y < height; y++) {
      // Fog is thicker at the bottom (closer to viewer)
      final fogIntensity = (y / height).clamp(0.0, 1.0) * 0.5;

      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (pixels[index] == 0) continue; // Skip transparent pixels

        final pixel = Color(pixels[index]);
        final blended = Color.lerp(pixel, fogColor, fogIntensity)!;
        pixels[index] = blended.value;
      }
    }
  }

  /// Apply rain effect with better distribution
  void _applyRainEffect(Uint32List pixels, int width, int height, Random random) {
    final rainRandom = Random(random.nextInt(10000));
    final rainDrops = (width * height / 50).round().clamp(10, 500);

    for (int i = 0; i < rainDrops; i++) {
      final x = rainRandom.nextInt(width);
      final startY = rainRandom.nextInt(height);
      final rainLength = 2 + rainRandom.nextInt(4);

      for (int j = 0; j < rainLength; j++) {
        final y = startY + j;
        if (x < width && y < height && y >= 0) {
          final index = y * width + x;
          // Semi-transparent rain that blends with background
          final existing = Color(pixels[index]);
          final rainColor = Color.lerp(existing, const Color(0xFFAABBCC), 0.6)!;
          pixels[index] = rainColor.value;
        }
      }
    }
  }

  /// Add stars for night sky
  void _addStars(Uint32List pixels, int width, int height, Random random) {
    final starRandom = Random(random.nextInt(10000));
    final numStars = (width * height / 100).round().clamp(5, 200);

    for (int i = 0; i < numStars; i++) {
      final x = starRandom.nextInt(width);
      final y = starRandom.nextInt(height ~/ 2); // Stars only in upper half

      if (x >= 0 && x < width && y >= 0 && y < height) {
        final index = y * width + x;
        // Only add star if pixel is dark (sky area)
        final existing = Color(pixels[index]);
        if (existing.computeLuminance() < 0.2) {
          final brightness = 0.5 + starRandom.nextDouble() * 0.5;
          final starColor = Color.lerp(Colors.white, const Color(0xFFFFFFAA), starRandom.nextDouble())!;
          pixels[index] = starColor.withOpacity(brightness).value;
        }
      }
    }
  }

  /// Get building colors based on color scheme
  _BuildingColors _getBuildingColors(int colorScheme, Random random, bool isNight) {
    switch (colorScheme) {
      case 0: // Realistic
        final baseHue = 20 + random.nextInt(40); // Brown to gray range
        final saturation = 0.1 + random.nextDouble() * 0.15;
        final value = isNight ? 0.3 + random.nextDouble() * 0.2 : 0.5 + random.nextDouble() * 0.3;
        final main = HSVColor.fromAHSV(1.0, baseHue.toDouble(), saturation, value).toColor();
        final window = isNight ? const Color(0xFFFFE4B5) : const Color(0xFF6699CC); // Warm light vs sky reflection
        final accent = Color.lerp(main, Colors.white, 0.2)!;
        return _BuildingColors(main, window, accent);

      case 1: // Neon/Cyberpunk
        final main = isNight ? const Color(0xFF0a0a15) : const Color(0xFF1A1A2E);
        final neonColors = [0xFF00FFFF, 0xFFFF00FF, 0xFFFFFF00, 0xFF00FF00, 0xFFFF6600];
        final window = Color(neonColors[random.nextInt(neonColors.length)]);
        final accent = Color.lerp(window, Colors.white, 0.3)!;
        return _BuildingColors(main, window, accent);

      case 2: // Monochrome
        final grayValue = isNight ? 60 + random.nextInt(40) : 100 + random.nextInt(80);
        final main = Color.fromARGB(255, grayValue, grayValue, grayValue);
        final windowGray = grayValue + (isNight ? 60 : 30);
        final window =
            Color.fromARGB(255, windowGray.clamp(0, 255), windowGray.clamp(0, 255), windowGray.clamp(0, 255));
        final accent = Colors.white.withOpacity(0.8);
        return _BuildingColors(main, window, accent);

      case 3: // Sunset
        final warmColors = [0xFFCC5533, 0xFFBB6644, 0xFFAA7755, 0xFF996655];
        final main = Color(warmColors[random.nextInt(warmColors.length)]);
        final window = const Color(0xFFFFDD44); // Golden windows reflecting sunset
        final accent = Color.lerp(main, const Color(0xFFFFAA00), 0.4)!;
        return _BuildingColors(main, window, accent);

      default:
        return _getBuildingColors(0, random, isNight);
    }
  }

  /// Get color for details based on color scheme
  Color _getDetailColor(int colorScheme) {
    switch (colorScheme) {
      case 0:
        return Colors.grey.shade500;
      case 1:
        return const Color(0xFF00FFFF);
      case 2:
        return Colors.grey.shade400;
      case 3:
        return const Color(0xFFFF8C42);
      default:
        return Colors.grey.shade400;
    }
  }

  /// Adjust color brightness
  Color _adjustBrightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}

/// Helper class to represent a building
class _Building {
  final int x, y, width, height, style, depth, floors;

  _Building({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.style,
    this.depth = 0,
    this.floors = 1,
  });
}

/// Helper class for building colors
class _BuildingColors {
  final Color main, window, accent;

  _BuildingColors(this.main, this.window, this.accent);
}

/// Helper class for window configuration
class _WindowConfig {
  final int width, height, horizontalSpacing, verticalSpacing, marginX, marginY;

  _WindowConfig({
    required this.width,
    required this.height,
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.marginX,
    required this.marginY,
  });
}
