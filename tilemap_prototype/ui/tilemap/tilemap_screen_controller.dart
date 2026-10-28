import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../tilemap/tilemap_notifier.dart';

/// Controller for managing tilemap screen interactions and keyboard state
class TilemapScreenController extends ChangeNotifier {
  final FocusNode focusNode = FocusNode();

  bool _isModifierPressed = false;
  bool get isModifierPressed => _isModifierPressed;

  /// Handle keyboard events to track modifier key state (Cmd/Ctrl)
  void handleKeyEvent(KeyEvent event) {
    final isModifier = event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight ||
        event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight;

    if (isModifier) {
      _isModifierPressed = event is KeyDownEvent;
      notifyListeners();
    }
  }

  /// Apply the current tilemap tool at the given position
  void applyTool(TileMapNotifier notifier, TileMapTool tool, int x, int y) {
    switch (tool) {
      case TileMapTool.paint:
        notifier.paintTile(x, y);
        break;
      case TileMapTool.erase:
        notifier.eraseTile(x, y);
        break;
      case TileMapTool.fill:
        notifier.fillTiles(x, y);
        break;
      case TileMapTool.eyedropper:
        notifier.pickTile(x, y);
        break;
      case TileMapTool.select:
        // Selection handled separately
        break;
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
}
