# Tileset editor integration with the web prototype

## Direction

Use `tilemap_prototype/web/pages/SimplePage.jsx` as the layout reference for the Flutter Tile Creator. Combine the prototype's source/effect/mask authoring workflow with PixelVerse's connected tileset generation, collections, variations, protected edits, and projection support.

The current bottom control editor will become a Library dock. Layers and Properties move into a persistent right panel. The large canvas stays central, with a narrow tools rail on its left. Keep Tile Creator and Map as primary workspaces. Canvas/Nodes, if implemented, are secondary authoring modes within Tile Creator, as in the prototype's `WorkspaceSwitch`.

Phases 1 and 2 are implemented: native Flutter tool rail, geometry/seed options, right Layers/Properties dock, bottom searchable preset Library, unified native-pixel canvas transform, repeat modes, pixel grid, hover inspection, eyedropper, and focus-aware canvas shortcuts. Dock preferences persist separately from project content. Existing generation remains native; graph/effect-chain integration and file interoperability are still planned. Exact visual parity awaits the prototype's missing stylesheet/build assets.

## What the prototype actually contains

- `App.jsx` routes `/` to the layer-based Canvas workspace and `/nodes` to the graph workspace.
- `SimplePage.jsx` defines the header, tools rail, options bar, canvas, status bar, right Layers/Properties panel, and bottom Library.
- `NodePalettePanel.jsx` provides a searchable folder tree and thumbnail catalog, click/drag insertion, collapse, resize, and stored dock preferences. Its default expanded height is 230 px.
- `LayersPanel.jsx` provides source layers, paint layers, effect chains, masks, blend controls, visibility, and ordering.
- `js/layers.js` compiles layer stacks into graph edges. Sources feed effects, then a layer blend; blends compose into Output. The graph owns parameter values. It also detects stacks invalidated by manual graph rewiring.
- `CanvasStage.jsx` supports pan, discrete zoom, Fit, actual pixels, 1×1/2×2/3×3 repeats, hover color inspection, eyedropper, paint tools, and source drops.
- `js/document.js` saves a versioned `.tgx` document containing nodes, edges, layers, palettes, size, and seed. It autosaves locally.
- `useTilemapStore.js` stores ordinary tile IDs in map cells. The return-to-map action in `EditorPage.jsx` adds a rendered PNG tile, not a 47-shape connected tileset.

Source completeness: the supplied folder references `../css/style.css`, but that file and a package/build manifest are absent in this repository. `/tilemap` is referenced by an action but is not registered in the supplied `App.jsx`. Exact spacing and a running visual comparison need the missing prototype assets. Component placement and behavior are available from the supplied source; proposed dimensions below are Flutter defaults, not measured CSS values.

## Target layout

```text
Header: Back · File/Edit/View · Set name · Tile Creator / Map · Save
┌───────┬───────────────────────────────────────┬──────────────────────┐
│ Tools │ Options: geometry · seed · repeat     │ Layers               │
│       │          grid · zoom · Fit · 1:1      │ source/effects/mask  │
│ Hand  ├───────────────────────────────────────┤ visibility/order     │
│ Zoom  │                                       ├──────────────────────┤
│ Pick  │          Large live canvas            │ Properties           │
│ Paint │                                       │ selected layer,      │
│ Erase │                                       │ effect, or mask      │
│ Fill  ├───────────────────────────────────────┤                      │
│ Color │ Size · zoom · hover position/color    │                      │
├───────┴───────────────────────────────────────┴──────────────────────┤
│ Library · Search · collapse                         resize handle   │
│ Folder tree        │ Source/preset thumbnail grid                    │
└────────────────────┴────────────────────────────────────────────────┘
Generation strip: connection parts · variations · Generate · Test on Map
```

Start with a 48 px tool rail, a resizable 300–380 px right panel, and a 230 px Library dock. Allow the Layers/Properties split to resize independently. Preserve a useful canvas minimum when resizing docks. Use existing PixelVerse theme tokens while matching the prototype's hierarchy, placement, density, and interaction model.

The Library contains authoring inputs, not generated output tiles. Generated Tiles remains in Map. Effects are added to a selected layer through an effect picker, following the prototype's Canvas library filter for sources.

Map keeps the same header, tool rail, canvas/status placement, and right-panel styling. Its right panel contains Generated Tiles and selected-tile properties. Its options bar contains sample layouts, paint/erase/pan, grid, zoom, Fit, and atlas mode. Hide the source Library in Map to maximize the map area; retain its state for returning to Tile Creator.

## Concept mapping

| Web concept | Combined PixelVerse behavior |
| --- | --- |
| Source node | Material, pattern, imported image, or paint source for a surface layer |
| Effect chain | Ordered, independently enabled effects on a layer; distinct from existing recipe-wide modifiers |
| Layer mask | Editable per-layer coverage; separate from the connection-shape mask |
| Layer blend | Opacity/compositing; retain existing Replace / On dark / On light / Tint semantics during migration |
| Output | Surface pixels consumed by the existing shape/projection generator |
| Palette references | Explicit palette data with adapters for the existing eight-slot surface palette |
| Templates | Complete authoring presets with stable source/effect IDs and initial parameters |
| PNG tile returned to map | A generated set with stable mask/variation identities, pixels, and provenance |
| Tilemap ID cells | Future manual tile placements; existing sample-map occupancy retains autotile semantics |

Do not reinterpret web tile IDs as Flutter occupancy values. Their map representations differ. Manual placement, if added, needs an explicit cell mode and stable set/tile references.

## Rendering and document design

1. Keep the Flutter rendering engine native. Port selected algorithms and concepts into Dart; do not embed a second JavaScript editor/runtime in the generator.
2. Add an authoring document with stable IDs for sources, effects, masks, blends, and Output, plus layer ordering metadata. Use one canonical parameter store; Canvas and a future Nodes view must edit the same data.
3. Initially adapt current `TilesetSurfaceSpec` and `TilesetRecipe` into this document and evaluate through existing implementations. Keep legacy recipes readable and render-equivalent before adding richer features.
4. Keep authored surface state distinct from the last generated result. Live canvas changes update the draft; Generate commits new output tiles under existing protected-edit rules.
5. Define render context explicitly: seed, logical size, palette, base, perspective, connection mask, variation, and border/interior coordinates. Cache by authoring revision and context; discard stale async results.
6. Preserve the seam contract. Classify effects as periodic, interior-only, or seam-affecting. Test border behavior across neighboring shapes and variations. Imported images, freehand painting, offsets, warps, and filters must not automatically receive a seamless guarantee.
7. Preserve project geometry. The prototype's arbitrary rectangular sizes and square-then-crop behavior must not replace Flutter's isometric sprite dimensions or project-wide perspective/tile size.
8. Version authoring data within the saved tileset document. Continue storing actual output pixels, revisions, protection, sample map, and collection entries. Migrations must preserve output without silently regenerating it.
9. Add `.tgx` import only after a supported-node adapter exists. Produce a compatibility report for unsupported nodes and parameter differences. Never silently discard unknown nodes or overwrite the original file. PNG import remains a separate flattened-image path.

## Delivery phases

### 1. Match the prototype layout using current functionality

- Extract a shared editor shell, tool rail, options bar, canvas viewport, split right panel, Library dock, and generation strip from the current extension-heavy screen.
- Move layer stack to right/top and Pattern/Noise/Color/Rules to right/bottom.
- Convert preset gallery content into the searchable bottom Library, initially using current presets/materials/patterns. Preserve replace-surface versus add-layer as explicit actions.
- Move seed and geometry summary to the options bar; keep Shape/Output controls accessible through compact popovers or the Properties panel.
- Keep existing save, Generate, Test on Map, map filters, and sample layout behavior.
- Persist dock preferences and selected Library category separately from project content.

Acceptance: prototype-equivalent panel placement, no old bottom parameter editor, no lost existing controls, and no generation/persistence changes.

### 2. Match canvas interactions

- One viewport transform owns pan, zoom, percentage readout, Fit, and actual pixels. Replace the current independent preview multiplier and gesture transform.
- Add 1×1/2×2/3×3 preview modes, pixel grid, hover coordinates/color, Hand, Zoom, and Eyedropper.
- Support Space-drag pan, wheel/pinch zoom, plus/minus, and Fit shortcut; ignore tool shortcuts while typing.
- Support click/drag from Library to add a layer, with clear drop feedback.
- Retain connection-shape preview as an additional view for connected tilesets.

Acceptance: repeat previews preserve native pixel proportions, zoom readout matches the viewport, and changing tools/settings does not reset view position.

### 3. Add richer layer authoring

- Introduce the canonical authoring schema and legacy adapters with render-equivalence fixtures.
- Add named source layers, ordered effect chains, per-layer opacity, enable/disable, duplicate, reorder, and optional masks.
- Add paint layers and mask painting, brush size/color, erase, fill, and eyedropper. Distinguish paint-source edits from protected edits to an individual generated variation.
- Use shared document commands for undo/redo; one slider gesture or stroke is one undo step. Keep viewport-only actions outside document history.
- Port a small verified source/effect subset first; reuse existing Dart effects only where parameter and rendering semantics match.

Acceptance: edits survive save/reopen, one source can produce connected variations, and protected output edits remain intact.

### 4. Integrate generation and map behavior

- Feed authored surfaces through current connection parts, modifiers, projection, variations, and export paths.
- Preserve logical tile identity and map occupancy when regenerating. Make missing shapes and stale results visible.
- Bound or isolate expensive preview evaluation; debounce thumbnails and cancel obsolete requests.
- Verify seam behavior for supported source/effect combinations and show a specific warning for seam-affecting edits.

Acceptance: existing 47-shape, shared-border, isometric, protected-edit, collection, and export checks pass with authored surfaces.

### 5. Add Nodes and interoperability

- Add the prototype's secondary Canvas/Nodes switch only when a usable graph editor exists.
- Canvas edits compile graph wiring; Nodes edits use the same canonical values. Validate cycles, port compatibility, missing nodes, and output reachability.
- Analyze whether a manually rewired graph is representable as layers. Offer explicit restore/adopt/detach actions; never silently replace wiring.
- Implement versioned `.tgx` import for supported nodes, followed by compatibility fixtures. Expand catalog coverage incrementally.

Acceptance: mode switching preserves pixels and selection; unsupported graphs remain intact and explain why Canvas cannot edit their structure.

## Responsive and validation requirements

- Wide screens use the prototype arrangement. Medium screens can collapse the right dock and Library. Phones use a canvas with Layers/Properties sheets and a Library drawer; do not squeeze four desktop regions into a narrow row.
- Verify panel resizing/collapse persistence, keyboard focus, drag/drop, selection sync, empty states, generation failures, and save failures.
- Capture rendered Flutter reference images for desktop, tablet, and phone; compare to the web prototype when its missing stylesheet/build assets are available.
- Test legacy round trips, authoring migrations, deterministic rendering, palette semantics, effect order, masks, pixel protection, connection seams, and isometric geometry.

Implementation starts with phase 1. Layout parity can ship independently; graph authoring and file interoperability follow only after the native schema and rendering contracts are validated.
