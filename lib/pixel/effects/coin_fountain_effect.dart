part of 'effects.dart';

/// Procedural 8-bit coin fountain & level victory confetti effect.
///
/// Features a celebratory fountain erupting upward from the sprite base,
/// showering golden spinning coins, sparkling faceted gems, fluttering confetti,
/// or twinkling stars with ballistic gravity and ground bounce damping.
class CoinFountainEffect extends Effect implements UIFieldProvider {
  CoinFountainEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.coinFountain,
          parameters ??
              const {
                'itemType': 'coins',
                'particleCount': 24,
                'fountainForce': 1.2,
                'gravity': 1.0,
                'bounceFloor': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'itemType': 'coins',
        'particleCount': 24,
        'fountainForce': 1.2,
        'gravity': 1.0,
        'bounceFloor': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'itemType': {
          'label': 'Fountain Item',
          'description': 'Type of celebratory arcade items bursting forth.',
          'type': 'select',
          'options': {
            'coins': 'Spinning Coins',
            'gems': 'Sparkling Gems',
            'confetti': 'Victory Confetti',
            'stars': 'Twinkling Stars',
          },
        },
        'particleCount': {
          'label': 'Item Count',
          'description': 'Total number of items in the celebratory shower.',
          'type': 'slider',
          'min': 8,
          'max': 64,
          'step': 4,
        },
        'fountainForce': {
          'label': 'Fountain Eruption Force',
          'description': 'Upward explosive velocity of the fountain burst.',
          'type': 'slider',
          'min': 0.5,
          'max': 2.5,
          'step': 0.1,
        },
        'gravity': {
          'label': 'Gravity Acceleration',
          'description': 'Downward gravitational pull on falling items.',
          'type': 'slider',
          'min': 0.2,
          'max': 2.0,
          'step': 0.1,
        },
        'bounceFloor': {
          'label': 'Floor Bounce',
          'description': 'Items bounce off the ground plane before coming to rest.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through the fountain eruption.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine celebratory items within character silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'itemType',
          label: 'Fountain Item',
          description: 'Type of arcade celebration particle.',
          options: {
            'coins': 'Spinning Coins',
            'gems': 'Sparkling Gems',
            'confetti': 'Victory Confetti',
            'stars': 'Twinkling Stars',
          },
        ),
        SliderField(
          key: 'particleCount',
          label: 'Item Count',
          description: 'Number of fountain particles.',
          min: 8,
          max: 64,
          divisions: 14,
          formatLabel: (v) => '${v.round()} items',
        ),
        SliderField(
          key: 'fountainForce',
          label: 'Fountain Force',
          description: 'Initial upward launch strength.',
          min: 0.5,
          max: 2.5,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'gravity',
          label: 'Gravity',
          description: 'Downward arc pull.',
          min: 0.2,
          max: 2.0,
          divisions: 18,
          formatLabel: (v) => '${v.toStringAsFixed(1)}g',
        ),
        const BoolField(
          key: 'bounceFloor',
          label: 'Floor Bounce',
          description: 'Bounce items off bottom ground plane.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Fountain shower timeline progress.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Confine fountain within character bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final itemType = parameters['itemType'] as String? ?? 'coins';
    final particleCount = (parameters['particleCount'] as num?)?.toInt() ?? 24;
    final fountainForce = (parameters['fountainForce'] as num?)?.toDouble() ?? 1.2;
    final gravity = (parameters['gravity'] as num?)?.toDouble() ?? 1.0;
    final bounceFloor = parameters['bounceFloor'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

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

    final spriteW = (maxX - minX + 1).toDouble();
    final spriteH = (maxY - minY + 1).toDouble();
    final originX = minX + spriteW / 2.0;
    final originY = minY + spriteH * 0.65;
    final groundFloorY = (height - 3).toDouble();

    void setPixel(int px, int py, int colorR, int colorG, int colorB, [double alpha = 1.0]) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final effA = alpha.clamp(0.0, 1.0);
      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      final newR = (oR * (1.0 - effA) + colorR * effA).round().clamp(0, 255);
      final newG = (oG * (1.0 - effA) + colorG * effA).round().clamp(0, 255);
      final newB = (oB * (1.0 - effA) + colorB * effA).round().clamp(0, 255);

      final targetA = (effA * 255).round();
      final newA = preserveAlpha ? origA : math.max(origA, targetA);

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    final cycleTime = time - time.floorToDouble();

    // Palette definitions
    const coinGoldBorder = [183, 129, 3];
    const coinGoldFace = [255, 215, 0];
    const coinGoldHighlight = [255, 245, 157];

    const gemPalettes = [
      [[255, 23, 68], [255, 138, 128]], // Ruby
      [[0, 230, 118], [185, 246, 202]], // Emerald
      [[41, 121, 255], [130, 177, 255]], // Sapphire
      [[213, 0, 249], [234, 128, 252]], // Amethyst
    ];

    const confettiColors = [
      [255, 64, 129], // Neon Pink
      [0, 229, 255], // Cyan
      [255, 234, 0], // Yellow
      [118, 255, 3], // Lime
      [255, 109, 0], // Orange
      [213, 0, 249], // Purple
    ];

    final maxDim = math.max(width, height).toDouble();

    for (int i = 0; i < particleCount; i++) {
      // Deterministic pseudo-random seed per item
      final seedAngle = math.sin(i * 12.9898 + 4.1415) * 43758.5453;
      final spreadFrac = (seedAngle - seedAngle.floorToDouble()) * 2.0 - 1.0; // -1.0 to 1.0

      final seedSpeed = math.sin(i * 78.233 + 1.234) * 43758.5453;
      final speedVariance = 0.8 + 0.4 * (seedSpeed - seedSpeed.floorToDouble());

      // Stagger launch time across the first 45% of cycle
      final launchDelay = (i / particleCount) * 0.45;
      final pTimeRaw = cycleTime - launchDelay;
      final pTime = pTimeRaw < 0 ? (pTimeRaw + 1.0) : pTimeRaw;

      // Ballistic launch trajectory
      // Angle: upward cone between -110 deg and -70 deg
      final launchAngle = -math.pi / 2.0 + spreadFrac * (math.pi * 0.35);
      final horizSpeed = math.cos(launchAngle) * (maxDim * 0.35) * speedVariance;
      final initVertSpeed = math.sin(launchAngle) * (maxDim * 1.1) * fountainForce * speedVariance;

      final gAcc = gravity * (maxDim * 2.2);

      // Current ballistic position before bounce
      double curX = originX + horizSpeed * pTime;
      double curY = originY + initVertSpeed * pTime + 0.5 * gAcc * pTime * pTime;

      // Floor bounce handling
      if (bounceFloor && curY > groundFloorY) {
        // Calculate collision time: solve originY + vy0*t + 0.5*g*t^2 = groundFloorY
        final a = 0.5 * gAcc;
        final b = initVertSpeed;
        final c = originY - groundFloorY;
        final disc = b * b - 4 * a * c;

        if (disc >= 0) {
          final tHit = (-b + math.sqrt(disc)) / (2 * a);
          if (pTime > tHit) {
            final tAfterBounce = pTime - tHit;
            final vImpact = initVertSpeed + gAcc * tHit;
            final vBounce = -vImpact * 0.52; // 52% coefficient of restitution
            curY = groundFloorY + vBounce * tAfterBounce + 0.5 * gAcc * tAfterBounce * tAfterBounce;

            // Secondary bounce clamp
            if (curY > groundFloorY) {
              curY = groundFloorY;
            }
          }
        } else {
          curY = groundFloorY;
        }
      }

      final ix = curX.round();
      final iy = curY.round();

      if (ix < -6 || ix >= width + 6 || iy < -6 || iy >= height + 6) continue;

      // Fade out near end of life
      final lifeFade = pTime > 0.85 ? ((1.0 - pTime) / 0.15).clamp(0.0, 1.0) : 1.0;

      // Render items according to type
      switch (itemType) {
        case 'coins':
          // 8-bit coin with perspective rotation spin
          final spinPhase = (pTime * 25.0 + i * 1.7) % (math.pi * 2.0);
          final coinWidthRatio = math.cos(spinPhase).abs(); // 0.0 to 1.0

          if (coinWidthRatio < 0.25) {
            // Coin seen edge-on (1 pixel wide x 3 pixels tall)
            setPixel(ix, iy - 1, coinGoldBorder[0], coinGoldBorder[1], coinGoldBorder[2], lifeFade);
            setPixel(ix, iy, coinGoldHighlight[0], coinGoldHighlight[1], coinGoldHighlight[2], lifeFade);
            setPixel(ix, iy + 1, coinGoldBorder[0], coinGoldBorder[1], coinGoldBorder[2], lifeFade);
          } else if (coinWidthRatio < 0.65) {
            // Coin semi-turned (2 pixels wide x 3 pixels tall)
            setPixel(ix, iy - 1, coinGoldFace[0], coinGoldFace[1], coinGoldFace[2], lifeFade);
            setPixel(ix + 1, iy - 1, coinGoldHighlight[0], coinGoldHighlight[1], coinGoldHighlight[2], lifeFade);
            setPixel(ix, iy, coinGoldFace[0], coinGoldFace[1], coinGoldFace[2], lifeFade);
            setPixel(ix + 1, iy, coinGoldBorder[0], coinGoldBorder[1], coinGoldBorder[2], lifeFade);
            setPixel(ix, iy + 1, coinGoldBorder[0], coinGoldBorder[1], coinGoldBorder[2], lifeFade);
          } else {
            // Full coin face (3x3 circular disk)
            setPixel(ix, iy - 1, coinGoldFace[0], coinGoldFace[1], coinGoldFace[2], lifeFade);
            setPixel(ix - 1, iy, coinGoldBorder[0], coinGoldBorder[1], coinGoldBorder[2], lifeFade);
            setPixel(ix, iy, coinGoldHighlight[0], coinGoldHighlight[1], coinGoldHighlight[2], lifeFade);
            setPixel(ix + 1, iy, coinGoldFace[0], coinGoldFace[1], coinGoldFace[2], lifeFade);
            setPixel(ix, iy + 1, coinGoldBorder[0], coinGoldBorder[1], coinGoldBorder[2], lifeFade);
          }
          break;

        case 'gems':
          // Sparkling faceted gemstone (3x3 diamond)
          final gem = gemPalettes[i % gemPalettes.length];
          final baseColor = gem[0];
          final highColor = gem[1];

          setPixel(ix, iy - 1, highColor[0], highColor[1], highColor[2], lifeFade);
          setPixel(ix - 1, iy, baseColor[0], baseColor[1], baseColor[2], lifeFade);
          setPixel(ix, iy, 255, 255, 255, lifeFade); // Glint spark
          setPixel(ix + 1, iy, baseColor[0], baseColor[1], baseColor[2], lifeFade);
          setPixel(ix, iy + 1, baseColor[0], baseColor[1], baseColor[2], lifeFade);
          break;

        case 'confetti':
          // Tumbling rectangular paper streamer
          final col = confettiColors[i % confettiColors.length];
          final flutter = math.sin(pTime * 20.0 + i * 3.1);

          if (flutter > 0.0) {
            // Horizontal 3x1 strip
            setPixel(ix - 1, iy, col[0], col[1], col[2], lifeFade);
            setPixel(ix, iy, col[0], col[1], col[2], lifeFade);
            setPixel(ix + 1, iy, col[0], col[1], col[2], lifeFade);
          } else {
            // Vertical 1x3 strip
            setPixel(ix, iy - 1, col[0], col[1], col[2], lifeFade);
            setPixel(ix, iy, col[0], col[1], col[2], lifeFade);
            setPixel(ix, iy + 1, col[0], col[1], col[2], lifeFade);
          }
          break;

        case 'stars':
          // 4-pointed golden twinkling star
          final twinkle = 0.6 + 0.4 * math.sin(pTime * 30.0 + i * 4.7);
          final starAlpha = lifeFade * twinkle;

          setPixel(ix, iy, 255, 255, 255, starAlpha); // Center white core
          setPixel(ix - 1, iy, 255, 215, 0, starAlpha * 0.85);
          setPixel(ix + 1, iy, 255, 215, 0, starAlpha * 0.85);
          setPixel(ix, iy - 1, 255, 215, 0, starAlpha * 0.85);
          setPixel(ix, iy + 1, 255, 215, 0, starAlpha * 0.85);
          break;
      }
    }

    return output;
  }
}
