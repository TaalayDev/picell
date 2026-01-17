import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// SPECIALIZED TILE PALETTES
// ============================================================================

class SpecializedPalettes {
  SpecializedPalettes._();

  /// Portal/teleport palette
  static const portal = TilePalette(
    name: 'Portal',
    colors: [
      Color(0xFF6B3FA0), // Base purple
      Color(0xFF9B59B6), // Mid purple
      Color(0xFF8E44AD), // Dark purple
      Color(0xFFE8DAEF), // Light glow
      Color(0xFF2C003E), // Deep void
    ],
  );

  /// Neon/cyber palette
  static const neon = TilePalette(
    name: 'Neon',
    colors: [
      Color(0xFF0D0D0D), // Dark base
      Color(0xFF00FFFF), // Cyan neon
      Color(0xFFFF00FF), // Magenta neon
      Color(0xFFFFFF00), // Yellow accent
      Color(0xFF1A1A2E), // Dark blue
    ],
  );

  /// Arcane/runic palette
  static const arcane = TilePalette(
    name: 'Arcane',
    colors: [
      Color(0xFF1A1A3A), // Dark blue base
      Color(0xFF4A90D9), // Magic blue
      Color(0xFF7EC8E3), // Light magic
      Color(0xFFFFD700), // Golden rune
      Color(0xFF0A0A1A), // Shadow
    ],
  );

  /// Toxic/poison palette
  static const toxic = TilePalette(
    name: 'Toxic',
    colors: [
      Color(0xFF2A3A1A), // Dark green base
      Color(0xFF4AFF4A), // Bright toxic
      Color(0xFF7FFF00), // Lime green
      Color(0xFFBFFF00), // Yellow-green
      Color(0xFF1A2A0A), // Shadow
    ],
  );

  /// Void/darkness palette
  static const voidSpace = TilePalette(
    name: 'Void',
    colors: [
      Color(0xFF0A0A12), // Near black
      Color(0xFF1A1A2E), // Dark purple
      Color(0xFF2D2D4A), // Purple tint
      Color(0xFF6A5ACD), // Violet highlight
      Color(0xFF000005), // Deepest void
    ],
  );

  /// Hologram palette
  static const hologram = TilePalette(
    name: 'Hologram',
    colors: [
      Color(0x8800BFFF), // Semi-transparent cyan
      Color(0x8840E0D0), // Turquoise
      Color(0x88FFFFFF), // White highlight
      Color(0x660099FF), // Blue tint
      Color(0x44003366), // Shadow
    ],
  );

  /// Energy/power palette
  static const energy = TilePalette(
    name: 'Energy',
    colors: [
      Color(0xFFFFD700), // Gold base
      Color(0xFFFFA500), // Orange
      Color(0xFFFF6347), // Red-orange
      Color(0xFFFFFFE0), // Light yellow
      Color(0xFFB8860B), // Dark gold
    ],
  );

  /// Frost/ice magic palette
  static const frostMagic = TilePalette(
    name: 'Frost Magic',
    colors: [
      Color(0xFF87CEEB), // Sky blue
      Color(0xFFADD8E6), // Light blue
      Color(0xFFB0E0E6), // Powder blue
      Color(0xFFFFFFFF), // White
      Color(0xFF4682B4), // Steel blue
    ],
  );

  /// Shadow/dark magic palette
  static const shadowMagic = TilePalette(
    name: 'Shadow Magic',
    colors: [
      Color(0xFF2F2F4F), // Dark slate
      Color(0xFF483D8B), // Dark slate blue
      Color(0xFF191970), // Midnight blue
      Color(0xFF9370DB), // Medium purple
      Color(0xFF0D0D1A), // Almost black
    ],
  );

  /// Ember/fire magic palette
  static const emberMagic = TilePalette(
    name: 'Ember Magic',
    colors: [
      Color(0xFFFF4500), // Orange red
      Color(0xFFFF6600), // Dark orange
      Color(0xFFFFCC00), // Yellow
      Color(0xFFFFE4B5), // Light peach
      Color(0xFF8B0000), // Dark red
    ],
  );
}

// ============================================================================
// SPECIALIZED TILES BASE CLASS
// ============================================================================

/// Base class for specialized magical/interactive tiles
abstract class SpecializedTile extends TileBase {
  SpecializedTile(super.id);

  @override
  TileCategory get category => TileCategory.special;

  @override
  bool get supportsRotation => true;
}

// ============================================================================
// PORTAL TILES
// ============================================================================

/// Swirling portal effect tile
class PortalTile extends SpecializedTile {
  PortalTile(super.id, {this.portalColor = PortalColor.purple});

  final PortalColor portalColor;

  @override
  String get name => 'Portal ${portalColor.name.capitalize()}';

  @override
  String get description => 'Swirling magical portal';

  @override
  String get iconName => 'blur_circular';

  @override
  TilePalette get palette => portalColor.palette;

  @override
  List<String> get tags => ['special', 'portal', 'magic', 'teleport'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 8;

  @override
  int get frameSpeed => 100;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    final centerX = width / 2;
    final centerY = height / 2;
    final maxRadius = min(width, height) / 2 * 0.9;
    final rotation = (frameIndex / frameCount) * 2 * pi;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance > maxRadius) {
          pixels[y * width + x] = 0x00000000; // Transparent
          continue;
        }

        // Calculate angle and spiral pattern
        final angle = atan2(dy, dx) + rotation;
        final normalizedDist = distance / maxRadius;

        // Spiral arms
        final spiralArms = 3;
        final spiralAngle = angle + normalizedDist * 4 * pi;
        final spiralValue = (sin(spiralAngle * spiralArms) + 1) / 2;

        // Edge fade
        final edgeFade = 1 - pow(normalizedDist, 2);

        // Center glow
        final centerGlow = pow(1 - normalizedDist, 3);

        Color pixelColor;
        if (centerGlow > 0.7) {
          pixelColor = pal.highlight;
        } else if (spiralValue > 0.6) {
          pixelColor = Color.lerp(pal.primary, pal.secondary, normalizedDist)!;
        } else if (spiralValue > 0.3) {
          pixelColor = pal.accent;
        } else {
          pixelColor = pal.shadow;
        }

        // Apply edge fade
        final alpha = (255 * edgeFade * (0.7 + spiralValue * 0.3)).round().clamp(0, 255);
        pixelColor = pixelColor.withAlpha(alpha);

        // Add sparkles
        if (random.nextDouble() > 0.97 && normalizedDist < 0.8) {
          pixelColor = pal.highlight;
        }

        pixels[y * width + x] = colorToInt(pixelColor);
      }
    }

    return pixels;
  }
}

enum PortalColor {
  purple(SpecializedPalettes.portal),
  blue(TilePalettes.water),
  green(SpecializedPalettes.toxic),
  red(SpecializedPalettes.emberMagic);

  final TilePalette palette;
  const PortalColor(this.palette);
}

// ============================================================================
// RUNE/ARCANE TILES
// ============================================================================

/// Glowing rune circle tile
class RuneCircleTile extends SpecializedTile {
  RuneCircleTile(super.id, {this.runeStyle = RuneStyle.arcane});

  final RuneStyle runeStyle;

  @override
  String get name => 'Rune Circle ${runeStyle.name.capitalize()}';

  @override
  String get description => 'Magical rune circle inscribed in stone';

  @override
  String get iconName => 'trip_origin';

  @override
  TilePalette get palette => runeStyle.palette;

  @override
  List<String> get tags => ['special', 'rune', 'magic', 'arcane', 'circle'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 6;

  @override
  int get frameSpeed => 180;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    final centerX = width / 2;
    final centerY = height / 2;
    final maxRadius = min(width, height) / 2 * 0.9;
    final pulse = sin((frameIndex / frameCount) * 2 * pi) * 0.5 + 0.5;

    // Stone base
    final stoneColor = const Color(0xFF4A4A5A);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = addNoise(stoneColor, random, 0.1);
    }

    // Draw concentric circles
    final circleRadii = [0.9, 0.75, 0.5, 0.25];
    final circleThickness = max(1, (width / 16).round());

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = sqrt(dx * dx + dy * dy);
        final normalizedDist = distance / maxRadius;

        // Check if on a circle line
        for (int i = 0; i < circleRadii.length; i++) {
          final targetRadius = circleRadii[i];
          if ((normalizedDist - targetRadius).abs() < circleThickness / maxRadius) {
            final intensity = pulse * 0.5 + 0.5;
            final glowColor = Color.lerp(pal.primary, pal.highlight, intensity)!;
            pixels[y * width + x] = colorToInt(glowColor);
            break;
          }
        }

        // Draw rune symbols along middle circle
        final angle = atan2(dy, dx);
        if ((normalizedDist - 0.62).abs() < 0.08) {
          final runeSegment = ((angle + pi) / (2 * pi) * 8).floor() % 8;
          final segmentAngle = (angle + pi) % (pi / 4);
          if (segmentAngle < pi / 8 && runeSegment % 2 == 0) {
            final runeGlow = Color.lerp(pal.accent, pal.highlight, pulse)!;
            pixels[y * width + x] = colorToInt(runeGlow);
          }
        }
      }
    }

    return pixels;
  }
}

enum RuneStyle {
  arcane(SpecializedPalettes.arcane),
  shadow(SpecializedPalettes.shadowMagic),
  frost(SpecializedPalettes.frostMagic),
  ember(SpecializedPalettes.emberMagic);

  final TilePalette palette;
  const RuneStyle(this.palette);
}

// ============================================================================
// ENERGY TILES
// ============================================================================

/// Energy field/force field tile
class EnergyFieldTile extends SpecializedTile {
  EnergyFieldTile(super.id, {this.fieldColor = FieldColor.blue});

  final FieldColor fieldColor;

  @override
  String get name => 'Energy Field ${fieldColor.name.capitalize()}';

  @override
  String get description => 'Pulsating energy force field';

  @override
  String get iconName => 'blur_on';

  @override
  TilePalette get palette => fieldColor.palette;

  @override
  List<String> get tags => ['special', 'energy', 'field', 'barrier', 'sci-fi'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 6;

  @override
  int get frameSpeed => 120;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    final waveOffset = (frameIndex / frameCount) * 2 * pi;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Hexagonal grid pattern
        final hexX = x / width * 4;
        final hexY = y / height * 4;
        final wave1 = sin(hexX * pi + waveOffset);
        final wave2 = sin(hexY * pi - waveOffset * 0.7);
        final combined = (wave1 + wave2) / 2;

        // Grid lines
        final gridX = (x % 4 == 0) ? 0.3 : 0.0;
        final gridY = (y % 4 == 0) ? 0.3 : 0.0;
        final gridIntensity = max(gridX, gridY);

        Color pixelColor;
        final intensity = (combined + 1) / 2 + gridIntensity;

        if (intensity > 0.8) {
          pixelColor = pal.highlight.withAlpha(200);
        } else if (intensity > 0.5) {
          pixelColor = pal.primary.withAlpha(180);
        } else if (intensity > 0.3) {
          pixelColor = pal.secondary.withAlpha(150);
        } else {
          pixelColor = pal.shadow.withAlpha(100);
        }

        // Random energy sparks
        if (random.nextDouble() > 0.98) {
          pixelColor = pal.highlight;
        }

        pixels[y * width + x] = colorToInt(pixelColor);
      }
    }

    return pixels;
  }
}

enum FieldColor {
  blue(SpecializedPalettes.arcane),
  green(SpecializedPalettes.toxic),
  red(SpecializedPalettes.emberMagic),
  purple(SpecializedPalettes.portal);

  final TilePalette palette;
  const FieldColor(this.palette);
}

// ============================================================================
// VOID/SPACE TILES
// ============================================================================

/// Void/dark space tile with stars
class VoidSpaceTile extends SpecializedTile {
  VoidSpaceTile(super.id, {this.starDensity = 0.03});

  final double starDensity;

  @override
  String get name => 'Void Space';

  @override
  String get description => 'Dark void with distant stars';

  @override
  String get iconName => 'dark_mode';

  @override
  TilePalette get palette => SpecializedPalettes.voidSpace;

  @override
  List<String> get tags => ['special', 'void', 'space', 'stars', 'dark'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 400;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    final twinklePhase = frameIndex / frameCount;

    // Fill with void gradient
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final gradient = (x + y) / (width + height);
        final baseColor = Color.lerp(pal.primary, pal.shadow, gradient)!;
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    // Add stars with twinkle
    final starRandom = Random(seed);
    for (int i = 0; i < (width * height * starDensity).round(); i++) {
      final x = starRandom.nextInt(width);
      final y = starRandom.nextInt(height);
      final brightness = starRandom.nextDouble();
      final twinkle = sin((brightness + twinklePhase) * 2 * pi);

      if (twinkle > 0) {
        Color starColor;
        if (brightness > 0.9) {
          starColor = pal.highlight;
        } else if (brightness > 0.6) {
          starColor = pal.accent;
        } else {
          starColor = pal.secondary;
        }

        final alpha = (twinkle * 255).round().clamp(100, 255);
        pixels[y * width + x] = colorToInt(starColor.withAlpha(alpha));
      }
    }

    return pixels;
  }
}

// ============================================================================
// HOLOGRAPHIC TILES
// ============================================================================

/// Holographic/glitch effect tile
class HologramTile extends SpecializedTile {
  HologramTile(super.id);

  @override
  String get name => 'Hologram';

  @override
  String get description => 'Flickering holographic display';

  @override
  String get iconName => 'tv';

  @override
  TilePalette get palette => SpecializedPalettes.hologram;

  @override
  List<String> get tags => ['special', 'hologram', 'sci-fi', 'tech', 'glitch'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 6;

  @override
  int get frameSpeed => 80;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    // Scan lines and glitch effect
    for (int y = 0; y < height; y++) {
      final scanLine = y % 2 == 0;
      final glitchLine = random.nextDouble() > 0.9;
      final lineOffset = glitchLine ? random.nextInt(3) - 1 : 0;

      for (int x = 0; x < width; x++) {
        final srcX = (x + lineOffset).clamp(0, width - 1);

        // Base hologram pattern
        final patternX = srcX / width * 8;
        final patternY = y / height * 8;
        final pattern = sin(patternX * pi) * cos(patternY * pi);

        Color pixelColor;
        if (pattern > 0.5) {
          pixelColor = pal.primary;
        } else if (pattern > 0) {
          pixelColor = pal.secondary;
        } else {
          pixelColor = pal.shadow;
        }

        // Scanline darkening
        if (scanLine) {
          pixelColor = Color.lerp(pixelColor, const Color(0x00000000), 0.3)!;
        }

        // Random noise
        if (random.nextDouble() > 0.95) {
          pixelColor = pal.highlight;
        }

        // Occasional full glitch
        if (glitchLine && random.nextDouble() > 0.7) {
          pixelColor = random.nextBool() ? pal.highlight : const Color(0x00000000);
        }

        pixels[y * width + srcX] = colorToInt(pixelColor);
      }
    }

    return pixels;
  }
}

// ============================================================================
// NEON TILES
// ============================================================================

/// Neon grid/cyber tile
class NeonGridTile extends SpecializedTile {
  NeonGridTile(super.id, {this.gridSize = 4});

  final int gridSize;

  @override
  String get name => 'Neon Grid';

  @override
  String get description => 'Cyberpunk neon grid pattern';

  @override
  String get iconName => 'grid_on';

  @override
  TilePalette get palette => SpecializedPalettes.neon;

  @override
  List<String> get tags => ['special', 'neon', 'cyber', 'grid', 'sci-fi'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 8;

  @override
  int get frameSpeed => 100;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    final pulsePhase = (frameIndex / frameCount) * 2 * pi;

    // Dark base
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(pal.primary);
    }

    // Draw neon grid
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final onGridX = x % gridSize == 0;
        final onGridY = y % gridSize == 0;

        if (onGridX || onGridY) {
          // Pulse effect along grid
          final pulse = sin(pulsePhase + (x + y) / (width + height) * 4 * pi);
          final intensity = (pulse + 1) / 2;

          Color lineColor;
          if (onGridX && onGridY) {
            // Intersection points - brightest
            lineColor = pal.highlight;
          } else if (intensity > 0.7) {
            lineColor = pal.secondary;
          } else {
            lineColor = Color.lerp(pal.accent, pal.shadow, 1 - intensity)!;
          }

          // Add glow spread
          pixels[y * width + x] = colorToInt(lineColor);

          // Glow to adjacent pixels
          if (x > 0) {
            final glowColor = Color.lerp(
              Color(pixels[y * width + x - 1]),
              lineColor,
              0.3,
            )!;
            pixels[y * width + x - 1] = colorToInt(glowColor);
          }
          if (y > 0) {
            final glowColor = Color.lerp(
              Color(pixels[(y - 1) * width + x]),
              lineColor,
              0.3,
            )!;
            pixels[(y - 1) * width + x] = colorToInt(glowColor);
          }
        }
      }
    }

    // Random bright spots
    for (int i = 0; i < 3; i++) {
      final x = random.nextInt(width);
      final y = random.nextInt(height);
      if (x % gridSize == 0 || y % gridSize == 0) {
        pixels[y * width + x] = colorToInt(pal.highlight);
      }
    }

    return pixels;
  }
}

// ============================================================================
// SPELL/MAGIC EFFECT TILES
// ============================================================================

/// Magic sparkle/particle tile
class MagicSparkleTile extends SpecializedTile {
  MagicSparkleTile(super.id, {this.sparkleColor = SparkleColor.gold});

  final SparkleColor sparkleColor;

  @override
  String get name => 'Magic Sparkle ${sparkleColor.name.capitalize()}';

  @override
  String get description => 'Shimmering magical particles';

  @override
  String get iconName => 'auto_awesome';

  @override
  TilePalette get palette => sparkleColor.palette;

  @override
  List<String> get tags => ['special', 'magic', 'sparkle', 'particle', 'effect'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 8;

  @override
  int get frameSpeed => 80;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    // Transparent base
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    // Generate particles
    final particleCount = (width * height * 0.15).round();
    final particleRandom = Random(seed);

    for (int i = 0; i < particleCount; i++) {
      final baseX = particleRandom.nextDouble() * width;
      final baseY = particleRandom.nextDouble() * height;
      final phase = particleRandom.nextDouble();
      final speed = 0.5 + particleRandom.nextDouble() * 0.5;

      // Animate position (float upward)
      final animPhase = (frameIndex / frameCount + phase) % 1.0;
      final y = ((baseY - animPhase * height * speed) % height).round().clamp(0, height - 1);
      final x = (baseX + sin(animPhase * 4 * pi) * 2).round().clamp(0, width - 1);

      // Fade based on animation phase
      final brightness = sin(animPhase * pi);
      if (brightness > 0.2) {
        Color particleColor;
        if (brightness > 0.8) {
          particleColor = pal.highlight;
        } else if (brightness > 0.5) {
          particleColor = pal.primary;
        } else {
          particleColor = pal.secondary;
        }

        final alpha = (brightness * 255).round().clamp(0, 255);
        pixels[y * width + x] = colorToInt(particleColor.withAlpha(alpha));
      }
    }

    return pixels;
  }
}

enum SparkleColor {
  gold(SpecializedPalettes.energy),
  blue(SpecializedPalettes.arcane),
  purple(SpecializedPalettes.portal),
  green(SpecializedPalettes.toxic);

  final TilePalette palette;
  const SparkleColor(this.palette);
}

// ============================================================================
// ELEMENTAL TILES
// ============================================================================

/// Flame/fire effect tile
class FlameTile extends SpecializedTile {
  FlameTile(super.id, {this.flameIntensity = 1.0});

  final double flameIntensity;

  @override
  String get name => 'Flame';

  @override
  String get description => 'Dancing flame effect';

  @override
  String get iconName => 'local_fire_department';

  @override
  TilePalette get palette => SpecializedPalettes.emberMagic;

  @override
  List<String> get tags => ['special', 'fire', 'flame', 'element', 'effect'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 6;

  @override
  int get frameSpeed => 100;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    // Generate flame from bottom
    for (int y = 0; y < height; y++) {
      final normalizedY = y / height;
      final flameHeight = 1 - normalizedY;

      for (int x = 0; x < width; x++) {
        // Turbulence
        final turbulence = noise2D(
          x / width * 4 + frameIndex * 0.5,
          y / height * 4,
          3,
        );

        final flameValue = flameHeight * flameIntensity + turbulence * 0.3;

        Color pixelColor;
        if (flameValue > 0.8) {
          pixelColor = pal.highlight;
        } else if (flameValue > 0.6) {
          pixelColor = pal.accent;
        } else if (flameValue > 0.4) {
          pixelColor = pal.primary;
        } else if (flameValue > 0.2) {
          pixelColor = pal.secondary;
        } else {
          pixels[y * width + x] = 0x00000000;
          continue;
        }

        // Add flickering
        if (random.nextDouble() > 0.8 && flameValue > 0.4) {
          pixelColor = pal.highlight;
        }

        final alpha = (flameValue * 255).round().clamp(0, 255);
        pixels[y * width + x] = colorToInt(pixelColor.withAlpha(alpha));
      }
    }

    return pixels;
  }
}

/// Ice crystal tile
class IceCrystalTile extends SpecializedTile {
  IceCrystalTile(super.id);

  @override
  String get name => 'Ice Crystal';

  @override
  String get description => 'Frozen ice crystal formation';

  @override
  String get iconName => 'ac_unit';

  @override
  TilePalette get palette => SpecializedPalettes.frostMagic;

  @override
  List<String> get tags => ['special', 'ice', 'crystal', 'frost', 'element'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 6;

  @override
  int get frameSpeed => 200;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    final centerX = width / 2;
    final centerY = height / 2;
    final shimmer = sin((frameIndex / frameCount) * 2 * pi) * 0.5 + 0.5;

    // Fill with base ice color
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(pal.shadow.withAlpha(100));
    }

    // Draw snowflake pattern (6-fold symmetry)
    final arms = 6;
    final armLength = min(width, height) / 2 * 0.8;

    for (int arm = 0; arm < arms; arm++) {
      final angle = arm * (2 * pi / arms);

      // Main arm
      for (double r = 0; r < armLength; r += 0.5) {
        final x = (centerX + cos(angle) * r).round().clamp(0, width - 1);
        final y = (centerY + sin(angle) * r).round().clamp(0, height - 1);

        final intensity = 1 - r / armLength;
        final shimmerIntensity = intensity * shimmer;

        Color crystalColor = Color.lerp(pal.primary, pal.highlight, shimmerIntensity)!;
        pixels[y * width + x] = colorToInt(crystalColor);

        // Side branches
        if (r > armLength * 0.3 && r < armLength * 0.8) {
          final branchLength = (armLength - r) * 0.6;
          for (final branchAngle in [angle - pi / 6, angle + pi / 6]) {
            for (double br = 0; br < branchLength; br += 0.5) {
              final bx = (x + cos(branchAngle) * br).round().clamp(0, width - 1);
              final by = (y + sin(branchAngle) * br).round().clamp(0, height - 1);

              final branchIntensity = (1 - br / branchLength) * intensity;
              crystalColor = Color.lerp(pal.secondary, pal.highlight, branchIntensity * shimmer)!;
              pixels[by * width + bx] = colorToInt(crystalColor);
            }
          }
        }
      }
    }

    // Add sparkles
    for (int i = 0; i < 5; i++) {
      final x = random.nextInt(width);
      final y = random.nextInt(height);
      if (pixels[y * width + x] != colorToInt(pal.shadow.withAlpha(100))) {
        if (random.nextDouble() > 0.5 - shimmer * 0.3) {
          pixels[y * width + x] = colorToInt(pal.highlight);
        }
      }
    }

    return pixels;
  }
}

/// Shadow wisp tile
class ShadowWispTile extends SpecializedTile {
  ShadowWispTile(super.id);

  @override
  String get name => 'Shadow Wisp';

  @override
  String get description => 'Ethereal shadow tendrils';

  @override
  String get iconName => 'waves';

  @override
  TilePalette get palette => SpecializedPalettes.shadowMagic;

  @override
  List<String> get tags => ['special', 'shadow', 'dark', 'wisp', 'ethereal'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 8;

  @override
  int get frameSpeed => 120;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
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
    final pal = palette;

    final wavePhase = (frameIndex / frameCount) * 2 * pi;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Multiple wave layers
        final wave1 = sin((x / width * 4 + wavePhase) * pi) * 0.5;
        final wave2 = cos((y / height * 3 - wavePhase * 0.7) * pi) * 0.3;
        final wave3 = sin(((x + y) / (width + height) * 6 + wavePhase * 0.5) * pi) * 0.2;

        final combined = (wave1 + wave2 + wave3 + 0.5).clamp(0.0, 1.0);

        Color pixelColor;
        if (combined > 0.7) {
          pixelColor = pal.accent;
        } else if (combined > 0.4) {
          pixelColor = pal.secondary;
        } else if (combined > 0.2) {
          pixelColor = pal.primary;
        } else {
          pixelColor = pal.shadow;
        }

        // Add subtle noise
        final alpha = ((combined * 0.7 + 0.3) * 255).round().clamp(100, 255);
        pixels[y * width + x] = addNoise(pixelColor.withAlpha(alpha), random, 0.05);
      }
    }

    return pixels;
  }
}

// ============================================================================
// UTILITY EXTENSION
// ============================================================================

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
