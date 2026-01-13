import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_html/html.dart';

import '../../core.dart';
import '../../data/models/template.dart';
import '../pixel_point.dart';
import '../../data.dart';
import '../../providers/providers.dart';
import '../../providers/background_image_provider.dart';
import '../services/animation_service.dart';
import '../services/drawing_service.dart';
import '../services/frame_service.dart';
import '../services/import_export_service.dart';
import '../services/layer_service.dart';
import '../services/selection_service.dart';
import '../services/template_service.dart';
import '../services/undo_redo_service.dart';
import '../pixel_canvas_state.dart';
import '../tools.dart';

part 'pixel_controller_provider.g.dart';

@riverpod
class PixelDrawController extends _$PixelDrawController {
  // Services
  late final LayerService _layerService;
  late final FrameService _frameService;
  late final AnimationService _animationService;
  late final DrawingService _drawingService;
  late final SelectionService _selectionService;
  late final UndoRedoService _undoRedoService;
  late final ImportExportService _importExportService;
  late final TemplateService _templateService;

  bool _isBatching = false;
  Uint32List? _activeBuffer;

  // Current project reference

  @override
  PixelCanvasState build(Project project) {
    // Initialize services
    _layerService = LayerService(ref.read(projectRepo));
    _frameService = FrameService(ref.read(projectRepo));
    _animationService = AnimationService(ref.read(projectRepo));
    _drawingService = DrawingService();
    _selectionService = SelectionService(width: project.width, height: project.height);
    _undoRedoService = UndoRedoService();
    _importExportService = ImportExportService();
    _templateService = TemplateService(ref.read(templateAPIRepoProvider));

    return PixelCanvasState(
      width: project.width,
      height: project.height,
      animationStates: List<AnimationStateModel>.from(project.states),
      frames: project.frames.isNotEmpty ? List<AnimationFrame>.from(project.frames) : _createDefaultFrame(),
      currentColor: Colors.black,
      currentTool: PixelTool.pencil,
      mirrorAxis: MirrorAxis.vertical,
      selectionRect: null,
      canUndo: _undoRedoService.canUndo,
      canRedo: _undoRedoService.canRedo,
    );
  }

  List<AnimationFrame> _createDefaultFrame() {
    return [
      AnimationFrame(
        id: 0,
        stateId: 0,
        name: 'Frame 1',
        duration: 100,
        layers: [
          Layer(
            layerId: 0,
            id: 'default-layer',
            name: 'Layer 1',
            pixels: Uint32List(project.width * project.height),
            order: 0,
          ),
        ],
      ),
    ];
  }

  AnimationFrame get currentFrame => state.currentFrame;
  Layer get currentLayer => state.currentLayer;
  bool get canUndo => _undoRedoService.canUndo;
  bool get canRedo => _undoRedoService.canRedo;

  // State management
  void _saveState() {
    _undoRedoService.saveState(state);
    state = state.copyWith(canUndo: canUndo, canRedo: canRedo);
  }

  void _updateProject() {
    ref.read(projectRepo).updateProject(
          project.copyWith(
            frames: state.frames,
            states: state.animationStates,
            editedAt: DateTime.now(),
          ),
        );
  }

  // MARK: Batch Drawing Methods

  // 1. Start Drawing (On Tap Down)
  void startBatchDrawing() {
    _isBatching = true;
    _saveState(); // Save state ONCE before the stroke begins
    // Create a mutable working copy of the current layer
    _activeBuffer = Uint32List.fromList(currentLayer.pixels);
  }

// 2. Update Drawing (On Pan Update)
  void batchSetPixel(int x, int y) {
    if (!_isBatching || _activeBuffer == null) return;

    // Use the mutable method in DrawingService
    _drawingService.setPixelMutable(
      pixels: _activeBuffer!,
      x: x,
      y: y,
      width: state.width,
      height: state.height,
      color: state.currentColor,
      selection: state.selectionRect,
    );

    // We need to notify the UI to redraw, but NOT update the entire Immutable Project State
    // This is the tricky part with Riverpod.
    // Ideally, update a temporary provider or a local value in PixelCanvasController
    // For now, we perform a "cheap" update:

    final updatedLayer = currentLayer.copyWith(pixels: _activeBuffer!);
    // This triggers a rebuild, but doesn't re-allocate the Uint32List because we are reusing _activeBuffer
    // _updateLayerAndFrameSimple(updatedLayer);
  }

  // 2.1 Batch Fill Pixels
  void batchFillPixels(List<PixelPoint<int>> points) {
    if (!_isBatching || _activeBuffer == null) return;

    // Use the mutable method in DrawingService
    _drawingService.fillPixelsMutable(
      pixels: _activeBuffer!,
      points: points,
      width: state.width,
      color: state.currentColor,
      selection: state.selectionRect,
    );

    // Cheap update to notify UI
    final updatedLayer = currentLayer.copyWith(pixels: _activeBuffer!);
    // _updateLayerAndFrameSimple(updatedLayer);
  }

// 3. End Drawing (On Pan End)
  void endBatchDrawing() {
    if (_activeBuffer != null) {
      // Final commit to Undo/Redo history and project structure
      _updateCurrentLayerPixels(_activeBuffer!);
      _activeBuffer = null;
    }
    _isBatching = false;
  }

// Helper for cheap updates without triggering DB/Repo updates
  void _updateLayerAndFrameSimple(Layer updatedLayer) {
    final updatedLayers = List<Layer>.from(currentFrame.layers);
    updatedLayers[state.currentLayerIndex] = updatedLayer;
    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);

    final frameIndex = state.frames.indexWhere((f) => f.id == currentFrame.id);
    final updatedFrames = List<AnimationFrame>.from(state.frames);
    updatedFrames[frameIndex] = updatedFrame;

    // Just update state memory, don't hit the database/repo
    state = state.copyWith(frames: updatedFrames);
  }

  // MARK: Drawing Operations

  // Drawing operations
  void setPixel(int x, int y) {
    _saveState();

    final modifier = _drawingService.createModifier(
      state.currentModifier,
      state.mirrorAxis,
    );

    final newPixels = _drawingService.setPixel(
      pixels: currentLayer.pixels,
      x: x,
      y: y,
      width: state.width,
      height: state.height,
      color: _getDrawingColor(),
      selection: state.selectionRect,
      modifier: modifier,
    );

    _updateCurrentLayerPixels(newPixels);
  }

  void fillPixels(List<PixelPoint<int>> points) {
    if (_selectionService.hasSelection && !_selectionService.isPointsInSelection(points)) {
      return;
    }
    _saveState();

    final newPixels = _drawingService.fillPixels(
      pixels: currentLayer.pixels,
      points: points,
      width: state.width,
      color: _getDrawingColor(),
      selection: state.selectionRect,
    );

    _updateCurrentLayerPixels(newPixels);
  }

  void floodFill(int x, int y) {
    _saveState();

    final newPixels = _drawingService.floodFill(
      pixels: currentLayer.pixels,
      x: x,
      y: y,
      width: state.width,
      height: state.height,
      fillColor: _getDrawingColor(),
      selection: state.selectionRect,
    );

    _updateCurrentLayerPixels(newPixels);
  }

  void clearCanvas() {
    _saveState();

    final newPixels = _drawingService.clearPixels(state.width, state.height);
    _updateCurrentLayerPixels(newPixels);
  }

  Color getPixelColor(int x, int y) {
    return _drawingService.getPixelColor(
      pixels: currentLayer.pixels,
      x: x,
      y: y,
      width: state.width,
      height: state.height,
    );
  }

  void applyGradient(List<Color> gradientColors) {
    _saveState();

    final newPixels = _drawingService.applyGradient(
      pixels: currentLayer.pixels,
      gradientColors: gradientColors,
    );

    _updateCurrentLayerPixels(newPixels);
  }

  // Drag operations
  Offset? _dragStartOffset;
  Uint32List? _originalPixels;

  void startDrag() {
    _saveState();
    _dragStartOffset = null;
    _originalPixels = null;
  }

  void dragPixels(double scale, Offset offset) {
    if (_dragStartOffset == null) {
      // First time, store the starting offset and original pixels
      _dragStartOffset = offset;
      _originalPixels = Uint32List.fromList(currentLayer.pixels);
      return;
    }

    // Calculate the delta offset from the starting offset
    final delta = offset - _dragStartOffset!;

    // Use the drawing service to drag pixels
    final newPixels = _drawingService.dragPixels(
      originalPixels: _originalPixels!,
      currentPixels: currentLayer.pixels,
      width: state.width,
      height: state.height,
      deltaOffset: delta,
    );

    _updateCurrentLayerPixels(newPixels);
  }

  void endDrag() {
    _dragStartOffset = null;
    _originalPixels = null;
  }

  // Selection transformation caching
  // These store the original pixels and bounds before any transformation
  // to avoid extracting from already-modified layer data during drag updates
  Uint32List? _transformCachedPixels;
  Rect? _transformCachedBounds;
  List<PixelPoint<int>>? _transformCachedSelection;

  /// Call this at the start of a rotation or resize operation to cache pixel data
  void startTransformSelection(List<PixelPoint<int>> selection) {
    if (selection.isEmpty || currentLayer.pixels.isEmpty) return;

    final bounds = _getSelectionBounds(selection);
    if (bounds == null || bounds.width <= 0 || bounds.height <= 0) return;

    _saveState();
    _transformCachedSelection = List<PixelPoint<int>>.from(selection);
    _transformCachedBounds = bounds;
    _transformCachedPixels = _extractSelectedPixels(
      currentLayer.pixels,
      selection,
      bounds,
      respectSelectionShape: false,
    );
  }

  /// Call this at the end of a rotation or resize operation to clear cached data
  void endTransformSelection() {
    _transformCachedPixels = null;
    _transformCachedBounds = null;
    _transformCachedSelection = null;
  }

  // Layer operations
  Future<void> addLayer(String name) async {
    final order = _layerService.calculateNextLayerOrder(currentFrame.layers);

    final newLayer = await _layerService.createLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      name: name,
      width: state.width,
      height: state.height,
      order: order,
    );

    final updatedLayers = [...currentFrame.layers, newLayer]..sort((a, b) => a.order.compareTo(b.order));

    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    state = state.copyWith(currentLayerIndex: updatedLayers.length - 1);
  }

  Future<void> removeLayer(int index) async {
    if (currentFrame.layers.length <= 1) return;

    final layerToRemove = currentFrame.layers[index];
    await _layerService.deleteLayer(layerToRemove.layerId);

    final updatedLayers = List<Layer>.from(currentFrame.layers)..removeAt(index);

    // Reorder remaining layers
    final reorderedLayers = updatedLayers.indexed.map((indexed) {
      final (i, layer) = indexed;
      return layer.copyWith(order: i);
    }).toList();

    final updatedFrame = currentFrame.copyWith(layers: reorderedLayers);
    _updateCurrentFrame(updatedFrame);

    // Adjust current layer index
    final newLayerIndex = index >= reorderedLayers.length ? reorderedLayers.length - 1 : index;

    state = state.copyWith(currentLayerIndex: newLayerIndex);
  }

  Future<int> duplicateLayer(int index) async {
    _saveState();
    final layerToDuplicate = currentFrame.layers[index];
    final insertIndex = index + 1;

    final newLayerData = await _layerService.createLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      name: 'Copy of ${layerToDuplicate.name}',
      width: state.width,
      height: state.height,
      order: _layerService.calculateNextLayerOrder(currentFrame.layers),
    );

    final newLayerWithContent = newLayerData.copyWith(
      pixels: Uint32List.fromList(layerToDuplicate.pixels),
      isVisible: layerToDuplicate.isVisible,
    );

    final tempLayers = [...currentFrame.layers, newLayerWithContent];

    final reorderedLayers = _layerService.reorderLayers(
      tempLayers,
      tempLayers.length - 1,
      insertIndex,
    );

    final updatedFrame = currentFrame.copyWith(layers: reorderedLayers);
    _updateCurrentFrame(updatedFrame);

    state = state.copyWith(currentLayerIndex: insertIndex);
    _updateProject();

    return insertIndex;
  }

  void selectLayer(int index) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    state = state.copyWith(currentLayerIndex: index);
  }

  Future<void> toggleLayerVisibility(int index) async {
    final layer = currentFrame.layers[index];
    final updatedLayer = _layerService.toggleLayerVisibility(layer);

    await _updateLayerAndFrame(index, updatedLayer);
  }

  Future<void> reorderLayers(int oldIndex, int newIndex) async {
    final reorderedLayers = _layerService.reorderLayers(
      currentFrame.layers,
      oldIndex,
      newIndex,
    );

    final updatedFrame = currentFrame.copyWith(layers: reorderedLayers);
    _updateCurrentFrame(updatedFrame);

    final newCurrentIndex = oldIndex == state.currentLayerIndex ? newIndex : state.currentLayerIndex;

    state = state.copyWith(currentLayerIndex: newCurrentIndex);
    _updateProject();
  }

  void updateLayer(Layer updatedLayer) {
    final layerIndex = currentFrame.layers.indexWhere(
      (layer) => layer.layerId == updatedLayer.layerId,
    );

    if (layerIndex != -1) {
      final updatedLayers = List<Layer>.from(currentFrame.layers);
      updatedLayers[layerIndex] = updatedLayer;

      final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
      _updateCurrentFrame(updatedFrame);
      _updateProject();
    }
  }

  // Frame operations
  Future<void> addFrame(String name, {int? copyFrameId, int? stateId}) async {
    final copyFrame = copyFrameId != null ? state.frames.firstWhere((f) => f.id == copyFrameId) : null;

    final order = _frameService.calculateNextFrameOrder(state.frames);

    final newFrame = await _frameService.createFrame(
      projectId: project.id,
      name: name,
      stateId: stateId ?? state.currentAnimationState.id,
      width: state.width,
      height: state.height,
      copyFromFrame: copyFrame,
      order: order,
    );

    final updatedFrames = [...state.frames, newFrame];
    state = state.copyWith(
      frames: updatedFrames,
      currentFrameIndex: state.currentFrames.length,
      currentLayerIndex: 0,
    );
  }

  Future<void> removeFrame(int index) async {
    if (state.frames.length <= 1) return;

    final frameToRemove = state.frames[index];
    await _frameService.deleteFrame(frameToRemove.id);

    final updatedFrames = List<AnimationFrame>.from(state.frames)..removeAt(index);

    // Filter frames for current state
    final currentStateFrames = _frameService.getFramesForState(
      updatedFrames,
      state.currentAnimationState.id,
    );

    final currentStateFrameIndex = _frameService
        .getFramesForState(
          state.frames,
          state.currentAnimationState.id,
        )
        .indexWhere((frame) => frame.id == frameToRemove.id);

    // Calculate new frame index
    int newFrameIndex;
    if (currentStateFrameIndex >= 0) {
      // The deleted frame belonged to current state
      newFrameIndex = _frameService.calculateSafeFrameIndex(
        currentStateFrames,
        state.currentFrameIndex,
        currentStateFrameIndex,
      );
    } else {
      // The deleted frame didn't belong to current state, keep current index
      newFrameIndex = state.currentFrameIndex;
    }

    // Ensure the frame index is valid
    final safeFrameIndex = newFrameIndex.clamp(0, currentStateFrames.isEmpty ? 0 : currentStateFrames.length - 1);

    state = state.copyWith(
      frames: updatedFrames,
      currentFrameIndex: safeFrameIndex,
      currentLayerIndex: 0,
    );

    // Update the project
    _updateProject();
  }

  void selectFrame(int frameId) {
    final index = state.currentFrames.indexWhere((frame) => frame.id == frameId);
    if (index >= 0) {
      state = state.copyWith(
        currentFrameIndex: index,
        currentLayerIndex: 0,
      );
    }
  }

  void nextFrame() {
    final nextIndex = (state.currentFrameIndex + 1) % state.currentFrames.length;
    state = state.copyWith(
      currentFrameIndex: nextIndex,
      currentLayerIndex: 0,
    );
  }

  void previousFrame() {
    final prevIndex = (state.currentFrameIndex - 1 + state.currentFrames.length) % state.currentFrames.length;
    state = state.copyWith(
      currentFrameIndex: prevIndex,
      currentLayerIndex: 0,
    );
  }

  // Animation state operations
  Future<void> addAnimationState(String name, int frameRate) async {
    final newState = await _animationService.createAnimationState(
      projectId: project.id,
      name: name,
      frameRate: frameRate,
    );

    state = state.copyWith(
      animationStates: [...state.animationStates, newState],
      currentAnimationStateIndex: state.animationStates.length,
      currentFrameIndex: 0,
      currentLayerIndex: 0,
    );
  }

  Future<void> removeAnimationState(int stateId) async {
    if (!_animationService.canDeleteState(state.animationStates)) return;

    final stateIndex = _animationService.findStateIndex(state.animationStates, stateId);
    if (stateIndex < 0) return;

    await _animationService.deleteAnimationState(stateId);

    final updatedStates = List<AnimationStateModel>.from(state.animationStates)..removeAt(stateIndex);

    final updatedFrames = _animationService.removeFramesForState(
      state.frames,
      stateId,
    );

    final newStateIndex = _animationService.calculateSafeStateIndex(
      updatedStates,
      state.currentAnimationStateIndex,
      stateIndex,
    );

    state = state.copyWith(
      animationStates: updatedStates,
      frames: updatedFrames,
      currentAnimationStateIndex: newStateIndex,
      currentFrameIndex: 0,
      currentLayerIndex: 0,
    );
  }

  void addTemplate(Template template) async {
    final order = _layerService.calculateNextLayerOrder(currentFrame.layers);

    var newLayer = await _layerService.createLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      name: template.name,
      width: state.width,
      height: state.height,
      order: order,
    );

    final pixels = _templateService.applyTemplateToLayer(
      template: template,
      layerPixels: newLayer.pixels,
      layerWidth: state.width,
      layerHeight: state.height,
    );

    newLayer = newLayer.copyWith(pixels: pixels);

    final updatedLayers = [...currentFrame.layers, newLayer]..sort((a, b) => a.order.compareTo(b.order));

    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    state = state.copyWith(currentLayerIndex: updatedLayers.length - 1);

    _updateProject();
  }

  void selectAnimationState(int stateId) {
    final index = _animationService.findStateIndex(state.animationStates, stateId);
    if (index >= 0) {
      state = state.copyWith(
        currentAnimationStateIndex: index,
        currentFrameIndex: 0,
        currentLayerIndex: 0,
      );
    }
  }

  Future<void> updateFrame(int index, AnimationFrame frame) async {
    await _frameService.updateFrame(
      projectId: project.id,
      frame: frame,
    );

    final updatedFrames = List<AnimationFrame>.from(state.frames);
    updatedFrames[index] = frame;

    state = state.copyWith(frames: updatedFrames);
    _updateProject();
  }

  Future<void> reorderFrames(int oldIndex, int newIndex) async {
    final reorderedFrames = _frameService.reorderFrames(
      state.frames,
      oldIndex,
      newIndex,
    );

    state = state.copyWith(
      frames: reorderedFrames,
      currentFrameIndex: oldIndex == state.currentFrameIndex ? newIndex : state.currentFrameIndex,
    );

    _updateProject();
  }

  // Selection operations
  void setSelection(List<PixelPoint<int>>? selection) {
    _selectionService.setSelection(selection, currentLayer.pixels);
    state = state.copyWith(selectionRect: selection);
  }

  void prepareToMoveSelection(List<PixelPoint<int>> initialSelection) {
    if (state.currentLayerIndex < 0 || state.currentLayerIndex >= currentFrame.layers.length) {
      debugPrint("prepareToMoveSelection: Invalid currentLayerIndex");
      return;
    }
    final layer = currentFrame.layers[state.currentLayerIndex];
    _selectionService.setSelection(initialSelection, layer.pixels);
    state = state.copyWith(selectionRect: initialSelection);
  }

  void moveSelection(List<PixelPoint<int>> newSelection, Point delta) {
    if (state.selectionRect == null) {
      debugPrint('No selection to move');
      return;
    }

    if (_selectionService.currentSelection == null || !_selectionService.hasSelection) {
      debugPrint('PixelDrawController.moveSelection: SelectionService not primed or has no selection.');

      if (state.selectionRect != null) {
        prepareToMoveSelection(state.selectionRect!);
      } else {
        return;
      }
    }

    if (_selectionService.currentSelection != null && listEquals(_selectionService.currentSelection!, newSelection)) {
      if (state.selectionRect != newSelection) {
        state = state.copyWith(selectionRect: newSelection);
      }
      return;
    }

    _saveState();

    final newPixels = _selectionService.moveSelection(
      newTargetSelection: newSelection,
      delta: delta,
      currentLayerPixels: Uint32List.fromList(currentLayer.pixels),
    );

    _updateCurrentLayerPixels(newPixels);
    state = state.copyWith(selectionRect: newSelection);
  }

  void clearSelection() {
    _selectionService.clearSelection();
    state = state.copyWith(selectionRect: null);
  }

  // Undo/Redo operations
  void undo() {
    final previousState = _undoRedoService.undo(state);
    if (previousState != null) {
      state = previousState;
      if (previousState.selectionRect != null) {
        _selectionService.setSelection(
          previousState.selectionRect,
          currentLayer.pixels,
        );
      }
      _updateProject();
    }
  }

  void redo() {
    final nextState = _undoRedoService.redo(state);
    if (nextState != null) {
      state = nextState;
      if (nextState.selectionRect != null) {
        _selectionService.setSelection(
          nextState.selectionRect,
          currentLayer.pixels,
        );
      }
      _updateProject();
    }
  }

  // Tool and color operations
  void setCurrentTool(PixelTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  void setCurrentColor(Color color) {
    state = state.copyWith(currentColor: color);
  }

  void setCurrentModifier(PixelModifier modifier) {
    state = state.copyWith(currentModifier: modifier);
  }

  // Import/Export operations
  Future<void> exportProjectAsJson(BuildContext context) async {
    await _importExportService.exportProjectAsJson(
      context: context,
      project: project,
    );
  }

  Future<void> exportImage({
    required BuildContext context,
    bool withBackground = false,
    double? exportWidth,
    double? exportHeight,
  }) async {
    await _importExportService.exportImage(
      context: context,
      project: project,
      layers: currentFrame.layers,
      withBackground: withBackground,
      exportWidth: exportWidth,
      exportHeight: exportHeight,
    );
  }

  Future<void> shareProject(BuildContext context) async {
    await _importExportService.shareProject(
      context: context,
      project: project,
      layers: currentFrame.layers,
    );
  }

  Future<void> exportAnimation({
    required BuildContext context,
    required List<AnimationFrame> frames,
    bool withBackground = false,
    double? exportWidth,
    double? exportHeight,
  }) async {
    await _importExportService.exportAnimation(
      context: context,
      project: project,
      frames: frames,
      withBackground: withBackground,
      exportWidth: exportWidth,
      exportHeight: exportHeight,
    );
  }

  Future<void> exportSpriteSheet({
    required BuildContext context,
    required int columns,
    required int spacing,
    required bool includeAllFrames,
    bool withBackground = false,
    Color backgroundColor = Colors.white,
    double? exportWidth,
    double? exportHeight,
  }) async {
    final frames = includeAllFrames ? state.currentFrames : [state.currentFrame];

    await _importExportService.exportSpriteSheet(
      context: context,
      project: project,
      frames: frames,
      columns: columns,
      spacing: spacing,
      includeAllFrames: includeAllFrames,
      withBackground: withBackground,
      backgroundColor: backgroundColor,
      exportWidth: exportWidth,
      exportHeight: exportHeight,
    );
  }

  Future<void> importImageAsBackground(BuildContext context) async {
    final imageBytes = await _importExportService.importImageAsBackground(context: context);
    if (imageBytes != null) {
      ref.read(backgroundImageProvider.notifier).update((state) => state.copyWith(image: imageBytes));
    }
  }

  Future<void> importImageAsLayer(BuildContext context) async {
    final newLayer = await _importExportService.importImageAsLayer(
      context: context,
      width: state.width,
      height: state.height,
      layerName: 'Imported Image',
    );

    if (newLayer != null) {
      final createdLayer = await _layerService.createLayer(
        projectId: project.id,
        frameId: currentFrame.id,
        name: newLayer.name,
        width: state.width,
        height: state.height,
        order: _layerService.calculateNextLayerOrder(currentFrame.layers),
      );

      final layerWithPixels = createdLayer.copyWith(pixels: newLayer.pixels);

      final updatedLayers = [...currentFrame.layers, layerWithPixels];
      final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
      _updateCurrentFrame(updatedFrame);

      state = state.copyWith(currentLayerIndex: updatedLayers.length - 1);
      _updateProject();
    }
  }

  // Helper methods
  Color _getDrawingColor() {
    return state.currentTool == PixelTool.eraser ? Colors.transparent : state.currentColor;
  }

  void _updateCurrentLayerPixels(Uint32List newPixels) {
    final updatedLayer = currentLayer.copyWith(pixels: newPixels);
    final updatedLayers = List<Layer>.from(currentFrame.layers);
    updatedLayers[state.currentLayerIndex] = updatedLayer;

    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    _layerService.updateLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      layer: updatedLayer,
    );
    _updateProject();
  }

  Future<void> _updateLayerAndFrame(int layerIndex, Layer updatedLayer) async {
    final updatedLayers = List<Layer>.from(currentFrame.layers);
    updatedLayers[layerIndex] = updatedLayer;

    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    await _layerService.updateLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      layer: updatedLayer,
    );
  }

  void _updateCurrentFrame(AnimationFrame updatedFrame) {
    final frameIndex = state.frames.indexWhere(
      (frame) => frame.id == currentFrame.id,
    );

    if (frameIndex != -1) {
      final updatedFrames = List<AnimationFrame>.from(state.frames);
      updatedFrames[frameIndex] = updatedFrame;
      state = state.copyWith(frames: updatedFrames);
    }
  }

  /// MARK: Selection Resizing & Rotation

  void resizeSelection(List<PixelPoint<int>> selection, List<PixelPoint<int>> oldSelection, Rect b, Offset? center) {
    if (oldSelection.isEmpty || selection.isEmpty || currentLayer.pixels.isEmpty) {
      return;
    }

    // Get bounds of NEW selection (after resize)
    final targetBounds = _getSelectionBounds(selection);
    if (targetBounds == null) return;

    // Use cached data if available (from startTransformSelection),
    // otherwise extract from the current layer (for backwards compatibility)
    final Uint32List selectedPixels;
    final Rect originalBounds;
    final List<PixelPoint<int>> originalSelection;

    if (_transformCachedPixels != null && _transformCachedBounds != null && _transformCachedSelection != null) {
      // Use cached data - this prevents extracting from already-modified layer
      selectedPixels = _transformCachedPixels!;
      originalBounds = _transformCachedBounds!;
      originalSelection = _transformCachedSelection!;
    } else {
      // Fallback: extract from layer (single-shot resize without caching)
      final bounds = _getSelectionBounds(oldSelection);
      if (bounds == null) return;
      originalBounds = bounds;
      originalSelection = oldSelection;
      selectedPixels = _extractSelectedPixels(
        currentLayer.pixels,
        oldSelection,
        originalBounds,
        respectSelectionShape: false,
      );
      _saveState();
    }

    final srcWidth = originalBounds.width.toInt().clamp(1, state.width);
    final srcHeight = originalBounds.height.toInt().clamp(1, state.height);
    final targetWidth = targetBounds.width.toInt().clamp(1, state.width);
    final targetHeight = targetBounds.height.toInt().clamp(1, state.height);

    final transformedPixels = PixelUtils.resize(
      selectedPixels,
      srcWidth, // source width
      srcHeight, // source height
      targetWidth, // target width
      targetHeight, // target height
      1, // bilinear interpolation
      0, // transparent background
    );

    final clearedPixels = _clearSelectionArea(
      currentLayer.pixels,
      originalSelection,
    );

    // Constrain target bounds to canvas
    final constrainedBounds = Rect.fromLTRB(
      targetBounds.left.clamp(0, state.width.toDouble()),
      targetBounds.top.clamp(0, state.height.toDouble()),
      targetBounds.right.clamp(1, state.width.toDouble()),
      targetBounds.bottom.clamp(1, state.height.toDouble()),
    );

    // Place transformed pixels
    final resultPixels = _placeTransformedPixels(
      clearedPixels,
      transformedPixels,
      constrainedBounds,
      targetWidth,
      targetHeight,
    );

    _updateCurrentLayerPixels(resultPixels);
  }

  void rotateSelection(
    List<PixelPoint<int>> selection,
    List<PixelPoint<int>> oldSelection,
    double angle,
    Offset? center,
  ) {
    if (oldSelection.isEmpty || currentLayer.pixels.isEmpty) return;

    // Use cached data if available (from startTransformSelection),
    // otherwise extract from the current layer (for backwards compatibility)
    final Uint32List selectedPixels;
    final Rect originalBounds;
    final List<PixelPoint<int>> originalSelection;

    if (_transformCachedPixels != null && _transformCachedBounds != null && _transformCachedSelection != null) {
      // Use cached data - this prevents extracting from already-modified layer
      selectedPixels = _transformCachedPixels!;
      originalBounds = _transformCachedBounds!;
      originalSelection = _transformCachedSelection!;
    } else {
      // Fallback: extract from layer (single-shot rotation without caching)
      final bounds = _getSelectionBounds(oldSelection);
      if (bounds == null || bounds.width <= 0 || bounds.height <= 0) return;
      originalBounds = bounds;
      originalSelection = oldSelection;
      selectedPixels = _extractSelectedPixels(
        currentLayer.pixels,
        oldSelection,
        originalBounds,
        respectSelectionShape: false,
      );
      _saveState();
    }

    if (originalBounds.width <= 0 || originalBounds.height <= 0) return;

    // Rotation center in world coords (pixels/canvas space)
    final rotCenter = center ?? originalBounds.center;

    final srcWidth = originalBounds.width.round().clamp(1, state.width);
    final srcHeight = originalBounds.height.round().clamp(1, state.height);

    // Compute the rotated bounding box in world coords
    final rotatedBounds = _computeRotatedBounds(originalBounds, rotCenter, angle);

    // Produce the rotated pixel buffer sized to rotatedBounds.w × rotatedBounds.h
    final rotatedPixels = PixelUtils.applyRotationWithBounds(
      selectedPixels,
      srcWidth,
      srcHeight,
      angle,
      originalBounds, // original (unrotated) world bounds
      rotatedBounds, // rotated world bounds (can be outside canvas)
      rotCenter,
      1, // bilinear
      0, // transparent background outside source
    );
    if (rotatedPixels.isEmpty) return;

    // Clear the ORIGINAL selection area on the layer (before rotation)
    final clearedPixels = _clearSelectionArea(
      currentLayer.pixels,
      originalSelection,
    );

    // Clamp destination rect to canvas; _placeTransformedPixels should clip if needed
    final constrainedDest = Rect.fromLTRB(
      rotatedBounds.left.clamp(0.0, state.width.toDouble()),
      rotatedBounds.top.clamp(0.0, state.height.toDouble()),
      rotatedBounds.right.clamp(1.0, state.width.toDouble()),
      rotatedBounds.bottom.clamp(1.0, state.height.toDouble()),
    );

    final targetW = rotatedBounds.width.round().clamp(1, state.width);
    final targetH = rotatedBounds.height.round().clamp(1, state.height);

    // Blit the rotated buffer into the (clipped) destination area
    final resultPixels = _placeTransformedPixels(
      clearedPixels,
      rotatedPixels,
      constrainedDest,
      targetW,
      targetH,
    );

    _updateCurrentLayerPixels(resultPixels);
  }

  /// Rotated AABB of [rect] about [center] by [angle] (radians) in screen coords.
  Rect _computeRotatedBounds(Rect rect, Offset center, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    Offset rot(Offset p) {
      final dx = p.dx - center.dx;
      final dy = p.dy - center.dy;
      return Offset(
        center.dx + dx * c - dy * s,
        center.dy + dx * s + dy * c,
      );
    }

    final p1 = rot(rect.topLeft);
    final p2 = rot(rect.topRight);
    final p3 = rot(rect.bottomLeft);
    final p4 = rot(rect.bottomRight);

    final minX = math.min(math.min(p1.dx, p2.dx), math.min(p3.dx, p4.dx));
    final maxX = math.max(math.max(p1.dx, p2.dx), math.max(p3.dx, p4.dx));
    final minY = math.min(math.min(p1.dy, p2.dy), math.min(p3.dy, p4.dy));
    final maxY = math.max(math.max(p1.dy, p2.dy), math.max(p3.dy, p4.dy));

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

// Helper methods for selection transformation

  Rect? _getSelectionBounds(List<PixelPoint<int>> selection) {
    if (selection.isEmpty) return null;

    int minX = selection.first.x;
    int maxX = selection.first.x;
    int minY = selection.first.y;
    int maxY = selection.first.y;

    for (final point in selection) {
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }

    return Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      (maxX + 1).toDouble(),
      (maxY + 1).toDouble(),
    );
  }

  Uint32List _extractSelectedPixels(
    Uint32List sourcePixels,
    List<PixelPoint<int>> selection,
    Rect bounds, {
    bool respectSelectionShape = false,
  }) {
    final width = bounds.width.toInt();
    final height = bounds.height.toInt();

    if (width <= 0 || height <= 0) {
      return Uint32List(0);
    }

    final pixels = Uint32List(width * height);
    final boundsLeft = bounds.left.toInt();
    final boundsTop = bounds.top.toInt();

    // For non-rectangular selections (like lasso), we need to check each pixel
    Set<String>? selectionSet;
    if (respectSelectionShape && selection.isNotEmpty) {
      selectionSet = <String>{};
      for (final point in selection) {
        selectionSet.add('${point.x},${point.y}');
      }
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final worldX = boundsLeft + x;
        final worldY = boundsTop + y;

        // Check if this pixel is in the selection (if needed)
        if (selectionSet != null && !selectionSet.contains('$worldX,$worldY')) {
          continue; // Skip pixels outside selection shape
        }

        // Check if world coordinates are valid
        if (worldX >= 0 && worldX < state.width && worldY >= 0 && worldY < state.height) {
          final sourceIndex = worldY * state.width + worldX;
          final destIndex = y * width + x;

          if (sourceIndex >= 0 && sourceIndex < sourcePixels.length) {
            pixels[destIndex] = sourcePixels[sourceIndex];
          }
        }
      }
    }

    return pixels;
  }

  Uint32List _clearSelectionArea(
    Uint32List pixels,
    List<PixelPoint<int>> selection,
  ) {
    final result = Uint32List.fromList(pixels);

    for (final point in selection) {
      final index = point.y * state.width + point.x;
      if (index >= 0 && index < result.length) {
        result[index] = 0; // Clear to transparent
      }
    }

    return result;
  }

  Uint32List _placeTransformedPixels(
    Uint32List targetPixels,
    Uint32List transformedPixels,
    Rect targetBounds,
    int sourceWidth,
    int sourceHeight,
  ) {
    final result = Uint32List.fromList(targetPixels);

    final targetX = targetBounds.left.round();
    final targetY = targetBounds.top.round();

    for (int y = 0; y < sourceHeight; y++) {
      for (int x = 0; x < sourceWidth; x++) {
        final sourceIndex = y * sourceWidth + x;
        if (sourceIndex >= 0 && sourceIndex < transformedPixels.length) {
          final pixel = transformedPixels[sourceIndex];

          // Skip transparent pixels
          if (pixel == 0) continue;

          final destX = targetX + x;
          final destY = targetY + y;

          if (destX >= 0 && destX < state.width && destY >= 0 && destY < state.height) {
            final destIndex = destY * state.width + destX;
            if (destIndex >= 0 && destIndex < result.length) {
              result[destIndex] = pixel;
            }
          }
        }
      }
    }

    return result;
  }

  Rect _calculateRotatedBounds(Rect originalBounds, double angle, Offset center) {
    // Calculate the four corners of the original bounds
    final corners = [
      Offset(originalBounds.left, originalBounds.top),
      Offset(originalBounds.right, originalBounds.top),
      Offset(originalBounds.right, originalBounds.bottom),
      Offset(originalBounds.left, originalBounds.bottom),
    ];

    // Rotate each corner around the center
    final rotatedCorners = corners.map((corner) {
      final dx = corner.dx - center.dx;
      final dy = corner.dy - center.dy;

      final cos = math.cos(angle);
      final sin = math.sin(angle);

      final rotatedX = center.dx + dx * cos - dy * sin;
      final rotatedY = center.dy + dx * sin + dy * cos;

      return Offset(rotatedX, rotatedY);
    }).toList();

    // Find the new bounding box
    double minX = rotatedCorners.first.dx;
    double maxX = rotatedCorners.first.dx;
    double minY = rotatedCorners.first.dy;
    double maxY = rotatedCorners.first.dy;

    for (final corner in rotatedCorners) {
      minX = math.min(minX, corner.dx);
      maxX = math.max(maxX, corner.dx);
      minY = math.min(minY, corner.dy);
      maxY = math.max(maxY, corner.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  List<PixelPoint<int>> _createSelectionFromBounds(Rect bounds) {
    final selection = <PixelPoint<int>>[];

    final minX = bounds.left.round().clamp(0, state.width - 1);
    final maxX = bounds.right.round().clamp(1, state.width);
    final minY = bounds.top.round().clamp(0, state.height - 1);
    final maxY = bounds.bottom.round().clamp(1, state.height);

    for (int y = minY; y < maxY; y++) {
      for (int x = minX; x < maxX; x++) {
        if (x >= 0 && x < state.width && y >= 0 && y < state.height) {
          selection.add(PixelPoint<int>(x, y));
        }
      }
    }

    return selection;
  }

  Uint32List _applyScaleTransform(
    Uint32List pixels,
    int width,
    int height,
    double scaleX,
    double scaleY,
  ) {
    // Use uniform scale (average of X and Y) for now
    // You could extend PixelUtils to support non-uniform scaling
    final scale = (scaleX + scaleY) / 2;

    return PixelUtils.applyScale(
      pixels,
      width,
      height,
      scale,
      width / 2,
      height / 2,
      1, // Bilinear interpolation
      0, // Transparent background
    );
  }
}
