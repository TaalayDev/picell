import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:equatable/equatable.dart';

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

  // Get pixels with all effects applied
  Uint32List get processedPixels {
    if (effects.isEmpty) return pixels;

    // Calculate square root to get width/height (assuming square or known dimensions)
    final size = pixels.length;
    final width = sqrt(size).floor();
    final height = width;

    return EffectsManager.applyMultipleEffects(pixels, width, height, effects);
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
