part of 'effects.dart';

/// Procedural cursed chain bind & runic seal break animation effect.
///
/// Wraps the sprite in interlocking diagonal iron chains etched with pulsating
/// ancient runes. As strain mounts, chains vibrate violently and heat up to
/// molten temperatures before violently detonating into flying metallic shards
/// and runic sparks when crossing the shatter threshold.
class CursedChainsEffect extends Effect implements UIFieldProvider {
  CursedChainsEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.cursedChains,
          parameters ??
              const {
                'chainCount': 3,
                'chainTightness': 1.0,
                'runeColor': 0xFFFF1744,
                'strainVibration': 0.5,
                'shatterTrigger': 0.75,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'chainCount': 3,
        'chainTightness': 1.0,
        'runeColor': 0xFFFF1744,
        'strainVibration': 0.5,
        'shatterTrigger': 0.75,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'chainCount': {
          'label': 'Chain Count',
          'description': 'Number of interlocking iron chains binding the sprite.',
          'type': 'slider',
          'min': 1,
          'max': 6,
          'step': 1,
        },
        'chainTightness': {
          'label': 'Chain Tightness',
          'description': 'Curvature and tension of the wrapping chains.',
          'type': 'slider',
          'min': 0.5,
          'max': 2.0,
          'step': 0.1,
        },
        'runeColor': {
          'label': 'Rune Glow Color',
          'description': 'Luminescent color of the etched ancient binding runes.',
          'type': 'color',
        },
        'strainVibration': {
          'label': 'Strain Vibration',
          'description': 'High-frequency jitter shaking as the chains build tension.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'shatterTrigger': {
          'label': 'Shatter Trigger',
          'description': 'Timeline moment where chains shatter into flying shards.',
          'type': 'slider',
          'min': 0.2,
          'max': 0.95,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Progress through the binding, strain, and shatter cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine chains and shards within the sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'chainCount',
          label: 'Chain Count',
          description: 'Number of binding iron chains.',
          min: 1,
          max: 6,
          divisions: 5,
          formatLabel: (v) => '${v.round()} chains',
        ),
        SliderField(
          key: 'chainTightness',
          label: 'Chain Tightness',
          description: 'Curvature and tension of the chain wrap.',
          min: 0.5,
          max: 2.0,
          divisions: 15,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'runeColor',
          label: 'Rune Glow Color',
          description: 'Luminescent color of the ancient runes.',
        ),
        SliderField(
          key: 'strainVibration',
          label: 'Strain Vibration',
          description: 'Violent shaking amplitude under heavy tension.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'shatterTrigger',
          label: 'Shatter Trigger',
          description: 'Timeline progress where seal breaks.',
          min: 0.2,
          max: 0.95,
          divisions: 15,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the binding & break cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict chains to the character silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final chainCount = (parameters['chainCount'] as num?)?.toInt() ?? 3;
    final chainTightness = (parameters['chainTightness'] as num?)?.toDouble() ?? 1.0;
    final runeColorInt = (parameters['runeColor'] as num?)?.toInt() ?? 0xFFFF1744;
    final strainVibration = (parameters['strainVibration'] as num?)?.toDouble() ?? 0.5;
    final shatterTrigger = (parameters['shatterTrigger'] as num?)?.toDouble() ?? 0.75;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    // Extract rune color channels
    final rA = (runeColorInt >> 24) & 0xFF;
    final rR = (runeColorInt >> 16) & 0xFF;
    final rG = (runeColorInt >> 8) & 0xFF;
    final rB = runeColorInt & 0xFF;

    // Detect sprite bounding box to wrap chains naturally around the subject
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

    final spriteW = (maxX - minX + 1).toDouble();
    final spriteH = (maxY - minY + 1).toDouble();
    final cx = minX + spriteW / 2.0;
    final cy = minY + spriteH / 2.0;
    final maxDim = math.max(spriteW, spriteH);

    void blendPixel(
      int px,
      int py,
      int colorR,
      int colorG,
      int colorB,
      double alphaFrac, {
      bool isAdditive = false,
    }) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final effAlpha = alphaFrac.clamp(0.0, 1.0);
      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      int newR, newG, newB;
      if (isAdditive) {
        newR = (oR + colorR * effAlpha).round().clamp(0, 255);
        newG = (oG + colorG * effAlpha).round().clamp(0, 255);
        newB = (oB + colorB * effAlpha).round().clamp(0, 255);
      } else {
        newR = (oR * (1.0 - effAlpha) + colorR * effAlpha).round().clamp(0, 255);
        newG = (oG * (1.0 - effAlpha) + colorG * effAlpha).round().clamp(0, 255);
        newB = (oB * (1.0 - effAlpha) + colorB * effAlpha).round().clamp(0, 255);
      }

      final targetA = (effAlpha * 255).round();
      final newA = preserveAlpha ? origA : math.max(origA, targetA);

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    final cycleTime = time - time.floorToDouble();
    final isShattered = cycleTime >= shatterTrigger;

    // Phase 1: Strain building ($0.0 \to shatterTrigger$)
    final strainFrac = isShattered ? 1.0 : (cycleTime / shatterTrigger).clamp(0.0, 1.0);

    // Phase 2: Shatter explosion ($shatterTrigger \to 1.0$)
    final shatterFrac = isShattered
        ? ((cycleTime - shatterTrigger) / (1.0 - shatterTrigger)).clamp(0.0, 1.0)
        : 0.0;

    // Flash illumination on seal break
    if (isShattered && shatterFrac < 0.25) {
      final flashIntensity = (1.0 - (shatterFrac / 0.25)) * 0.45;
      for (int py = minY; py <= maxY; py++) {
        for (int px = minX; px <= maxX; px++) {
          blendPixel(px, py, rR, rG, rB, flashIntensity, isAdditive: true);
        }
      }
    }

    // Configure distinct chain angles and placements
    const chainAngles = [
      0.65, // Diagonal descending (\)
      -0.65, // Diagonal ascending (/)
      0.15, // Near-horizontal belly bind
      -0.35, // Low ascending wrap
      0.45, // High descending wrap
      0.0, // Horizontal chest shackle
    ];

    for (int c = 0; c < chainCount; c++) {
      final angle = chainAngles[c % chainAngles.length];
      final yBias = (c - (chainCount - 1) / 2.0) * (spriteH / (chainCount + 1)) * 0.9;
      final chainCenterY = cy + yBias;
      final chainCenterX = cx;

      // Jitter vibration during heavy strain
      final jitterScale = math.pow(strainFrac, 2.0).toDouble() * strainVibration * 2.8;
      final jx = math.sin(cycleTime * 95.0 + c * 17.3) * jitterScale;
      final jy = math.cos(cycleTime * 110.0 + c * 23.7) * jitterScale;

      // Chain length spans across the sprite diagonal
      final span = (maxDim * 0.85).round();

      // Heating interpolation towards molten red-hot right before shatter
      final heatFactor = math.pow(strainFrac, 3.0).toDouble();

      for (int s = -span; s <= span; s++) {
        final tNorm = s / span; // -1.0 to 1.0
        // Parabolic arc for sag / tightness wrap around sprite volume
        final sag = math.cos(tNorm * math.pi * 0.5) * (spriteH * 0.18 / chainTightness);

        double lx = chainCenterX + s * math.cos(angle) - sag * math.sin(angle) + jx;
        double ly = chainCenterY + s * math.sin(angle) + sag * math.cos(angle) + jy;

        // Check if shattered: shards scatter outward from chain center
        if (isShattered) {
          // Shard index for pseudo-random deterministic trajectory
          final shardId = (s + span) ~/ 3;
          final shardRand = math.sin(shardId * 37.17 + c * 59.3).abs();
          final shardRandAngle = math.cos(shardId * 71.9 + c * 13.1) * math.pi * 2.0;

          // Outward velocity along chain normal + radial explosion
          final outDirX = math.cos(shardRandAngle);
          final outDirY = math.sin(shardRandAngle);

          final scatterDist = shatterFrac * (maxDim * 0.65) * (0.6 + 0.8 * shardRand);
          lx += outDirX * scatterDist;
          ly += outDirY * scatterDist + math.pow(shatterFrac, 2.0) * (maxDim * 0.25); // slight gravity pull
        }

        final ix = lx.round();
        final iy = ly.round();

        // Shatter opacity fades out
        final shardAlpha = isShattered ? (1.0 - shatterFrac * 0.9).clamp(0.0, 1.0) : 1.0;

        // Alternate link styles: link pattern repeating every 4 pixels
        final linkPhase = ((s + span) % 4);
        final isHorizontalLink = linkPhase < 2;

        // Base metallic iron colors
        int baseIronR = 60;
        int baseIronG = 65;
        int baseIronB = 75;

        // Molten heating tint
        if (heatFactor > 0.1) {
          baseIronR = (baseIronR * (1.0 - heatFactor) + rR * heatFactor).round();
          baseIronG = (baseIronG * (1.0 - heatFactor) + (rG * 0.6) * heatFactor).round();
          baseIronB = (baseIronB * (1.0 - heatFactor) + (rB * 0.2) * heatFactor).round();
        }

        // Highlight & shadow colors for 3D metallic feel
        final highIronR = (baseIronR + 80).clamp(0, 255);
        final highIronG = (baseIronG + 80).clamp(0, 255);
        final highIronB = (baseIronB + 80).clamp(0, 255);

        final darkIronR = (baseIronR * 0.45).round();
        final darkIronG = (baseIronG * 0.45).round();
        final darkIronB = (baseIronB * 0.45).round();

        // 1. Draw iron chain link pixels
        if (isHorizontalLink) {
          // Horizontal oval link (3 wide, 2 tall)
          blendPixel(ix - 1, iy, highIronR, highIronG, highIronB, shardAlpha * 0.95);
          blendPixel(ix, iy, baseIronR, baseIronG, baseIronB, shardAlpha * 0.95);
          blendPixel(ix + 1, iy, darkIronR, darkIronG, darkIronB, shardAlpha * 0.95);
          blendPixel(ix, iy + 1, darkIronR, darkIronG, darkIronB, shardAlpha * 0.75);
        } else {
          // Vertical interlocking link (2 wide, 3 tall)
          blendPixel(ix, iy - 1, highIronR, highIronG, highIronB, shardAlpha * 0.95);
          blendPixel(ix, iy, baseIronR, baseIronG, baseIronB, shardAlpha * 0.95);
          blendPixel(ix, iy + 1, darkIronR, darkIronG, darkIronB, shardAlpha * 0.95);
          blendPixel(ix + 1, iy, darkIronR, darkIronG, darkIronB, shardAlpha * 0.75);
        }

        // 2. Runic Glyphs etched along the chains
        final isRuneNode = ((s + span) % 8 == 0);
        if (isRuneNode) {
          // Fast pulse as strain increases
          final pulseSpeed = 4.0 + strainFrac * 12.0;
          final pulse = 0.5 + 0.5 * math.sin(cycleTime * math.pi * 2.0 * pulseSpeed + s * 0.2);
          final runeAlpha = ((0.55 + 0.45 * pulse) * shardAlpha).clamp(0.0, 1.0);

          // Glowing rune center
          blendPixel(ix, iy, rR, rG, rB, runeAlpha, isAdditive: true);

          // Rune aura corona
          final auraAlpha = runeAlpha * 0.45;
          blendPixel(ix - 1, iy, rR, rG, rB, auraAlpha, isAdditive: true);
          blendPixel(ix + 1, iy, rR, rG, rB, auraAlpha, isAdditive: true);
          blendPixel(ix, iy - 1, rR, rG, rB, auraAlpha, isAdditive: true);
          blendPixel(ix, iy + 1, rR, rG, rB, auraAlpha, isAdditive: true);

          // If shattered: burst of flying rune sparks
          if (isShattered) {
            final sparkPhase = (s * 13.7).abs();
            final sparkDist = shatterFrac * (maxDim * 0.85);
            final sparkAngle = (sparkPhase % (math.pi * 2.0));
            final spX = (ix + math.cos(sparkAngle) * sparkDist).round();
            final spY = (iy + math.sin(sparkAngle) * sparkDist).round();
            final spAlpha = (1.0 - shatterFrac) * (rA / 255.0);
            blendPixel(spX, spY, 255, 255, 255, spAlpha, isAdditive: true);
            blendPixel(spX + 1, spY, rR, rG, rB, spAlpha * 0.6, isAdditive: true);
          }
        }
      }
    }

    return output;
  }
}
