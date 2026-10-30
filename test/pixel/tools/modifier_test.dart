import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/canvas/canvas_widget_bindings.dart';
import 'package:picell/pixel/pixel_point.dart';
import 'package:picell/pixel/services/drawing_service.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/pixel/tools/glowing_modifier.dart';
import 'package:picell/pixel/tools/mirror_modifier.dart';
import 'package:picell/pixel/tools/outline_modifier.dart';
import 'package:picell/pixel/tools/radial_modifier.dart';
import 'package:picell/pixel/tools/shadow_modifier.dart';

void main() {
  group('MirrorModifier', () {
    const w = 10;
    const h = 10;
    final point = PixelPoint(2, 3, color: 0xFF112233);

    test('horizontal axis mirrors Y', () {
      final modifier = MirrorModifier(MirrorAxis.horizontal);
      final result = modifier.apply(point, w, h);

      expect(result.length, 1);
      expect(result.first.x, 2);
      expect(result.first.y, h - 1 - 3); // 6
      expect(result.first.color, 0xFF112233);
    });

    test('vertical axis mirrors X', () {
      final modifier = MirrorModifier(MirrorAxis.vertical);
      final result = modifier.apply(point, w, h);

      expect(result.length, 1);
      expect(result.first.x, w - 1 - 2); // 7
      expect(result.first.y, 3);
      expect(result.first.color, 0xFF112233);
    });

    test('both axis mirrors all three quadrants', () {
      final modifier = MirrorModifier(MirrorAxis.both);
      final result = modifier.apply(point, w, h);

      expect(result.length, 3);
      final coords = result.map((p) => (p.x, p.y)).toSet();
      expect(coords, contains((7, 3))); // (mx, y)
      expect(coords, contains((2, 6))); // (x, my)
      expect(coords, contains((7, 6))); // (mx, my)
    });
  });

  group('RadialModifier', () {
    const w = 16;
    const h = 16;
    final point = PixelPoint(2, 4, color: 0xFFFFFFFF);

    test('fourFold mode produces 3 reflected points across quadrants', () {
      const modifier = RadialModifier(mode: RadialSymmetryMode.fourFold);
      final result = modifier.apply(point, w, h);

      expect(result.length, 3);
      final coords = result.map((p) => (p.x, p.y)).toSet();
      expect(coords, contains((13, 4)));
      expect(coords, contains((2, 11)));
      expect(coords, contains((13, 11)));
      expect(result.every((p) => p.color == point.color), isTrue);
    });

    test('eightFold mode produces 8-way kaleidoscope symmetry', () {
      const modifier = RadialModifier(mode: RadialSymmetryMode.eightFold);
      final result = modifier.apply(point, w, h);

      expect(result.length, greaterThanOrEqualTo(3));
      // None of the points should be the original point
      expect(result.any((p) => p.x == 2 && p.y == 4), isFalse);
      // All points must stay within bounds
      expect(result.every((p) => p.x >= 0 && p.x < w && p.y >= 0 && p.y < h), isTrue);
    });
  });

  group('OutlineModifier', () {
    const w = 10;
    const h = 10;
    final point = PixelPoint(5, 5, color: 0xFFFFFFFF);

    test('4-way cardinal outline without corners', () {
      const modifier = OutlineModifier(outlineColor: 0xFF000000, includeCorners: false);
      final result = modifier.apply(point, w, h);

      expect(result.length, 4);
      final coords = result.map((p) => (p.x, p.y)).toSet();
      expect(coords, contains((5, 4))); // up
      expect(coords, contains((5, 6))); // down
      expect(coords, contains((4, 5))); // left
      expect(coords, contains((6, 5))); // right
      expect(result.every((p) => p.color == 0xFF000000), isTrue);
    });

    test('8-way outline with corners', () {
      const modifier = OutlineModifier(outlineColor: 0xFFFF0000, includeCorners: true);
      final result = modifier.apply(point, w, h);

      expect(result.length, 8);
      final coords = result.map((p) => (p.x, p.y)).toSet();
      expect(coords, contains((4, 4)));
      expect(coords, contains((6, 4)));
      expect(coords, contains((4, 6)));
      expect(coords, contains((6, 6)));
      expect(result.every((p) => p.color == 0xFFFF0000), isTrue);
    });

    test('clips outline points at borders', () {
      const modifier = OutlineModifier(outlineColor: 0xFF000000, includeCorners: true);
      final borderPoint = PixelPoint(0, 0, color: 0xFFFFFFFF);
      final result = modifier.apply(borderPoint, w, h);

      // (0, -1), (-1, 0), (-1, -1), (1, -1), (-1, 1) are out of bounds
      // Remaining valid: (0, 1), (1, 0), (1, 1) -> 3 points
      expect(result.length, 3);
      final coords = result.map((p) => (p.x, p.y)).toSet();
      expect(coords, contains((0, 1)));
      expect(coords, contains((1, 0)));
      expect(coords, contains((1, 1)));
    });
  });

  group('ShadowModifier', () {
    const w = 10;
    const h = 10;
    final point = PixelPoint(3, 3, color: 0xFF00FF00);

    test('hard directional shadow creates single offset pixel without source point', () {
      const modifier = ShadowModifier(offsetX: 2, offsetY: 1, softShadow: false);
      final result = modifier.apply(point, w, h);

      expect(result.length, 1);
      expect(result.first.x, 5);
      expect(result.first.y, 4);
      // Source point should not be in result
      expect(result.any((p) => p.x == 3 && p.y == 3), isFalse);
    });

    test('soft shadow spreads radially from offset target', () {
      const modifier = ShadowModifier(offsetX: 1, offsetY: 1, spread: 1, softShadow: true);
      final result = modifier.apply(point, w, h);

      expect(result.length, greaterThan(1));
      // All points should be around (4, 4)
      final coords = result.map((p) => (p.x, p.y)).toSet();
      expect(coords, contains((4, 4)));
    });
  });

  group('GlowModifier', () {
    const w = 10;
    const h = 10;
    final point = PixelPoint(5, 5, color: 0xFFFFFF00);

    test('generates radial aura points around source without duplicating source', () {
      const modifier = GlowModifier(radius: 1, intensity: 0.8);
      final result = modifier.apply(point, w, h);

      expect(result.isNotEmpty, isTrue);
      // Center point (5, 5) must not be returned
      expect(result.any((p) => p.x == 5 && p.y == 5), isFalse);

      final coords = result.map((p) => (p.x, p.y)).toSet();
      expect(coords, contains((5, 4)));
      expect(coords, contains((5, 6)));
      expect(coords, contains((4, 5)));
      expect(coords, contains((6, 5)));
    });

    test('custom glowColor overrides source color tint', () {
      const customColor = 0xFF00FFFF;
      const modifier = GlowModifier(radius: 1, intensity: 1.0, glowColor: customColor);
      final result = modifier.apply(point, w, h);

      for (final p in result) {
        expect((p.color >> 16) & 0xFF, (customColor >> 16) & 0xFF);
        expect((p.color >> 8) & 0xFF, (customColor >> 8) & 0xFF);
        expect(p.color & 0xFF, customColor & 0xFF);
      }
    });
  });

  group('Service & Binding resolution', () {
    test('DrawingService createModifier resolves all modifiers correctly', () {
      final service = DrawingService();

      expect(service.createModifier(PixelModifier.none, MirrorAxis.horizontal), isNull);
      expect(service.createModifier(PixelModifier.mirror, MirrorAxis.horizontal), isA<MirrorModifier>());
      expect(service.createModifier(PixelModifier.radial, MirrorAxis.horizontal), isA<RadialModifier>());
      expect(service.createModifier(PixelModifier.outline, MirrorAxis.horizontal), isA<OutlineModifier>());
      expect(service.createModifier(PixelModifier.shadow, MirrorAxis.horizontal), isA<ShadowModifier>());
      expect(service.createModifier(PixelModifier.glow, MirrorAxis.horizontal), isA<GlowModifier>());
    });

    test('PixelCanvasWidgetBindings resolveModifier resolves all modifiers', () {
      final config = PixelCanvasWidgetBindings.buildRuntimeConfig(
        width: 16,
        height: 16,
        currentTool: PixelTool.pencil,
        currentLayer: Layer(layerId: 1, id: '1', name: 'l', pixels: Uint32List(16 * 16)),
        currentColor: const Color(0xFF000000),
        brushSize: 1,
        sprayIntensity: 1,
        modifier: PixelModifier.radial,
        mirrorAxis: MirrorAxis.both,
        selectionState: null,
        selectionAnimation: const AlwaysStoppedAnimation(0.0),
      );

      expect(config.modifier, isA<RadialModifier>());
    });
  });
}
