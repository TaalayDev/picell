part of 'effects.dart';

/// Effect that creates various types of shaking/vibration animations
class ShakeEffect extends Effect {
  ShakeEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.shake,
          parameters ??
              const {
                'intensity': 0.5, // Shake intensity (0-1)
                'speed': 0.7, // Shake speed/frequency (0-1)
                'direction': 0, // 0=both, 1=horizontal, 2=vertical, 3=circular
                'shakeType': 0, // 0=random, 1=earthquake, 2=vibration, 3=impact
                'decay': 0.0, // Shake decay over time (0-1)
                'roughness': 0.5, // How jagged the shake is (0-1)
                'trauma': 1.0, // Shake trauma level (0-1)
                'randomSeed': 42, // Seed for deterministic randomness
                'time': 0.0, // Animation time parameter (0-1)
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'intensity': 0.5,
      'speed': 0.7,
      'direction': 0,
      'shakeType': 0,
      'decay': 0.0,
      'roughness': 0.5,
      'trauma': 1.0,
      'randomSeed': 42,
      'time': 0.0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'intensity': {
        'label': 'Shake Intensity',
        'description': 'How strong the shaking motion is.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'speed': {
        'label': 'Shake Speed',
        'description': 'How fast the shaking occurs.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'direction': {
        'label': 'Shake Direction',
        'description': 'Direction of the shaking motion.',
        'type': 'select',
        'options': {
          0: 'Both Axes',
          1: 'Horizontal Only',
          2: 'Vertical Only',
          3: 'Circular',
        },
      },
      'shakeType': {
        'label': 'Shake Type',
        'description': 'Type of shaking pattern.',
        'type': 'select',
        'options': {
          0: 'Random Shake',
          1: 'Earthquake',
          2: 'High-Freq Vibration',
          3: 'Impact/Hit',
        },
      },
      'decay': {
        'label': 'Shake Decay',
        'description': 'How quickly the shake subsides over time.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'roughness': {
        'label': 'Shake Roughness',
        'description': 'How chaotic and irregular the shake is.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'trauma': {
        'label': 'Trauma Level',
        'description': 'Overall shake trauma/stress level.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'randomSeed': {
        'label': 'Random Seed',
        'description': 'Changes the random shake pattern.',
        'type': 'slider',
        'min': 1,
        'max': 100,
        'divisions': 99,
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final intensity = parameters['intensity'] as double;
    final speed = parameters['speed'] as double;
    final direction = parameters['direction'] as int;
    final shakeType = parameters['shakeType'] as int;
    final decay = parameters['decay'] as double;
    final roughness = parameters['roughness'] as double;
    final trauma = parameters['trauma'] as double;
    final randomSeed = parameters['randomSeed'] as int;
    final time = parameters['time'] as double;

    final result = Uint32List(pixels.length);

    // Calculate decay factor
    final decayFactor = decay > 0 ? exp(-decay * time * 3) : 1.0;
    final effectiveIntensity = intensity * trauma * decayFactor;

    if (effectiveIntensity <= 0.01) {
      // No shake, return original
      return Uint32List.fromList(pixels);
    }

    // Calculate shake offset based on type
    final (offsetX, offsetY) = _calculateShakeOffset(
        time, speed, shakeType, direction, effectiveIntensity, roughness, randomSeed, width, height);

    // Apply shake transformation
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final destIndex = y * width + x;

        // Calculate source position (reverse the shake)
        final sourceX = (x - offsetX).round();
        final sourceY = (y - offsetY).round();

        // Sample pixel with bounds checking
        if (sourceX >= 0 && sourceX < width && sourceY >= 0 && sourceY < height) {
          final sourceIndex = sourceY * width + sourceX;
          result[destIndex] = pixels[sourceIndex];
        } else {
          result[destIndex] = 0; // Transparent for out-of-bounds
        }
      }
    }

    return result;
  }

  /// Calculate shake offset based on shake type and parameters
  (double, double) _calculateShakeOffset(double time, double speed, int shakeType, int direction, double intensity,
      double roughness, int seed, int width, int height) {
    final maxShake = intensity * min(width, height) * 0.1;
    final animTime = time * speed * 20;

    double shakeX = 0.0;
    double shakeY = 0.0;

    switch (shakeType) {
      case 0: // Random shake
        shakeX = _perlinNoise(animTime * 2, seed) * maxShake;
        shakeY = _perlinNoise(animTime * 2, seed + 1000) * maxShake;

        // Add roughness with higher frequency noise
        if (roughness > 0) {
          shakeX += _perlinNoise(animTime * 8, seed + 2000) * maxShake * roughness * 0.5;
          shakeY += _perlinNoise(animTime * 8, seed + 3000) * maxShake * roughness * 0.5;
        }
        break;

      case 1: // Earthquake (low frequency, rolling motion)
        final baseFreq = animTime * 0.5;
        final rollX = sin(baseFreq) * cos(baseFreq * 1.3);
        final rollY = cos(baseFreq * 0.8) * sin(baseFreq * 1.7);

        shakeX = rollX * maxShake;
        shakeY = rollY * maxShake;

        // Add some randomness for realism
        shakeX += _perlinNoise(animTime, seed) * maxShake * 0.3;
        shakeY += _perlinNoise(animTime, seed + 500) * maxShake * 0.3;
        break;

      case 2: // High-frequency vibration
        final vibrateFreq = animTime * 3;
        shakeX = sin(vibrateFreq * 7) * cos(vibrateFreq * 11) * maxShake * 0.8;
        shakeY = cos(vibrateFreq * 9) * sin(vibrateFreq * 13) * maxShake * 0.8;

        // Add ultra-high frequency for buzzing effect
        if (roughness > 0.5) {
          shakeX += sin(vibrateFreq * 23) * maxShake * roughness * 0.3;
          shakeY += cos(vibrateFreq * 29) * maxShake * roughness * 0.3;
        }
        break;

      case 3: // Impact/Hit (sharp initial movement, then decay)
        final impactTime = (animTime % 10) / 10; // Reset every 10 time units
        final impactDecay = exp(-impactTime * 8); // Sharp decay

        if (impactTime < 0.5) {
          // Only shake for first half of cycle
          final impactX = sin(impactTime * pi * 8) * impactDecay;
          final impactY = cos(impactTime * pi * 6) * impactDecay;

          shakeX = impactX * maxShake;
          shakeY = impactY * maxShake * 0.7; // Less vertical movement
        }
        break;
    }

    // Apply directional constraints
    switch (direction) {
      case 1: // Horizontal only
        shakeY = 0.0;
        break;
      case 2: // Vertical only
        shakeX = 0.0;
        break;
      case 3: // Circular
        final angle = atan2(shakeY, shakeX);
        final magnitude = sqrt(shakeX * shakeX + shakeY * shakeY);
        final circularAngle = angle + animTime * 2;
        shakeX = cos(circularAngle) * magnitude;
        shakeY = sin(circularAngle) * magnitude;
        break;
      case 0: // Both axes (no change)
      default:
        break;
    }

    return (shakeX, shakeY);
  }

  /// Simple Perlin-like noise function for shake randomness
  double _perlinNoise(double x, int seed) {
    final intX = x.floor();
    final fracX = x - intX;

    final a = _hash(intX + seed);
    final b = _hash(intX + 1 + seed);

    // Smooth interpolation
    final smoothed = fracX * fracX * (3 - 2 * fracX);
    return (a * (1 - smoothed) + b * smoothed) * 2 - 1; // -1 to 1
  }

  /// Hash function for pseudo-random values
  double _hash(int input) {
    var h = input;
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    h = (h >> 16) ^ h;
    return (h & 0xFFFFFF) / 0xFFFFFF; // 0 to 1
  }
}

/// Optimized shake effect for performance-critical scenarios
class QuickShakeEffect extends Effect {
  QuickShakeEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.quickShake,
          parameters ??
              const {
                'intensity': 0.4, // Shake intensity (0-1)
                'frequency': 0.8, // Shake frequency (0-1)
                'horizontal': true, // Enable horizontal shake
                'vertical': true, // Enable vertical shake
                'time': 0.0, // Animation time parameter (0-1)
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'intensity': 0.4,
      'frequency': 0.8,
      'horizontal': true,
      'vertical': true,
      'time': 0.0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'intensity': {
        'label': 'Shake Intensity',
        'description': 'Strength of the shake effect.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'frequency': {
        'label': 'Shake Frequency',
        'description': 'How rapidly the shaking occurs.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'horizontal': {
        'label': 'Horizontal Shake',
        'description': 'Enable left/right shaking.',
        'type': 'bool',
      },
      'vertical': {
        'label': 'Vertical Shake',
        'description': 'Enable up/down shaking.',
        'type': 'bool',
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final intensity = parameters['intensity'] as double;
    final frequency = parameters['frequency'] as double;
    final horizontal = parameters['horizontal'] as bool;
    final vertical = parameters['vertical'] as bool;
    final time = parameters['time'] as double;

    if (intensity <= 0.01) {
      return Uint32List.fromList(pixels);
    }

    final result = Uint32List(pixels.length);

    // Simple, fast shake calculation
    final animTime = time * frequency * 15;
    final maxShake = intensity * min(width, height) * 0.08;

    final offsetX = horizontal ? sin(animTime * 7) * cos(animTime * 3) * maxShake : 0.0;
    final offsetY = vertical ? cos(animTime * 5) * sin(animTime * 9) * maxShake : 0.0;

    // Fast pixel copying with shake offset
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final destIndex = y * width + x;

        final sourceX = (x - offsetX).round().clamp(0, width - 1);
        final sourceY = (y - offsetY).round().clamp(0, height - 1);
        final sourceIndex = sourceY * width + sourceX;

        result[destIndex] = pixels[sourceIndex];
      }
    }

    return result;
  }
}

/// Camera shake effect that simulates screen/camera movement
class CameraShakeEffect extends Effect {
  CameraShakeEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.cameraShake,
          parameters ??
              const {
                'magnitude': 0.5, // Shake magnitude (0-1)
                'duration': 1.0, // Shake duration in cycles (0.1-5.0)
                'falloff': 0.8, // How quickly shake reduces (0-1)
                'rotationShake': 0.2, // Slight rotation during shake (0-1)
                'zoomShake': 0.1, // Slight zoom variation (0-1)
                'triggerTime': 0.0, // When the shake was triggered (0-1)
                'time': 0.0, // Current animation time (0-1)
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'magnitude': 0.5,
      'duration': 1.0,
      'falloff': 0.8,
      'rotationShake': 0.2,
      'zoomShake': 0.1,
      'triggerTime': 0.0,
      'time': 0.0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'magnitude': {
        'label': 'Shake Magnitude',
        'description': 'Overall strength of camera shake.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'duration': {
        'label': 'Shake Duration',
        'description': 'How long the shake effect lasts.',
        'type': 'slider',
        'min': 0.1,
        'max': 5.0,
        'divisions': 100,
      },
      'falloff': {
        'label': 'Shake Falloff',
        'description': 'How quickly the shake dies down.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'rotationShake': {
        'label': 'Rotation Shake',
        'description': 'Adds slight rotation to the shake.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'zoomShake': {
        'label': 'Zoom Shake',
        'description': 'Adds slight zoom variations.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'triggerTime': {
        'label': 'Trigger Time',
        'description': 'When the shake was triggered (set to current time to restart).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final magnitude = parameters['magnitude'] as double;
    final duration = parameters['duration'] as double;
    final falloff = parameters['falloff'] as double;
    final rotationShake = parameters['rotationShake'] as double;
    final zoomShake = parameters['zoomShake'] as double;
    final triggerTime = parameters['triggerTime'] as double;
    final time = parameters['time'] as double;

    final result = Uint32List(pixels.length);

    // Calculate time since shake was triggered
    final elapsed = (time - triggerTime).abs();

    // Check if shake is still active
    if (elapsed > duration) {
      return Uint32List.fromList(pixels);
    }

    // Calculate shake intensity with falloff
    final progress = elapsed / duration;
    final intensity = magnitude * exp(-falloff * progress * 5);

    if (intensity <= 0.01) {
      return Uint32List.fromList(pixels);
    }

    // Calculate shake components
    final shakeTime = elapsed * 25; // High frequency for camera shake
    // Preserve at least a pixel of motion on small pixel-art canvases.
    final maxOffset = max(1.25, intensity * min(width, height) * 0.15);

    // Positional shake
    final offsetX = sin(shakeTime * 8.5) * cos(shakeTime * 3.7) * maxOffset;
    final offsetY = cos(shakeTime * 7.2) * sin(shakeTime * 4.1) * maxOffset;

    // Rotation shake (very subtle)
    final rotationAngle = sin(shakeTime * 6.3) * rotationShake * intensity * 0.02; // Small angle

    // Zoom shake
    final zoomFactor = 1.0 + sin(shakeTime * 9.1) * zoomShake * intensity * 0.05;

    // Apply transformations
    final centerX = width / 2.0;
    final centerY = height / 2.0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final destIndex = y * width + x;

        // Apply transformations in reverse order
        var sourceX = x.toDouble();
        var sourceY = y.toDouble();

        // Reverse zoom (scale down to sample from larger area)
        sourceX = centerX + (sourceX - centerX) / zoomFactor;
        sourceY = centerY + (sourceY - centerY) / zoomFactor;

        // Reverse rotation
        if (rotationAngle.abs() > 0.001) {
          final dx = sourceX - centerX;
          final dy = sourceY - centerY;
          final cos_a = cos(-rotationAngle);
          final sin_a = sin(-rotationAngle);
          sourceX = centerX + dx * cos_a - dy * sin_a;
          sourceY = centerY + dx * sin_a + dy * cos_a;
        }

        // Reverse position offset
        sourceX -= offsetX;
        sourceY -= offsetY;

        // Sample pixel
        final intX = sourceX.round();
        final intY = sourceY.round();

        if (intX >= 0 && intX < width && intY >= 0 && intY < height) {
          final sourceIndex = intY * width + intX;
          result[destIndex] = pixels[sourceIndex];
        } else {
          result[destIndex] = 0;
        }
      }
    }

    return result;
  }
}
