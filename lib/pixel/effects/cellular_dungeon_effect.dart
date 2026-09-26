part of 'effects.dart';

/// Procedural cellular dungeon & cave labyrinth architecture generator.
///
/// Generates 8-bit roguelike dungeon maps, organic caves, and crypt catacombs
/// featuring autotiled stone brick walls, flagstone floor paving, overhang shadows,
/// and flickering wall-mounted torches casting warm radial light pools.
class CellularDungeonEffect extends Effect implements UIFieldProvider {
  CellularDungeonEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.cellularDungeon,
          parameters ??
              const {
                'dungeonType': 'stoneDungeon',
                'roomCount': 5,
                'corridorWidth': 3,
                'torchPlacement': true,
                'wallPalette': 'granite',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'dungeonType': 'stoneDungeon',
        'roomCount': 5,
        'corridorWidth': 3,
        'torchPlacement': true,
        'wallPalette': 'granite',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'dungeonType': {
          'label': 'Architecture Style',
          'description': 'Procedural layout generation algorithm.',
          'type': 'select',
          'options': {
            'stoneDungeon': 'Stone Keep Dungeon',
            'organicCave': 'Underdark Organic Cave',
            'cryptCatacombs': 'Symmetrical Crypt Catacombs',
          },
        },
        'roomCount': {
          'label': 'Room Density',
          'description': 'Number of partitioned dungeon chambers.',
          'type': 'slider',
          'min': 2,
          'max': 12,
          'step': 1,
        },
        'corridorWidth': {
          'label': 'Corridor Width',
          'description': 'Hallway width connecting chambers.',
          'type': 'slider',
          'min': 1,
          'max': 6,
          'step': 1,
        },
        'torchPlacement': {
          'label': 'Wall Torches',
          'description': 'Mount flickering torches with ambient light pools.',
          'type': 'bool',
        },
        'wallPalette': {
          'label': 'Stone Palette',
          'description': 'Geological stone and mortar color theme.',
          'type': 'select',
          'options': {
            'granite': 'Slate Granite Keep',
            'mossy': 'Mossy Dungeon Stone',
            'obsidian': 'Dark Obsidian Vault',
            'sandstone': 'Desert Sandstone Tomb',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress driving torch flame flicker.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict dungeon generation to existing silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'dungeonType',
          label: 'Architecture Style',
          description: 'Procedural layout generation algorithm.',
          options: {
            'stoneDungeon': 'Stone Keep Dungeon',
            'organicCave': 'Underdark Organic Cave',
            'cryptCatacombs': 'Symmetrical Crypt Catacombs',
          },
        ),
        SliderField(
          key: 'roomCount',
          label: 'Room Density',
          description: 'Number of partitioned dungeon rooms.',
          min: 2,
          max: 12,
          divisions: 10,
          formatLabel: (v) => '${v.round()} rooms',
        ),
        SliderField(
          key: 'corridorWidth',
          label: 'Corridor Width',
          description: 'Hallway connecting corridor width.',
          min: 1,
          max: 6,
          divisions: 5,
          formatLabel: (v) => '${v.round()} px',
        ),
        const BoolField(
          key: 'torchPlacement',
          label: 'Wall Torches',
          description: 'Mount flickering torches with ambient light pools.',
        ),
        const SelectField(
          key: 'wallPalette',
          label: 'Stone Palette',
          description: 'Stone and mortar coloration.',
          options: {
            'granite': 'Slate Granite Keep',
            'mossy': 'Mossy Dungeon Stone',
            'obsidian': 'Dark Obsidian Vault',
            'sandstone': 'Desert Sandstone Tomb',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Dungeon lighting animation progress.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Confine dungeon within original sprite bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final dungeonType = parameters['dungeonType'] as String? ?? 'stoneDungeon';
    final roomCount = (parameters['roomCount'] as num?)?.toInt() ?? 5;
    final corridorWidth = (parameters['corridorWidth'] as num?)?.toInt() ?? 3;
    final torchPlacement = parameters['torchPlacement'] as bool? ?? true;
    final wallPalette = parameters['wallPalette'] as String? ?? 'granite';
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);

    // Stone Palettes: [WallBase, WallHighlight, WallShadow/Mortar, FloorBase, FloorHighlight]
    late final List<List<int>> palette;
    switch (wallPalette) {
      case 'mossy':
        palette = [
          [46, 77, 44], // WallBase
          [76, 120, 72], // WallHighlight
          [24, 40, 22], // WallShadow
          [35, 58, 42], // FloorBase
          [48, 80, 56], // FloorHighlight
        ];
        break;
      case 'obsidian':
        palette = [
          [34, 30, 48], // WallBase
          [62, 54, 84], // WallHighlight
          [16, 14, 26], // WallShadow
          [26, 24, 38], // FloorBase
          [40, 36, 56], // FloorHighlight
        ];
        break;
      case 'sandstone':
        palette = [
          [141, 110, 99], // WallBase
          [188, 170, 164], // WallHighlight
          [93, 64, 55], // WallShadow
          [109, 76, 65], // FloorBase
          [161, 136, 127], // FloorHighlight
        ];
        break;
      case 'granite':
      default:
        palette = [
          [65, 75, 85], // WallBase
          [100, 115, 130], // WallHighlight
          [30, 35, 42], // WallShadow
          [48, 56, 65], // FloorBase
          [72, 84, 98], // FloorHighlight
        ];
        break;
    }

    // Grid representation: true = floor (walkable), false = solid wall
    final grid = List<bool>.filled(width * height, false);

    if (dungeonType == 'organicCave') {
      // Cellular automata cave simulation
      final rand = math.Random(1337);
      for (int i = 0; i < grid.length; i++) {
        grid[i] = rand.nextDouble() < 0.46;
      }
      // Apply 3 simulation steps (B5678 / S45678)
      final temp = List<bool>.filled(width * height, false);
      for (int step = 0; step < 3; step++) {
        for (int y = 1; y < height - 1; y++) {
          for (int x = 1; x < width - 1; x++) {
            int wallNeighbors = 0;
            for (int dy = -1; dy <= 1; dy++) {
              for (int dx = -1; dx <= 1; dx++) {
                if (!grid[(y + dy) * width + (x + dx)]) wallNeighbors++;
              }
            }
            temp[y * width + x] = (wallNeighbors < 5);
          }
        }
        for (int i = 0; i < grid.length; i++) {
          grid[i] = temp[i];
        }
      }
    } else if (dungeonType == 'cryptCatacombs') {
      // Symmetrical crypt layout: central nave + side burial chambers
      final cx = width ~/ 2;
      final naveW = math.max(3, corridorWidth + 1);

      // Central long nave
      for (int y = 2; y < height - 2; y++) {
        for (int x = cx - naveW ~/ 2; x <= cx + naveW ~/ 2; x++) {
          if (x >= 0 && x < width) grid[y * width + x] = true;
        }
      }

      // Symmetrical side crypt alcoves
      final alcoveSpacing = math.max(6, height ~/ (roomCount + 1));
      for (int y = alcoveSpacing; y < height - alcoveSpacing; y += alcoveSpacing) {
        // Horizontal side hall
        for (int x = 3; x < width - 3; x++) {
          for (int dy = 0; dy < corridorWidth; dy++) {
            final py = y + dy;
            if (py < height - 2) grid[py * width + x] = true;
          }
        }
        // Crypt pillars
        if (y + 1 < height - 2) {
          grid[(y + 1) * width + (cx - naveW)] = false;
          grid[(y + 1) * width + (cx + naveW)] = false;
        }
      }
    } else {
      // 'stoneDungeon': BSP-style rectangular rooms & connecting corridors
      final rooms = <math.Rectangle<int>>[];
      final rand = math.Random(42);

      const margin = 2;
      final maxRoomW = math.max(6, width ~/ 3);
      final maxRoomH = math.max(6, height ~/ 3);

      for (int r = 0; r < roomCount; r++) {
        final rw = 4 + rand.nextInt(math.max(1, maxRoomW - 4));
        final rh = 4 + rand.nextInt(math.max(1, maxRoomH - 4));
        final rx = margin + rand.nextInt(math.max(1, width - rw - margin * 2));
        final ry = margin + rand.nextInt(math.max(1, height - rh - margin * 2));

        final newRoom = math.Rectangle<int>(rx, ry, rw, rh);
        rooms.add(newRoom);

        // Carve room
        for (int y = ry; y < ry + rh; y++) {
          for (int x = rx; x < rx + rw; x++) {
            grid[y * width + x] = true;
          }
        }

        // Carve corridor to previous room
        if (r > 0) {
          final prev = rooms[r - 1];
          final pCx = prev.left + prev.width ~/ 2;
          final pCy = prev.top + prev.height ~/ 2;
          final nCx = rx + rw ~/ 2;
          final nCy = ry + rh ~/ 2;

          // Horizontal leg
          final startX = math.min(pCx, nCx);
          final endX = math.max(pCx, nCx);
          for (int x = startX; x <= endX; x++) {
            for (int w = 0; w < corridorWidth; w++) {
              final py = pCy + w - corridorWidth ~/ 2;
              if (py >= 0 && py < height) grid[py * width + x] = true;
            }
          }

          // Vertical leg
          final startY = math.min(pCy, nCy);
          final endY = math.max(pCy, nCy);
          for (int y = startY; y <= endY; y++) {
            for (int w = 0; w < corridorWidth; w++) {
              final px = nCx + w - corridorWidth ~/ 2;
              if (px >= 0 && px < width) grid[y * width + px] = true;
            }
          }
        }
      }
    }

    // Force map boundary walls
    for (int x = 0; x < width; x++) {
      grid[x] = false;
      grid[(height - 1) * width + x] = false;
    }
    for (int y = 0; y < height; y++) {
      grid[y * width] = false;
      grid[y * width + (width - 1)] = false;
    }

    // Identify torch anchor locations along walls
    final torchLocations = <math.Point<int>>[];
    if (torchPlacement) {
      for (int y = 1; y < height - 1; y += 3) {
        for (int x = 1; x < width - 1; x += 4) {
          // If this is a wall directly above a floor cell, it's a great spot for a wall torch
          if (!grid[y * width + x] && grid[(y + 1) * width + x]) {
            torchLocations.add(math.Point<int>(x, y));
            if (torchLocations.length >= 8) break;
          }
        }
        if (torchLocations.length >= 8) break;
      }
    }

    final cycleTime = time - time.floorToDouble();

    // Render floor and walls
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        final isFloor = grid[idx];
        int r, g, b;

        if (isFloor) {
          // Flagstone floor pattern: subtle grid dither every 4 pixels
          final isPavingSeam = (x % 5 == 0 || y % 5 == 0);
          final flagstoneNoise = ((x * 17 + y * 31) % 7) == 0;

          if (isPavingSeam) {
            r = palette[3][0];
            g = palette[3][1];
            b = palette[3][2];
          } else if (flagstoneNoise) {
            r = palette[4][0];
            g = palette[4][1];
            b = palette[4][2];
          } else {
            r = palette[3][0] + 6;
            g = palette[3][1] + 6;
            b = palette[3][2] + 6;
          }

          // Overhang shadow if wall is directly above
          if (y > 0 && !grid[(y - 1) * width + x]) {
            r = (r * 0.55).round();
            g = (g * 0.55).round();
            b = (b * 0.55).round();
          } else if (y > 1 && !grid[(y - 2) * width + x]) {
            r = (r * 0.78).round();
            g = (g * 0.78).round();
            b = (b * 0.78).round();
          }
        } else {
          // Solid stone wall autotiling
          final hasFloorBelow = (y < height - 1 && grid[(y + 1) * width + x]);
          final hasFloorAbove = (y > 0 && grid[(y - 1) * width + x]);
          final isBrickMortar = (y % 4 == 0) || ((x % 8 == (y ~/ 4 % 2) * 4));

          if (hasFloorAbove) {
            // Top rim highlight of wall
            r = palette[1][0];
            g = palette[1][1];
            b = palette[1][2];
          } else if (hasFloorBelow) {
            // Front facing wall base
            r = isBrickMortar ? palette[2][0] : palette[0][0];
            g = isBrickMortar ? palette[2][1] : palette[0][1];
            b = isBrickMortar ? palette[2][2] : palette[0][2];
          } else {
            // Solid subterranean interior rock
            r = isBrickMortar ? (palette[2][0] * 0.8).round() : (palette[0][0] * 0.85).round();
            g = isBrickMortar ? (palette[2][1] * 0.8).round() : (palette[0][1] * 0.85).round();
            b = isBrickMortar ? (palette[2][2] * 0.8).round() : (palette[0][2] * 0.85).round();
          }
        }

        // Apply flickering radial torch lighting
        if (torchPlacement && torchLocations.isNotEmpty) {
          for (int t = 0; t < torchLocations.length; t++) {
            final pt = torchLocations[t];
            final dx = (x - pt.x).abs();
            if (dx > 10) continue;
            final dy = (y - pt.y).abs();
            if (dy > 10) continue;

            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist < 9.0) {
              final flicker = 0.8 + 0.2 * math.sin(cycleTime * 35.0 + t * 7.3);
              final falloff = (1.0 - dist / 9.0) * flicker;

              // Warm amber torch light pool
              r = (r + 255 * falloff * 0.55).round().clamp(0, 255);
              g = (g + 175 * falloff * 0.40).round().clamp(0, 255);
              b = (b + 40 * falloff * 0.15).round().clamp(0, 255);
            }
          }
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (r << 16) | (g << 8) | b;
      }
    }

    // Draw torch sprites (wooden mount + yellow/orange flame pixel)
    if (torchPlacement) {
      for (int t = 0; t < torchLocations.length; t++) {
        final pt = torchLocations[t];
        final tx = pt.x;
        final ty = pt.y;

        if (tx >= 0 && tx < width && ty >= 0 && ty < height) {
          final idx = ty * width + tx;
          final origA = (pixels[idx] >> 24) & 0xFF;
          if (!preserveAlpha || origA > 0) {
            // Flame pixel
            final flickerColor = (t % 2 == 0) ? const [255, 235, 59] : const [255, 152, 0];
            output[idx] = (255 << 24) | (flickerColor[0] << 16) | (flickerColor[1] << 8) | flickerColor[2];

            // Wooden sconce bracket pixel below
            if (ty < height - 1) {
              final sIdx = (ty + 1) * width + tx;
              output[sIdx] = (255 << 24) | (100 << 16) | (60 << 8) | 25;
            }
          }
        }
      }
    }

    return output;
  }
}
