import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/rig/rig.dart';
import '../../../pixel/rig/rig_editor_controller.dart';

/// The rig editor's canvas: the rest-pose sprite with the skeleton drawn on
/// top, plus pan/zoom and the select / create-bone interactions.
///
/// One finger (or the mouse) drives the active tool; two fingers pan and
/// zoom; the scroll wheel pans, and zooms while Ctrl/Cmd is held.
class RigCanvas extends StatefulWidget {
  const RigCanvas({super.key, required this.controller, required this.image});

  final RigEditorController controller;

  /// The composited rest pose, or null while it is still being prepared.
  final ui.Image? image;

  @override
  State<RigCanvas> createState() => RigCanvasState();
}

class RigCanvasState extends State<RigCanvas> {
  static const double _minScale = 1;
  static const double _maxScale = 128;

  /// Pointer slop for grabbing handles, in screen pixels.
  static const double _grabRadius = 14;

  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _viewport = Size.zero;
  bool _fitted = false;

  /// Set once the user pans or zooms; until then the canvas keeps itself
  /// fitted when its viewport changes (a panel opening, a window resize).
  bool _userMoved = false;

  // Active one-finger interaction.
  _Drag? _drag;
  _PoseDrag? _poseDrag;
  _IkDrag? _ikDrag;
  _PlacementDrag? _placementDrag;
  Offset? _draftHead;
  Offset? _draftTail;
  String? _draftParent;

  // Raw pointer tracking. GestureDetector's scale recognizer only starts
  // after a touch-slop drag, which would grab and draw from the wrong pixel
  // and swallow plain taps, so the tool is driven from pointer-down.
  final Map<int, Offset> _pointers = {};
  int? _toolPointer;
  int? _panPointer;
  bool _pinching = false;
  double _pinchStartDistance = 1;
  double _scaleAtStart = 1;
  Offset _offsetAtStart = Offset.zero;
  Offset _focalAtStart = Offset.zero;

  RigEditorController get c => widget.controller;

  /// Fits the whole canvas in view with a margin.
  void fit() {
    if (_viewport.isEmpty) return;
    _userMoved = false;
    final s = math.min(_viewport.width / c.width, _viewport.height / c.height) * 0.9;
    setState(() {
      _scale = s.clamp(_minScale, _maxScale);
      _offset = Offset(
        (_viewport.width - c.width * _scale) / 2,
        (_viewport.height - c.height * _scale) / 2,
      );
    });
  }

  Offset _toCanvas(Offset screen) => (screen - _offset) / _scale;

  void _zoomAbout(Offset focal, double newScale) {
    _userMoved = true;
    newScale = newScale.clamp(_minScale, _maxScale);
    final canvasPoint = _toCanvas(focal);
    setState(() {
      _scale = newScale;
      _offset = focal - canvasPoint * newScale;
    });
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      if (e.buttons & (kMiddleMouseButton | kSecondaryMouseButton) != 0) {
        _panPointer = e.pointer;
      } else {
        _toolPointer = e.pointer;
        _beginToolDrag(_toCanvas(e.localPosition));
      }
    } else if (_pointers.length == 2) {
      // A second finger turns the gesture into navigation.
      _cancelToolDrag();
      _toolPointer = null;
      _panPointer = null;
      _pinching = true;
      _beginPinch();
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_pinching) {
      if (_pointers.length >= 2) _updatePinch();
    } else if (e.pointer == _panPointer) {
      _userMoved = true;
      setState(() => _offset += e.delta);
    } else if (e.pointer == _toolPointer) {
      _updateToolDrag(_toCanvas(e.localPosition));
    }
  }

  void _onPointerUp(PointerEvent e, {required bool cancelled}) {
    _pointers.remove(e.pointer);
    if (e.pointer == _toolPointer) {
      _toolPointer = null;
      cancelled ? _cancelToolDrag() : _endToolDrag();
    }
    if (e.pointer == _panPointer) _panPointer = null;
    if (_pinching && _pointers.length < 2) _pinching = false;
  }

  (Offset, double) _pinchState() {
    final pts = _pointers.values.take(2).toList();
    return ((pts[0] + pts[1]) / 2, math.max((pts[0] - pts[1]).distance, 1));
  }

  void _beginPinch() {
    _userMoved = true;
    final (focal, distance) = _pinchState();
    _pinchStartDistance = distance;
    _focalAtStart = focal;
    _scaleAtStart = _scale;
    _offsetAtStart = _offset;
  }

  void _updatePinch() {
    final (focal, distance) = _pinchState();
    final newScale = (_scaleAtStart * distance / _pinchStartDistance).clamp(_minScale, _maxScale);
    final canvasAtFocal = (_focalAtStart - _offsetAtStart) / _scaleAtStart;
    setState(() {
      _scale = newScale;
      _offset = focal - canvasAtFocal * newScale;
    });
  }

  // ── Tool interactions ────────────────────────────────────────────────────

  void _beginToolDrag(Offset p) {
    final tolerance = _grabRadius / _scale;
    // While a preset is being placed, the pointer only handles its box.
    if (c.placement != null) {
      final handle = c.placementHandleAt(p, tolerance);
      if (handle != null) _placementDrag = _PlacementDrag(handle, start: p);
      return;
    }
    if (c.mode == RigMode.animate && _beginIkDrag(p, tolerance)) return;
    switch (c.tool) {
      case RigTool.select:
        final hit = c.hitTest(p, tolerance);
        c.selectBone(hit?.boneId);
        // Reshaping the skeleton is a setup edit; animate mode only selects.
        if (hit == null || c.mode == RigMode.animate) return;
        c.beginGesture();
        _drag = _Drag(hit, start: p);
      case RigTool.rotate:
      case RigTool.move:
        // Pose the bone under the pointer, or else the selected one, so the
        // drag can start anywhere once a bone is picked.
        final hit = c.hitTest(p, tolerance);
        if (hit != null) c.selectBone(hit.boneId);
        final id = c.selectedBoneId;
        final shown = id == null ? null : c.displayBone(id);
        if (id == null || shown == null) return;
        c.beginGesture();
        _poseDrag = c.tool == RigTool.rotate
            ? _PoseDrag.rotate(
                id,
                center: shown.head,
                startAngle: (p - shown.head).direction,
                startRotation: c.poseOf(id).rotation,
                sign: c.rotationSign(id),
              )
            : _PoseDrag.move(id, start: p, startTranslation: c.poseOf(id).translation);
      case RigTool.createBone:
        // Starting anywhere on an existing bone makes the new one its child.
        final attach = c.attachPoint(p, tolerance);
        setState(() {
          _draftParent = attach.parentId;
          _draftHead = attach.head;
          _draftTail = attach.head;
        });
    }
  }

  /// Starts dragging an IK target: by its ring, or - with the rotate and
  /// move tools - by grabbing any bone that an IK chain is steering, which
  /// pulls the chain's target along. Returns whether a drag started.
  bool _beginIkDrag(Offset p, double tolerance) {
    final hit = c.hitTest(p, tolerance);
    if (hit == null) return false;

    IkChain? chain;
    if (hit.part == RigHitPart.ikTarget) {
      chain = c.ikChain(hit.chainId);
    } else if (c.tool != RigTool.select && c.isIkDriven(hit.boneId)) {
      chain = c.ikChainsOf(hit.boneId).where((x) => c.ikTarget(x.id) != null).firstOrNull;
    }
    final handle = chain == null ? null : c.ikHandle(chain);
    if (chain == null || handle == null) return false;

    c.selectIkChain(chain.id);
    c.beginGesture();
    // Keep the grab point: the target moves with the pointer instead of
    // jumping under it.
    _ikDrag = _IkDrag(chain.id, grabOffset: handle - p);
    return true;
  }

  void _updateToolDrag(Offset p) {
    final placing = _placementDrag;
    if (placing != null) {
      if (placing.handle == PlacementHandle.move) {
        final total = p - placing.start;
        final wanted = Offset(total.dx.roundToDouble(), total.dy.roundToDouble());
        c.movePlacement(wanted - placing.applied);
        placing.applied = wanted;
      } else {
        c.dragPlacementHandle(placing.handle, p);
      }
      return;
    }
    final ik = _ikDrag;
    if (ik != null) {
      c.setIkTarget(ik.chainId, p + ik.grabOffset);
      return;
    }
    final pose = _poseDrag;
    if (pose != null) {
      _updatePoseDrag(pose, p);
      return;
    }
    final drag = _drag;
    if (drag != null) {
      final id = drag.hit.boneId;
      if (drag.hit.part == RigHitPart.tail) {
        c.setBoneTail(id, p);
      } else {
        // Move by the whole-pixel distance travelled so far.
        final total = p - drag.start;
        final wanted = Offset(total.dx.roundToDouble(), total.dy.roundToDouble());
        if (wanted != drag.applied) {
          c.moveBone(id, wanted - drag.applied);
          drag.applied = wanted;
        }
      }
      return;
    }
    if (_draftHead != null) {
      setState(() => _draftTail = c.snapToPixel(p));
    }
  }

  void _updatePoseDrag(_PoseDrag drag, Offset p) {
    if (drag.isRotation) {
      final offset = p - drag.center;
      // Too close to the joint the angle is noise.
      if (offset.distance < 0.3) return;
      var step = offset.direction - drag.lastAngle;
      // Unwrap so crossing the +-180 degree seam doesn't jump a full turn.
      while (step > math.pi) {
        step -= 2 * math.pi;
      }
      while (step < -math.pi) {
        step += 2 * math.pi;
      }
      drag.accumulated += step;
      drag.lastAngle = offset.direction;
      c.setPose(drag.boneId, rotation: drag.startRotation + drag.sign * drag.accumulated * 180 / math.pi);
    } else {
      final total = p - drag.start;
      final wanted = Offset(total.dx.roundToDouble(), total.dy.roundToDouble());
      c.setPose(drag.boneId, translation: drag.startTranslation + c.toLocalDelta(drag.boneId, wanted));
    }
  }

  void _endToolDrag() {
    _placementDrag = null;
    if (_drag != null || _poseDrag != null || _ikDrag != null) {
      c.endGesture();
      _drag = null;
      _poseDrag = null;
      _ikDrag = null;
    }
    final head = _draftHead, tail = _draftTail;
    if (head != null && tail != null) {
      c.addBone(head: head, tail: tail, parentId: _draftParent);
    }
    _clearDraft();
  }

  void _cancelToolDrag() {
    _placementDrag = null;
    if (_drag != null || _poseDrag != null || _ikDrag != null) {
      c.endGesture();
      _drag = null;
      _poseDrag = null;
      _ikDrag = null;
    }
    _clearDraft();
  }

  void _clearDraft() {
    if (_draftHead == null && _draftTail == null && _draftParent == null) return;
    setState(() {
      _draftHead = null;
      _draftTail = null;
      _draftParent = null;
    });
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed) {
      _zoomAbout(e.localPosition, _scale * math.exp(-e.scrollDelta.dy / 200));
    } else {
      _userMoved = true;
      setState(() => _offset -= e.scrollDelta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final resized = _viewport != box.biggest;
      _viewport = box.biggest;
      if ((!_fitted || (resized && !_userMoved)) && !_viewport.isEmpty) {
        _fitted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) fit();
        });
      }
      final theme = Theme.of(context);
      return ClipRect(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: (e) => _onPointerUp(e, cancelled: false),
          onPointerCancel: (e) => _onPointerUp(e, cancelled: true),
          onPointerSignal: _onPointerSignal,
          child: MouseRegion(
            cursor: c.tool == RigTool.createBone ? SystemMouseCursors.precise : MouseCursor.defer,
            child: CustomPaint(
              size: Size.infinite,
              painter: _RigPainter(
                controller: c,
                image: widget.image,
                scale: _scale,
                offset: _offset,
                draftHead: _draftHead,
                draftTail: _draftTail,
                background: theme.colorScheme.surface,
                gridColor: theme.dividerColor,
                boneColor: theme.colorScheme.primary,
                selectedColor: theme.colorScheme.secondary,
                ikColor: theme.colorScheme.tertiary,
                jointFill: theme.colorScheme.surface,
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// A drag of the box a skeleton preset is being placed in.
class _PlacementDrag {
  _PlacementDrag(this.handle, {required this.start});
  final PlacementHandle handle;
  final Offset start;

  /// Whole-pixel offset already applied when moving.
  Offset applied = Offset.zero;
}

/// A drag of an IK chain's target.
class _IkDrag {
  _IkDrag(this.chainId, {required this.grabOffset});
  final String chainId;

  /// Target minus pointer when the drag began.
  final Offset grabOffset;
}

/// A rotate or move drag on a bone in animate mode.
class _PoseDrag {
  _PoseDrag.rotate(
    this.boneId, {
    required this.center,
    required double startAngle,
    required this.startRotation,
    required this.sign,
  })  : isRotation = true,
        lastAngle = startAngle,
        start = Offset.zero,
        startTranslation = Offset.zero;

  _PoseDrag.move(this.boneId, {required this.start, required this.startTranslation})
      : isRotation = false,
        center = Offset.zero,
        lastAngle = 0,
        startRotation = 0,
        sign = 1;

  final String boneId;
  final bool isRotation;

  // Rotation.
  final Offset center;
  final double startRotation;
  final double sign;
  double lastAngle;
  double accumulated = 0;

  // Move.
  final Offset start;
  final Offset startTranslation;
}

class _Drag {
  _Drag(this.hit, {required this.start});
  final RigHit hit;
  final Offset start;

  /// Whole-pixel offset already applied to the bone.
  Offset applied = Offset.zero;
}

class _RigPainter extends CustomPainter {
  _RigPainter({
    required this.controller,
    required this.image,
    required this.scale,
    required this.offset,
    required this.draftHead,
    required this.draftTail,
    required this.background,
    required this.gridColor,
    required this.boneColor,
    required this.selectedColor,
    required this.ikColor,
    required this.jointFill,
  }) : super(repaint: controller);

  final RigEditorController controller;
  final ui.Image? image;
  final double scale;
  final Offset offset;
  final Offset? draftHead;
  final Offset? draftTail;
  final Color background, gridColor, boneColor, selectedColor, ikColor, jointFill;

  Offset _s(Offset canvasPoint) => canvasPoint * scale + offset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = controller.width, h = controller.height;
    final area = Rect.fromLTWH(offset.dx, offset.dy, w * scale, h * scale);

    canvas.drawRect(area, Paint()..color = background);
    _paintChecker(canvas, area);

    final img = image;
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        area,
        Paint()..filterQuality = FilterQuality.none,
      );
    }

    if (scale >= 8) {
      final grid = Paint()
        ..color = gridColor.withValues(alpha: 0.5)
        ..strokeWidth = 0.5;
      for (var x = 0; x <= w; x++) {
        canvas.drawLine(Offset(area.left + x * scale, area.top), Offset(area.left + x * scale, area.bottom), grid);
      }
      for (var y = 0; y <= h; y++) {
        canvas.drawLine(Offset(area.left, area.top + y * scale), Offset(area.right, area.top + y * scale), grid);
      }
    }
    canvas.drawRect(
      area,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = gridColor
        ..strokeWidth = 1,
    );

    final animating = controller.mode == RigMode.animate;
    for (final d in controller.displayBones) {
      final id = d.bone.id;
      _paintBone(canvas, d.head, d.tail, selected: id == controller.selectedBoneId, hasParts: _hasParts(id));
      if (animating && controller.keyAt(id, controller.time) != null) {
        _paintKeyMarker(canvas, _s(d.head));
      }
    }

    if (animating) {
      for (final chain in controller.rig.ikChains) {
        _paintIkHandle(canvas, chain);
      }
    }

    final placement = controller.placement;
    if (placement != null) _paintPlacement(canvas, placement);

    final head = draftHead, tail = draftTail;
    if (head != null && tail != null) {
      _paintBone(canvas, head, tail, selected: true, hasParts: true, draft: true);
    }
  }

  /// The box a preset is being fitted to, with its handles and a preview of
  /// the bones as they would land.
  void _paintPlacement(Canvas canvas, PresetPlacement placement) {
    final box = Rect.fromPoints(_s(placement.box.topLeft), _s(placement.box.bottomRight));
    canvas.drawRect(box, Paint()..color = ikColor.withValues(alpha: 0.08));
    canvas.drawRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ikColor,
    );

    for (final b in controller.placementGhost) {
      final a = _s(b.head), z = _s(b.tail);
      canvas.drawLine(a, z, Paint()..color = Colors.black.withValues(alpha: 0.5)..strokeWidth = 4..strokeCap = StrokeCap.round);
      canvas.drawLine(a, z, Paint()..color = ikColor..strokeWidth = 2..strokeCap = StrokeCap.round);
      canvas.drawCircle(a, 3.5, Paint()..color = jointFill);
      canvas.drawCircle(
        a,
        3.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ikColor,
      );
    }

    // Handles: the corners and the middle of each edge.
    final handles = [
      box.topLeft,
      box.topCenter,
      box.topRight,
      box.centerLeft,
      box.centerRight,
      box.bottomLeft,
      box.bottomCenter,
      box.bottomRight,
    ];
    for (final h in handles) {
      final r = Rect.fromCenter(center: h, width: 9, height: 9);
      canvas.drawRect(r, Paint()..color = jointFill);
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ikColor,
      );
    }
  }

  /// The ring a chain's target is grabbed by. Solid while the chain is on
  /// (it has target keys), faint while it is only waiting for its first one.
  /// A thin line shows how far the chain falls short of an unreachable target.
  void _paintIkHandle(Canvas canvas, IkChain chain) {
    final handle = controller.ikHandle(chain);
    if (handle == null) return;
    final at = _s(handle);
    final active = controller.ikTarget(chain.id) != null;
    final selected = controller.selectedIkChain?.id == chain.id;
    final alpha = active ? 1.0 : 0.55;

    if (active) {
      final tip = controller.displayBone(chain.tipBoneId)?.tail;
      if (tip != null && (tip - handle).distance > 0.6) {
        canvas.drawLine(
          _s(tip),
          at,
          Paint()
            ..color = ikColor.withValues(alpha: 0.7)
            ..strokeWidth = 1,
        );
      }
    }

    final radius = selected ? 8.0 : 7.0;
    canvas.drawCircle(at, radius + 1.5, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 3 : 2
        ..color = ikColor.withValues(alpha: alpha),
    );
    final cross = Paint()
      ..color = ikColor.withValues(alpha: alpha)
      ..strokeWidth = 1.5;
    canvas.drawLine(at - const Offset(3, 0), at + const Offset(3, 0), cross);
    canvas.drawLine(at - const Offset(0, 3), at + const Offset(0, 3), cross);
  }

  /// A small diamond beside a joint that has a keyframe on the current frame.
  void _paintKeyMarker(Canvas canvas, Offset at) {
    final c = at + const Offset(10, -10);
    final path = Path()
      ..moveTo(c.dx, c.dy - 4)
      ..lineTo(c.dx + 4, c.dy)
      ..lineTo(c.dx, c.dy + 4)
      ..lineTo(c.dx - 4, c.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = selectedColor);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  bool _hasParts(String boneId) => controller.rig.parts.any((p) => p.boneId == boneId);

  void _paintChecker(Canvas canvas, Rect area) {
    final cell = math.max(scale, 6.0);
    final light = Paint()..color = Colors.white.withValues(alpha: 0.04);
    canvas.save();
    canvas.clipRect(area);
    for (var y = 0; y * cell < area.height; y++) {
      for (var x = 0; x * cell < area.width; x++) {
        if ((x + y).isEven) continue;
        canvas.drawRect(Rect.fromLTWH(area.left + x * cell, area.top + y * cell, cell, cell), light);
      }
    }
    canvas.restore();
  }

  void _paintBone(Canvas canvas, Offset head, Offset tail,
      {required bool selected, required bool hasParts, bool draft = false}) {
    final a = _s(head), b = _s(tail);
    final color = selected ? selectedColor : boneColor;
    final alpha = draft ? 0.7 : (hasParts ? 1.0 : 0.6);

    // A dark casing keeps the line readable over any sprite colours.
    final casing = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = selected ? 5 : 4
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = selected ? 3 : 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, casing);
    canvas.drawLine(a, b, line);

    // Tip: a small tick across the line so direction is readable.
    final dir = b - a;
    if (dir.distance > 0) {
      final n = Offset(-dir.dy, dir.dx) / dir.distance * 4;
      canvas.drawLine(b - n, b + n, line);
    }

    canvas.drawCircle(a, selected ? 6 : 5, Paint()..color = jointFill);
    canvas.drawCircle(
      a,
      selected ? 6 : 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RigPainter old) =>
      old.image != image ||
      old.scale != scale ||
      old.offset != offset ||
      old.draftHead != draftHead ||
      old.draftTail != draftTail ||
      old.boneColor != boneColor ||
      old.selectedColor != selectedColor ||
      old.ikColor != ikColor ||
      old.background != background;
}
