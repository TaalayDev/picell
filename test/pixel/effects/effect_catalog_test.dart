import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  group('EffectCatalog', () {
    test('contains exactly one descriptor for every effect type', () {
      expect(EffectCatalog.descriptors.length, EffectType.values.length);
      expect(
        EffectCatalog.descriptors.keys.toSet(),
        EffectType.values.toSet(),
      );

      for (final entry in EffectCatalog.descriptors.entries) {
        expect(entry.value.type, entry.key);
      }
    });

    test('matches the approved workspace inventory', () {
      expect(_count(EffectWorkspace.filters), 46);
      expect(_count(EffectWorkspace.materials), 18);
      expect(_count(EffectWorkspace.generators), 18);
      expect(_count(EffectWorkspace.animation), 76);
      expect(_count(EffectWorkspace.lighting), 16);
      expect(_count(EffectWorkspace.distortions), 12);
    });

    test('all generators have an empty-layer policy and generator role', () {
      final generators = EffectCatalog.inWorkspace(EffectWorkspace.generators);

      for (final descriptor in generators) {
        expect(descriptor.role, EffectRole.generator,
            reason: descriptor.type.name);
        expect(
          descriptor.inputPolicy,
          EffectInputPolicy.requiresEmptyLayer,
          reason: descriptor.type.name,
        );
      }
    });

    test('generators create visible content from an empty layer', () {
      const width = 32;
      const height = 32;
      final emptyPixels = Uint32List(width * height);

      for (final descriptor
          in EffectCatalog.inWorkspace(EffectWorkspace.generators)) {
        final output = EffectsManager.createEffect(descriptor.type).apply(
          emptyPixels,
          width,
          height,
        );
        expect(
          output.any((pixel) => pixel >> 24 != 0),
          isTrue,
          reason: descriptor.type.name,
        );
      }
    });

    test('materials do not paint pixels onto an empty layer', () {
      const width = 16;
      const height = 16;
      final emptyPixels = Uint32List(width * height);

      for (final descriptor
          in EffectCatalog.inWorkspace(EffectWorkspace.materials)) {
        final output = EffectsManager.createEffect(descriptor.type).apply(
          emptyPixels,
          width,
          height,
        );
        expect(
          output.every((pixel) => pixel >> 24 == 0),
          isTrue,
          reason: descriptor.type.name,
        );
      }
    });

    test('animation is divided into transformers and special effects', () {
      final animation =
          EffectCatalog.inWorkspace(EffectWorkspace.animation).toList();
      final transformers = animation
          .where((item) => item.animationKind == AnimationKind.transformer);
      final specialEffects = animation
          .where((item) => item.animationKind == AnimationKind.specialEffect);

      expect(transformers.length, 18);
      expect(specialEffects.length, 58);
      expect(
        animation.every((item) => item.animationKind != null),
        isTrue,
      );
      expect(
        transformers.every(
          (item) =>
              item.role == EffectRole.modifier &&
              item.inputPolicy == EffectInputPolicy.requiresPixels &&
              item.isAnimated,
        ),
        isTrue,
      );
    });

    test('legacy isAnimation reads the catalog capability', () {
      for (final type in EffectType.values) {
        final effect = EffectsManager.createEffect(type);
        expect(
          effect.isAnimation,
          EffectCatalog.forType(type).isAnimated,
          reason: type.name,
        );
      }
    });
  });
}

int _count(EffectWorkspace workspace) =>
    EffectCatalog.inWorkspace(workspace).length;
