import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

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
      return TileData.empty(context.width, context.height);
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
    return TileData.solidColor(color, context.width, context.height);
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
    final width = context.width;
    final height = context.height;
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
      return TileData.empty(context.width, context.height);
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
    final width = context.width;
    final height = context.height;
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

class CheckerboardNode extends NodeData {
  double scale;
  Color colorA;
  Color colorB;

  CheckerboardNode({
    super.id,
    super.position,
    this.scale = 4.0,
    this.colorA = const Color(0xFF000000),
    this.colorB = const Color(0xFFFFFFFF),
  }) : super(name: 'Checkerboard');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(
          id: '${id}_in_color_a',
          nodeId: id,
          name: 'Color A',
          type: SocketType.color,
        ),
        NodeSocket(
          id: '${id}_in_color_b',
          nodeId: id,
          name: 'Color B',
          type: SocketType.color,
        ),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(
          id: '${id}_out_checker',
          nodeId: id,
          name: 'Pattern',
          type: SocketType.image,
        )
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    final colorAValue = (colorA.r * 255).toInt() << 16 |
        (colorA.g * 255).toInt() << 8 |
        (colorA.b * 255).toInt() |
        (colorA.a * 255).toInt() << 24;

    final colorBValue = (colorB.r * 255).toInt() << 16 |
        (colorB.g * 255).toInt() << 8 |
        (colorB.b * 255).toInt() |
        (colorB.a * 255).toInt() << 24;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Determine check based on scale
        // x / scale floor % 2 == y / scale floor % 2

        final cx = (x / scale).floor();
        final cy = (y / scale).floor();

        final isA = (cx + cy) % 2 == 0;

        pixels[y * width + x] = isA ? colorAValue : colorBValue;
      }
    }

    return TileData(pixels: pixels, width: width, height: height);
  }
}

class StripesNode extends NodeData {
  double scale;
  double angle; // 0 for vertical, 90 for horizontal, etc.
  Color colorA;
  Color colorB;

  StripesNode({
    super.id,
    super.position,
    this.scale = 4.0,
    this.angle = 0.0,
    this.colorA = const Color(0xFF000000),
    this.colorB = const Color(0xFFFFFFFF),
  }) : super(name: 'Stripes');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(
          id: '${id}_in_color_a',
          nodeId: id,
          name: 'Color A',
          type: SocketType.color,
        ),
        NodeSocket(
          id: '${id}_in_color_b',
          nodeId: id,
          name: 'Color B',
          type: SocketType.color,
        ),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(
          id: '${id}_out_stripes',
          nodeId: id,
          name: 'Pattern',
          type: SocketType.image,
        )
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    final colorAValue = (colorA.r * 255).toInt() << 16 |
        (colorA.g * 255).toInt() << 8 |
        (colorA.b * 255).toInt() |
        (colorA.a * 255).toInt() << 24;

    final colorBValue = (colorB.r * 255).toInt() << 16 |
        (colorB.g * 255).toInt() << 8 |
        (colorB.b * 255).toInt() |
        (colorB.a * 255).toInt() << 24;

    final rad = angle * pi / 180.0;
    final cosA = cos(rad);
    final sinA = sin(rad);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Rotate coordinates
        // actually we can just use distance from a line equation or simpler rotated coord
        // rotatedX = x * cos - y * sin

        final rx = x * cosA - y * sinA;

        final val = (rx / scale).floor();
        final isA = val % 2 == 0;

        pixels[y * width + x] = isA ? colorAValue : colorBValue;
      }
    }

    return TileData(pixels: pixels, width: width, height: height);
  }
}

class BricksNode extends NodeData {
  double scale;
  double ratio; // width / height of brick
  double mortar; // thickness 0..1 relative to brick size
  double stagger; // 0..1
  Color colorA; // Brick
  Color colorB; // Mortar

  BricksNode({
    super.id,
    super.position,
    this.scale = 5.0,
    this.ratio = 2.0,
    this.mortar = 0.1,
    this.stagger = 0.5,
    this.colorA = const Color(0xFFB7410E), // Rust
    this.colorB = const Color(0xFFD3D3D3), // Light gray
  }) : super(name: 'Bricks');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_brick', nodeId: id, name: 'Brick Color', type: SocketType.color),
        NodeSocket(id: '${id}_in_mortar', nodeId: id, name: 'Mortar Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_bricks', nodeId: id, name: 'Pattern', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    final brickHeight = scale;
    final brickWidth = scale * ratio;

    final cA = colorA.value;
    final cB = colorB.value;

    for (int y = 0; y < height; y++) {
      final row = (y / brickHeight).floor();
      final offsetY = (y / brickHeight) - row;

      // Apply stagger to every other row (or custom stagger logic)
      final rowOffset = (row % 2 == 1) ? stagger * brickWidth : 0.0;

      for (int x = 0; x < width; x++) {
        final xx = x + rowOffset;
        final col = (xx / brickWidth).floor();
        final offsetX = (xx / brickWidth) - col;

        bool inMortar = false;
        // Check vertical mortar (edges of brick width)
        if (offsetX < mortar / 2 || offsetX > 1.0 - mortar / 2) inMortar = true;

        // Check horizontal mortar (edges of brick height)
        if (offsetY < mortar / 2 || offsetY > 1.0 - mortar / 2) inMortar = true;

        pixels[y * width + x] = inMortar ? cB : cA;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class GridNode extends NodeData {
  double scale;
  double thickness; // 0..1
  Color colorBack;
  Color colorLine;

  GridNode({
    super.id,
    super.position,
    this.scale = 8.0,
    this.thickness = 0.1,
    this.colorBack = const Color(0xFF000000),
    this.colorLine = const Color(0xFFFFFFFF),
  }) : super(name: 'Grid');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_bg', nodeId: id, name: 'Background', type: SocketType.color),
        NodeSocket(id: '${id}_in_line', nodeId: id, name: 'Line', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_grid', nodeId: id, name: 'Pattern', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    final cB = colorBack.value;
    final cL = colorLine.value;

    final cellW = scale;
    final cellH = scale;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final nx = (x / cellW);
        final ny = (y / cellH);

        final fx = nx - nx.floor();
        final fy = ny - ny.floor();

        bool isLine = false;
        if (fx < thickness || fy < thickness) isLine = true;

        pixels[y * width + x] = isLine ? cL : cB;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

enum GradientType { linear, radial }

class GradientNode extends NodeData {
  GradientType gradientType;
  Color colorStart;
  Color colorEnd;

  GradientNode({
    super.id,
    super.position,
    this.gradientType = GradientType.linear,
    this.colorStart = const Color(0xFF000000),
    this.colorEnd = const Color(0xFFFFFFFF),
  }) : super(name: 'Gradient');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_start', nodeId: id, name: 'Start Color', type: SocketType.color),
        NodeSocket(id: '${id}_in_end', nodeId: id, name: 'End Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_grad', nodeId: id, name: 'Gradient', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double t = 0.0;
        if (gradientType == GradientType.linear) {
          t = x / (width - 1);
        } else {
          final dx = x - width / 2.0;
          final dy = y - height / 2.0;
          final dist = sqrt(dx * dx + dy * dy);
          t = (dist / (width / 2.0 * 1.414)).clamp(0.0, 1.0);
        }

        final r = (colorStart.red + (colorEnd.red - colorStart.red) * t).toInt().clamp(0, 255);
        final g = (colorStart.green + (colorEnd.green - colorStart.green) * t).toInt().clamp(0, 255);
        final b = (colorStart.blue + (colorEnd.blue - colorStart.blue) * t).toInt().clamp(0, 255);
        final a = (colorStart.alpha + (colorEnd.alpha - colorStart.alpha) * t).toInt().clamp(0, 255);

        pixels[y * width + x] = (a << 24) | (r << 16) | (g << 8) | b;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class VoronoiNode extends NodeData {
  double scale;
  double randomness;
  double seed;
  Color cellColor;
  Color edgeColor;

  VoronoiNode({
    super.id,
    super.position,
    this.scale = 5.0,
    this.randomness = 1.0,
    this.seed = 0.0,
    this.cellColor = const Color(0xFF222222),
    this.edgeColor = const Color(0xFFFFFFFF),
  }) : super(name: 'Voronoi');

  @override
  List<NodeSocket> get inputs => [];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_vor', nodeId: id, name: 'Pattern', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    Color lerp(Color a, Color b, double t) {
      return Color.fromARGB(
        (a.alpha + (b.alpha - a.alpha) * t).toInt(),
        (a.red + (b.red - a.red) * t).toInt(),
        (a.green + (b.green - a.green) * t).toInt(),
        (a.blue + (b.blue - a.blue) * t).toInt(),
      );
    }

    // Hash function based on seed
    Offset getFeaturePoint(int gx, int gy) {
      final seedInt = seed.toInt();
      final n = gx + gy * 57 + seedInt * 131;
      final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
      final val = h / 0x7fffffff;

      final n2 = gx * 17 + gy * 31 + seedInt * 97;
      final h2 = (n2 * (n2 * n2 * 15731 + 789221) + 1376312589) & 0x7fffffff;
      final val2 = h2 / 0x7fffffff;

      return Offset(val * randomness, val2 * randomness);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final nx = x / scale;
        final ny = y / scale;

        final igx = nx.floor();
        final igy = ny.floor();

        double minDist = 100.0;

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final gx = igx + dx;
            final gy = igy + dy;

            final featureOffset = getFeaturePoint(gx, gy);
            final px = gx + 0.5 + featureOffset.dx * 0.5;
            final py = gy + 0.5 + featureOffset.dy * 0.5;

            final d = sqrt((nx - px) * (nx - px) + (ny - py) * (ny - py));
            if (d < minDist) {
              minDist = d;
            }
          }
        }

        final val = (minDist).clamp(0.0, 1.0);
        pixels[y * width + x] = lerp(cellColor, edgeColor, val).value;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class WaveNode extends NodeData {
  double scale;
  double angle; // 0..360
  Color colorA;
  Color colorB;

  WaveNode({
    super.id,
    super.position,
    this.scale = 0.2, // Period of wave
    this.angle = 0.0,
    this.colorA = const Color(0xFF000000),
    this.colorB = const Color(0xFFFFFFFF),
  }) : super(name: 'Wave');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_a', nodeId: id, name: 'Color A', type: SocketType.color),
        NodeSocket(id: '${id}_in_b', nodeId: id, name: 'Color B', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_wave', nodeId: id, name: 'Pattern', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    final rad = angle * pi / 180.0;
    final cosA = cos(rad);
    final sinA = sin(rad);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final rx = x * cosA - y * sinA;
        final val = (sin(rx * scale) + 1) / 2;

        final r = (colorA.red + (colorB.red - colorA.red) * val).toInt().clamp(0, 255);
        final g = (colorA.green + (colorB.green - colorA.green) * val).toInt().clamp(0, 255);
        final b = (colorA.blue + (colorB.blue - colorA.blue) * val).toInt().clamp(0, 255);
        final a = (colorA.alpha + (colorB.alpha - colorA.alpha) * val).toInt().clamp(0, 255);

        pixels[y * width + x] = (a << 24) | (r << 16) | (g << 8) | b;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class GroundNode extends NodeData {
  double roughness;
  double seed;
  Color colorPrimary;
  Color colorSecondary;

  GroundNode({
    super.id,
    super.position,
    this.roughness = 0.5,
    this.seed = 0.0,
    this.colorPrimary = const Color(0xFF4E342E), // Brown
    this.colorSecondary = const Color(0xFF388E3C), // Green grass
  }) : super(name: 'Ground');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_p', nodeId: id, name: 'Primary', type: SocketType.color),
        NodeSocket(id: '${id}_in_s', nodeId: id, name: 'Secondary', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);
    final random = Random((seed * 1000).toInt());

    // Simple noise map function
    double noise(int x, int y) {
      final n = x + y * 57 + (seed * 100).toInt();
      final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
      return (h / 0x7fffffff);
    }

    final cP = colorPrimary;
    final cS = colorSecondary;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Overlay noise
        double n = 0.0;
        // Simple fbm-like stacking
        n += noise(x, y) * 1.0;
        n += noise(x * 2, y * 2) * 0.5;
        n /= 1.5;

        // Threshold for mixing
        final mix = (n > (1.0 - roughness)) ? 1.0 : 0.0;

        final r = (cP.red + (cS.red - cP.red) * mix).toInt().clamp(0, 255);
        final g = (cP.green + (cS.green - cP.green) * mix).toInt().clamp(0, 255);
        final b = (cP.blue + (cS.blue - cP.blue) * mix).toInt().clamp(0, 255);

        // Add random variation
        final variation = (random.nextDouble() - 0.5) * 20;

        final rFinal = (r + variation).toInt().clamp(0, 255);
        final gFinal = (g + variation).toInt().clamp(0, 255);
        final bFinal = (b + variation).toInt().clamp(0, 255);

        pixels[y * width + x] = (255 << 24) | (rFinal << 16) | (gFinal << 8) | bFinal;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class WallNode extends NodeData {
  double scale;
  double roughness;
  Color colorStone;
  Color colorMortar;

  WallNode({
    super.id,
    super.position,
    this.scale = 4.0,
    this.roughness = 0.2,
    this.colorStone = const Color(0xFF757575), // Grey
    this.colorMortar = const Color(0xFF424242), // Dark Grey
  }) : super(name: 'Wall');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_stone', nodeId: id, name: 'Stone Color', type: SocketType.color),
        NodeSocket(id: '${id}_in_mortar', nodeId: id, name: 'Mortar Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);
    final random = Random(12345);

    // Reuse Brick logic but with texture
    final cA = colorStone;
    final cB = colorMortar;

    for (int y = 0; y < height; y++) {
      final row = (y / scale).floor();
      final rowOffset = (row % 2 == 1) ? scale * 1.5 : 0.0; // Stagger

      for (int x = 0; x < width; x++) {
        final xx = x + rowOffset;
        final col = (xx / (scale * 2.0)).floor();

        final offsetX = (xx / (scale * 2.0)) - col;
        final offsetY = (y / scale) - row;

        // Mortar
        bool inMortar = false;
        if (offsetX < 0.05 || offsetX > 0.95) inMortar = true;
        if (offsetY < 0.05 || offsetY > 0.95) inMortar = true;

        Color pixelColor = inMortar ? cB : cA;

        if (!inMortar) {
          // Add roughness/texture to stone
          final noise = (random.nextDouble() - 0.5) * roughness * 50;
          final r = (pixelColor.red + noise).toInt().clamp(0, 255);
          final g = (pixelColor.green + noise).toInt().clamp(0, 255);
          final b = (pixelColor.blue + noise).toInt().clamp(0, 255);
          pixelColor = Color.fromARGB(255, r, g, b);
        }

        pixels[y * width + x] = pixelColor.value;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class WaterNode extends NodeData {
  double turbulence;
  double scale;
  Color colorDeep;
  Color colorSurface;

  WaterNode({
    super.id,
    super.position,
    this.turbulence = 0.5,
    this.scale = 5.0,
    this.colorDeep = const Color(0xFF0D47A1), // Deep Blue
    this.colorSurface = const Color(0xFF42A5F5), // Light Blue
  }) : super(name: 'Water');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_deep', nodeId: id, name: 'Deep Color', type: SocketType.color),
        NodeSocket(id: '${id}_in_surf', nodeId: id, name: 'Surface Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Sine wave combination
        final v1 = sin(x / scale + y / scale);
        final v2 = sin(x / (scale * 0.5) - y / (scale * 0.5) + turbulence);
        final val = (v1 + v2) / 2.0; // -1..1
        final n = (val + 1) / 2.0; // 0..1

        // Lerp
        final r = (colorDeep.red + (colorSurface.red - colorDeep.red) * n).toInt().clamp(0, 255);
        final g = (colorDeep.green + (colorSurface.green - colorDeep.green) * n).toInt().clamp(0, 255);
        final b = (colorDeep.blue + (colorSurface.blue - colorDeep.blue) * n).toInt().clamp(0, 255);

        // Specular highlight?
        int finalR = r;
        int finalG = g;
        int finalB = b;

        if (n > 0.9) {
          finalR = (finalR + 30).clamp(0, 255);
          finalG = (finalG + 30).clamp(0, 255);
          finalB = (finalB + 30).clamp(0, 255);
        }

        pixels[y * width + x] = (255 << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class WoodNode extends NodeData {
  double grainScale;
  double rings;
  Color colorDark;
  Color colorLight;

  WoodNode({
    super.id,
    super.position,
    this.grainScale = 10.0,
    this.rings = 3.0,
    this.colorDark = const Color(0xFF5D4037), // Dark Wood
    this.colorLight = const Color(0xFFD7CCC8), // Light Wood
  }) : super(name: 'Wood');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_dark', nodeId: id, name: 'Dark Color', type: SocketType.color),
        NodeSocket(id: '${id}_in_light', nodeId: id, name: 'Light Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Distance from center modified by noise
        final cx = width / 2.0;
        final cy = height / 2.0;

        final dx = x - cx;
        final dy = y - cy;

        final dist = sqrt(dx * dx + dy * dy);

        // Sine of distance creates rings
        // Add noise to angle for grain
        // Simplify: straight grain + knots? Or just concentric for "log end"

        // Let's do linear grain (planks)
        // x coordinate dominated, with sine perturbation

        final n = sin(y / grainScale + sin(x / 5.0) * 0.2); // Wobbly lines

        // Rings? No, just grain lines for plank

        double v = ((x / grainScale) + sin(y / (grainScale * 2)) * rings) % 1.0;
        if (v < 0) v += 1.0;

        // Make it smooth triangle wave rather than saw
        v = v < 0.5 ? v * 2 : (1.0 - v) * 2;

        final r = (colorDark.red + (colorLight.red - colorDark.red) * v).toInt().clamp(0, 255);
        final g = (colorDark.green + (colorLight.green - colorDark.green) * v).toInt().clamp(0, 255);
        final b = (colorDark.blue + (colorLight.blue - colorDark.blue) * v).toInt().clamp(0, 255);

        pixels[y * width + x] = (255 << 24) | (r << 16) | (g << 8) | b;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class LavaNode extends NodeData {
  double temperature;
  double turbulence;
  Color colorHot;
  Color colorCool;

  LavaNode({
    super.id,
    super.position,
    this.temperature = 0.7,
    this.turbulence = 0.5,
    this.colorHot = const Color(0xFFFF5722), // Deep Orange
    this.colorCool = const Color(0xFFB71C1C), // Red 900
  }) : super(name: 'Lava');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_hot', nodeId: id, name: 'Hot Color', type: SocketType.color),
        NodeSocket(id: '${id}_in_cool', nodeId: id, name: 'Cool Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    double noise(double x, double y) {
      final ix = x.floor();
      final iy = y.floor();
      final fx = x - ix;
      final fy = y - iy;

      final n = ix + iy * 57;

      double hash(int n) {
        final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
        return h / 0x7fffffff;
      }

      final v1 = hash(n);
      final v2 = hash(n + 1);
      final v3 = hash(n + 57);
      final v4 = hash(n + 58);

      final i1 = v1 + fx * (v2 - v1);
      final i2 = v3 + fx * (v4 - v3);
      return i1 + fy * (i2 - i1);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Turbulent noise for flowing lava
        final n1 = noise(x / 10.0, y / 10.0);
        final n2 = noise(x / 5.0 + n1 * turbulence * 5, y / 5.0);

        final val = (n2 + temperature) / 2.0;
        final t = val.clamp(0.0, 1.0);

        final r = (colorCool.red + (colorHot.red - colorCool.red) * t).toInt().clamp(0, 255);
        final g = (colorCool.green + (colorHot.green - colorCool.green) * t).toInt().clamp(0, 255);
        final b = (colorCool.blue + (colorHot.blue - colorCool.blue) * t).toInt().clamp(0, 255);

        pixels[y * width + x] = (255 << 24) | (r << 16) | (g << 8) | b;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class SnowNode extends NodeData {
  double density;
  double softness;
  Color color;

  SnowNode({
    super.id,
    super.position,
    this.density = 0.5,
    this.softness = 0.5,
    this.color = const Color(0xFFFAFAFA),
  }) : super(name: 'Snow');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_col', nodeId: id, name: 'Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);
    final random = Random(42);

    final c = color.value;
    final cR = (c >> 16) & 0xFF;
    final cG = (c >> 8) & 0xFF;
    final cB = c & 0xFF;

    // Blueish for shadow
    final sR = (cR * 0.9).toInt();
    final sG = (cG * 0.9).toInt();
    final sB = (cB * 1.0).toInt(); // Keep blue

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final rVal = random.nextDouble();

        // Smooth noise would be better, but grain is okay for snow
        // Density affects how "packed" it is vs fluffy

        bool isShadow = rVal > density;
        final factor = isShadow ? (1.0 - softness * 0.2) : 1.0;

        final r = (cR * factor).toInt().clamp(0, 255);
        final g = (cG * factor).toInt().clamp(0, 255);
        final b = (cB * factor).toInt().clamp(0, 255);

        pixels[y * width + x] = (255 << 24) | (r << 16) | (g << 8) | b;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class MetalFloorNode extends NodeData {
  double panels;
  double scratchiness;
  Color colorBase;
  Color colorHighlight;

  MetalFloorNode({
    super.id,
    super.position,
    this.panels = 4.0,
    this.scratchiness = 0.3,
    this.colorBase = const Color(0xFF607D8B),
    this.colorHighlight = const Color(0xFFCFD8DC),
  }) : super(name: 'Metal Floor');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_base', nodeId: id, name: 'Base', type: SocketType.color),
        NodeSocket(id: '${id}_in_high', nodeId: id, name: 'Highlight', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);
    final random = Random(777);

    final panelSize = width / panels;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final panelX = (x / panelSize).floor();
        final panelY = (y / panelSize).floor();

        final px = x % panelSize;
        final py = y % panelSize;

        bool isEdge = px < 1 || px > panelSize - 1 || py < 1 || py > panelSize - 1;

        // Base metallic gradient on panel
        double val = (px + py) / (panelSize * 2);

        // Random scratches
        if (random.nextDouble() < scratchiness * 0.1) {
          val += 0.3;
        }

        if (isEdge) val = 0.0;

        final r = (colorBase.red + (colorHighlight.red - colorBase.red) * val).toInt().clamp(0, 255);
        final g = (colorBase.green + (colorHighlight.green - colorBase.green) * val).toInt().clamp(0, 255);
        final b = (colorBase.blue + (colorHighlight.blue - colorBase.blue) * val).toInt().clamp(0, 255);

        pixels[y * width + x] = (255 << 24) | (r << 16) | (g << 8) | b;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class MossyStoneNode extends NodeData {
  double mossCoverage;
  double scale;
  Color colorStone;
  Color colorMoss;

  MossyStoneNode({
    super.id,
    super.position,
    this.mossCoverage = 0.4,
    this.scale = 5.0,
    this.colorStone = const Color(0xFF795548),
    this.colorMoss = const Color(0xFF33691E),
  }) : super(name: 'Mossy Stone');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_stone', nodeId: id, name: 'Stone', type: SocketType.color),
        NodeSocket(id: '${id}_in_moss', nodeId: id, name: 'Moss', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);
    final random = Random(888);

    double noise(double x, double y) {
      // Simplified noise for demo
      return (sin(x) + cos(y) + 2) / 4.0;
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Feature blobs (stones)
        final n = noise(x / scale, y / scale);

        // Moss noise
        final m = noise(x / scale * 2.0 + 100, y / scale * 2.0 + 100);

        final isMoss = m < mossCoverage;

        Color c = isMoss ? colorMoss : colorStone;

        // Texture variation
        final v = (random.nextDouble() - 0.5) * 20;
        final r = (c.red + v).toInt().clamp(0, 255);
        final g = (c.green + v).toInt().clamp(0, 255);
        final b = (c.blue + v).toInt().clamp(0, 255);

        pixels[y * width + x] = (255 << 24) | (r << 16) | (g << 8) | b;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class MudNode extends NodeData {
  double wetness;
  double dirtiness;
  Color colorWet;
  Color colorDry;

  MudNode({
    super.id,
    super.position,
    this.wetness = 0.6,
    this.dirtiness = 0.5,
    this.colorWet = const Color(0xFF3E2723),
    this.colorDry = const Color(0xFF795548),
  }) : super(name: 'Mud');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_wet', nodeId: id, name: 'Wet Color', type: SocketType.color),
        NodeSocket(id: '${id}_in_dry', nodeId: id, name: 'Dry Color', type: SocketType.color),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_mat', nodeId: id, name: 'Material', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);
    final random = Random(999);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Sticky noise
        final n = (sin(x / 3.0) * cos(y / 4.0)).abs();

        bool isWet = n < wetness;

        Color c = isWet ? colorWet : colorDry;

        if (random.nextDouble() < dirtiness * 0.2) {
          c = Color.lerp(c, const Color(0xFF000000), 0.2)!;
        }

        pixels[y * width + x] = (255 << 24) | (c.red << 16) | (c.green << 8) | c.blue;
      }
    }
    return TileData(pixels: pixels, width: width, height: height);
  }
}

class PlatformNode extends NodeData {
  bool top;
  bool bottom;
  bool left;
  bool right;
  double thickness;
  double radius;
  double shadow;

  PlatformNode({
    super.id,
    super.position,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.thickness = 0.2, // Border thickness relative to size (0..0.5)
    this.radius = 0.0, // Corner radius relative to size (0..0.5)
    this.shadow = 0.0, // Inner shadow strength (0..1)
  }) : super(name: 'Platform');

  @override
  List<NodeSocket> get inputs => [
        NodeSocket(id: '${id}_in_main', nodeId: id, name: 'Main', type: SocketType.image),
        NodeSocket(id: '${id}_in_border', nodeId: id, name: 'Border', type: SocketType.image),
      ];

  @override
  List<NodeSocket> get outputs => [
        NodeSocket(id: '${id}_out_plat', nodeId: id, name: 'Result', type: SocketType.image),
      ];

  @override
  Future<dynamic> evaluate(NodeEvaluationContext context) async {
    TileData? mainTile;
    TileData? borderTile;

    try {
      mainTile = await context.getInput(id, 'Main') as TileData?;
    } catch (_) {}

    try {
      borderTile = await context.getInput(id, 'Border') as TileData?;
    } catch (_) {}

    // Fallback if inputs disconnected
    mainTile ??= TileData.solidColor(const Color(0xFFCCCCCC), context.width, context.height);
    borderTile ??= TileData.solidColor(const Color(0xFF666666), context.width, context.height);

    final width = context.width;
    final height = context.height;
    final pixels = Uint32List(width * height);

    // Helper to sample texture
    int sample(TileData tile, double u, double v) {
      final tx = (u * tile.width).floor().clamp(0, tile.width - 1);
      final ty = (v * tile.height).floor().clamp(0, tile.height - 1);
      return tile.pixels[ty * tile.width + tx];
    }

    final bordThick = thickness;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final u = x / width;
        final v = y / height;

        // 1. Check shape boundaries (Rounded Rectangle)
        bool outside = false;

        if (radius > 0) {
          double dx = 0, dy = 0;
          if (u < radius)
            dx = radius - u;
          else if (u > 1.0 - radius) dx = u - (1.0 - radius);

          if (v < radius)
            dy = radius - v;
          else if (v > 1.0 - radius) dy = v - (1.0 - radius);

          if (dx > 0 && dy > 0) {
            if (sqrt(dx * dx + dy * dy) > radius) {
              outside = true;
            }
          }
        }

        if (outside) {
          pixels[y * width + x] = 0x00000000; // Transparent
          continue;
        }

        // 2. Composing borders
        bool isBorder = false;

        double distToEdge = 1.0;

        if (top) distToEdge = min(distToEdge, v);
        if (bottom) distToEdge = min(distToEdge, 1.0 - v);
        if (left) distToEdge = min(distToEdge, u);
        if (right) distToEdge = min(distToEdge, 1.0 - u);

        // Radius correction for distance
        if (radius > 0) {
          double dx = 0, dy = 0;
          if (u < radius)
            dx = radius - u;
          else if (u > 1.0 - radius) dx = u - (1.0 - radius);

          if (v < radius)
            dy = radius - v;
          else if (v > 1.0 - radius) dy = v - (1.0 - radius);

          if (dx > 0 && dy > 0) {
            double cornerDist = sqrt(dx * dx + dy * dy);
            double dEdge = radius - cornerDist;

            bool cornerHasBorders = false;
            if (u < 0.5 && v < 0.5 && top && left) cornerHasBorders = true;
            if (u > 0.5 && v < 0.5 && top && right) cornerHasBorders = true;
            if (u < 0.5 && v > 0.5 && bottom && left) cornerHasBorders = true;
            if (u > 0.5 && v > 0.5 && bottom && right) cornerHasBorders = true;

            if (cornerHasBorders) {
              distToEdge = dEdge;
            }
          }
        }

        if (distToEdge < bordThick) {
          // Additional check: verify this specific side is enabled if not in a corner
          // Simplified: The min() logic above handles "closest edge". If closest edge is enabled, then valid.
          // BUT, if closest edge is disabled, it shouldn't be a border?
          // Actually, distToEdge only considers enabled edges, so if distToEdge < bordThick, it MUST be near an enabled edge.
          isBorder = true;
        }

        int pixelColor = 0;
        if (isBorder) {
          pixelColor = sample(borderTile, u, v);
        } else {
          pixelColor = sample(mainTile, u, v);
        }

        // 3. Apply Shadow
        if (shadow > 0) {
          if (!isBorder && isBorder == false) {
            double d = (distToEdge - bordThick);
            if (d < 0) d = 0;
            double shadowRange = 0.1;
            if (d < shadowRange) {
              double sFactor = (1.0 - d / shadowRange) * shadow;
              int a = (pixelColor >> 24) & 0xFF;
              int r = (pixelColor >> 16) & 0xFF;
              int g = (pixelColor >> 8) & 0xFF;
              int b = pixelColor & 0xFF;

              r = (r * (1.0 - sFactor * 0.5)).toInt();
              g = (g * (1.0 - sFactor * 0.5)).toInt();
              b = (b * (1.0 - sFactor * 0.5)).toInt();

              pixelColor = (a << 24) | (r << 16) | (g << 8) | b;
            }
          }
        }

        pixels[y * width + x] = pixelColor;
      }
    }

    return TileData(pixels: pixels, width: width, height: height);
  }
}
