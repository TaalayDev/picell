import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/app/theme/pv_tokens.dart';
import 'package:picell/core/utils/feature_flags.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/tileset/tileset_collection.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/providers/projects_provider.dart';
import 'package:picell/ui/widgets/dialogs/new_project_dialog.dart';
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
  Future<Project> addProject(Project newProject, {String source = 'blank'}) async {
    return newProject.copyWith(id: 99);
  }
}

void main() {
  setUpAll(() => PvTokens.useDesignFonts = false);
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

  testWidgets('shows a dialog on desktop and creates a project', (tester) async {
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
    await tester.ensureVisible(find.byKey(const ValueKey('project-tab-create')));
    await tester.tap(find.byKey(const ValueKey('project-tab-create')));
    await tester.pumpAndSettle();

    expect(result?.id, 99);
    expect(result?.name, 'Created project');
    expect(result?.width, 16);
    expect(result?.height, 16);
  });

  testWidgets('creates a tileset without pixel-canvas dimension fields', (tester) async {
    Project? result;
    await pumpHost(tester, size: const Size(1000, 800), onResult: (p) => result = p);
    await tester.tap(find.text('Tileset'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('project-tab-new-width')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('project-tab-new-name')), 'Platforms');
    FilledButton create() => tester.widget(find.byKey(const ValueKey('project-tab-create')));
    expect(create().onPressed, isNull, reason: 'perspective and tile size must be chosen first');
    await tester.ensureVisible(find.byKey(const ValueKey('tileset-perspective-top')));
    await tester.tap(find.byKey(const ValueKey('tileset-perspective-top')));
    await tester.pump();
    expect(create().onPressed, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('tileset-size-32')));
    await tester.tap(find.byKey(const ValueKey('tileset-size-32')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('project-tab-create')));
    await tester.tap(find.byKey(const ValueKey('project-tab-create')));
    await tester.pumpAndSettle();
    expect(result?.type, ProjectType.proceduralTileset);
    final collection = TilesetCollection.fromJson(jsonDecode(result!.tilesetData!) as Map<String, dynamic>);
    expect((collection.perspective, collection.tileSize), (TilesetPerspective.topDown, 32));
    expect(result?.name, 'Platforms');
  }, skip: !kTilesetGeneratorEnabled);

  testWidgets('shows a bottom sheet on mobile and selects an existing project', (tester) async {
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

  testWidgets('NewProjectDialog switches between Pixel Art and Tileset modes', (tester) async {
    dynamic result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<dynamic>(
                  context: context,
                  builder: (_) => const NewProjectDialog(subscription: UserSubscription.free()),
                );
              },
              child: const Text('Open new project'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open new project'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('project-type-pixel-art')), findsOneWidget);
    expect(find.byKey(const ValueKey('project-type-tileset')), findsOneWidget);
    expect(find.text('Tileset Studio'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('project-type-tileset')));
    await tester.pumpAndSettle();
    expect(find.text('Tileset Studio'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'World Tiles');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(result?.name, 'World Tiles');
    expect(result?.type, ProjectType.proceduralTileset);
  }, skip: !kTilesetGeneratorEnabled);
}
