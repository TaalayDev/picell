import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../pixel/tools.dart';
import '../pixel/tools/texture_brush_tool.dart';
import 'providers.dart';

const shapeTools = {
  PixelTool.line,
  PixelTool.rectangle,
  PixelTool.circle,
  PixelTool.triangle,
  PixelTool.diamond,
  PixelTool.hexagon,
  PixelTool.heart,
  PixelTool.arrow,
  PixelTool.lightning,
  PixelTool.cross,
  PixelTool.spiral,
  PixelTool.cloud,
};
const selectionTools = {PixelTool.select, PixelTool.ellipseSelect, PixelTool.lasso, PixelTool.smartSelect};

@immutable
class EditorToolMemory {
  const EditorToolMemory({
    this.shape = PixelTool.line,
    this.selection = PixelTool.select,
    this.texture,
    this.blendMode = BlendMode.srcOver,
    this.isTextureFill = false,
  });

  final PixelTool shape;
  final PixelTool selection;
  final TexturePattern? texture;
  final BlendMode blendMode;
  final bool isTextureFill;

  EditorToolMemory copyWith(
          {PixelTool? shape,
          PixelTool? selection,
          TexturePattern? texture,
          BlendMode? blendMode,
          bool? isTextureFill}) =>
      EditorToolMemory(
        shape: shape ?? this.shape,
        selection: selection ?? this.selection,
        texture: texture ?? this.texture,
        blendMode: blendMode ?? this.blendMode,
        isTextureFill: isTextureFill ?? this.isTextureFill,
      );
}

final editorToolMemoryProvider =
    NotifierProvider<EditorToolMemoryNotifier, EditorToolMemory>(EditorToolMemoryNotifier.new);

/// Remembers group choices independently from the active canvas tool.
class EditorToolMemoryNotifier extends Notifier<EditorToolMemory> {
  static const storageKey = 'editor_tool_memory_v1';

  @override
  EditorToolMemory build() {
    final saved = ref.read(localStorageProvider).getString(storageKey);
    if (saved == null) return const EditorToolMemory();
    try {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      return EditorToolMemory(
        shape: shapeTools.where((tool) => tool.name == json['shape']).firstOrNull ?? PixelTool.line,
        selection: selectionTools.where((tool) => tool.name == json['selection']).firstOrNull ?? PixelTool.select,
        texture: json['texture'] == null ? null : TexturePattern.fromJson(json['texture'] as Map<String, dynamic>),
        blendMode: BlendMode.values.where((mode) => mode.name == json['blendMode']).firstOrNull ?? BlendMode.srcOver,
        isTextureFill: json['isTextureFill'] == true,
      );
    } catch (_) {
      return const EditorToolMemory();
    }
  }

  void rememberTool(PixelTool tool) {
    if (shapeTools.contains(tool) && tool != state.shape) {
      _save(state.copyWith(shape: tool));
    } else if (selectionTools.contains(tool) && tool != state.selection) {
      _save(state.copyWith(selection: tool));
    } else if ((tool == PixelTool.textureBrush || tool == PixelTool.textureFill) &&
        (tool == PixelTool.textureFill) != state.isTextureFill) {
      _save(state.copyWith(isTextureFill: tool == PixelTool.textureFill));
    }
  }

  void rememberTexture(TexturePattern texture, BlendMode blendMode, bool isFill) {
    _save(state.copyWith(texture: texture, blendMode: blendMode, isTextureFill: isFill));
  }

  void _save(EditorToolMemory next) {
    state = next;
    ref.read(localStorageProvider).setString(
        storageKey,
        jsonEncode({
          'shape': next.shape.name,
          'selection': next.selection.name,
          'texture': next.texture?.toJson(),
          'blendMode': next.blendMode.name,
          'isTextureFill': next.isTextureFill,
        }));
  }
}
