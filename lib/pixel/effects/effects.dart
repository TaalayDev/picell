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
part 'breathing_effect.dart';
part 'glow_pulse_effect.dart';
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
part 'solar_eclipse_effect.dart';
part 'meteor_shower_effect.dart';
part 'autumn_wind_effect.dart';
part 'soul_wisps_effect.dart';
part 'abyssal_tentacles_effect.dart';
part 'cursed_chains_effect.dart';
part 'beam_teleport_effect.dart';
part 'danger_alarm_effect.dart';
part 'coin_fountain_effect.dart';
part 'magma_fissures_effect.dart';
part 'frost_glaze_effect.dart';
part 'dragon_aura_effect.dart';
part 'cellular_dungeon_effect.dart';
part 'gothic_rosette_effect.dart';
part 'runic_maze_effect.dart';
part 'circuit_board_effect.dart';
part 'deep_space_nebula_effect.dart';
part 'spaceship_hull_effect.dart';
part 'bismuth_crystals_effect.dart';
part 'coral_reef_effect.dart';
part 'basalt_columns_effect.dart';
part 'waterfall_cascade_effect.dart';
part 'firefly_swarm_effect.dart';
part 'whispering_reeds_effect.dart';
part 'risograph_print_effect.dart';
part 'pixel_sorting_effect.dart';
part 'ink_crosshatch_effect.dart';
part 'rust_corrosion_effect.dart';
part 'worn_fabric_effect.dart';
part 'cracked_ceramic_effect.dart';
part 'moss_lichen_effect.dart';
part 'paint_peeling_effect.dart';
part 'texture_effect_utils.dart';
part 'kaleidoscope_effect.dart';
part 'topographic_contours_effect.dart';
part 'isometric_extrusion_effect.dart';
part 'paper_cutout_effect.dart';
part 'cel_shading_effect.dart';
part 'low_poly_facets_effect.dart';
part 'ascii_mosaic_effect.dart';
part 'geyser_vent_effect.dart';
part 'stalactite_drips_effect.dart';
part 'woodblock_ukiyoe_effect.dart';
part 'cyanotype_print_effect.dart';
part 'linocut_stamp_effect.dart';
part 'byzantine_mosaic_effect.dart';
part 'chalk_pastel_effect.dart';
part 'wax_sgraffito_effect.dart';
part 'ben_day_comic_effect.dart';
part 'delftware_tile_effect.dart';
part 'thermal_receipt_effect.dart';
part 'lichen_moss_effect.dart';
part 'spore_bloom_effect.dart';
part 'banyan_mangrove_effect.dart';
part 'sunbeam_god_rays_effect.dart';
part 'dust_devil_effect.dart';
part 'aurora_curtains_effect.dart';
part 'glacial_crevasse_effect.dart';
part 'sand_dunes_effect.dart';
part 'tidal_rock_pool_effect.dart';
part 'roman_travertine_effect.dart';
part 'kintsugi_lacquer_effect.dart';
part 'petrified_agate_effect.dart';
part 'voronoi_shatter_effect.dart';
part 'wind_ash_dispersal_effect.dart';
part 'lateral_slice_glitch_effect.dart';
part 'directional_motion_blur_effect.dart';
part 'radial_zoom_blur_effect.dart';
part 'dithered_frosted_blur_effect.dart';
part 'luminance_gradient_map_effect.dart';
part 'directional_light_ramp_effect.dart';
part 'silhouette_depth_bevel_effect.dart';
part 'action_speed_lines_effect.dart';
part 'chromatic_echo_dash_effect.dart';
part 'booster_thruster_effect.dart';
part 'crown_soul_fire_effect.dart';
part 'hanging_icicles_effect.dart';
part 'viscous_slime_effect.dart';
part 'arc_lightning_effect.dart';
part 'ki_flare_aura_effect.dart';
part 'orbiting_runes_halo_effect.dart';
part 'hexagonal_aegis_effect.dart';
part 'crystal_shard_reflector_effect.dart';
part 'gravity_singularity_effect.dart';
part 'stomp_dust_impact_effect.dart';
part 'water_ripple_wake_effect.dart';
part 'sprouting_bramble_effect.dart';
part 'abyssal_tendril_miasma_effect.dart';
part 'lost_soul_wisps_effect.dart';
part 'eldritch_peeping_eyes_effect.dart';
part 'tactical_reticle_effect.dart';
part 'holo_scanline_glitch_effect.dart';
part 'nanotech_circuit_effect.dart';
part 'alchemical_circle_effect.dart';
part 'floating_sigils_effect.dart';
part 'sacred_geometry_halo_effect.dart';
part 'supernova_corona_effect.dart';
part 'orbiting_moons_effect.dart';
part 'zodiac_constellation_effect.dart';
part 'effect_catalog.dart';

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
  solarEclipse,
  meteorShower,
  autumnWind,
  soulWisps,
  abyssalTentacles,
  cursedChains,
  beamTeleport,
  dangerAlarm,
  coinFountain,
  magmaFissures,
  frostGlaze,
  dragonAura,
  cellularDungeon,
  gothicRosette,
  runicMaze,
  circuitBoard,
  deepSpaceNebula,
  spaceshipHull,
  bismuthCrystals,
  coralReef,
  basaltColumns,
  waterfallCascade,
  fireflySwarm,
  whisperingReeds,
  risographPrint,
  pixelSorting,
  inkCrosshatch,
  rustCorrosion,
  wornFabric,
  crackedCeramic,
  mossLichen,
  paintPeeling,
  kaleidoscope,
  topographicContours,
  isometricExtrusion,
  paperCutout,
  celShading,
  lowPolyFacets,
  asciiMosaic,
  geyserVent,
  stalactiteDrips,
  woodblockUkiyoe,
  cyanotypePrint,
  linocutStamp,
  byzantineMosaic,
  chalkPastel,
  waxSgraffito,
  benDayComic,
  delftwareTile,
  thermalReceipt,
  lichenMoss,
  sporeBloom,
  banyanMangrove,
  sunbeamGodRays,
  dustDevil,
  auroraCurtains,
  glacialCrevasse,
  sandDunes,
  tidalRockPool,
  romanTravertine,
  kintsugiLacquer,
  petrifiedAgate,
  voronoiShatter,
  windAshDispersal,
  lateralSliceGlitch,
  directionalMotionBlur,
  radialZoomBlur,
  ditheredFrostedBlur,
  luminanceGradientMap,
  directionalLightRamp,
  silhouetteDepthBevel,
  actionSpeedLines,
  chromaticEchoDash,
  boosterThruster,
  crownSoulFire,
  hangingIcicles,
  viscousSlime,
  arcLightning,
  kiFlareAura,
  orbitingRunesHalo,
  hexagonalAegis,
  crystalShardReflector,
  gravitySingularity,
  stompDustImpact,
  waterRippleWake,
  sproutingBramble,
  abyssalTendrilMiasma,
  lostSoulWisps,
  eldritchPeepingEyes,
  tacticalReticle,
  holoScanlineGlitch,
  nanotechCircuit,
  alchemicalCircle,
  floatingSigils,
  sacredGeometryHalo,
  supernovaCorona,
  orbitingMoons,
  zodiacConstellation,
  breathing,
  glowPulse,
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

  /// Number of frames this effect wants when generating an animation, or
  /// `null` to let the generator derive it from duration × FPS.
  int? get preferredFrameCount => null;

  /// Whether the animation is a seamless loop (progress 1.0 equals 0.0).
  /// Generators then sample progress in `[0, 1)` to avoid a duplicated frame.
  bool get isSeamlessLoop => false;

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
        EffectType.solarEclipse => 'Solar Eclipse & Corona',
        EffectType.meteorShower => 'Meteor Shower & Starfall',
        EffectType.autumnWind => 'Autumn Wind & Leaf Vortex',
        EffectType.soulWisps => 'Necromantic Soul Wisps',
        EffectType.abyssalTentacles => 'Abyssal Tentacles & Eye Swarm',
        EffectType.cursedChains => 'Cursed Chains & Runic Break',
        EffectType.beamTeleport => 'Pixel Beam Teleport & Spawn',
        EffectType.dangerAlarm => 'Pixel Heartbeat & Danger Alarm',
        EffectType.coinFountain => '8-Bit Coin Fountain & Confetti',
        EffectType.magmaFissures => 'Molten Magma Fissures & Haze',
        EffectType.frostGlaze => 'Frost Glaze & Crystal Freeze',
        EffectType.dragonAura => 'Supercharged Dragon Aura',
        EffectType.cellularDungeon => 'Cellular Dungeon & Cave Labyrinth',
        EffectType.gothicRosette => 'Gothic Stained Glass Rosette',
        EffectType.runicMaze => 'Ancient Runic Maze & Stele',
        EffectType.circuitBoard => 'Procedural PCB & Circuit Board',
        EffectType.deepSpaceNebula => 'Deep Space Nebula & Gas Giant',
        EffectType.spaceshipHull => 'Spaceship Hull & Greeble Plating',
        EffectType.bismuthCrystals => 'Bismuth Crystals & Stepped Geodes',
        EffectType.coralReef => 'Coral Reef & Turing Flora',
        EffectType.basaltColumns => 'Basalt Columns & Volcanic Steppes',
        EffectType.waterfallCascade => 'Waterfall Cascade & Foam Splash Mist',
        EffectType.fireflySwarm =>
          'Bioluminescent Firefly Swarm & Twilight Meadow',
        EffectType.whisperingReeds => 'Whispering Reeds & Rippling Pond Water',
        EffectType.risographPrint => 'Risograph Print',
        EffectType.pixelSorting => 'Pixel Sorting',
        EffectType.inkCrosshatch => 'Ink & Crosshatch',
        EffectType.rustCorrosion => 'Rust & Corrosion',
        EffectType.wornFabric => 'Worn Fabric',
        EffectType.crackedCeramic => 'Cracked Ceramic',
        EffectType.mossLichen => 'Moss & Lichen',
        EffectType.paintPeeling => 'Paint Peeling',
        EffectType.kaleidoscope => 'Kaleidoscope',
        EffectType.topographicContours => 'Topographic Contours',
        EffectType.isometricExtrusion => 'Isometric Extrusion',
        EffectType.paperCutout => 'Paper Cutout',
        EffectType.celShading => 'Cel Shading',
        EffectType.lowPolyFacets => 'Low-Poly Facets',
        EffectType.asciiMosaic => 'ASCII Mosaic',
        EffectType.geyserVent => 'Geyser Steam Vent & Boiling Mud Pool',
        EffectType.stalactiteDrips =>
          'Stalactite Mineral Drips & Cavern Echo Ripples',
        EffectType.woodblockUkiyoe => 'Woodblock Ukiyo-e & Bokashi',
        EffectType.cyanotypePrint => 'Cyanotype Sun Print & Prussian Blue',
        EffectType.linocutStamp => 'Linocut Relief Stamp & Brayer',
        EffectType.byzantineMosaic => 'Byzantine Mosaic & Gold Leaf',
        EffectType.chalkPastel => 'Chalk Pastel & Charcoal Smudge',
        EffectType.waxSgraffito => 'Wax Crayon & Oil Sgraffito',
        EffectType.benDayComic => 'Ben-Day Comic & Misregistration',
        EffectType.delftwareTile => 'Glazed Delftware & Majolica Tile',
        EffectType.thermalReceipt => 'Thermal Receipt & Dot Matrix',
        EffectType.lichenMoss => 'Lichen Crust & Rock Moss',
        EffectType.sporeBloom => 'Spore Bloom & Fungal Woods',
        EffectType.banyanMangrove => 'Banyan Mangrove & Aerial Roots',
        EffectType.sunbeamGodRays => 'Sunbeam God Rays & Tyndall Haze',
        EffectType.dustDevil => 'Dust Devil & Desert Haboob',
        EffectType.auroraCurtains => 'Aurora Borealis Curtains',
        EffectType.glacialCrevasse => 'Glacial Crevasse & Serac Ice',
        EffectType.sandDunes => 'Wind-Sculpted Sand Dunes',
        EffectType.tidalRockPool => 'Tidal Rock Pool & Anemone',
        EffectType.romanTravertine => 'Roman Travertine & Ashlar Stone',
        EffectType.kintsugiLacquer => 'Cracked Kintsugi Gold Lacquer',
        EffectType.petrifiedAgate => 'Petrified Wood & Banded Agate',
        EffectType.voronoiShatter => 'Voronoi Glass Shatter',
        EffectType.windAshDispersal => 'Wind Ash & Sand Dispersal',
        EffectType.lateralSliceGlitch => 'Lateral Slice & Fault Glitch',
        EffectType.directionalMotionBlur => 'Directional Motion Blur',
        EffectType.radialZoomBlur => 'Radial Zoom & Shock Blur',
        EffectType.ditheredFrostedBlur => 'Dithered Frosted Blur',
        EffectType.luminanceGradientMap => 'Luminance Gradient Map',
        EffectType.directionalLightRamp => 'Directional Light Ramp',
        EffectType.silhouetteDepthBevel => 'Silhouette Depth Bevel',
        EffectType.actionSpeedLines => 'Anime Speed Lines & Focus Stream',
        EffectType.chromaticEchoDash => 'Chromatic Echo Dash & Ghost Afterimages',
        EffectType.boosterThruster => 'Booster Thruster & Rocket Flame Exhaust',
        EffectType.crownSoulFire => 'Crown Soul Fire & Flame Licks',
        EffectType.hangingIcicles => 'Frost Glaze & Hanging Icicles',
        EffectType.viscousSlime => 'Viscous Slime & Acid Ooze Drippings',
        EffectType.arcLightning => 'Arc Lightning & Supercharged Crackle',
        EffectType.kiFlareAura => 'Super Saiyan Ki Flare & Fighting Aura',
        EffectType.orbitingRunesHalo => 'Levitating Orbiting Runes & Celestial Halo',
        EffectType.hexagonalAegis => 'Hard-Light Hexagonal Aegis',
        EffectType.crystalShardReflector => 'Prismatic Crystal Shard Reflector',
        EffectType.gravitySingularity => 'Gravity Singularity & Accretion Well',
        EffectType.stompDustImpact => 'Kinetic Stomp Dust & Impact Shockwave',
        EffectType.waterRippleWake => 'Water Ripple & Puddle Reflection Wake',
        EffectType.sproutingBramble => 'Sprouting Wildflower & Bramble Footsteps',
        EffectType.abyssalTendrilMiasma => 'Abyssal Tendril Miasma',
        EffectType.lostSoulWisps => 'Wandering Lost Soul Wisps',
        EffectType.eldritchPeepingEyes => 'Eldritch Gaze & Peeping Eyes',
        EffectType.tacticalReticle => 'Tactical Lock-On Reticle',
        EffectType.holoScanlineGlitch => 'Holo-Scanline Glitch & Decimation',
        EffectType.nanotechCircuit => 'Nanotech Circuit Conduits',
        EffectType.alchemicalCircle => 'Alchemical Transmutation Circle',
        EffectType.floatingSigils => 'Runic Glyphs & Floating Sigils',
        EffectType.sacredGeometryHalo => 'Sacred Geometry Halo',
        EffectType.supernovaCorona => 'Supernova Corona Flare',
        EffectType.orbitingMoons => 'Orbiting Satellite Moons',
        EffectType.zodiacConstellation => 'Zodiac Constellation Map',
        EffectType.breathing => 'Smart Breathing (Idle)',
        EffectType.glowPulse => 'Glow Pulse',
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
        EffectType.solarEclipse =>
          'Celestial occulting disc, undulating corona prominences, and diamond ring burst',
        EffectType.meteorShower =>
          'High-speed incandescent shooting star streaks, glowing tails, and bursts',
        EffectType.autumnWind =>
          'Tumbling sakura petals, maple leaves, and ginkgo caught in wind swirl currents',
        EffectType.soulWisps =>
          '3D orbiting spectral spirits with hollow eye sockets and whisper vapor trails',
        EffectType.abyssalTentacles =>
          'Writhing shadowy tentacles with blinking eldritch eyes and glancing pupils',
        EffectType.cursedChains =>
          'Interlocking binding iron chains, pulsing runes, strain vibration, and shatter burst',
        EffectType.beamTeleport =>
          'Vertical laser column spawn, ground impact dust, and streaming digital blocks',
        EffectType.dangerAlarm =>
          'Cardiac lub-dub pulse rhythm, pulsing crimson vignette, and monochrome desaturation',
        EffectType.coinFountain =>
          'Ballistic celebration fountain with spinning coins, sparkling gems, and confetti',
        EffectType.magmaFissures =>
          'Glowing subterranean lava cracks, charred crust, and refractive heat haze',
        EffectType.frostGlaze =>
          'Dendritic frost needles, hexagonal ice crystals, and specular shimmer',
        EffectType.dragonAura =>
          'Raging plasma energy flames, jagged upward spikes, and static lightning arcs',
        EffectType.cellularDungeon =>
          'Procedural roguelike stone keeps, organic caves, catacombs, and wall torches',
        EffectType.gothicRosette =>
          'Symmetrical rose windows with lead came tracery, jewel glass, and sunbeams',
        EffectType.runicMaze =>
          'Carved Celtic knots, Greek meanders, Aztec stepped spirals, and runic pulses',
        EffectType.circuitBoard =>
          'PCB conducting traces, solder vias, SMD chips, and traveling electronic data packets',
        EffectType.deepSpaceNebula =>
          'Multi-octave cosmic gas clouds, star clusters, and a ringed gas giant planet',
        EffectType.spaceshipHull =>
          'Segmented starship armor plates, rivets, ventilation grilles, hazard stripes, and beacons',
        EffectType.bismuthCrystals =>
          'Concentric stepped cubic hopper crystals, rainbow thin-film oxides, and facet glints',
        EffectType.coralReef =>
          'Reaction-diffusion Turing brain corals, sea fans, tube sponges, and bioluminescent polyps',
        EffectType.basaltColumns =>
          'Interlocking hexagonal volcanic basalt columns, stepped heights, and molten lava seepage',
        EffectType.waterfallCascade =>
          'Vertical multi-stream torrents plunging down rock tiers with acceleration, impact foam, spray, and mist',
        EffectType.fireflySwarm =>
          'Wandering phosphorescent fireflies drifting in 3D flight paths with organic bio-pulses and soft ambient glow',
        EffectType.whisperingReeds =>
          'Shoreline reeds and cattails gently swaying to wind gusts, paired with expanding concentric water ripples',
        EffectType.risographPrint =>
          'Limited spot inks, imperfect registration, and tactile paper grain',
        EffectType.pixelSorting =>
          'Sort brightness, hue, or saturation bands into directional glitch trails',
        EffectType.inkCrosshatch =>
          'Hand-inked outlines with directional crosshatched shading',
        EffectType.rustCorrosion =>
          'Layered oxidation, pitted metal, and downward corrosion streaks',
        EffectType.wornFabric =>
          'Woven threads, faded fibers, worn patches, and frayed edges',
        EffectType.crackedCeramic =>
          'Glossy fired glaze with branching crazing and chipped areas',
        EffectType.mossLichen =>
          'Organic moss and lichen clusters that gather in shaded edges',
        EffectType.paintPeeling =>
          'Flaking painted layers that reveal the original material beneath',
        EffectType.kaleidoscope =>
          'Mirrored radial segments with rotation and animated folding',
        EffectType.topographicContours =>
          'Layered elevation lines derived from image brightness',
        EffectType.isometricExtrusion =>
          'Blocky directional depth extending from opaque sprite pixels',
        EffectType.paperCutout =>
          'Layered colored paper shapes with stepped cast shadows',
        EffectType.celShading =>
          'Quantized lighting bands with configurable ink contours',
        EffectType.lowPolyFacets =>
          'Triangulated flat-color facets with directional lighting',
        EffectType.asciiMosaic =>
          'Tonal image regions rendered as character or symbol tiles',
        EffectType.geyserVent =>
          'Pressurized geothermal geyser eruption with boiling mud bubbles, steam plumes, and mineral terraces',
        EffectType.stalactiteDrips =>
          'Hanging limestone stalactites dripping water beads with acoustic puddle ripples and stalagmite splashes',
        EffectType.woodblockUkiyoe =>
          'Carved woodcut relief keylines with fibrous washi paper grain and hand-wiped bokashi gradients',
        EffectType.cyanotypePrint =>
          'Ferric cyanotype photographic sun print with rich Prussian blue tones and paper tooth',
        EffectType.linocutStamp =>
          'High-contrast relief print with sharp directional gouges, roller ink, and background chatter',
        EffectType.byzantineMosaic =>
          'Fractured stone, ceramic tiles, and shimmering gold leaf smalti with mortar grout',
        EffectType.chalkPastel =>
          'Textured charcoal and French pastel with flow-field smudges, paper tooth, and chalk dust',
        EffectType.waxSgraffito =>
          'Thick waxy impasto with scratched-through incisions revealing radiant rainbow under-wax',
        EffectType.benDayComic =>
          'Silver-age comic offset print with angled CMYK Ben-Day dots, misregistration, and aged newsprint',
        EffectType.delftwareTile =>
          'Tin-glazed pottery tile with diffusing cobalt oxide wash, porcelain crazing, and vitreous bevel gloss',
        EffectType.thermalReceipt =>
          'Point-of-sale thermal receipt and 9-pin impact print with dithered needle dots, fading, and creases',
        EffectType.lichenMoss =>
          'Multi-tier crustose lichen rings, creeping moss tendrils, and micro-spores on stone',
        EffectType.sporeBloom =>
          'Bioluminescent mushroom caps venting swirling phosphorescent spore clouds with curl noise',
        EffectType.banyanMangrove =>
          'Tangled aerial root pillars with wind-swayed Spanish moss fronds and swamp waterlines',
        EffectType.sunbeamGodRays =>
          'Volumetric crepuscular light shafts piercing canopy foliage with floating specular dust motes',
        EffectType.dustDevil =>
          'Swirling cyclonic sandstorm vortex with 3D orbiting sand grains, ground skirts, and heat mirage',
        EffectType.auroraCurtains =>
          'Undulating ribbons of celestial geomagnetic plasma rippling over starry arctic skies with vertical ray striations',
        EffectType.glacialCrevasse =>
          'Cavernous glacial ice chasm glowing with saturated sapphire subsurface scattering, fracture walls, and snow cornices',
        EffectType.sandDunes =>
          'Sweeping crescent barchan sand dunes with razor slipface crests, wind micro-ripples, and blowing sand plumes',
        EffectType.tidalRockPool =>
          'Low-tide coastal granite basin holding saltwater with dancing caustics, swaying kelp, anemones, and white salt rims',
        EffectType.romanTravertine =>
          'Honed porous travertine limestone with dissolved karst pore cavities, bedding bands, and mortar joints',
        EffectType.kintsugiLacquer =>
          'Traditional fractured Japanese pottery with raised 24k gold leaf repair seams and makie gold dust',
        EffectType.petrifiedAgate =>
          'Fossilized tree wood with concentric banded chalcedony agate rings and quartz geode druse pockets',
        EffectType.voronoiShatter =>
          'Explodes sprite into geometric polygon shards with fracture gaps and outward blast displacement',
        EffectType.windAshDispersal =>
          'Dissolves sprite contours into blowing sand grains and burning ash motes drifting downwind',
        EffectType.lateralSliceGlitch =>
          'Shears sprite into stepped horizontal slices with alternating lateral shifts and chromatic fault dispersion',
        EffectType.directionalMotionBlur =>
          'Smears pixels along a velocity angle vector with trailing, symmetric, or leading falloff',
        EffectType.radialZoomBlur =>
          'Radiates explosive motion blur outward or inward from a focal center with crisp deadzone',
        EffectType.ditheredFrostedBlur =>
          'Scatters and softens pixels using Bayer matrix dithering, stochastic jitter, and palette quantization',
        EffectType.luminanceGradientMap =>
          'Remaps pixel luminance values through curated multi-stop gradient color palettes with Bayer dithering',
        EffectType.directionalLightRamp =>
          'Directional environmental lighting blend between primary overhead sun and opposing ground/lava bounce',
        EffectType.silhouetteDepthBevel =>
          'Automatic 3D inner contour beveling, surface normal lighting, specular facet highlights, and ambient occlusion',
        EffectType.actionSpeedLines =>
          'Dynamic anime manga speed lines streaming from sprite trailing contours with randomized stroke weights and dust',
        EffectType.chromaticEchoDash =>
          'Stepped ghost afterimages trailing behind along motion vector with chromatic color shifting and Bayer dither dissolves',
        EffectType.boosterThruster =>
          'Directional rocket thruster flame exhaust with supersonic Mach shock diamonds, propellant palettes, and smoke billows',
        EffectType.crownSoulFire =>
          'Flickering tongues of fire sprouting upward from head, shoulders, or contour perimeter with floating embers',
        EffectType.hangingIcicles =>
          'Dendritic crystalline frost creeping across top surfaces with needle icicle spikes and dripping melted beads',
        EffectType.viscousSlime =>
          'Thick bubbling viscous ooze coating top contours with hanging fluid droplets stretching and dripping downward',
        EffectType.arcLightning =>
          'Jagged branching electric arcs hugging silhouette contours and leaping between extremities with core sparks',
        EffectType.kiFlareAura =>
          'Blazing combat energy aura enveloping the character with vertical heat plumes, inner rim glow, and floating motes',
        EffectType.orbitingRunesHalo =>
          'Mystical 3D perspective halos, ancient orbiting rune stones, and concentrated mana spheres hovering above crown',
        EffectType.hexagonalAegis =>
          'Glowing cyberpunk honeycomb hexagonal barrier micro-plates contouring around the sprite with dithered energy fill',
        EffectType.crystalShardReflector =>
          'Sharp floating polygonal diamond crystal facets hovering outside sprite contour with prismatic refraction and glints',
        EffectType.gravitySingularity =>
          'Miniature dark gravitational lens and event horizon void core with swirling relativistic accretion disk arms',
        EffectType.stompDustImpact =>
          'Bilateral kicking dust billows, floating soil motes, and ground impact cracks erupting from character feet contact points',
        EffectType.waterRippleWake =>
          'Concentric perspective ripples and dithered inverted mirror reflection shimmering in a shallow water pool beneath feet',
        EffectType.sproutingBramble =>
          'Verdant creeping moss, climbing vine tendrils, and micro-flower blossoms sprouting along the ground baseline',
        EffectType.abyssalTendrilMiasma =>
          'Creeping ink-black serpentine tendrils and viscous dark matter oozing from contour edges with glowing miasma fringes',
        EffectType.lostSoulWisps =>
          'Hovering spectral spirit skulls and ghostly wisps with hollow facial voids and undulating ethereal vapor tails',
        EffectType.eldritchPeepingEyes =>
          'Geometric demonic eyeballs opening along the silhouette contour with slit or cross pupils and capillary veins',
        EffectType.tacticalReticle =>
          'Sci-fi holographic targeting reticle with corner framing brackets, centroid crosshair ticks, and telemetry data',
        EffectType.holoScanlineGlitch =>
          'Holographic phosphor scanlines, horizontal row displacement jitter, and chromatic aberration decimation',
        EffectType.nanotechCircuit =>
          'Glowing subdermal PCB conductive circuit traces, 45° and 90° bus tracks, and pulsing nanite data packets',
        EffectType.alchemicalCircle =>
          'Sacred alchemical transmutation array with concentric containment rings, star polygons, and celestial spoke rays',
        EffectType.floatingSigils =>
          'Hovering Elder Futhark runes and celestial sigils with luminescent halos and connecting ether threads',
        EffectType.sacredGeometryHalo =>
          'Polyhedral sacred geometry halos, Metatron 13-sphere cubes, and Merkaba star tetrahedrons with nodal sparks',
        EffectType.supernovaCorona =>
          'Blazing stellar corona flare with multi-point diffraction starburst spikes and coronal plasma prominences',
        EffectType.orbitingMoons =>
          'Gravitational satellite system with spherical shaded moons and inclined orbital guide tracks',
        EffectType.zodiacConstellation =>
          'Astronomical star chart with major constellation asterisms, 4-point cross glints, and background stardust',
        EffectType.glowPulse => 'A soft halo that gently brightens and fades around the sprite',
        EffectType.breathing =>
          'Sprite-aware idle breathing with planted feet, rigid head, chest expansion, and pixel-snapped poses',
      };

  bool get isAnimation => EffectCatalog.forType(type).isAnimated;

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
      EffectType.crt => Icon(Icons.tv, size: size, color: color),
      EffectType.lcdMatrix =>
        Icon(Icons.videogame_asset, size: size, color: color),
      EffectType.chromaticAberration =>
        Icon(Icons.filter_tilt_shift, size: size, color: color),
      EffectType.dropShadow => Icon(Icons.layers, size: size, color: color),
      EffectType.normalMap => Icon(Icons.explore, size: size, color: color),
      EffectType.colorCycling => Icon(Icons.sync, size: size, color: color),
      EffectType.rimLight => Icon(Icons.wb_sunny, size: size, color: color),
      EffectType.squashStretch =>
        Icon(Icons.swap_vert, size: size, color: color),
      EffectType.windSway => Icon(Icons.air, size: size, color: color),
      EffectType.hitFlash => Icon(Icons.flash_on, size: size, color: color),
      EffectType.ghostTrail =>
        Icon(Icons.fast_forward, size: size, color: color),
      EffectType.starfield =>
        Icon(Icons.auto_awesome, size: size, color: color),
      EffectType.electricArc => Icon(Icons.bolt, size: size, color: color),
      EffectType.blizzard => Icon(Icons.ac_unit, size: size, color: color),
      EffectType.portalVortex => Icon(Icons.cyclone, size: size, color: color),
      EffectType.energyShield => Icon(Icons.shield, size: size, color: color),
      EffectType.radiantRays =>
        Icon(Icons.wb_twilight, size: size, color: color),
      EffectType.burningEmbers =>
        Icon(Icons.local_fire_department, size: size, color: color),
      EffectType.underwaterCaustics =>
        Icon(Icons.waves, size: size, color: color),
      EffectType.risingBubbles =>
        Icon(Icons.bubble_chart, size: size, color: color),
      EffectType.slimeDrip => Icon(Icons.water_drop, size: size, color: color),
      EffectType.radialShockwave =>
        Icon(Icons.adjust, size: size, color: color),
      EffectType.slashArc => Icon(Icons.flash_on, size: size, color: color),
      EffectType.hologramGlitch => Icon(Icons.cast, size: size, color: color),
      EffectType.solarEclipse =>
        Icon(Icons.brightness_3, size: size, color: color),
      EffectType.meteorShower => Icon(Icons.star, size: size, color: color),
      EffectType.autumnWind => Icon(Icons.air, size: size, color: color),
      EffectType.soulWisps => Icon(Icons.blur_on, size: size, color: color),
      EffectType.abyssalTentacles =>
        Icon(Icons.visibility, size: size, color: color),
      EffectType.cursedChains => Icon(Icons.link, size: size, color: color),
      EffectType.beamTeleport =>
        Icon(Icons.vertical_align_bottom, size: size, color: color),
      EffectType.dangerAlarm => Icon(Icons.favorite, size: size, color: color),
      EffectType.coinFountain =>
        Icon(Icons.monetization_on, size: size, color: color),
      EffectType.magmaFissures =>
        Icon(Icons.whatshot, size: size, color: color),
      EffectType.frostGlaze => Icon(Icons.ac_unit, size: size, color: color),
      EffectType.dragonAura => Icon(Icons.flash_on, size: size, color: color),
      EffectType.cellularDungeon =>
        Icon(Icons.grid_view, size: size, color: color),
      EffectType.gothicRosette =>
        Icon(Icons.brightness_7, size: size, color: color),
      EffectType.runicMaze =>
        Icon(Icons.account_tree, size: size, color: color),
      EffectType.circuitBoard =>
        Icon(Icons.developer_board, size: size, color: color),
      EffectType.deepSpaceNebula =>
        Icon(Icons.public, size: size, color: color),
      EffectType.spaceshipHull => Icon(Icons.shield, size: size, color: color),
      EffectType.bismuthCrystals =>
        Icon(Icons.auto_awesome, size: size, color: color),
      EffectType.coralReef => Icon(Icons.spa, size: size, color: color),
      EffectType.basaltColumns =>
        Icon(Icons.view_column, size: size, color: color),
      EffectType.waterfallCascade =>
        Icon(Icons.waves, size: size, color: color),
      EffectType.fireflySwarm =>
        Icon(Icons.bubble_chart, size: size, color: color),
      EffectType.whisperingReeds => Icon(Icons.grass, size: size, color: color),
      EffectType.risographPrint => Icon(Icons.print, size: size, color: color),
      EffectType.pixelSorting => Icon(Icons.sort, size: size, color: color),
      EffectType.inkCrosshatch => Icon(Icons.gesture, size: size, color: color),
      EffectType.rustCorrosion => Icon(Icons.blur_on, size: size, color: color),
      EffectType.wornFabric => Icon(Icons.texture, size: size, color: color),
      EffectType.crackedCeramic =>
        Icon(Icons.broken_image, size: size, color: color),
      EffectType.mossLichen => Icon(Icons.grass, size: size, color: color),
      EffectType.paintPeeling =>
        Icon(Icons.format_paint, size: size, color: color),
      EffectType.kaleidoscope => Icon(Icons.camera, size: size, color: color),
      EffectType.topographicContours =>
        Icon(Icons.map, size: size, color: color),
      EffectType.isometricExtrusion =>
        Icon(Icons.view_in_ar, size: size, color: color),
      EffectType.paperCutout => Icon(Icons.layers, size: size, color: color),
      EffectType.celShading => Icon(Icons.tonality, size: size, color: color),
      EffectType.lowPolyFacets =>
        Icon(Icons.change_history, size: size, color: color),
      EffectType.asciiMosaic =>
        Icon(Icons.text_fields, size: size, color: color),
      EffectType.geyserVent => Icon(Icons.whatshot, size: size, color: color),
      EffectType.stalactiteDrips =>
        Icon(Icons.opacity, size: size, color: color),
      EffectType.woodblockUkiyoe => Icon(Icons.brush, size: size, color: color),
      EffectType.cyanotypePrint =>
        Icon(Icons.wb_sunny, size: size, color: color),
      EffectType.linocutStamp => Icon(Icons.cut, size: size, color: color),
      EffectType.byzantineMosaic =>
        Icon(Icons.grid_view, size: size, color: color),
      EffectType.chalkPastel => Icon(Icons.gesture, size: size, color: color),
      EffectType.waxSgraffito => Icon(Icons.draw, size: size, color: color),
      EffectType.benDayComic =>
        Icon(Icons.photo_filter, size: size, color: color),
      EffectType.delftwareTile => Icon(Icons.layers, size: size, color: color),
      EffectType.thermalReceipt =>
        Icon(Icons.receipt_long, size: size, color: color),
      EffectType.lichenMoss => Icon(Icons.grass, size: size, color: color),
      EffectType.sporeBloom =>
        Icon(Icons.bubble_chart, size: size, color: color),
      EffectType.banyanMangrove => Icon(Icons.park, size: size, color: color),
      EffectType.sunbeamGodRays =>
        Icon(Icons.wb_sunny, size: size, color: color),
      EffectType.dustDevil => Icon(Icons.cyclone, size: size, color: color),
      EffectType.auroraCurtains => Icon(Icons.waves, size: size, color: color),
      EffectType.glacialCrevasse =>
        Icon(Icons.ac_unit, size: size, color: color),
      EffectType.sandDunes => Icon(Icons.terrain, size: size, color: color),
      EffectType.tidalRockPool => Icon(Icons.pool, size: size, color: color),
      EffectType.romanTravertine =>
        Icon(Icons.view_quilt, size: size, color: color),
      EffectType.kintsugiLacquer =>
        Icon(Icons.auto_awesome, size: size, color: color),
      EffectType.petrifiedAgate => Icon(Icons.grain, size: size, color: color),
      EffectType.voronoiShatter =>
        Icon(Icons.broken_image, size: size, color: color),
      EffectType.windAshDispersal =>
        Icon(Icons.grain, size: size, color: color),
      EffectType.lateralSliceGlitch =>
        Icon(Icons.splitscreen, size: size, color: color),
      EffectType.directionalMotionBlur =>
        Icon(Icons.fast_forward, size: size, color: color),
      EffectType.radialZoomBlur =>
        Icon(Icons.zoom_out_map, size: size, color: color),
      EffectType.ditheredFrostedBlur =>
        Icon(Icons.blur_on, size: size, color: color),
      EffectType.luminanceGradientMap =>
        Icon(Icons.gradient, size: size, color: color),
      EffectType.directionalLightRamp =>
        Icon(Icons.wb_twilight, size: size, color: color),
      EffectType.silhouetteDepthBevel =>
        Icon(Icons.layers, size: size, color: color),
      EffectType.actionSpeedLines =>
        Icon(Icons.fast_forward, size: size, color: color),
      EffectType.chromaticEchoDash =>
        Icon(Icons.motion_photos_on, size: size, color: color),
      EffectType.boosterThruster =>
        Icon(Icons.local_fire_department, size: size, color: color),
      EffectType.crownSoulFire =>
        Icon(Icons.whatshot, size: size, color: color),
      EffectType.hangingIcicles =>
        Icon(Icons.severe_cold, size: size, color: color),
      EffectType.viscousSlime =>
        Icon(Icons.water_drop, size: size, color: color),
      EffectType.arcLightning =>
        Icon(Icons.bolt, size: size, color: color),
      EffectType.kiFlareAura =>
        Icon(Icons.flare, size: size, color: color),
      EffectType.orbitingRunesHalo =>
        Icon(Icons.stars, size: size, color: color),
      EffectType.hexagonalAegis =>
        Icon(Icons.shield_outlined, size: size, color: color),
      EffectType.crystalShardReflector =>
        Icon(Icons.diamond_outlined, size: size, color: color),
      EffectType.gravitySingularity =>
        Icon(Icons.cyclone, size: size, color: color),
      EffectType.stompDustImpact =>
        Icon(Icons.landslide_outlined, size: size, color: color),
      EffectType.waterRippleWake =>
        Icon(Icons.waves, size: size, color: color),
      EffectType.sproutingBramble =>
        Icon(Icons.park_outlined, size: size, color: color),
      EffectType.abyssalTendrilMiasma =>
        Icon(Icons.grain, size: size, color: color),
      EffectType.lostSoulWisps =>
        Icon(Icons.blur_on, size: size, color: color),
      EffectType.eldritchPeepingEyes =>
        Icon(Icons.visibility_outlined, size: size, color: color),
      EffectType.tacticalReticle =>
        Icon(Icons.filter_center_focus, size: size, color: color),
      EffectType.holoScanlineGlitch =>
        Icon(Icons.developer_board, size: size, color: color),
      EffectType.nanotechCircuit =>
        Icon(Icons.memory, size: size, color: color),
      EffectType.alchemicalCircle =>
        Icon(Icons.change_circle_outlined, size: size, color: color),
      EffectType.floatingSigils =>
        Icon(Icons.auto_awesome, size: size, color: color),
      EffectType.sacredGeometryHalo =>
        Icon(Icons.hub_outlined, size: size, color: color),
      EffectType.supernovaCorona =>
        Icon(Icons.wb_sunny_outlined, size: size, color: color),
      EffectType.orbitingMoons =>
        Icon(Icons.public, size: size, color: color),
      EffectType.zodiacConstellation =>
        Icon(Icons.flare, size: size, color: color),
      EffectType.glowPulse => Icon(Icons.flare, size: size, color: color),
      EffectType.breathing => Icon(Icons.air, size: size, color: color),
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
      EffectType.chromaticAberration =>
        const Color(0xFFFF2A6D), // Synthwave Neon Pink
      EffectType.dropShadow => const Color(0xFF546E7A), // Slate shadow grey
      EffectType.normalMap =>
        const Color(0xFF8080FF), // Tangent normal blue-violet
      EffectType.colorCycling =>
        const Color(0xFF00E676), // Vibrant cycling green
      EffectType.rimLight => const Color(0xFFFFD54F), // Warm sunlight gold
      EffectType.squashStretch =>
        const Color(0xFFFF7043), // Elastic coral orange
      EffectType.windSway => const Color(0xFF66BB6A), // Foliage wind green
      EffectType.hitFlash => const Color(0xFFFF1744), // Damage flash crimson
      EffectType.ghostTrail =>
        const Color(0xFF29B6F6), // Speed phantom light blue
      EffectType.starfield =>
        const Color(0xFF7C4DFF), // Deep cosmic starlight purple
      EffectType.electricArc =>
        const Color(0xFF00E5FF), // Ionized electric cyan
      EffectType.blizzard => const Color(0xFF80D8FF), // Frosted ice blue
      EffectType.portalVortex =>
        const Color(0xFFD500F9), // Electric violet portal
      EffectType.energyShield =>
        const Color(0xFF00B0FF), // Forcefield electric blue
      EffectType.radiantRays => const Color(0xFFFFD700), // Holy ascension gold
      EffectType.burningEmbers =>
        const Color(0xFFFF6D00), // Incandescent flame orange
      EffectType.underwaterCaustics =>
        const Color(0xFF00E5FF), // Tropical cyan caustics
      EffectType.risingBubbles => const Color(0xFF80DEEA), // Effervescent aqua
      EffectType.slimeDrip => const Color(0xFF76FF03), // Toxic acid lime green
      EffectType.radialShockwave =>
        const Color(0xFFFF9100), // Impact blast amber orange
      EffectType.slashArc =>
        const Color(0xFFFF1744), // Crimson blade strike red
      EffectType.hologramGlitch =>
        const Color(0xFF00E5FF), // Hologram laser cyan
      EffectType.solarEclipse => const Color(0xFFFFB300), // Corona gold amber
      EffectType.meteorShower =>
        const Color(0xFF80D8FF), // Cosmic shooting star cyan
      EffectType.autumnWind => const Color(0xFFFF7043), // Autumn scarlet maple
      EffectType.soulWisps => const Color(0xFF00E676), // Spectral soul green
      EffectType.abyssalTentacles => const Color(0xFF7C4DFF), // Abyssal purple
      EffectType.cursedChains => const Color(0xFFFF1744), // Cursed crimson seal
      EffectType.beamTeleport => const Color(0xFF00E5FF), // Retro laser cyan
      EffectType.dangerAlarm => const Color(0xFFFF1744), // Critical warning red
      EffectType.coinFountain => const Color(0xFFFFD700), // Victory gold
      EffectType.magmaFissures => const Color(0xFFFF3D00), // Molten lava orange
      EffectType.frostGlaze => const Color(0xFF80D8FF), // Glacial frost cyan
      EffectType.dragonAura => const Color(0xFFFFD600), // Dragon aura gold
      EffectType.cellularDungeon =>
        const Color(0xFF78909C), // Stone dungeon slate
      EffectType.gothicRosette =>
        const Color(0xFFC2185B), // Cathedral rose magenta
      EffectType.runicMaze => const Color(0xFF00E5FF), // Arcane rune cyan
      EffectType.circuitBoard => const Color(0xFF00E676), // PCB circuit emerald
      EffectType.deepSpaceNebula =>
        const Color(0xFF7C4DFF), // Cosmic nebula purple
      EffectType.spaceshipHull =>
        const Color(0xFF90A4AE), // Starship armor slate
      EffectType.bismuthCrystals =>
        const Color(0xFFE040FB), // Iridescent bismuth magenta
      EffectType.coralReef => const Color(0xFFFF4081), // Living coral pink
      EffectType.basaltColumns =>
        const Color(0xFFFF5722), // Volcanic magma basalt
      EffectType.waterfallCascade =>
        const Color(0xFF00B4D8), // Glacial cascade cyan
      EffectType.fireflySwarm =>
        const Color(0xFF76FF03), // Bioluminescent lime phosphor
      EffectType.whisperingReeds =>
        const Color(0xFF26A69A), // Serene reed water teal
      EffectType.risographPrint =>
        const Color(0xFFFF5A5F), // Riso fluorescent red
      EffectType.pixelSorting => const Color(0xFF00E5FF), // Digital cyan
      EffectType.inkCrosshatch =>
        const Color(0xFF3E2723), // India ink brown-black
      EffectType.rustCorrosion => const Color(0xFFB44719), // Iron oxide orange
      EffectType.wornFabric =>
        const Color(0xFF607D8B), // Faded textile blue-grey
      EffectType.crackedCeramic => const Color(0xFF80CBC4), // Celadon glaze
      EffectType.mossLichen => const Color(0xFF689F38), // Moss green
      EffectType.paintPeeling => const Color(0xFFE57373), // Weathered paint red
      EffectType.kaleidoscope => const Color(0xFFE040FB),
      EffectType.topographicContours => const Color(0xFF8D6E63),
      EffectType.isometricExtrusion => const Color(0xFF5C6BC0),
      EffectType.paperCutout => const Color(0xFFFF8A65),
      EffectType.celShading => const Color(0xFFFFD54F),
      EffectType.lowPolyFacets => const Color(0xFF26A69A),
      EffectType.asciiMosaic => const Color(0xFF66BB6A),
      EffectType.geyserVent =>
        const Color(0xFFFFB300), // Geothermal sulfur amber
      EffectType.stalactiteDrips =>
        const Color(0xFF90A4AE), // Cave limestone slate
      EffectType.woodblockUkiyoe =>
        const Color(0xFFC62828), // Cinnabar vermilion
      EffectType.cyanotypePrint =>
        const Color(0xFF0D47A1), // Prussian royal blue
      EffectType.linocutStamp =>
        const Color(0xFF37474F), // Linoleum relief slate
      EffectType.byzantineMosaic =>
        const Color(0xFFD4AF37), // Byzantine imperial gold
      EffectType.chalkPastel => const Color(0xFF708090), // Charcoal slate
      EffectType.waxSgraffito =>
        const Color(0xFFFF4081), // Prismatic sgraffito magenta
      EffectType.benDayComic =>
        const Color(0xFFE91E63), // Comic process magenta
      EffectType.delftwareTile => const Color(0xFF1976D2), // Delft cobalt blue
      EffectType.thermalReceipt =>
        const Color(0xFF546E7A), // Thermal receipt slate
      EffectType.lichenMoss => const Color(0xFF689F38), // Lichen Yellow-Green
      EffectType.sporeBloom => const Color(0xFF00E5FF), // Bioluminescent Cyan
      EffectType.banyanMangrove =>
        const Color(0xFF5D4037), // Mangrove Bark Brown
      EffectType.sunbeamGodRays => const Color(0xFFFFD54F), // Amber Sunlight
      EffectType.dustDevil => const Color(0xFFD87D4A), // Desert Terracotta Sand
      EffectType.auroraCurtains =>
        const Color(0xFF00E676), // Polar Aurora Emerald
      EffectType.glacialCrevasse => const Color(0xFF00B0FF), // Glacial Cyan
      EffectType.sandDunes => const Color(0xFFFF9800), // Dune Amber
      EffectType.tidalRockPool =>
        const Color(0xFF00BCD4), // Tidepool Saltwater Cyan
      EffectType.romanTravertine =>
        const Color(0xFFD7CCC8), // Travertine Limestone Warm Grey
      EffectType.kintsugiLacquer =>
        const Color(0xFFFFD700), // Kintsugi Gold Leaf
      EffectType.petrifiedAgate =>
        const Color(0xFFE64A19), // Petrified Agate Rust/Amber
      EffectType.voronoiShatter =>
        const Color(0xFF80DEEA), // Glass Cyan / Shard
      EffectType.windAshDispersal =>
        const Color(0xFFFF7043), // Ember Ash Orange
      EffectType.lateralSliceGlitch =>
        const Color(0xFFBA68C8), // Glitch Violet / Magenta
      EffectType.directionalMotionBlur =>
        const Color(0xFF29B6F6), // Velocity Light Blue
      EffectType.radialZoomBlur =>
        const Color(0xFFFF7043), // Impact Burst Orange
      EffectType.ditheredFrostedBlur =>
        const Color(0xFF4DB6AC), // Frosted Glass Teal
      EffectType.luminanceGradientMap =>
        const Color(0xFFAB47BC), // Gradient Magenta / Purple
      EffectType.directionalLightRamp =>
        const Color(0xFFFFB300), // Sunlight Amber
      EffectType.silhouetteDepthBevel =>
        const Color(0xFF26A69A), // 3D Bevel Teal
      EffectType.actionSpeedLines =>
        const Color(0xFF00E5FF), // Speed Line Electric Cyan
      EffectType.chromaticEchoDash =>
        const Color(0xFFE040FB), // Ghost Echo Neon Magenta
      EffectType.boosterThruster =>
        const Color(0xFFFF6D00), // Rocket Thruster Flame Orange
      EffectType.crownSoulFire =>
        const Color(0xFFFF3D00), // Flame vermilion / fire orange
      EffectType.hangingIcicles =>
        const Color(0xFF00E5FF), // Glacial frost cyan
      EffectType.viscousSlime =>
        const Color(0xFF76FF03), // Toxic acid lime green
      EffectType.arcLightning =>
        const Color(0xFF00E5FF), // Tesla electric cyan
      EffectType.kiFlareAura =>
        const Color(0xFFFFD700), // Super Saiyan gold
      EffectType.orbitingRunesHalo =>
        const Color(0xFFFFAB00), // Celestial halo gold
      EffectType.hexagonalAegis =>
        const Color(0xFF00E5FF), // Holo-cyan barrier
      EffectType.crystalShardReflector =>
        const Color(0xFF80DEEA), // Prismatic crystal cyan/diamond
      EffectType.gravitySingularity =>
        const Color(0xFFE040FB), // Cosmic singularity violet
      EffectType.stompDustImpact =>
        const Color(0xFF8D6E63), // Dust earth brown
      EffectType.waterRippleWake =>
        const Color(0xFF29B6F6), // Water ripple azure
      EffectType.sproutingBramble =>
        const Color(0xFF00C853), // Botanical flora green
      EffectType.abyssalTendrilMiasma =>
        const Color(0xFF7B1FA2), // Nether violet
      EffectType.lostSoulWisps =>
        const Color(0xFF00E5FF), // Ghost cyan
      EffectType.eldritchPeepingEyes =>
        const Color(0xFFFF1744), // Crimson eye red
      EffectType.tacticalReticle =>
        const Color(0xFF00F0FF), // Cyber cyan
      EffectType.holoScanlineGlitch =>
        const Color(0xFFFF0055), // Holo magenta
      EffectType.nanotechCircuit =>
        const Color(0xFFFFB000), // Circuit gold
      EffectType.alchemicalCircle =>
        const Color(0xFFFFD700), // Hermetic gold
      EffectType.floatingSigils =>
        const Color(0xFF18FFFF), // Valkyrie cyan
      EffectType.sacredGeometryHalo =>
        const Color(0xFFFF8A65), // Solar prism
      EffectType.supernovaCorona =>
        const Color(0xFFFFD54F), // Solar white/gold
      EffectType.orbitingMoons =>
        const Color(0xFF80D8FF), // Celestial azure
      EffectType.zodiacConstellation =>
        const Color(0xFFE040FB), // Cosmic amethyst
      EffectType.glowPulse => const Color(0xFFFFD54F),
      EffectType.breathing => const Color(0xFF4DD0E1), // Calm breath aqua
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
    return applyMultipleEffects(
        args.pixels, args.width, args.height, args.effects);
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
      case EffectType.solarEclipse:
        return SolarEclipseEffect(params);
      case EffectType.meteorShower:
        return MeteorShowerEffect(params);
      case EffectType.autumnWind:
        return AutumnWindEffect(params);
      case EffectType.soulWisps:
        return SoulWispsEffect(params);
      case EffectType.abyssalTentacles:
        return AbyssalTentaclesEffect(params);
      case EffectType.cursedChains:
        return CursedChainsEffect(params);
      case EffectType.beamTeleport:
        return BeamTeleportEffect(params);
      case EffectType.dangerAlarm:
        return DangerAlarmEffect(params);
      case EffectType.coinFountain:
        return CoinFountainEffect(params);
      case EffectType.magmaFissures:
        return MagmaFissuresEffect(params);
      case EffectType.frostGlaze:
        return FrostGlazeEffect(params);
      case EffectType.dragonAura:
        return DragonAuraEffect(params);
      case EffectType.cellularDungeon:
        return CellularDungeonEffect(params);
      case EffectType.gothicRosette:
        return GothicRosetteEffect(params);
      case EffectType.runicMaze:
        return RunicMazeEffect(params);
      case EffectType.circuitBoard:
        return CircuitBoardEffect(params);
      case EffectType.deepSpaceNebula:
        return DeepSpaceNebulaEffect(params);
      case EffectType.spaceshipHull:
        return SpaceshipHullEffect(params);
      case EffectType.bismuthCrystals:
        return BismuthCrystalsEffect(params);
      case EffectType.coralReef:
        return CoralReefEffect(params);
      case EffectType.basaltColumns:
        return BasaltColumnsEffect(params);
      case EffectType.waterfallCascade:
        return WaterfallCascadeEffect(params);
      case EffectType.fireflySwarm:
        return FireflySwarmEffect(params);
      case EffectType.whisperingReeds:
        return WhisperingReedsEffect(params);
      case EffectType.risographPrint:
        return RisographPrintEffect(params);
      case EffectType.pixelSorting:
        return PixelSortingEffect(params);
      case EffectType.inkCrosshatch:
        return InkCrosshatchEffect(params);
      case EffectType.rustCorrosion:
        return RustCorrosionEffect(params);
      case EffectType.wornFabric:
        return WornFabricEffect(params);
      case EffectType.crackedCeramic:
        return CrackedCeramicEffect(params);
      case EffectType.mossLichen:
        return MossLichenEffect(params);
      case EffectType.paintPeeling:
        return PaintPeelingEffect(params);
      case EffectType.kaleidoscope:
        return KaleidoscopeEffect(params);
      case EffectType.topographicContours:
        return TopographicContoursEffect(params);
      case EffectType.isometricExtrusion:
        return IsometricExtrusionEffect(params);
      case EffectType.paperCutout:
        return PaperCutoutEffect(params);
      case EffectType.celShading:
        return CelShadingEffect(params);
      case EffectType.lowPolyFacets:
        return LowPolyFacetsEffect(params);
      case EffectType.asciiMosaic:
        return AsciiMosaicEffect(params);
      case EffectType.geyserVent:
        return GeyserVentEffect(params);
      case EffectType.stalactiteDrips:
        return StalactiteDripsEffect(params);
      case EffectType.woodblockUkiyoe:
        return WoodblockUkiyoeEffect(params);
      case EffectType.cyanotypePrint:
        return CyanotypePrintEffect(params);
      case EffectType.linocutStamp:
        return LinocutStampEffect(params);
      case EffectType.byzantineMosaic:
        return ByzantineMosaicEffect(params);
      case EffectType.chalkPastel:
        return ChalkPastelEffect(params);
      case EffectType.waxSgraffito:
        return WaxSgraffitoEffect(params);
      case EffectType.benDayComic:
        return BenDayComicEffect(params);
      case EffectType.delftwareTile:
        return DelftwareTileEffect(params);
      case EffectType.thermalReceipt:
        return ThermalReceiptEffect(params);
      case EffectType.lichenMoss:
        return LichenMossEffect(params);
      case EffectType.sporeBloom:
        return SporeBloomEffect(params);
      case EffectType.banyanMangrove:
        return BanyanMangroveEffect(params);
      case EffectType.sunbeamGodRays:
        return SunbeamGodRaysEffect(params);
      case EffectType.dustDevil:
        return DustDevilEffect(params);
      case EffectType.auroraCurtains:
        return AuroraCurtainsEffect(params);
      case EffectType.glacialCrevasse:
        return GlacialCrevasseEffect(params);
      case EffectType.sandDunes:
        return SandDunesEffect(params);
      case EffectType.tidalRockPool:
        return TidalRockPoolEffect(params);
      case EffectType.romanTravertine:
        return RomanTravertineEffect(params);
      case EffectType.kintsugiLacquer:
        return KintsugiLacquerEffect(params);
      case EffectType.petrifiedAgate:
        return PetrifiedAgateEffect(params);
      case EffectType.voronoiShatter:
        return VoronoiShatterEffect(params);
      case EffectType.windAshDispersal:
        return WindAshDispersalEffect(params);
      case EffectType.lateralSliceGlitch:
        return LateralSliceGlitchEffect(params);
      case EffectType.directionalMotionBlur:
        return DirectionalMotionBlurEffect(params);
      case EffectType.radialZoomBlur:
        return RadialZoomBlurEffect(params);
      case EffectType.ditheredFrostedBlur:
        return DitheredFrostedBlurEffect(params);
      case EffectType.luminanceGradientMap:
        return LuminanceGradientMapEffect(params);
      case EffectType.directionalLightRamp:
        return DirectionalLightRampEffect(params);
      case EffectType.silhouetteDepthBevel:
        return SilhouetteDepthBevelEffect(params);
      case EffectType.actionSpeedLines:
        return ActionSpeedLinesEffect(params);
      case EffectType.chromaticEchoDash:
        return ChromaticEchoDashEffect(params);
      case EffectType.boosterThruster:
        return BoosterThrusterEffect(params);
      case EffectType.crownSoulFire:
        return CrownSoulFireEffect(params);
      case EffectType.hangingIcicles:
        return HangingIciclesEffect(params);
      case EffectType.viscousSlime:
        return ViscousSlimeEffect(params);
      case EffectType.arcLightning:
        return ArcLightningEffect(params);
      case EffectType.kiFlareAura:
        return KiFlareAuraEffect(params);
      case EffectType.orbitingRunesHalo:
        return OrbitingRunesHaloEffect(params);
      case EffectType.hexagonalAegis:
        return HexagonalAegisEffect(params);
      case EffectType.crystalShardReflector:
        return CrystalShardReflectorEffect(params);
      case EffectType.gravitySingularity:
        return GravitySingularityEffect(params);
      case EffectType.stompDustImpact:
        return StompDustImpactEffect(params);
      case EffectType.waterRippleWake:
        return WaterRippleWakeEffect(params);
      case EffectType.sproutingBramble:
        return SproutingBrambleEffect(params);
      case EffectType.abyssalTendrilMiasma:
        return AbyssalTendrilMiasmaEffect(params);
      case EffectType.lostSoulWisps:
        return LostSoulWispsEffect(params);
      case EffectType.eldritchPeepingEyes:
        return EldritchPeepingEyesEffect(params);
      case EffectType.tacticalReticle:
        return TacticalReticleEffect(params);
      case EffectType.holoScanlineGlitch:
        return HoloScanlineGlitchEffect(params);
      case EffectType.nanotechCircuit:
        return NanotechCircuitEffect(params);
      case EffectType.alchemicalCircle:
        return AlchemicalCircleEffect(params);
      case EffectType.floatingSigils:
        return FloatingSigilsEffect(params);
      case EffectType.sacredGeometryHalo:
        return SacredGeometryHaloEffect(params);
      case EffectType.supernovaCorona:
        return SupernovaCoronaEffect(params);
      case EffectType.orbitingMoons:
        return OrbitingMoonsEffect(params);
      case EffectType.zodiacConstellation:
        return ZodiacConstellationEffect(params);
      case EffectType.glowPulse:
        return GlowPulseEffect(params);
      case EffectType.breathing:
        return BreathingEffect(params);
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
