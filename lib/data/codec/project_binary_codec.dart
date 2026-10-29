import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../models/animation_frame_model.dart';
import '../models/layer.dart';
import '../models/project_model.dart';

/// Top-level isolate entry points for [compute].
Uint8List _encodeProjectBytesIsolate(Project project) => ProjectBinaryCodec.encodeSync(project);
Project _decodeProjectBytesIsolate(Uint8List bytes) => ProjectBinaryCodec.decodeSync(bytes);

/// Versioned binary codec (`PXV\x02`) for `.pxv` project files with automatic
/// fallback to legacy UTF-8 JSON `.pxv` project files.
///
/// Binary layout:
/// - Bytes `0..3`: Magic header `'PXV\x02'` (`0x50, 0x58, 0x56, 0x02`)
/// - Bytes `4..end`: ZLib-compressed payload containing:
///   - `uint32` little-endian manifest byte length `M`
///   - `M` bytes of UTF-8 JSON manifest (project metadata, states, frames,
///     and layer descriptors referencing byte offsets in the blob section)
///   - Contiguous binary blob section (thumbnail `Uint8List` + little-endian
///     `Uint32List` layer pixel buffers)
class ProjectBinaryCodec {
  const ProjectBinaryCodec._();

  /// Magic header `'PXV\x02'`.
  static const List<int> magic = [0x50, 0x58, 0x56, 0x02];

  /// Returns true if [bytes] begins with the `'PXV\x02'` binary header.
  static bool isBinaryFormat(Uint8List bytes) {
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  /// Encodes [project] into a compressed `PXV\x02` binary buffer in a
  /// background isolate.
  static Future<Uint8List> encode(Project project) => compute(_encodeProjectBytesIsolate, project);

  /// Decodes a [Project] from either `PXV\x02` binary bytes or legacy UTF-8
  /// JSON `.pxv` bytes in a background isolate.
  static Future<Project> decode(Uint8List bytes) => compute(_decodeProjectBytesIsolate, bytes);

  /// Synchronously encodes [project] into `PXV\x02` binary bytes.
  static Uint8List encodeSync(Project project) {
    // Calculate total blob size: thumbnail bytes + 4 bytes per pixel for each layer.
    var totalBlobBytes = project.thumbnail?.length ?? 0;
    for (final frame in project.frames) {
      for (final layer in frame.layers) {
        totalBlobBytes += layer.pixels.length * 4;
      }
    }

    final blobBuffer = Uint8List(totalBlobBytes);
    final blobData = ByteData.sublistView(blobBuffer);
    var cursor = 0;

    Map<String, int>? thumbnailBlob;
    if (project.thumbnail != null) {
      final thumb = project.thumbnail!;
      blobBuffer.setRange(cursor, cursor + thumb.length, thumb);
      thumbnailBlob = {'offset': cursor, 'length': thumb.length};
      cursor += thumb.length;
    }

    final framesJson = <Map<String, dynamic>>[];
    for (final frame in project.frames) {
      final layersJson = <Map<String, dynamic>>[];
      for (final layer in frame.layers) {
        final pixels = layer.pixels;
        final byteLength = pixels.length * 4;
        final offset = cursor;
        for (var i = 0; i < pixels.length; i++) {
          blobData.setUint32(offset + i * 4, pixels[i], Endian.little);
        }
        cursor += byteLength;
        layersJson.add(layer.toManifestJson(pixelOffset: offset, pixelByteLength: byteLength));
      }
      framesJson.add({
        'id': frame.id,
        'name': frame.name,
        'stateId': frame.stateId,
        'layers': layersJson,
        'duration': frame.duration,
        'createdAt': frame.createdAt.millisecondsSinceEpoch,
        'editedAt': frame.editedAt.millisecondsSinceEpoch,
        'order': frame.order,
      });
    }

    final manifestMap = <String, dynamic>{
      'formatVersion': 2,
      'id': project.id,
      'name': project.name,
      'width': project.width,
      'height': project.height,
      'type': project.type.name,
      'tileWidth': project.tileWidth,
      'tileHeight': project.tileHeight,
      'gridColumns': project.gridColumns,
      'gridRows': project.gridRows,
      'tilemapData': project.tilemapData,
      if (project.tilesetData != null) 'tilesetData': project.tilesetData,
      if (project.rigData != null) 'rigData': project.rigData,
      'states': [for (final state in project.states) state.toJson()],
      'frames': framesJson,
      'thumbnailBlob': thumbnailBlob,
      'isCloudSynced': project.isCloudSynced,
      'remoteId': project.remoteId,
      'forkedFromId': project.forkedFromId,
      'selectedFrameId': project.selectedFrameId,
      'selectedLayerId': project.selectedLayerId,
      'createdAt': project.createdAt.millisecondsSinceEpoch,
      'editedAt': project.editedAt.millisecondsSinceEpoch,
    };

    final manifestBytes = utf8.encode(jsonEncode(manifestMap));
    final uncompressed = Uint8List(4 + manifestBytes.length + blobBuffer.length);
    ByteData.sublistView(uncompressed, 0, 4).setUint32(0, manifestBytes.length, Endian.little);
    uncompressed.setRange(4, 4 + manifestBytes.length, manifestBytes);
    uncompressed.setRange(4 + manifestBytes.length, uncompressed.length, blobBuffer);

    final compressed = const ZLibEncoder().encodeBytes(uncompressed);
    final result = Uint8List(magic.length + compressed.length);
    result.setRange(0, magic.length, magic);
    result.setRange(magic.length, result.length, compressed);
    return result;
  }

  /// Synchronously decodes a [Project] from either `PXV\x02` binary bytes or
  /// legacy UTF-8 JSON `.pxv` bytes.
  static Project decodeSync(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('Empty project file');
    }
    if (isBinaryFormat(bytes)) {
      return _decodeBinaryV2(bytes);
    }
    // Check for unsupported future binary versions starting with 'PXV'
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x58 && bytes[2] == 0x56) {
      throw FormatException('Unsupported binary .pxv version: ${bytes[3]}');
    }
    return _decodeLegacyJson(bytes);
  }

  /// Decodes a string or byte payload that may be raw JSON or base64-encoded
  /// `PXV\x02` binary data.
  static Project decodeStringOrBytes(String raw) {
    final trimmed = raw.trimLeft();
    if (trimmed.startsWith('{')) {
      final json = jsonDecode(trimmed);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid project JSON root');
      }
      return Project.fromJson(json);
    }
    try {
      final bytes = base64Decode(raw.trim());
      return decodeSync(bytes);
    } catch (_) {
      final bytes = Uint8List.fromList(utf8.encode(raw));
      return decodeSync(bytes);
    }
  }

  static Project _decodeBinaryV2(Uint8List bytes) {
    final Uint8List decompressed;
    try {
      final compressedSlice = Uint8List.sublistView(bytes, magic.length);
      decompressed = const ZLibDecoder().decodeBytes(compressedSlice);
    } catch (e) {
      throw FormatException('Corrupted PXV binary payload: $e');
    }

    if (decompressed.length < 4) {
      throw const FormatException('Truncated PXV binary payload');
    }

    final manifestLength = ByteData.sublistView(decompressed, 0, 4).getUint32(0, Endian.little);
    if (manifestLength < 2 || 4 + manifestLength > decompressed.length) {
      throw const FormatException('Invalid PXV manifest length');
    }

    final Map<String, dynamic> manifest;
    try {
      final manifestStr = utf8.decode(Uint8List.sublistView(decompressed, 4, 4 + manifestLength));
      final decoded = jsonDecode(manifestStr);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Manifest is not a JSON object');
      }
      manifest = decoded;
    } catch (e) {
      throw FormatException('Invalid PXV manifest JSON: $e');
    }

    final blobStart = 4 + manifestLength;
    final blobBuffer = Uint8List.sublistView(decompressed, blobStart);
    final blobData = ByteData.sublistView(blobBuffer);

    Uint8List? thumbnail;
    final thumbMeta = manifest['thumbnailBlob'];
    if (thumbMeta is Map<String, dynamic>) {
      final offset = thumbMeta['offset'] as int;
      final length = thumbMeta['length'] as int;
      if (offset < 0 || length < 0 || offset + length > blobBuffer.length) {
        throw const FormatException('Invalid thumbnail blob bounds in PXV file');
      }
      thumbnail = Uint8List.fromList(Uint8List.sublistView(blobBuffer, offset, offset + length));
    } else if (manifest['thumbnail'] is List) {
      thumbnail = Uint8List.fromList((manifest['thumbnail'] as List).cast<int>());
    }

    final framesRaw = manifest['frames'] as List? ?? const [];
    final frames = <AnimationFrame>[];
    for (final frameRaw in framesRaw) {
      final frameMap = frameRaw as Map<String, dynamic>;
      final layersRaw = frameMap['layers'] as List? ?? const [];
      final layers = <Layer>[];
      for (final layerRaw in layersRaw) {
        final layerMap = layerRaw as Map<String, dynamic>;
        final pixelsMeta = layerMap['pixelsBlob'];
        late final Uint32List pixels;
        if (pixelsMeta is Map<String, dynamic>) {
          final offset = pixelsMeta['offset'] as int;
          final byteLength = pixelsMeta['byteLength'] as int;
          if (offset < 0 || byteLength < 0 || byteLength % 4 != 0 || offset + byteLength > blobBuffer.length) {
            throw const FormatException('Invalid layer pixel blob bounds in PXV file');
          }
          final count = byteLength ~/ 4;
          pixels = Uint32List(count);
          for (var i = 0; i < count; i++) {
            pixels[i] = blobData.getUint32(offset + i * 4, Endian.little);
          }
        } else if (layerMap['pixels'] is List) {
          pixels = Uint32List.fromList((layerMap['pixels'] as List).cast<int>());
        } else {
          throw const FormatException('Layer missing pixel data in PXV file');
        }
        layers.add(Layer.fromManifestJson(layerMap, pixels));
      }
      frames.add(AnimationFrame(
        id: frameMap['id'] as int,
        name: frameMap['name'] as String,
        stateId: frameMap['stateId'] as int,
        layers: layers,
        duration: frameMap['duration'] as int,
        order: frameMap['order'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(frameMap['createdAt'] as int),
        editedAt: DateTime.fromMillisecondsSinceEpoch(frameMap['editedAt'] as int),
      ));
    }

    final statesRaw = manifest['states'] as List? ?? const [];
    final states = [
      for (final stateRaw in statesRaw) AnimationStateModel.fromJson(stateRaw as Map<String, dynamic>),
    ];

    return Project(
      id: manifest['id'] as int,
      name: manifest['name'] as String,
      width: manifest['width'] as int,
      height: manifest['height'] as int,
      type: manifest['type'] != null
          ? ProjectType.values.firstWhere(
              (e) => e.name == manifest['type'],
              orElse: () => ProjectType.pixelArt,
            )
          : ProjectType.pixelArt,
      tileWidth: manifest['tileWidth'] as int?,
      tileHeight: manifest['tileHeight'] as int?,
      gridColumns: manifest['gridColumns'] as int?,
      gridRows: manifest['gridRows'] as int?,
      tilemapData: manifest['tilemapData'] as String?,
      rigData: manifest['rigData'] as String?,
      tilesetData: manifest['tilesetData'] as String?,
      states: states,
      frames: frames,
      isCloudSynced: manifest['isCloudSynced'] as bool? ?? false,
      remoteId: manifest['remoteId'] as int?,
      forkedFromId: manifest['forkedFromId'] as int?,
      selectedFrameId: manifest['selectedFrameId'] as int?,
      selectedLayerId: manifest['selectedLayerId'] as int?,
      thumbnail: thumbnail,
      createdAt: DateTime.fromMillisecondsSinceEpoch(manifest['createdAt'] as int),
      editedAt: DateTime.fromMillisecondsSinceEpoch(manifest['editedAt'] as int),
    );
  }

  static Project _decodeLegacyJson(Uint8List bytes) {
    try {
      // Strip UTF-8 BOM if present
      final slice = (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF)
          ? Uint8List.sublistView(bytes, 3)
          : bytes;
      final jsonString = utf8.decode(slice);
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid project JSON format');
      }
      return Project.fromJson(decoded);
    } catch (e) {
      throw FormatException('Invalid project file format: $e');
    }
  }
}
