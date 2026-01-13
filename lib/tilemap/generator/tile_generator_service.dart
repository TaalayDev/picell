import 'dart:math';
import 'dart:typed_data';

import '../../data/models/tilemap_model.dart';
import 'tile_generator_config.dart';
import 'tile_palette.dart';
import 'tiles/stone_tiles.dart';

/// Available tile generator types
enum TileGeneratorType {
  // Original types
  grass('Grass', 'Natural grass terrain'),
  dirt('Dirt', 'Earthy dirt with rocks'),
  stone('Stone', 'Rocky stone surface'),
  water('Water', 'Flowing water'),
  brick('Brick', 'Classic brick pattern'),
  wood('Wood', 'Wooden planks'),
  lava('Lava', 'Molten lava'),
  crystal('Crystal', 'Mystical crystals'),
  snow('Snow', 'Fresh snow'),
  sand('Sand', 'Desert sand'),
  cobblestone('Cobblestone', 'Stone path'),

  // New stone tile types from reference image
  horizontalStoneBrick('Horizontal Stone Brick', 'Layered horizontal stone bricks'),
  horizontalStoneBrickWorn('Worn Stone Brick', 'Weathered horizontal stone bricks'),
  irregularCobblestone('Irregular Cobblestone', 'Rough irregular cobblestone'),
  vineCoveredStone('Vine-Covered Stone', 'Ancient stone with climbing vines'),
  roughStone('Rough Stone', 'Heavily textured rough stone'),
  stoneBrickTransition('Stone-Brick Transition', 'Stone transitioning to brick'),
  verticalStoneColumn('Vertical Stone Column', 'Vertical stone column pattern'),
  stoneGrassTop('Stone with Grass', 'Stone with grass growing on top'),
  ornateStoneBlock('Ornate Stone Block', 'Decorative carved stone block'),
  darkVerticalPlanks('Dark Planks', 'Dark wooden vertical planks'),
  iceFrostStone('Ice Frost Stone', 'Stone with ice and icicles'),
  largeBrickPattern('Large Brick Pattern', 'Large format brick blocks'),
  stoneWithDoor('Stone with Door', 'Stone wall with door frame');

  final String displayName;
  final String description;

  const TileGeneratorType(this.displayName, this.description);
}

/// Service for generating tiles
class TileGeneratorService {
  TileGeneratorService._();
  static final instance = TileGeneratorService._();

  /// Get all available generator types
  List<TileGeneratorType> get availableTypes => TileGeneratorType.values;

  /// Get stone-specific tile types
  List<TileGeneratorType> get stoneTileTypes => [
        TileGeneratorType.horizontalStoneBrick,
        TileGeneratorType.horizontalStoneBrickWorn,
        TileGeneratorType.irregularCobblestone,
        TileGeneratorType.vineCoveredStone,
        TileGeneratorType.roughStone,
        TileGeneratorType.stoneBrickTransition,
        TileGeneratorType.verticalStoneColumn,
        TileGeneratorType.stoneGrassTop,
        TileGeneratorType.ornateStoneBlock,
        TileGeneratorType.darkVerticalPlanks,
        TileGeneratorType.iceFrostStone,
        TileGeneratorType.largeBrickPattern,
        TileGeneratorType.stoneWithDoor,
      ];

  /// Create a generator config for the given type
  TileGeneratorConfig createConfig({
    required TileGeneratorType type,
    required int tileWidth,
    required int tileHeight,
    int variantCount = 4,
    int? seed,
    TilePalette? customPalette,
  }) {
    switch (type) {
      // Original types
      case TileGeneratorType.grass:
        return GrassTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
          includeFlowers: true,
        );
      case TileGeneratorType.dirt:
        return DirtTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.stone:
        return StoneTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.water:
        return WaterTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.brick:
        return BrickTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.wood:
        return WoodTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.lava:
        return LavaTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.crystal:
        return CrystalTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.snow:
        return SnowTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.sand:
        return _SandTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.cobblestone:
        return _CobblestoneTileConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );

      // New stone tile types
      case TileGeneratorType.horizontalStoneBrick:
        return HorizontalStoneBrickConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.horizontalStoneBrickWorn:
        return HorizontalStoneBrickConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
          addWear: true,
          wearIntensity: 0.15,
        );
      case TileGeneratorType.irregularCobblestone:
        return IrregularCobblestoneConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.vineCoveredStone:
        return VineCoveredStoneConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.roughStone:
        return RoughStoneConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.stoneBrickTransition:
        return StoneBrickTransitionConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.verticalStoneColumn:
        return VerticalStoneColumnConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.stoneGrassTop:
        return StoneWithGrassTopConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.ornateStoneBlock:
        return OrnateStoneBlockConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.darkVerticalPlanks:
        return DarkVerticalPlanksConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.iceFrostStone:
        return IceFrostStoneConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.largeBrickPattern:
        return LargeBrickPatternConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
      case TileGeneratorType.stoneWithDoor:
        return StoneWithDoorConfig(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          variantCount: variantCount,
          seed: seed,
          customPalette: customPalette,
        );
    }
  }

  /// Generate tiles for the given type
  List<Tile> generateTiles({
    required TileGeneratorType type,
    required int tileWidth,
    required int tileHeight,
    int variantCount = 4,
    int? seed,
    TilePalette? customPalette,
  }) {
    final config = createConfig(
      type: type,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      variantCount: variantCount,
      seed: seed,
      customPalette: customPalette,
    );

    final generatedTiles = config.generateTiles();
    return generatedTiles.asMap().entries.map((entry) {
      return Tile(
        id: entry.key,
        name: entry.value.name,
        width: entry.value.width,
        height: entry.value.height,
        pixels: entry.value.pixels,
      );
    }).toList();
  }

  /// Generate a complete tileset with multiple types
  List<Tile> generateMixedTileset({
    required List<TileGeneratorType> types,
    required int tileWidth,
    required int tileHeight,
    int variantsPerType = 2,
    int? seed,
  }) {
    final tiles = <Tile>[];
    var nextId = 0;

    for (final type in types) {
      final typeTiles = generateTiles(
        type: type,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        variantCount: variantsPerType,
        seed: seed != null ? seed + type.index : null,
      );

      for (final tile in typeTiles) {
        tiles.add(tile.copyWith(id: nextId++));
      }
    }

    return tiles;
  }

  /// Generate a dungeon-themed tileset with all stone types
  List<Tile> generateDungeonTileset({
    required int tileWidth,
    required int tileHeight,
    int variantsPerType = 2,
    int? seed,
  }) {
    return generateMixedTileset(
      types: stoneTileTypes,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      variantsPerType: variantsPerType,
      seed: seed,
    );
  }

  /// Get the default palette for a type
  TilePalette getPaletteForType(TileGeneratorType type) {
    switch (type) {
      case TileGeneratorType.grass:
        return TilePalettes.grass;
      case TileGeneratorType.dirt:
        return TilePalettes.dirt;
      case TileGeneratorType.stone:
        return TilePalettes.stone;
      case TileGeneratorType.water:
        return TilePalettes.water;
      case TileGeneratorType.brick:
        return TilePalettes.brick;
      case TileGeneratorType.wood:
        return TilePalettes.wood;
      case TileGeneratorType.lava:
        return TilePalettes.lava;
      case TileGeneratorType.crystal:
        return TilePalettes.crystal;
      case TileGeneratorType.snow:
        return TilePalettes.snow;
      case TileGeneratorType.sand:
        return TilePalettes.sand;
      case TileGeneratorType.cobblestone:
        return TilePalettes.cobblestone;

      // Stone tile palettes
      case TileGeneratorType.horizontalStoneBrick:
      case TileGeneratorType.horizontalStoneBrickWorn:
      case TileGeneratorType.roughStone:
      case TileGeneratorType.stoneBrickTransition:
      case TileGeneratorType.stoneGrassTop:
      case TileGeneratorType.iceFrostStone:
      case TileGeneratorType.largeBrickPattern:
      case TileGeneratorType.stoneWithDoor:
        return StoneTilePalettes.grayStone;
      case TileGeneratorType.irregularCobblestone:
      case TileGeneratorType.verticalStoneColumn:
      case TileGeneratorType.ornateStoneBlock:
        return StoneTilePalettes.darkStone;
      case TileGeneratorType.vineCoveredStone:
        return StoneTilePalettes.grayStone;
      case TileGeneratorType.darkVerticalPlanks:
        return StoneTilePalettes.darkWood;
    }
  }
}

/// Sand tile generator (internal)
class _SandTileConfig extends TerrainTileConfig {
  _SandTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.sand);

  @override
  String get name => 'Sand';

  @override
  String get description => 'Desert sand with dunes';

  @override
  String get iconName => 'beach_access';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseVal = noise2D(x / 4.0 + variantIndex * 5, y / 4.0, random, 2);
        final colorIndex = (noiseVal * 3).floor().clamp(0, 2);
        pixels[y * tileWidth + x] = addNoise(palette.colors[colorIndex], random, 0.03);
      }
    }

    // Add occasional pebbles
    if (random.nextDouble() < 0.2) {
      final px = random.nextInt(tileWidth);
      final py = random.nextInt(tileHeight);
      pixels[py * tileWidth + px] = colorToInt(TilePalettes.stone.primary);
    }

    return pixels;
  }
}

/// Cobblestone tile generator (internal)
class _CobblestoneTileConfig extends TerrainTileConfig {
  _CobblestoneTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.cobblestone);

  @override
  String get name => 'Cobblestone';

  @override
  String get description => 'Cobblestone path';

  @override
  String get iconName => 'grid_on';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    // Fill with mortar
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Add cobblestones
    final stoneCount = (tileWidth * tileHeight / 16).round();
    for (int s = 0; s < stoneCount; s++) {
      final cx = random.nextInt(tileWidth);
      final cy = random.nextInt(tileHeight);
      final size = random.nextInt(2) + 2;
      final stoneColor = random.nextBool() ? palette.primary : palette.secondary;

      for (int dy = -size ~/ 2; dy <= size ~/ 2; dy++) {
        for (int dx = -size ~/ 2; dx <= size ~/ 2; dx++) {
          final px = cx + dx;
          final py = cy + dy;
          if (px >= 0 && px < tileWidth && py >= 0 && py < tileHeight) {
            if (dx.abs() + dy.abs() < size) {
              pixels[py * tileWidth + px] = addNoise(stoneColor, random, 0.05);
            }
          }
        }
      }
    }

    return pixels;
  }
}
