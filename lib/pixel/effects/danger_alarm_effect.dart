part of 'effects.dart';

/// Procedural pixel heartbeat & danger alarm effect for critical low HP states.
///
/// Features a cardiac 'lub-dub' double-pulse rhythm that synchronizes a heavy
/// pulsing crimson edge vignette, desaturating high-tension monochrome shifts,
/// and retro warning scanlines.
class DangerAlarmEffect extends Effect implements UIFieldProvider {
  DangerAlarmEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.dangerAlarm,
          parameters ??
              const {
                'pulseBPM': 120.0,
                'vignetteThickness': 0.45,
                'alarmColor': 0xFFFF1744,
                'monochromeDepth': 0.5,
                'doublePulse': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'pulseBPM': 120.0,
        'vignetteThickness': 0.45,
        'alarmColor': 0xFFFF1744,
        'monochromeDepth': 0.5,
        'doublePulse': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'pulseBPM': {
          'label': 'Heartbeat BPM',
          'description': 'Pounding cardiac beats per minute frequency.',
          'type': 'slider',
          'min': 60.0,
          'max': 200.0,
          'step': 5.0,
        },
        'vignetteThickness': {
          'label': 'Vignette Depth',
          'description': 'Reach of the perimeter pulsing alarm shadow.',
          'type': 'slider',
          'min': 0.1,
          'max': 0.9,
          'step': 0.05,
        },
        'alarmColor': {
          'label': 'Alarm Color',
          'description': 'Flashing warning vignette and strobe color.',
          'type': 'color',
        },
        'monochromeDepth': {
          'label': 'Monochrome Drain',
          'description': 'Color desaturation depth during cardiac peaks.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'doublePulse': {
          'label': 'Lub-Dub Cardiac Pulse',
          'description': 'Simulate realistic anatomical double-beat heart rhythm.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through heartbeat rhythm.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine alarm vignette within character silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'pulseBPM',
          label: 'Heartbeat BPM',
          description: 'Cardiac beats per minute rate.',
          min: 60.0,
          max: 200.0,
          divisions: 28,
          formatLabel: (v) => '${v.round()} BPM',
        ),
        SliderField(
          key: 'vignetteThickness',
          label: 'Vignette Depth',
          description: 'Inward reach of the danger alarm vignette.',
          min: 0.1,
          max: 0.9,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const ColorField(
          key: 'alarmColor',
          label: 'Alarm Color',
          description: 'Color of the pulsing emergency vignette.',
        ),
        SliderField(
          key: 'monochromeDepth',
          label: 'Monochrome Drain',
          description: 'Color desaturation during high-stress peaks.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'doublePulse',
          label: 'Lub-Dub Double Pulse',
          description: 'Authentic anatomical cardiac rhythm.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Heartbeat timeline progress.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict alarm pulse to sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final pulseBPM = (parameters['pulseBPM'] as num?)?.toDouble() ?? 120.0;
    final vignetteThickness = (parameters['vignetteThickness'] as num?)?.toDouble() ?? 0.45;
    final alarmColorInt = (parameters['alarmColor'] as num?)?.toInt() ?? 0xFFFF1744;
    final monochromeDepth = (parameters['monochromeDepth'] as num?)?.toDouble() ?? 0.5;
    final doublePulse = parameters['doublePulse'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final aA = (alarmColorInt >> 24) & 0xFF;
    final aR = (alarmColorInt >> 16) & 0xFF;
    final aG = (alarmColorInt >> 8) & 0xFF;
    final aB = alarmColorInt & 0xFF;

    // Detect subject bounding box
    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = pixels[y * width + x];
        if (((pixel >> 24) & 0xFF) > 10) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      minX = 0;
      minY = 0;
      maxX = width - 1;
      maxY = height - 1;
    }

    final boxW = (maxX - minX + 1).toDouble();
    final boxH = (maxY - minY + 1).toDouble();
    final cx = preserveAlpha ? (minX + boxW / 2.0) : (width / 2.0);
    final cy = preserveAlpha ? (minY + boxH / 2.0) : (height / 2.0);
    final halfRadiusX = (preserveAlpha ? boxW : width.toDouble()) / 2.0;
    final halfRadiusY = (preserveAlpha ? boxH : height.toDouble()) / 2.0;

    // Calculate cardiac pulse intensity ($0.0 \to 1.0$)
    // Frequency scaled to BPM over a standard 1.0 time unit (assuming 1 unit = ~2 seconds)
    final cycles = (pulseBPM / 60.0) * 2.0;
    final cardiacT = (time * cycles) % 1.0;

    double pulseIntensity = 0.0;
    if (doublePulse) {
      // Anatomical "lub-dub" double pulse
      if (cardiacT < 0.22) {
        // Systolic beat 1 ("lub")
        pulseIntensity = math.sin((cardiacT / 0.22) * math.pi);
      } else if (cardiacT >= 0.24 && cardiacT < 0.46) {
        // Diastolic beat 2 ("dub") - slightly softer
        pulseIntensity = math.sin(((cardiacT - 0.24) / 0.22) * math.pi) * 0.72;
      }
    } else {
      // Single emergency strobe pulse
      pulseIntensity = 0.5 + 0.5 * math.sin(cardiacT * math.pi * 2.0);
    }

    final innerVignetteRadius = math.max(0.05, 1.0 - vignetteThickness);
    final currentMonochrome = monochromeDepth * pulseIntensity;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        final oR = (origPixel >> 16) & 0xFF;
        final oG = (origPixel >> 8) & 0xFF;
        final oB = origPixel & 0xFF;

        // 1. Calculate radial vignette distance
        final nx = ((x - cx) / (halfRadiusX + 0.001)).abs();
        final ny = ((y - cy) / (halfRadiusY + 0.001)).abs();
        final dist = math.sqrt(nx * nx + ny * ny);

        double vignetteAlpha = 0.0;
        if (dist > innerVignetteRadius) {
          final t = ((dist - innerVignetteRadius) / (1.2 - innerVignetteRadius)).clamp(0.0, 1.0);
          vignetteAlpha = math.pow(t, 1.5).toDouble() * pulseIntensity * 0.85;
        }

        // 2. Monochrome high-tension desaturation
        int curR = oR;
        int curG = oG;
        int curB = oB;

        if (currentMonochrome > 0.01) {
          final gray = (0.299 * oR + 0.587 * oG + 0.114 * oB).round();
          // High-contrast tension curve on desaturated gray
          final contrastGray = (((gray - 128) * 1.25) + 128).round().clamp(0, 255);
          curR = (oR * (1.0 - currentMonochrome) + contrastGray * currentMonochrome).round().clamp(0, 255);
          curG = (oG * (1.0 - currentMonochrome) + contrastGray * currentMonochrome).round().clamp(0, 255);
          curB = (oB * (1.0 - currentMonochrome) + contrastGray * currentMonochrome).round().clamp(0, 255);
        }

        // 3. Blend emergency alarm vignette
        final finalR = (curR * (1.0 - vignetteAlpha) + aR * vignetteAlpha).round().clamp(0, 255);
        final finalG = (curG * (1.0 - vignetteAlpha) + aG * vignetteAlpha).round().clamp(0, 255);
        final finalB = (curB * (1.0 - vignetteAlpha) + aB * vignetteAlpha).round().clamp(0, 255);

        // 4. Subtle retro warning scanline strobing during peak beat
        int resultR = finalR;
        int resultG = finalG;
        int resultB = finalB;
        if (pulseIntensity > 0.6 && (y % 2 == 0)) {
          final scanMul = 1.0 - (pulseIntensity * 0.15);
          resultR = (resultR * scanMul).round();
          resultG = (resultG * scanMul).round();
          resultB = (resultB * scanMul).round();
        }

        final targetA = (vignetteAlpha * aA).round();
        final newA = preserveAlpha ? origA : math.max(origA, targetA);

        output[idx] = (newA << 24) | (resultR << 16) | (resultG << 8) | resultB;
      }
    }

    return output;
  }
}
