import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/pixel/effects/effects.dart';

void main() {
  Uint32List render(Map<String, dynamic> settings, [int w = 128, int h = 96]) =>
      OceanEffect(settings).apply(Uint32List(w * h), w, h);

  test('ocean is deterministic, replaces input, and loops seamlessly', () {
    final source = Uint32List(128 * 96)..fillRange(0, 128 * 96, 0xffff00ff);
    final output = OceanEffect().apply(source, 128, 96);
    expect(output, orderedEquals(render({})));
    expect(source, everyElement(0xffff00ff));
    expect(render({'time': 1}), orderedEquals(output));
    expect(render({'time': .25}), isNot(orderedEquals(output)));
    expect(render({'randomSeed': 43}), isNot(orderedEquals(output)));
    expect(OceanEffect().isSeamlessLoop, isTrue);
  });

  test('Start Y leaves transparent sky and fills only the water region', () {
    final output = render({'startY': .5}, 64, 64);
    expect(output.take(64 * 32), everyElement(0));
    expect(output.skip(64 * 32).every((p) => p >> 24 == 255), isTrue);
    expect(render({'startY': 1}), everyElement(0));
    expect(render({'startY': 2}), everyElement(0));
    expect(render({'startY': -1}).every((p) => p >> 24 == 255), isTrue);
  });

  test('legacy horizon migrates and sky settings no longer paint a background', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'ocean',
      'parameters': {'horizonLevel': .6, 'waveFrequency': 1, 'skyGradient': true}
    })!;
    expect(effect, isA<OceanEffect>());
    expect(effect.parameters['startY'], .6);
    final keys = effect.getFields().map((f) => f.key);
    expect(keys, containsAll(['startY', 'oceanStyle', 'perspective', 'randomSeed']));
    expect(keys, isNot(anyOf(contains('skyGradient'), contains('cloudCover'), contains('sunSize'))));
    expect(render({'horizonLevel': .2}), orderedEquals(render({'startY': .2})));
    expect(render({'horizonLevel': .2, 'startY': .7}), orderedEquals(render({'startY': .7})));
    expect(render({'skyGradient': true, 'cloudCover': 1, 'sunSize': 1}), orderedEquals(render({})));
  });

  test('all styles and palettes handle tiny and narrow canvases', () {
    for (final size in [(1, 1), (1, 32), (32, 1), (3, 2), (8, 8)]) {
      for (var style = 0; style < 4; style++) {
        for (var palette = 0; palette < 8; palette++) {
          final output =
              render({'oceanStyle': style, 'colorScheme': palette, 'startY': 0, 'waveAmplitude': 1}, size.$1, size.$2);
          expect(output, hasLength(size.$1 * size.$2));
          expect(output.every((p) => p >> 24 == 255), isTrue);
        }
      }
    }
    expect(render({}, 0, 0), isEmpty);
  });

  test('wave, foam, perspective and style controls visibly affect water', () {
    final base = render({});
    for (final settings in [
      {'oceanStyle': 1},
      {'oceanStyle': 2},
      {'oceanStyle': 3},
      {'waveAmplitude': 0},
      {'waveFrequency': 0},
      {'waveDirection': 0},
      {'foamIntensity': 0},
      {'perspective': 0},
      {'sunGlare': 0},
      {'waterDepth': 0},
      {'waveComplexity': 0},
    ]) {
      expect(render(settings), isNot(orderedEquals(base)), reason: '$settings');
    }
  });

  test('End Y bounds ocean output and empty or reversed ranges render nothing', () {
    final output = render({'startY': .25, 'endY': .75}, 64, 64);
    expect(output.take(16 * 64), everyElement(0));
    expect(output.skip(48 * 64), everyElement(0));
    expect(output.skip(16 * 64).take(32 * 64).every((p) => p >> 24 == 255), isTrue);
    expect(render({'startY': .5, 'endY': .5}), everyElement(0));
    expect(render({'startY': .8, 'endY': .2}), everyElement(0));
    expect(render({'endY': 2}), orderedEquals(render({})));
  });

  test('coast adds shoreline within bounds and keeps seamless animation', () {
    final settings = {'coast': true, 'startY': .25, 'endY': .75};
    final output = render(settings, 64, 64);
    expect(output, isNot(orderedEquals(render({'startY': .25, 'endY': .75}, 64, 64))));
    expect(output.take(16 * 64), everyElement(0));
    expect(output.skip(48 * 64), everyElement(0));
    expect(render({...settings, 'time': 1}, 64, 64), orderedEquals(output));
    expect(render({...settings, 'time': .25}, 64, 64), isNot(orderedEquals(output)));
    expect(OceanEffect().getFields().map((f) => f.key), containsAll(['endY', 'coast']));
  });

  test('render optional ocean contact sheet', () {
    final path = Platform.environment['OCEAN_PREVIEW'];
    if (path == null) return;
    final sheet = img.Image(width: 1152, height: 512);
    for (var panel = 0; panel < 6; panel++) {
      final pixels = render({
        'oceanStyle': [0, 1, 2, 3, 0, 0][panel],
        'colorScheme': [0, 5, 0, 3, 2, 6][panel],
        'startY': .18
      }, 192, 128);
      final frame = img.Image(width: 192, height: 128);
      for (var y = 0; y < 128; y++) {
        for (var x = 0; x < 192; x++) {
          final p = pixels[y * 192 + x];
          final bg = (x ~/ 8 + y ~/ 8).isEven ? 48 : 57;
          frame.setPixelRgba(x, y, p == 0 ? bg : p >> 16 & 255, p == 0 ? bg : p >> 8 & 255, p == 0 ? bg : p & 255, 255);
        }
      }
      img.compositeImage(
          sheet, img.copyResize(frame, width: 384, height: 256, interpolation: img.Interpolation.nearest),
          dstX: panel % 3 * 384, dstY: panel ~/ 3 * 256);
    }
    File(path).writeAsBytesSync(img.encodePng(sheet));
  });
}
