import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/pixel/rig/presets/motion_catalog.dart';
import 'package:picell/pixel/rig/presets/motion_presets.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_solver.dart';

void main() {
  const presets = [
    MotionPresets.frontHurt,
    MotionPresets.frontCrouch,
    MotionPresets.frontLand,
    MotionPresets.frontInteract,
    MotionPresets.frontCelebrate,
    MotionPresets.dash,
    MotionPresets.fall
  ];
  var id = 0;
  final bones = BonePresetBuilder.build(BonePresets.humanoid,
      box: const Rect.fromLTWH(0, 0, 64, 64), snap: (p) => p, newId: () => 'bone-${id++}').bones;
  Bone named(String name) => bones.firstWhere((b) => b.name == name);
  MotionResult build(MotionPreset p, {bool mirror = false, double intensity = 1}) =>
      MotionBuilder.build(p, bones: bones, canvasHeight: 64, mirror: mirror, intensity: intensity);
  for (final p in presets) {
    test('${p.name} is discoverable and fits all humanoid roles', () {
      expect(MotionPresets.byId(p.id), p);
      expect(MotionPresets.all.where((v) => v.id == p.id), hasLength(1));
      final r = build(p);
      expect(r.missing, isEmpty);
      expect(r.matched, hasLength(11));
      expect(
          r.keyframes.every((k) =>
              k.time >= 0 &&
              k.time < p.frames &&
              k.rotation.isFinite &&
              k.translation.dx.isFinite &&
              k.translation.dy.isFinite),
          isTrue);
      expect(r.keyframes.map((k) => (k.boneId, k.time)).toSet(), hasLength(r.keyframes.length));
      if (p.id.startsWith('front_')) {
        expect(p.legControls, isTrue);
        expect(p.plantFeet, isFalse);
        expect(p.lockedRoles, isEmpty);
      }
    });
    test('${p.name} mirrors limb roles, rotations and horizontal shifts', () {
      final normal = build(p), mirrored = build(p, mirror: true);
      for (final track in p.tracks) {
        final role = track.role;
        final opposite = role.endsWith('_l')
            ? '${role.substring(0, role.length - 2)}_r'
            : role.endsWith('_r')
                ? '${role.substring(0, role.length - 2)}_l'
                : role;
        final source = normal.keyframes.where((k) => k.boneId == named(role).id).toList();
        final target = mirrored.keyframes.where((k) => k.boneId == named(opposite).id).toList();
        expect(target, hasLength(source.length));
        for (var i = 0; i < source.length; i++) {
          expect(target[i].time, source[i].time);
          expect(target[i].rotation, closeTo(-source[i].rotation, 1e-8));
          expect(target[i].translation.dx, closeTo(-source[i].translation.dx, 1e-8));
          expect(target[i].translation.dy, closeTo(source[i].translation.dy, 1e-8));
        }
      }
    });
    test('${p.name} respects strength and configured timing', () {
      final normal = build(p), half = build(p, intensity: .5);
      for (var i = 0; i < normal.keyframes.length; i++) {
        expect(half.keyframes[i].rotation, closeTo(normal.keyframes[i].rotation * .5, 1e-8));
      }
      for (final count in [1, 2, 24]) {
        final c =
            RigEditorController(rig: Rig(id: 'r', stateId: 1, bones: bones), restLayers: [], width: 64, height: 64)
              ..mode = RigMode.animate;
        final configured = p.copyWith(frames: count, fps: 15, loop: false);
        c.applyMotion(configured);
        expect(c.activeClip.length, count);
        expect(c.activeClip.fps, 15);
        expect(c.activeClip.loop, isFalse);
        expect(c.activeClip.keyframes.every((k) => k.time >= 0 && k.time < count), isTrue);
        c.dispose();
      }
    });
  }
  test('recovering one-shots end in a neutral pose', () {
    for (final p in [
      MotionPresets.frontHurt,
      MotionPresets.frontLand,
      MotionPresets.frontInteract,
      MotionPresets.dash
    ]) {
      final result = build(p);
      final clip = RigClip(id: 'clip', name: p.name, length: p.frames, loop: false, keyframes: result.keyframes);
      final finalPose = PoseInterpolator.sample(clip, bones, (p.frames - 1).toDouble());
      expect(finalPose.values.every((pose) => pose.rotation.abs() < 1e-8 && pose.translation.distance < 1e-8), isTrue,
          reason: p.name);
      expect(result.keyframes.any((k) => k.rotation.abs() > 10), isTrue, reason: '${p.name} has a visible action');
    }
  });
  test('crouch lowers the hips and holds its final pose', () {
    final p = MotionPresets.frontCrouch, r = build(p);
    final clip = RigClip(id: 'clip', name: p.name, length: p.frames, loop: false, keyframes: r.keyframes);
    final finalPose = PoseInterpolator.sample(clip, bones, 100);
    expect(finalPose[named('hips').id]!.translation.dy, greaterThan(0));
    expect(finalPose[named('thigh_l').id]!.rotation, greaterThan(0));
    expect(finalPose[named('thigh_r').id]!.rotation, lessThan(0));
    expect(finalPose, PoseInterpolator.sample(clip, bones, p.frames - 1));
  });
  test('celebration and fall loop without accumulating position', () {
    for (final p in [MotionPresets.frontCelebrate, MotionPresets.fall]) {
      expect(p.loop, isTrue);
      final r = build(p), clip = RigClip(id: 'clip', name: p.name, length: p.frames, keyframes: build(p).keyframes);
      expect(PoseInterpolator.sample(clip, bones, 0), PoseInterpolator.sample(clip, bones, p.frames * 10.0));
      if (p == MotionPresets.fall) expect(r.keyframes.every((k) => k.translation == Offset.zero), isTrue);
    }
  });
  test('celebration keeps the raised hands inside the character canvas', () {
    const p = MotionPresets.frontCelebrate;
    final rig = Rig(id: 'r', stateId: 1, bones: bones);
    final clip = RigClip(id: 'clip', name: p.name, length: p.frames, keyframes: build(p).keyframes);
    for (var frame = 0; frame < p.frames; frame++) {
      final world = RigSolver.solveClip(rig, clip, frame.toDouble()).world;
      for (final role in ['hand_l', 'hand_r']) {
        final hand = named(role);
        for (final point in [hand.head, hand.tail]) {
          final shown = world[hand.id]!.apply(point);
          expect(shown.dx, inInclusiveRange(0, 64));
          expect(shown.dy, inInclusiveRange(0, 64));
        }
      }
    }
  });

  test('new front actions can opt into planting and joint locks and release them for dash', () {
    final c = RigEditorController(rig: Rig(id: 'r', stateId: 1, bones: bones), restLayers: [], width: 64, height: 64)
      ..mode = RigMode.animate;
    addTearDown(c.dispose);
    for (final p in presets.where((p) => p.id.startsWith('front_'))) {
      c.applyMotion(p.copyWith(plantFeet: true, lockedRoles: MotionPreset.legJointRoles));
      expect(c.activeClip.freezes, hasLength(p.frames * 6));
      expect(c.activeClip.ikKeyframes.where((k) => k.planted), hasLength(p.frames * 2));
      for (var f = 0; f < p.frames; f++) {
        c.setTime(f);
        for (final role in ['foot_l', 'foot_r']) {
          expect((c.displayBone(named(role).id)!.tail - named(role).tail).distance, lessThan(1e-8));
        }
      }
      final saved = c.rig;
      c.applyMotion(MotionPresets.dash);
      expect(c.activeClip.freezes, isEmpty);
      expect(c.activeClip.ikKeyframes.where((k) => k.planted), isEmpty);
      c.undo();
      expect(c.rig, saved);
    }
  });
}
