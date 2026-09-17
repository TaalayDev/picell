import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/animation_frame_controller.dart';
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

  List<AnimationFrame> createSampleFrames(int count, {int stateId = 1, int width = 16, int height = 16}) {
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

  testWidgets('AnimationTimeline frames scroll horizontally in a ListView', (tester) async {
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
      (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalListViewFinder, findsOneWidget);

    // Verify frame index badge is visible
    expect(find.text('1'), findsWidgets);

    // Tap frame 2 to select it
    final frame2Finder = find.byKey(const ValueKey(2));
    expect(frame2Finder, findsOneWidget);
    await tester.tap(frame2Finder);
    await tester.pumpAndSettle();

    expect(selectedFrameId, 2);
  });

  testWidgets('AnimationTimeline frames support horizontal scrolling without overflow', (tester) async {
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
      (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalListViewFinder, findsOneWidget);

    // Scroll horizontally to the right
    await tester.drag(horizontalListViewFinder, const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Later frames should now be visible after scrolling without any overflow
    expect(tester.takeException(), isNull);
  });
}
