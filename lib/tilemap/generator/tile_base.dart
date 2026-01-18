import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'tile_palette.dart';
import 'tiles/decoration_tiles.dart';
import 'tiles/environment_tiles.dart';
import 'tiles/extended_urban.dart';
import 'tiles/platformer_blocks.dart';
import 'tiles/platformer_tiles.dart';
import 'tiles/terrain.dart';
import 'tiles/structure.dart';
import 'tiles/liquid.dart';
import 'tiles/nature.dart';
import 'tiles/special.dart';
import 'tiles/specialized.dart';
import 'tiles/stone.dart';
import 'tiles/extended_stone.dart';
import 'tiles/urban_tiles.dart' hide HerringboneBrickTile;
import 'tiles/varied.dart';

/// Base class for all tile types with powerful abstraction
abstract class TileBase {
  TileBase(this.id);

  /// Unique identifier for this tile type
  String id;

  /// Display name
  String get name;

  /// Description of the tile
  String get description;

  /// Category for grouping (Terrain, Structure, Nature, etc.)
  TileCategory get category;

  /// Icon name for UI display
  String get iconName;

  /// The color palette used for generation
  TilePalette get palette;

  /// Whether this tile can be rotated
  bool get supportsRotation => false;

  /// Whether this tile supports edge variations
  bool get supportsEdgeVariations => false;

  /// Whether this tile can connect to adjacent tiles
  bool get supportsAutoTiling => false;

  /// Tags for filtering and search
  List<String> get tags;

  /// Whether this tile is animated
  bool get animated => false;

  /// Number of animation frames
  int get frameCount => 1;

  /// Duration of each frame in milliseconds
  int get frameSpeed => 100;

  /// Generate a specific frame for animated tiles
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    return generate(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
    );
  }

  /// Generate pixel data for a tile
  Uint32List generate({
    required int width,
    required int height,
    int seed,
    TileVariation variation,
  });

  /// Generate multiple variants
  List<Uint32List> generateVariants({
    required int width,
    required int height,
    int count = 4,
    int? baseSeed,
  }) {
    final random = Random(baseSeed);
    return List.generate(count, (i) {
      return generate(
        width: width,
        height: height,
        seed: random.nextInt(1000000),
        variation: TileVariation.values[i % TileVariation.values.length],
      );
    });
  }

  /// Helper to convert Color to ARGB int
  int colorToInt(Color color) {
    return color.value;
  }

  /// Helper to blend two colors
  int blendColors(Color c1, Color c2, double t) {
    final r = (c1.red + (c2.red - c1.red) * t).round();
    final g = (c1.green + (c2.green - c1.green) * t).round();
    final b = (c1.blue + (c2.blue - c1.blue) * t).round();
    final a = (c1.alpha + (c2.alpha - c1.alpha) * t).round();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Helper to add noise variation to a color
  int addNoise(Color baseColor, Random random, double intensity) {
    final variation = ((random.nextDouble() - 0.5) * 2 * intensity * 255).round();
    final r = (baseColor.red + variation).clamp(0, 255);
    final g = (baseColor.green + variation).clamp(0, 255);
    final b = (baseColor.blue + variation).clamp(0, 255);
    return (baseColor.alpha << 24) | (r << 16) | (g << 8) | b;
  }

  /// Generate Perlin-like noise value
  double noise2D(double x, double y, int octaves) {
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

  double _smoothNoise(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    double hash(int x, int y) {
      final n = x + y * 57;
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
}

/// Tile categories for organization
enum TileCategory {
  terrain('Terrain', 'Ground surfaces like grass, dirt, sand'),
  structure('Structure', 'Man-made structures like walls, floors'),
  nature('Nature', 'Natural elements like rocks, trees'),
  liquid('Liquid', 'Water, lava, and other fluids'),
  special('Special', 'Magical and special effect tiles'),
  decoration('Decoration', 'Decorative elements'),
  dungeon('Dungeon', 'Dungeon and cave tiles'),
  urban('Urban', 'City and road tiles'),
  varied('Varied', 'Tiles with varied color palettes'),
  platformer('Platformer', 'Tiles for platformer games');

  final String name;
  final String description;
  const TileCategory(this.name, this.description);
}

/// Tile variations for generation diversity
enum TileVariation {
  standard,
  weathered,
  mossy,
  cracked,
  pristine,
  frozen,
  overgrown,
}

// ============================================================================
// TILE REGISTRY
// ============================================================================

/// Registry of all available tile types
class TileRegistry {
  TileRegistry._();
  static final instance = TileRegistry._();

  /// All registered tile types
  final Map<String, TileBase Function()> _registry = {
    // =========================================================================
    // TERRAIN TILES (Original)
    // =========================================================================
    'grass': () => GrassTile('grass'),
    'grass_flowers': () => GrassTile('grass_flowers', includeFlowers: true),
    'dirt': () => DirtTile('dirt'),
    'sand': () => SandTile('sand'),
    'snow': () => SnowTile('snow'),

    // =========================================================================
    // STRUCTURE TILES (Original)
    // =========================================================================
    'wall_brick': () => WallTile('wall_brick', style: WallStyle.brick),
    'wall_stone': () => WallTile('wall_stone', style: WallStyle.stone),
    'wall_dark': () => WallTile('wall_dark', style: WallStyle.darkBrick),
    'wall_cobble': () => WallTile('wall_cobble', style: WallStyle.cobblestone),
    'floor_wood': () => FloorTile('floor_wood', style: FloorStyle.wood),
    'floor_stone': () => FloorTile('floor_stone', style: FloorStyle.stone),
    'floor_tile': () => FloorTile('floor_tile', style: FloorStyle.tile),

    // =========================================================================
    // LIQUID TILES (Original)
    // =========================================================================
    'water': () => WaterTile('water'),
    'lava': () => LavaTile('lava'),

    // =========================================================================
    // NATURE TILES
    // =========================================================================
    // Rocks and Stones
    'stone': () => StoneTile('stone'),
    'stone_mossy': () => StoneTile('stone_mossy', addMoss: true),
    'stone_large': () => StoneTile('stone_large', large: true),
    'stone_brown': () => StoneTile('stone_brown', rockPalette: NaturePalettes.brownRock),
    'rock_pile': () => RockPileTile('rock_pile'),
    'boulder': () => BoulderTile('boulder'),
    'boulder_cracked': () => BoulderTile('boulder_cracked', cracked: true),

    // Trees
    'tree_trunk_oak': () => TreeTrunkTile('tree_trunk_oak', oak: true),
    'tree_trunk_pine': () => TreeTrunkTile('tree_trunk_pine', oak: false),
    'tree_foliage': () => TreeFoliageTile('tree_foliage'),
    'tree_foliage_autumn': () => TreeFoliageTile('tree_foliage_autumn', autumn: true),
    'tree_foliage_cherry': () => TreeFoliageTile('tree_foliage_cherry', cherry: true),
    'pine_tree': () => PineTreeTile('pine_tree'),
    'pine_tree_snowy': () => PineTreeTile('pine_tree_snowy', snow: true),

    // Flowers
    'flower_red': () => FlowerTile('flower_red', colorPalette: NaturePalettes.flowerRed),
    'flower_yellow': () => FlowerTile('flower_yellow', colorPalette: NaturePalettes.flowerYellow),
    'flower_blue': () => FlowerTile('flower_blue', colorPalette: NaturePalettes.flowerBlue),
    'flower_purple': () => FlowerTile('flower_purple', colorPalette: NaturePalettes.flowerPurple),
    'flower_patch_red': () => FlowerPatchTile('flower_patch_red', colorPalette: NaturePalettes.flowerRed),
    'flower_patch_yellow': () => FlowerPatchTile('flower_patch_yellow', colorPalette: NaturePalettes.flowerYellow),
    'flower_patch_mixed': () => FlowerPatchTile('flower_patch_mixed', flowerCount: 5),

    // Grass and Vegetation
    'tall_grass': () => TallGrassTile('tall_grass'),
    'tall_grass_dense': () => TallGrassTile('tall_grass_dense', dense: true),
    'reed': () => ReedTile('reed'),
    'cattail': () => ReedTile('cattail', cattail: true),
    'bush': () => BushTile('bush'),
    'berry_bush': () => BushTile('berry_bush', berries: true),

    // Mushrooms
    'mushroom': () => MushroomTile('mushroom'),
    'mushroom_glowing': () => MushroomTile('mushroom_glowing', glowing: true),
    'mushroom_cluster': () => MushroomTile('mushroom_cluster', cluster: true),

    // Crystals
    'crystal_blue': () => NatureCrystalTile('crystal_blue'),
    'crystal_purple': () => NatureCrystalTile('crystal_purple', crystalPalette: NaturePalettes.amethyst),
    'crystal_green': () => NatureCrystalTile('crystal_green', crystalPalette: NaturePalettes.emerald),

    // Wood
    'log': () => LogTile('log'),
    'log_mossy': () => LogTile('log_mossy', mossy: true),
    'tree_stump': () => StumpTile('tree_stump'),

    // Water Plants
    'lily_pad': () => NatureLilyPadTile('lily_pad'),
    'lily_pad_flower': () => NatureLilyPadTile('lily_pad_flower', withFlower: true),
    'vine_hanging': () => VineTile('vine_hanging', hanging: true),
    'vine_climbing': () => VineTile('vine_climbing', hanging: false),

    // =========================================================================
    // SPECIAL TILES (Original)
    // =========================================================================
    'crystal': () => CrystalTile('crystal'),

    // =========================================================================
    // URBAN / ROAD TILES (NEW)
    // =========================================================================
    'asphalt': () => AsphaltTile('asphalt'),
    'asphalt_cracked': () => AsphaltTile('asphalt_cracked', addCracks: true),
    'asphalt_patched': () => AsphaltTile('asphalt_patched', addPatches: true),
    'road_center_line': () => RoadCenterLineTile('road_center_line'),
    'road_center_line_dashed': () => RoadCenterLineTile('road_center_line_dashed', dashed: true),
    'road_double_yellow': () => RoadCenterLineTile('road_double_yellow', doubleYellow: true),
    'road_edge_left': () => RoadEdgeLineTile('road_edge_left', leftEdge: true),
    'road_edge_right': () => RoadEdgeLineTile('road_edge_right', leftEdge: false),
    'parking_lot': () => ParkingLotTile('parking_lot'),

    // =========================================================================
    // CONCRETE TILES (NEW)
    // =========================================================================
    'concrete': () => ConcreteTile('concrete'),
    'concrete_joints': () => ConcreteTile('concrete_joints', addJoints: true),
    'concrete_cracked': () => ConcreteTile('concrete_cracked', addCracks: true),
    'concrete_slab': () => ConcreteSlabTile('concrete_slab'),
    'concrete_slab_small': () => ConcreteSlabTile('concrete_slab_small', slabSize: 4),

    // =========================================================================
    // GRASS VARIATIONS (NEW)
    // =========================================================================
    'lush_grass': () => LushGrassTile('lush_grass'),
    'lush_grass_dense': () => LushGrassTile('lush_grass_dense', density: 0.6),
    'worn_grass': () => WornGrassTile('worn_grass'),
    'dry_grass': () => DryGrassTile('dry_grass'),

    // =========================================================================
    // DIRT AND SOIL TILES (NEW)
    // =========================================================================
    'soil': () => SoilTile('soil'),
    'soil_rocky': () => SoilTile('soil_rocky', addRocks: true),
    'cracked_earth': () => CrackedEarthTile('cracked_earth'),
    'gravel': () => GravelTile('gravel'),
    'fine_gravel': () => GravelTile('fine_gravel', fine: true),

    // =========================================================================
    // ROCK AND CLIFF TILES (NEW)
    // =========================================================================
    'rock_cliff': () => RockCliffTile('rock_cliff'),
    'mossy_rock': () => MossyRockTile('mossy_rock'),

    // =========================================================================
    // ROOF TILES (NEW)
    // =========================================================================
    'roof_tile': () => RoofTileTile('roof_tile'),
    'roof_tile_large': () => RoofTileTile('roof_tile_large', tileHeight: 6),
    'slate_roof': () => SlateRoofTile('slate_roof'),
    'shingle_roof': () => ShingleRoofTile('shingle_roof'),

    // =========================================================================
    // PAVING AND FLOOR TILES (NEW)
    // =========================================================================
    'cobblestone_paving': () => CobblestonePavingTile('cobblestone_paving'),
    'cobblestone_irregular': () => CobblestonePavingTile('cobblestone_irregular', irregular: true),
    'checkered_floor': () => CheckeredFloorTile('checkered_floor'),
    'checkered_floor_small': () => CheckeredFloorTile('checkered_floor_small', tileSize: 2),
    'square_floor_tile': () => SquareFloorTile('square_floor_tile'),
    'beach_sand': () => BeachSandTile('beach_sand'),
    'beach_sand_shells': () => BeachSandTile('beach_sand_shells', addShells: true),

    // =========================================================================
    // BRICK PATTERN VARIATIONS (NEW)
    // =========================================================================
    'running_bond_brick': () => RunningBondBrickTile('running_bond_brick'),
    'stack_bond_brick': () => StackBondBrickTile('stack_bond_brick'),
    'basket_weave_brick': () => BasketWeaveBrickTile('basket_weave_brick'),
    'diagonal_brick': () => DiagonalBrickTile('diagonal_brick'),
    'herringbone_brick': () => HerringboneBrickTile('herringbone_brick'),

    // =========================================================================
    // STONE PATTERN VARIATIONS (NEW)
    // =========================================================================
    'flagstone': () => FlagstoneTile('flagstone'),
    'ashlar_stone': () => AshlarStoneTile('ashlar_stone'),
    'river_rock': () => RiverRockTile('river_rock'),

    // =========================================================================
    // DECORATIVE FLOOR TILES (NEW)
    // =========================================================================
    'marble_floor': () => MarbleFloorTile('marble_floor'),
    'marble_floor_small': () => MarbleFloorTile('marble_floor_small', tileSize: 4),
    'granite_floor': () => GraniteFloorTile('granite_floor'),
    'ceramic_tile': () => CeramicTileTile('ceramic_tile'),

    // =========================================================================
    // WOOD AND METAL SURFACES (NEW)
    // =========================================================================
    'weathered_wood': () => WeatheredWoodTile('weathered_wood'),
    'weathered_wood_horizontal': () => WeatheredWoodTile('weathered_wood_horizontal', vertical: false),
    'corrugated_metal': () => CorrugatedMetalTile('corrugated_metal'),
    'corrugated_metal_horizontal': () => CorrugatedMetalTile('corrugated_metal_horizontal', vertical: false),
    'rusty_metal': () => RustyMetalTile('rusty_metal'),
    'diamond_plate': () => DiamondPlateTile('diamond_plate'),
    'metal_grating': () => GratingTile('metal_grating'),
    'metal_grating_fine': () => GratingTile('metal_grating_fine', gridSize: 2),

    // =========================================================================
    // EXISTING DUNGEON STONE TILES
    // =========================================================================
    'horizontal_stone_brick': () => HorizontalStoneBrickTile('horizontal_stone_brick'),
    'horizontal_stone_brick_light': () => HorizontalStoneBrickTile(
          'horizontal_stone_brick_light',
          style: HorizontalBrickStyle.light,
        ),
    'horizontal_stone_brick_worn': () => HorizontalStoneBrickTile(
          'horizontal_stone_brick_worn',
          style: HorizontalBrickStyle.worn,
        ),
    'vine_covered_stone': () => VineCoveredStoneTile('vine_covered_stone'),
    'rough_textured_stone': () => RoughTexturedStoneTile('rough_textured_stone'),
    'stone_brick_transition': () => StoneBrickTransitionTile('stone_brick_transition'),
    'vertical_stone_column': () => VerticalStoneColumnTile('vertical_stone_column'),
    'stone_with_grass_top': () => StoneWithGrassTopTile('stone_with_grass_top'),
    'ornate_stone_block': () => OrnateStoneBlockTile('ornate_stone_block'),
    'large_stone_blocks': () => LargeStoneBlocksTile('large_stone_blocks'),
    'dark_vertical_planks': () => DarkVerticalPlanksTile('dark_vertical_planks'),
    'ice_frost_stone': () => IceFrostStoneTile('ice_frost_stone'),
    'large_brick_pattern': () => LargeBrickPatternTile('large_brick_pattern'),
    'stone_with_door': () => StoneWithDoorTile('stone_with_door'),
    'cracked_stone_floor': () => CrackedStoneFloorTile('cracked_stone_floor'),
    'mossy_dungeon_wall': () => MossyDungeonWallTile('mossy_dungeon_wall'),
    'ancient_ruin_stone': () => AncientRuinStoneTile('ancient_ruin_stone'),
    'carved_stone_tile': () => CarvedStoneTileTile('carved_stone_tile'),

    // =========================================================================
    // EXTENDED GRAY STONE TILES
    // =========================================================================
    'rough_stone_floor': () => RoughStoneFloorTile('rough_stone_floor'),
    'vine_stone_floor': () => VineStoneFloorTile('vine_stone_floor'),
    'regular_stone_brick': () => RegularStoneBrickTile('regular_stone_brick'),
    'vertical_stone_stripes': () => VerticalStoneStripesTile('vertical_stone_stripes'),
    'concentric_square_stone': () => ConcentricSquareStoneTile('concentric_square_stone'),
    'cross_hatch_stone': () => CrossHatchStoneTile('cross_hatch_stone'),
    'large_bordered_stone_block': () => LargeBorderedStoneBlockTile('large_bordered_stone_block'),
    'horizontal_stone_slab': () => HorizontalStoneSlabTile('horizontal_stone_slab'),
    'mossy_large_stone': () => MossyLargeStoneTile('mossy_large_stone'),
    'inset_square_stone': () => InsetSquareStoneTile('inset_square_stone'),
    'striped_border_stone': () => StripedBorderStoneTile('striped_border_stone'),
    'horizontal_lined_stone': () => HorizontalLinedStoneTile('horizontal_lined_stone'),

    // =========================================================================
    // EXTENDED BROWN BRICK TILES
    // =========================================================================
    'rough_brown_brick_floor': () => RoughBrownBrickFloorTile('rough_brown_brick_floor'),
    'horizontal_brown_brick': () => HorizontalBrownBrickTile('horizontal_brown_brick'),
    'diagonal_brown_brick': () => DiagonalBrownBrickTile('diagonal_brown_brick'),
    'vine_brown_brick': () => VineBrownBrickTile('vine_brown_brick'),
    'standard_brown_brick_wall': () => StandardBrownBrickWallTile('standard_brown_brick_wall'),
    'grid_brown_brick': () => GridBrownBrickTile('grid_brown_brick'),
    'large_bordered_brown_brick': () => LargeBorderedBrownBrickTile('large_bordered_brown_brick'),
    'horizontal_brown_brick_slab': () => HorizontalBrownBrickSlabTile('horizontal_brown_brick_slab'),

    // =========================================================================
    // RED ROOF VARIANTS
    // =========================================================================
    'roof_shingle_red': () => ColoredRoofShingleTile('roof_shingle_red', colorPalette: ColoredRoofPalettes.redRoof),
    'roof_curved_red': () => ColoredRoofTileTile('roof_curved_red', colorPalette: ColoredRoofPalettes.redRoof),
    'small_brick_red': () => ColoredSmallBrickTile('small_brick_red', colorPalette: ColoredRoofPalettes.redRoof),

    // =========================================================================
    // ORANGE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_orange': () =>
        ColoredRoofShingleTile('roof_shingle_orange', colorPalette: ColoredRoofPalettes.orangeRoof),
    'roof_curved_orange': () => ColoredRoofTileTile('roof_curved_orange', colorPalette: ColoredRoofPalettes.orangeRoof),
    'small_brick_orange': () =>
        ColoredSmallBrickTile('small_brick_orange', colorPalette: ColoredRoofPalettes.orangeRoof),

    // =========================================================================
    // TEAL ROOF VARIANTS
    // =========================================================================
    'roof_shingle_teal': () => ColoredRoofShingleTile('roof_shingle_teal', colorPalette: ColoredRoofPalettes.tealRoof),
    'roof_curved_teal': () => ColoredRoofTileTile('roof_curved_teal', colorPalette: ColoredRoofPalettes.tealRoof),
    'small_brick_teal': () => ColoredSmallBrickTile('small_brick_teal', colorPalette: ColoredRoofPalettes.tealRoof),

    // =========================================================================
    // PURPLE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_purple': () =>
        ColoredRoofShingleTile('roof_shingle_purple', colorPalette: ColoredRoofPalettes.purpleRoof),
    'roof_curved_purple': () => ColoredRoofTileTile('roof_curved_purple', colorPalette: ColoredRoofPalettes.purpleRoof),
    'small_brick_purple': () =>
        ColoredSmallBrickTile('small_brick_purple', colorPalette: ColoredRoofPalettes.purpleRoof),

    // =========================================================================
    // MAROON ROOF VARIANTS
    // =========================================================================
    'roof_shingle_maroon': () =>
        ColoredRoofShingleTile('roof_shingle_maroon', colorPalette: ColoredRoofPalettes.maroonRoof),
    'roof_curved_maroon': () => ColoredRoofTileTile('roof_curved_maroon', colorPalette: ColoredRoofPalettes.maroonRoof),
    'small_brick_maroon': () =>
        ColoredSmallBrickTile('small_brick_maroon', colorPalette: ColoredRoofPalettes.maroonRoof),

    // =========================================================================
    // BLUE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_blue': () => ColoredRoofShingleTile('roof_shingle_blue', colorPalette: ColoredRoofPalettes.blueRoof),
    'roof_curved_blue': () => ColoredRoofTileTile('roof_curved_blue', colorPalette: ColoredRoofPalettes.blueRoof),
    'small_brick_blue': () => ColoredSmallBrickTile('small_brick_blue', colorPalette: ColoredRoofPalettes.blueRoof),

    // =========================================================================
    // NAVY ROOF VARIANTS
    // =========================================================================
    'roof_shingle_navy': () => ColoredRoofShingleTile('roof_shingle_navy', colorPalette: ColoredRoofPalettes.navyRoof),
    'roof_curved_navy': () => ColoredRoofTileTile('roof_curved_navy', colorPalette: ColoredRoofPalettes.navyRoof),
    'small_brick_navy': () => ColoredSmallBrickTile('small_brick_navy', colorPalette: ColoredRoofPalettes.navyRoof),

    // =========================================================================
    // GRAY ROOF VARIANTS
    // =========================================================================
    'roof_shingle_gray': () => ColoredRoofShingleTile('roof_shingle_gray', colorPalette: ColoredRoofPalettes.grayRoof),
    'roof_curved_gray': () => ColoredRoofTileTile('roof_curved_gray', colorPalette: ColoredRoofPalettes.grayRoof),
    'small_brick_gray': () => ColoredSmallBrickTile('small_brick_gray', colorPalette: ColoredRoofPalettes.grayRoof),

    // =========================================================================
    // DARK GRAY ROOF VARIANTS
    // =========================================================================
    'roof_shingle_dark_gray': () =>
        ColoredRoofShingleTile('roof_shingle_dark_gray', colorPalette: ColoredRoofPalettes.darkGrayRoof),
    'roof_curved_dark_gray': () =>
        ColoredRoofTileTile('roof_curved_dark_gray', colorPalette: ColoredRoofPalettes.darkGrayRoof),
    'small_brick_dark_gray': () =>
        ColoredSmallBrickTile('small_brick_dark_gray', colorPalette: ColoredRoofPalettes.darkGrayRoof),

    // =========================================================================
    // BROWN ROOF VARIANTS
    // =========================================================================
    'roof_shingle_brown': () =>
        ColoredRoofShingleTile('roof_shingle_brown', colorPalette: ColoredRoofPalettes.brownRoof),
    'roof_curved_brown': () => ColoredRoofTileTile('roof_curved_brown', colorPalette: ColoredRoofPalettes.brownRoof),
    'small_brick_brown': () => ColoredSmallBrickTile('small_brick_brown', colorPalette: ColoredRoofPalettes.brownRoof),

    // =========================================================================
    // GREEN ROOF VARIANTS
    // =========================================================================
    'roof_shingle_green': () =>
        ColoredRoofShingleTile('roof_shingle_green', colorPalette: ColoredRoofPalettes.greenRoof),
    'roof_curved_green': () => ColoredRoofTileTile('roof_curved_green', colorPalette: ColoredRoofPalettes.greenRoof),
    'small_brick_green': () => ColoredSmallBrickTile('small_brick_green', colorPalette: ColoredRoofPalettes.greenRoof),

    // =========================================================================
    // DARK GREEN ROOF VARIANTS
    // =========================================================================
    'roof_shingle_dark_green': () =>
        ColoredRoofShingleTile('roof_shingle_dark_green', colorPalette: ColoredRoofPalettes.darkGreenRoof),
    'roof_curved_dark_green': () =>
        ColoredRoofTileTile('roof_curved_dark_green', colorPalette: ColoredRoofPalettes.darkGreenRoof),
    'small_brick_dark_green': () =>
        ColoredSmallBrickTile('small_brick_dark_green', colorPalette: ColoredRoofPalettes.darkGreenRoof),

    // =========================================================================
    // OLIVE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_olive': () =>
        ColoredRoofShingleTile('roof_shingle_olive', colorPalette: ColoredRoofPalettes.oliveRoof),
    'roof_curved_olive': () => ColoredRoofTileTile('roof_curved_olive', colorPalette: ColoredRoofPalettes.oliveRoof),
    'small_brick_olive': () => ColoredSmallBrickTile('small_brick_olive', colorPalette: ColoredRoofPalettes.oliveRoof),

    // =========================================================================
    // WARM GRAY STONE VARIANTS
    // =========================================================================
    'cobble_warm_gray': () => ColoredCobblestoneTile('cobble_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'stone_brick_warm_gray': () =>
        ColoredStoneBrickTile('stone_brick_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'rough_warm_gray': () => ColoredRoughStoneTile('rough_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'large_block_warm_gray': () =>
        ColoredLargeBlockTile('large_block_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'weathered_warm_gray': () =>
        ColoredWeatheredStoneTile('weathered_warm_gray', colorPalette: VariedStonePalettes.warmGray),

    // =========================================================================
    // COOL GRAY STONE VARIANTS
    // =========================================================================
    'cobble_cool_gray': () => ColoredCobblestoneTile('cobble_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'stone_brick_cool_gray': () =>
        ColoredStoneBrickTile('stone_brick_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'rough_cool_gray': () => ColoredRoughStoneTile('rough_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'large_block_cool_gray': () =>
        ColoredLargeBlockTile('large_block_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'weathered_cool_gray': () =>
        ColoredWeatheredStoneTile('weathered_cool_gray', colorPalette: VariedStonePalettes.coolGray),

    // =========================================================================
    // TAN STONE VARIANTS
    // =========================================================================
    'cobble_tan': () => ColoredCobblestoneTile('cobble_tan', colorPalette: VariedStonePalettes.tanStone),
    'stone_brick_tan': () => ColoredStoneBrickTile('stone_brick_tan', colorPalette: VariedStonePalettes.tanStone),
    'rough_tan': () => ColoredRoughStoneTile('rough_tan', colorPalette: VariedStonePalettes.tanStone),
    'large_block_tan': () => ColoredLargeBlockTile('large_block_tan', colorPalette: VariedStonePalettes.tanStone),
    'weathered_tan': () => ColoredWeatheredStoneTile('weathered_tan', colorPalette: VariedStonePalettes.tanStone),

    // =========================================================================
    // CREAM STONE VARIANTS
    // =========================================================================
    'cobble_cream': () => ColoredCobblestoneTile('cobble_cream', colorPalette: VariedStonePalettes.creamStone),
    'stone_brick_cream': () => ColoredStoneBrickTile('stone_brick_cream', colorPalette: VariedStonePalettes.creamStone),
    'rough_cream': () => ColoredRoughStoneTile('rough_cream', colorPalette: VariedStonePalettes.creamStone),
    'large_block_cream': () => ColoredLargeBlockTile('large_block_cream', colorPalette: VariedStonePalettes.creamStone),
    'weathered_cream': () => ColoredWeatheredStoneTile('weathered_cream', colorPalette: VariedStonePalettes.creamStone),

    // =========================================================================
    // BROWN STONE VARIANTS
    // =========================================================================
    'cobble_brown_stone': () =>
        ColoredCobblestoneTile('cobble_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'stone_brick_brown_stone': () =>
        ColoredStoneBrickTile('stone_brick_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'rough_brown_stone': () => ColoredRoughStoneTile('rough_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'large_block_brown_stone': () =>
        ColoredLargeBlockTile('large_block_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'weathered_brown_stone': () =>
        ColoredWeatheredStoneTile('weathered_brown_stone', colorPalette: VariedStonePalettes.brownStone),

    // =========================================================================
    // DARK BROWN STONE VARIANTS
    // =========================================================================
    'cobble_dark_brown': () =>
        ColoredCobblestoneTile('cobble_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'stone_brick_dark_brown': () =>
        ColoredStoneBrickTile('stone_brick_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'rough_dark_brown': () =>
        ColoredRoughStoneTile('rough_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'large_block_dark_brown': () =>
        ColoredLargeBlockTile('large_block_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'weathered_dark_brown': () =>
        ColoredWeatheredStoneTile('weathered_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),

    // =========================================================================
    // OLIVE STONE VARIANTS
    // =========================================================================
    'cobble_olive_stone': () =>
        ColoredCobblestoneTile('cobble_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'stone_brick_olive_stone': () =>
        ColoredStoneBrickTile('stone_brick_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'rough_olive_stone': () => ColoredRoughStoneTile('rough_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'large_block_olive_stone': () =>
        ColoredLargeBlockTile('large_block_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'weathered_olive_stone': () =>
        ColoredWeatheredStoneTile('weathered_olive_stone', colorPalette: VariedStonePalettes.oliveStone),

    // =========================================================================
    // WEATHERED STONE VARIANTS
    // =========================================================================
    'cobble_weathered_stone': () =>
        ColoredCobblestoneTile('cobble_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'stone_brick_weathered_stone': () =>
        ColoredStoneBrickTile('stone_brick_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'rough_weathered_stone': () =>
        ColoredRoughStoneTile('rough_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'large_block_weathered_stone': () =>
        ColoredLargeBlockTile('large_block_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'weathered_weathered_stone': () =>
        ColoredWeatheredStoneTile('weathered_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),

    // =========================================================================
    // HAZARD TILES
    // =========================================================================
    'lava_drip': () => LavaDripTile('lava_drip'),
    'lava_cracks': () => LavaCracksTile('lava_cracks'),
    'poison_slime': () => PoisonSlimeTile('poison_slime'),
    'cracked_electric': () => CrackedElectricTile('cracked_electric'),

    // =========================================================================
    // LIQUID TILES
    // =========================================================================
    'water_bubble': () => WaterBubbleTile('water_bubble'),
    'deep_water_stones': () => DeepWaterStonesTile('deep_water_stones'),

    // =========================================================================
    // TERRAIN TILES
    // =========================================================================
    'grass_top_dirt': () => GrassTopDirtTile('grass_top_dirt'),
    'grass_top_dirt_thick': () => GrassTopDirtTile('grass_top_dirt_thick', grassHeight: 6),
    'sand_layers': () => SandLayersTile('sand_layers'),
    'rocky_ground': () => RockyGroundTile('rocky_ground'),
    'snow_ice_top': () => SnowIceTopTile('snow_ice_top'),
    'snow_ice_top_thick': () => SnowIceTopTile('snow_ice_top_thick', snowHeight: 7),
    'stone_path_grass': () => StonePathGrassTile('stone_path_grass'),

    // =========================================================================
    // STRUCTURE TILES
    // =========================================================================
    'metal_grate': () => MetalGrateTile('metal_grate'),
    'metal_grate_large': () => MetalGrateTile('metal_grate_large', panelSize: 6),
    'wood_plank_vertical': () => WoodPlankTile('wood_plank_vertical', vertical: true),
    'wood_plank_horizontal': () => WoodPlankTile('wood_plank_horizontal', vertical: false),
    'red_brick_platformer': () => RedBrickPlatformerTile('red_brick_platformer'),

    // =========================================================================
    // DECORATION/PATTERN TILES
    // =========================================================================
    'fish_scale': () => FishScaleTile('fish_scale'),
    'honeycomb': () => HoneycombTile('honeycomb'),
    'purple_octagon': () => PurpleOctagonTile('purple_octagon'),
    'orange_scale': () => OrangeScaleTile('orange_scale'),

    // =========================================================================
    // DECORATION TILES - CONTAINERS
    // =========================================================================
    'wooden_crate': () => WoodenCrateTile('wooden_crate'),
    'wooden_crate_open': () => WoodenCrateTile('wooden_crate_open', open: true),
    'barrel': () => BarrelTile('barrel'),
    'barrel_sideways': () => BarrelTile('barrel_sideways', sideways: true),
    'treasure_chest': () => TreasureChestTile('treasure_chest'),
    'treasure_chest_open': () => TreasureChestTile('treasure_chest_open', open: true),
    'mimic_chest': () => TreasureChestTile('mimic_chest', open: true, mimic: true),
    'pot': () => PotTile('pot'),
    'pot_broken': () => PotTile('pot_broken', broken: true),
    'sack': () => SackTile('sack'),
    'sack_open': () => SackTile('sack_open', open: true),

    // =========================================================================
    // DECORATION TILES - LIGHTING
    // =========================================================================
    'torch_lit': () => TorchTile('torch_lit'),
    'torch_unlit': () => TorchTile('torch_unlit', lit: false),
    'lantern_lit': () => LanternTile('lantern_lit'),
    'lantern_unlit': () => LanternTile('lantern_unlit', lit: false),
    'candle': () => CandleTile('candle'),
    'candle_unlit': () => CandleTile('candle_unlit', lit: false),
    'candle_holder': () => CandleTile('candle_holder', inHolder: true),
    'brazier_lit': () => BrazierTile('brazier_lit'),
    'brazier': () => BrazierTile('brazier', lit: false),

    // =========================================================================
    // DECORATION TILES - FURNITURE
    // =========================================================================
    'table': () => TableTile('table'),
    'small_table': () => TableTile('small_table', small: true),
    'chair': () => ChairTile('chair'),
    'bookshelf': () => BookshelfTile('bookshelf'),
    'bed': () => BedTile('bed'),

    // =========================================================================
    // DECORATION TILES - WALL DECORATIONS
    // =========================================================================
    'painting': () => PaintingTile('painting'),
    'painting_landscape': () => PaintingTile('painting_landscape', style: 0),
    'painting_portrait': () => PaintingTile('painting_portrait', style: 1),
    'painting_abstract': () => PaintingTile('painting_abstract', style: 2),
    'banner': () => BannerTile('banner'),
    'rug': () => RugTile('rug'),
    'rug_ornate': () => RugTile('rug_ornate', ornate: true),
    'curtain': () => CurtainTile('curtain'),
    'curtain_open': () => CurtainTile('curtain_open', open: true),
    'clock': () => ClockTile('clock'),

    // =========================================================================
    // DECORATION TILES - SIGNS
    // =========================================================================
    'wood_sign': () => WoodSignTile('wood_sign'),
    'hanging_sign': () => WoodSignTile('hanging_sign', hanging: true),

    // =========================================================================
    // DECORATION TILES - TREASURE & LOOT
    // =========================================================================
    'coin_pile': () => CoinPileTile('coin_pile'),
    'coin_pile_large': () => CoinPileTile('coin_pile_large', large: true),
    'gem_ruby': () => GemTile('gem_ruby', gemType: 0),
    'gem_emerald': () => GemTile('gem_emerald', gemType: 1),
    'gem_sapphire': () => GemTile('gem_sapphire', gemType: 2),
    'gem_amethyst': () => GemTile('gem_amethyst', gemType: 3),

    // =========================================================================
    // DECORATION TILES - BONES & REMAINS
    // =========================================================================
    'skull': () => SkullTile('skull'),
    'bone_pile': () => BonePileTile('bone_pile'),

    // =========================================================================
    // DECORATION TILES - WEAPONS & ARMOR
    // =========================================================================
    'weapon_rack': () => WeaponRackTile('weapon_rack'),
    'wall_shield': () => WallShieldTile('wall_shield'),

    // =========================================================================
    // DECORATION TILES - FOOD & DRINK
    // =========================================================================
    'food_plate': () => FoodPlateTile('food_plate'),
    'mug_full': () => MugTile('mug_full'),
    'mug_empty': () => MugTile('mug_empty', full: false),

    // =========================================================================
    // DECORATION TILES - TROPHIES & DISPLAYS
    // =========================================================================
    'trophy_gold': () => TrophyTile('trophy_gold'),
    'trophy_silver': () => TrophyTile('trophy_silver', gold: false),
    'statue': () => StatueTile('statue'),

    // =========================================================================
    // DECORATION TILES - MISC
    // =========================================================================
    'anvil': () => AnvilTile('anvil'),
    'rope_coil': () => RopeCoilTile('rope_coil'),
    'spider_web': () => SpiderWebTile('spider_web'),
    'lever_off': () => LeverTile('lever_off'),
    'lever_on': () => LeverTile('lever_on', activated: true),
    'key': () => KeyTile('key'),
    'golden_key': () => KeyTile('golden_key', golden: true),

    // =========================================================================
    // SPECIALIZED TILES - PORTALS
    // =========================================================================
    'portal_purple': () => PortalTile('portal_purple', portalColor: PortalColor.purple),
    'portal_blue': () => PortalTile('portal_blue', portalColor: PortalColor.blue),
    'portal_green': () => PortalTile('portal_green', portalColor: PortalColor.green),
    'portal_red': () => PortalTile('portal_red', portalColor: PortalColor.red),

    // =========================================================================
    // SPECIALIZED TILES - RUNE CIRCLES
    // =========================================================================
    'rune_circle_arcane': () => RuneCircleTile('rune_circle_arcane', runeStyle: RuneStyle.arcane),
    'rune_circle_shadow': () => RuneCircleTile('rune_circle_shadow', runeStyle: RuneStyle.shadow),
    'rune_circle_frost': () => RuneCircleTile('rune_circle_frost', runeStyle: RuneStyle.frost),
    'rune_circle_ember': () => RuneCircleTile('rune_circle_ember', runeStyle: RuneStyle.ember),

    // =========================================================================
    // SPECIALIZED TILES - ENERGY FIELDS
    // =========================================================================
    'energy_field_blue': () => EnergyFieldTile('energy_field_blue', fieldColor: FieldColor.blue),
    'energy_field_green': () => EnergyFieldTile('energy_field_green', fieldColor: FieldColor.green),
    'energy_field_red': () => EnergyFieldTile('energy_field_red', fieldColor: FieldColor.red),
    'energy_field_purple': () => EnergyFieldTile('energy_field_purple', fieldColor: FieldColor.purple),

    // =========================================================================
    // SPECIALIZED TILES - VOID & SPACE
    // =========================================================================
    'void_space': () => VoidSpaceTile('void_space'),
    'void_space_dense': () => VoidSpaceTile('void_space_dense', starDensity: 0.06),

    // =========================================================================
    // SPECIALIZED TILES - HOLOGRAM & NEON
    // =========================================================================
    'hologram': () => HologramTile('hologram'),
    'neon_grid': () => NeonGridTile('neon_grid'),
    'neon_grid_fine': () => NeonGridTile('neon_grid_fine', gridSize: 2),

    // =========================================================================
    // SPECIALIZED TILES - MAGIC SPARKLES
    // =========================================================================
    'magic_sparkle_gold': () => MagicSparkleTile('magic_sparkle_gold', sparkleColor: SparkleColor.gold),
    'magic_sparkle_blue': () => MagicSparkleTile('magic_sparkle_blue', sparkleColor: SparkleColor.blue),
    'magic_sparkle_purple': () => MagicSparkleTile('magic_sparkle_purple', sparkleColor: SparkleColor.purple),
    'magic_sparkle_green': () => MagicSparkleTile('magic_sparkle_green', sparkleColor: SparkleColor.green),

    // =========================================================================
    // SPECIALIZED TILES - ELEMENTAL
    // =========================================================================
    'flame': () => FlameTile('flame'),
    'flame_intense': () => FlameTile('flame_intense', flameIntensity: 1.5),
    'ice_crystal': () => IceCrystalTile('ice_crystal'),
    'shadow_wisp': () => ShadowWispTile('shadow_wisp'),

    // =========================================================================
    // PLATFORMER BLOCKS - GRASS TOP COMBINATIONS
    // =========================================================================
    'platformer_grass_dirt': () => GrassDirtBlockTile('platformer_grass_dirt'),
    'platformer_grass_stone': () => GrassStoneBlockTile('platformer_grass_stone'),
    'platformer_grass_brick': () => GrassBrickBlockTile('platformer_grass_brick'),
    'platformer_grass_clay': () => GrassClayBlockTile('platformer_grass_clay'),
    'platformer_grass_concrete': () => GrassConcreteBlockTile('platformer_grass_concrete'),

    // =========================================================================
    // PLATFORMER BLOCKS - SNOW TOP COMBINATIONS
    // =========================================================================
    'platformer_snow_ice': () => SnowIceBlockTile('platformer_snow_ice'),
    'platformer_snow_stone': () => SnowStoneBlockTile('platformer_snow_stone'),
    'platformer_snow_dirt': () => SnowDirtBlockTile('platformer_snow_dirt'),

    // =========================================================================
    // PLATFORMER BLOCKS - MOSS TOP COMBINATIONS
    // =========================================================================
    'platformer_moss_stone': () => MossStoneBlockTile('platformer_moss_stone'),
    'platformer_moss_brick': () => MossBrickBlockTile('platformer_moss_brick'),

    // =========================================================================
    // PLATFORMER BLOCKS - SAND TOP COMBINATIONS
    // =========================================================================
    'platformer_sand_sandstone': () => SandSandstoneBlockTile('platformer_sand_sandstone'),
    'platformer_sand_stone': () => SandStoneBlockTile('platformer_sand_stone'),

    // =========================================================================
    // PLATFORMER BLOCKS - METAL TOP COMBINATIONS
    // =========================================================================
    'platformer_metal_metal': () => MetalBlockTile('platformer_metal_metal'),
    'platformer_metal_concrete': () => MetalConcreteBlockTile('platformer_metal_concrete'),

    // =========================================================================
    // PLATFORMER BLOCKS - WOOD TOP COMBINATIONS
    // =========================================================================
    'platformer_wood_wood': () => WoodBlockTile('platformer_wood_wood'),
    'platformer_wood_dirt': () => WoodDirtBlockTile('platformer_wood_dirt'),
    'platformer_wood_stone': () => WoodStoneBlockTile('platformer_wood_stone'),

    // =========================================================================
    // PLATFORMER BLOCKS - FUNGUS TOP COMBINATIONS
    // =========================================================================
    'platformer_fungus_dirt': () => FungusDirtBlockTile('platformer_fungus_dirt'),
    'platformer_fungus_stone': () => FungusStoneBlockTile('platformer_fungus_stone'),

    // =========================================================================
    // PLATFORMER BLOCKS - CRYSTAL TOP COMBINATIONS
    // =========================================================================
    'platformer_crystal_stone': () => CrystalStoneBlockTile('platformer_crystal_stone'),
    'platformer_crystal_dark_brick': () => CrystalDarkBrickBlockTile('platformer_crystal_dark_brick'),

    // =========================================================================
    // PLATFORMER BLOCKS - ICE TOP COMBINATIONS
    // =========================================================================
    'platformer_ice_ice': () => IceBlockTile('platformer_ice_ice'),
    'platformer_ice_stone': () => IceStoneBlockTile('platformer_ice_stone'),

    // =========================================================================
    // PLATFORMER BLOCKS - AUTUMN TOP COMBINATIONS
    // =========================================================================
    'platformer_autumn_dirt': () => AutumnDirtBlockTile('platformer_autumn_dirt'),
    'platformer_autumn_stone': () => AutumnStoneBlockTile('platformer_autumn_stone'),

    // =========================================================================
    // PLATFORMER BLOCKS - CUSTOM CONFIGURABLE
    // =========================================================================
    'platformer_grass_wood': () => PlatformerBlockTile(
          'platformer_grass_wood',
          topSurface: TopSurface.grass,
          baseMaterial: BaseMaterial.wood,
        ),
    'platformer_moss_dark_brick': () => PlatformerBlockTile(
          'platformer_moss_dark_brick',
          topSurface: TopSurface.moss,
          baseMaterial: BaseMaterial.darkBrick,
        ),
    'platformer_sand_clay': () => PlatformerBlockTile(
          'platformer_sand_clay',
          topSurface: TopSurface.sand,
          baseMaterial: BaseMaterial.clay,
        ),
    'platformer_snow_concrete': () => PlatformerBlockTile(
          'platformer_snow_concrete',
          topSurface: TopSurface.snow,
          baseMaterial: BaseMaterial.concrete,
        ),
    'platformer_autumn_brick': () => PlatformerBlockTile(
          'platformer_autumn_brick',
          topSurface: TopSurface.autumn,
          baseMaterial: BaseMaterial.brick,
        ),
    'platformer_fungus_dark_brick': () => PlatformerBlockTile(
          'platformer_fungus_dark_brick',
          topSurface: TopSurface.fungus,
          baseMaterial: BaseMaterial.darkBrick,
        ),
    'platformer_crystal_ice': () => PlatformerBlockTile(
          'platformer_crystal_ice',
          topSurface: TopSurface.crystal,
          baseMaterial: BaseMaterial.ice,
        ),
    'platformer_ice_dark_brick': () => PlatformerBlockTile(
          'platformer_ice_dark_brick',
          topSurface: TopSurface.ice,
          baseMaterial: BaseMaterial.darkBrick,
        ),

    // =========================================================================
    // PLATFORMER BLOCKS - NO-TOP FILL VERSIONS
    // =========================================================================
    'platformer_fill_dirt': () => DirtFillBlockTile('platformer_fill_dirt'),
    'platformer_fill_stone': () => StoneFillBlockTile('platformer_fill_stone'),
    'platformer_fill_brick': () => BrickFillBlockTile('platformer_fill_brick'),
    'platformer_fill_wood': () => WoodFillBlockTile('platformer_fill_wood'),
    'platformer_fill_concrete': () => ConcreteFillBlockTile('platformer_fill_concrete'),
    'platformer_fill_sandstone': () => SandstoneFillBlockTile('platformer_fill_sandstone'),
    'platformer_fill_ice': () => IceFillBlockTile('platformer_fill_ice'),
    'platformer_fill_metal': () => MetalFillBlockTile('platformer_fill_metal'),
    'platformer_fill_dark_brick': () => DarkBrickFillBlockTile('platformer_fill_dark_brick'),
    'platformer_fill_clay': () => ClayFillBlockTile('platformer_fill_clay'),

    // =========================================================================
    // PLATFORMER TILES - NO-TOP FILL VERSIONS
    // =========================================================================
    'dirt_fill': () => DirtFillTile('dirt_fill'),
    'ice_fill': () => IceFillTile('ice_fill'),
    'sand_fill': () => SandFillTile('sand_fill'),
    'water_fill': () => WaterFillTile('water_fill'),
    'deep_water_fill': () => DeepWaterFillTile('deep_water_fill'),
    'lava_fill': () => LavaFillTile('lava_fill'),
    'lava_cracks_fill': () => LavaCracksFillTile('lava_cracks_fill'),
    'poison_slime_fill': () => PoisonSlimeFillTile('poison_slime_fill'),
    'stone_path_fill': () => StonePathFillTile('stone_path_fill'),
    'rocky_ground_fill': () => RockyGroundFillTile('rocky_ground_fill'),
    'metal_panel_fill': () => MetalPanelFillTile('metal_panel_fill'),
    'wood_fill': () => WoodFillTile('wood_fill'),
    'brick_fill': () => BrickFillTile('brick_fill'),

    // =========================================================================
    // ENVIRONMENT TILES - CAVE/UNDERGROUND
    // =========================================================================
    'cave_floor': () => CaveFloorTile('cave_floor'),
    'cave_floor_wet': () => CaveFloorTile('cave_floor_wet', hasPuddles: true),
    'stalactite': () => StalactiteTile('stalactite'),
    'stalagmite': () => StalactiteTile('stalagmite', pointingDown: false),
    'glowing_fungus': () => GlowingFungusTile('glowing_fungus'),
    'glowing_fungus_dense': () => GlowingFungusTile('glowing_fungus_dense', density: 0.6),
    'underground_lake': () => UndergroundLakeTile('underground_lake'),

    // =========================================================================
    // ENVIRONMENT TILES - SWAMP/MARSH
    // =========================================================================
    'swamp_mud': () => SwampMudTile('swamp_mud'),
    'swamp_mud_wet': () => SwampMudTile('swamp_mud_wet', hasRipples: true),
    'swamp_water': () => SwampWaterTile('swamp_water'),
    'lily_pads': () => LilyPadTile('lily_pads'),
    'lily_pads_flowering': () => LilyPadTile('lily_pads_flowering', hasFlowers: true),
    'bog': () => BogTile('bog'),

    // =========================================================================
    // ENVIRONMENT TILES - INTERIOR
    // =========================================================================
    'carpet_red': () => CarpetTile('carpet_red', color: CarpetColor.red),
    'carpet_blue': () => CarpetTile('carpet_blue', color: CarpetColor.blue),
    'carpet_green': () => CarpetTile('carpet_green', color: CarpetColor.green),
    'carpet_purple': () => CarpetTile('carpet_purple', color: CarpetColor.purple),
    'wallpaper_striped': () => WallpaperTile('wallpaper_striped', pattern: WallpaperPattern.striped),
    'wallpaper_damask': () => WallpaperTile('wallpaper_damask', pattern: WallpaperPattern.damask),
    'wallpaper_floral': () => WallpaperTile('wallpaper_floral', pattern: WallpaperPattern.floral),
    'mosaic': () => MosaicTile('mosaic'),

    // =========================================================================
    // ENVIRONMENT TILES - FARM/RURAL
    // =========================================================================
    'tilled_soil': () => TilledSoilTile('tilled_soil'),
    'tilled_soil_seeded': () => TilledSoilTile('tilled_soil_seeded', hasSeeds: true),
    'hay_loose': () => HayTile('hay_loose'),
    'hay_bale': () => HayTile('hay_bale', isBaled: true),
    'wheat_field_mature': () => WheatFieldTile('wheat_field_mature', mature: true),
    'wheat_field_young': () => WheatFieldTile('wheat_field_young', mature: false),

    // =========================================================================
    // ENVIRONMENT TILES - TRANSITIONS/EDGES
    // =========================================================================
    'shoreline_top': () => ShorelineTile('shoreline_top', direction: EdgeDirection.top),
    'shoreline_bottom': () => ShorelineTile('shoreline_bottom', direction: EdgeDirection.bottom),
    'path_edge_top': () => PathEdgeTile('path_edge_top', direction: EdgeDirection.top),
    'path_edge_bottom': () => PathEdgeTile('path_edge_bottom', direction: EdgeDirection.bottom),
    'snow_edge_top': () => SnowEdgeTile('snow_edge_top', direction: EdgeDirection.top),
    'snow_edge_bottom': () => SnowEdgeTile('snow_edge_bottom', direction: EdgeDirection.bottom),
  };

  /// Get all registered tile IDs
  List<String> get allIds => _registry.keys.toList();

  /// Get a tile instance by ID
  TileBase? getTile(String id) {
    final factory = _registry[id];
    return factory?.call();
  }

  /// Get all tiles in a category
  List<TileBase> getTilesInCategory(TileCategory category) {
    return _registry.values.map((f) => f()).where((t) => t.category == category).toList();
  }

  /// Get all categories with tiles
  Map<TileCategory, List<TileBase>> get tilesByCategory {
    final result = <TileCategory, List<TileBase>>{};
    for (final category in TileCategory.values) {
      final tiles = getTilesInCategory(category);
      if (tiles.isNotEmpty) {
        result[category] = tiles;
      }
    }
    return result;
  }

  /// Search tiles by tag
  List<TileBase> searchByTag(String tag) {
    return _registry.values.map((f) => f()).where((t) => t.tags.contains(tag.toLowerCase())).toList();
  }

  /// Get all stone/dungeon tiles
  List<TileBase> get stoneTiles {
    return searchByTag('stone') + searchByTag('dungeon');
  }

  /// Get all structure tiles including new stone types
  List<TileBase> get allStructureTiles {
    return getTilesInCategory(TileCategory.structure) + getTilesInCategory(TileCategory.dungeon);
  }

  /// Register a custom tile type
  void register(String id, TileBase Function() factory) {
    _registry[id] = factory;
  }

  /// Unregister a tile type
  void unregister(String id) {
    _registry.remove(id);
  }

  /// Check if a tile ID exists
  bool hasTile(String id) {
    return _registry.containsKey(id);
  }

  /// Get count of registered tiles
  int get count => _registry.length;

  /// Get all tile IDs matching a pattern
  List<String> searchIds(String pattern) {
    final lowerPattern = pattern.toLowerCase();
    return _registry.keys.where((id) => id.toLowerCase().contains(lowerPattern)).toList();
  }
}
