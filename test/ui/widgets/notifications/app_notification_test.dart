import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/ui/widgets/notifications/app_notification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppNotification displays on the top right and supports actions',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppNotification.success(
                      context,
                      'Test success message',
                      title: 'Success!',
                      actionLabel: 'Undo',
                      onAction: () {
                        actionCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Notification'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap the button to show notification
    await tester.tap(find.text('Show Notification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Entrance animation

    // Verify notification content
    expect(find.text('Test success message'), findsOneWidget);
    expect(find.text('Success!'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Verify it is positioned near top right
    final cardFinder = find.text('Test success message');
    final cardCenter = tester.getCenter(cardFinder);
    expect(cardCenter.dx, greaterThan(400)); // Default test surface width is 800
    expect(cardCenter.dy, lessThan(200));

    // Tap action
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(actionCalled, isTrue);

    // Test dismissal
    AppNotification.dismissAll();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // Exit animation

    expect(find.text('Test success message'), findsNothing);
  });

  testWidgets('AppNotification supports error, warning, and info helpers',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppNotification.error(context, 'Err'),
                    child: const Text('ErrBtn'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppNotification.warning(context, 'Warn'),
                    child: const Text('WarnBtn'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppNotification.info(context, 'Inf'),
                    child: const Text('InfoBtn'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('ErrBtn'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Err'), findsOneWidget);

    await tester.tap(find.text('WarnBtn'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Warn'), findsOneWidget);

    await tester.tap(find.text('InfoBtn'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Inf'), findsOneWidget);

    AppNotification.dismissAll();
    await tester.pumpAndSettle();
  });
}
