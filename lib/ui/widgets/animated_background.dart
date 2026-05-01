import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/theme/bioluminescent_brutalism.dart';
import '../../core.dart';
import '../../app/theme/art_deco.dart';
import '../../app/theme/art_nouevau.dart';
import '../../app/theme/coral_reef.dart';
import '../../app/theme/crystaline.dart';
import '../../app/theme/candy_carnival.dart';
import '../../app/theme/data_stream.dart';
import '../../app/theme/enchanted_forest.dart';
import '../../app/theme/gothic_theme.dart';
import '../../app/theme/lofi_night.dart';
import '../../app/theme/origami.dart';
import '../../app/theme/pointillism.dart';
import '../../app/theme/stained_glass.dart';
import '../../app/theme/steampunk.dart';
import '../../app/theme/arctic_aurora.dart';
import '../../app/theme/autumn_harvest.dart';
import '../../app/theme/cherry_blossom.dart';
import '../../app/theme/copper_steampunk.dart';
import '../../app/theme/cosmic.dart';
import '../../app/theme/cyberpunk.dart';
import '../../app/theme/deep_sea.dart';
import '../../app/theme/dream_scape.dart';
import '../../app/theme/emerald_forest.dart';
import '../../app/theme/forest.dart';
import '../../app/theme/golden_hour.dart';
import '../../app/theme/ice_crystal.dart';
import '../../app/theme/midnight.dart';
import '../../app/theme/monochrome.dart';
import '../../app/theme/neon.dart';
import '../../app/theme/ocean.dart';
import '../../app/theme/pastel.dart';
import '../../app/theme/prismatic.dart';
import '../../app/theme/purple_rain.dart';
import '../../app/theme/retro_wave.dart';
import '../../app/theme/rose_quartz_garden.dart';
import '../../app/theme/sunset.dart';
import '../../app/theme/toxic_waste.dart';
import '../../app/theme/volcanic.dart';
import '../../app/theme/winter_wonderland.dart';
import '../../app/theme/halloween.dart';
import 'theme_selector.dart';

class AnimatedBackground extends HookConsumerWidget {
  final Widget child;
  final double intensity;
  final bool enableAnimation;
  final AppTheme? appTheme;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.enableAnimation = true,
    this.appTheme,
  });

  bool get isDesktopOrWeb => kIsWeb || !Platform.isAndroid && !Platform.isIOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = appTheme ?? ref.watch(themeProvider).theme;

    return Stack(
      children: [
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: _getBaseGradient(theme),
            ),
          ),
        ),
        //if (isDesktopOrWeb)
        RepaintBoundary(child: _buildAnimatedLayer(theme, enableAnimation)),
        child,
      ],
    );
  }

  Gradient _getBaseGradient(AppTheme theme) {
    switch (theme.type) {
      case ThemeType.volcanic:
        return LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.15)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.08)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.iceCrystal:
        return RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.04)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.retroWave:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.background,
            Color.lerp(theme.background, theme.primaryColor, 0.12)!,
            Color.lerp(theme.background, theme.accentColor, 0.08)!,
            theme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.cherryBlossom:
        return RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.03)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.cyberpunk:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.15)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.08)!,
            theme.background,
            Color.lerp(theme.background, theme.primaryColor, 0.05)!,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );

      case ThemeType.goldenHour:
        return RadialGradient(
          center: Alignment.topRight,
          radius: 1.8,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.06)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.03)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.purpleRain:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.08)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.05)!,
            theme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.pastel:
        return RadialGradient(
          center: Alignment.topLeft,
          radius: 2.0,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.02)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.01)!,
            theme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.candyCarnival:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.background,
            Color.lerp(theme.background, theme.primaryColor, 0.06)!,
            Color.lerp(theme.background, theme.accentColor, 0.05)!,
            theme.background,
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        );

      case ThemeType.cosmic:
        return RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            theme.background,
            Color.lerp(theme.background, theme.primaryColor, 0.1)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 1.0],
        );

      case ThemeType.midnight:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.background,
            Color.lerp(theme.background, theme.primaryColor, 0.05)!,
            theme.background,
          ],
        );

      case ThemeType.ocean:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.02)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.03)!,
          ],
        );

      case ThemeType.forest:
        return RadialGradient(
          center: Alignment.bottomLeft,
          radius: 1.2,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.03)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
          ],
        );

      case ThemeType.sunset:
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.02)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.01)!,
          ],
        );

      case ThemeType.neon:
        return RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            theme.background,
            Color.lerp(theme.background, theme.primaryColor, 0.08)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.05)!,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.arcticAurora:
        return RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.05)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.03)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.toxicWaste:
        return LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.2)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.1)!,
            theme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.dreamscape:
        return RadialGradient(
          center: Alignment.center,
          radius: 2.0,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.03)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.deepSea:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.04)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.copperSteampunk:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.1)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.05)!,
            theme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case ThemeType.emeraldForest:
        return RadialGradient(
          center: Alignment.topLeft,
          radius: 1.8,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.04)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.roseQuartzGarden:
        return RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.04)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.winterWonderland:
        return RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.04)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      case ThemeType.autumnHarvest:
        return RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.04)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );
      case ThemeType.halloween:
        return RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color.lerp(theme.background, theme.primaryColor, 0.04)!,
            theme.background,
            Color.lerp(theme.background, theme.accentColor, 0.02)!,
            theme.background,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        );

      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.background,
            Color.lerp(theme.background, theme.primaryColor, 0.01)!,
          ],
        );
    }
  }

  Widget _buildAnimatedLayer(AppTheme theme, bool enableAnimation) {
    if (!isDesktopOrWeb) {
      return _DefaultBackground(
        theme: theme,
        intensity: intensity,
        enableAnimation: enableAnimation,
      );
    }

    switch (theme.type) {
      case ThemeType.volcanic:
        return VolcanicBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.iceCrystal:
        return IceCrystalBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.retroWave:
        return RetroWaveBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.cherryBlossom:
        return CherryBlossomBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.cyberpunk:
        return CyberpunkBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.goldenHour:
        return GoldenHourBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.purpleRain:
        return PurpleRainBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.pastel:
        return PastelBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.cosmic:
        return CosmicBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.midnight:
        return MidnightBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.ocean:
        return OceanBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.forest:
        return ForestBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.sunset:
        return SunsetBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.neon:
        return NeonBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.monochrome:
        return MonochromeBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.arcticAurora:
        return ArcticAuroraBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.toxicWaste:
        return ToxicWasteBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.dreamscape:
        return DreamscapeBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.deepSea:
        return DeepSeaBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.copperSteampunk:
        return CopperSteampunkBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.prismatic:
        return PrismaticBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.emeraldForest:
        return EmeraldForestBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.roseQuartzGarden:
        return RoseQuartzGardenBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.winterWonderland: // ADD THIS CASE
        return WinterWonderlandBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.autumnHarvest:
        return AutumnHarvestBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.halloween:
        return HalloweenBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      case ThemeType.steampunk:
        return SteampunkBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.gothic:
        return GothicBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.artDeco:
        return ArtDecoBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.crystalline:
        return CrystallineBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.enchantedForest:
        return EnchantedForestBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.coralReef:
        return CoralReefBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.stainedGlass:
        return StainedGlassBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.dataStream:
        return DataStreamBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.lofiNight:
        return LofiNightBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.artNouveau:
        return ArtNouveauBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.origami:
        return OrigamiBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.pointillism:
        return PointillismBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.candyCarnival:
        return CandyCarnivalBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
      case ThemeType.bioluminescentBrutalism:
        return BioluminescentBrutalismBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );

      default:
        return _DefaultBackground(
          theme: theme,
          intensity: intensity,
          enableAnimation: enableAnimation,
        );
    }
  }
}

class _DefaultBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const _DefaultBackground({
    required this.theme,
    required this.intensity,
    required this.enableAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: theme.type.animationDuration,
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    final floatAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(controller),
    );

    return CustomPaint(
      painter: _DefaultPainter(
        animation: floatAnimation,
        primaryColor: theme.primaryColor,
        accentColor: theme.accentColor,
        intensity: intensity,
        animationEnabled: enableAnimation,
        style: _shapeStyleFor(theme.type),
      ),
      size: Size.infinite,
    );
  }
}

enum _ShapeStyle {
  bubbles,
  stars,
  embers,
  snow,
  stripes,
  diamonds,
  leaves,
  rain,
}

_ShapeStyle _shapeStyleFor(ThemeType type) {
  switch (type) {
    case ThemeType.cosmic:
    case ThemeType.midnight:
    case ThemeType.neon:
    case ThemeType.lofiNight:
    case ThemeType.prismatic:
    case ThemeType.bioluminescentBrutalism:
      return _ShapeStyle.stars;

    case ThemeType.volcanic:
    case ThemeType.sunset:
    case ThemeType.goldenHour:
    case ThemeType.halloween:
    case ThemeType.toxicWaste:
    case ThemeType.autumnHarvest:
      return _ShapeStyle.embers;

    case ThemeType.winterWonderland:
    case ThemeType.arcticAurora:
    case ThemeType.iceCrystal:
      return _ShapeStyle.snow;

    case ThemeType.cyberpunk:
    case ThemeType.retroWave:
    case ThemeType.dataStream:
      return _ShapeStyle.stripes;

    case ThemeType.crystalline:
    case ThemeType.stainedGlass:
    case ThemeType.artDeco:
    case ThemeType.copperSteampunk:
    case ThemeType.steampunk:
    case ThemeType.gothic:
      return _ShapeStyle.diamonds;

    case ThemeType.forest:
    case ThemeType.emeraldForest:
    case ThemeType.enchantedForest:
    case ThemeType.cherryBlossom:
    case ThemeType.artNouveau:
    case ThemeType.origami:
      return _ShapeStyle.leaves;

    case ThemeType.purpleRain:
      return _ShapeStyle.rain;

    case ThemeType.ocean:
    case ThemeType.deepSea:
    case ThemeType.coralReef:
    case ThemeType.dreamscape:
    case ThemeType.pastel:
    case ThemeType.roseQuartzGarden:
    case ThemeType.candyCarnival:
    case ThemeType.pointillism:
    case ThemeType.monochrome:
    case ThemeType.darkMode:
    case ThemeType.lightMode:
      return _ShapeStyle.bubbles;
  }
}

class _DefaultPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;
  final _ShapeStyle style;

  _DefaultPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    required this.style,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case _ShapeStyle.bubbles:
        _paintBubbles(canvas, size);
        break;
      case _ShapeStyle.stars:
        _paintStars(canvas, size);
        break;
      case _ShapeStyle.embers:
        _paintEmbers(canvas, size);
        break;
      case _ShapeStyle.snow:
        _paintSnow(canvas, size);
        break;
      case _ShapeStyle.stripes:
        _paintStripes(canvas, size);
        break;
      case _ShapeStyle.diamonds:
        _paintDiamonds(canvas, size);
        break;
      case _ShapeStyle.leaves:
        _paintLeaves(canvas, size);
        break;
      case _ShapeStyle.rain:
        _paintRain(canvas, size);
        break;
    }
  }

  double get _t => animation * 2 * math.pi;

  Color _mix(double phase, {double alphaA = 0.03, double alphaB = 0.05}) {
    return Color.lerp(
      primaryColor.withValues(alpha: alphaA),
      accentColor.withValues(alpha: alphaB),
      math.sin(phase) * 0.5 + 0.5,
    )!;
  }

  void _paintBubbles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(456);
    final count = (15 * intensity).round();
    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final dy = math.sin(_t + i * 0.5) * 20 * intensity;
      final r = (5 + random.nextDouble() * 15) * intensity;
      paint.color = _mix(_t + i);
      canvas.drawCircle(Offset(x, baseY + dy), r, paint);
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(123);
    final count = (24 * intensity).round();
    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final twinkle = math.sin(_t * 1.5 + i * 1.3) * 0.5 + 0.5;
      final r = (0.8 + random.nextDouble() * 1.6) * intensity;
      paint.color = (i.isEven ? primaryColor : accentColor).withValues(alpha: 0.10 + 0.18 * twinkle);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _paintEmbers(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(789);
    final count = (18 * intensity).round();
    for (int i = 0; i < count; i++) {
      final baseX = random.nextDouble() * size.width;
      final yPhase = (random.nextDouble() + animation * 0.5) % 1.0;
      final y = size.height * (1.0 - yPhase);
      final dx = math.sin(_t + i * 0.7) * 12 * intensity;
      final r = (1.2 + random.nextDouble() * 2.2) * intensity;
      paint.color = _mix(_t * 0.7 + i, alphaA: 0.18, alphaB: 0.12);
      canvas.drawCircle(Offset(baseX + dx, y), r, paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(321);
    final count = (20 * intensity).round();
    for (int i = 0; i < count; i++) {
      final baseX = random.nextDouble() * size.width;
      final yPhase = (random.nextDouble() + animation * 0.3) % 1.0;
      final y = size.height * yPhase;
      final dx = math.sin(_t * 0.5 + i * 0.4) * 18 * intensity;
      final r = (1.4 + random.nextDouble() * 1.6) * intensity;
      paint.color = accentColor.withValues(alpha: 0.18);
      canvas.drawCircle(Offset(baseX + dx, y), r, paint);
    }
  }

  void _paintStripes(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const count = 12;
    final span = size.width + size.height;
    for (int i = 0; i < count; i++) {
      final phase = (i / count + animation * 0.1) % 1.0;
      final offset = phase * span;
      final glow = math.sin(_t + i * 0.6) * 0.5 + 0.5;
      paint.color = (i.isEven ? primaryColor : accentColor).withValues(alpha: 0.05 + 0.05 * glow);
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset - size.height, size.height),
        paint,
      );
    }
  }

  void _paintDiamonds(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(987);
    final count = (12 * intensity).round();
    for (int i = 0; i < count; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      final dy = math.sin(_t * 0.6 + i * 0.5) * 8 * intensity;
      final r = (6 + random.nextDouble() * 10) * intensity;
      paint.color = _mix(_t * 0.5 + i, alphaA: 0.05, alphaB: 0.07);
      final path = Path()
        ..moveTo(cx, cy + dy - r)
        ..lineTo(cx + r, cy + dy)
        ..lineTo(cx, cy + dy + r)
        ..lineTo(cx - r, cy + dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _paintLeaves(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(654);
    final count = (16 * intensity).round();
    for (int i = 0; i < count; i++) {
      final baseX = random.nextDouble() * size.width;
      final yPhase = (random.nextDouble() + animation * 0.2) % 1.0;
      final y = size.height * yPhase;
      final dx = math.sin(_t * 0.4 + i * 0.6) * 24 * intensity;
      final rx = (3 + random.nextDouble() * 4) * intensity;
      final ry = (1.4 + random.nextDouble() * 1.6) * intensity;
      paint.color = _mix(_t * 0.3 + i, alphaA: 0.07, alphaB: 0.05);
      canvas.save();
      canvas.translate(baseX + dx, y);
      canvas.rotate(math.sin(_t * 0.3 + i) * 0.6 + i.toDouble());
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), paint);
      canvas.restore();
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final random = math.Random(222);
    final count = (22 * intensity).round();
    for (int i = 0; i < count; i++) {
      final baseX = random.nextDouble() * size.width;
      final yPhase = (random.nextDouble() + animation * 1.2) % 1.0;
      final y = size.height * yPhase;
      final len = (8 + random.nextDouble() * 8) * intensity;
      paint.color = (i.isEven ? primaryColor : accentColor).withValues(alpha: 0.18);
      canvas.drawLine(Offset(baseX, y), Offset(baseX - len * 0.4, y + len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DefaultPainter oldDelegate) {
    return animationEnabled ||
        oldDelegate.animation != animation ||
        oldDelegate.animationEnabled != animationEnabled ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.intensity != intensity ||
        oldDelegate.style != style;
  }
}

extension AnimatedBackgroundExtension on Widget {
  Widget withAnimatedBackground({
    required AppTheme theme,
    double intensity = 1.0,
    bool enableAnimation = true,
  }) {
    return AnimatedBackground(
      intensity: intensity,
      enableAnimation: enableAnimation,
      child: this,
    );
  }
}
