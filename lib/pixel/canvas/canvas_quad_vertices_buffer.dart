import 'dart:typed_data';
import 'dart:ui';

/// Reusable typed buffers for building a quad batch via [Vertices.raw].
class PixelCanvasQuadVerticesBuffer {
  static const int verticesPerQuad = 4;
  static const int indicesPerQuad = 6;
  static const int maxQuadsPerBatch = 16383;

  static const int _positionScalarsPerQuad = verticesPerQuad * 2;

  Float32List _positions = Float32List(0);
  Int32List _colors = Int32List(0);
  Uint16List _indices = Uint16List(0);

  int _quadCapacity = 0;
  int _quadCount = 0;

  bool get isEmpty => _quadCount == 0;
  bool get isFull => _quadCount >= maxQuadsPerBatch;

  void reset() {
    _quadCount = 0;
  }

  void addQuad({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required int colorValue,
  }) {
    if (isFull) {
      throw StateError('Quad buffer exceeded max batch size.');
    }

    _ensureCapacity(_quadCount + 1);

    final vertexOffset = _quadCount * verticesPerQuad;
    final positionOffset = _quadCount * _positionScalarsPerQuad;

    _positions[positionOffset] = left;
    _positions[positionOffset + 1] = top;
    _positions[positionOffset + 2] = right;
    _positions[positionOffset + 3] = top;
    _positions[positionOffset + 4] = right;
    _positions[positionOffset + 5] = bottom;
    _positions[positionOffset + 6] = left;
    _positions[positionOffset + 7] = bottom;

    _colors[vertexOffset] = colorValue;
    _colors[vertexOffset + 1] = colorValue;
    _colors[vertexOffset + 2] = colorValue;
    _colors[vertexOffset + 3] = colorValue;

    _quadCount += 1;
  }

  Vertices? buildVertices() {
    if (isEmpty) {
      return null;
    }

    final vertexCount = _quadCount * verticesPerQuad;
    final indexCount = _quadCount * indicesPerQuad;

    return Vertices.raw(
      VertexMode.triangles,
      _positions.buffer.asFloat32List(0, vertexCount * 2),
      colors: _colors.buffer.asInt32List(0, vertexCount),
      indices: _indices.buffer.asUint16List(0, indexCount),
    );
  }

  void _ensureCapacity(int requiredQuads) {
    if (requiredQuads <= _quadCapacity) {
      return;
    }

    var newCapacity = _quadCapacity == 0 ? 256 : _quadCapacity;
    while (newCapacity < requiredQuads) {
      newCapacity *= 2;
    }
    if (newCapacity > maxQuadsPerBatch) {
      newCapacity = maxQuadsPerBatch;
    }

    _positions = _growFloat32List(_positions, newCapacity * _positionScalarsPerQuad);
    _colors = _growInt32List(_colors, newCapacity * verticesPerQuad);
    _indices = _growUint16List(_indices, newCapacity * indicesPerQuad);
    _primeIndices(startQuad: _quadCapacity, endQuad: newCapacity);
    _quadCapacity = newCapacity;
  }

  void _primeIndices({required int startQuad, required int endQuad}) {
    for (int quad = startQuad; quad < endQuad; quad++) {
      final vertexOffset = quad * verticesPerQuad;
      final indexOffset = quad * indicesPerQuad;

      _indices[indexOffset] = vertexOffset;
      _indices[indexOffset + 1] = vertexOffset + 1;
      _indices[indexOffset + 2] = vertexOffset + 2;
      _indices[indexOffset + 3] = vertexOffset;
      _indices[indexOffset + 4] = vertexOffset + 2;
      _indices[indexOffset + 5] = vertexOffset + 3;
    }
  }

  Float32List _growFloat32List(Float32List source, int length) {
    final grown = Float32List(length);
    grown.setRange(0, source.length, source);
    return grown;
  }

  Int32List _growInt32List(Int32List source, int length) {
    final grown = Int32List(length);
    grown.setRange(0, source.length, source);
    return grown;
  }

  Uint16List _growUint16List(Uint16List source, int length) {
    final grown = Uint16List(length);
    grown.setRange(0, source.length, source);
    return grown;
  }
}
