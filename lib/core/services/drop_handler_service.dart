import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../data/models/animation_frame_model.dart';
import '../../data/models/layer.dart';
import '../../data/models/project_model.dart';
import 'aseprite_parser.dart';

/// Simple wrapper for dropped files
class DroppedFile {
  final String path;
  final String name;

  DroppedFile(this.path) : name = path.split(Platform.pathSeparator).last;

  Future<Uint8List> readAsBytes() async {
    return File(path).readAsBytes();
  }
}

/// Types of files that can be dropped
enum DroppedFileType {
  image,
  aseprite,
  project,
  unknown,
}

/// Result of processing a dropped file
class DroppedFileResult {
  final DroppedFileType type;
  final Project? project;
  final Layer? layer;
  final img.Image? image;
  final String? errorMessage;
  final String fileName;

  DroppedFileResult({
    required this.type,
    required this.fileName,
    this.project,
    this.layer,
    this.image,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
  bool get hasProject => project != null;
  bool get hasLayer => layer != null;
  bool get hasImage => image != null;
}

/// Service for handling dropped files in PixelVerse
class DropHandlerService {
  static final DropHandlerService _instance = DropHandlerService._internal();
  factory DropHandlerService() => _instance;
  DropHandlerService._internal();

  final AsepriteParser _asepriteParser = AsepriteParser();

  /// Supported image extensions
  static const List<String> imageExtensions = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
  ];

  /// Supported Aseprite extensions
  static const List<String> asepriteExtensions = ['ase', 'aseprite'];

  /// Project file extension
  static const String projectExtension = 'pxv';

  /// Determine the type of a dropped file based on its extension
  DroppedFileType getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();

    if (imageExtensions.contains(extension)) {
      return DroppedFileType.image;
    } else if (asepriteExtensions.contains(extension)) {
      return DroppedFileType.aseprite;
    } else if (extension == projectExtension) {
      return DroppedFileType.project;
    }

    return DroppedFileType.unknown;
  }

  /// Process a single dropped file from path
  Future<DroppedFileResult> processDroppedFile(String filePath) async {
    final file = DroppedFile(filePath);
    final fileName = file.name;
    final fileType = getFileType(fileName);

    try {
      final bytes = await file.readAsBytes();

      switch (fileType) {
        case DroppedFileType.image:
          return await _processImageFile(bytes, fileName);
        case DroppedFileType.aseprite:
          return await _processAsepriteFile(bytes, fileName);
        case DroppedFileType.project:
          return await _processProjectFile(bytes, fileName);
        case DroppedFileType.unknown:
          return DroppedFileResult(
            type: DroppedFileType.unknown,
            fileName: fileName,
            errorMessage: 'Unsupported file type',
          );
      }
    } catch (e) {
      debugPrint('Error processing dropped file: $e');
      return DroppedFileResult(
        type: fileType,
        fileName: fileName,
        errorMessage: 'Failed to process file: $e',
      );
    }
  }

  /// Process multiple dropped files from paths
  Future<List<DroppedFileResult>> processDroppedFiles(List<String> filePaths) async {
    final results = <DroppedFileResult>[];
    for (final path in filePaths) {
      results.add(await processDroppedFile(path));
    }
    return results;
  }

  /// Process an image file and return as a decoded image
  Future<DroppedFileResult> _processImageFile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        return DroppedFileResult(
          type: DroppedFileType.image,
          fileName: fileName,
          errorMessage: 'Could not decode image',
        );
      }

      return DroppedFileResult(
        type: DroppedFileType.image,
        fileName: fileName,
        image: image,
      );
    } catch (e) {
      return DroppedFileResult(
        type: DroppedFileType.image,
        fileName: fileName,
        errorMessage: 'Failed to decode image: $e',
      );
    }
  }

  /// Process an Aseprite file and convert to a Project
  Future<DroppedFileResult> _processAsepriteFile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final aseFile = _asepriteParser.parse(bytes);
      if (aseFile == null) {
        return DroppedFileResult(
          type: DroppedFileType.aseprite,
          fileName: fileName,
          errorMessage: 'Could not parse Aseprite file',
        );
      }

      final project = _convertAsepriteToProject(aseFile, fileName);
      return DroppedFileResult(
        type: DroppedFileType.aseprite,
        fileName: fileName,
        project: project,
      );
    } catch (e) {
      return DroppedFileResult(
        type: DroppedFileType.aseprite,
        fileName: fileName,
        errorMessage: 'Failed to process Aseprite file: $e',
      );
    }
  }

  /// Process a .pxv project file
  Future<DroppedFileResult> _processProjectFile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final jsonString = String.fromCharCodes(bytes);
      final jsonData = _parseJson(jsonString);
      if (jsonData == null) {
        return DroppedFileResult(
          type: DroppedFileType.project,
          fileName: fileName,
          errorMessage: 'Invalid project file format',
        );
      }

      final project = Project.fromJson(jsonData);
      return DroppedFileResult(
        type: DroppedFileType.project,
        fileName: fileName,
        project: project,
      );
    } catch (e) {
      return DroppedFileResult(
        type: DroppedFileType.project,
        fileName: fileName,
        errorMessage: 'Failed to parse project file: $e',
      );
    }
  }

  /// Convert an Aseprite file to a PixelVerse Project
  Project _convertAsepriteToProject(AsepriteFile aseFile, String fileName) {
    final projectName = fileName.replaceAll(RegExp(r'\.(ase|aseprite)$', caseSensitive: false), '');

    final frames = <AnimationFrame>[];
    final states = <AnimationStateModel>[
      const AnimationStateModel(
        id: 0,
        name: 'Animation',
        frameRate: 24,
      ),
    ];

    // Convert each Aseprite frame to PixelVerse AnimationFrame
    for (int frameIndex = 0; frameIndex < aseFile.frames.length; frameIndex++) {
      final aseFrame = aseFile.frames[frameIndex];
      final layers = <Layer>[];

      // Create a full-size pixel buffer for each layer
      for (int layerIndex = 0; layerIndex < aseFile.layers.length; layerIndex++) {
        final aseLayer = aseFile.layers[layerIndex];
        final pixels = Uint32List(aseFile.width * aseFile.height);

        // Find cel for this layer in this frame
        final cel = aseFrame.cels.where((c) => c.layerIndex == layerIndex).firstOrNull;

        if (cel != null) {
          // Copy cel pixels to the correct position in the layer
          for (int y = 0; y < cel.height; y++) {
            for (int x = 0; x < cel.width; x++) {
              final destX = cel.x + x;
              final destY = cel.y + y;

              if (destX >= 0 && destX < aseFile.width && destY >= 0 && destY < aseFile.height) {
                final srcIndex = y * cel.width + x;
                final destIndex = destY * aseFile.width + destX;
                pixels[destIndex] = cel.pixels[srcIndex];
              }
            }
          }
        }

        layers.add(Layer(
          layerId: layerIndex,
          id: const Uuid().v4(),
          name: aseLayer.name,
          pixels: pixels,
          isVisible: aseLayer.isVisible,
          opacity: aseLayer.opacity,
          order: layerIndex,
        ));
      }

      // Ensure at least one layer exists
      if (layers.isEmpty) {
        layers.add(Layer(
          layerId: 0,
          id: const Uuid().v4(),
          name: 'Layer 1',
          pixels: Uint32List(aseFile.width * aseFile.height),
          order: 0,
        ));
      }

      frames.add(AnimationFrame(
        id: frameIndex,
        stateId: 0,
        name: 'Frame ${frameIndex + 1}',
        duration: aseFrame.duration,
        layers: layers,
      ));
    }

    // Ensure at least one frame exists
    if (frames.isEmpty) {
      frames.add(AnimationFrame(
        id: 0,
        stateId: 0,
        name: 'Frame 1',
        duration: 100,
        layers: [
          Layer(
            layerId: 0,
            id: const Uuid().v4(),
            name: 'Layer 1',
            pixels: Uint32List(aseFile.width * aseFile.height),
            order: 0,
          ),
        ],
      ));
    }

    return Project(
      id: 0,
      name: projectName,
      width: aseFile.width,
      height: aseFile.height,
      frames: frames,
      states: states,
      createdAt: DateTime.now(),
      editedAt: DateTime.now(),
    );
  }

  /// Convert an image to a Layer
  Layer imageToLayer(
    img.Image image,
    int canvasWidth,
    int canvasHeight, {
    String layerName = 'Imported Image',
  }) {
    // Resize image if needed
    img.Image resized = image;
    if (image.width != canvasWidth || image.height != canvasHeight) {
      resized = img.copyResize(
        image,
        width: canvasWidth,
        height: canvasHeight,
        interpolation: img.Interpolation.nearest,
      );
    }

    // Convert to pixel array
    final pixels = Uint32List(canvasWidth * canvasHeight);
    for (int y = 0; y < canvasHeight; y++) {
      for (int x = 0; x < canvasWidth; x++) {
        final pixel = resized.getPixel(x, y);
        final a = pixel.a.toInt();
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        pixels[y * canvasWidth + x] = (a << 24) | (r << 16) | (g << 8) | b;
      }
    }

    return Layer(
      layerId: 0,
      id: const Uuid().v4(),
      name: layerName,
      pixels: pixels,
      order: 0,
    );
  }

  /// Convert an image to a Project
  Project imageToProject(img.Image image, String fileName) {
    final projectName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final pixels = Uint32List(image.width * image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final a = pixel.a.toInt();
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        pixels[y * image.width + x] = (a << 24) | (r << 16) | (g << 8) | b;
      }
    }

    return Project(
      id: 0,
      name: projectName,
      width: image.width,
      height: image.height,
      frames: [
        AnimationFrame(
          id: 0,
          stateId: 0,
          name: 'Frame 1',
          duration: 100,
          layers: [
            Layer(
              layerId: 0,
              id: const Uuid().v4(),
              name: 'Layer 1',
              pixels: pixels,
              order: 0,
            ),
          ],
        ),
      ],
      states: const [
        AnimationStateModel(
          id: 0,
          name: 'Animation',
          frameRate: 24,
        ),
      ],
      createdAt: DateTime.now(),
      editedAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? _parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
