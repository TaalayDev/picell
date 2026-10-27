import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/pixel/tools/texture_brush_tool.dart';
import 'package:picell/providers/editor_tool_memory_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  setUp(() => LocalStorage.instance.setString(EditorToolMemoryNotifier.storageKey, '{}'));

  test('group choices and texture settings survive a new editor session', () {
    final first = ProviderContainer();
    final memory = first.read(editorToolMemoryProvider.notifier);
    memory.rememberTool(PixelTool.triangle);
    memory.rememberTool(PixelTool.lasso);
    memory.rememberTexture(TextureManager().getDefaultTextures().first, BlendMode.multiply, true);
    memory.rememberTool(PixelTool.pencil);
    first.dispose();

    final next = ProviderContainer();
    addTearDown(next.dispose);
    final saved = next.read(editorToolMemoryProvider);
    expect(saved.shape, PixelTool.triangle);
    expect(saved.selection, PixelTool.lasso);
    expect(saved.texture?.toJson(), TextureManager().getDefaultTextures().first.toJson());
    expect(saved.blendMode, BlendMode.multiply);
    expect(saved.isTextureFill, isTrue);
  });

  test('invalid or outdated saved tools fall back to valid group choices', () {
    LocalStorage.instance.setString(
        EditorToolMemoryNotifier.storageKey, '{"shape":"pencil","selection":"removedTool","blendMode":"unknown"}');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final saved = container.read(editorToolMemoryProvider);
    expect(saved.shape, PixelTool.line);
    expect(saved.selection, PixelTool.select);
    expect(saved.blendMode, BlendMode.srcOver);
  });
}
