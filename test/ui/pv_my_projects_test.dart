import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/data.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/widgets/project/home/pv_my_projects.dart';

Project _project(int id, String name, DateTime edited) => Project(
      id: id,
      name: name,
      width: 32,
      height: 32,
      createdAt: edited,
      editedAt: edited,
    );

Widget _host(AsyncValue<List<Project>> projects, {VoidCallback? onCreate, void Function(Project)? onTap}) {
  void noop(Project _) {}
  return MaterialApp(
    theme: AppTheme.defaultTheme.themeData,
    localizationsDelegates: Strings.localizationsDelegates,
    supportedLocales: Strings.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: PvMyProjects(
          projects: projects,
          onCreateNew: onCreate ?? () {},
          onTapProject: onTap ?? noop,
          onDeleteProject: noop,
          onEditProject: noop,
          onUploadProject: noop,
          onUpdateProject: noop,
          onDeleteCloudProject: noop,
          onRetry: () {},
        ),
      ),
    ),
  );
}

void main() {
  desktopTests();

  testWidgets('empty list shows the create-first-project state', (tester) async {
    var created = 0;
    await tester.pumpWidget(_host(const AsyncData([]), onCreate: () => created++));
    await tester.pump();

    expect(find.text('Create your first project'), findsOneWidget);
    await tester.tap(find.text('Create your first project'));
    expect(created, 1);
  });

  testWidgets('resume card opens the most recently edited project', (tester) async {
    final opened = <String>[];
    final projects = [
      _project(1, 'Old Sprite', DateTime(2026, 1, 1)),
      _project(2, 'Fresh Slime', DateTime(2026, 6, 1)),
    ];
    await tester.pumpWidget(_host(AsyncData(projects), onTap: (p) => opened.add(p.name)));
    await tester.pump();

    expect(find.text('CONTINUE WHERE YOU LEFT OFF'), findsOneWidget);
    await tester.tap(find.byTooltip('Resume'));
    expect(opened, ['Fresh Slime']);
  });

  testWidgets('mobile section stays compact and supports search and project opening', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    final projects = [
      _project(1, 'First sprite', DateTime(2026, 1, 1)),
      _project(2, 'Latest sprite', DateTime(2026, 6, 1)),
    ];
    await tester.pumpWidget(_host(AsyncData(projects), onTap: (project) => opened.add(project.name)));
    await tester.pump();
    expect(tester.getSize(find.byType(PvMyProjects)).height, lessThan(320));
    expect(tester.getSize(find.byType(PvResumeCard)).height, lessThan(110));
    await tester.tap(find.byTooltip('Search...'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'First');
    tester.testTextInput.hide();
    await tester.pump();
    expect(find.text('First sprite'), findsOneWidget);
    await tester.tap(find.text('First sprite'));
    expect(opened, ['First sprite']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading state builds a skeleton', (tester) async {
    await tester.pumpWidget(_host(const AsyncLoading()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}

void _noop(Project _) {}

Widget _desktopHost(Widget child) => MaterialApp(
      theme: AppTheme.defaultTheme.themeData,
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: 1100, child: child))),
    );

void desktopTests() {
  testWidgets('quick create panel reports the picked size and import', (tester) async {
    int? picked;
    var imported = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.defaultTheme.themeData,
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 340,
            child: PvQuickCreatePanel(onPickSize: (s) => picked = s, onImport: () => imported++),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('64×64'));
    await tester.tap(find.text('Import image or project file'));
    expect(picked, 64);
    expect(imported, 1);
  });

  testWidgets('grid scrolls horizontally from Create to the last project', (tester) async {
    final projects = [for (var i = 0; i < 7; i++) _project(i, 'Sprite $i', DateTime(2026, 1, i + 1))];
    var created = 0;
    await tester.pumpWidget(_desktopHost(PvProjectsGrid(
      projects: projects,
      onCreateNew: () => created++,
      onTapProject: _noop,
      onDeleteProject: _noop,
      onEditProject: _noop,
      onUploadProject: _noop,
      onUpdateProject: _noop,
      onDeleteCloudProject: _noop,
    )));
    await tester.pump();
    expect(find.text('Create'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(-4000, 0));
    await tester.pump();
    // Flagship cards may upper-case the name.
    expect(find.byWidgetPredicate((w) => w is Text && w.data?.toLowerCase() == 'sprite 6'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(4000, 0));
    await tester.pump();
    await tester.tap(find.text('Create'));
    expect(created, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide resume card opens the project', (tester) async {
    Project? opened;
    final p = _project(1, 'Slime Quest', DateTime(2026, 6, 1));
    await tester.pumpWidget(_desktopHost(PvResumeCardWide(project: p, onResume: () => opened = p)));
    await tester.tap(find.text('Resume'));
    expect(opened, p);
  });
}
