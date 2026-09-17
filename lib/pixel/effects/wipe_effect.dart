part of 'effects.dart';

/// Effect that reveals or hides the image with various geometric wipe patterns
class WipeEffect extends Effect {
  WipeEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.wipe,
          parameters ??
              const {
                'progress': 0.0, // Wipe progress (0-1)
                'wipeType': 0, // 0=linear, 1=circular, 2=spiral, 3=radial, 4=venetian, 5=iris, 6=diamond
                'direction': 0.0, // Direction/angle parameter (0-1)
                'centerX': 0.5, // Center X for radial patterns (0-1)
                'centerY': 0.5, // Center Y for radial patterns (0-1)
                'softness': 0.1, // Edge softness (0-1)
                'invert': false, // Reverse the wipe (hide instead of reveal)
                'strips': 5, // Number of strips for venetian blind (1-20)
                'rotation': 0.0, // Additional rotation for some patterns (0-1)
                'feather': 0.0, // Feather/blur on edges (0-1)
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'progress': 0.0,
      'wipeType': 0,
      'direction': 0,
      'centerX': 0.5,
      'centerY': 0.5,
      'softness': 0.1,
      'invert': false,
      'strips': 5,
      'rotation': 0.0,
      'feather': 0.0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'progress': {
        'label': 'Wipe Progress',
        'description': 'How much of the wipe transition has completed (0 = start, 1 = end).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'wipeType': {
        'label': 'Wipe Type',
        'description': 'The geometric pattern used for the wipe transition.',
        'type': 'select',
        'options': {
          0: 'Linear Wipe',
          1: 'Circular Wipe',
          2: 'Spiral Wipe',
          3: 'Radial Wipe',
          4: 'Venetian Blind',
          5: 'Iris Wipe',
          6: 'Diamond Wipe',
          7: 'Clock Wipe',
          8: 'Barn Door',
        },
      },
      'direction': {
        'label': 'Direction/Angle',
        'description': 'Direction or angle for the wipe pattern (meaning varies by type).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'centerX': {
        'label': 'Center X',
        'description': 'Horizontal center point for radial wipe patterns.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'centerY': {
        'label': 'Center Y',
        'description': 'Vertical center point for radial wipe patterns.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'softness': {
        'label': 'Edge Softness',
        'description': 'How soft/blurred the wipe edge is.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'invert': {
        'label': 'Invert Wipe',
        'description': 'Reverse the wipe direction (hide instead of reveal).',
        'type': 'bool',
      },
      'strips': {
        'label': 'Strip Count',
        'description': 'Number of strips for venetian blind wipe.',
        'type': 'slider',
        'min': 1,
        'max': 20,
        'divisions': 19,
      },
      'rotation': {
        'label': 'Rotation',
        'description': 'Additional rotation applied to some wipe patterns.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'feather': {
        'label': 'Edge Feather',
        'description': 'Additional feathering/blur effect on the wipe edges.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final progress = (parameters['progress'] as double).clamp(0.0, 1.0);
    final wipeType = parameters['wipeType'] as int;
    final direction = parameters['direction'] as double;
    final centerX = parameters['centerX'] as double;
    final centerY = parameters['centerY'] as double;
    final softness = parameters['softness'] as double;
    final invert = parameters['invert'] as bool;
    final strips = (parameters['strips'] as int).clamp(1, 20);
    final rotation = parameters['rotation'] as double;
    final feather = parameters['feather'] as double;

    final result = Uint32List(pixels.length);

    // Calculate center point in pixels
    final wipeCenterX = centerX * width;
    final wipeCenterY = centerY * height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final originalPixel = pixels[index];

        // Skip transparent pixels
        if (((originalPixel >> 24) & 0xFF) == 0) {
          result[index] = 0;
          continue;
        }

        // Calculate wipe mask value (0-1, where 1 = fully visible)
        double maskValue = _calculateWipeMask(
            x, y, width, height, wipeType, progress, direction, wipeCenterX, wipeCenterY, strips, rotation);

        // Apply invert if specified
        if (invert) {
          maskValue = 1.0 - maskValue;
        }

        // Apply softness to the mask
        if (softness > 0) {
          maskValue = _applySoftness(maskValue, softness);
        }

        // Apply feathering if specified
        if (feather > 0) {
          maskValue = _applyFeather(maskValue, x, y, feather);
        }

        // Apply mask to pixel
        result[index] = _applyMaskToPixel(originalPixel, maskValue);
      }
    }

    return result;
  }

  /// Calculate the wipe mask value for a pixel based on the wipe type
  double _calculateWipeMask(int x, int y, int width, int height, int wipeType, double progress, double direction,
      double centerX, double centerY, int strips, double rotation) {
    switch (wipeType) {
      case 0: // Linear wipe
        return _linearWipe(x, y, width, height, progress, direction);

      case 1: // Circular wipe
        return _circularWipe(x, y, centerX, centerY, width, height, progress);

      case 2: // Spiral wipe
        return _spiralWipe(x, y, centerX, centerY, width, height, progress, direction);

      case 3: // Radial wipe
        return _radialWipe(x, y, centerX, centerY, progress, direction);

      case 4: // Venetian blind
        return _venetianBlindWipe(x, y, width, height, progress, direction, strips);

      case 5: // Iris wipe
        return _irisWipe(x, y, centerX, centerY, width, height, progress, direction);

      case 6: // Diamond wipe
        return _diamondWipe(x, y, centerX, centerY, width, height, progress, rotation);

      case 7: // Clock wipe
        return _clockWipe(x, y, centerX, centerY, progress, direction);

      case 8: // Barn door wipe
        return _barnDoorWipe(x, y, width, height, progress, direction);

      default:
        return _linearWipe(x, y, width, height, progress, direction);
    }
  }

  /// Linear wipe (straight line across image)
  double _linearWipe(int x, int y, int width, int height, double progress, double direction) {
    // Convert direction (0-1) to angle (0-2π)
    final angle = direction * 2 * pi;

    // Calculate the wipe line position
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);

    // Project pixel position onto the wipe direction
    final centerX = width / 2;
    final centerY = height / 2;
    final relativeX = x - centerX;
    final relativeY = y - centerY;

    // Project onto direction vector
    final projection = relativeX * cosAngle + relativeY * sinAngle;

    // Calculate maximum projection distance
    final maxProjection = (width + height) / 2;

    // Normalize projection to 0-1
    final normalizedProjection = (projection + maxProjection) / (2 * maxProjection);

    return normalizedProjection <= progress ? 1.0 : 0.0;
  }

  /// Circular wipe (expanding/contracting circle)
  double _circularWipe(int x, int y, double centerX, double centerY, int width, int height, double progress) {
    final distance = sqrt(pow(x - centerX, 2) + pow(y - centerY, 2));
    final maxDistance =
        sqrt(centerX * centerX + centerY * centerY + pow(width - centerX, 2) + pow(height - centerY, 2));

    final normalizedDistance = distance / maxDistance;
    return normalizedDistance <= progress ? 1.0 : 0.0;
  }

  /// Spiral wipe (rotating spiral pattern)
  double _spiralWipe(
      int x, int y, double centerX, double centerY, int width, int height, double progress, double direction) {
    final dx = x - centerX;
    final dy = y - centerY;
    final distance = sqrt(dx * dx + dy * dy);
    final angle = atan2(dy, dx);

    // Normalize angle to 0-1
    var normalizedAngle = (angle + pi) / (2 * pi);

    // Apply direction (spiral direction)
    if (direction > 0.5) {
      normalizedAngle = 1.0 - normalizedAngle; // Counter-clockwise
    }

    // Calculate spiral factor
    final maxDistance =
        sqrt(centerX * centerX + centerY * centerY + pow(width - centerX, 2) + pow(height - centerY, 2));
    final normalizedDistance = distance / maxDistance;

    // Combine angle and distance for spiral effect
    final spiralProgress = (normalizedAngle + normalizedDistance * 2) % 1.0;

    return spiralProgress <= progress ? 1.0 : 0.0;
  }

  /// Radial wipe (like clock hands)
  double _radialWipe(int x, int y, double centerX, double centerY, double progress, double direction) {
    final dx = x - centerX;
    final dy = y - centerY;
    var angle = atan2(dy, dx);

    // Normalize angle to 0-1
    angle = (angle + pi) / (2 * pi);

    // Apply direction offset
    angle = (angle + direction) % 1.0;

    return angle <= progress ? 1.0 : 0.0;
  }

  /// Venetian blind wipe (horizontal or vertical strips)
  double _venetianBlindWipe(int x, int y, int width, int height, double progress, double direction, int strips) {
    final isVertical = direction > 0.5;
    final stripSize = isVertical ? (width / strips) : (height / strips);
    final position = isVertical ? x : y;

    final stripIndex = (position / stripSize).floor();
    final positionInStrip = (position % stripSize) / stripSize;

    // Stagger the strips slightly
    final stripOffset = (stripIndex * 0.1) % 1.0;
    final adjustedProgress = (progress + stripOffset).clamp(0.0, 1.0);

    return positionInStrip <= adjustedProgress ? 1.0 : 0.0;
  }

  /// Iris wipe (rectangular expanding from center)
  double _irisWipe(
      int x, int y, double centerX, double centerY, int width, int height, double progress, double direction) {
    final dx = (x - centerX).abs();
    final dy = (y - centerY).abs();

    // Calculate max distances
    final maxDx = max(centerX, width - centerX);
    final maxDy = max(centerY, height - centerY);

    // Direction controls aspect ratio (0 = square, 1 = wide rectangle)
    final aspectRatio = 1.0 + direction * 2;

    final normalizedDx = dx / maxDx;
    final normalizedDy = dy / (maxDy * aspectRatio);

    final maxNormalized = max(normalizedDx, normalizedDy);

    return maxNormalized <= progress ? 1.0 : 0.0;
  }

  /// Diamond wipe (diamond shape expanding from center)
  double _diamondWipe(
      int x, int y, double centerX, double centerY, int width, int height, double progress, double rotation) {
    final dx = x - centerX;
    final dy = y - centerY;

    // Apply rotation
    final rotAngle = rotation * 2 * pi;
    final rotatedX = dx * cos(rotAngle) - dy * sin(rotAngle);
    final rotatedY = dx * sin(rotAngle) + dy * cos(rotAngle);

    // Diamond distance (Manhattan distance)
    final diamondDistance = rotatedX.abs() + rotatedY.abs();

    // Calculate max diamond distance
    final maxDistance = max(centerX + centerY,
        max((width - centerX) + centerY, max(centerX + (height - centerY), (width - centerX) + (height - centerY))));

    final normalizedDistance = diamondDistance / maxDistance;

    return normalizedDistance <= progress ? 1.0 : 0.0;
  }

  /// Clock wipe (sweeping like clock hand)
  double _clockWipe(int x, int y, double centerX, double centerY, double progress, double direction) {
    final dx = x - centerX;
    final dy = y - centerY;

    // Calculate angle from center
    var angle = atan2(dy, dx);

    // Normalize to 0-2π, starting from top (12 o'clock)
    angle = angle + pi / 2;
    if (angle < 0) angle += 2 * pi;
    if (angle >= 2 * pi) angle -= 2 * pi;

    // Apply direction (starting angle)
    final startAngle = direction * 2 * pi;
    angle = (angle - startAngle + 2 * pi) % (2 * pi);

    final normalizedAngle = angle / (2 * pi);

    return normalizedAngle <= progress ? 1.0 : 0.0;
  }

  /// Barn door wipe (opens from center outward)
  double _barnDoorWipe(int x, int y, int width, int height, double progress, double direction) {
    final isVertical = direction > 0.5;

    if (isVertical) {
      // Vertical barn doors (open left/right from center)
      final centerX = width / 2;
      final distanceFromCenter = (x - centerX).abs();
      final maxDistance = width / 2;

      return (distanceFromCenter / maxDistance) <= progress ? 1.0 : 0.0;
    } else {
      // Horizontal barn doors (open up/down from center)
      final centerY = height / 2;
      final distanceFromCenter = (y - centerY).abs();
      final maxDistance = height / 2;

      return (distanceFromCenter / maxDistance) <= progress ? 1.0 : 0.0;
    }
  }

  /// Apply softness to the mask value
  double _applySoftness(double maskValue, double softness) {
    if (softness <= 0) return maskValue;

    // The geometric masks are currently binary. Keep fully revealed pixels
    // visible; the previous formula mapped both 0 and 1 to zero.
    if (maskValue <= 0.0 || maskValue >= 1.0) return maskValue;

    // Create smooth transition around the edge
    final softRange = softness * 0.5;

    if (maskValue <= softRange) {
      return maskValue / softRange;
    } else if (maskValue >= 1.0 - softRange) {
      return (1.0 - maskValue) / softRange;
    } else {
      return 1.0;
    }
  }

  /// Apply feather effect to the mask
  double _applyFeather(double maskValue, int x, int y, double feather) {
    if (feather <= 0) return maskValue;

    // Add some noise/variation to create feathered edge
    final noise = sin(x * 0.1) * cos(y * 0.1) * sin(x * 0.05 + y * 0.07);
    final featherAmount = feather * 0.1;

    return (maskValue + noise * featherAmount).clamp(0.0, 1.0);
  }

  /// Apply mask value to pixel (adjust alpha)
  int _applyMaskToPixel(int pixel, double maskValue) {
    if (maskValue <= 0.0) return 0; // Fully transparent
    if (maskValue >= 1.0) return pixel; // Fully opaque

    final originalAlpha = (pixel >> 24) & 0xFF;
    final newAlpha = (originalAlpha * maskValue).round().clamp(0, 255);

    return (newAlpha << 24) | (pixel & 0x00FFFFFF);
  }
}
