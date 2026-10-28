import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

/// Design tokens for the redesigned Projects and Bone Rig screens.
///
/// Everything is derived from the active [AppTheme] so the look follows the
/// selected theme; only the rig mode accents are fixed (they carry meaning).
@immutable
class PvTokens extends ThemeExtension<PvTokens> {
  const PvTokens({
    required this.gradient,
    required this.ink,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.accent,
    required this.ok,
    required this.warn,
    required this.err,
    required this.checkerA,
    required this.checkerB,
    required this.cardRadius,
    required this.buttonRadius,
    required this.chipRadius,
    required this.cardBorderWidth,
    required this.cardElevation,
    required this.shadowColor,
    required this.isDark,
  });

  factory PvTokens.fromTheme(AppTheme t) {
    final g = t.geometry;
    return PvTokens(
      gradient: LinearGradient(colors: [t.primaryColor, t.accentColor]),
      ink: t.onPrimary,
      background: t.background,
      surface: t.surface,
      surfaceHigh: t.surfaceVariant,
      divider: t.divider,
      textPrimary: t.textPrimary,
      textSecondary: t.textSecondary,
      primary: t.primaryColor,
      accent: t.accentColor,
      ok: t.success,
      warn: t.warning,
      err: t.error,
      checkerA: Color.lerp(t.surface, t.surfaceVariant, 0.5)!,
      checkerB: t.surfaceVariant,
      cardRadius: g.cardRadius,
      buttonRadius: g.buttonRadius,
      chipRadius: g.chipRadius,
      cardBorderWidth: g.cardBorderWidth,
      cardElevation: g.cardElevation,
      shadowColor: g.shadowColor,
      isDark: t.isDark,
    );
  }

  final LinearGradient gradient;
  final Color ink;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color accent;
  final Color ok;
  final Color warn;
  final Color err;

  /// Transparency-checkerboard colors for thumbnails and the rig canvas.
  final Color checkerA;
  final Color checkerB;

  final double cardRadius;
  final double buttonRadius;
  final double chipRadius;

  /// Card outline and shadow straight from the theme's geometry, so project
  /// cards read like the theme's own cards.
  final double cardBorderWidth;
  final double cardElevation;
  final Color? shadowColor;
  final bool isDark;

  // Rig editor accents — fixed because they identify the mode / chain type.
  static const rigSetup = Color(0xFF35D0F0);
  static const rigAnimate = Color(0xFFFF9A3D);
  static const rigIk = Color(0xFFB58CFF);

  /// Tints [c] over [surface] — the "mode tint" used on rig bars.
  Color tint(Color c, [double alpha = 0.10]) => Color.alphaBlend(c.withValues(alpha: alpha), surface);

  /// Surface decoration for cards: the theme's radius, border width and
  /// shadow. [hovered] swaps the outline to the accent and lifts the shadow.
  BoxDecoration cardDecoration({bool hovered = false, Color? color, double? radius, bool outlined = true}) {
    final lift = hovered ? 4.0 : 0.0;
    final elevation = cardElevation + lift;
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius ?? cardRadius),
      border: outlined
          ? Border.all(color: hovered ? accent : divider, width: cardBorderWidth < 1 ? 1 : cardBorderWidth)
          : null,
      boxShadow: elevation <= 0 && shadowColor == null
          ? null
          : [
              BoxShadow(
                color: shadowColor ?? Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                blurRadius: 4 + elevation * 3,
                offset: Offset(0, 1 + elevation),
              ),
            ],
    );
  }

  // ── Type ──────────────────────────────────────────────────────────────────
  /// Pixel display face for logos and hero headings. Use sparingly.
  TextStyle pixelTitle({double size = 16, Color? color}) =>
      GoogleFonts.pressStart2p(fontSize: size, height: 1.2, color: color ?? textPrimary);

  /// Pixel label face for section headers, buttons and badges.
  /// Tests run offline, where google_fonts cannot download the design fonts, and turn this off.
  @visibleForTesting
  static bool useDesignFonts = true;

  TextStyle pixelLabel({double size = 12, Color? color, FontWeight weight = FontWeight.w700}) => useDesignFonts
      ? GoogleFonts.silkscreen(fontSize: size, fontWeight: weight, color: color ?? textPrimary)
      : TextStyle(fontSize: size, fontWeight: weight, color: color ?? textPrimary, letterSpacing: 1);

  TextStyle body({double size = 14, Color? color, FontWeight weight = FontWeight.w500}) => useDesignFonts
      ? GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? textPrimary)
      : TextStyle(fontSize: size, fontWeight: weight, color: color ?? textPrimary);

  /// Monospace for numbers, frame indices and bone names.
  TextStyle mono({double size = 12, Color? color, FontWeight weight = FontWeight.w500}) => useDesignFonts
      ? GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color ?? textPrimary)
      : TextStyle(fontSize: size, fontWeight: weight, color: color ?? textPrimary, fontFamily: 'monospace');

  @override
  PvTokens copyWith({LinearGradient? gradient}) => PvTokens(
        gradient: gradient ?? this.gradient,
        ink: ink,
        background: background,
        surface: surface,
        surfaceHigh: surfaceHigh,
        divider: divider,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primary: primary,
        accent: accent,
        ok: ok,
        warn: warn,
        err: err,
        checkerA: checkerA,
        checkerB: checkerB,
        cardRadius: cardRadius,
        buttonRadius: buttonRadius,
        chipRadius: chipRadius,
        cardBorderWidth: cardBorderWidth,
        cardElevation: cardElevation,
        shadowColor: shadowColor,
        isDark: isDark,
      );

  @override
  PvTokens lerp(ThemeExtension<PvTokens>? other, double t) {
    if (other is! PvTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PvTokens(
      gradient: LinearGradient.lerp(gradient, other.gradient, t)!,
      ink: c(ink, other.ink),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      divider: c(divider, other.divider),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      primary: c(primary, other.primary),
      accent: c(accent, other.accent),
      ok: c(ok, other.ok),
      warn: c(warn, other.warn),
      err: c(err, other.err),
      checkerA: c(checkerA, other.checkerA),
      checkerB: c(checkerB, other.checkerB),
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      buttonRadius: buttonRadius + (other.buttonRadius - buttonRadius) * t,
      chipRadius: chipRadius + (other.chipRadius - chipRadius) * t,
      cardBorderWidth: cardBorderWidth + (other.cardBorderWidth - cardBorderWidth) * t,
      cardElevation: cardElevation + (other.cardElevation - cardElevation) * t,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension PvTokensContext on BuildContext {
  /// Redesign tokens for the active theme. Falls back to the default theme
  /// when the surrounding [ThemeData] was not built from an [AppTheme].
  PvTokens get pv => Theme.of(this).extension<PvTokens>() ?? PvTokens.fromTheme(AppTheme.defaultTheme);
}

/// Body text theme shared by every app theme; plain text when [PvTokens.useDesignFonts] is off.
TextTheme appBaseTextTheme() =>
    PvTokens.useDesignFonts ? GoogleFonts.sourceCodeProTextTheme() : Typography.material2021().black;
