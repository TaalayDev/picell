import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'theme.dart';

AppTheme buildDarkTheme() {
  final baseTextTheme = appBaseTextTheme();

  return AppTheme(
    type: ThemeType.darkMode,
    isDark: true,
    primaryColor: const Color(0xFF00C853),
    primaryVariant: const Color(0xFF4CAF50),
    onPrimary: Colors.black,
    accentColor: const Color(0xFF536DFE),
    onAccent: Colors.white,
    background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    surfaceVariant: const Color(0xFF2D2D2D),
    textPrimary: Colors.white,
    textSecondary: const Color(0xFFB0B0B0),
    textDisabled: const Color(0xFF6E6E6E),
    divider: const Color(0xFF3D3D3D),
    toolbarColor: const Color(0xFF252525),
    error: const Color(0xFFCF6679),
    success: const Color(0xFF4CAF50),
    warning: const Color(0xFFFFB74D),
    gridLine: const Color(0xFF3D3D3D),
    gridBackground: const Color(0xFF2D2D2D),
    canvasBackground: const Color(0xFF121212),
    selectionOutline: const Color(0xFF2196F3),
    selectionFill: const Color(0x502196F3),
    activeIcon: const Color(0xFF00C853),
    inactiveIcon: const Color(0xFFB0B0B0),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: Colors.white,
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB0B0B0),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}
