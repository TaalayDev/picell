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
import '../../widgets/dialogs/tilemap_export_dialog.dart';
import '../tile_generator_screen.dart';
import 'tilemap_canvas_widget.dart';
import 'tilemap_painters.dart';
import 'tilemap_panels.dart';

export 'tilemap_canvas_widget.dart';
export 'tilemap_painters.dart';
export 'tilemap_panels.dart';
export 'tilemap_screen_controller.dart';

enum ScreenSize { mobile, tablet, desktop }

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
  bool _showTilesPanel = false;
  bool _showLayersPanel = false;

  ScreenSize _getScreenSize(double width) {
    if (width < 600) return ScreenSize.mobile;
    if (width < 1000) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    // _saveProject();
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
    if (_isSaving || !mounted) return;

    final notifier = ref.read(_provider.notifier);
    final currentState = ref.read(_provider);

    if (_lastSavedState != null &&
        _lastSavedState!.tiles.length == currentState.tiles.length &&
        _lastSavedState!.layers.length == currentState.layers.length) {}

    _isSaving = true;
    try {
      final tilemapJson = notifier.toJsonString();
      final thumbnailPixels = notifier.generateThumbnailPixels();
      final tileWidth = widget.project.tileWidth ?? 16;
      final tileHeight = widget.project.tileHeight ?? 16;
      final mapWidth = currentState.gridWidth * tileWidth;
      final mapHeight = currentState.gridHeight * tileHeight;

      final thumbnail = ImageHelper.convertToBytes(thumbnailPixels);

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
    final screenSize = _getScreenSize(size.width);
    final isDesktop = screenSize == ScreenSize.desktop;
    final isTablet = screenSize == ScreenSize.tablet;
    final isMobile = screenSize == ScreenSize.mobile;

    ref.listen<TileMapState>(_provider, (previous, next) {
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
          child: SafeArea(
            child: Stack(
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Column(
                    children: [
                      _buildTopBar(context, state, notifier, colorScheme, screenSize),
                      Expanded(
                        child: Row(
                          children: [
                            // Desktop: Always show tile panel
                            // Tablet: Show as overlay when toggled
                            if (isDesktop)
                              TileCollectionPanel(
                                state: state,
                                notifier: notifier,
                                project: widget.project,
                                onAddTile: () => _navigateToTileGenerator(context, notifier, state),
                                onEditTile: (tile) => notifier.startEditingTileById(tile.id),
                              ),
                            Expanded(
                              child: Stack(
                                children: [
                                  _buildTilemapCanvas(context, state, notifier, colorScheme, screenSize),
                                  // Tablet overlay panels
                                  if (isTablet && _showTilesPanel)
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Material(
                                        elevation: 8,
                                        child: TileCollectionPanel(
                                          state: state,
                                          notifier: notifier,
                                          project: widget.project,
                                          onAddTile: () => _navigateToTileGenerator(context, notifier, state),
                                          onEditTile: (tile) => notifier.startEditingTileById(tile.id),
                                          onClose: () => setState(() => _showTilesPanel = false),
                                        ),
                                      ),
                                    ),
                                  if (isTablet && _showLayersPanel)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Material(
                                        elevation: 8,
                                        child: LayersPanel(
                                          state: state,
                                          notifier: notifier,
                                          onClose: () => setState(() => _showLayersPanel = false),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isDesktop)
                              LayersPanel(
                                state: state,
                                notifier: notifier,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Mobile bottom navigation
                  bottomNavigationBar: isMobile ? _buildMobileBottomBar(context, state, notifier, colorScheme) : null,
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
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
    ScreenSize screenSize,
  ) {
    final isMobile = screenSize == ScreenSize.mobile;
    final isTablet = screenSize == ScreenSize.tablet;

    return Container(
      height: isMobile ? 48 : 56,
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
            iconSize: isMobile ? 20 : 24,
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.project.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Tablet: Panel toggle buttons
          if (isTablet) ...[
            IconButton(
              icon: Icon(_showTilesPanel ? Icons.grid_view : Icons.grid_view_outlined),
              onPressed: () => setState(() {
                _showTilesPanel = !_showTilesPanel;
                if (_showTilesPanel) _showLayersPanel = false;
              }),
              tooltip: 'Tiles',
              isSelected: _showTilesPanel,
            ),
            IconButton(
              icon: Icon(_showLayersPanel ? Icons.layers : Icons.layers_outlined),
              onPressed: () => setState(() {
                _showLayersPanel = !_showLayersPanel;
                if (_showLayersPanel) _showTilesPanel = false;
              }),
              tooltip: 'Layers',
              isSelected: _showLayersPanel,
            ),
            const SizedBox(width: 8),
          ],
          // Tools - compact on mobile/tablet
          TilemapToolbar(
            state: state,
            notifier: notifier,
            isModifierPressed: _isModifierPressed,
            compact: isMobile,
          ),
          const Spacer(),
          // Hide hint on mobile
          if (!isMobile) ...[
            EditHintWidget(isModifierPressed: _isModifierPressed),
            const SizedBox(width: 12),
          ],
          // Compact view controls on tablet/mobile
          ViewControlsWidget(
            state: state,
            notifier: notifier,
            compact: isMobile,
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: state.layers.any((l) => l.tileIds.any((r) => r.any((t) => t != null)))
                  ? () => _exportTilemap(context, state, notifier)
                  : null,
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('Export'),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: state.layers.any((l) => l.tileIds.any((r) => r.any((t) => t != null)))
                  ? () => _exportTilemap(context, state, notifier)
                  : null,
            ),
          ],
          SizedBox(width: isMobile ? 8 : 16),
        ],
      ),
    );
  }

  Widget _buildMobileBottomBar(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MobileNavButton(
                icon: Icons.grid_view,
                label: 'Tiles',
                badge: state.tiles.length.toString(),
                onTap: () => _showTilesPanelBottomSheet(context, state, notifier),
              ),
              _MobileNavButton(
                icon: Icons.layers,
                label: 'Layers',
                badge: state.layers.length.toString(),
                onTap: () => _showLayersPanelBottomSheet(context, state, notifier),
              ),
              if (state.selectedTile != null)
                _MobileSelectedTileButton(
                  tile: state.selectedTile!,
                  onTap: () => _showTilesPanelBottomSheet(context, state, notifier),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTilesPanelBottomSheet(BuildContext context, TileMapState state, TileMapNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => TileCollectionPanel(
          state: state,
          notifier: notifier,
          project: widget.project,
          onAddTile: () {
            Navigator.pop(context);
            _navigateToTileGenerator(context, notifier, state);
          },
          onEditTile: (tile) {
            Navigator.pop(context);
            notifier.startEditingTileById(tile.id);
          },
          scrollController: scrollController,
          isBottomSheet: true,
        ),
      ),
    );
  }

  void _showLayersPanelBottomSheet(BuildContext context, TileMapState state, TileMapNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) => LayersPanel(
          state: state,
          notifier: notifier,
          scrollController: scrollController,
          isBottomSheet: true,
        ),
      ),
    );
  }

  Widget _buildTilemapCanvas(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
    ScreenSize screenSize,
  ) {
    final margin = switch (screenSize) {
      ScreenSize.mobile => 8.0,
      ScreenSize.tablet => 12.0,
      ScreenSize.desktop => 16.0,
    };

    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(screenSize == ScreenSize.mobile ? 12 : 16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenSize == ScreenSize.mobile ? 11 : 15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TilemapCanvasWidget(
              state: state,
              notifier: notifier,
              constraints: constraints,
              isModifierPressed: _isModifierPressed,
              screenSize: screenSize,
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
              onTileLongPress: (x, y) {
                // Mobile: long press to edit tile
                notifier.startEditingTile(x, y);
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
    TilemapExportDialog.show(
      context: context,
      state: state,
      notifier: notifier,
      tileWidth: widget.project.tileWidth ?? 16,
      tileHeight: widget.project.tileHeight ?? 16,
      projectName: widget.project.name,
    );
  }
}

class _MobileNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _MobileNavButton({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              label: badge != null ? Text(badge!) : null,
              isLabelVisible: badge != null,
              child: Icon(icon, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSelectedTileButton extends StatelessWidget {
  final SavedTile tile;
  final VoidCallback onTap;

  const _MobileSelectedTileButton({
    required this.tile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colorScheme.outline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CustomPaint(
                  painter: TilePreviewPainter(
                    pixels: tile.pixels,
                    width: tile.width,
                    height: tile.height,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 9,
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  tile.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
