import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  Uint32List render(Map<String, dynamic> settings, [int w = 128, int h = 96]) =>
      MountainRangeEffect(settings).apply(Uint32List(w * h), w, h);

  test('seeded summits are deterministic and animation wraps seamlessly', () {
    final output = render({});
    expect(render({}), orderedEquals(output));
    expect(render({'time': 1}), orderedEquals(output));
    expect(render({'randomSeed': 43}), isNot(orderedEquals(output)));
    expect(render({'parallaxScroll': false, 'time': .4}), orderedEquals(output));
    expect(MountainRangeEffect().isSeamlessLoop, isTrue);
  });

  test('all styles render on tiny and narrow canvases without mutating input', () {
    for (final size in [(1, 1), (1, 32), (32, 1), (3, 2), (8, 8)]) {
      for (var style = 0; style < 5; style++) {
        final input = Uint32List(size.$1 * size.$2)..fillRange(0, size.$1 * size.$2, 0x80123456);
        final result = MountainRangeEffect({'style': style, 'layers': 5.0, 'skyGradient': false, 'preserveAlpha': true})
            .apply(input, size.$1, size.$2);
        expect(input, everyElement(0x80123456));
        expect(result.every((p) => p == 0 || p >> 24 == 128), isTrue);
      }
    }
    expect(render({}, 0, 0), isEmpty);
  });

  test('lighting and snow preserve skyline while planning changes it', () {
    final output = render({'skyGradient': false});
    expect(output.first, 0);
    expect(render({'skyGradient': false, 'sunPosition': .1, 'snowCaps': 1}).map((p) => p >> 24),
        orderedEquals(output.map((p) => p >> 24)));
    for (final settings in [
      {'peakSpacing': 0},
      {'detailLevel': 0},
      {'ridgeStrength': 0}
    ]) {
      expect(render(settings), isNot(orderedEquals(render({}))), reason: '$settings');
    }
  });

  test('Start Y leaves space above and scales mountains into the remaining canvas', () {
    final shifted = render({'startY': .25}, 64, 64);
    expect(shifted.take(64 * 16), everyElement(0));
    expect(shifted.skip(64 * 16), orderedEquals(render({}, 64, 48)));
    expect(render({'startY': 1}, 64, 64), everyElement(0));
    expect(render({'startY': -1}), orderedEquals(render({})));
    expect(render({'startY': 2}), everyElement(0));
  });

  test('legacy sky settings cannot paint a background', () {
    final output = render({});
    expect(output.first, 0);
    expect(render({'skyGradient': true, 'sunSize': .2, 'sunStrength': 1}), orderedEquals(output));
  });

  test('render optional mountain contact sheet', () {
    final path = Platform.environment['MOUNTAIN_PREVIEW'];
    if (path == null) return;
    final sheet = img.Image(width: 1152, height: 512);
    for (var panel = 0; panel < 6; panel++) {
      final pixels = render({
        'style': [0, 1, 2, 3, 4, 3][panel],
        'colorScheme': panel,
        'snowCaps': panel == 5 ? .8 : .45
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

  group('MountainRangeEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = MountainRangeEffect();
      expect(effect.type, equals(EffectType.mountainRange));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['layers'], equals(3));
      expect(effect.parameters['style'], equals(0));
      expect(effect.parameters['heightVariation'], equals(0.55));
      expect(effect.parameters['baseHeight'], equals(0.0));
      expect(effect.parameters['colorScheme'], equals(0));
      expect(effect.parameters['atmosphericHaze'], equals(0.5));
      expect(effect.parameters['snowCaps'], equals(0.2));
      expect(effect.parameters['mistIntensity'], equals(0.3));
      expect(effect.parameters.containsKey('skyGradient'), isFalse);
      expect(effect.parameters['startY'], 0.0);
      expect(effect.parameters['sunPosition'], equals(0.7));
      expect(effect.parameters['parallaxScroll'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = MountainRangeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'layers' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'style' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'heightVariation' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'baseHeight' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'colorScheme' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'atmosphericHaze' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'snowCaps' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'mistIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'skyGradient'), isFalse);
      expect(fields.any((f) => f.key == 'startY' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sunPosition' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'parallaxScroll' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes MountainRangeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.mountainRange,
        {
          'style': 3,
          'colorScheme': 1,
          'layers': 4,
          'snowCaps': 0.5,
        },
      );
      expect(effect, isA<MountainRangeEffect>());
      expect(effect.parameters['style'], equals(3));
      expect(effect.parameters['colorScheme'], equals(1));
      expect(effect.parameters['layers'], equals(4));
      expect(effect.parameters['snowCaps'], equals(0.5));
    });

    test('renders multi-layered mountain panorama on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = MountainRangeEffect({
        'style': 0,
        'colorScheme': 0,
        'layers': 3,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('renders different styles (Jagged vs Rolling Ridge vs Volcanic)', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final jagged = MountainRangeEffect({
        'style': 1,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final rolling = MountainRangeEffect({
        'style': 2,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final volcanic = MountainRangeEffect({
        'style': 4,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffJaggedRolling = false;
      bool diffJaggedVolcanic = false;
      for (int i = 0; i < pixels.length; i++) {
        if (jagged[i] != rolling[i]) diffJaggedRolling = true;
        if (jagged[i] != volcanic[i]) diffJaggedVolcanic = true;
      }
      expect(diffJaggedRolling, isTrue);
      expect(diffJaggedVolcanic, isTrue);
    });

    test('colorScheme variations produce distinct color output', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final blue = MountainRangeEffect({
        'colorScheme': 0,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final sunset = MountainRangeEffect({
        'colorScheme': 1,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final green = MountainRangeEffect({
        'colorScheme': 3,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffBlueSunset = false;
      bool diffBlueGreen = false;
      for (int i = 0; i < pixels.length; i++) {
        if (blue[i] != sunset[i]) diffBlueSunset = true;
        if (blue[i] != green[i]) diffBlueGreen = true;
      }
      expect(diffBlueSunset, isTrue);
      expect(diffBlueGreen, isTrue);
    });

    test('time animation drives parallax scrolling and diurnal sun transit', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final t0 = MountainRangeEffect({
        'time': 0.0,
        'parallaxScroll': true,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final t5 = MountainRangeEffect({
        'time': 0.5,
        'parallaxScroll': true,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (t0[i] != t5[i]) {
          diffDetected = true;
          break;
        }
      }
      expect(diffDetected, isTrue);
    });

    test('preserveAlpha respects input sprite silhouette mask', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a small 4x4 square in the center
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          pixels[y * width + x] = 0xFF00FF00;
        }
      }

      final effect = MountainRangeEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Outside the 4x4 square must stay 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 6 || x >= 10 || y < 6 || y >= 10) {
            expect(out[y * width + x], equals(0));
          }
        }
      }

      // Inside the 4x4 square should be drawn
      int nonZeroInside = 0;
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          if (out[y * width + x] != 0) nonZeroInside++;
        }
      }
      expect(nonZeroInside, greaterThan(0));
    });
  });
}
