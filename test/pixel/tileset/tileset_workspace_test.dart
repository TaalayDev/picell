import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/data/repo/project_repo.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/providers/providers.dart';
import 'package:picell/ui/screens/editor_workspace_screen.dart';

class _MemoryRepo implements ProjectRepo {
  _MemoryRepo(this.stored);
  Project stored;
  bool dropWrites = true;
  int writes = 0;
  @override
  Future<void> updateProject(Project project) async {
    writes++;
    if (!dropWrites) stored = project;
  }

  @override
  Future<Project?> fetchProject(int id) async => stored;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('workspace verifies saves before leaving a dirty tileset', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = TilesetSettings(variations: 1);
    final doc = TilesetDocument(
        name: 'Platforms',
        settings: settings,
        tiles: generatePlatformTileset(settings),
        cells: [1],
        columns: 1,
        rows: 1);
    final project = Project(
        id: 1,
        name: 'Platforms',
        width: 16,
        height: 16,
        type: ProjectType.proceduralTileset,
        tilesetData: jsonEncode(doc.toJson()),
        createdAt: DateTime(2026),
        editedAt: DateTime(2026));
    final repo = _MemoryRepo(project);
    await tester.pumpWidget(ProviderScope(
        overrides: [projectRepo.overrideWithValue(repo)],
        child: MaterialApp(
            localizationsDelegates: Strings.localizationsDelegates,
            supportedLocales: Strings.supportedLocales,
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute<void>(builder: (_) => EditorWorkspaceScreen(initialProject: project))),
                        child: const Text('Open workspace')))))));
    await tester.runAsync(() => tester.tap(find.text('Open workspace')));
    await tester.runAsync(() => tester.pump(const Duration(milliseconds: 400)));
    await tester.runAsync(() => tester.pump());
    for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    final name = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Collection name');
    expect(name, findsOneWidget);
    await tester.enterText(name, 'Changed Platforms');
    await tester.pump();
    expect(find.byKey(const ValueKey('project-tab-unsaved')), findsOneWidget);
    await tester.runAsync(() => tester.tap(find.byKey(const ValueKey('project-tabs-home'))));
    for (var i = 0; i < 50 && repo.writes == 0; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(find.byType(EditorWorkspaceScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('project-tab-unsaved')), findsOneWidget);
    expect(repo.stored.name, 'Platforms');
    repo.dropWrites = false;
    await tester.runAsync(() => tester.tap(find.byKey(const ValueKey('project-tabs-home'))));
    for (var i = 0; i < 50 && repo.writes < 2; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(repo.stored.name, 'Changed Platforms');
    expect(repo.stored.thumbnail, isNotNull);
    expect(find.byType(EditorWorkspaceScreen), findsNothing);
    expect(find.text('Open workspace'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
