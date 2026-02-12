import 'dart:math';

import '../pixel_point.dart';
import 'package:flutter/material.dart';

import '../tools.dart';

/// A spray paint tool that creates a randomized spray effect
class SprayTool extends Tool {
  static const int _defaultIntensity = 8;

  final Random _random = Random();
  bool _isDrawing = false;
  List<PixelPoint<int>> _currentPixels = [];
  Offset? _previousPoint;

  SprayTool() : super(PixelTool.sprayPaint);

  @override
  void onStart(PixelDrawDetails details) {
    _isDrawing = true;
    _applySpray(details);
    _previousPoint = details.position;
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (!_isDrawing || _previousPoint == null) return;
    final distance = (details.position - _previousPoint!).distance;
    if (_isDrawing && distance > details.strokeWidth * 30) {
      _applySpray(details);
      _previousPoint = details.position;
    }
  }

  @override
  void onEnd(PixelDrawDetails details) {
    _isDrawing = false;
    _currentPixels = [];
  }

  void _applySpray(PixelDrawDetails details) {
    final sprayPixels = _generateSprayPixels(
      details.position,
      details.strokeWidth, // brush size
      _defaultIntensity, // intensity
      details.color,
      details.size,
      details.width,
      details.height,
    );

    _currentPixels.addAll(sprayPixels);

    if (_currentPixels.isNotEmpty) {
      details.onPixelsUpdated(_currentPixels);
    }
  }

  List<PixelPoint<int>> _generateSprayPixels(
    Offset position,
    int brushSize,
    int intensity,
    Color color,
    Size canvasSize,
    int canvasWidth,
    int canvasHeight,
  ) {
    final pixelWidth = canvasSize.width / canvasWidth;
    final pixelHeight = canvasSize.height / canvasHeight;

    final centerX = (position.dx / pixelWidth).floor();
    final centerY = (position.dy / pixelHeight).floor();

    final List<PixelPoint<int>> pixels = [];
    final Set<String> usedPositions = <String>{}; // Prevent duplicate pixels

    // Adjust intensity based on brush size for better coverage
    final adjustedIntensity = _getAdjustedIntensity(brushSize, intensity);
    // Make spray more spread out by increasing effective radius
    final radius = (brushSize * 1.8).toDouble(); // Increased spread factor

    if (brushSize <= 1) {
      // For size 1, spread to adjacent pixels sometimes
      _generateTinyBrushSpray(
          centerX, centerY, pixels, color, canvasWidth, canvasHeight, adjustedIntensity, usedPositions);
    } else if (brushSize == 2) {
      // For size 2, use a wider spread pattern
      _generateSmallBrushSpray(
          centerX, centerY, pixels, color, canvasWidth, canvasHeight, adjustedIntensity, usedPositions);
    } else {
      // For larger brushes, use wider circular distribution
      _generateLargeBrushSpray(
          centerX, centerY, pixels, color, canvasWidth, canvasHeight, radius, adjustedIntensity, usedPositions);
    }

    return pixels;
  }

  int _getAdjustedIntensity(int brushSize, int intensity) {
    if (brushSize <= 1) return intensity.clamp(2, 4); // Slightly more for spread
    if (brushSize == 2) return (intensity * 0.8).round().clamp(3, 6);
    if (brushSize == 3) return (intensity * 1.0).round(); // Full intensity for spread
    return (intensity * 1.2).round(); // More particles for larger spread areas
  }

  void _generateTinyBrushSpray(
    int centerX,
    int centerY,
    List<PixelPoint<int>> pixels,
    Color color,
    int canvasWidth,
    int canvasHeight,
    int intensity,
    Set<String> usedPositions,
  ) {
    // For brush size 1, occasionally spread to nearby pixels
    final offsets = [
      [0, 0], // center (higher probability)
      [0, 0], // center again for higher weight
      [-1, 0], [1, 0], [0, -1], [0, 1], // adjacent
      [-1, -1], [-1, 1], [1, -1], [1, 1], // diagonal
    ];

    for (int i = 0; i < intensity; i++) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final pixelX = centerX + offset[0];
      final pixelY = centerY + offset[1];
      final posKey = '$pixelX,$pixelY';

      if (pixelX >= 0 &&
          pixelX < canvasWidth &&
          pixelY >= 0 &&
          pixelY < canvasHeight &&
          !usedPositions.contains(posKey)) {
        usedPositions.add(posKey);

        // Lower opacity for spread effect
        final opacity = 0.4 + _random.nextDouble() * 0.5; // 40% to 90% opacity
        final sprayColor = color.withOpacity(opacity);
        pixels.add(PixelPoint(pixelX, pixelY, color: sprayColor.value));
      }
    }
  }

  void _generateSmallBrushSpray(
    int centerX,
    int centerY,
    List<PixelPoint<int>> pixels,
    Color color,
    int canvasWidth,
    int canvasHeight,
    int intensity,
    Set<String> usedPositions,
  ) {
    // For brush size 2, paint in a larger 5x5 area for more spread
    final offsets = <List<int>>[];

    // Generate 5x5 grid centered on brush position
    for (int dx = -2; dx <= 2; dx++) {
      for (int dy = -2; dy <= 2; dy++) {
        offsets.add([dx, dy]);
      }
    }

    for (int i = 0; i < intensity; i++) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final pixelX = centerX + offset[0];
      final pixelY = centerY + offset[1];
      final posKey = '$pixelX,$pixelY';

      if (pixelX >= 0 &&
          pixelX < canvasWidth &&
          pixelY >= 0 &&
          pixelY < canvasHeight &&
          !usedPositions.contains(posKey)) {
        usedPositions.add(posKey);

        // Distance-based probability but more even distribution
        final distanceFromCenter = sqrt(pow(offset[0], 2) + pow(offset[1], 2));
        final probability = distanceFromCenter == 0
            ? 0.8
            : distanceFromCenter <= 1.5
                ? 0.6
                : distanceFromCenter <= 2.5
                    ? 0.4
                    : 0.2;

        if (_random.nextDouble() < probability) {
          final opacity = 0.3 + _random.nextDouble() * 0.6; // 30% to 90% opacity
          final sprayColor = color.withOpacity(opacity);
          pixels.add(PixelPoint(pixelX, pixelY, color: sprayColor.value));
        }
      }
    }
  }

  void _generateLargeBrushSpray(
    int centerX,
    int centerY,
    List<PixelPoint<int>> pixels,
    Color color,
    int canvasWidth,
    int canvasHeight,
    double radius,
    int intensity,
    Set<String> usedPositions,
  ) {
    // More spread out circular distribution
    for (int i = 0; i < intensity; i++) {
      final angle = _random.nextDouble() * 2 * pi;

      // Use square root for more even distribution across the area
      final normalizedDistance = sqrt(_random.nextDouble());
      final distance = normalizedDistance * radius;

      final offsetX = (distance * cos(angle)).round();
      final offsetY = (distance * sin(angle)).round();

      final pixelX = centerX + offsetX;
      final pixelY = centerY + offsetY;
      final posKey = '$pixelX,$pixelY';

      if (pixelX >= 0 &&
          pixelX < canvasWidth &&
          pixelY >= 0 &&
          pixelY < canvasHeight &&
          !usedPositions.contains(posKey)) {
        usedPositions.add(posKey);

        // Much flatter density falloff for more spread
        final distanceFromCenter = sqrt(pow(offsetX, 2) + pow(offsetY, 2));
        final maxDistance = radius;
        final density = 1.0 - (distanceFromCenter / maxDistance) * 0.2; // Only 20% falloff

        if (_random.nextDouble() < density) {
          final opacity = 0.2 + _random.nextDouble() * 0.7; // 20% to 90% opacity
          final sprayColor = color.withOpacity(opacity);
          pixels.add(PixelPoint(pixelX, pixelY, color: sprayColor.value));
        }
      }
    }
  }
}
