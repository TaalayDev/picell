import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/pixel/rig/presets/name_tokens.dart';

void main() {
  Offset snap(Offset p) => Offset(p.dx.floorToDouble() + 0.5, p.dy.floorToDouble() + 0.5);

  var n = 0;
  String newId() => 'id${n++}';
  setUp(() => n = 0);

  BuiltPreset build(
    BonePreset p, {
    Rect box = const Rect.fromLTWH(0, 0, 64, 64),
    bool flip = false,
    bool withIk = false,
    String? attachTo,
    Set<String> taken = const {},
  }) =>
      BonePresetBuilder.build(
        p,
        box: box,
        snap: snap,
        newId: newId,
        flip: flip,
        withIk: withIk,
        attachTo: attachTo,
        takenNames: taken,
      );

  group('the presets that come with the editor', () {
    for (final preset in BonePresets.all) {
      group(preset.name, () {
        test('are laid out inside the unit box, parents first, with unique names', () {
          final seen = <String>{};
          for (final b in preset.bones) {
            expect(b.parent == null || seen.contains(b.parent), isTrue, reason: '${b.name} comes before its parent ${b.parent}');
            expect(seen.add(b.name), isTrue, reason: 'duplicate name ${b.name}');
            for (final p in [b.head, b.tail]) {
              expect(p.dx, inInclusiveRange(0, 1), reason: b.name);
              expect(p.dy, inInclusiveRange(0, 1), reason: b.name);
            }
            expect((b.tail - b.head).distance, greaterThan(0.02), reason: '${b.name} has length');
          }
          expect(preset.bones.where((b) => b.parent == null), isNotEmpty);
        });

        test('chains end on real bones and do not ask for more bones than exist above them', () {
          final byName = {for (final b in preset.bones) b.name: b};
          for (final ik in preset.ik) {
            expect(byName.containsKey(ik.tip), isTrue, reason: ik.name);
            var depth = 0;
            for (PresetBone? b = byName[ik.tip]; b != null; b = b.parent == null ? null : byName[b.parent!]) {
              depth++;
            }
            expect(ik.boneCount, lessThanOrEqualTo(depth), reason: ik.name);
          }
        });

        test('place on a canvas as connected bones with real lengths', () {
          final built = build(preset, withIk: true);
          expect(built.bones.length, preset.bones.length);
          final byId = {for (final b in built.bones) b.id: b};
          for (final b in built.bones) {
            expect(b.length, greaterThanOrEqualTo(1), reason: b.name);
            expect(b.head.dx, inInclusiveRange(0, 64), reason: b.name);
            expect(b.head.dy, inInclusiveRange(0, 64), reason: b.name);
          }
          // A bone that starts where its parent ends stays joined to it.
          for (final pb in preset.bones) {
            if (pb.parent == null) continue;
            final parent = preset.bones.firstWhere((x) => x.name == pb.parent);
            if ((pb.head - parent.tail).distance > 1e-9) continue;
            final child = byId[built.idsByName[pb.name]!]!;
            final parentBone = byId[built.idsByName[parent.name]!]!;
            expect((child.head - parentBone.tail).distance, lessThan(1e-6), reason: '${pb.name} joins ${parent.name}');
          }
          expect(built.chains.length, preset.ik.length);
        });
      });
    }

    test('every preset name is understood as a role by the matcher, so animation presets can find them', () {
      for (final preset in BonePresets.all) {
        final bones = build(preset).bones;
        final roles = [for (final b in preset.bones) b.name];
        final found = RoleMatcher.match(roles, bones);
        expect(found.keys.toSet(), roles.toSet(), reason: preset.name);
      }
    });

    test('ids are unique', () {
      expect({for (final p in BonePresets.all) p.id}.length, BonePresets.all.length);
      expect(BonePresets.byId('humanoid'), BonePresets.humanoid);
      expect(BonePresets.byId('nope'), isNull);
    });
  });

  group('the builder', () {
    final preset = BonePresets.arm;

    test('stretches to fill the box: a taller box makes longer bones', () {
      final tall = build(preset, box: const Rect.fromLTWH(10, 0, 8, 60));
      final short = build(preset, box: const Rect.fromLTWH(10, 0, 8, 30));
      expect(tall.bones.first.length, closeTo(2 * short.bones.first.length, 1.5));
    });

    test('stretching width and height separately bends the angles', () {
      final wide = build(BonePresets.leg, box: const Rect.fromLTWH(0, 0, 40, 40));
      final narrow = build(BonePresets.leg, box: const Rect.fromLTWH(0, 0, 10, 40));
      // The foot points sideways more in a wide box.
      final footWide = wide.bones.last, footNarrow = narrow.bones.last;
      expect(footWide.restAngle.abs(), lessThan(footNarrow.restAngle.abs()));
    });

    test('lands on pixel centres', () {
      final built = build(BonePresets.humanoid, box: const Rect.fromLTWH(3, 5, 37, 51));
      for (final b in built.bones) {
        expect(b.head.dx - 0.5, closeTo((b.head.dx - 0.5).roundToDouble(), 1e-9), reason: b.name);
        expect(b.head.dy - 0.5, closeTo((b.head.dy - 0.5).roundToDouble(), 1e-9), reason: b.name);
      }
    });

    test('mirroring flips left to right and keeps the structure', () {
      final box = const Rect.fromLTWH(0, 0, 32, 32);
      final normal = build(BonePresets.humanoid, box: box);
      final flipped = build(BonePresets.humanoid, box: box, flip: true);
      Bone named(BuiltPreset b, String name) => b.bones.firstWhere((x) => x.name == name);

      expect(named(normal, 'arm_l').head.dx + named(flipped, 'arm_l').head.dx, closeTo(32, 1.01));
      expect(named(normal, 'arm_l').head.dx, lessThan(16));
      expect(named(flipped, 'arm_l').head.dx, greaterThan(16));
      expect(flipped.bones.map((b) => b.parentId == null), normal.bones.map((b) => b.parentId == null));
    });

    test('roots hang from the bone to attach to; the rest keep their own parents', () {
      final built = build(BonePresets.arm, attachTo: 'shoulder');
      expect(built.bones.first.parentId, 'shoulder');
      expect(built.bones[1].parentId, built.bones.first.id);
    });

    test('a bone squeezed under a pixel keeps one pixel of length', () {
      final built = build(BonePresets.tentacle, box: const Rect.fromLTWH(0, 0, 1, 3));
      for (final b in built.bones) {
        expect(b.length, greaterThanOrEqualTo(1), reason: b.name);
      }
    });

    test('name clashes add one suffix to the whole preset', () {
      final built = build(BonePresets.humanoid, taken: {'arm_l', 'head'});
      expect(built.bones.map((b) => b.name), everyElement(endsWith('_2')));
      expect(NameTokens.of(built.bones.first.name), contains('hips'));
      final third = build(BonePresets.humanoid, taken: {'arm_l', 'arm_l_2'});
      expect(third.bones.first.name, endsWith('_3'));
      expect(build(BonePresets.humanoid, taken: {'unrelated'}).bones.first.name, 'hips');
    });

    test('IK chains are made only on request, on the right bones, and fold the other way when mirrored', () {
      expect(build(BonePresets.humanoid).chains, isEmpty);
      final built = build(BonePresets.humanoid, withIk: true);
      expect(built.chains.length, 4);
      final legIk = built.chains.firstWhere((c) => c.name == 'leg_l_ik');
      expect(built.bones.firstWhere((b) => b.id == legIk.tipBoneId).name, 'shin_l');
      expect(legIk.bend, 1);
      final flipped = build(BonePresets.humanoid, withIk: true, flip: true);
      expect(flipped.chains.first.bend, -1);
    });

    test('aspect describes the shape of the preset', () {
      expect(BonePresets.tail.aspect, greaterThan(5), reason: 'a long thin row');
      expect(BonePresets.tentacle.aspect, lessThan(0.2), reason: 'a tall thin column');
    });
  });
}
