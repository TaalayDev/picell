import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/pixel/tools/gradient_tool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 16×16 canvas drawn at 160×160, so 1 canvas pixel = 10 widget pixels and
  // handles (14 screen px at zoom 1) are grabbable within 1.4 canvas pixels.
  final layer = Layer(
    layerId: 1,
    id: 'a',
    name: 'A',
    pixels: Uint32List(16 * 16),
  );

  PixelDrawDetails at(double x, double y) => PixelDrawDetails(
        position: Offset(x * 10, y * 10),
        size: const Size(160, 160),
        width: 16,
        height: 16,
        currentLayer: layer,
        color: Colors.black,
        modifier: null,
        onPixelsUpdated: (_) {},
      );

  late List<String> log;
  late GradientTool tool;

  setUp(() {
    log = [];
    tool = GradientTool(
      onGradientPreview: (s, e) => log.add('preview ${s.dx},${s.dy}->${e.dx},${e.dy}'),
      onGradientApply: (s, e) => log.add('apply ${s.dx},${s.dy}->${e.dx},${e.dy}'),
      onGradientClear: () => log.add('clear'),
      onGradientCancel: () => log.add('cancel'),
    );
  });

  void drag(double x0, double y0, double x1, double y1) {
    tool.onStart(at(x0, y0));
    tool.onMove(at(x1, y1));
    tool.onEnd(at(x1, y1));
  }

  test('a drag leaves a pending gradient without applying', () {
    drag(2, 2, 10, 2);
    expect(tool.hasPendingGradient, isTrue);
    expect(tool.end, const Offset(10, 2));
    expect(log.where((l) => l.startsWith('apply')), isEmpty);
  });

  test('dragging a handle edits that endpoint only', () {
    drag(2, 2, 10, 2);
    drag(10.5, 2.5, 12, 6); // grab end handle
    expect(tool.start, const Offset(2, 2));
    expect(tool.end, const Offset(12, 6));
    drag(2.4, 2, 1, 1); // grab start handle
    expect(tool.start, const Offset(1, 1));
    expect(log.where((l) => l.startsWith('apply')), isEmpty);
  });

  test('commit applies once and clears', () {
    drag(2, 2, 10, 2);
    log.clear();
    expect(tool.commit(), isTrue);
    expect(log, ['apply 2.0,2.0->10.0,2.0', 'clear']);
    expect(tool.isActive, isFalse);
    expect(tool.commit(), isFalse);
  });

  test('cancel drops without applying', () {
    drag(2, 2, 10, 2);
    log.clear();
    expect(tool.cancel(), isTrue);
    expect(log, ['cancel']);
    expect(tool.isActive, isFalse);
  });

  test('a new drag elsewhere commits the previous one when it ends', () {
    drag(2, 2, 10, 2);
    log.clear();
    tool.onStart(at(5, 12));
    tool.onMove(at(14, 12));
    expect(log.where((l) => l.startsWith('apply')), isEmpty, reason: 'not committed mid-drag');
    tool.onEnd(at(14, 12));
    expect(log, contains('apply 2.0,2.0->10.0,2.0'));
    expect(log.last, 'preview 5.0,12.0->14.0,12.0');
    expect(tool.start, const Offset(5, 12));
  });

  test('a click outside the handles commits without starting a new one', () {
    drag(2, 2, 10, 2);
    log.clear();
    drag(6, 12, 6, 12);
    expect(log.where((l) => !l.startsWith('preview')), ['apply 2.0,2.0->10.0,2.0', 'clear']);
    expect(tool.isActive, isFalse);
  });

  test('a lone click does nothing', () {
    drag(6, 6, 6, 6);
    expect(log.last, 'cancel');
    expect(tool.isActive, isFalse);
  });

  test('cancelDrag restores the previously pending gradient', () {
    drag(2, 2, 10, 2);
    tool.onStart(at(5, 12));
    tool.onMove(at(14, 12));
    tool.cancelDrag();
    expect(tool.hasPendingGradient, isTrue);
    expect(tool.start, const Offset(2, 2));
    expect(log.last, 'preview 2.0,2.0->10.0,2.0');
    expect(log.where((l) => l.startsWith('apply')), isEmpty);
  });

  test('handle hit area shrinks in canvas pixels as zoom grows', () {
    var zoom = 1.0;
    tool = GradientTool(
      onGradientPreview: (_, __) {},
      onGradientApply: (_, __) => log.add('apply'),
      onGradientClear: () {},
      zoomLevel: () => zoom,
    );
    drag(2, 2, 10, 2);
    zoom = 10; // 100 screen px per canvas pixel → 0.75 px minimum radius
    drag(11, 2, 12, 2); // 1 px away: misses the handle → new gradient
    expect(log, ['apply']);
  });
}
