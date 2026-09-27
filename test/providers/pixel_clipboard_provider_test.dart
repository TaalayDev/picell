import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/providers/pixel_clipboard_provider.dart';

void main() {
  PixelClipboardData clipboardData() => PixelClipboardData(
        pixels: Uint32List(4),
        width: 2,
        height: 2,
        region: SelectionRegion(
          path: Path()..addRect(const Rect.fromLTWH(0, 0, 2, 2)),
          bounds: const Rect.fromLTWH(0, 0, 2, 2),
          shape: SelectionShape.rectangle,
        ),
      );

  test('take consumes clipboard data immediately', () {
    final notifier = EditorClipboardNotifier();
    final data = clipboardData();
    notifier.store(data);

    expect(notifier.take(), same(data));
    expect(notifier.state, isNull);
  });

  test('failed paste can restore consumed data without replacing a new copy',
      () {
    final notifier = EditorClipboardNotifier();
    final original = clipboardData();
    final newer = clipboardData();
    notifier.store(original);
    notifier.take();

    notifier.restoreIfEmpty(original);
    expect(notifier.state, same(original));

    notifier.store(newer);
    notifier.restoreIfEmpty(original);
    expect(notifier.state, same(newer));
  });
}
