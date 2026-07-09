import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../core.dart';
import '../../../data/models/project_model.dart';
import '../../../pixel/image_painter.dart';
import '../painter/checkboard_painter.dart';

class ProjectThumbnailWidget extends StatefulWidget {
  const ProjectThumbnailWidget({
    super.key,
    required this.project,
    this.fit = BoxFit.fill,
  });

  final Project project;

  /// [BoxFit.fill] (default) stretches the pixel art to the box — correct
  /// when the box already matches the project's aspect ratio. Pass
  /// [BoxFit.contain] when the box's aspect ratio is clamped/fixed
  /// independently of the project's, to avoid distorting the art.
  final BoxFit fit;

  @override
  State<ProjectThumbnailWidget> createState() => _ProjectThumbnailWidgetState();
}

class _ProjectThumbnailWidgetState extends State<ProjectThumbnailWidget> {
  ui.Image? _image;

  @override
  void initState() {
    _createImageFromPixels();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ProjectThumbnailWidget oldWidget) {
    if (oldWidget.project.thumbnail != widget.project.thumbnail) {
      _createImageFromPixels();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: CheckerboardPainter(
                cellSize: 8,
                color1: Colors.grey.shade100,
                color2: Colors.grey.shade50,
              ),
            ),
            if (_image != null)
              CustomPaint(painter: ImagePainter(_image!, fit: widget.fit))
            else
              const Center(
                child: Icon(Feather.image, size: 48),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createImageFromPixels() async {
    final pixels = widget.project.thumbnail;
    if (pixels == null) {
      return;
    }

    final image = await ImageHelper.createImageFrom(
      pixels,
      widget.project.width,
      widget.project.height,
    );
    if (mounted) {
      setState(() {
        _image = image;
      });
    }
  }
}
