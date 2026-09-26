import 'package:flutter_test/flutter_test.dart';
import 'package:picell/ui/utils/multi_selection.dart';

void main() {
  const items = ['a', 'b', 'c', 'd', 'e'];

  test('plain click selects one active item', () {
    final result = updateMultiSelection(
      orderedItems: items,
      selected: {'a', 'b'},
      active: 'b',
      clicked: 'd',
    );
    expect(result.selected, {'d'});
    expect(result.active, 'd');
  });

  test('toggle adds and removes while retaining an active selection', () {
    final added = updateMultiSelection(
      orderedItems: items,
      selected: {'b'},
      active: 'b',
      clicked: 'd',
      toggle: true,
    );
    expect(added.selected, {'b', 'd'});
    expect(added.active, 'd');

    final removed = updateMultiSelection(
      orderedItems: items,
      selected: added.selected,
      active: added.active,
      clicked: 'd',
      toggle: true,
    );
    expect(removed.selected, {'b'});
    expect(removed.active, 'b');
  });

  test('the sole active item cannot be toggled off', () {
    final result = updateMultiSelection(
      orderedItems: items,
      selected: {'c'},
      active: 'c',
      clicked: 'c',
      toggle: true,
    );
    expect(result.selected, {'c'});
    expect(result.active, 'c');
  });

  test('shift selects an anchored range and makes endpoint active', () {
    final result = updateMultiSelection(
      orderedItems: items,
      selected: {'b'},
      active: 'b',
      clicked: 'e',
      anchor: 'b',
      extendRange: true,
    );
    expect(result.selected, {'b', 'c', 'd', 'e'});
    expect(result.active, 'e');
    expect(result.anchor, 'b');
  });
}
