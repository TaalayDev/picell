import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/mcp/mcp_control.dart';

void main() {
  testWidgets('desktop connection panel opens above the navigator and starts/stops', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      navigatorKey: key,
      home: const Scaffold(body: Text('Projects')),
      builder: (_, child) => McpControl(navigatorKey: key, child: child!),
    )));
    await tester.tap(find.byTooltip('AI connection (MCP)'));
    await tester.pumpAndSettle();
    expect(find.text('Stopped'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Start connection'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Running on this computer'), findsOneWidget);
    expect(find.text('Copy connection details'), findsOneWidget);
    await tester.tap(find.text('Stop and save'));
    for (var attempt = 0; attempt < 50 && find.text('AI connection (MCP)').evaluate().isNotEmpty; attempt++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    expect(find.text('AI connection (MCP)'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
