import 'dart:math';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

import '../../data.dart';
import '../effects/effects.dart';
import 'effect_stack_service.dart';

class LayerService {
  final ProjectRepo _projectRepo;

  LayerService(this._projectRepo);

  Future<Layer> createLayer({
    required int projectId,
    required int frameId,
    required String name,
    required int width,
    required int height,
    int? order,
  }) async {
    final newLayer = Layer(
      layerId: 0,
      id: const Uuid().v4(),
      name: name,
      pixels: Uint32List(width * height),
      order: order ?? 0,
    );

    return await _projectRepo.createLayer(projectId, frameId, newLayer);
  }

  Future<void> deleteLayer(int layerId) async {
    await _projectRepo.deleteLayer(layerId);
  }

  Future<void> updateLayer({
    required int projectId,
    required int frameId,
    required Layer layer,
  }) async {
    await _projectRepo.updateLayer(projectId, frameId, layer);
  }

  List<Layer> reorderLayers(List<Layer> layers, int oldIndex, int newIndex) {
    final reorderedLayers = List<Layer>.from(layers);
    final layer = reorderedLayers.removeAt(oldIndex);
    reorderedLayers.insert(newIndex, layer);

    return reorderedLayers.indexed.map((indexed) {
      final (index, layer) = indexed;
      return layer.copyWith(order: index);
    }).toList();
  }

  Layer toggleLayerVisibility(Layer layer) {
    return layer.copyWith(isVisible: !layer.isVisible);
  }

  Layer toggleLayerLocked(Layer layer) {
    return layer.copyWith(isLocked: !layer.isLocked);
  }

  Layer updateLayerOpacity(Layer layer, double opacity) {
    return layer.copyWith(opacity: opacity.clamp(0.0, 1.0));
  }

  Layer renameLayer(Layer layer, String newName) {
    return layer.copyWith(name: newName);
  }

  Layer addEffectToLayer(Layer layer, Effect effect) {
    return EffectStackService.addEffect(layer, effect).layer;
  }

  Layer updateLayerEffect(Layer layer, int effectIndex, Effect updatedEffect) {
    final updatedEffects = List<Effect>.from(layer.effects);
    updatedEffects[effectIndex] = updatedEffect;
    return layer.copyWith(effects: updatedEffects);
  }

  Layer removeEffectFromLayer(Layer layer, int effectIndex) {
    final updatedEffects = List<Effect>.from(layer.effects);
    updatedEffects.removeAt(effectIndex);
    return layer.copyWith(effects: updatedEffects);
  }

  Layer clearLayerEffects(Layer layer) {
    return layer.copyWith(effects: []);
  }

  Layer updateLayerPixels(Layer layer, Uint32List newPixels) {
    return layer.copyWith(pixels: newPixels);
  }

  int calculateNextLayerOrder(List<Layer> layers) {
    if (layers.isEmpty) return 0;
    return layers.map((l) => l.order).reduce(max) + 1;
  }
}
