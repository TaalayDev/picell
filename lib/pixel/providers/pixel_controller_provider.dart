import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:image/image.dart' as img;

import '../../core.dart';
import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../../data/models/template.dart';
import '../pixel_point.dart';
import '../../data.dart';
import '../../providers/providers.dart';
import '../../providers/background_image_provider.dart';
import '../../providers/imported_palette_provider.dart';
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
    _selectionService =
        SelectionService(width: project.width, height: project.height);
    _undoRedoService = UndoRedoService();
    _importExportService = ImportExportService();
    _templateService = TemplateService(ref.read(templateAPIRepoProvider));

    return PixelCanvasState(
      width: project.width,
      height: project.height,
      animationStates: project.states.isNotEmpty
          ? List<AnimationStateModel>.from(project.states)
          : [const AnimationStateModel(id: 0, name: 'Default', frameRate: 12)],
      frames: project.frames.isNotEmpty
          ? List<AnimationFrame>.from(project.frames)
          : _createDefaultFrame(),
      currentColor: Colors.black,
      currentTool: PixelTool.pencil,
      mirrorAxis: MirrorAxis.vertical,
      selectionState: null,
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

  void startBatchDrawing() {
    _isBatching = true;
    _saveState();
    _activeBuffer = Uint32List.fromList(currentLayer.pixels);
  }

  void batchSetPixel(int x, int y) {
    if (!_isBatching || _activeBuffer == null) return;

    _drawingService.setPixelMutable(
      pixels: _activeBuffer!,
      x: x,
      y: y,
      width: state.width,
      height: state.height,
      color: state.currentColor,
      selection: state.selectionState?.region,
    );
  }

  void batchFillPixels(List<PixelPoint<int>> points) {
    if (!_isBatching || _activeBuffer == null) return;

    _drawingService.fillPixelsMutable(
      pixels: _activeBuffer!,
      points: points,
      width: state.width,
      color: state.currentColor,
      selection: state.selectionState?.region,
    );
  }

  void endBatchDrawing() {
    if (_activeBuffer != null) {
      _updateCurrentLayerPixels(_activeBuffer!);
      _activeBuffer = null;
    }
    _isBatching = false;
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
      selection: state.selectionState?.region,
      modifier: modifier,
    );

    _updateCurrentLayerPixels(newPixels);
  }

  void fillPixels(List<PixelPoint<int>> points) {
    final sel = state.selectionState?.region;
    if (sel != null && points.isNotEmpty) {
      // Check if any points are in selection
      final anyInside = points.any((p) => sel.contains(p.x, p.y));
      if (!anyInside) return;
    }
    _saveState();

    final newPixels = _drawingService.fillPixels(
      pixels: currentLayer.pixels,
      points: points,
      width: state.width,
      color: _getDrawingColor(),
      selection: state.selectionState?.region,
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
      selection: state.selectionState?.region,
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

  void clearSelectionArea() {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return;
    _saveState();
    final clearedPixels = _selectionService.clearPixelsInSelection(
      sel,
      currentLayer.pixels,
      state.width,
      state.height,
    );
    _updateCurrentLayerPixels(clearedPixels);
  }

  Future<void> selectionToNewLayer({bool clearSource = false}) async {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return;

    final layerId = const Uuid().v4();
    final newLayerPixels = _selectionService.extractPixels(
      sel,
      currentLayer.pixels,
      state.width,
      state.height,
    );

    // Check if any pixels were extracted
    bool hasPixels = newLayerPixels.any((p) => p != 0);
    if (!hasPixels) return;

    _saveState();

    if (clearSource) {
      final clearedPixels = _selectionService.clearPixelsInSelection(
        sel,
        currentLayer.pixels,
        state.width,
        state.height,
      );
      _updateCurrentLayerPixels(clearedPixels);
    }

    final newLayer = Layer(
      layerId: 0,
      id: layerId,
      name: 'Selection',
      pixels: newLayerPixels,
      isVisible: true,
      order: state.currentFrame.layers.length, // Add to top
    );

    await addLayerWithPixels(newLayer);

    // Select the new layer (it's added at the end)
    selectLayer(state.currentFrame.layers.length - 1);
  }

  Uint32List? _transformCachedPixels;
  Uint32List? _transformCachedLayerWithoutSelection; // layer pixels with selection cleared
  Rect? _transformCachedBounds;
  SelectionRegion? _transformCachedRegion;
  Offset _totalMoveOffset = Offset.zero;

  void startTransformSelection(SelectionRegion region) {
    if (currentLayer.pixels.isEmpty) return;

    final bounds = region.bounds;
    if (bounds.width <= 0 || bounds.height <= 0) return;

    _saveState();
    _transformCachedRegion = region;
    _transformCachedBounds = bounds;

    // Extract selected pixels into a local buffer
    final bw = bounds.width.ceil();
    final bh = bounds.height.ceil();
    final extracted = Uint32List(bw * bh);
    final indices = region.getSelectedPixelIndices(state.width, state.height);
    for (final idx in indices) {
      if (idx >= 0 &&
          idx < currentLayer.pixels.length &&
          currentLayer.pixels[idx] != 0) {
        final x = idx % state.width;
        final y = idx ~/ state.width;
        final lx = x - bounds.left.floor();
        final ly = y - bounds.top.floor();
        if (lx >= 0 && lx < bw && ly >= 0 && ly < bh) {
          extracted[ly * bw + lx] = currentLayer.pixels[idx];
        }
      }
    }
    _transformCachedPixels = extracted;

    // Cache the layer with the selection area cleared — used for smooth move
    _transformCachedLayerWithoutSelection = _selectionService.clearPixelsInSelection(
      region,
      currentLayer.pixels,
      state.width,
      state.height,
    );
    _totalMoveOffset = Offset.zero;

    // Enter transform mode in selection state
    state = state.copyWith(
      selectionState: state.selectionState?.copyWith(
        isTransforming: true,
        capturedPixels: () => extracted,
        capturedBounds: () => bounds,
      ),
    );
  }

  void endTransformSelection() {
    _transformCachedPixels = null;
    _transformCachedLayerWithoutSelection = null;
    _transformCachedBounds = null;
    _transformCachedRegion = null;
    _totalMoveOffset = Offset.zero;

    if (state.selectionState != null) {
      state = state.copyWith(
        selectionState: state.selectionState!.copyWith(
          isTransforming: false,
          capturedPixels: () => null,
          capturedBounds: () => null,
        ),
      );
    }
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

    final updatedLayers = [...currentFrame.layers, newLayer]
      ..sort((a, b) => a.order.compareTo(b.order));

    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    state = state.copyWith(currentLayerIndex: updatedLayers.length - 1);
  }

  /// Add a layer with pre-existing pixels (for import operations)
  Future<void> addLayerWithPixels(Layer layer) async {
    _saveState();
    final order = _layerService.calculateNextLayerOrder(currentFrame.layers);

    final newLayer = await _layerService.createLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      name: layer.name,
      width: state.width,
      height: state.height,
      order: order,
    );

    final layerWithPixels = newLayer.copyWith(pixels: layer.pixels);

    final updatedLayers = [...currentFrame.layers, layerWithPixels];
    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    state = state.copyWith(currentLayerIndex: updatedLayers.length - 1);
    _updateProject();
  }

  Future<void> removeLayer(int index) async {
    if (currentFrame.layers.length <= 1) return;

    final layerToRemove = currentFrame.layers[index];
    await _layerService.deleteLayer(layerToRemove.layerId);

    final updatedLayers = List<Layer>.from(currentFrame.layers)
      ..removeAt(index);

    final reorderedLayers = updatedLayers.indexed.map((indexed) {
      final (i, layer) = indexed;
      return layer.copyWith(order: i);
    }).toList();

    final updatedFrame = currentFrame.copyWith(layers: reorderedLayers);
    _updateCurrentFrame(updatedFrame);

    final newLayerIndex =
        index >= reorderedLayers.length ? reorderedLayers.length - 1 : index;

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

    final newCurrentIndex = oldIndex == state.currentLayerIndex
        ? newIndex
        : state.currentLayerIndex;

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
    final copyFrame = copyFrameId != null
        ? state.frames.firstWhere((f) => f.id == copyFrameId)
        : null;

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

    final updatedFrames = List<AnimationFrame>.from(state.frames)
      ..removeAt(index);

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

    int newFrameIndex;
    if (currentStateFrameIndex >= 0) {
      newFrameIndex = _frameService.calculateSafeFrameIndex(
        currentStateFrames,
        state.currentFrameIndex,
        currentStateFrameIndex,
      );
    } else {
      newFrameIndex = state.currentFrameIndex;
    }

    // Ensure the frame index is valid
    final safeFrameIndex = newFrameIndex.clamp(
        0, currentStateFrames.isEmpty ? 0 : currentStateFrames.length - 1);

    state = state.copyWith(
      frames: updatedFrames,
      currentFrameIndex: safeFrameIndex,
      currentLayerIndex: 0,
    );

    // Update the project
    _updateProject();
  }

  void selectFrame(int frameId) {
    final index =
        state.currentFrames.indexWhere((frame) => frame.id == frameId);
    if (index >= 0) {
      state = state.copyWith(
        currentFrameIndex: index,
        currentLayerIndex: 0,
      );
    }
  }

  void nextFrame() {
    final nextIndex =
        (state.currentFrameIndex + 1) % state.currentFrames.length;
    state = state.copyWith(
      currentFrameIndex: nextIndex,
      currentLayerIndex: 0,
    );
  }

  void previousFrame() {
    final prevIndex =
        (state.currentFrameIndex - 1 + state.currentFrames.length) %
            state.currentFrames.length;
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

    // Copy the first frame of the current state as the starting frame
    final currentFirstFrame =
        state.currentFrames.isNotEmpty ? state.currentFrames.first : null;
    final defaultFrame = await _frameService.createFrame(
      projectId: project.id,
      name: 'Frame 1',
      stateId: newState.id,
      width: state.width,
      height: state.height,
      copyFromFrame: currentFirstFrame,
      order: 0,
    );

    state = state.copyWith(
      animationStates: [...state.animationStates, newState],
      frames: [...state.frames, defaultFrame],
      currentAnimationStateIndex: state.animationStates.length,
      currentFrameIndex: 0,
      currentLayerIndex: 0,
    );
  }

  Future<void> copyAnimationState(int sourceStateId) async {
    // Find the source state
    final sourceIndex =
        _animationService.findStateIndex(state.animationStates, sourceStateId);
    if (sourceIndex < 0) return;
    final sourceState = state.animationStates[sourceIndex];

    // Create a new animation state with a "Copy of" name
    final newState = await _animationService.createAnimationState(
      projectId: project.id,
      name: '${sourceState.name} (copy)',
      frameRate: sourceState.frameRate,
    );

    // Copy all frames belonging to the source state
    final sourceFrames =
        state.frames.where((f) => f.stateId == sourceStateId).toList();
    final newFrames = <AnimationFrame>[];
    for (final frame in sourceFrames) {
      final copiedFrame = await _frameService.createFrame(
        projectId: project.id,
        name: frame.name,
        stateId: newState.id,
        width: state.width,
        height: state.height,
        copyFromFrame: frame,
        order: frame.order,
      );
      newFrames.add(copiedFrame);
    }

    // If no frames were copied, create a default one
    if (newFrames.isEmpty) {
      final defaultFrame = await _frameService.createFrame(
        projectId: project.id,
        name: 'Frame 1',
        stateId: newState.id,
        width: state.width,
        height: state.height,
        order: 0,
      );
      newFrames.add(defaultFrame);
    }

    state = state.copyWith(
      animationStates: [...state.animationStates, newState],
      frames: [...state.frames, ...newFrames],
      currentAnimationStateIndex: state.animationStates.length,
      currentFrameIndex: 0,
      currentLayerIndex: 0,
    );

    _updateProject();
  }

  Future<void> removeAnimationState(int stateId) async {
    if (!_animationService.canDeleteState(state.animationStates)) return;

    final stateIndex =
        _animationService.findStateIndex(state.animationStates, stateId);
    if (stateIndex < 0) return;

    await _animationService.deleteAnimationState(stateId);

    final updatedStates = List<AnimationStateModel>.from(state.animationStates)
      ..removeAt(stateIndex);

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

    final updatedLayers = [...currentFrame.layers, newLayer]
      ..sort((a, b) => a.order.compareTo(b.order));

    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    state = state.copyWith(currentLayerIndex: updatedLayers.length - 1);

    _updateProject();
  }

  void selectAnimationState(int stateId) {
    final index =
        _animationService.findStateIndex(state.animationStates, stateId);
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
      currentFrameIndex: oldIndex == state.currentFrameIndex
          ? newIndex
          : state.currentFrameIndex,
    );

    _updateProject();
  }

  // Selection operations
  void setSelection(SelectionRegion? region) {
    if (region == null) {
      state = state.copyWith(selectionState: null);
      return;
    }
    // Use layer's anchor if available
    final layerAnchor = currentLayer.anchorPoint;
    state = state.copyWith(
      selectionState: SelectionState(
        region: region,
        anchorPoint: layerAnchor,
      ),
    );
  }

  void moveSelection(Offset delta) {
    final sel = state.selectionState;
    if (sel == null) return;

    final cached = _transformCachedPixels;
    final cachedLayer = _transformCachedLayerWithoutSelection;
    final cachedBounds = _transformCachedBounds;
    final cachedRegion = _transformCachedRegion;

    if (cached == null || cachedLayer == null || cachedBounds == null || cachedRegion == null) {
      // Fallback when transform was not explicitly started (e.g. external call)
      _saveState();
      final newPixels = _selectionService.moveSelectedPixels(
        region: sel.region,
        layerPixels: currentLayer.pixels,
        delta: delta,
      );
      _updateCurrentLayerPixels(newPixels);
      state = state.copyWith(
        selectionState: sel.copyWith(region: sel.region.shifted(delta)),
      );
      return;
    }

    // Accumulate total offset from the cached original position
    _totalMoveOffset += delta;

    // Re-apply from scratch: start with cleared layer, stamp pixels at new position
    final result = Uint32List.fromList(cachedLayer);
    final dx = _totalMoveOffset.dx.round();
    final dy = _totalMoveOffset.dy.round();
    final bw = cachedBounds.width.ceil();
    final bh = cachedBounds.height.ceil();
    final origLeft = cachedBounds.left.floor();
    final origTop = cachedBounds.top.floor();

    for (int ly = 0; ly < bh; ly++) {
      for (int lx = 0; lx < bw; lx++) {
        final srcIdx = ly * bw + lx;
        if (srcIdx >= cached.length || cached[srcIdx] == 0) continue;
        final nx = origLeft + lx + dx;
        final ny = origTop + ly + dy;
        if (nx >= 0 && nx < state.width && ny >= 0 && ny < state.height) {
          result[ny * state.width + nx] = cached[srcIdx];
        }
      }
    }

    final movedRegion = cachedRegion.shifted(_totalMoveOffset);
    _updateCurrentLayerPixels(result);
    state = state.copyWith(
      selectionState: sel.copyWith(region: movedRegion),
    );
  }

  void resizeSelectionNew(Rect targetBounds) {
    final sel = state.selectionState;
    if (sel == null) return;

    final cached = _transformCachedPixels;
    final cachedBounds = _transformCachedBounds;
    final cachedRegion = _transformCachedRegion;
    if (cached == null || cachedBounds == null || cachedRegion == null) return;

    final srcW = cachedBounds.width.ceil().clamp(1, state.width);
    final srcH = cachedBounds.height.ceil().clamp(1, state.height);

    final constrainedTargetBounds = Rect.fromLTRB(
      targetBounds.left.clamp(0.0, state.width.toDouble()),
      targetBounds.top.clamp(0.0, state.height.toDouble()),
      targetBounds.right.clamp(0.0, state.width.toDouble()),
      targetBounds.bottom.clamp(0.0, state.height.toDouble()),
    );
    if (constrainedTargetBounds.width <= 0 ||
        constrainedTargetBounds.height <= 0) {
      return;
    }

    final targetW = constrainedTargetBounds.width.round().clamp(1, state.width);
    final targetH =
        constrainedTargetBounds.height.round().clamp(1, state.height);

    final transformedPixels = PixelUtils.resize(
      cached,
      srcW,
      srcH,
      targetW,
      targetH,
      1,
      0,
    );

    // Clear original area and place resized pixels
    final clearedPixels = _selectionService.clearPixelsInSelection(
      cachedRegion,
      currentLayer.pixels,
      state.width,
      state.height,
    );

    final resultPixels = _placeTransformedPixels(
      clearedPixels,
      transformedPixels,
      constrainedTargetBounds,
      targetW,
      targetH,
    );

    // Create new selection region matching resized area
    final newRegion = _selectionService.createRectangleSelection(
      constrainedTargetBounds.left.floor(),
      constrainedTargetBounds.top.floor(),
      (constrainedTargetBounds.right - 1).floor(),
      (constrainedTargetBounds.bottom - 1).floor(),
    );

    _updateCurrentLayerPixels(resultPixels);
    state = state.copyWith(
      selectionState: sel.copyWith(
        region: newRegion,
        scale: Size(targetW / srcW, targetH / srcH),
      ),
    );
  }

  void rotateSelectionNew(double angle, {Offset? pivot}) {
    final sel = state.selectionState;
    if (sel == null) return;

    final cached = _transformCachedPixels;
    final cachedBounds = _transformCachedBounds;
    final cachedRegion = _transformCachedRegion;
    if (cached == null || cachedBounds == null || cachedRegion == null) return;

    // Use anchor point, or provided pivot, or center
    final rotCenter = sel.anchorPoint ?? pivot ?? cachedBounds.center;

    final srcW = cachedBounds.width.round().clamp(1, state.width);
    final srcH = cachedBounds.height.round().clamp(1, state.height);

    final rotatedBounds = _computeRotatedBounds(cachedBounds, rotCenter, angle);

    final rotatedPixels = PixelUtils.applyRotationWithBounds(
      cached,
      srcW,
      srcH,
      angle,
      cachedBounds,
      rotatedBounds,
      rotCenter,
      1,
      0,
    );
    if (rotatedPixels.isEmpty) return;

    final clearedPixels = _selectionService.clearPixelsInSelection(
      cachedRegion,
      currentLayer.pixels,
      state.width,
      state.height,
    );

    final constrainedDest = Rect.fromLTRB(
      rotatedBounds.left.clamp(0.0, state.width.toDouble()),
      rotatedBounds.top.clamp(0.0, state.height.toDouble()),
      rotatedBounds.right.clamp(1.0, state.width.toDouble()),
      rotatedBounds.bottom.clamp(1.0, state.height.toDouble()),
    );

    final targetW = rotatedBounds.width.round().clamp(1, state.width);
    final targetH = rotatedBounds.height.round().clamp(1, state.height);

    final resultPixels = _placeTransformedPixels(
      clearedPixels,
      rotatedPixels,
      constrainedDest,
      targetW,
      targetH,
    );

    // Create new region from rotated bounds
    final newRegion = _selectionService.createRectangleSelection(
      constrainedDest.left.floor(),
      constrainedDest.top.floor(),
      (constrainedDest.right - 1).floor(),
      (constrainedDest.bottom - 1).floor(),
    );

    _updateCurrentLayerPixels(resultPixels);
    state = state.copyWith(
      selectionState: sel.copyWith(
        region: newRegion,
        rotation: angle,
      ),
    );
  }

  void setAnchorPoint(Offset anchor) {
    final sel = state.selectionState;
    if (sel == null) return;

    // Update selection state
    state = state.copyWith(
      selectionState: sel.copyWith(anchorPoint: () => anchor),
    );

    // Persist to layer
    _updateCurrentLayer(currentLayer.copyWith(anchorPoint: () => anchor));
  }

  void autoSelectLayer() {
    if (currentLayer.pixels.isEmpty) return;

    final region = _selectionService.createAutoSelection(
      pixels: currentLayer.pixels,
      w: state.width,
      h: state.height,
    );

    if (region.bounds == Rect.zero) return;

    setSelection(region);
  }

  void selectAll() {
    final region = _selectionService.selectAll();
    setSelection(region);
  }

  void invertSelectionRegion() {
    final sel = state.selectionState;
    if (sel == null) return;

    final inverted = _selectionService.invertSelection(sel.region);
    setSelection(inverted);
  }

  void flipSelectionPixels({required bool horizontal}) {
    final sel = state.selectionState;
    if (sel == null) return;

    _saveState();
    final newPixels = _selectionService.flipSelectedPixels(
      region: sel.region,
      layerPixels: currentLayer.pixels,
      horizontal: horizontal,
    );
    _updateCurrentLayerPixels(newPixels);
  }

  void clearSelection() {
    state = state.copyWith(selectionState: null);
  }

  // Undo/Redo operations
  void undo() {
    final previousState = _undoRedoService.undo(state);
    if (previousState != null) {
      state = previousState;
      _updateProject();
    }
  }

  void redo() {
    final nextState = _undoRedoService.redo(state);
    if (nextState != null) {
      state = nextState;
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
    final frames =
        includeAllFrames ? state.currentFrames : [state.currentFrame];

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
    final imageBytes =
        await _importExportService.importImageAsBackground(context: context);
    if (imageBytes != null) {
      ref
          .read(backgroundImageProvider.notifier)
          .update((state) => state.copyWith(image: imageBytes));

      // Extract dominant colors and publish to palette panel
      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded != null) {
        final palette =
            PixelArtConverter.extractPaletteFromImage(decoded, maxColors: 32);
        ref.read(importedPaletteProvider.notifier).set(palette);
      }
    }
  }

  Future<void> importImageAsLayer(
    BuildContext context, {
    PixelArtConversionOptions options = const PixelArtConversionOptions(),
  }) async {
    final newLayer = await _importExportService.importImageAsLayer(
      context: context,
      width: state.width,
      height: state.height,
      layerName: 'Imported Image',
      options: options,
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

      // Extract unique colors from the converted pixels and publish to palette panel
      final palette = PixelArtConverter.extractPaletteFromPixels(
        newLayer.pixels,
        maxColors: 64,
      );
      ref.read(importedPaletteProvider.notifier).set(palette);
    }
  }

  // Helper methods
  Color _getDrawingColor() {
    return state.currentTool == PixelTool.eraser
        ? Colors.transparent
        : state.currentColor;
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

  /// MARK: Selection Resizing & Rotation (legacy wrappers kept for overlay compatibility)

  void resizeSelection(SelectionRegion region, SelectionRegion oldRegion,
      Rect b, Offset? center) {
    resizeSelectionNew(region.bounds);
  }

  void rotateSelection(SelectionRegion region, SelectionRegion oldRegion,
      double angle, Offset? center) {
    rotateSelectionNew(angle, pivot: center);
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

          if (destX >= 0 &&
              destX < state.width &&
              destY >= 0 &&
              destY < state.height) {
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

  void _updateCurrentLayer(Layer layer) {
    final updatedLayers = List<Layer>.from(currentFrame.layers);
    updatedLayers[state.currentLayerIndex] = layer;
    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);

    final frameIndex = state.frames.indexWhere((f) => f.id == currentFrame.id);
    final updatedFrames = List<AnimationFrame>.from(state.frames);
    updatedFrames[frameIndex] = updatedFrame;

    state = state.copyWith(frames: updatedFrames);
  }
}
