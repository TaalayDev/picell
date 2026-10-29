# PixelVerse MCP connection

## Start and connect

On desktop, click the link icon at the bottom right of the app and choose
**Start connection**. The panel shows a temporary token and a button to copy
connection details. Closing the panel leaves the connection running; **Stop and
save** flushes editor changes and closes it. Connections do not automatically
start on launch. A new connection gets a new token.

Configure an MCP client that supports Streamable HTTP and custom headers:

- URL: `http://127.0.0.1:38475/mcp`
- Header: `Authorization: Bearer <token shown in the app>`

The app accepts connections only on loopback. The token grants local project
creation and editing; keep it private. No model API key is needed in PixelVerse.
The server is available on desktop; mobile and web do not expose the control.
macOS release builds include the server entitlement needed by the sandbox.

## Tools

| Tool | Arguments |
| --- | --- |
| `list_projects` | optional `offset` and `limit` (maximum 100) |
| `get_project` | `projectId` |
| `create_project` | `name`, `width`, `height`, `operationId` |
| `open_project` | `projectId` |
| `get_preview` | `projectId`, optional `frameId`; returns inline PNG |
| `set_pixels` | `projectId`, `frameId`, `layerId`, `expectedRevision`, `pixels` |
| `fill_region` | same target/revision fields, `x`, `y`, `color` |
| `apply_gradient` | same target/revision fields, `startX`, `startY`, `endX`, `endY`, `colors` (1–16); optional `type`, `steps`, `dither`, `ditherSpread`, `blend`, `target` |
| `save_project` | `projectId`; awaits local persistence |
| `undo`, `redo` | `projectId`, `expectedRevision` |

`get_project` and creation responses include stable frame IDs, layer UUIDs, and
the current revision. `layerId` is the returned string UUID, not its database
integer or array position. Pixel coordinates are zero-based and colors use
`#AARRGGBB`. `set_pixels` replaces pixels exactly, including transparent pixels;
`fill_region` uses the editor's normal source-over flood fill. Both ignore the
UI drawing tool and selection. Finish any active drawing gesture and clear the
selection before editing through MCP.

`apply_gradient` paints through `colors` from start to end. Coordinates are
canvas pixels as numbers (pixel `x,y` covers `x..x+1`, so `0.5` is a pixel
centre). `type` is `linear` (default), `radial`, `reflected`, `diamond` or
`angle`. `steps` defaults to the number of colors, so only those exact colors
are painted; `0` gives a smooth blend. `dither` is `none` (default), `bayer2`,
`bayer4` or `bayer8`, and `ditherSpread` (0–1) narrows the dithered band edge.
`blend` is `replace` (default), `over` or `lockAlpha`; `target: "contiguous"`
limits it to the same-colour area under the start point.

Example creation arguments:

```json
{"name":"Forest sprite","width":32,"height":32,"operationId":"forest-001"}
```

Use the IDs and revision from that response in `set_pixels`:

```json
{
  "projectId": 1,
  "frameId": 1,
  "layerId": "<returned layer UUID>",
  "expectedRevision": 0,
  "pixels": [
    {"x": 15, "y": 15, "color": "#FF228833"},
    {"x": 16, "y": 15, "color": "#FF336622"}
  ]
}
```

A typical session creates a project, opens it, draws one or more batches, checks
the PNG preview, and calls `save_project`. Each pixel batch creates one undo
entry. Reuse the latest returned revision after every edit. UI state changes
also advance revisions, so on `stale_revision` call `get_project` again.

## Limits and behavior

- Pixel-art projects only, maximum canvas dimensions 512×512; procedural layers
  and locked layers reject drawing.
- Maximum 65,536 pixel entries per batch and 16 pinned editor sessions per
  connection. Commands are serialized, with at most eight queued/running calls.
- Reusing `operationId` with the same creation arguments returns the same project
  for that connection. Changing arguments returns `operation_conflict`. This
  deduplication is in memory; it does not survive stopping or restarting the app.
- Validation completes before a pixel batch changes the editor. Invalid
  coordinates or colors leave pixels and undo history unchanged.
- The connection pins editor providers and project identities so closing and
  reopening a workspace uses the same live state while MCP is connected.
- `saved: false` on a drawing response means the edit is in memory and normal
  autosave is pending. Use `save_project` before relying on persistence. A failed
  save retains the snapshot for retry; the stop control reports save failures.
- Tools return `isError` and structured error codes such as `invalid_arguments`,
  `not_found`, `stale_revision`, `locked_layer`, `editor_busy`, `save_failed`, and
  `unsupported_operation`.

Deletion, sharing, publishing, importing, exporting, layer/frame creation, and
embedded chat are later milestones. Preview PNGs are currently available through
MCP; exporting files is not implemented.

## Verification

The MCP tests exercise atomic edits, exact colors with the eraser selected,
undo/redo, previews, revision checks, locked/busy rejection, save failure/retry,
reopening, authenticated HTTP initialization, tool discovery, and HTTP project
creation. The connection panel has a widget test for opening, starting, and
stopping. Existing drawing and archive-export tests are also run.

The macOS debug app has been built successfully. Windows/Linux native builds,
macOS release signing/distribution, and connections from third-party MCP clients
still need platform-specific verification.
