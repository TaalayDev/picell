import 'dart:typed_data';
import 'dart:ui';

import 'selection_region.dart';

class SelectionState {
  final SelectionRegion region;
  final bool isTransforming;
  final Offset transformOffset;
  final double rotation;
  final Size scale;
  final Offset? anchorPoint;
  final Uint32List? capturedPixels;
  final Rect? capturedBounds;

  const SelectionState({
    required this.region,
    this.isTransforming = false,
    this.transformOffset = Offset.zero,
    this.rotation = 0.0,
    this.scale = const Size(1.0, 1.0),
    this.anchorPoint,
    this.capturedPixels,
    this.capturedBounds,
  });

  SelectionState copyWith({
    SelectionRegion? region,
    bool? isTransforming,
    Offset? transformOffset,
    double? rotation,
    Size? scale,
    Offset? Function()? anchorPoint,
    Uint32List? Function()? capturedPixels,
    Rect? Function()? capturedBounds,
  }) {
    return SelectionState(
      region: region ?? this.region,
      isTransforming: isTransforming ?? this.isTransforming,
      transformOffset: transformOffset ?? this.transformOffset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      anchorPoint: anchorPoint != null ? anchorPoint() : this.anchorPoint,
      capturedPixels: capturedPixels != null ? capturedPixels() : this.capturedPixels,
      capturedBounds: capturedBounds != null ? capturedBounds() : this.capturedBounds,
    );
  }

  /// Get the effective anchor point (explicit or center of bounds)
  Offset get effectiveAnchor {
    return anchorPoint ?? region.bounds.center;
  }
}
