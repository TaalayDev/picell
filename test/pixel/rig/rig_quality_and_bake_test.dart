import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

void main() {
  // A W×H canvas with a diagonal-ish 2px-thick bar on one layer, bound to a
  // bone that turns through the clip: RotSprite and nearest differ on it.
  Layer bar(int w, int h, String key) {
    final px = Uint32List(w * h);
    for (var x = w ~/ 4; x < w * 3 ~/ 4; x++) {
      for (final y in [h ~/ 2, h ~/ 2 + 1]) {
        px[y * w + x] = x.isEven ? 0xFFAA0000 : 0xFF00AA00;
      }
    }
    return Layer(layerId: 0, id: 'id-$key', name: key, stableKey: key, pixels: px);
  }

  Rig rig(int w, int h, {RigSettings settings = const RigSettings()}) => Rig(
        id: 'r',
        stateId: 1,
        bones: [Bone(id: 'b', name: 'b', head: Offset(w / 2 + .5, h / 2 + .5), length: w / 4)],
        parts: const [RigPart(id: 'p', boneId: 'b', layerKey: 'bar')],
        settings: settings,
      );

  RigClip turning(int length) => RigClip(id: 'c', name: 'c', length: length, keyframes: [
        const RigKeyframe(time: 0, boneId: 'b'),
        RigKeyframe(time: length - 1, boneId: 'b', rotation: 77),
      ]);

  group('per-layer rotation quality', () {
    test('survives JSON, and old rigs have no overrides', () {
      const settings = RigSettings(layerRotationModes: {'face': RigRotationMode.nearest});
      expect(RigSettings.fromJson(settings.toJson()), settings);
      expect(RigSettings.fromJson(const {'snapAngleDegrees': 0}).layerRotationModes, isEmpty);
      expect(const RigSettings().toJson().containsKey('layerRotationModes'), isFalse);
    });

    test('a layer override wins over the rig setting', () {
      const settings = RigSettings(
        rotationMode: RigRotationMode.rotsprite,
        layerRotationModes: {'face': RigRotationMode.nearest},
      );
      expect(settings.rotationModeFor('face'), RigRotationMode.nearest);
      expect(settings.rotationModeFor('arm'), RigRotationMode.rotsprite);
    });

    test('the baker draws each layer with its own mode', () {
      const w = 24, h = 24;
      final layers = [bar(w, h, 'bar')];
      final clip = turning(6);
      List<Uint32List> bake(RigSettings s) =>
          RigBaker(rig: rig(w, h, settings: s), width: w, height: h, layers: layers).bakeClip(clip);

      final rotsprite = bake(const RigSettings(rotationMode: RigRotationMode.rotsprite));
      final nearest = bake(const RigSettings());
      expect(rotsprite, isNot(nearest), reason: 'the modes must differ for this to test anything');

      expect(bake(const RigSettings(layerRotationModes: {'bar': RigRotationMode.rotsprite})), rotsprite);
      expect(
        bake(const RigSettings(
            rotationMode: RigRotationMode.rotsprite, layerRotationModes: {'bar': RigRotationMode.nearest})),
        nearest,
      );
    });

    test('the editor sets and clears an override as undo steps', () {
      final c = RigEditorController(rig: rig(16, 16), restLayers: [bar(16, 16, 'bar')], width: 16, height: 16);
      c.setLayerRotationMode('bar', RigRotationMode.rotsprite);
      expect(c.rig.settings.rotationModeFor('bar'), RigRotationMode.rotsprite);
      c.setLayerRotationMode('bar', null);
      expect(c.rig.settings.layerRotationModes, isEmpty);
      c.undo();
      expect(c.rig.settings.layerRotationModes, {'bar': RigRotationMode.rotsprite});
    });
  });

  group('bakeClipInBackground', () {
    test('a small clip bakes right away, same as bakeClip', () async {
      const w = 16, h = 16;
      final layers = [bar(w, h, 'bar')];
      final clip = turning(4);
      final progress = <double>[];
      final frames = await RigBaker.bakeClipInBackground(
          rig: rig(w, h), clip: clip, width: w, height: h, layers: layers, onProgress: progress.add);
      expect(frames, RigBaker(rig: rig(w, h), width: w, height: h, layers: layers).bakeClip(clip));
      expect(progress, [1]);
    });

    test('a big clip bakes on an isolate with the same result and reports progress', () async {
      // 64×64 × 100 frames is over the threshold.
      const w = 64, h = 64;
      final clip = turning(100);
      expect(w * h * clip.length, greaterThan(RigBaker.backgroundThreshold));
      final layers = [bar(w, h, 'bar')];
      const settings = RigSettings(rotationMode: RigRotationMode.rotsprite);
      final progress = <double>[];

      final frames = await RigBaker.bakeClipInBackground(
        rig: rig(w, h, settings: settings),
        clip: clip,
        width: w,
        height: h,
        layers: layers,
        onProgress: progress.add,
      );

      expect(frames, RigBaker(rig: rig(w, h, settings: settings), width: w, height: h, layers: layers).bakeClip(clip));
      expect(progress, hasLength(100));
      expect(progress.last, 1);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThan(progress[i - 1]));
      }
    });
  });
}
