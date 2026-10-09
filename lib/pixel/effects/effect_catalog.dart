part of 'effects.dart';

/// Primary user-facing area where an effect is discovered and managed.
enum EffectWorkspace {
  filters,
  materials,
  generators,
  animation,
  lighting,
}

/// The effect's structural responsibility in a layer effect stack.
enum EffectRole {
  modifier,
  generator,
  overlay,
}

/// Pixel state required before an effect can be added to a layer.
enum EffectInputPolicy {
  anyLayer,
  requiresPixels,
  requiresEmptyLayer,
}

/// User-facing subdivision within the Animation workspace.
enum AnimationKind {
  transformer,
  specialEffect,
}

/// User-facing subdivision within the Filters workspace.
enum FilterKind {
  filter,
  distortion,
}

/// Independent runtime and presentation features supported by an effect.
enum EffectCapability {
  animated,
}

/// Search facets that do not affect the effect's primary workspace.
enum EffectTag {
  environment,
  lighting,
  nature,
  particles,
  print,
  retro,
  sciFi,
}

@immutable
class EffectDescriptor {
  const EffectDescriptor({
    required this.type,
    required this.workspace,
    required this.role,
    required this.inputPolicy,
    this.filterKind,
    this.animationKind,
    this.tags = const {},
    this.capabilities = const {},
  });

  final EffectType type;
  final EffectWorkspace workspace;
  final EffectRole role;
  final EffectInputPolicy inputPolicy;
  final FilterKind? filterKind;
  final AnimationKind? animationKind;
  final Set<EffectTag> tags;
  final Set<EffectCapability> capabilities;

  bool get isAnimated => capabilities.contains(EffectCapability.animated);
}

/// Canonical functional classification for every [EffectType].
///
/// Effect identifiers and effect serialization remain owned by [EffectType].
/// This registry contains presentation and validation metadata only.
class EffectCatalog {
  EffectCatalog._();

  static final Map<EffectType, EffectDescriptor> descriptors =
      Map.unmodifiable(_buildDescriptors());

  static EffectDescriptor forType(EffectType type) => descriptors[type]!;

  static Iterable<EffectDescriptor> inWorkspace(EffectWorkspace workspace) =>
      descriptors.values
          .where((descriptor) => descriptor.workspace == workspace);

  static Map<EffectType, EffectDescriptor> _buildDescriptors() {
    final result = <EffectType, EffectDescriptor>{};

    void addWorkspace(
      Set<EffectType> types, {
      required EffectWorkspace workspace,
      required EffectRole role,
      required EffectInputPolicy inputPolicy,
      FilterKind? filterKind,
      AnimationKind? animationKind,
    }) {
      for (final type in types) {
        final previous = result[type];
        if (previous != null) {
          throw StateError(
            'Effect ${type.name} belongs to both '
            '${previous.workspace.name} and ${workspace.name}.',
          );
        }

        result[type] = EffectDescriptor(
          type: type,
          workspace: workspace,
          role: role,
          inputPolicy: _inputPolicyOverrides[type] ?? inputPolicy,
          filterKind: filterKind,
          animationKind: animationKind,
          tags: Set.unmodifiable(_tagsFor(type)),
          capabilities: _animatedTypes.contains(type)
              ? const {EffectCapability.animated}
              : const {},
        );
      }
    }

    addWorkspace(
      _filters,
      workspace: EffectWorkspace.filters,
      role: EffectRole.modifier,
      inputPolicy: EffectInputPolicy.requiresPixels,
      filterKind: FilterKind.filter,
    );
    addWorkspace(
      _materials,
      workspace: EffectWorkspace.materials,
      role: EffectRole.modifier,
      inputPolicy: EffectInputPolicy.requiresPixels,
    );
    addWorkspace(
      _generators,
      workspace: EffectWorkspace.generators,
      role: EffectRole.generator,
      inputPolicy: EffectInputPolicy.requiresEmptyLayer,
    );
    addWorkspace(
      _animationTransformers,
      workspace: EffectWorkspace.animation,
      role: EffectRole.modifier,
      inputPolicy: EffectInputPolicy.requiresPixels,
      animationKind: AnimationKind.transformer,
    );
    addWorkspace(
      _animationSpecialEffects,
      workspace: EffectWorkspace.animation,
      role: EffectRole.overlay,
      inputPolicy: EffectInputPolicy.anyLayer,
      animationKind: AnimationKind.specialEffect,
    );
    addWorkspace(
      _lighting,
      workspace: EffectWorkspace.lighting,
      role: EffectRole.overlay,
      inputPolicy: EffectInputPolicy.requiresPixels,
    );
    addWorkspace(
      _distortions,
      workspace: EffectWorkspace.filters,
      role: EffectRole.modifier,
      inputPolicy: EffectInputPolicy.requiresPixels,
      filterKind: FilterKind.distortion,
    );

    final missing =
        EffectType.values.where((type) => !result.containsKey(type));
    if (missing.isNotEmpty) {
      throw StateError(
        'Effect catalog is missing: ${missing.map((type) => type.name).join(', ')}',
      );
    }

    return result;
  }

  static Set<EffectTag> _tagsFor(EffectType type) {
    final tags = <EffectTag>{};
    if (_particleTypes.contains(type)) tags.add(EffectTag.particles);
    if (_natureTypes.contains(type)) tags.add(EffectTag.nature);
    if (_environmentTypes.contains(type)) tags.add(EffectTag.environment);
    if (_printTypes.contains(type)) tags.add(EffectTag.print);
    if (_retroTypes.contains(type)) tags.add(EffectTag.retro);
    if (_sciFiTypes.contains(type)) tags.add(EffectTag.sciFi);
    if (_lighting.contains(type) || type == EffectType.vignette) {
      tags.add(EffectTag.lighting);
    }
    return tags;
  }

  static const Map<EffectType, EffectInputPolicy> _inputPolicyOverrides = {
    EffectType.hitFlash: EffectInputPolicy.requiresPixels,
    EffectType.ghostTrail: EffectInputPolicy.requiresPixels,
    EffectType.energyShield: EffectInputPolicy.requiresPixels,
    EffectType.slimeDrip: EffectInputPolicy.requiresPixels,
    EffectType.slashArc: EffectInputPolicy.requiresPixels,
    EffectType.hangingIcicles: EffectInputPolicy.requiresPixels,
    EffectType.hologramGlitch: EffectInputPolicy.requiresPixels,
    EffectType.frostGlaze: EffectInputPolicy.requiresPixels,
    EffectType.viscousSlime: EffectInputPolicy.requiresPixels,
    EffectType.crystalShardReflector: EffectInputPolicy.requiresPixels,
    EffectType.waterRippleWake: EffectInputPolicy.requiresPixels,
    EffectType.sproutingBramble: EffectInputPolicy.requiresPixels,
    EffectType.eldritchPeepingEyes: EffectInputPolicy.requiresPixels,
    EffectType.fog: EffectInputPolicy.requiresPixels,
    EffectType.radiantRays: EffectInputPolicy.anyLayer,
    EffectType.solarEclipse: EffectInputPolicy.anyLayer,
    EffectType.sunbeamGodRays: EffectInputPolicy.anyLayer,
    EffectType.auroraCurtains: EffectInputPolicy.anyLayer,
    EffectType.supernovaCorona: EffectInputPolicy.anyLayer,
    EffectType.orbitingMoons: EffectInputPolicy.anyLayer,
    EffectType.zodiacConstellation: EffectInputPolicy.anyLayer,
    EffectType.sacredGeometryHalo: EffectInputPolicy.anyLayer,
    EffectType.floatingSigils: EffectInputPolicy.anyLayer,
    EffectType.alchemicalCircle: EffectInputPolicy.anyLayer,
  };

  static const Set<EffectType> _filters = {
    EffectType.brightness,
    EffectType.contrast,
    EffectType.invert,
    EffectType.grayscale,
    EffectType.sepia,
    EffectType.threshold,
    EffectType.pixelate,
    EffectType.blur,
    EffectType.sharpen,
    EffectType.emboss,
    EffectType.noise,
    EffectType.colorBalance,
    EffectType.dithering,
    EffectType.outline,
    EffectType.paletteReduction,
    EffectType.watercolor,
    EffectType.halftone,
    EffectType.oilPaint,
    EffectType.gradient,
    EffectType.stainedGlass,
    EffectType.opacity,
    EffectType.crt,
    EffectType.lcdMatrix,
    EffectType.risographPrint,
    EffectType.inkCrosshatch,
    EffectType.topographicContours,
    EffectType.paperCutout,
    EffectType.celShading,
    EffectType.lowPolyFacets,
    EffectType.asciiMosaic,
    EffectType.woodblockUkiyoe,
    EffectType.cyanotypePrint,
    EffectType.linocutStamp,
    EffectType.byzantineMosaic,
    EffectType.chalkPastel,
    EffectType.waxSgraffito,
    EffectType.benDayComic,
    EffectType.delftwareTile,
    EffectType.thermalReceipt,
    EffectType.ditheredFrostedBlur,
    EffectType.luminanceGradientMap,
    EffectType.kintsugiLacquer,
    EffectType.petrifiedAgate,
    EffectType.normalMap,
    EffectType.vignette,
    EffectType.platformer,
  };

  static const Set<EffectType> _materials = {
    EffectType.wood,
    EffectType.crystal,
    EffectType.metal,
    EffectType.stone,
    EffectType.ice,
    EffectType.treeBark,
    EffectType.leafVenation,
    EffectType.groundTexture,
    EffectType.wallTexture,
    EffectType.rustCorrosion,
    EffectType.wornFabric,
    EffectType.crackedCeramic,
    EffectType.mossLichen,
    EffectType.paintPeeling,
    EffectType.romanTravertine,
    EffectType.perlinWorms,
    EffectType.voronoi,
  };

  static const Set<EffectType> _generators = {
    EffectType.mountainRange,
    EffectType.forest,
    EffectType.ocean,
    EffectType.cloudFormation,
    EffectType.city,
    EffectType.cellularDungeon,
    EffectType.gothicRosette,
    EffectType.runicMaze,
    EffectType.circuitBoard,
    EffectType.deepSpaceNebula,
    EffectType.spaceshipHull,
    EffectType.bismuthCrystals,
    EffectType.coralReef,
    EffectType.basaltColumns,
    EffectType.banyanMangrove,
    EffectType.glacialCrevasse,
    EffectType.sandDunes,
    EffectType.tidalRockPool,
  };

  static const Set<EffectType> _animationTransformers = {
    EffectType.pulse,
    EffectType.wave,
    EffectType.rotate,
    EffectType.float,
    EffectType.simpleFloat,
    EffectType.physicsFloat,
    EffectType.shake,
    EffectType.quickShake,
    EffectType.cameraShake,
    EffectType.dissolve,
    EffectType.fadeDissolve,
    EffectType.melt,
    EffectType.jello,
    EffectType.wipe,
    EffectType.colorCycling,
    EffectType.squashStretch,
    EffectType.breathing,
    EffectType.windSway,
    EffectType.kaleidoscope,
  };

  static const Set<EffectType> _animationSpecialEffects = {
    EffectType.hologramGlitch,
    EffectType.fire,
    EffectType.fog,
    EffectType.rain,
    EffectType.sparkle,
    EffectType.particle,
    EffectType.explosion,
    EffectType.oceanWaves,
    EffectType.clouds,
    EffectType.sky,
    EffectType.hitFlash,
    EffectType.ghostTrail,
    EffectType.starfield,
    EffectType.electricArc,
    EffectType.blizzard,
    EffectType.portalVortex,
    EffectType.energyShield,
    EffectType.burningEmbers,
    EffectType.risingBubbles,
    EffectType.slimeDrip,
    EffectType.radialShockwave,
    EffectType.slashArc,
    EffectType.meteorShower,
    EffectType.autumnWind,
    EffectType.soulWisps,
    EffectType.abyssalTentacles,
    EffectType.cursedChains,
    EffectType.beamTeleport,
    EffectType.dangerAlarm,
    EffectType.coinFountain,
    EffectType.magmaFissures,
    EffectType.dragonAura,
    EffectType.waterfallCascade,
    EffectType.fireflySwarm,
    EffectType.whisperingReeds,
    EffectType.geyserVent,
    EffectType.stalactiteDrips,
    EffectType.lichenMoss,
    EffectType.sporeBloom,
    EffectType.dustDevil,
    EffectType.actionSpeedLines,
    EffectType.chromaticEchoDash,
    EffectType.boosterThruster,
    EffectType.crownSoulFire,
    EffectType.hangingIcicles,
    EffectType.frostGlaze,
    EffectType.viscousSlime,
    EffectType.arcLightning,
    EffectType.kiFlareAura,
    EffectType.orbitingRunesHalo,
    EffectType.hexagonalAegis,
    EffectType.crystalShardReflector,
    EffectType.gravitySingularity,
    EffectType.stompDustImpact,
    EffectType.waterRippleWake,
    EffectType.sproutingBramble,
    EffectType.abyssalTendrilMiasma,
    EffectType.lostSoulWisps,
    EffectType.eldritchPeepingEyes,
    EffectType.tacticalReticle,
  };

  static const Set<EffectType> _lighting = {
    EffectType.glow,
    EffectType.dropShadow,
    EffectType.rimLight,
    EffectType.radiantRays,
    EffectType.underwaterCaustics,
    EffectType.solarEclipse,
    EffectType.sunbeamGodRays,
    EffectType.auroraCurtains,
    EffectType.directionalLightRamp,
    EffectType.silhouetteDepthBevel,
    EffectType.supernovaCorona,
    EffectType.orbitingMoons,
    EffectType.zodiacConstellation,
    EffectType.sacredGeometryHalo,
    EffectType.floatingSigils,
    EffectType.alchemicalCircle,
  };

  static const Set<EffectType> _distortions = {
    EffectType.glitch,
    EffectType.chromaticAberration,
    EffectType.pixelSorting,
    EffectType.isometricExtrusion,
    EffectType.voronoiShatter,
    EffectType.windAshDispersal,
    EffectType.lateralSliceGlitch,
    EffectType.directionalMotionBlur,
    EffectType.radialZoomBlur,
    EffectType.holoScanlineGlitch,
    EffectType.nanotechCircuit,
  };

  // Kept equivalent to the legacy Effect.isAnimation switch. Workspace and
  // animation capability intentionally remain independent.
  static const Set<EffectType> _animatedTypes = {
    EffectType.sparkle,
    EffectType.particle,
    EffectType.pulse,
    EffectType.wave,
    EffectType.rotate,
    EffectType.float,
    EffectType.simpleFloat,
    EffectType.physicsFloat,
    EffectType.shake,
    EffectType.quickShake,
    EffectType.cameraShake,
    EffectType.dissolve,
    EffectType.fadeDissolve,
    EffectType.melt,
    EffectType.explosion,
    EffectType.jello,
    EffectType.wipe,
    EffectType.rain,
    EffectType.fire,
    EffectType.oceanWaves,
    EffectType.clouds,
    EffectType.sky,
    EffectType.colorCycling,
    EffectType.squashStretch,
    EffectType.breathing,
    EffectType.windSway,
    EffectType.hitFlash,
    EffectType.ghostTrail,
    EffectType.starfield,
    EffectType.electricArc,
    EffectType.blizzard,
    EffectType.portalVortex,
    EffectType.energyShield,
    EffectType.radiantRays,
    EffectType.burningEmbers,
    EffectType.underwaterCaustics,
    EffectType.risingBubbles,
    EffectType.slimeDrip,
    EffectType.radialShockwave,
    EffectType.slashArc,
    EffectType.hologramGlitch,
    EffectType.solarEclipse,
    EffectType.meteorShower,
    EffectType.autumnWind,
    EffectType.soulWisps,
    EffectType.abyssalTentacles,
    EffectType.cursedChains,
    EffectType.beamTeleport,
    EffectType.dangerAlarm,
    EffectType.coinFountain,
    EffectType.magmaFissures,
    EffectType.frostGlaze,
    EffectType.dragonAura,
    EffectType.cellularDungeon,
    EffectType.gothicRosette,
    EffectType.runicMaze,
    EffectType.circuitBoard,
    EffectType.deepSpaceNebula,
    EffectType.spaceshipHull,
    EffectType.bismuthCrystals,
    EffectType.coralReef,
    EffectType.basaltColumns,
    EffectType.mountainRange,
    EffectType.waterfallCascade,
    EffectType.fireflySwarm,
    EffectType.whisperingReeds,
    EffectType.geyserVent,
    EffectType.stalactiteDrips,
    EffectType.lichenMoss,
    EffectType.sporeBloom,
    EffectType.banyanMangrove,
    EffectType.sunbeamGodRays,
    EffectType.dustDevil,
    EffectType.auroraCurtains,
    EffectType.glacialCrevasse,
    EffectType.sandDunes,
    EffectType.tidalRockPool,
    EffectType.kaleidoscope,
  };

  static const Set<EffectType> _natureTypes = {
    EffectType.fire,
    EffectType.rain,
    EffectType.fog,
    EffectType.wood,
    EffectType.stone,
    EffectType.ice,
    EffectType.forest,
    EffectType.ocean,
    EffectType.clouds,
    EffectType.treeBark,
    EffectType.leafVenation,
    EffectType.coralReef,
    EffectType.waterfallCascade,
    EffectType.fireflySwarm,
    EffectType.whisperingReeds,
    EffectType.lichenMoss,
    EffectType.sporeBloom,
    EffectType.banyanMangrove,
    EffectType.dustDevil,
    EffectType.glacialCrevasse,
    EffectType.sandDunes,
    EffectType.tidalRockPool,
  };

  static const Set<EffectType> _particleTypes = {
    EffectType.sparkle,
    EffectType.particle,
    EffectType.explosion,
    EffectType.starfield,
    EffectType.electricArc,
    EffectType.blizzard,
    EffectType.burningEmbers,
    EffectType.risingBubbles,
    EffectType.meteorShower,
    EffectType.autumnWind,
    EffectType.soulWisps,
    EffectType.coinFountain,
    EffectType.dragonAura,
    EffectType.fireflySwarm,
    EffectType.geyserVent,
    EffectType.sporeBloom,
    EffectType.dustDevil,
    EffectType.actionSpeedLines,
    EffectType.arcLightning,
    EffectType.lostSoulWisps,
  };

  static const Set<EffectType> _environmentTypes = {
    EffectType.mountainRange,
    EffectType.oceanWaves,
    EffectType.cloudFormation,
    EffectType.city,
    EffectType.sky,
    EffectType.platformer,
    EffectType.deepSpaceNebula,
    EffectType.cellularDungeon,
  };

  static const Set<EffectType> _printTypes = {
    EffectType.risographPrint,
    EffectType.inkCrosshatch,
    EffectType.woodblockUkiyoe,
    EffectType.cyanotypePrint,
    EffectType.linocutStamp,
    EffectType.benDayComic,
    EffectType.thermalReceipt,
  };

  static const Set<EffectType> _retroTypes = {
    EffectType.crt,
    EffectType.lcdMatrix,
    EffectType.halftone,
    EffectType.dithering,
    EffectType.pixelate,
  };

  static const Set<EffectType> _sciFiTypes = {
    EffectType.starfield,
    EffectType.portalVortex,
    EffectType.energyShield,
    EffectType.hologramGlitch,
    EffectType.spaceshipHull,
    EffectType.tacticalReticle,
    EffectType.holoScanlineGlitch,
    EffectType.nanotechCircuit,
  };
}
