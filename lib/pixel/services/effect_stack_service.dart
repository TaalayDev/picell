import 'dart:typed_data';

import '../../data/models/layer.dart';
import '../effects/effects.dart';

enum EffectStackAddFailure {
  requiresPixels,
  requiresEmptyLayer,
  generatorAlreadyExists,
}

class EffectStackAddValidation {
  const EffectStackAddValidation._(this.failure);

  const EffectStackAddValidation.allowed() : this._(null);

  const EffectStackAddValidation.rejected(EffectStackAddFailure failure)
      : this._(failure);

  final EffectStackAddFailure? failure;

  bool get isAllowed => failure == null;
}

class EffectStackAddResult {
  const EffectStackAddResult({
    required this.layer,
    required this.validation,
  });

  final Layer layer;
  final EffectStackAddValidation validation;

  bool get didAdd => validation.isAllowed;
}

class EffectStackState {
  const EffectStackState({
    required this.hasVisiblePixels,
    required this.hasGenerator,
  });

  final bool hasVisiblePixels;
  final bool hasGenerator;
}

/// Owns the domain rules for adding effects to an ordered layer effect stack.
///
/// Existing stacks are deliberately not validated when projects are loaded so
/// legacy files remain non-destructive. All new additions should go through
/// this service.
class EffectStackService {
  const EffectStackService._();

  static bool hasVisiblePixels(Layer layer) =>
      layer.pixels.any((pixel) => (pixel >>> 24) != 0);

  static bool hasGenerator(Layer layer) => layer.effects.any(
        (effect) =>
            EffectCatalog.forType(effect.type).role == EffectRole.generator,
      );

  static bool isProcedural(Layer layer) => hasGenerator(layer);

  static EffectStackState inspect(Layer layer) => EffectStackState(
        hasVisiblePixels: hasVisiblePixels(layer),
        hasGenerator: hasGenerator(layer),
      );

  static EffectStackAddValidation validateAdd(Layer layer, Effect effect) {
    return validateAddToState(inspect(layer), effect);
  }

  static EffectStackAddValidation validateAddToState(
    EffectStackState state,
    Effect effect,
  ) {
    final descriptor = EffectCatalog.forType(effect.type);

    if (descriptor.role == EffectRole.generator) {
      if (state.hasGenerator) {
        return const EffectStackAddValidation.rejected(
          EffectStackAddFailure.generatorAlreadyExists,
        );
      }
      if (state.hasVisiblePixels) {
        return const EffectStackAddValidation.rejected(
          EffectStackAddFailure.requiresEmptyLayer,
        );
      }
    }

    if (descriptor.inputPolicy == EffectInputPolicy.requiresPixels &&
        !state.hasVisiblePixels &&
        !state.hasGenerator) {
      return const EffectStackAddValidation.rejected(
        EffectStackAddFailure.requiresPixels,
      );
    }

    if (descriptor.inputPolicy == EffectInputPolicy.requiresEmptyLayer &&
        state.hasVisiblePixels) {
      return const EffectStackAddValidation.rejected(
        EffectStackAddFailure.requiresEmptyLayer,
      );
    }

    return const EffectStackAddValidation.allowed();
  }

  static EffectStackAddResult addEffect(Layer layer, Effect effect) {
    final validation = validateAdd(layer, effect);
    if (!validation.isAllowed) {
      return EffectStackAddResult(layer: layer, validation: validation);
    }

    final descriptor = EffectCatalog.forType(effect.type);
    final effects = descriptor.role == EffectRole.generator
        ? <Effect>[effect, ...layer.effects]
        : <Effect>[...layer.effects, effect];

    return EffectStackAddResult(
      layer: layer.copyWith(effects: effects),
      validation: validation,
    );
  }

  static Layer convertToPixels(
    Layer layer, {
    required int width,
    required int height,
  }) {
    if (!isProcedural(layer)) return layer;

    final rendered = EffectsManager.applyMultipleEffects(
      layer.pixels,
      width,
      height,
      layer.effects,
    );
    return layer.copyWith(
      pixels: Uint32List.fromList(rendered),
      effects: const [],
    );
  }

  static Layer reorderEffect(Layer layer, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= layer.effects.length) return layer;

    final reordered = List<Effect>.from(layer.effects);
    if (oldIndex < newIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= reordered.length) return layer;

    final wasStructurallyValid = _hasValidGeneratorPlacement(reordered);
    final effect = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, effect);

    if (wasStructurallyValid && !_hasValidGeneratorPlacement(reordered)) {
      return layer;
    }
    return layer.copyWith(effects: reordered);
  }

  static bool _hasValidGeneratorPlacement(List<Effect> effects) {
    final generatorIndices = <int>[
      for (final (index, effect) in effects.indexed)
        if (EffectCatalog.forType(effect.type).role == EffectRole.generator)
          index,
    ];
    return generatorIndices.isEmpty ||
        (generatorIndices.length == 1 && generatorIndices.single == 0);
  }
}
