part of 'effects.dart';

/// Smart, sprite-aware idle breathing animation.
///
/// Unlike a plain scale, the breathing is built the way pixel artists animate
/// idle loops by hand:
///
/// * The opaque bounds of the sprite are detected automatically, so the anchor
///   is relative to the character, not the canvas.
/// * A *planted* region next to the anchor (legs / feet) never moves.
/// * A *body* band (torso) stretches to absorb the breath.
/// * A *rigid* region at the far end (head) is only shifted, never distorted,
///   so faces and eyes keep their exact pixels.
/// * Optional chest expansion widens the torso symmetrically around each
///   row's own centre.
/// * Offsets are snapped to whole pixels and the cycle is quantized to the
///   configured frame count, so every generated frame is a clean pixel pose.
class BreathingEffect extends Effect with UIFieldProvider {
  BreathingEffect([Map<String, dynamic>? params])
      : super(EffectType.breathing, params ?? _defaults);

  static const Map<String, dynamic> _defaults = {
    'frames': 8,
    'style': 'chest',
    'anchor': 'bottom',
    'anchorPosition': 0.5,
    'depth': 0,
    'plantedRatio': 0.35,
    'rigidRatio': 0.3,
    'chestExpand': 0,
    'easing': 'organic',
    'hold': 0.15,
    'cycles': 1,
    'phase': 0.0,
    'pixelSnap': true,
    'time': 0.0,
  };

  static const Map<String, String> _styleOptions = {
    'chest': 'Chest (body stretches, head stays rigid)',
    'bob': 'Bob (upper body shifts as a block)',
    'scale': 'Scale (whole sprite stretches from anchor)',
  };

  static const Map<String, String> _anchorOptions = {
    'bottom': 'Bottom (standing / feet planted)',
    'top': 'Top (hanging / ceiling)',
    'center': 'Center (flying / floating)',
    'custom': 'Custom position',
  };

  static const Map<String, String> _easingOptions = {
    'organic': 'Organic (quick inhale, slow exhale)',
    'smooth': 'Smooth (sine)',
    'step': 'Two-pose (classic in / out)',
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  int? get preferredFrameCount => _intParam('frames', 8, 2, 24);

  @override
  bool get isSeamlessLoop => true;

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'frames': {
        'label': 'Frame Count',
        'description': 'Number of poses in one breathing loop.',
        'type': 'slider',
        'min': 2,
        'max': 24,
        'divisions': 22,
      },
      'style': {
        'label': 'Breathing Style',
        'description': 'How the body deforms while breathing.',
        'type': 'select',
        'options': _styleOptions,
      },
      'anchor': {
        'label': 'Anchor',
        'description': 'Fixed side of the sprite that never moves.',
        'type': 'select',
        'options': _anchorOptions,
      },
      'anchorPosition': {
        'label': 'Custom Anchor Position',
        'description': 'Anchor line from sprite top (0) to bottom (1).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'depth': {
        'label': 'Breath Depth (px)',
        'description': '0 = auto, based on the sprite height.',
        'type': 'slider',
        'min': 0,
        'max': 8,
        'divisions': 8,
      },
      'plantedRatio': {
        'label': 'Planted Region',
        'description': 'Part of the sprite next to the anchor that stays still.',
        'type': 'slider',
        'min': 0.0,
        'max': 0.8,
        'divisions': 80,
      },
      'rigidRatio': {
        'label': 'Rigid Head Region',
        'description': 'Far end of the sprite that moves without distortion.',
        'type': 'slider',
        'min': 0.0,
        'max': 0.6,
        'divisions': 60,
      },
      'chestExpand': {
        'label': 'Chest Expansion (px)',
        'description': 'Extra horizontal widening of the torso on inhale.',
        'type': 'slider',
        'min': 0,
        'max': 3,
        'divisions': 3,
      },
      'easing': {
        'label': 'Breath Rhythm',
        'description': 'Timing curve of inhale and exhale.',
        'type': 'select',
        'options': _easingOptions,
      },
      'hold': {
        'label': 'Rest Pause',
        'description': 'Portion of the loop spent fully exhaled.',
        'type': 'slider',
        'min': 0.0,
        'max': 0.5,
        'divisions': 50,
      },
      'cycles': {
        'label': 'Breaths per Loop',
        'description': 'How many breaths happen within the frame count.',
        'type': 'slider',
        'min': 1,
        'max': 4,
        'divisions': 3,
      },
      'phase': {
        'label': 'Cycle Phase',
        'description': 'Starting offset within the breathing cycle.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'pixelSnap': {
        'label': 'Pixel Snap',
        'description': 'Snap offsets to whole pixels for crisp pixel art.',
        'type': 'bool',
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Timeline progress (0 to 1) updated during frame generation.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SliderField(
          key: 'frames',
          label: 'Frame Count',
          description: 'Number of poses in one breathing loop.',
          min: 2,
          max: 24,
          divisions: 22,
          isInteger: true,
        ),
        const SelectField(
          key: 'style',
          label: 'Breathing Style',
          description: 'How the body deforms while breathing.',
          options: _styleOptions,
        ),
        const SelectField(
          key: 'anchor',
          label: 'Anchor',
          description: 'Fixed side of the sprite that never moves.',
          options: _anchorOptions,
        ),
        SliderField(
          key: 'anchorPosition',
          label: 'Custom Anchor Position',
          description: 'Used when Anchor is "Custom": sprite top (0) to bottom (1).',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'depth',
          label: 'Breath Depth',
          description: 'Maximum rise in pixels. 0 = auto from sprite height.',
          min: 0,
          max: 8,
          divisions: 8,
          isInteger: true,
          formatLabel: (v) => v.round() == 0 ? 'Auto' : '${v.round()} px',
        ),
        SliderField(
          key: 'plantedRatio',
          label: 'Planted Region',
          description: 'Part of the sprite next to the anchor that stays still (legs).',
          min: 0.0,
          max: 0.8,
          divisions: 80,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'rigidRatio',
          label: 'Rigid Head Region',
          description: 'Far end of the sprite that moves without distortion (head).',
          min: 0.0,
          max: 0.6,
          divisions: 60,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'chestExpand',
          label: 'Chest Expansion',
          description: 'Extra horizontal widening of the torso on inhale.',
          min: 0,
          max: 3,
          divisions: 3,
          isInteger: true,
          formatLabel: (v) => '${v.round()} px',
        ),
        const SelectField(
          key: 'easing',
          label: 'Breath Rhythm',
          description: 'Timing curve of inhale and exhale.',
          options: _easingOptions,
        ),
        SliderField(
          key: 'hold',
          label: 'Rest Pause',
          description: 'Portion of the loop spent fully exhaled.',
          min: 0.0,
          max: 0.5,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SliderField(
          key: 'cycles',
          label: 'Breaths per Loop',
          description: 'How many breaths happen within the frame count.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
        ),
        SliderField(
          key: 'phase',
          label: 'Cycle Phase',
          description: 'Starting offset within the breathing cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'pixelSnap',
          label: 'Pixel Snap',
          description: 'Snap offsets to whole pixels for crisp pixel art.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress (0 to 1) updated during frame generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
      ];

  // ---------------------------------------------------------------------------
  // Parameter helpers
  // ---------------------------------------------------------------------------

  int _intParam(String key, int fallback, int min, int max) =>
      ((parameters[key] as num?)?.round() ?? fallback).clamp(min, max);

  double _doubleParam(String key, double fallback, double min, double max) =>
      ((parameters[key] as num?)?.toDouble() ?? fallback).clamp(min, max);

  /// Breath amount in `[0, 1]` (0 = exhaled / rest, 1 = full inhale) for a
  /// cycle position [p] in `[0, 1)`.
  static double breathCurve(double p, String easing, double hold) {
    final active = 1.0 - hold;
    if (active <= 0 || p >= active) return 0.0;
    final q = p / active;

    double easeInOut(double x) => 0.5 - 0.5 * math.cos(math.pi * x);

    switch (easing) {
      case 'step':
        return q < 0.5 ? 1.0 : 0.0;
      case 'smooth':
        return 0.5 - 0.5 * math.cos(2.0 * math.pi * q);
      case 'organic':
      default:
        const inhale = 0.4;
        if (q < inhale) return easeInOut(q / inhale);
        return 1.0 - easeInOut((q - inhale) / (1.0 - inhale));
    }
  }

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.length < width * height) {
      return pixels;
    }

    final frames = _intParam('frames', 8, 2, 24);
    final style = parameters['style'] as String? ?? 'chest';
    final anchor = parameters['anchor'] as String? ?? 'bottom';
    final anchorPosition = _doubleParam('anchorPosition', 0.5, 0.0, 1.0);
    final depthParam = _intParam('depth', 0, 0, 8);
    final plantedRatio = _doubleParam('plantedRatio', 0.35, 0.0, 0.8);
    final rigidRatio = _doubleParam('rigidRatio', 0.3, 0.0, 0.6);
    final chestExpand = _intParam('chestExpand', 0, 0, 3);
    final easing = parameters['easing'] as String? ?? 'organic';
    final hold = _doubleParam('hold', 0.15, 0.0, 0.5);
    final cycles = _intParam('cycles', 1, 1, 4);
    final phase = _doubleParam('phase', 0.0, 0.0, 1.0);
    final pixelSnap = parameters['pixelSnap'] as bool? ?? true;
    final time = _doubleParam('time', 0.0, 0.0, 1.0);

    // --- Sprite analysis -----------------------------------------------------
    final rowLeft = Int32List(height)..fillRange(0, height, -1);
    final rowRight = Int32List(height)..fillRange(0, height, -1);
    int top = -1;
    int bottom = -1;
    for (int y = 0; y < height; y++) {
      final base = y * width;
      for (int x = 0; x < width; x++) {
        if ((pixels[base + x] >>> 24) != 0) {
          if (rowLeft[y] < 0) rowLeft[y] = x;
          rowRight[y] = x;
        }
      }
      if (rowLeft[y] >= 0) {
        if (top < 0) top = y;
        bottom = y;
      }
    }
    if (top < 0) return Uint32List.fromList(pixels);

    final spriteHeight = bottom - top + 1;

    // --- Timing --------------------------------------------------------------
    // Quantize to the frame count so live previews show the exact poses the
    // generator will produce.
    final frameIndex = (time * frames + 1e-6).floor() % frames;
    final cycle = (frameIndex / frames * cycles + phase) % 1.0;
    final breath = breathCurve(cycle, easing, hold);

    final depth = depthParam > 0
        ? depthParam.toDouble()
        : math.max(1.0, (spriteHeight * 0.04).roundToDouble());

    double totalOffset = depth * breath;
    if (pixelSnap) totalOffset = totalOffset.roundToDouble();

    double chestOffset = chestExpand * breath;
    if (pixelSnap) chestOffset = chestOffset.roundToDouble();

    if (totalOffset == 0 && chestOffset == 0) {
      return Uint32List.fromList(pixels);
    }

    // --- Anchor & per-direction extents -------------------------------------
    final double anchorY = switch (anchor) {
      'top' => top.toDouble(),
      'center' => (top + bottom) / 2.0,
      'custom' => top + anchorPosition * (spriteHeight - 1),
      _ => bottom.toDouble(),
    };
    final upExtent = anchorY - top;
    final downExtent = bottom - anchorY;
    final extentSum = upExtent + downExtent;

    double upOffset = extentSum > 0 ? totalOffset * upExtent / extentSum : 0;
    if (pixelSnap) upOffset = upOffset.roundToDouble();
    final downOffset = totalOffset - upOffset;

    final up = _BreathBand.build(style, upExtent, upOffset, plantedRatio, rigidRatio);
    final down = _BreathBand.build(style, downExtent, downOffset, plantedRatio, rigidRatio);

    // --- Remap ---------------------------------------------------------------
    final result = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      final double srcYd;
      final double chestWeight;
      if (y <= anchorY) {
        final src = up.sourceDistance(anchorY - y);
        srcYd = anchorY - src;
        chestWeight = up.chestWeight(src);
      } else {
        final src = down.sourceDistance(y - anchorY);
        srcYd = anchorY + src;
        chestWeight = down.chestWeight(src);
      }

      final srcY = (srcYd + 0.5).floor();
      if (srcY < 0 || srcY >= height) continue;

      final srcBase = srcY * width;
      final dstBase = y * width;
      final left = rowLeft[srcY];
      if (left < 0) continue; // fully transparent source row

      double expand = chestOffset * chestWeight;
      if (pixelSnap) expand = expand.roundToDouble();

      if (expand <= 0) {
        for (int x = 0; x < width; x++) {
          result[dstBase + x] = pixels[srcBase + x];
        }
        continue;
      }

      // Widen this row symmetrically around its own opaque centre.
      final right = rowRight[srcY];
      final cx = (left + right) / 2.0;
      final halfWidth = (right - left) / 2.0 + 0.5;
      final scale = halfWidth / (halfWidth + expand);
      for (int x = 0; x < width; x++) {
        final srcX = (cx + (x - cx) * scale + 0.5).floor();
        if (srcX >= 0 && srcX < width) {
          result[dstBase + x] = pixels[srcBase + srcX];
        }
      }
    }

    return result;
  }
}

/// Piecewise distance mapping for one direction away from the anchor.
///
/// Distances are measured from the anchor line outward:
/// `[0, planted]` stays fixed, `(planted, rigidStart]` stretches to absorb
/// [offset], and everything beyond is shifted rigidly by [offset].
class _BreathBand {
  _BreathBand(this.extent, this.planted, this.rigidStart, this.offset);

  final double extent;
  final double planted;
  final double rigidStart;
  final double offset;

  static _BreathBand build(
    String style,
    double extent,
    double offset,
    double plantedRatio,
    double rigidRatio,
  ) {
    if (extent <= 0) return _BreathBand(0, 0, 0, 0);

    double planted;
    double rigidStart;
    switch (style) {
      case 'scale':
        planted = 0;
        rigidStart = extent;
        break;
      case 'bob':
        planted = plantedRatio * extent;
        rigidStart = planted;
        break;
      case 'chest':
      default:
        planted = plantedRatio * extent;
        rigidStart = math.max(planted, (1.0 - rigidRatio) * extent);
        // Keep at least a 1px band so the body can actually stretch.
        if (rigidStart - planted < 1.0) rigidStart = math.min(extent, planted + 1.0);
        break;
    }

    // Never compress the stretch band to (or below) zero length.
    final band = rigidStart - planted;
    final safeOffset = band > 0 ? math.max(offset, -(band - 1.0)) : offset;
    return _BreathBand(extent, planted, rigidStart, safeOffset);
  }

  double get _band => rigidStart - planted;

  /// Maps an output distance from the anchor to the source distance.
  double sourceDistance(double u) {
    if (offset == 0 || u <= planted) return u;
    final band = _band;
    if (band > 0) {
      if (u <= rigidStart + offset) {
        return planted + (u - planted) * band / (band + offset);
      }
    } else if (offset > 0 && u <= planted + offset) {
      // "Bob" style: repeat the waist row to fill the gap.
      return planted;
    }
    return u - offset;
  }

  /// Bell-shaped weight (0..1) peaking in the middle of the torso band.
  double chestWeight(double sourceDist) {
    if (extent <= 0) return 0;
    final start = planted;
    final end = _band >= 2 ? rigidStart : extent;
    final len = end - start;
    if (len <= 0 || sourceDist <= start || sourceDist >= end) return 0;
    return math.sin(math.pi * (sourceDist - start) / len);
  }
}
