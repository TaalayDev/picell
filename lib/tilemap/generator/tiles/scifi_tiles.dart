import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// SCI-FI TILE PALETTES
// ============================================================================

class SciFiPalettes {
  SciFiPalettes._();

  /// Metal hull - standard spaceship hull
  static const metalHull = TilePalette(
    name: 'Metal Hull',
    colors: [
      Color(0xFF4A5568), // Base gray-blue
      Color(0xFF5A6578), // Light
      Color(0xFF3A4558), // Dark
      Color(0xFF6A7588), // Highlight
      Color(0xFF2A3548), // Shadow
    ],
  );

  /// Dark metal - industrial dark metal
  static const darkMetal = TilePalette(
    name: 'Dark Metal',
    colors: [
      Color(0xFF2D3748), // Base dark
      Color(0xFF3D4758), // Light
      Color(0xFF1D2738), // Darker
      Color(0xFF4D5768), // Highlight
      Color(0xFF0D1728), // Shadow
    ],
  );

  /// Brushed steel
  static const brushedSteel = TilePalette(
    name: 'Brushed Steel',
    colors: [
      Color(0xFF8A9AAA), // Base steel
      Color(0xFF9AAABA), // Light
      Color(0xFF7A8A9A), // Medium
      Color(0xFFAABACA), // Highlight
      Color(0xFF5A6A7A), // Shadow
    ],
  );

  /// Rusty metal
  static const rustyMetal = TilePalette(
    name: 'Rusty Metal',
    colors: [
      Color(0xFF6B4A3A), // Rust base
      Color(0xFF7B5A4A), // Light rust
      Color(0xFF5B3A2A), // Dark rust
      Color(0xFF8B6A5A), // Highlight
      Color(0xFF3B2A1A), // Shadow
    ],
  );

  /// Neon cyan - for lights and accents
  static const neonCyan = TilePalette(
    name: 'Neon Cyan',
    colors: [
      Color(0xFF00D4FF), // Bright cyan
      Color(0xFF00E8FF), // Lighter
      Color(0xFF00B8E0), // Medium
      Color(0xFFAAFFFF), // Glow
      Color(0xFF008BAA), // Dark
    ],
  );

  /// Neon pink
  static const neonPink = TilePalette(
    name: 'Neon Pink',
    colors: [
      Color(0xFFFF00AA), // Bright pink
      Color(0xFFFF44CC), // Lighter
      Color(0xFFCC0088), // Medium
      Color(0xFFFFAADD), // Glow
      Color(0xFF880066), // Dark
    ],
  );

  /// Neon green
  static const neonGreen = TilePalette(
    name: 'Neon Green',
    colors: [
      Color(0xFF00FF88), // Bright green
      Color(0xFF44FFAA), // Lighter
      Color(0xFF00CC66), // Medium
      Color(0xFFAAFFCC), // Glow
      Color(0xFF008844), // Dark
    ],
  );

  /// Neon orange
  static const neonOrange = TilePalette(
    name: 'Neon Orange',
    colors: [
      Color(0xFFFF8800), // Bright orange
      Color(0xFFFFAA44), // Lighter
      Color(0xFFCC6600), // Medium
      Color(0xFFFFCC88), // Glow
      Color(0xFF884400), // Dark
    ],
  );

  /// Holographic - iridescent effect
  static const holographic = TilePalette(
    name: 'Holographic',
    colors: [
      Color(0xFF88AAFF), // Blue
      Color(0xFFAA88FF), // Purple
      Color(0xFFFF88AA), // Pink
      Color(0xFF88FFAA), // Green
      Color(0xFFFFAA88), // Orange
    ],
  );

  /// Energy blue - for force fields
  static const energyBlue = TilePalette(
    name: 'Energy Blue',
    colors: [
      Color(0xFF4488FF), // Base blue
      Color(0xFF66AAFF), // Light
      Color(0xFF2266DD), // Dark
      Color(0xFFAADDFF), // Glow
      Color(0xFF1144AA), // Deep
    ],
  );

  /// Warning - hazard stripes
  static const warning = TilePalette(
    name: 'Warning',
    colors: [
      Color(0xFFFFCC00), // Yellow
      Color(0xFF2A2A2A), // Black
      Color(0xFFFFDD44), // Light yellow
      Color(0xFF1A1A1A), // Dark black
      Color(0xFFCC9900), // Dark yellow
    ],
  );

  /// Tech green - computer screens
  static const techGreen = TilePalette(
    name: 'Tech Green',
    colors: [
      Color(0xFF00AA44), // Terminal green
      Color(0xFF00CC55), // Light
      Color(0xFF008833), // Dark
      Color(0xFF00FF66), // Bright
      Color(0xFF004422), // Shadow
    ],
  );

  /// Circuit board
  static const circuitBoard = TilePalette(
    name: 'Circuit Board',
    colors: [
      Color(0xFF1A4A2A), // Green PCB base
      Color(0xFF2A5A3A), // Light
      Color(0xFF0A3A1A), // Dark
      Color(0xFFCCCC44), // Gold traces
      Color(0xFF888822), // Dark gold
    ],
  );

  /// Copper wiring
  static const copper = TilePalette(
    name: 'Copper',
    colors: [
      Color(0xFFB87333), // Copper base
      Color(0xFFD4883D), // Light
      Color(0xFF8B5A2B), // Dark
      Color(0xFFE89848), // Highlight
      Color(0xFF5A3A1A), // Shadow
    ],
  );
}

// ============================================================================
// METAL FLOOR TILES
// ============================================================================

/// Metal floor panel with rivets
class MetalFloorTile extends TileBase {
  final TilePalette metalPalette;
  final bool addRivets;
  final bool addScratches;

  MetalFloorTile(
    super.id, {
    this.metalPalette = SciFiPalettes.metalHull,
    this.addRivets = true,
    this.addScratches = false,
  });

  @override
  String get name => 'Metal Floor';
  @override
  String get description => 'Industrial metal floor panel';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => metalPalette;
  @override
  List<String> get tags => ['metal', 'floor', 'scifi', 'industrial', 'spaceship'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base metal texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise = noise2D(x / 4.0 + seed, y / 4.0, 2);
        Color baseColor;
        if (noise < 0.3) {
          baseColor = palette.shadow;
        } else if (noise < 0.5) {
          baseColor = palette.colors[2];
        } else if (noise < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    // Add panel edges (border)
    for (int i = 0; i < width; i++) {
      pixels[i] = colorToInt(palette.shadow);
      pixels[(height - 1) * width + i] = colorToInt(palette.highlight);
    }
    for (int i = 0; i < height; i++) {
      pixels[i * width] = colorToInt(palette.shadow);
      pixels[i * width + width - 1] = colorToInt(palette.highlight);
    }

    // Add rivets in corners
    if (addRivets) {
      _addRivet(pixels, width, height, 2, 2, random);
      _addRivet(pixels, width, height, width - 3, 2, random);
      _addRivet(pixels, width, height, 2, height - 3, random);
      _addRivet(pixels, width, height, width - 3, height - 3, random);
    }

    // Add scratches
    if (addScratches || variation == TileVariation.weathered) {
      _addScratches(pixels, width, height, random);
    }

    return pixels;
  }

  void _addRivet(Uint32List pixels, int w, int h, int cx, int cy, Random random) {
    if (cx >= 0 && cx < w && cy >= 0 && cy < h) {
      pixels[cy * w + cx] = colorToInt(palette.highlight);
    }
    // Shadow
    if (cx + 1 < w && cy + 1 < h) {
      pixels[(cy + 1) * w + cx + 1] = colorToInt(palette.shadow);
    }
  }

  void _addScratches(Uint32List pixels, int w, int h, Random random) {
    final scratchCount = random.nextInt(3) + 1;
    for (int s = 0; s < scratchCount; s++) {
      var sx = random.nextInt(w);
      var sy = random.nextInt(h);
      final length = random.nextInt(6) + 3;
      final horizontal = random.nextBool();

      for (int i = 0; i < length; i++) {
        if (sx >= 0 && sx < w && sy >= 0 && sy < h) {
          pixels[sy * w + sx] = colorToInt(palette.highlight);
        }
        if (horizontal) {
          sx++;
        } else {
          sy++;
        }
      }
    }
  }
}

/// Diamond plate / checker plate floor
class SciFiDiamondPlateTile extends TileBase {
  final TilePalette metalPalette;

  SciFiDiamondPlateTile(super.id, {this.metalPalette = SciFiPalettes.brushedSteel});

  @override
  String get name => 'Diamond Plate';
  @override
  String get description => 'Anti-slip diamond pattern metal';
  @override
  String get iconName => 'texture';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => metalPalette;
  @override
  List<String> get tags => ['metal', 'floor', 'diamond', 'industrial', 'grip'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base metal
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise = noise2D(x / 3.0 + seed, y / 3.0, 2);
        final baseColor = noise > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.02);
      }
    }

    // Diamond pattern - raised bumps
    const spacing = 4;
    for (int py = 0; py < height; py += spacing) {
      final offset = ((py ~/ spacing) % 2) * (spacing ~/ 2);
      for (int px = offset; px < width; px += spacing) {
        // Draw diamond shape
        _drawDiamond(pixels, width, height, px, py, random);
      }
    }

    return pixels;
  }

  void _drawDiamond(Uint32List pixels, int w, int h, int cx, int cy, Random random) {
    // Small raised diamond
    final points = [
      (cx, cy - 1),
      (cx - 1, cy),
      (cx + 1, cy),
      (cx, cy + 1),
      (cx, cy),
    ];

    for (final (px, py) in points) {
      if (px >= 0 && px < w && py >= 0 && py < h) {
        pixels[py * w + px] = colorToInt(palette.highlight);
      }
    }
    // Shadow
    if (cx + 1 < w && cy + 1 < h) {
      pixels[(cy + 1) * w + cx + 1] = addNoise(palette.shadow, random, 0.02);
    }
  }
}

/// Grated metal floor
class SciFiGratingTile extends TileBase {
  final int gridSize;
  final TilePalette metalPalette;

  SciFiGratingTile(super.id, {this.gridSize = 3, this.metalPalette = SciFiPalettes.darkMetal});

  @override
  String get name => 'Metal Grating';
  @override
  String get description => 'Industrial metal grating';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => metalPalette;
  @override
  List<String> get tags => ['metal', 'grating', 'industrial', 'floor', 'ventilation'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dark background (void below grating)
    final bgColor = const Color(0xFF0A0A0A);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(bgColor);
    }

    // Draw grating bars
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isHBar = y % gridSize == 0;
        final isVBar = x % gridSize == 0;

        if (isHBar || isVBar) {
          Color barColor;
          if (isHBar && isVBar) {
            barColor = palette.highlight; // Intersection
          } else if (isHBar) {
            barColor = palette.primary;
          } else {
            barColor = palette.secondary;
          }
          pixels[y * width + x] = addNoise(barColor, random, 0.03);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// WALL AND PANEL TILES
// ============================================================================

/// Sci-fi wall panel with tech details
class TechWallTile extends TileBase {
  final TilePalette metalPalette;
  final TilePalette accentPalette;
  final bool addVents;
  final bool addLights;

  TechWallTile(
    super.id, {
    this.metalPalette = SciFiPalettes.metalHull,
    this.accentPalette = SciFiPalettes.neonCyan,
    this.addVents = false,
    this.addLights = true,
  });

  @override
  String get name => 'Tech Wall';
  @override
  String get description => 'Futuristic wall panel with tech details';
  @override
  String get iconName => 'view_module';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => metalPalette;
  @override
  List<String> get tags => ['wall', 'panel', 'scifi', 'tech', 'spaceship'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base wall texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise = noise2D(x / 5.0 + seed, y / 5.0, 2);
        final baseColor = noise > 0.5 ? palette.primary : palette.colors[2];
        pixels[y * width + x] = addNoise(baseColor, random, 0.02);
      }
    }

    // Panel border
    for (int i = 0; i < width; i++) {
      pixels[i] = colorToInt(palette.shadow);
      pixels[width + i] = colorToInt(palette.highlight);
      pixels[(height - 2) * width + i] = colorToInt(palette.shadow);
      pixels[(height - 1) * width + i] = colorToInt(palette.highlight);
    }
    for (int i = 0; i < height; i++) {
      pixels[i * width] = colorToInt(palette.shadow);
      pixels[i * width + 1] = colorToInt(palette.highlight);
      pixels[i * width + width - 2] = colorToInt(palette.shadow);
      pixels[i * width + width - 1] = colorToInt(palette.highlight);
    }

    // Add accent lights
    if (addLights) {
      final lightY = height ~/ 2;
      for (int x = 3; x < width - 3; x++) {
        pixels[lightY * width + x] = colorToInt(accentPalette.primary);
        // Glow effect
        if (lightY > 0) {
          pixels[(lightY - 1) * width + x] = colorToInt(accentPalette.colors[3]);
        }
        if (lightY < height - 1) {
          pixels[(lightY + 1) * width + x] = colorToInt(accentPalette.colors[3]);
        }
      }
    }

    // Add vents
    if (addVents) {
      final ventY = height ~/ 3;
      for (int x = 4; x < width - 4; x += 2) {
        pixels[ventY * width + x] = colorToInt(palette.shadow);
      }
    }

    return pixels;
  }
}

/// Hexagonal panel tile
class HexPanelTile extends TileBase {
  final TilePalette metalPalette;

  HexPanelTile(super.id, {this.metalPalette = SciFiPalettes.darkMetal});

  @override
  String get name => 'Hex Panel';
  @override
  String get description => 'Hexagonal pattern panel';
  @override
  String get iconName => 'hexagon';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => metalPalette;
  @override
  List<String> get tags => ['hex', 'hexagon', 'panel', 'scifi', 'pattern'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base color
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise = noise2D(x / 3.0 + seed, y / 3.0, 2);
        final baseColor = noise > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.02);
      }
    }

    // Draw hexagonal pattern
    const hexSize = 6;
    for (int hy = 0; hy < height; hy += hexSize) {
      final offset = ((hy ~/ hexSize) % 2) * (hexSize ~/ 2);
      for (int hx = offset; hx < width; hx += hexSize) {
        _drawHexOutline(pixels, width, height, hx, hy, hexSize ~/ 2);
      }
    }

    return pixels;
  }

  void _drawHexOutline(Uint32List pixels, int w, int h, int cx, int cy, int size) {
    // Simplified hex outline
    for (int i = -size + 1; i < size; i++) {
      // Top edge
      final tx = cx + i;
      final ty = cy - size ~/ 2;
      if (tx >= 0 && tx < w && ty >= 0 && ty < h) {
        pixels[ty * w + tx] = colorToInt(palette.shadow);
      }
      // Bottom edge
      final by = cy + size ~/ 2;
      if (tx >= 0 && tx < w && by >= 0 && by < h) {
        pixels[by * w + tx] = colorToInt(palette.highlight);
      }
    }
  }
}

// ============================================================================
// CIRCUIT AND TECH TILES
// ============================================================================

/// Circuit board pattern
class CircuitBoardTile extends TileBase {
  final TilePalette boardPalette;
  final bool addComponents;

  CircuitBoardTile(super.id, {this.boardPalette = SciFiPalettes.circuitBoard, this.addComponents = true});

  @override
  String get name => 'Circuit Board';
  @override
  String get description => 'Electronic circuit board pattern';
  @override
  String get iconName => 'memory';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => boardPalette;
  @override
  List<String> get tags => ['circuit', 'electronics', 'tech', 'computer', 'pcb'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Green PCB base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise = noise2D(x / 6.0 + seed, y / 6.0, 2);
        final baseColor = noise > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.02);
      }
    }

    // Draw circuit traces (gold lines)
    final traceColor = palette.colors[3]; // Gold
    _drawTraces(pixels, width, height, random, traceColor);

    // Add components
    if (addComponents) {
      _addComponents(pixels, width, height, random);
    }

    return pixels;
  }

  void _drawTraces(Uint32List pixels, int w, int h, Random random, Color color) {
    // Horizontal traces
    for (int y = 2; y < h - 2; y += 4) {
      final startX = random.nextInt(w ~/ 3);
      final endX = w - random.nextInt(w ~/ 3);
      for (int x = startX; x < endX; x++) {
        pixels[y * w + x] = colorToInt(color);
      }
      // Add vertical branches
      if (random.nextBool()) {
        final branchX = startX + random.nextInt(endX - startX);
        final branchLen = random.nextInt(3) + 2;
        for (int dy = 0; dy < branchLen && y + dy < h; dy++) {
          pixels[(y + dy) * w + branchX] = colorToInt(color);
        }
      }
    }

    // Vertical traces
    for (int x = 3; x < w - 3; x += 5) {
      final startY = random.nextInt(h ~/ 3);
      final endY = h - random.nextInt(h ~/ 3);
      for (int y = startY; y < endY; y++) {
        if (pixels[y * w + x] != colorToInt(color)) {
          pixels[y * w + x] = colorToInt(color);
        }
      }
    }
  }

  void _addComponents(Uint32List pixels, int w, int h, Random random) {
    // Add small IC chips (rectangles)
    final chipCount = random.nextInt(2) + 1;
    for (int c = 0; c < chipCount; c++) {
      final cx = random.nextInt(w - 6) + 3;
      final cy = random.nextInt(h - 4) + 2;
      // Chip body
      for (int dy = 0; dy < 3; dy++) {
        for (int dx = 0; dx < 4; dx++) {
          if (cx + dx < w && cy + dy < h) {
            pixels[(cy + dy) * w + cx + dx] = colorToInt(palette.shadow);
          }
        }
      }
    }

    // Add solder pads (circles)
    final padCount = random.nextInt(4) + 2;
    for (int p = 0; p < padCount; p++) {
      final px = random.nextInt(w - 2) + 1;
      final py = random.nextInt(h - 2) + 1;
      pixels[py * w + px] = colorToInt(palette.colors[4]); // Dark gold
    }
  }
}

/// Data stream / matrix effect tile
class DataStreamTile extends TileBase {
  final TilePalette streamPalette;

  DataStreamTile(super.id, {this.streamPalette = SciFiPalettes.techGreen});

  @override
  String get name => 'Data Stream';
  @override
  String get description => 'Flowing data/matrix effect';
  @override
  String get iconName => 'data_usage';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => streamPalette;
  @override
  List<String> get tags => ['data', 'matrix', 'digital', 'code', 'stream'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final pixels = Uint32List(width * height);

    // Dark background
    final bgColor = const Color(0xFF001100);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(bgColor);
    }

    // Draw data columns
    for (int x = 0; x < width; x += 2) {
      final columnSeed = seed + x * 100;
      final colRandom = Random(columnSeed);
      final offset = (frameIndex * 2 + colRandom.nextInt(4)) % height;

      for (int y = 0; y < height; y++) {
        final dataY = (y + offset) % height;
        if (colRandom.nextDouble() > 0.6) {
          // Determine brightness based on position
          final brightness = 1.0 - (y / height) * 0.7;
          if (brightness > 0.8) {
            pixels[dataY * width + x] = colorToInt(palette.colors[3]); // Bright
          } else if (brightness > 0.5) {
            pixels[dataY * width + x] = colorToInt(palette.primary);
          } else if (brightness > 0.2) {
            pixels[dataY * width + x] = colorToInt(palette.colors[2]);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ENERGY AND FORCE FIELD TILES
// ============================================================================

/// Energy/force field tile
class ForceFieldTile extends TileBase {
  final TilePalette energyPalette;
  final bool horizontal;

  ForceFieldTile(super.id, {this.energyPalette = SciFiPalettes.energyBlue, this.horizontal = false});

  @override
  String get name => 'Force Field';
  @override
  String get description => 'Energy barrier / force field';
  @override
  String get iconName => 'shield';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => energyPalette;
  @override
  List<String> get tags => ['energy', 'shield', 'barrier', 'force field', 'power'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex);
    final pixels = Uint32List(width * height);

    // Semi-transparent energy field
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final wave = sin((horizontal ? y : x) / 2.0 + frameIndex * 0.5 + seed);
        final noise = noise2D(x / 4.0 + frameIndex, y / 4.0 + seed, 2);

        Color color;
        if (wave > 0.5 || noise > 0.7) {
          color = palette.colors[3]; // Glow
        } else if (wave > 0.0 || noise > 0.5) {
          color = palette.primary;
        } else if (noise > 0.3) {
          color = palette.secondary;
        } else {
          color = palette.colors[2];
        }

        // Add transparency effect
        final alpha = (150 + (noise * 100).round()).clamp(100, 255);
        pixels[y * width + x] = (alpha << 24) | (color.red << 16) | (color.green << 8) | color.blue;
      }
    }

    // Add energy crackles
    if (random.nextDouble() > 0.5) {
      var cx = random.nextInt(width);
      var cy = random.nextInt(height);
      for (int i = 0; i < 5; i++) {
        if (cx >= 0 && cx < width && cy >= 0 && cy < height) {
          pixels[cy * width + cx] = colorToInt(const Color(0xFFFFFFFF));
        }
        cx += random.nextInt(3) - 1;
        cy += random.nextInt(3) - 1;
      }
    }

    return pixels;
  }
}

/// Plasma/energy conduit
class PlasmaConduitTile extends TileBase {
  final TilePalette plasmaPalette;
  final bool vertical;

  PlasmaConduitTile(super.id, {this.plasmaPalette = SciFiPalettes.neonPink, this.vertical = true});

  @override
  String get name => 'Plasma Conduit';
  @override
  String get description => 'Energy plasma conduit';
  @override
  String get iconName => 'bolt';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => plasmaPalette;
  @override
  List<String> get tags => ['plasma', 'energy', 'conduit', 'power', 'pipe'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final metalPalette = SciFiPalettes.darkMetal;

    // Metal pipe housing
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pos = vertical ? x : y;
        final size = vertical ? width : height;
        final center = size ~/ 2;
        final dist = (pos - center).abs();

        if (dist >= center - 1) {
          // Outer edge
          pixels[y * width + x] = colorToInt(metalPalette.shadow);
        } else if (dist >= center - 2) {
          // Metal housing
          pixels[y * width + x] = colorToInt(metalPalette.primary);
        } else {
          // Plasma center
          final flow = vertical ? y : x;
          final wave = sin((flow + frameIndex * 2) / 3.0);
          Color plasmaColor;
          if (wave > 0.5) {
            plasmaColor = palette.colors[3]; // Glow
          } else if (wave > 0.0) {
            plasmaColor = palette.primary;
          } else {
            plasmaColor = palette.secondary;
          }
          pixels[y * width + x] = addNoise(plasmaColor, random, 0.1);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// HAZARD AND WARNING TILES
// ============================================================================

/// Hazard stripes tile
class HazardStripesTile extends TileBase {
  final bool diagonal;
  final TilePalette hazardPalette;

  HazardStripesTile(super.id, {this.diagonal = true, this.hazardPalette = SciFiPalettes.warning});

  @override
  String get name => 'Hazard Stripes';
  @override
  String get description => 'Warning/hazard stripe pattern';
  @override
  String get iconName => 'warning';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => hazardPalette;
  @override
  List<String> get tags => ['hazard', 'warning', 'stripes', 'danger', 'caution'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final stripeWidth = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int stripeIndex;
        if (diagonal) {
          stripeIndex = ((x + y) ~/ stripeWidth) % 2;
        } else {
          stripeIndex = (x ~/ stripeWidth) % 2;
        }

        final color = stripeIndex == 0 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(color, random, 0.02);
      }
    }

    return pixels;
  }
}

/// Radioactive/biohazard warning tile
class BiohazardTile extends TileBase {
  BiohazardTile(super.id);

  @override
  String get name => 'Biohazard';
  @override
  String get description => 'Biohazard warning symbol';
  @override
  String get iconName => 'coronavirus';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => SciFiPalettes.neonGreen;
  @override
  List<String> get tags => ['biohazard', 'warning', 'toxic', 'danger', 'radiation'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dark background
    final bgColor = const Color(0xFF1A1A0A);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = addNoise(bgColor, random, 0.02);
    }

    // Draw simplified biohazard symbol
    final cx = width ~/ 2;
    final cy = height ~/ 2;
    final radius = min(width, height) ~/ 3;

    // Three circles around center
    for (int angle = 0; angle < 3; angle++) {
      final a = angle * 2.0944; // 120 degrees in radians
      final ox = cx + (radius * 0.6 * cos(a)).round();
      final oy = cy + (radius * 0.6 * sin(a)).round();

      // Draw small circle
      for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
          if (dx * dx + dy * dy <= 4) {
            final px = ox + dx;
            final py = oy + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              pixels[py * width + px] = colorToInt(palette.primary);
            }
          }
        }
      }
    }

    // Center circle
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final px = cx + dx;
        final py = cy + dy;
        if (px >= 0 && px < width && py >= 0 && py < height) {
          pixels[py * width + px] = colorToInt(palette.colors[3]);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// SPACE AND WINDOW TILES
// ============================================================================

/// Space window / viewport tile
class SpaceWindowTile extends TileBase {
  final bool addStars;

  SpaceWindowTile(super.id, {this.addStars = true});

  @override
  String get name => 'Space Window';
  @override
  String get description => 'Spaceship viewport/window';
  @override
  String get iconName => 'panorama';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => SciFiPalettes.metalHull;
  @override
  List<String> get tags => ['window', 'viewport', 'space', 'spaceship', 'stars'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Draw frame
    final frameWidth = 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isFrame = x < frameWidth || x >= width - frameWidth || y < frameWidth || y >= height - frameWidth;

        if (isFrame) {
          final edge = x == 0 || y == 0;
          pixels[y * width + x] = colorToInt(edge ? palette.shadow : palette.primary);
        } else {
          // Space background
          pixels[y * width + x] = colorToInt(const Color(0xFF050510));
        }
      }
    }

    // Add stars
    if (addStars) {
      final starCount = (width * height * 0.02).round();
      for (int s = 0; s < starCount; s++) {
        final sx = random.nextInt(width - 4) + 2;
        final sy = random.nextInt(height - 4) + 2;
        final brightness = random.nextInt(3);

        Color starColor;
        if (brightness == 0) {
          starColor = const Color(0xFF666666);
        } else if (brightness == 1) {
          starColor = const Color(0xFFAAAAAA);
        } else {
          starColor = const Color(0xFFFFFFFF);
        }
        pixels[sy * width + sx] = colorToInt(starColor);
      }
    }

    return pixels;
  }
}

/// Holographic display tile
class SciFiHologramTile extends TileBase {
  SciFiHologramTile(super.id);

  @override
  String get name => 'Hologram';
  @override
  String get description => 'Holographic display effect';
  @override
  String get iconName => 'blur_on';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => SciFiPalettes.holographic;
  @override
  List<String> get tags => ['hologram', 'display', 'projection', 'tech', 'futuristic'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Scanline effect
        final scanline = (y + frameIndex) % 3 == 0;

        // Color cycling
        final colorIndex = ((x + y + frameIndex * 2) ~/ 4) % palette.colors.length;
        var color = palette.colors[colorIndex];

        if (scanline) {
          // Darken scanlines
          color = Color.fromARGB(
            200,
            (color.red * 0.7).round(),
            (color.green * 0.7).round(),
            (color.blue * 0.7).round(),
          );
        }

        // Add noise/glitch
        if (random.nextDouble() > 0.95) {
          color = const Color(0xFFFFFFFF);
        }

        pixels[y * width + x] = (color.alpha << 24) | (color.red << 16) | (color.green << 8) | color.blue;
      }
    }

    return pixels;
  }
}

// ============================================================================
// MECHANICAL TILES
// ============================================================================

/// Gear/cog pattern tile
class GearTile extends TileBase {
  final TilePalette metalPalette;

  GearTile(super.id, {this.metalPalette = SciFiPalettes.brushedSteel});

  @override
  String get name => 'Gear';
  @override
  String get description => 'Mechanical gear pattern';
  @override
  String get iconName => 'settings';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => metalPalette;
  @override
  List<String> get tags => ['gear', 'cog', 'mechanical', 'machine', 'steampunk'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Background
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = addNoise(palette.shadow, random, 0.02);
      }
    }

    // Draw gear
    final cx = width ~/ 2;
    final cy = height ~/ 2;
    final outerRadius = min(width, height) ~/ 2 - 1;
    final innerRadius = outerRadius - 2;
    final holeRadius = innerRadius ~/ 2;
    const teeth = 8;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final angle = atan2(dy.toDouble(), dx.toDouble());

        // Tooth pattern
        final toothAngle = (angle * teeth / (2 * pi) + 0.5).floor() % 2 == 0;
        final effectiveOuter = toothAngle ? outerRadius : innerRadius;

        if (dist <= effectiveOuter && dist >= holeRadius) {
          // Metal part
          final isEdge = dist >= effectiveOuter - 1 || dist <= holeRadius + 1;
          if (isEdge) {
            pixels[y * width + x] = colorToInt(palette.highlight);
          } else {
            pixels[y * width + x] = addNoise(palette.primary, random, 0.03);
          }
        }
      }
    }

    // Center axle
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final px = cx + dx;
        final py = cy + dy;
        if (px >= 0 && px < width && py >= 0 && py < height) {
          pixels[py * width + px] = colorToInt(palette.shadow);
        }
      }
    }

    return pixels;
  }
}

/// Vent/air duct tile
class VentTile extends TileBase {
  final bool horizontal;
  final TilePalette metalPalette;

  VentTile(super.id, {this.horizontal = true, this.metalPalette = SciFiPalettes.darkMetal});

  @override
  String get name => 'Vent';
  @override
  String get description => 'Ventilation grate';
  @override
  String get iconName => 'air';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => metalPalette;
  @override
  List<String> get tags => ['vent', 'ventilation', 'air', 'grate', 'duct'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dark background (inside duct)
    final bgColor = const Color(0xFF0A0A0A);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(bgColor);
    }

    // Frame
    for (int i = 0; i < width; i++) {
      pixels[i] = colorToInt(palette.primary);
      pixels[(height - 1) * width + i] = colorToInt(palette.primary);
    }
    for (int i = 0; i < height; i++) {
      pixels[i * width] = colorToInt(palette.primary);
      pixels[i * width + width - 1] = colorToInt(palette.primary);
    }

    // Slats
    if (horizontal) {
      for (int y = 2; y < height - 2; y += 3) {
        for (int x = 1; x < width - 1; x++) {
          pixels[y * width + x] = addNoise(palette.secondary, random, 0.02);
          // Highlight on top edge
          if (y > 0) {
            pixels[(y - 1) * width + x] = colorToInt(palette.highlight);
          }
        }
      }
    } else {
      for (int x = 2; x < width - 2; x += 3) {
        for (int y = 1; y < height - 1; y++) {
          pixels[y * width + x] = addNoise(palette.secondary, random, 0.02);
          // Highlight on left edge
          if (x > 0) {
            pixels[y * width + x - 1] = colorToInt(palette.highlight);
          }
        }
      }
    }

    return pixels;
  }
}

/// Pipe tile
class PipeTile extends TileBase {
  final bool vertical;
  final TilePalette pipePalette;
  final bool addRust;

  PipeTile(super.id, {this.vertical = true, this.pipePalette = SciFiPalettes.brushedSteel, this.addRust = false});

  @override
  String get name => 'Pipe';
  @override
  String get description => 'Industrial pipe';
  @override
  String get iconName => 'linear_scale';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => pipePalette;
  @override
  List<String> get tags => ['pipe', 'tube', 'industrial', 'plumbing'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Background
    final bgColor = const Color(0xFF1A1A1A);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(bgColor);
    }

    // Draw pipe
    final pipeWidth = (vertical ? width : height) * 0.6;
    final pipeStart = ((vertical ? width : height) - pipeWidth) ~/ 2;
    final pipeEnd = pipeStart + pipeWidth.round();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pos = vertical ? x : y;

        if (pos >= pipeStart && pos < pipeEnd) {
          // Inside pipe
          final pipePos = (pos - pipeStart) / pipeWidth;
          final curve = sin(pipePos * pi);

          Color pipeColor;
          if (curve > 0.9) {
            pipeColor = palette.highlight;
          } else if (curve > 0.6) {
            pipeColor = palette.primary;
          } else if (curve > 0.3) {
            pipeColor = palette.secondary;
          } else {
            pipeColor = palette.shadow;
          }

          pixels[y * width + x] = addNoise(pipeColor, random, 0.02);
        }
      }
    }

    // Add rust patches
    if (addRust || variation == TileVariation.weathered) {
      final rustPalette = SciFiPalettes.rustyMetal;
      final rustPatches = random.nextInt(3) + 1;
      for (int r = 0; r < rustPatches; r++) {
        final rx = random.nextInt(width - 3) + 1;
        final ry = random.nextInt(height - 3) + 1;
        for (int dy = 0; dy < 3; dy++) {
          for (int dx = 0; dx < 2; dx++) {
            if (rx + dx < width && ry + dy < height) {
              final idx = (ry + dy) * width + rx + dx;
              if (pixels[idx] != colorToInt(bgColor)) {
                pixels[idx] = addNoise(rustPalette.primary, random, 0.05);
              }
            }
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// LIGHT AND GLOW TILES
// ============================================================================

/// Neon light strip tile
class NeonStripTile extends TileBase {
  final TilePalette neonPalette;
  final bool vertical;

  NeonStripTile(super.id, {this.neonPalette = SciFiPalettes.neonCyan, this.vertical = false});

  @override
  String get name => 'Neon Strip';
  @override
  String get description => 'Neon light strip';
  @override
  String get iconName => 'light';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => neonPalette;
  @override
  List<String> get tags => ['neon', 'light', 'glow', 'strip', 'cyberpunk'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 2;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final pixels = Uint32List(width * height);

    // Dark background
    final bgColor = const Color(0xFF0A0A0A);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(bgColor);
    }

    // Neon strip position
    final stripPos = vertical ? width ~/ 2 : height ~/ 2;
    final stripWidth = 2;
    final glowRadius = 3;

    // Flicker effect
    final flicker = frameIndex == 1 ? 0.9 : 1.0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pos = vertical ? x : y;
        final dist = (pos - stripPos).abs();

        if (dist < stripWidth) {
          // Core neon
          final color = palette.primary;
          pixels[y * width + x] = colorToInt(Color.fromARGB(
            255,
            (color.red * flicker).round(),
            (color.green * flicker).round(),
            (color.blue * flicker).round(),
          ));
        } else if (dist < glowRadius) {
          // Glow
          final intensity = 1.0 - (dist - stripWidth) / (glowRadius - stripWidth);
          final glowColor = palette.colors[3];
          final alpha = (intensity * 150 * flicker).round().clamp(0, 255);
          pixels[y * width + x] = (alpha << 24) | (glowColor.red << 16) | (glowColor.green << 8) | glowColor.blue;
        }
      }
    }

    return pixels;
  }
}

/// LED panel tile
class LedPanelTile extends TileBase {
  final TilePalette ledPalette;
  final int gridSize;

  LedPanelTile(super.id, {this.ledPalette = SciFiPalettes.neonGreen, this.gridSize = 2});

  @override
  String get name => 'LED Panel';
  @override
  String get description => 'LED display panel';
  @override
  String get iconName => 'grid_3x3';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  TilePalette get palette => ledPalette;
  @override
  List<String> get tags => ['led', 'display', 'panel', 'lights', 'digital'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dark base
    final bgColor = const Color(0xFF0A0A0A);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(bgColor);
    }

    // Draw LED grid
    for (int y = 0; y < height; y += gridSize) {
      for (int x = 0; x < width; x += gridSize) {
        // Random brightness for each LED
        final brightness = random.nextDouble();
        Color ledColor;

        if (brightness > 0.8) {
          ledColor = palette.colors[3]; // Bright
        } else if (brightness > 0.5) {
          ledColor = palette.primary;
        } else if (brightness > 0.2) {
          ledColor = palette.colors[2];
        } else {
          ledColor = palette.shadow;
        }

        // Draw LED pixel(s)
        for (int dy = 0; dy < gridSize - 1 && y + dy < height; dy++) {
          for (int dx = 0; dx < gridSize - 1 && x + dx < width; dx++) {
            pixels[(y + dy) * width + x + dx] = colorToInt(ledColor);
          }
        }
      }
    }

    return pixels;
  }
}
