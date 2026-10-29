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
import '../effects/effect_target.dart';
import '../effects/effects.dart';
import '../services/animation_service.dart';
import '../services/clipboard_placement_service.dart';
import '../services/drawing_service.dart';
import '../services/editor_selection_service.dart';
import '../services/effect_stack_service.dart';
import '../services/frame_service.dart';
import '../services/import_export_service.dart';
import '../rotsprite.dart';
import '../services/layer_merge_service.dart';
import '../services/layer_service.dart';
import '../services/pixel_transform_service.dart';
import '../services/selection_service.dart';
import '../services/template_service.dart';
import '../services/undo_redo_service.dart';
import '../rig/rig_bake.dart';
import '../rig/stable_layer_keys.dart';
import '../pixel_canvas_state.dart';
import '../tools.dart';
import '../../ui/utils/multi_selection.dart';
import 'editor_selection_provider.dart';

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
  late final RigBakeService _rigBakeService;

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

  // Bone rigs of the project (see RigDocument). Kept here, not in the
  // canvas state, because rig edits never touch frames or undo history.
  String? _rigData;

  @override
  PixelCanvasState build(Project project) {
    _rigData = project.rigData;
    // Keep the timeline selection alive for as long as the project is open.
    ref.listen(editorSelectionProvider(project.id), (_, __) {});
    // Initialize services
    _layerService = LayerService(ref.read(projectRepo));
    _frameService = FrameService(ref.read(projectRepo));
    _animationService = AnimationService(ref.read(projectRepo));
    _drawingService = DrawingService();
    _selectionService = SelectionService(width: project.width, height: project.height);
    _undoRedoService = UndoRedoService();
    _importExportService = ImportExportService();
    _templateService = TemplateService(ref.read(templateAPIRepoProvider));
    _projectRepo = ref.read(projectRepo);
    _rigBakeService = RigBakeService(_projectRepo);

    // Flush the pending save when the app is backgrounded or closing so the
    // debounce window can't drop the last edits.
    _lifecycleListener = AppLifecycleListener(
      onPause: () => unawaited(flushPendingProjectSave()),
      onDetach: () => unawaited(flushPendingProjectSave()),
    );

    ref.onDispose(() {
      _cloudSyncTimer?.cancel();
      _nudgeTimer?.cancel();
      _lifecycleListener?.dispose();
      unawaited(flushPendingProjectSave());
    });

    final animationStates = project.states.isNotEmpty
        ? List<AnimationStateModel>.from(project.states)
        : [const AnimationStateModel(id: 0, name: 'Default', frameRate: 12)];
    final frames = project.frames.isNotEmpty ? List<AnimationFrame>.from(project.frames) : _createDefaultFrame();
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
  bool get currentLayerIsProcedural => EffectStackService.isProcedural(currentLayer);
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
    // After a canvas crop this controller's state is stale; the editor
    // reopens with the cropped project.
    if (_retired) return;
    final updated = project.copyWith(
      frames: state.frames,
      states: state.animationStates,
      selectedFrameId: currentFrame.id,
      selectedLayerId: currentLayer.layerId,
      rigData: _rigData,
      clearRigData: _rigData == null,
      editedAt: DateTime.now(),
    );
    _pendingProjectSave = updated;
    _projectSaveGeneration += 1;
    ref.read(editorWorkspaceProvider.notifier).setUnsavedChanges(project.id, true);
    _projectSaveTimer?.cancel();
    _projectSaveTimer = Timer(
      _localSaveDebounce,
      () => unawaited(flushPendingProjectSave()),
    );
    _scheduleCloudSync(updated);
  }

  /// The bone rig that [stateId] belongs to, if any: the animation holding its
  /// rest pose, or the animation its baked frames live in.
  Rig? rigForState(int stateId) {
    for (final rig in RigDocument.decode(_rigData)) {
      if (rig.stateId == stateId || rig.outputStateId == stateId) return rig;
    }
    return null;
  }

  /// Everything the rig editor needs, from what the editor is showing now.
  ///
  /// The rig is drawn against one frame of its rest-pose animation. Opened
  /// from that animation, that is the frame being edited, so layers just
  /// drawn or added there are what the rig sees. Opened from the baked
  /// animation (whose frames are the rig's output, not its source), it is
  /// the frame the rig was last set up on.
  ({Rig? rig, AnimationStateModel source, int restFrameIndex, List<AnimationFrame> frames}) prepareRigSession() {
    final current = state.currentAnimationState;
    final existing = rigForState(current.id);
    final sourceId = existing?.stateId ?? current.id;
    final source = state.animationStates.firstWhere((s) => s.id == sourceId, orElse: () => current);

    final frames = prepareRigEditing(source.id);
    final wanted = current.id == source.id ? state.currentFrameIndex : (existing?.restFrameIndex ?? 0);
    final index = frames.isEmpty ? 0 : wanted.clamp(0, frames.length - 1);
    return (rig: existing, source: source, restFrameIndex: index, frames: frames);
  }

  /// Gets animation [stateId] ready for rig editing and returns its frames:
  /// every layer gets a `Layer.stableKey` so a rig can follow it from frame
  /// to frame. Only layer metadata changes (pixel buffers are shared), so
  /// this is not an undo step; stamping is repeatable, so keys come back
  /// identical if an undo restores frames from before it ran.
  List<AnimationFrame> prepareRigEditing(int stateId) {
    final stamped = StableLayerKeys.ensure(state.frames, stateId);
    var changed = false;
    for (var i = 0; i < stamped.length; i++) {
      if (!identical(stamped[i], state.frames[i])) changed = true;
    }
    if (changed) {
      _detachSelectionFromLayer();
      state = state.copyWith(frames: stamped);
      _updateProject();
    }
    return [
      for (final f in state.frames)
        if (f.stateId == stateId) f,
    ];
  }

  /// Stores [rig] as the rig of its animation state, replacing the previous
  /// one. Saved with the project like any other edit.
  void saveRig(Rig rig) {
    final rigs = [
      for (final r in RigDocument.decode(_rigData))
        if (r.stateId != rig.stateId) r,
      rig,
    ];
    _rigData = RigDocument.encode(rigs);
    _updateProject();
  }

  /// Frames that baking [rig] would delete although they hold hand-painted
  /// pixels (a shorter clip drops its tail frames). Ask before going ahead.
  List<AnimationFrame> rigBakeLosses(Rig rig) => RigBakePlanner.removalsWithEdits(rig: rig, frames: state.frames);

  /// Saves [rig] and, when [bake] is set and it has keyframes, bakes its clip
  /// into the rig's output animation. The bake is one undo step. The rest
  /// pose is only read; frames already baked are refreshed in place, so hand
  /// edits on their cleanup layers survive.
  ///
  /// Returns the rig as stored (it now knows its output animation). If the
  /// bake fails the rig is still saved and the error is rethrown.
  Future<Rig> applyRig(Rig rig, {bool bake = true}) async {
    if (!bake || !RigBakeService.canBake(rig)) {
      saveRig(rig);
      return rig;
    }

    _detachSelectionFromLayer();
    _saveState();
    final RigBakeResult result;
    try {
      result = await _rigBakeService.bake(
        projectId: project.id,
        rig: rig,
        states: state.animationStates,
        frames: state.frames,
        width: state.width,
        height: state.height,
      );
    } catch (_) {
      _undoRedoService.discardLastSavedState();
      state = state.copyWith(canUndo: canUndo, canRedo: canRedo);
      saveRig(rig);
      rethrow;
    }

    // Show the result: its first frame, on the layer meant for touch-ups.
    final outputIndex = result.states.indexWhere((s) => s.id == result.outputState.id);
    final firstFrame = result.frames.firstWhere((f) => f.stateId == result.outputState.id);
    final cleanupIndex = firstFrame.layers.indexWhere((l) => l.stableKey == RigLayerKeys.cleanup);
    state = state.copyWith(
      animationStates: result.states,
      frames: result.frames,
      currentAnimationStateIndex: outputIndex,
      currentFrameIndex: 0,
      currentLayerIndex: cleanupIndex < 0 ? 0 : cleanupIndex,
    );
    saveRig(result.rig);
    _persistEditorSelection();
    return result.rig;
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

  /// Whether newer edits still need to be persisted after the current write.
  bool get hasPendingProjectSave => _pendingProjectSave != null;

  /// Writes the most recent pending project snapshot immediately.
  // Set by [cropCanvasToSelection]: nothing from this controller may be
  // saved any more.
  bool _retired = false;

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
      ErrorReportService.instance.report(error, stack, operation: 'editor.saveProject');
      // Preserve a failed snapshot for an explicit retry, without replacing a
      // newer edit that arrived while this write was in flight.
      if (_pendingProjectSave == null && generation == _projectSaveGeneration) {
        _pendingProjectSave = pending;
      }
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

  /// Commits explicit automation pixels independently of UI tool/selection state.
  /// Validation happens before history capture so a failed call has no side effects.
  void applyAutomationPixels(Uint32List pixels) {
    if (_isBatching) throw StateError('A drawing gesture is in progress');
    if (currentLayer.isLocked) throw StateError('The layer is locked');
    if (currentLayerIsProcedural) throw StateError('The layer is procedural');
    if (pixels.length != state.width * state.height) {
      throw ArgumentError('Pixel buffer does not match the canvas');
    }
    _beginPixelUndo();
    _updateCurrentLayerPixels(Uint32List.fromList(pixels));
  }

  bool get automationBusy => _isBatching;

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
  Uint32List? _originalPixels;

  void startDrag() {
    if (currentLayerIsProcedural) return;
    _saveState();
    // One copy per drag; every move re-offsets this original.
    _originalPixels = Uint32List.fromList(currentLayer.pixels);
  }

  /// Moves the current layer's pixels by [delta], measured in canvas pixels
  /// from where the drag started.
  void dragPixels(Offset delta) {
    final original = _originalPixels;
    if (original == null) return;

    final newPixels = _drawingService.dragPixels(
      originalPixels: original,
      currentPixels: currentLayer.pixels,
      width: state.width,
      height: state.height,
      deltaOffset: delta,
    );

    _updateCurrentLayerPixels(newPixels);
  }

  void endDrag() {
    _originalPixels = null;
  }

  // Layers multi-selected in the layers panel (frame indices), reported by
  // the canvas notifier. Selection edits act on all of them; see
  // [_selectionTargetIndices].
  List<int> _selectedLayerIndices = const [];

  set selectedLayerIndices(List<int> indices) {
    if (listEquals(indices, _selectedLayerIndices)) return;
    // Transform caches hold one buffer per target layer; a different set of
    // targets must recapture.
    _detachSelectionFromLayer();
    _selectedLayerIndices = List.unmodifiable(indices);
  }

  /// Layers selected in the layers panel (frame indices, sorted, active
  /// included). Without a multi-selection this is only the active layer.
  List<int> get selectedLayerIndices => EffectTarget.resolveSelection(
        selected: _selectedLayerIndices,
        activeIndex: state.currentLayerIndex,
        layerCount: currentFrame.layers.length,
      );

  /// Frame indices of the layers a selection edit acts on, sorted bottom to
  /// top. The active layer is always included when the multi-selection holds
  /// it; other selected layers are skipped when locked, hidden or procedural.
  /// Without a valid multi-selection this is only the active layer.
  List<int> get _selectionTargetIndices {
    final active = state.currentLayerIndex;
    final layers = currentFrame.layers;
    return [
      for (final i in EffectTarget.resolveSelection(
        selected: _selectedLayerIndices,
        activeIndex: active,
        layerCount: layers.length,
      ))
        if (i == active || _isSelectionEditable(layers[i])) i,
    ];
  }

  bool _isSelectionEditable(Layer layer) =>
      layer.isVisible && !layer.isLocked && !EffectStackService.isProcedural(layer) && layer.pixels.isNotEmpty;

  /// The extra (non-active) layers a selection edit acts on.
  List<int> get _extraSelectionTargets => [
        for (final i in _selectionTargetIndices)
          if (i != state.currentLayerIndex) i,
      ];

  /// Replaces the pixels of several current-frame layers in one state update
  /// and persists them. Callers record undo with [_saveState] first.
  void _updateLayersPixels(Map<int, Uint32List> pixelsByIndex) {
    _dropStaleSelectionCapture();
    final updated = List<Layer>.from(currentFrame.layers);
    for (final MapEntry(key: index, value: pixels) in pixelsByIndex.entries) {
      updated[index] = updated[index].copyWith(pixels: pixels);
    }
    _updateCurrentFrame(currentFrame.copyWith(layers: updated));
    for (final index in pixelsByIndex.keys) {
      _layerService.updateLayer(
        projectId: project.id,
        frameId: currentFrame.id,
        layer: updated[index],
      );
    }
    _updateProject();
  }

  /// The selected layers' pixels composited top-over-bottom, as they look.
  Uint32List _mergedSelectionTargetPixels(List<int> targets) => PixelUtils.mergeLayersPixels(
        width: state.width,
        height: state.height,
        layers: [for (final i in targets) currentFrame.layers[i]],
      );

  /// Clears the selected pixels from every target layer as one undo step.
  void _clearSelectionOnLayers(SelectionRegion sel, List<int> targets) {
    _saveState();
    _updateLayersPixels({
      for (final i in targets)
        i: _selectionService.clearPixelsInSelection(sel, currentFrame.layers[i].pixels, state.width, state.height),
    });
  }

  void clearSelectionArea() {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return;
    if (_extraSelectionTargets.isNotEmpty) {
      _detachSelectionFromLayer();
      _clearSelectionOnLayers(sel, _selectionTargetIndices);
      return;
    }
    _beginPixelUndo();
    final clearedPixels = _selectionService.clearPixelsInSelection(
      sel,
      currentLayer.pixels,
      state.width,
      state.height,
    );
    _updateCurrentLayerPixels(clearedPixels);
  }

  /// The canvas indices inside [region].
  List<bool> _selectionMask(SelectionRegion region) {
    final mask = List<bool>.filled(state.width * state.height, false);
    for (final i in region.getSelectedPixelIndices(state.width, state.height)) {
      mask[i] = true;
    }
    return mask;
  }

  /// Sets [indices] to [color] on every selection target layer as one undo
  /// step, the same way [clearSelectionArea] edits them.
  void _paintSelectionTargets(List<int> indices, Color color) {
    if (indices.isEmpty || currentLayer.pixels.isEmpty) return;
    final value = color.toARGB32();
    Uint32List paint(Uint32List source) {
      final out = Uint32List.fromList(source);
      for (final i in indices) {
        if (i < out.length) out[i] = value;
      }
      return out;
    }

    if (_extraSelectionTargets.isNotEmpty) {
      _detachSelectionFromLayer();
      _saveState();
      _updateLayersPixels({
        for (final i in _selectionTargetIndices) i: paint(currentFrame.layers[i].pixels),
      });
      return;
    }
    _beginPixelUndo();
    _updateCurrentLayerPixels(paint(currentLayer.pixels));
  }

  /// Alt+Backspace: fills the selection with [color] on every selected layer.
  void fillSelection(Color color) {
    final sel = state.selectionState?.region;
    if (sel == null) return;
    _paintSelectionTargets(sel.getSelectedPixelIndices(state.width, state.height), color);
  }

  /// Draws a 1-pixel outline of the selection in [color] on every selected
  /// layer: along the inside of its edge, or with [inside] false just
  /// outside it. The canvas border counts as outside the selection.
  void strokeSelection(Color color, {bool inside = true}) {
    final sel = state.selectionState?.region;
    if (sel == null) return;
    final w = state.width, h = state.height;
    final mask = _selectionMask(sel);
    bool selected(int x, int y) => x >= 0 && y >= 0 && x < w && y < h && mask[y * w + x];
    final edge = <int>[];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (mask[y * w + x] != inside) continue;
        if (selected(x - 1, y) != inside ||
            selected(x + 1, y) != inside ||
            selected(x, y - 1) != inside ||
            selected(x, y + 1) != inside) {
          edge.add(y * w + x);
        }
      }
    }
    _paintSelectionTargets(edge, color);
  }

  /// Ctrl+Shift+C: the selected area as the frame looks, every visible layer
  /// composited (canvas-sized; other pixels are 0). Null without a selection.
  Uint32List? copyMergedSelectionPixels() {
    final sel = state.selectionState?.region;
    if (sel == null) return null;
    final merged = LayerMergeService.composite(currentFrame.layers, state.width, state.height);
    return _selectionService.copySelectedPixels(sel, merged);
  }

  /// The selection's bounds snapped out to whole pixels and clipped to the
  /// canvas, or null when that leaves nothing.
  Rect? get _selectionCropRect {
    final bounds = state.selectionState?.region.bounds;
    if (bounds == null) return null;
    final rect = Rect.fromLTRB(
      bounds.left.floorToDouble().clamp(0, state.width.toDouble()),
      bounds.top.floorToDouble().clamp(0, state.height.toDouble()),
      bounds.right.ceilToDouble().clamp(0, state.width.toDouble()),
      bounds.bottom.ceilToDouble().clamp(0, state.height.toDouble()),
    );
    return rect.width < 1 || rect.height < 1 ? null : rect;
  }

  /// Whether [cropCanvasToSelection] can run: a selection that isn't the
  /// whole canvas, and no bone rig (its coordinates aren't shifted yet).
  bool get canCropToSelection {
    final rect = _selectionCropRect;
    return rect != null &&
        _rigData == null &&
        rect != Rect.fromLTWH(0, 0, state.width.toDouble(), state.height.toDouble());
  }

  /// Crops every frame and layer of the project to the selection's bounds and
  /// saves it. Not undoable: the canvas size is fixed for an open editor, so
  /// the caller reopens it with the returned project, and this controller
  /// stops saving. Returns null when [canCropToSelection] is false.
  Future<Project?> cropCanvasToSelection() async {
    if (!canCropToSelection) return null;
    final rect = _selectionCropRect!;
    final left = rect.left.toInt(), top = rect.top.toInt();
    final width = rect.width.toInt(), height = rect.height.toInt();
    _detachSelectionFromLayer();
    await flushPendingProjectSave();

    Uint32List crop(Uint32List source) {
      final out = Uint32List(width * height);
      if (source.length != state.width * state.height) return out;
      for (var y = 0; y < height; y++) {
        final from = (top + y) * state.width + left;
        out.setRange(y * width, (y + 1) * width, source, from);
      }
      return out;
    }

    final shift = Offset(left.toDouble(), top.toDouble());
    final cropped = project.copyWith(
      width: width,
      height: height,
      states: state.animationStates,
      frames: [
        for (final frame in state.frames)
          frame.copyWith(layers: [
            for (final layer in frame.layers)
              layer.copyWith(
                pixels: crop(layer.pixels),
                anchorPoint: () => layer.anchorPoint == null ? null : layer.anchorPoint! - shift,
              ),
          ]),
      ],
      selectedFrameId: currentFrame.id,
      selectedLayerId: currentLayer.layerId,
      editedAt: DateTime.now(),
    );
    _retired = true;
    _cloudSyncTimer?.cancel();
    await _projectRepo.updateProject(cropped);
    return cropped;
  }

  /// Returns a pixel buffer containing only the selected pixels (canvas-sized).
  /// Returns null if there is no active selection.
  Uint32List? copySelectionPixels() {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return null;
    final targets = _selectionTargetIndices;
    if (targets.length > 1) {
      return _selectionService.copySelectedPixels(sel, _mergedSelectionTargetPixels(targets));
    }
    return _selectionService.copySelectedPixels(sel, currentLayer.pixels);
  }

  /// Clears the selected pixels from the current layer (every selected layer
  /// when several are selected) and returns their data.
  Uint32List? cutSelectionPixels() {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return null;
    final targets = _selectionTargetIndices;
    if (targets.length > 1) {
      _detachSelectionFromLayer();
      final copied = _selectionService.copySelectedPixels(sel, _mergedSelectionTargetPixels(targets));
      _clearSelectionOnLayers(sel, targets);
      return copied;
    }
    _beginPixelUndo();
    final copied = _selectionService.copySelectedPixels(sel, currentLayer.pixels);
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
  /// [inPlace] (Ctrl+Shift+V) keeps the copied coordinates even when the
  /// source canvas had another size, instead of centering.
  Future<void> pastePixels(
    Uint32List pixels,
    SelectionRegion region, {
    required int sourceWidth,
    required int sourceHeight,
    bool inPlace = false,
  }) async {
    final layerId = const Uuid().v4();
    final placement = placeClipboardPixels(
      source: pixels,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      targetWidth: state.width,
      targetHeight: state.height,
      inPlace: inPlace,
    );
    final newLayer = Layer(
      layerId: 0,
      id: layerId,
      name: 'Pasted',
      pixels: placement.pixels,
      isVisible: true,
      order: state.currentFrame.layers.length,
    );
    // Inserted above the current layer, which it becomes.
    await addLayerWithPixels(newLayer);
    setSelection(region.shifted(placement.offset));
  }

  Future<void> selectionToNewLayer({bool clearSource = false}) async {
    final sel = state.selectionState?.region;
    if (sel == null || currentLayer.pixels.isEmpty) return;

    final layerId = const Uuid().v4();
    final targets = _selectionTargetIndices;
    final newLayerPixels = _selectionService.extractPixels(
      sel,
      targets.length > 1 ? _mergedSelectionTargetPixels(targets) : currentLayer.pixels,
      state.width,
      state.height,
    );

    // Check if any pixels were extracted
    bool hasPixels = newLayerPixels.any((p) => p != 0);
    if (!hasPixels) return;

    if (clearSource && targets.length > 1) {
      _detachSelectionFromLayer();
      _clearSelectionOnLayers(sel, targets);
    } else {
      _saveState();
    }

    if (clearSource && targets.length == 1) {
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

    // Inserted above the current layer, which it becomes.
    await addLayerWithPixels(newLayer);
  }

  Uint32List? _transformCachedPixels;
  Uint32List? _transformCachedLayerWithoutSelection; // layer pixels with selection cleared
  Rect? _transformCachedBounds;
  SelectionRegion? _transformCachedRegion;
  Offset? _transformCachedAnchor;
  Offset _totalMoveOffset = Offset.zero;
  bool _transformPreviewDirty = false;

  // The other selected layers transformed along with the active one. Their
  // geometry (bounds, offset, scale, rotation) is the active layer's; only
  // the pixel buffers differ. Empty for a single-layer transform.
  List<_LayerTransformCache> _extraTransformLayers = const [];

  // A transform session spans every drag and nudge applied to the same
  // floating pixels, from the first one until the pixels are dropped
  // (commit, a new selection, a layer/frame switch...). Esc cancels the
  // whole session: [_transformSessionStart] is the state before its first
  // step, [_transformSessionUndoDepth] the undo stack size then.
  PixelCanvasState? _transformSessionStart;
  int _transformSessionUndoDepth = 0;

  // Arrow-key nudges keep one transform open so a burst of presses is one
  // undo step; it ends after a pause or when anything else ends it.
  static const _nudgeIdle = Duration(milliseconds: 600);
  Timer? _nudgeTimer;
  bool _nudging = false;

  /// Whether a transform session is open, i.e. Enter would commit and Esc
  /// would cancel.
  bool get hasTransformSession => _transformSessionStart != null;

  void startTransformSelection(SelectionRegion region) {
    if (_nudging) endTransformSelection();
    if (currentLayer.pixels.isEmpty) return;

    final bounds = region.bounds;
    if (bounds.width <= 0 || bounds.height <= 0) return;

    if (_transformSessionStart == null) {
      _transformSessionStart = state;
      _transformSessionUndoDepth = _undoRedoService.undoStackSize;
    }
    // One snapshot covers every target layer, so one undo reverts them all.
    _saveState();
    _transformCachedRegion = region;
    _transformCachedAnchor = state.selectionState?.effectiveAnchor ?? region.bounds.center;

    final cachedSelectionPixels = state.selectionState?.capturedPixels;
    final cachedSelectionBounds = state.selectionState?.capturedBounds;
    final extraTargets = _extraSelectionTargets;
    final extrasMatch = listEquals(
      [for (final c in _extraTransformLayers) c.layerIndex],
      extraTargets,
    );

    if (_transformCachedLayerWithoutSelection == null ||
        cachedSelectionPixels == null ||
        cachedSelectionBounds == null ||
        !extrasMatch) {
      final capture = _captureOpaqueSelection(region, currentLayer.pixels);
      _transformCachedPixels = capture.selectionPixels;
      _transformCachedBounds = capture.bounds;
      _transformCachedLayerWithoutSelection = capture.basePixels;
      _extraTransformLayers = [
        for (final i in extraTargets)
          _LayerTransformCache.capture(i, _captureOpaqueSelection(region, currentFrame.layers[i].pixels)),
      ];
    } else {
      _transformCachedPixels = Uint32List.fromList(cachedSelectionPixels);
      _transformCachedBounds = cachedSelectionBounds;
      for (final c in _extraTransformLayers) {
        c.source = c.floating;
      }
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
    _nudgeTimer?.cancel();
    _nudgeTimer = null;
    _nudging = false;
    final rotSprite = _pendingRotSprite;
    if (rotSprite != null) {
      rotateSelectionNew(rotSprite.angle, pivot: rotSprite.pivot, region: rotSprite.region, finalPass: true);
    }
    if (_transformPreviewDirty) {
      // Keep the layer's serialized anchor in sync with where the selection
      // (and its anchor) ended up — otherwise it goes stale after any move.
      final anchor = state.selectionState?.anchorPoint;
      if (anchor != null && currentLayer.anchorPoint != anchor) {
        _updateCurrentLayer(currentLayer.copyWith(anchorPoint: () => anchor));
      }
      for (final c in _extraTransformLayers) {
        if (c.layerIndex >= currentFrame.layers.length) continue;
        _layerService.updateLayer(
          projectId: project.id,
          frameId: currentFrame.id,
          layer: currentFrame.layers[c.layerIndex],
        );
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

  /// Enter: drops the floating pixels where they are and keeps the
  /// selection. Returns false when no transform session is open.
  bool commitTransformSession() {
    if (_transformSessionStart == null) return false;
    _detachSelectionFromLayer();
    return true;
  }

  /// Esc: puts the pixels and the selection back as they were before the
  /// session's first move, resize, rotate or nudge, and drops the undo steps
  /// it recorded. Returns false when no transform session is open.
  bool cancelTransformSession() {
    final start = _transformSessionStart;
    if (start == null) return false;
    _pendingRotSprite = null;
    if (state.selectionState?.isTransforming == true) endTransformSelection();
    while (_undoRedoService.undoStackSize > _transformSessionUndoDepth) {
      _undoRedoService.discardLastSavedState();
    }
    _resetSelectionTransformCache();
    // Frames and layers can't change during a session (switching ends it), so
    // only the pixels and the selection go back. The start state's buffers
    // are the ones its undo snapshot held; transforms never write into them.
    state = state.copyWith(
      frames: start.frames,
      selectionState: start.selectionState?.copyWith(
        isTransforming: false,
        capturedPixels: () => null,
        capturedBounds: () => null,
      ),
      canUndo: canUndo,
      canRedo: canRedo,
    );
    _updateProject();
    return true;
  }

  /// Transform panel: moves and resizes the selected pixels to [bounds]
  /// (kept on the canvas) as one step of the transform session, so Esc
  /// reverts it with the rest.
  void setSelectionBounds(Rect bounds) {
    final selection = state.selectionState;
    if (selection == null || selection.isTransforming || bounds == selection.region.bounds) return;
    if (bounds.width < 1 || bounds.height < 1) return;
    startTransformSelection(selection.region);
    if (state.selectionState?.isTransforming != true) return;
    resizeSelectionNew(bounds);
    endTransformSelection();
  }

  /// Transform panel: rotates the selected pixels by [angle] radians around
  /// the anchor as one step of the transform session. Rendered at the
  /// interpolation setting's best quality (RotSprite when chosen).
  void rotateSelectionBy(double angle) {
    final selection = state.selectionState;
    if (selection == null || selection.isTransforming || angle == 0) return;
    final anchor = selection.effectiveAnchor;
    final matrix = Matrix4.translationValues(anchor.dx, anchor.dy, 0)
      ..rotateZ(angle)
      ..multiply(Matrix4.translationValues(-anchor.dx, -anchor.dy, 0));
    startTransformSelection(selection.region);
    if (state.selectionState?.isTransforming != true) return;
    rotateSelectionNew(angle, region: selection.region.transformed(matrix), finalPass: true);
    endTransformSelection();
  }

  /// Arrow keys: moves the selected pixels by [delta]. Presses in a quick
  /// burst share one transform, so they undo (and cancel) together.
  void nudgeSelection(Offset delta) {
    final selection = state.selectionState;
    if (selection == null || delta == Offset.zero) return;
    if (!_nudging) {
      // A pointer drag owns the transform right now.
      if (selection.isTransforming) return;
      startTransformSelection(selection.region);
      if (state.selectionState?.isTransforming != true) return;
      _nudging = true;
    }
    moveSelection(delta);
    _nudgeTimer?.cancel();
    _nudgeTimer = Timer(_nudgeIdle, () {
      if (_nudging) endTransformSelection();
    });
  }

  /// Ends any in-progress transform and drops the transform caches before
  /// the current layer or frame changes. The cached "layer without
  /// selection" and captured pixels alias the OLD layer — reusing them after
  /// a switch would stamp the old layer's content onto the new one. The
  /// selection region and anchor survive (standard editor behavior); the
  /// next transform recaptures from the new layer.
  /// Drops the transform caches after layer pixels changed outside a
  /// transform (delete, a stroke, undo). The cached "layer without
  /// selection" and floating pixels describe the layer as it was, so the
  /// next drag would stamp that old content back over the edit. The next
  /// transform recaptures from the current pixels instead.
  void _dropStaleSelectionCapture() {
    if (state.selectionState?.isTransforming == true) return;
    _detachSelectionFromLayer();
  }

  void _detachSelectionFromLayer() {
    if (state.selectionState?.isTransforming == true) {
      endTransformSelection();
    }
    _resetSelectionTransformCache();
    final sel = state.selectionState;
    if (sel != null && (sel.capturedPixels != null || sel.capturedBounds != null)) {
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
    final valid = indices.where((index) => index >= 0 && index < currentFrame.layers.length).toSet().toList()..sort();

    return [
      for (final index in valid) Layer.fromJson(currentFrame.layers[index].toJson()),
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
        anchorPoint: () => source.anchorPoint == null ? null : source.anchorPoint! + placement.offset,
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
      currentLayerIndex: layers.indexWhere((layer) => layer.id == lastCreatedId),
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
    await Future.wait(requested.map((i) => _layerService.deleteLayer(layers[i].layerId)));

    final remaining = <Layer>[
      for (final (index, layer) in layers.indexed)
        if (!requested.contains(index)) layer,
    ];
    final reordered = [
      for (final (index, layer) in remaining.indexed) layer.copyWith(order: index),
    ];
    _updateCurrentFrame(currentFrame.copyWith(layers: reordered));

    var activeIndex = reordered.indexWhere((layer) => layer.id == activeLayerId);
    if (activeIndex < 0) {
      activeIndex = requested.reduce((a, b) => a < b ? a : b).clamp(0, reordered.length - 1);
    }
    state = state.copyWith(currentLayerIndex: activeIndex);
    // The stored indices now point at other layers.
    _selectedLayerIndices = const [];
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
    final sourceIds = indices.where((i) => i >= 0 && i < currentFrame.layers.length).toSet().toList()..sort();
    if (sourceIds.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();
    var layers = List<Layer>.from(currentFrame.layers);
    // The copies go in one block above the topmost source, in stack order.
    var insertIndex = sourceIds.last + 1;
    String? lastCreatedId;

    for (final source in [for (final index in sourceIds) layers[index]]) {
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
      layers.insert(insertIndex++, copy);
      lastCreatedId = copy.id;
    }

    layers = [for (final (index, layer) in layers.indexed) layer.copyWith(order: index)];
    _updateCurrentFrame(currentFrame.copyWith(layers: layers));
    state = state.copyWith(
      currentLayerIndex: layers.indexWhere((layer) => layer.id == lastCreatedId),
    );
    _updateProject();
  }

  Future<void> setLayersVisibility(Iterable<int> indices, bool visible) =>
      _updateLayers(indices, (layer) => layer.copyWith(isVisible: visible));

  Future<void> setLayersLocked(Iterable<int> indices, bool locked) =>
      _updateLayers(indices, (layer) => layer.copyWith(isLocked: locked));

  Future<void> setLayersOpacity(Iterable<int> indices, double opacity) =>
      _updateLayers(indices, (layer) => layer.copyWith(opacity: opacity.clamp(0.0, 1.0)));

  Future<void> _updateLayers(
    Iterable<int> indices,
    Layer Function(Layer layer) transform,
  ) async {
    final valid = indices.where((i) => i >= 0 && i < currentFrame.layers.length).toSet();
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

  /// Layers panel drag: moves the layer at [oldIndex] to [newIndex] as one
  /// undo step. When it is part of a multi-selection, the other selected
  /// layers move with it, gathered into one block in their stacking order.
  Future<void> reorderLayers(int oldIndex, int newIndex) async {
    // Commit any floating selection first: it rewrites the current layers.
    _detachSelectionFromLayer();
    final count = currentFrame.layers.length;
    if (oldIndex < 0 || oldIndex >= count) return;
    final selected = selectedLayerIndices;
    final group = selected.length > 1 && selected.contains(oldIndex) ? selected : [oldIndex];
    // The stack as if the dragged layer moved alone; the block lands where it
    // would, after the same number of unselected layers.
    final single = List<int>.generate(count, (i) => i)
      ..remove(oldIndex)
      ..insert(newIndex.clamp(0, count - 1), oldIndex);
    final before = single.takeWhile((i) => i != oldIndex).where((i) => !group.contains(i)).length;
    final others = [
      for (final i in single)
        if (!group.contains(i)) i
    ];
    _applyLayerOrder([...others.take(before), ...group, ...others.skip(before)], group.toSet());
  }

  /// Applies a new stacking order as one undo step. [moved] maps each new
  /// position to an old layer index; [selected] (old indices) stays selected.
  /// Does nothing when the order is unchanged. Callers detach the floating
  /// selection first.
  void _applyLayerOrder(List<int> moved, Set<int> selected) {
    if (Iterable.generate(moved.length).every((i) => moved[i] == i)) return;
    _saveState();
    final layers = currentFrame.layers;
    final activeLayerId = currentLayer.id;
    final reordered = [
      for (final (index, oldIndex) in moved.indexed) layers[oldIndex].copyWith(order: index),
    ];
    _updateCurrentFrame(currentFrame.copyWith(layers: reordered));
    _selectedLayerIndices = [
      for (final (index, oldIndex) in moved.indexed)
        if (selected.contains(oldIndex)) index,
    ];
    state = state.copyWith(currentLayerIndex: reordered.indexWhere((layer) => layer.id == activeLayerId));
    _updateProject();
  }

  /// Merges the layers at [indices] into the lowest of them as one undo
  /// step. That layer keeps its identity and name and gets the composite of
  /// all of them, with effects and opacity baked in; the others are deleted.
  /// Hidden and locked layers are left out. Returns false when fewer than two
  /// layers can merge.
  Future<bool> mergeLayers(Iterable<int> indices) async {
    // Commit any floating selection first so it is part of the merge.
    _detachSelectionFromLayer();
    final layers = currentFrame.layers;
    final merging = indices
        .toSet()
        .where((i) => i >= 0 && i < layers.length && layers[i].isVisible && !layers[i].isLocked)
        .toList()
      ..sort();
    if (merging.length < 2) return false;

    _saveState();
    final targetIndex = merging.first;
    final removed = merging.skip(1).toSet();
    final activeLayerId = currentLayer.id;
    final merged = layers[targetIndex].copyWith(
      pixels: LayerMergeService.composite([for (final i in merging) layers[i]], state.width, state.height),
      effects: const [],
      opacity: 1.0,
    );
    await Future.wait(removed.map((i) => _layerService.deleteLayer(layers[i].layerId)));

    final remaining = [
      for (final (index, layer) in layers.indexed)
        if (index == targetIndex) merged else if (!removed.contains(index)) layer,
    ];
    final reordered = [
      for (final (index, layer) in remaining.indexed) layer.copyWith(order: index),
    ];
    _updateCurrentFrame(currentFrame.copyWith(layers: reordered));
    // The merged layer becomes active when the active one was merged into it;
    // removed layers were all above it, so its index is unchanged.
    final activeIndex = reordered.indexWhere((layer) => layer.id == activeLayerId);
    _selectedLayerIndices = const [];
    state = state.copyWith(currentLayerIndex: activeIndex >= 0 ? activeIndex : targetIndex);
    _updateProject();
    return true;
  }

  /// Merges the active layer into the one below it. Returns false when there
  /// is none, or either is hidden or locked.
  Future<bool> mergeLayerDown() => mergeLayers([state.currentLayerIndex - 1, state.currentLayerIndex]);

  /// Moves the selected layers one step up ([delta] > 0) or down as one undo
  /// step, keeping their relative order. A layer already at the top (or
  /// bottom), or blocked by another selected layer there, stays put.
  Future<void> moveSelectedLayers(int delta) async {
    // Commit any floating selection first: it rewrites the current layers.
    _detachSelectionFromLayer();
    final layers = currentFrame.layers;
    final selected = selectedLayerIndices.toSet();
    // Position in the new stack -> index in the old one.
    final moved = List<int>.generate(layers.length, (i) => i);
    void swap(int a, int b) {
      final t = moved[a];
      moved[a] = moved[b];
      moved[b] = t;
    }

    if (delta > 0) {
      for (var i = moved.length - 2; i >= 0; i--) {
        if (selected.contains(moved[i]) && !selected.contains(moved[i + 1])) swap(i, i + 1);
      }
    } else {
      for (var i = 1; i < moved.length; i++) {
        if (selected.contains(moved[i]) && !selected.contains(moved[i - 1])) swap(i, i - 1);
      }
    }
    _applyLayerOrder(moved, selected);
  }

  /// Activates the layer [delta] steps above (positive) or below the active
  /// one, stopping at the top and bottom.
  void selectAdjacentLayer(int delta) => selectLayer(state.currentLayerIndex + delta);

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
    ref.read(analyticsProvider).logEvent(name: 'effect_applied', parameters: {'effect': effect.type.name});
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
    final sourceLayer = effects == null ? currentLayer : currentLayer.copyWith(effects: List<Effect>.from(effects));
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
      currentLayerIndex: _safeLayerIndex(newFrame),
    );
    _persistEditorSelection();
    _recordProgress(ProgressionEvent.frameAdded);
  }

  /// Append generated animation frames to the source frame's animation state.
  /// Generated frames contain the rendered target layer; the remaining layers
  /// are copied from the source frame so the timeline keeps its composition.
  /// Adds [generatedFrames] as new frames of the source state.
  ///
  /// Each generated frame holds one layer per entry of [sourceLayerIds], in
  /// the same order; those layers of the source frame are replaced and every
  /// other layer is copied unchanged. [activeLayerId] (default: the first
  /// source layer) stays selected. [flattened] means opacity was baked into
  /// the pixels, so layers that received content are reset to full opacity.
  Future<void> addGeneratedEffectFrames(
    List<AnimationFrame> generatedFrames, {
    required int sourceFrameId,
    int? sourceLayerId,
    List<int>? sourceLayerIds,
    int? activeLayerId,
    bool flattened = false,
  }) async {
    if (generatedFrames.isEmpty) return;
    final layerIds = sourceLayerIds ?? [if (sourceLayerId != null) sourceLayerId];
    if (layerIds.isEmpty || layerIds.toSet().length != layerIds.length) {
      throw ArgumentError('Generated frames need distinct source layers');
    }
    final sourceIndex = state.frames.indexWhere((frame) => frame.id == sourceFrameId);
    if (sourceIndex < 0) throw StateError('Source frame no longer exists');
    final source = state.frames[sourceIndex];
    final targetIndices = <int>[];
    for (final id in layerIds) {
      final index = source.layers.indexWhere((layer) => layer.layerId == id);
      if (index < 0) throw StateError('Source layer no longer exists');
      targetIndices.add(index);
    }
    final activeIndex = activeLayerId == null
        ? targetIndices.first
        : source.layers.indexWhere((layer) => layer.layerId == activeLayerId);
    if (activeIndex < 0 || !targetIndices.contains(activeIndex)) {
      throw StateError('Active layer is not part of the generated layers');
    }
    final stateIndex = state.animationStates.indexWhere((item) => item.id == source.stateId);
    if (stateIndex < 0) throw StateError('Animation state no longer exists');
    for (final generated in generatedFrames) {
      if (generated.layers.length != layerIds.length ||
          generated.layers.any((layer) => layer.pixels.length != state.width * state.height)) {
        throw ArgumentError('Generated frame has invalid pixels');
      }
    }

    final firstGeneratedIndex = state.frames.where((frame) => frame.stateId == source.stateId).length;
    var nextOrder = _frameService.calculateNextFrameOrder(state.frames);
    for (final generated in generatedFrames) {
      final layers = <Layer>[
        for (final (index, layer) in source.layers.indexed)
          if (targetIndices.contains(index))
            () {
              final rendered = generated.layers[targetIndices.indexOf(index)].pixels;
              final hasContent = rendered.any((pixel) => pixel != 0);
              return layer.copyWith(
                id: const Uuid().v4(),
                layerId: 0,
                pixels: Uint32List.fromList(rendered),
                effects: const [],
                opacity: flattened && hasContent ? 1.0 : layer.opacity,
              );
            }()
          else
            layer.copyWith(
              id: const Uuid().v4(),
              layerId: 0,
              pixels: Uint32List.fromList(layer.pixels),
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
      currentLayerIndex: activeIndex,
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
      final stateFrames = state.frames.where((f) => f.stateId == animationState.id).toList();
      final selected = stateFrames.where((f) => frameIds.contains(f.id)).map((f) => f.id).toSet();
      if (selected.length == stateFrames.length && stateFrames.isNotEmpty) {
        final keepId = animationState.id == state.currentAnimationState.id ? currentFrame.id : stateFrames.first.id;
        selected.remove(keepId);
      }
      removable.addAll(selected);
    }
    if (removable.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();
    final oldCurrentFrames = state.currentFrames;
    final oldActiveId = currentFrame.id;
    final firstRemovedIndex = oldCurrentFrames.indexWhere((f) => removable.contains(f.id));
    await Future.wait(removable.map(_frameService.deleteFrame));
    final updatedFrames = state.frames.where((f) => !removable.contains(f.id)).toList();
    final newCurrentFrames = updatedFrames.where((f) => f.stateId == state.currentAnimationState.id).toList();
    var activeIndex = newCurrentFrames.indexWhere((f) => f.id == oldActiveId);
    if (activeIndex < 0) {
      activeIndex = firstRemovedIndex.clamp(0, newCurrentFrames.length - 1);
    }
    state = state.copyWith(
      frames: updatedFrames,
      currentFrameIndex: activeIndex,
      currentLayerIndex: _safeLayerIndex(newCurrentFrames[activeIndex]),
    );
    _collapseFrameSelection();
    _updateProject();
  }

  /// Copies [frameIds] as one undo step. Each animation's copies are placed
  /// right after its last copied frame, in timeline order; the active frame
  /// stays active.
  Future<void> duplicateFramesByIds(Iterable<int> frameIds) async {
    final ids = frameIds.toSet();
    if (!state.frames.any((frame) => ids.contains(frame.id))) return;
    // Commit any floating selection first so the copies include it.
    _detachSelectionFromLayer();
    final sources = state.frames.where((frame) => ids.contains(frame.id)).toList();
    _saveState();
    final activeId = currentFrame.id;
    final copiesByState = <int, List<AnimationFrame>>{};
    final lastSourceByState = <int, int>{};
    var nextOrder = _frameService.calculateNextFrameOrder(state.frames);
    for (final source in sources) {
      var created = await _frameService.createFrame(
        projectId: project.id,
        name: 'Copy of ${source.name}',
        stateId: source.stateId,
        width: state.width,
        height: state.height,
        copyFromFrame: source,
        order: nextOrder++,
      );
      created = created.copyWith(duration: source.duration);
      await _frameService.updateFrame(projectId: project.id, frame: created);
      copiesByState.putIfAbsent(source.stateId, () => []).add(created);
      lastSourceByState[source.stateId] = source.id;
    }
    final inserted = [
      for (final frame in state.frames) ...[
        frame,
        if (lastSourceByState[frame.stateId] == frame.id) ...copiesByState[frame.stateId]!,
      ],
    ];
    final nextOrderByState = <int, int>{};
    final updatedFrames = [
      for (final frame in inserted)
        if (copiesByState.containsKey(frame.stateId))
          frame.copyWith(order: nextOrderByState.update(frame.stateId, (o) => o + 1, ifAbsent: () => 0))
        else
          frame,
    ];
    state = state.copyWith(
      frames: updatedFrames,
      currentFrameIndex: updatedFrames
          .where((f) => f.stateId == state.currentAnimationState.id)
          .toList()
          .indexWhere((f) => f.id == activeId),
    );
    _updateProject();
  }

  /// Sets the duration of [frameIds] as one undo step. Does nothing when
  /// none of them changes.
  Future<void> updateFramesDurationByIds(Iterable<int> frameIds, int duration) async {
    final ids = frameIds.toSet();
    final value = math.max(1, duration);
    if (!state.frames.any((frame) => ids.contains(frame.id) && frame.duration != value)) return;
    _saveState();
    final updated = [
      for (final frame in state.frames)
        if (ids.contains(frame.id)) frame.copyWith(duration: value) else frame,
    ];
    state = state.copyWith(frames: updated);
    await Future.wait(updated
        .where((frame) => ids.contains(frame.id))
        .map((frame) => _frameService.updateFrame(projectId: project.id, frame: frame)));
    _updateProject();
  }

  /// Renames [frameId] as one undo step.
  void renameFrame(int frameId, String name) {
    final trimmed = name.trim();
    final index = state.frames.indexWhere((frame) => frame.id == frameId);
    if (index < 0 || trimmed.isEmpty || state.frames[index].name == trimmed) return;
    _saveState();
    state = state.copyWith(frames: [
      for (final frame in state.frames)
        if (frame.id == frameId) frame.copyWith(name: trimmed) else frame,
    ]);
    _updateProject();
  }

  /// Reverses the order of [frameIds] within each animation as one undo
  /// step: the selected slots keep their positions and the frames in them
  /// swap end to end. Unselected frames don't move.
  Future<void> reverseFrames(Iterable<int> frameIds) async {
    final ids = frameIds.toSet();
    final reversedByState = <int, List<AnimationFrame>>{};
    for (final frame in state.frames) {
      if (ids.contains(frame.id)) reversedByState.putIfAbsent(frame.stateId, () => []).add(frame);
    }
    reversedByState.removeWhere((_, frames) => frames.length < 2);
    if (reversedByState.isEmpty) return;

    // The active frame keeps its identity but changes index.
    _detachSelectionFromLayer();
    _saveState();
    final activeId = currentFrame.id;
    final cursors = <int, int>{};
    final swapped = [
      for (final frame in state.frames)
        if (reversedByState[frame.stateId] case final group? when ids.contains(frame.id))
          () {
            final i = cursors.update(frame.stateId, (c) => c + 1, ifAbsent: () => 0);
            return group[group.length - 1 - i];
          }()
        else
          frame,
    ];
    final nextOrder = <int, int>{};
    final updated = [
      for (final frame in swapped)
        if (reversedByState.containsKey(frame.stateId))
          frame.copyWith(order: nextOrder.update(frame.stateId, (o) => o + 1, ifAbsent: () => 0))
        else
          frame,
    ];
    state = state.copyWith(
      frames: updated,
      currentFrameIndex: updated
          .where((f) => f.stateId == state.currentAnimationState.id)
          .toList()
          .indexWhere((f) => f.id == activeId),
    );
    _updateProject();
  }

  /// Moves [frameIds] to the end of animation [stateId] as one undo step,
  /// keeping their order. With [copy], copies them there instead. Frames
  /// already in that animation are skipped. A move never empties an
  /// animation: like delete, it leaves that animation's active (or first)
  /// frame behind. The active frame stays valid; when it moved away, the
  /// nearest remaining frame becomes active.
  Future<void> moveFramesToState(Iterable<int> frameIds, int stateId, {bool copy = false}) async {
    if (!state.animationStates.any((s) => s.id == stateId)) return;
    final ids = frameIds.toSet();
    var sources = [
      for (final frame in state.frames)
        if (ids.contains(frame.id) && frame.stateId != stateId) frame,
    ];
    if (!copy) {
      for (final animationState in state.animationStates) {
        final stateFrames = state.frames.where((f) => f.stateId == animationState.id).toList();
        final leaving = sources.where((f) => f.stateId == animationState.id).toList();
        if (stateFrames.isNotEmpty && leaving.length == stateFrames.length) {
          final keepId = animationState.id == state.currentAnimationState.id ? currentFrame.id : stateFrames.first.id;
          sources = [
            for (final f in sources)
              if (f.id != keepId) f
          ];
        }
      }
    }
    if (sources.isEmpty) return;

    _detachSelectionFromLayer();
    _saveState();
    final oldCurrentFrames = state.currentFrames;
    final oldActiveId = currentFrame.id;
    final firstMovedIndex = oldCurrentFrames.indexWhere((f) => sources.any((s) => s.id == f.id));
    final List<AnimationFrame> arriving;
    if (copy) {
      arriving = [];
      var nextOrder = _frameService.calculateNextFrameOrder(state.frames);
      for (final source in sources) {
        var created = await _frameService.createFrame(
          projectId: project.id,
          name: source.name,
          stateId: stateId,
          width: state.width,
          height: state.height,
          copyFromFrame: source,
          order: nextOrder++,
        );
        created = created.copyWith(duration: source.duration);
        await _frameService.updateFrame(projectId: project.id, frame: created);
        arriving.add(created);
      }
    } else {
      arriving = [for (final source in sources) source.copyWith(stateId: stateId)];
    }
    final movedIds = {for (final source in sources) source.id};
    final touchedStates = {stateId, if (!copy) ...sources.map((f) => f.stateId)};
    final nextOrderByState = <int, int>{};
    final updatedFrames = [
      for (final frame in [
        for (final frame in state.frames)
          if (copy || !movedIds.contains(frame.id)) frame,
        ...arriving,
      ])
        if (touchedStates.contains(frame.stateId))
          frame.copyWith(order: nextOrderByState.update(frame.stateId, (o) => o + 1, ifAbsent: () => 0))
        else
          frame,
    ];
    final newCurrentFrames = updatedFrames.where((f) => f.stateId == state.currentAnimationState.id).toList();
    var activeIndex = newCurrentFrames.indexWhere((f) => f.id == oldActiveId);
    if (activeIndex < 0) activeIndex = firstMovedIndex.clamp(0, newCurrentFrames.length - 1);
    state = state.copyWith(
      frames: updatedFrames,
      currentFrameIndex: activeIndex,
      currentLayerIndex: _safeLayerIndex(newCurrentFrames[activeIndex]),
    );
    _collapseFrameSelection();
    _updateProject();
  }

  /// Moves [draggedIds] as a block next to [targetId] (after it when the block
  /// came from before it, otherwise before it), as one undo step. Only frames
  /// in the target's animation move.
  Future<void> reorderFramesByIds(Set<int> draggedIds, int targetId) async {
    final targetIndexInAll = state.frames.indexWhere((frame) => frame.id == targetId);
    if (targetIndexInAll < 0 || draggedIds.contains(targetId)) return;
    // Commit any floating selection first: it rewrites the current frame.
    _detachSelectionFromLayer();
    final target = state.frames[targetIndexInAll];
    final stateFrames = state.frames.where((f) => f.stateId == target.stateId).toList();
    final dragged = stateFrames.where((f) => draggedIds.contains(f.id)).toList();
    if (dragged.isEmpty) return;
    final oldActiveId = currentFrame.id;
    final targetIndex = stateFrames.indexWhere((f) => f.id == targetId);
    final firstDraggedIndex = stateFrames.indexWhere((f) => draggedIds.contains(f.id));
    final remaining = stateFrames.where((f) => !draggedIds.contains(f.id)).toList();
    var insertIndex = remaining.indexWhere((f) => f.id == targetId);
    if (firstDraggedIndex < targetIndex) insertIndex++;
    remaining.insertAll(insertIndex, dragged);
    if (Iterable.generate(remaining.length).every((i) => remaining[i].id == stateFrames[i].id)) return;
    _saveState();
    final reordered = [
      for (final (index, frame) in remaining.indexed) frame.copyWith(order: index),
    ];
    var cursor = 0;
    final allFrames = [
      for (final frame in state.frames)
        if (frame.stateId == target.stateId) reordered[cursor++] else frame,
    ];
    final currentStateFrames = allFrames.where((f) => f.stateId == state.currentAnimationState.id).toList();
    state = state.copyWith(
      frames: allFrames,
      currentFrameIndex: currentStateFrames.indexWhere((f) => f.id == oldActiveId),
    );
    _updateProject();
  }

  /// Makes [frameId] the only selected frame and the active one.
  void selectFrame(int frameId) {
    if (_activateFrame(frameId)) _collapseFrameSelection();
  }

  bool _activateFrame(int frameId) {
    final index = state.currentFrames.indexWhere((frame) => frame.id == frameId);
    if (index < 0) return false;
    _detachSelectionFromLayer();
    final targetFrame = state.currentFrames[index];
    state = state.copyWith(
      currentFrameIndex: index,
      currentLayerIndex: _safeLayerIndex(targetFrame),
    );
    _persistEditorSelection();
    return true;
  }

  // Timeline multi-selection and the last-used editor area; see
  // [EditorSelection].
  EditorSelectionNotifier get _editorSelectionNotifier => ref.read(editorSelectionProvider(project.id).notifier);
  EditorSelection get editorSelection => ref.read(editorSelectionProvider(project.id));

  /// Frames selected in the timeline: frames of the current animation, always
  /// including the active one.
  Set<int> get selectedFrameIds => editorSelection.resolveFrames(state);

  void setSelectionTarget(EditorSelectionTarget target) =>
      _editorSelectionNotifier.modify((s) => s.copyWith(target: target));

  /// A timeline click on [frameId]. [toggle] adds or removes it (Ctrl/Cmd-click
  /// or long-press), [extendRange] selects from the anchor to it (Shift-click),
  /// otherwise it becomes the only selected frame. Either way it becomes
  /// active. A frame of another animation switches to that animation and is
  /// selected alone.
  void selectFrames(int frameId, {bool toggle = false, bool extendRange = false}) {
    final clicked = state.frames.where((frame) => frame.id == frameId).firstOrNull;
    if (clicked == null) return;
    if (clicked.stateId != state.currentAnimationState.id) {
      selectAnimationState(clicked.stateId);
      toggle = false;
      extendRange = false;
    }
    final result = updateMultiSelection(
      orderedItems: [for (final frame in state.currentFrames) frame.id],
      selected: selectedFrameIds,
      active: currentFrame.id,
      clicked: frameId,
      anchor: editorSelection.frameAnchorId,
      toggle: toggle,
      extendRange: extendRange,
    );
    _activateFrame(result.active);
    _editorSelectionNotifier.modify((s) => s.copyWith(
          frameIds: result.selected,
          frameAnchorId: () => result.anchor,
          target: EditorSelectionTarget.frames,
        ));
  }

  /// Shift+, / Shift+.: extends the frame selection from the anchor to the
  /// frame [delta] steps from the active one, stopping at either end.
  void extendFrameSelection(int delta) {
    final frames = state.currentFrames;
    final index = (state.currentFrameIndex + delta).clamp(0, frames.length - 1);
    if (index == state.currentFrameIndex) return;
    selectFrames(frames[index].id, extendRange: true);
  }

  /// Moves the selected frames one step left ([delta] < 0) or right as one
  /// undo step. A non-contiguous selection is gathered into one block.
  Future<void> moveSelectedFrames(int delta) async {
    final ids = selectedFrameIds;
    final frames = state.currentFrames;
    final positions = [
      for (final (index, frame) in frames.indexed)
        if (ids.contains(frame.id)) index,
    ];
    final target = delta < 0 ? positions.first - 1 : positions.last + 1;
    if (target < 0 || target >= frames.length) return;
    await reorderFramesByIds(ids, frames[target].id);
  }

  void selectAllFrames() {
    _editorSelectionNotifier.modify((s) => s.copyWith(
          frameIds: {for (final frame in state.currentFrames) frame.id},
          frameAnchorId: () => currentFrame.id,
          target: EditorSelectionTarget.frames,
        ));
  }

  void _collapseFrameSelection() {
    final active = currentFrame.id;
    _editorSelectionNotifier.modify((s) => s.copyWith(frameIds: {active}, frameAnchorId: () => active));
  }

  /// Deletes what the last-used editor area has selected: the selected pixels
  /// on the canvas, the selected layers or the selected frames. Returns false
  /// when there was nothing to act on (the canvas without a pixel selection),
  /// so callers can fall back to another action.
  Future<bool> deleteSelected() async {
    switch (editorSelection.target) {
      case EditorSelectionTarget.frames:
        await removeFramesByIds(selectedFrameIds);
      case EditorSelectionTarget.layers:
        await removeLayers(selectedLayerIndices);
      case EditorSelectionTarget.canvas:
        if (state.selectionState == null) return false;
        clearSelectionArea();
    }
    return true;
  }

  /// Duplicates what the last-used editor area has selected: the selected
  /// pixels into a new layer, the selected layers or the selected frames.
  /// Returns false when there was nothing to act on.
  Future<bool> duplicateSelected() async {
    switch (editorSelection.target) {
      case EditorSelectionTarget.frames:
        await duplicateFramesByIds(selectedFrameIds);
      case EditorSelectionTarget.layers:
        await duplicateLayers(selectedLayerIndices);
      case EditorSelectionTarget.canvas:
        if (state.selectionState == null) return false;
        await selectionToNewLayer();
    }
    return true;
  }

  void nextFrame() {
    final nextIndex = (state.currentFrameIndex + 1) % state.currentFrames.length;
    _detachSelectionFromLayer();
    final targetFrame = state.currentFrames[nextIndex];
    state = state.copyWith(
      currentFrameIndex: nextIndex,
      currentLayerIndex: _safeLayerIndex(targetFrame),
    );
    _collapseFrameSelection();
    _persistEditorSelection();
  }

  void previousFrame() {
    final prevIndex = (state.currentFrameIndex - 1 + state.currentFrames.length) % state.currentFrames.length;
    _detachSelectionFromLayer();
    final targetFrame = state.currentFrames[prevIndex];
    state = state.copyWith(
      currentFrameIndex: prevIndex,
      currentLayerIndex: _safeLayerIndex(targetFrame),
    );
    _collapseFrameSelection();
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
    final currentFirstFrame = state.currentFrames.isNotEmpty ? state.currentFrames.first : null;
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
    final sourceIndex = _animationService.findStateIndex(state.animationStates, sourceStateId);
    if (sourceIndex < 0) return;
    final sourceState = state.animationStates[sourceIndex];

    // Copies of copies share one base name and get a counter, and the result
    // stays within the 100-character column limit.
    final base = sourceState.name.replaceFirst(RegExp(r'(\s*\(copy(?: \d+)?\))+$'), '');
    final taken = state.animationStates.map((s) => s.name).toSet();
    String copyName(int n) {
      final suffix = n == 1 ? ' (copy)' : ' (copy $n)';
      final room = 100 - suffix.length;
      return '${base.length > room ? base.substring(0, room) : base}$suffix';
    }

    var copyNumber = 1;
    while (taken.contains(copyName(copyNumber))) {
      copyNumber++;
    }

    final newState = await _animationService.createAnimationState(
      projectId: project.id,
      name: copyName(copyNumber),
      frameRate: sourceState.frameRate,
    );

    // Copy all frames belonging to the source state
    final sourceFrames = state.frames.where((f) => f.stateId == sourceStateId).toList();
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
    _persistEditorSelection();
  }

  Future<void> addTemplate(Template template) async {
    if (template.builderParts.isNotEmpty) {
      for (final part in template.builderParts) {
        await addTemplate(part);
      }
      return;
    }
    if (template.layers.isNotEmpty) {
      for (final source in template.layers) {
        final order = _layerService.calculateNextLayerOrder(currentFrame.layers);
        final layer = await _layerService.createLayer(
            projectId: project.id,
            frameId: currentFrame.id,
            name: source.name,
            width: state.width,
            height: state.height,
            order: order);
        final pixels = _templateService.applyTemplateToLayer(
            template:
                Template(name: source.name, width: template.width, height: template.height, pixels: source.pixels),
            layerPixels: layer.pixels,
            layerWidth: state.width,
            layerHeight: state.height);
        _insertLayerAboveCurrent(layer.copyWith(
            pixels: pixels, isVisible: source.isVisible, isLocked: source.isLocked, opacity: source.opacity));
      }
      _updateProject();
      _recordProgress(ProgressionEvent.templateUsed);
      return;
    }
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
    final index = _animationService.findStateIndex(state.animationStates, stateId);
    if (index >= 0) {
      final targetFrames = state.frames.where((frame) => frame.stateId == stateId).toList();
      final layerIndex = targetFrames.isEmpty ? 0 : _safeLayerIndex(targetFrames.first);
      _detachSelectionFromLayer();
      state = state.copyWith(
        currentAnimationStateIndex: index,
        currentFrameIndex: 0,
        currentLayerIndex: layerIndex,
      );
      if (targetFrames.isNotEmpty) {
        _collapseFrameSelection();
        _persistEditorSelection();
      }
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
    if (oldIndex < 0 || oldIndex >= current.length || newIndex < 0 || newIndex >= current.length) {
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

    if (cached == null || cachedLayer == null || cachedBounds == null || cachedRegion == null) {
      // Fallback when transform was not explicitly started (e.g. external call)
      _saveState();
      final extraTargets = _extraSelectionTargets;
      if (extraTargets.isNotEmpty) {
        _updateLayersPixels({
          for (final i in [state.currentLayerIndex, ...extraTargets])
            i: _selectionService.moveSelectedPixels(
              region: sel.region,
              layerPixels: currentFrame.layers[i].pixels,
              delta: delta,
            ),
        });
      } else {
        final newPixels = _selectionService.moveSelectedPixels(
          region: sel.region,
          layerPixels: currentLayer.pixels,
          delta: delta,
        );
        _updateCurrentLayerPixels(newPixels);
      }
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
    final dx = _totalMoveOffset.dx.round();
    final dy = _totalMoveOffset.dy.round();
    final movedRegion = cachedRegion.shifted(_totalMoveOffset);
    final result = _stampMovedPixels(cachedLayer, cached, cachedBounds, dx, dy);

    _updateCurrentLayerPreviewPixels(
      result,
      extra: {
        for (final c in _extraTransformLayers) c.layerIndex: _stampMovedPixels(c.base, c.source, cachedBounds, dx, dy),
      },
    );
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
    if (cached == null || cachedLayer == null || cachedBounds == null || cachedRegion == null) {
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
    if (constrainedTargetBounds.width <= 0 || constrainedTargetBounds.height <= 0) {
      return;
    }

    // Target size is bounded by the canvas so a handle dragged far past the
    // edge can't balloon the resize/placement cost into the millions of
    // pixels per drag frame. (Overhang is squashed rather than clipped — an
    // acceptable trade for keeping the transform interactive.)
    final targetW = constrainedTargetBounds.width.round().clamp(1, state.width);
    final targetH = constrainedTargetBounds.height.round().clamp(1, state.height);

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

    final extra = <int, Uint32List>{};
    for (final c in _extraTransformLayers) {
      c.floating = PixelUtils.resize(c.source, srcW, srcH, targetW, targetH, _selectionTransformInterpolation, 0);
      extra[c.layerIndex] = _placeTransformedPixels(c.base, c.floating, constrainedTargetBounds, targetW, targetH);
    }

    _updateCurrentLayerPreviewPixels(resultPixels, extra: extra);
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

  // The last RotSprite rotation previewed with nearest neighbour during a
  // drag; [endTransformSelection] renders it properly once.
  ({double angle, Offset? pivot, SelectionRegion? region})? _pendingRotSprite;

  /// Rotates the floating pixels by [angle] from where the transform
  /// started. With the RotSprite setting, drag previews ([finalPass] false)
  /// use nearest neighbour, which is cheap enough per frame, and the drag's
  /// end renders RotSprite once.
  void rotateSelectionNew(
    double angle, {
    Offset? pivot,
    SelectionRegion? region,
    bool finalPass = false,
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

    final useRotSprite = _transformInterpolationSetting == TransformInterpolation.rotSprite;
    _pendingRotSprite = useRotSprite && !finalPass ? (angle: angle, pivot: pivot, region: region) : null;
    Uint32List rotate(Uint32List source) => useRotSprite && finalPass
        ? rotSpriteWithBounds(source, srcW, srcH, angle, cachedBounds, rotatedBounds, rotCenter)
        : PixelUtils.applyRotationWithBounds(
            source,
            srcW,
            srcH,
            angle,
            cachedBounds,
            rotatedBounds,
            rotCenter,
            _selectionTransformInterpolation,
            0,
          );

    final rotatedPixels = rotate(cached);
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

    final extra = <int, Uint32List>{};
    for (final c in _extraTransformLayers) {
      final rotated = rotate(c.source);
      if (rotated.isEmpty) continue;
      c.floating = rotated;
      extra[c.layerIndex] = _placeTransformedPixels(c.base, rotated, bufferBounds, targetW, targetH);
    }

    _updateCurrentLayerPreviewPixels(resultPixels, extra: extra);
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
    final anchor = state.selectionState?.anchorPoint ?? currentLayer.anchorPoint;
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

  // The selection the last deselect dropped, for Reselect.
  SelectionRegion? _lastDeselectedRegion;

  /// A selection change made by the user (a selection tool, select all,
  /// deselect...), recorded as its own undo step. Internal ops that move or
  /// replace the selection as part of a bigger edit use [setSelection].
  void selectRegion(SelectionRegion? region) {
    final current = state.selectionState?.region;
    if (identical(region, current)) return;
    _undoRedoService.saveSelection(state.selectionState);
    if (region == null) _lastDeselectedRegion = current;
    setSelection(region);
    state = state.copyWith(canUndo: canUndo, canRedo: canRedo);
  }

  /// Whether [reselect] has a selection to bring back.
  bool get canReselect => _lastDeselectedRegion != null;

  /// Ctrl+Shift+D: selects again what the last deselect dropped.
  void reselect() {
    final region = _lastDeselectedRegion;
    if (region != null) selectRegion(region);
  }

  /// Selects the opaque pixels of the layer at [index] (Ctrl/Cmd-click on a
  /// layer thumbnail). Does nothing for an empty layer.
  void selectLayerPixels(int index) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    final layer = currentFrame.layers[index];
    if (layer.pixels.isEmpty) return;
    final region = _selectionService.createAutoSelection(
      pixels: layer.processedPixels(state.width, state.height),
      w: state.width,
      h: state.height,
    );
    if (region.bounds == Rect.zero) return;
    selectRegion(region);
  }

  void autoSelectLayer() => selectLayerPixels(state.currentLayerIndex);

  void selectAll() {
    final region = _selectionService.selectAll();
    selectRegion(region);
  }

  void invertSelectionRegion() {
    final sel = state.selectionState;
    if (sel == null) return;

    final inverted = _selectionService.invertSelection(sel.region);
    selectRegion(inverted);
  }

  void growSelectionRegion({int by = 1}) {
    final sel = state.selectionState;
    if (sel == null) return;

    final grown = _selectionService.growSelection(sel.region, by: by);
    selectRegion(grown.bounds.isEmpty ? null : grown);
  }

  void shrinkSelectionRegion({int by = 1}) {
    final sel = state.selectionState;
    if (sel == null) return;

    final shrunk = _selectionService.shrinkSelection(sel.region, by: by);
    selectRegion(shrunk.bounds.isEmpty ? null : shrunk);
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
    final extraTargets = _extraSelectionTargets;
    if (extraTargets.isEmpty) {
      _updateCurrentLayerPixels(result.pixels);
    } else {
      // The region's geometry is the same for every layer, so each result
      // lands in the same [result.region].
      _updateLayersPixels({
        state.currentLayerIndex: result.pixels,
        for (final i in extraTargets)
          if (PixelTransformService.transformSelection(
            layerPixels: currentFrame.layers[i].pixels,
            canvasWidth: state.width,
            canvasHeight: state.height,
            region: region,
            transform: transform,
          )
              case final r?)
            i: r.pixels,
      });
    }
    setSelection(result.region);
  }

  /// Flips or rotates whole layers about the canvas centre in the current
  /// frame. Locked and procedural (effect-generated) layers are skipped.
  Future<void> transformLayers(
    Iterable<int> indices,
    PixelTransform transform,
  ) async {
    final targets = indices.where((i) => i >= 0 && i < currentFrame.layers.length).where((i) {
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
    final before = state;
    final previousState = _undoRedoService.undo(state);
    if (previousState != null) {
      state = previousState;
      _dropStaleSelectionCapture();
      _syncRowsAfterHistoryStep(before, state);
      _updateProject();
    }
  }

  void redo() {
    final before = state;
    final nextState = _undoRedoService.redo(state);
    if (nextState != null) {
      state = nextState;
      _dropStaleSelectionCapture();
      _syncRowsAfterHistoryStep(before, state);
      _updateProject();
    }
  }

  /// Frame and layer ops write their rows right away (create, delete), but
  /// undo and redo only swap the in-memory state, and the project save only
  /// updates rows that exist. This mirrors a history step in the database:
  /// frames and layers it dropped are deleted, ones it brought back are
  /// rewritten under their old ids. Ids are never reused (AUTOINCREMENT), and
  /// the repo queues these writes in order with the project save.
  void _syncRowsAfterHistoryStep(PixelCanvasState before, PixelCanvasState after) {
    if (identical(before.frames, after.frames)) return;
    void run(Future<void> write, String what) {
      unawaited(write.catchError((Object error, StackTrace stack) {
        ErrorReportService.instance.report(error, stack, operation: 'editor.history.$what');
      }));
    }

    final beforeFrames = {for (final frame in before.frames) frame.id: frame};
    final afterIds = {for (final frame in after.frames) frame.id};
    for (final id in beforeFrames.keys) {
      if (id != 0 && !afterIds.contains(id)) run(_projectRepo.deleteFrame(id), 'deleteFrame');
    }
    for (final frame in after.frames) {
      if (frame.id == 0) continue;
      final old = beforeFrames[frame.id];
      if (old == null) {
        run(_projectRepo.restoreFrame(project.id, frame), 'restoreFrame');
        continue;
      }
      if (identical(old.layers, frame.layers)) continue;
      final oldLayerIds = {for (final layer in old.layers) layer.layerId};
      final newLayerIds = {for (final layer in frame.layers) layer.layerId};
      for (final id in oldLayerIds.difference(newLayerIds)) {
        if (id != 0) run(_projectRepo.deleteLayer(id), 'deleteLayer');
      }
      for (final layer in frame.layers) {
        if (layer.layerId != 0 && !oldLayerIds.contains(layer.layerId)) {
          run(_projectRepo.restoreLayer(project.id, frame.id, layer), 'restoreLayer');
        }
      }
    }
  }

  // Tool and color operations
  void setCurrentTool(PixelTool tool) {
    if (state.currentTool != tool) {
      ref.read(analyticsProvider).logEvent(name: 'tool_used', parameters: {'tool': tool.name});
    }
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
    _logExport('pxv');
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
    _logExport('png');
  }

  void _logExport(String format) {
    ref.read(analyticsProvider).logEvent(name: 'export', parameters: {
      'format': format,
      'width': project.width,
      'height': project.height,
    });
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
    _logExport('gif');
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
    _recordProgress(ProgressionEvent.imageExported);
    _logExport('spritesheet');
  }

  /// Counts an action toward quests. In-memory only, safe on hot paths.
  void _recordProgress(ProgressionEvent event) {
    final progression = ref.read(progressionProvider.notifier);
    progression.record(event);
    // Coming back to an older piece counts for the "old project" bonus quest.
    if (event == ProgressionEvent.strokeCompleted &&
        project.createdAt.isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
      progression.record(ProgressionEvent.oldProjectStroke);
    }
  }

  Future<void> importImageAsBackground(BuildContext context) async {
    final imageBytes = await _importExportService.importImageAsBackground(context: context);
    if (imageBytes != null) {
      ref.read(backgroundImageProvider.notifier).update((state) => state.copyWith(image: imageBytes));

      // Extract dominant colors and publish to palette panel
      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded != null) {
        final palette = PixelArtConverter.extractPaletteFromImage(decoded, maxColors: 32);
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
    return state.currentTool == PixelTool.eraser ? Colors.transparent : state.currentColor;
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
    _dropStaleSelectionCapture();

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

  /// Shows a transform frame: [newPixels] on the active layer and [extra]
  /// (frame index → pixels) on the other transformed layers, in one update.
  void _updateCurrentLayerPreviewPixels(Uint32List newPixels, {Map<int, Uint32List> extra = const {}}) {
    _transformPreviewDirty = true;
    if (extra.isEmpty) {
      _updateCurrentLayer(currentLayer.copyWith(pixels: newPixels));
      return;
    }
    final updated = List<Layer>.from(currentFrame.layers);
    updated[state.currentLayerIndex] = currentLayer.copyWith(pixels: newPixels);
    for (final MapEntry(key: index, value: pixels) in extra.entries) {
      if (index < updated.length) updated[index] = updated[index].copyWith(pixels: pixels);
    }
    _updateCurrentFrame(currentFrame.copyWith(layers: updated));
  }

  /// [base] with the floating [floating] pixels (laid out over [bounds])
  /// stamped [dx], [dy] away from where they were captured.
  Uint32List _stampMovedPixels(Uint32List base, Uint32List floating, Rect bounds, int dx, int dy) {
    final result = Uint32List.fromList(base);
    final bw = bounds.width.ceil();
    final bh = bounds.height.ceil();
    final origLeft = bounds.left.floor();
    final origTop = bounds.top.floor();

    for (int ly = 0; ly < bh; ly++) {
      for (int lx = 0; lx < bw; lx++) {
        final srcIdx = ly * bw + lx;
        if (srcIdx >= floating.length || floating[srcIdx] == 0) continue;
        final nx = origLeft + lx + dx;
        final ny = origTop + ly + dy;
        if (nx >= 0 && nx < state.width && ny >= 0 && ny < state.height) {
          result[ny * state.width + nx] = floating[srcIdx];
        }
      }
    }
    return result;
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

  void resizeSelection(SelectionRegion region, SelectionRegion oldRegion, Rect b, Offset? center) {
    resizeSelectionNew(region.bounds, region: region);
  }

  void rotateSelection(SelectionRegion region, SelectionRegion oldRegion, double angle, Offset? center) {
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
    _transformSessionStart = null;
    _pendingRotSprite = null;
    _transformCachedPixels = null;
    _transformCachedLayerWithoutSelection = null;
    _transformCachedBounds = null;
    _transformCachedRegion = null;
    _transformCachedAnchor = null;
    _totalMoveOffset = Offset.zero;
    _transformPreviewDirty = false;
    _extraTransformLayers = const [];
  }

  Offset _remapAnchorToBounds(
    Offset anchor,
    Rect sourceBounds,
    Rect targetBounds,
  ) {
    final normalizedX = sourceBounds.width == 0 ? 0.5 : (anchor.dx - sourceBounds.left) / sourceBounds.width;
    final normalizedY = sourceBounds.height == 0 ? 0.5 : (anchor.dy - sourceBounds.top) / sourceBounds.height;

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

  TransformInterpolation get _transformInterpolationSetting =>
      ref.read(editorSettingsNotifierProvider).transformInterpolation;

  int get _selectionTransformInterpolation => _transformInterpolationSetting.pixelUtilsValue;
}

/// One extra layer of a multi-layer selection transform.
class _LayerTransformCache {
  _LayerTransformCache.capture(this.layerIndex, _SelectionCapture capture)
      : base = capture.basePixels,
        source = capture.selectionPixels,
        floating = capture.selectionPixels;

  final int layerIndex;

  /// The layer's pixels with the selection cleared.
  final Uint32List base;

  /// The floating pixels this transform session started from.
  Uint32List source;

  /// The floating pixels as last transformed; the next session starts here.
  Uint32List floating;
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
