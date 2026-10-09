import 'package:flutter/foundation.dart';

import 'effects.dart';

/// Sellable collections of effects. Every [EffectType] belongs to exactly one
/// pack; [EffectPackId.free] is available to everyone.
///
/// Future effects ship in new packs so they can be sold separately, while
/// Ultimate owners get them through the `allEffects` entitlement.
enum EffectPackId {
  free,
  basicFilters,
  artistic,
  materials,
  worldGenerators,
  lightingDistortion,
  motion,
  vfxNature,
  vfxMagic,
  vfxAction,
}

@immutable
class EffectPack {
  const EffectPack({
    required this.id,
    required this.types,
  });

  final EffectPackId id;
  final Set<EffectType> types;

  bool get isFree => id == EffectPackId.free;
}

class EffectPackCatalog {
  EffectPackCatalog._();

  static final Map<EffectPackId, EffectPack> packs = Map.unmodifiable({
    for (final entry in _packTypes.entries)
      entry.key: EffectPack(id: entry.key, types: entry.value),
  });

  static final Map<EffectType, EffectPackId> _packByType =
      Map.unmodifiable(_buildIndex());

  static EffectPack forId(EffectPackId id) => packs[id]!;

  static EffectPackId packIdOf(EffectType type) => _packByType[type]!;

  static EffectPack packOf(EffectType type) => forId(packIdOf(type));

  static bool isFree(EffectType type) => packIdOf(type) == EffectPackId.free;

  static Map<EffectType, EffectPackId> _buildIndex() {
    final result = <EffectType, EffectPackId>{};
    for (final entry in _packTypes.entries) {
      for (final type in entry.value) {
        final previous = result[type];
        if (previous != null) {
          throw StateError(
            'Effect ${type.name} belongs to both '
            '${previous.name} and ${entry.key.name} packs.',
          );
        }
        result[type] = entry.key;
      }
    }

    final missingPacks =
        EffectPackId.values.where((id) => !_packTypes.containsKey(id));
    if (missingPacks.isNotEmpty) {
      throw StateError(
        'Effect packs without contents: '
        '${missingPacks.map((id) => id.name).join(', ')}',
      );
    }

    final missing = EffectType.values.where((type) => !result.containsKey(type));
    if (missing.isNotEmpty) {
      throw StateError(
        'Effects without a pack: ${missing.map((type) => type.name).join(', ')}',
      );
    }

    return result;
  }

  static const Map<EffectPackId, Set<EffectType>> _packTypes = {
    // A taste of every workspace so free users can see what packs offer.
    EffectPackId.free: {
      EffectType.brightness,
      EffectType.contrast,
      EffectType.invert,
      EffectType.grayscale,
      EffectType.sepia,
      EffectType.threshold,
      EffectType.pixelate,
      EffectType.opacity,
      EffectType.outline,
      EffectType.gradient,
      EffectType.noise,
      EffectType.vignette,
      EffectType.treeBark,
      EffectType.voronoi,
      EffectType.cellularDungeon,
      EffectType.squashStretch,
      EffectType.windSway,
      EffectType.hitFlash,
      EffectType.ghostTrail,
      EffectType.glow,
      EffectType.dropShadow,
      EffectType.glitch,
    },
    // Included with Pro.
    EffectPackId.basicFilters: {
      EffectType.blur,
      EffectType.sharpen,
      EffectType.emboss,
      EffectType.colorBalance,
      EffectType.dithering,
      EffectType.paletteReduction,
      EffectType.halftone,
      EffectType.crt,
      EffectType.lcdMatrix,
      EffectType.normalMap,
      EffectType.platformer,
      EffectType.luminanceGradientMap,
      EffectType.ditheredFrostedBlur,
    },
    EffectPackId.artistic: {
      EffectType.watercolor,
      EffectType.oilPaint,
      EffectType.stainedGlass,
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
      EffectType.kintsugiLacquer,
      EffectType.petrifiedAgate,
    },
    EffectPackId.materials: {
      EffectType.wood,
      EffectType.crystal,
      EffectType.metal,
      EffectType.stone,
      EffectType.ice,
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
    },
    EffectPackId.worldGenerators: {
      EffectType.mountainRange,
      EffectType.forest,
      EffectType.ocean,
      EffectType.cloudFormation,
      EffectType.city,
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
    },
    EffectPackId.lightingDistortion: {
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
    },
    EffectPackId.motion: {
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
      EffectType.kaleidoscope,
      EffectType.breathing,
      EffectType.glowPulse,
    },
    EffectPackId.vfxNature: {
      EffectType.fire,
      EffectType.fog,
      EffectType.rain,
      EffectType.clouds,
      EffectType.sky,
      EffectType.oceanWaves,
      EffectType.blizzard,
      EffectType.burningEmbers,
      EffectType.risingBubbles,
      EffectType.slimeDrip,
      EffectType.autumnWind,
      EffectType.magmaFissures,
      EffectType.waterfallCascade,
      EffectType.fireflySwarm,
      EffectType.whisperingReeds,
      EffectType.geyserVent,
      EffectType.stalactiteDrips,
      EffectType.lichenMoss,
      EffectType.sporeBloom,
      EffectType.dustDevil,
      EffectType.hangingIcicles,
      EffectType.frostGlaze,
      EffectType.viscousSlime,
      EffectType.sproutingBramble,
      EffectType.waterRippleWake,
    },
    EffectPackId.vfxMagic: {
      EffectType.sparkle,
      EffectType.particle,
      EffectType.soulWisps,
      EffectType.abyssalTentacles,
      EffectType.cursedChains,
      EffectType.dragonAura,
      EffectType.crownSoulFire,
      EffectType.lostSoulWisps,
      EffectType.eldritchPeepingEyes,
      EffectType.abyssalTendrilMiasma,
      EffectType.orbitingRunesHalo,
      EffectType.portalVortex,
      EffectType.kiFlareAura,
      EffectType.crystalShardReflector,
    },
    EffectPackId.vfxAction: {
      EffectType.hologramGlitch,
      EffectType.explosion,
      EffectType.starfield,
      EffectType.electricArc,
      EffectType.energyShield,
      EffectType.radialShockwave,
      EffectType.slashArc,
      EffectType.meteorShower,
      EffectType.beamTeleport,
      EffectType.dangerAlarm,
      EffectType.coinFountain,
      EffectType.actionSpeedLines,
      EffectType.chromaticEchoDash,
      EffectType.boosterThruster,
      EffectType.arcLightning,
      EffectType.hexagonalAegis,
      EffectType.gravitySingularity,
      EffectType.stompDustImpact,
      EffectType.tacticalReticle,
    },
  };
}
