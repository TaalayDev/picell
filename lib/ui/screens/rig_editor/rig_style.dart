import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../pixel/rig/rig_editor_controller.dart';

/// Accent for a rig mode: cyan while building the skeleton, orange while
/// animating. The same color tints the top bar, tools, timeline and playhead.
Color rigModeColor(RigMode mode) => mode == RigMode.setup ? PvTokens.rigSetup : PvTokens.rigAnimate;

/// Theme scoped to the rig editor. Panels, timeline and canvas read the
/// color scheme, so overriding it here restyles all of them at once: primary
/// follows the mode, tertiary is the IK purple, surfaces come from the app
/// theme's tokens.
ThemeData rigThemeFor(BuildContext context, RigMode mode) {
  final base = Theme.of(context);
  final pv = context.pv;
  final accent = rigModeColor(mode);
  return base.copyWith(
    scaffoldBackgroundColor: pv.background,
    dividerColor: pv.divider,
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      onPrimary: const Color(0xFF0B1018),
      primaryContainer: pv.tint(accent, 0.22),
      onPrimaryContainer: accent,
      secondary: pv.accent,
      tertiary: PvTokens.rigIk,
      surface: pv.surface,
      onSurface: pv.textPrimary,
      onSurfaceVariant: pv.textSecondary,
      surfaceContainerLow: pv.surface,
      surfaceContainerHigh: pv.surfaceHigh,
      surfaceContainerHighest: pv.surfaceHigh,
      outlineVariant: pv.divider,
      error: pv.err,
      secondaryContainer: pv.tint(pv.accent, 0.22),
      onSecondaryContainer: pv.accent,
      tertiaryContainer: pv.tint(pv.warn, 0.18),
      onTertiaryContainer: pv.warn,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: pv.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: pv.divider),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: pv.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    ),
    textTheme: base.textTheme.apply(bodyColor: pv.textPrimary, displayColor: pv.textPrimary).copyWith(
          labelSmall: pv.body(size: 11, color: pv.textSecondary),
          labelMedium: pv.body(size: 12, weight: FontWeight.w600),
          bodySmall: pv.body(size: 12, weight: FontWeight.w400),
        ),
  );
}
