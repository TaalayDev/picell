import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/template.dart';
import '../../data.dart';
import '../pixel_point.dart';
import '../effects/effects.dart';
import '../pixel_canvas_state.dart';
import '../tools.dart';
import 'pixel_controller_provider.dart';

part 'pixel_canvas_provider.g.dart';

@riverpod
class PixelCanvasNotifier extends _$PixelCanvasNotifier {
  @override
  PixelCanvasState build(Project project) {
    return ref.watch(pixelDrawControllerProvider(project));
  }

  final StreamController<PixelDrawEvent> _eventController = StreamController.broadcast();
  late Stream<PixelDrawEvent> eventStream = _eventController.stream;

  PixelDrawController get _controller => ref.read(pixelDrawControllerProvider(project).notifier);

  // Expose frequently used getters
  AnimationFrame get currentFrame => _controller.currentFrame;
  Layer get currentLayer => _controller.currentLayer;
  bool get canUndo => _controller.canUndo;
  bool get canRedo => _controller.canRedo;

  // Tool and color operations
  set currentTool(PixelTool tool) => _controller.setCurrentTool(tool);
  PixelTool get currentTool => state.currentTool;

  set currentColor(Color color) => _controller.setCurrentColor(color);
  Color get currentColor => state.currentColor;

  // Drawing operations
  void startDrawing() => _controller.startBatchDrawing();
  void endDrawing() => _controller.endBatchDrawing();
  void setPixel(int x, int y) => _controller.batchSetPixel(x, y);
  void fillPixels(List<PixelPoint<int>> points) => _controller.batchFillPixels(points);
  void fill(int x, int y) => _controller.floodFill(x, y);
  void clear() => _controller.clearCanvas();
  Color getPixelColor(int x, int y) => _controller.getPixelColor(x, y);
  void applyGradient(List<Color> gradientColors) => _controller.applyGradient(gradientColors);

  // Drag operations
  void startDrag() => _controller.startDrag();
  void dragPixels(double scale, Offset offset) => _controller.dragPixels(scale, offset);
  void endDrag() => _controller.endDrag();

  // Layer operations
  Future<void> addLayer(String name) => _controller.addLayer(name);
  Future<void> addLayerWithPixels(Layer layer) => _controller.addLayerWithPixels(layer);
  Future<void> removeLayer(int index) => _controller.removeLayer(index);
  Future<int> duplicateLayer(int index) => _controller.duplicateLayer(index);
  void selectLayer(int index) => _controller.selectLayer(index);
  Future<void> toggleLayerVisibility(int index) => _controller.toggleLayerVisibility(index);
  Future<void> reorderLayers(int oldIndex, int newIndex) => _controller.reorderLayers(oldIndex, newIndex);
  void updateLayer(Layer updatedLayer) => _controller.updateLayer(updatedLayer);
  Layer getCurrentLayer() => _controller.currentLayer;

  // Frame operations
  Future<void> addFrame(String name, {int? copyFrame, int? stateId}) =>
      _controller.addFrame(name, copyFrameId: copyFrame, stateId: stateId);
  Future<void> removeFrame(int index) => _controller.removeFrame(index);
  void selectFrame(int frameId) => _controller.selectFrame(frameId);
  void nextFrame() => _controller.nextFrame();
  void prevFrame() => _controller.previousFrame();

  Future<void> updateFrame(int index, AnimationFrame frame) => _controller.updateFrame(index, frame);
  Future<void> reorderFrames(int oldIndex, int newIndex) => _controller.reorderFrames(oldIndex, newIndex);

  // Animation state operations
  Future<void> addAnimationState(String name, int frameRate) => _controller.addAnimationState(name, frameRate);
  Future<void> removeAnimationState(int stateId) => _controller.removeAnimationState(stateId);
  void selectAnimationState(int stateId) => _controller.selectAnimationState(stateId);

  // Selection operations
  void setSelection(List<PixelPoint<int>>? selection) => _controller.setSelection(selection);
  void moveSelection(List<PixelPoint<int>> selection, Point delta) => _controller.moveSelection(selection, delta);
  void clearSelection() {
    _eventController.add(const ClearSelectionEvent());
    _controller.clearSelection();
  }

  void addTemplate(Template template) => _controller.addTemplate(template);

  // Undo/Redo operations
  void undo() => _controller.undo();
  void redo() => _controller.redo();

  void setCurrentModifier(PixelModifier modifier) {
    _controller.setCurrentModifier(modifier);
  }

  void pushEvent(PixelDrawEvent event) {
    _eventController.add(event);
  }

  // Import/Export operations
  Future<void> exportJson(BuildContext context) => _controller.exportProjectAsJson(context);
  Future<void> exportImage(
    BuildContext context, {
    bool background = false,
    double? exportWidth,
    double? exportHeight,
  }) =>
      _controller.exportImage(
        context: context,
        withBackground: background,
        exportWidth: exportWidth,
        exportHeight: exportHeight,
      );
  Future<void> share(BuildContext context) => _controller.shareProject(context);
  Future<void> importImage(BuildContext context, {bool background = false}) {
    if (background) {
      return _controller.importImageAsBackground(context);
    } else {
      return _controller.importImageAsLayer(context);
    }
  }

  Future<void> exportAnimation(
    BuildContext context, {
    bool background = false,
    double? exportWidth,
    double? exportHeight,
  }) =>
      _controller.exportAnimation(
        context: context,
        frames: state.currentFrames,
        withBackground: background,
        exportWidth: exportWidth,
        exportHeight: exportHeight,
      );

  Future<void> exportSpriteSheet(
    BuildContext context, {
    required int columns,
    required int spacing,
    required bool includeAllFrames,
    bool withBackground = false,
    Color backgroundColor = Colors.white,
    double? exportWidth,
    double? exportHeight,
  }) =>
      _controller.exportSpriteSheet(
        context: context,
        columns: columns,
        spacing: spacing,
        includeAllFrames: includeAllFrames,
        withBackground: withBackground,
        backgroundColor: backgroundColor,
        exportWidth: exportWidth,
        exportHeight: exportHeight,
      );

  // Layer effects operations
  void addLayerEffect(Effect effect) {
    final updatedLayer = _controller.currentLayer.copyWith(
      effects: [..._controller.currentLayer.effects, effect],
    );
    updateLayer(updatedLayer);
  }

  void updateLayerEffect(int effectIndex, Effect updatedEffect) {
    final effects = [..._controller.currentLayer.effects];
    effects[effectIndex] = updatedEffect;
    final updatedLayer = _controller.currentLayer.copyWith(effects: effects);
    updateLayer(updatedLayer);
  }

  void removeLayerEffect(int effectIndex) {
    final effects = [..._controller.currentLayer.effects];
    effects.removeAt(effectIndex);
    final updatedLayer = _controller.currentLayer.copyWith(effects: effects);
    updateLayer(updatedLayer);
  }

  void clearLayerEffects() {
    final updatedLayer = _controller.currentLayer.copyWith(effects: []);
    updateLayer(updatedLayer);
  }

  /// Set the pixels of the current layer directly (used when importing from tilemap)
  void setLayerPixels(Uint32List pixels) {
    final updatedLayer = _controller.currentLayer.copyWith(pixels: pixels);
    updateLayer(updatedLayer);
  }

  void resizeSelection(
    List<PixelPoint<int>> selection,
    List<PixelPoint<int>> oldSelection,
    Rect newBounds,
    Offset? center,
  ) {
    _controller.resizeSelection(selection, oldSelection, newBounds, center);

    final newSelection = _createSelectionFromBounds(newBounds);
    setSelection(newSelection);
  }

  void rotateSelection(
    List<PixelPoint<int>> selection,
    List<PixelPoint<int>> oldSelection,
    double angle,
    Offset? center,
  ) {
    _controller.rotateSelection(selection, oldSelection, angle, center);
  }

  /// Call at the start of a rotation or resize operation to cache the original pixels
  void startTransformSelection(List<PixelPoint<int>> selection) {
    _controller.startTransformSelection(selection);
  }

  /// Call at the end of a rotation or resize operation to clear the cache
  void endTransformSelection() {
    _controller.endTransformSelection();
  }

  List<PixelPoint<int>> _createSelectionFromBounds(Rect bounds) {
    final selection = <PixelPoint<int>>[];

    final minX = bounds.left.round().clamp(0, state.width - 1);
    final maxX = bounds.right.round().clamp(1, state.width);
    final minY = bounds.top.round().clamp(0, state.height - 1);
    final maxY = bounds.bottom.round().clamp(1, state.height);

    for (int y = minY; y < maxY; y++) {
      for (int x = minX; x < maxX; x++) {
        selection.add(PixelPoint<int>(x, y));
      }
    }

    return selection;
  }
}
