import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/pixel/effects/effects.dart';

void main() {
  Uint32List render(Map<String, dynamic> settings, [int w = 128, int h = 96]) =>
      ForestEffect(settings).apply(Uint32List(w * h), w, h);

  test('forest replaces input deterministically without modifying it', () {
    final source = Uint32List(128 * 96)..fillRange(0, 128 * 96, 0xff123456);
    final result = ForestEffect().apply(source, 128, 96);
    expect(result, orderedEquals(render({})));
    expect(source, everyElement(0xff123456));
    expect(render({'randomSeed': 43}), isNot(orderedEquals(result)));
  });

  test('partial saved settings load through effect factory with all controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'forest',
      'parameters': {'layers': 3.0, 'treeDensity': 1},
    });
    expect(effect, isA<ForestEffect>());
    expect(effect!.apply(Uint32List(4096), 64, 64), hasLength(4096));
    expect(
        effect.getFields().map((f) => f.key),
        containsAll([
          'terrainRelief',
          'enableMist',
          'treeType',
        ]));
  });

  test('all tree species and seasons render on tiny and narrow canvases', () {
    for (final size in [(1, 1), (1, 32), (32, 1), (2, 3), (8, 8), (96, 32)]) {
      for (var type = 0; type < 5; type++) {
        for (var season = 0; season < 6; season++) {
          final result = render(
              {'treeType': type, 'colorScheme': season, 'layers': 6, 'enableMist': true, 'godRays': 1},
              size.$1,
              size.$2);
          expect(result, hasLength(size.$1 * size.$2));
          expect(result.every((p) => p == 0 || p >> 24 == 255), isTrue);
        }
      }
    }
    expect(ForestEffect().apply(Uint32List(0), 0, 0), isEmpty);
  });

  test('skyless output is transparent and atmosphere preserves its silhouette', () {
    final base = render({'renderSky': false});
    expect(base.first, 0);
    expect(base.any((p) => p != 0), isTrue);
    final atmosphere = render({'renderSky': false, 'enableMist': true, 'godRays': 1});
    expect(atmosphere.map((p) => p >> 24), orderedEquals(base.map((p) => p >> 24)));
    final filled = Uint32List(128 * 96)..fillRange(0, 128 * 96, 0xffff00ff);
    expect(ForestEffect({'renderSky': false}).apply(filled, 128, 96), orderedEquals(base));
  });

  test('removed sky and clearing settings have no effect on legacy projects', () {
    final effect = ForestEffect();
    expect(
        effect.getFields().map((f) => f.key),
        isNot(anyOf(
          contains('renderSky'),
          contains('skyGradient'),
          contains('skyNoise'),
          contains('clearingWidth'),
          contains('clearingPosition'),
          contains('sunSize'),
        )));
    expect(render({'renderSky': true, 'skyNoise': 1, 'sunSize': .2, 'clearingWidth': 1, 'clearingPosition': .5}),
        orderedEquals(render({})));
  });

  test('lighting does not move trees', () {
    final a = render({'renderSky': false, 'enableShadows': false});
    final b = render({'renderSky': false, 'enableShadows': false, 'sunPosition': 0, 'rimLight': 1, 'lightingAngle': 0});
    expect(a.map((p) => p >> 24), orderedEquals(b.map((p) => p >> 24)));
    expect(a, isNot(orderedEquals(b)));
  });

  test('planning and species controls change the forest', () {
    final base = render({});
    for (final settings in [
      {'treeType': 0},
      {'treeType': 1},
      {'treeType': 3},
      {'treeType': 4},
      {'terrainRelief': 1},
      {'layers': 1},
      {'treeDensity': .1},
      {'randomSeed': 77},
    ]) {
      expect(render(settings), isNot(orderedEquals(base)), reason: '$settings');
    }
  });

  test('render optional forest contact sheet', () {
    final path = Platform.environment['FOREST_PREVIEW'];
    if (path == null) return;
    final sheet = img.Image(width: 1152, height: 512);
    for (var panel = 0; panel < 6; panel++) {
      final pixels = render({
        'treeType': [0, 1, 2, 3, 4, 2][panel],
        'colorScheme': panel,
        'enableMist': panel == 4,
        'godRays': panel == 4 ? .7 : 0,
      }, 192, 128);
      final frame = img.Image(width: 192, height: 128);
      for (var y = 0; y < 128; y++) {
        for (var x = 0; x < 192; x++) {
          final p = pixels[y * 192 + x];
          frame.setPixelRgba(x, y, p >> 16 & 255, p >> 8 & 255, p & 255, p >> 24);
        }
      }
      img.compositeImage(
          sheet, img.copyResize(frame, width: 384, height: 256, interpolation: img.Interpolation.nearest),
          dstX: panel % 3 * 384, dstY: panel ~/ 3 * 256);
    }
    File(path).writeAsBytesSync(img.encodePng(sheet));
  });
}
