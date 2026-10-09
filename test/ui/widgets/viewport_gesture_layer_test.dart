import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/canvas/pixel_viewport_controller.dart';
import 'package:picell/ui/widgets/painter/pixel_viewport_gesture_layer.dart';
import 'package:picell/ui/widgets/painter/pixel_viewport_transform.dart';

void main() {
  Future<PixelViewportController> pump(WidgetTester tester, {double scale = 1.0, Offset offset = Offset.zero}) async {
    final controller = PixelViewportController(initialScale: scale, initialOffset: offset)
      ..origin = const Offset(300, 200); // 400x400 canvas centred in 1000x800
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PixelViewportGestureLayer(
          controller: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => Center(
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: PixelViewportTransform(
                  controller: controller,
                  child: const SizedBox(key: ValueKey('canvas'), width: 400, height: 400),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    return controller;
  }

  Offset canvasTopLeft(WidgetTester tester) => tester.getTopLeft(find.byKey(const ValueKey('canvas')));

  testWidgets('trackpad pan moves the canvas by exactly the pan delta', (tester) async {
    await pump(tester, scale: 2.0, offset: const Offset(37, -12));
    final before = canvasTopLeft(tester);
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(pointer.panZoomStart(const Offset(900, 100)));
    await tester.pump();
    await tester.sendEventToBinding(pointer.panZoomUpdate(const Offset(900, 100), pan: const Offset(10, 5)));
    await tester.pump();
    final after = canvasTopLeft(tester);
    expect(after - before, const Offset(10, 5));
  });

  testWidgets('zoom anchored on a moving focal point stays under the fingers', (tester) async {
    final c = await pump(tester, scale: 1.3, offset: const Offset(-40, 25));
    const start = Offset(420, 380);
    final localBefore = (start - canvasTopLeft(tester)) / c.scale;
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(pointer.panZoomStart(start));
    await tester.pump();
    await tester.sendEventToBinding(pointer.panZoomUpdate(start, pan: const Offset(60, -30), scale: 0.7));
    await tester.pump();
    final localAfter = (start + const Offset(60, -30) - canvasTopLeft(tester)) / c.scale;
    expect((localAfter - localBefore).distance, lessThan(0.5));
  });

  testWidgets('trackpad pinch keeps the point under the fingers fixed', (tester) async {
    final c = await pump(tester);
    const focal = Offset(700, 300);
    final origin = canvasTopLeft(tester);
    final localBefore = (focal - origin) / c.scale; // canvas-local point under the fingers
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(pointer.panZoomStart(focal));
    await tester.pump();
    await tester.sendEventToBinding(pointer.panZoomUpdate(focal, scale: 1.5));
    await tester.pump();
    final localAfter = (focal - canvasTopLeft(tester)) / c.scale;
    expect((localAfter - localBefore).distance, lessThan(0.5));
  });

  testWidgets('two-finger touch starts without a jump and pans by its displacement', (tester) async {
    final c = await pump(tester, scale: 2.0, offset: const Offset(37, -12));
    final before = canvasTopLeft(tester);
    final first = await tester.startGesture(const Offset(430, 350), pointer: 21);
    final second = await tester.startGesture(const Offset(590, 350), pointer: 22);
    await tester.pump();
    expect(canvasTopLeft(tester), before);
    await first.moveBy(const Offset(-5, -30));
    await second.moveBy(const Offset(-5, -30));
    await tester.pump();
    expect(c.scale, closeTo(2.0, 1e-9));
    expect((canvasTopLeft(tester) - before - const Offset(-5, -30)).distance, lessThan(0.001));
    await first.up();
    await second.up();
  });

  testWidgets('small pinch during a two-finger drag anchors to the canvas origin', (tester) async {
    final c = await pump(tester);
    const focal = Offset(510, 350);
    final localBefore = (focal - canvasTopLeft(tester)) / c.scale;
    final first = await tester.startGesture(const Offset(430, 350), pointer: 21);
    final second = await tester.startGesture(const Offset(590, 350), pointer: 22);
    await first.moveTo(const Offset(385, 320));
    await second.moveTo(const Offset(625, 320));
    await tester.pump();
    final localAfter = (focal + const Offset(-5, -30) - canvasTopLeft(tester)) / c.scale;
    expect((localAfter - localBefore).distance, lessThan(0.001));
    await first.up();
    await second.up();
  });

}
