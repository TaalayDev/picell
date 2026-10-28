import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'tile_palette.dart';

// ============================================================================
// TILE PROCEDURAL EFFECTS
// Shared post-generation pixel overlays used by TileVariation system.
// Any tile can call these after its base generation to apply a variation.
// ============================================================================

class TileProceduralEffects {
  TileProceduralEffects._();

  // --------------------------------------------------------------------------
  // WEATHERED — horizontal wear lines, edge erosion, stain blotches
  // --------------------------------------------------------------------------
  static void applyWeathering(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
    TilePalette palette,
  ) {
    // Noise-based stain blotches
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final n = _noise2D(x / 3.0 + 100, y / 3.0, 3);
        if (n > 0.7 && rng.nextDouble() < 0.45) {
          pixels[y * width + x] = _addNoise(palette.shadow, rng, 0.12);
        }
      }
    }
    // Horizontal erosion streaks
    final streakCount = 1 + rng.nextInt(3);
    for (int s = 0; s < streakCount; s++) {
      final sy = rng.nextInt(height);
      final streakLen = width ~/ 2 + rng.nextInt(width ~/ 2);
      final startX = rng.nextInt(width - streakLen + 1);
      for (int dx = 0; dx < streakLen; dx++) {
        final px = startX + dx;
        if (pixels[sy * width + px] >> 24 == 0) continue;
        if (rng.nextDouble() < 0.6) {
          pixels[sy * width + px] = _addNoise(palette.shadow, rng, 0.1);
        }
      }
    }
    // Dark corner vignette
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final edgeDist = _edgeDistance(x, y, width, height);
        if (edgeDist <= 1 && rng.nextDouble() < 0.5) {
          pixels[y * width + x] = _addNoise(palette.shadow, rng, 0.08);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // MOSSY — clustered organic green growth seeded from random points
  // --------------------------------------------------------------------------
  static void applyMoss(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double coverage = 0.25,
  }) {
    const mossLight = Color(0xFF6AAA5A);
    const mossDark = Color(0xFF4A8A3A);
    const mossShadow = Color(0xFF2A5A1A);

    // Grow patches from random seed points
    final seedCount = 2 + rng.nextInt(3);
    final seeds = List.generate(
      seedCount,
      (_) => [rng.nextInt(width), rng.nextInt(height)],
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        // Closest seed distance
        var minDist = double.infinity;
        for (final seed in seeds) {
          final d = sqrt(pow(x - seed[0], 2) + pow(y - seed[1], 2));
          if (d < minDist) minDist = d;
        }
        final radius = 3.5 + coverage * 4;
        final n = _noise2D(x / 2.5 + 200, y / 2.5, 2);
        if (minDist < radius + n * 2 && rng.nextDouble() < coverage) {
          final mossColor = n > 0.6
              ? mossLight
              : n > 0.3
              ? mossDark
              : mossShadow;
          pixels[y * width + x] = _addNoise(mossColor, rng, 0.08);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // CRACKED — procedural branching cracks radiating downward
  // --------------------------------------------------------------------------
  static void applyCracks(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
    TilePalette palette, {
    int count = 2,
  }) {
    for (int c = 0; c < count; c++) {
      var cx = rng.nextInt(width);
      var cy = rng.nextBool() ? 0 : rng.nextInt(height ~/ 3);

      while (cy < height && cx >= 0 && cx < width) {
        if (pixels[cy * width + cx] >> 24 != 0) {
          pixels[cy * width + cx] = _colorToInt(palette.shadow);
        }

        // Occasional branch
        if (rng.nextDouble() < 0.18) {
          var bx = cx;
          var by = cy;
          final dir = rng.nextBool() ? 1 : -1;
          final len = 2 + rng.nextInt(4);
          for (int i = 0; i < len; i++) {
            bx += dir;
            by += rng.nextInt(2);
            if (bx >= 0 && bx < width && by >= 0 && by < height) {
              if (pixels[by * width + bx] >> 24 != 0) {
                pixels[by * width + bx] = _colorToInt(palette.shadow);
              }
            }
          }
        }
        cy++;
        cx += rng.nextInt(3) - 1;
        cx = cx.clamp(0, width - 1);
      }
    }
    // Scattered micro-fractures (only on opaque pixels)
    final chipCount = (width * height * 0.015).round();
    for (int i = 0; i < chipCount; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 != 0) {
        pixels[y * width + x] = _colorToInt(palette.shadow);
      }
    }
  }

  // --------------------------------------------------------------------------
  // PRISTINE — higher contrast, sharper edges, no noise scatter
  // --------------------------------------------------------------------------
  static void applyPristine(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
    TilePalette palette,
  ) {
    // Boost bright pixels and sharpen edge highlights
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final raw = pixels[y * width + x];
        if (raw == 0) continue;
        final r = (raw >> 16) & 0xFF;
        final g = (raw >> 8) & 0xFF;
        final b = raw & 0xFF;
        final lum = (r * 0.299 + g * 0.587 + b * 0.114);
        if (lum > 160) {
          // Boost highlights
          final nr = (r + 18).clamp(0, 255);
          final ng = (g + 18).clamp(0, 255);
          final nb = (b + 18).clamp(0, 255);
          pixels[y * width + x] = (0xFF << 24) | (nr << 16) | (ng << 8) | nb;
        } else if (lum < 60) {
          // Deepen shadows
          final nr = (r - 12).clamp(0, 255);
          final ng = (g - 12).clamp(0, 255);
          final nb = (b - 12).clamp(0, 255);
          pixels[y * width + x] = (0xFF << 24) | (nr << 16) | (ng << 8) | nb;
        }
      }
    }
    // Edge highlight pass
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (_edgeDistance(x, y, width, height) == 1) {
          pixels[y * width + x] = _addNoise(palette.highlight, rng, 0.04);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // FROZEN — blue-tinted icy crystal overlay, frost edge crystals
  // --------------------------------------------------------------------------
  static void applyFrost(Uint32List pixels, int width, int height, Random rng) {
    const frostLight = Color(0xFFD8F0FF);
    const frostMid = Color(0xFFAAD8F0);
    const frostDark = Color(0xFF88C0E0);

    // Blue tint pass over existing pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final raw = pixels[y * width + x];
        if (raw == 0) continue;
        final a = (raw >> 24) & 0xFF;
        final r = (raw >> 16) & 0xFF;
        final g = (raw >> 8) & 0xFF;
        final b = raw & 0xFF;
        // Shift toward blue
        final nr = (r * 0.75).round().clamp(0, 255);
        final ng = (g * 0.85).round().clamp(0, 255);
        final nb = (b + 28).clamp(0, 255);
        pixels[y * width + x] = (a << 24) | (nr << 16) | (ng << 8) | nb;
      }
    }

    // Ice crystal clusters along edges and random points
    final crystalSeeds = List.generate(
      3,
      (_) => [rng.nextInt(width), rng.nextInt(height)],
    );
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = _noise2D(x / 2.0 + 300, y / 2.0, 2);
        final edgeDist = _edgeDistance(x, y, width, height);

        // Check proximity to crystal seeds
        var minDist = double.infinity;
        for (final s in crystalSeeds) {
          final d = sqrt(pow(x - s[0], 2) + pow(y - s[1], 2));
          if (d < minDist) minDist = d;
        }

        if ((edgeDist <= 2 || minDist < 3) &&
            n > 0.45 &&
            rng.nextDouble() < 0.55) {
          final fc = n > 0.7
              ? frostLight
              : n > 0.5
              ? frostMid
              : frostDark;
          pixels[y * width + x] = _addNoise(fc, rng, 0.05);
        }
        // Occasional sparkle
        if (rng.nextDouble() > 0.98) {
          pixels[y * width + x] = _colorToInt(frostLight);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // OVERGROWN — vines/roots creeping over surface + moss base
  // --------------------------------------------------------------------------
  static void applyOvergrown(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
  ) {
    // First apply moss as base
    applyMoss(pixels, width, height, rng, coverage: 0.35);

    const vineDark = Color(0xFF2A5A1A);
    const vineMid = Color(0xFF3A7A2A);
    const vineLeaf = Color(0xFF4A9A3A);

    // Draw vine tendrils from top/sides
    final vineCount = 2 + rng.nextInt(3);
    for (int v = 0; v < vineCount; v++) {
      // Start from a random edge
      int vx, vy;
      final edge = rng.nextInt(3); // 0=top, 1=left, 2=right
      if (edge == 0) {
        vx = rng.nextInt(width);
        vy = 0;
      } else if (edge == 1) {
        vx = 0;
        vy = rng.nextInt(height);
      } else {
        vx = width - 1;
        vy = rng.nextInt(height);
      }

      // Grow vine with random walk biased downward/inward
      final vineLen = height ~/ 2 + rng.nextInt(height ~/ 2);
      for (int i = 0; i < vineLen; i++) {
        if (vx < 0 || vx >= width || vy < 0 || vy >= height) break;
        if (pixels[vy * width + vx] >> 24 != 0) {
          pixels[vy * width + vx] = _addNoise(vineMid, rng, 0.1);
        }

        // Leaf nodes
        if (rng.nextDouble() < 0.2) {
          final lx = vx + (rng.nextBool() ? 1 : -1);
          final ly = vy;
          if (lx >= 0 && lx < width && pixels[ly * width + lx] >> 24 != 0) {
            pixels[ly * width + lx] = _addNoise(vineLeaf, rng, 0.08);
          }
        }

        // Walk: bias toward center and down
        vx += rng.nextInt(3) - 1;
        vy += rng.nextBool() ? 1 : 0;
      }
    }

    // Root tendrils at bottom edge (only on opaque pixels)
    for (int x = 0; x < width; x++) {
      final rootLen = rng.nextInt(3);
      for (int dy = 0; dy < rootLen; dy++) {
        final y = height - 1 - dy;
        if (pixels[y * width + x] >> 24 != 0 && rng.nextDouble() < 0.4) {
          pixels[y * width + x] = _addNoise(vineDark, rng, 0.08);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // PEBBLES — scattered mineral chips and gravel clusters
  // --------------------------------------------------------------------------
  static void applyPebbles(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double density = 0.08,
    Color? lightColor,
    Color? darkColor,
  }) {
    final light = lightColor ?? const Color(0xFF9A8B7A);
    final dark = darkColor ?? const Color(0xFF6B5B4A);
    final count = (width * height * density).round();
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 == 0) continue;
      final color = rng.nextBool() ? light : dark;
      pixels[y * width + x] = _addNoise(color, rng, 0.07);
    }
  }

  // --------------------------------------------------------------------------
  // RIPPLES — wind/water carved bands for sand, silt, snow, and mud
  // --------------------------------------------------------------------------
  static void applyRipples(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double strength = 0.35,
    Color? lightColor,
    Color? darkColor,
  }) {
    final light = lightColor ?? const Color(0xFFE8D8B2);
    final dark = darkColor ?? const Color(0xFFB89B67);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final wave = sin((x / width) * pi * 4 + (y / height) * pi * 2);
        if (wave > (0.68 - strength * 0.5)) {
          pixels[y * width + x] = _addNoise(light, rng, 0.04);
        } else if (wave < (-0.72 + strength * 0.35)) {
          pixels[y * width + x] = _addNoise(dark, rng, 0.04);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // DRIFTS — layered snow/silt accumulation bands
  // --------------------------------------------------------------------------
  static void applyDrifts(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double strength = 0.35,
    Color? crestColor,
    Color? troughColor,
  }) {
    final crest = crestColor ?? const Color(0xFFFFFFFF);
    final trough = troughColor ?? const Color(0xFFB8C8D8);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final band =
            sin((x / width) * pi * 3 + rng.nextDouble() * 0.35) +
            cos((y / height) * pi * 2);
        if (band > (1.1 - strength)) {
          pixels[y * width + x] = _addNoise(crest, rng, 0.03);
        } else if (band < (-0.75 + strength * 0.3)) {
          pixels[y * width + x] = _addNoise(trough, rng, 0.05);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // VEGETATION PATCHES — small organic clusters for grass, moss, weeds
  // --------------------------------------------------------------------------
  static void applyVegetationPatches(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double coverage = 0.18,
    Color? lightColor,
    Color? darkColor,
  }) {
    final light = lightColor ?? const Color(0xFF75B94C);
    final dark = darkColor ?? const Color(0xFF3F7F29);
    final seeds = List.generate(
      2 + rng.nextInt(3),
      (_) => [rng.nextInt(width), rng.nextInt(height)],
    );
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        var minDist = double.infinity;
        for (final seed in seeds) {
          final d = sqrt(pow(x - seed[0], 2) + pow(y - seed[1], 2));
          if (d < minDist) minDist = d;
        }
        final n = _noise2D(x / 2.3 + 600, y / 2.3, 2);
        if (minDist < 2.5 + coverage * 6 &&
            n > 0.35 &&
            rng.nextDouble() < coverage) {
          pixels[y * width + x] = _addNoise(n > 0.6 ? light : dark, rng, 0.07);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // PANEL HIGHLIGHTS — grout, seams, and beveled structural edges
  // --------------------------------------------------------------------------
  static void applyPanelHighlights(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    Color? lineColor,
    int spacing = 4,
  }) {
    final color = lineColor ?? const Color(0xFFD8D0C8);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        if (x % spacing == 0 || y % spacing == 0) {
          if (rng.nextDouble() < 0.75) {
            pixels[y * width + x] = _addNoise(color, rng, 0.03);
          }
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // WOOD KNOTS — darker organic knots and streak anchors
  // --------------------------------------------------------------------------
  static void applyWoodKnots(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int count = 2,
    Color? knotColor,
  }) {
    final color = knotColor ?? const Color(0xFF5D3A1F);
    for (int i = 0; i < count; i++) {
      final cx = 1 + rng.nextInt(max(1, width - 2));
      final cy = 1 + rng.nextInt(max(1, height - 2));
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final x = cx + dx;
          final y = cy + dy;
          if (x < 0 || y < 0 || x >= width || y >= height) continue;
          if (pixels[y * width + x] >> 24 == 0) continue;
          if (dx.abs() + dy.abs() <= 1) {
            pixels[y * width + x] = _addNoise(color, rng, 0.06);
          }
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // MASONRY CHIPS — chipped corners and edge pitting for stone/brick surfaces
  // --------------------------------------------------------------------------
  static void applyMasonryChips(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double density = 0.05,
    Color? chipColor,
  }) {
    final color = chipColor ?? const Color(0xFF4A4038);
    final count = (width * height * density).round();
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      final edgeDist = _edgeDistance(x, y, width, height);
      if (edgeDist > 2 && rng.nextDouble() < 0.5) continue;
      if (pixels[y * width + x] >> 24 == 0) continue;
      pixels[y * width + x] = _addNoise(color, rng, 0.08);
    }
  }

  // --------------------------------------------------------------------------
  // FOAM CAPS — bright surface crests and edge foam
  // --------------------------------------------------------------------------
  static void applyFoamCaps(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double density = 0.1,
    Color? foamColor,
  }) {
    final color = foamColor ?? const Color(0xFFFFFFFF);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final wave = sin((x / width) * pi * 4 + (y / height) * pi * 1.5);
        if (wave > (0.82 - density * 0.55) && rng.nextDouble() < 0.6) {
          pixels[y * width + x] = _addNoise(color, rng, 0.03);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // SURFACE BUBBLES — scattered round highlights for liquids
  // --------------------------------------------------------------------------
  static void applySurfaceBubbles(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int count = 3,
    Color? bubbleColor,
    Color? rimColor,
  }) {
    if (width < 3 || height < 3) return;
    final center = bubbleColor ?? const Color(0xFFFFFFFF);
    final rim = rimColor ?? const Color(0xFFD8F0FF);
    for (int i = 0; i < count; i++) {
      final bx = 1 + rng.nextInt(width - 2);
      final by = 1 + rng.nextInt(height - 2);
      if (pixels[by * width + bx] >> 24 == 0) continue;
      pixels[by * width + bx] = _colorToInt(center);
      for (final offset in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        final x = bx + offset[0];
        final y = by + offset[1];
        if (pixels[y * width + x] >> 24 != 0) {
          pixels[y * width + x] = _addNoise(rim, rng, 0.02);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // IRIDESCENCE — rainbow/oily sheen over dark liquids
  // --------------------------------------------------------------------------
  static void applyIridescence(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double strength = 0.35,
  }) {
    const sheen = [
      Color(0xFF5AC8FA),
      Color(0xFFAF52DE),
      Color(0xFFFF9F0A),
      Color(0xFF64D2FF),
    ];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final band = sin((x / width) * pi * 3 + (y / height) * pi);
        if (band > (0.9 - strength * 0.45) && rng.nextDouble() < 0.45) {
          pixels[y * width + x] = _addNoise(
            sheen[(x + y) % sheen.length],
            rng,
            0.03,
          );
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // CAUSTIC GLOW — glowing toxic/acidic patches
  // --------------------------------------------------------------------------
  static void applyCausticGlow(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double strength = 0.35,
    Color? glowColor,
  }) {
    final glow = glowColor ?? const Color(0xFFD7FF6B);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final n = _noise2D(x / 2.3 + 720, y / 2.3, 2);
        if (n > (0.76 - strength * 0.32) && rng.nextDouble() < 0.55) {
          pixels[y * width + x] = _addNoise(glow, rng, 0.04);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // ARCANE GLYPHS — glowing rune-like dots and lines
  // --------------------------------------------------------------------------
  static void applyArcaneGlyphs(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int glyphCount = 2,
    Color? glyphColor,
  }) {
    final color = glyphColor ?? const Color(0xFFFFFFFF);
    for (int i = 0; i < glyphCount; i++) {
      if (width < 3 || height < 3) break;
      final cx = 1 + rng.nextInt(width - 2);
      final cy = 1 + rng.nextInt(height - 2);
      final horizontal = rng.nextBool();
      final len = 1 + rng.nextInt(2);
      for (int d = -len; d <= len; d++) {
        final x = horizontal ? cx + d : cx;
        final y = horizontal ? cy : cy + d;
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        if (pixels[y * width + x] >> 24 == 0) continue;
        pixels[y * width + x] = _addNoise(color, rng, 0.03);
      }
      pixels[cy * width + cx] = _colorToInt(color);
    }
  }

  // --------------------------------------------------------------------------
  // ENERGY VEINS — bright crackling energy filaments
  // --------------------------------------------------------------------------
  static void applyEnergyVeins(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int count = 2,
    Color? veinColor,
  }) {
    final color = veinColor ?? const Color(0xFFFFFFFF);
    for (int c = 0; c < count; c++) {
      var x = rng.nextInt(width);
      var y = rng.nextInt(height);
      final length =
          max(width, height) ~/ 2 +
          rng.nextInt(max(1, max(width, height) ~/ 2));
      for (int i = 0; i < length; i++) {
        if (x < 0 || y < 0 || x >= width || y >= height) break;
        if (pixels[y * width + x] >> 24 != 0) {
          pixels[y * width + x] = _addNoise(color, rng, 0.03);
        }
        x += rng.nextInt(3) - 1;
        y += rng.nextInt(3) - 1;
      }
    }
  }

  // --------------------------------------------------------------------------
  // STAR GLINTS — tiny sparkling highlights for crystals and magic
  // --------------------------------------------------------------------------
  static void applyStarGlints(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int count = 3,
    Color? glintColor,
  }) {
    final color = glintColor ?? const Color(0xFFFFFFFF);
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 == 0) continue;
      pixels[y * width + x] = _colorToInt(color);
      if (x > 0 && pixels[y * width + x - 1] >> 24 != 0) {
        pixels[y * width + x - 1] = _addNoise(color, rng, 0.02);
      }
      if (x < width - 1 && pixels[y * width + x + 1] >> 24 != 0) {
        pixels[y * width + x + 1] = _addNoise(color, rng, 0.02);
      }
      if (y > 0 && pixels[(y - 1) * width + x] >> 24 != 0) {
        pixels[(y - 1) * width + x] = _addNoise(color, rng, 0.02);
      }
      if (y < height - 1 && pixels[(y + 1) * width + x] >> 24 != 0) {
        pixels[(y + 1) * width + x] = _addNoise(color, rng, 0.02);
      }
    }
  }

  // --------------------------------------------------------------------------
  // VOID FLECKS — shadow flecks and cosmic motes
  // --------------------------------------------------------------------------
  static void applyVoidFlecks(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double density = 0.06,
    Color? darkColor,
    Color? lightColor,
  }) {
    final dark = darkColor ?? const Color(0xFF0A0A1A);
    final light = lightColor ?? const Color(0xFF4A4A7E);
    final count = (width * height * density).round();
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 == 0) continue;
      pixels[y * width + x] = _addNoise(
        rng.nextBool() ? dark : light,
        rng,
        0.04,
      );
    }
  }

  // --------------------------------------------------------------------------
  // DECORATIVE TRIM — border accents for banners, rugs, chests, signs
  // --------------------------------------------------------------------------
  static void applyDecorativeTrim(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    Color? trimColor,
  }) {
    final color = trimColor ?? const Color(0xFFDDAA44);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final edge = _edgeDistance(x, y, width, height);
        if (edge == 1 && rng.nextDouble() < 0.75) {
          pixels[y * width + x] = _addNoise(color, rng, 0.03);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // FABRIC PATTERN — stitched dots and woven bands
  // --------------------------------------------------------------------------
  static void applyFabricPattern(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    Color? patternColor,
    int spacing = 3,
  }) {
    final color = patternColor ?? const Color(0xFFFFE0A0);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        if ((x + y) % spacing == 0 && rng.nextDouble() < 0.5) {
          pixels[y * width + x] = _addNoise(color, rng, 0.02);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // METAL SHINE — bright specular hits for props and trims
  // --------------------------------------------------------------------------
  static void applyMetalShine(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int count = 3,
    Color? shineColor,
  }) {
    final color = shineColor ?? const Color(0xFFE0E4EA);
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 == 0) continue;
      pixels[y * width + x] = _colorToInt(color);
      if (x < width - 1 && pixels[y * width + x + 1] >> 24 != 0) {
        pixels[y * width + x + 1] = _addNoise(color, rng, 0.02);
      }
    }
  }

  // --------------------------------------------------------------------------
  // DUST SPECKS — aged decorative clutter and storage wear
  // --------------------------------------------------------------------------
  static void applyDustSpecks(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double density = 0.05,
    Color? dustColor,
  }) {
    final color = dustColor ?? const Color(0xFFB8A890);
    final count = (width * height * density).round();
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 == 0) continue;
      pixels[y * width + x] = _addNoise(color, rng, 0.03);
    }
  }

  // --------------------------------------------------------------------------
  // DAMP PATCHES — cool seepage stains and slick cave moisture
  // --------------------------------------------------------------------------
  static void applyDampPatches(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double strength = 0.22,
    Color? dampColor,
    Color? sheenColor,
  }) {
    final dark = dampColor ?? const Color(0xFF2E3B44);
    final sheen = sheenColor ?? const Color(0xFF5D7382);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final moisture = _noise2D(x / 2.7 + 840, y / 2.7, 2);
        if (moisture > (0.8 - strength * 0.35) && rng.nextDouble() < 0.5) {
          pixels[y * width + x] = _addNoise(dark, rng, 0.04);
        } else if (moisture > (0.9 - strength * 0.25) &&
            rng.nextDouble() < 0.22) {
          pixels[y * width + x] = _addNoise(sheen, rng, 0.03);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // MINERAL VEINS — bright crystalline seams through stone and cave walls
  // --------------------------------------------------------------------------
  static void applyMineralVeins(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int count = 2,
    Color? veinColor,
    Color? accentColor,
  }) {
    final vein = veinColor ?? const Color(0xFFB9C5CC);
    final accent = accentColor ?? const Color(0xFFE2E8EC);
    for (int c = 0; c < count; c++) {
      var x = rng.nextInt(width);
      var y = rng.nextInt(height);
      final horizontalBias = rng.nextBool();
      final length = max(width, height) ~/ 2 + rng.nextInt(max(1, width ~/ 3));
      for (int i = 0; i < length; i++) {
        if (x < 0 || y < 0 || x >= width || y >= height) break;
        if (pixels[y * width + x] >> 24 != 0) {
          pixels[y * width + x] = _addNoise(
            rng.nextDouble() < 0.25 ? accent : vein,
            rng,
            0.03,
          );
        }
        if (horizontalBias) {
          x += 1;
          y += rng.nextInt(3) - 1;
        } else {
          y += 1;
          x += rng.nextInt(3) - 1;
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // RUNE CARVINGS — carved glyph slashes with subtle highlight lift
  // --------------------------------------------------------------------------
  static void applyRuneCarvings(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int glyphCount = 2,
    Color? carveColor,
    Color? highlightColor,
  }) {
    if (width < 3 || height < 3) return;
    final carve = carveColor ?? const Color(0xFF3A312B);
    final highlight = highlightColor ?? const Color(0xFFB8ACA0);
    for (int i = 0; i < glyphCount; i++) {
      final cx = 1 + rng.nextInt(width - 2);
      final cy = 1 + rng.nextInt(height - 2);
      final rune = rng.nextInt(3);
      final points = switch (rune) {
        0 => const [
          [0, -1],
          [0, 0],
          [0, 1],
          [1, 0],
        ],
        1 => const [
          [-1, -1],
          [0, 0],
          [1, 1],
          [1, -1],
        ],
        _ => const [
          [-1, 1],
          [0, 0],
          [1, -1],
          [0, 1],
        ],
      };
      for (final point in points) {
        final x = cx + point[0];
        final y = cy + point[1];
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        if (pixels[y * width + x] >> 24 == 0) continue;
        pixels[y * width + x] = _addNoise(carve, rng, 0.02);
        final hx = (x + 1).clamp(0, width - 1);
        if (pixels[y * width + hx] >> 24 != 0 && rng.nextDouble() < 0.5) {
          pixels[y * width + hx] = _addNoise(highlight, rng, 0.02);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // ROAD SCUFFS — tire wear, directional abrasion, street grime
  // --------------------------------------------------------------------------
  static void applyRoadScuffs(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int laneCount = 2,
    Color? darkColor,
    Color? lightColor,
  }) {
    final dark = darkColor ?? const Color(0xFF2C2C2C);
    final light = lightColor ?? const Color(0xFF666666);
    for (int lane = 0; lane < laneCount; lane++) {
      final center = ((lane + 1) * height / (laneCount + 1)).round();
      for (int x = 0; x < width; x++) {
        final offset = rng.nextInt(3) - 1;
        final y = (center + offset).clamp(0, height - 1);
        if (pixels[y * width + x] >> 24 == 0) continue;
        pixels[y * width + x] = _addNoise(dark, rng, 0.03);
        if (rng.nextDouble() < 0.2 &&
            y > 0 &&
            pixels[(y - 1) * width + x] >> 24 != 0) {
          pixels[(y - 1) * width + x] = _addNoise(light, rng, 0.02);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // PATCH REPAIRS — urban resurfacing rectangles and slab replacement blocks
  // --------------------------------------------------------------------------
  static void applyPatchRepairs(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int patchCount = 2,
    Color? patchColor,
    Color? seamColor,
  }) {
    final fill = patchColor ?? const Color(0xFF626262);
    final seam = seamColor ?? const Color(0xFF2F2F2F);
    for (int i = 0; i < patchCount; i++) {
      final patchW = max(2, width ~/ 4 + rng.nextInt(max(1, width ~/ 4)));
      final patchH = max(2, height ~/ 4 + rng.nextInt(max(1, height ~/ 4)));
      final startX = rng.nextInt(max(1, width - patchW + 1));
      final startY = rng.nextInt(max(1, height - patchH + 1));
      for (int y = startY; y < startY + patchH; y++) {
        for (int x = startX; x < startX + patchW; x++) {
          if (pixels[y * width + x] >> 24 == 0) continue;
          final edge =
              x == startX ||
              x == startX + patchW - 1 ||
              y == startY ||
              y == startY + patchH - 1;
          pixels[y * width + x] = _addNoise(
            edge ? seam : fill,
            rng,
            edge ? 0.02 : 0.04,
          );
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // RUST STREAKS — oxidized drips and grime on metal/industrial surfaces
  // --------------------------------------------------------------------------
  static void applyRustStreaks(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    int streakCount = 3,
    Color? rustColor,
  }) {
    final rust = rustColor ?? const Color(0xFF8B5A32);
    for (int i = 0; i < streakCount; i++) {
      final x = rng.nextInt(width);
      var y = rng.nextInt(max(1, height ~/ 3));
      final length = max(2, height ~/ 3 + rng.nextInt(max(1, height ~/ 3)));
      for (int d = 0; d < length && y < height; d++, y++) {
        if (pixels[y * width + x] >> 24 != 0 && rng.nextDouble() < 0.75) {
          pixels[y * width + x] = _addNoise(rust, rng, 0.05);
        }
        if (x + 1 < width &&
            pixels[y * width + x + 1] >> 24 != 0 &&
            rng.nextDouble() < 0.2) {
          pixels[y * width + x + 1] = _addNoise(rust, rng, 0.03);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // PAINT FLECKS — chipped lane paint, hazard paint, industrial markings
  // --------------------------------------------------------------------------
  static void applyPaintFlecks(
    Uint32List pixels,
    int width,
    int height,
    Random rng, {
    double density = 0.05,
    Color? paintColor,
  }) {
    final paint = paintColor ?? const Color(0xFFE8E8E8);
    final count = (width * height * density).round();
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 == 0) continue;
      pixels[y * width + x] = _addNoise(paint, rng, 0.02);
    }
  }

  // --------------------------------------------------------------------------
  // SCORCH — burn marks, soot smudges, char deposits
  // --------------------------------------------------------------------------
  static void applyScorch(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
  ) {
    const charBlack = Color(0xFF1A1208);
    const sootBrown = Color(0xFF3A2A18);
    const ashGray = Color(0xFF6A6058);

    // Central scorch zone
    final cx = width ~/ 2 + rng.nextInt(width ~/ 4) - width ~/ 8;
    final cy = height ~/ 2 + rng.nextInt(height ~/ 4) - height ~/ 8;
    final radius = 3.0 + rng.nextDouble() * 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        final n = _noise2D(x / 2.5 + 400, y / 2.5, 2);

        if (dist < radius * 0.4 && rng.nextDouble() < 0.8) {
          pixels[y * width + x] = _addNoise(charBlack, rng, 0.06);
        } else if (dist < radius && n > 0.4 && rng.nextDouble() < 0.6) {
          pixels[y * width + x] = _addNoise(sootBrown, rng, 0.08);
        } else if (dist < radius * 1.5 && n > 0.55 && rng.nextDouble() < 0.35) {
          pixels[y * width + x] = _addNoise(ashGray, rng, 0.1);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // BURNT — char marks, soot smudges, embers, black/brown overlay
  // --------------------------------------------------------------------------
  static void applyBurnt(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
  ) {
    const charBlack = Color(0xFF120E08);
    const sootBrown = Color(0xFF3A2818);
    const ashGray = Color(0xFF605850);

    // Irregular scorch zones seeded from random burn origins
    final originCount = 1 + rng.nextInt(2);
    final origins = List.generate(
      originCount,
      (_) => [rng.nextInt(width), rng.nextInt(height)],
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        var minD = double.infinity;
        for (final o in origins) {
          final d = sqrt(pow(x - o[0], 2) + pow(y - o[1], 2));
          if (d < minD) minD = d;
        }
        final n = _noise2D(x / 2.5 + 400, y / 2.5, 2);
        final maxR = 3.0 + rng.nextDouble() * 3;
        if (minD < maxR * 0.4 && rng.nextDouble() < 0.82) {
          pixels[y * width + x] = _addNoise(charBlack, rng, 0.06);
        } else if (minD < maxR && n > 0.4 && rng.nextDouble() < 0.62) {
          pixels[y * width + x] = _addNoise(sootBrown, rng, 0.08);
        } else if (minD < maxR * 1.6 && n > 0.55 && rng.nextDouble() < 0.35) {
          pixels[y * width + x] = _addNoise(ashGray, rng, 0.10);
        }
      }
    }

    // Scattered bright ember flecks
    final emberCount = 1 + rng.nextInt(3);
    const ember = Color(0xFFFF6520);
    for (int i = 0; i < emberCount; i++) {
      final ex = rng.nextInt(width);
      final ey = rng.nextInt(height);
      if (pixels[ey * width + ex] >> 24 != 0) {
        pixels[ey * width + ex] = _colorToInt(ember);
      }
    }
  }

  // --------------------------------------------------------------------------
  // SUBMERGED — darkened, cold blue tint, waterline ripple band
  // --------------------------------------------------------------------------
  static void applySubmerged(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
  ) {
    const waterDark = Color(0xFF1A2A36);
    const waterSheen = Color(0xFF2E5070);
    const rippleLight = Color(0xFF6AA0C0);

    // Overall damp/dark pass
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final raw = pixels[y * width + x];
        if (raw >> 24 == 0) continue;
        final a = (raw >> 24) & 0xFF;
        final r = (raw >> 16) & 0xFF;
        final g = (raw >> 8) & 0xFF;
        final b = raw & 0xFF;
        final nr = (r * 0.58).round().clamp(0, 255);
        final ng = (g * 0.68 + 8).round().clamp(0, 255);
        final nb = (b * 0.75 + 20).round().clamp(0, 255);
        pixels[y * width + x] = (a << 24) | (nr << 16) | (ng << 8) | nb;
      }
    }

    // Waterline ripple bands (horizontal waves in upper third)
    final waterlineY = height ~/ 4 + rng.nextInt(max(1, height ~/ 4));
    for (int x = 0; x < width; x++) {
      for (int dy = 0; dy < 2; dy++) {
        final wy = waterlineY + dy;
        if (wy >= height) break;
        final wave = sin(x / 3.0 + rng.nextDouble() * 0.5);
        if (wave > 0.3 && pixels[wy * width + x] >> 24 != 0) {
          pixels[wy * width + x] = _addNoise(rippleLight, rng, 0.04);
        }
      }
    }

    // Damp patches (seep stains)
    final patchCount = 2 + rng.nextInt(2);
    for (int p = 0; p < patchCount; p++) {
      final px = rng.nextInt(width);
      final py = rng.nextInt(height);
      for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
          final x = px + dx;
          final y = py + dy;
          if (x < 0 || y < 0 || x >= width || y >= height) continue;
          if (pixels[y * width + x] >> 24 == 0) continue;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < 2.5 && rng.nextDouble() < 0.6) {
            pixels[y * width + x] = _addNoise(waterDark, rng, 0.05);
          } else if (dist < 3.5 && rng.nextDouble() < 0.25) {
            pixels[y * width + x] = _addNoise(waterSheen, rng, 0.04);
          }
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // RUSTED — orange/brown streaks, surface pitting, oxidation blotches
  // --------------------------------------------------------------------------
  static void applyRusted(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
  ) {
    const rustOrange = Color(0xFF9B4B1A);
    const rustDeep = Color(0xFF6B2A08);
    const oxideBrown = Color(0xFF7A4020);

    // Noise-based rust blotches
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final n = _noise2D(x / 2.8 + 500, y / 2.8, 3);
        if (n > 0.62 && rng.nextDouble() < 0.55) {
          pixels[y * width + x] = _addNoise(n > 0.78 ? rustDeep : rustOrange, rng, 0.08);
        }
      }
    }

    // Vertical rust drip streaks from random top points
    final streakCount = 2 + rng.nextInt(3);
    for (int s = 0; s < streakCount; s++) {
      var x = rng.nextInt(width);
      var y = rng.nextInt(max(1, height ~/ 3));
      final len = height ~/ 3 + rng.nextInt(max(1, height ~/ 2));
      for (int d = 0; d < len && y < height; d++, y++) {
        if (pixels[y * width + x] >> 24 != 0 && rng.nextDouble() < 0.78) {
          pixels[y * width + x] = _addNoise(oxideBrown, rng, 0.06);
        }
        if (x + 1 < width && pixels[y * width + x + 1] >> 24 != 0 && rng.nextDouble() < 0.18) {
          pixels[y * width + x + 1] = _addNoise(rustOrange, rng, 0.04);
        }
        if (rng.nextDouble() < 0.15) x += rng.nextInt(3) - 1;
        x = x.clamp(0, width - 1);
      }
    }

    // Pitting: tiny shadow pits scattered across surface
    final pitCount = (width * height * 0.03).round();
    for (int i = 0; i < pitCount; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 != 0) {
        pixels[y * width + x] = _addNoise(rustDeep, rng, 0.10);
      }
    }
  }

  // --------------------------------------------------------------------------
  // HAUNTED — desaturated, purple-dark particle noise, void flecks
  // --------------------------------------------------------------------------
  static void applyHaunted(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
  ) {
    const voidDark = Color(0xFF0A0818);
    const specterPurple = Color(0xFF4A3A6A);
    const ghostWhite = Color(0xFFD8D4E8);

    // Desaturate + darken entire tile
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final raw = pixels[y * width + x];
        if (raw >> 24 == 0) continue;
        final a = (raw >> 24) & 0xFF;
        final r = (raw >> 16) & 0xFF;
        final g = (raw >> 8) & 0xFF;
        final b = raw & 0xFF;
        final lum = (r * 0.299 + g * 0.587 + b * 0.114).round();
        // Blend toward luminance (desaturate) then tint purple
        final nr = ((lum * 0.6 + r * 0.4) * 0.6 + 12).round().clamp(0, 255);
        final ng = ((lum * 0.6 + g * 0.4) * 0.55).round().clamp(0, 255);
        final nb = ((lum * 0.6 + b * 0.4) * 0.75 + 18).round().clamp(0, 255);
        pixels[y * width + x] = (a << 24) | (nr << 16) | (ng << 8) | nb;
      }
    }

    // Purple void particle clusters
    final voidCount = (width * height * 0.04).round();
    for (int i = 0; i < voidCount; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 == 0) continue;
      final n = _noise2D(x / 2.0 + 700, y / 2.0, 2);
      pixels[y * width + x] = _addNoise(n > 0.6 ? specterPurple : voidDark, rng, 0.06);
    }

    // Occasional ghostly white glint
    final glintCount = 1 + rng.nextInt(2);
    for (int i = 0; i < glintCount; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 != 0) {
        pixels[y * width + x] = _addNoise(ghostWhite, rng, 0.04);
      }
    }
  }

  // --------------------------------------------------------------------------
  // GILDED — gold-trim on edges and surface crevices, rich warm highlights
  // --------------------------------------------------------------------------
  static void applyGilded(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
  ) {
    const goldBright = Color(0xFFFFD040);
    const goldMid = Color(0xFFCCA020);
    const goldDeep = Color(0xFF886800);

    // Edge trim — perimeter pixels get gold highlight
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] >> 24 == 0) continue;
        final edge = _edgeDistance(x, y, width, height);
        if (edge == 0) {
          pixels[y * width + x] = _addNoise(goldDeep, rng, 0.04);
        } else if (edge == 1 && rng.nextDouble() < 0.75) {
          pixels[y * width + x] = _addNoise(goldMid, rng, 0.04);
        } else if (edge == 2 && rng.nextDouble() < 0.35) {
          pixels[y * width + x] = _addNoise(goldBright, rng, 0.06);
        }
      }
    }

    // Crevice gold fill — dark pixels near surface features get gold inlay
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final raw = pixels[y * width + x];
        if (raw >> 24 == 0) continue;
        final lum = (((raw >> 16) & 0xFF) * 0.299 +
                ((raw >> 8) & 0xFF) * 0.587 +
                (raw & 0xFF) * 0.114)
            .round();
        if (lum < 50 && rng.nextDouble() < 0.4) {
          pixels[y * width + x] = _addNoise(goldDeep, rng, 0.05);
        }
      }
    }

    // Specular gold glints
    final glintCount = 2 + rng.nextInt(3);
    for (int i = 0; i < glintCount; i++) {
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      if (pixels[y * width + x] >> 24 != 0) {
        pixels[y * width + x] = _colorToInt(goldBright);
      }
    }
  }

  // --------------------------------------------------------------------------
  // SHATTERED — fragmentation crack lines + displaced cluster offsets
  // --------------------------------------------------------------------------
  static void applyShattered(
    Uint32List pixels,
    int width,
    int height,
    Random rng,
    TilePalette palette,
  ) {
    // First apply more cracks than normal
    applyCracks(pixels, width, height, rng, palette, count: 4);

    // Radiating lines from a single impact point
    final ox = rng.nextInt(width);
    final oy = rng.nextInt(height);
    const rayCount = 8;
    for (int r = 0; r < rayCount; r++) {
      final angle = (r / rayCount) * 2 * pi;
      final len = 3 + rng.nextInt(5);
      for (int d = 0; d < len; d++) {
        final x = (ox + d * cos(angle)).round();
        final y = (oy + d * sin(angle)).round();
        if (x < 0 || y < 0 || x >= width || y >= height) break;
        if (pixels[y * width + x] >> 24 != 0) {
          pixels[y * width + x] = _colorToInt(palette.shadow);
        }
      }
    }

    // Displaced fragment clusters — small regions with offset highlight
    final fragmentCount = 2 + rng.nextInt(3);
    for (int f = 0; f < fragmentCount; f++) {
      final fx = rng.nextInt(max(1, width - 4));
      final fy = rng.nextInt(max(1, height - 4));
      for (int dy = 0; dy < 2; dy++) {
        for (int dx = 0; dx < 3; dx++) {
          final x = fx + dx;
          final y = fy + dy;
          if (x >= width || y >= height) continue;
          if (pixels[y * width + x] >> 24 == 0) continue;
          // Edge of fragment = shadow; interior = highlight
          pixels[y * width + x] = (dx == 0 || dy == 0)
              ? _addNoise(palette.shadow, rng, 0.04)
              : _addNoise(palette.highlight, rng, 0.06);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // PRIVATE HELPERS (mirror of TileBase helpers, no inheritance needed)
  // --------------------------------------------------------------------------

  static int _colorToInt(Color color) => color.value;

  static int _addNoise(Color baseColor, Random random, double intensity) {
    final v = ((random.nextDouble() - 0.5) * 2 * intensity * 255).round();
    final r = (baseColor.red + v).clamp(0, 255);
    final g = (baseColor.green + v).clamp(0, 255);
    final b = (baseColor.blue + v).clamp(0, 255);
    return (baseColor.alpha << 24) | (r << 16) | (g << 8) | b;
  }

  static double _noise2D(double x, double y, int octaves) {
    double value = 0;
    double amplitude = 1;
    double frequency = 1;
    double maxValue = 0;
    for (int i = 0; i < octaves; i++) {
      value += amplitude * _smoothNoise(x * frequency, y * frequency);
      maxValue += amplitude;
      amplitude *= 0.5;
      frequency *= 2;
    }
    return value / maxValue;
  }

  static double _smoothNoise(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;
    double hash(int hx, int hy) {
      final n = hx + hy * 57;
      final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
      return h / 0x7fffffff;
    }

    final v1 = hash(ix, iy);
    final v2 = hash(ix + 1, iy);
    final v3 = hash(ix, iy + 1);
    final v4 = hash(ix + 1, iy + 1);
    final i1 = v1 + fx * (v2 - v1);
    final i2 = v3 + fx * (v4 - v3);
    return i1 + fy * (i2 - i1);
  }

  static int _edgeDistance(int x, int y, int width, int height) {
    return [x, y, width - 1 - x, height - 1 - y].reduce(min);
  }
}
