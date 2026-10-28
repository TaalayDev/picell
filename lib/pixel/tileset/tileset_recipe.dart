part of 'tileset_generator.dart';

enum TilesetBase {
  ground('Ground'),
  wall('Wall'),
  floor('Floor'),
  path('Path');

  const TilesetBase(this.label);
  final String label;
}

/// A composable recipe, independent of which connection parts are requested.
class TilesetRecipe {
  const TilesetRecipe(
      {this.base = TilesetBase.ground,
      this.surface = TilesetMaterials.earth,
      this.platform = false,
      this.vegetation = false,
      this.vegetationDensity = 45,
      this.extraModifiers = const {}});
  final TilesetBase base;
  final TilesetMaterial surface;
  final bool platform, vegetation;
  final int vegetationDensity;

  /// Intensities of registry modifiers other than platform and vegetation, by id.
  final Map<String, int> extraModifiers;
  static List<TilesetBase> basesFor(TilesetPerspective perspective) =>
      perspective == TilesetPerspective.topDown ? TilesetBase.values : [TilesetBase.ground, TilesetBase.wall];
  static List<TilesetMaterial> surfacesFor(TilesetBase base) => TilesetMaterials.forBase(base);
  bool canPlatform(TilesetPerspective p) => TilesetModifiers.platform.applies(base, p);
  bool get canVegetate => TilesetModifiers.vegetation.applies(base, TilesetPerspective.side);

  /// Intensity (0-100) of an active modifier, or null when it is off.
  int? modifierIntensity(String id) => switch (id) {
        'platform' => platform ? 100 : null,
        'vegetation' => vegetation ? vegetationDensity : null,
        _ => extraModifiers[id],
      };

  /// Turns a modifier on at [intensity], or off when it is null.
  TilesetRecipe withModifier(String id, int? intensity) => switch (id) {
        'platform' => copyWith(platform: intensity != null),
        'vegetation' =>
          intensity == null ? copyWith(vegetation: false) : copyWith(vegetation: true, vegetationDensity: intensity),
        _ => copyWith(extraModifiers: {
            for (final entry in extraModifiers.entries)
              if (entry.key != id) entry.key: entry.value,
            if (intensity != null) id: intensity,
          }),
      };

  TilesetType rendererFor(TilesetPerspective p) {
    if (!basesFor(p).contains(base) ||
        !(surface.spec != null || surfacesFor(base).contains(surface)) ||
        vegetationDensity < 0 ||
        vegetationDensity > 100) {
      throw ArgumentError('Incompatible tileset recipe');
    }
    for (final id in extraModifiers.keys) {
      if (id == 'platform' || id == 'vegetation') throw ArgumentError('Incompatible tileset recipe');
      TilesetModifiers.byId(id);
    }
    for (final modifier in TilesetModifiers.all) {
      final intensity = modifierIntensity(modifier.id);
      if (intensity != null && (!modifier.applies(base, p) || intensity < 0 || intensity > 100)) {
        throw ArgumentError('Incompatible tileset recipe');
      }
    }
    return switch (base) {
      TilesetBase.wall => TilesetType.walls,
      TilesetBase.floor => TilesetType.floors,
      TilesetBase.path => TilesetType.paths,
      TilesetBase.ground => platform
          ? (p == TilesetPerspective.isometric ? TilesetType.raisedBlocks : TilesetType.platforms)
          : (p == TilesetPerspective.topDown ? TilesetType.terrain : TilesetType.ground),
    };
  }

  TilesetRecipe copyWith(
          {TilesetBase? base,
          TilesetMaterial? surface,
          bool? platform,
          bool? vegetation,
          int? vegetationDensity,
          Map<String, int>? extraModifiers}) =>
      TilesetRecipe(
          base: base ?? this.base,
          surface: surface ?? this.surface,
          platform: platform ?? this.platform,
          vegetation: vegetation ?? this.vegetation,
          vegetationDensity: vegetationDensity ?? this.vegetationDensity,
          extraModifiers: extraModifiers ?? this.extraModifiers);
  factory TilesetRecipe.fromSettings(TilesetSettings s) =>
      s.recipe ??
      TilesetRecipe(
          base: switch (s.type) {
            TilesetType.walls => TilesetBase.wall,
            TilesetType.floors => TilesetBase.floor,
            TilesetType.paths => TilesetBase.path,
            _ => TilesetBase.ground
          },
          surface: s.type == TilesetType.walls
              ? TilesetMaterials.brick
              : s.type == TilesetType.floors
                  ? TilesetMaterials.stone
                  : TilesetMaterials.earth,
          platform: s.type == TilesetType.platforms || s.type == TilesetType.raisedBlocks,
          vegetation: s.type == TilesetType.platforms || s.type == TilesetType.terrain);
  Map<String, dynamic> toJson() => {
        'base': base.name,
        'surface': surface.id,
        if (surface.spec != null) 'surfaceSpec': surface.spec!.toJson(),
        'platform': platform,
        'vegetation': vegetation,
        'vegetationDensity': vegetationDensity,
        if (extraModifiers.isNotEmpty) 'modifiers': extraModifiers,
      };
  factory TilesetRecipe.fromJson(Map<String, dynamic> json) {
    final extra = <String, int>{};
    for (final entry in ((json['modifiers'] as Map?) ?? const {}).entries) {
      final id = entry.key as String, value = entry.value;
      if (value is! int) throw const FormatException('Invalid modifier intensity');
      TilesetModifiers.byId(id);
      extra[id] = value;
    }
    return TilesetRecipe(
        base: TilesetBase.values.byName(json['base'] as String),
        surface: json['surface'] == 'custom'
            ? TilesetMaterial.custom(TilesetSurfaceSpec.fromJson((json['surfaceSpec'] as Map).cast<String, dynamic>()))
            : TilesetMaterials.byId(json['surface'] as String),
        platform: json['platform'] as bool,
        vegetation: json['vegetation'] as bool,
        vegetationDensity: json['vegetationDensity'] as int,
        extraModifiers: Map.unmodifiable(extra));
  }
}

GeneratedTile _applyRecipe(TilesetSettings s, GeneratedTile tile) {
  final recipe = s.recipe;
  if (recipe == null) return tile;
  final pixels = Uint32List.fromList(tile.pixels), n = s.size, p = s.palette;
  final band = n ~/ 8;
  final active = [
    for (final modifier in TilesetModifiers.all)
      if (recipe.modifierIntensity(modifier.id) case final intensity?) (modifier, intensity),
  ];
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final i = y * n + x, original = pixels[i];
      if (original >> 24 == 0 || original == p[0]) continue;
      final hx = x == n - 1 ? 0 : x, hy = y == n - 1 ? 0 : y;
      final boundary = x < band || y < band || x >= n - band || y >= n - band;
      final noise = tileHash(hx, hy, s.seed + (boundary ? 0 : tile.variation * 193 + tile.revision * 997));
      final pixel = MaterialPixel(
          x: hx,
          y: hy,
          size: n,
          noise: noise,
          density: s.density,
          palette: p,
          perspective: s.perspective,
          seed: s.seed,
          variant: boundary ? 0 : tile.variation * 193 + tile.revision * 997,
          boundary: boundary,
          col: x,
          row: y,
          mask: tile.mask);
      var color = recipe.surface.shade(pixel);
      for (final (modifier, intensity) in active) {
        color = modifier.shade(
            ModifierPixel(pixel: pixel, row: y, mask: tile.mask, boundary: boundary, intensity: intensity), color);
      }
      pixels[i] = color;
    }
  }
  return tile.copyWith(pixels: pixels);
}

String tilesetPartLabel(int mask) {
  var label = platformTileName(mask);
  for (final direction in {'top': 'North', 'bottom': 'South', 'left': 'West', 'right': 'East'}.entries) {
    label = label.replaceAll(RegExp(direction.key, caseSensitive: false), direction.value);
  }
  return label;
}
