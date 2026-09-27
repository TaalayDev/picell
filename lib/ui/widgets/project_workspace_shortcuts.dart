import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectWorkspaceShortcuts extends StatelessWidget {
  const ProjectWorkspaceShortcuts({
    super.key,
    required this.onNextTab,
    required this.onPreviousTab,
    required this.onActivateTab,
    required this.onCloseCurrentTab,
    required this.child,
  });

  final VoidCallback onNextTab;
  final VoidCallback onPreviousTab;
  final ValueChanged<int> onActivateTab;
  final VoidCallback onCloseCurrentTab;
  final Widget child;

  static const _digitKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  @override
  Widget build(BuildContext context) {
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.tab, control: true): onNextTab,
      const SingleActivator(LogicalKeyboardKey.tab, meta: true): onNextTab,
      const SingleActivator(
        LogicalKeyboardKey.tab,
        control: true,
        shift: true,
      ): onPreviousTab,
      const SingleActivator(
        LogicalKeyboardKey.tab,
        meta: true,
        shift: true,
      ): onPreviousTab,
      const SingleActivator(LogicalKeyboardKey.keyW, control: true):
          onCloseCurrentTab,
      const SingleActivator(LogicalKeyboardKey.keyW, meta: true):
          onCloseCurrentTab,
    };

    for (var index = 0; index < _digitKeys.length; index++) {
      bindings[SingleActivator(_digitKeys[index], control: true)] =
          () => onActivateTab(index);
      bindings[SingleActivator(_digitKeys[index], meta: true)] =
          () => onActivateTab(index);
    }

    return CallbackShortcuts(bindings: bindings, child: child);
  }
}
