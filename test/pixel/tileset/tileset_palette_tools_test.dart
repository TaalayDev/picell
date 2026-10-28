import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_palette_tools.dart';

void main() {
  test('suggested shades keep the base as Mid and order light above mid above dark', () {
    final shades = suggestShades(0xff4e9a44);
    expect(shades[5], 0xff4e9a44);
    expect(tilesetLuminance(shades[4]!), greaterThan(tilesetLuminance(shades[5]!)));
    expect(tilesetLuminance(shades[5]!), greaterThan(tilesetLuminance(shades[6]!)));
    expect(tilesetLuminance(shades[7]!), greaterThan(tilesetLuminance(shades[4]!)));
    expect(tilesetLuminance(shades[0]!), lessThan(tilesetLuminance(shades[6]!)));
    expect(paletteContrastWarning([shades[0]!, 0, 0, 0, shades[4]!, shades[5]!, shades[6]!, shades[7]!]), isNull);
  });

  test('flat palettes warn about the closest pair', () {
    const flat = 0xff808080;
    expect(paletteContrastWarning([0, 0, 0, 0, flat, flat, 0xff202020, 0]), contains('Light and Mid'));
    expect(paletteContrastWarning([0, 0, 0, 0, 0xffd0d0d0, flat, flat, 0]), contains('Mid and Dark'));
    expect(paletteContrastWarning([0, 0, 0, 0, 0xffa0a0a0, 0xff909090, 0xff808080, 0]), isNotNull);
  });

  test('suggesting shades also works for gray and extreme colors', () {
    for (final base in [0xff808080, 0xff000000, 0xffffffff, 0xffff0000]) {
      final shades = suggestShades(base);
      expect(shades.length, 5);
      for (final c in shades.values) {
        expect(c >> 24, 0xff);
      }
    }
  });
}
