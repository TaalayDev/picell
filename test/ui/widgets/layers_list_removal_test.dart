import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors LayersPanel: layers are stored bottom-first and shown reversed.
// The list handed to the package must be the displayed (reversed) one.
Widget _host(List<int> layers) {
  final reversed = layers.reversed.toList();
  return MaterialApp(
    home: Scaffold(
      body: AnimatedReorderableListView<int>(
        items: reversed,
        onReorder: (_, __) {},
        itemBuilder: (context, index) => SizedBox(
          key: ValueKey(reversed[index]),
          height: 40,
          child: Text('L${reversed[index]}'),
        ),
        enterTransition: [FlipInX(), ScaleIn()],
        exitTransition: [SlideInLeft()],
        isSameItem: (a, b) => a == b,
      ),
    ),
  );
}

void main() {
  testWidgets('deleting several layers at once does not throw', (tester) async {
    await tester.pumpWidget(_host([0, 1, 2, 3, 4, 5]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host([0, 2, 5]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('L5'), findsOneWidget);
    expect(find.text('L1'), findsNothing);
  });
}
