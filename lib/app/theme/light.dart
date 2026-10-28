import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'theme.dart';

AppTheme buildLightTheme() {
  final baseTextTheme = appBaseTextTheme();

  return AppTheme(
    type: ThemeType.lightMode,
    isDark: false,
    primaryColor: const Color(0xFF1A863A),
    primaryVariant: const Color(0xFF006428),
    onPrimary: Colors.white,
    accentColor: const Color(0xFF3F51B5),
    onAccent: Colors.white,
    background: const Color(0xFFF5F5F5),
    surface: Colors.white,
    surfaceVariant: const Color(0xFFE0E0E0),
    textPrimary: const Color(0xFF212121),
    textSecondary: const Color(0xFF757575),
    textDisabled: const Color(0xFFBDBDBD),
    divider: const Color(0xFFDDDDDD),
    toolbarColor: const Color(0xFFEEEEEE),
    error: const Color(0xFFB00020),
    success: const Color(0xFF388E3C),
    warning: const Color(0xFFFFA000),
    gridLine: const Color(0xFFDDDDDD),
    gridBackground: Colors.white,
    canvasBackground: Colors.white,
    selectionOutline: const Color(0xFF2196F3),
    selectionFill: const Color(0x302196F3),
    activeIcon: const Color(0xFF1A863A),
    inactiveIcon: const Color(0xFF757575),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF212121),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF212121),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF212121),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF757575),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}
