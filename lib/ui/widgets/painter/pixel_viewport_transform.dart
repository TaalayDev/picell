import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../pixel/canvas/pixel_viewport_controller.dart';

class PixelViewportTransform extends SingleChildRenderObjectWidget {
  const PixelViewportTransform({
    super.key,
    required this.controller,
    required super.child,
  });

  final PixelViewportController controller;

  Matrix4 _buildTransform() {
    return Matrix4.identity()
      ..translateByDouble(controller.offset.dx, controller.offset.dy, 0.0, 1.0)
      ..scaleByDouble(controller.scale, controller.scale, 1.0, 1.0);
  }

  @override
  RenderTransform createRenderObject(BuildContext context) {
    return RenderTransform(
      transform: _buildTransform(),
      transformHitTests: true,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderTransform renderObject,
  ) {
    renderObject.transform = _buildTransform();
  }
}
