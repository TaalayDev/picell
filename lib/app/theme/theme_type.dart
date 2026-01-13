import 'package:flutter/material.dart';

enum ThemeType {
  darkMode,
  lightMode,
  midnight,
  forest,
  sunset,
  ocean,
  monochrome,
  neon,
  cosmic,
  pastel,
  purpleRain,
  goldenHour,
  cyberpunk,
  cherryBlossom,
  retroWave,
  iceCrystal,
  volcanic,
  arcticAurora,
  toxicWaste,
  dreamscape,
  deepSea,
  copperSteampunk,
  prismatic,
  emeraldForest,
  roseQuartzGarden,
  winterWonderland,
  autumnHarvest,
  halloween,
  steampunk,
  gothic;

  static List<ThemeType> lockedThemeTypes = [
    ThemeType.ocean,
    ThemeType.monochrome,
    ThemeType.neon,
    ThemeType.cosmic,
    ThemeType.purpleRain,
    ThemeType.goldenHour,
    ThemeType.cyberpunk,
    ThemeType.cherryBlossom,
    ThemeType.retroWave,
    ThemeType.volcanic,
    ThemeType.arcticAurora,
    ThemeType.toxicWaste,
    ThemeType.dreamscape,
    ThemeType.deepSea,
    ThemeType.copperSteampunk,
    ThemeType.prismatic,
    ThemeType.autumnHarvest,
  ];

  bool get isDark => [
        ThemeType.darkMode,
        ThemeType.midnight,
        ThemeType.monochrome,
        ThemeType.neon,
        ThemeType.cosmic,
        ThemeType.purpleRain,
        ThemeType.cyberpunk,
        ThemeType.retroWave,
        ThemeType.volcanic,
        ThemeType.toxicWaste,
        ThemeType.deepSea,
        ThemeType.copperSteampunk,
        ThemeType.prismatic,
        ThemeType.halloween,
        ThemeType.steampunk,
      ].contains(this);

  bool get isLocked => lockedThemeTypes.contains(this);

  bool get isLight => !isDark;

  String get displayName {
    switch (this) {
      case ThemeType.darkMode:
        return 'Dark Mode';
      case ThemeType.lightMode:
        return 'Light Mode';
      case ThemeType.midnight:
        return 'Midnight';
      case ThemeType.forest:
        return 'Forest';
      case ThemeType.sunset:
        return 'Sunset';
      case ThemeType.ocean:
        return 'Ocean';
      case ThemeType.monochrome:
        return 'Monochrome';
      case ThemeType.neon:
        return 'Neon';
      case ThemeType.cosmic:
        return 'Cosmic';
      case ThemeType.pastel:
        return 'Pastel';
      case ThemeType.purpleRain:
        return 'Purple Rain';
      case ThemeType.goldenHour:
        return 'Golden Hour';
      case ThemeType.cyberpunk:
        return 'Cyberpunk';
      case ThemeType.cherryBlossom:
        return 'Cherry Blossom';
      case ThemeType.retroWave:
        return 'Retro Wave';
      case ThemeType.iceCrystal:
        return 'Ice Crystal';
      case ThemeType.volcanic:
        return 'Volcanic';
      case ThemeType.arcticAurora:
        return 'Arctic Aurora';
      case ThemeType.toxicWaste:
        return 'Toxic Waste';
      case ThemeType.dreamscape:
        return 'Dreamscape';
      case ThemeType.deepSea:
        return 'Deep Sea';
      case ThemeType.copperSteampunk:
        return 'Copper Steampunk';
      case ThemeType.prismatic:
        return 'Prismatic';
      case ThemeType.emeraldForest:
        return 'Emerald Forest';
      case ThemeType.roseQuartzGarden:
        return 'Rose Quartz Garden';
      case ThemeType.winterWonderland:
        return 'Winter Wonderland';
      case ThemeType.autumnHarvest:
        return 'Autumn Harvest';
      case ThemeType.halloween:
        return 'Halloween';
      case ThemeType.steampunk:
        return 'Steampunk';
      case ThemeType.gothic:
        return 'Gothic';
    }
  }

  Duration get animationDuration {
    switch (this) {
      case ThemeType.cosmic:
      case ThemeType.neon:
        return const Duration(seconds: 8);
      case ThemeType.midnight:
        return const Duration(seconds: 12);
      case ThemeType.ocean:
        return const Duration(seconds: 10);
      case ThemeType.forest:
        return const Duration(seconds: 15);
      case ThemeType.sunset:
        return const Duration(seconds: 6);
      case ThemeType.pastel:
        return const Duration(seconds: 20);
      case ThemeType.purpleRain:
        return const Duration(seconds: 4);
      case ThemeType.goldenHour:
        return const Duration(seconds: 14);
      case ThemeType.cyberpunk:
        return const Duration(seconds: 15);
      case ThemeType.cherryBlossom:
        return const Duration(seconds: 25);
      case ThemeType.retroWave:
        return const Duration(seconds: 8);
      case ThemeType.iceCrystal:
        return const Duration(seconds: 18);
      case ThemeType.volcanic:
        return const Duration(seconds: 10);
      case ThemeType.arcticAurora:
        return const Duration(seconds: 16);
      case ThemeType.toxicWaste:
        return const Duration(seconds: 8);
      case ThemeType.dreamscape:
        return const Duration(seconds: 22);
      case ThemeType.deepSea:
        return const Duration(seconds: 18);
      case ThemeType.copperSteampunk:
        return const Duration(seconds: 20);
      case ThemeType.prismatic:
        return const Duration(seconds: 20);
      case ThemeType.emeraldForest:
        return const Duration(seconds: 16);
      case ThemeType.winterWonderland:
        return const Duration(seconds: 18);
      case ThemeType.autumnHarvest:
        return const Duration(seconds: 20);
      default:
        return const Duration(seconds: 10);
    }
  }
}
