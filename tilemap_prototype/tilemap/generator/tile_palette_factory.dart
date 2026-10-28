import 'dart:ui';

import 'package:flutter/material.dart' show HSLColor;

import 'tile_palette.dart';

// ============================================================================
// TILE PALETTE FACTORY
// Derives modified palettes from existing ones for variation effects.
// All methods return new TilePalette instances — originals are unchanged.
// ============================================================================

class TilePaletteFactory {
  TilePaletteFactory._();

  /// Returns a weathered version of a palette:
  /// darker primaries, desaturated highlights, aged look.
  static TilePalette weathered(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Weathered)',
      colors: base.colors.map((c) => _darken(c, 0.12)).toList(),
    );
  }

  /// Returns a frozen version: blue-shifted, brighter highlights.
  static TilePalette frozen(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Frozen)',
      colors: base.colors.map((c) => _blueShift(c, 0.25)).toList(),
    );
  }

  /// Returns a mossy version: green-tinted, slightly darkened.
  static TilePalette mossy(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Mossy)',
      colors: base.colors.map((c) => _greenShift(c, 0.15)).toList(),
    );
  }

  /// Returns a pristine version: higher contrast, vivid highlights.
  static TilePalette pristine(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Pristine)',
      colors: base.colors.map((c) => _boost(c, 0.08)).toList(),
    );
  }

  /// Returns a scorched version: dark, brownish-black tones.
  static TilePalette scorched(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Scorched)',
      colors: base.colors.map((c) => _scorch(c)).toList(),
    );
  }

  /// Returns an overgrown version: green-shifted primaries, dark shadows.
  static TilePalette overgrown(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Overgrown)',
      colors: base.colors.map((c) => _greenShift(c, 0.2)).toList(),
    );
  }

  /// Returns a burnt version: charred dark brown/black tones.
  static TilePalette burnt(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Burnt)',
      colors: base.colors.map((c) => _scorch(c)).toList(),
    );
  }

  /// Returns a submerged version: darker, blue-green tinted, waterlogged.
  static TilePalette submerged(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Submerged)',
      colors: base.colors.map((c) {
        final r = (c.red * 0.60).round().clamp(0, 255);
        final g = (c.green * 0.72 + 12).round().clamp(0, 255);
        final b = (c.blue * 0.80 + 22).round().clamp(0, 255);
        return Color.fromARGB(c.alpha, r, g, b);
      }).toList(),
    );
  }

  /// Returns a rusted version: orange-reddish hue, desaturated shadows.
  static TilePalette rusted(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Rusted)',
      colors: base.colors.map((c) {
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withHue(15.0)
            .withSaturation((hsl.saturation * 0.55 + 0.3).clamp(0.0, 1.0))
            .withLightness((hsl.lightness * 0.75).clamp(0.0, 1.0))
            .toColor();
      }).toList(),
    );
  }

  /// Returns a haunted version: desaturated with subtle purple tint.
  static TilePalette haunted(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Haunted)',
      colors: base.colors.map((c) {
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withHue((hsl.hue * 0.1 + 270.0 * 0.9).clamp(0.0, 360.0))
            .withSaturation((hsl.saturation * 0.18).clamp(0.0, 1.0))
            .withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0))
            .toColor();
      }).toList(),
    );
  }

  /// Returns a gilded version: highlights shifted to warm gold.
  static TilePalette gilded(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Gilded)',
      colors: base.colors.map((c) {
        final hsl = HSLColor.fromColor(c);
        if (hsl.lightness > 0.45) {
          return hsl
              .withHue(42.0)
              .withSaturation(0.72)
              .withLightness((hsl.lightness + 0.07).clamp(0.0, 1.0))
              .toColor();
        }
        return _darken(c, 0.06);
      }).toList(),
    );
  }

  /// Returns a shattered version: high contrast, slight desaturation.
  static TilePalette shattered(TilePalette base) {
    return TilePalette(
      name: '${base.name} (Shattered)',
      colors: base.colors.map((c) {
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withSaturation((hsl.saturation * 0.65).clamp(0.0, 1.0))
            .withLightness(
              hsl.lightness > 0.5
                  ? (hsl.lightness + 0.13).clamp(0.0, 1.0)
                  : (hsl.lightness - 0.13).clamp(0.0, 1.0),
            )
            .toColor();
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // Color transform helpers
  // --------------------------------------------------------------------------

  /// Darken a color by [amount] (0.0–1.0).
  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Increase contrast/saturation slightly.
  static Color _boost(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation + amount * 2).clamp(0.0, 1.0))
        .withLightness(
          hsl.lightness > 0.5
              ? (hsl.lightness + amount).clamp(0.0, 1.0)
              : (hsl.lightness - amount * 0.5).clamp(0.0, 1.0),
        )
        .toColor();
  }

  /// Shift color toward blue (frost/ice effect).
  static Color _blueShift(Color c, double strength) {
    final r = (c.red * (1 - strength * 0.3)).round().clamp(0, 255);
    final g = (c.green * (1 - strength * 0.1)).round().clamp(0, 255);
    final b = (c.blue + (255 - c.blue) * strength * 0.4).round().clamp(0, 255);
    return Color.fromARGB(c.alpha, r, g, b);
  }

  /// Shift color toward green (moss/overgrown effect).
  static Color _greenShift(Color c, double strength) {
    final r = (c.red * (1 - strength * 0.2)).round().clamp(0, 255);
    final g = (c.green + (180 - c.green) * strength * 0.3).round().clamp(0, 255);
    final b = (c.blue * (1 - strength * 0.15)).round().clamp(0, 255);
    return Color.fromARGB(c.alpha, r, g, b);
  }

  /// Shift toward dark brownish-black (scorch effect).
  static Color _scorch(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withHue((hsl.hue * 0.3 + 25 * 0.7) % 360) // pull toward brown
        .withSaturation((hsl.saturation * 0.4).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.35).clamp(0.0, 1.0))
        .toColor();
  }
}
