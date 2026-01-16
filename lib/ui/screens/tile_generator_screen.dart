import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import '../../tilemap/generator/tile_base.dart';
import '../../tilemap/generator/tile_palette.dart';
import '../widgets/animated_background.dart';
import 'pixel_canvas_screen.dart';

/// Drawing tool for tile editor
enum TileDrawTool {
  pencil,
  eraser,
  fill,
  eyedropper,
}

/// Canvas display mode
enum CanvasDisplayMode {
  /// Single tile fills available space
  single,

  /// Tile repeated in a 3x3 tilemap pattern
  tilemap,
}

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
  final Color currentColor;
  final TileDrawTool currentTool;
  final CanvasDisplayMode displayMode;
  final List<Uint32List> undoHistory;
  final int undoIndex;

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
    this.currentColor = Colors.black,
    this.currentTool = TileDrawTool.pencil,
    this.displayMode = CanvasDisplayMode.single,
    this.undoHistory = const [],
    this.undoIndex = -1,
  });

  bool get canUndo => undoIndex > 0;
  bool get canRedo => undoIndex < undoHistory.length - 1;

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
    Color? currentColor,
    TileDrawTool? currentTool,
    CanvasDisplayMode? displayMode,
    List<Uint32List>? undoHistory,
    int? undoIndex,
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
      currentColor: currentColor ?? this.currentColor,
      currentTool: currentTool ?? this.currentTool,
      displayMode: displayMode ?? this.displayMode,
      undoHistory: undoHistory ?? this.undoHistory,
      undoIndex: undoIndex ?? this.undoIndex,
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
      final pixels = Uint32List.fromList(state.variants[index]);
      _pushUndoState(pixels);
      state = state.copyWith(
        selectedVariantIndex: index,
        currentTile: pixels,
      );
    }
  }

  /// Set current drawing color
  void setColor(Color color) {
    state = state.copyWith(currentColor: color);
  }

  /// Set current tool
  void setTool(TileDrawTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  /// Toggle display mode
  void toggleDisplayMode() {
    state = state.copyWith(
      displayMode: state.displayMode == CanvasDisplayMode.single ? CanvasDisplayMode.tilemap : CanvasDisplayMode.single,
    );
  }

  /// Set display mode
  void setDisplayMode(CanvasDisplayMode mode) {
    state = state.copyWith(displayMode: mode);
  }

  /// Draw a pixel
  void drawPixel(int x, int y) {
    if (state.currentTile == null) return;
    if (x < 0 || x >= state.tileWidth || y < 0 || y >= state.tileHeight) return;

    final pixels = Uint32List.fromList(state.currentTile!);
    final index = y * state.tileWidth + x;

    switch (state.currentTool) {
      case TileDrawTool.pencil:
        pixels[index] = state.currentColor.value;
        break;
      case TileDrawTool.eraser:
        pixels[index] = 0x00000000; // Transparent
        break;
      case TileDrawTool.fill:
        _floodFill(pixels, x, y, state.currentColor.value);
        break;
      case TileDrawTool.eyedropper:
        final pickedColor = Color(pixels[index]);
        state = state.copyWith(
          currentColor: pickedColor,
          currentTool: TileDrawTool.pencil,
        );
        return;
    }

    state = state.copyWith(currentTile: pixels);
  }

  /// Start drawing (for undo)
  void startDrawing() {
    if (state.currentTile != null) {
      _pushUndoState(Uint32List.fromList(state.currentTile!));
    }
  }

  /// End drawing
  void endDrawing() {
    // Nothing needed for now
  }

  void _pushUndoState(Uint32List pixels) {
    final newHistory = state.undoHistory.sublist(0, state.undoIndex + 1);
    newHistory.add(Uint32List.fromList(pixels));
    // Limit history to 50 entries
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }
    state = state.copyWith(
      undoHistory: newHistory,
      undoIndex: newHistory.length - 1,
    );
  }

  /// Undo
  void undo() {
    if (!state.canUndo) return;
    final newIndex = state.undoIndex - 1;
    state = state.copyWith(
      undoIndex: newIndex,
      currentTile: Uint32List.fromList(state.undoHistory[newIndex]),
    );
  }

  /// Redo
  void redo() {
    if (!state.canRedo) return;
    final newIndex = state.undoIndex + 1;
    state = state.copyWith(
      undoIndex: newIndex,
      currentTile: Uint32List.fromList(state.undoHistory[newIndex]),
    );
  }

  /// Flood fill algorithm
  void _floodFill(Uint32List pixels, int startX, int startY, int newColor) {
    final targetColor = pixels[startY * state.tileWidth + startX];
    if (targetColor == newColor) return;

    final stack = <(int, int)>[];
    stack.add((startX, startY));

    while (stack.isNotEmpty) {
      final (x, y) = stack.removeLast();
      if (x < 0 || x >= state.tileWidth || y < 0 || y >= state.tileHeight) continue;

      final index = y * state.tileWidth + x;
      if (pixels[index] != targetColor) continue;

      pixels[index] = newColor;

      stack.add((x + 1, y));
      stack.add((x - 1, y));
      stack.add((x, y + 1));
      stack.add((x, y - 1));
    }
  }

  /// Clear the canvas
  void clear() {
    if (state.currentTile == null) return;
    _pushUndoState(Uint32List.fromList(state.currentTile!));
    final pixels = Uint32List(state.tileWidth * state.tileHeight);
    state = state.copyWith(currentTile: pixels);
  }

  /// Create a new blank tile
  void createBlankTile() {
    final pixels = Uint32List(state.tileWidth * state.tileHeight);
    // Fill with transparent
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }
    _pushUndoState(pixels);
    state = state.copyWith(
      currentTile: pixels,
      selectedTileId: null,
      variants: [],
    );
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

    if (variants.isNotEmpty) {
      _pushUndoState(Uint32List.fromList(variants[0]));
    }

    state = state.copyWith(
      variants: variants,
      selectedVariantIndex: 0,
      currentTile: variants.isNotEmpty ? Uint32List.fromList(variants[0]) : null,
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
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 900;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Top toolbar
            _buildTopBar(context, state, notifier, colorScheme),

            // Main content
            Expanded(
              child: Row(
                children: [
                  // Left panel - Tile type selector (collapsible on small screens)
                  if (isWide) _buildTileSelector(context, state, notifier),

                  // Main canvas area
                  Expanded(
                    child: Column(
                      children: [
                        // Canvas with tools
                        Expanded(
                          child: _buildCanvasArea(context, state, notifier),
                        ),

                        // Variants row
                        if (state.variants.isNotEmpty) _buildVariantsRow(context, state, notifier),
                      ],
                    ),
                  ),

                  // Right panel - Color palette and tools
                  _buildToolsPanel(context, state, notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),

          // Title
          Text(
            widget.project.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 16),

          // Display mode toggle
          _buildDisplayModeToggle(context, state, notifier, colorScheme),

          const Spacer(),

          // Undo/Redo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: state.canUndo ? notifier.undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: state.canRedo ? notifier.redo : null,
            tooltip: 'Redo',
          ),
          const SizedBox(width: 8),

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

          // Regenerate button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.regenerate,
            tooltip: 'Regenerate',
          ),

          // Clear button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: state.currentTile != null ? notifier.clear : null,
            tooltip: 'Clear Canvas',
          ),
          const SizedBox(width: 8),

          // Continue to editor button
          FilledButton.icon(
            onPressed: state.currentTile != null ? () => _continueToEditor(context, state.currentTile!) : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Edit in Studio'),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildDisplayModeToggle(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            context,
            icon: Icons.crop_square,
            label: 'Single',
            isSelected: state.displayMode == CanvasDisplayMode.single,
            onTap: () => notifier.setDisplayMode(CanvasDisplayMode.single),
            colorScheme: colorScheme,
          ),
          _buildModeButton(
            context,
            icon: Icons.grid_view,
            label: 'Tilemap',
            isSelected: state.displayMode == CanvasDisplayMode.tilemap,
            onTap: () => notifier.setDisplayMode(CanvasDisplayMode.tilemap),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
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
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with create blank option
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tile Templates',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: notifier.createBlankTile,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Blank Tile'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: tilesByCategory.entries
                  .where((e) => state.selectedCategory == null || e.key == state.selectedCategory)
                  .expand((entry) => [
                        if (state.selectedCategory == null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(entry.key),
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.key.name.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                ),
                              ],
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

  IconData _getCategoryIcon(TileCategory category) {
    switch (category) {
      case TileCategory.terrain:
        return Icons.landscape;
      case TileCategory.structure:
        return Icons.domain;
      case TileCategory.nature:
        return Icons.park;
      case TileCategory.liquid:
        return Icons.water;
      case TileCategory.special:
        return Icons.auto_awesome;
      case TileCategory.decoration:
        return Icons.emoji_nature;
      case TileCategory.dungeon:
        return Icons.castle;
    }
  }

  Widget _buildCategoryTabs(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(
              context,
              label: 'All',
              isSelected: state.selectedCategory == null,
              onTap: () => notifier.selectCategory(null),
              colorScheme: colorScheme,
            ),
            ...TileCategory.values.map((category) {
              return _buildCategoryChip(
                context,
                label: category.name,
                isSelected: state.selectedCategory == category,
                onTap: () => notifier.selectCategory(category),
                colorScheme: colorScheme,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Palette preview
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: _buildPalettePreview(tile.palette),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        tile.description,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                    size: 16,
                  ),
              ],
            ),
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

  Widget _buildCanvasArea(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.currentTile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.touch_app,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a template or create a blank tile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from the left panel to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _TileEditorCanvas(
              pixels: state.currentTile!,
              width: state.tileWidth,
              height: state.tileHeight,
              displayMode: state.displayMode,
              currentTool: state.currentTool,
              currentColor: state.currentColor,
              onDrawPixel: notifier.drawPixel,
              onStartDrawing: notifier.startDrawing,
              onEndDrawing: notifier.endDrawing,
              constraints: constraints,
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolsPanel(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawing Tools Section
            _buildSectionHeader(context, 'Tools', Icons.edit),
            const SizedBox(height: 8),
            _buildToolGrid(context, state, notifier, colorScheme),
            const SizedBox(height: 16),

            // Current Color Section
            _buildSectionHeader(context, 'Color', Icons.palette),
            const SizedBox(height: 8),
            _buildColorPicker(context, state, notifier, colorScheme),
            const SizedBox(height: 16),

            // Quick Colors
            _buildQuickColors(context, state, notifier, colorScheme),
            const SizedBox(height: 16),

            // Tile Info (if selected)
            if (state.selectedTileId != null) ...[
              _buildSectionHeader(context, 'Tile Info', Icons.info_outline),
              const SizedBox(height: 8),
              _buildCompactTileInfo(context, state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildToolGrid(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: TileDrawTool.values.map((tool) {
        final isSelected = state.currentTool == tool;
        return _buildToolButton(
          context,
          tool: tool,
          isSelected: isSelected,
          onTap: () => notifier.setTool(tool),
          colorScheme: colorScheme,
        );
      }).toList(),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required TileDrawTool tool,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Tooltip(
      message: _toolName(tool),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: colorScheme.primary, width: 2) : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            _toolIcon(tool),
            size: 20,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  IconData _toolIcon(TileDrawTool tool) {
    switch (tool) {
      case TileDrawTool.pencil:
        return Icons.edit;
      case TileDrawTool.eraser:
        return Icons.auto_fix_high;
      case TileDrawTool.fill:
        return Icons.format_color_fill;
      case TileDrawTool.eyedropper:
        return Icons.colorize;
    }
  }

  String _toolName(TileDrawTool tool) {
    switch (tool) {
      case TileDrawTool.pencil:
        return 'Pencil';
      case TileDrawTool.eraser:
        return 'Eraser';
      case TileDrawTool.fill:
        return 'Fill';
      case TileDrawTool.eyedropper:
        return 'Color Picker';
    }
  }

  Widget _buildColorPicker(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _showColorPickerDialog(context, state, notifier),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: state.currentColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: state.currentColor.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${state.currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
  ) {
    Color pickedColor = state.currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: _SimpleColorPicker(
            currentColor: pickedColor,
            onColorChanged: (color) {
              pickedColor = color;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              notifier.setColor(pickedColor);
              Navigator.of(context).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickColors(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    final quickColors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.brown,
      Colors.grey,
      Colors.pink,
      Colors.teal,
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: quickColors.map((color) {
        final isSelected = state.currentColor.value == color.value;
        return GestureDetector(
          onTap: () => notifier.setColor(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactTileInfo(BuildContext context, TileGeneratorState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final registry = TileRegistry.instance;
    final tile = registry.getTile(state.selectedTileId!);
    if (tile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tile.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.tileWidth}×${state.tileHeight} • ${_variationName(state.variation)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
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
      height: 100,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_on, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Variants',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${state.variants.length} available',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
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

/// Interactive tile editor canvas with drawing support
class _TileEditorCanvas extends HookWidget {
  final Uint32List pixels;
  final int width;
  final int height;
  final CanvasDisplayMode displayMode;
  final TileDrawTool currentTool;
  final Color currentColor;
  final Function(int x, int y) onDrawPixel;
  final VoidCallback onStartDrawing;
  final VoidCallback onEndDrawing;
  final BoxConstraints constraints;

  const _TileEditorCanvas({
    required this.pixels,
    required this.width,
    required this.height,
    required this.displayMode,
    required this.currentTool,
    required this.currentColor,
    required this.onDrawPixel,
    required this.onStartDrawing,
    required this.onEndDrawing,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isDrawing = useState(false);
    final lastPixel = useState<(int, int)?>(null);
    final hoverPos = useState<Offset?>(null);

    // Calculate canvas size to fill available space
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    final aspectRatio = width / height;

    double canvasWidth, canvasHeight;
    if (displayMode == CanvasDisplayMode.tilemap) {
      // In tilemap mode, show 3x3 grid so divide available space
      final tilemapAspect = aspectRatio;
      if (availableWidth / availableHeight > tilemapAspect) {
        canvasHeight = availableHeight * 0.9;
        canvasWidth = canvasHeight * tilemapAspect;
      } else {
        canvasWidth = availableWidth * 0.9;
        canvasHeight = canvasWidth / tilemapAspect;
      }
    } else {
      // Single mode - fill available space
      if (availableWidth / availableHeight > aspectRatio) {
        canvasHeight = availableHeight;
        canvasWidth = canvasHeight * aspectRatio;
      } else {
        canvasWidth = availableWidth;
        canvasHeight = canvasWidth / aspectRatio;
      }
    }

    return Center(
      child: MouseRegion(
        onHover: (event) {
          hoverPos.value = event.localPosition;
        },
        onExit: (_) {
          hoverPos.value = null;
        },
        cursor: _getCursor(),
        child: Listener(
          onPointerDown: (event) {
            isDrawing.value = true;
            onStartDrawing();
            final pos = _getPixelFromOffset(event.localPosition, canvasWidth, canvasHeight);
            if (pos != null) {
              lastPixel.value = pos;
              onDrawPixel(pos.$1, pos.$2);
            }
          },
          onPointerMove: (event) {
            if (isDrawing.value) {
              final pos = _getPixelFromOffset(event.localPosition, canvasWidth, canvasHeight);
              if (pos != null && pos != lastPixel.value) {
                // Draw line between last and current position
                if (lastPixel.value != null) {
                  _drawLine(lastPixel.value!, pos);
                } else {
                  onDrawPixel(pos.$1, pos.$2);
                }
                lastPixel.value = pos;
              }
            }
            hoverPos.value = event.localPosition;
          },
          onPointerUp: (event) {
            isDrawing.value = false;
            lastPixel.value = null;
            onEndDrawing();
          },
          onPointerCancel: (event) {
            isDrawing.value = false;
            lastPixel.value = null;
            onEndDrawing();
          },
          child: SizedBox(
            width: canvasWidth,
            height: canvasHeight,
            child: CustomPaint(
              painter: _TileEditorPainter(
                pixels: pixels,
                width: width,
                height: height,
                displayMode: displayMode,
                hoverPos: hoverPos.value,
                currentTool: currentTool,
                currentColor: currentColor,
              ),
              size: Size(canvasWidth, canvasHeight),
            ),
          ),
        ),
      ),
    );
  }

  MouseCursor _getCursor() {
    switch (currentTool) {
      case TileDrawTool.pencil:
      case TileDrawTool.eraser:
        return SystemMouseCursors.precise;
      case TileDrawTool.fill:
        return SystemMouseCursors.click;
      case TileDrawTool.eyedropper:
        return SystemMouseCursors.precise;
    }
  }

  (int, int)? _getPixelFromOffset(Offset offset, double canvasWidth, double canvasHeight) {
    final pixelWidth = canvasWidth / width;
    final pixelHeight = canvasHeight / height;

    final x = (offset.dx / pixelWidth).floor();
    final y = (offset.dy / pixelHeight).floor();

    if (x >= 0 && x < width && y >= 0 && y < height) {
      return (x, y);
    }
    return null;
  }

  void _drawLine((int, int) from, (int, int) to) {
    // Bresenham's line algorithm
    int x0 = from.$1, y0 = from.$2;
    int x1 = to.$1, y1 = to.$2;

    int dx = (x1 - x0).abs();
    int dy = (y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    while (true) {
      onDrawPixel(x0, y0);

      if (x0 == x1 && y0 == y1) break;

      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }
  }
}

/// Painter for the tile editor with tilemap mode support
class _TileEditorPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;
  final CanvasDisplayMode displayMode;
  final Offset? hoverPos;
  final TileDrawTool currentTool;
  final Color currentColor;

  _TileEditorPainter({
    required this.pixels,
    required this.width,
    required this.height,
    required this.displayMode,
    this.hoverPos,
    required this.currentTool,
    required this.currentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    // Draw checkerboard background for transparency
    _drawCheckerboard(canvas, size, pixelWidth, pixelHeight);

    if (displayMode == CanvasDisplayMode.tilemap) {
      // Draw 3x3 tilemap with center tile being the editable one
      final tileWidth = size.width / 3;
      final tileHeight = size.height / 3;

      for (int ty = 0; ty < 3; ty++) {
        for (int tx = 0; tx < 3; tx++) {
          final offsetX = tx * tileWidth;
          final offsetY = ty * tileHeight;
          final isCenter = tx == 1 && ty == 1;

          canvas.save();
          canvas.translate(offsetX, offsetY);

          // Draw tile with dimming for non-center tiles
          _drawTile(canvas, Size(tileWidth, tileHeight), isCenter ? 1.0 : 0.5);

          canvas.restore();
        }
      }

      // Draw border around center tile
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(
        Rect.fromLTWH(size.width / 3, size.height / 3, size.width / 3, size.height / 3),
        centerPaint,
      );
    } else {
      // Single tile mode - draw at full size
      _drawTile(canvas, size, 1.0);

      // Draw hover preview
      if (hoverPos != null) {
        final hx = (hoverPos!.dx / pixelWidth).floor();
        final hy = (hoverPos!.dy / pixelHeight).floor();

        if (hx >= 0 && hx < width && hy >= 0 && hy < height) {
          final hoverPaint = Paint()
            ..color = currentTool == TileDrawTool.eraser
                ? Colors.red.withValues(alpha: 0.5)
                : currentColor.withValues(alpha: 0.5);
          canvas.drawRect(
            Rect.fromLTWH(hx * pixelWidth, hy * pixelHeight, pixelWidth, pixelHeight),
            hoverPaint,
          );

          // Draw hover outline
          final outlinePaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;
          canvas.drawRect(
            Rect.fromLTWH(hx * pixelWidth, hy * pixelHeight, pixelWidth, pixelHeight),
            outlinePaint,
          );
        }
      }
    }

    // Draw grid lines
    _drawGrid(canvas, size, pixelWidth, pixelHeight);
  }

  void _drawCheckerboard(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    final lightPaint = Paint()..color = const Color(0xFFE0E0E0);
    final darkPaint = Paint()..color = const Color(0xFFBDBDBD);

    final checkerSize = (pixelWidth / 2).clamp(2.0, 8.0);

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final isLight = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }
  }

  void _drawTile(Canvas canvas, Size size, double opacity) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < pixels.length) {
          final color = Color(pixels[index]);
          if (color.alpha > 0) {
            final paint = Paint()..color = color.withValues(alpha: color.a * opacity);
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
  }

  void _drawGrid(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    // Only draw grid if pixels are large enough
    if (pixelWidth < 4 || pixelHeight < 4) return;

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (int x = 0; x <= width; x++) {
      canvas.drawLine(
        Offset(x * pixelWidth, 0),
        Offset(x * pixelWidth, size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (int y = 0; y <= height; y++) {
      canvas.drawLine(
        Offset(0, y * pixelHeight),
        Offset(size.width, y * pixelHeight),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TileEditorPainter oldDelegate) {
    return oldDelegate.pixels != pixels ||
        oldDelegate.displayMode != displayMode ||
        oldDelegate.hoverPos != hoverPos ||
        oldDelegate.currentTool != currentTool ||
        oldDelegate.currentColor != currentColor;
  }
}

/// Simple color picker widget
class _SimpleColorPicker extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  const _SimpleColorPicker({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  State<_SimpleColorPicker> createState() => _SimpleColorPickerState();
}

class _SimpleColorPickerState extends State<_SimpleColorPicker> {
  late double hue;
  late double saturation;
  late double lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.currentColor);
    hue = hsl.hue;
    saturation = hsl.saturation;
    lightness = hsl.lightness;
  }

  void _updateColor() {
    final color = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color preview
        Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(height: 16),

        // Hue slider
        _buildSlider(
          label: 'Hue',
          value: hue,
          max: 360,
          gradient: LinearGradient(
            colors: List.generate(7, (i) => HSLColor.fromAHSL(1, i * 60.0, 1, 0.5).toColor()),
          ),
          onChanged: (v) {
            setState(() => hue = v);
            _updateColor();
          },
        ),

        // Saturation slider
        _buildSlider(
          label: 'Saturation',
          value: saturation,
          max: 1,
          gradient: LinearGradient(
            colors: [
              HSLColor.fromAHSL(1, hue, 0, lightness).toColor(),
              HSLColor.fromAHSL(1, hue, 1, lightness).toColor(),
            ],
          ),
          onChanged: (v) {
            setState(() => saturation = v);
            _updateColor();
          },
        ),

        // Lightness slider
        _buildSlider(
          label: 'Lightness',
          value: lightness,
          max: 1,
          gradient: LinearGradient(
            colors: [
              Colors.black,
              HSLColor.fromAHSL(1, hue, saturation, 0.5).toColor(),
              Colors.white,
            ],
          ),
          onChanged: (v) {
            setState(() => lightness = v);
            _updateColor();
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Container(
            height: 24,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: SliderComponentShape.noOverlay,
                trackShape: const RoundedRectSliderTrackShape(),
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                value: value,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
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
