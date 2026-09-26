import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/ui/widgets/panel_select_all_region.dart';

void main() {
  testWidgets('Ctrl+A is handled by the last focused panel', (tester) async {
    var firstCount = 0;
    var secondCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            PanelSelectAllRegion(
              onSelectAll: () => firstCount++,
              child: const ColoredBox(
                key: ValueKey('first-panel'),
                color: Colors.transparent,
                child: SizedBox(width: 100, height: 100),
              ),
            ),
            PanelSelectAllRegion(
              onSelectAll: () => secondCount++,
              child: const ColoredBox(
                key: ValueKey('second-panel'),
                color: Colors.transparent,
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ],
        ),
      ),
    );

    Future<void> pressSelectAll() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    await tester.tap(find.byKey(const ValueKey('first-panel')));
    await pressSelectAll();
    expect((firstCount, secondCount), (1, 0));

    await tester.tap(find.byKey(const ValueKey('second-panel')));
    await pressSelectAll();
    expect((firstCount, secondCount), (1, 1));
  });
}
