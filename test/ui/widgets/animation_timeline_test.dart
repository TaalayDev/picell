import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/animation_frame_controller.dart';
import 'package:picell/ui/utils/multi_selection.dart';
import 'package:picell/ui/widgets/animation_timeline.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    );
  }

  List<AnimationFrame> createSampleFrames(int count,
      {int stateId = 1, int width = 16, int height = 16}) {
    return List.generate(
      count,
      (index) => AnimationFrame(
        id: index + 1,
        name: 'Frame ${index + 1}',
        stateId: stateId,
        duration: 100,
        layers: [
          Layer(
            layerId: 1,
            id: 'layer_1',
            name: 'Layer 1',
            pixels: Uint32List(width * height),
          ),
        ],
        order: index,
        createdAt: DateTime(2026, 1, 1),
        editedAt: DateTime(2026, 1, 1),
      ),
    );
  }

  // Holds the frame selection the way the pixel draw controller does.
  Widget selectionHost({
    required List<AnimationFrame> frames,
    Function(Set<int>)? onDeleteFrame,
    Function(Set<int>)? copyFrame,
    Function(Set<int>, int)? onFrameReordered,
    Function(Set<int>, int)? onDurationChanged,
    void Function(int, String)? onRenameFrame,
    void Function(Set<int>)? onReverseFrames,
    void Function(Set<int>, int, bool)? onMoveFramesToState,
    List<AnimationStateModel> states = const [AnimationStateModel(id: 1, name: 'Idle', frameRate: 12)],
  }) {
    var active = frames.first.id;
    var selected = {active};
    int? anchor = active;
    return StatefulBuilder(
      builder: (context, setState) => AnimationTimeline(
        width: 16,
        height: 16,
        isExpanded: true,
        states: states,
        frames: frames,
        selectedStateId: 1,
        selectedFrameId: active,
        selectedFrameIds: selected,
        onSelectFrames: (id, {required toggle, required extendRange}) => setState(() {
          final result = updateMultiSelection(
            orderedItems: [for (final f in frames) f.id],
            selected: selected,
            active: active,
            clicked: id,
            anchor: anchor,
            toggle: toggle,
            extendRange: extendRange,
          );
          active = result.active;
          selected = result.selected;
          anchor = result.anchor;
        }),
        onSelectAllFrames: () => setState(() => selected = {for (final f in frames) f.id}),
        onRenameFrame: onRenameFrame,
        onReverseFrames: onReverseFrames,
        onMoveFramesToState: onMoveFramesToState,
        isPlaying: false,
        settings: const AnimationSettings(),
        onSelectFrame: (_) {},
        onAddFrame: () {},
        onDeleteFrame: onDeleteFrame ?? (_) {},
        onDurationChanged: onDurationChanged ?? (_, __) {},
        onFrameReordered: onFrameReordered ?? (_, __) {},
        onPlayPause: () {},
        onStop: () {},
        onNextFrame: () {},
        onPreviousFrame: () {},
        onSettingsChanged: (_) {},
        onExpandChanged: () {},
        copyFrame: copyFrame ?? (_) {},
        onAddState: (_) {},
        onRenameState: (_, __) {},
        onDeleteState: (_) {},
        onDuplicateState: (_) {},
        onCopyState: (_) {},
        onSelectedStateChanged: (_) {},
      ),
    );
  }

  testWidgets('AnimationTimeline frames scroll horizontally in a ListView',
      (tester) async {
    final frames = createSampleFrames(10);
    int selectedFrameId = 1;
    int selectedStateId = 1;
    final states = [
      const AnimationStateModel(id: 1, name: 'Idle', frameRate: 12),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        AnimationTimeline(
          width: 16,
          height: 16,
          isExpanded: true,
          states: states,
          frames: frames,
          selectedStateId: selectedStateId,
          selectedFrameId: selectedFrameId,
          isPlaying: false,
          settings: const AnimationSettings(),
          onSelectFrame: (id) {
            selectedFrameId = id;
          },
          onAddFrame: () {},
          onDeleteFrame: (_) {},
          onDurationChanged: (_, __) {},
          onFrameReordered: (_, __) {},
          onPlayPause: () {},
          onStop: () {},
          onNextFrame: () {},
          onPreviousFrame: () {},
          onSettingsChanged: (_) {},
          onExpandChanged: () {},
          copyFrame: (_) {},
          onAddState: (_) {},
          onRenameState: (_, __) {},
          onDeleteState: (_) {},
          onDuplicateState: (_) {},
          onCopyState: (_) {},
          onSelectedStateChanged: (id) {
            selectedStateId = id;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify horizontal ListView exists for frames
    final horizontalListViewFinder = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalListViewFinder, findsOneWidget);

    // Tap frame 2 to select it
    final frame2Finder = find.byKey(const ValueKey(2));
    expect(frame2Finder, findsOneWidget);
    await tester.tap(frame2Finder);
    await tester.pumpAndSettle();

    expect(selectedFrameId, 2);
  });

  testWidgets(
      'AnimationTimeline frames support horizontal scrolling without overflow',
      (tester) async {
    // 25 frames would previously cause GridView with 18px extent in a 40px row to overflow
    final frames = createSampleFrames(25, width: 32, height: 16);
    final states = [
      const AnimationStateModel(id: 1, name: 'Walk', frameRate: 12),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        AnimationTimeline(
          width: 32,
          height: 16,
          isExpanded: true,
          states: states,
          frames: frames,
          selectedStateId: 1,
          selectedFrameId: 1,
          isPlaying: false,
          settings: const AnimationSettings(),
          onSelectFrame: (_) {},
          onAddFrame: () {},
          onDeleteFrame: (_) {},
          onDurationChanged: (_, __) {},
          onFrameReordered: (_, __) {},
          onPlayPause: () {},
          onStop: () {},
          onNextFrame: () {},
          onPreviousFrame: () {},
          onSettingsChanged: (_) {},
          onExpandChanged: () {},
          copyFrame: (_) {},
          onAddState: (_) {},
          onRenameState: (_, __) {},
          onDeleteState: (_) {},
          onDuplicateState: (_) {},
          onCopyState: (_) {},
          onSelectedStateChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final horizontalListViewFinder = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalListViewFinder, findsOneWidget);

    // Scroll horizontally to the right
    await tester.drag(horizontalListViewFinder, const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Later frames should now be visible after scrolling without any overflow
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ctrl and Shift selections are passed to bulk frame actions',
      (tester) async {
    final frames = createSampleFrames(5);
    Set<int>? copied;
    Set<int>? deleted;
    (Set<int>, int)? reordered;

    await tester.pumpWidget(
      buildTestableWidget(
        selectionHost(
          frames: frames,
          onDeleteFrame: (ids) => deleted = Set.of(ids),
          onFrameReordered: (ids, target) => reordered = (Set.of(ids), target),
          copyFrame: (ids) => copied = Set.of(ids),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.byKey(const ValueKey('selected-frame-count')), findsOneWidget);
    expect(find.byKey(const ValueKey('frame-1-selected')), findsOneWidget);
    expect(find.byKey(const ValueKey('frame-2-selected')), findsOneWidget);
    await tester.tap(find.byIcon(Feather.copy).first);
    expect(copied, {1, 2});

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const ValueKey(4)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(find.byKey(const ValueKey('frame-1-selected')), findsNothing);
    expect(find.byKey(const ValueKey('frame-2-selected')), findsOneWidget);
    expect(find.byKey(const ValueKey('frame-3-selected')), findsOneWidget);
    expect(find.byKey(const ValueKey('frame-4-selected')), findsOneWidget);
    await tester.tap(find.byIcon(Feather.trash));
    expect(deleted, {2, 3, 4});

    final source = tester.getCenter(find.byKey(const ValueKey(4)).last);
    final target = tester.getCenter(find.byKey(const ValueKey(1)).last);
    await tester.dragFrom(source, target - source);
    await tester.pumpAndSettle();
    expect(reordered?.$1, {2, 3, 4});
    expect(reordered?.$2, 1);
  });

  testWidgets('Ctrl+A selects every frame in the focused animation panel',
      (tester) async {
    final frames = createSampleFrames(4);
    Set<int>? copied;

    await tester.pumpWidget(
      buildTestableWidget(
        selectionHost(frames: frames, copyFrame: (ids) => copied = Set.of(ids)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(1)).last);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.byKey(const ValueKey('selected-frame-count')), findsOneWidget);
    await tester.tap(find.byIcon(Feather.copy).first);
    expect(copied, {1, 2, 3, 4});
  });

  testWidgets('long-press opens the frame menu, which can add the frame to the selection', (tester) async {
    Set<int>? copied;
    await tester.pumpWidget(
      buildTestableWidget(
        selectionHost(frames: createSampleFrames(4), copyFrame: (ids) => copied = Set.of(ids)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey(3)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('frame-menu-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Feather.copy).first);
    expect(copied, {1, 3});
  });

  testWidgets('right-click menu acts on the selection the frame belongs to', (tester) async {
    Set<int>? deleted;
    Set<int>? reversed;
    (Set<int>, int, bool)? moved;
    await tester.pumpWidget(
      buildTestableWidget(
        selectionHost(
          frames: createSampleFrames(4),
          states: const [
            AnimationStateModel(id: 1, name: 'Idle', frameRate: 12),
            // Not 2..4: state rows share ValueKey(int) with frames.
            AnimationStateModel(id: 99, name: 'Run', frameRate: 12),
          ],
          onDeleteFrame: (ids) => deleted = Set.of(ids),
          onReverseFrames: (ids) => reversed = Set.of(ids),
          onMoveFramesToState: (ids, stateId, copy) => moved = (Set.of(ids), stateId, copy),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const ValueKey(3)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    Future<void> menuOn(int frameId, String item) async {
      await tester.tap(find.byKey(ValueKey(frameId)).last, buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('frame-menu-$item')));
      await tester.pumpAndSettle();
    }

    await menuOn(2, 'reverse');
    expect(reversed, {1, 2, 3});
    await menuOn(1, 'move-99');
    // Records compare Set fields by identity, so check each field.
    expect(moved?.$1, {1, 2, 3});
    expect((moved?.$2, moved?.$3), (99, false));

    // A frame outside the selection is acted on alone, and single frames
    // can't be reversed.
    await tester.tap(find.byKey(const ValueKey(4)).last, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('frame-menu-reverse')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('frame-menu-delete')));
    await tester.pumpAndSettle();
    expect(deleted, {4});
  });

  testWidgets('the menu sets the duration of the selection', (tester) async {
    (Set<int>, int)? duration;
    await tester.pumpWidget(
      buildTestableWidget(
        selectionHost(frames: createSampleFrames(3), onDurationChanged: (ids, ms) => duration = (Set.of(ids), ms)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey(2)).last, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('frame-menu-duration')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('frame-menu-input')), '250');
    await tester.tap(find.byKey(const ValueKey('frame-menu-confirm')));
    await tester.pumpAndSettle();
    expect(duration?.$1, {1, 2});
    expect(duration?.$2, 250);
  });

  testWidgets('the duration field commits on Enter, not on every keystroke', (tester) async {
    final commits = <(Set<int>, int)>[];
    await tester.pumpWidget(
      buildTestableWidget(
        selectionHost(frames: createSampleFrames(2), onDurationChanged: (ids, ms) => commits.add((Set.of(ids), ms))),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('frame-duration-field')), '15');
    await tester.enterText(find.byKey(const ValueKey('frame-duration-field')), '150');
    expect(commits, isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(commits.first.$1, {1});
    expect(commits.first.$2, 150);
  });

  testWidgets('dragging shows an insertion marker and fades every dragged frame', (tester) async {
    await tester.pumpWidget(buildTestableWidget(selectionHost(frames: createSampleFrames(4))));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey(1)).last));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey(4)).last));
    await tester.pump();

    expect(find.byKey(const ValueKey('frame-insert-marker')), findsOneWidget);
    final faded = tester
        .widgetList<Opacity>(find.ancestor(of: find.byType(Semantics), matching: find.byType(Opacity)))
        .where((o) => o.opacity < 1);
    expect(faded, isNotEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('frame-insert-marker')), findsNothing);
  });

  testWidgets('without onSelectFrames modifiers fall back to single selection', (tester) async {
    final frames = createSampleFrames(3);
    final selectedIds = <int>[];
    await tester.pumpWidget(
      buildTestableWidget(
        AnimationTimeline(
          width: 16,
          height: 16,
          isExpanded: true,
          states: const [AnimationStateModel(id: 1, name: 'Idle', frameRate: 12)],
          frames: frames,
          selectedStateId: 1,
          selectedFrameId: 1,
          isPlaying: false,
          settings: const AnimationSettings(),
          onSelectFrame: selectedIds.add,
          onAddFrame: () {},
          onDeleteFrame: (_) {},
          onDurationChanged: (_, __) {},
          onFrameReordered: (_, __) {},
          onPlayPause: () {},
          onStop: () {},
          onNextFrame: () {},
          onPreviousFrame: () {},
          onSettingsChanged: (_) {},
          onExpandChanged: () {},
          copyFrame: (_) {},
          onAddState: (_) {},
          onRenameState: (_, __) {},
          onDeleteState: (_) {},
          onDuplicateState: (_) {},
          onCopyState: (_) {},
          onSelectedStateChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(selectedIds, [2]);
    expect(find.byKey(const ValueKey('selected-frame-count')), findsNothing);
  });

  group('rig integration', () {
    Widget timeline(List<AnimationFrame> frames, {VoidCallback? onOpenRig, bool rigLocked = false}) {
      return buildTestableWidget(
        AnimationTimeline(
          width: 16,
          height: 16,
          isExpanded: true,
          states: const [AnimationStateModel(id: 1, name: 'Walk', frameRate: 12)],
          frames: frames,
          selectedStateId: 1,
          selectedFrameId: frames.first.id,
          isPlaying: false,
          settings: const AnimationSettings(),
          onSelectFrame: (_) {},
          onAddFrame: () {},
          onDeleteFrame: (_) {},
          onDurationChanged: (_, __) {},
          onFrameReordered: (_, __) {},
          onPlayPause: () {},
          onStop: () {},
          onNextFrame: () {},
          onPreviousFrame: () {},
          onSettingsChanged: (_) {},
          onExpandChanged: () {},
          copyFrame: (_) {},
          onAddState: (_) {},
          onRenameState: (_, __) {},
          onDeleteState: (_) {},
          onDuplicateState: (_) {},
          onCopyState: (_) {},
          onSelectedStateChanged: (_) {},
          onOpenRig: onOpenRig,
          rigLocked: rigLocked,
        ),
      );
    }

    testWidgets('the rig button opens the editor and is hidden without a handler', (tester) async {
      var opened = 0;
      await tester.pumpWidget(timeline(createSampleFrames(2), onOpenRig: () => opened++));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-rig-editor')));
      expect(opened, 1);

      await tester.pumpWidget(timeline(createSampleFrames(2)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-rig-editor')), findsNothing);
    });

    testWidgets('only frames with a rig layer carry the rig badge', (tester) async {
      final plain = createSampleFrames(2);
      final rigged = plain[1].copyWith(layers: [
        Layer(
          layerId: 9,
          id: 'rig',
          name: 'Rig',
          pixels: Uint32List(256),
          stableKey: 'rig:output',
        ),
      ]);
      await tester.pumpWidget(timeline([plain[0], rigged]));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('rig-badge-${plain[0].id}')), findsNothing);
      expect(find.byKey(ValueKey('rig-badge-${rigged.id}')), findsOneWidget);
    });
  });
}
