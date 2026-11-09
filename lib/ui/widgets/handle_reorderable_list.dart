import 'package:flutter/material.dart';

/// A vertical list whose rows are reordered by dragging a dedicated handle.
///
/// Rows get their handle through [itemBuilder]'s `dragHandle` argument, so the
/// caller decides where to place it (e.g. at the start of a row). Everything
/// else (taps, scrolling) is left alone. [onReorder] receives the final
/// indices: the item at `oldIndex` ends up at `newIndex` after the move.
class HandleReorderableList<T> extends StatelessWidget {
  final List<T> items;
  final Key Function(T item) keyOf;
  final Widget Function(BuildContext context, int index, T item, Widget dragHandle) itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ScrollController? controller;
  final Widget? dragHandleIcon;

  const HandleReorderableList({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    required this.onReorder,
    this.controller,
    this.dragHandleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollController: controller,
      buildDefaultDragHandles: false,
      itemCount: items.length,
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeOut.transform(animation.value);
          return Material(
            type: MaterialType.transparency,
            elevation: 6 * t,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            child: child,
          );
        },
        child: child,
      ),
      onReorder: (oldIndex, newIndex) {
        // ReorderableListView reports the insertion slot before removal.
        if (newIndex > oldIndex) newIndex -= 1;
        if (newIndex == oldIndex) return;
        onReorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final handle = ReorderableDragStartListener(
          index: index,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: dragHandleIcon ?? const Icon(Icons.drag_indicator, size: 16),
          ),
        );
        return KeyedSubtree(
          key: keyOf(item),
          child: itemBuilder(context, index, item, handle),
        );
      },
    );
  }
}
