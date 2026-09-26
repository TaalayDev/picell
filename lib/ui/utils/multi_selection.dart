import 'package:flutter/services.dart';

class MultiSelectionResult<T> {
  const MultiSelectionResult({
    required this.selected,
    required this.active,
    required this.anchor,
  });

  final Set<T> selected;
  final T active;
  final T anchor;
}

/// Applies desktop-style selection while guaranteeing one active item.
MultiSelectionResult<T> updateMultiSelection<T>({
  required List<T> orderedItems,
  required Set<T> selected,
  required T active,
  required T clicked,
  T? anchor,
  bool toggle = false,
  bool extendRange = false,
}) {
  assert(orderedItems.contains(clicked));
  final available = selected.where(orderedItems.contains).toSet();
  if (!available.contains(active) && orderedItems.contains(active)) {
    available.add(active);
  }

  if (extendRange) {
    final rangeAnchor = orderedItems.contains(anchor) ? anchor as T : active;
    final anchorIndex = orderedItems.indexOf(rangeAnchor);
    final clickedIndex = orderedItems.indexOf(clicked);
    final start = anchorIndex < clickedIndex ? anchorIndex : clickedIndex;
    final end = anchorIndex > clickedIndex ? anchorIndex : clickedIndex;
    final range = orderedItems.sublist(start, end + 1).toSet();
    return MultiSelectionResult(
      selected: toggle ? {...available, ...range} : range,
      active: clicked,
      anchor: rangeAnchor,
    );
  }

  if (toggle) {
    if (available.contains(clicked)) {
      if (available.length == 1) {
        return MultiSelectionResult(
          selected: available,
          active: clicked,
          anchor: clicked,
        );
      }
      available.remove(clicked);
      final nextActive = active == clicked
          ? orderedItems.firstWhere(available.contains)
          : active;
      return MultiSelectionResult(
        selected: available,
        active: nextActive,
        anchor: clicked,
      );
    }
    available.add(clicked);
    return MultiSelectionResult(
      selected: available,
      active: clicked,
      anchor: clicked,
    );
  }

  return MultiSelectionResult(
    selected: {clicked},
    active: clicked,
    anchor: clicked,
  );
}

bool get isMultiSelectTogglePressed {
  final keyboard = HardwareKeyboard.instance;
  return keyboard.isControlPressed || keyboard.isMetaPressed;
}

bool get isRangeSelectPressed => HardwareKeyboard.instance.isShiftPressed;
