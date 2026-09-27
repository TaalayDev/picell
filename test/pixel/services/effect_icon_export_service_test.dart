import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/services/effect_icon_export_service.dart';

void main() {
  const service = EffectIconExportService();

  test('uses a smiley source except for generators', () {
    final smiley = service.sourcePixelsFor(BrightnessEffect());
    final generator = service.sourcePixelsFor(MountainRangeEffect());

    expect(smiley.any((pixel) => pixel != 0), isTrue);
    expect(generator.every((pixel) => pixel == 0), isTrue);
  });

  test('exports static effects as JPEG', () async {
    final asset = await service.buildAsset(
      BrightnessEffect(),
      outputSize: 64,
    );

    expect(asset.fileName, 'brightness.jpg');
    expect(asset.isAnimated, isFalse);
    expect(img.decodeJpg(asset.bytes), isNotNull);
  });

  test('exports animated effects as GIF', () async {
    final asset = await service.buildAsset(
      PulseEffect(),
      outputSize: 64,
    );

    expect(asset.fileName, 'pulse.gif');
    expect(asset.isAnimated, isTrue);
    expect(asset.bytes.sublist(0, 6), [71, 73, 70, 56, 57, 97]);
    expect(img.decodeGif(asset.bytes)?.numFrames, 12);
  });

  test('bulk export groups assets in a zip archive', () async {
    final result = await service.buildArchive(
      [BrightnessEffect(), PulseEffect()],
      outputSize: 64,
    );
    final archive = ZipDecoder().decodeBytes(result.bytes);

    expect(result.exportedCount, 2);
    expect(result.failures, isEmpty);
    expect(
      archive.files.map((file) => file.name),
      containsAll([
        'filters/brightness.jpg',
        'animation/pulse.gif',
        'manifest.json',
      ]),
    );
  });

  test(
    'bulk export renders the complete effect catalog',
    () async {
      final result = await service.buildArchive(
        [
          for (final type in EffectType.values)
            EffectsManager.createEffect(type),
        ],
        outputSize: 64,
      );

      expect(result.failures, isEmpty);
      expect(result.exportedCount, EffectType.values.length);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
