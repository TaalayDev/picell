part of 'effects.dart';

double _textureHash(int x, int y, [int seed = 0]) {
  var value = x * 374761393 + y * 668265263 + seed * 1442695041;
  value = (value ^ (value >> 13)) * 1274126177;
  return ((value ^ (value >> 16)) & 0xffff) / 65535.0;
}

double _textureNoise(double x, double y, [int seed = 0]) {
  final x0 = x.floor();
  final y0 = y.floor();
  final tx = x - x0;
  final ty = y - y0;
  final sx = tx * tx * (3.0 - 2.0 * tx);
  final sy = ty * ty * (3.0 - 2.0 * ty);
  final top = _textureMix(
      _textureHash(x0, y0, seed), _textureHash(x0 + 1, y0, seed), sx);
  final bottom = _textureMix(
      _textureHash(x0, y0 + 1, seed), _textureHash(x0 + 1, y0 + 1, seed), sx);
  return _textureMix(top, bottom, sy);
}

double _textureFbm(double x, double y, [int seed = 0]) {
  var value = 0.0;
  var amplitude = 0.58;
  var frequency = 1.0;
  for (var octave = 0; octave < 4; octave++) {
    value += _textureNoise(x * frequency, y * frequency, seed + octave * 19) *
        amplitude;
    frequency *= 2.03;
    amplitude *= 0.48;
  }
  return value.clamp(0.0, 1.0);
}

double _textureMix(double a, double b, double amount) =>
    a + (b - a) * amount.clamp(0.0, 1.0);

int _textureChannel(int color, int shift) => (color >> shift) & 0xff;

int _textureBlendColor(int base, int overlay, double amount, int alpha) {
  final t = amount.clamp(0.0, 1.0);
  final r = _textureMix(_textureChannel(base, 16).toDouble(),
          _textureChannel(overlay, 16).toDouble(), t)
      .round()
      .clamp(0, 255);
  final g = _textureMix(_textureChannel(base, 8).toDouble(),
          _textureChannel(overlay, 8).toDouble(), t)
      .round()
      .clamp(0, 255);
  final b = _textureMix(_textureChannel(base, 0).toDouble(),
          _textureChannel(overlay, 0).toDouble(), t)
      .round()
      .clamp(0, 255);
  return (alpha.clamp(0, 255) << 24) | (r << 16) | (g << 8) | b;
}

double _textureLuminance(int pixel) =>
    (0.299 * _textureChannel(pixel, 16) +
        0.587 * _textureChannel(pixel, 8) +
        0.114 * _textureChannel(pixel, 0)) /
    255.0;
