import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/pixel/rig/presets/motion_catalog.dart';
import 'package:picell/pixel/rig/presets/motion_presets.dart';

void main() {
  var n = 0;
  List<Bone> placed(BonePreset p, {Rect box = const Rect.fromLTWH(0, 0, 64, 64)}) => BonePresetBuilder.build(
        p,
        box: box,
        snap: (o) => Offset(o.dx.floorToDouble() + 0.5, o.dy.floorToDouble() + 0.5),
        newId: () => 'id${n++}',
      ).bones;

  Bone bone(String id, String name, {String? parent}) =>
      Bone(id: id, name: name, parentId: parent, head: Offset.zero, length: 1);

  MotionResult build(MotionPreset p, List<Bone> bones,
          {double h = 64, double intensity = 1, bool mirror = false, String? selected}) =>
      MotionBuilder.build(p,
          bones: bones, canvasHeight: h, intensity: intensity, mirror: mirror, selectedBoneId: selected);

  List<RigKeyframe> keysOf(MotionResult r, Bone b) =>
      r.keyframes.where((k) => k.boneId == b.id).toList()..sort((x, y) => x.time.compareTo(y.time));

  group('Wave', () {
    test('shapes: sine swings both ways, lift only up, bounce folds over', () {
      const sine = Wave(amplitude: 10);
      const lift = Wave(amplitude: 10, shape: WaveShape.lift);
      const bounce = Wave(amplitude: 10, shape: WaveShape.bounce);
      expect(sine.at(0.25), closeTo(10, 1e-9));
      expect(sine.at(0.75), closeTo(-10, 1e-9));
      expect(lift.at(0.25), closeTo(10, 1e-9));
      expect(lift.at(0.75), 0);
      expect(bounce.at(0.25), closeTo(10, 1e-9));
      expect(bounce.at(0.75), closeTo(10, 1e-9), reason: 'peaks twice a cycle');
      expect(bounce.at(0.5), closeTo(0, 1e-9));
    });

    test('bias, cycles, phase and the chain shifts', () {
      expect(const Wave(bias: 5).at(0.3), 5);
      expect(const Wave(amplitude: 1, cycles: 2).at(0.125), closeTo(1, 1e-9));
      expect(const Wave(amplitude: 1, phase: 0.25).at(0), closeTo(1, 1e-9));
      expect(const Wave(amplitude: 2).at(0, phaseShift: 0.25, amplitudeScale: 3), closeTo(6, 1e-9));
    });
  });

  test('front idle breathes symmetrically with quiet legs and a seamless neutral seam', () {
    const idle = MotionPresets.frontIdle;
    expect(MotionPresets.byId('front_idle'), idle);
    expect(idle.loop, isTrue);
    expect(idle.frames / idle.fps, 2);
    Wave motion(String role) => idle.tracks.firstWhere((t) => t.role == role).rotation!;
    for (final t in [0.0, .25, .5, .75, 1.0]) {
      expect(motion('arm_l').at(t), closeTo(-motion('arm_r').at(t), 1e-9));
      expect(motion('forearm_l').at(t), closeTo(-motion('forearm_r').at(t), 1e-9));
      for (final role in ['spine', 'head', 'thigh_l', 'thigh_r', 'shin_l', 'shin_r']) {
        expect(motion(role).at(t), 0);
      }
    }
    for (final track in idle.tracks) {
      expect(track.tx, isNull);
      for (final wave in [track.rotation, track.ty].whereType<Wave>()) {
        expect(wave.at(0), closeTo(0, 1e-9));
        expect(wave.at(1), closeTo(wave.at(0), 1e-9));
      }
    }
    expect(idle.tracks.first.ty!.at(.5), greaterThan(0));
    expect(idle.tracks.first.tx, isNull);
    expect(idle.tracks.first.rotation!.at(.5), 0);
    final bones = placed(BonePresets.humanoid);
    final normal = build(idle, bones);
    final half = build(idle, bones, intensity: .5);
    final mirrored = build(idle, bones, mirror: true);
    expect(normal.missing, isEmpty);
    expect(mirrored.missing, isEmpty);
    for (var i = 0; i < normal.keyframes.length; i++) {
      expect(half.keyframes[i].rotation, closeTo(normal.keyframes[i].rotation * .5, 1e-9));
    }
  });

  group('front-facing locomotion', () {
    test('front walk and run are available with looping timing and no lean bias', () {
      expect(MotionPresets.byId('front_walk'), MotionPresets.frontWalk);
      expect(MotionPresets.byId('front_run'), MotionPresets.frontRun);
      expect(MotionPresets.frontRun.fps, greaterThan(MotionPresets.frontWalk.fps));
      for (final preset in [MotionPresets.frontWalk, MotionPresets.frontRun]) {
        expect(preset.loop, isTrue);
        expect(preset.tracks.firstWhere((t) => t.role == 'spine').rotation!.bias, 0);
        expect(preset.tracks.where((t) => t.role != 'hips').every((t) => t.tx == null && t.ty == null), isTrue,
            reason: 'limbs must rotate around their connected joints');
        for (final track in preset.tracks) {
          for (final wave in [track.rotation, track.tx, track.ty].whereType<Wave>()) {
            expect(wave.at(0), closeTo(wave.at(1), 1e-9));
          }
        }
      }
    });

    test('front steps alternate left and right with opposite arm swings', () {
      for (final preset in [MotionPresets.frontWalk, MotionPresets.frontRun]) {
        Wave motion(String role) => preset.tracks.firstWhere((t) => t.role == role).rotation!;
        expect(motion('shin_l').at(0).abs(), greaterThan(0));
        expect(motion('shin_r').at(0).abs(), closeTo(0, 1e-9));
        expect(motion('shin_r').at(.5).abs(), greaterThan(0));
        expect(motion('shin_l').at(.5).abs(), closeTo(0, 1e-9));
        expect(motion('arm_r').at(0).abs(), greaterThan(0));
        expect(motion('arm_l').at(.5).abs(), greaterThan(0));
      }
      final walk = MotionPresets.frontWalk.tracks.firstWhere((t) => t.role == 'shin_l').rotation!;
      final run = MotionPresets.frontRun.tracks.firstWhere((t) => t.role == 'shin_l').rotation!;
      expect(run.at(0).abs(), greaterThan(walk.at(0).abs()));
    });

    test('frontal presets support strength and mirror controls', () {
      final bones = placed(BonePresets.humanoid);
      for (final preset in [MotionPresets.frontWalk, MotionPresets.frontRun]) {
        final normal = build(preset, bones);
        final half = build(preset, bones, intensity: .5);
        final mirrored = build(preset, bones, mirror: true);
        expect(normal.missing, isEmpty);
        expect(mirrored.missing, isEmpty);
        expect(normal.frames, 12);
        expect(normal.loop, isTrue);
        for (var i = 0; i < normal.keyframes.length; i++) {
          expect(half.keyframes[i].rotation, closeTo(normal.keyframes[i].rotation * .5, 1e-9));
        }
      }
    });
  });

  group('front-facing one-shot actions', () {
    test('jump and attack are discoverable, non-looping, centered and recover to rest', () {
      expect(MotionPresets.byId('front_jump'), MotionPresets.frontJump);
      expect(MotionPresets.byId('front_attack'), MotionPresets.frontAttack);
      final bones = placed(BonePresets.humanoid);
      for (final preset in [MotionPresets.frontJump, MotionPresets.frontAttack]) {
        final result = build(preset, bones);
        expect(result.missing, isEmpty);
        expect(result.loop, isFalse);
        for (final track in preset.tracks) {
          expect(track.keys.first.t, 0);
          expect(track.keys.last.t, 1);
          expect(track.keys.last.rotation, 0);
          expect(track.keys.every((key) => key.tx == 0), isTrue);
          if (track.role != 'hips') expect(track.keys.every((key) => key.ty == 0), isTrue);
        }
        for (final bone in result.matched.values) {
          final keys = result.keyframes.where((k) => k.boneId == bone.id).toList();
          expect(keys.first.time, 0);
          expect(keys.last.time, preset.frames - 1);
          expect(keys.last.rotation, 0);
          expect(keys.last.translation, Offset.zero);
        }
      }
    });

    test('front jump crouches, rises, lands and uses symmetric limb bends', () {
      const jump = MotionPresets.frontJump;
      final hips = jump.tracks.firstWhere((t) => t.role == 'hips').keys;
      expect(hips.firstWhere((k) => k.t == .18).ty, greaterThan(0));
      expect(hips.firstWhere((k) => k.t == .5).ty, lessThan(0));
      expect(hips.firstWhere((k) => k.t == .82).ty, greaterThan(0));
      for (final role in ['thigh', 'shin', 'arm', 'forearm']) {
        final left = jump.tracks.firstWhere((t) => t.role == '${role}_l').keys;
        final right = jump.tracks.firstWhere((t) => t.role == '${role}_r').keys;
        for (var i = 0; i < left.length; i++) {
          expect(left[i].t, right[i].t);
          expect(left[i].rotation, -right[i].rotation);
        }
      }
    });

    test('front attack has a windup, cross-body follow-through and mirrors to the left', () {
      const preset = MotionPresets.frontAttack;
      final arm = preset.tracks.firstWhere((t) => t.role == 'arm_r').keys;
      expect(arm.firstWhere((k) => k.t == .25).rotation, lessThan(-90));
      expect(arm.firstWhere((k) => k.t == .58).rotation, greaterThan(0));
      final bones = placed(BonePresets.humanoid);
      for (final action in [MotionPresets.frontJump, preset]) {
        final normal = build(action, bones);
        final half = build(action, bones, intensity: .5);
        final mirrored = build(action, bones, mirror: true);
        expect(mirrored.missing, isEmpty);
        for (var i = 0; i < normal.keyframes.length; i++) {
          expect(half.keyframes[i].rotation, closeTo(normal.keyframes[i].rotation * .5, 1e-9));
          expect(mirrored.keyframes[i].rotation, closeTo(-normal.keyframes[i].rotation, 1e-9));
        }
        expect(mirrored.matched['arm_r']!.name, 'arm_l');
      }
    });
  });

  group('the catalogue', () {
    test('has unique ids, sane timing, and tracks', () {
      expect({for (final p in MotionPresets.all) p.id}.length, MotionPresets.all.length);
      for (final p in MotionPresets.all) {
        expect(p.frames, inInclusiveRange(2, 60), reason: p.name);
        expect(p.fps, inInclusiveRange(1, 60), reason: p.name);
        expect(p.tracks, isNotEmpty, reason: p.name);
        expect(p.name, isNotEmpty);
        expect(p.description, isNotEmpty);
      }
      expect(MotionPresets.byId('walk'), MotionPresets.walk);
      expect(MotionPresets.byId('nope'), isNull);
    });

    test('every role an animation uses is a bone some skeleton preset really has', () {
      final names = {
        for (final bp in BonePresets.all)
          for (final b in bp.bones) b.name
      };
      for (final p in MotionPresets.all.where((p) => p.target == MotionTarget.roles)) {
        for (final role in p.roles) {
          expect(names.contains(role), isTrue, reason: '${p.name} uses "$role"');
        }
      }
    });

    test('each animation finds all of its bones on the skeleton it is made for', () {
      final cases = {
        'idle': BonePresets.humanoid,
        'front_idle': BonePresets.humanoid,
        'walk': BonePresets.humanoid,
        'run': BonePresets.humanoid,
        'front_walk': BonePresets.humanoid,
        'front_run': BonePresets.humanoid,
        'front_jump': BonePresets.humanoid,
        'front_attack': BonePresets.humanoid,
        'jump': BonePresets.humanoid,
        'wave': BonePresets.humanoid,
        'attack': BonePresets.humanoid,
        'quadruped_walk': BonePresets.quadruped,
        'bird_flap': BonePresets.bird,
        'fish_swim': BonePresets.fish,
      };
      for (final e in cases.entries) {
        final preset = MotionPresets.byId(e.key)!;
        final r = build(preset, placed(e.value));
        expect(r.missing, isEmpty, reason: '${preset.name} on ${e.value.name}');
        expect(r.isEmpty, isFalse);
      }
    });

    test('the simple humanoid runs everything except what needs a hand', () {
      final bones = placed(BonePresets.humanoidSimple);
      for (final id in [
        'idle',
        'walk',
        'run',
        'front_idle',
        'front_walk',
        'front_run',
        'front_jump',
        'front_attack',
        'jump',
        'attack'
      ]) {
        expect(build(MotionPresets.byId(id)!, bones).missing, isEmpty, reason: id);
      }
      expect(build(MotionPresets.wave, bones).missing, ['hand_r']);
    });

    test('keys are inside the clip and rotations are believable', () {
      final skeletons = [BonePresets.humanoid, BonePresets.quadruped, BonePresets.bird, BonePresets.fish];
      for (final p in MotionPresets.all.where((p) => p.target == MotionTarget.roles)) {
        for (final sk in skeletons) {
          final r = build(p, placed(sk));
          for (final k in r.keyframes) {
            expect(k.time, inInclusiveRange(0, p.frames - 1), reason: p.name);
            expect(k.rotation.abs(), lessThanOrEqualTo(180), reason: p.name);
          }
        }
      }
    });
  });

  group('coverage', () {
    test('counts how many roles a rig can supply', () {
      final bones = [bone('1', 'head'), bone('2', 'arm_l'), bone('3', 'tail')];
      final c = MotionBuilder.coverage(MotionPresets.wave, bones);
      expect(c.total, 5);
      expect(c.matched, 1, reason: 'only the head (arm_r, forearm_r... are absent)');
      expect(MotionBuilder.coverage(MotionPresets.wave, bones, mirror: true).matched, 2,
          reason: 'mirrored, it looks for arm_l too');
      expect(MotionBuilder.coverage(MotionPresets.sway, bones), (matched: 0, total: 0), reason: 'selection based');
    });

    test('mirroring looks for the other side', () {
      final bones = [bone('1', 'arm_l'), bone('2', 'forearm_l'), bone('3', 'hand_l')];
      expect(MotionBuilder.coverage(MotionPresets.wave, bones).matched, 0);
      expect(MotionBuilder.coverage(MotionPresets.wave, bones, mirror: true).matched, 3);
    });
  });

  group('building', () {
    final humanoid = placed(BonePresets.humanoid);
    Bone named(String name) => humanoid.firstWhere((b) => b.name == name);

    test('waves give one key per frame for each bone found', () {
      final r = build(MotionPresets.walk, humanoid);
      final thigh = keysOf(r, named('thigh_l'));
      expect(thigh.map((k) => k.time), [for (var i = 0; i < 8; i++) i]);
      expect(r.frames, 8);
      expect(r.fps, 10);
      expect(r.loop, isTrue);
    });

    test('the two legs of a walk are half a stride apart', () {
      final r = build(MotionPresets.walk, humanoid);
      final left = keysOf(r, named('thigh_l')), right = keysOf(r, named('thigh_r'));
      for (var i = 0; i < 8; i++) {
        expect(left[i].rotation, closeTo(right[(i + 4) % 8].rotation, 1e-9), reason: 'frame $i');
      }
      expect(left.map((k) => k.rotation).reduce(math.max), greaterThan(20));
      expect(left.map((k) => k.rotation).reduce(math.min), lessThan(-20));
    });

    test('a walk bobs the hips up (never down) by a few pixels', () {
      final r = build(MotionPresets.walk, humanoid);
      final ys = keysOf(r, named('hips')).map((k) => k.translation.dy);
      expect(ys.reduce(math.max), lessThanOrEqualTo(0));
      expect(ys.reduce(math.min), lessThan(-0.5));
    });

    test('intensity scales rotations and shifts', () {
      final normal = keysOf(build(MotionPresets.walk, humanoid), named('thigh_l'));
      final half = keysOf(build(MotionPresets.walk, humanoid, intensity: 0.5), named('thigh_l'));
      final double2 = keysOf(build(MotionPresets.walk, humanoid, intensity: 2), named('thigh_l'));
      for (var i = 0; i < 8; i++) {
        expect(half[i].rotation, closeTo(normal[i].rotation / 2, 1e-9));
        expect(double2[i].rotation, closeTo(normal[i].rotation * 2, 1e-9));
      }
      expect(build(MotionPresets.walk, humanoid, intensity: 0).keyframes.every((k) => k.rotation == 0), isTrue);
    });

    test('mirror swaps the sides and turns the rotations around', () {
      final normal = build(MotionPresets.wave, humanoid);
      final mirrored = build(MotionPresets.wave, humanoid, mirror: true);
      expect(keysOf(normal, named('arm_r')).first.rotation, -150);
      expect(keysOf(mirrored, named('arm_l')).first.rotation, 150, reason: 'the left arm waves instead');
      expect(keysOf(mirrored, named('arm_r')), isEmpty);
      expect(mirrored.matched['arm_r'], named('arm_l'), reason: 'role to the bone found for it');
    });

    test('mirror also flips sideways shifts', () {
      final normal = keysOf(build(MotionPresets.attack, humanoid), named('hips'));
      final mirrored = keysOf(build(MotionPresets.attack, humanoid, mirror: true), named('hips'));
      expect(normal.map((k) => k.translation.dx).reduce(math.max), greaterThan(0));
      expect(mirrored.map((k) => k.translation.dx).reduce(math.min), lessThan(0));
    });

    test('shifts follow the canvas height, but never vanish on a small sprite', () {
      final big = keysOf(build(MotionPresets.walk, humanoid, h: 128), named('hips'));
      final small = keysOf(build(MotionPresets.walk, humanoid, h: 16), named('hips'));
      expect(big.map((k) => k.translation.dy.abs()).reduce(math.max), closeTo(0.02 * 128, 1e-6));
      // 2% of 16 is 0.32 px: rounded up to a whole pixel step.
      expect(small.map((k) => k.translation.dy.abs()).reduce(math.max), 1);
    });

    test('keyed motions put poses on the frames they name, easing between', () {
      const jump = MotionPresets.jump;
      final hips = keysOf(build(jump, humanoid), named('hips'));
      expect(hips.first.time, 0);
      expect(hips.last.time, jump.frames - 1, reason: 'a one-shot motion reaches its last frame');
      expect(hips.every((k) => k.easing == RigEasing.easeInOut), isTrue);
      // The apex is the highest point.
      final apex = hips.reduce((a, b) => a.translation.dy < b.translation.dy ? a : b);
      expect(apex.time, (0.5 * (jump.frames - 1)).round());
    });

    test('a looping keyed motion never uses the frame the loop returns to', () {
      const loopy = MotionPreset(
        id: 'x',
        name: 'x',
        description: 'x',
        category: 'x',
        frames: 4,
        fps: 8,
        tracks: [
          MotionTrack('head', keys: [MotionKey(0), MotionKey(0.5, rotation: 10), MotionKey(1)])
        ],
      );
      final times = keysOf(build(loopy, humanoid), named('head')).map((k) => k.time);
      expect(times, [0, 2], reason: 'key t=1 wraps onto frame 0 instead of a fifth frame');
    });

    test('missing roles are reported and left out', () {
      final r = build(MotionPresets.walk, [named('hips'), named('spine')]);
      expect(r.matched.keys, ['hips', 'spine']);
      expect(r.missing, contains('thigh_l'));
      expect(r.keyframes.map((k) => k.boneId).toSet(), {named('hips').id, named('spine').id});
    });

    test('nothing to animate gives an empty result', () {
      expect(build(MotionPresets.walk, const []).isEmpty, isTrue);
    });
  });

  group('selection based motions', () {
    final tail = placed(BonePresets.tail);
    Bone t(int i) => tail.firstWhere((b) => b.name == 'tail_$i');

    test('need a selected bone', () {
      expect(build(MotionPresets.sway, tail).isEmpty, isTrue);
      expect(build(MotionPresets.sway, tail, selected: 'ghost').isEmpty, isTrue);
    });

    test('a single-bone motion moves only the selected bone', () {
      final r = build(MotionPresets.sway, tail, selected: t(2).id);
      expect(r.keyframes.map((k) => k.boneId).toSet(), {t(2).id});
      expect(r.keyframes.length, MotionPresets.sway.frames);
    });

    test('a chain motion reaches every bone below, later and larger the further it is', () {
      final r = build(MotionPresets.followThrough, tail, selected: t(1).id);
      expect(r.keyframes.map((k) => k.boneId).toSet(), {for (var i = 1; i <= 4; i++) t(i).id});

      double peak(Bone b) => keysOf(r, b).map((k) => k.rotation.abs()).reduce(math.max);
      expect(peak(t(2)), greaterThan(peak(t(1))));
      expect(peak(t(4)), greaterThan(peak(t(3))));

      // The wave arrives later down the chain: the peak frame moves along.
      int peakFrame(Bone b) => keysOf(r, b).reduce((a, c) => a.rotation >= c.rotation ? a : c).time;
      expect(peakFrame(t(1)), isNot(peakFrame(t(4))));
    });

    test('selecting a bone in the middle starts the wave there', () {
      final r = build(MotionPresets.followThrough, tail, selected: t(3).id);
      expect(r.keyframes.map((k) => k.boneId).toSet(), {t(3).id, t(4).id});
    });

    test('a bob moves the selected bone up and down', () {
      final r = build(MotionPresets.bob, tail, selected: t(1).id);
      final ys = r.keyframes.map((k) => k.translation.dy);
      expect(ys.reduce(math.min), lessThan(0));
      expect(ys.reduce(math.max), greaterThan(0));
    });
  });
}
