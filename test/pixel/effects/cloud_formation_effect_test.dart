import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/pixel/effects/effects.dart';

void main() {
  Uint32List render(Map<String, dynamic> settings, [int w = 128, int h = 96]) =>
      CloudFormationEffect(settings).apply(Uint32List(w * h), w, h);

  test('seeded cloud layout replaces source deterministically without mutation', () {
    final source = Uint32List(128 * 96)..fillRange(0, 128 * 96, 0xffff00ff);
    final effect = CloudFormationEffect();
    final output = effect.apply(source, 128, 96);
    expect(output, orderedEquals(render({})));
    expect(source, everyElement(0xffff00ff));
    expect(render({'randomSeed': 43}), isNot(orderedEquals(output)));
    expect(output.any((p) => p == 0), isTrue);
    expect(output.any((p) => p >> 24 > 0 && p >> 24 < 255), isTrue);
  });

  test('factory loads partial legacy settings and exposes positioning controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'cloudFormation',
      'parameters': {'layers': 1.0, 'density': 1, 'skyGradient': true}
    })!;
    expect(effect, isA<CloudFormationEffect>());
    expect(effect.apply(Uint32List(4096), 64, 64).any((p) => p != 0), isTrue);
    final keys = effect.getFields().map((f) => f.key);
    expect(keys, containsAll(['startY', 'cloudScale', 'windShear', 'style', 'randomSeed']));
    expect(keys, isNot(contains('skyGradient')));
    expect(render({'skyGradient': true}), orderedEquals(render({})));
  });

  test('Start Y confines all clouds to the requested generation area', () {
    final output = render({'startY': .5}, 64, 64);
    expect(output.take(64 * 32), everyElement(0));
    expect(output.skip(64 * 32).any((p) => p != 0), isTrue);
    expect(render({'startY': 1}), everyElement(0));
    expect(render({'startY': 2}), everyElement(0));
    expect(render({'startY': -1}), orderedEquals(render({})));
  });

  test('zero coverage or density produces empty transparent output', () {
    expect(render({'coverage': 0}), everyElement(0));
    expect(render({'density': 0}), everyElement(0));
  });

  test('all cloud styles handle tiny and narrow canvases and single layers', () {
    for (final size in [(1, 1), (1, 32), (32, 1), (3, 2), (8, 8), (96, 32)]) {
      for (var style = 0; style < 5; style++) {
        for (final layers in [1, 5]) {
          expect(render({'style': style, 'layers': layers}, size.$1, size.$2), hasLength(size.$1 * size.$2));
        }
      }
    }
    expect(render({}, 0, 0), isEmpty);
  });

  test('lighting and haze change colors without moving clouds', () {
    final base = render({});
    final lit = render({'sunPosition': 0, 'atmosphericHaze': 1, 'colorScheme': 1});
    expect(lit.map((p) => p >> 24), orderedEquals(base.map((p) => p >> 24)));
    expect(lit, isNot(orderedEquals(base)));
    for (final settings in [
      {'style': 1},
      {'style': 2},
      {'style': 3},
      {'style': 4},
      {'cloudScale': 1},
      {'windShear': 1},
      {'coverage': 1},
      {'baseHeight': .8},
    ]) {
      expect(render(settings), isNot(orderedEquals(base)), reason: '$settings');
    }
  });

  test('render optional cloud contact sheet', () {
    final path = Platform.environment['CLOUD_PREVIEW'];
    if (path == null) return;
    final sheet = img.Image(width: 1152, height: 512);
    for (var panel = 0; panel < 6; panel++) {
      final pixels = render({
        'style': [0, 1, 2, 3, 4, 0][panel],
        'colorScheme': panel % 5,
        'baseHeight': .5
      }, 192, 128);
      final frame = img.Image(width: 192, height: 128);
      for (var y = 0; y < 128; y++) {
        for (var x = 0; x < 192; x++) {
          final p = pixels[y * 192 + x];
          final alpha = (p >> 24) / 255;
          final bg = (x ~/ 8 + y ~/ 8).isEven ? 48 : 57;
          int c(int shift) => (((p >> shift & 255) * alpha) + bg * (1 - alpha)).round();
          frame.setPixelRgba(x, y, c(16), c(8), c(0), 255);
        }
      }
      img.compositeImage(
          sheet, img.copyResize(frame, width: 384, height: 256, interpolation: img.Interpolation.nearest),
          dstX: panel % 3 * 384, dstY: panel ~/ 3 * 256);
    }
    File(path).writeAsBytesSync(img.encodePng(sheet));
  });
}
