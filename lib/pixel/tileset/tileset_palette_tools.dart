import 'dart:math' as math;

/// Roles of the eight palette slots a surface paints with.
const tilesetSlotRoles = [
  'Outline',
  'Accent 1',
  'Accent 2',
  'Accent 3',
  'Light',
  'Mid',
  'Dark',
  'Highlight',
];

double _channel(int c) {
  final v = c / 255;
  return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG relative luminance of an ARGB color, 0-1.
double tilesetLuminance(int argb) =>
    0.2126 * _channel((argb >> 16) & 255) + 0.7152 * _channel((argb >> 8) & 255) + 0.0722 * _channel(argb & 255);

/// WCAG contrast ratio between two colors, 1-21.
double tilesetContrast(int a, int b) {
  final la = tilesetLuminance(a), lb = tilesetLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

({double h, double s, double l}) _toHsl(int argb) {
  final r = ((argb >> 16) & 255) / 255, g = ((argb >> 8) & 255) / 255, b = (argb & 255) / 255;
  final high = math.max(r, math.max(g, b)), low = math.min(r, math.min(g, b));
  final l = (high + low) / 2, d = high - low;
  if (d == 0) return (h: 0, s: 0, l: l);
  final s = l > 0.5 ? d / (2 - high - low) : d / (high + low);
  final h = high == r
      ? (g - b) / d + (g < b ? 6 : 0)
      : high == g
          ? (b - r) / d + 2
          : (r - g) / d + 4;
  return (h: h * 60, s: s, l: l);
}

int _fromHsl(double h, double s, double l) {
  h = (h % 360 + 360) % 360;
  s = s.clamp(0.0, 1.0);
  l = l.clamp(0.0, 1.0);
  final c = (1 - (2 * l - 1).abs()) * s, x = c * (1 - ((h / 60) % 2 - 1).abs()), m = l - c / 2;
  final (r, g, b) = switch (h ~/ 60) {
    0 => (c, x, 0.0),
    1 => (x, c, 0.0),
    2 => (0.0, c, x),
    3 => (0.0, x, c),
    4 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  int to8(double v) => ((v + m) * 255).round().clamp(0, 255);
  return 0xff000000 | to8(r) << 16 | to8(g) << 8 | to8(b);
}

/// A light / mid / dark ramp built around [base], which becomes the Mid slot.
/// Shadows drift toward blue and lights toward yellow, which keeps pixel art lively.
Map<int, int> suggestShades(int base) {
  final c = _toHsl(base);
  int shade(double dl, double dh, double ds) => _fromHsl(c.h + dh, c.s + ds, c.l + dl);
  return {
    0: shade(-c.l * 0.75 + 0.04, 12, -0.1),
    4: shade(0.14, -6, 0),
    5: 0xff000000 | base & 0xffffff,
    6: shade(-0.16, 10, 0.04),
    7: shade(0.3, -10, -0.1),
  };
}

/// The first pair among Light (4), Mid (5) and Dark (6) that is hard to tell apart.
({int a, int b, double ratio, String message})? paletteContrastIssue(List<int> palette) {
  if (palette.length < 7) return null;
  const pairs = [(4, 5, 1.25), (5, 6, 1.25), (4, 6, 1.6)];
  for (final (a, b, min) in pairs) {
    final ratio = tilesetContrast(palette[a], palette[b]);
    if (ratio >= min) continue;
    final fix = tilesetLuminance(palette[b]) <= tilesetLuminance(palette[a]) ? 'darkening' : 'lightening';
    return (
      a: a,
      b: b,
      ratio: ratio,
      message: switch ((a, b)) {
        (4, 5) => 'Light and Mid are too close to tell apart.',
        (5, 6) => 'Mid and Dark are too close to tell apart.',
        _ => 'Light and Dark barely differ; shading will look flat.',
      }
          .replaceFirst('.', '. Try $fix slot $b.')
          .replaceFirst(';', ';')
    );
  }
  return null;
}

/// Explains why Light, Mid and Dark would be hard to tell apart, or null when they read clearly.
String? paletteContrastWarning(List<int> palette) => paletteContrastIssue(palette)?.message;
