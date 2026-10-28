# PixelVerse MCP actions plan

## Goal and current scope

Let a connected AI assistant create and edit projects inside PixelVerse using
typed MCP tools. This does not create Flutter source-code projects. Adding the
dependency is preparation only: no server, model connection, or tools start yet.

`flutter_mcp: ^2.0.2` is the integration dependency. Its transitive `mcp_bundle`
dependency requires archive 3.x, while existing PixelVerse export code uses
archive 4.x APIs. The manifest retains archive 4.x through an explicit override.
Treat bundle installation/packing compatibility and platform builds as release
gates before enabling the runtime; remove the override when upstream supports 4.x.

## 1. Connection and command layer

- Add `lib/mcp/` with an MCP lifecycle service, tool registry, typed argument
  validation, and an app-command adapter backed by the existing Riverpod container.
- Start with desktop and a Streamable HTTP server on loopback. Make remote
  control an explicit app setting, show connection status and a stop control,
  authenticate sessions, and shut the server down with the app.
- Expose PixelVerse as an MCP server for an external assistant. An embedded LLM,
  API keys, background scheduling, and notifications are separate future features.
- Route writes through the same controllers as UI actions. Hold active editor
  providers alive during a command; resolve project/frame/layer IDs explicitly.
- Serialize mutations per project. Return a revision with reads and require
  `expectedRevision` on writes to reject edits against stale state. Deduplicate
  retried creation requests with an operation ID.
- Return structured results containing IDs, revision, change summary, save status,
  and stable error codes. Bound canvas dimensions, pixel counts, payload size,
  execution time, and concurrent work. Reject invalid or locked targets before
  changing state. Use `#AARRGGBB` for tool colors and integer pixel coordinates.

## 2. First usable milestone: create, inspect, draw, save

Tool names below are proposed public contracts, not implemented APIs.

| Tool | Main arguments | Existing integration / result |
| --- | --- | --- |
| `list_projects` | pagination | Project repository; return IDs, names, dimensions, types |
| `get_project` | projectId | `Projects.getProject`; return frames, layers, revision and capabilities |
| `create_project` | name, width, height, operationId | `Projects.addProject`; create the normal default frame/layer and return their IDs |
| `open_project` | projectId | Workspace controller plus editor navigation; return active target IDs |
| `get_preview` | projectId, frameId, scale | Composite current live editor state; return bounded PNG image content |
| `set_pixels` | target IDs, expectedRevision, pixels | Canvas batch drawing; one undo entry per tool call |
| `fill_region` | target IDs, expectedRevision, x, y, color | Existing flood fill controller action |
| `save_project` | projectId | Await `flushPendingProjectSave`; report persistence failure accurately |
| `undo` / `redo` | projectId, expectedRevision | Existing editor history; return revision and preview metadata |

Reuse `lib/providers/projects_provider.dart`,
`lib/providers/editor_workspace_provider.dart`,
`lib/pixel/providers/pixel_canvas_provider.dart`, and
`lib/pixel/providers/pixel_controller_provider.dart`. Avoid direct database or
raw pixel-buffer writes that bypass history, notifications, or persistence.
Check how batch drawing applies tools/modifiers; explicit pixel writes must have
deterministic behavior regardless of the tool currently selected in the UI.

Acceptance scenario: connect an assistant, create a 32×32 project, open it, draw a
small multicolor sprite with a bounded batch, inspect its PNG preview, undo/redo,
save, close, reopen, and verify the pixels persisted. Also exercise stale revision,
locked layer, invalid coordinates, disconnect, and save failure paths.

## 3. Layers and animation

Add `rename_project`, `add_layer`, `rename_layer`, `duplicate_layer`,
`set_layer_properties` (visibility/opacity), and `reorder_layers` through existing
editor actions. Then add `add_frame`, `duplicate_frame`, `set_frame_duration`,
and `select_frame` through the frame/animation controllers. Address frames and
layers by stable IDs, resolving indices inside the adapter at execution time.

Acceptance: create a layered sprite and a two-frame animation; verify ordering,
opacity, duration, undo behavior, and persistence after reopening. Ensure project
rename stays consistent between the database and any open workspace tab.

## 4. Drawing, transforms, and export

- Add deterministic line/rectangle/ellipse actions and bounded pixel patches for
  efficient artwork generation. Define clipping versus rejection explicitly.
- Add selection transforms and effects through existing controller commands.
- Adapt `lib/pixel/services/import_export_service.dart` for `export_png`,
  `export_gif`, `export_sprite_sheet`, and `export_project`. Separate byte
  generation from current BuildContext/share-dialog flows. Return downloadable
  artifacts or app-selected destinations; do not accept arbitrary write paths.
- Add import from explicitly selected files after the export path is reliable.

Acceptance: compare preview/export pixels, transparency, animation timing, and
sprite-sheet layout with the editor's current exports.

## 5. Advanced project types and destructive actions

Add templates, tilemap, procedural tileset, and rig tools only after defining
capabilities for each project type. Return unsupported-operation errors when a
tool does not apply. Build these on their existing domain controllers, with
separate validation and history behavior.

Keep project/layer/frame deletion, destructive replacement, cloud upload,
publishing, and external sharing out of the first milestone. When added, use
app-visible confirmation for destructive or externally visible actions, and
record the affected project and operation without logging artwork payloads or
credentials.

## Verification and rollout

1. Verify the dependency import and existing archive export tests; check the
   archive override against bundle pack/install functionality before using it.
2. Build desktop targets before enabling MCP, then verify mobile/web separately;
   package platform listings do not establish feature parity.
3. Test command schemas, controller integration, atomic batches, revision checks,
   operation deduplication, save errors, and connection lifecycle.
4. Run a real MCP client session through discovery, creation, edit, preview, save,
   reconnect, and shutdown. Document client setup only after verifying it.
5. Ship behind the connection setting. First release includes only milestone 2;
   expand the tool set after its end-to-end workflow passes.
