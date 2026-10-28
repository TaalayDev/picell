import 'tile_base.dart';

// ============================================================================
// TILE BIOME
// ============================================================================

/// Biome classifications derived from tile tags for environment-aware grouping.
enum TileBiome {
  forest('Forest', 'Woodland, jungle, and forested environments', [
    'forest',
    'tree',
    'wood',
    'leaf',
    'mushroom',
    'bamboo',
    'moss',
    'root',
    'fern',
    'bark',
    'nature',
  ]),
  desert('Desert', 'Arid, sandy, and dry environments', [
    'sand',
    'desert',
    'arid',
    'cactus',
    'salt',
    'quicksand',
    'fossil',
    'dry',
    'dune',
  ]),
  arctic('Arctic', 'Frozen tundra, ice caps, and snowy environments', [
    'snow',
    'ice',
    'frozen',
    'arctic',
    'frost',
    'tundra',
    'glacier',
    'permafrost',
  ]),
  ocean('Ocean', 'Oceans, lakes, rivers, and underwater environments', [
    'water',
    'ocean',
    'underwater',
    'aquatic',
    'coral',
    'seagrass',
    'lake',
    'river',
    'beach',
    'reef',
    'fish',
  ]),
  volcanic('Volcanic', 'Volcanic, lava, and scorched environments', [
    'volcanic',
    'lava',
    'fire',
    'magma',
    'scorched',
    'ash',
    'crater',
    'obsidian',
    'ember',
  ]),
  swamp('Swamp', 'Wetlands, bogs, and marshy environments', [
    'swamp',
    'mud',
    'bog',
    'marsh',
    'wetland',
    'reed',
    'lily',
    'algae',
    'murky',
  ]),
  dungeon('Dungeon', 'Underground cave and dungeon environments', [
    'dungeon',
    'cave',
    'underground',
    'ruin',
    'crypt',
    'ancient',
    'stalactite',
    'fungus',
  ]),
  urban('Urban', 'City, road, and man-made environments', [
    'urban',
    'city',
    'road',
    'concrete',
    'asphalt',
    'building',
    'brick',
    'pavement',
    'roof',
  ]),
  industrial('Industrial', 'Factory, mechanical, and steampunk environments', [
    'industrial',
    'mechanical',
    'pipe',
    'gear',
    'factory',
    'steam',
    'boiler',
    'conveyor',
    'hydraulic',
    'catwalk',
    'fuel',
    'rivets',
  ]),
  scifi('Sci-Fi', 'Futuristic, space, and high-tech environments', [
    'scifi',
    'tech',
    'neon',
    'electric',
    'laser',
    'hologram',
    'plasma',
    'energy',
    'charged',
  ]),
  magic('Magic', 'Fantasy, arcane, and enchanted environments', [
    'magic',
    'rune',
    'crystal',
    'glowing',
    'enchanted',
    'arcane',
    'fantasy',
    'portal',
    'elemental',
  ]),
  grassland('Grassland', 'Open plains, meadows, and grassy environments', [
    'grass',
    'meadow',
    'plain',
    'field',
    'prairie',
    'flower',
    'clover',
    'lush',
  ]),
  autumn('Autumn', 'Autumnal, fall, and seasonal environments', [
    'autumn',
    'fall',
    'leaves',
    'orange',
    'seasonal',
    'decay',
    'harvest',
  ]);

  final String label;
  final String description;
  final List<String> tags;

  const TileBiome(this.label, this.description, this.tags);
}

// ============================================================================
// QUERY / SORT
// ============================================================================

/// Sort order options for tile catalog queries.
enum TileSortOrder {
  /// Sort alphabetically by display name.
  byName,

  /// Sort by category first, then by name within each category.
  byCategory,

  /// Sort by tile ID alphabetically.
  byId,
}

/// Immutable query object for filtering the tile catalog.
class TileCatalogQuery {
  const TileCatalogQuery({
    this.textSearch,
    this.category,
    this.biome,
    this.tags = const [],
    this.requireAllTags = false,
    this.animatedOnly,
    this.autoTilingOnly,
    this.sortOrder = TileSortOrder.byCategory,
  });

  /// Free-text search matched against tile name, description, id, and tags.
  final String? textSearch;

  /// Restrict results to a single [TileCategory].
  final TileCategory? category;

  /// Restrict results to tiles whose tags overlap a [TileBiome]'s tag set.
  final TileBiome? biome;

  /// Filter by one or more tags.
  final List<String> tags;

  /// When `true`, a tile must carry **all** [tags] (AND); otherwise any match suffices (OR).
  final bool requireAllTags;

  /// When non-null, filter animated vs. non-animated tiles.
  final bool? animatedOnly;

  /// When non-null, filter auto-tiling vs. non-auto-tiling tiles.
  final bool? autoTilingOnly;

  /// How to order the result list.
  final TileSortOrder sortOrder;

  /// Returns a copy with individual fields overridden.
  TileCatalogQuery copyWith({
    String? textSearch,
    TileCategory? category,
    TileBiome? biome,
    List<String>? tags,
    bool? requireAllTags,
    bool? animatedOnly,
    bool? autoTilingOnly,
    TileSortOrder? sortOrder,
    bool clearTextSearch = false,
    bool clearCategory = false,
    bool clearBiome = false,
    bool clearAnimatedOnly = false,
    bool clearAutoTilingOnly = false,
  }) {
    return TileCatalogQuery(
      textSearch: clearTextSearch ? null : textSearch ?? this.textSearch,
      category: clearCategory ? null : category ?? this.category,
      biome: clearBiome ? null : biome ?? this.biome,
      tags: tags ?? this.tags,
      requireAllTags: requireAllTags ?? this.requireAllTags,
      animatedOnly: clearAnimatedOnly ? null : animatedOnly ?? this.animatedOnly,
      autoTilingOnly: clearAutoTilingOnly ? null : autoTilingOnly ?? this.autoTilingOnly,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// `true` when no filters are active (returns all tiles in sort order).
  bool get isEmpty =>
      (textSearch == null || textSearch!.isEmpty) &&
      category == null &&
      biome == null &&
      tags.isEmpty &&
      animatedOnly == null &&
      autoTilingOnly == null;
}

// ============================================================================
// STATS
// ============================================================================

/// Aggregate statistics about the tile catalog.
class TileCatalogStats {
  const TileCatalogStats({
    required this.totalCount,
    required this.countByCategory,
    required this.countByBiome,
    required this.animatedCount,
    required this.autoTilingCount,
    required this.uniqueTagCount,
  });

  final int totalCount;
  final Map<TileCategory, int> countByCategory;
  final Map<TileBiome, int> countByBiome;
  final int animatedCount;
  final int autoTilingCount;
  final int uniqueTagCount;

  @override
  String toString() =>
      'TileCatalogStats(total: $totalCount, animated: $animatedCount, '
      'autoTiling: $autoTilingCount, tags: $uniqueTagCount)';
}

// ============================================================================
// TILE CATALOG
// ============================================================================

/// A rich query layer over [TileRegistry].
///
/// [TileCatalog] does not replace [TileRegistry]; it wraps it with:
/// * Multi-criteria filtering via [TileCatalogQuery]
/// * Biome-based grouping via [TileBiome]
/// * Sorting via [TileSortOrder]
/// * Similar-tile recommendations via [getSimilar]
/// * Aggregate statistics via [stats]
///
/// Usage:
/// ```dart
/// final results = TileCatalog.instance.search(
///   TileCatalogQuery(biome: TileBiome.forest, sortOrder: TileSortOrder.byName),
/// );
/// ```
class TileCatalog {
  TileCatalog._();

  /// The singleton instance.
  static final instance = TileCatalog._();

  final _registry = TileRegistry.instance;

  // --------------------------------------------------------------------------
  // Basic accessors
  // --------------------------------------------------------------------------

  /// All registered tiles as a flat list (unsorted).
  List<TileBase> get all => _registry.allIds.map((id) => _registry.getTile(id)!).toList();

  /// All unique tags found across every registered tile.
  Set<String> get allTags {
    final tags = <String>{};
    for (final id in _registry.allIds) {
      final tile = _registry.getTile(id);
      if (tile != null) tags.addAll(tile.tags);
    }
    return UnmodifiableSetView(tags);
  }

  // --------------------------------------------------------------------------
  // Primary search API
  // --------------------------------------------------------------------------

  /// Return tiles matching [query], in the order specified by [TileCatalogQuery.sortOrder].
  List<TileBase> search(TileCatalogQuery query) {
    Iterable<TileBase> results = all;

    // --- category filter ---
    if (query.category != null) {
      results = results.where((t) => t.category == query.category);
    }

    // --- biome filter (tag-overlap) ---
    if (query.biome != null) {
      final biomeTags = query.biome!.tags;
      results = results.where((t) => t.tags.any(biomeTags.contains));
    }

    // --- explicit tag filter ---
    if (query.tags.isNotEmpty) {
      if (query.requireAllTags) {
        results = results.where((t) => query.tags.every(t.tags.contains));
      } else {
        results = results.where((t) => query.tags.any(t.tags.contains));
      }
    }

    // --- feature flags ---
    if (query.animatedOnly == true) {
      results = results.where((t) => t.animated);
    } else if (query.animatedOnly == false) {
      results = results.where((t) => !t.animated);
    }

    if (query.autoTilingOnly == true) {
      results = results.where((t) => t.supportsAutoTiling);
    } else if (query.autoTilingOnly == false) {
      results = results.where((t) => !t.supportsAutoTiling);
    }

    // --- free-text filter (name, description, id, tags) ---
    if (query.textSearch != null && query.textSearch!.isNotEmpty) {
      final pattern = query.textSearch!.toLowerCase();
      results = results.where(
        (t) =>
            t.name.toLowerCase().contains(pattern) ||
            t.description.toLowerCase().contains(pattern) ||
            t.id.toLowerCase().contains(pattern) ||
            t.tags.any((tag) => tag.toLowerCase().contains(pattern)),
      );
    }

    return _sort(results.toList(), query.sortOrder);
  }

  // --------------------------------------------------------------------------
  // Convenience search helpers
  // --------------------------------------------------------------------------

  /// Full-text search across name, description, id, and tags.
  List<TileBase> searchText(String text, {TileSortOrder sortOrder = TileSortOrder.byName}) {
    return search(TileCatalogQuery(textSearch: text, sortOrder: sortOrder));
  }

  /// Return all tiles belonging to [biome].
  List<TileBase> getTilesForBiome(TileBiome biome, {TileSortOrder sortOrder = TileSortOrder.byCategory}) {
    return search(TileCatalogQuery(biome: biome, sortOrder: sortOrder));
  }

  /// Return tiles matching ANY of [tags] (OR).
  List<TileBase> searchByTags(List<String> tags, {TileSortOrder sortOrder = TileSortOrder.byCategory}) {
    return search(TileCatalogQuery(tags: tags, sortOrder: sortOrder));
  }

  /// Return tiles matching ALL of [tags] (AND).
  List<TileBase> searchByAllTags(List<String> tags, {TileSortOrder sortOrder = TileSortOrder.byCategory}) {
    return search(TileCatalogQuery(tags: tags, requireAllTags: true, sortOrder: sortOrder));
  }

  /// Return all tiles sorted by [sortOrder].
  List<TileBase> getAllSorted({TileSortOrder sortOrder = TileSortOrder.byCategory}) {
    return _sort(all, sortOrder);
  }

  // --------------------------------------------------------------------------
  // Biome grouping
  // --------------------------------------------------------------------------

  /// Tiles grouped by their primary biome (first matching biome wins).
  ///
  /// Tiles that match no biome appear under a `null` key.
  Map<TileBiome?, List<TileBase>> get tilesByBiome {
    final result = <TileBiome?, List<TileBase>>{};
    for (final tile in all) {
      final biome = getPrimaryBiome(tile);
      result.putIfAbsent(biome, () => []).add(tile);
    }
    return result;
  }

  /// All biomes a given tile belongs to (may be multiple).
  List<TileBiome> getBiomesForTile(TileBase tile) {
    return TileBiome.values.where((b) => tile.tags.any(b.tags.contains)).toList();
  }

  /// The single "most representative" biome for [tile], or `null` if none match.
  ///
  /// Chosen by the biome whose tag list has the most matches with the tile's tags.
  TileBiome? getPrimaryBiome(TileBase tile) {
    TileBiome? best;
    int bestScore = 0;
    for (final biome in TileBiome.values) {
      final score = tile.tags.where(biome.tags.contains).length;
      if (score > bestScore) {
        bestScore = score;
        best = biome;
      }
    }
    return best;
  }

  // --------------------------------------------------------------------------
  // Recommendations
  // --------------------------------------------------------------------------

  /// Return [limit] tiles most similar to [tile].
  ///
  /// Similarity is scored by:
  /// * +3 if same [TileCategory]
  /// * +2 per overlapping tag
  /// * +1 per shared biome
  List<TileBase> getSimilar(TileBase tile, {int limit = 6}) {
    final tileBiomes = getBiomesForTile(tile);

    final scored = all.where((t) => t.id != tile.id).map((t) {
      int score = 0;
      if (t.category == tile.category) score += 3;
      score += t.tags.where(tile.tags.contains).length * 2;
      score += getBiomesForTile(t).where(tileBiomes.contains).length;
      return (tile: t, score: score);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).map((e) => e.tile).toList();
  }

  // --------------------------------------------------------------------------
  // Statistics
  // --------------------------------------------------------------------------

  /// Aggregate statistics computed on demand.
  TileCatalogStats get stats {
    final tiles = all;
    return TileCatalogStats(
      totalCount: tiles.length,
      countByCategory: {for (final cat in TileCategory.values) cat: tiles.where((t) => t.category == cat).length},
      countByBiome: {
        for (final biome in TileBiome.values) biome: tiles.where((t) => t.tags.any(biome.tags.contains)).length,
      },
      animatedCount: tiles.where((t) => t.animated).length,
      autoTilingCount: tiles.where((t) => t.supportsAutoTiling).length,
      uniqueTagCount: allTags.length,
    );
  }

  // --------------------------------------------------------------------------
  // Internal
  // --------------------------------------------------------------------------

  List<TileBase> _sort(List<TileBase> tiles, TileSortOrder order) {
    final sorted = List<TileBase>.from(tiles);
    switch (order) {
      case TileSortOrder.byName:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case TileSortOrder.byCategory:
        sorted.sort((a, b) {
          final c = a.category.index.compareTo(b.category.index);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
      case TileSortOrder.byId:
        sorted.sort((a, b) => a.id.compareTo(b.id));
    }
    return sorted;
  }
}

// ignore: avoid_classes_with_only_static_members
/// A read-only [Set] view that disallows mutations.
class UnmodifiableSetView<T> implements Set<T> {
  const UnmodifiableSetView(this._inner);
  final Set<T> _inner;

  @override
  bool contains(Object? element) => _inner.contains(element);

  @override
  Iterator<T> get iterator => _inner.iterator;

  @override
  int get length => _inner.length;

  @override
  T? lookup(Object? object) => _inner.lookup(object);

  @override
  Set<T> toSet() => Set<T>.from(_inner);

  @override
  bool get isEmpty => _inner.isEmpty;

  @override
  bool get isNotEmpty => _inner.isNotEmpty;

  @override
  Iterable<T> where(bool Function(T) test) => _inner.where(test);

  @override
  bool containsAll(Iterable<Object?> other) => _inner.containsAll(other);

  @override
  Set<T> intersection(Set<Object?> other) => _inner.intersection(other);

  @override
  Set<T> union(Set<T> other) => _inner.union(other);

  @override
  Set<T> difference(Set<Object?> other) => _inner.difference(other);

  @override
  void forEach(void Function(T element) f) => _inner.forEach(f);

  @override
  Iterable<R> map<R>(R Function(T e) f) => _inner.map(f);

  @override
  Iterable<T> skip(int count) => _inner.skip(count);

  @override
  Iterable<T> take(int count) => _inner.take(count);

  @override
  List<T> toList({bool growable = true}) => _inner.toList(growable: growable);

  @override
  T get first => _inner.first;

  @override
  T get last => _inner.last;

  @override
  T get single => _inner.single;

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) => _inner.firstWhere(test, orElse: orElse);

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) => _inner.lastWhere(test, orElse: orElse);

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) => _inner.singleWhere(test, orElse: orElse);

  @override
  bool every(bool Function(T element) test) => _inner.every(test);

  @override
  bool any(bool Function(T element) test) => _inner.any(test);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _inner.skipWhile(test);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _inner.takeWhile(test);

  @override
  Iterable<R> expand<R>(Iterable<R> Function(T element) f) => _inner.expand(f);

  @override
  T reduce(T Function(T value, T element) combine) => _inner.reduce(combine);

  @override
  R fold<R>(R initialValue, R Function(R previousValue, T element) combine) => _inner.fold(initialValue, combine);

  @override
  String join([String separator = '']) => _inner.join(separator);

  @override
  T elementAt(int index) => _inner.elementAt(index);

  @override
  Iterable<T> followedBy(Iterable<T> other) => _inner.followedBy(other);

  @override
  Iterable<R> whereType<R>() => _inner.whereType<R>();

  @override
  Set<R> cast<R>() => _inner.cast<R>();

  // ----- Mutation methods throw -----

  @override
  bool add(T value) => throw UnsupportedError('UnmodifiableSetView is read-only');

  @override
  void addAll(Iterable<T> elements) => throw UnsupportedError('UnmodifiableSetView is read-only');

  @override
  bool remove(Object? value) => throw UnsupportedError('UnmodifiableSetView is read-only');

  @override
  void removeAll(Iterable<Object?> elements) => throw UnsupportedError('UnmodifiableSetView is read-only');

  @override
  void retainAll(Iterable<Object?> elements) => throw UnsupportedError('UnmodifiableSetView is read-only');

  @override
  void removeWhere(bool Function(T element) test) => throw UnsupportedError('UnmodifiableSetView is read-only');

  @override
  void retainWhere(bool Function(T element) test) => throw UnsupportedError('UnmodifiableSetView is read-only');

  @override
  void clear() => throw UnsupportedError('UnmodifiableSetView is read-only');
}
