import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/ui/widgets/shortcuts_wrapper.dart';

void main() {
  late List<String> calls;
  late TextEditingController text;

  Future<void> pump(WidgetTester tester, {bool withTextField = false}) async {
    calls = [];
    text = TextEditingController(text: '120');
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ShortcutsWrapper(
          onUndo: () {},
          onRedo: () {},
          onSave: () {},
          maxLayers: 9,
          onZoom100: () => calls.add('zoom100'),
          onZoomFit: () => calls.add('zoomFit'),
          onLayerChanged: (i) => calls.add('layer $i'),
          onDelete: () => calls.add('delete'),
          onDuplicate: () => calls.add('duplicate'),
          onSelectAdjacentLayer: (d) => calls.add('layerStep $d'),
          onMoveLayers: (d) => calls.add('moveLayers $d'),
          onPreviousFrame: () => calls.add('prevFrame'),
          onNextFrame: () => calls.add('nextFrame'),
          onExtendFrameSelection: (d) => calls.add('extendFrames $d'),
          onMoveFrames: (d) => calls.add('moveFrames $d'),
          onNewFrame: () => calls.add('newFrame'),
          child: withTextField ? TextField(key: const ValueKey('field'), controller: text) : const SizedBox.expand(),
        ),
      ),
    ));
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, List<LogicalKeyboardKey> keys) async {
    for (final k in keys) {
      await tester.sendKeyDownEvent(k);
    }
    for (final k in keys.reversed) {
      await tester.sendKeyUpEvent(k);
    }
    await tester.pump();
  }

  // Cmd is the shortcut modifier on macOS.
  final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);
  const shift = LogicalKeyboardKey.shiftLeft;
  const cmd = LogicalKeyboardKey.metaLeft;

  testWidgets(', and . step frames; Shift extends the selection', (tester) async {
    await pump(tester);
    await press(tester, [LogicalKeyboardKey.comma]);
    await press(tester, [LogicalKeyboardKey.period]);
    await press(tester, [shift, LogicalKeyboardKey.comma]);
    await press(tester, [shift, LogicalKeyboardKey.period]);
    expect(calls, ['prevFrame', 'nextFrame', 'extendFrames -1', 'extendFrames 1']);
  }, variant: macOS);

  testWidgets('Cmd+Arrow moves frames and Shift+N adds one', (tester) async {
    await pump(tester);
    await press(tester, [cmd, LogicalKeyboardKey.arrowLeft]);
    await press(tester, [cmd, LogicalKeyboardKey.arrowRight]);
    await press(tester, [shift, LogicalKeyboardKey.keyN]);
    expect(calls, ['moveFrames -1', 'moveFrames 1', 'newFrame']);
  }, variant: macOS);

  testWidgets('Shift+[ ] step layers and Cmd+[ ] move them', (tester) async {
    await pump(tester);
    await press(tester, [shift, LogicalKeyboardKey.bracketLeft]);
    await press(tester, [shift, LogicalKeyboardKey.bracketRight]);
    await press(tester, [cmd, LogicalKeyboardKey.bracketLeft]);
    await press(tester, [cmd, LogicalKeyboardKey.bracketRight]);
    expect(calls, ['layerStep -1', 'layerStep 1', 'moveLayers -1', 'moveLayers 1']);
  }, variant: macOS);

  testWidgets('Delete and Backspace delete; Cmd+J duplicates', (tester) async {
    await pump(tester);
    await press(tester, [LogicalKeyboardKey.delete]);
    await press(tester, [LogicalKeyboardKey.backspace]);
    await press(tester, [cmd, LogicalKeyboardKey.keyJ]);
    expect(calls, ['delete', 'delete', 'duplicate']);
  }, variant: macOS);

  testWidgets('1 picks a layer and Cmd+1 zooms to 100%', (tester) async {
    await pump(tester);
    await press(tester, [LogicalKeyboardKey.digit1]);
    await press(tester, [cmd, LogicalKeyboardKey.digit1]);
    await press(tester, [cmd, LogicalKeyboardKey.digit0]);
    expect(calls, ['layer 0', 'zoom100', 'zoomFit']);
  }, variant: macOS);

  testWidgets('frame keys and Backspace leave a focused text field alone', (tester) async {
    await pump(tester, withTextField: true);
    await tester.tap(find.byKey(const ValueKey('field')));
    await tester.pump();
    text.selection = const TextSelection.collapsed(offset: 3);

    await press(tester, [LogicalKeyboardKey.backspace]);
    await press(tester, [LogicalKeyboardKey.comma]);
    await press(tester, [LogicalKeyboardKey.delete]);
    await press(tester, [cmd, LogicalKeyboardKey.arrowLeft]);

    expect(calls, isEmpty);
    expect(text.text, '12', reason: 'Backspace still edits the field');
  }, variant: macOS);
}
