import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/ui/screens/rig_editor/rig_canvas.dart';
import 'package:picell/ui/screens/rig_editor/rig_editor_screen.dart';

void main() {
  Layer layer(String key, String name) =>
      Layer(layerId: 0, id: 'id-$key', name: name, pixels: Uint32List(16 * 16), stableKey: key);

  late List<Rig?> results;

  Future<void> open(WidgetTester tester, {Rig? rig}) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    results = [];

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => results.add(await RigEditorScreen.show(
                context,
                rig: rig ?? const Rig(id: 'r', stateId: 1),
                restLayers: [layer('body', 'Body'), layer('arm', 'Arm')],
                width: 16,
                height: 16,
                title: 'Walk',
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Drags on the canvas between two canvas-relative offsets from its centre.
  Future<void> drag(WidgetTester tester, Offset from, Offset to) async {
    final centre = tester.getCenter(find.byType(RigCanvas));
    final gesture = await tester.startGesture(centre + from);
    await gesture.moveTo(centre + (from + to) / 2);
    await gesture.moveTo(centre + to);
    await gesture.up();
    await tester.pump();
  }

  testWidgets('shows setup chrome and a hint while the rig is empty', (tester) async {
    await open(tester);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('drag on the canvas'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Arm'), findsOneWidget);
  });

  testWidgets('drawing a bone adds it to the tree and selects it', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();

    await drag(tester, const Offset(-100, -100), const Offset(-100, 100));

    expect(find.text('bone_1'), findsOneWidget);
    expect(find.textContaining('drag on the canvas'), findsNothing);
    // The selected bone's properties are shown.
    expect(find.text('Limit rotation'), findsOneWidget);
  });

  testWidgets('a layer can be bound to a bone from the layers list', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    await drag(tester, const Offset(0, -100), const Offset(0, 100));

    await tester.tap(find.byTooltip('Choose the bone that moves Arm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bone_1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final rig = results.single!;
    expect(rig.bones, hasLength(1));
    expect(rig.parts.single.layerKey, 'arm');
    expect(rig.parts.single.boneId, rig.bones.single.id);
  });

  testWidgets('undo removes the bone again', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    await drag(tester, const Offset(0, -100), const Offset(0, 100));
    expect(find.text('bone_1'), findsOneWidget);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(find.text('bone_1'), findsNothing);
  });

  testWidgets('a bone is drawn from the exact pointer-down point, not after touch slop', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();

    final canvas = tester.getRect(find.byType(RigCanvas));
    final scale = (canvas.width / 16 < canvas.height / 16 ? canvas.width : canvas.height) * 0.9 / 16;
    // Press at the centre of the canvas' pixel (8, 8) and drag three pixels down.
    final origin = canvas.center + Offset(0.5 * scale, 0.5 * scale);
    final gesture = await tester.startGesture(origin);
    await gesture.moveTo(origin + Offset(0, 3 * scale));
    await gesture.up();
    await tester.pump();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final bone = results.single!.bones.single;
    expect(bone.head, const Offset(8.5, 8.5));
    expect(bone.length, closeTo(3, 1e-9));
  });

  testWidgets('dragging a joint with the select tool moves the whole bone by whole pixels', (tester) async {
    await open(tester);
    final canvas = tester.getRect(find.byType(RigCanvas));
    final scale = (canvas.width < canvas.height ? canvas.width : canvas.height) * 0.9 / 16;
    Offset pixel(double x, double y) => canvas.center + Offset((x - 8) * scale, (y - 8) * scale);

    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    var g = await tester.startGesture(pixel(4.5, 4.5));
    await g.moveTo(pixel(4.5, 8.5));
    await g.up();
    await tester.pump();

    await tester.tap(find.byTooltip('Select and move bones (V)'));
    await tester.pump();
    g = await tester.startGesture(pixel(4.5, 4.5));
    await g.moveTo(pixel(5.5, 5.5));
    await g.moveTo(pixel(6.6, 6.4));
    await g.up();
    await tester.pump();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final bone = results.single!.bones.single;
    expect(bone.head, const Offset(6.5, 6.5), reason: 'moved by (2, 2) pixels');
    expect(bone.length, closeTo(4, 1e-9));

    // One drag is one undo step.
  });

  Offset pixelAt(WidgetTester tester, double x, double y) {
    final canvas = tester.getRect(find.byType(RigCanvas));
    final scale = (canvas.width < canvas.height ? canvas.width : canvas.height) * 0.9 / 16;
    return canvas.center + Offset((x - 8) * scale, (y - 8) * scale);
  }

  Future<void> dragBetween(WidgetTester tester, Offset from, Offset to) async {
    final g = await tester.startGesture(from);
    await g.moveTo(Offset.lerp(from, to, 0.5)!);
    await g.moveTo(to);
    await g.up();
    await tester.pump();
  }

  testWidgets('a bone started on the middle of another becomes its child', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    await dragBetween(tester, pixelAt(tester, 4.5, 3.5), pixelAt(tester, 4.5, 11.5));
    // Start on the body, a little off the line, and draw sideways.
    await dragBetween(tester, pixelAt(tester, 4.7, 7.4), pixelAt(tester, 10.5, 7.5));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final bones = results.single!.bones;
    expect(bones, hasLength(2));
    expect(bones[1].parentId, bones[0].id);
    expect(bones[1].head, const Offset(4.5, 7.5), reason: 'joined on the parent\'s line');
  });

  testWidgets('a bone started away from every bone is a free root', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    await dragBetween(tester, pixelAt(tester, 4.5, 3.5), pixelAt(tester, 4.5, 11.5));
    await dragBetween(tester, pixelAt(tester, 11.5, 3.5), pixelAt(tester, 11.5, 11.5));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(results.single!.bones.map((b) => b.parentId), [null, null]);
  });

  testWidgets('selecting a layer then drawing a bone binds the bone to it', (tester) async {
    await open(tester);
    await tester.tap(find.text('Arm'));
    await tester.pump();
    expect(find.byKey(const ValueKey('armed-layer-banner')), findsOneWidget);
    expect(find.textContaining('Next bone moves "Arm"'), findsOneWidget);

    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    await dragBetween(tester, pixelAt(tester, 4.5, 3.5), pixelAt(tester, 4.5, 11.5));

    expect(find.byKey(const ValueKey('armed-layer-banner')), findsNothing, reason: 'one layer, one bone');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final rig = results.single!;
    expect(rig.parts.single.layerKey, 'arm');
    expect(rig.parts.single.boneId, rig.bones.single.id);
  });

  testWidgets('the banner lets go of the armed layer', (tester) async {
    await open(tester);
    await tester.tap(find.text('Arm'));
    await tester.pump();
    await tester.tap(find.byTooltip('Don\'t bind a layer'));
    await tester.pump();
    expect(find.byKey(const ValueKey('armed-layer-banner')), findsNothing);

    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    await dragBetween(tester, pixelAt(tester, 4.5, 3.5), pixelAt(tester, 4.5, 11.5));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(results.single!.parts, isEmpty);
  });

  testWidgets('Cancel closes straight away when nothing changed', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    expect(results, [null]);
  });

  testWidgets('Cancel asks before discarding changes, and can keep editing', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Draw a bone (B)'));
    await tester.pump();
    await drag(tester, const Offset(0, -100), const Offset(0, 100));

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard rig changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    expect(results, [null]);
  });

  testWidgets('narrow screens move the panels into a bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: RigEditorScreen(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: [layer('body', 'Body')],
        width: 16,
        height: 16,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Bones'), findsNothing);

    await tester.tap(find.byTooltip('Bones and layers'));
    await tester.pumpAndSettle();
    expect(find.text('Bones'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  group('animate mode', () {
    const spine = Bone(id: 'spine', name: 'spine', head: Offset(8.5, 12.5), length: 6, restAngle: -90);

    Future<void> openAnimate(WidgetTester tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [spine]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();
    }

    Offset pixel(WidgetTester tester, double x, double y) {
      final canvas = tester.getRect(find.byType(RigCanvas));
      final scale = (canvas.width < canvas.height ? canvas.width : canvas.height) * 0.9 / 16;
      return canvas.center + Offset((x - 8) * scale, (y - 8) * scale);
    }

    testWidgets('the switch shows the timeline, posing tools and hides drawing', (tester) async {
      await openAnimate(tester);
      expect(find.byTooltip('Rotate a bone (R)'), findsOneWidget);
      expect(find.byTooltip('Move a bone (M)'), findsOneWidget);
      expect(find.byTooltip('Draw a bone (B)'), findsNothing);
      expect(find.text('1 / 8'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);
      // Looking at animate mode alone is not a change.
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard rig changes?'), findsNothing);
    });

    testWidgets('rotating a bone keys it on the current frame', (tester) async {
      await openAnimate(tester);
      // Pick the bone, then drag a quarter turn clockwise around its joint:
      // from straight up to straight right.
      final joint = pixel(tester, 8.5, 12.5);
      final up = pixel(tester, 8.5, 8.5);
      final right = pixel(tester, 12.5, 12.5);
      await tester.tapAt(up);
      await tester.pump();

      final g = await tester.startGesture(up);
      await g.moveTo(Offset.lerp(up, right, 0.5)! + (joint - Offset.lerp(up, right, 0.5)!) * 0.3);
      await g.moveTo(right);
      await g.up();
      await tester.pump();

      expect(find.byKey(const ValueKey('key-spine-0')), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final key = results.single!.clips.single.keyframes.single;
      expect(key.time, 0);
      expect(key.rotation, closeTo(90, 1));
    });

    testWidgets('timeline cells move the playhead and the pose panel follows', (tester) async {
      await openAnimate(tester);
      await tester.tap(find.byKey(const ValueKey('cell-spine-3')));
      await tester.pump();
      expect(find.text('4 / 8'), findsOneWidget);
      expect(find.text('Pose · frame 4'), findsOneWidget);

      await tester.tap(find.text('Add key'));
      await tester.pump();
      expect(find.byKey(const ValueKey('key-spine-3')), findsOneWidget);
      expect(find.text('Keyed on this frame'), findsOneWidget);

      await tester.tap(find.text('Remove key'));
      await tester.pump();
      expect(find.byKey(const ValueKey('key-spine-3')), findsNothing);
    });

    testWidgets('clip length and loop are editable', (tester) async {
      await openAnimate(tester);
      await tester.tap(find.byTooltip('More Frames'));
      await tester.pump();
      expect(find.text('1 / 9'), findsOneWidget);
      await tester.tap(find.byTooltip('Looping'));
      await tester.pump();
      expect(find.byTooltip('Plays once'), findsOneWidget);
    });

    testWidgets('playback advances frames and stops when paused', (tester) async {
      await openAnimate(tester);
      await tester.tap(find.byTooltip('Play'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('1 / 8'), findsNothing, reason: 'the playhead moved');
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      final frozen = tester.widget<Text>(find.textContaining(' / 8')).data;
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<Text>(find.textContaining(' / 8')).data, frozen);
    });

    testWidgets('leaving animate mode stops playback', (tester) async {
      await openAnimate(tester);
      await tester.tap(find.byTooltip('Play'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Setup'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Play'), findsNothing);
      // No timer left running: pumping further must not throw or leak.
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('inverse kinematics', () {
    const upper = Bone(id: 'upper', name: 'upper', head: Offset(4.5, 8.5), length: 4);
    const lower = Bone(id: 'lower', name: 'lower', parentId: 'upper', head: Offset(8.5, 8.5), length: 4);
    const arm = IkChain(id: 'ik', name: 'arm_ik', tipBoneId: 'lower');

    Rig armRig({List<IkChain> chains = const [], List<RigClip> clips = const []}) =>
        Rig(id: 'r', stateId: 1, bones: const [upper, lower], ikChains: chains, clips: clips);

    testWidgets('an IK chain is added from the selected bone in setup mode', (tester) async {
      await open(tester, rig: armRig());
      await tester.tap(find.text('lower'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('add-ik-chain')));
      await tester.pump();

      expect(find.text('lower_ik'), findsOneWidget);
      expect(find.byKey(const ValueKey('remove-ik-chain')), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final chain = results.single!.ikChains.single;
      expect(chain.tipBoneId, 'lower');
      expect(chain.boneCount, 2);
    });

    testWidgets('the chain length can be changed and the chain removed', (tester) async {
      await open(tester, rig: armRig(chains: [arm]));
      await tester.tap(find.text('lower'));
      await tester.pump();

      await tester.tap(find.byTooltip('Fewer bones in the chain'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('remove-ik-chain')));
      await tester.pump();
      expect(find.byKey(const ValueKey('add-ik-chain')), findsOneWidget, reason: 'the bone can get a new chain');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(results.single!.ikChains, isEmpty);
    });

    testWidgets('dragging the target ring in animate mode keys it and bends the arm', (tester) async {
      await open(tester, rig: armRig(chains: [arm]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();

      // The ring waits on the hand, the tip of the lower bone.
      await dragBetween(tester, pixelAt(tester, 12.5, 8.5), pixelAt(tester, 8.5, 4.5));

      expect(find.byKey(const ValueKey('ikkey-ik-0')), findsOneWidget, reason: 'the target is keyed on frame 1');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final key = results.single!.clips.single.ikKeyframes.single;
      expect(key.chainId, 'ik');
      expect(key.time, 0);
      expect(key.target.dx, closeTo(8.5, 0.5));
      expect(key.target.dy, closeTo(4.5, 0.5));
    });

    testWidgets('grabbing a bone the chain steers pulls the target along', (tester) async {
      final clip = RigClip(
        id: 'main',
        name: 'x',
        keyframes: const [],
        ikKeyframes: const [IkKeyframe(time: 0, chainId: 'ik', target: Offset(12.5, 8.5))],
      );
      await open(tester, rig: armRig(chains: [arm], clips: [clip]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();

      // The rotate tool is active; take the forearm in the middle and lift it three pixels.
      await dragBetween(tester, pixelAt(tester, 10.5, 8.5), pixelAt(tester, 10.5, 5.5));

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final key = results.single!.clips.single.ikKeyframes.single;
      expect(key.target.dx, closeTo(12.5, 0.5), reason: 'moved by the pointer\'s travel, not placed under it');
      expect(key.target.dy, closeTo(5.5, 0.5));
      expect(results.single!.clips.single.keyframes, isEmpty, reason: 'no rotation key was made on the bone');
    });

    testWidgets('IK chains get their own timeline row, and selecting it shows the chain controls', (tester) async {
      await open(tester, rig: armRig(chains: [arm]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ikcell-ik-2')));
      await tester.pump();
      expect(find.text('3 / 8'), findsOneWidget);
      expect(find.text('Chain'), findsOneWidget);
      expect(find.textContaining('Off: drag the ring'), findsOneWidget);

      await tester.tap(find.text('Key target'));
      await tester.pump();
      expect(find.byKey(const ValueKey('ikkey-ik-2')), findsOneWidget);
      expect(find.text('Target keyed on this frame'), findsOneWidget);
    });

    testWidgets('a bone steered by IK says so in the pose panel', (tester) async {
      final clip = RigClip(
        id: 'main',
        name: 'x',
        ikKeyframes: const [IkKeyframe(time: 0, chainId: 'ik', target: Offset(10.5, 6.5))],
      );
      await open(tester, rig: armRig(chains: [arm], clips: [clip]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('upper').first);
      await tester.pump();
      expect(find.textContaining('Steered by IK'), findsOneWidget);
    });
  });

  group('pose library', () {
    const spine = Bone(id: 'spine', name: 'spine', head: Offset(8.5, 12.5), length: 6, restAngle: -90);

    Future<void> openAnimate(WidgetTester tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [spine]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();
      // Pick the bone and pose it: flipped on frame 1.
      await tester.tap(find.text('spine').first);
      await tester.pump();
      await tester.tap(find.text('Flip horizontally'));
      await tester.pump();
    }

    Future<void> savePoseAs(WidgetTester tester, String name) async {
      await tester.ensureVisible(find.byKey(const ValueKey('save-pose')));
      await tester.tap(find.byKey(const ValueKey('save-pose')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), name);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('saving a pose lists it, and tapping it keys the pose on another frame', (tester) async {
      await openAnimate(tester);
      await savePoseAs(tester, 'Stance');
      expect(find.text('Stance'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('frame-3')));
      await tester.pump();
      expect(find.byKey(const ValueKey('key-spine-3')), findsNothing);
      await tester.ensureVisible(find.text('Stance'));
      await tester.tap(find.text('Stance'));
      await tester.pump();
      expect(find.byKey(const ValueKey('key-spine-3')), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final rig = results.single!;
      expect(rig.poses.single.name, 'Stance');
      expect(rig.clips.single.keyframes.map((k) => (k.time, k.flipX)), containsAll([(0, true), (3, true)]));
    });

    testWidgets('a pose can be renamed and deleted from its menu', (tester) async {
      await openAnimate(tester);
      await savePoseAs(tester, 'Stance');

      await tester.ensureVisible(find.byTooltip('Pose actions'));
      await tester.tap(find.byTooltip('Pose actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Guard');
      await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
      await tester.pumpAndSettle();
      expect(find.text('Guard'), findsOneWidget);

      await tester.tap(find.byTooltip('Pose actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Guard'), findsNothing);
      expect(find.textContaining('Save the pose on this frame'), findsOneWidget);
    });

    testWidgets('the pose library only exists in animate mode', (tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [spine]));
      expect(find.byKey(const ValueKey('save-pose')), findsNothing);
    });

    testWidgets('cancelling the name dialog saves nothing', (tester) async {
      await openAnimate(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('save-pose')));
      await tester.tap(find.byKey(const ValueKey('save-pose')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Save the pose on this frame'), findsOneWidget);
    });
  });

  group('GIF preview', () {
    const spine = Bone(id: 'spine', name: 'spine', head: Offset(8.5, 12.5), length: 6, restAngle: -90);

    testWidgets('shows the baked animation as a looping image once something is keyed', (tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [spine]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('spine').first);
      await tester.pump();
      await tester.tap(find.text('Flip horizontally'));
      await tester.pump();

      await tester.tap(find.byTooltip('Preview as GIF'));
      // Encoding runs on an isolate: let it finish in real time.
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await tester.pump();
      await tester.pump();

      expect(find.text('Animation preview'), findsOneWidget);
      expect(find.byKey(const ValueKey('rig-gif-preview')), findsOneWidget);
      expect(find.byKey(const ValueKey('save-rig-gif')), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Animation preview'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing, reason: 'the progress bar goes away');
    });

    testWidgets('with nothing keyed it says so instead of making an empty GIF', (tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [spine]));
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Preview as GIF'));
      await tester.pump();

      expect(find.textContaining('nothing is keyed yet'), findsOneWidget);
      expect(find.text('Animation preview'), findsNothing);
    });

    testWidgets('the preview is an animate-mode tool', (tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [spine]));
      expect(find.byTooltip('Preview as GIF'), findsNothing);
    });
  });

  /// Scrolls the open dialog's list until [key] is built and on screen.
  Future<void> reveal(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(find.byKey(key), 120, scrollable: find.byType(Scrollable).last);
    await tester.pump();
  }

  group('ready-made skeletons', () {
    Future<void> choose(WidgetTester tester, String id) async {
      await tester.tap(find.byKey(const ValueKey('add-skeleton-preset')));
      await tester.pumpAndSettle();
      await reveal(tester, ValueKey('skeleton-$id'));
      await tester.tap(find.byKey(ValueKey('skeleton-$id')));
      await tester.pumpAndSettle();
    }

    Future<Rig> finish(WidgetTester tester) async {
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      return results.single!;
    }

    testWidgets('the picker lists skeletons and starts placing the one tapped', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('add-skeleton-preset')));
      await tester.pumpAndSettle();
      expect(find.text('Ready-made skeletons'), findsOneWidget);
      expect(find.byKey(const ValueKey('skeleton-humanoid')), findsOneWidget);
      expect(find.textContaining('Humanoid · 16 bones'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('skeleton-humanoid')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('placement-bar')), findsOneWidget);
      expect(find.textContaining('drag the box to move it'), findsOneWidget);
      // Nothing is added until it is confirmed.
      await tester.tap(find.byKey(const ValueKey('placement-cancel')));
      await tester.pump();
      expect(find.byKey(const ValueKey('placement-bar')), findsNothing);
      expect((await finish(tester)).bones, isEmpty);
    });

    testWidgets('the empty bone list offers the picker too', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('empty-skeleton-presets')));
      await tester.pumpAndSettle();
      expect(find.text('Ready-made skeletons'), findsOneWidget);
    });

    testWidgets('adding a skeleton puts all its bones on the rig and says so', (tester) async {
      await open(tester);
      await choose(tester, 'humanoid');
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();

      expect(find.textContaining('Humanoid added: 16 bones'), findsOneWidget);
      expect(find.byKey(const ValueKey('placement-bar')), findsNothing);
      final rig = await finish(tester);
      expect(rig.bones.length, 16);
      expect(rig.bones.map((b) => b.name), containsAll(['hips', 'head', 'arm_l', 'shin_r']));
      expect(rig.ikChains, isEmpty);
    });

    testWidgets('dragging an edge of the box stretches the skeleton', (tester) async {
      await open(tester);
      await choose(tester, 'humanoid');
      // The box starts at 1,1 -> 15,15 on this empty 16 x 16 canvas. Pull its
      // bottom edge up to y = 9.
      await dragBetween(tester, pixelAt(tester, 8, 15), pixelAt(tester, 8, 9));
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();

      final bones = (await finish(tester)).bones;
      final lowest = bones.map((b) => b.tail.dy > b.head.dy ? b.tail.dy : b.head.dy).reduce((a, b) => a > b ? a : b);
      expect(lowest, lessThanOrEqualTo(9.5), reason: 'the whole figure is squashed into the shorter box');
    });

    testWidgets('dragging inside the box moves it, to whole pixels', (tester) async {
      await open(tester);
      await choose(tester, 'humanoid');
      // The box is 1,1 -> 15,15, so the hips start at x = 8.5. Grab it in the
      // middle and take it two pixels to the right.
      await dragBetween(tester, pixelAt(tester, 8, 8), pixelAt(tester, 10, 8));
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();

      final hips = (await finish(tester)).bones.firstWhere((b) => b.name == 'hips');
      expect(hips.head.dx, 10.5);
      expect(hips.head.dy, closeTo(9.5, 1.01), reason: 'the vertical position is unchanged');
    });

    testWidgets('Mirror puts the left limbs on the right', (tester) async {
      await open(tester);
      await choose(tester, 'humanoid');
      await tester.tap(find.byKey(const ValueKey('placement-flip')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();
      final armL = (await finish(tester)).bones.firstWhere((b) => b.name == 'arm_l');
      expect(armL.head.dx, greaterThan(8));
    });

    testWidgets('With IK adds the limb chains', (tester) async {
      await open(tester);
      await choose(tester, 'humanoid');
      await tester.tap(find.byKey(const ValueKey('placement-ik')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();
      expect((await finish(tester)).ikChains.length, 4);
    });

    testWidgets('a part is attached to the selected bone', (tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [
        Bone(id: 'spine', name: 'spine', head: Offset(8.5, 12.5), length: 6, restAngle: -90),
      ]));
      await tester.tap(find.text('spine').first);
      await tester.pump();
      await choose(tester, 'tail');

      expect(find.byKey(const ValueKey('placement-attach')), findsOneWidget);
      expect(find.text('Attach to spine'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();

      final rig = await finish(tester);
      final tail1 = rig.bones.firstWhere((b) => b.name == 'tail_1');
      expect(tail1.parentId, 'spine');
      expect(rig.bones.where((b) => b.name.startsWith('tail')).length, 4);
    });

    testWidgets('turning attach off leaves the part free', (tester) async {
      await open(tester, rig: const Rig(id: 'r', stateId: 1, bones: [
        Bone(id: 'spine', name: 'spine', head: Offset(8.5, 12.5), length: 6, restAngle: -90),
      ]));
      await tester.tap(find.text('spine').first);
      await tester.pump();
      await choose(tester, 'tail');
      await tester.tap(find.byKey(const ValueKey('placement-attach')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();
      final rig = await finish(tester);
      expect(rig.bones.firstWhere((b) => b.name == 'tail_1').parentId, isNull);
    });

    testWidgets('layers named like the new bones are bound, and the message says how many', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Rig? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async => result = await RigEditorScreen.show(
                context,
                rig: const Rig(id: 'r', stateId: 1),
                restLayers: [layer('head', 'Head'), layer('arm', 'Left Arm'), layer('misc', 'Misc')],
                width: 16,
                height: 16,
                title: 'Walk',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await choose(tester, 'humanoid');
      await tester.tap(find.byKey(const ValueKey('placement-place')));
      await tester.pump();
      expect(find.textContaining('2 layers bound by name'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result!.parts.map((p) => p.layerKey).toSet(), {'head', 'arm'});
    });

    testWidgets('Escape drops the placement and Enter adds it', (tester) async {
      await open(tester);
      await choose(tester, 'tail');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const ValueKey('placement-bar')), findsNothing);

      await choose(tester, 'tail');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const ValueKey('placement-bar')), findsNothing);
      expect((await finish(tester)).bones.length, 4);
    });

    testWidgets('the skeleton button is a setup tool', (tester) async {
      await open(tester);
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('add-skeleton-preset')), findsNothing);
    });
  });

  group('ready-made animations', () {
    Rig humanoidRig() {
      var n = 0;
      final built = BonePresetBuilder.build(
        BonePresets.humanoid,
        box: const Rect.fromLTWH(0, 0, 16, 16),
        snap: (o) => Offset(o.dx.floorToDouble() + 0.5, o.dy.floorToDouble() + 0.5),
        newId: () => 'b${n++}',
      );
      return Rig(id: 'r', stateId: 1, bones: built.bones);
    }

    Future<void> openPicker(WidgetTester tester, {Rig? rig}) async {
      await open(tester, rig: rig ?? humanoidRig());
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('motion-presets-button')));
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, String id) async {
      await reveal(tester, ValueKey('motion-$id'));
      await tester.tap(find.byKey(ValueKey('motion-$id')));
      await tester.pumpAndSettle();
    }

    testWidgets('the picker lists animations with what each needs', (tester) async {
      await openPicker(tester);
      expect(find.text('Ready-made animations'), findsOneWidget);
      expect(find.byKey(const ValueKey('motion-walk')), findsOneWidget);
      expect(find.text('11 of 11 bones found'), findsWidgets);
      await reveal(tester, const ValueKey('motion-quadruped_walk'));
      expect(find.textContaining('No bones named like'), findsWidgets);
      await reveal(tester, const ValueKey('motion-sway'));
      expect(find.text('Select a bone first'), findsWidgets);
    });

    testWidgets('choosing a walk keys the bones, sets the clip, and says so', (tester) async {
      await openPicker(tester);
      await pick(tester, 'walk');

      expect(find.textContaining('"Walk" applied to 11 bones'), findsOneWidget);
      expect(find.text('1 / 8'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final clip = results.single!.clips.single;
      expect(clip.length, 8);
      expect(clip.fps, 10);
      expect(clip.keyframes.map((k) => k.boneId).toSet().length, 11);
    });

    testWidgets('mirroring turns it to the other side', (tester) async {
      await openPicker(tester);
      await tester.tap(find.byKey(const ValueKey('motion-mirror')));
      await tester.pump();
      await pick(tester, 'wave');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final rig = results.single!;
      final armL = rig.bones.firstWhere((b) => b.name == 'arm_l');
      final armR = rig.bones.firstWhere((b) => b.name == 'arm_r');
      final keyed = rig.clips.single.keyframes.map((k) => k.boneId).toSet();
      expect(keyed, contains(armL.id));
      expect(keyed, isNot(contains(armR.id)));
    });

    testWidgets('strength scales the swing', (tester) async {
      await openPicker(tester);
      final slider = tester.widget<Slider>(find.byKey(const ValueKey('motion-intensity')));
      slider.onChanged!(2);
      await tester.pump();
      expect(find.text('200%'), findsWidgets);
      await pick(tester, 'walk');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final rig = results.single!;
      final thigh = rig.bones.firstWhere((b) => b.name == 'thigh_l');
      final peak = rig.clips.single.keyframes
          .where((k) => k.boneId == thigh.id)
          .map((k) => k.rotation.abs())
          .reduce((a, b) => a > b ? a : b);
      expect(peak, closeTo(56, 1), reason: 'the walk swings 28 degrees at 100%');
    });

    testWidgets('a rig without the bones is told what to name them', (tester) async {
      await openPicker(tester, rig: const Rig(id: 'r', stateId: 1, bones: [
        Bone(id: 'x', name: 'blob', head: Offset(8.5, 8.5), length: 3),
      ]));
      await pick(tester, 'walk');
      expect(find.textContaining('No bones for "Walk"'), findsOneWidget);
      expect(find.textContaining('hips, spine, head'), findsOneWidget, reason: 'it names what to look for');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(results.single!.clips, isEmpty, reason: 'nothing was changed');
    });

    testWidgets('an any-bone animation works on the selected bone', (tester) async {
      await open(tester, rig: humanoidRig());
      await tester.tap(find.text('Animate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('head').first);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('motion-presets-button')));
      await tester.pumpAndSettle();
      await pick(tester, 'sway');
      expect(find.textContaining('"Sway" applied to 1 bone.'), findsOneWidget);
    });

    testWidgets('closing the picker changes nothing, and undo takes an applied animation back', (tester) async {
      await openPicker(tester);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard rig changes?'), findsNothing, reason: 'nothing was changed');

      await openPicker(tester);
      await pick(tester, 'walk');
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(results.last!.clips, isEmpty);
    });

    testWidgets('the animations button is an animate-mode tool', (tester) async {
      await open(tester, rig: humanoidRig());
      expect(find.byKey(const ValueKey('motion-presets-button')), findsNothing);
    });
  });
}
