import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/ui/widgets/handle_reorderable_list.dart';

Widget _host(List<int> items, void Function(int, int) onReorder) => MaterialApp(
      home: Scaffold(
        body: HandleReorderableList<int>(
          items: items,
          keyOf: (i) => ValueKey(i),
          onReorder: onReorder,
          itemBuilder: (context, index, item, handle) => SizedBox(
            height: 40,
            child: Row(children: [handle, Text('L$item')]),
          ),
        ),
      ),
    );

void main() {
  testWidgets('removing several items at once does not throw', (tester) async {
    await tester.pumpWidget(_host([5, 4, 3, 2, 1, 0], (_, __) {}));
    await tester.pumpWidget(_host([5, 2, 0], (_, __) {}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('L1'), findsNothing);
    expect(find.text('L5'), findsOneWidget);
  });

  testWidgets('dragging the handle reports final indices', (tester) async {
    (int, int)? moved;
    await tester.pumpWidget(_host([0, 1, 2], (o, n) => moved = (o, n)));
    final handle = find.byIcon(Icons.drag_indicator).first;
    final g = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 140));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(moved, (0, 2));
  });
}
