import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

import '../effects/effect_animation_renderer.dart';
import '../effects/effects.dart';
import '../pixel_utils.dart';

class EffectIconAsset {
  const EffectIconAsset({
    required this.fileName,
    required this.bytes,
    required this.isAnimated,
  });

  final String fileName;
  final Uint8List bytes;
  final bool isAnimated;
}

class EffectIconArchiveResult {
  const EffectIconArchiveResult({
    required this.bytes,
    required this.exportedCount,
    required this.failures,
  });

  final Uint8List bytes;
  final int exportedCount;
  final Map<EffectType, String> failures;
}

/// Builds the image assets used by the effect picker.
///
/// Modifiers and overlays receive the same pixel-art smiley source. Generators
/// receive a transparent layer because they are responsible for every output
/// pixel themselves. Animated effects are exported as GIF; all others use JPG.
class EffectIconExportService {
  const EffectIconExportService();

  static const int canvasSize = 64;
  static const int defaultOutputSize = 256;
  static const int animationFrameCount = 12;
  static const int animationFps = 12;

  Uint32List sourcePixelsFor(Effect effect) {
    final descriptor = EffectCatalog.forType(effect.type);
    return descriptor.role == EffectRole.generator ? Uint32List(canvasSize * canvasSize) : buildSmileyPixels();
  }

  Future<Uint32List> renderPreview(
    Effect effect, {
    double progress = 0.35,
  }) async {
    final descriptor = EffectCatalog.forType(effect.type);
    final isAnimated = descriptor.isAnimated ||
        descriptor.workspace == EffectWorkspace.animation;
    final source = sourcePixelsFor(effect);
    if (!isAnimated) {
      return effect.apply(source, canvasSize, canvasSize);
    }

    return EffectAnimationRenderer.renderFrame(
      pixels: source,
      width: canvasSize,
      height: canvasSize,
      effects: [effect],
      animatedEffectIndex: 0,
      progress: progress,
    );
  }

  Future<List<Uint32List>> renderPreviewFrames(
    Effect effect, {
    int frameCount = animationFrameCount,
  }) async {
    final descriptor = EffectCatalog.forType(effect.type);
    final isAnimated = descriptor.isAnimated ||
        descriptor.workspace == EffectWorkspace.animation;
    final source = sourcePixelsFor(effect);
    if (!isAnimated) {
      final singleFrame = await effect.apply(source, canvasSize, canvasSize);
      return [singleFrame];
    }

    return Future.wait(
      List.generate(frameCount, (frame) {
        final progress = frame / frameCount;
        return EffectAnimationRenderer.renderFrame(
          pixels: Uint32List.fromList(source),
          width: canvasSize,
          height: canvasSize,
          effects: [effect],
          animatedEffectIndex: 0,
          progress: progress,
        );
      }),
    );
  }

  Future<EffectIconAsset> buildAsset(
    Effect effect, {
    int outputSize = defaultOutputSize,
  }) async {
    final descriptor = EffectCatalog.forType(effect.type);
    if (descriptor.isAnimated) {
      return _buildGif(effect, outputSize: outputSize);
    }
    return _buildJpg(effect, outputSize: outputSize);
  }

  Future<EffectIconArchiveResult> buildArchive(
    Iterable<Effect> effects, {
    int outputSize = defaultOutputSize,
    void Function(int completed, int total)? onProgress,
  }) async {
    final requested = effects.toList(growable: false);
    final archive = Archive();
    final failures = <EffectType, String>{};
    var exportedCount = 0;

    for (var index = 0; index < requested.length; index++) {
      final effect = requested[index];
      try {
        final asset = await buildAsset(effect, outputSize: outputSize);
        final workspace = EffectCatalog.forType(effect.type).workspace.name;
        archive.addFile(
          ArchiveFile.bytes('$workspace/${asset.fileName}', asset.bytes),
        );
        exportedCount++;
      } catch (error) {
        failures[effect.type] = error.toString();
      }
      onProgress?.call(index + 1, requested.length);
    }

    if (failures.isNotEmpty) {
      final report = failures.entries.map((entry) => '${entry.key.name}: ${entry.value}').join('\n');
      archive.addFile(
        ArchiveFile.string('export-errors.txt', report),
      );
    }

    final manifest = <String, Object>{
      'canvasSize': canvasSize,
      'outputSize': outputSize,
      'animationFrames': animationFrameCount,
      'animationFps': animationFps,
      'exported': exportedCount,
      'failed': failures.length,
    };
    archive.addFile(
      ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest),
      ),
    );

    return EffectIconArchiveResult(
      bytes: ZipEncoder().encodeBytes(archive),
      exportedCount: exportedCount,
      failures: Map.unmodifiable(failures),
    );
  }

  Future<EffectIconAsset> _buildJpg(
    Effect effect, {
    required int outputSize,
  }) async {
    final pixels = await renderPreview(effect);
    var image = PixelUtils.imageFromAarrggbb(
      pixels,
      canvasSize,
      canvasSize,
    );
    image = PixelUtils.compositeOnMatte(image);
    if (outputSize != canvasSize) {
      image = img.copyResize(
        image,
        width: outputSize,
        height: outputSize,
        interpolation: img.Interpolation.nearest,
      );
    }
    return EffectIconAsset(
      fileName: '${effect.type.name}.jpg',
      bytes: Uint8List.fromList(img.encodeJpg(image, quality: 92)),
      isAnimated: false,
    );
  }

  Future<EffectIconAsset> _buildGif(
    Effect effect, {
    required int outputSize,
  }) async {
    final source = sourcePixelsFor(effect);
    final encoder = img.GifEncoder(
      delay: (100 / animationFps).round(),
      repeat: 0,
    );

    for (var frame = 0; frame < animationFrameCount; frame++) {
      final progress = frame / animationFrameCount;
      final pixels = await EffectAnimationRenderer.renderFrame(
        pixels: source,
        width: canvasSize,
        height: canvasSize,
        effects: [effect],
        animatedEffectIndex: 0,
        progress: progress,
      );
      var image = PixelUtils.imageFromAarrggbb(
        pixels,
        canvasSize,
        canvasSize,
        hardAlphaForGif: true,
      );
      if (outputSize != canvasSize) {
        image = img.copyResize(
          image,
          width: outputSize,
          height: outputSize,
          interpolation: img.Interpolation.nearest,
        );
      }
      encoder.addFrame(image);
    }

    return EffectIconAsset(
      fileName: '${effect.type.name}.gif',
      bytes: encoder.finish()!,
      isAnimated: true,
    );
  }

  static Uint32List buildSmileyPixels() {
    final pixels = Uint32List(canvasSize * canvasSize);
    const center = (canvasSize - 1) / 2;

    for (var y = 0; y < canvasSize; y++) {
      for (var x = 0; x < canvasSize; x++) {
        final dx = x - center;
        final dy = y - center;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared <= 25 * 25) {
          pixels[y * canvasSize + x] = distanceSquared >= 23 * 23 ? 0xFF5A3513 : (y < 25 ? 0xFFFFD84A : 0xFFFFC928);
        }
      }
    }

    void fillRect(int left, int top, int right, int bottom, int color) {
      for (var y = top; y <= bottom; y++) {
        for (var x = left; x <= right; x++) {
          pixels[y * canvasSize + x] = color;
        }
      }
    }

    fillRect(21, 23, 25, 30, 0xFF3B2414);
    fillRect(39, 23, 43, 30, 0xFF3B2414);
    fillRect(22, 23, 23, 25, 0xFFFFFFFF);
    fillRect(40, 23, 41, 25, 0xFFFFFFFF);

    for (var x = 25; x <= 39; x++) {
      final normalized = (x - 32).abs() / 12;
      final y = 39 - (normalized * normalized * 7).round();
      fillRect(x, y, x, y + 2, 0xFF5A2418);
    }
    // fillRect(24, 44, 40, 46, 0xFF5A2418);

    return pixels;
  }
}
