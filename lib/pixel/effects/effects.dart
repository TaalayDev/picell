import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../data/models/selection_region.dart';
import '../../ui/widgets/app_icon.dart';
import '../../ui/widgets/fields/ui_field.dart';
import '../pixel_utils.dart';
import '../../l10n/strings.dart';

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
part 'perlin_worms_effect.dart';
part 'voronoi_effect.dart';
part 'crt_effect.dart';
part 'lcd_matrix_effect.dart';
part 'chromatic_aberration_effect.dart';
part 'drop_shadow_effect.dart';
part 'normal_map_effect.dart';
part 'color_cycling_effect.dart';
part 'rim_light_effect.dart';
part 'squash_stretch_effect.dart';
part 'wind_sway_effect.dart';
part 'hit_flash_effect.dart';
part 'ghost_trail_effect.dart';
part 'starfield_effect.dart';
part 'electric_arc_effect.dart';
part 'blizzard_effect.dart';
part 'portal_vortex_effect.dart';
part 'energy_shield_effect.dart';
part 'radiant_rays_effect.dart';
part 'burning_embers_effect.dart';
part 'underwater_caustics_effect.dart';
part 'rising_bubbles_effect.dart';
part 'slime_drip_effect.dart';
part 'radial_shockwave_effect.dart';
part 'slash_arc_effect.dart';
part 'hologram_glitch_effect.dart';

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
  platformer,
  perlinWorms,
  voronoi,
  crt,
  lcdMatrix,
  chromaticAberration,
  dropShadow,
  normalMap,
  colorCycling,
  rimLight,
  squashStretch,
  windSway,
  hitFlash,
  ghostTrail,
  starfield,
  electricArc,
  blizzard,
  portalVortex,
  energyShield,
  radiantRays,
  burningEmbers,
  underwaterCaustics,
  risingBubbles,
  slimeDrip,
  radialShockwave,
  slashArc,
  hologramGlitch,
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

  /// Return a strongly-typed list of [UIField] descriptors for this effect's
  /// parameters.  Override in subclasses for full control; the default
  /// implementation converts the legacy [getMetadata()] map automatically.
  List<UIField> getFields() => _fieldsFromMetadata(getMetadata());

  String getName(BuildContext context) => switch (type) {
        EffectType.brightness => Strings.of(context).effectBrightness,
        EffectType.contrast => Strings.of(context).effectContrast,
        EffectType.invert => Strings.of(context).effectInvert,
        EffectType.grayscale => Strings.of(context).effectGrayscale,
        EffectType.sepia => Strings.of(context).effectSepia,
        EffectType.threshold => Strings.of(context).effectThreshold,
        EffectType.pixelate => Strings.of(context).effectPixelate,
        EffectType.blur => Strings.of(context).effectBlur,
        EffectType.sharpen => Strings.of(context).effectSharpen,
        EffectType.emboss => 'Emboss',
        EffectType.vignette => Strings.of(context).effectVignette,
        EffectType.noise => Strings.of(context).effectNoise,
        EffectType.colorBalance => 'Color Balance',
        EffectType.dithering => 'Dithering',
        EffectType.outline => 'Outline',
        EffectType.paletteReduction => 'Palette Reduction',
        EffectType.watercolor => 'Watercolor',
        EffectType.halftone => 'Halftone',
        EffectType.glow => Strings.of(context).effectGlow,
        EffectType.oilPaint => 'Oil Paint',
        EffectType.gradient => 'Gradient Map',
        EffectType.fire => Strings.of(context).effectFire,
        EffectType.wood => 'Wood',
        EffectType.rain => Strings.of(context).effectRain,
        EffectType.crystal => 'Crystal',
        EffectType.stainedGlass => 'Stained Glass',
        EffectType.glitch => Strings.of(context).effectGlitch,
        EffectType.metal => 'Metal',
        EffectType.sparkle => Strings.of(context).effectSparkle,
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
        EffectType.perlinWorms => 'Perlin Worms',
        EffectType.voronoi => 'Voronoi',
        EffectType.crt => 'CRT & Scanlines',
        EffectType.lcdMatrix => 'Handheld LCD & Game Boy',
        EffectType.chromaticAberration => 'Chromatic Aberration',
        EffectType.dropShadow => 'Isometric & 2D Drop Shadow',
        EffectType.normalMap => '2D Normal Map Generator',
        EffectType.colorCycling => 'Color Cycling (Palette Shift)',
        EffectType.rimLight => 'Edge Highlight & Rim Light',
        EffectType.squashStretch => 'Squash & Stretch',
        EffectType.windSway => 'Wind Sway & Foliage',
        EffectType.hitFlash => 'Hit Flash & Damage Blink',
        EffectType.ghostTrail => 'Ghost Trail & After-Image',
        EffectType.starfield => 'Twinkling Starfield & Space',
        EffectType.electricArc => 'Electric Arc & Lightning',
        EffectType.blizzard => 'Pixel Blizzard & Snowfall',
        EffectType.portalVortex => 'Portal Vortex & Rift',
        EffectType.energyShield => 'Energy Shield & Forcefield',
        EffectType.radiantRays => 'Radiant Ascension & God Rays',
        EffectType.burningEmbers => 'Burning Embers & Soul Dissolve',
        EffectType.underwaterCaustics => 'Underwater Caustics & Wobble',
        EffectType.risingBubbles => 'Rising Bubbles & Potion Fizz',
        EffectType.slimeDrip => 'Slime Drip & Toxic Splatter',
        EffectType.radialShockwave => 'Radial Shockwave & Blast',
        EffectType.slashArc => 'Melee Slash Wave & Arc',
        EffectType.hologramGlitch => 'Hologram Glitch & Flicker',
      };

  String getDescription(BuildContext context) => switch (type) {
        // Color & Tone Effects
        EffectType.brightness => 'Adjust image brightness levels',
        EffectType.contrast => 'Enhance or reduce image contrast',
        EffectType.invert => 'Invert all colors in the image',
        EffectType.grayscale => 'Convert image to black and white',
        EffectType.sepia => 'Apply vintage sepia tone',
        EffectType.threshold => 'Convert to high-contrast binary',
        EffectType.colorBalance => 'Adjust color channel balance',
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
        EffectType.perlinWorms =>
          'Generate organic worm-like patterns with Perlin noise',
        EffectType.voronoi =>
          'Create cellular Voronoi diagram patterns with multiple modes',
        EffectType.crt =>
          'Simulate retro CRT display with scanlines, curvature, and phosphor mask',
        EffectType.lcdMatrix =>
          'Simulate retro Game Boy & handheld dot-matrix LCD displays with dithering',
        EffectType.chromaticAberration =>
          'Prismatic lens RGB split and color fringing distortion',
        EffectType.dropShadow =>
          'Cast 2D drop shadows and isometric ground-plane projections',
        EffectType.normalMap =>
          'Generate tangent-space normal maps for 2D dynamic lighting',
        EffectType.colorCycling =>
          'Classic 8-bit/16-bit retro animated palette cycling',
        EffectType.rimLight =>
          'Directional 2D rim lighting and silhouette edge highlights',
        EffectType.squashStretch =>
          'Volume-preserving elastic squash and stretch character animation',
        EffectType.windSway =>
          'Organic wind swaying and bending for plants, grass, and cloth',
        EffectType.hitFlash =>
          'Retro video game impact damage flashes and invulnerability blinks',
        EffectType.ghostTrail =>
          'High-speed dash and teleport after-image speed trails',
        EffectType.starfield =>
          'Procedural twinkling starfield, cosmic nebula dust, and meteor streaks',
        EffectType.electricArc =>
          'Fractal lightning bolts, electric arcs, and ionized plasma discharge',
        EffectType.blizzard =>
          'Swirling snowfall, howling blizzard winds, and frost accumulation',
        EffectType.portalVortex =>
          'Swirling dimensional vortex, event horizon void, and accretion disk',
        EffectType.energyShield =>
          'Pulsing hexagonal forcefield, spherical bubble, and kinetic ripples',
        EffectType.radiantRays =>
          'Volumetric vertical god ray light pillars and ascending stardust motes',
        EffectType.burningEmbers =>
          'Progressive scorch dissolution, crumbling ash, and floating embers',
        EffectType.underwaterCaustics =>
          'Shimmering refractive sunlight caustics, aquatic tint, and fluid sway',
        EffectType.risingBubbles =>
          'Buoyant circular air bubbles, lateral wobble flutter, and surface pops',
        EffectType.slimeDrip =>
          'Viscous fluid droplet swelling, stretching necks, and ground splatters',
        EffectType.radialShockwave =>
          'Expanding supersonic pressure ring, ground-impact shockwave, and debris',
        EffectType.slashArc =>
          'Curved crescent katana slash wave, cutting edge glint, and sparks',
        EffectType.hologramGlitch =>
          'Holographic scanline raster, beam flutter, and slice tear jitter',
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
      case EffectType.colorCycling:
      case EffectType.squashStretch:
      case EffectType.windSway:
      case EffectType.hitFlash:
      case EffectType.ghostTrail:
      case EffectType.starfield:
      case EffectType.electricArc:
      case EffectType.blizzard:
      case EffectType.portalVortex:
      case EffectType.energyShield:
      case EffectType.radiantRays:
      case EffectType.burningEmbers:
      case EffectType.underwaterCaustics:
      case EffectType.risingBubbles:
      case EffectType.slimeDrip:
      case EffectType.radialShockwave:
      case EffectType.slashArc:
      case EffectType.hologramGlitch:
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
      case EffectType.perlinWorms:
      case EffectType.voronoi:
      case EffectType.crt:
      case EffectType.lcdMatrix:
      case EffectType.chromaticAberration:
      case EffectType.dropShadow:
      case EffectType.normalMap:
      case EffectType.rimLight:
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
      case EffectType.perlinWorms:
      case EffectType.voronoi:
      case EffectType.crt:
      case EffectType.lcdMatrix:
      case EffectType.chromaticAberration:
      case EffectType.dropShadow:
      case EffectType.normalMap:
      case EffectType.colorCycling:
      case EffectType.rimLight:
      case EffectType.squashStretch:
      case EffectType.windSway:
      case EffectType.hitFlash:
      case EffectType.ghostTrail:
      case EffectType.starfield:
      case EffectType.electricArc:
      case EffectType.blizzard:
      case EffectType.portalVortex:
      case EffectType.energyShield:
      case EffectType.radiantRays:
      case EffectType.burningEmbers:
      case EffectType.underwaterCaustics:
      case EffectType.risingBubbles:
      case EffectType.slimeDrip:
      case EffectType.radialShockwave:
      case EffectType.slashArc:
      case EffectType.hologramGlitch:
        return false;
    }
  }

  Widget getIcon({double? size, Color? color}) {
    return switch (type) {
      // Effects with matching AppIcons
      EffectType.stainedGlass =>
        AppIcon(AppIcons.church_window, size: size, color: color),
      EffectType.metal =>
        AppIcon(AppIcons.metal_plate, size: size, color: color),
      EffectType.sparkle =>
        AppIcon(AppIcons.sparkles, size: size, color: color),
      EffectType.particle =>
        AppIcon(AppIcons.particle, size: size, color: color),
      EffectType.wave => AppIcon(AppIcons.wave, size: size, color: color),
      EffectType.rotate =>
        AppIcon(AppIcons.rotate_right, size: size, color: color),
      EffectType.float ||
      EffectType.simpleFloat ||
      EffectType.physicsFloat =>
        AppIcon(AppIcons.float, size: size, color: color),
      EffectType.shake ||
      EffectType.quickShake ||
      EffectType.cameraShake =>
        AppIcon(AppIcons.shake_camera, size: size, color: color),
      EffectType.melt => AppIcon(AppIcons.face_melt, size: size, color: color),
      EffectType.explosion =>
        AppIcon(AppIcons.explosion, size: size, color: color),
      EffectType.jello => AppIcon(AppIcons.jelly, size: size, color: color),
      EffectType.wipe => AppIcon(AppIcons.wipe, size: size, color: color),
      EffectType.fog => AppIcon(AppIcons.fog, size: size, color: color),
      EffectType.stone =>
        AppIcon(AppIcons.stone_sphere, size: size, color: color),
      EffectType.ice => AppIcon(AppIcons.ice, size: size, color: color),
      EffectType.mountainRange =>
        AppIcon(AppIcons.mountain_top, size: size, color: color),
      EffectType.oceanWaves ||
      EffectType.ocean =>
        AppIcon(AppIcons.ocean_sea_water, size: size, color: color),
      EffectType.clouds ||
      EffectType.cloudFormation =>
        AppIcon(AppIcons.cloud, size: size, color: color),
      EffectType.treeBark =>
        AppIcon(AppIcons.tree_branch, size: size, color: color),
      EffectType.leafVenation =>
        AppIcon(AppIcons.leaf, size: size, color: color),
      EffectType.city => AppIcon(AppIcons.city, size: size, color: color),

      // Effects using flutter_vector_icons
      EffectType.brightness =>
        Icon(MaterialIcons.brightness_6, size: size, color: color),
      EffectType.contrast => Icon(Icons.contrast, size: size, color: color),
      EffectType.invert =>
        Icon(MaterialIcons.invert_colors, size: size, color: color),
      EffectType.grayscale =>
        Icon(MaterialIcons.monochrome_photos, size: size, color: color),
      EffectType.sepia =>
        Icon(MaterialIcons.filter_vintage, size: size, color: color),
      EffectType.threshold =>
        Icon(MaterialIcons.tune, size: size, color: color),
      EffectType.pixelate =>
        Icon(MaterialIcons.grid_on, size: size, color: color),
      EffectType.blur => Icon(MaterialIcons.blur_on, size: size, color: color),
      EffectType.sharpen => Icon(Feather.aperture, size: size, color: color),
      EffectType.emboss => Icon(MaterialIcons.layers, size: size, color: color),
      EffectType.vignette =>
        Icon(MaterialIcons.vignette, size: size, color: color),
      EffectType.noise => Icon(MaterialIcons.grain, size: size, color: color),
      EffectType.colorBalance =>
        Icon(MaterialIcons.tune, size: size, color: color),
      EffectType.dithering =>
        Icon(MaterialIcons.texture, size: size, color: color),
      EffectType.outline =>
        Icon(MaterialIcons.border_style, size: size, color: color),
      EffectType.paletteReduction =>
        Icon(MaterialIcons.palette, size: size, color: color),
      EffectType.watercolor => Icon(Ionicons.water, size: size, color: color),
      EffectType.halftone => Icon(Icons.grid_3x3, size: size, color: color),
      EffectType.glow => Icon(Feather.sun, size: size, color: color),
      EffectType.oilPaint =>
        Icon(MaterialIcons.brush, size: size, color: color),
      EffectType.gradient =>
        Icon(MaterialIcons.gradient, size: size, color: color),
      EffectType.fire =>
        Icon(MaterialIcons.local_fire_department, size: size, color: color),
      EffectType.wood =>
        Icon(MaterialCommunityIcons.tree, size: size, color: color),
      EffectType.rain => Icon(Feather.cloud_rain, size: size, color: color),
      EffectType.crystal => Icon(Icons.diamond, size: size, color: color),
      EffectType.glitch => Icon(MaterialCommunityIcons.television_classic,
          size: size, color: color),
      EffectType.pulse =>
        Icon(MaterialCommunityIcons.heart_pulse, size: size, color: color),
      EffectType.dissolve ||
      EffectType.fadeDissolve =>
        Icon(MaterialCommunityIcons.blur, size: size, color: color),
      EffectType.forest =>
        Icon(MaterialCommunityIcons.forest, size: size, color: color),
      EffectType.sky => Icon(MaterialCommunityIcons.weather_partly_cloudy,
          size: size, color: color),
      EffectType.groundTexture =>
        Icon(MaterialCommunityIcons.terrain, size: size, color: color),
      EffectType.wallTexture =>
        Icon(MaterialCommunityIcons.wall, size: size, color: color),
      EffectType.opacity =>
        Icon(MaterialCommunityIcons.opacity, size: size, color: color),
      EffectType.platformer =>
        Icon(MaterialCommunityIcons.grid, size: size, color: color),
      EffectType.perlinWorms =>
        Icon(MaterialCommunityIcons.creation, size: size, color: color),
      EffectType.voronoi =>
        Icon(MaterialCommunityIcons.hexagon_multiple, size: size, color: color),
      EffectType.crt =>
        Icon(Icons.tv, size: size, color: color),
      EffectType.lcdMatrix =>
        Icon(Icons.videogame_asset, size: size, color: color),
      EffectType.chromaticAberration =>
        Icon(Icons.filter_tilt_shift, size: size, color: color),
      EffectType.dropShadow =>
        Icon(Icons.layers, size: size, color: color),
      EffectType.normalMap =>
        Icon(Icons.explore, size: size, color: color),
      EffectType.colorCycling =>
        Icon(Icons.sync, size: size, color: color),
      EffectType.rimLight =>
        Icon(Icons.wb_sunny, size: size, color: color),
      EffectType.squashStretch =>
        Icon(Icons.swap_vert, size: size, color: color),
      EffectType.windSway =>
        Icon(Icons.air, size: size, color: color),
      EffectType.hitFlash =>
        Icon(Icons.flash_on, size: size, color: color),
      EffectType.ghostTrail =>
        Icon(Icons.fast_forward, size: size, color: color),
      EffectType.starfield =>
        Icon(Icons.auto_awesome, size: size, color: color),
      EffectType.electricArc =>
        Icon(Icons.bolt, size: size, color: color),
      EffectType.blizzard =>
        Icon(Icons.ac_unit, size: size, color: color),
      EffectType.portalVortex =>
        Icon(Icons.cyclone, size: size, color: color),
      EffectType.energyShield =>
        Icon(Icons.shield, size: size, color: color),
      EffectType.radiantRays =>
        Icon(Icons.wb_twilight, size: size, color: color),
      EffectType.burningEmbers =>
        Icon(Icons.local_fire_department, size: size, color: color),
      EffectType.underwaterCaustics =>
        Icon(Icons.waves, size: size, color: color),
      EffectType.risingBubbles =>
        Icon(Icons.bubble_chart, size: size, color: color),
      EffectType.slimeDrip =>
        Icon(Icons.water_drop, size: size, color: color),
      EffectType.radialShockwave =>
        Icon(Icons.adjust, size: size, color: color),
      EffectType.slashArc =>
        Icon(Icons.flash_on, size: size, color: color),
      EffectType.hologramGlitch =>
        Icon(Icons.cast, size: size, color: color),
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
      EffectType.float ||
      EffectType.simpleFloat ||
      EffectType.physicsFloat =>
        const Color(0xFF00BCD4), // Cyan
      EffectType.shake ||
      EffectType.quickShake ||
      EffectType.cameraShake =>
        const Color(0xFFFF5722), // Deep orange
      EffectType.jello => const Color(0xFF4CAF50), // Green

      // Nature Effects - Natural colors
      EffectType.fire => const Color(0xFFFF5722), // Red-orange
      EffectType.wood => const Color(0xFF795548), // Brown
      EffectType.rain => const Color(0xFF2196F3), // Blue
      EffectType.ice => const Color(0xFF00BCD4), // Cyan
      EffectType.stone => const Color(0xFF607D8B), // Blue grey
      EffectType.mountainRange => const Color(0xFF455A64), // Dark blue grey
      EffectType.oceanWaves ||
      EffectType.ocean =>
        const Color(0xFF006064), // Teal
      EffectType.forest => const Color(0xFF388E3C), // Green
      EffectType.cloudFormation ||
      EffectType.clouds =>
        const Color(0xFF90A4AE), // Blue grey
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
      EffectType.dissolve ||
      EffectType.fadeDissolve =>
        const Color(0xFF9E9E9E), // Grey
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
      EffectType.perlinWorms => const Color(0xFF9C27B0), // Purple
      EffectType.voronoi => const Color(0xFF00BCD4), // Cyan
      EffectType.crt => const Color(0xFF00E5FF), // Retro phosphor cyan
      EffectType.lcdMatrix => const Color(0xFF8BAC0F), // DMG Game Boy Green
      EffectType.chromaticAberration => const Color(0xFFFF2A6D), // Synthwave Neon Pink
      EffectType.dropShadow => const Color(0xFF546E7A), // Slate shadow grey
      EffectType.normalMap => const Color(0xFF8080FF), // Tangent normal blue-violet
      EffectType.colorCycling => const Color(0xFF00E676), // Vibrant cycling green
      EffectType.rimLight => const Color(0xFFFFD54F), // Warm sunlight gold
      EffectType.squashStretch => const Color(0xFFFF7043), // Elastic coral orange
      EffectType.windSway => const Color(0xFF66BB6A), // Foliage wind green
      EffectType.hitFlash => const Color(0xFFFF1744), // Damage flash crimson
      EffectType.ghostTrail => const Color(0xFF29B6F6), // Speed phantom light blue
      EffectType.starfield => const Color(0xFF7C4DFF), // Deep cosmic starlight purple
      EffectType.electricArc => const Color(0xFF00E5FF), // Ionized electric cyan
      EffectType.blizzard => const Color(0xFF80D8FF), // Frosted ice blue
      EffectType.portalVortex => const Color(0xFFD500F9), // Electric violet portal
      EffectType.energyShield => const Color(0xFF00B0FF), // Forcefield electric blue
      EffectType.radiantRays => const Color(0xFFFFD700), // Holy ascension gold
      EffectType.burningEmbers => const Color(0xFFFF6D00), // Incandescent flame orange
      EffectType.underwaterCaustics => const Color(0xFF00E5FF), // Tropical cyan caustics
      EffectType.risingBubbles => const Color(0xFF80DEEA), // Effervescent aqua
      EffectType.slimeDrip => const Color(0xFF76FF03), // Toxic acid lime green
      EffectType.radialShockwave => const Color(0xFFFF9100), // Impact blast amber orange
      EffectType.slashArc => const Color(0xFFFF1744), // Crimson blade strike red
      EffectType.hologramGlitch => const Color(0xFF00E5FF), // Hologram laser cyan
    };
  }

  @override
  String toString() => '${type.name}: $parameters';

  // ---------------------------------------------------------------------------
  // Legacy metadata → UIField conversion
  // ---------------------------------------------------------------------------

  static List<UIField> _fieldsFromMetadata(Map<String, dynamic> metadata) {
    final fields = <UIField>[];

    for (final entry in metadata.entries) {
      final key = entry.key;
      final meta = entry.value;

      if (meta is! Map<String, dynamic>) continue;

      final label = meta['label'] as String? ?? key;
      final description = meta['description'] as String?;
      final type = meta['type'] as String? ?? 'slider';

      switch (type) {
        case 'slider':
          fields.add(SliderField(
            key: key,
            label: label,
            description: description,
            min: (meta['min'] as num?)?.toDouble() ?? 0.0,
            max: (meta['max'] as num?)?.toDouble() ?? 1.0,
            divisions: meta['divisions'] as int?,
            isInteger: meta['min'] is int && meta['max'] is int,
          ));
          break;
        case 'color':
          fields.add(
              ColorField(key: key, label: label, description: description));
          break;
        case 'select':
          final rawOptions = meta['options'];
          final options = <dynamic, String>{};
          if (rawOptions is Map) {
            for (final e in rawOptions.entries) {
              options[e.key] = e.value.toString();
            }
          } else if (rawOptions is List) {
            for (final item in rawOptions) {
              options[item] = item.toString();
            }
          }
          fields.add(SelectField(
            key: key,
            label: label,
            description: description,
            options: options,
          ));
          break;
        case 'bool':
          fields
              .add(BoolField(key: key, label: label, description: description));
          break;
        default:
          // Unknown type — skip
          break;
      }
    }

    return fields;
  }
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

  /// Canvases up to this many pixels apply effects synchronously; larger
  /// ones are worth the isolate round-trip.
  static const int _asyncEffectsPixelThreshold = 128 * 128;

  /// Like [applyMultipleEffects], but runs in a background isolate for
  /// large canvases so heavy effects (noise, oil paint, Voronoi, ...) don't
  /// block the UI thread. On web `compute` runs on the main thread; callers
  /// should keep their debounce in place.
  static Future<Uint32List> applyMultipleEffectsAsync(
    Uint32List pixels,
    int width,
    int height,
    List<Effect> effects,
  ) {
    if (effects.isEmpty) return Future.value(pixels);
    if (width * height <= _asyncEffectsPixelThreshold) {
      return Future.value(applyMultipleEffects(pixels, width, height, effects));
    }
    return compute(_applyMultipleEffectsForCompute, (
      pixels: pixels,
      width: width,
      height: height,
      effects: effects,
    ));
  }

  static Uint32List _applyMultipleEffectsForCompute(
    ({Uint32List pixels, int width, int height, List<Effect> effects}) args,
  ) {
    return applyMultipleEffects(args.pixels, args.width, args.height, args.effects);
  }

  static Uint32List applyEffectToSelection(
    Uint32List pixels,
    int width,
    int height,
    Effect effect,
    SelectionRegion selectionRegion,
  ) {
    return applyMultipleEffectsToSelection(
      pixels,
      width,
      height,
      [effect],
      selectionRegion,
    );
  }

  static Uint32List applyMultipleEffectsToSelection(
    Uint32List pixels,
    int width,
    int height,
    List<Effect> effects,
    SelectionRegion selectionRegion,
  ) {
    if (effects.isEmpty) {
      return Uint32List.fromList(pixels);
    }

    final processedPixels = applyMultipleEffects(
      pixels,
      width,
      height,
      effects,
    );

    return mergeSelectionPixels(
      originalPixels: pixels,
      processedPixels: processedPixels,
      width: width,
      height: height,
      selectionRegion: selectionRegion,
    );
  }

  static Uint32List mergeSelectionPixels({
    required Uint32List originalPixels,
    required Uint32List processedPixels,
    required int width,
    required int height,
    required SelectionRegion selectionRegion,
  }) {
    final result = Uint32List.fromList(originalPixels);
    final selectedIndices = selectionRegion.getSelectedPixelIndices(
      width,
      height,
    );

    for (final index in selectedIndices) {
      if (index >= 0 &&
          index < result.length &&
          index < processedPixels.length) {
        result[index] = processedPixels[index];
      }
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
      case EffectType.perlinWorms:
        return PerlinWormsEffect(params);
      case EffectType.voronoi:
        return VoronoiEffect(params);
      case EffectType.crt:
        return CrtEffect(params);
      case EffectType.lcdMatrix:
        return LcdMatrixEffect(params);
      case EffectType.chromaticAberration:
        return ChromaticAberrationEffect(params);
      case EffectType.dropShadow:
        return DropShadowEffect(params);
      case EffectType.normalMap:
        return NormalMapEffect(params);
      case EffectType.colorCycling:
        return ColorCyclingEffect(params);
      case EffectType.rimLight:
        return RimLightEffect(params);
      case EffectType.squashStretch:
        return SquashStretchEffect(params);
      case EffectType.windSway:
        return WindSwayEffect(params);
      case EffectType.hitFlash:
        return HitFlashEffect(params);
      case EffectType.ghostTrail:
        return GhostTrailEffect(params);
      case EffectType.starfield:
        return StarfieldEffect(params);
      case EffectType.electricArc:
        return ElectricArcEffect(params);
      case EffectType.blizzard:
        return BlizzardEffect(params);
      case EffectType.portalVortex:
        return PortalVortexEffect(params);
      case EffectType.energyShield:
        return EnergyShieldEffect(params);
      case EffectType.radiantRays:
        return RadiantRaysEffect(params);
      case EffectType.burningEmbers:
        return BurningEmbersEffect(params);
      case EffectType.underwaterCaustics:
        return UnderwaterCausticsEffect(params);
      case EffectType.risingBubbles:
        return RisingBubblesEffect(params);
      case EffectType.slimeDrip:
        return SlimeDripEffect(params);
      case EffectType.radialShockwave:
        return RadialShockwaveEffect(params);
      case EffectType.slashArc:
        return SlashArcEffect(params);
      case EffectType.hologramGlitch:
        return HologramGlitchEffect(params);
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
