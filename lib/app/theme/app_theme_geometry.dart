import 'package:flutter/material.dart';

/// Holds all dimensional/spatial configuration for a theme.
/// Replaces hardcoded radii, paddings, elevations throughout the app.
class AppThemeGeometry {
  // ── Radii ──────────────────────────────────────────────────────────────────
  final double cardRadius;
  final double buttonRadius;
  final double dialogRadius;
  final double chipRadius;
  final double inputRadius;
  final double bottomSheetRadius;
  final double tooltipRadius;

  // ── Padding ────────────────────────────────────────────────────────────────
  final EdgeInsets cardPadding;
  final EdgeInsets buttonPadding;
  final EdgeInsets contentPadding;
  final EdgeInsets chipPadding;

  // ── Elevation & Shadow ─────────────────────────────────────────────────────
  final double cardElevation;
  final double dialogElevation;
  final double appBarElevation;
  final Color? shadowColor;

  // ── Borders ────────────────────────────────────────────────────────────────
  final double cardBorderWidth;
  final bool hasDividers;

  // ── Typography extras ──────────────────────────────────────────────────────
  final double titleLetterSpacing;
  final double bodyLetterSpacing;

  // ── Icons ──────────────────────────────────────────────────────────────────
  final double iconSize;

  // ── Motion ────────────────────────────────────────────────────────────────
  final Duration hoverDuration;
  final Curve hoverCurve;

  const AppThemeGeometry({
    required this.cardRadius,
    required this.buttonRadius,
    required this.dialogRadius,
    required this.chipRadius,
    required this.inputRadius,
    required this.bottomSheetRadius,
    required this.tooltipRadius,
    required this.cardPadding,
    required this.buttonPadding,
    required this.contentPadding,
    required this.chipPadding,
    required this.cardElevation,
    required this.dialogElevation,
    required this.appBarElevation,
    this.shadowColor,
    required this.cardBorderWidth,
    required this.hasDividers,
    required this.titleLetterSpacing,
    required this.bodyLetterSpacing,
    required this.iconSize,
    required this.hoverDuration,
    required this.hoverCurve,
  });

  /// Default geometry — matches original hardcoded values in theme.dart.
  static const defaults = AppThemeGeometry(
    cardRadius: 12,
    buttonRadius: 8,
    dialogRadius: 12,
    chipRadius: 16,
    inputRadius: 8,
    bottomSheetRadius: 20,
    tooltipRadius: 6,
    cardPadding: EdgeInsets.all(12),
    buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    contentPadding: EdgeInsets.all(16),
    chipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    cardElevation: 2,
    dialogElevation: 8,
    appBarElevation: 0,
    shadowColor: null,
    cardBorderWidth: 0,
    hasDividers: true,
    titleLetterSpacing: 0,
    bodyLetterSpacing: 0.2,
    iconSize: 24,
    hoverDuration: Duration(milliseconds: 150),
    hoverCurve: Curves.easeOut,
  );

  // ── Flagship presets ───────────────────────────────────────────────────────

  static const retroWave = AppThemeGeometry(
    cardRadius: 4,
    buttonRadius: 4,
    dialogRadius: 6,
    chipRadius: 4,
    inputRadius: 4,
    bottomSheetRadius: 4,
    tooltipRadius: 2,
    cardPadding: EdgeInsets.all(10),
    buttonPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    contentPadding: EdgeInsets.all(16),
    chipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    cardElevation: 0,
    dialogElevation: 4,
    appBarElevation: 0,
    shadowColor: Color(0x4DFF0080),
    cardBorderWidth: 1.5,
    hasDividers: true,
    titleLetterSpacing: 2.0,
    bodyLetterSpacing: 0.5,
    iconSize: 24,
    hoverDuration: Duration(milliseconds: 120),
    hoverCurve: Curves.easeOut,
  );

  static const candyCarnival = AppThemeGeometry(
    cardRadius: 24,
    buttonRadius: 50,
    dialogRadius: 24,
    chipRadius: 50,
    inputRadius: 16,
    bottomSheetRadius: 28,
    tooltipRadius: 12,
    cardPadding: EdgeInsets.all(12),
    buttonPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    contentPadding: EdgeInsets.all(16),
    chipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    cardElevation: 0,
    dialogElevation: 6,
    appBarElevation: 0,
    shadowColor: Color(0x33FF6EB4),
    cardBorderWidth: 2.0,
    hasDividers: false,
    titleLetterSpacing: 0.5,
    bodyLetterSpacing: 0.2,
    iconSize: 26,
    hoverDuration: Duration(milliseconds: 200),
    hoverCurve: Curves.elasticOut,
  );

  static const cherryBlossom = AppThemeGeometry(
    cardRadius: 20,
    buttonRadius: 12,
    dialogRadius: 20,
    chipRadius: 20,
    inputRadius: 12,
    bottomSheetRadius: 24,
    tooltipRadius: 8,
    cardPadding: EdgeInsets.all(12),
    buttonPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    contentPadding: EdgeInsets.all(16),
    chipPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    cardElevation: 3,
    dialogElevation: 8,
    appBarElevation: 0,
    shadowColor: Color(0x66FFB7C5),
    cardBorderWidth: 1.0,
    hasDividers: true,
    titleLetterSpacing: 0.3,
    bodyLetterSpacing: 0.2,
    iconSize: 24,
    hoverDuration: Duration(milliseconds: 180),
    hoverCurve: Curves.easeInOutSine,
  );

  static const steampunk = AppThemeGeometry(
    cardRadius: 6,
    buttonRadius: 6,
    dialogRadius: 8,
    chipRadius: 6,
    inputRadius: 6,
    bottomSheetRadius: 8,
    tooltipRadius: 4,
    cardPadding: EdgeInsets.all(10),
    buttonPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    contentPadding: EdgeInsets.all(16),
    chipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    cardElevation: 6,
    dialogElevation: 10,
    appBarElevation: 2,
    shadowColor: Color(0xFF3D2B1F),
    cardBorderWidth: 2.0,
    hasDividers: true,
    titleLetterSpacing: 1.0,
    bodyLetterSpacing: 0.3,
    iconSize: 24,
    hoverDuration: Duration(milliseconds: 160),
    hoverCurve: Curves.easeInOut,
  );

  static const origami = AppThemeGeometry(
    cardRadius: 0,
    buttonRadius: 2,
    dialogRadius: 4,
    chipRadius: 2,
    inputRadius: 2,
    bottomSheetRadius: 4,
    tooltipRadius: 2,
    cardPadding: EdgeInsets.all(12),
    buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    contentPadding: EdgeInsets.all(16),
    chipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    cardElevation: 0,
    dialogElevation: 4,
    appBarElevation: 0,
    shadowColor: null,
    cardBorderWidth: 0,
    hasDividers: true,
    titleLetterSpacing: -0.5,
    bodyLetterSpacing: 0.1,
    iconSize: 22,
    hoverDuration: Duration(milliseconds: 200),
    hoverCurve: Curves.easeInOutCubic,
  );

  static const crystaline = AppThemeGeometry(
    cardRadius: 12,
    buttonRadius: 10,
    dialogRadius: 16,
    chipRadius: 10,
    inputRadius: 10,
    bottomSheetRadius: 20,
    tooltipRadius: 8,
    cardPadding: EdgeInsets.all(12),
    buttonPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    contentPadding: EdgeInsets.all(16),
    chipPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    cardElevation: 0,
    dialogElevation: 8,
    appBarElevation: 0,
    shadowColor: Color(0x809B59B6),
    cardBorderWidth: 1.0,
    hasDividers: true,
    titleLetterSpacing: 1.5,
    bodyLetterSpacing: 0.3,
    iconSize: 24,
    hoverDuration: Duration(milliseconds: 200),
    hoverCurve: Curves.easeOutQuint,
  );

  AppThemeGeometry copyWith({
    double? cardRadius,
    double? buttonRadius,
    double? dialogRadius,
    double? chipRadius,
    double? inputRadius,
    double? bottomSheetRadius,
    double? tooltipRadius,
    EdgeInsets? cardPadding,
    EdgeInsets? buttonPadding,
    EdgeInsets? contentPadding,
    EdgeInsets? chipPadding,
    double? cardElevation,
    double? dialogElevation,
    double? appBarElevation,
    Color? shadowColor,
    double? cardBorderWidth,
    bool? hasDividers,
    double? titleLetterSpacing,
    double? bodyLetterSpacing,
    double? iconSize,
    Duration? hoverDuration,
    Curve? hoverCurve,
  }) {
    return AppThemeGeometry(
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      dialogRadius: dialogRadius ?? this.dialogRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      bottomSheetRadius: bottomSheetRadius ?? this.bottomSheetRadius,
      tooltipRadius: tooltipRadius ?? this.tooltipRadius,
      cardPadding: cardPadding ?? this.cardPadding,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      contentPadding: contentPadding ?? this.contentPadding,
      chipPadding: chipPadding ?? this.chipPadding,
      cardElevation: cardElevation ?? this.cardElevation,
      dialogElevation: dialogElevation ?? this.dialogElevation,
      appBarElevation: appBarElevation ?? this.appBarElevation,
      shadowColor: shadowColor ?? this.shadowColor,
      cardBorderWidth: cardBorderWidth ?? this.cardBorderWidth,
      hasDividers: hasDividers ?? this.hasDividers,
      titleLetterSpacing: titleLetterSpacing ?? this.titleLetterSpacing,
      bodyLetterSpacing: bodyLetterSpacing ?? this.bodyLetterSpacing,
      iconSize: iconSize ?? this.iconSize,
      hoverDuration: hoverDuration ?? this.hoverDuration,
      hoverCurve: hoverCurve ?? this.hoverCurve,
    );
  }
}
