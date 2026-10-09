import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:image/image.dart' as img;

import '../../core.dart';
import '../../core/services/error_report_service.dart';
import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../../data/models/template.dart';
import '../pixel_point.dart';
import '../../data.dart';
import '../../providers/providers.dart';
import '../../providers/background_image_provider.dart';
import '../../providers/editor_settings_provider.dart';
import '../../providers/editor_workspace_provider.dart';
import '../../providers/imported_palette_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/project_upload_provider.dart';
import '../../data/models/progression_model.dart';
import '../effects/effects.dart';
import '../services/animation_service.dart';
import '../services/clipboard_placement_service.dart';
import '../services/drawing_service.dart';
import '../services/editor_selection_service.dart';
import '../services/effect_stack_service.dart';
import '../services/frame_service.dart';
import '../services/import_export_service.dart';
import '../services/layer_service.dart';
import '../services/pixel_transform_service.dart';
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

  // Debounce timer for cloud auto-sync (30s after last save)
  Timer? _cloudSyncTimer;

  // Debounced local project save: strokes only schedule a save; the latest
  // pending snapshot is written after [_localSaveDebounce] or on flush.
  static const _localSaveDebounce = Duration(seconds: 2);
  Timer? _projectSaveTimer;
  Project? _pendingProjectSave;
  Future<bool>? _projectSaveInFlight;
  int _projectSaveGeneration = 0;
  AppLifecycleListener? _lifecycleListener;
  late final ProjectRepo _projectRepo;

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
    _projectRepo = ref.read(projectRepo);

    // Flush the pending save when the app is backgrounded or closing so the
    // debounce window can't drop the last edits.
    _lifecycleListener = AppLifecycleListener(
      onPause: () => unawaited(flushPendingProjectSave()),
      onDetach: () => unawaited(flushPendingProjectSave()),
    );

    ref.onDispose(() {
      _cloudSyncTimer?.cancel();
      _lifecycleListener?.dispose();
      unawaited(flushPendingProjectSave());
    });

    final animationStates = project.states.isNotEmpty
        ? List<AnimationStateModel>.from(project.states)
        : [const AnimationStateModel(id: 0, name: 'Default', frameRate: 12)];
    final frames = project.frames.isNotEmpty
        ? List<AnimationFrame>.from(project.frames)
        : _createDefaultFrame();
    final restoredSelection = restoreEditorSelection(
      project,
      animationStates,
      frames,
    );

    return PixelCanvasState(
      width: project.width,
      height: project.height,
      animationStates: animationStates,
      frames: frames,
      currentAnimationStateIndex: restoredSelection.stateIndex,
      currentFrameIndex: restoredSelection.frameIndex,
      currentLayerIndex: restoredSelection.layerIndex,
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
  bool get currentLayerIsProcedural =>
      EffectStackService.isProcedural(currentLayer);
  bool get canUndo => _undoRedoService.canUndo;
  bool get canRedo => _undoRedoService.canRedo;
  int get undoStackSize => _undoRedoService.undoStackSize;
  int get redoStackSize => _undoRedoService.redoStackSize;
  List<String> get undoStackSummary => _undoRedoService.getUndoStackSummary();
  List<String> get redoStackSummary => _undoRedoService.getRedoStackSummary();

  // State management
  void _saveState() {
    _undoRedoService.saveState(state);
    state = state.copyWith(canUndo: canUndo, canRedo: canRedo);
  }

  // Pending pixel-op undo capture: pre-op state and the current layer's
  // pre-op buffer. Consumed by _updateCurrentLayerPixels, which records a
  // compact pixel diff instead of retaining a full snapshot. Only set by
  // single-commit, pixel-only operations.
  PixelCanvasState? _pendingUndoPreState;
  Uint32List? _pendingUndoPrePixels;

  void _beginPixelUndo() {
    _pendingUndoPreState = state;
    _pendingUndoPrePixels = currentLayer.pixels;
  }

  void _clearPendingPixelUndo() {
    _pendingUndoPreState = null;
    _pendingUndoPrePixels = null;
  }

  void _updateProject() {
    final updated = project.copyWith(
      frames: state.frames,
      states: state.animationStates,
      selectedFrameId: currentFrame.id,
      selectedLayerId: currentLayer.layerId,
      editedAt: DateTime.now(),
    );
    _pendingProjectSave = updated;
    _projectSaveGeneration += 1;
    ref
        .read(editorWorkspaceProvider.notifier)
        .setUnsavedChanges(project.id, true);
    _projectSaveTimer?.cancel();
    _projectSaveTimer = Timer(
      _localSaveDebounce,
      () => unawaited(flushPendingProjectSave()),
    );
    _scheduleCloudSync(updated);
  }

  void _persistEditorSelection() {
    if (currentFrame.layers.isEmpty) return;
    final frameId = currentFrame.id;
    final layerId = currentLayer.layerId;
    final pendingSave = _pendingProjectSave;
    if (pendingSave != null) {
      _pendingProjectSave = pendingSave.copyWith(
        selectedFrameId: frameId,
        selectedLayerId: layerId,
      );
    }
    unawaited(_projectRepo.updateProjectSelection(
      project.id,
      frameId: frameId,
      layerId: layerId,
    ));
  }

  /// Writes the most recent pending project snapshot immediately.
  Future<bool> flushPendingProjectSave() {
    _projectSaveTimer?.cancel();
    _projectSaveTimer = null;
    final pending = _pendingProjectSave;
    if (pending == null) {
      return _projectSaveInFlight ?? Future.value(true);
    }
    _pendingProjectSave = null;
    final generation = _projectSaveGeneration;
    final previousSave = _projectSaveInFlight;
    final save = () async {
      if (previousSave != null) await previousSave;
      return _persistProject(pending, generation);
    }();
    _projectSaveInFlight = save;
    unawaited(save.whenComplete(() {
      if (identical(_projectSaveInFlight, save)) {
        _projectSaveInFlight = null;
      }
    }));
    return save;
  }

  Future<bool> _persistProject(Project pending, int generation) async {
    final workspace = ref.read(editorWorkspaceProvider.notifier);
    try {
      await _projectRepo.updateProject(pending);
      if (_pendingProjectSave == null && generation == _projectSaveGeneration) {
        workspace.setUnsavedChanges(project.id, false);
      }
      return true;
    } catch (error, stack) {
      ErrorReportService.instance
          .report(error, stack, operation: 'editor.saveProject');
      workspace.setUnsavedChanges(project.id, true);
      return false;
    }
  }

  void _scheduleCloudSync(Project updated) {
    if (!updated.isCloudSynced || updated.remoteId == null) return;
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer(const Duration(seconds: 30), () {
      ref.read(projectUploadProvider.notifier).silentSyncProject(
            localProject: updated,
          );
    });
  }

  // MARK: Batch Drawing Methods

  bool startBatchDrawing() {
    if (currentLayerIsProcedural) return false;
    _isBatching = true;
    _beginPixelUndo();
    _activeBuffer = Uint32List.fromList(currentLayer.pixels);
    return true;
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
      erase: state.currentTool == PixelTool.eraser,
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
      erase: state.currentTool == PixelTool.eraser,
    );
  }

  void endBatchDrawing() {
    if (_activeBuffer != null) {
      _updateCurrentLayerPixels(_activeBuffer!);
      _activeBuffer = null;
      _recordProgress(ProgressionEvent.strokeCompleted);
    }
    _isBatching = false;
  }

  /// Cancels an in-progress batch drawing without committing the buffer.
  /// The undo capture from [startBatchDrawing] is discarded — nothing was
  /// pushed to the undo stack yet (diffs are recorded at commit time).
  void cancelBatchDrawing() {
    if (!_isBatching) return;
    _activeBuffer = null;
    _isBatching = false;
    _clearPendingPixelUndo();
    state = state.copyWith(canUndo: canUndo, canRedo: canRedo);
  }

  // MARK: Drawing Operations

  // Drawing operations
  void setPixel(int x, int y) {
    _beginPixelUndo();

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
      erase: state.currentTool == PixelTool.eraser,
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
    _beginPixelUndo();

    final newPixels = _drawingService.fillPixels(
      pixels: currentLayer.pixels,
      points: points,
      width: state.width,
      color: _getDrawingColor(),
      selection: state.selectionState?.region,
      erase: state.currentTool == PixelTool.eraser,
    );

    _updateCurrentLayerPixels(newPixels);
    // Shape tools (line, rectangle, circle, ...) commit through here.
    _recordProgress(ProgressionEvent.shapeDrawn);
  }

  void floodFill(int x, int y) {
    _beginPixelUndo();

    final newPixels = _drawingService.floodFill(
      pixels: currentLayer.pixels,
      x: x,
      y: y,
      width: state.width,
      height: state.height,
      fillColor: _getDrawingColor(),
      selection: state.selectionState?.region,
      erase: state.currentTool == PixelTool.eraser,
    );

    _updateCurrentLayerPixels(newPixels);
    _recordProgress(ProgressionEvent.strokeCompleted);
    _recordProgress(ProgressionEvent.fillUsed);
  }

  void clearCanvas() {
    _beginPixelUndo();

    final newPixels = _drawingService.clearPixels(state.width, state.height);
    _updateCurrentLayerPixels(newPixels);
  }

  /// Draws imported [source] pixels onto the current layer. Transparent
  /// source pixels leave the existing content untouched.
  void importPixelsToCurrentLayer(Uint32List source) {
    final current = currentLayer.pixels;
    if (source.length != current.length) return;

    _beginPixelUndo();

    final merged = Uint32List.fromList(current);
    for (var i = 0; i < merged.length; i++) {
      if ((source[i] >> 24) != 0) merged[i] = source[i];
    }
    _updateCurrentLayerPixels(merged);
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

  void applyGradientFromPoints(Offset startPx, Offset endPx, Color endColor) {
    _beginPixelUndo();
    final colors = _drawingService.computeLinearGradientColors(
      width: state.width,
      height: state.height,
      startPx: startPx,
      endPx: endPx,
      startColor: state.currentColor,
      endColor: endColor,
      selectionRegion: state.selectionState?.region,
    );
    final newPixels = _drawingService.applyGradient(
      pixels: currentLayer.pixels,
      gradientColors: colors,
    );
    _updateCurrentLayerPixels(newPixels);
  }

  void applyGradient(List<Color> gradientColors) {
    _beginPixelUndo();

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
    if (currentLayerIsProcedural) return;
    _saveState();
    _dragStartOffset = null;
    _originalPixels = null;
  }

  void dragPixels(Offset offset) {
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
    _beginPixelUndo();
    final clearedPixels = _selectionService.clearPixelsInSelection(
      sel,
      currentLayer.pixels,
      state.width,
      state.height,
    );
    _updateCurrentLayerPixels(clearedPixels);
  }

  /// Returns a pixel buffer containing only the selected pixels (canvas-sized).
  /// Returns null if there is no active selection.
  Uint32List? copySelectionPixels() {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return null;
    return _selectionService.copySelectedPixels(sel, currentLayer.pixels);
  }

  /// Clears the selected pixels from the current layer and returns their data.
  Uint32List? cutSelectionPixels() {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return null;
    _beginPixelUndo();
    final copied =
        _selectionService.copySelectedPixels(sel, currentLayer.pixels);
    final cleared = _selectionService.clearPixelsInSelection(
      sel,
      currentLayer.pixels,
      state.width,
      state.height,
    );
    _updateCurrentLayerPixels(cleared);
    return copied;
  }

  /// Pastes [pixels] as a floating new layer and selects it.
  Future<void> pastePixels(
    Uint32List pixels,
    SelectionRegion region, {
    required int sourceWidth,
    required int sourceHeight,
  }) async {
    final layerId = const Uuid().v4();
    final placement = placeClipboardPixels(
      source: pixels,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      targetWidth: state.width,
      targetHeight: state.height,
    );
    final newLayer = Layer(
      layerId: 0,
      id: layerId,
      name: 'Pasted',
      pixels: placement.pixels,
      isVisible: true,
      order: state.currentFrame.layers.length,
    );
    await addLayerWithPixels(newLayer);
    selectLayer(state.currentFrame.layers.length - 1);
    setSelection(region.shifted(placement.offset));
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
  Uint32List?
      _transformCachedLayerWithoutSelection; // layer pixels with selection cleared
  Rect? _transformCachedBounds;
  SelectionRegion? _transformCachedRegion;
  Offset? _transformCachedAnchor;
  Offset _totalMoveOffset = Offset.zero;
  bool _transformPreviewDirty = false;

  void startTransformSelection(SelectionRegion region) {
    if (currentLayer.pixels.isEmpty) return;

    final bounds = region.bounds;
    if (bounds.width <= 0 || bounds.height <= 0) return;

    _saveState();
    _transformCachedRegion = region;
    _transformCachedAnchor =
        state.selectionState?.effectiveAnchor ?? region.bounds.center;

    final cachedSelectionPixels = state.selectionState?.capturedPixels;
    final cachedSelectionBounds = state.selectionState?.capturedBounds;

    if (_transformCachedLayerWithoutSelection == null ||
        cachedSelectionPixels == null ||
        cachedSelectionBounds == null) {
      final capture = _captureOpaqueSelection(region, currentLayer.pixels);
      _transformCachedPixels = capture.selectionPixels;
      _transformCachedBounds = capture.bounds;
      _transformCachedLayerWithoutSelection = capture.basePixels;
    } else {
      _transformCachedPixels = Uint32List.fromList(cachedSelectionPixels);
      _transformCachedBounds = cachedSelectionBounds;
    }
    _totalMoveOffset = Offset.zero;
    _transformPreviewDirty = false;

    // Enter transform mode in selection state
    state = state.copyWith(
      selectionState: state.selectionState?.copyWith(
        isTransforming: true,
        capturedPixels: () => Uint32List.fromList(_transformCachedPixels!),
        capturedBounds: () => _transformCachedBounds,
      ),
    );
  }

  void endTransformSelection() {
    if (_transformPreviewDirty) {
      // Keep the layer's serialized anchor in sync with where the selection
      // (and its anchor) ended up — otherwise it goes stale after any move.
      final anchor = state.selectionState?.anchorPoint;
      if (anchor != null && currentLayer.anchorPoint != anchor) {
        _updateCurrentLayer(currentLayer.copyWith(anchorPoint: () => anchor));
      }
      _persistCurrentLayer();
    }

    _totalMoveOffset = Offset.zero;
    _transformPreviewDirty = false;

    if (state.selectionState != null) {
      state = state.copyWith(
        selectionState: state.selectionState!.copyWith(
          isTransforming: false,
        ),
      );
    }
  }

  /// Ends any in-progress transform and drops the transform caches before
  /// the current layer or frame changes. The cached "layer without
  /// selection" and captured pixels alias the OLD layer — reusing them after
  /// a switch would stamp the old layer's content onto the new one. The
  /// selection region and anchor survive (standard editor behavior); the
  /// next transform recaptures from the new layer.
  void _detachSelectionFromLayer() {
    if (state.selectionState?.isTransforming == true) {
      endTransformSelection();
    }
    _resetSelectionTransformCache();
    final sel = state.selectionState;
    if (sel != null &&
        (sel.capturedPixels != null || sel.capturedBounds != null)) {
      state = state.copyWith(
        selectionState: sel.copyWith(
          capturedPixels: () => null,
          capturedBounds: () => null,
        ),
      );
    }
  }

  /// Inserts [layer] directly above the selected layer, renumbers `order` to
  /// match list positions, and selects it.
  void _insertLayerAboveCurrent(Layer layer) {
    final layers = List<Layer>.from(currentFrame.layers);
    final insertIndex = (state.currentLayerIndex + 1).clamp(0, layers.length);
    layers.insert(insertIndex, layer);

    final ordered = [
      for (final (index, l) in layers.indexed) l.copyWith(order: index),
    ];
    _updateCurrentFrame(currentFrame.copyWith(layers: ordered));
    state = state.copyWith(currentLayerIndex: insertIndex);
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

    _insertLayerAboveCurrent(newLayer);
    _updateProject();
    _recordProgress(ProgressionEvent.layerAdded);
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

    _insertLayerAboveCurrent(layerWithPixels);
    _updateProject();
  }

  List<Layer> copyLayers(Iterable<int> indices) {
    final valid = indices
        .where((index) => index >= 0 && index < currentFrame.layers.length)
        .toSet()
        .toList()
      ..sort();

    return [
      for (final index in valid)
        Layer.fromJson(currentFrame.layers[index].toJson()),
    ];
  }

  Future<void> pasteLayers(
    List<Layer> sourceLayers, {
    required int sourceWidth,
    required int sourceHeight,
  }) async {
    if (sourceLayers.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();

    var layers = List<Layer>.from(currentFrame.layers);
    var insertIndex = state.currentLayerIndex + 1;
    String? lastCreatedId;

    for (final source in sourceLayers) {
      final created = await _layerService.createLayer(
        projectId: project.id,
        frameId: currentFrame.id,
        name: source.name,
        width: state.width,
        height: state.height,
        order: layers.length,
      );
      final placement = placeClipboardPixels(
        source: source.pixels,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        targetWidth: state.width,
        targetHeight: state.height,
      );
      final cloned = Layer.fromJson(source.toJson());
      final pasted = created.copyWith(
        pixels: placement.pixels,
        effects: cloned.effects,
        isVisible: source.isVisible,
        isLocked: source.isLocked,
        opacity: source.opacity,
        anchorPoint: () => source.anchorPoint == null
            ? null
            : source.anchorPoint! + placement.offset,
      );
      layers.insert(insertIndex, pasted);
      insertIndex += 1;
      lastCreatedId = pasted.id;
    }

    layers = [
      for (final (index, layer) in layers.indexed) layer.copyWith(order: index),
    ];
    _updateCurrentFrame(currentFrame.copyWith(layers: layers));
    state = state.copyWith(
      currentLayerIndex:
          layers.indexWhere((layer) => layer.id == lastCreatedId),
    );
    _updateProject();
  }

  Future<void> removeLayer(int index) async {
    await removeLayers([index]);
  }

  Future<void> removeLayers(Iterable<int> indices) async {
    final layers = currentFrame.layers;
    if (layers.length <= 1) return;
    final requested = indices.where((i) => i >= 0 && i < layers.length).toSet();
    if (requested.isEmpty) return;

    // A frame must always retain one layer. When all are selected, keep the
    // active layer; it remains the single active item after the operation.
    if (requested.length == layers.length) {
      requested.remove(state.currentLayerIndex.clamp(0, layers.length - 1));
    }
    if (requested.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();
    final activeLayerId = currentLayer.id;
    await Future.wait(
        requested.map((i) => _layerService.deleteLayer(layers[i].layerId)));

    final remaining = <Layer>[
      for (final (index, layer) in layers.indexed)
        if (!requested.contains(index)) layer,
    ];
    final reordered = [
      for (final (index, layer) in remaining.indexed)
        layer.copyWith(order: index),
    ];
    _updateCurrentFrame(currentFrame.copyWith(layers: reordered));

    var activeIndex =
        reordered.indexWhere((layer) => layer.id == activeLayerId);
    if (activeIndex < 0) {
      activeIndex = requested
          .reduce((a, b) => a < b ? a : b)
          .clamp(0, reordered.length - 1);
    }
    state = state.copyWith(currentLayerIndex: activeIndex);
    _updateProject();
  }

  Future<int> duplicateLayer(int index) async {
    _detachSelectionFromLayer();
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

  Future<void> duplicateLayers(Iterable<int> indices) async {
    final sourceIds = indices
        .where((i) => i >= 0 && i < currentFrame.layers.length)
        .toSet()
        .toList()
      ..sort();
    if (sourceIds.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();
    final originalIds = [
      for (final index in sourceIds) currentFrame.layers[index].id
    ];
    var layers = List<Layer>.from(currentFrame.layers);
    String? lastCreatedId;

    for (final sourceId in originalIds) {
      final sourceIndex = layers.indexWhere((layer) => layer.id == sourceId);
      final source = layers[sourceIndex];
      final created = await _layerService.createLayer(
        projectId: project.id,
        frameId: currentFrame.id,
        name: 'Copy of ${source.name}',
        width: state.width,
        height: state.height,
        order: layers.length,
      );
      final copy = created.copyWith(
        pixels: Uint32List.fromList(source.pixels),
        effects: List.of(source.effects),
        isVisible: source.isVisible,
        isLocked: source.isLocked,
        opacity: source.opacity,
        anchorPoint: () => source.anchorPoint,
      );
      layers.insert(sourceIndex + 1, copy);
      lastCreatedId = copy.id;
    }

    layers = [
      for (final (index, layer) in layers.indexed) layer.copyWith(order: index)
    ];
    _updateCurrentFrame(currentFrame.copyWith(layers: layers));
    state = state.copyWith(
      currentLayerIndex:
          layers.indexWhere((layer) => layer.id == lastCreatedId),
    );
    _updateProject();
  }

  Future<void> setLayersVisibility(Iterable<int> indices, bool visible) =>
      _updateLayers(indices, (layer) => layer.copyWith(isVisible: visible));

  Future<void> setLayersLocked(Iterable<int> indices, bool locked) =>
      _updateLayers(indices, (layer) => layer.copyWith(isLocked: locked));

  Future<void> setLayersOpacity(Iterable<int> indices, double opacity) =>
      _updateLayers(
          indices, (layer) => layer.copyWith(opacity: opacity.clamp(0.0, 1.0)));

  Future<void> _updateLayers(
    Iterable<int> indices,
    Layer Function(Layer layer) transform,
  ) async {
    final valid =
        indices.where((i) => i >= 0 && i < currentFrame.layers.length).toSet();
    if (valid.isEmpty) return;
    _saveState();
    final updated = List<Layer>.from(currentFrame.layers);
    for (final index in valid) {
      updated[index] = transform(updated[index]);
    }
    _updateCurrentFrame(currentFrame.copyWith(layers: updated));
    await Future.wait(valid.map((index) => _layerService.updateLayer(
          projectId: project.id,
          frameId: currentFrame.id,
          layer: updated[index],
        )));
    _updateProject();
  }

  void selectLayer(int index) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    if (index == state.currentLayerIndex) return;
    _detachSelectionFromLayer();
    state = state.copyWith(currentLayerIndex: index);
    _persistEditorSelection();
  }

  Future<void> toggleLayerVisibility(int index) async {
    final layer = currentFrame.layers[index];
    final updatedLayer = _layerService.toggleLayerVisibility(layer);

    await _updateLayerAndFrame(index, updatedLayer);
  }

  Future<void> reorderLayers(int oldIndex, int newIndex) async {
    _detachSelectionFromLayer();
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

  void applyEffectToLayer(Effect effect) {
    _saveState();
    final sourceLayer = currentLayer;
    final region = state.selectionState?.region;
    final processedPixels = region == null
        ? effect.apply(
            sourceLayer.pixels,
            state.width,
            state.height,
          )
        : EffectsManager.applyMultipleEffectsToSelection(
            sourceLayer.pixels,
            state.width,
            state.height,
            [effect],
            region,
          );
    final updatedLayer = sourceLayer.copyWith(pixels: processedPixels);
    updateLayer(updatedLayer);
  }

  bool convertCurrentLayerToPixels({List<Effect>? effects}) {
    final sourceLayer = effects == null
        ? currentLayer
        : currentLayer.copyWith(effects: List<Effect>.from(effects));
    if (!EffectStackService.isProcedural(sourceLayer)) return false;

    _saveState();
    final converted = EffectStackService.convertToPixels(
      sourceLayer,
      width: state.width,
      height: state.height,
    );
    updateLayer(converted);
    return true;
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
      currentLayerIndex: _safeLayerIndex(newFrame),
    );
    _persistEditorSelection();
    _recordProgress(ProgressionEvent.frameAdded);
  }

  /// Append generated animation frames to the source frame's animation state.
  /// Generated frames contain the rendered target layer; the remaining layers
  /// are copied from the source frame so the timeline keeps its composition.
  Future<void> addGeneratedEffectFrames(
    List<AnimationFrame> generatedFrames, {
    required int sourceFrameId,
    required int sourceLayerId,
  }) async {
    if (generatedFrames.isEmpty) return;
    final sourceIndex =
        state.frames.indexWhere((frame) => frame.id == sourceFrameId);
    if (sourceIndex < 0) throw StateError('Source frame no longer exists');
    final source = state.frames[sourceIndex];
    final layerIndex =
        source.layers.indexWhere((layer) => layer.layerId == sourceLayerId);
    if (layerIndex < 0) throw StateError('Source layer no longer exists');
    final stateIndex =
        state.animationStates.indexWhere((item) => item.id == source.stateId);
    if (stateIndex < 0) throw StateError('Animation state no longer exists');
    for (final generated in generatedFrames) {
      if (generated.layers.length != 1 ||
          generated.layers.single.pixels.length != state.width * state.height) {
        throw ArgumentError('Generated frame has invalid pixels');
      }
    }

    final firstGeneratedIndex =
        state.frames.where((frame) => frame.stateId == source.stateId).length;
    var nextOrder = _frameService.calculateNextFrameOrder(state.frames);
    for (final generated in generatedFrames) {
      final renderedPixels = generated.layers.single.pixels;
      final layers = <Layer>[
        for (final (index, layer) in source.layers.indexed)
          layer.copyWith(
            id: const Uuid().v4(),
            layerId: 0,
            pixels: index == layerIndex
                ? Uint32List.fromList(renderedPixels)
                : Uint32List.fromList(layer.pixels),
            effects: index == layerIndex ? const [] : layer.effects,
          ),
      ];
      final frame = AnimationFrame(
        id: 0,
        stateId: source.stateId,
        name: generated.name,
        duration: generated.duration,
        order: nextOrder++,
        layers: layers,
      );
      final created = await _projectRepo.createFrame(project.id, frame);
      state = state.copyWith(frames: [...state.frames, created]);
    }
    state = state.copyWith(
      currentAnimationStateIndex: stateIndex,
      currentFrameIndex: firstGeneratedIndex,
      currentLayerIndex: layerIndex,
    );
    _updateProject();
    _recordProgress(ProgressionEvent.animationGenerated);
  }

  Future<void> removeFrame(int index) async {
    final current = state.currentFrames;
    if (index < 0 || index >= current.length) return;
    await removeFramesByIds({current[index].id});
  }

  Future<void> removeFramesByIds(Set<int> frameIds) async {
    if (frameIds.isEmpty) return;
    final removable = <int>{};
    for (final animationState in state.animationStates) {
      final stateFrames =
          state.frames.where((f) => f.stateId == animationState.id).toList();
      final selected = stateFrames
          .where((f) => frameIds.contains(f.id))
          .map((f) => f.id)
          .toSet();
      if (selected.length == stateFrames.length && stateFrames.isNotEmpty) {
        final keepId = animationState.id == state.currentAnimationState.id
            ? currentFrame.id
            : stateFrames.first.id;
        selected.remove(keepId);
      }
      removable.addAll(selected);
    }
    if (removable.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();
    final oldCurrentFrames = state.currentFrames;
    final oldActiveId = currentFrame.id;
    final firstRemovedIndex =
        oldCurrentFrames.indexWhere((f) => removable.contains(f.id));
    await Future.wait(removable.map(_frameService.deleteFrame));
    final updatedFrames =
        state.frames.where((f) => !removable.contains(f.id)).toList();
    final newCurrentFrames = updatedFrames
        .where((f) => f.stateId == state.currentAnimationState.id)
        .toList();
    var activeIndex = newCurrentFrames.indexWhere((f) => f.id == oldActiveId);
    if (activeIndex < 0) {
      activeIndex = firstRemovedIndex.clamp(0, newCurrentFrames.length - 1);
    }
    state = state.copyWith(
      frames: updatedFrames,
      currentFrameIndex: activeIndex,
      currentLayerIndex: _safeLayerIndex(newCurrentFrames[activeIndex]),
    );
    _updateProject();
  }

  Future<void> duplicateFramesByIds(Iterable<int> frameIds) async {
    final ids = frameIds.toSet();
    final sources =
        state.frames.where((frame) => ids.contains(frame.id)).toList();
    if (sources.isEmpty) return;
    _saveState();
    final createdFrames = <AnimationFrame>[];
    for (final source in sources) {
      var created = await _frameService.createFrame(
        projectId: project.id,
        name: 'Copy of ${source.name}',
        stateId: source.stateId,
        width: state.width,
        height: state.height,
        copyFromFrame: source,
        order: _frameService
            .calculateNextFrameOrder([...state.frames, ...createdFrames]),
      );
      created = created.copyWith(duration: source.duration);
      await _frameService.updateFrame(projectId: project.id, frame: created);
      createdFrames.add(created);
    }
    state = state.copyWith(frames: [...state.frames, ...createdFrames]);
    _updateProject();
  }

  Future<void> updateFramesDurationByIds(
      Iterable<int> frameIds, int duration) async {
    final ids = frameIds.toSet();
    final updated = [
      for (final frame in state.frames)
        if (ids.contains(frame.id))
          frame.copyWith(duration: duration)
        else
          frame,
    ];
    await Future.wait(updated.where((frame) => ids.contains(frame.id)).map(
        (frame) =>
            _frameService.updateFrame(projectId: project.id, frame: frame)));
    state = state.copyWith(frames: updated);
    _updateProject();
  }

  Future<void> reorderFramesByIds(Set<int> draggedIds, int targetId) async {
    final targetIndexInAll =
        state.frames.indexWhere((frame) => frame.id == targetId);
    if (targetIndexInAll < 0) return;
    final target = state.frames[targetIndexInAll];
    final stateFrames =
        state.frames.where((f) => f.stateId == target.stateId).toList();
    final dragged =
        stateFrames.where((f) => draggedIds.contains(f.id)).toList();
    if (dragged.isEmpty || draggedIds.contains(targetId)) return;
    final oldActiveId = currentFrame.id;
    final targetIndex = stateFrames.indexWhere((f) => f.id == targetId);
    final firstDraggedIndex =
        stateFrames.indexWhere((f) => draggedIds.contains(f.id));
    final remaining =
        stateFrames.where((f) => !draggedIds.contains(f.id)).toList();
    var insertIndex = remaining.indexWhere((f) => f.id == targetId);
    if (firstDraggedIndex < targetIndex) insertIndex++;
    remaining.insertAll(insertIndex, dragged);
    final reordered = [
      for (final (index, frame) in remaining.indexed)
        frame.copyWith(order: index),
    ];
    var cursor = 0;
    final allFrames = [
      for (final frame in state.frames)
        if (frame.stateId == target.stateId) reordered[cursor++] else frame,
    ];
    final currentStateFrames = allFrames
        .where((f) => f.stateId == state.currentAnimationState.id)
        .toList();
    state = state.copyWith(
      frames: allFrames,
      currentFrameIndex:
          currentStateFrames.indexWhere((f) => f.id == oldActiveId),
    );
    _updateProject();
  }

  void selectFrame(int frameId) {
    final index =
        state.currentFrames.indexWhere((frame) => frame.id == frameId);
    if (index >= 0) {
      _detachSelectionFromLayer();
      final targetFrame = state.currentFrames[index];
      state = state.copyWith(
        currentFrameIndex: index,
        currentLayerIndex: _safeLayerIndex(targetFrame),
      );
      _persistEditorSelection();
    }
  }

  void nextFrame() {
    final nextIndex =
        (state.currentFrameIndex + 1) % state.currentFrames.length;
    _detachSelectionFromLayer();
    final targetFrame = state.currentFrames[nextIndex];
    state = state.copyWith(
      currentFrameIndex: nextIndex,
      currentLayerIndex: _safeLayerIndex(targetFrame),
    );
    _persistEditorSelection();
  }

  void previousFrame() {
    final prevIndex =
        (state.currentFrameIndex - 1 + state.currentFrames.length) %
            state.currentFrames.length;
    _detachSelectionFromLayer();
    final targetFrame = state.currentFrames[prevIndex];
    state = state.copyWith(
      currentFrameIndex: prevIndex,
      currentLayerIndex: _safeLayerIndex(targetFrame),
    );
    _persistEditorSelection();
  }

  int _safeLayerIndex(AnimationFrame frame) {
    if (frame.layers.isEmpty) return 0;
    return state.currentLayerIndex.clamp(0, frame.layers.length - 1);
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
    _persistEditorSelection();
    _recordProgress(ProgressionEvent.animationStateAdded);
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
    _persistEditorSelection();
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

    _insertLayerAboveCurrent(newLayer);

    _updateProject();
    _recordProgress(ProgressionEvent.templateUsed);
  }

  void selectAnimationState(int stateId) {
    final index =
        _animationService.findStateIndex(state.animationStates, stateId);
    if (index >= 0) {
      final targetFrames =
          state.frames.where((frame) => frame.stateId == stateId).toList();
      final layerIndex =
          targetFrames.isEmpty ? 0 : _safeLayerIndex(targetFrames.first);
      _detachSelectionFromLayer();
      state = state.copyWith(
        currentAnimationStateIndex: index,
        currentFrameIndex: 0,
        currentLayerIndex: layerIndex,
      );
      if (targetFrames.isNotEmpty) _persistEditorSelection();
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
    final current = state.currentFrames;
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length) {
      return;
    }
    await reorderFramesByIds({current[oldIndex].id}, current[newIndex].id);
  }

  // Selection operations
  void setSelection(SelectionRegion? region) {
    if (region == null) {
      _resetSelectionTransformCache();
      state = state.copyWith(selectionState: null);
      return;
    }
    _resetSelectionTransformCache();
    state = state.copyWith(
      selectionState: SelectionState(
        region: region,
        anchorPoint: region.bounds.center,
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

    if (cached == null ||
        cachedLayer == null ||
        cachedBounds == null ||
        cachedRegion == null) {
      // Fallback when transform was not explicitly started (e.g. external call)
      _saveState();
      final newPixels = _selectionService.moveSelectedPixels(
        region: sel.region,
        layerPixels: currentLayer.pixels,
        delta: delta,
      );
      _updateCurrentLayerPixels(newPixels);
      state = state.copyWith(
        selectionState: sel.copyWith(
          region: sel.region.shifted(delta),
          anchorPoint: () => sel.effectiveAnchor + delta,
        ),
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
    final movedRegion = cachedRegion.shifted(_totalMoveOffset);

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

    _updateCurrentLayerPreviewPixels(result);
    state = state.copyWith(
      selectionState: sel.copyWith(
        region: movedRegion,
        anchorPoint: () => sel.effectiveAnchor + delta,
        capturedBounds: () => movedRegion.bounds,
      ),
    );
  }

  void resizeSelectionNew(
    Rect targetBounds, {
    SelectionRegion? region,
  }) {
    final sel = state.selectionState;
    if (sel == null) return;

    final cached = _transformCachedPixels;
    final cachedLayer = _transformCachedLayerWithoutSelection;
    final cachedBounds = _transformCachedBounds;
    final cachedRegion = _transformCachedRegion;
    if (cached == null ||
        cachedLayer == null ||
        cachedBounds == null ||
        cachedRegion == null) {
      return;
    }

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

    // Target size is bounded by the canvas so a handle dragged far past the
    // edge can't balloon the resize/placement cost into the millions of
    // pixels per drag frame. (Overhang is squashed rather than clipped — an
    // acceptable trade for keeping the transform interactive.)
    final targetW = constrainedTargetBounds.width.round().clamp(1, state.width);
    final targetH =
        constrainedTargetBounds.height.round().clamp(1, state.height);

    final transformedPixels = PixelUtils.resize(
      cached,
      srcW,
      srcH,
      targetW,
      targetH,
      _selectionTransformInterpolation,
      0,
    );

    final newRegion = region ??
        _selectionService.createRectangleSelection(
          constrainedTargetBounds.left.floor(),
          constrainedTargetBounds.top.floor(),
          (constrainedTargetBounds.right - 1).floor(),
          (constrainedTargetBounds.bottom - 1).floor(),
        );
    final newAnchor = _remapAnchorToBounds(
      _transformCachedAnchor ?? sel.effectiveAnchor,
      cachedRegion.bounds,
      newRegion.bounds,
    );

    final resultPixels = _placeTransformedPixels(
      cachedLayer,
      transformedPixels,
      constrainedTargetBounds,
      targetW,
      targetH,
    );

    _updateCurrentLayerPreviewPixels(resultPixels);
    state = state.copyWith(
      selectionState: sel.copyWith(
        region: newRegion,
        scale: Size(targetW / srcW, targetH / srcH),
        anchorPoint: () => newAnchor,
        capturedPixels: () => Uint32List.fromList(transformedPixels),
        capturedBounds: () => newRegion.bounds,
      ),
    );
  }

  void rotateSelectionNew(
    double angle, {
    Offset? pivot,
    SelectionRegion? region,
  }) {
    final sel = state.selectionState;
    if (sel == null) return;

    final cached = _transformCachedPixels;
    final cachedLayer = _transformCachedLayerWithoutSelection;
    final cachedBounds = _transformCachedBounds;
    if (cached == null || cachedLayer == null || cachedBounds == null) return;

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
      _selectionTransformInterpolation,
      0,
    );
    if (rotatedPixels.isEmpty) return;

    final constrainedDest = Rect.fromLTRB(
      rotatedBounds.left.clamp(0.0, state.width.toDouble()),
      rotatedBounds.top.clamp(0.0, state.height.toDouble()),
      rotatedBounds.right.clamp(1.0, state.width.toDouble()),
      rotatedBounds.bottom.clamp(1.0, state.height.toDouble()),
    );

    // The rotated buffer is laid out for the UNCLAMPED rotatedBounds (see
    // PixelUtils.applyRotationWithBounds). Placement must use that same
    // geometry — indexing it against the clamped rect shifts every pixel
    // when the rotation overhangs a canvas edge. _placeTransformedPixels
    // clips out-of-canvas pixels itself.
    final targetW = rotatedBounds.width.round().clamp(1, 4096);
    final targetH = rotatedBounds.height.round().clamp(1, 4096);
    final bufferBounds = Rect.fromLTWH(
      rotatedBounds.left.roundToDouble(),
      rotatedBounds.top.roundToDouble(),
      targetW.toDouble(),
      targetH.toDouble(),
    );

    final newRegion = region ??
        _selectionService.createRectangleSelection(
          constrainedDest.left.floor(),
          constrainedDest.top.floor(),
          (constrainedDest.right - 1).floor(),
          (constrainedDest.bottom - 1).floor(),
        );

    final resultPixels = _placeTransformedPixels(
      cachedLayer,
      rotatedPixels,
      bufferBounds,
      targetW,
      targetH,
    );

    _updateCurrentLayerPreviewPixels(resultPixels);
    state = state.copyWith(
      selectionState: sel.copyWith(
        region: newRegion,
        rotation: angle,
        capturedPixels: () => Uint32List.fromList(rotatedPixels),
        capturedBounds: () => bufferBounds,
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

    // Mirror onto the layer in memory only — this fires per drag move.
    // [persistAnchorPoint] writes it to the database when the drag ends.
    _updateCurrentLayer(currentLayer.copyWith(anchorPoint: () => anchor));
  }

  /// Persists the current anchor point to the database. Called once when an
  /// anchor-handle drag ends.
  void persistAnchorPoint() {
    final anchor =
        state.selectionState?.anchorPoint ?? currentLayer.anchorPoint;
    if (anchor == null) return;

    final layer = currentLayer.copyWith(anchorPoint: () => anchor);
    _updateCurrentLayer(layer);
    _layerService.updateLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      layer: layer,
    );
    _updateProject();
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

  void growSelectionRegion({int by = 1}) {
    final sel = state.selectionState;
    if (sel == null) return;

    final grown = _selectionService.growSelection(sel.region, by: by);
    if (grown.bounds.isEmpty) {
      clearSelection();
    } else {
      setSelection(grown);
    }
  }

  void shrinkSelectionRegion({int by = 1}) {
    final sel = state.selectionState;
    if (sel == null) return;

    final shrunk = _selectionService.shrinkSelection(sel.region, by: by);
    if (shrunk.bounds.isEmpty) {
      clearSelection();
    } else {
      setSelection(shrunk);
    }
  }

  void flipSelectionPixels({required bool horizontal}) => transformSelection(
        horizontal ? PixelTransform.flipHorizontal : PixelTransform.flipVertical,
      );

  /// Flips or quarter-turns the selected pixels together with the selection
  /// shape. Records a full snapshot because the selection changes as well as
  /// the pixels.
  void transformSelection(PixelTransform transform) {
    if (state.selectionState == null || currentLayerIsProcedural) return;

    _detachSelectionFromLayer();
    final region = state.selectionState?.region;
    if (region == null) return;

    final result = PixelTransformService.transformSelection(
      layerPixels: currentLayer.pixels,
      canvasWidth: state.width,
      canvasHeight: state.height,
      region: region,
      transform: transform,
    );
    if (result == null) return;

    _saveState();
    _updateCurrentLayerPixels(result.pixels);
    setSelection(result.region);
  }

  /// Flips or rotates whole layers about the canvas centre in the current
  /// frame. Locked and procedural (effect-generated) layers are skipped.
  Future<void> transformLayers(
    Iterable<int> indices,
    PixelTransform transform,
  ) async {
    final targets = indices
        .where((i) => i >= 0 && i < currentFrame.layers.length)
        .where((i) {
      final layer = currentFrame.layers[i];
      return !layer.isLocked && !EffectStackService.isProcedural(layer);
    }).toSet();
    if (targets.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();

    final updated = List<Layer>.from(currentFrame.layers);
    for (final index in targets) {
      final layer = updated[index];
      final anchor = layer.anchorPoint;
      updated[index] = layer.copyWith(
        pixels: PixelTransformService.transformLayerPixels(
          pixels: layer.pixels,
          width: state.width,
          height: state.height,
          transform: transform,
        ),
        anchorPoint: anchor == null
            ? null
            : () => PixelTransformService.transformPoint(
                  point: anchor,
                  width: state.width,
                  height: state.height,
                  transform: transform,
                ),
      );
    }
    _updateCurrentFrame(currentFrame.copyWith(layers: updated));
    await Future.wait(targets.map((index) => _layerService.updateLayer(
          projectId: project.id,
          frameId: currentFrame.id,
          layer: updated[index],
        )));
    _updateProject();
  }

  void clearSelection() {
    _resetSelectionTransformCache();
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
    _recordProgress(ProgressionEvent.imageExported);
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
    _recordProgress(ProgressionEvent.animationExported);
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
    _recordProgress(ProgressionEvent.imageExported);
  }

  /// Counts an action toward quests. In-memory only, safe on hot paths.
  void _recordProgress(ProgressionEvent event) {
    final progression = ref.read(progressionProvider.notifier);
    progression.record(event);
    // Coming back to an older piece counts for the "old project" bonus quest.
    if (event == ProgressionEvent.strokeCompleted &&
        project.createdAt
            .isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
      progression.record(ProgressionEvent.oldProjectStroke);
    }
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
      _recordProgress(ProgressionEvent.imageImported);
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
      _recordProgress(ProgressionEvent.imageImported);
    }
  }

  // Helper methods
  Color _getDrawingColor() {
    return state.currentTool == PixelTool.eraser
        ? Colors.transparent
        : state.currentColor;
  }

  void _updateCurrentLayerPixels(Uint32List newPixels) {
    if (currentLayerIsProcedural) {
      _activeBuffer = null;
      _isBatching = false;
      _clearPendingPixelUndo();
      return;
    }

    final undoPreState = _pendingUndoPreState;
    final undoPrePixels = _pendingUndoPrePixels;
    _clearPendingPixelUndo();

    final updatedLayer = currentLayer.copyWith(pixels: newPixels);
    final updatedLayers = List<Layer>.from(currentFrame.layers);
    updatedLayers[state.currentLayerIndex] = updatedLayer;

    final updatedFrame = currentFrame.copyWith(layers: updatedLayers);
    _updateCurrentFrame(updatedFrame);

    if (undoPreState != null && undoPrePixels != null) {
      _undoRedoService.savePixelDiff(
        preState: undoPreState,
        prePixels: undoPrePixels,
        postPixels: newPixels,
      );
      state = state.copyWith(canUndo: canUndo, canRedo: canRedo);
    }

    _layerService.updateLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      layer: updatedLayer,
    );
    _updateProject();
  }

  void _updateCurrentLayerPreviewPixels(Uint32List newPixels) {
    _transformPreviewDirty = true;
    _updateCurrentLayer(currentLayer.copyWith(pixels: newPixels));
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
    resizeSelectionNew(region.bounds, region: region);
  }

  void rotateSelection(SelectionRegion region, SelectionRegion oldRegion,
      double angle, Offset? center) {
    rotateSelectionNew(angle, pivot: center, region: region);
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

  _SelectionCapture _captureOpaqueSelection(
    SelectionRegion region,
    Uint32List layerPixels,
  ) {
    final bounds = region.bounds;
    final bw = bounds.width.ceil().clamp(1, state.width);
    final bh = bounds.height.ceil().clamp(1, state.height);
    final extracted = Uint32List(bw * bh);
    final basePixels = Uint32List.fromList(layerPixels);
    final indices = region.getSelectedPixelIndices(state.width, state.height);

    for (final idx in indices) {
      if (idx < 0 || idx >= layerPixels.length) continue;

      final pixel = layerPixels[idx];
      if (pixel == 0) continue;

      final x = idx % state.width;
      final y = idx ~/ state.width;
      final lx = x - bounds.left.floor();
      final ly = y - bounds.top.floor();

      if (lx >= 0 && lx < bw && ly >= 0 && ly < bh) {
        extracted[ly * bw + lx] = pixel;
      }

      basePixels[idx] = 0;
    }

    return _SelectionCapture(
      selectionPixels: extracted,
      basePixels: basePixels,
      bounds: bounds,
    );
  }

  void _resetSelectionTransformCache() {
    _transformCachedPixels = null;
    _transformCachedLayerWithoutSelection = null;
    _transformCachedBounds = null;
    _transformCachedRegion = null;
    _transformCachedAnchor = null;
    _totalMoveOffset = Offset.zero;
    _transformPreviewDirty = false;
  }

  Offset _remapAnchorToBounds(
    Offset anchor,
    Rect sourceBounds,
    Rect targetBounds,
  ) {
    final normalizedX = sourceBounds.width == 0
        ? 0.5
        : (anchor.dx - sourceBounds.left) / sourceBounds.width;
    final normalizedY = sourceBounds.height == 0
        ? 0.5
        : (anchor.dy - sourceBounds.top) / sourceBounds.height;

    return Offset(
      targetBounds.left + normalizedX * targetBounds.width,
      targetBounds.top + normalizedY * targetBounds.height,
    );
  }

  void _persistCurrentLayer() {
    final layer = currentLayer;
    _layerService.updateLayer(
      projectId: project.id,
      frameId: currentFrame.id,
      layer: layer,
    );
    _updateProject();
  }

  int get _selectionTransformInterpolation {
    return ref
        .read(editorSettingsNotifierProvider)
        .transformInterpolation
        .pixelUtilsValue;
  }
}

class _SelectionCapture {
  final Uint32List selectionPixels;
  final Uint32List basePixels;
  final Rect bounds;

  const _SelectionCapture({
    required this.selectionPixels,
    required this.basePixels,
    required this.bounds,
  });
}
