import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:picell/pixel/tools/eraser_tool.dart';

import '../../data.dart';
import '../tools.dart';
import '../tools/fill_tool.dart';
import '../tools/pencil_tool.dart';
import '../tools/selection_tool.dart';
import '../tools/eyedropper_tool.dart';
import '../tools/pen_tool.dart';
import '../tools/shape_tool.dart';
import '../tools/shape_util.dart';
import '../tools/lasso_tool.dart';
import '../pixel_point.dart';
import '../tools/curve_tool.dart';
import '../tools/spray_tool.dart';
import '../tools/smart_selection_tool.dart';
import '../tools/texture_brush_tool.dart';
import 'canvas_controller.dart';

/// Manages tool-specific drawing operations with pixel-perfect generation
class ToolDrawingManager {
  final int width;
  final int height;
  final Function(Color)? onColorPicked;
  final Function(SelectionModel?)? onSelectionChanged;
  final Function(SelectionModel)? onMoveSelection;
  final Function(List<PixelPoint<int>>?)? onSelectionEnd;

  late final SelectionUtils _selectionUtils;
  late final ShapeUtils _shapeUtils;

  late final FillTool _fillTool;
  late final PencilTool _pencilTool;
  late final PenTool _penTool;
  late final EraserTool _eraserTool;
  late final CurveTool _curveTool;
  late final LineTool _lineTool;
  late final RectangleTool _rectangleTool;
  late final OvalToolBresenham _circleTool;
  late final SelectionTool _selectionTool;
  late final SmartSelectionTool _smartSelectionTool;
  late final LassoTool _lassoTool;
  late final EyedropperTool _eyedropperTool;
  late final SprayTool _sprayTool;

  // Extra shape tools
  late final HeartTool _heartTool;
  late final DiamondTool _diamondTool;
  late final ArrowTool _arrowTool;
  late final HexagonTool _hexagonTool;
  late final LightningTool _lightningTool;
  late final CrossTool _crossTool;
  late final TriangleTool _triangleTool;
  late final SpiralTool _spiralTool;
  late final CloudTool _cloudTool;

  // Texture tools
  TextureBrushTool? _currentTextureBrush;
  int? _selectedTextureId;
  BlendMode _textureBlendMode = BlendMode.srcOver;
  TextureBrushMode _textureMode = TextureBrushMode.brush;
  TextureFillMode _textureFillMode = TextureFillMode.tile;
  double _textureSpacingMultiplier = 1.0;

  final _random = Random();

  bool get isCurveActive => _curveTool.hasStartPoint;
  bool get isCurveDefining => _curveTool.isDefiningCurve;
  Offset? get curveStartPoint => _curveTool.startPoint;
  Offset? get curveEndPoint => _curveTool.endPoint;
  Offset? get curveControlPoint => _curveTool.controlPoint;

  List<Offset> get lassoPreviewPoints => _lassoTool.previewPoints;
  bool get isDrawingLasso => _lassoTool.isDrawing;

  // Texture brush getters
  TextureBrushTool? get currentTextureBrush => _currentTextureBrush;
  int? get selectedTextureId => _selectedTextureId;
  BlendMode get textureBlendMode => _textureBlendMode;

  ToolDrawingManager({
    required this.width,
    required this.height,
    this.onColorPicked,
    this.onSelectionChanged,
    this.onMoveSelection,
    this.onSelectionEnd,
  }) {
    _initializeTools();
  }

  void _initializeTools() {
    _selectionUtils = SelectionUtils(
      width: width,
      height: height,
      size: () => Size(width.toDouble(), height.toDouble()),
      onSelectionChanged: onSelectionChanged,
      onMoveSelection: onMoveSelection,
      onSelectionEnd: (s) {},
      update: (callback) => callback(),
    );

    _shapeUtils = ShapeUtils(
      width: width,
      height: height,
    );

    _fillTool = FillTool();
    _pencilTool = PencilTool();
    _penTool = PenTool();
    _eraserTool = EraserTool();
    _curveTool = CurveTool();
    _lineTool = LineTool();
    _rectangleTool = RectangleTool();
    _circleTool = OvalToolBresenham();
    _selectionTool = SelectionTool(_selectionUtils, _circleTool);
    _lassoTool = LassoTool();
    _eyedropperTool = EyedropperTool(
      onColorPicked: (color) => onColorPicked?.call(color),
    );
    _sprayTool = SprayTool();
    _smartSelectionTool = SmartSelectionTool();

    _heartTool = HeartTool();
    _diamondTool = DiamondTool();
    _arrowTool = ArrowTool();
    _hexagonTool = HexagonTool();
    _lightningTool = LightningTool();
    _crossTool = CrossTool();
    _triangleTool = TriangleTool();
    _spiralTool = SpiralTool();
    _cloudTool = CloudTool();
  }

  Tool _getTool(PixelTool toolType) {
    return switch (toolType) {
      PixelTool.pencil => _pencilTool,
      PixelTool.pen => _penTool,
      PixelTool.eraser => _eraserTool,
      PixelTool.curve => _curveTool,
      PixelTool.line => _lineTool,
      PixelTool.rectangle => _rectangleTool,
      PixelTool.circle => _circleTool,
      PixelTool.fill => _fillTool,
      PixelTool.select => _selectionTool,
      PixelTool.lasso => _lassoTool,
      PixelTool.eyedropper => _eyedropperTool,
      PixelTool.sprayPaint => _sprayTool,
      PixelTool.smartSelect => _smartSelectionTool,
      PixelTool.heart => _heartTool,
      PixelTool.diamond => _diamondTool,
      PixelTool.arrow => _arrowTool,
      PixelTool.hexagon => _hexagonTool,
      PixelTool.lightning => _lightningTool,
      PixelTool.cross => _crossTool,
      PixelTool.triangle => _triangleTool,
      PixelTool.spiral => _spiralTool,
      PixelTool.cloud => _cloudTool,
      PixelTool.textureBrush => _currentTextureBrush ?? _pencilTool,
      PixelTool.textureFill => _currentTextureBrush ?? _pencilTool,
      _ => _pencilTool,
    };
  }

  void handleTap(PixelTool toolType, PixelDrawDetails details) {
    final tool = _getTool(toolType);
    tool.onStart(details);
  }

  void startDrawing(PixelTool toolType, PixelDrawDetails details) {
    final tool = _getTool(toolType);
    tool.onStart(details);
  }

  void continueDrawing(PixelTool toolType, PixelDrawDetails details) {
    final tool = _getTool(toolType);
    tool.onMove(details);
  }

  void endDrawing(PixelTool toolType, PixelDrawDetails details) {
    final tool = _getTool(toolType);
    tool.onEnd(details);
  }

  /// MARK: Texture Brush Tool Methods
  Future<bool> setTextureBrush({
    int? textureId,
    String? textureName,
    BlendMode? blendMode,
    TextureBrushMode? mode,
    TextureFillMode? fillMode,
    double? spacingMultiplier,
  }) async {
    try {
      _selectedTextureId = textureId;
      _textureBlendMode = blendMode ?? _textureBlendMode;
      _textureMode = mode ?? _textureMode;
      _textureFillMode = fillMode ?? _textureFillMode;
      _textureSpacingMultiplier = spacingMultiplier ?? _textureSpacingMultiplier;

      _currentTextureBrush = await TextureManager().createTextureBrush(
        textureId: textureId,
        textureName: textureName,
        blendMode: _textureBlendMode,
        mode: _textureMode,
        fillMode: _textureFillMode,
        spacingMultiplier: _textureSpacingMultiplier,
      );

      return _currentTextureBrush != null;
    } catch (e) {
      print('Error setting texture brush: $e');
      _currentTextureBrush = null;
      return false;
    }
  }

  void setTextureBlendMode(BlendMode blendMode) {
    _textureBlendMode = blendMode;

    // Update current texture brush if it exists
    if (_selectedTextureId != null) {
      setTextureBrush(
        textureId: _selectedTextureId,
        blendMode: blendMode,
      );
    }
  }

  void setTextureFill(bool isFill) {
    setTextureBrush(
      mode: isFill ? TextureBrushMode.fill : TextureBrushMode.brush,
      spacingMultiplier: _textureSpacingMultiplier,
      fillMode: TextureFillMode.stretch,
    );
  }

  void clearTextureBrush() {
    _currentTextureBrush = null;
    _selectedTextureId = null;
  }

  /// MARK: Curve Tool
  void handleCurveTap(PixelDrawDetails details, PixelCanvasController controller) {
    _curveTool.onStart(details);

    if (_curveTool.hasStartPoint && _curveTool.hasEndPoint) {
      controller.setCurvePoints(
        _curveTool.startPoint,
        _curveTool.endPoint,
        _curveTool.controlPoint,
      );
    }
  }

  void handleCurveMove(PixelDrawDetails details, PixelCanvasController controller) {
    if (_curveTool.isDefiningCurve) {
      _curveTool.onMove(details);

      controller.setCurvePoints(
        _curveTool.startPoint,
        _curveTool.endPoint,
        details.position,
      );
    }
  }

  void resetCurveTool() {
    _curveTool = CurveTool();
  }

  /// MARK: Selection Tool
  void handleSelectionStart(PixelDrawDetails details) {
    _selectionTool.onStart(details);
  }

  void handleSelectionEnd(PixelDrawDetails details) {
    _selectionTool.onEnd(details);
    onSelectionEnd?.call(_selectionTool.previewPoints);
  }

  void handleSelectionUpdate(PixelDrawDetails details) {
    _selectionTool.onMove(details);
  }

  /// MARK: Pen Tool
  void handlePenTap(
    PixelDrawDetails details,
    PixelCanvasController controller, {
    VoidCallback? onPathClosed,
  }) {
    final position = details.position;
    final penPoints = List<Offset>.from(controller.penPoints);
    const closeThreshold = 10.0;

    if (penPoints.isNotEmpty) {
      final startPoint = penPoints[0];
      if ((position - startPoint).distance <= closeThreshold) {
        penPoints.add(startPoint);
        _finalizePenPath(penPoints, details, controller, close: true);
        onPathClosed?.call();
      } else {
        penPoints.add(position);
        controller.setPenPoints(penPoints);
        _updatePenPathPreview(penPoints, details, controller);
      }
    } else {
      penPoints.add(position);
      controller.setPenPoints(penPoints);
      controller.setDrawingPenPath(true);
      _updatePenPathPreview(penPoints, details, controller);
    }
  }

  void _updatePenPathPreview(
    List<Offset> penPoints,
    PixelDrawDetails details,
    PixelCanvasController controller,
  ) {
    if (penPoints.length < 2) {
      final pixelPos = details.pixelPosition;
      if (_isValidPoint(pixelPos.x, pixelPos.y)) {
        final pixels = [PixelPoint(pixelPos.x, pixelPos.y, color: details.color.value)];
        controller.setPreviewPixels(pixels);
      }
      return;
    }

    final pixels = _shapeUtils.getPenPathPixels(
      penPoints,
      close: false,
      size: details.size,
    );

    final coloredPixels = pixels.map((point) {
      return PixelPoint(
        point.x,
        point.y,
        color: details.color.value,
      );
    }).toList();

    controller.setPreviewPixels(coloredPixels);
  }

  void _finalizePenPath(
    List<Offset> penPoints,
    PixelDrawDetails details,
    PixelCanvasController controller, {
    bool close = true,
  }) {
    if (penPoints.length > 1) {
      final pixels = _shapeUtils.getPenPathPixels(
        penPoints,
        close: close,
        size: details.size,
      );

      final coloredPixels = pixels.map((point) {
        return PixelPoint(
          point.x,
          point.y,
          color: details.color.value,
        );
      }).toList();

      controller.setPreviewPixels(coloredPixels);
    }

    controller.setPenPoints([]);
    controller.setDrawingPenPath(false);
  }

  void closePenPath(PixelCanvasController controller, PixelDrawDetails details, {bool close = true}) {
    final penPoints = List<Offset>.from(controller.penPoints);
    if (penPoints.isNotEmpty && controller.isDrawingPenPath) {
      _finalizePenPath(penPoints, details, controller, close: close);
    }
  }

  /// MARK: Lasso Tool
  void handleLassoStart(PixelDrawDetails details) {
    _lassoTool.onStart(details);
  }

  void handleLassoMove(PixelDrawDetails details) {
    _lassoTool.onMove(details);
  }

  void handleLassoEnd(PixelDrawDetails details) {
    _lassoTool.onEnd(details);
    // The lasso tool should call onPixelsUpdated with the selected pixels
    // This will be handled automatically through the tool's onEnd method
  }

  List<PixelPoint<int>> filterPointsBySelection(List<PixelPoint<int>> pixels) {
    if (_selectionUtils.selectionRect == null) return pixels;

    return pixels.where((point) {
      return _selectionUtils.inInSelectionBounds(point.x, point.y);
    }).toList();
  }

  List<PixelPoint<int>> applyModifier(
    PixelPoint<int> pixel,
    Modifier? modifier,
  ) {
    if (modifier == null) return [pixel];

    final modifiedPixels = modifier.apply(pixel, width, height);
    return [pixel] +
        modifiedPixels.where((point) {
          return point.x >= 0 &&
              point.x < width &&
              point.y >= 0 &&
              point.y < height &&
              _selectionUtils.inInSelectionBounds(point.x, point.y);
        }).toList();
  }

  List<PixelPoint<int>> generateBrushStroke(
    Offset startPos,
    Offset endPos,
    int brushSize,
    Color color,
    Size canvasSize,
  ) {
    final pixelWidth = canvasSize.width / width;
    final pixelHeight = canvasSize.height / height;

    final startX = (startPos.dx / pixelWidth).floor();
    final startY = (startPos.dy / pixelHeight).floor();
    final endX = (endPos.dx / pixelWidth).floor();
    final endY = (endPos.dy / pixelHeight).floor();

    final List<PixelPoint<int>> pixels = [];

    final linePoints = _shapeUtils.getLinePoints(startX, startY, endX, endY);

    for (final point in linePoints) {
      final brushPixels = _shapeUtils.getBrushPixels(
        point.x,
        point.y,
        brushSize,
      );
      pixels.addAll(brushPixels.map((p) => PixelPoint(
            p.x,
            p.y,
            color: color.value,
          )));
    }

    return filterPointsBySelection(pixels);
  }

  List<PixelPoint<int>> generateSprayPixels(
    Offset position,
    int brushSize,
    int intensity,
    Color color,
    Size canvasSize,
  ) {
    final pixelWidth = canvasSize.width / width;
    final pixelHeight = canvasSize.height / height;

    final x = (position.dx / pixelWidth).floor();
    final y = (position.dy / pixelHeight).floor();

    final List<PixelPoint<int>> pixels = [];
    final radius = brushSize.toDouble();

    for (int i = 0; i < intensity; i++) {
      // Use circular distribution for more natural spray
      final angle = _random.nextDouble() * 2 * pi;
      final distance = sqrt(_random.nextDouble()) * radius;

      final offsetX = (distance * cos(angle)).round();
      final offsetY = (distance * sin(angle)).round();

      final px = x + offsetX;
      final py = y + offsetY;

      if (_isValidPoint(px, py)) {
        pixels.add(PixelPoint(px, py, color: color.value));
      }
    }

    return filterPointsBySelection(pixels);
  }

  List<PixelPoint<int>> generateShapePreview(
    PixelTool tool,
    Offset startPos,
    Offset currentPos,
    Color color,
    Size canvasSize,
  ) {
    final pixelWidth = canvasSize.width / width;
    final pixelHeight = canvasSize.height / height;

    final startX = (startPos.dx / pixelWidth).floor();
    final startY = (startPos.dy / pixelHeight).floor();
    final currentX = (currentPos.dx / pixelWidth).floor();
    final currentY = (currentPos.dy / pixelHeight).floor();

    List<PixelPoint<int>> shapePixels = [];

    switch (tool) {
      case PixelTool.line:
        shapePixels = _shapeUtils.getLinePixels(startX, startY, currentX, currentY);
        break;
      case PixelTool.rectangle:
        shapePixels = _shapeUtils.getRectanglePixels(startX, startY, currentX, currentY);
        break;
      case PixelTool.circle:
        shapePixels = _shapeUtils.getCirclePixels(startX, startY, currentX, currentY);
        break;
      default:
        break;
    }

    return filterPointsBySelection(shapePixels
        .map((p) => PixelPoint(
              p.x,
              p.y,
              color: color.value,
            ))
        .toList());
  }

  bool _isValidPoint(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }
}
