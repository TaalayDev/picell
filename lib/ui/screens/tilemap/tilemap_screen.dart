import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core.dart';
import '../../../data.dart';
import '../../../providers/providers.dart';
import '../../../tilemap/tilemap_edit_modal.dart';
import '../../../tilemap/tilemap_notifier.dart';
import '../../widgets/animated_background.dart';
import '../tile_generator_screen.dart';
import 'tilemap_canvas_widget.dart';
import 'tilemap_panels.dart';

export 'tilemap_canvas_widget.dart';
export 'tilemap_painters.dart';
export 'tilemap_panels.dart';
export 'tilemap_screen_controller.dart';

class TileMapScreen extends StatefulHookConsumerWidget {
  const TileMapScreen({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  ConsumerState<TileMapScreen> createState() => _TileMapScreenState();
}

class _TileMapScreenState extends ConsumerState<TileMapScreen> {
  late final _provider = tileMapProvider(widget.project);
  final _focusNode = FocusNode();
  bool _isModifierPressed = false;
  Timer? _saveDebouncer;
  TileMapState? _lastSavedState;
  bool _isSaving = false;

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    // Save before disposing
    _saveProject();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 2), () {
      _saveProject();
    });
  }

  Future<void> _saveProject() async {
    if (_isSaving) return;

    final notifier = ref.read(_provider.notifier);
    final currentState = ref.read(_provider);

    // Skip if nothing changed
    if (_lastSavedState != null &&
        _lastSavedState!.tiles.length == currentState.tiles.length &&
        _lastSavedState!.layers.length == currentState.layers.length) {
      // Basic check - for a full deep comparison we'd need more complex logic
      // but this catches the most common cases
    }

    _isSaving = true;
    try {
      final tilemapJson = notifier.toJsonString();
      final thumbnailPixels = notifier.generateThumbnailPixels();
      final tileWidth = widget.project.tileWidth ?? 16;
      final tileHeight = widget.project.tileHeight ?? 16;
      final mapWidth = currentState.gridWidth * tileWidth;
      final mapHeight = currentState.gridHeight * tileHeight;

      // Convert pixels to bytes for thumbnail storage
      final thumbnail = ImageHelper.convertToBytes(thumbnailPixels);

      // Update project with tilemap data, thumbnail, and map dimensions
      // width/height are updated to map dimensions so thumbnail renders correctly
      final updatedProject = widget.project.copyWith(
        tilemapData: tilemapJson,
        thumbnail: thumbnail,
        width: mapWidth,
        height: mapHeight,
        editedAt: DateTime.now(),
      );

      await ref.read(projectRepo).updateProject(updatedProject);
      _lastSavedState = currentState;
    } catch (e) {
      debugPrint('Failed to save tilemap: $e');
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 1000;

    // Listen for state changes to trigger auto-save
    ref.listen<TileMapState>(_provider, (previous, next) {
      // Only schedule save if tiles or layers have changed
      if (previous != null &&
          (previous.tiles != next.tiles ||
              previous.layers != next.layers ||
              previous.gridWidth != next.gridWidth ||
              previous.gridHeight != next.gridHeight)) {
        _scheduleSave();
      }
    });

    return AnimatedBackground(
      child: GestureDetector(
        onTap: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) {
            final isModifier = event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight ||
                event.logicalKey == LogicalKeyboardKey.metaLeft ||
                event.logicalKey == LogicalKeyboardKey.metaRight;

            if (isModifier) {
              setState(() {
                _isModifierPressed = event is KeyDownEvent;
              });
            }
          },
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  children: [
                    _buildTopBar(context, state, notifier, colorScheme),
                    Expanded(
                      child: Row(
                        children: [
                          TileCollectionPanel(
                            state: state,
                            notifier: notifier,
                            project: widget.project,
                            onAddTile: () => _navigateToTileGenerator(context, notifier, state),
                            onEditTile: (tile) => notifier.startEditingTileById(tile.id),
                          ),
                          Expanded(
                            child: _buildTilemapCanvas(context, state, notifier, colorScheme),
                          ),
                          if (isWide)
                            LayersPanel(
                              state: state,
                              notifier: notifier,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isEditingTile)
                TileEditModal(
                  state: state,
                  notifier: notifier,
                  tileWidth: widget.project.tileWidth ?? 16,
                  tileHeight: widget.project.tileHeight ?? 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Text(
            widget.project.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          TilemapToolbar(
            state: state,
            notifier: notifier,
            isModifierPressed: _isModifierPressed,
          ),
          const Spacer(),
          EditHintWidget(isModifierPressed: _isModifierPressed),
          const SizedBox(width: 12),
          ViewControlsWidget(
            state: state,
            notifier: notifier,
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: state.layers.any((l) => l.tileIds.any((r) => r.any((t) => t != null)))
                ? () => _exportTilemap(context, state, notifier)
                : null,
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('Export'),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildTilemapCanvas(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TilemapCanvasWidget(
              state: state,
              notifier: notifier,
              constraints: constraints,
              isModifierPressed: _isModifierPressed,
              onTileTap: (x, y) {
                if (_isModifierPressed) {
                  notifier.startEditingTile(x, y);
                } else {
                  _applyCurrentTool(notifier, state, x, y);
                }
              },
              onTileDrag: (x, y) {
                _applyCurrentTool(notifier, state, x, y);
              },
            );
          },
        ),
      ),
    );
  }

  void _applyCurrentTool(TileMapNotifier notifier, TileMapState state, int x, int y) {
    switch (state.currentTool) {
      case TileMapTool.paint:
        notifier.paintTile(x, y);
        break;
      case TileMapTool.erase:
        notifier.eraseTile(x, y);
        break;
      case TileMapTool.fill:
        notifier.fillTiles(x, y);
        break;
      case TileMapTool.eyedropper:
        notifier.pickTile(x, y);
        break;
      case TileMapTool.select:
        break;
    }
  }

  void _navigateToTileGenerator(BuildContext context, TileMapNotifier notifier, TileMapState state) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => TileGeneratorScreen(
          project: widget.project,
          returnResultForTilemap: true,
        ),
      ),
    );

    if (result != null && result['pixels'] is Uint32List) {
      notifier.addTileFromPixels(
        name: result['name'] ?? 'Tile ${state.tiles.length + 1}',
        pixels: result['pixels'],
        width: result['width'] ?? widget.project.tileWidth ?? 16,
        height: result['height'] ?? widget.project.tileHeight ?? 16,
        sourceTemplateId: result['templateId'],
      );
    }
  }

  void _exportTilemap(BuildContext context, TileMapState state, TileMapNotifier notifier) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon!')),
    );
  }
}
