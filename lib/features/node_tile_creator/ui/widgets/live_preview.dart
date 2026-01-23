import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/node_graph_controller.dart';
import '../../models/nodes.dart';

/// Provider that tracks only connection and node property changes (not positions)
final previewTriggerProvider = StateProvider<int>((ref) => 0);

/// Provider that evaluates the graph and returns the result
final previewProvider = FutureProvider.autoDispose<TileData?>((ref) async {
  // Watch only the trigger, not the whole graph
  ref.watch(previewTriggerProvider);
  final controller = ref.read(nodeGraphProvider.notifier);
  return await controller.evaluateForPreview();
});

class LivePreviewWidget extends ConsumerStatefulWidget {
  const LivePreviewWidget({super.key});

  @override
  ConsumerState<LivePreviewWidget> createState() => _LivePreviewWidgetState();
}

class _LivePreviewWidgetState extends ConsumerState<LivePreviewWidget> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _refreshPreview() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      ref.read(previewTriggerProvider.notifier).state++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(previewProvider);

    return Container(
      child: previewAsync.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (tileData) {
          if (tileData == null) {
            return _buildEmptyState();
          }
          return _TilePreview(tileData: tileData);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.white.withOpacity(0.2), size: 32),
          const SizedBox(height: 8),
          Text(
            'Connect nodes to Output',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.withOpacity(0.7), size: 32),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TilePreview extends StatefulWidget {
  final TileData tileData;

  const _TilePreview({required this.tileData});

  @override
  State<_TilePreview> createState() => _TilePreviewState();
}

class _TilePreviewState extends State<_TilePreview> {
  ui.Image? _image;
  bool _tiled = false;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  @override
  void didUpdateWidget(covariant _TilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tileData != widget.tileData) {
      _generateImage();
    }
  }

  Future<void> _generateImage() async {
    final pixels = widget.tileData.pixels;
    final width = widget.tileData.width;
    final height = widget.tileData.height;

    // Convert ARGB to RGBA for the image decoder
    final rgba = Uint8List(width * height * 4);
    for (int i = 0; i < pixels.length; i++) {
      final pixel = pixels[i];
      final a = (pixel >> 24) & 0xFF;
      final r = (pixel >> 16) & 0xFF;
      final g = (pixel >> 8) & 0xFF;
      final b = pixel & 0xFF;
      rgba[i * 4 + 0] = r;
      rgba[i * 4 + 1] = g;
      rgba[i * 4 + 2] = b;
      rgba[i * 4 + 3] = a;
    }

    final completer = await ui.ImmutableBuffer.fromUint8List(rgba);

    final descriptor = ui.ImageDescriptor.raw(
      completer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();

    if (mounted) {
      setState(() {
        _image = frame.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _tiled = !_tiled;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: _tiled
              ? CustomPaint(
                  painter: _TiledPainter(_image!),
                  size: Size.infinite,
                )
              : Center(
                  child: RawImage(
                    image: _image,
                    filterQuality: FilterQuality.none,
                    scale: 1 / 4, // Scale up 4x
                  ),
                ),
        ),
      ),
    );
  }
}

class _TiledPainter extends CustomPainter {
  final ui.Image image;

  _TiledPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    final tileSize = image.width.toDouble() * 3; // 3x scale

    for (double x = 0; x < size.width; x += tileSize) {
      for (double y = 0; y < size.height; y += tileSize) {
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(x, y, tileSize, tileSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TiledPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
