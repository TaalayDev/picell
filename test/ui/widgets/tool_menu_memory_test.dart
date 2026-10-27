import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/pixel/tools/texture_brush_tool.dart';
import 'package:picell/providers/editor_tool_memory_provider.dart';
import 'package:picell/ui/widgets/panel/texture_brush_panel.dart';
import 'package:picell/ui/widgets/tool_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  setUp(() => LocalStorage.instance.setString(EditorToolMemoryNotifier.storageKey, '{}'));

  testWidgets('shape and selection buttons restore choices and keep menus available', (tester) async {
    final tool = ValueNotifier(PixelTool.pencil);
    addTearDown(tool.dispose);
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
          body: ValueListenableBuilder(
        valueListenable: tool,
        builder: (context, value, _) => Row(children: [
          ShapesMenuButton(currentTool: tool, onSelectTool: (value) => tool.value = value),
          SelectionToolsMenuButton(currentTool: tool, onSelectTool: (value) => tool.value = value),
        ]),
      )),
    )));
    await tester.tap(find.byKey(const ValueKey('shape-tool-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triangle'));
    await tester.pumpAndSettle();
    expect(tool.value, PixelTool.triangle);
    tool.value = PixelTool.pencil;
    await tester.pump();
    expect(find.byIcon(Icons.change_history), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shape-tool-activate')));
    await tester.pumpAndSettle();
    expect(tool.value, PixelTool.triangle);
    expect(find.text('Rectangle'), findsNothing);

    await tester.longPress(find.byKey(const ValueKey('selection-tool-activate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lasso'));
    await tester.pumpAndSettle();
    expect(tool.value, PixelTool.lasso);
    tool.value = PixelTool.pencil;
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('selection-tool-activate')));
    await tester.pumpAndSettle();
    expect(tool.value, PixelTool.lasso);
    expect(tester.takeException(), isNull);
  });

  testWidgets('texture click restores settings and options reopen with those settings', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final texture = TextureManager().getDefaultTextures().first;
    container.read(editorToolMemoryProvider.notifier).rememberTexture(texture, BlendMode.multiply, true);
    final tool = ValueNotifier(PixelTool.pencil);
    addTearDown(tool.dispose);
    (int, BlendMode, bool)? applied;
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
              body: TextureToolsMenuButton(
            currentTool: tool,
            onTextureSelected: (texture, blend, fill) => applied = (texture.id, blend, fill),
          )),
        )));
    await tester.tap(find.byKey(const ValueKey('texture-tool-activate')));
    await tester.pumpAndSettle();
    expect(applied, (texture.id, BlendMode.multiply, true));
    expect(find.byType(TextureBrushPanel), findsNothing);
    await tester.tap(find.byKey(const ValueKey('texture-tool-options')));
    await tester.pumpAndSettle();
    final panel = tester.widget<TextureBrushPanel>(find.byType(TextureBrushPanel));
    expect(panel.selectedTextureId, texture.id);
    expect(panel.blendMode, BlendMode.multiply);
    expect(panel.isFill, isTrue);
    expect(tester.takeException(), isNull);
  });
}
