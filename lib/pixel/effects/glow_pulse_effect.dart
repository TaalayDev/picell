part of 'effects.dart';

/// Seamless alpha-aware halo drawn behind the original sprite.
class GlowPulseEffect extends Effect {
  GlowPulseEffect([Map<String, dynamic>? params])
      : super(EffectType.glowPulse, {..._defaults, ...?params});

  static const _defaults = <String, dynamic>{
    'frames': 16,
    'radius': 4,
    'intensity': 0.8,
    'minimum': 0.1,
    'color': 0xFFFFD54F,
    'cycles': 1,
    'phase': 0.0,
    'time': 0.0,
  };

  double _value(String key) => (parameters[key] as num).toDouble();

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  int? get preferredFrameCount => _value('frames').round().clamp(2, 48);

  @override
  bool get isSeamlessLoop => true;

  @override
  Map<String, dynamic> getMetadata() => {
        'frames':
            _slider('Frame Count', 'Frames in one seamless loop.', 2, 48, 46),
        'radius': _slider('Glow Radius',
            'Halo reach in pixels. Leave room around the sprite.', 1, 24, 23),
        'intensity': _slider('Peak Intensity',
            'Glow opacity at the brightest point.', 0.0, 1.0, 100),
        'minimum': _slider('Minimum Glow',
            'Fraction of peak brightness between pulses.', 0.0, 1.0, 100),
        'color': {
          'label': 'Glow Color',
          'type': 'color',
          'description': 'Color of the halo.'
        },
        'cycles': _slider(
            'Pulses per Loop', 'Number of pulses in the animation.', 1, 4, 3),
        'phase': _slider('Cycle Phase', 'Starting position in the pulse cycle.',
            0.0, 1.0, 100),
        'time': _slider('Animation Time', 'Timeline progress.', 0.0, 1.0, 100),
      };

  static Map<String, dynamic> _slider(
          String label, String description, num min, num max, int divisions) =>
      {
        'label': label,
        'description': description,
        'type': 'slider',
        'min': min,
        'max': max,
        'divisions': divisions
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.length != width * height)
      return pixels;
    final result = Uint32List.fromList(pixels);
    final frames = preferredFrameCount!;
    final frame =
        (_value('time').clamp(0.0, 1.0) * frames + 1e-6).floor() % frames;
    final cycle = (frame / frames * _value('cycles').round().clamp(1, 4) +
            _value('phase')) %
        1.0;
    final pulse = 0.5 - 0.5 * math.cos(2 * math.pi * cycle);
    final minimum = _value('minimum').clamp(0.0, 1.0);
    final color = (parameters['color'] as num).toInt();
    final opacity = _value('intensity').clamp(0.0, 1.0) *
        (minimum + (1 - minimum) * pulse) *
        ((color >>> 24) / 255);
    if (opacity == 0) return result;
    final radius = _value('radius').round().clamp(1, 24);
    final sigma = radius / 2.0;
    final weights = List<double>.generate(
        radius + 1, (d) => math.exp(-d * d / (2 * sigma * sigma)));
    final horizontal = Float64List(pixels.length);
    // Separable maximum of Gaussian-weighted alpha: symmetric around contours,
    // without accumulating brightness where multiple opaque pixels overlap.
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double value = 0;
        for (int dx = -radius; dx <= radius; dx++) {
          final sx = x + dx;
          if (sx < 0 || sx >= width) continue;
          value = math.max(
              value, (pixels[y * width + sx] >>> 24) / 255 * weights[dx.abs()]);
        }
        horizontal[y * width + x] = value;
      }
    }
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = y * width + x;
        final source = pixels[i];
        final alpha = (source >>> 24) / 255;
        if (alpha == 1) continue; // Keep opaque sprite pixels exactly intact.
        double halo = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          final sy = y + dy;
          if (sy < 0 || sy >= height) continue;
          halo = math.max(halo, horizontal[sy * width + x] * weights[dy.abs()]);
        }
        final behind = halo * opacity * (1 - alpha);
        final outAlpha = alpha + behind;
        if (outAlpha == 0) continue;
        int channel(int shift) => ((((source >>> shift) & 255) * alpha +
                    ((color >>> shift) & 255) * behind) /
                outAlpha)
            .round()
            .clamp(0, 255);
        result[i] = ((outAlpha * 255).round().clamp(0, 255) << 24) |
            (channel(16) << 16) |
            (channel(8) << 8) |
            channel(0);
      }
    }
    return result;
  }
}
