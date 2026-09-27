import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/projects_provider.dart';
import 'package:picell/ui/widgets/project_tab_launcher.dart';

class _FakeProjects extends Projects {
  static final existing = Project(
    id: 1,
    name: 'Existing project',
    width: 32,
    height: 24,
    createdAt: DateTime(2026),
    editedAt: DateTime(2026),
  );

  @override
  Stream<List<Project>> build() => Stream.value([existing]);

  @override
  Future<Project> addProject(Project newProject) async {
    return newProject.copyWith(id: 99);
  }
}

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required Size size,
    required ValueChanged<Project?> onResult,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectsProvider.overrideWith(_FakeProjects.new)],
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  onResult(await ProjectTabLauncher.show(context));
                },
                child: const Text('Open launcher'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open launcher'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a dialog on desktop and creates a project',
      (tester) async {
    Project? result;
    await pumpHost(
      tester,
      size: const Size(1000, 800),
      onResult: (project) => result = project,
    );

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const ValueKey('project-tab-new-name')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('project-tab-new-name')),
      'Created project',
    );
    await tester.tap(find.byKey(const ValueKey('project-tab-create')));
    await tester.pumpAndSettle();

    expect(result?.id, 99);
    expect(result?.name, 'Created project');
    expect(result?.width, 16);
    expect(result?.height, 16);
  });

  testWidgets('shows a bottom sheet on mobile and selects an existing project',
      (tester) async {
    Project? result;
    await pumpHost(
      tester,
      size: const Size(390, 844),
      onResult: (project) => result = project,
    );

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Existing project'));
    await tester.pumpAndSettle();

    expect(result?.id, 1);
  });
}
