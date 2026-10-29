import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/core/services/drop_handler_service.dart';
import 'package:picell/data.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  Project buildSampleProject() {
    final pixels1 = Uint32List.fromList([
      0xFF112233,
      0x80445566,
      0x00000000,
      0xFFAABBCC,
    ]);
    final pixels2 = Uint32List.fromList([
      0xFFFFFFFF,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFF0000,
    ]);

    return Project(
      id: 42,
      name: 'Волшебный Замок 🏰',
      width: 2,
      height: 2,
      type: ProjectType.pixelArt,
      tileWidth: 16,
      tileHeight: 16,
      gridColumns: 8,
      gridRows: 6,
      tilemapData: '{"columns":8,"rows":6}',
      rigData: '{"version":1,"rigs":[]}',
      tilesetData: '{"kind":"tilesetCollection","version":2}',
      thumbnail: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
      isCloudSynced: true,
      remoteId: 101,
      forkedFromId: 77,
      selectedFrameId: 10,
      selectedLayerId: 20,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      editedAt: DateTime.fromMillisecondsSinceEpoch(1700000500000),
      states: const [
        AnimationStateModel(id: 1, name: 'Idle ✨', frameRate: 12),
        AnimationStateModel(id: 2, name: 'Walk', frameRate: 24),
      ],
      frames: [
        AnimationFrame(
          id: 10,
          name: 'Кадр 1',
          stateId: 1,
          duration: 120,
          order: 0,
          createdAt: DateTime.fromMillisecondsSinceEpoch(1700000001000),
          editedAt: DateTime.fromMillisecondsSinceEpoch(1700000002000),
          layers: [
            Layer(
              layerId: 20,
              id: 'layer-uuid-1',
              name: 'Фон',
              pixels: pixels1,
              isVisible: true,
              isLocked: false,
              opacity: 0.75,
              order: 0,
              anchorPoint: const Offset(1.5, 0.5),
              stableKey: 'stable-1',
              effects: [
                EffectsManager.createEffect(
                  EffectType.brightness,
                  {'value': 0.2},
                ),
              ],
            ),
            Layer(
              layerId: 21,
              id: 'layer-uuid-2',
              name: 'Детали',
              pixels: pixels2,
              isVisible: false,
              isLocked: true,
              opacity: 1.0,
              order: 1,
            ),
          ],
        ),
      ],
    );
  }

  group('ProjectBinaryCodec & Project dual serialization', () {
    test('round-trips a full Project through binary PXV v2 format (toBytes / fromBytes)', () {
      final original = buildSampleProject();

      final bytes = original.toBytes();
      expect(ProjectBinaryCodec.isBinaryFormat(bytes), isTrue);
      expect(bytes.sublist(0, 4), ProjectBinaryCodec.magic);

      final restored = Project.fromBytes(bytes);
      expect(restored, equals(original));
      expect(restored.name, 'Волшебный Замок 🏰');
      expect(restored.thumbnail, equals(original.thumbnail));
      expect(restored.frames.single.layers.first.pixels, equals(original.frames.single.layers.first.pixels));
      expect(restored.frames.single.layers.first.anchorPoint, const Offset(1.5, 0.5));
      expect(restored.frames.single.layers.first.stableKey, 'stable-1');
      expect(restored.frames.single.layers.first.effects.single.type, EffectType.brightness);
      expect(restored.frames.single.layers.last.pixels, equals(original.frames.single.layers.last.pixels));
    });

    test('round-trips async isolate binary serialization (toBytesAsync / fromBytesAsync)', () async {
      final original = buildSampleProject();
      final bytes = await original.toBytesAsync();
      final restored = await Project.fromBytesAsync(bytes);
      expect(restored, equals(original));
    });

    test('preserves legacy toJson / fromJson serialization AND decodes legacy JSON bytes via fromBytes', () {
      final original = buildSampleProject();

      // 1. Direct toJson / fromJson
      final jsonMap = original.toJson();
      final fromJson = Project.fromJson(jsonMap);
      expect(fromJson, equals(original));

      // 2. Legacy UTF-8 JSON .pxv bytes decoded via Project.fromBytes
      final legacyJsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));
      expect(ProjectBinaryCodec.isBinaryFormat(legacyJsonBytes), isFalse);
      final fromLegacyBytes = Project.fromBytes(legacyJsonBytes);
      expect(fromLegacyBytes, equals(original));

      // 3. Legacy UTF-8 JSON with BOM
      final bomBytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...legacyJsonBytes]);
      expect(Project.fromBytes(bomBytes), equals(original));
    });

    test('decodes bundled legacy FriendlyRobot.pxv via both fromBytes and DropHandlerService', () async {
      final file = File('assets/data/FriendlyRobot.pxv');
      final rawBytes = await file.readAsBytes();
      expect(ProjectBinaryCodec.isBinaryFormat(rawBytes), isFalse);

      // Decode legacy JSON .pxv with Project.fromBytes
      final legacyProject = Project.fromBytes(rawBytes);
      expect(legacyProject.name, 'Friendly Robot');
      expect(legacyProject.width, 24);
      expect(legacyProject.height, 24);
      expect(legacyProject.frames, isNotEmpty);

      // Re-encode FriendlyRobot as PXV v2 binary and verify size reduction & exact fidelity
      final binaryBytes = legacyProject.toBytes();
      expect(ProjectBinaryCodec.isBinaryFormat(binaryBytes), isTrue);
      expect(binaryBytes.length, lessThan(rawBytes.length ~/ 3));

      final redecoded = Project.fromBytes(binaryBytes);
      expect(redecoded, equals(legacyProject));

      // Verify DropHandlerService handles both legacy JSON .pxv and new binary .pxv
      final dropLegacy = await DropHandlerService().processBytes('FriendlyRobot.pxv', rawBytes);
      expect(dropLegacy.isSuccess, isTrue);
      expect(dropLegacy.project, equals(legacyProject));

      final dropBinary = await DropHandlerService().processBytes('FriendlyRobot_v2.pxv', binaryBytes);
      expect(dropBinary.isSuccess, isTrue);
      expect(dropBinary.project, equals(legacyProject));
    });

    test('decodeStringOrBytes supports both raw JSON strings and base64-encoded binary PXV bytes', () {
      final original = buildSampleProject();

      final jsonStr = jsonEncode(original.toJson());
      expect(ProjectBinaryCodec.decodeStringOrBytes(jsonStr), equals(original));

      final base64Binary = base64Encode(original.toBytes());
      expect(ProjectBinaryCodec.decodeStringOrBytes(base64Binary), equals(original));
    });

    test('rejects empty, truncated, or unsupported version bytes with FormatException', () {
      expect(() => Project.fromBytes(Uint8List(0)), throwsFormatException);
      expect(() => Project.fromBytes(Uint8List.fromList([0x50, 0x58, 0x56, 0x99, 1, 2])), throwsFormatException);
      expect(() => Project.fromBytes(Uint8List.fromList([0x50, 0x58, 0x56, 0x02, 0xFF, 0x00])), throwsFormatException);
      expect(() => Project.fromBytes(Uint8List.fromList(utf8.encode('not json'))), throwsFormatException);
    });
  });
}
