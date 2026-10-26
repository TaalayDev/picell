import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/data/models/template.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/pixel/rig/presets/motion_catalog.dart';
import 'package:picell/pixel/rig/rig_validator.dart';
import 'package:picell/pixel/rig/presets/name_tokens.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

void main() {
  final template = Template.fromJson(
    jsonDecode(File('assets/data/templates/simple_hero_32x32.json').readAsStringSync()) as Map<String, dynamic>,
  );

  RigEditorController openHero() => RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: [
          for (final (i, l) in template.layers.indexed)
            Layer(
              layerId: i,
              id: 'id-$i',
              name: l.name,
              pixels: Uint32List.fromList(l.pixels),
              stableKey: l.name,
            ),
        ],
        width: template.width,
        height: template.height,
      );

  test('the basic preset is body, head, two arms and two legs', () {
    final names = BonePresets.humanoidBasic.bones.map((b) => b.name).toSet();
    expect(names, {'body', 'head', 'arm_l', 'arm_r', 'leg_l', 'leg_r'});
    expect(BonePresets.byId('humanoid_basic'), isNotNull);
    expect(BonePresets.all.where((p) => !p.addOn), contains(BonePresets.humanoidBasic));
  });

  test('the example template has one layer per body part, each with art', () {
    expect(template.layers.map((l) => l.name), ['leg_l', 'leg_r', 'arm_l', 'body', 'arm_r', 'head']);
    for (final l in template.layers) {
      expect(l.pixels.any((p) => p != 0), isTrue, reason: l.name);
    }
    // Parts do not overlap: the composite keeps every pixel exactly once.
    final painted = template.layers.fold<int>(0, (n, l) => n + l.pixels.where((p) => p != 0).length);
    expect(template.pixels.where((p) => p != 0).length, painted);
  });

  test('body and leg read as the roles the animation presets look for', () {
    expect(NameTokens.sameThing('body', 'hips'), isTrue);
    expect(NameTokens.of('leg_l'), NameTokens.of('thigh_l'));
  });

  test('placing the preset binds every layer and sits on the art', () {
    final c = openHero();
    c.beginPlacement(BonePresets.humanoidBasic);
    final placed = c.commitPlacement();
    expect(placed!.boundLayers, 6, reason: 'each layer is bound to the bone of the same name');
    expect(c.rig.bones, hasLength(6));
    expect(c.rig.parts, hasLength(6));
    final head = c.rig.bones.firstWhere((b) => b.name == 'head');
    expect(head.head, const Offset(16, 12));
    expect(c.issues.where((i) => i.severity == RigIssueSeverity.error), isEmpty);
  });

  test('a ready-made walk and idle fit the basic skeleton', () {
    final c = openHero();
    c.beginPlacement(BonePresets.humanoidBasic);
    c.commitPlacement();
    final walk = c.motionCoverage(MotionPresets.frontWalk);
    expect(walk.matched, greaterThanOrEqualTo(6), reason: 'body, head, both arms and both legs');
    c.mode = RigMode.animate;
    final result = c.applyMotion(MotionPresets.frontWalk);
    expect(result.keyframes, isNotEmpty);
    expect(c.activeClip.keyframes, isNotEmpty);
    expect(c.motionCoverage(MotionPresets.frontIdle).matched, greaterThanOrEqualTo(3));
  });
}
