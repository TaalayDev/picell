import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

const _w = 0xFFFFFFFF;
const _r = 0xFFFF0000;
const _g = 0xFF00FF00;

/// 8×12 test sprite: rows 2..3 = head (red), 4..8 = body (white),
/// 9..11 = legs (green).
Uint32List _sprite() {
  const width = 8;
  const height = 12;
  final pixels = Uint32List(width * height);
  for (int y = 2; y < height; y++) {
    final color = y < 4 ? _r : (y < 9 ? _w : _g);
    for (int x = 2; x < 6; x++) {
      pixels[y * width + x] = color;
    }
  }
  return pixels;
}

int _topRow(Uint32List p, int width, int height) {
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if ((p[y * width + x] >>> 24) != 0) return y;
    }
  }
  return -1;
}

void main() {
  group('BreathingEffect', () {
    test('is registered, animated and serializable', () {
      final effect = EffectsManager.createEffect(EffectType.breathing, {'frames': 6});
      expect(effect, isA<BreathingEffect>());
      expect(effect.isAnimation, isTrue);
      expect(effect.preferredFrameCount, 6);
      expect(effect.isSeamlessLoop, isTrue);

      final fromJson = EffectsManager.effectFromJson({
        'type': 'breathing',
        'parameters': {'frames': 4},
      });
      expect(fromJson, isA<BreathingEffect>());
      expect(fromJson?.preferredFrameCount, 4);
    });

    test('frame count is clamped', () {
      expect(BreathingEffect({'frames': 1}).preferredFrameCount, 2);
      expect(BreathingEffect({'frames': 99}).preferredFrameCount, 24);
    });

    test('rest pose (time 0) is unchanged', () {
      final pixels = _sprite();
      final out = BreathingEffect().apply(pixels, 8, 12);
      expect(out, equals(pixels));
    });

    test('bottom anchor: feet planted, head rises rigidly on inhale', () {
      final pixels = _sprite();
      // Two-pose classic: frame 0 = inhale, frame 1 = exhale.
      final inhale = BreathingEffect({
        'frames': 2,
        'easing': 'step',
        'hold': 0.0,
        'depth': 1,
        'style': 'chest',
        'time': 0.0,
      }).apply(pixels, 8, 12);

      // Legs untouched.
      for (int y = 9; y < 12; y++) {
        expect(inhale[y * 8 + 3], _g, reason: 'leg row $y moved');
      }
      // Head shifted up by exactly one pixel, without distortion.
      expect(_topRow(inhale, 8, 12), 1);
      expect(inhale[1 * 8 + 3], _r);
      expect(inhale[2 * 8 + 3], _r);
      expect(inhale[3 * 8 + 3], _w);

      final exhale = BreathingEffect({
        'frames': 2,
        'easing': 'step',
        'hold': 0.0,
        'depth': 1,
        'time': 0.5,
      }).apply(pixels, 8, 12);
      expect(exhale, equals(pixels));
    });

    test('top anchor keeps top row fixed and extends downward', () {
      final pixels = _sprite();
      final out = BreathingEffect({
        'frames': 2,
        'easing': 'step',
        'hold': 0.0,
        'depth': 2,
        'anchor': 'top',
        'time': 0.0,
      }).apply(pixels, 8, 12);

      expect(_topRow(out, 8, 12), 2);
      expect(out[2 * 8 + 3], _r);
      // Sprite would extend past canvas bottom; legs still present at bottom.
      expect(out[11 * 8 + 3], _g);
    });

    test('chest expansion widens the torso but not head or feet', () {
      final pixels = _sprite();
      final out = BreathingEffect({
        'frames': 2,
        'easing': 'step',
        'hold': 0.0,
        'depth': 1,
        'chestExpand': 1,
        'time': 0.0,
      }).apply(pixels, 8, 12);

      int rowWidth(int y) {
        int c = 0;
        for (int x = 0; x < 8; x++) {
          if ((out[y * 8 + x] >>> 24) != 0) c++;
        }
        return c;
      }

      expect(rowWidth(10), 4, reason: 'feet must not widen');
      expect(rowWidth(1), 4, reason: 'head must not widen');
      final maxTorso = [for (int y = 3; y < 9; y++) rowWidth(y)].reduce((a, b) => a > b ? a : b);
      expect(maxTorso, greaterThan(4));
    });

    test('live time is quantized to frame poses', () {
      final pixels = _sprite();
      Uint32List at(double t) => BreathingEffect({
            'frames': 4,
            'depth': 3,
            'hold': 0.0,
            'easing': 'smooth',
            'time': t,
          }).apply(pixels, 8, 12);

      expect(at(0.25), equals(at(0.3)));
      expect(at(0.5), equals(at(0.74)));
    });

    test('empty layer is returned unchanged', () {
      final pixels = Uint32List(16);
      expect(BreathingEffect({'time': 0.3}).apply(pixels, 4, 4), equals(pixels));
    });
  });
}
