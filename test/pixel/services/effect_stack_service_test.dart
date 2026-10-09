import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/services/effect_stack_service.dart';

void main() {
  group('EffectStackService', () {
    test('treats RGB data with zero alpha as an empty layer', () {
      final layer = _layer([0x00010203, 0x00FFFFFF]);

      expect(EffectStackService.hasVisiblePixels(layer), isFalse);
      expect(
        EffectStackService.validateAdd(layer, MountainRangeEffect()).isAllowed,
        isTrue,
      );
    });

    test('only animations require visible source pixels', () {
      final emptyLayer = _layer([0x00000000]);
      final paintedLayer = _layer([0x01000000]);

      // Filters, materials and lighting work on an empty layer.
      for (final effect in [
        BrightnessEffect(),
        EffectsManager.createEffect(EffectType.wood),
        EffectsManager.createEffect(EffectType.glow),
      ]) {
        expect(
          EffectStackService.validateAdd(emptyLayer, effect).isAllowed,
          isTrue,
          reason: effect.type.name,
        );
      }

      // Animation transformers still need something to animate.
      final animation = EffectsManager.createEffect(EffectType.breathing);
      expect(
        EffectStackService.validateAdd(emptyLayer, animation).failure,
        EffectStackAddFailure.requiresPixels,
      );
      expect(
        EffectStackService.validateAdd(paintedLayer, animation).isAllowed,
        isTrue,
      );
    });

    test('allows modifiers after a generator on an empty pixel buffer', () {
      final layer = _layer(
        [0x00000000],
        effects: [MountainRangeEffect()],
      );

      expect(
        EffectStackService.validateAdd(layer, BrightnessEffect()).isAllowed,
        isTrue,
      );
    });

    test('rejects generators on painted layers', () {
      final layer = _layer([0xFF112233]);

      expect(
        EffectStackService.validateAdd(layer, MountainRangeEffect()).failure,
        EffectStackAddFailure.requiresEmptyLayer,
      );
    });

    test('rejects a second generator', () {
      final layer = _layer(
        [0x00000000],
        effects: [ForestEffect()],
      );

      expect(
        EffectStackService.validateAdd(layer, MountainRangeEffect()).failure,
        EffectStackAddFailure.generatorAlreadyExists,
      );
    });

    test('inserts a generator first and keeps overlays after it', () {
      final overlay = FireEffect();
      final layer = _layer([0x00000000], effects: [overlay]);

      final result = EffectStackService.addEffect(layer, MountainRangeEffect());

      expect(result.didAdd, isTrue);
      expect(result.layer.effects.first, isA<MountainRangeEffect>());
      expect(result.layer.effects.last, same(overlay));
    });

    test('any-layer overlays remain available on empty layers', () {
      final layer = _layer([0x00000000]);

      expect(
        EffectStackService.validateAdd(layer, FireEffect()).isAllowed,
        isTrue,
      );
    });

    test('rejected additions preserve the original layer', () {
      final layer = _layer([0x00000000]);

      final result = EffectStackService.addEffect(layer, EffectsManager.createEffect(EffectType.breathing));

      expect(result.didAdd, isFalse);
      expect(result.layer, same(layer));
      expect(result.layer.effects, isEmpty);
    });

    test('prevents reordering a generator away from the first position', () {
      final generator = MountainRangeEffect();
      final modifier = BrightnessEffect();
      final layer = _layer(
        [0x00000000],
        effects: [generator, modifier],
      );

      final movedGenerator = EffectStackService.reorderEffect(layer, 0, 2);
      final movedBeforeGenerator =
          EffectStackService.reorderEffect(layer, 1, 0);

      expect(movedGenerator, same(layer));
      expect(movedBeforeGenerator, same(layer));
    });

    test('reorders modifiers after a generator', () {
      final generator = MountainRangeEffect();
      final brightness = BrightnessEffect();
      final contrast = ContrastEffect();
      final layer = _layer(
        [0x00000000],
        effects: [generator, brightness, contrast],
      );

      final result = EffectStackService.reorderEffect(layer, 2, 1);

      expect(result.effects, [generator, contrast, brightness]);
    });

    test('converts a procedural stack to editable pixels', () {
      final layer = _layer(
        List.filled(32 * 32, 0),
        effects: [MountainRangeEffect(), BrightnessEffect()],
      );

      final converted = EffectStackService.convertToPixels(
        layer,
        width: 32,
        height: 32,
      );

      expect(converted.effects, isEmpty);
      expect(converted.pixels.any((pixel) => pixel >>> 24 != 0), isTrue);
      expect(EffectStackService.isProcedural(converted), isFalse);
      expect(layer.effects, hasLength(2));
    });

    test('leaves ordinary pixel layers unchanged during conversion', () {
      final layer = _layer([0xFFFFFFFF], effects: [BrightnessEffect()]);

      final converted = EffectStackService.convertToPixels(
        layer,
        width: 1,
        height: 1,
      );

      expect(converted, same(layer));
    });
  });
}

Layer _layer(List<int> pixels, {List<Effect> effects = const []}) => Layer(
      layerId: 1,
      id: 'layer',
      name: 'Layer',
      pixels: Uint32List.fromList(pixels),
      effects: effects,
    );
