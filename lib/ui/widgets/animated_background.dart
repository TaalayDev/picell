import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/theme/gothic_theme.dart';
import '../../app/theme/steampunk.dart';
import '../../core.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = appTheme ?? ref.watch(themeProvider).theme;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: _getBaseGradient(theme),
          ),
        ),
        _buildAnimatedLayer(theme),
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

  Widget _buildAnimatedLayer(AppTheme theme) {
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
      ),
      size: Size.infinite,
    );
  }
}

class _DefaultPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  _DefaultPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(456);

    for (int i = 0; i < (15 * intensity).round(); i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final offset = math.sin(animation * 2 * math.pi + i * 0.5) * 20 * intensity;

      final x = baseX;
      final y = baseY + offset;
      final radius = (5 + random.nextDouble() * 15) * intensity;

      paint.color = Color.lerp(
        primaryColor.withOpacity(0.03),
        accentColor.withOpacity(0.05),
        math.sin(animation * 2 * math.pi + i) * 0.5 + 0.5,
      )!;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
