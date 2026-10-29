import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/gradient/gradient_renderer.dart';

const _black = 0xFF000000;
const _white = 0xFFFFFFFF;
const _red = 0xFFFF0000;

Uint32List _render(
  GradientSpec spec, {
  int width = 16,
  int height = 1,
  Uint32List? base,
  Uint8List? mask,
}) =>
    GradientRenderer.render(
      base: base ?? Uint32List(width * height),
      width: width,
      height: height,
      spec: spec,
      mask: mask,
    );

/// Horizontal gradient spanning the full width of a [width]-pixel row.
GradientSpec _horizontal(
  int width,
  List<int> stops, {
  int? steps,
  GradientDither dither = GradientDither.none,
  double spread = 1,
  GradientBlend blend = GradientBlend.replace,
}) =>
    GradientSpec(
      start: const Offset(0, 0.5),
      end: Offset(width.toDouble(), 0.5),
      stops: stops,
      steps: steps,
      dither: dither,
      ditherSpread: spread,
      blend: blend,
    );

void main() {
  group('smooth', () {
    test('runs from first to last stop and brightens monotonically', () {
      final out = _render(_horizontal(16, [_black, _white]));
      expect(out.first & 0xFF, lessThan(0x10));
      expect(out.last & 0xFF, greaterThan(0xEF));
      for (int i = 1; i < out.length; i++) {
        expect(out[i] & 0xFF, greaterThanOrEqualTo(out[i - 1] & 0xFF));
      }
    });

    test('clamps beyond the endpoints', () {
      const spec = GradientSpec(
        start: Offset(4, 0.5),
        end: Offset(12, 0.5),
        stops: [_black, _white],
      );
      final out = _render(spec);
      for (int x = 0; x < 4; x++) {
        expect(out[x], _black);
      }
      for (int x = 12; x < 16; x++) {
        expect(out[x], _white);
      }
    });

    test('fading to transparent keeps the hue', () {
      final mid = GradientRenderer.lerpPremultiplied(_red, 0x00000000, 0.5);
      expect(mid >>> 24, closeTo(0x80, 1));
      expect(mid & 0x00FFFFFF, 0x00FF0000);
    });
  });

  group('steps', () {
    test('produces equal-width bands in order', () {
      final out = _render(_horizontal(16, [_black, _white], steps: 4));
      final bands = GradientRenderer.bandColors(const [_black, _white], 4);
      expect(bands.first, _black);
      expect(bands.last, _white);
      for (int x = 0; x < 16; x++) {
        expect(out[x], bands[x ~/ 4], reason: 'pixel $x');
      }
    });

    test('palette ramp introduces no new colours', () {
      const ramp = [0xFF1A1C2C, 0xFF5D275D, 0xFFB13E53, 0xFFEF7D57];
      final out = _render(
        _horizontal(32, ramp, steps: 4, dither: GradientDither.bayer4),
        width: 32,
        height: 8,
      );
      expect(out.toSet(), ramp.toSet());
    });

    test('multi-stop ramp samples through intermediate stops', () {
      final bands = GradientRenderer.bandColors(const [_black, _red, _white], 3);
      expect(bands, const [_black, _red, _white]);
      final five = GradientRenderer.bandColors(const [_black, _red, _white], 5);
      expect(five[2], _red);
    });
  });

  group('dither', () {
    GradientSpec spec(GradientDither d, {double spread = 1}) => GradientSpec(
          start: const Offset(0, 0),
          end: const Offset(32, 0),
          stops: const [_black, _white],
          steps: 2,
          dither: d,
          ditherSpread: spread,
        );

    int mixedColumns(Uint32List out, int width, int height) {
      var mixed = 0;
      for (int x = 0; x < width; x++) {
        final col = {for (int y = 0; y < height; y++) out[y * width + x]};
        if (col.length > 1) mixed++;
      }
      return mixed;
    }

    test('only emits band colours and is deterministic', () {
      for (final d in GradientDither.values) {
        final a = _render(spec(d), width: 32, height: 8);
        final b = _render(spec(d), width: 32, height: 8);
        expect(a, b, reason: d.name);
        expect(a.toSet().difference({_black, _white}), isEmpty);
      }
    });

    test('no dither gives a hard edge; dither mixes the transition', () {
      final hard = _render(spec(GradientDither.none), width: 32, height: 8);
      expect(mixedColumns(hard, 32, 8), 0);

      final soft = _render(spec(GradientDither.bayer4), width: 32, height: 8);
      expect(mixedColumns(soft, 32, 8), greaterThan(8));
    });

    test('dither density follows position', () {
      final out = _render(spec(GradientDither.bayer8), width: 32, height: 8);
      double whiteShare(int x) => List.generate(8, (y) => out[y * 32 + x]).where((c) => c == _white).length / 8;
      expect(whiteShare(4), lessThan(whiteShare(16)));
      expect(whiteShare(16), lessThan(whiteShare(28)));
    });

    test('smaller spread narrows the dithered seam', () {
      final wide = _render(spec(GradientDither.bayer4), width: 32, height: 8);
      final narrow = _render(
        spec(GradientDither.bayer4, spread: 0.25),
        width: 32,
        height: 8,
      );
      expect(
        mixedColumns(narrow, 32, 8),
        lessThan(mixedColumns(wide, 32, 8)),
      );
      expect(mixedColumns(narrow, 32, 8), greaterThan(0));
    });

    test('bayer matrices are permutations of 0..n²-1', () {
      expect(GradientRenderer.bayerMatrix(2), [0, 2, 3, 1]);
      for (final n in [2, 4, 8]) {
        final m = GradientRenderer.bayerMatrix(n);
        expect(m.toSet(), {for (int i = 0; i < n * n; i++) i});
      }
    });

    test('dither is ignored for smooth gradients', () {
      final plain = _render(_horizontal(16, [_black, _white]));
      final dithered = _render(
        _horizontal(16, [_black, _white], dither: GradientDither.bayer4),
      );
      expect(dithered, plain);
    });
  });

  group('geometry', () {
    Uint32List shape(GradientType type, {Offset end = const Offset(8, 4)}) => _render(
          GradientSpec(
            type: type,
            start: const Offset(4, 4),
            end: end,
            stops: const [_black, _white],
            steps: 4,
          ),
          width: 8,
          height: 8,
        );

    test('reflected mirrors around the start point', () {
      final out = shape(GradientType.reflected);
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          expect(out[y * 8 + x], out[y * 8 + (7 - x)], reason: '($x,$y)');
        }
      }
      expect(out[4 * 8 + 0], _white);
      expect(out[4 * 8 + 4], _black);
    });

    test('diamond is constant along |dx| + |dy|', () {
      final out = shape(GradientType.diamond);
      // Pixel centres at equal Manhattan distance from (4, 4).
      expect(out[4 * 8 + 6], out[6 * 8 + 4]);
      expect(out[4 * 8 + 6], out[5 * 8 + 5]);
      // The four pixels around (4, 4) are equidistant.
      expect(out[3 * 8 + 3], out[4 * 8 + 4]);
      expect(out[3 * 8 + 3], isNot(_white));
      expect(out[0], _white);
    });

    test('angle sweeps once around the start', () {
      final out = _render(
        const GradientSpec(
          type: GradientType.angle,
          start: Offset(4, 4),
          end: Offset(8, 4),
          stops: [_black, _white],
        ),
        width: 8,
        height: 8,
      );
      int lum(int x, int y) => out[y * 8 + x] & 0xFF;
      // Starts dark just clockwise of the drag direction (→), brightens
      // through ↓, ←, ↑ (screen space, y down).
      expect(lum(7, 4), lessThan(lum(4, 7)));
      expect(lum(4, 7), lessThan(lum(0, 4)));
      expect(lum(0, 4), lessThan(lum(4, 0)));
    });

    test('start == end fills with the first stop', () {
      final out = _render(
        const GradientSpec(
          start: Offset(3, 3),
          end: Offset(3, 3),
          stops: [_red, _white],
        ),
        width: 4,
        height: 4,
      );
      expect(out.toSet(), {_red});
    });

    test('radial is centred on start and symmetric', () {
      final out = _render(
        const GradientSpec(
          type: GradientType.radial,
          start: Offset(4, 4),
          end: Offset(8, 4),
          stops: [_black, _white],
          steps: 4,
        ),
        width: 8,
        height: 8,
      );
      expect(out[3 * 8 + 3], _black);
      expect(out[0], _white);
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          expect(out[y * 8 + x], out[y * 8 + (7 - x)]);
          expect(out[y * 8 + x], out[(7 - y) * 8 + x]);
        }
      }
    });

    test('diagonal linear gradient is constant along perpendiculars', () {
      final out = _render(
        const GradientSpec(
          start: Offset(0, 0),
          end: Offset(8, 8),
          stops: [_black, _white],
          steps: 4,
        ),
        width: 8,
        height: 8,
      );
      // Pixels on the same anti-diagonal (x + y const) project to the same t.
      for (int s = 0; s < 15; s++) {
        final colors = {
          for (int x = max(0, s - 7); x <= min(7, s); x++) out[(s - x) * 8 + x],
        };
        expect(colors.length, 1, reason: 'anti-diagonal $s');
      }
    });
  });

  group('mask and blend', () {
    test('pixels outside the mask are untouched', () {
      final base = Uint32List(16)..fillRange(0, 16, 0xFF00FF00);
      final mask = Uint8List(16)..fillRange(4, 8, 1);
      final out = _render(_horizontal(16, [_black, _white]), base: base, mask: mask);
      for (int x = 0; x < 16; x++) {
        if (x >= 4 && x < 8) {
          expect(out[x], isNot(0xFF00FF00));
        } else {
          expect(out[x], 0xFF00FF00);
        }
      }
      expect(base[5], 0xFF00FF00, reason: 'base must not be mutated');
    });

    test('replace overwrites alpha', () {
      final base = Uint32List(4)..fillRange(0, 4, _white);
      final out = _render(
        _horizontal(4, [0x00000000]),
        width: 4,
        base: base,
      );
      expect(out.toSet(), {0x00000000});
    });

    test('over matches Color.alphaBlend', () {
      final rnd = Random(7);
      for (int i = 0; i < 200; i++) {
        final src = rnd.nextInt(1 << 32);
        final dst = rnd.nextInt(1 << 32);
        expect(
          GradientRenderer.blendOver(src, dst),
          Color.alphaBlend(Color(src), Color(dst)).toARGB32(),
          reason: '${src.toRadixString(16)} over ${dst.toRadixString(16)}',
        );
      }
    });

    test('lockAlpha skips transparent pixels and keeps alpha', () {
      final base = Uint32List.fromList([0x00000000, 0x80FFFFFF, _white, 0]);
      final out = _render(
        _horizontal(4, [_red], blend: GradientBlend.lockAlpha),
        width: 4,
        base: base,
      );
      expect(out[0], 0x00000000);
      expect(out[1], 0x80FF0000);
      expect(out[2], _red);
      expect(out[3], 0);
    });
  });
}
