import 'package:flutter/material.dart';
import 'package:pixelverse/data.dart';

import 'autumn_harvest.dart';
import 'cherry_blossom.dart';
import 'copper_steampunk.dart';
import 'cosmic.dart';
import 'cyberpunk.dart';
import 'dark.dart';
import 'forest.dart';
import 'golden_hour.dart';
import 'gothic_theme.dart';
import 'ice_crystal.dart';
import 'light.dart';
import 'midnight.dart';
import 'monochrome.dart';
import 'neon.dart';
import 'ocean.dart';
import 'pastel.dart';
import 'prismatic.dart';
import 'purple_rain.dart';
import 'retro_wave.dart';
import 'rose_quartz_garden.dart';
import 'steampunk.dart';
import 'sunset.dart';
import 'theme_type.dart';

import 'arctic_aurora.dart';
import 'deep_sea.dart';
import 'dream_scape.dart';
import 'toxic_waste.dart';
import 'volcanic.dart';
import 'emerald_forest.dart';
import 'winter_wonderland.dart';
import 'halloween.dart';

export 'theme_type.dart';

class AppTheme {
  static const defaultType = ThemeType.retroWave;
  static final defaultTheme = AppTheme.fromType(defaultType);

  final ThemeType type;
  final bool isDark;

  // Primary colors
  final Color primaryColor;
  final Color primaryVariant;
  final Color onPrimary;

  // Secondary colors
  final Color accentColor;
  final Color onAccent;

  // Background colors
  final Color background;
  final Color surface;
  final Color surfaceVariant;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  // UI element colors
  final Color divider;
  final Color toolbarColor;
  final Color error;
  final Color success;
  final Color warning;

  // Grid colors
  final Color gridLine;
  final Color gridBackground;

  // Canvas-related colors
  final Color canvasBackground;
  final Color selectionOutline;
  final Color selectionFill;

  // Icon colors
  final Color activeIcon;
  final Color inactiveIcon;

  // Font settings
  final TextTheme textTheme;
  final FontWeight primaryFontWeight;

  AppTheme({
    required this.type,
    required this.isDark,
    required this.primaryColor,
    required this.primaryVariant,
    required this.onPrimary,
    required this.accentColor,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.divider,
    required this.toolbarColor,
    required this.error,
    required this.success,
    required this.warning,
    required this.gridLine,
    required this.gridBackground,
    required this.canvasBackground,
    required this.selectionOutline,
    required this.selectionFill,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.textTheme,
    required this.primaryFontWeight,
  });

  factory AppTheme.fromType(ThemeType type) {
    switch (type) {
      case ThemeType.lightMode:
        return buildLightTheme();
      case ThemeType.darkMode:
        return buildDarkTheme();
      case ThemeType.midnight:
        return buildMidnightTheme();
      case ThemeType.forest:
        return buildForestTheme();
      case ThemeType.sunset:
        return buildSunsetTheme();
      case ThemeType.ocean:
        return buildOceanTheme();
      case ThemeType.monochrome:
        return buildMonochromeTheme();
      case ThemeType.neon:
        return buildNeonTheme();
      case ThemeType.cosmic:
        return buildCosmicTheme();
      case ThemeType.pastel:
        return buildPastelTheme();
      case ThemeType.purpleRain:
        return buildPurpleRainTheme();
      case ThemeType.goldenHour:
        return buildGoldenHourTheme();
      case ThemeType.cyberpunk:
        return buildCyberpunkTheme();
      case ThemeType.cherryBlossom:
        return buildCherryBlossomTheme();
      case ThemeType.retroWave:
        return buildRetroWaveTheme();
      case ThemeType.iceCrystal:
        return buildIceCrystalTheme();
      case ThemeType.volcanic:
        return buildVolcanicTheme();
      case ThemeType.arcticAurora:
        return buildArcticAuroraTheme();
      case ThemeType.toxicWaste:
        return buildToxicWasteTheme();
      case ThemeType.dreamscape:
        return buildDreamscapeTheme();
      case ThemeType.deepSea:
        return buildDeepSeaTheme();
      case ThemeType.copperSteampunk:
        return buildCopperSteampunkTheme();
      case ThemeType.prismatic:
        return buildPrismaticTheme();
      case ThemeType.emeraldForest:
        return buildEmeraldForestTheme();
      case ThemeType.roseQuartzGarden:
        return buildRoseQuartzGardenTheme();
      case ThemeType.winterWonderland:
        return buildWinterWonderlandTheme();
      case ThemeType.autumnHarvest:
        return buildAutumnHarvestTheme();
      case ThemeType.halloween:
        return buildHalloweenTheme();
      case ThemeType.steampunk:
        return buildSteampunkTheme();
      case ThemeType.gothic:
        return buildGothicTheme();
    }
  }

  ThemeData get themeData {
    var t = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: onPrimary,
        secondary: accentColor,
        onSecondary: onAccent,
        error: error,
        onError: isDark ? Colors.black : Colors.white,
        background: background,
        onBackground: textPrimary,
        surface: surface,
        onSurface: textPrimary,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: divider,
      textTheme: textTheme,
      iconTheme: IconThemeData(
        color: activeIcon,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: toolbarColor,
        foregroundColor: textPrimary,
        centerTitle: true,
      ),
      dialogBackgroundColor: surface,
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        textStyle: TextStyle(color: textPrimary),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: toolbarColor,
      ),
      cardTheme: CardThemeData(
        color: surface,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: surfaceVariant,
        filled: true,
        labelStyle: TextStyle(color: textSecondary),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: divider),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: error),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: error, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onPrimary,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: onPrimary,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
        thumbColor: primaryColor,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
        }),
        checkColor: MaterialStateProperty.all(onPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
        }),
      ),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
        }),
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey.shade200 : Colors.white;
        }),
      ),
    );

    return t;
  }

  Color shift(Color c, double amount) {
    amount *= (isDark ? -1 : 1);

    /// Convert to HSL
    var hslc = HSLColor.fromColor(c);

    /// Add/Remove lightness
    double lightness = (hslc.lightness + amount).clamp(0, 1.0).toDouble();

    /// Convert back to Color
    return hslc.withLightness(lightness).toColor();
  }
}

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.defaultTheme;

  AppTheme get theme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = LocalStorage();
    final themeString = prefs.getString(_themeKey);

    if (themeString != null) {
      try {
        final themeType = ThemeType.values.firstWhere(
          (t) => t.toString() == themeString,
          orElse: () => ThemeType.darkMode,
        );
        _currentTheme = AppTheme.fromType(themeType);
        notifyListeners();
      } catch (e) {
        // If theme loading fails, use default
        _currentTheme = AppTheme.defaultTheme;
      }
    }
  }

  Future<void> setTheme(ThemeType themeType) async {
    _currentTheme = AppTheme.fromType(themeType);

    final prefs = LocalStorage();
    prefs.setString(_themeKey, themeType.toString());

    notifyListeners();
  }
}
