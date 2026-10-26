import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/data/models/template.dart';
import 'package:picell/pixel/rig/rig_example.dart';

void main() {
  test('the bone rig example comes with bones, bound layers and animations', () {
    final template = Template.fromJson(
      jsonDecode(File('assets/data/templates/simple_hero_32x32.json').readAsStringSync()) as Map<String, dynamic>,
    );
    final rig = buildBoneRigExample(
      base: const Rig(id: 'r', stateId: 1),
      restLayers: [
        for (final (i, l) in template.layers.indexed)
          Layer(layerId: i, id: 'id-$i', name: l.name, pixels: Uint32List.fromList(l.pixels), stableKey: l.name),
      ],
      width: template.width,
      height: template.height,
    );

    expect(rig.bones, hasLength(6));
    expect(rig.parts, hasLength(6));
    expect(rig.clips.map((c) => c.name), ['Idle', 'Walk', 'Jump']);
    for (final clip in rig.clips) {
      expect(clip.keyframes, isNotEmpty, reason: clip.name);
    }
    expect(rig.activeClip!.name, 'Walk');
  });
}
