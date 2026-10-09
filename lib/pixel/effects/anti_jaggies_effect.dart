part of 'effects.dart';

/// Cleans up pixel-art lines: removes stray single pixels, fills one-pixel
/// holes, and thins "doubled" staircase corners so one-pixel lines stay
/// one pixel wide ("pixel-perfect" lines).
class AntiJaggiesEffect extends Effect with UIFieldProvider {
  AntiJaggiesEffect([Map<String, dynamic>? params])
      : super(
          EffectType.antiJaggies,
          params ?? _defaults,
        );

  static const Map<String, dynamic> _defaults = {
    'removeOrphans': true,
    'orphanMaxNeighbors': 0,
    'fillPinholes': true,
    'pixelPerfect': true,
    'passes': 1,
    'alphaThreshold': 0,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map<String, dynamic>.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'removeOrphans': {
        'label': 'Remove Stray Pixels',
        'description': 'Delete pixels that have few or no neighbours.',
        'type': 'bool',
      },
      'orphanMaxNeighbors': {
        'label': 'Stray Pixel Neighbours',
        'description': 'A pixel with this many neighbours or fewer (out of 8) counts as stray.',
        'type': 'slider',
        'min': 0,
        'max': 2,
        'divisions': 2,
      },
      'fillPinholes': {
        'label': 'Fill Pinholes',
        'description': 'Fill transparent pixels completely surrounded by the sprite.',
        'type': 'bool',
      },
      'pixelPerfect': {
        'label': 'Pixel-Perfect Lines',
        'description': 'Remove the redundant corner pixel in one-pixel staircase lines.',
        'type': 'bool',
      },
      'passes': {
        'label': 'Passes',
        'description': 'Repeat the cleanup this many times.',
        'type': 'slider',
        'min': 1,
        'max': 3,
        'divisions': 2,
      },
      'alphaThreshold': {
        'label': 'Transparency Threshold',
        'description': 'Pixels with alpha at or below this value count as transparent.',
        'type': 'slider',
        'min': 0,
        'max': 128,
        'divisions': 32,
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const BoolField(
          key: 'removeOrphans',
          label: 'Remove Stray Pixels',
          description: 'Delete pixels that have few or no neighbours.',
        ),
        const SliderField(
          key: 'orphanMaxNeighbors',
          label: 'Stray Pixel Neighbours',
          description: 'A pixel with this many neighbours or fewer (out of 8) counts as stray.',
          min: 0,
          max: 2,
          divisions: 2,
          isInteger: true,
        ),
        const BoolField(
          key: 'fillPinholes',
          label: 'Fill Pinholes',
          description: 'Fill transparent pixels completely surrounded by the sprite.',
        ),
        const BoolField(
          key: 'pixelPerfect',
          label: 'Pixel-Perfect Lines',
          description: 'Remove the redundant corner pixel in one-pixel staircase lines.',
        ),
        const SliderField(
          key: 'passes',
          label: 'Passes',
          description: 'Repeat the cleanup this many times.',
          min: 1,
          max: 3,
          divisions: 2,
          isInteger: true,
        ),
        const SliderField(
          key: 'alphaThreshold',
          label: 'Transparency Threshold',
          description: 'Pixels with alpha at or below this value count as transparent.',
          min: 0,
          max: 128,
          divisions: 32,
          isInteger: true,
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.length != width * height) return pixels;

    final p = parameters;
    final removeOrphans = p['removeOrphans'] as bool? ?? true;
    final orphanMax = ((p['orphanMaxNeighbors'] as num?)?.toInt() ?? 0).clamp(0, 2);
    final fillPinholes = p['fillPinholes'] as bool? ?? true;
    final pixelPerfect = p['pixelPerfect'] as bool? ?? true;
    final passes = ((p['passes'] as num?)?.toInt() ?? 1).clamp(1, 3);
    final threshold = ((p['alphaThreshold'] as num?)?.toInt() ?? 0).clamp(0, 128);

    var current = Uint32List.fromList(pixels);
    for (var pass = 0; pass < passes; pass++) {
      final before = current;
      final next = Uint32List.fromList(current);

      bool solidIn(Uint32List buf, int x, int y) =>
          x >= 0 && y >= 0 && x < width && y < height && ((buf[y * width + x] >> 24) & 0xFF) > threshold;
      bool solid(int x, int y) => solidIn(before, x, y);
      // Corner removal reads the evolving buffer so two neighbouring corners
      // are never removed together (which would break the line).
      bool live(int x, int y) => solidIn(next, x, y);

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          if (solid(x, y)) {
            if (removeOrphans && _neighbourCount(solid, x, y) <= orphanMax) {
              next[i] = 0;
              continue;
            }
            if (pixelPerfect && live(x, y) && _isRedundantCorner(live, x, y)) {
              next[i] = 0;
            }
          } else if (fillPinholes) {
            final fill = _pinholeColor(before, solid, width, x, y);
            if (fill != null) next[i] = fill;
          }
        }
      }

      if (listEquals(next, current)) break;
      current = next;
    }
    return current;
  }

  static int _neighbourCount(bool Function(int, int) solid, int x, int y) {
    var count = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if ((dx != 0 || dy != 0) && solid(x + dx, y + dy)) count++;
      }
    }
    return count;
  }

  /// The corner pixel of a one-pixel staircase: exactly two orthogonal
  /// neighbours at a right angle whose 2x2 block is otherwise empty (so it is
  /// an L, not the corner of a filled shape). Its two neighbours already touch
  /// diagonally, so removing it keeps the line connected.
  static bool _isRedundantCorner(bool Function(int, int) solid, int x, int y) {
    final up = solid(x, y - 1);
    final down = solid(x, y + 1);
    final left = solid(x - 1, y);
    final right = solid(x + 1, y);
    if ((up && down) || (left && right)) return false;
    if (!(up || down) || !(left || right)) return false;

    final vy = up ? -1 : 1;
    final hx = left ? -1 : 1;
    if (solid(x + hx, y + vy)) return false; // filled corner

    // Any other neighbour must hang off one of the two line neighbours, or
    // removing this pixel could disconnect it.
    final a = (x + hx, y);
    final c = (x, y + vy);
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if ((nx, ny) == a || (nx, ny) == c) continue;
        if (!solid(nx, ny)) continue;
        final touchesA = (nx - a.$1).abs() + (ny - a.$2).abs() == 1;
        final touchesC = (nx - c.$1).abs() + (ny - c.$2).abs() == 1;
        if (!touchesA && !touchesC) return false;
      }
    }
    return true;
  }

  /// Colour for a transparent pixel with all four orthogonal neighbours
  /// solid, or null. Uses the most common of those colours.
  static int? _pinholeColor(
    Uint32List before,
    bool Function(int, int) solid,
    int width,
    int x,
    int y,
  ) {
    if (!(solid(x - 1, y) && solid(x + 1, y) && solid(x, y - 1) && solid(x, y + 1))) {
      return null;
    }
    final colors = [
      before[y * width + x - 1],
      before[y * width + x + 1],
      before[(y - 1) * width + x],
      before[(y + 1) * width + x],
    ];
    final counts = <int, int>{};
    for (final c in colors) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
