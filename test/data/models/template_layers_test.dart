import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/template.dart';

void main() {
  test('front adventurer restores six layers and a transparent background', () {
    final json = jsonDecode(File('assets/data/templates/front_scarf_adventurer_64x96.json').readAsStringSync())
        as Map<String, dynamic>;
    final template = Template.fromJson(json);
    expect(template.layers.map((layer) => layer.name), ['leg_l', 'leg_r', 'arm_l', 'body', 'arm_r', 'head']);
    expect(template.pixels.toList(), List<int>.from(json['pixels'] as List));
    expect(template.pixels.first, 0);
    expect(template.pixels.last, 0);
    expect(template.tags, contains('front-view'));
    for (final layer in template.layers) {
      expect(layer.pixels, hasLength(64 * 96));
      expect(layer.pixels.any((p) => p != 0), true);
    }
    expect(Template.fromJson(jsonDecode(jsonEncode(template.toJson()))), template);
  });

  test('scarf adventurer restores six aligned layers with unchanged pixels', () {
    final json = jsonDecode(File('assets/data/templates/scarf_adventurer_64x96.json').readAsStringSync())
        as Map<String, dynamic>;
    final template = Template.fromJson(json);
    expect(template.layers.map((layer) => layer.name), ['leg_l', 'leg_r', 'arm_l', 'body', 'arm_r', 'head']);
    expect(template.pixels.toList(), List<int>.from(json['pixels'] as List));
    for (final layer in template.layers) {
      expect(layer.pixels, hasLength(64 * 96));
      expect(layer.pixels.any((p) => p != 0), true);
    }
    expect(Template.fromJson(jsonDecode(jsonEncode(template.toJson()))), template);
  });

  test('clockwork robot preserves source pixels across six editable layers', () {
    final json =
        jsonDecode(File('assets/data/templates/clockwork_robot_64x96.json').readAsStringSync()) as Map<String, dynamic>;
    final template = Template.fromJson(json);
    expect(template.layers.map((layer) => layer.name), ['leg_l', 'leg_r', 'arm_l', 'body', 'arm_r', 'head']);
    expect(template.pixels.toList(), List<int>.from(json['pixels'] as List));
    expect(template.width, 64);
    expect(template.height, 96);
    for (final layer in template.layers) {
      expect(layer.pixels, hasLength(64 * 96));
      expect(layer.pixels.any((p) => p != 0), true);
    }
    final index = jsonDecode(File('assets/data/templates/index.json').readAsStringSync()) as List;
    expect(index.where((name) => name == 'clockwork_robot_64x96.json'), hasLength(1));
    expect(Template.fromJson(jsonDecode(jsonEncode(template.toJson()))), template);
  });

  test('side-profile knight restores aligned layers without changing its artwork', () {
    final json = jsonDecode(File('assets/data/templates/side_profile_knight_32x48.json').readAsStringSync())
        as Map<String, dynamic>;
    final template = Template.fromJson(json);
    expect(template.layers, hasLength(14));
    expect(template.builderParts, isEmpty);
    expect(template.pixels.toList(), List<int>.from(json['pixels'] as List));
    for (final layer in template.layers) {
      expect(layer.pixels, hasLength(32 * 48));
      expect(layer.pixels.any((p) => p != 0), true);
    }
    expect(Template.fromJson(jsonDecode(jsonEncode(template.toJson()))), template);
  });

  test('layered templates round trip with composite preview and metadata', () {
    final template = Template.fromJson({
      'name': 'Layered',
      'width': 2,
      'height': 1,
      'layers': [
        {
          'name': 'Base',
          'pixels': [0xffff0000, 0xff00ff00]
        },
        {
          'name': 'Top',
          'pixels': [0xff0000ff, 0],
          'opacity': 0.5,
          'is_locked': true
        },
        {
          'name': 'Hidden',
          'pixels': [0xffffffff, 0xffffffff],
          'is_visible': false
        },
      ],
    });
    expect(template.pixels.toList(), [0xff800080, 0xff00ff00]);
    final restored = Template.fromJson(jsonDecode(jsonEncode(template.toJson())));
    expect(restored, template);
    expect(restored.layers.map((l) => l.name), ['Base', 'Top', 'Hidden']);
    expect(restored.layers[1].isLocked, true);
    expect(restored.layers[2].isVisible, false);
    expect(template.copyWith(name: 'Copy').layers, template.layers);
  });

  test('flat templates remain compatible', () {
    final template = Template.fromJson({
      'name': 'Flat',
      'width': 1,
      'height': 1,
      'pixels': [0xff123456]
    });
    expect(template.layers, isEmpty);
    expect(template.pixels.single, 0xff123456);
    expect(template.toJson().containsKey('layers'), false);
  });

  test('replacing layers refreshes the composite and retains pro status', () {
    final original = Template(name: 'Pro', width: 1, height: 1, pixels: Uint32List(1), isPro: true);
    final changed = original.copyWith(layers: [
      TemplateLayer(name: 'Ink', pixels: Uint32List.fromList([0xff123456]))
    ]);
    expect(changed.pixels.single, 0xff123456);
    expect(changed.isPro, true);
  });
}
