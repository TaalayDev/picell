import 'package:flutter/material.dart';
import '../../../pixel/tileset/tileset_canvas.dart';
import '../../../pixel/tileset/tileset_collection.dart';
import '../../../pixel/tileset/tileset_generator.dart';
import 'tileset_atlas_cache.dart';
import 'tileset_canvas_painter.dart';

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.title, required this.colors, required this.child, this.onClose});
  final String title;
  final TilesetWorkspaceColors colors;
  final Widget child;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Material(
      color: colors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
              if (onClose != null)
                IconButton(tooltip: 'Close panel', onPressed: onClose, icon: const Icon(Icons.close, size: 18)),
            ])),
        Expanded(child: child),
      ]));
}

String _setSummary(TilesetEntry entry) {
  final d = entry.document;
  return '${d.settings.parts.length} parts · ${d.tiles.length} tiles';
}

/// Left panel: every set in the project, the New tileset button, and the tiles of
/// each set ready to be added to the canvas.
class TilesetSetsPanel extends StatelessWidget {
  const TilesetSetsPanel(
      {super.key,
      required this.collection,
      required this.atlas,
      required this.colors,
      required this.enabled,
      required this.onCreate,
      required this.onAddSet,
      required this.onAddTile,
      required this.onEdit,
      required this.onRename,
      required this.onDuplicate,
      required this.onDelete,
      this.onClose});
  final TilesetCollection collection;
  final TilesetAtlasCache atlas;
  final TilesetWorkspaceColors colors;
  final bool enabled;
  final VoidCallback onCreate;
  final ValueChanged<TilesetEntry> onAddSet, onEdit, onRename, onDuplicate, onDelete;
  final void Function(TilesetEntry entry, GeneratedTile tile) onAddTile;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final onCanvas = {
      for (final item in collection.canvas.items)
        if (item.kind == TilesetCanvasKind.set) item.entryId
    };
    return _PanelFrame(
        title: 'Tilesets',
        colors: colors,
        onClose: onClose,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilledButton.icon(
                  key: const ValueKey('workspace-new-tileset'),
                  onPressed: enabled ? onCreate : null,
                  icon: const Icon(Icons.add),
                  label: const Text('New tileset'))),
          Expanded(
              child: collection.entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No tilesets yet. Create one to start filling the canvas.'))
                  : ListView(children: [
                      for (final entry in collection.entries)
                        _SetTile(
                            key: ValueKey('set-tile-${entry.id}'),
                            entry: entry,
                            collection: collection,
                            atlas: atlas,
                            colors: colors,
                            enabled: enabled,
                            onCanvas: onCanvas.contains(entry.id),
                            onAddSet: onAddSet,
                            onAddTile: onAddTile,
                            onEdit: onEdit,
                            onRename: onRename,
                            onDuplicate: onDuplicate,
                            onDelete: onDelete),
                    ])),
        ]));
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile(
      {super.key,
      required this.entry,
      required this.collection,
      required this.atlas,
      required this.colors,
      required this.enabled,
      required this.onCanvas,
      required this.onAddSet,
      required this.onAddTile,
      required this.onEdit,
      required this.onRename,
      required this.onDuplicate,
      required this.onDelete});
  final TilesetEntry entry;
  final TilesetCollection collection;
  final TilesetAtlasCache atlas;
  final TilesetWorkspaceColors colors;
  final bool enabled, onCanvas;
  final ValueChanged<TilesetEntry> onAddSet, onEdit, onRename, onDuplicate, onDelete;
  final void Function(TilesetEntry entry, GeneratedTile tile) onAddTile;

  @override
  Widget build(BuildContext context) {
    final d = entry.document, mismatch = !collection.matchesGeometry(entry);
    return ExpansionTile(
        maintainState: false,
        tilePadding: const EdgeInsets.only(left: 12, right: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: SizedBox(
            width: 36,
            height: 36,
            child: CustomPaint(painter: TilesetThumbPainter(atlas, entry, null, colors.checkerA))),
        title: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(onCanvas ? _setSummary(entry) : '${_setSummary(entry)} · not on canvas',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (mismatch)
            Text('Different geometry · regenerate',
                key: ValueKey('geometry-mismatch-${entry.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.warn, fontSize: 12)),
        ]),
        trailing: PopupMenuButton<String>(
            tooltip: 'Manage ${d.name}',
            enabled: enabled,
            onSelected: (action) {
              switch (action) {
                case 'canvas':
                  onAddSet(entry);
                case 'edit':
                  onEdit(entry);
                case 'rename':
                  onRename(entry);
                case 'duplicate':
                  onDuplicate(entry);
                case 'delete':
                  onDelete(entry);
              }
            },
            itemBuilder: (_) => [
                  PopupMenuItem(value: 'canvas', child: Text(onCanvas ? 'Show on canvas' : 'Add to canvas')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit tileset')),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ]),
        children: [
          if (mismatch)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                    'Generated as ${d.settings.perspective.label} · ${d.settings.size}px. '
                    'Regenerate to match the project (${collection.perspective.label} · ${collection.tileSize}px).',
                    style: TextStyle(color: colors.warn, fontSize: 12))),
          Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 4, runSpacing: 4, children: [
                for (final tile in d.tiles)
                  Tooltip(
                      message:
                          '${tile.nameFor(d.settings.perspective, type: d.settings.type)} · v${tile.variation + 1}',
                      child: InkWell(
                          onTap: enabled ? () => onAddTile(entry, tile) : null,
                          child: SizedBox(
                              width: 32,
                              height: 32,
                              child:
                                  CustomPaint(painter: TilesetThumbPainter(atlas, entry, tile.id, colors.checkerA))))),
              ])),
          const SizedBox(height: 4),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Tap a tile to place a copy on the canvas.',
                  style: TextStyle(color: colors.textMuted, fontSize: 12))),
        ]);
  }
}

/// Right panel: details and actions for whatever is selected on the canvas.
class TilesetInspectorPanel extends StatelessWidget {
  const TilesetInspectorPanel(
      {super.key,
      required this.collection,
      required this.atlas,
      required this.colors,
      required this.selection,
      required this.enabled,
      required this.zoom,
      required this.onEdit,
      required this.onRename,
      required this.onDuplicate,
      required this.onDelete,
      required this.onRemoveFromCanvas,
      required this.onNoteText,
      required this.onNoteSize,
      required this.onAlign,
      required this.onSelectEntry,
      this.onClose});
  final TilesetCollection collection;
  final TilesetAtlasCache atlas;
  final TilesetWorkspaceColors colors;
  final List<TilesetCanvasItem> selection;
  final bool enabled;
  final double zoom;
  final ValueChanged<TilesetEntry> onEdit, onRename, onDuplicate, onDelete;
  final VoidCallback onRemoveFromCanvas;
  final void Function(TilesetCanvasItem item, String text) onNoteText;
  final void Function(TilesetCanvasItem item, int width, int height) onNoteSize;
  final void Function(bool horizontal) onAlign;
  final ValueChanged<String> onSelectEntry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final entries = collection.entriesById;
    Widget body;
    String title = 'Inspector';
    if (selection.isEmpty) {
      body = _CanvasInfo(collection: collection, colors: colors, zoom: zoom);
    } else if (selection.length > 1) {
      title = '${selection.length} items selected';
      body = ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: enabled ? () => onAlign(true) : null,
              icon: const Icon(Icons.align_horizontal_left, size: 18),
              label: const Text('Align left')),
          OutlinedButton.icon(
              onPressed: enabled ? () => onAlign(false) : null,
              icon: const Icon(Icons.align_vertical_top, size: 18),
              label: const Text('Align top')),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: enabled ? onRemoveFromCanvas : null,
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            label: const Text('Remove from canvas')),
      ]);
    } else {
      final item = selection.single, entry = entries[item.entryId];
      switch (item.kind) {
        case TilesetCanvasKind.set:
          title = 'Tileset';
          body = entry == null
              ? const SizedBox.shrink()
              : _SetDetails(
                  entry: entry,
                  collection: collection,
                  colors: colors,
                  enabled: enabled,
                  onEdit: onEdit,
                  onRename: onRename,
                  onDuplicate: onDuplicate,
                  onDelete: onDelete,
                  onRemoveFromCanvas: onRemoveFromCanvas);
        case TilesetCanvasKind.tile:
          title = 'Tile';
          final tileIndex = entry?.document.tiles.indexWhere((t) => t.id == item.tileId) ?? -1;
          body = entry == null || tileIndex < 0
              ? const SizedBox.shrink()
              : _TileDetails(
                  entry: entry,
                  tile: entry.document.tiles[tileIndex],
                  atlas: atlas,
                  colors: colors,
                  enabled: enabled,
                  onOpenSet: () => onSelectEntry(entry.id),
                  onRemoveFromCanvas: onRemoveFromCanvas);
        case TilesetCanvasKind.note:
          title = 'Note';
          body = _NoteDetails(
              item: item,
              enabled: enabled,
              onText: onNoteText,
              onSize: onNoteSize,
              onRemoveFromCanvas: onRemoveFromCanvas);
      }
    }
    return _PanelFrame(title: title, colors: colors, onClose: onClose, child: body);
  }
}

class _CanvasInfo extends StatelessWidget {
  const _CanvasInfo({required this.collection, required this.colors, required this.zoom});
  final TilesetCollection collection;
  final TilesetWorkspaceColors colors;
  final double zoom;
  @override
  Widget build(BuildContext context) {
    final items = collection.canvas.items;
    int count(TilesetCanvasKind kind) => items.where((i) => i.kind == kind).length;
    final muted = TextStyle(color: colors.textMuted, fontSize: 13);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('${collection.perspective.label} · ${collection.tileSize}px'),
      const SizedBox(height: 4),
      Text('${count(TilesetCanvasKind.set)} sets · ${count(TilesetCanvasKind.tile)} tiles · '
          '${count(TilesetCanvasKind.note)} notes on canvas'),
      Text('Zoom ${(zoom * 100).round()}%', style: muted),
      const SizedBox(height: 16),
      Text('Canvas controls', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final tip in const [
        'Drag an item to move it. Items snap to the tile grid.',
        'Drag empty space to select several items. Hold Shift to add to the selection.',
        'Scroll or two-finger drag to pan. Ctrl/Cmd + scroll or pinch to zoom.',
        'Use the Hand tool to pan with one finger or the mouse.',
        'Double-click a tileset to edit it.',
        'Delete removes items from the canvas only; sets stay in the project.',
      ])
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $tip', style: muted)),
    ]);
  }
}

class _SetDetails extends StatelessWidget {
  const _SetDetails(
      {required this.entry,
      required this.collection,
      required this.colors,
      required this.enabled,
      required this.onEdit,
      required this.onRename,
      required this.onDuplicate,
      required this.onDelete,
      required this.onRemoveFromCanvas});
  final TilesetEntry entry;
  final TilesetCollection collection;
  final TilesetWorkspaceColors colors;
  final bool enabled;
  final ValueChanged<TilesetEntry> onEdit, onRename, onDuplicate, onDelete;
  final VoidCallback onRemoveFromCanvas;
  @override
  Widget build(BuildContext context) {
    final d = entry.document, recipe = TilesetRecipe.fromSettings(d.settings);
    final config = entry.resolvedConfiguration;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(d.name, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text('${recipe.base.label} · ${recipe.surface.label}'
          '${recipe.platform ? ' · Platform' : ''}${recipe.vegetation ? ' · Vegetation' : ''}'),
      Text('${d.settings.parts.length} parts × ${d.settings.variations} variations = ${d.tiles.length} tiles'),
      Text('${d.tiles.where((t) => t.protected).length} protected · seed ${config.seed}',
          style: TextStyle(color: colors.textMuted)),
      if (!collection.matchesGeometry(entry))
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                'Generated as ${d.settings.perspective.label} · ${d.settings.size}px. '
                'Regenerate to match the project.',
                style: TextStyle(color: colors.warn))),
      const SizedBox(height: 12),
      Wrap(spacing: 4, runSpacing: 4, children: [
        for (final color in d.settings.palette)
          Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: Color(color), border: Border.all(color: colors.divider))),
      ]),
      const SizedBox(height: 16),
      FilledButton.icon(
          key: const ValueKey('inspector-edit'),
          onPressed: enabled ? () => onEdit(entry) : null,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit tileset')),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton(onPressed: enabled ? () => onRename(entry) : null, child: const Text('Rename')),
        OutlinedButton(onPressed: enabled ? () => onDuplicate(entry) : null, child: const Text('Duplicate')),
        OutlinedButton(onPressed: enabled ? onRemoveFromCanvas : null, child: const Text('Remove from canvas')),
        OutlinedButton(
            key: const ValueKey('inspector-delete'),
            onPressed: enabled ? () => onDelete(entry) : null,
            style: OutlinedButton.styleFrom(foregroundColor: colors.warn),
            child: const Text('Delete tileset')),
      ]),
    ]);
  }
}

class _TileDetails extends StatelessWidget {
  const _TileDetails(
      {required this.entry,
      required this.tile,
      required this.atlas,
      required this.colors,
      required this.enabled,
      required this.onOpenSet,
      required this.onRemoveFromCanvas});
  final TilesetEntry entry;
  final GeneratedTile tile;
  final TilesetAtlasCache atlas;
  final TilesetWorkspaceColors colors;
  final bool enabled;
  final VoidCallback onOpenSet, onRemoveFromCanvas;
  @override
  Widget build(BuildContext context) {
    final s = entry.document.settings;
    return ListView(padding: const EdgeInsets.all(16), children: [
      AspectRatio(
          aspectRatio: s.spriteWidth / s.spriteHeight,
          child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: colors.divider)),
              child: CustomPaint(painter: TilesetThumbPainter(atlas, entry, tile.id, colors.checkerA)))),
      const SizedBox(height: 12),
      Text(tile.nameFor(s.perspective, type: s.type), style: Theme.of(context).textTheme.titleSmall),
      Text('${tile.groupFor(s.perspective, type: s.type)} · variation ${tile.variation + 1}'),
      Text('Mask ${tile.mask} · revision ${tile.revision}${tile.protected ? ' · protected' : ''}',
          style: TextStyle(color: colors.textMuted)),
      Text('From ${entry.document.name}', style: TextStyle(color: colors.textMuted)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton(onPressed: enabled ? onOpenSet : null, child: const Text('Select tileset')),
        OutlinedButton(onPressed: enabled ? onRemoveFromCanvas : null, child: const Text('Remove from canvas')),
      ]),
    ]);
  }
}

class _NoteDetails extends StatefulWidget {
  const _NoteDetails(
      {required this.item,
      required this.enabled,
      required this.onText,
      required this.onSize,
      required this.onRemoveFromCanvas});
  final TilesetCanvasItem item;
  final bool enabled;
  final void Function(TilesetCanvasItem item, String text) onText;
  final void Function(TilesetCanvasItem item, int width, int height) onSize;
  final VoidCallback onRemoveFromCanvas;
  @override
  State<_NoteDetails> createState() => _NoteDetailsState();
}

class _NoteDetailsState extends State<_NoteDetails> {
  late final _text = TextEditingController(text: widget.item.text);
  @override
  void didUpdateWidget(_NoteDetails old) {
    super.didUpdateWidget(old);
    // Switching to a different note replaces the text; typing keeps the cursor.
    if (old.item.id != widget.item.id && _text.text != widget.item.text) _text.text = widget.item.text;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    Widget stepper(String label, int value, void Function(int) set) => Row(children: [
          Expanded(child: Text('$label $value')),
          IconButton(
              tooltip: 'Decrease ${label.toLowerCase()}',
              onPressed: widget.enabled && value > 1 ? () => set(value - 1) : null,
              icon: const Icon(Icons.remove)),
          IconButton(
              tooltip: 'Increase ${label.toLowerCase()}',
              onPressed: widget.enabled && value < 64 ? () => set(value + 1) : null,
              icon: const Icon(Icons.add)),
        ]);
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
          key: const ValueKey('note-text'),
          controller: _text,
          enabled: widget.enabled,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Text', border: OutlineInputBorder()),
          onChanged: (value) => widget.onText(item, value)),
      stepper('Width', item.width, (v) => widget.onSize(item, v, item.height)),
      stepper('Height', item.height, (v) => widget.onSize(item, item.width, v)),
      const SizedBox(height: 8),
      OutlinedButton(
          onPressed: widget.enabled ? widget.onRemoveFromCanvas : null, child: const Text('Remove from canvas')),
    ]);
  }
}
