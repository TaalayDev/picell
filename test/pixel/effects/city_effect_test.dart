import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/pixel/effects/effects.dart';

void main() {
  Uint32List render(Map<String, dynamic> settings, [int w = 128, int h = 96]) =>
      CityEffect(settings).apply(Uint32List(w * h), w, h);

  test('seeded city is deterministic and replaces source without mutating it', () {
    final input = Uint32List(128 * 96)..fillRange(0, 128 * 96, 0xff123456);
    final effect = CityEffect();
    final output = effect.apply(input, 128, 96);
    expect(output, orderedEquals(render({})));
    expect(render({}), orderedEquals(render({})));
    expect(render({'randomSeed': 43}), isNot(orderedEquals(output)));
    expect(input, everyElement(0xff123456));
  });

  test('legacy partial settings and integer slider values survive JSON loading', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'city',
      'parameters': {'buildingDensity': 1, 'randomSeed': 17, 'buildingStyle': 4},
    });
    expect(effect, isA<CityEffect>());
    expect(effect!.apply(Uint32List(64 * 64), 64, 64), hasLength(4096));
    expect(
        effect.getFields().map((f) => f.key),
        containsAll([
          'depthLayers',
          'districtLayout',
          'landmarkStrength',
          'waterReflection',
        ]));
  });

  test('all styles and weather work on tiny and narrow canvases', () {
    for (final size in [(1, 1), (1, 32), (32, 1), (2, 3), (8, 8), (96, 32)]) {
      for (var style = 0; style < 6; style++) {
        for (var weather = 0; weather < 4; weather++) {
          final output = render({
            'buildingStyle': style,
            'weatherEffect': weather,
            'waterReflection': true,
            'minHeight': 1,
            'maxHeight': 0,
          }, size.$1, size.$2);
          expect(output, hasLength(size.$1 * size.$2));
          expect(output.every((p) => p == 0 || p >> 24 == 255), isTrue);
        }
      }
    }
    expect(CityEffect().apply(Uint32List(0), 0, 0), isEmpty);
  });

  test('night and rain preserve skyline alpha on transparent exports', () {
    final clear = render({'groundStreets': false});
    for (final weather in [1, 2, 3]) {
      final output = render({'groundStreets': false, 'weatherEffect': weather});
      expect(output.map((p) => p >> 24), orderedEquals(clear.map((p) => p >> 24)));
    }
    expect(clear.first, 0);
    expect(clear.any((p) => p != 0), isTrue);
  });

  test('sky choice does not reshuffle architecture', () {
    final transparent = render({'backgroundMode': 0});
    final sky = render({'backgroundMode': 2});
    for (var i = 0; i < sky.length; i++) {
      if (transparent[i] != 0) expect(sky[i], transparent[i]);
    }
    expect(sky.every((p) => p >> 24 == 255), isTrue);
  });

  test('district planning, depth and architectural controls affect output', () {
    final base = render({});
    for (final settings in [
      {'districtLayout': 1},
      {'districtLayout': 2},
      {'depthLayers': 1},
      {'buildingStyle': 1},
      {'buildingStyle': 2},
      {'buildingStyle': 4},
      {'buildingStyle': 5},
      {'windowDensity': 0},
      {'buildingDensity': 0},
      {'landmarkStrength': 0},
      {'waterReflection': true},
    ]) {
      expect(render(settings), isNot(orderedEquals(base)), reason: '$settings');
    }
  });

  test('render visual contact sheet when requested', () {
    final path = Platform.environment['CITY_PREVIEW'];
    if (path == null) return;
    final sheet = img.Image(width: 384 * 3, height: 256 * 2);
    for (var style = 0; style < 6; style++) {
      final pixels = render({
        'buildingStyle': style,
        'colorScheme': style,
        'backgroundMode': 1,
        'weatherEffect': style.isOdd ? 3 : 0,
        'waterReflection': style >= 3,
        'randomSeed': 42,
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
          dstX: style % 3 * 384, dstY: style ~/ 3 * 256);
    }
    File(path).writeAsBytesSync(img.encodePng(sheet));
  });
}
