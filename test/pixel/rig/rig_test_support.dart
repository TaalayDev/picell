import 'dart:typed_data';

/// Pixel grids as ASCII art so expectations read like the sprite: `.` is
/// transparent, any other character is a distinct colour.
const _palette = <String, int>{
  'R': 0xFFFF0000,
  'G': 0xFF00FF00,
  'B': 0xFF0000FF,
  'Y': 0xFFFFFF00,
  'W': 0xFFFFFFFF,
};

Uint32List parseGrid(List<String> rows) {
  final width = rows.first.length;
  final out = Uint32List(width * rows.length);
  for (var y = 0; y < rows.length; y++) {
    assert(rows[y].length == width, 'ragged row $y');
    for (var x = 0; x < width; x++) {
      final ch = rows[y][x];
      out[y * width + x] = ch == '.' ? 0 : _palette[ch]!;
    }
  }
  return out;
}

List<String> renderGrid(Uint32List pixels, int width) {
  final reverse = {for (final e in _palette.entries) e.value: e.key};
  return [
    for (var y = 0; y < pixels.length ~/ width; y++)
      [
        for (var x = 0; x < width; x++)
          pixels[y * width + x] == 0 ? '.' : (reverse[pixels[y * width + x]] ?? '?'),
      ].join(),
  ];
}
