import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'pixel_point.dart';
import '../data/models/layer.dart';

enum PixelTool {
  pencil,
  fill,
  eraser,
  line,
  rectangle,
  circle,
  select,
  eyedropper,
  brush,
  gradient,
  rotate,
  pixelPerfectLine,
  sprayPaint,
  drag,
  contour,
  pen,
  lasso,
  curve,
  textureBrush,
  textureFill,
  smartSelect,
  ellipseSelect,

  // Extra Shapes
  heart,
  diamond,
  arrow,
  hexagon,
  lightning,
  cross,
  triangle,
  spiral,
  cloud;

  MouseCursor get cursor {
    switch (this) {
      case PixelTool.pencil:
        return SystemMouseCursors.precise;
      case PixelTool.brush:
        return SystemMouseCursors.precise;
      case PixelTool.eraser:
        return SystemMouseCursors.precise;
      case PixelTool.fill:
        return SystemMouseCursors.click;
      case PixelTool.eyedropper:
        return SystemMouseCursors.precise;
      case PixelTool.rectangle:
      case PixelTool.select:
      case PixelTool.circle:
      case PixelTool.curve:
      case PixelTool.line:
      case PixelTool.heart:
      case PixelTool.diamond:
      case PixelTool.arrow:
      case PixelTool.hexagon:
      case PixelTool.lightning:
      case PixelTool.cross:
      case PixelTool.triangle:
      case PixelTool.spiral:
      case PixelTool.cloud:
        return SystemMouseCursors.cell;
      case PixelTool.lasso:
        return SystemMouseCursors.precise;
      case PixelTool.gradient:
        return SystemMouseCursors.click;
      case PixelTool.sprayPaint:
        return SystemMouseCursors.precise;
      case PixelTool.drag:
        return SystemMouseCursors.grab;
      case PixelTool.textureBrush:
        return SystemMouseCursors.precise;
      case PixelTool.smartSelect:
        return SystemMouseCursors.click;
      case PixelTool.ellipseSelect:
        return SystemMouseCursors.cell;
      default:
        return SystemMouseCursors.basic;
    }
  }
}

enum PixelModifier {
  none,
  glow,
  shadow,
  mirror;

  bool get isNone => this == PixelModifier.none;
  bool get isMirror => this == PixelModifier.mirror;
  bool get isGlow => this == PixelModifier.glow;
  bool get isShadow => this == PixelModifier.shadow;
}

enum MirrorAxis { horizontal, vertical, both }

abstract class Modifier {
  final PixelModifier type;

  const Modifier(this.type);

  bool get isNone => type == PixelModifier.none;
  bool get isMirror => type == PixelModifier.mirror;

  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height);
}

abstract class Tool {
  final PixelTool type;

  const Tool(this.type);

  bool get isPencil => type == PixelTool.pencil;
  bool get isFill => type == PixelTool.fill;
  bool get isEraser => type == PixelTool.eraser;
  bool get isLine => type == PixelTool.line;
  bool get isRectangle => type == PixelTool.rectangle;
  bool get isCircle => type == PixelTool.circle;
  bool get isSelect => type == PixelTool.select;
  bool get isEyedropper => type == PixelTool.eyedropper;
  bool get isBrush => type == PixelTool.brush;
  bool get isGradient => type == PixelTool.gradient;
  bool get isRotate => type == PixelTool.rotate;
  bool get isPixelPerfectLine => type == PixelTool.pixelPerfectLine;
  bool get isSprayPaint => type == PixelTool.sprayPaint;
  bool get isDrag => type == PixelTool.drag;
  bool get isContour => type == PixelTool.contour;
  bool get isPen => type == PixelTool.pen;
  bool get isLasso => type == PixelTool.lasso;
  bool get isCurve => type == PixelTool.curve;
  bool get isTextureBrush => type == PixelTool.textureBrush;
  bool get isSmartSelect => type == PixelTool.smartSelect;
  bool get isEllipseSelect => type == PixelTool.ellipseSelect;

  void onStart(PixelDrawDetails details);
  void onMove(PixelDrawDetails details);
  void onEnd(PixelDrawDetails details);

  Uint32List createPreviewPixels(PixelDrawDetails details) {
    final pixelPosition = details.pixelPosition;
    final colorValue = details.color.value;

    final previewPixels = Uint32List(details.width * details.height);

    final index = pixelPosition.y * details.width + pixelPosition.x;

    if (index >= 0 && index < previewPixels.length) {
      previewPixels[index] = colorValue;
    }

    return previewPixels;
  }
}

abstract class DrawTool extends Tool {
  const DrawTool(super.type);

  @override
  void onStart(PixelDrawDetails details) {
    // Implement drawing logic
  }

  @override
  void onMove(PixelDrawDetails details) {
    // Implement drawing logic
  }

  @override
  void onEnd(PixelDrawDetails details) {
    // Implement drawing logic
  }
}

class PixelDrawDetails {
  final Offset position;
  final Size size;
  final int width;
  final int height;
  final Layer currentLayer;
  final Color color;
  final int strokeWidth;
  final Modifier? modifier;
  final Function(List<PixelPoint<int>>) onPixelsUpdated;

  PixelPoint<int> get pixelPosition => _getPixelCoordinates(
        position,
        size,
        width,
        height,
      );

  PixelDrawDetails({
    required this.position,
    required this.size,
    required this.width,
    required this.height,
    required this.currentLayer,
    required this.color,
    this.strokeWidth = 1,
    required this.modifier,
    required this.onPixelsUpdated,
  });

  PixelPoint<int> _getPixelCoordinates(
    Offset position,
    Size size,
    int width,
    int height,
  ) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    return PixelPoint(
      (position.dx / pixelWidth).floor(),
      (position.dy / pixelHeight).floor(),
      color: color.value,
    );
  }

  PixelDrawDetails copyWith({
    Offset? position,
    Size? size,
    int? width,
    int? height,
    Layer? currentLayer,
    Color? color,
    int? strokeWidth,
    Modifier? Function()? modifier,
    Function(List<PixelPoint<int>>)? onPixelsUpdated,
  }) {
    return PixelDrawDetails(
      position: position ?? this.position,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      currentLayer: currentLayer ?? this.currentLayer,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      modifier: modifier != null ? modifier() : this.modifier,
      onPixelsUpdated: onPixelsUpdated ?? this.onPixelsUpdated,
    );
  }
}
