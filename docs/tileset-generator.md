# Procedural Tileset Generator

Choose **New Project → Tileset**, or **Add → Tileset Generator** in a workspace.
Both open a **Tileset collection** project. The landing page lists independently
named sets with previews, counts, rename/duplicate/delete controls, and a
**Create tileset** action. Generation and tile editing live on a separate screen;
**Add to collection** commits a new result, while **Save to collection** commits
an existing one. Standalone collections support open/save as `.pvtiles` files.

## Workspace canvas

A project opens on a workspace: a **Tilesets** panel on the left, an infinite canvas
in the middle, and an **Inspector** on the right. **New tileset** sits at the top of
the left panel. Sets, single tiles and notes can be arranged freely on the canvas;
positions are stored in cells of the project tile size (`canvas.items` in the
collection), so zoom never changes a layout. Tapping a tile in a set's expanded list
places a copy on the canvas. Dragging snaps to whole cells; drag empty space to
select several items (Shift adds), double-click a set to edit it, Delete removes
items from the canvas only. Undo/redo, grid, fit-all, notes and left/top alignment
are in the canvas toolbar. Scroll or two-finger drag pans; Ctrl/Cmd + scroll or
pinch zooms; the Hand tool pans with one pointer. Below 960 px the panels open as
overlays. New and duplicated sets land on a free spot; deleting a set drops its items.
Collections saved before the canvas existed receive an automatic flowing layout.

## Materials and modifiers

Surfaces and modifiers live in a registry (`lib/pixel/tileset/tileset_materials.dart`).
A **material** (`TilesetMaterial`) has a stable `id` stored in documents, a label,
a category, the bases it can build, a suggested palette preset, and a `shade`
function: a pure function of `MaterialPixel` (wrapped x/y, size, noise, density,
palette). Edge pixels get tile- and variation-independent noise, so any material
that stays inside that contract connects seamlessly. A **modifier**
(`TilesetModifier`) runs after the material, sees `ModifierPixel` (including the
tile mask and whether the pixel is in the shared border), declares where it
applies, and may have a 0-100 intensity. Recipes reference both by id; documents
written before the registry load unchanged, and unknown ids are rejected.

To add a material or modifier, declare it, list it in `TilesetMaterials.all` /
`TilesetModifiers.all`, and run `flutter test test/pixel/tileset/tileset_material_registry_test.dart`.
That suite covers every registered entry for every base, perspective and tile size
(plain and with all modifiers): unique stable ids, palette presets, distinct artwork,
deterministic seeds, JSON round trips, isometric sprites, and the connection seam
check across all 4,096 neighbourhoods.

## Surface editor (layered surfaces)

A set's surface is a stack of up to 6 layers, bottom first (`tileset_surface.dart`). Each layer has a pattern
(12 shapes), optional noise (speckle, blotch, streak, grain), four palette slots (middle, dark, light,
highlight), a rule for where it draws (everywhere, interior, border, exposed top, exposed sides), density, invert
and a blend (replace, only on dark, only on light, tint). The first layer fills the tile; upper layers draw detail.
The old material list survives as presets (`tileset_surface_presets.dart`) that open as editable layers.

Seams are safe by construction: patterns use wrapped coordinates, noise ignores the tile and variation on border
pixels, and neighbour-dependent areas only paint the interior. The editor shows the tile, a 3x3 repeat and a
"Seamless" pill computed with `TilesetSurfaceSpec.isSeamless`. Custom surfaces are stored in the recipe as
`surface: 'custom'` plus `surfaceSpec`. Edits are undoable (slider drags coalesce) and "Save as my surface"
keeps a surface and its palette in SharedPreferences (`tileset.mySurfaces`).

Not yet built: palette editor with suggested shades, pattern parameters (cell size, gap), solo layer,
JSON import/export, Pro gating of presets, a mobile bottom-sheet inspector.

## Set configuration and generation

**Perspective and tile size are chosen first, once per project**: in the New Project
form (or the Add → Tileset Generator dialog), and neither has a default. A project
with no saved data asks for them before anything else. Every set shares them, they
can be changed only while the project has no sets, and the set page shows them
read-only. Collections are version 2 and store `perspective` and `tileSize`. Version 1
collections derive the geometry from their sets' desired configuration (most common
wins, ties go to the earliest set); sets generated with a different geometry keep
their pixels, show a mismatch note, and adopt the project geometry when regenerated.

There is no separate settings page: **Edit tileset** and **New tileset** open the
generator directly. Its left panel holds the project geometry (read-only), the
surface list, modifiers, palette preset and custom colors, seed, and connection
parts. Name, palette and seed belong to the set; settings are a draft until the user
generates, and **Add to collection** saves the set and returns to the workspace. The
collection entry stores the configuration derived from the saved document.

## Recipe workflow

1. Open the generator from the workspace. Projection and tile size come from the
   project; set the name, palette preset and seed in the same panel.
2. Pick a surface from the list. Category chips at the top (Earth, Road, Liquid,
   Dungeon, Tech, Roof, Fabric, Stone, Wood) filter the list; each card shows a
   rendered swatch for the current perspective. There is no separate base-type
   choice: the base follows the surface (the current base is kept when the surface
   can build it). A surface that can build several bases shows a small "Use as" row
   (Ground / Wall / Floor / Path). Surfaces that cannot build anything in the current
   perspective are hidden. Catalog:
   Earth (Earth, Grass, Sand, Snow, Clay, Dirt trail), Road (Gravel, Flagstone, Asphalt, Cobblestone),
   Liquid (Water, Lava, Swamp, Ice), Dungeon (Dungeon brick, Cave wall, Cave floor, Crystal, Obsidian),
   Tech (Metal plate, Grate, Circuit, Hazard stripes, Concrete), Roof (Shingles, Terracotta, Thatch, Slate),
   Fabric (Carpet, Canvas), Stone (Stone, Brick, Masonry, Plaster) and Wood (Planks, Wood).
   Contact sheets: `docs/tileset_m1_sheet.png` to `docs/tileset_m8_sheet.png`.
   The surface follows its palette preset unless the palette was edited.
4. Apply compatible modifiers: Platform for side-view/isometric ground and Vegetation
   for ground/paths, with adjustable vegetation density. Wear (Cracks, Stains) and cover
   (Moss, Snow cover, Vines) work on every base (Snow cover not on Floor); each has an
   intensity slider and they stack in registry order (contact sheet: `docs/tileset_m3_sheet.png`). Incompatible modifiers are disabled.
5. Choose connection parts in a visual 47-shape selector. Presets include Full set,
   Surface and Platform parts. Cardinal directions refer to logical grid axes before
   projection. Counts distinguish parts from variations (e.g. 9 × 3 = 27 tiles).
6. Generate selected parts, inspect/edit the result, then add it to the collection.

Missing shapes in the sample map are marked with crossed placeholders. **Generate
missing parts** generates only the missing identities using the current generated
recipe and preserves all existing pixels, revisions and protection. Protected parts
cannot be silently removed when changing the requested parts or variations.

The original ten rendering combinations remain supported for legacy documents.
Old single-set projects open as a one-entry collection without regenerating pixels.

## Current behavior

- Desktop settings / preview / tile-browser layout, with tabs on narrow screens.
- Four material palettes, editable colors, seeded native 16/32/48px generation,
  density, and 1–6 variations per shape. In isometric mode size means logical
  diamond height, not the full sprite rectangle.
- Any non-empty subset of the 47 canonical eight-neighbor shapes, including
  combined concave corners. Diagonal bits only matter when both adjacent cardinal
  neighbors exist. Top-down terrain renders a continuous surface with boundary
  rims. Terrain and each structured type match shared-edge pixels across all
  4,096 local neighborhoods, in both directions and at every native size.
- Paint/erase preview with stroke undo/redo, grid, backgrounds, zoom, and selection
  highlights. Cells outside the sample map are empty.
- Independent pixel editor with transparent erasing. Apply protects that variation;
  unlocking preserves pixels until regeneration. Individual regeneration retains
  its mask and shared perimeter. Boundary edits can break connections. Protected
  tiles block a perspective or type change during generation to avoid mixing incompatible
  platform and terrain artwork.
- `.pvtiles` editable documents include actual pixels, generation settings, per-tile
  revisions/protection, perspective/type, and sample geometry. Version-2 documents
  remain compatible with reading existing version-1 platform documents. Open restores
  the actual generated pixels. Isometric files use version 3 to store non-square
  sprites. Recipe/partial-set documents use version 4; versions 1–3 remain readable.
  Collections use a separate version-1 envelope with stable entry IDs and nested
  documents. Collection imports accept both envelopes and legacy single documents.
- PNG atlas and matching JSON manifest export only existing parts, use eight columns, ordered by mask then
  variation. Unused atlas slots remain transparent. Counts include variations.
  Recipe and partial-set manifests use version 3 with explicit part counts and a
  completeness flag. Legacy isometric manifests use version 2 with sprite dimensions, 2:1 grid steps, top
  anchor, elevation, logical mask axes, and painter order. A 16px logical tile has
  32×16 ground, 32×24 raised-block, or 32×32 wall sprites.
- Save writes library projects, thumbnails, pixels, and protection state. Workspace
  close, home navigation, and resident-tab eviction flush dirty tilesets first.
  Failed or unverified writes keep the session open. Standalone sessions retain
  the file-save/discard behavior; cancelling a save leaves them dirty.
- Database schema 11 adds nullable `tilesetData` independently of legacy tilemaps.
  Project JSON carries that field through existing import/export and cloud payloads.
  Upload thumbnails support tilesets without animation frames.

## Isometric layout

The logical cell grid still uses 47 normalized neighbor masks. Isometric projection
maps grid columns down-right and grid rows down-left. Only exposed east/south faces
are rendered for raised tiles. Diagonal painter order resolves sprite overlap.
The preview and raw-RGBA library thumbnail share the same origins and bounds.
Picking checks visible sprite pixels in reverse painter order before falling back
to the inverse grid projection for empty cells. Pixel editing retains the full
rectangular sprite, including transparent padding and raised faces.

## Architecture

`tileset_collection.dart` owns the collection envelope and legacy migration.
`tileset_recipe.dart` defines the type/surface catalog, modifier compatibility, and
surface/platform/vegetation stages. `tileset_collection_screen.dart` owns the project
landing page and draft commits; `tileset_recipe_controls.dart` owns recipe/part controls.
`lib/pixel/tileset/tileset_generator.dart` contains pure Dart topology, deterministic
bounded-integer noise, platform rendering, and the versioned document format.
`tileset_export.dart` shares atlas ordering between PNG encoding and metadata.
`tileset_geometry.dart` owns projection, origins, painter order, visible-pixel
picking, and thumbnail composition for both square and isometric grids.
`lib/ui/screens/tileset_generator/tileset_generator_screen.dart` owns a session
with optional collection commit callbacks. `tileset_project.dart` converts the sample
geometry into a raw RGBA library thumbnail and a persistent project document.
Bulk generation/PNG encoding use `compute`; render images are cached and disposed
when replaced or when the session closes.

Generation settings are drafts until Generate is pressed. Saved documents and
exports describe the last generated result. A pending perspective change shows
which generated perspective is still displayed; it applies only after Generate.
Each type has sample geometry: islands, path junctions, wall doorways and room
footprints, connected floor rooms, or layered ground. Reset uses the generated
type while pending selectors leave the current map intact. Protected variations survive bulk
regeneration; size changes or reduced variation counts that invalidate them are
blocked until the document is saved and the affected tiles are unlocked.

## Remaining implementation

- Reuse the full pixel editor for layers, advanced tools, and tile-edit undo history.
- Expand material-specific textures and palettes, and optional per-cell elevation
  beyond the current uniform-height raised-block and wall modes.
- Add optional atlas extrusion/padding and engine-specific exporters.
- Add preview pan tools.
- Finish localization.
- Manually verify native save/open dialogs, web downloads, and live cloud round trips.
  Cloud payload serialization is covered locally; no upload is performed by tests.

Run the focused suite with `flutter test --no-pub test/pixel/tileset`.

## Generator workspace design

The workspace follows the layout of `design_prototype/Tileset Generator.dc.html`,
using the selected app theme for surfaces, accents, text, borders, checkerboards,
control shapes, and shadows. It inherits the app typography and component themes,
and updates when the active theme changes without resetting the session.
It includes an inline project name and save/export header, illustrated
perspective choices, compact settings, and an anchored generation action. The
centered preview includes floating paint/history tools, grid/background controls,
and zoom. Narrow windows use Settings, Preview, and Tiles tabs.

The browser groups 20 primary connection roles, with the remaining 27 combined
corner shapes under Additional connections. The inspector shows an enlarged
checkerboard preview, sockets, usage count, selectable variations, pixel editing,
regeneration, and protection. Loading feedback reports actual operations.
