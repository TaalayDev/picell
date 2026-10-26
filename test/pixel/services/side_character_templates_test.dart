import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/template.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/services/random_builder.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/pixel/rig/presets/motion_catalog.dart';
import 'package:picell/pixel/rig/presets/motion_presets.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_baker.dart';

void main() {
  final files = (jsonDecode(File('assets/data/templates/index.json').readAsStringSync()) as List).cast<String>();
  Template load(String filename) =>
      Template.fromJson(jsonDecode(File('assets/data/templates/$filename').readAsStringSync())).copyWith(isAsset: true);
  final parts = [
    for (final f in files)
      if (f.startsWith('side_character_builder_')) load(f)
  ];
  test('side profiles contain valid transparent parts and paired ready-made characters', () {
    expect(parts, hasLength(67));
    expect(parts.every((p) => p.width == 32 && p.height == 32 && p.category == 'side-character-builder'), isTrue);
    for (final p in parts) {
      expect(p.pixels, hasLength(1024));
      expect(p.pixels.any((v) => v == 0), isTrue);
      expect(p.pixels.any((v) => v != 0), isTrue);
      expect(p.pixels.every((v) => v == 0 || v >> 24 == 255), isTrue);
      for (final tag in ['slot:', 'variant:', 'rig:']) {
        expect(p.tags.where((v) => v.startsWith(tag)), hasLength(1));
      }
    }
    for (final name in ['adventurer', 'worker', 'knight', 'mage', 'explorer']) {
      final right = load('side_character_${name}_right_32.json');
      final left = load('side_character_${name}_left_32.json');
      expect(right.category, 'characters');
      expect(left.category, 'characters');
      expect(right.pixels.where((v) => v != 0).length, greaterThan(100));
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          expect(left.pixels[y * 32 + x], right.pixels[y * 32 + 31 - x]);
        }
      }
    }
  });
  test('random side characters produce varied, correctly composed bone layers', () {
    final unique = <String>{};
    for (var seed = 0; seed < 50; seed++) {
      final character = buildRandomCharacter(parts, 'side-character-builder', random: Random(seed))!;
      expect(character.builderParts, hasLength(16));
      expect(character.width, 32);
      expect(character.height, 32);
      final layers = {for (final p in character.builderParts) p.name: p};
      expect(layers.keys.toSet(), BonePresets.humanoidSide.bones.map((b) => b.name).toSet());
      final pixels = List<int>.filled(1024, 0);
      for (final part in character.builderParts) {
        for (var i = 0; i < 1024; i++) {
          if (part.pixels[i] != 0) pixels[i] = part.pixels[i];
        }
      }
      expect(character.pixels, pixels);
      unique.add(character.pixels.join(','));
      final mirrored = buildRandomCharacter(parts, 'side-character-builder', random: Random(seed), facingLeft: true)!;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          expect(mirrored.pixels[y * 32 + x], character.pixels[y * 32 + 31 - x]);
        }
      }
      for (var i = 0; i < 16; i++) {
        expect(mirrored.builderParts[i].name, character.builderParts[i].name);
      }
    }
    expect(unique.length, greaterThan(40));
  });
  test('ready-made adventurer matches the modular bone-layer composition', () {
    const recipe = [
      ('upper_arm_far', 'green'),
      ('forearm_far', 'green'),
      ('hand_far', 'light'),
      ('thigh_far', 'brown'),
      ('shin_far', 'brown'),
      ('foot_far', 'leather'),
      ('hips', 'brown'),
      ('thigh_near', 'brown'),
      ('shin_near', 'brown'),
      ('foot_near', 'leather'),
      ('torso', 'green'),
      ('neck', 'light'),
      ('head', 'light'),
      ('upper_arm_near', 'green'),
      ('forearm_near', 'green'),
      ('hand_near', 'light'),
      ('hair', 'brown'),
      ('accessory', 'backpack'),
    ];
    final layers = <String, List<int>>{};
    for (final (slot, variant) in recipe) {
      final part = load('side_character_builder_${slot}_${variant}_32.json');
      final role = part.tags.firstWhere((t) => t.startsWith('rig:')).substring(4);
      final pixels = layers.putIfAbsent(role, () => List.filled(1024, 0));
      for (var i = 0; i < 1024; i++) {
        if (part.pixels[i] != 0) pixels[i] = part.pixels[i];
      }
    }
    final pixels = List<int>.filled(1024, 0);
    for (final layer in layers.values) {
      for (var i = 0; i < 1024; i++) {
        if (layer[i] != 0) pixels[i] = layer[i];
      }
    }
    expect(load('side_character_adventurer_right_32.json').pixels, pixels);
  });

  test('incomplete or mismatched parts cannot generate a broken character', () {
    expect(buildRandomCharacter([], 'side-character-builder'), isNull);
    expect(buildRandomCharacter(parts.where((p) => !p.tags.contains('slot:neck')).toList(), 'side-character-builder'),
        isNull);
    final old = load('character_builder_head_light_16.json');
    expect(buildRandomCharacter([old], 'side-character-builder'), isNull);
  });
  test('native-size side skeleton automatically binds all generated body layers and bakes rest exactly', () {
    for (final facingLeft in [false, true]) {
      final character =
          buildRandomCharacter(parts, 'side-character-builder', random: Random(8), facingLeft: facingLeft)!;
      final layers = [
        for (var i = 0; i < character.builderParts.length; i++)
          Layer(
              layerId: 0,
              id: 'l$i',
              name: character.builderParts[i].name,
              stableKey: 'layer-$i',
              order: i,
              pixels: character.builderParts[i].pixels)
      ];
      var id = 0;
      final c = RigEditorController(
          rig: const Rig(id: 'r', stateId: 1), restLayers: layers, width: 32, height: 32, newId: () => 'id-${id++}');
      c.beginPlacement(BonePresets.humanoidSide);
      expect(c.placement!.box, const Rect.fromLTWH(0, 0, 32, 32));
      c.setPlacementFlip(facingLeft);
      c.setPlacementIk(true);
      final result = c.commitPlacement()!;
      expect(result.boundLayers, 16);
      expect(c.rig.parts, hasLength(16));
      expect(c.rig.ikChains, hasLength(4));
      final head = c.rig.bones.firstWhere((b) => b.name == 'head');
      expect(head.head.dx, facingLeft ? 15.5 : 16.5);
      expect(head.head.dy, 11.5);
      final baked = RigBaker(rig: c.rig, width: 32, height: 32, layers: layers)
          .bakeFrame(const RigClip(id: 'rest', name: 'Rest'), 0);
      expect(baked, character.pixels);
      for (final p in [
        MotionPresets.walk,
        MotionPresets.run,
        MotionPresets.jump,
        MotionPresets.attack,
        MotionPresets.dash,
        MotionPresets.fall
      ]) {
        final built = MotionBuilder.build(p, bones: c.rig.bones, canvasHeight: 32, mirror: facingLeft);
        expect(built.missing, isEmpty, reason: p.name);
      }
      c.mode = RigMode.animate;
      c.applyMotion(MotionPresets.walk, mirror: facingLeft);
      final moving = RigBaker(rig: c.rig, width: 32, height: 32, layers: layers).bakeFrame(c.activeClip, 2);
      expect(moving.any((v) => v != 0), isTrue);
      expect(moving, isNot(orderedEquals(character.pixels)));
      c.dispose();
    }
  });
}
