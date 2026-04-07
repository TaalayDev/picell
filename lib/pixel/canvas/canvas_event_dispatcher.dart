import 'dart:async';

import '../pixel_canvas_state.dart' as canvas_events;
import '../tools/texture_brush_tool.dart';
import 'canvas_input_adapter.dart';
import 'tool_drawing_manager.dart';

class PixelCanvasEventDispatcher {
  PixelCanvasEventDispatcher({
    required PixelCanvasInputAdapter inputAdapter,
    required ToolDrawingManager toolManager,
    Stream<canvas_events.PixelDrawEvent>? eventStream,
  }) : _inputAdapter = inputAdapter,
       _toolManager = toolManager,
       _eventStream = eventStream;

  PixelCanvasInputAdapter _inputAdapter;
  ToolDrawingManager _toolManager;
  Stream<canvas_events.PixelDrawEvent>? _eventStream;
  StreamSubscription<canvas_events.PixelDrawEvent>? _eventSubscription;
  bool _attached = false;

  Stream<canvas_events.PixelDrawEvent>? get eventStream => _eventStream;

  set eventStream(Stream<canvas_events.PixelDrawEvent>? value) {
    if (identical(_eventStream, value)) return;
    _eventStream = value;
    if (_attached) {
      _subscribe();
    }
  }

  void update({
    PixelCanvasInputAdapter? inputAdapter,
    ToolDrawingManager? toolManager,
    Stream<canvas_events.PixelDrawEvent>? eventStream,
  }) {
    if (inputAdapter != null) {
      _inputAdapter = inputAdapter;
    }
    if (toolManager != null) {
      _toolManager = toolManager;
    }
    if (eventStream != null || _eventStream != null) {
      this.eventStream = eventStream;
    }
  }

  void attach() {
    if (_attached) return;
    _attached = true;
    _subscribe();
  }

  void detach() {
    _attached = false;
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  void _subscribe() {
    _eventSubscription?.cancel();
    final stream = _eventStream;
    if (stream == null) {
      _eventSubscription = null;
      return;
    }

    _eventSubscription = stream.listen(_handleEvent);
  }

  void _handleEvent(canvas_events.PixelDrawEvent event) {
    if (event is canvas_events.ClosePenPathEvent) {
      _inputAdapter.finishPenPath();
      return;
    }

    if (event is canvas_events.TextureBrushPatternEvent) {
      unawaited(
        _toolManager.setTextureBrush(
          textureId: event.texture.id,
          blendMode: event.blendMode,
          mode: event.isFill ? TextureBrushMode.fill : TextureBrushMode.brush,
          fillMode: event.isFill ? TextureFillMode.stretch : TextureFillMode.center,
        ),
      );
      return;
    }

    if (event is canvas_events.ClearSelectionEvent) {
      _inputAdapter.clearLocalSelection();
    }
  }
}
