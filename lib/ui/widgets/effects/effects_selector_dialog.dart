import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/subscription_model.dart';
import '../../../pixel/effects/effects.dart';
import '../../../providers/subscription_provider.dart';
import '../../screens/subscription_screen.dart';
import '../animated_background.dart';
import '../subscription/feature_gate.dart';
import '../../../l10n/strings.dart';

class EffectSelectorDialog extends ConsumerStatefulWidget {
  final Function(Effect) onEffectSelected;

  const EffectSelectorDialog({
    super.key,
    required this.onEffectSelected,
  });

  @override
  ConsumerState<EffectSelectorDialog> createState() =>
      _EffectSelectorDialogState();
}

class _EffectSelectorDialogState extends ConsumerState<EffectSelectorDialog> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  List<String> _getCategories(BuildContext context) {
    final s = Strings.of(context);
    return [
      s.categoryAll,
      s.categoryColorTone,
      s.categoryBlurSharpen,
      s.categoryArtistic,
      s.categoryAnimation,
      s.categoryNature,
      s.categoryParticles,
      s.categoryDistortion,
      s.categoryTextures,
      s.categorySpecialFx,
    ];
  }

  List<EffectType> get _filteredEffects {
    const allEffects = EffectType.values;

    // First filter by category
    List<EffectType> categoryFiltered;

    switch (_selectedCategoryIndex) {
      case 1: // Color & Tone
        categoryFiltered = [
          EffectType.brightness,
          EffectType.contrast,
          EffectType.invert,
          EffectType.grayscale,
          EffectType.sepia,
          EffectType.colorBalance,
          EffectType.threshold,
          EffectType.gradient,
          EffectType.paletteReduction,
          EffectType.colorCycling,
          EffectType.luminanceGradientMap,
          EffectType.directionalLightRamp,
        ];
        break;
      case 2: // Blur & Sharpen
        categoryFiltered = [
          EffectType.blur,
          EffectType.sharpen,
          EffectType.pixelate,
          EffectType.directionalMotionBlur,
          EffectType.radialZoomBlur,
          EffectType.ditheredFrostedBlur,
        ];
        break;
      case 3: // Artistic
        categoryFiltered = [
          EffectType.emboss,
          EffectType.vignette,
          EffectType.outline,
          EffectType.dithering,
          EffectType.watercolor,
          EffectType.halftone,
          EffectType.oilPaint,
          EffectType.stainedGlass,
          EffectType.crt,
          EffectType.lcdMatrix,
          EffectType.dropShadow,
          EffectType.rimLight,
          EffectType.gothicRosette,
          EffectType.runicMaze,
          EffectType.bismuthCrystals,
          EffectType.risographPrint,
          EffectType.pixelSorting,
          EffectType.inkCrosshatch,
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
          EffectType.kaleidoscope,
          EffectType.topographicContours,
          EffectType.isometricExtrusion,
          EffectType.paperCutout,
          EffectType.celShading,
          EffectType.lowPolyFacets,
          EffectType.asciiMosaic,
          EffectType.silhouetteDepthBevel,
        ];
        break;
      case 4: // Animation
        categoryFiltered = [
          EffectType.pulse,
          EffectType.wave,
          EffectType.rotate,
          EffectType.kaleidoscope,
          EffectType.float,
          EffectType.simpleFloat,
          EffectType.physicsFloat,
          EffectType.shake,
          EffectType.quickShake,
          EffectType.cameraShake,
          EffectType.jello,
          EffectType.colorCycling,
          EffectType.squashStretch,
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
        ];
        break;
      case 5: // Nature
        categoryFiltered = [
          EffectType.fire,
          EffectType.wood,
          EffectType.rain,
          EffectType.stone,
          EffectType.mountainRange,
          EffectType.forest,
          EffectType.ocean,
          EffectType.clouds,
          EffectType.treeBark,
          EffectType.leafVenation,
          EffectType.fog,
          EffectType.starfield,
          EffectType.electricArc,
          EffectType.blizzard,
          EffectType.underwaterCaustics,
          EffectType.risingBubbles,
          EffectType.slimeDrip,
          EffectType.solarEclipse,
          EffectType.meteorShower,
          EffectType.autumnWind,
          EffectType.magmaFissures,
          EffectType.frostGlaze,
          EffectType.deepSpaceNebula,
          EffectType.bismuthCrystals,
          EffectType.coralReef,
          EffectType.basaltColumns,
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
          EffectType.petrifiedAgate,
        ];
        break;
      case 6: // Particles
        categoryFiltered = [
          EffectType.sparkle,
          EffectType.particle,
          EffectType.explosion,
          EffectType.glow,
          EffectType.starfield,
          EffectType.electricArc,
          EffectType.blizzard,
          EffectType.portalVortex,
          EffectType.radiantRays,
          EffectType.burningEmbers,
          EffectType.risingBubbles,
          EffectType.slimeDrip,
          EffectType.radialShockwave,
          EffectType.slashArc,
          EffectType.meteorShower,
          EffectType.autumnWind,
          EffectType.soulWisps,
          EffectType.cursedChains,
          EffectType.beamTeleport,
          EffectType.coinFountain,
          EffectType.dragonAura,
          EffectType.fireflySwarm,
          EffectType.geyserVent,
          EffectType.stalactiteDrips,
          EffectType.sporeBloom,
          EffectType.sunbeamGodRays,
          EffectType.dustDevil,
          EffectType.actionSpeedLines,
          EffectType.chromaticEchoDash,
          EffectType.boosterThruster,
          EffectType.crownSoulFire,
          EffectType.hangingIcicles,
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
          EffectType.holoScanlineGlitch,
          EffectType.nanotechCircuit,
          EffectType.alchemicalCircle,
          EffectType.floatingSigils,
          EffectType.sacredGeometryHalo,
          EffectType.supernovaCorona,
          EffectType.orbitingMoons,
          EffectType.zodiacConstellation,
        ];
        break;
      case 7: // Distortion
        categoryFiltered = [
          EffectType.glitch,
          EffectType.dissolve,
          EffectType.fadeDissolve,
          EffectType.melt,
          EffectType.wipe,
          EffectType.crt,
          EffectType.chromaticAberration,
          EffectType.squashStretch,
          EffectType.windSway,
          EffectType.portalVortex,
          EffectType.burningEmbers,
          EffectType.underwaterCaustics,
          EffectType.radialShockwave,
          EffectType.hologramGlitch,
          EffectType.abyssalTentacles,
          EffectType.cursedChains,
          EffectType.beamTeleport,
          EffectType.dangerAlarm,
          EffectType.magmaFissures,
          EffectType.dragonAura,
          EffectType.cellularDungeon,
          EffectType.gothicRosette,
          EffectType.runicMaze,
          EffectType.voronoiShatter,
          EffectType.windAshDispersal,
          EffectType.lateralSliceGlitch,
          EffectType.directionalMotionBlur,
          EffectType.radialZoomBlur,
          EffectType.ditheredFrostedBlur,
          EffectType.luminanceGradientMap,
          EffectType.directionalLightRamp,
          EffectType.silhouetteDepthBevel,
          EffectType.actionSpeedLines,
          EffectType.chromaticEchoDash,
          EffectType.boosterThruster,
          EffectType.crownSoulFire,
          EffectType.hangingIcicles,
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
          EffectType.holoScanlineGlitch,
          EffectType.nanotechCircuit,
          EffectType.alchemicalCircle,
          EffectType.floatingSigils,
          EffectType.sacredGeometryHalo,
          EffectType.supernovaCorona,
          EffectType.orbitingMoons,
          EffectType.zodiacConstellation,
        ];
        break;
      case 8: // Textures
        categoryFiltered = [
          EffectType.crystal,
          EffectType.metal,
          EffectType.noise,
          EffectType.lcdMatrix,
          EffectType.normalMap,
          EffectType.cellularDungeon,
          EffectType.gothicRosette,
          EffectType.runicMaze,
          EffectType.circuitBoard,
          EffectType.spaceshipHull,
          EffectType.bismuthCrystals,
          EffectType.basaltColumns,
          EffectType.woodblockUkiyoe,
          EffectType.cyanotypePrint,
          EffectType.linocutStamp,
          EffectType.byzantineMosaic,
          EffectType.chalkPastel,
          EffectType.waxSgraffito,
          EffectType.delftwareTile,
          EffectType.lichenMoss,
          EffectType.banyanMangrove,
          EffectType.glacialCrevasse,
          EffectType.sandDunes,
          EffectType.romanTravertine,
          EffectType.kintsugiLacquer,
          EffectType.petrifiedAgate,
          EffectType.rustCorrosion,
          EffectType.wornFabric,
          EffectType.crackedCeramic,
          EffectType.mossLichen,
          EffectType.paintPeeling,
          EffectType.voronoiShatter,
          EffectType.windAshDispersal,
        ];
        break;
      case 9: // Special FX
        categoryFiltered = [
          EffectType.city,
          EffectType.dropShadow,
          EffectType.normalMap,
          EffectType.hitFlash,
          EffectType.ghostTrail,
          EffectType.starfield,
          EffectType.electricArc,
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
          EffectType.waterfallCascade,
          EffectType.fireflySwarm,
          EffectType.whisperingReeds,
          EffectType.geyserVent,
          EffectType.stalactiteDrips,
          EffectType.woodblockUkiyoe,
          EffectType.cyanotypePrint,
          EffectType.linocutStamp,
          EffectType.byzantineMosaic,
          EffectType.chalkPastel,
          EffectType.waxSgraffito,
          EffectType.benDayComic,
          EffectType.delftwareTile,
          EffectType.thermalReceipt,
          EffectType.lichenMoss,
          EffectType.sporeBloom,
          EffectType.banyanMangrove,
          EffectType.sunbeamGodRays,
          EffectType.dustDevil,
          EffectType.auroraCurtains,
          EffectType.glacialCrevasse,
          EffectType.sandDunes,
          EffectType.tidalRockPool,
          EffectType.romanTravertine,
          EffectType.kintsugiLacquer,
          EffectType.petrifiedAgate,
          EffectType.voronoiShatter,
          EffectType.windAshDispersal,
          EffectType.lateralSliceGlitch,
          EffectType.directionalMotionBlur,
          EffectType.radialZoomBlur,
          EffectType.ditheredFrostedBlur,
          EffectType.luminanceGradientMap,
          EffectType.directionalLightRamp,
          EffectType.silhouetteDepthBevel,
          EffectType.actionSpeedLines,
          EffectType.chromaticEchoDash,
          EffectType.boosterThruster,
          EffectType.crownSoulFire,
          EffectType.hangingIcicles,
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
          EffectType.holoScanlineGlitch,
          EffectType.nanotechCircuit,
          EffectType.alchemicalCircle,
          EffectType.floatingSigils,
          EffectType.sacredGeometryHalo,
          EffectType.supernovaCorona,
          EffectType.orbitingMoons,
          EffectType.zodiacConstellation,
        ];
        break;
      default: // All
        categoryFiltered = allEffects;
    }

    // Then filter by search
    if (_searchQuery.isEmpty) {
      return categoryFiltered;
    }

    return categoryFiltered.where((type) {
      final query =
          _searchQuery.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final enumName = type.name.toLowerCase();
      final displayName = EffectsManager.createEffect(type)
          .getName(context)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      return enumName.contains(query) || displayName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final subscriptionState = ref.watch(subscriptionStateProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile ? double.infinity : 600,
        height: isMobile ? double.infinity : 500,
        child: AnimatedBackground(
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        Strings.of(context).selectEffect,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),

                const Divider(),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: Strings.of(context).searchEffects,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Categories
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _getCategories(context).length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedCategoryIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(_getCategories(context)[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategoryIndex = index;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Effects grid
                Expanded(
                  child: _filteredEffects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 48,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(Strings.of(context).noEffectsMatch),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 150,
                          ),
                          itemCount: _filteredEffects.length,
                          itemBuilder: (context, index) {
                            final effectType = _filteredEffects[index];
                            final effect =
                                EffectsManager.createEffect(effectType);
                            final name = effect.getName(context);
                            final hasProAccess =
                                subscriptionState.hasFeatureAccess(
                                    SubscriptionFeature.advancedTools);

                            return _buildEffectCard(context, name, effectType,
                                effect, hasProAccess);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEffectCard(
    BuildContext context,
    String name,
    EffectType type,
    Effect effect,
    bool hasProAccess,
  ) {
    final color = effect.getColor(context);
    final icon = effect.getIcon(size: 28, color: color);
    final isPremium = effect.isPremium;
    final isLocked = isPremium && !hasProAccess;

    final content = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isLocked) {
            _showUpgradePrompt(context);
          } else {
            widget.onEffectSelected(effect);
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.2),
                child: icon,
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                effect.getDescription(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    if (isLocked) {
      return ProBadge(child: content);
    }

    return content;
  }

  void _showUpgradePrompt(BuildContext context) {
    final s = Strings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(s.premiumEffect),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.proVersionStatus,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              s.proFeaturesInclude,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(s.featureBullet(s.featureAdvancedEffects)),
            Text(s.featureBullet(s.featureUnlimitedProjects)),
            Text(s.featureBullet(s.featureCloudBackup)),
            Text(s.featureBullet(s.featurePrioritySupport)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.maybeLater),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the effects dialog too
              SubscriptionOfferScreen.show(
                context,
                featurePrompt: SubscriptionFeature.advancedTools,
              );
            },
            icon: const Icon(Icons.upgrade),
            label: Text(s.upgradeToPro),
          ),
        ],
      ),
    );
  }
}
