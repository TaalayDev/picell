import 'dart:typed_data';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../pixel/effects/effects.dart';

class Layer with EquatableMixin {
  final int layerId;
  final String id;
  final String name;
  final Uint32List pixels;
  final List<Effect> effects;
  final bool isVisible;
  final bool isLocked;
  final double opacity;
  final int order;
  final Offset? anchorPoint;

  Layer({
    required this.layerId,
    required this.id,
    required this.name,
    required this.pixels,
    this.effects = const [],
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    this.order = 0,
    this.anchorPoint,
  });

  Layer copyWith({
    int? layerId,
    String? id,
    String? name,
    Uint32List? pixels,
    List<Effect>? effects,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    int? order,
    Offset? Function()? anchorPoint,
  }) {
    return Layer(
      layerId: layerId ?? this.layerId,
      id: id ?? this.id,
      name: name ?? this.name,
      pixels: pixels ?? this.pixels,
      effects: effects ?? this.effects,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      order: order ?? this.order,
      anchorPoint: anchorPoint != null ? anchorPoint() : this.anchorPoint,
    );
  }

  // Pixels with all effects applied. Computed once per Layer instance:
  // Layer is immutable (copyWith creates a new instance whenever pixels or
  // effects change), and effect application is a full-buffer pass that gets
  // requested repeatedly by the cache manager, painter, and merge helpers.
  // [prepareProcessedPixels] can fill the cache from a background isolate.
  //
  // Effects need the canvas size (a layer only holds a flat buffer), so every
  // read passes it. A layer always belongs to one canvas, so the first size
  // is the only size and the cache is never stale.
  Uint32List? _processedPixels;

  /// [pixels] with every effect applied, for a [width] × [height] canvas.
  Uint32List processedPixels(int width, int height) =>
      _processedPixels ??= _computeProcessedPixels(pixels, effects, width, height);

  /// Whether reading [processedPixels] would run effects on this thread.
  bool get needsEffectProcessing => effects.isEmpty ? false : _processedPixels == null;

  static Uint32List _computeProcessedPixels(Uint32List pixels, List<Effect> effects, int width, int height) {
    if (effects.isEmpty) return pixels;
    assert(width * height == pixels.length, 'Layer is not $width×$height');
    return EffectsManager.applyMultipleEffects(pixels, width, height, effects);
  }

  /// Applies effects of every layer that has any in one background isolate,
  /// so opening a project with effects doesn't freeze the UI while the
  /// canvas, timeline and layer previews read [processedPixels]. Produces
  /// exactly what [processedPixels] would.
  static Future<void> prepareProcessedPixels(Iterable<Layer> layers, int width, int height) async {
    final pending = layers.where((layer) => layer.needsEffectProcessing).toList();
    if (pending.isEmpty) return;

    final results = await compute(
      _computeProcessedPixelsBatch,
      (
        width: width,
        height: height,
        layers: [for (final layer in pending) (pixels: layer.pixels, effects: layer.effects)],
      ),
    );
    for (var i = 0; i < pending.length; i++) {
      pending[i]._processedPixels ??= results[i];
    }
  }

  static List<Uint32List> _computeProcessedPixelsBatch(
    ({int width, int height, List<({Uint32List pixels, List<Effect> effects})> layers}) args,
  ) {
    return [
      for (final layer in args.layers) _computeProcessedPixels(layer.pixels, layer.effects, args.width, args.height),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'layerId': layerId,
      'id': id,
      'name': name,
      'pixels': pixels.toList(),
      'effects': effects
          .map((e) => {
                'type': e.type.name,
                'parameters': e.parameters,
              })
          .toList(),
      'isVisible': isVisible,
      'isLocked': isLocked,
      'opacity': opacity,
      'order': order,
      if (anchorPoint != null)
        'anchorPoint': {'dx': anchorPoint!.dx, 'dy': anchorPoint!.dy},
    };
  }

  factory Layer.fromJson(Map<String, dynamic> json) {
    List<Effect> effectsList = [];
    if (json.containsKey('effects') && json['effects'] != null) {
      final effectsData = json['effects'] as List;
      effectsList = effectsData.map((effectData) {
        final effectType = EffectType.values.firstWhere(
          (type) => type.name == effectData['type'],
          orElse: () => EffectType.brightness,
        );
        return EffectsManager.createEffect(
          effectType,
          Map<String, dynamic>.from(effectData['parameters']),
        );
      }).toList();
    }

    return Layer(
      layerId: json['layerId'] as int,
      id: json['id'] as String,
      name: json['name'] as String,
      pixels: Uint32List.fromList((json['pixels'] as List).cast<int>()),
      effects: effectsList,
      isVisible: json['isVisible'] as bool,
      isLocked: json['isLocked'] as bool,
      opacity: json['opacity'] as double,
      order: json['order'] as int? ?? 0,
      anchorPoint: json['anchorPoint'] != null
          ? Offset(
              (json['anchorPoint']['dx'] as num).toDouble(),
              (json['anchorPoint']['dy'] as num).toDouble(),
            )
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, layerId, name, pixels, isVisible, isLocked, opacity, order, effects, anchorPoint];
}
