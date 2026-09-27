import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/ui/widgets/project_workspace_shortcuts.dart';

void main() {
  testWidgets('switches project tabs with control shortcuts', (tester) async {
    var nextCount = 0;
    var previousCount = 0;
    var closedCount = 0;
    int? activatedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectWorkspaceShortcuts(
          onNextTab: () => nextCount += 1,
          onPreviousTab: () => previousCount += 1,
          onActivateTab: (index) => activatedIndex = index,
          onCloseCurrentTab: () => closedCount += 1,
          child: const Scaffold(
            body: Focus(
              autofocus: true,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(nextCount, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(previousCount, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(activatedIndex, 2);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(closedCount, 1);
  });
}
