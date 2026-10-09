import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/services/pixel_transform_service.dart';
import 'package:picell/ui/widgets/shortcuts_wrapper.dart';

void main() {
  Future<List<PixelTransform>> press(
    WidgetTester tester,
    List<LogicalKeyboardKey> keys,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final received = <PixelTransform>[];
    await tester.pumpWidget(MaterialApp(
      home: ShortcutsWrapper(
        onUndo: () {},
        onRedo: () {},
        onSave: () {},
        onTransform: received.add,
        child: const SizedBox.expand(),
      ),
    ));
    await tester.pump();
    for (final k in keys) {
      await tester.sendKeyDownEvent(k);
    }
    for (final k in keys.reversed) {
      await tester.sendKeyUpEvent(k);
    }
    debugDefaultTargetPlatformOverride = null;
    return received;
  }

  const shift = LogicalKeyboardKey.shiftLeft;

  testWidgets('Shift+H / Shift+V flip', (tester) async {
    expect(await press(tester, [shift, LogicalKeyboardKey.keyH]), [PixelTransform.flipHorizontal]);
    expect(await press(tester, [shift, LogicalKeyboardKey.keyV]), [PixelTransform.flipVertical]);
  });

  testWidgets('Shift+R / Shift+L / Shift+X rotate', (tester) async {
    expect(await press(tester, [shift, LogicalKeyboardKey.keyR]), [PixelTransform.rotate90Clockwise]);
    expect(await press(tester, [shift, LogicalKeyboardKey.keyL]), [PixelTransform.rotate90CounterClockwise]);
    expect(await press(tester, [shift, LogicalKeyboardKey.keyX]), [PixelTransform.rotate180]);
  });

  testWidgets('plain keys and Ctrl+Shift+H do not transform', (tester) async {
    expect(await press(tester, [LogicalKeyboardKey.keyH]), isEmpty);
    expect(await press(tester, [LogicalKeyboardKey.keyL]), isEmpty);
    expect(
      await press(tester, [LogicalKeyboardKey.metaLeft, shift, LogicalKeyboardKey.keyH]),
      isEmpty,
    );
  });
}
