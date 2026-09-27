import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/editor_workspace_provider.dart';
import 'package:picell/ui/widgets/project_tabs_bar.dart';

void main() {
  Project project(int id, String name) => Project(
        id: id,
        name: name,
        width: 16,
        height: 16,
        createdAt: DateTime(2026),
        editedAt: DateTime(2026),
      );

  testWidgets('shows open projects and dispatches tab actions', (tester) async {
    int? selected;
    int? closed;
    var opened = 0;
    var showedProjects = 0;
    (int, int)? reordered;
    final state = EditorWorkspaceState(
      tabs: [
        ProjectEditorTab(project: project(1, 'Forest')),
        ProjectEditorTab(
          project: project(2, 'Castle'),
          hasUnsavedChanges: true,
        ),
      ],
      activeProjectId: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: Scaffold(
          body: ProjectTabsBar(
            state: state,
            loadingProjectId: 1,
            onProjectSelected: (value) => selected = value,
            onProjectClosed: (value) => closed = value,
            onProjectReordered: (oldIndex, newIndex) =>
                reordered = (oldIndex, newIndex),
            onOpenProject: () => opened += 1,
            onShowProjects: () => showedProjects += 1,
          ),
        ),
      ),
    );

    expect(find.text('Forest'), findsOneWidget);
    expect(find.text('Castle'), findsOneWidget);
    expect(find.byKey(const ValueKey('project-tab-loading')), findsOneWidget);
    expect(find.byKey(const ValueKey('project-tab-unsaved')), findsOneWidget);

    await tester.tap(find.text('Forest'));
    expect(selected, 1);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('project-tab-2')),
        matching: find.byIcon(Icons.close),
      ),
    );
    expect(closed, 2);

    await tester.tap(find.byKey(const ValueKey('project-tabs-add')));
    await tester.tap(find.byKey(const ValueKey('project-tabs-home')));
    expect(opened, 1);
    expect(showedProjects, 1);

    await tester.drag(
      find.byKey(const ValueKey('project-tab-1')),
      const Offset(180, 0),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(reordered, isNotNull);
  });
}
