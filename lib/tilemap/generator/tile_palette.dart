import 'dart:ui';

import 'package:flutter/material.dart';

/// A color palette for tile generation
class TilePalette {
  final String name;
  final List<Color> colors;
  final Color? backgroundColor;

  const TilePalette({
    required this.name,
    required this.colors,
    this.backgroundColor,
  });

  /// Get a color at index (wraps around if out of bounds)
  Color getColor(int index) {
    if (colors.isEmpty) return const Color(0xFF000000);
    return colors[index % colors.length];
  }

  /// Get primary color (first color)
  Color get primary => colors.isNotEmpty ? colors[0] : const Color(0xFF000000);

  /// Get secondary color (second color or primary)
  Color get secondary => colors.length > 1 ? colors[1] : primary;

  /// Get accent color (third color or secondary)
  Color get accent => colors.length > 2 ? colors[2] : secondary;

  /// Get highlight color (fourth color or accent)
  Color get highlight => colors.length > 3 ? colors[3] : accent;

  /// Get shadow color (fifth color or darker primary)
  Color get shadow => colors.length > 4 ? colors[4] : _darken(primary, 0.3);

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

/// Predefined palettes for different tile types
class TilePalettes {
  TilePalettes._();

  // ===== TERRAIN PALETTES =====

  static const grass = TilePalette(
    name: 'Grass',
    colors: [
      Color(0xFF4A7C23), // Base green
      Color(0xFF5C8C2A), // Light green
      Color(0xFF3D6B1C), // Dark green
      Color(0xFF6B9E31), // Highlight
      Color(0xFF2D5014), // Shadow
      Color(0xFF8B6914), // Dirt accent
    ],
  );

  static const dirt = TilePalette(
    name: 'Dirt',
    colors: [
      Color(0xFF8B6914), // Base brown
      Color(0xFFA07818), // Light brown
      Color(0xFF6B5010), // Dark brown
      Color(0xFFC49A2C), // Highlight
      Color(0xFF4A3A0C), // Shadow
    ],
  );

  static const stone = TilePalette(
    name: 'Stone',
    colors: [
      Color(0xFF6B6B6B), // Base gray
      Color(0xFF8A8A8A), // Light gray
      Color(0xFF4A4A4A), // Dark gray
      Color(0xFFA8A8A8), // Highlight
      Color(0xFF2F2F2F), // Shadow
    ],
  );

  static const sand = TilePalette(
    name: 'Sand',
    colors: [
      Color(0xFFE8D5A3), // Base sand
      Color(0xFFF5E6BE), // Light sand
      Color(0xFFD4C28E), // Dark sand
      Color(0xFFFFF0D4), // Highlight
      Color(0xFFB8A676), // Shadow
    ],
  );

  static const water = TilePalette(
    name: 'Water',
    colors: [
      Color(0xFF3D7EAA), // Base blue
      Color(0xFF5A9BC9), // Light blue
      Color(0xFF2A5A7A), // Dark blue
      Color(0xFF7CB8E8), // Highlight/foam
      Color(0xFF1D4A66), // Deep shadow
    ],
  );

  static const lava = TilePalette(
    name: 'Lava',
    colors: [
      Color(0xFFD44000), // Base orange
      Color(0xFFFF6B1A), // Light orange
      Color(0xFFAA3000), // Dark red
      Color(0xFFFFD700), // Yellow highlight
      Color(0xFF660000), // Dark shadow
    ],
  );

  static const snow = TilePalette(
    name: 'Snow',
    colors: [
      Color(0xFFFFFFFF), // White
      Color(0xFFF0F8FF), // Ice blue tint
      Color(0xFFE0E8F0), // Shadow
      Color(0xFFD0E0F0), // Deep shadow
      Color(0xFFA8C8E8), // Blue accent
    ],
  );

  static const ice = TilePalette(
    name: 'Ice',
    colors: [
      Color(0xFFB0E0FF), // Base ice
      Color(0xFFD0F0FF), // Light ice
      Color(0xFF80C0E8), // Medium ice
      Color(0xFFFFFFFF), // Highlight
      Color(0xFF60A0D0), // Shadow
    ],
  );

  // ===== DUNGEON PALETTES =====

  static const brick = TilePalette(
    name: 'Brick',
    colors: [
      Color(0xFF8B4513), // Base brick
      Color(0xFFA65D3F), // Light brick
      Color(0xFF6B3410), // Dark brick
      Color(0xFFC07050), // Highlight
      Color(0xFF4A2508), // Shadow/mortar
    ],
  );

  static const cobblestone = TilePalette(
    name: 'Cobblestone',
    colors: [
      Color(0xFF5A5A5A), // Base
      Color(0xFF7A7A7A), // Light
      Color(0xFF3A3A3A), // Dark
      Color(0xFF9A9A9A), // Highlight
      Color(0xFF2A2A2A), // Shadow
    ],
  );

  static const wood = TilePalette(
    name: 'Wood',
    colors: [
      Color(0xFF8B5A2B), // Base wood
      Color(0xFFA67040), // Light wood
      Color(0xFF6B4020), // Dark wood
      Color(0xFFC08050), // Highlight
      Color(0xFF4A2810), // Shadow
    ],
  );

  static const darkBrick = TilePalette(
    name: 'Dark Brick',
    colors: [
      Color(0xFF3A3A40), // Base
      Color(0xFF4A4A55), // Light
      Color(0xFF2A2A30), // Dark
      Color(0xFF5A5A68), // Highlight
      Color(0xFF1A1A20), // Shadow
    ],
  );

  // ===== FANTASY PALETTES =====

  static const crystal = TilePalette(
    name: 'Crystal',
    colors: [
      Color(0xFF9966CC), // Base purple
      Color(0xFFBB88EE), // Light
      Color(0xFF7744AA), // Dark
      Color(0xFFDDAAFF), // Highlight
      Color(0xFF553388), // Shadow
    ],
  );

  static const magic = TilePalette(
    name: 'Magic',
    colors: [
      Color(0xFF00AAFF), // Cyan
      Color(0xFF66CCFF), // Light cyan
      Color(0xFFFF00AA), // Magenta
      Color(0xFFFFFFFF), // White highlight
      Color(0xFF0066AA), // Dark cyan
    ],
  );

  static const void_ = TilePalette(
    name: 'Void',
    colors: [
      Color(0xFF1A1A2E), // Base dark
      Color(0xFF2A2A4E), // Lighter
      Color(0xFF0A0A1A), // Darkest
      Color(0xFF4A4A7E), // Highlight
      Color(0xFF000008), // Shadow
    ],
  );

  // ===== NATURE PALETTES =====

  static const forest = TilePalette(
    name: 'Forest',
    colors: [
      Color(0xFF2D5A27), // Deep green
      Color(0xFF4A7C3F), // Medium green
      Color(0xFF1A3A18), // Dark green
      Color(0xFF6B9E5A), // Light green
      Color(0xFF3D2817), // Brown trunk
    ],
  );

  static const autumn = TilePalette(
    name: 'Autumn',
    colors: [
      Color(0xFFD4652F), // Orange
      Color(0xFFE8A040), // Yellow
      Color(0xFFAA4420), // Dark orange
      Color(0xFFC74040), // Red
      Color(0xFF6B4020), // Brown
    ],
  );

  static const flower = TilePalette(
    name: 'Flower',
    colors: [
      Color(0xFFFF6B8A), // Pink
      Color(0xFFFFAA00), // Yellow center
      Color(0xFF4A7C23), // Green stem
      Color(0xFFFFFFFF), // White petals
      Color(0xFFFF4466), // Dark pink
    ],
  );

  /// Get all available palettes
  static List<TilePalette> get all => [
        grass,
        dirt,
        stone,
        sand,
        water,
        lava,
        snow,
        ice,
        brick,
        cobblestone,
        wood,
        darkBrick,
        crystal,
        magic,
        void_,
        forest,
        autumn,
        flower,
      ];

  /// Get palette by name
  static TilePalette? getByName(String name) {
    try {
      return all.firstWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
