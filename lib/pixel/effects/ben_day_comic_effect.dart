part of 'effects.dart';

/// An effect that procedurally transforms an image into a vintage 1960s
/// silver-age comic book offset print with angled CMYK Ben-Day dot screens,
/// mechanical print plate misregistration, and aged newsprint paper.
class BenDayComicEffect extends Effect {
  BenDayComicEffect([Map<String, dynamic>? params])
      : super(
          EffectType.benDayComic,
          params ??
              {
                'dotPitch': 4.0,
                'misregistrationShift': 1.2,
                'newsprintYellowing': 0.4,
                'cmykDotGain': 0.3,
                'paperInkBleed': 0.25,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'dotPitch': 4.0,
        'misregistrationShift': 1.2,
        'newsprintYellowing': 0.4,
        'cmykDotGain': 0.3,
        'paperInkBleed': 0.25,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'dotPitch': {
          'label': 'Dot Screen Pitch',
          'description': 'Spacing and resolution of the mechanical halftone Ben-Day dots.',
          'type': 'slider',
          'min': 2.0,
          'max': 10.0,
          'step': 0.5,
        },
        'misregistrationShift': {
          'label': 'Plate Misregistration',
          'description': 'Mechanical press plate roller shift creating chromatic misalignment.',
          'type': 'slider',
          'min': 0.0,
          'max': 3.0,
          'step': 0.1,
        },
        'newsprintYellowing': {
          'label': 'Aged Newsprint Pulp',
          'description': 'Oxidation yellowing and fibrous grain of vintage cheap paper stock.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'cmykDotGain': {
          'label': 'Ink Dot Gain',
          'description': 'Radial expansion of ink dots as porous newsprint absorbs liquid ink.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'paperInkBleed': {
          'label': 'Edge Feathering Bleed',
          'description': 'Microscopic capillary ink feathering along dot boundaries.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict Ben-Day dots strictly to the existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'dotPitch',
          label: 'Dot Screen Pitch',
          description: 'Spacing and resolution of the mechanical halftone Ben-Day dots.',
          min: 2.0,
          max: 10.0,
          divisions: 16,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'misregistrationShift',
          label: 'Plate Misregistration',
          description: 'Mechanical press plate roller shift creating chromatic misalignment.',
          min: 0.0,
          max: 3.0,
          divisions: 30,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'newsprintYellowing',
          label: 'Aged Newsprint Pulp',
          description: 'Oxidation yellowing and fibrous grain of vintage cheap paper stock.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'cmykDotGain',
          label: 'Ink Dot Gain',
          description: 'Radial expansion of ink dots as porous newsprint absorbs liquid ink.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'paperInkBleed',
          label: 'Edge Feathering Bleed',
          description: 'Microscopic capillary ink feathering along dot boundaries.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict Ben-Day dots strictly to the existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final double rawPitch = (parameters['dotPitch'] as num?)?.toDouble() ?? 4.0;
    final double pitch = rawPitch.clamp(2.0, 10.0);
    final double rawShift = (parameters['misregistrationShift'] as num?)?.toDouble() ?? 1.2;
    final double shift = rawShift.clamp(0.0, 3.0);
    final double yellowing = ((parameters['newsprintYellowing'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final double dotGain = ((parameters['cmykDotGain'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final double bleed = ((parameters['paperInkBleed'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List(width * height);

    // Precalculate CMYK channels for all pixels
    final Float32List chanC = Float32List(width * height);
    final Float32List chanM = Float32List(width * height);
    final Float32List chanY = Float32List(width * height);
    final Float32List chanK = Float32List(width * height);

    for (int i = 0; i < width * height; i++) {
      final int pixel = pixels[i];
      final double r = ((pixel >> 16) & 0xFF) / 255.0;
      final double g = ((pixel >> 8) & 0xFF) / 255.0;
      final double b = (pixel & 0xFF) / 255.0;

      final double maxVal = math.max(r, math.max(g, b));
      final double k = 1.0 - maxVal;

      if (k >= 0.999) {
        chanC[i] = 0.0;
        chanM[i] = 0.0;
        chanY[i] = 0.0;
        chanK[i] = 1.0;
      } else {
        chanC[i] = ((1.0 - r - k) / (1.0 - k)).clamp(0.0, 1.0);
        chanM[i] = ((1.0 - g - k) / (1.0 - k)).clamp(0.0, 1.0);
        chanY[i] = ((1.0 - b - k) / (1.0 - k)).clamp(0.0, 1.0);
        chanK[i] = k.clamp(0.0, 1.0);
      }
    }

    // Authentic Silver-Age Optical Screen Angles
    // Cyan: 15°, Magenta: 75°, Yellow: 0°, Key/Black: 45°
    const double angC = 15.0 * (math.pi / 180.0);
    const double angM = 75.0 * (math.pi / 180.0);
    const double angK = 45.0 * (math.pi / 180.0);

    final double cosC = math.cos(angC), sinC = math.sin(angC);
    final double cosM = math.cos(angM), sinM = math.sin(angM);
    const double cosY = 1.0, sinY = 0.0;
    final double cosK = math.cos(angK), sinK = math.sin(angK);

    // Mechanical plate misregistration offsets
    final double offCx = -shift * 0.7;
    final double offCy = shift * 0.5;
    final double offMx = shift * 0.6;
    final double offMy = shift * 0.6;
    final double offYx = shift * 0.3;
    final double offYy = -shift * 0.8;
    const double offKx = 0.0;
    const double offKy = 0.0;

    // Newsprint base paper color: warm cream oxidized pulp
    final double paperBaseR = 248.0 - yellowing * 22.0;
    final double paperBaseG = 242.0 - yellowing * 30.0;
    final double paperBaseB = 222.0 - yellowing * 62.0;

    final double maxRadius = pitch * 0.7071; // Half diagonal of pitch cell

    for (int y = 0; y < height; y++) {
      final int rowOffset = y * width;

      for (int x = 0; x < width; x++) {
        final int idx = rowOffset + x;
        final int origPixel = pixels[idx];
        final int origAlpha = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origAlpha == 0) {
          result[idx] = 0;
          continue;
        }

        // Subtractive CMYK dot coverage calculations
        final double dotC = _evaluateChannelDot(
          x + offCx,
          y + offCy,
          cosC,
          sinC,
          pitch,
          maxRadius,
          dotGain,
          bleed,
          chanC,
          width,
          height,
        );

        final double dotM = _evaluateChannelDot(
          x + offMx,
          y + offMy,
          cosM,
          sinM,
          pitch,
          maxRadius,
          dotGain,
          bleed,
          chanM,
          width,
          height,
        );

        final double dotY = _evaluateChannelDot(
          x + offYx,
          y + offYy,
          cosY,
          sinY,
          pitch,
          maxRadius,
          dotGain,
          bleed,
          chanY,
          width,
          height,
        );

        final double dotK = _evaluateChannelDot(
          x + offKx,
          y + offKy,
          cosK,
          sinK,
          pitch,
          maxRadius,
          dotGain,
          bleed,
          chanK,
          width,
          height,
        );

        // Newsprint paper fiber tooth noise
        final double paperGrain = (_grainNoise(x, y) - 0.5) * 14.0 * yellowing;
        final double curPaperR = (paperBaseR + paperGrain).clamp(0.0, 255.0);
        final double curPaperG = (paperBaseG + paperGrain).clamp(0.0, 255.0);
        final double curPaperB = (paperBaseB + paperGrain).clamp(0.0, 255.0);

        // Subtractive ink synthesis:
        // Pure Cyan absorbs Red: (1 - dotC)
        // Pure Magenta absorbs Green: (1 - dotM)
        // Pure Yellow absorbs Blue: (1 - dotY)
        // Key absorbs all: (1 - dotK)
        final double outR = curPaperR * (1.0 - dotC) * (1.0 - dotK * 0.95);
        final double outG = curPaperG * (1.0 - dotM) * (1.0 - dotK * 0.95);
        final double outB = curPaperB * (1.0 - dotY) * (1.0 - dotK * 0.95);

        final int finalR = outR.round().clamp(0, 255);
        final int finalG = outG.round().clamp(0, 255);
        final int finalB = outB.round().clamp(0, 255);
        final int outAlpha = preserveAlpha ? origAlpha : 255;

        result[idx] = (outAlpha << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return result;
  }

  static double _evaluateChannelDot(
    double px,
    double py,
    double cosA,
    double sinA,
    double pitch,
    double maxRadius,
    double dotGain,
    double bleed,
    Float32List channel,
    int width,
    int height,
  ) {
    // Rotate plate coordinates to screen angle
    final double u = px * cosA + py * sinA;
    final double v = -px * sinA + py * cosA;

    // Nearest dot center in rotated screen grid
    final double cellU = (u / pitch).round() * pitch;
    final double cellV = (v / pitch).round() * pitch;

    // Map dot center back to image space to sample ink density
    final double origCx = cellU * cosA - cellV * sinA;
    final double origCy = cellU * sinA + cellV * cosA;

    final int sx = origCx.round().clamp(0, width - 1);
    final int sy = origCy.round().clamp(0, height - 1);
    final double inkVal = channel[sy * width + sx];

    if (inkVal <= 0.005) return 0.0;

    // Dot gain expansion
    final double effectiveVal = (inkVal * (1.0 + dotGain * 0.4)).clamp(0.0, 1.0);

    // Target dot radius
    final double dotRadius = (pitch * 0.52) * math.sqrt(effectiveVal);

    // Distance from current pixel to dot center
    final double du = u - cellU;
    final double dv = v - cellV;
    final double dist = math.sqrt(du * du + dv * dv);

    // Edge feathering & ink bleed
    final double feather = 0.5 + bleed * 0.8;
    if (dist <= dotRadius - feather) {
      return 1.0;
    } else if (dist >= dotRadius + feather) {
      return 0.0;
    } else {
      return (1.0 - (dist - (dotRadius - feather)) / (2.0 * feather)).clamp(0.0, 1.0);
    }
  }

  static double _grainNoise(int x, int y) {
    int h = (x * 374761393 + y * 668265263) ^ 0x4f4f4f4f;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h & 0x7FFFFFFF) / 2147483647.0);
  }
}
