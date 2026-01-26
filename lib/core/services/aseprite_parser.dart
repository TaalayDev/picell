import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';

/// Represents an Aseprite file's parsed content
class AsepriteFile {
  final int width;
  final int height;
  final int frameCount;
  final List<AsepriteFrame> frames;
  final List<AsepriteLayer> layers;
  final List<Color32> palette;

  AsepriteFile({
    required this.width,
    required this.height,
    required this.frameCount,
    required this.frames,
    required this.layers,
    required this.palette,
  });
}

class AsepriteFrame {
  final int duration;
  final List<AsepriteCel> cels;

  AsepriteFrame({
    required this.duration,
    required this.cels,
  });
}

class AsepriteLayer {
  final int index;
  final String name;
  final bool isVisible;
  final double opacity;
  final int blendMode;

  AsepriteLayer({
    required this.index,
    required this.name,
    required this.isVisible,
    required this.opacity,
    required this.blendMode,
  });
}

class AsepriteCel {
  final int layerIndex;
  final int x;
  final int y;
  final int width;
  final int height;
  final Uint32List pixels;

  AsepriteCel({
    required this.layerIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pixels,
  });
}

class Color32 {
  final int r, g, b, a;
  Color32(this.r, this.g, this.b, this.a);

  int toArgb() => (a << 24) | (r << 16) | (g << 8) | b;
}

/// Parser for Aseprite (.ase/.aseprite) files
class AsepriteParser {
  static const int _aseFileMagic = 0xA5E0;
  static const int _aseFrameMagic = 0xF1FA;

  // Chunk types
  static const int _chunkOldPalette = 0x0004;
  static const int _chunkOldPalette2 = 0x0011;
  static const int _chunkLayer = 0x2004;
  static const int _chunkCel = 0x2005;
  static const int _chunkCelExtra = 0x2006;
  static const int _chunkColorProfile = 0x2007;
  static const int _chunkExternalFiles = 0x2008;
  static const int _chunkMask = 0x2016;
  static const int _chunkPath = 0x2017;
  static const int _chunkTags = 0x2018;
  static const int _chunkPalette = 0x2019;
  static const int _chunkUserData = 0x2020;
  static const int _chunkSlice = 0x2022;
  static const int _chunkTileset = 0x2023;

  // Color depth values
  static const int _colorDepthRgba = 32;
  static const int _colorDepthGrayscale = 16;
  static const int _colorDepthIndexed = 8;

  // Cel types
  static const int _celTypeRaw = 0;
  static const int _celTypeLinked = 1;
  static const int _celTypeCompressed = 2;
  static const int _celTypeCompressedTilemap = 3;

  late ByteData _data;
  int _position = 0;
  int _colorDepth = _colorDepthRgba;
  List<Color32> _palette = [];

  /// Parse an Aseprite file from bytes
  AsepriteFile? parse(Uint8List bytes) {
    try {
      _data = ByteData.view(bytes.buffer);
      _position = 0;
      _palette = [];

      // Read header
      final fileSize = _readDword();
      final magic = _readWord();

      if (magic != _aseFileMagic) {
        debugPrint('Invalid Aseprite file magic: $magic');
        return null;
      }

      final frameCount = _readWord();
      final width = _readWord();
      final height = _readWord();
      _colorDepth = _readWord();
      final flags = _readDword();
      final speed = _readWord(); // Deprecated
      _readDword(); // Set 0
      _readDword(); // Set 0
      final transparentIndex = _readByte();
      _skip(3); // Ignore bytes
      final numColors = _readWord();
      final pixelWidth = _readByte();
      final pixelHeight = _readByte();
      final gridX = _readShort();
      final gridY = _readShort();
      final gridWidth = _readWord();
      final gridHeight = _readWord();
      _skip(84); // Reserved

      // Initialize default grayscale palette for indexed mode
      if (_colorDepth == _colorDepthIndexed && numColors > 0) {
        _palette = List.generate(256, (i) => Color32(i, i, i, 255));
      }

      final layers = <AsepriteLayer>[];
      final frames = <AsepriteFrame>[];

      // Read frames
      for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
        final frameData = _readFrame(width, height, layers);
        if (frameData != null) {
          frames.add(frameData);
        }
      }

      return AsepriteFile(
        width: width,
        height: height,
        frameCount: frameCount,
        frames: frames,
        layers: layers,
        palette: _palette,
      );
    } catch (e, stack) {
      debugPrint('Error parsing Aseprite file: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Parse Aseprite file from a file path
  Future<AsepriteFile?> parseFile(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      return parse(bytes);
    } catch (e) {
      debugPrint('Error reading Aseprite file: $e');
      return null;
    }
  }

  AsepriteFrame? _readFrame(int imageWidth, int imageHeight, List<AsepriteLayer> layers) {
    final frameStart = _position;
    final frameSize = _readDword();
    final frameMagic = _readWord();

    if (frameMagic != _aseFrameMagic) {
      debugPrint('Invalid frame magic: $frameMagic');
      return null;
    }

    int chunkCount = _readWord();
    final duration = _readWord();
    _skip(2); // Reserved
    final newChunkCount = _readDword();
    if (newChunkCount != 0) {
      chunkCount = newChunkCount;
    }

    final cels = <AsepriteCel>[];

    // Read chunks
    for (int i = 0; i < chunkCount; i++) {
      final chunkStart = _position;
      final chunkSize = _readDword();
      final chunkType = _readWord();

      switch (chunkType) {
        case _chunkLayer:
          final layer = _readLayerChunk(layers.length);
          layers.add(layer);
          break;
        case _chunkCel:
          final cel = _readCelChunk(imageWidth, imageHeight);
          if (cel != null) {
            cels.add(cel);
          }
          break;
        case _chunkPalette:
          _readPaletteChunk();
          break;
        case _chunkOldPalette:
        case _chunkOldPalette2:
          _readOldPaletteChunk(chunkType == _chunkOldPalette2);
          break;
        default:
          // Skip unknown chunks
          break;
      }

      // Move to end of chunk
      _position = chunkStart + chunkSize;
    }

    return AsepriteFrame(
      duration: duration,
      cels: cels,
    );
  }

  AsepriteLayer _readLayerChunk(int index) {
    final flags = _readWord();
    final type = _readWord();
    final childLevel = _readWord();
    final defaultWidth = _readWord(); // Ignored
    final defaultHeight = _readWord(); // Ignored
    final blendMode = _readWord();
    final opacity = _readByte();
    _skip(3); // Reserved
    final name = _readString();

    return AsepriteLayer(
      index: index,
      name: name,
      isVisible: (flags & 0x01) != 0,
      opacity: opacity / 255.0,
      blendMode: blendMode,
    );
  }

  AsepriteCel? _readCelChunk(int imageWidth, int imageHeight) {
    final layerIndex = _readWord();
    final x = _readShort();
    final y = _readShort();
    final opacity = _readByte();
    final celType = _readWord();
    final zIndex = _readShort();
    _skip(5); // Reserved

    switch (celType) {
      case _celTypeRaw:
        return _readRawCel(layerIndex, x, y, opacity);
      case _celTypeCompressed:
        return _readCompressedCel(layerIndex, x, y, opacity);
      case _celTypeLinked:
        // Linked cels reference another frame's cel
        final framePosition = _readWord();
        // For now, return null for linked cels - they need special handling
        return null;
      default:
        return null;
    }
  }

  AsepriteCel _readRawCel(int layerIndex, int x, int y, int opacity) {
    final width = _readWord();
    final height = _readWord();
    final pixels = _readPixels(width, height);

    return AsepriteCel(
      layerIndex: layerIndex,
      x: x,
      y: y,
      width: width,
      height: height,
      pixels: pixels,
    );
  }

  AsepriteCel _readCompressedCel(int layerIndex, int x, int y, int opacity) {
    final width = _readWord();
    final height = _readWord();

    // Read compressed data (zlib)
    final compressedData = _readRemainingChunkData();
    final decompressed = _decompressZlib(compressedData);

    if (decompressed == null) {
      return AsepriteCel(
        layerIndex: layerIndex,
        x: x,
        y: y,
        width: width,
        height: height,
        pixels: Uint32List(width * height),
      );
    }

    final pixels = _bytesToPixels(decompressed, width, height);

    return AsepriteCel(
      layerIndex: layerIndex,
      x: x,
      y: y,
      width: width,
      height: height,
      pixels: pixels,
    );
  }

  Uint32List _readPixels(int width, int height) {
    final pixelCount = width * height;
    final pixels = Uint32List(pixelCount);

    switch (_colorDepth) {
      case _colorDepthRgba:
        for (int i = 0; i < pixelCount; i++) {
          final r = _readByte();
          final g = _readByte();
          final b = _readByte();
          final a = _readByte();
          pixels[i] = (a << 24) | (r << 16) | (g << 8) | b;
        }
        break;
      case _colorDepthGrayscale:
        for (int i = 0; i < pixelCount; i++) {
          final v = _readByte();
          final a = _readByte();
          pixels[i] = (a << 24) | (v << 16) | (v << 8) | v;
        }
        break;
      case _colorDepthIndexed:
        for (int i = 0; i < pixelCount; i++) {
          final index = _readByte();
          if (index < _palette.length) {
            pixels[i] = _palette[index].toArgb();
          } else {
            pixels[i] = 0;
          }
        }
        break;
    }

    return pixels;
  }

  Uint32List _bytesToPixels(Uint8List bytes, int width, int height) {
    final pixelCount = width * height;
    final pixels = Uint32List(pixelCount);
    int offset = 0;

    switch (_colorDepth) {
      case _colorDepthRgba:
        for (int i = 0; i < pixelCount && offset + 3 < bytes.length; i++) {
          final r = bytes[offset++];
          final g = bytes[offset++];
          final b = bytes[offset++];
          final a = bytes[offset++];
          pixels[i] = (a << 24) | (r << 16) | (g << 8) | b;
        }
        break;
      case _colorDepthGrayscale:
        for (int i = 0; i < pixelCount && offset + 1 < bytes.length; i++) {
          final v = bytes[offset++];
          final a = bytes[offset++];
          pixels[i] = (a << 24) | (v << 16) | (v << 8) | v;
        }
        break;
      case _colorDepthIndexed:
        for (int i = 0; i < pixelCount && offset < bytes.length; i++) {
          final index = bytes[offset++];
          if (index < _palette.length) {
            pixels[i] = _palette[index].toArgb();
          } else {
            pixels[i] = 0;
          }
        }
        break;
    }

    return pixels;
  }

  void _readPaletteChunk() {
    final size = _readDword();
    final firstIndex = _readDword();
    final lastIndex = _readDword();
    _skip(8); // Reserved

    // Ensure palette is large enough
    while (_palette.length <= lastIndex) {
      _palette.add(Color32(0, 0, 0, 255));
    }

    for (int i = firstIndex; i <= lastIndex; i++) {
      final flags = _readWord();
      final r = _readByte();
      final g = _readByte();
      final b = _readByte();
      final a = _readByte();
      _palette[i] = Color32(r, g, b, a);

      if ((flags & 0x01) != 0) {
        // Has name
        _readString();
      }
    }
  }

  void _readOldPaletteChunk(bool isLong) {
    final numPackets = _readWord();

    int index = 0;
    for (int i = 0; i < numPackets; i++) {
      final skip = _readByte();
      index += skip;

      int count = _readByte();
      if (count == 0) count = 256;

      // Ensure palette is large enough
      while (_palette.length < index + count) {
        _palette.add(Color32(0, 0, 0, 255));
      }

      for (int j = 0; j < count; j++) {
        final r = _readByte();
        final g = _readByte();
        final b = _readByte();
        _palette[index++] = Color32(r, g, b, 255);
      }
    }
  }

  Uint8List _readRemainingChunkData() {
    // This needs to read until end of chunk
    // We'll read a reasonable amount - actual size determined by chunk bounds
    final remaining = _data.lengthInBytes - _position;
    final bytes = Uint8List(remaining);
    for (int i = 0; i < remaining; i++) {
      bytes[i] = _readByte();
    }
    return bytes;
  }

  Uint8List? _decompressZlib(Uint8List compressed) {
    try {
      final decoder = ZLibDecoder();
      return Uint8List.fromList(decoder.decodeBytes(compressed));
    } catch (e) {
      debugPrint('Zlib decompression error: $e');
      return null;
    }
  }

  // Binary reading helpers
  int _readByte() {
    return _data.getUint8(_position++);
  }

  int _readWord() {
    final value = _data.getUint16(_position, Endian.little);
    _position += 2;
    return value;
  }

  int _readShort() {
    final value = _data.getInt16(_position, Endian.little);
    _position += 2;
    return value;
  }

  int _readDword() {
    final value = _data.getUint32(_position, Endian.little);
    _position += 4;
    return value;
  }

  String _readString() {
    final length = _readWord();
    final bytes = <int>[];
    for (int i = 0; i < length; i++) {
      bytes.add(_readByte());
    }
    return String.fromCharCodes(bytes);
  }

  void _skip(int count) {
    _position += count;
  }
}
