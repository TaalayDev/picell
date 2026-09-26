import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/ui/widgets/tool_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('top bar groups infrequent actions into File, View and Add',
      (tester) async {
    var historyCalls = 0;
    var effectsCalls = 0;
    var tileModeCalls = 0;

    final project = Project(
      id: 1,
      name: 'Toolbar test',
      width: 16,
      height: 16,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
    );
    final currentTool = ValueNotifier(PixelTool.pencil);
    final currentModifier = ValueNotifier(PixelModifier.none);
    final brushSize = ValueNotifier(1);
    final sprayIntensity = ValueNotifier(1);
    final selectionMode = ValueNotifier(SelectionMode.replace);

    addTearDown(() {
      currentTool.dispose();
      currentModifier.dispose();
      brushSize.dispose();
      sprayIntensity.dispose();
      selectionMode.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: ToolBar(
              currentTool: currentTool,
              currentModifier: currentModifier,
              brushSize: brushSize,
              sprayIntensity: sprayIntensity,
              onSelectTool: (tool) => currentTool.value = tool,
              onSelectModifier: (modifier) => currentModifier.value = modifier,
              onUndo: () {},
              onRedo: () {},
              currentColor: Colors.black,
              onColorPicker: () {},
              subscription: const UserSubscription.free(),
              project: project,
              selectionMode: selectionMode,
              onShowHistory: () => historyCalls++,
              onEffects: () => effectsCalls++,
              onToggleTileMode: () => tileModeCalls++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('toolbar-file-menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('toolbar-view-menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('toolbar-add-menu')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toolbar-file-menu')));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    expect(find.text('Editor Settings'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(historyCalls, 1);

    await tester.tap(find.byKey(const ValueKey('toolbar-view-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Tile Mode - preview seamless tiling'), findsOneWidget);
    expect(find.text('Show Grid'), findsOneWidget);
    expect(
      find.text('Onion Skin (long-press to set opacity)'),
      findsOneWidget,
    );
    await tester.tap(
      find
          .ancestor(
            of: find.text('Tile Mode - preview seamless tiling'),
            matching: find.byWidgetPredicate(
              (widget) => widget is CheckedPopupMenuItem,
            ),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(tileModeCalls, 1);

    await tester.tap(find.byKey(const ValueKey('toolbar-add-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Materials'), findsOneWidget);
    expect(find.text('Generators'), findsOneWidget);
    expect(find.text('Animation: Transformers'), findsOneWidget);
    expect(find.text('Animation: Special effects'), findsOneWidget);
    expect(find.text('Lighting'), findsOneWidget);
    expect(find.text('Distortions'), findsOneWidget);
    expect(find.text('Layer Effects'), findsOneWidget);
    expect(find.text('Template Gallery'), findsOneWidget);

    await tester.tap(find.text('Materials'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Select Effect'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('toolbar-add-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Layer Effects'));
    await tester.pumpAndSettle();
    expect(effectsCalls, 1);
  });
}
