# Procedural Tileset Generator

Choose **New Project → Tileset**, or **Add → Tileset Generator** in a workspace.
Both create library projects that reopen in the generator. A generator opened outside
a workspace still supports standalone `.pvtiles` documents.

Supported combinations:

- **Side View:** Platforms, Ground, Walls.
- **Top-Down:** Terrain, Paths, Walls, Floors.
- **Isometric:** Ground, Raised Blocks, Walls.

Perspective selection updates the available types. All ten prototype combinations
are functional.
Types use distinct renderers: grass-capped platforms, layered earth, gravel paths,
brick elevations, stone wall caps, and tiled floors.

## Current behavior

- Desktop settings / preview / tile-browser layout, with tabs on narrow screens.
- Four material palettes, editable colors, seeded native 16/32/48px generation,
  density, and 1–6 variations per shape. In isometric mode size means logical
  diamond height, not the full sprite rectangle.
- All 47 canonical eight-neighbor shapes for every supported type, including
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
  sprites; versions 1 and 2 remain readable.
- PNG atlas and matching JSON manifest use eight columns, ordered by mask then
  variation. Unused atlas slots remain transparent. Counts include variations.
  Isometric manifests use version 2 with sprite dimensions, 2:1 grid steps, top
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

`lib/pixel/tileset/tileset_generator.dart` contains pure Dart topology, deterministic
bounded-integer noise, platform rendering, and the versioned document format.
`tileset_export.dart` shares atlas ordering between PNG encoding and metadata.
`tileset_geometry.dart` owns projection, origins, painter order, visible-pixel
picking, and thumbnail composition for both square and isometric grids.
`lib/ui/screens/tileset_generator/tileset_generator_screen.dart` owns a session
with optional library save callbacks. `tileset_project.dart` converts the sample
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

The workspace follows `design_prototype/Tileset Generator.dc.html`: charcoal
panels, violet accents, an inline project name and save/export header, illustrated
perspective choices, compact settings, and an anchored generation action. The
centered preview includes floating paint/history tools, grid/background controls,
and zoom. Narrow windows use Settings, Preview, and Tiles tabs.

The browser groups 20 primary connection roles, with the remaining 27 combined
corner shapes under Additional connections. The inspector shows an enlarged
checkerboard preview, sockets, usage count, selectable variations, pixel editing,
regeneration, and protection. Loading feedback reports actual operations.
