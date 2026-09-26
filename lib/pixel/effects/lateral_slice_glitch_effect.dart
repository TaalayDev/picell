part of 'effects.dart';

/// An effect that shears sprite pixels into stepped horizontal or angled slices
/// with alternating lateral displacements, chromatic RGB channel misregistration,
/// and digital fault dropout noise.
class LateralSliceGlitchEffect extends Effect {
  LateralSliceGlitchEffect([Map<String, dynamic>? params])
      : super(
          EffectType.lateralSliceGlitch,
          params ??
              {
                'sliceCount': 12.0,
                'maxShift': 5.0,
                'shiftProbability': 0.65,
                'sliceAngle': 0.0,
                'chromaticSplit': 1.8,
                'faultNoise': 0.35,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'sliceCount': 12.0,
        'maxShift': 5.0,
        'shiftProbability': 0.65,
        'sliceAngle': 0.0,
        'chromaticSplit': 1.8,
        'faultNoise': 0.35,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'sliceCount': {
          'label': 'Slice Count',
          'description': 'Number of horizontal fractured strata bands.',
          'type': 'slider',
          'min': 4.0,
          'max': 36.0,
          'step': 2.0,
        },
        'maxShift': {
          'label': 'Lateral Shift',
          'description': 'Maximum displacement distance of fractured slices.',
          'type': 'slider',
          'min': 0.0,
          'max': 20.0,
          'step': 0.5,
        },
        'shiftProbability': {
          'label': 'Shift Probability',
          'description': 'Frequency of displaced slices versus aligned intact slices.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'sliceAngle': {
          'label': 'Slice Tilt Angle',
          'description': 'Angle of the slicing shear plane in degrees.',
          'type': 'slider',
          'min': -30.0,
          'max': 30.0,
          'step': 2.5,
        },
        'chromaticSplit': {
          'label': 'Chromatic Aberration',
          'description': 'Sub-pixel horizontal separation of Red and Blue channels.',
          'type': 'slider',
          'min': 0.0,
          'max': 5.0,
          'step': 0.2,
        },
        'faultNoise': {
          'label': 'Fault Line Dropout',
          'description': 'Scanline shadow and digital dropout noise along slice boundaries.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine slice glitch strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'sliceCount',
          label: 'Slice Count',
          description: 'Number of horizontal fractured strata bands.',
          min: 4.0,
          max: 36.0,
          divisions: 16,
          formatLabel: (v) => '${v.round()}',
        ),
        SliderField(
          key: 'maxShift',
          label: 'Lateral Shift',
          description: 'Maximum displacement distance of fractured slices.',
          min: 0.0,
          max: 20.0,
          divisions: 40,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'shiftProbability',
          label: 'Shift Probability',
          description: 'Frequency of displaced slices versus aligned intact slices.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'sliceAngle',
          label: 'Slice Tilt Angle',
          description: 'Angle of the slicing shear plane.',
          min: -30.0,
          max: 30.0,
          divisions: 24,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'chromaticSplit',
          label: 'Chromatic Aberration',
          description: 'Sub-pixel horizontal separation of Red and Blue channels.',
          min: 0.0,
          max: 5.0,
          divisions: 25,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'faultNoise',
          label: 'Fault Line Dropout',
          description: 'Scanline shadow and digital dropout noise along slice boundaries.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine slice glitch strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final int numSlices = ((parameters['sliceCount'] as num?)?.toDouble() ?? 12.0).round().clamp(3, 48);
    final double maxDisplacement = ((parameters['maxShift'] as num?)?.toDouble() ?? 5.0).clamp(0.0, 40.0);
    final double prob = ((parameters['shiftProbability'] as num?)?.toDouble() ?? 0.65).clamp(0.05, 1.0);
    final double angleDeg = ((parameters['sliceAngle'] as num?)?.toDouble() ?? 0.0).clamp(-45.0, 45.0);
    final double split = ((parameters['chromaticSplit'] as num?)?.toDouble() ?? 1.8).clamp(0.0, 10.0);
    final double fault = ((parameters['faultNoise'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final double angleRad = angleDeg * (math.pi / 180.0);
    final double cosA = math.cos(angleRad);
    final double sinA = math.sin(angleRad);

    final double sliceThickness = height / numSlices;

    // Precompute random shifts for each slice band
    final sliceShifts = Float64List(numSlices + 4);
    for (int s = 0; s < sliceShifts.length; s++) {
      final double hProb = _hash(s * 73 + 19);
      if (hProb <= prob) {
        final double hDist = (_hash(s * 137 + 53) - 0.5) * 2.0;
        sliceShifts[s] = hDist * maxDisplacement;
      } else {
        sliceShifts[s] = 0.0;
      }
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;

        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        // Projected axis along the slice normal
        final double projected = (y - height * 0.5) * cosA + (x - width * 0.5) * sinA + height * 0.5;
        final int sliceIdx = (projected / sliceThickness).floor().clamp(0, numSlices + 2);
        final double distToSliceFault = (projected - sliceIdx * sliceThickness).abs();

        final double dx = sliceShifts[sliceIdx];

        // Inverse mapping to find source pixel on active layer
        final double srcX = x - dx;
        final double srcY = y.toDouble();

        final int sampleX = srcX.round();
        final int sampleY = srcY.round();

        // Sample center pixel
        int centerA = 0;
        int centerR = 0;
        int centerG = 0;
        int centerB = 0;

        if (sampleX >= 0 && sampleX < width && sampleY >= 0 && sampleY < height) {
          final int p = pixels[sampleY * width + sampleX];
          centerA = (p >> 24) & 0xFF;
          centerR = (p >> 16) & 0xFF;
          centerG = (p >> 8) & 0xFF;
          centerB = p & 0xFF;
        }

        // Chromatic split sampling
        int finalR = centerR;
        int finalG = centerG;
        int finalB = centerB;
        int finalA = centerA;

        if (split > 0.1) {
          final int redX = (srcX + split).round();
          if (redX >= 0 && redX < width && sampleY >= 0 && sampleY < height) {
            final int pR = pixels[sampleY * width + redX];
            final int aR = (pR >> 24) & 0xFF;
            if (aR > 0) {
              finalR = (pR >> 16) & 0xFF;
              finalA = math.max(finalA, aR);
            }
          }

          final int blueX = (srcX - split).round();
          if (blueX >= 0 && blueX < width && sampleY >= 0 && sampleY < height) {
            final int pB = pixels[sampleY * width + blueX];
            final int aB = (pB >> 24) & 0xFF;
            if (aB > 0) {
              finalB = pB & 0xFF;
              finalA = math.max(finalA, aB);
            }
          }
        }

        if (finalA == 0) {
          output[idx] = 0;
          continue;
        }

        // Digital scanline dropout and fault shadow near boundaries
        if (fault > 0.05 && distToSliceFault < 1.4) {
          final double faultT = 1.0 - (distToSliceFault / 1.4);
          final double faultDarken = (1.0 - faultT * fault * 0.45).clamp(0.2, 1.0);
          finalR = (finalR * faultDarken).round();
          finalG = (finalG * faultDarken).round();
          finalB = (finalB * faultDarken).round();
        }

        output[idx] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return output;
  }

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return x / 2147483647.0;
  }
}
