import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/screens/rig_editor/rig_gif_preview.dart';

// A 1x1 transparent GIF.
final _gif = Uint8List.fromList(const [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff,
  0x21, 0xf9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02,
  0x02, 0x44, 0x01, 0x00, 0x3b,
]);

void main() {
  testWidgets('saving the GIF asks the gate first; previewing never does', (tester) async {
    var asked = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => RigGifPreviewDialog.show(context, bytes: _gif, fileName: 'a.gif', onBeforeSave: () async {
            asked++;
            return false;
          }),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rig-gif-preview')), findsOneWidget);
    expect(asked, 0);

    await tester.tap(find.byKey(const ValueKey('save-rig-gif')));
    await tester.pumpAndSettle();
    // Refused: still looking at the preview, nothing saved.
    expect(asked, 1);
    expect(find.byKey(const ValueKey('rig-gif-preview')), findsOneWidget);
  });
}
