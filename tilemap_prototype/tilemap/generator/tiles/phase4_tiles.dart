import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// PHASE 4 TILE PALETTES
// ============================================================================

class Phase4Palettes {
  Phase4Palettes._();

  // --- Environmental ---

  static const volcanicAsh = TilePalette(
    name: 'Volcanic Ash',
    colors: [
      Color(0xFF7A7570), // Base ash gray
      Color(0xFF5A5550), // Dark ash
      Color(0xFF9A9590), // Light ash
      Color(0xFFFF4400), // Hot crack glow
      Color(0xFF3A3530), // Deep shadow
    ],
  );

  static const quicksand = TilePalette(
    name: 'Quicksand',
    colors: [
      Color(0xFFD4B896), // Sandy tan
      Color(0xFFB89870), // Darker tan
      Color(0xFFE4C8A6), // Light sand
      Color(0xFF9A7850), // Wet edge
      Color(0xFFC8A880), // Mid tone
    ],
  );

  static const tundra = TilePalette(
    name: 'Tundra',
    colors: [
      Color(0xFF8AA0A8), // Frozen gray-blue
      Color(0xFF6A8090), // Dark frozen
      Color(0xFFAAC0C8), // Ice highlight
      Color(0xFF607080), // Permafrost crack
      Color(0xFF4A6070), // Deep shadow
    ],
  );

  static const mudFlat = TilePalette(
    name: 'Mud Flat',
    colors: [
      Color(0xFF6A5840), // Wet mud brown
      Color(0xFF7A6850), // Mid mud
      Color(0xFF503828), // Dark wet mud
      Color(0xFF8A7860), // Dry edge
      Color(0xFF403020), // Deep mud shadow
    ],
  );

  static const saltFlat = TilePalette(
    name: 'Salt Flat',
    colors: [
      Color(0xFFEEEBE0), // White salt
      Color(0xFFD8D4C8), // Off-white
      Color(0xFFF8F6F0), // Bright crystal
      Color(0xFFB8B4A8), // Crack line
      Color(0xFFCCCAC0), // Shadow
    ],
  );

  static const meteorCrater = TilePalette(
    name: 'Meteor Crater',
    colors: [
      Color(0xFF4A3830), // Scorched dark
      Color(0xFF6A5840), // Crater edge
      Color(0xFF2A1A10), // Burn center
      Color(0xFF8A6840), // Outer rim
      Color(0xFFFF8800), // Ember glow
    ],
  );

  static const fossilBed = TilePalette(
    name: 'Fossil Bed',
    colors: [
      Color(0xFFB8A888), // Sandy stone
      Color(0xFF988870), // Rock base
      Color(0xFFD8C8A8), // Fossil highlight
      Color(0xFF787060), // Dark stone
      Color(0xFFE8D8B8), // Bone white
    ],
  );

  // --- Mechanical / Industrial ---

  static const steamPipe = TilePalette(
    name: 'Steam Pipe',
    colors: [
      Color(0xFF787878), // Metal gray
      Color(0xFF585858), // Dark metal
      Color(0xFF989898), // Highlight
      Color(0xFFE0E0E0), // Steam white
      Color(0xFFB87840), // Rust/copper accent
    ],
  );

  static const boilerPlate = TilePalette(
    name: 'Boiler Plate',
    colors: [
      Color(0xFF606060), // Iron base
      Color(0xFF404040), // Dark iron
      Color(0xFF808080), // Highlight
      Color(0xFFA05030), // Heat discoloration
      Color(0xFF303030), // Deep shadow
    ],
  );

  static const conveyorBelt = TilePalette(
    name: 'Conveyor Belt',
    colors: [
      Color(0xFF484848), // Belt dark rubber
      Color(0xFF686868), // Belt mid
      Color(0xFFFFCC00), // Arrow yellow
      Color(0xFF303030), // Shadow gap
      Color(0xFF808080), // Metal trim
    ],
  );

  static const electricFloor = TilePalette(
    name: 'Electric Floor',
    colors: [
      Color(0xFF303048), // Dark base
      Color(0xFF484860), // Mid blue-gray
      Color(0xFF00AAFF), // Electric blue
      Color(0xFFCCEEFF), // Spark white
      Color(0xFF2040A0), // Deep glow
    ],
  );

  static const hydraulicPiston = TilePalette(
    name: 'Hydraulic Piston',
    colors: [
      Color(0xFF686868), // Cylinder metal
      Color(0xFF484848), // Dark metal
      Color(0xFF909090), // Highlight
      Color(0xFF4878A8), // Hydraulic fluid blue
      Color(0xFFA86030), // Worn copper
    ],
  );

  static const catwalkFloor = TilePalette(
    name: 'Catwalk Floor',
    colors: [
      Color(0xFF707070), // Grating metal
      Color(0xFF505050), // Dark grating
      Color(0xFF909090), // Highlight bar
      Color(0xFF181818), // Void below
      Color(0xFF585858), // Mid bar
    ],
  );

  static const fuelDrum = TilePalette(
    name: 'Fuel Drum',
    colors: [
      Color(0xFF3A6A30), // Drum green
      Color(0xFF284820), // Dark green
      Color(0xFF5A8A50), // Light green
      Color(0xFFFFCC00), // Hazard yellow
      Color(0xFF181810), // Shadow
    ],
  );

  // --- Nature ---

  static const bambooGround = TilePalette(
    name: 'Bamboo Ground',
    colors: [
      Color(0xFF8A9A60), // Bamboo green-yellow
      Color(0xFF6A7A40), // Dark bamboo
      Color(0xFFAABA80), // Light bamboo
      Color(0xFF786040), // Shadow ground
      Color(0xFF5A6830), // Deep bamboo
    ],
  );

  static const mossMat = TilePalette(
    name: 'Moss Mat',
    colors: [
      Color(0xFF4A6830), // Deep moss green
      Color(0xFF3A5820), // Dark moss
      Color(0xFF6A8848), // Light moss
      Color(0xFF587040), // Mid moss
      Color(0xFF283818), // Shadow
    ],
  );

  static const leafLitter = TilePalette(
    name: 'Leaf Litter',
    colors: [
      Color(0xFFC87820), // Autumn orange
      Color(0xFFA85010), // Dark autumn
      Color(0xFFE89830), // Yellow leaf
      Color(0xFF886820), // Brown leaf
      Color(0xFF487028), // Green leaf
    ],
  );

  static const rootNetwork = TilePalette(
    name: 'Root Network',
    colors: [
      Color(0xFF785840), // Root brown
      Color(0xFF583818), // Dark root
      Color(0xFF986850), // Light root
      Color(0xFF7A6850), // Dirt base
      Color(0xFF503828), // Dark dirt
    ],
  );

  static const thornyBrush = TilePalette(
    name: 'Thorny Brush',
    colors: [
      Color(0xFF384828), // Dark branch
      Color(0xFF283018), // Very dark
      Color(0xFF284818), // Deep green leaf
      Color(0xFF586838), // Branch mid
      Color(0xFFD0C890), // Thorn light
    ],
  );

  static const seagrass = TilePalette(
    name: 'Seagrass',
    colors: [
      Color(0xFF287858), // Deep seagrass green
      Color(0xFF185848), // Dark water
      Color(0xFF489870), // Light seagrass
      Color(0xFF104838), // Water shadow
      Color(0xFF38A870), // Bright grass tip
    ],
  );
}

// ============================================================================
// ENVIRONMENTAL TERRAIN TILES
// ============================================================================

/// Gray porous volcanic ash ground with hot glowing cracks
class VolcanicAshTile extends TileBase {
  VolcanicAshTile(super.id);

  @override
  String get name => 'Volcanic Ash';
  @override
  String get description => 'Gray porous volcanic ash with faintly glowing cracks';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'whatshot';
  @override
  TilePalette get palette => Phase4Palettes.volcanicAsh;
  @override
  List<String> get tags => ['volcanic', 'ash', 'lava', 'terrain', 'environmental'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base ash texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 2.5 + seed, y / 2.5, 4);
        Color c;
        if (n > 0.65) {
          c = palette.colors[2]; // light
        } else if (n > 0.35) {
          c = palette.primary; // base
        } else {
          c = palette.colors[1]; // dark
        }
        pixels[y * width + x] = addNoise(c, random, 0.07);
      }
    }

    // Porous holes
    for (int i = 0; i < (width * height) ~/ 20; i++) {
      final px = random.nextInt(width);
      final py = random.nextInt(height);
      pixels[py * width + px] = colorToInt(palette.colors[4]);
    }

    // Hot glowing cracks
    final crackCount = 3 + random.nextInt(3);
    for (int c = 0; c < crackCount; c++) {
      int cx = random.nextInt(width);
      int cy = random.nextInt(height);
      final length = 4 + random.nextInt(6);
      for (int s = 0; s < length; s++) {
        if (cx >= 0 && cx < width && cy >= 0 && cy < height) {
          pixels[cy * width + cx] = colorToInt(palette.colors[3]); // glow
        }
        cx += random.nextInt(3) - 1;
        cy += random.nextInt(3) - 1;
        cx = cx.clamp(0, width - 1);
        cy = cy.clamp(0, height - 1);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Sandy ground with slow-sink ripples indicating quicksand
class QuicksandTile extends TileBase {
  QuicksandTile(super.id);

  @override
  String get name => 'Quicksand';
  @override
  String get description => 'Treacherous sandy ground with subtle sink ripples';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'blur_on';
  @override
  TilePalette get palette => Phase4Palettes.quicksand;
  @override
  List<String> get tags => ['quicksand', 'sand', 'hazard', 'terrain'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Sandy base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.0 + seed, y / 3.0, 3);
        Color c;
        if (n > 0.6) {
          c = palette.colors[2];
        } else if (n > 0.3) {
          c = palette.primary;
        } else {
          c = palette.colors[1];
        }
        pixels[y * width + x] = addNoise(c, random, 0.06);
      }
    }

    // Concentric ripple rings around center
    final cx = width ~/ 2;
    final cy = height ~/ 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dist = ((x - cx).toDouble().abs() + (y - cy).toDouble().abs());
        if (dist.toInt() % 4 == 0) {
          final base = pixels[y * width + x];
          final alpha = (base >> 24) & 0xFF;
          final r = (base >> 16) & 0xFF;
          final g = (base >> 8) & 0xFF;
          final b = base & 0xFF;
          pixels[y * width + x] =
              (alpha << 24) | (((r * 0.88).toInt()) << 16) | (((g * 0.85).toInt()) << 8) | (b * 0.80).toInt();
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Frozen bare ground with permafrost crack network
class TundraTile extends TileBase {
  TundraTile(super.id);

  @override
  String get name => 'Tundra';
  @override
  String get description => 'Frozen bare ground with permafrost polygon cracks';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'ac_unit';
  @override
  TilePalette get palette => Phase4Palettes.tundra;
  @override
  List<String> get tags => ['tundra', 'frozen', 'ice', 'terrain', 'arctic'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Frozen ground base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 4.0 + seed, y / 4.0, 3);
        Color c;
        if (n > 0.6) {
          c = palette.colors[2]; // ice highlight
        } else if (n > 0.3) {
          c = palette.primary;
        } else {
          c = palette.colors[1];
        }
        pixels[y * width + x] = addNoise(c, random, 0.05);
      }
    }

    // Permafrost polygon cracks - draw grid lines with slight offset
    final cellSize = width ~/ 3;
    for (int row = 0; row <= 3; row++) {
      for (int col = 0; col < width; col++) {
        final y = (row * cellSize + random.nextInt(3) - 1).clamp(0, height - 1);
        if (y >= 0 && y < height) {
          pixels[y * width + col] = colorToInt(palette.colors[3]);
        }
      }
    }
    for (int col = 0; col <= 3; col++) {
      for (int row = 0; row < height; row++) {
        final x = (col * cellSize + random.nextInt(3) - 1).clamp(0, width - 1);
        if (x >= 0 && x < width) {
          pixels[row * width + x] = colorToInt(palette.colors[3]);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Wet gray-brown mud flat with subtle footprint impressions
class MudFlatTile extends TileBase {
  MudFlatTile(super.id);

  @override
  String get name => 'Mud Flat';
  @override
  String get description => 'Wet gray-brown muddy ground with footprint impressions';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'water';
  @override
  TilePalette get palette => Phase4Palettes.mudFlat;
  @override
  List<String> get tags => ['mud', 'wet', 'swamp', 'terrain'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Wet mud base with varied wetness
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.5 + seed, y / 3.5, 3);
        Color c;
        if (n > 0.65) {
          c = palette.colors[3]; // dry edge
        } else if (n > 0.4) {
          c = palette.secondary;
        } else {
          c = palette.primary;
        }
        pixels[y * width + x] = addNoise(c, random, 0.06);
      }
    }

    // Footprint impressions (oval dents)
    final printCount = 2 + random.nextInt(2);
    for (int i = 0; i < printCount; i++) {
      final px = 2 + random.nextInt(width - 6);
      final py = 2 + random.nextInt(height - 6);
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
          final fx = px + dx;
          final fy = py + dy;
          if (fx >= 0 && fx < width && fy >= 0 && fy < height) {
            pixels[fy * width + fx] = colorToInt(palette.colors[4]);
          }
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// White cracked salt flat with crystalline edges
class SaltFlatTile extends TileBase {
  SaltFlatTile(super.id);

  @override
  String get name => 'Salt Flat';
  @override
  String get description => 'Blinding white salt flat with crystalline crack edges';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'brightness_7';
  @override
  TilePalette get palette => Phase4Palettes.saltFlat;
  @override
  List<String> get tags => ['salt', 'desert', 'flat', 'terrain', 'arid'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Bright white base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 5.0 + seed, y / 5.0, 2);
        Color c;
        if (n > 0.6) {
          c = palette.colors[2]; // bright
        } else {
          c = palette.primary;
        }
        pixels[y * width + x] = addNoise(c, random, 0.03);
      }
    }

    // Polygon crack network
    final cellW = width ~/ 3;
    final cellH = height ~/ 3;
    for (int row = 0; row <= 3; row++) {
      for (int x = 0; x < width; x++) {
        final y = (row * cellH + random.nextInt(2)).clamp(0, height - 1);
        pixels[y * width + x] = colorToInt(palette.colors[3]);
      }
    }
    for (int col = 0; col <= 3; col++) {
      for (int y = 0; y < height; y++) {
        final x = (col * cellW + random.nextInt(2)).clamp(0, width - 1);
        pixels[y * width + x] = colorToInt(palette.colors[3]);
      }
    }

    // Crystal sparkle highlights along cracks
    for (int i = 0; i < 10; i++) {
      final px = random.nextInt(width);
      final py = random.nextInt(height);
      pixels[py * width + px] = colorToInt(palette.colors[2]);
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Circular blast impact pattern with scorched radial edges
class MeteorCraterTile extends TileBase {
  MeteorCraterTile(super.id);

  @override
  String get name => 'Meteor Crater';
  @override
  String get description => 'Circular impact crater with scorched radial blast pattern';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'flare';
  @override
  TilePalette get palette => Phase4Palettes.meteorCrater;
  @override
  List<String> get tags => ['crater', 'meteor', 'scorched', 'terrain', 'impact'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final cx = width / 2.0;
    final cy = height / 2.0;
    final maxDist = (cx < cy ? cx : cy);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = (dx * dx + dy * dy).toDouble();
        final normDist = (dist / (maxDist * maxDist)).clamp(0.0, 1.0);
        final n = noise2D(x / 2.0 + seed, y / 2.0, 3) * 0.2;

        Color c;
        if (normDist < 0.12) {
          c = palette.colors[2]; // black burn center
        } else if (normDist < 0.35) {
          c = palette.primary; // dark scorch
        } else if (normDist < 0.65) {
          c = palette.colors[1]; // crater edge
        } else {
          c = palette.colors[3]; // outer rim
        }

        pixels[y * width + x] = addNoise(c, random, 0.08 + n);
      }
    }

    // Ember glow ring
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = (dx * dx + dy * dy).toDouble();
        final normDist = (dist / (maxDist * maxDist)).clamp(0.0, 1.0);
        if (normDist > 0.30 && normDist < 0.38 && random.nextDouble() < 0.15) {
          pixels[y * width + x] = colorToInt(palette.colors[4]);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Sedimentary rock with embedded fossil outlines
class FossilBedTile extends TileBase {
  FossilBedTile(super.id);

  @override
  String get name => 'Fossil Bed';
  @override
  String get description => 'Sedimentary stone with embedded shell and bone fossil shapes';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'texture';
  @override
  TilePalette get palette => Phase4Palettes.fossilBed;
  @override
  List<String> get tags => ['fossil', 'stone', 'ancient', 'terrain'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Sedimentary layered base
    for (int y = 0; y < height; y++) {
      final layerN = noise2D(y / 4.0 + seed, 0, 2);
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.0 + seed, y / 3.0, 3) * 0.3 + layerN * 0.7;
        Color c;
        if (n > 0.6) {
          c = palette.colors[2];
        } else if (n > 0.3) {
          c = palette.primary;
        } else {
          c = palette.colors[1];
        }
        pixels[y * width + x] = addNoise(c, random, 0.06);
      }
    }

    // Fossil shapes: simple arcs/ovals
    final fossilCount = 2 + random.nextInt(3);
    for (int f = 0; f < fossilCount; f++) {
      final fx = 3 + random.nextInt(width - 6);
      final fy = 3 + random.nextInt(height - 6);
      final fw = 3 + random.nextInt(4);
      final fh = 2 + random.nextInt(3);
      // Draw oval outline
      for (int dy = -fh; dy <= fh; dy++) {
        for (int dx = -fw; dx <= fw; dx++) {
          final dist = (dx * dx).toDouble() / (fw * fw) + (dy * dy).toDouble() / (fh * fh);
          if (dist > 0.7 && dist < 1.3) {
            final px = fx + dx;
            final py = fy + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              pixels[py * width + px] = colorToInt(palette.colors[4]); // bone white
            }
          }
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

// ============================================================================
// MECHANICAL / INDUSTRIAL TILES
// ============================================================================

/// Metal pipe with steam vent openings
class SteamPipeTile extends TileBase {
  SteamPipeTile(super.id);

  @override
  String get name => 'Steam Pipe';
  @override
  String get description => 'Industrial metal pipe with pressurized steam vents';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  String get iconName => 'settings';
  @override
  TilePalette get palette => Phase4Palettes.steamPipe;
  @override
  List<String> get tags => ['steam', 'pipe', 'industrial', 'mechanical'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 200;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Background plate
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = addNoise(palette.colors[1], random, 0.05);
      }
    }

    // Horizontal pipe body
    final pipeY = height ~/ 2;
    final pipeR = height ~/ 5;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final distFromCenter = (y - pipeY).abs();
        if (distFromCenter <= pipeR) {
          final grad = 1.0 - distFromCenter / pipeR;
          Color c;
          if (grad > 0.7) {
            c = palette.colors[2]; // highlight
          } else if (grad > 0.3) {
            c = palette.primary;
          } else {
            c = palette.colors[1];
          }
          pixels[y * width + x] = addNoise(c, random, 0.04);
        }
      }
    }

    // Pipe joint rings
    for (int rx = width ~/ 4; rx < width; rx += width ~/ 4) {
      for (int y = pipeY - pipeR; y <= pipeY + pipeR; y++) {
        if (y >= 0 && y < height && rx < width) {
          pixels[y * width + rx] = colorToInt(palette.colors[1]);
          if (rx + 1 < width) pixels[y * width + rx + 1] = colorToInt(palette.colors[1]);
        }
      }
    }

    // Steam vent: cloud rises by frameIndex*2 pixels each frame
    final ventX = width ~/ 2;
    final steamOffset = frameIndex * 2;
    for (int y = pipeY - pipeR - 1; y >= 0; y--) {
      if (ventX >= 0 && ventX < width) {
        // Steam widens and fades as it rises
        final riseAmt = pipeY - pipeR - 1 - y;
        final spread = riseAmt ~/ 3;
        final opacity = 1.0 - riseAmt / (pipeY.toDouble());
        if (opacity <= 0) continue;
        // Offset the steam column upward per frame (wraps within the vent area)
        final effectiveY = (y - steamOffset).clamp(0, height - 1);
        for (int dx = -spread; dx <= spread + 1; dx++) {
          final px = (ventX + dx).clamp(0, width - 1);
          if (effectiveY < height) {
            pixels[effectiveY * width + px] = Color.lerp(
              palette.colors[3],
              palette.colors[1],
              1.0 - opacity,
            )!.withAlpha((255 * opacity).round()).value;
          }
        }
      }
    }

    // Rust accent on joints
    for (int i = 0; i < 4; i++) {
      final rx = random.nextInt(width);
      final ry = (pipeY + random.nextInt(pipeR * 2) - pipeR).clamp(0, height - 1);
      pixels[ry * width + rx] = colorToInt(palette.colors[4]);
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Riveted iron plates with heat discoloration
class BoilerPlateTile extends TileBase {
  BoilerPlateTile(super.id);

  @override
  String get name => 'Boiler Plate';
  @override
  String get description => 'Riveted iron boiler plate with heat discoloration';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  String get iconName => 'hardware';
  @override
  TilePalette get palette => Phase4Palettes.boilerPlate;
  @override
  List<String> get tags => ['boiler', 'iron', 'industrial', 'rivets', 'mechanical'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Iron base with noise
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 4.0 + seed, y / 4.0, 3);
        Color c;
        if (n > 0.6) {
          c = palette.colors[2];
        } else if (n > 0.3) {
          c = palette.primary;
        } else {
          c = palette.colors[1];
        }
        pixels[y * width + x] = addNoise(c, random, 0.07);
      }
    }

    // Heat discoloration gradient from bottom
    for (int y = height ~/ 2; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final heatFactor = (y - height / 2) / (height / 2);
        if (random.nextDouble() < heatFactor * 0.4) {
          pixels[y * width + x] = addNoise(palette.colors[3], random, 0.1);
        }
      }
    }

    // Rivets at corners of plate panels
    final panelW = width ~/ 2;
    final panelH = height ~/ 2;
    for (int row = 0; row <= 2; row++) {
      for (int col = 0; col <= 2; col++) {
        final rx = col * panelW - 1;
        final ry = row * panelH - 1;
        if (rx >= 0 && rx < width && ry >= 0 && ry < height) {
          pixels[ry * width + rx] = colorToInt(palette.colors[2]);
          if (rx + 1 < width && ry + 1 < height) {
            pixels[(ry + 1) * width + (rx + 1)] = colorToInt(palette.colors[4]);
          }
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Conveyor belt surface with directional arrow markings
class ConveyorBeltActiveTile extends TileBase {
  ConveyorBeltActiveTile(super.id);

  @override
  String get name => 'Conveyor Belt';
  @override
  String get description => 'Moving conveyor belt with directional arrow markings';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  String get iconName => 'arrow_forward';
  @override
  TilePalette get palette => Phase4Palettes.conveyorBelt;
  @override
  List<String> get tags => ['conveyor', 'belt', 'industrial', 'mechanical', 'moving'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 100;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Belt base with horizontal ridges
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        Color c;
        if (y % 3 == 0) {
          c = palette.colors[3]; // gap/shadow
        } else if (y % 3 == 1) {
          c = palette.primary;
        } else {
          c = palette.secondary;
        }
        pixels[y * width + x] = addNoise(c, random, 0.04);
      }
    }

    // Metal side trims
    for (int x = 0; x < width; x++) {
      pixels[0 * width + x] = colorToInt(palette.colors[4]);
      pixels[(height - 1) * width + x] = colorToInt(palette.colors[4]);
    }

    // Arrow markings scroll rightward by frameIndex * 2px per frame
    final arrowSpacing = (width / 2).round().clamp(6, 12);
    final arrowOffset = (frameIndex * 2) % arrowSpacing;
    for (int ax = arrowOffset; ax < width + arrowSpacing; ax += arrowSpacing) {
      final ay = height ~/ 2;
      // Arrow body
      for (int dx = -2; dx <= 1; dx++) {
        final px = ax + dx;
        if (px >= 0 && px < width && ay >= 0 && ay < height) {
          pixels[ay * width + px] = colorToInt(palette.colors[2]);
        }
      }
      // Arrow head
      for (int dy = -1; dy <= 1; dy++) {
        final px = ax + 2 - dy.abs();
        final py = ay + dy;
        if (px >= 0 && px < width && py >= 0 && py < height) {
          pixels[py * width + px] = colorToInt(palette.colors[2]);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Charged electric floor with arcing spark patterns
class ElectricFloorTile extends TileBase {
  ElectricFloorTile(super.id);

  @override
  String get name => 'Electric Floor';
  @override
  String get description => 'Charged electric floor with arcing sparks and glow';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'bolt';
  @override
  TilePalette get palette => Phase4Palettes.electricFloor;
  @override
  List<String> get tags => ['electric', 'charged', 'hazard', 'special', 'energy'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 80;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    // Use a frame-specific seed so sparks appear at different positions each frame
    final random = Random(seed + frameIndex * 997);
    final pixels = Uint32List(width * height);

    // Dark energized base (stable across frames — use base seed)
    final baseRng = Random(seed);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.0 + seed, y / 3.0, 3);
        Color c;
        if (n > 0.65) {
          c = palette.secondary;
        } else {
          c = palette.primary;
        }
        pixels[y * width + x] = addNoise(c, baseRng, 0.05);
      }
    }

    // Electric glow grid lines (fixed)
    final gridSize = width ~/ 4;
    for (int x = 0; x < width; x += gridSize) {
      for (int y = 0; y < height; y++) {
        if (x < width) {
          pixels[y * width + x] = colorToInt(palette.colors[2]);
        }
      }
    }
    for (int y = 0; y < height; y += gridSize) {
      for (int x = 0; x < width; x++) {
        if (y < height) {
          pixels[y * width + x] = colorToInt(palette.colors[2]);
        }
      }
    }

    // Spark arcs — different per frame due to frame-seeded RNG
    final sparkCount = 3 + random.nextInt(3);
    for (int s = 0; s < sparkCount; s++) {
      int sx = random.nextInt(width);
      int sy = random.nextInt(height);
      final length = 3 + random.nextInt(5);
      for (int i = 0; i < length; i++) {
        if (sx >= 0 && sx < width && sy >= 0 && sy < height) {
          pixels[sy * width + sx] = colorToInt(palette.colors[3]); // bright spark
        }
        sx += random.nextInt(3) - 1;
        sy += random.nextInt(3) - 1;
        sx = sx.clamp(0, width - 1);
        sy = sy.clamp(0, height - 1);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Hydraulic piston mechanism viewed from above
class HydraulicPistonTile extends TileBase {
  HydraulicPistonTile(super.id);

  @override
  String get name => 'Hydraulic Piston';
  @override
  String get description => 'Top-down view of a hydraulic piston cylinder mechanism';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  String get iconName => 'arrow_upward';
  @override
  TilePalette get palette => Phase4Palettes.hydraulicPiston;
  @override
  List<String> get tags => ['hydraulic', 'piston', 'mechanical', 'industrial'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Metal plate background
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = addNoise(palette.colors[1], random, 0.06);
      }
    }

    final cx = width / 2.0;
    final cy = height / 2.0;

    // Outer cylinder ring
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = (dx * dx + dy * dy).toDouble();
        final outerR = (cx * 0.8) * (cx * 0.8);
        final innerR = (cx * 0.55) * (cx * 0.55);
        if (dist <= outerR && dist > innerR) {
          pixels[y * width + x] = addNoise(palette.primary, random, 0.05);
        } else if (dist <= innerR) {
          // Hydraulic fluid center
          pixels[y * width + x] = addNoise(palette.colors[3], random, 0.04);
        }
      }
    }

    // Highlight arc on cylinder
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = (dx * dx + dy * dy).toDouble();
        final outerR = (cx * 0.8) * (cx * 0.8);
        final outerR2 = (cx * 0.7) * (cx * 0.7);
        if (dist <= outerR && dist > outerR2 && dy < 0) {
          pixels[y * width + x] = colorToInt(palette.colors[2]);
        }
      }
    }

    // Bolt holes at cardinal positions around periphery
    const boltOffsetsX = [0.0, 1.0, 0.0, -1.0];
    const boltOffsetsY = [-1.0, 0.0, 1.0, 0.0];
    for (int b = 0; b < 4; b++) {
      final bxC = (cx + (cx * 0.9) * boltOffsetsX[b]).round();
      final byC = (cy + (cy * 0.9) * boltOffsetsY[b]).round();
      if (bxC >= 0 && bxC < width && byC >= 0 && byC < height) {
        pixels[byC * width + bxC] = colorToInt(palette.colors[1]);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Industrial catwalk floor grating with depth shadow below
class CatwalkFloorTile extends TileBase {
  CatwalkFloorTile(super.id);

  @override
  String get name => 'Catwalk Floor';
  @override
  String get description => 'Metal grating catwalk with shadow depth visible below';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  String get iconName => 'grid_on';
  @override
  TilePalette get palette => Phase4Palettes.catwalkFloor;
  @override
  List<String> get tags => ['catwalk', 'grating', 'industrial', 'metal', 'floor'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Void/depth below
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.colors[3]);
    }

    // Grating bars (horizontal strips with gaps)
    final barH = 2;
    final gapH = 2;
    for (int y = 0; y < height; y += barH + gapH) {
      for (int dy = 0; dy < barH; dy++) {
        final py = y + dy;
        if (py >= height) break;
        for (int x = 0; x < width; x++) {
          Color c;
          if (dy == 0) {
            c = palette.colors[2]; // top highlight
          } else {
            c = palette.primary;
          }
          pixels[py * width + x] = addNoise(c, random, 0.05);
        }
      }
    }

    // Vertical cross-bars
    for (int x = 0; x < width; x += 4) {
      for (int y = 0; y < height; y++) {
        final barRow = y % (barH + gapH);
        if (barRow < barH) {
          // already bar - add vertical cross
        } else {
          // in gap - add thin cross bar
          if (x < width) {
            pixels[y * width + x] = colorToInt(palette.colors[4]);
          }
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Cylindrical metal fuel drum with hazard stripe markings
class FuelDrumTile extends TileBase {
  FuelDrumTile(super.id);

  @override
  String get name => 'Fuel Drum';
  @override
  String get description => 'Metal fuel barrel with hazard yellow stripe markings';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  String get iconName => 'local_gas_station';
  @override
  TilePalette get palette => Phase4Palettes.fuelDrum;
  @override
  List<String> get tags => ['fuel', 'barrel', 'industrial', 'hazard', 'drum'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Background floor
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = addNoise(palette.colors[4], random, 0.05);
    }

    final cx = width / 2.0;
    final cy = height / 2.0;
    final rx = width * 0.38;
    final ry = height * 0.45;

    // Draw drum oval (top-down cylinder)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / rx;
        final dy = (y - cy) / ry;
        final dist = dx * dx + dy * dy;
        if (dist <= 1.0) {
          // Color gradient for cylinder curve
          final grad = 1.0 - dx.abs();
          Color c;
          if (grad > 0.8) {
            c = palette.colors[2]; // highlight
          } else if (grad > 0.3) {
            c = palette.primary;
          } else {
            c = palette.colors[1];
          }
          pixels[y * width + x] = addNoise(c, random, 0.05);
        }
      }
    }

    // Hazard stripe band in the middle
    final stripeY1 = (cy - ry * 0.2).round();
    final stripeY2 = (cy + ry * 0.2).round();
    for (int y = stripeY1; y <= stripeY2; y++) {
      if (y < 0 || y >= height) continue;
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / rx;
        final dy = (y - cy) / ry;
        if (dx * dx + dy * dy <= 1.0) {
          // Alternating diagonal hazard stripes
          if ((x + y) % 6 < 3) {
            pixels[y * width + x] = colorToInt(palette.colors[3]); // yellow
          }
        }
      }
    }

    // Drum lid rim
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / rx;
        final dy = (y - cy) / ry;
        final dist = dx * dx + dy * dy;
        if (dist > 0.85 && dist <= 1.0) {
          pixels[y * width + x] = colorToInt(palette.colors[1]);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

// ============================================================================
// NATURE TILES
// ============================================================================

/// Ground-level bamboo shoot and shadow pattern
class BambooGroundTile extends TileBase {
  BambooGroundTile(super.id);

  @override
  String get name => 'Bamboo Ground';
  @override
  String get description => 'Ground with overhead bamboo shadows and emerging shoots';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'grass';
  @override
  TilePalette get palette => Phase4Palettes.bambooGround;
  @override
  List<String> get tags => ['bamboo', 'ground', 'forest', 'nature', 'asian'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Ground base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.0 + seed, y / 3.0, 3);
        Color c;
        if (n > 0.55) {
          c = palette.colors[2];
        } else {
          c = palette.colors[3];
        }
        pixels[y * width + x] = addNoise(c, random, 0.06);
      }
    }

    // Bamboo stalks (vertical columns)
    final stalkCount = 3 + random.nextInt(2);
    final spacing = width ~/ stalkCount;
    for (int s = 0; s < stalkCount; s++) {
      final sx = spacing ~/ 2 + s * spacing + random.nextInt(3) - 1;
      if (sx < 0 || sx >= width) continue;
      for (int y = 0; y < height; y++) {
        // Node segments
        final segment = y % (height ~/ 3);
        Color c;
        if (segment == 0 || segment == 1) {
          c = palette.colors[1]; // joint ring
        } else {
          c = palette.primary;
        }
        pixels[y * width + sx] = colorToInt(c);
        if (sx + 1 < width) pixels[y * width + sx + 1] = addNoise(palette.secondary, random, 0.04);
      }
    }

    // Fallen leaf litter on ground
    for (int i = 0; i < 6; i++) {
      final lx = random.nextInt(width);
      final ly = random.nextInt(height);
      pixels[ly * width + lx] = colorToInt(palette.colors[0]);
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Dense flat moss carpet with height variation texture
class MossMatTile extends TileBase {
  MossMatTile(super.id);

  @override
  String get name => 'Moss Mat';
  @override
  String get description => 'Dense flat carpet of moss with subtle height variation';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'eco';
  @override
  TilePalette get palette => Phase4Palettes.mossMat;
  @override
  List<String> get tags => ['moss', 'carpet', 'ground', 'nature', 'damp'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dense moss base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 2.0 + seed, y / 2.0, 5);
        Color c;
        if (n > 0.7) {
          c = palette.colors[2]; // light moss tip
        } else if (n > 0.45) {
          c = palette.primary;
        } else if (n > 0.2) {
          c = palette.secondary;
        } else {
          c = palette.colors[1]; // shadow base
        }
        pixels[y * width + x] = addNoise(c, random, 0.08);
      }
    }

    // Tiny moss "bumps" highlights
    for (int i = 0; i < (width * height) ~/ 10; i++) {
      final px = random.nextInt(width);
      final py = random.nextInt(height);
      pixels[py * width + px] = colorToInt(palette.colors[2]);
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Mixed autumn and green fallen leaves scattered on ground
class LeafLitterTile extends TileBase {
  LeafLitterTile(super.id);

  @override
  String get name => 'Leaf Litter';
  @override
  String get description => 'Scattered autumn and green fallen leaves on ground';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'park';
  @override
  TilePalette get palette => Phase4Palettes.leafLitter;
  @override
  List<String> get tags => ['leaves', 'autumn', 'ground', 'nature', 'forest floor'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dirt ground base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = addNoise(palette.colors[3], random, 0.07);
      }
    }

    // Scatter leaves of various colors
    final leafCount = 8 + random.nextInt(6);
    final leafColors = [
      palette.primary, // orange
      palette.colors[1], // dark autumn
      palette.colors[2], // yellow
      palette.colors[3], // brown
      palette.colors[4], // green
    ];
    for (int l = 0; l < leafCount; l++) {
      final lx = random.nextInt(width - 2) + 1;
      final ly = random.nextInt(height - 2) + 1;
      final lc = leafColors[random.nextInt(leafColors.length)];
      // Leaf as a small oval/diamond shape
      pixels[ly * width + lx] = colorToInt(lc);
      if (lx + 1 < width) pixels[ly * width + lx + 1] = colorToInt(lc);
      if (ly + 1 < height) pixels[(ly + 1) * width + lx] = colorToInt(lc);
      // Random rotation: sometimes extend diagonally
      if (random.nextBool()) {
        if (lx - 1 >= 0) pixels[ly * width + lx - 1] = addNoise(lc, random, 0.1);
      } else {
        if (ly - 1 >= 0) pixels[(ly - 1) * width + lx] = addNoise(lc, random, 0.1);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Tangled surface root network over dirt ground
class RootNetworkTile extends TileBase {
  RootNetworkTile(super.id);

  @override
  String get name => 'Root Network';
  @override
  String get description => 'Tangled web of surface roots over compacted dirt';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'account_tree';
  @override
  TilePalette get palette => Phase4Palettes.rootNetwork;
  @override
  List<String> get tags => ['roots', 'tree', 'ground', 'nature', 'forest'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dirt base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.0 + seed, y / 3.0, 3);
        Color c;
        if (n > 0.55) {
          c = palette.colors[3];
        } else {
          c = palette.colors[4];
        }
        pixels[y * width + x] = addNoise(c, random, 0.07);
      }
    }

    // Root network: random walk paths
    final rootCount = 4 + random.nextInt(3);
    for (int r = 0; r < rootCount; r++) {
      int rx = random.nextInt(width);
      int ry = random.nextInt(height);
      final length = 8 + random.nextInt(8);
      for (int step = 0; step < length; step++) {
        if (rx >= 0 && rx < width && ry >= 0 && ry < height) {
          pixels[ry * width + rx] = addNoise(palette.primary, random, 0.06);
          // Root shadow/depth beside it
          if (rx + 1 < width) {
            pixels[ry * width + rx + 1] = colorToInt(palette.colors[1]);
          }
        }
        // Branching walk
        final dir = random.nextInt(4);
        switch (dir) {
          case 0:
            rx++;
            break;
          case 1:
            rx--;
            break;
          case 2:
            ry++;
            break;
          case 3:
            ry--;
            break;
        }
        rx = rx.clamp(0, width - 1);
        ry = ry.clamp(0, height - 1);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Dense thorny shrub with spiky branch silhouette
class ThornyBrushTile extends TileBase {
  ThornyBrushTile(super.id);

  @override
  String get name => 'Thorny Brush';
  @override
  String get description => 'Dense thorny shrub with spiky protruding branches';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'spa';
  @override
  TilePalette get palette => Phase4Palettes.thornyBrush;
  @override
  List<String> get tags => ['thorns', 'brush', 'shrub', 'nature', 'hazard'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Transparent background
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    // Dense branch base fill
    for (int y = height ~/ 4; y < height; y++) {
      for (int x = 1; x < width - 1; x++) {
        final n = noise2D(x / 2.5 + seed, y / 2.5, 4);
        if (n > 0.3) {
          Color c;
          if (n > 0.65) {
            c = palette.colors[3]; // branch mid
          } else {
            c = palette.colors[1]; // dark branch
          }
          pixels[y * width + x] = addNoise(c, random, 0.08);
        }
      }
    }

    // Leafy clumps
    for (int i = 0; i < 8; i++) {
      final lx = 1 + random.nextInt(width - 2);
      final ly = height ~/ 4 + random.nextInt(height * 3 ~/ 4);
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final px = lx + dx;
          final py = ly + dy;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            pixels[py * width + px] = addNoise(palette.colors[2], random, 0.1);
          }
        }
      }
    }

    // Thorns (thin spikes)
    final thornCount = 8 + random.nextInt(6);
    for (int t = 0; t < thornCount; t++) {
      final tx = random.nextInt(width);
      final ty = random.nextInt(height ~/ 2);
      final len = 2 + random.nextInt(3);
      final dirX = random.nextInt(3) - 1;
      final dirY = -(1 + random.nextInt(2));
      for (int s = 0; s < len; s++) {
        final px = (tx + dirX * s).clamp(0, width - 1);
        final py = (ty + dirY * s).clamp(0, height - 1);
        pixels[py * width + px] = colorToInt(palette.colors[4]); // thorn light
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Underwater seagrass with flowing blade pattern
class SeagrassTile extends TileBase {
  SeagrassTile(super.id);

  @override
  String get name => 'Seagrass';
  @override
  String get description => 'Underwater seagrass meadow with flowing green blades';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'waves';
  @override
  TilePalette get palette => Phase4Palettes.seagrass;
  @override
  List<String> get tags => ['seagrass', 'underwater', 'ocean', 'nature', 'aquatic'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Water base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 4.0 + seed, y / 4.0, 3);
        Color c;
        if (n > 0.5) {
          c = palette.colors[1];
        } else {
          c = palette.colors[3];
        }
        pixels[y * width + x] = addNoise(c, random, 0.05);
      }
    }

    // Seagrass blades (curved stalks from bottom)
    final bladeCount = 4 + random.nextInt(4);
    for (int b = 0; b < bladeCount; b++) {
      int bx = random.nextInt(width);
      final sway = random.nextDouble() * 0.6 - 0.3; // curve direction
      final bladeH = height ~/ 2 + random.nextInt(height ~/ 3);
      for (int step = 0; step < bladeH; step++) {
        final by = height - 1 - step;
        bx = (bx + (sway * step / bladeH * 2).round()).clamp(0, width - 1);
        if (by >= 0 && by < height) {
          Color c;
          if (step < 3) {
            c = palette.colors[1]; // root
          } else if (step > bladeH - 3) {
            c = palette.colors[4]; // bright tip
          } else {
            c = palette.primary;
          }
          pixels[by * width + bx] = colorToInt(c);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}
