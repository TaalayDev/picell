import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import '../../tilemap/generator/tile_base.dart';
import '../../tilemap/generator/tile_palette.dart';
import '../widgets/animated_background.dart';
import 'pixel_canvas_screen.dart';

/// Provider for tile generator state
final tileGeneratorProvider =
    StateNotifierProvider.autoDispose.family<TileGeneratorNotifier, TileGeneratorState, Project>((ref, project) {
  return TileGeneratorNotifier(project);
});

/// State for the tile generator
class TileGeneratorState {
  final int tileWidth;
  final int tileHeight;
  final Uint32List? currentTile;
  final String? selectedTileId;
  final TileCategory? selectedCategory;
  final TileVariation variation;
  final int seed;
  final List<Uint32List> variants;
  final int selectedVariantIndex;

  const TileGeneratorState({
    required this.tileWidth,
    required this.tileHeight,
    this.currentTile,
    this.selectedTileId,
    this.selectedCategory,
    this.variation = TileVariation.standard,
    this.seed = 0,
    this.variants = const [],
    this.selectedVariantIndex = 0,
  });

  TileGeneratorState copyWith({
    int? tileWidth,
    int? tileHeight,
    Uint32List? currentTile,
    String? selectedTileId,
    TileCategory? selectedCategory,
    TileVariation? variation,
    int? seed,
    List<Uint32List>? variants,
    int? selectedVariantIndex,
  }) {
    return TileGeneratorState(
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      currentTile: currentTile ?? this.currentTile,
      selectedTileId: selectedTileId ?? this.selectedTileId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      variation: variation ?? this.variation,
      seed: seed ?? this.seed,
      variants: variants ?? this.variants,
      selectedVariantIndex: selectedVariantIndex ?? this.selectedVariantIndex,
    );
  }
}

/// State notifier for tile generation
class TileGeneratorNotifier extends StateNotifier<TileGeneratorState> {
  final Project project;
  final TileRegistry _registry = TileRegistry.instance;

  TileGeneratorNotifier(this.project)
      : super(TileGeneratorState(
          tileWidth: project.tileWidth ?? project.width,
          tileHeight: project.tileHeight ?? project.height,
        ));

  /// Select a tile type to generate
  void selectTileType(String tileId) {
    state = state.copyWith(
      selectedTileId: tileId,
      variants: [],
      selectedVariantIndex: 0,
    );
    _generateVariants();
  }

  /// Select a category filter
  void selectCategory(TileCategory? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Change the variation style
  void setVariation(TileVariation variation) {
    state = state.copyWith(variation: variation);
    _generateVariants();
  }

  /// Regenerate with a new seed
  void regenerate() {
    state = state.copyWith(seed: DateTime.now().millisecondsSinceEpoch);
    _generateVariants();
  }

  /// Select a variant
  void selectVariant(int index) {
    if (index >= 0 && index < state.variants.length) {
      state = state.copyWith(
        selectedVariantIndex: index,
        currentTile: state.variants[index],
      );
    }
  }

  /// Generate variants for the selected tile type
  void _generateVariants() {
    final tileId = state.selectedTileId;
    if (tileId == null) return;

    final tile = _registry.getTile(tileId);
    if (tile == null) return;

    final variants = tile.generateVariants(
      width: state.tileWidth,
      height: state.tileHeight,
      count: 6,
      baseSeed: state.seed,
    );

    state = state.copyWith(
      variants: variants,
      selectedVariantIndex: 0,
      currentTile: variants.isNotEmpty ? variants[0] : null,
    );
  }

  /// Get all available tile types
  List<TileBase> getAvailableTiles() {
    if (state.selectedCategory != null) {
      return _registry.getTilesInCategory(state.selectedCategory!);
    }
    return _registry.allIds.map((id) => _registry.getTile(id)!).toList();
  }

  /// Get tiles grouped by category
  Map<TileCategory, List<TileBase>> get tilesByCategory {
    return _registry.tilesByCategory;
  }

  /// Get the current generated tile pixels
  Uint32List? get currentTilePixels => state.currentTile;
}

/// Tile Generator Screen - create a single tile and edit it
class TileGeneratorScreen extends StatefulHookConsumerWidget {
  const TileGeneratorScreen({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  ConsumerState<TileGeneratorScreen> createState() => _TileGeneratorScreenState();
}

class _TileGeneratorScreenState extends ConsumerState<TileGeneratorScreen> {
  late final _generatorProvider = tileGeneratorProvider(widget.project);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_generatorProvider);
    final notifier = ref.read(_generatorProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.project.name),
          actions: [
            // Variation selector
            PopupMenuButton<TileVariation>(
              icon: const Icon(Icons.style),
              tooltip: 'Tile Style',
              onSelected: notifier.setVariation,
              itemBuilder: (context) => TileVariation.values.map((v) {
                return PopupMenuItem(
                  value: v,
                  child: Row(
                    children: [
                      if (state.variation == v) Icon(Icons.check, color: colorScheme.primary, size: 20),
                      if (state.variation != v) const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      Text(_variationName(v)),
                    ],
                  ),
                );
              }).toList(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: notifier.regenerate,
              tooltip: 'Regenerate',
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: state.currentTile != null ? () => _continueToEditor(context, state.currentTile!) : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Edit Tile'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: [
            // Left panel - Tile type selector
            _buildTileSelector(context, state, notifier),

            // Main area - Preview and variants
            Expanded(
              child: Column(
                children: [
                  // Main preview
                  Expanded(
                    flex: 2,
                    child: _buildPreview(context, state),
                  ),

                  // Variants row
                  if (state.variants.isNotEmpty) _buildVariantsRow(context, state, notifier),
                ],
              ),
            ),

            // Right panel - Tile info
            if (state.selectedTileId != null) _buildInfoPanel(context, state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildTileSelector(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final tilesByCategory = notifier.tilesByCategory;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tile Generator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Category tabs
          _buildCategoryTabs(context, state, notifier),

          // Tile list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: tilesByCategory.entries
                  .where((e) => state.selectedCategory == null || e.key == state.selectedCategory)
                  .expand((entry) => [
                        if (state.selectedCategory == null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                            child: Text(
                              entry.key.name,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ...entry.value.map((tile) => _buildTileOption(
                              context,
                              tile,
                              state.selectedTileId == tile.id,
                              () => notifier.selectTileType(tile.id),
                            )),
                      ])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: state.selectedCategory == null,
            onSelected: (_) => notifier.selectCategory(null),
          ),
          const SizedBox(width: 4),
          ...TileCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilterChip(
                label: Text(category.name),
                selected: state.selectedCategory == category,
                onSelected: (_) => notifier.selectCategory(category),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTileOption(
    BuildContext context,
    TileBase tile,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Palette preview
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _buildPalettePreview(tile.palette),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? colorScheme.onPrimaryContainer : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tile.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                : colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPalettePreview(TilePalette palette) {
    return Row(
      children: palette.colors.take(4).map((color) {
        return Expanded(
          child: Container(color: color),
        );
      }).toList(),
    );
  }

  Widget _buildPreview(BuildContext context, TileGeneratorState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.currentTile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a tile type to generate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: state.tileWidth / state.tileHeight,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(
                painter: _TilePreviewPainter(
                  pixels: state.currentTile!,
                  width: state.tileWidth,
                  height: state.tileHeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantsRow(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variants',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.variants.length,
              itemBuilder: (context, index) {
                final isSelected = index == state.selectedVariantIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => notifier.selectVariant(index),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : colorScheme.outline,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CustomPaint(
                          painter: _TilePreviewPainter(
                            pixels: state.variants[index],
                            width: state.tileWidth,
                            height: state.tileHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final registry = TileRegistry.instance;
    final tile = registry.getTile(state.selectedTileId!);
    if (tile == null) return const SizedBox.shrink();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              tile.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tile.category.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              tile.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Tile info
            _buildInfoRow(context, 'Size', '${state.tileWidth}×${state.tileHeight}'),
            _buildInfoRow(context, 'Seed', '${state.seed % 10000}'),
            _buildInfoRow(context, 'Style', _variationName(state.variation)),
            const SizedBox(height: 16),

            // Tags
            Text(
              'Tags',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: tile.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Palette
            Text(
              'Palette',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPalettePreview(tile.palette),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _variationName(TileVariation variation) {
    switch (variation) {
      case TileVariation.standard:
        return 'Standard';
      case TileVariation.weathered:
        return 'Weathered';
      case TileVariation.mossy:
        return 'Mossy';
      case TileVariation.cracked:
        return 'Cracked';
      case TileVariation.pristine:
        return 'Pristine';
      case TileVariation.frozen:
        return 'Frozen';
      case TileVariation.overgrown:
        return 'Overgrown';
    }
  }

  void _continueToEditor(BuildContext context, Uint32List tilePixels) {
    // Navigate to pixel editor with the generated tile
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PixelCanvasScreen(
          project: widget.project,
          tilemapPixels: tilePixels,
        ),
      ),
    );
  }
}

/// Custom painter for tile preview
class _TilePreviewPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;

  _TilePreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < pixels.length) {
          final color = Color(pixels[index]);
          final paint = Paint()..color = color;
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelWidth,
              y * pixelHeight,
              pixelWidth + 0.5,
              pixelHeight + 0.5,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TilePreviewPainter oldDelegate) {
    return oldDelegate.pixels != pixels || oldDelegate.width != width || oldDelegate.height != height;
  }
}
