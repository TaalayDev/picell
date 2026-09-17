import 'dart:typed_data';

import 'effects.dart';

/// Renders one animation frame from the raw layer and its ordered effect stack.
class EffectAnimationRenderer {
  static Future<Uint32List> renderFrame({
    required Uint32List pixels,
    required int width,
    required int height,
    required List<Effect> effects,
    required int animatedEffectIndex,
    required double progress,
  }) {
    final selected = effects[animatedEffectIndex];
    final parameters = Map<String, dynamic>.from(selected.parameters)
      ..['time'] = progress;

    switch (selected.type) {
      case EffectType.dissolve:
      case EffectType.fadeDissolve:
      case EffectType.wipe:
        parameters['progress'] = progress;
        break;
      case EffectType.clouds:
      case EffectType.sky:
        parameters['animated'] = true;
        break;
      case EffectType.rain:
        parameters['speed'] = progress;
        break;
      default:
        break;
    }

    final frameEffects = List<Effect>.from(effects);
    frameEffects[animatedEffectIndex] =
        EffectsManager.createEffect(selected.type, parameters);
    return EffectsManager.applyMultipleEffectsAsync(
      pixels,
      width,
      height,
      frameEffects,
    );
  }
}
