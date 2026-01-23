import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'node_graph_model.dart';

/// Represents generated tile data
class TileData {
  final Uint32List pixels;
  final int width;
  final int height;

  TileData({required this.pixels, required this.width, required this.height});

  /// Create a solid color tile
  factory TileData.solidColor(Color color, int width, int height) {
    final pixels = Uint32List(width * height);
    final colorValue = color.value;
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorValue;
    }
    return TileData(pixels: pixels, width: width, height: height);
  }

  /// Create an empty (transparent) tile
  factory TileData.empty(int width, int height) {
    return TileData(pixels: Uint32List(width * height), width: width, height: height);
  }
}

class OutputNode extends NodeData {
  OutputNode({super.id, super.position}) : super(name: 'Output');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(
          id: '${id}_in_main',
          nodeId: id,
          name: 'Tile',
          type: SocketType.image,
        )
      ];

  @override
  List<NodeSocket> get outputs => [];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    try {
      return await context.getInput(id, 'Tile');
    } catch (e) {
      // No input connected, return empty tile
      return TileData.empty(32, 32);
    }
  }
}

class ColorNode extends NodeData {
  Color color;

  ColorNode({
    super.id,
    super.position,
    this.color = const Color(0xFFFFFFFF),
  }) : super(name: 'Color');

  @override
  List<NodeSocket> get inputs => [];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(
          id: '${id}_out_color',
          nodeId: id,
          name: 'Color',
          type: SocketType.color,
        ),
        NodeSocket(
          id: '${id}_out_tile',
          nodeId: id,
          name: 'Tile',
          type: SocketType.image,
        ),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    // Return a solid color tile
    return TileData.solidColor(color, 32, 32);
  }
}

class NoiseNode extends NodeData {
  double scale;
  double seed;
  List<Color> colors;

  NoiseNode({
    super.id,
    super.position,
    this.scale = 0.1,
    this.seed = 0.0,
    List<Color>? colors,
  })  : colors = colors ?? [const Color(0xFF1a1a2e), const Color(0xFF4a4a6a), const Color(0xFF8a8aaa)],
        super(name: 'Noise');

  @override
  List<NodeSocket> get inputs => [];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(
          id: '${id}_out_noise',
          nodeId: id,
          name: 'Noise Map',
          type: SocketType.image,
        )
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    const width = 32;
    const height = 32;
    final pixels = Uint32List(width * height);
    final random = Random((seed * 1000).toInt());

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise = _noise2D(x * scale + seed, y * scale + seed);
        final colorIndex = (noise * (colors.length - 1)).round().clamp(0, colors.length - 1);
        final baseColor = colors[colorIndex];

        // Add some variation
        final variation = (random.nextDouble() - 0.5) * 20;
        final r = (baseColor.red + variation).clamp(0, 255).toInt();
        final g = (baseColor.green + variation).clamp(0, 255).toInt();
        final b = (baseColor.blue + variation).clamp(0, 255).toInt();

        pixels[y * width + x] = (255 << 24) | (r << 16) | (g << 8) | b;
      }
    }

    return TileData(pixels: pixels, width: width, height: height);
  }

  double _noise2D(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    double hash(int x, int y) {
      final n = x + y * 57;
      final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
      return h / 0x7fffffff;
    }

    final v1 = hash(ix, iy);
    final v2 = hash(ix + 1, iy);
    final v3 = hash(ix, iy + 1);
    final v4 = hash(ix + 1, iy + 1);

    final i1 = v1 + fx * (v2 - v1);
    final i2 = v3 + fx * (v4 - v3);

    return i1 + fy * (i2 - i1);
  }
}

class MixNode extends NodeData {
  double factor;

  MixNode({super.id, super.position, this.factor = 0.5}) : super(name: 'Mix');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(
          id: '${id}_in_a',
          nodeId: id,
          name: 'A',
          type: SocketType.image,
        ),
        NodeSocket(
          id: '${id}_in_b',
          nodeId: id,
          name: 'B',
          type: SocketType.image,
        ),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(
          id: '${id}_out_mix',
          nodeId: id,
          name: 'Result',
          type: SocketType.image,
        )
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    TileData? tileA;
    TileData? tileB;

    try {
      tileA = await context.getInput(id, 'A') as TileData?;
    } catch (_) {}

    try {
      tileB = await context.getInput(id, 'B') as TileData?;
    } catch (_) {}

    if (tileA == null && tileB == null) {
      return TileData.empty(32, 32);
    }
    if (tileA == null) return tileB!;
    if (tileB == null) return tileA;

    final width = tileA.width;
    final height = tileA.height;
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      final a = tileA.pixels[i];
      final b = tileB.pixels[i];

      final aR = (a >> 16) & 0xFF;
      final aG = (a >> 8) & 0xFF;
      final aB = a & 0xFF;

      final bR = (b >> 16) & 0xFF;
      final bG = (b >> 8) & 0xFF;
      final bB = b & 0xFF;

      final r = (aR + (bR - aR) * factor).round();
      final g = (aG + (bG - aG) * factor).round();
      final bl = (aB + (bB - aB) * factor).round();

      pixels[i] = (255 << 24) | (r << 16) | (g << 8) | bl;
    }

    return TileData(pixels: pixels, width: width, height: height);
  }
}

class ShapeNode extends NodeData {
  ShapeType shapeType;
  Color fillColor;
  Color backgroundColor;

  ShapeNode({
    super.id,
    super.position,
    this.shapeType = ShapeType.circle,
    this.fillColor = const Color(0xFFFFFFFF),
    this.backgroundColor = const Color(0xFF000000),
  }) : super(name: 'Shape');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(
          id: '${id}_in_color',
          nodeId: id,
          name: 'Color',
          type: SocketType.color,
        )
      ];

  @override
  List<NodeSocket> get outputs =>
      [NodeSocket(id: '${id}_out_shape', nodeId: id, name: 'Shape', type: SocketType.image)];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    const width = 32;
    const height = 32;
    final pixels = Uint32List(width * height);
    final bgValue = (backgroundColor.r * 255).toInt() << 16 |
        (backgroundColor.g * 255).toInt() << 8 |
        (backgroundColor.b * 255).toInt() |
        (backgroundColor.a * 255).toInt() << 24;
    final fillValue = (fillColor.r * 255).toInt() << 16 |
        (fillColor.g * 255).toInt() << 8 |
        (fillColor.b * 255).toInt() |
        (fillColor.a * 255).toInt() << 24;

    // Fill with background
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = bgValue;
    }

    final centerX = width / 2;
    final centerY = height / 2;
    final radius = width / 2 - 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        bool inside = false;

        switch (shapeType) {
          case ShapeType.circle:
            final dx = x - centerX;
            final dy = y - centerY;
            inside = (dx * dx + dy * dy) <= radius * radius;
            break;
          case ShapeType.square:
            inside = x >= 2 && x < width - 2 && y >= 2 && y < height - 2;
            break;
          case ShapeType.diamond:
            final dx = (x - centerX).abs();
            final dy = (y - centerY).abs();
            inside = (dx + dy) <= radius;
            break;
        }

        if (inside) {
          pixels[y * width + x] = fillValue;
        }
      }
    }

    return TileData(pixels: pixels, width: width, height: height);
  }
}

enum ShapeType { circle, square, diamond }
