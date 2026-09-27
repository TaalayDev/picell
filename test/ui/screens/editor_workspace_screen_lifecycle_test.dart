import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/screens/editor_workspace_screen.dart';

void main() {
  testWidgets('does not modify workspace provider during the first build',
      (tester) async {
    final project = Project(
      id: 1,
      name: 'Lifecycle test',
      width: 16,
      height: 16,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: EditorWorkspaceScreen(initialProject: project),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
