import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';

/// Neighbouring tiles must agree on the pixels they share, for all 4,096 local
/// neighbourhoods, both directions, using different variations on either side.
void expectSeamless(TilesetSettings s, String label) {
  final tiles = {for (final t in generateTileset(s)) t.id: t};
  for (var bits = 0; bits < 4096; bits++) {
    final h = List.generate(12, (i) => (bits >> i) & 1)
      ..[5] = 1
      ..[6] = 1;
    final v = List.generate(12, (i) => (bits >> i) & 1)
      ..[4] = 1
      ..[7] = 1;
    final left = tileMaskAt(h, 4, 3, 1, 1), right = tileMaskAt(h, 4, 3, 2, 1);
    final top = tileMaskAt(v, 3, 4, 1, 1), bottom = tileMaskAt(v, 3, 4, 1, 2);
    final a = tiles['$left:0']!.pixels, b = tiles['$right:1']!.pixels;
    final c = tiles['$top:1']!.pixels, d = tiles['$bottom:0']!.pixels;
    for (var i = 0; i < s.size; i++) {
      if (a[i * s.size + s.size - 1] != b[i * s.size]) fail('$label: horizontal seam $left|$right row $i');
      if (c[(s.size - 1) * s.size + i] != d[i]) fail('$label: vertical seam $top/$bottom column $i');
    }
  }
}
