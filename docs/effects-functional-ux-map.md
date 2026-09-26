# Effects functional UX map

Status: Step 0 implementation baseline  
Scope: editor top bar, effect discovery, side-panel navigation, and effect input rules  
Source of truth audited: `EffectType`, `Effect.isAnimation`, the effect selector, the desktop side panel, and the editor toolbar

## 1. Current-state audit

- The engine exposes 186 `EffectType` values through one `Effect` abstraction and one ordered `Layer.effects` stack.
- The selector has ten overlapping presentation categories. The same effect can appear in Animation, Nature, Particles, Distortion, Textures, and Special FX.
- Animation is currently a boolean implementation capability. It does not reliably identify the feature area: several procedural scene generators are marked as animations.
- The desktop side panel is a fixed two-tab `TabController`: Layers and Effects. Both tabs contain text labels.
- The toolbar mixes frequent actions with discovery and configuration actions. Effects, Tile Mode, Grid, Onion Skin, Template Gallery, Keyboard Shortcuts, Settings, and History are separate controls.
- There is no central metadata describing an effect's primary workspace, input requirement, stack role, or animation subtype.
- There is no domain-level rule preventing a full-canvas generator from being added to a non-empty layer.

The existing effect classes, `EffectType` identifiers, serialization, and `Layer.effects` order remain unchanged during the navigation refactor.

## 2. Agreed user-facing model

Each effect has exactly one **primary workspace** used for discovery and side-panel placement. Search may additionally use multiple tags. Animation capability is independent from the primary workspace.

| Workspace | User intent | Default input policy | Stack role |
| --- | --- | --- | --- |
| Filters | Correct or stylize existing artwork | `requiresPixels` | modifier |
| Materials | Replace or enrich the surface of existing pixels while preserving the silhouette | `requiresPixels` | modifier |
| Generators | Create the layer's base image procedurally | `requiresEmptyLayer` | generator, first in stack |
| Animation / Transformers | Move, deform, reveal, or recolor existing artwork over time | `requiresPixels` | modifier |
| Animation / Special Effects | Add an animated or event-like visual around artwork | effect-specific, normally `anyLayer` | modifier/overlay |
| Lighting | Add light, shadow, depth, or atmospheric illumination | effect-specific, normally `requiresPixels` | modifier/overlay |
| Distortions | Spatially displace, fragment, or glitch existing artwork | `requiresPixels` | modifier |

Tags such as `nature`, `print`, `retro`, `particles`, `environment`, and `premium` improve search but never create another primary location for the same effect.

## 3. Effect inventory and proposed ownership

The lists below are exhaustive for the current 186 enum values. They are the classification baseline for the descriptor registry in Step 1.

### Filters — 46

Default policy: `requiresPixels`; role: `modifier`.

`brightness`, `contrast`, `invert`, `grayscale`, `sepia`, `threshold`, `pixelate`, `blur`, `sharpen`, `emboss`, `noise`, `colorBalance`, `dithering`, `outline`, `paletteReduction`, `watercolor`, `halftone`, `oilPaint`, `gradient`, `stainedGlass`, `opacity`, `crt`, `lcdMatrix`, `risographPrint`, `inkCrosshatch`, `topographicContours`, `paperCutout`, `celShading`, `lowPolyFacets`, `asciiMosaic`, `woodblockUkiyoe`, `cyanotypePrint`, `linocutStamp`, `byzantineMosaic`, `chalkPastel`, `waxSgraffito`, `benDayComic`, `delftwareTile`, `thermalReceipt`, `ditheredFrostedBlur`, `luminanceGradientMap`, `kintsugiLacquer`, `petrifiedAgate`, `normalMap`, `vignette`, `platformer`

Notes:

- `normalMap` remains a filter because its primary output is image data, even though it is commonly used by lighting workflows.
- `vignette` remains a filter because it is a whole-image tonal correction; it receives a `lighting` search tag.
- `kintsugiLacquer` and `petrifiedAgate` require a code-level alpha audit in Step 1. They stay in Filters until silhouette-preserving behavior is confirmed.

### Materials — 18

Default policy: `requiresPixels`; role: `modifier`; must preserve transparent pixels.

`wood`, `crystal`, `metal`, `stone`, `ice`, `treeBark`, `leafVenation`, `groundTexture`, `wallTexture`, `rustCorrosion`, `wornFabric`, `crackedCeramic`, `mossLichen`, `paintPeeling`, `frostGlaze`, `romanTravertine`, `perlinWorms`, `voronoi`

Notes:

- `frostGlaze` is animatable but its primary user intent is surface treatment. It receives the `animated` capability without moving to Animation.
- Any material that paints outside the source alpha is a defect against this model and must either be corrected or reclassified.

### Generators — 18

Default policy: `requiresEmptyLayer`; role: `generator`; must be first in the stack; at most one generator per layer.

`mountainRange`, `forest`, `ocean`, `cloudFormation`, `city`, `cellularDungeon`, `gothicRosette`, `runicMaze`, `circuitBoard`, `deepSpaceNebula`, `spaceshipHull`, `bismuthCrystals`, `coralReef`, `basaltColumns`, `banyanMangrove`, `glacialCrevasse`, `sandDunes`, `tidalRockPool`

Notes:

- Some generators currently report `isAnimation == true`. They stay in Generators and receive the independent `animated` capability.
- The empty-layer rule applies when adding a generator, not when reopening an existing legacy project.
- Painting on a procedural layer will later require **Convert to Pixels**; silently regenerating over manual edits is not allowed.

### Animation / Transformers — 18

Default policy: `requiresPixels`; role: `modifier`; capability: `animated`.

`pulse`, `wave`, `rotate`, `float`, `simpleFloat`, `physicsFloat`, `shake`, `quickShake`, `cameraShake`, `dissolve`, `fadeDissolve`, `melt`, `jello`, `wipe`, `colorCycling`, `squashStretch`, `windSway`, `kaleidoscope`

Secondary grouping inside the Animation panel:

- Motion: `rotate`, `float`, `simpleFloat`, `physicsFloat`, `shake`, `quickShake`, `cameraShake`, `windSway`
- Deformation: `pulse`, `wave`, `melt`, `jello`, `squashStretch`, `kaleidoscope`
- Reveal/transition: `dissolve`, `fadeDissolve`, `wipe`
- Color: `colorCycling`

### Animation / Special Effects — 58

Default policy: `anyLayer`; role: `overlay`; capability is `animated` only where the current renderer supports time-based output.

`fire`, `fog`, `rain`, `sparkle`, `particle`, `explosion`, `oceanWaves`, `clouds`, `sky`, `hitFlash`, `ghostTrail`, `starfield`, `electricArc`, `blizzard`, `portalVortex`, `energyShield`, `burningEmbers`, `risingBubbles`, `slimeDrip`, `radialShockwave`, `slashArc`, `meteorShower`, `autumnWind`, `soulWisps`, `abyssalTentacles`, `cursedChains`, `beamTeleport`, `dangerAlarm`, `coinFountain`, `magmaFissures`, `dragonAura`, `waterfallCascade`, `fireflySwarm`, `whisperingReeds`, `geyserVent`, `stalactiteDrips`, `lichenMoss`, `sporeBloom`, `dustDevil`, `actionSpeedLines`, `chromaticEchoDash`, `boosterThruster`, `crownSoulFire`, `hangingIcicles`, `viscousSlime`, `arcLightning`, `kiFlareAura`, `orbitingRunesHalo`, `hexagonalAegis`, `crystalShardReflector`, `gravitySingularity`, `stompDustImpact`, `waterRippleWake`, `sproutingBramble`, `abyssalTendrilMiasma`, `lostSoulWisps`, `eldritchPeepingEyes`, `tacticalReticle`

Input-policy exceptions to confirm in Step 1:

- Anchored effects should become `requiresPixels`: `hitFlash`, `ghostTrail`, `energyShield`, `slimeDrip`, `slashArc`, `frostGlaze`, `hangingIcicles`, `viscousSlime`, `crystalShardReflector`, `waterRippleWake`, `sproutingBramble`, `eldritchPeepingEyes`.
- Scene-like effects that fully replace the input must be moved to Generators rather than receiving `requiresEmptyLayer` inside Special Effects.

### Lighting — 16

Default policy: `requiresPixels`; role: `modifier` or `overlay`.

`glow`, `dropShadow`, `rimLight`, `radiantRays`, `underwaterCaustics`, `solarEclipse`, `sunbeamGodRays`, `auroraCurtains`, `directionalLightRamp`, `silhouetteDepthBevel`, `supernovaCorona`, `orbitingMoons`, `zodiacConstellation`, `sacredGeometryHalo`, `floatingSigils`, `alchemicalCircle`

Policy exceptions:

- `radiantRays`, `solarEclipse`, `sunbeamGodRays`, `auroraCurtains`, `supernovaCorona`, `orbitingMoons`, `zodiacConstellation`, `sacredGeometryHalo`, `floatingSigils`, and `alchemicalCircle` are overlays and may use `anyLayer` if an empty-input render test confirms meaningful output.
- Animated lighting stays in Lighting and receives the `animated` capability.

### Distortions — 12

Default policy: `requiresPixels`; role: `modifier`.

`glitch`, `chromaticAberration`, `hologramGlitch`, `pixelSorting`, `isometricExtrusion`, `voronoiShatter`, `windAshDispersal`, `lateralSliceGlitch`, `directionalMotionBlur`, `radialZoomBlur`, `holoScanlineGlitch`, `nanotechCircuit`

Notes:

- `nanotechCircuit` receives a `sci-fi` tag. If the alpha audit shows that it only decorates the source surface, it may move to Materials before Step 1 is frozen.
- `hologramGlitch` and `kaleidoscope` retain their current animation capability even though their primary workspaces differ.

## 4. Top-bar information architecture

Desktop and wide layouts use three menus. Compact layouts may collapse them into one overflow menu while keeping the same grouping.

### File

- Open / Import
- Save
- Save As / Export Image
- Share
- Projects
- History
- Keyboard Shortcuts
- Settings

### View

- Tile Mode, with checked state
- Grid, with checked state
- Onion Skin, with checked state and nested opacity control
- Zoom In
- Zoom Out

### Add

- Filters
- Materials
- Generators
- Animation
  - Transformers
  - Special Effects
- Lighting
- Distortions
- Template Gallery

The direct toolbar retains only:

- Undo and Redo
- active tool options such as brush size and spray intensity
- selection controls
- current color access
- active-mode indicators when Tile Mode, Grid, or Onion Skin is enabled

The existing mirror/symmetry control remains direct until tool-frequency telemetry or a later UX review justifies moving it.

## 5. Side-panel information architecture

Tabs use icons only and always provide tooltips and semantic labels.

Stable order:

1. Layers — always visible
2. Filters — always visible
3. Materials — visible when the project/frame uses a material
4. Generators — visible when the project/frame uses a generator
5. Animation — visible when the project/frame uses an animation effect
6. Lighting — visible when the project/frame uses a lighting effect
7. Distortions — visible when the project/frame uses a distortion
8. Add (`+`) — always visible and opens effect discovery

Visibility is derived from the current project or frame, not only the selected layer. This prevents tabs from shifting whenever the user selects another layer. A visible workspace with no matching effect on the selected layer shows an empty state and an Add action.

Selecting an effect from Add opens the corresponding workspace automatically. Animation uses one sidebar tab with Transformers and Special Effects as internal segments.

## 6. Input and stack rules

1. A visually empty layer contains no pixel with alpha greater than zero. RGB data in fully transparent pixels does not make a layer non-empty.
2. Materials and Transformers require at least one visible source pixel.
3. A Generator can only be added to a visually empty layer.
4. A layer can contain at most one Generator, and it must be the first stack item.
5. Modifiers and overlays can follow a Generator.
6. Adding effects to legacy projects is validated, but loading legacy stacks is non-destructive and must not reject the project.
7. Input rules are enforced by the domain/controller layer. Disabled buttons and messages in the UI are supplementary safeguards.
8. Painting onto a procedural layer requires a reversible **Convert to Pixels** operation integrated with Undo/Redo.

## 7. Step 1 metadata contract

Step 1 should represent this map with a central descriptor rather than more hard-coded lists:

```dart
class EffectDescriptor {
  final EffectType type;
  final EffectWorkspace workspace;
  final EffectRole role;
  final EffectInputPolicy inputPolicy;
  final AnimationKind? animationKind;
  final Set<EffectTag> tags;
  final Set<EffectCapability> capabilities;
}
```

Required invariants:

- every `EffectType` has exactly one descriptor;
- every descriptor has exactly one primary workspace;
- generator role implies `requiresEmptyLayer`;
- transformer subtype implies `requiresPixels` and `animated`;
- presentation code reads the registry instead of maintaining effect lists;
- persisted effect identifiers remain unchanged.

## 8. Risks and decisions before generator implementation

- **Behavior does not always match naming.** Alpha/input tests are required before finalizing Materials, Generators, and overlay exceptions.
- **`isAnimation` is overloaded.** It must become a compatibility getter backed by capabilities rather than remain the category source.
- **Dynamic tabs can jitter.** Stable ordering and project/frame-level visibility are mandatory.
- **Procedural layers need an explicit lifecycle.** Generator rendering, manual painting, conversion, serialization, and Undo/Redo must be designed together.
- **The top bar is horizontally constrained.** Menu labels may collapse on medium widths, but their grouping must remain consistent.

## 9. Step 0 completion criteria

- [x] Current top bar and side panel audited.
- [x] All 186 effect identifiers assigned to one proposed primary workspace.
- [x] Materials and Generators have distinct input and stack rules.
- [x] Animation is divided into Transformers and Special Effects.
- [x] Three top-bar menus and dynamic icon-only side tabs are specified.
- [x] Backward-compatibility constraints are recorded.
- [x] Generator empty-input and Material transparent-input behavior is covered by executable tests in Step 1.
- [ ] Product review resolves the explicitly marked policy exceptions before Generator enforcement ships.
