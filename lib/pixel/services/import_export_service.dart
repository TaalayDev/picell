import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core.dart';
import '../../data.dart';
import '../../gifencoder/gifencoder.dart' as gifencoder;

const _kGifFps = 10;

class ImportExportService {
  Future<void> exportProjectAsJson({
    required BuildContext context,
    required Project project,
  }) async {
    final json = project.toJson();
    final jsonString = jsonEncode(json);
    await FileUtils(context).save('${project.name}.pxv', jsonString);
  }

  Future<void> exportImage({
    required BuildContext context,
    required Project project,
    required List<Layer> layers,
    required bool withBackground,
    double? exportWidth,
    double? exportHeight,
  }) async {
    final pixels = PixelUtils.mergeLayersPixels(
      width: project.width,
      height: project.height,
      layers: layers,
    );

    if (withBackground) {
      for (int i = 0; i < pixels.length; i++) {
        if (pixels[i] == 0) {
          pixels[i] = Colors.white.value;
        }
      }
    }

    await FileUtils(context).save32Bit(
      pixels,
      project.width,
      project.height,
      exportWidth: exportWidth,
      exportHeight: exportHeight,
    );
  }

  Future<void> exportAnimation({
    required BuildContext context,
    required Project project,
    required List<AnimationFrame> frames,
    required bool withBackground,
    double? exportWidth,
    double? exportHeight,
  }) async {
    final wantTransparent = !withBackground;

    final outputWidth = exportWidth?.toInt() ?? project.width;
    final outputHeight = exportHeight?.toInt() ?? project.height;
    final needsResize = outputWidth != project.width || outputHeight != project.height;

    final gb = gifencoder.GifBuffer(outputWidth, outputHeight);

    for (final frame in frames) {
      var pixelsAARRGGBB = PixelUtils.mergeLayersPixels(
        width: project.width,
        height: project.height,
        layers: frame.layers,
      );

      Uint32List framePixels;
      if (wantTransparent) {
        // Snap alpha and set RGB to 0 for transparent to avoid fringes
        final snapped = Uint32List.fromList(pixelsAARRGGBB);
        for (int i = 0; i < snapped.length; i++) {
          final pixel = snapped[i];
          final a = (pixel >> 24) & 0xFF;
          if (a < 128) {
            snapped[i] = 0;
          } else {
            // Unpremultiply if needed
            if (a < 255) {
              final scale = 255.0 / a;
              int r = (((pixel >> 16) & 0xFF) * scale).round().clamp(0, 255);
              int g = (((pixel >> 8) & 0xFF) * scale).round().clamp(0, 255);
              int b = ((pixel & 0xFF) * scale).round().clamp(0, 255);
              snapped[i] = (255 << 24) | (r << 16) | (g << 8) | b;
            }
          }
        }
        framePixels = snapped;
      } else {
        // Blend with white for non-transparent background
        final forced = Uint32List.fromList(pixelsAARRGGBB);
        for (int i = 0; i < forced.length; i++) {
          final pixel = forced[i];
          final a = (pixel >> 24) & 0xFF;
          int r = ((pixel >> 16) & 0xFF) + 255 - a;
          int g = ((pixel >> 8) & 0xFF) + 255 - a;
          int b = (pixel & 0xFF) + 255 - a;
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);
          forced[i] = (255 << 24) | (r << 16) | (g << 8) | b;
        }
        framePixels = forced;
      }

      if (needsResize) {
        framePixels = PixelUtils.resizeWithImagePackage(
          framePixels,
          project.width,
          project.height,
          outputWidth,
          outputHeight,
          interpolation: img.Interpolation.nearest,
        );
      }

      final rgba = PixelUtils.aarrggbbToRgbaForGif(framePixels);

      gb.add(rgba);
    }

    final data = Uint8List.fromList(gb.build(_kGifFps));

    await FileUtils(context).saveImage(data, '${project.name}.gif');
  }

  Future<void> shareProject({
    required BuildContext context,
    required Project project,
    required List<Layer> layers,
  }) async {
    final pixels = PixelUtils.mergeLayersPixels(
      width: project.width,
      height: project.height,
      layers: layers,
    );

    await Share.shareXFiles([
      XFile.fromData(
        ImageHelper.convertToBytes(pixels),
        name: '${project.name}.png',
        mimeType: 'image/png',
      ),
    ]);
  }

  Future<Uint8List> importImageBytes({
    required BuildContext context,
    required int width,
    required int height,
  }) async {
    final img.Image? pickedImage = await FileUtils(context).pickImageFile();
    if (pickedImage == null) return Uint8List(0);

    // Resize to canvas size using area-average downscale for accuracy
    img.Image resized = pickedImage;
    if (pickedImage.width != width || pickedImage.height != height) {
      resized = img.copyResize(
        pickedImage,
        width: width,
        height: height,
        interpolation: img.Interpolation.average,
      );
    }

    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Imports an image file and converts it to a pixel-art [Layer].
  ///
  /// Uses area-average downscaling for accurate colour sampling, followed by
  /// optional median-cut colour quantization and dithering as specified by
  /// [options].
  Future<Layer?> importImageAsLayer({
    required BuildContext context,
    required int width,
    required int height,
    String? layerName,
    PixelArtConversionOptions options = const PixelArtConversionOptions(),
  }) async {
    final img.Image? pickedImage = await FileUtils(context).pickImageFile();
    if (pickedImage == null) return null;

    final pixels = PixelArtConverter.convert(
      source: pickedImage,
      targetWidth: width,
      targetHeight: height,
      options: options,
    );

    return Layer(
      layerId: 0,
      id: const Uuid().v4(),
      name: layerName ?? 'Imported Image',
      pixels: pixels,
      isVisible: true,
      order: 0,
    );
  }

  Future<Uint8List?> importImageAsBackground({
    required BuildContext context,
  }) async {
    final img.Image? pickedImage = await FileUtils(context).pickImageFile();
    if (pickedImage == null) return null;

    return Uint8List.fromList(img.encodePng(pickedImage));
  }

  Future<Project?> importProject({
    required BuildContext context,
  }) async {
    try {
      final contents = await FileUtils(context).readProjectFileContents();
      if (contents == null) return null;

      final projectData = jsonDecode(contents);
      return Project.fromJson(projectData);
    } catch (e) {
      debugPrint('Error importing project: $e');
      return null;
    }
  }

  Map<String, dynamic> createSpriteSheetMetadata({
    required List<AnimationFrame> frames,
    required int columns,
    required int frameWidth,
    required int frameHeight,
    required int spacing,
  }) {
    return {
      'version': '1.0',
      'frames': frames.length,
      'columns': columns,
      'frameWidth': frameWidth,
      'frameHeight': frameHeight,
      'spacing': spacing,
      'frameData': frames
          .map((frame) => {
                'name': frame.name,
                'duration': frame.duration,
              })
          .toList(),
    };
  }

  Future<void> exportSpriteSheet({
    required BuildContext context,
    required Project project,
    required List<AnimationFrame> frames,
    required int columns,
    required int spacing,
    required bool includeAllFrames,
    bool withBackground = false,
    Color backgroundColor = Colors.white,
    double? exportWidth,
    double? exportHeight,
  }) async {
    // Calculate sprite sheet dimensions
    final framesToUse = includeAllFrames ? frames : [frames.first];
    final rows = (framesToUse.length / columns).ceil();

    // Calculate total dimensions including spacing
    final totalWidth = (project.width * columns) + (spacing * (columns - 1));
    final totalHeight = (project.height * rows) + (spacing * (rows - 1));

    // Create sprite sheet image
    var spriteSheet = img.Image(
      width: totalWidth,
      height: totalHeight,
      numChannels: 4,
    );

    // Fill background if needed
    if (withBackground) {
      for (int y = 0; y < totalHeight; y++) {
        for (int x = 0; x < totalWidth; x++) {
          spriteSheet.setPixelRgba(
            x,
            y,
            backgroundColor.red,
            backgroundColor.green,
            backgroundColor.blue,
            backgroundColor.alpha,
          );
        }
      }
    }

    // Draw each frame onto the sprite sheet
    for (int i = 0; i < framesToUse.length; i++) {
      final frame = framesToUse[i];
      final row = i ~/ columns;
      final col = i % columns;

      // Calculate position for this frame
      final xOffset = col * (project.width + spacing);
      final yOffset = row * (project.height + spacing);

      // Merge layers for this frame
      final framePixels = PixelUtils.mergeLayersPixels(
        width: project.width,
        height: project.height,
        layers: frame.layers,
      );

      // Draw frame pixels onto sprite sheet
      for (int y = 0; y < project.height; y++) {
        for (int x = 0; x < project.width; x++) {
          final pixel = framePixels[y * project.width + x];

          // Skip transparent pixels if we're using a background
          if (pixel == 0 && withBackground) continue;

          // Extract ARGB channels
          final a = (pixel >> 24) & 0xFF;
          final r = (pixel >> 16) & 0xFF;
          final g = (pixel >> 8) & 0xFF;
          final b = pixel & 0xFF;

          // Set pixel in sprite sheet
          if (a > 0) {
            spriteSheet.setPixelRgba(
              x + xOffset,
              y + yOffset,
              r,
              g,
              b,
              a,
            );
          }
        }
      }
    }

    if (exportWidth != null && exportHeight != null) {
      final resizedTotalWidth = (exportWidth * columns) + (spacing * (columns - 1));
      final resizedTotalHeight = (exportHeight * rows) + (spacing * (rows - 1));

      spriteSheet = img.copyResize(
        spriteSheet,
        width: resizedTotalWidth.toInt(),
        height: resizedTotalHeight.toInt(),
      );
    }

    // Save sprite sheet image
    final pngData = img.encodePng(spriteSheet);
    await FileUtils(context).saveImage(
      pngData,
      '${project.name}_sprite_sheet.png',
    );
  }
}
