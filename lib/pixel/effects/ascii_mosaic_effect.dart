part of 'effects.dart';

/// Replaces image cells with luminance-selected bitmap glyphs.
class AsciiMosaicEffect extends Effect {
  AsciiMosaicEffect([Map<String, dynamic>? params])
      : super(
            EffectType.asciiMosaic,
            params ??
                const {
                  'cellSize': 7,
                  'charset': 0,
                  'invert': false,
                  'colorize': true,
                  'foregroundColor': 0xFFB9F6CA,
                  'backgroundColor': 0xFF102018,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'cellSize': 7,
        'charset': 0,
        'invert': false,
        'colorize': true,
        'foregroundColor': 0xFFB9F6CA,
        'backgroundColor': 0xFF102018,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'cellSize': {
          'label': 'Character Size',
          'type': 'slider',
          'min': 5,
          'max': 20,
          'divisions': 15
        },
        'charset': {
          'label': 'Character Set',
          'type': 'select',
          'options': {0: 'Classic ASCII', 1: 'Blocks', 2: 'Binary'}
        },
        'invert': {'label': 'Invert Density', 'type': 'bool'},
        'colorize': {'label': 'Use Source Colors', 'type': 'bool'},
        'foregroundColor': {'label': 'Glyph Color', 'type': 'color'},
        'backgroundColor': {'label': 'Background Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  static const _classic = <List<String>>[
    ['00000', '00000', '00000', '00000', '00000', '00000', '00000'],
    ['00000', '00000', '00100', '00000', '00100', '00000', '00000'],
    ['00000', '00000', '00000', '11111', '00000', '00000', '00000'],
    ['00100', '00100', '11111', '00100', '00100', '00000', '00000'],
    ['10101', '01110', '11111', '01110', '10101', '00000', '00000'],
    ['11011', '11111', '01110', '11111', '11011', '00000', '00000'],
    ['11111', '11111', '11111', '11111', '11111', '11111', '11111'],
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final cell = ((parameters['cellSize'] as num?)?.toInt() ?? 7).clamp(5, 20);
    final charset = ((parameters['charset'] as num?)?.toInt() ?? 0).clamp(0, 2);
    final invert = parameters['invert'] as bool? ?? false;
    final colorize = parameters['colorize'] as bool? ?? true;
    final foreground = parameters['foregroundColor'] as int? ?? 0xFFB9F6CA;
    final background = parameters['backgroundColor'] as int? ?? 0xFF102018;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List(width * height);
    for (var cellY = 0; cellY < height; cellY += cell) {
      for (var cellX = 0; cellX < width; cellX += cell) {
        var lum = 0.0, red = 0.0, green = 0.0, blue = 0.0, count = 0;
        for (var y = cellY; y < math.min(cellY + cell, height); y++) {
          for (var x = cellX; x < math.min(cellX + cell, width); x++) {
            final p = pixels[y * width + x];
            if (((p >> 24) & 0xff) == 0) continue;
            lum += _textureLuminance(p);
            red += _textureChannel(p, 16);
            green += _textureChannel(p, 8);
            blue += _textureChannel(p, 0);
            count++;
          }
        }
        if (count == 0) continue;
        var density = (lum / count).clamp(0.0, 1.0);
        if (invert) density = 1.0 - density;
        final glyphIndex = (density * (_classic.length - 1))
            .round()
            .clamp(0, _classic.length - 1);
        final glyph = _classic[glyphIndex];
        final sampled = 0xFF000000 |
            ((red / count).round() << 16) |
            ((green / count).round() << 8) |
            (blue / count).round();
        final glyphColor = colorize ? sampled : foreground;
        for (var y = cellY; y < math.min(cellY + cell, height); y++) {
          for (var x = cellX; x < math.min(cellX + cell, width); x++) {
            final i = y * width + x;
            final alpha = (pixels[i] >> 24) & 0xff;
            if (preserveAlpha && alpha == 0) continue;
            final gx = ((x - cellX) * 5 ~/ cell).clamp(0, 4);
            final gy = ((y - cellY) * 7 ~/ cell).clamp(0, 6);
            var mark = glyph[gy].codeUnitAt(gx) == 49;
            if (charset == 1) {
              mark = density > ((x - cellX + y - cellY) / (cell * 2));
            }
            if (charset == 2) {
              mark = ((glyphIndex + cellX ~/ cell + cellY ~/ cell) & 1) ==
                  ((x - cellX) < cell ~/ 2 ? 0 : 1);
            }
            result[i] = ((preserveAlpha ? alpha : 255) << 24) |
                ((mark ? glyphColor : background) & 0x00ffffff);
          }
        }
      }
    }
    return result;
  }
}
