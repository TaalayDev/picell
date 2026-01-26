import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../ui/widgets/app_icon.dart';
import '../pixel_utils.dart';

part 'brightness_effect.dart';
part 'contrast_effect.dart';
part 'emboss_effect.dart';
part 'grayscale_effect.dart';
part 'invert_effect.dart';
part 'noise_effect.dart';
part 'pixelate_effect.dart';
part 'sepia_effect.dart';
part 'sharpen_effect.dart';
part 'threshold_effect.dart';
part 'vignette_effect.dart';
part 'blur_effect.dart';
part 'color_balance_effect.dart';
part 'dithering_effect.dart';
part 'outline_effect.dart';
part 'palette_reduction_effect.dart';
part 'watercolor_effect.dart';
part 'halftone_effect.dart';
part 'glow_effect.dart';
part 'oil_paint_effect.dart';
part 'gradient_effect.dart';
part 'fire_effect.dart';
part 'wood_effect.dart';
part 'rain_effect.dart';
part 'crystal_effect.dart';
part 'stained_glass_effect.dart';
part 'glitch_effect.dart';
part 'metal_effect.dart';
part 'sparkle_effect.dart';
part 'particle_effect.dart';
part 'pulse_effect.dart';
part 'wave_effect.dart';
part 'rotate_effect.dart';
part 'float_effect.dart';
part 'shake_effect.dart';
part 'dissolve_effect.dart';
part 'melt_effect.dart';
part 'explosion_effect.dart';
part 'jello_effect.dart';
part 'wipe_effect.dart';
part 'fog_effect.dart';
part 'stone_effect.dart';
part 'ice_effect.dart';
part 'mountain_range_effect.dart';
part 'ocean_waves_effect.dart';
part 'forest_effect.dart';
part 'ocean_effect.dart';
part 'cloud_formation_effect.dart';
part 'clouds_effect.dart';
part 'bark_effect.dart';
part 'leaf_venation_effect.dart';
part 'city_effect.dart';
part 'sky_effect.dart';
part 'ground_texture_effect.dart';
part 'wall_texture_effect.dart';
part 'opacity_effect.dart';
part 'platformer_effect.dart';

enum EffectType {
  brightness,
  contrast,
  invert,
  grayscale,
  sepia,
  threshold,
  pixelate,
  blur,
  sharpen,
  emboss,
  vignette,
  noise,
  colorBalance,
  dithering,
  outline,
  paletteReduction,
  watercolor,
  halftone,
  glow,
  oilPaint,
  gradient,
  fire,
  wood,
  rain,
  crystal,
  stainedGlass,
  glitch,
  metal,
  sparkle,
  particle,
  pulse,
  wave,
  rotate,
  float,
  simpleFloat,
  physicsFloat,
  shake,
  quickShake,
  cameraShake,
  dissolve,
  fadeDissolve,
  melt,
  explosion,
  jello,
  wipe,
  fog,
  stone,
  ice,
  mountainRange,
  oceanWaves,
  forest,
  ocean,
  cloudFormation,
  clouds,
  treeBark,
  leafVenation,
  city,
  sky,
  groundTexture,
  wallTexture,
  opacity,
  platformer
}

/// Base abstract class for all effects
abstract class Effect {
  final EffectType type;
  final Map<String, dynamic> parameters;

  const Effect(this.type, this.parameters);

  /// Apply the effect to the given pixels
  Uint32List apply(Uint32List pixels, int width, int height);

  /// Get the default parameters for this effect
  Map<String, dynamic> getDefaultParameters();
  Map<String, dynamic> getMetadata();

  String getName(BuildContext context) => switch (type) {
        EffectType.brightness => 'Brightness',
        EffectType.contrast => 'Contrast',
        EffectType.invert => 'Invert',
        EffectType.grayscale => 'Grayscale',
        EffectType.sepia => 'Sepia',
        EffectType.threshold => 'Threshold',
        EffectType.pixelate => 'Pixelate',
        EffectType.blur => 'Blur',
        EffectType.sharpen => 'Sharpen',
        EffectType.emboss => 'Emboss',
        EffectType.vignette => 'Vignette',
        EffectType.noise => 'Noise',
        EffectType.colorBalance => 'Color Balance',
        EffectType.dithering => 'Dithering',
        EffectType.outline => 'Outline',
        EffectType.paletteReduction => 'Palette Reduction',
        EffectType.watercolor => 'Watercolor',
        EffectType.halftone => 'Halftone',
        EffectType.glow => 'Glow',
        EffectType.oilPaint => 'Oil Paint',
        EffectType.gradient => 'Gradient Map',
        EffectType.fire => 'Fire',
        EffectType.wood => 'Wood',
        EffectType.rain => 'Rain',
        EffectType.crystal => 'Crystal',
        EffectType.stainedGlass => 'Stained Glass',
        EffectType.glitch => 'Glitch',
        EffectType.metal => 'Metal',
        EffectType.sparkle => 'Sparkle',
        EffectType.particle => 'Particle',
        EffectType.pulse => 'Pulse',
        EffectType.wave => 'Wave',
        EffectType.rotate => 'Rotate',
        EffectType.float => 'Float',
        EffectType.simpleFloat => 'Simple Float',
        EffectType.physicsFloat => 'Physics Float',
        EffectType.shake => 'Shake',
        EffectType.quickShake => 'Quick Shake',
        EffectType.cameraShake => 'Camera Shake',
        EffectType.dissolve => 'Dissolve',
        EffectType.fadeDissolve => 'Fade Dissolve',
        EffectType.melt => 'Melt',
        EffectType.explosion => 'Explosion',
        EffectType.jello => 'Jello',
        EffectType.wipe => 'Wipe',
        EffectType.fog => 'Fog',
        EffectType.stone => 'Stone',
        EffectType.ice => 'Ice',
        EffectType.mountainRange => 'Mountain Range',
        EffectType.oceanWaves => 'Ocean Waves',
        EffectType.forest => 'Forest',
        EffectType.ocean => 'Ocean',
        EffectType.cloudFormation => 'Cloud Formation',
        EffectType.clouds => 'Clouds',
        EffectType.treeBark => 'Tree Bark',
        EffectType.leafVenation => 'Leaf Venation',
        EffectType.city => 'City',
        EffectType.sky => 'Sky',
        EffectType.groundTexture => 'Ground Texture',
        EffectType.wallTexture => 'Wall Texture',
        EffectType.opacity => 'Opacity',
        EffectType.platformer => 'Platformer',
      };

  String getDescription(BuildContext context) => switch (type) {
        // Color & Tone Effects
        EffectType.brightness => 'Adjust image brightness levels',
        EffectType.contrast => 'Enhance or reduce image contrast',
        EffectType.invert => 'Invert all colors in the image',
        EffectType.grayscale => 'Convert to black and white',
        EffectType.sepia => 'Apply vintage sepia tone',
        EffectType.threshold => 'Create high-contrast black/white',
        EffectType.colorBalance => 'Adjust RGB color channels',
        EffectType.gradient => 'Apply gradient color overlay',
        EffectType.paletteReduction => 'Reduce to limited color palette',

        // Blur & Sharpen Effects
        EffectType.pixelate => 'Create pixelated blocks effect',
        EffectType.blur => 'Apply gaussian blur filter',
        EffectType.sharpen => 'Enhance edge definition',

        // Artistic Effects
        EffectType.emboss => 'Create 3D embossed appearance',
        EffectType.vignette => 'Darken edges for focus',
        EffectType.outline => 'Add outline to shapes',
        EffectType.dithering => 'Apply retro dithering pattern',
        EffectType.halftone => 'Simulate comic book printing',
        EffectType.watercolor => 'Create soft watercolor blend',
        EffectType.oilPaint => 'Simulate oil painting strokes',
        EffectType.stainedGlass => 'Create stained glass mosaic',

        // Animation Effects
        EffectType.pulse => 'Rhythmic pulsing animation',
        EffectType.wave => 'Smooth wave motion',
        EffectType.rotate => 'Continuous rotation effect',
        EffectType.float => 'Gentle floating movement',
        EffectType.simpleFloat => 'Basic up/down floating',
        EffectType.physicsFloat => 'Realistic floating physics',
        EffectType.shake => 'Subtle shaking motion',
        EffectType.quickShake => 'Rapid shake animation',
        EffectType.cameraShake => 'Screen shake effect',
        EffectType.jello => 'Bouncy jello wobble',

        // Nature Effects
        EffectType.fire => 'Dynamic fire flames',
        EffectType.wood => 'Natural wood grain texture',
        EffectType.rain => 'Falling rain animation',
        EffectType.ice => 'Frozen ice crystal texture',
        EffectType.stone => 'Rough stone surface',
        EffectType.mountainRange => 'Mountain silhouette backdrop',
        EffectType.oceanWaves => 'Rolling ocean waves',
        EffectType.forest => 'Dense forest background',
        EffectType.ocean => 'Calm ocean surface',
        EffectType.cloudFormation => 'Dynamic cloud formation',
        EffectType.clouds => 'Floating cloud layers',
        EffectType.treeBark => 'Detailed tree bark texture',
        EffectType.leafVenation => 'Leaf vein pattern overlay',
        EffectType.fog => 'Misty fog atmosphere',
        EffectType.sky => 'Beautiful sky gradient',

        // Particle Effects
        EffectType.sparkle => 'Magical sparkle particles',
        EffectType.particle => 'Dynamic particle system',
        EffectType.explosion => 'Explosive burst effect',
        EffectType.glow => 'Soft luminous glow',

        // Distortion Effects
        EffectType.glitch => 'Digital glitch distortion',
        EffectType.dissolve => 'Gradual dissolve transition',
        EffectType.fadeDissolve => 'Smooth fade dissolution',
        EffectType.melt => 'Melting drip effect',
        EffectType.wipe => 'Directional wipe transition',

        // Texture Effects
        EffectType.crystal => 'Crystalline surface texture',
        EffectType.metal => 'Metallic surface finish',
        EffectType.noise => 'Random noise texture',
        EffectType.groundTexture => 'Natural ground surface',
        EffectType.wallTexture => 'Various wall surface textures',

        // Special FX
        EffectType.city => 'Urban cityscape backdrop',
        EffectType.opacity => 'Adjust layer transparency',
        EffectType.platformer => 'Create platformer tile edges',
      };

  bool get isAnimation {
    switch (type) {
      // Animation effects that create movement or time-based changes
      case EffectType.sparkle:
      case EffectType.particle:
      case EffectType.pulse:
      case EffectType.wave:
      case EffectType.rotate:
      case EffectType.float:
      case EffectType.simpleFloat:
      case EffectType.physicsFloat:
      case EffectType.shake:
      case EffectType.quickShake:
      case EffectType.cameraShake:
      case EffectType.dissolve:
      case EffectType.fadeDissolve:
      case EffectType.melt:
      case EffectType.explosion:
      case EffectType.jello:
      case EffectType.wipe:
      case EffectType.rain:
      case EffectType.fire:
      case EffectType.oceanWaves:
      case EffectType.clouds:
      case EffectType.sky:
        return true;

      // Static effects that don't animate
      case EffectType.brightness:
      case EffectType.contrast:
      case EffectType.invert:
      case EffectType.grayscale:
      case EffectType.sepia:
      case EffectType.threshold:
      case EffectType.pixelate:
      case EffectType.blur:
      case EffectType.sharpen:
      case EffectType.emboss:
      case EffectType.vignette:
      case EffectType.noise:
      case EffectType.colorBalance:
      case EffectType.dithering:
      case EffectType.outline:
      case EffectType.paletteReduction:
      case EffectType.watercolor:
      case EffectType.halftone:
      case EffectType.glow:
      case EffectType.oilPaint:
      case EffectType.gradient:
      case EffectType.wood:
      case EffectType.crystal:
      case EffectType.stainedGlass:
      case EffectType.glitch:
      case EffectType.metal:
      case EffectType.stone:
      case EffectType.ice:
      case EffectType.mountainRange:
      case EffectType.forest:
      case EffectType.ocean:
      case EffectType.cloudFormation:
      case EffectType.treeBark:
      case EffectType.leafVenation:
      case EffectType.city:
      case EffectType.fog:
      case EffectType.groundTexture:
      case EffectType.wallTexture:
      case EffectType.opacity:
      case EffectType.platformer:
        return false;
    }
  }

  bool get isPremium {
    switch (type) {
      case EffectType.oilPaint:
      case EffectType.watercolor:
      case EffectType.crystal:
      case EffectType.stainedGlass:
      case EffectType.metal:
      case EffectType.fire:
      case EffectType.wood:
      case EffectType.stone:
      case EffectType.ice:
      case EffectType.mountainRange:
      case EffectType.oceanWaves:
      case EffectType.forest:
      case EffectType.ocean:
      case EffectType.cloudFormation:
      case EffectType.clouds:
      case EffectType.city:
      case EffectType.fog:
      // Premium animation effects
      case EffectType.sparkle:
      case EffectType.particle:
      case EffectType.pulse:
      case EffectType.wave:
      case EffectType.rotate:
      case EffectType.float:
      case EffectType.simpleFloat:
      case EffectType.physicsFloat:
      case EffectType.shake:
      case EffectType.quickShake:
      case EffectType.cameraShake:
      case EffectType.dissolve:
      case EffectType.fadeDissolve:
      case EffectType.melt:
      case EffectType.explosion:
      case EffectType.jello:
      case EffectType.wipe:
      case EffectType.rain:
      case EffectType.sky:
      case EffectType.groundTexture:
      case EffectType.wallTexture:
        return true;

      case EffectType.brightness:
      case EffectType.contrast:
      case EffectType.invert:
      case EffectType.grayscale:
      case EffectType.sepia:
      case EffectType.threshold:
      case EffectType.pixelate:
      case EffectType.blur:
      case EffectType.sharpen:
      case EffectType.emboss:
      case EffectType.vignette:
      case EffectType.noise:
      case EffectType.colorBalance:
      case EffectType.dithering:
      case EffectType.outline:
      case EffectType.paletteReduction:
      case EffectType.halftone:
      case EffectType.glow:
      case EffectType.gradient:
      case EffectType.glitch:
      case EffectType.treeBark:
      case EffectType.leafVenation:
      case EffectType.opacity:
      case EffectType.platformer:
        return false;
    }
  }

  Widget getIcon({double? size, Color? color}) {
    return switch (type) {
      // Effects with matching AppIcons
      EffectType.stainedGlass => AppIcon(AppIcons.church_window, size: size, color: color),
      EffectType.metal => AppIcon(AppIcons.metal_plate, size: size, color: color),
      EffectType.sparkle => AppIcon(AppIcons.sparkles, size: size, color: color),
      EffectType.particle => AppIcon(AppIcons.particle, size: size, color: color),
      EffectType.wave => AppIcon(AppIcons.wave, size: size, color: color),
      EffectType.rotate => AppIcon(AppIcons.rotate_right, size: size, color: color),
      EffectType.float ||
      EffectType.simpleFloat ||
      EffectType.physicsFloat =>
        AppIcon(AppIcons.float, size: size, color: color),
      EffectType.shake ||
      EffectType.quickShake ||
      EffectType.cameraShake =>
        AppIcon(AppIcons.shake_camera, size: size, color: color),
      EffectType.melt => AppIcon(AppIcons.face_melt, size: size, color: color),
      EffectType.explosion => AppIcon(AppIcons.explosion, size: size, color: color),
      EffectType.jello => AppIcon(AppIcons.jelly, size: size, color: color),
      EffectType.wipe => AppIcon(AppIcons.wipe, size: size, color: color),
      EffectType.fog => AppIcon(AppIcons.fog, size: size, color: color),
      EffectType.stone => AppIcon(AppIcons.stone_sphere, size: size, color: color),
      EffectType.ice => AppIcon(AppIcons.ice, size: size, color: color),
      EffectType.mountainRange => AppIcon(AppIcons.mountain_top, size: size, color: color),
      EffectType.oceanWaves || EffectType.ocean => AppIcon(AppIcons.ocean_sea_water, size: size, color: color),
      EffectType.clouds || EffectType.cloudFormation => AppIcon(AppIcons.cloud, size: size, color: color),
      EffectType.treeBark => AppIcon(AppIcons.tree_branch, size: size, color: color),
      EffectType.leafVenation => AppIcon(AppIcons.leaf, size: size, color: color),
      EffectType.city => AppIcon(AppIcons.city, size: size, color: color),

      // Effects using flutter_vector_icons
      EffectType.brightness => Icon(MaterialIcons.brightness_6, size: size, color: color),
      EffectType.contrast => Icon(Icons.contrast, size: size, color: color),
      EffectType.invert => Icon(MaterialIcons.invert_colors, size: size, color: color),
      EffectType.grayscale => Icon(MaterialIcons.monochrome_photos, size: size, color: color),
      EffectType.sepia => Icon(MaterialIcons.filter_vintage, size: size, color: color),
      EffectType.threshold => Icon(MaterialIcons.tune, size: size, color: color),
      EffectType.pixelate => Icon(MaterialIcons.grid_on, size: size, color: color),
      EffectType.blur => Icon(MaterialIcons.blur_on, size: size, color: color),
      EffectType.sharpen => Icon(Feather.aperture, size: size, color: color),
      EffectType.emboss => Icon(MaterialIcons.layers, size: size, color: color),
      EffectType.vignette => Icon(MaterialIcons.vignette, size: size, color: color),
      EffectType.noise => Icon(MaterialIcons.grain, size: size, color: color),
      EffectType.colorBalance => Icon(MaterialIcons.tune, size: size, color: color),
      EffectType.dithering => Icon(MaterialIcons.texture, size: size, color: color),
      EffectType.outline => Icon(MaterialIcons.border_style, size: size, color: color),
      EffectType.paletteReduction => Icon(MaterialIcons.palette, size: size, color: color),
      EffectType.watercolor => Icon(Ionicons.water, size: size, color: color),
      EffectType.halftone => Icon(Icons.grid_3x3, size: size, color: color),
      EffectType.glow => Icon(Feather.sun, size: size, color: color),
      EffectType.oilPaint => Icon(MaterialIcons.brush, size: size, color: color),
      EffectType.gradient => Icon(MaterialIcons.gradient, size: size, color: color),
      EffectType.fire => Icon(MaterialIcons.local_fire_department, size: size, color: color),
      EffectType.wood => Icon(MaterialCommunityIcons.tree, size: size, color: color),
      EffectType.rain => Icon(Feather.cloud_rain, size: size, color: color),
      EffectType.crystal => Icon(Icons.diamond, size: size, color: color),
      EffectType.glitch => Icon(MaterialCommunityIcons.television_classic, size: size, color: color),
      EffectType.pulse => Icon(MaterialCommunityIcons.heart_pulse, size: size, color: color),
      EffectType.dissolve || EffectType.fadeDissolve => Icon(MaterialCommunityIcons.blur, size: size, color: color),
      EffectType.forest => Icon(MaterialCommunityIcons.forest, size: size, color: color),
      EffectType.sky => Icon(MaterialCommunityIcons.weather_partly_cloudy, size: size, color: color),
      EffectType.groundTexture => Icon(MaterialCommunityIcons.terrain, size: size, color: color),
      EffectType.wallTexture => Icon(MaterialCommunityIcons.wall, size: size, color: color),
      EffectType.opacity => Icon(MaterialCommunityIcons.opacity, size: size, color: color),
      EffectType.platformer => Icon(MaterialCommunityIcons.grid, size: size, color: color),
    };
  }

  Color getColor(BuildContext context) {
    return switch (type) {
      // Color & Tone Effects - Warm colors
      EffectType.brightness => Colors.amber,
      EffectType.contrast => Colors.orange,
      EffectType.invert => Colors.purple,
      EffectType.grayscale => Colors.blueGrey,
      EffectType.sepia => const Color(0xFFD2B48C), // Tan/sepia color
      EffectType.threshold => Colors.grey,
      EffectType.colorBalance => Colors.green,
      EffectType.gradient => Colors.pink,
      EffectType.paletteReduction => Colors.indigo,

      // Blur & Sharpen Effects - Cool blues
      EffectType.pixelate => Colors.lightBlue,
      EffectType.blur => Colors.blue,
      EffectType.sharpen => Colors.cyan,

      // Artistic Effects - Creative colors
      EffectType.emboss => Colors.teal,
      EffectType.vignette => const Color(0xFF5D4037), // Brown
      EffectType.outline => Colors.red,
      EffectType.dithering => Colors.deepOrange,
      EffectType.watercolor => const Color(0xFF4FC3F7), // Light blue
      EffectType.halftone => Colors.indigo,
      EffectType.oilPaint => const Color(0xFF8D6E63), // Brown
      EffectType.stainedGlass => const Color(0xFF9C27B0), // Purple

      // Animation Effects - Energetic colors
      EffectType.pulse => const Color(0xFFE91E63), // Pink
      EffectType.wave => const Color(0xFF2196F3), // Blue
      EffectType.rotate => const Color(0xFF673AB7), // Deep purple
      EffectType.float || EffectType.simpleFloat || EffectType.physicsFloat => const Color(0xFF00BCD4), // Cyan
      EffectType.shake || EffectType.quickShake || EffectType.cameraShake => const Color(0xFFFF5722), // Deep orange
      EffectType.jello => const Color(0xFF4CAF50), // Green

      // Nature Effects - Natural colors
      EffectType.fire => const Color(0xFFFF5722), // Red-orange
      EffectType.wood => const Color(0xFF795548), // Brown
      EffectType.rain => const Color(0xFF2196F3), // Blue
      EffectType.ice => const Color(0xFF00BCD4), // Cyan
      EffectType.stone => const Color(0xFF607D8B), // Blue grey
      EffectType.mountainRange => const Color(0xFF455A64), // Dark blue grey
      EffectType.oceanWaves || EffectType.ocean => const Color(0xFF006064), // Teal
      EffectType.forest => const Color(0xFF388E3C), // Green
      EffectType.cloudFormation || EffectType.clouds => const Color(0xFF90A4AE), // Blue grey
      EffectType.treeBark => const Color(0xFF5D4037), // Brown
      EffectType.leafVenation => const Color(0xFF4CAF50), // Green
      EffectType.fog => const Color(0xFFB0BEC5), // Light blue grey
      EffectType.sky => const Color(0xFF81D4FA), // Light sky blue

      // Particle Effects - Bright colors
      EffectType.sparkle => const Color(0xFFFFD700), // Gold
      EffectType.particle => const Color(0xFFFF9800), // Orange
      EffectType.explosion => const Color(0xFFFF5722), // Red-orange
      EffectType.glow => const Color(0xFFFFC107), // Amber

      // Distortion Effects - Electric colors
      EffectType.glitch => const Color(0xFF00FF00), // Bright green
      EffectType.dissolve || EffectType.fadeDissolve => const Color(0xFF9E9E9E), // Grey
      EffectType.melt => const Color(0xFFFF9800), // Orange
      EffectType.wipe => const Color(0xFF607D8B), // Blue grey

      // Texture Effects - Material colors
      EffectType.crystal => const Color(0xFFE1F5FE), // Light cyan
      EffectType.metal => const Color(0xFF616161), // Grey
      EffectType.noise => const Color(0xFF424242), // Dark grey
      EffectType.groundTexture => const Color(0xFF6D4C41), // Brown
      EffectType.wallTexture => const Color(0xFF8D6E63), // Brown

      // Special FX - Unique colors
      EffectType.city => const Color(0xFF37474F), // Dark blue grey
      EffectType.opacity => const Color(0xFF9E9E9E), // Grey
      EffectType.platformer => const Color(0xFF00BCD4), // Cyan
    };
  }

  @override
  String toString() => '${type.name}: $parameters';
}

/// Utility class to manage effects
class EffectsManager {
  /// Apply a single effect to pixels
  static Uint32List applyEffect(
    Uint32List pixels,
    int width,
    int height,
    Effect effect,
  ) {
    return effect.apply(pixels, width, height);
  }

  /// Apply multiple effects in sequence
  static Uint32List applyMultipleEffects(
    Uint32List pixels,
    int width,
    int height,
    List<Effect> effects,
  ) {
    Uint32List result = Uint32List.fromList(pixels);

    for (final effect in effects) {
      result = effect.apply(result, width, height);
    }

    return result;
  }

  /// Create an effect instance based on type
  static Effect createEffect(EffectType type, [Map<String, dynamic>? params]) {
    switch (type) {
      case EffectType.brightness:
        return BrightnessEffect(params);
      case EffectType.contrast:
        return ContrastEffect(params);
      case EffectType.invert:
        return InvertEffect(params);
      case EffectType.grayscale:
        return GrayscaleEffect(params);
      case EffectType.sepia:
        return SepiaEffect(params);
      case EffectType.threshold:
        return ThresholdEffect(params);
      case EffectType.pixelate:
        return PixelateEffect(params);
      case EffectType.blur:
        return BlurEffect(params);
      case EffectType.sharpen:
        return SharpenEffect(params);
      case EffectType.emboss:
        return EmbossEffect(params);
      case EffectType.vignette:
        return VignetteEffect(params);
      case EffectType.noise:
        return NoiseEffect(params);
      case EffectType.colorBalance:
        return ColorBalanceEffect(params);
      case EffectType.dithering:
        return DitheringEffect(params);
      case EffectType.outline:
        return OutlineEffect(params);
      case EffectType.paletteReduction:
        return PaletteReductionEffect(params);
      case EffectType.watercolor:
        return WatercolorEffect(params);
      case EffectType.halftone:
        return HalftoneEffect(params);
      case EffectType.glow:
        return GlowEffect(params);
      case EffectType.oilPaint:
        return OilPaintEffect(params);
      case EffectType.gradient:
        return GradientEffect(params);
      case EffectType.fire:
        return FireEffect(params);
      case EffectType.wood:
        return WoodEffect(params);
      case EffectType.rain:
        return RainEffect(params);
      case EffectType.crystal:
        return CrystalEffect(params);
      case EffectType.stainedGlass:
        return StainedGlassEffect(params);
      case EffectType.glitch:
        return GlitchEffect(params);
      case EffectType.metal:
        return MetalEffect(params);
      case EffectType.sparkle:
        return SparkleEffect(params);
      case EffectType.particle:
        return ParticleEffect(params);
      case EffectType.pulse:
        return PulseEffect(params);
      case EffectType.wave:
        return WaveEffect(params);
      case EffectType.rotate:
        return RotateEffect(params);
      case EffectType.float:
        return FloatEffect(params);
      case EffectType.simpleFloat:
        return SimpleFloatEffect(params);
      case EffectType.physicsFloat:
        return PhysicsFloatEffect(params);
      case EffectType.shake:
        return ShakeEffect(params);
      case EffectType.quickShake:
        return QuickShakeEffect(params);
      case EffectType.cameraShake:
        return CameraShakeEffect(params);
      case EffectType.dissolve:
        return DissolveEffect(params);
      case EffectType.fadeDissolve:
        return FadeDissolveEffect(params);
      case EffectType.melt:
        return MeltEffect(params);
      case EffectType.explosion:
        return ExplosionEffect(params);
      case EffectType.jello:
        return JelloEffect(params);
      case EffectType.wipe:
        return WipeEffect(params);
      case EffectType.fog:
        return FogEffect(params);
      case EffectType.stone:
        return StoneEffect(params);
      case EffectType.ice:
        return IceEffect(params);
      case EffectType.mountainRange:
        return MountainRangeEffect(params);
      case EffectType.oceanWaves:
        return OceanWavesEffect(params);
      case EffectType.forest:
        return ForestEffect(params);
      case EffectType.ocean:
        return OceanEffect(params);
      case EffectType.cloudFormation:
        return CloudFormationEffect(params);
      case EffectType.clouds:
        return CloudsEffect(params);
      case EffectType.treeBark:
        return TreeBarkEffect(params);
      case EffectType.leafVenation:
        return LeafVenationEffect(params);
      case EffectType.city:
        return CityEffect(params);
      case EffectType.sky:
        return SkyEffect(params);
      case EffectType.groundTexture:
        return GroundTextureEffect(params);
      case EffectType.wallTexture:
        return WallTextureEffect(params);
      case EffectType.opacity:
        return OpacityEffect(params);
      case EffectType.platformer:
        return PlatformerEffect(params);
    }
  }

  static Effect? effectFromJson(Map<String, dynamic> json) {
    try {
      final type = EffectType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => EffectType.brightness,
      );
      return createEffect(type, Map<String, dynamic>.from(json['parameters']));
    } catch (e) {
      return null;
    }
  }
}
