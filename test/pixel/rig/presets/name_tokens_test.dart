import 'package:flutter/painting.dart' show Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/presets/name_tokens.dart';

void main() {
  Bone bone(String id, String name) => Bone(id: id, name: name, head: Offset.zero, length: 1);

  group('NameTokens', () {
    test('spellings of the same name give the same words', () {
      for (final name in ['arm_l', 'Arm L', 'left arm', 'LeftArm', 'upperArm_left', 'Shoulder.L']) {
        expect(NameTokens.of(name), {'arm', 'l'}, reason: name);
      }
    });

    test('synonyms fold to one word and numbers are kept', () {
      expect(NameTokens.of('Calf_R_3'), {'shin', 'r', '3'});
      expect(NameTokens.of('tail_1'), isNot(NameTokens.of('tail_2')));
      expect(NameTokens.of('Pelvis'), {'hips'});
      expect(NameTokens.of('torso'), {'spine'});
      expect(NameTokens.of('  '), isEmpty);
    });

    test('sameThing compares whole names', () {
      expect(NameTokens.sameThing('Head', 'head'), isTrue);
      expect(NameTokens.sameThing('Left Arm', 'arm_l'), isTrue);
      expect(NameTokens.sameThing('arm', 'arm_l'), isFalse, reason: 'one has a side');
      expect(NameTokens.sameThing('', ''), isFalse);
    });

    test('mirrored swaps the sides', () {
      expect(NameTokens.mirrored({'arm', 'l'}), {'arm', 'r'});
      expect(NameTokens.mirrored({'head'}), {'head'});
    });
  });

  group('RoleMatcher', () {
    test('finds bones by role, however they are spelled', () {
      final bones = [bone('1', 'Head'), bone('2', 'Left Arm'), bone('3', 'arm_r'), bone('4', 'tail')];
      final m = RoleMatcher.match(['head', 'arm_l', 'arm_r', 'thigh_l'], bones);
      expect(m.keys, containsAll(['head', 'arm_l', 'arm_r']));
      expect(m['arm_l']!.id, '2');
      expect(m['arm_r']!.id, '3');
      expect(m.containsKey('thigh_l'), isFalse, reason: 'nothing fits');
    });

    test('numbered bones are told apart, and a copy still matches its role', () {
      final chain = [bone('1', 'tail_1'), bone('2', 'tail_2'), bone('3', 'tail_3')];
      final m = RoleMatcher.match(['tail_1', 'tail_2', 'tail_3'], chain);
      expect(m.map((k, v) => MapEntry(k, v.id)), {'tail_1': '1', 'tail_2': '2', 'tail_3': '3'});

      final copy = RoleMatcher.match(['arm_l'], [bone('1', 'arm_l_2')]);
      expect(copy['arm_l']!.id, '1');
    });

    test('the closest name wins and a bone is given to one role only', () {
      final bones = [bone('1', 'arm_l'), bone('2', 'arm_l_extra')];
      final m = RoleMatcher.match(['arm_l'], bones);
      expect(m['arm_l']!.id, '1', reason: 'fewest extra words');

      final single = RoleMatcher.match(['arm_l', 'arm'], [bone('1', 'arm_l')]);
      expect(single.length, 1, reason: 'the specific role takes it first');
      expect(single.containsKey('arm_l'), isTrue);
    });

    test('a side-less role does not pick a bone for the wrong side by accident', () {
      final m = RoleMatcher.match(['head'], [bone('1', 'head_l')]);
      expect(m['head']!.id, '1', reason: 'extra words are allowed, just ranked lower');
    });

    test('empty input gives nothing', () {
      expect(RoleMatcher.match(const [], [bone('1', 'a')]), isEmpty);
      expect(RoleMatcher.match(['head'], const []), isEmpty);
    });
  });
}
