import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import '../../tilemap/generator/tile_base.dart';
import '../../tilemap/generator/tile_palette.dart';
import '../../tilemap/tile_generator_notifier.dart';
import '../widgets/animated_background.dart';
import 'pixel_canvas_screen.dart';

/// Tile Generator Screen - create a single tile and edit it
class TileGeneratorScreen extends StatefulHookConsumerWidget {
  const TileGeneratorScreen({
    super.key,
    required this.project,
    this.returnResultForTilemap = false,
  });

  final Project project;
  final bool returnResultForTilemap;

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

          // Continue to editor button or return for tilemap
          FilledButton.icon(
            onPressed: state.currentTile != null
                ? () {
                    if (widget.returnResultForTilemap) {
                      _returnResultForTilemap(context, state);
                    } else {
                      _continueToEditor(context, state.currentTile!);
                    }
                  }
                : null,
            icon: Icon(widget.returnResultForTilemap ? Icons.add : Icons.arrow_forward),
            label: Text(widget.returnResultForTilemap ? 'Add to Tilemap' : 'Edit in Studio'),
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
      case TileCategory.urban:
        return Icons.location_city;
      case TileCategory.varied:
        return Icons.color_lens;
      case TileCategory.platformer:
        return Icons.directions_run;
      case TileCategory.scifi:
        return Icons.rocket_launch;
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: notifier.createBlankTile,
              icon: const Icon(Icons.add),
              label: const Text('Create Blank Tile'),
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
      width: 220,
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
            const SizedBox(height: 12),

            // Tile Palette Colors (auto-populated)
            if (state.paletteColors.isNotEmpty) ...[
              _buildPaletteColorsSection(context, state, notifier, colorScheme),
              const SizedBox(height: 12),
            ],

            // Quick Colors
            _buildQuickColors(context, state, notifier, colorScheme),
            const SizedBox(height: 16),

            // Generation Settings (if tile selected)
            if (state.selectedTileId != null) ...[
              _buildSectionHeader(context, 'Generation', Icons.tune),
              const SizedBox(height: 8),
              _buildGenerationSettings(context, state, notifier, colorScheme),
              const SizedBox(height: 16),

              // Corner Radii Section
              _buildSectionHeader(context, 'Corner Radii', Icons.rounded_corner),
              const SizedBox(height: 8),
              _buildCornerRadiiSettings(context, state, notifier, colorScheme),
              const SizedBox(height: 16),

              // Tile Info
              _buildSectionHeader(context, 'Tile Info', Icons.info_outline),
              const SizedBox(height: 8),
              _buildCompactTileInfo(context, state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteColorsSection(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.color_lens, size: 14, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'Tile Palette',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: state.paletteColors.map((color) {
            final isSelected = state.currentColor.value == color.value;
            return GestureDetector(
              onTap: () => notifier.setColor(color),
              child: Tooltip(
                message: '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
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
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerationSettings(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Noise Intensity
        _buildSliderSetting(
          context,
          label: 'Noise Intensity',
          value: state.noiseIntensity,
          min: 0,
          max: 0.3,
          onChanged: notifier.setNoiseIntensity,
          colorScheme: colorScheme,
          valueLabel: '${(state.noiseIntensity * 100).toInt()}%',
        ),
        const SizedBox(height: 8),

        // Noise Octaves
        _buildSliderSetting(
          context,
          label: 'Noise Detail',
          value: state.noiseOctaves.toDouble(),
          min: 1,
          max: 6,
          onChanged: (v) => notifier.setNoiseOctaves(v.round()),
          colorScheme: colorScheme,
          valueLabel: '${state.noiseOctaves}',
        ),
      ],
    );
  }

  Widget _buildCornerRadiiSettings(
    BuildContext context,
    TileGeneratorState state,
    TileGeneratorNotifier notifier,
    ColorScheme colorScheme,
  ) {
    final maxRadius = (state.tileWidth < state.tileHeight ? state.tileWidth : state.tileHeight) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick set all corners
        Row(
          children: [
            Expanded(
              child: Text(
                'All Corners',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            SizedBox(
              width: 100,
              child: Slider(
                value: state.topLeftRadius,
                min: 0,
                max: maxRadius,
                onChanged: notifier.setAllCornerRadii,
              ),
            ),
          ],
        ),

        const Divider(height: 16),

        // Individual corners in a 2x2 grid
        Row(
          children: [
            Expanded(
              child: _buildCornerRadiusControl(
                context,
                label: 'TL',
                value: state.topLeftRadius,
                max: maxRadius,
                onChanged: notifier.setTopLeftRadius,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCornerRadiusControl(
                context,
                label: 'TR',
                value: state.topRightRadius,
                max: maxRadius,
                onChanged: notifier.setTopRightRadius,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCornerRadiusControl(
                context,
                label: 'BL',
                value: state.bottomLeftRadius,
                max: maxRadius,
                onChanged: notifier.setBottomLeftRadius,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCornerRadiusControl(
                context,
                label: 'BR',
                value: state.bottomRightRadius,
                max: maxRadius,
                onChanged: notifier.setBottomRightRadius,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCornerRadiusControl(
    BuildContext context, {
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${value.round()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ColorScheme colorScheme,
    required String valueLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                valueLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
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
              _getColorHex(state.currentColor),
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

  String _getColorHex(Color color) {
    if (color.alpha < 255) {
      return '#${color.value.toRadixString(16).toUpperCase()}';
    }
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
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

  void _returnResultForTilemap(BuildContext context, TileGeneratorState state) {
    if (state.currentTile == null) return;

    // Return the tile data for use in tilemap
    Navigator.of(context).pop<Map<String, dynamic>>({
      'pixels': Uint32List.fromList(state.currentTile!),
      'width': state.tileWidth,
      'height': state.tileHeight,
      'name': state.selectedTileId != null
          ? TileRegistry.instance.getTile(state.selectedTileId!)?.name ?? 'Tile'
          : 'Custom Tile',
      'templateId': state.selectedTileId,
    });
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
          child: RepaintBoundary(
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: CustomPaint(
                isComplex: true,
                willChange: true,
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
    if (displayMode == CanvasDisplayMode.tilemap) {
      // In tilemap mode, only the center tile (1,1) is editable
      final tileWidth = canvasWidth / 3;
      final tileHeight = canvasHeight / 3;

      // Calculate which tile was clicked
      final tileX = (offset.dx / tileWidth).floor();
      final tileY = (offset.dy / tileHeight).floor();

      // Only allow drawing on the center tile
      if (tileX != 1 || tileY != 1) {
        return null;
      }

      // Calculate position relative to the center tile
      final centerTileLeft = tileWidth;
      final centerTileTop = tileHeight;
      final localX = offset.dx - centerTileLeft;
      final localY = offset.dy - centerTileTop;

      final pixelWidth = tileWidth / width;
      final pixelHeight = tileHeight / height;

      final x = (localX / pixelWidth).floor();
      final y = (localY / pixelHeight).floor();

      if (x >= 0 && x < width && y >= 0 && y < height) {
        return (x, y);
      }
      return null;
    } else {
      // Single mode - full canvas is one tile
      final pixelWidth = canvasWidth / width;
      final pixelHeight = canvasHeight / height;

      final x = (offset.dx / pixelWidth).floor();
      final y = (offset.dy / pixelHeight).floor();

      if (x >= 0 && x < width && y >= 0 && y < height) {
        return (x, y);
      }
      return null;
    }
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

  // Cached paint objects for better performance
  static final Paint _lightCheckerPaint = Paint()..color = const Color(0xFFE0E0E0);
  static final Paint _darkCheckerPaint = Paint()..color = const Color(0xFFBDBDBD);
  static final Paint _gridPaint = Paint()
    ..color = const Color(0x1A000000)
    ..strokeWidth = 0.5;
  static final Paint _centerBorderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _hoverOutlinePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

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
          _drawTile(canvas, Size(tileWidth, tileHeight), isCenter ? 1.0 : 0.8);

          canvas.restore();
        }
      }

      // Draw border around center tile
      canvas.drawRect(
        Rect.fromLTWH(size.width / 3, size.height / 3, size.width / 3, size.height / 3),
        _centerBorderPaint,
      );

      // Draw hover preview for tilemap mode (only in center tile)
      if (hoverPos != null) {
        final tileWidth = size.width / 3;
        final tileHeight = size.height / 3;

        // Calculate which tile is being hovered
        final tileX = (hoverPos!.dx / tileWidth).floor();
        final tileY = (hoverPos!.dy / tileHeight).floor();

        // Only show hover in center tile
        if (tileX == 1 && tileY == 1) {
          final centerTileLeft = tileWidth;
          final centerTileTop = tileHeight;
          final localX = hoverPos!.dx - centerTileLeft;
          final localY = hoverPos!.dy - centerTileTop;

          final tilePixelWidth = tileWidth / width;
          final tilePixelHeight = tileHeight / height;

          final hx = (localX / tilePixelWidth).floor();
          final hy = (localY / tilePixelHeight).floor();

          if (hx >= 0 && hx < width && hy >= 0 && hy < height) {
            final hoverPaint = Paint()
              ..color = currentTool == TileDrawTool.eraser
                  ? Colors.red.withValues(alpha: 0.5)
                  : currentColor.withValues(alpha: 0.5);
            canvas.drawRect(
              Rect.fromLTWH(
                centerTileLeft + hx * tilePixelWidth,
                centerTileTop + hy * tilePixelHeight,
                tilePixelWidth,
                tilePixelHeight,
              ),
              hoverPaint,
            );

            // Draw hover outline
            canvas.drawRect(
              Rect.fromLTWH(
                centerTileLeft + hx * tilePixelWidth,
                centerTileTop + hy * tilePixelHeight,
                tilePixelWidth,
                tilePixelHeight,
              ),
              _hoverOutlinePaint,
            );
          }
        }
      }
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
          canvas.drawRect(
            Rect.fromLTWH(hx * pixelWidth, hy * pixelHeight, pixelWidth, pixelHeight),
            _hoverOutlinePaint,
          );
        }
      }
    }

    // Draw grid lines
    _drawGrid(canvas, size, pixelWidth, pixelHeight);
  }

  void _drawCheckerboard(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    final checkerSize = (pixelWidth / 2).clamp(2.0, 8.0);
    final cols = (size.width / checkerSize).ceil();
    final rows = (size.height / checkerSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final isLight = (col + row) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(col * checkerSize, row * checkerSize, checkerSize, checkerSize),
          isLight ? _lightCheckerPaint : _darkCheckerPaint,
        );
      }
    }
  }

  // Reusable paint for tile drawing
  static final Paint _tilePaint = Paint();

  void _drawTile(Canvas canvas, Size size, double opacity) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;
    final pixelWidthPadded = pixelWidth + 0.5;
    final pixelHeightPadded = pixelHeight + 0.5;
    final pixelCount = pixels.length;

    for (int y = 0; y < height; y++) {
      final yPos = y * pixelHeight;
      final rowStart = y * width;
      for (int x = 0; x < width; x++) {
        final index = rowStart + x;
        if (index < pixelCount) {
          final pixelValue = pixels[index];
          // Skip fully transparent pixels
          if ((pixelValue >> 24) & 0xFF == 0) continue;

          final color = Color(pixelValue);
          _tilePaint.color = opacity < 1.0 ? color.withValues(alpha: color.a * opacity) : color;
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelWidth,
              yPos,
              pixelWidthPadded,
              pixelHeightPadded,
            ),
            _tilePaint,
          );
        }
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    // Only draw grid if pixels are large enough
    if (pixelWidth < 4 || pixelHeight < 4) return;

    // Vertical lines
    for (int x = 0; x <= width; x++) {
      canvas.drawLine(
        Offset(x * pixelWidth, 0),
        Offset(x * pixelWidth, size.height),
        _gridPaint,
      );
    }

    // Horizontal lines
    for (int y = 0; y <= height; y++) {
      canvas.drawLine(
        Offset(0, y * pixelHeight),
        Offset(size.width, y * pixelHeight),
        _gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TileEditorPainter oldDelegate) {
    // Use identical for Uint32List to check reference equality first (faster)
    return !identical(oldDelegate.pixels, pixels) ||
        oldDelegate.displayMode != displayMode ||
        oldDelegate.hoverPos != hoverPos ||
        oldDelegate.currentTool != currentTool ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
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

  // Reusable paint for preview drawing
  static final Paint _previewPaint = Paint();

  _TilePreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;
    final pixelWidthPadded = pixelWidth + 0.5;
    final pixelHeightPadded = pixelHeight + 0.5;
    final pixelCount = pixels.length;

    for (int y = 0; y < height; y++) {
      final rowStart = y * width;
      for (int x = 0; x < width; x++) {
        final index = rowStart + x;
        if (index < pixelCount) {
          final pixelValue = pixels[index];
          // Skip fully transparent pixels
          if ((pixelValue >> 24) & 0xFF == 0) continue;

          _previewPaint.color = Color(pixelValue);
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelWidth,
              y * pixelHeight,
              pixelWidthPadded,
              pixelHeightPadded,
            ),
            _previewPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TilePreviewPainter oldDelegate) {
    return !identical(oldDelegate.pixels, pixels) || oldDelegate.width != width || oldDelegate.height != height;
  }
}
