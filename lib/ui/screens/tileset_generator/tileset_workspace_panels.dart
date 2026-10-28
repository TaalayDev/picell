import 'package:flutter/material.dart';
import '../../../app/theme/pv_tokens.dart';
import '../../widgets/pv/pv_compact_controls.dart';
import '../../../pixel/tileset/tileset_canvas.dart';
import '../../../pixel/tileset/tileset_collection.dart';
import '../../../pixel/tileset/tileset_generator.dart';
import 'tileset_atlas_cache.dart';
import 'tileset_canvas_painter.dart';

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.title, required this.colors, required this.child, this.onClose, this.trailing});
  final String title;
  final TilesetWorkspaceColors colors;
  final Widget child;
  final VoidCallback? onClose;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Material(
      color: colors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            height: 38,
            padding: EdgeInsets.fromLTRB(14, 0, onClose == null ? 14 : 4, 0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider))),
            child: Row(children: [
              Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.text))),
              if (trailing != null) trailing!,
              if (onClose != null)
                IconButton(
                    tooltip: 'Close panel',
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16)),
            ])),
        Expanded(child: child),
      ]));
}

/// Shared compact button styles for the side panels.
ButtonStyle _outlined(BuildContext context, {Color? foreground}) => OutlinedButton.styleFrom(
    minimumSize: const Size(0, 30),
    visualDensity: VisualDensity.compact,
    foregroundColor: foreground,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.pv.buttonRadius)));

ButtonStyle _filled(BuildContext context) => FilledButton.styleFrom(
    minimumSize: const Size(0, 34),
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.pv.buttonRadius)));

/// Muted "label value" row for the inspector.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {required this.colors});
  final String label, value;
  final TilesetWorkspaceColors colors;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 72, child: Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: colors.text))),
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
        trailing: Text('${collection.entries.length}', style: context.pv.mono(size: 11, color: colors.textMuted)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: FilledButton.icon(
                  key: const ValueKey('workspace-new-tileset'),
                  style: _filled(context),
                  onPressed: enabled ? onCreate : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New tileset'))),
          Expanded(
              child: collection.entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('No tilesets yet. Create one to start filling the canvas.',
                          style: TextStyle(fontSize: 12, color: colors.textMuted)))
                  : ListView(padding: const EdgeInsets.only(bottom: 8), children: [
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
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.only(left: 10, right: 0),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        minTileHeight: 44,
        leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
                width: 30,
                height: 30,
                child: CustomPaint(painter: TilesetThumbPainter(atlas, entry, null, colors.checkerA)))),
        title: Text(d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (!onCanvas) ...[
              Tooltip(
                  message: 'Not on canvas',
                  child: Icon(Icons.visibility_off_outlined, size: 11, color: colors.textMuted)),
              const SizedBox(width: 4),
            ],
            Expanded(
                child: Text(onCanvas ? _setSummary(entry) : '${_setSummary(entry)} · not on canvas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: colors.textMuted))),
          ]),
          if (mismatch)
            Text('Different geometry · regenerate',
                key: ValueKey('geometry-mismatch-${entry.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.warn, fontSize: 11)),
        ]),
        trailing: PopupMenuButton<String>(
            iconSize: 18,
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
              child: Wrap(spacing: 3, runSpacing: 3, children: [
                for (final tile in d.tiles)
                  Tooltip(
                      message:
                          '${tile.nameFor(d.settings.perspective, type: d.settings.type)} · v${tile.variation + 1}',
                      child: InkWell(
                          onTap: enabled ? () => onAddTile(entry, tile) : null,
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                              width: 30,
                              height: 30,
                              child:
                                  CustomPaint(painter: TilesetThumbPainter(atlas, entry, tile.id, colors.checkerA))))),
              ])),
          const SizedBox(height: 4),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Tap a tile to place a copy on the canvas.',
                  style: TextStyle(color: colors.textMuted, fontSize: 11))),
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
      body = ListView(padding: const EdgeInsets.all(12), children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          OutlinedButton.icon(
              style: _outlined(context),
              onPressed: enabled ? () => onAlign(true) : null,
              icon: const Icon(Icons.align_horizontal_left, size: 15),
              label: const Text('Align left')),
          OutlinedButton.icon(
              style: _outlined(context),
              onPressed: enabled ? () => onAlign(false) : null,
              icon: const Icon(Icons.align_vertical_top, size: 15),
              label: const Text('Align top')),
          OutlinedButton.icon(
              style: _outlined(context),
              onPressed: enabled ? onRemoveFromCanvas : null,
              icon: const Icon(Icons.remove_circle_outline, size: 15),
              label: const Text('Remove from canvas')),
        ]),
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
    final muted = TextStyle(color: colors.textMuted, fontSize: 11, height: 1.35);
    return ListView(padding: const EdgeInsets.all(12), children: [
      _Fact('Geometry', '${collection.perspective.label} · ${collection.tileSize}px', colors: colors),
      _Fact(
          'On canvas',
          '${count(TilesetCanvasKind.set)} sets · ${count(TilesetCanvasKind.tile)} tiles · '
              '${count(TilesetCanvasKind.note)} notes',
          colors: colors),
      _Fact('Zoom', '${(zoom * 100).round()}%', colors: colors),
      const SizedBox(height: 12),
      Text('Canvas controls', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.text)),
      const SizedBox(height: 6),
      for (final tip in const [
        'Drag an item to move it. Items snap to the tile grid.',
        'Drag empty space to select several items. Hold Shift to add to the selection.',
        'Scroll or two-finger drag to pan. Ctrl/Cmd + scroll or pinch to zoom.',
        'Use the Hand tool to pan with one finger or the mouse.',
        'Double-click a tileset to edit it.',
        'Delete removes items from the canvas only; sets stay in the project.',
      ])
        Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(top: 5, right: 6),
                  child: Container(width: 3, height: 3, color: colors.textMuted)),
              Expanded(child: Text(tip, style: muted)),
            ])),
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
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _Fact(
          'Recipe',
          '${recipe.base.label} · ${recipe.surface.label}'
              '${recipe.platform ? ' · Platform' : ''}${recipe.vegetation ? ' · Vegetation' : ''}',
          colors: colors),
      _Fact('Tiles', '${d.settings.parts.length} parts × ${d.settings.variations} variations = ${d.tiles.length}',
          colors: colors),
      _Fact('Protected', '${d.tiles.where((t) => t.protected).length}', colors: colors),
      _Fact('Seed', '${config.seed}', colors: colors),
      if (!collection.matchesGeometry(entry))
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                'Generated as ${d.settings.perspective.label} · ${d.settings.size}px. '
                'Regenerate to match the project.',
                style: TextStyle(color: colors.warn, fontSize: 12))),
      const SizedBox(height: 8),
      Row(children: [
        for (final color in d.settings.palette)
          Expanded(
              child: Container(
                  height: 18,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: colors.divider)))),
      ]),
      const SizedBox(height: 12),
      FilledButton.icon(
          key: const ValueKey('inspector-edit'),
          style: _filled(context),
          onPressed: enabled ? () => onEdit(entry) : null,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit tileset')),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        OutlinedButton(
            style: _outlined(context), onPressed: enabled ? () => onRename(entry) : null, child: const Text('Rename')),
        OutlinedButton(
            style: _outlined(context),
            onPressed: enabled ? () => onDuplicate(entry) : null,
            child: const Text('Duplicate')),
        OutlinedButton(
            style: _outlined(context),
            onPressed: enabled ? onRemoveFromCanvas : null,
            child: const Text('Remove from canvas')),
        OutlinedButton(
            key: const ValueKey('inspector-delete'),
            onPressed: enabled ? () => onDelete(entry) : null,
            style: _outlined(context, foreground: colors.warn),
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
    return ListView(padding: const EdgeInsets.all(12), children: [
      AspectRatio(
          aspectRatio: s.spriteWidth / s.spriteHeight,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.pv.buttonRadius),
                  border: Border.all(color: colors.divider)),
              child: CustomPaint(painter: TilesetThumbPainter(atlas, entry, tile.id, colors.checkerA)))),
      const SizedBox(height: 10),
      Text(tile.nameFor(s.perspective, type: s.type),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      _Fact('Group', '${tile.groupFor(s.perspective, type: s.type)} · variation ${tile.variation + 1}', colors: colors),
      _Fact('Mask', '${tile.mask} · revision ${tile.revision}${tile.protected ? ' · protected' : ''}', colors: colors),
      _Fact('From', entry.document.name, colors: colors),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        OutlinedButton(
            style: _outlined(context), onPressed: enabled ? onOpenSet : null, child: const Text('Select tileset')),
        OutlinedButton(
            style: _outlined(context),
            onPressed: enabled ? onRemoveFromCanvas : null,
            child: const Text('Remove from canvas')),
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
    Widget stepper(String label, int value, void Function(int) set) => PvStepper(
        label: label,
        value: value,
        min: 1,
        max: 64,
        decreaseTooltip: 'Decrease ${label.toLowerCase()}',
        increaseTooltip: 'Increase ${label.toLowerCase()}',
        onChanged: widget.enabled ? set : null);
    return ListView(padding: const EdgeInsets.all(12), children: [
      PvTextField(
          fieldKey: const ValueKey('note-text'),
          controller: _text,
          enabled: widget.enabled,
          hint: 'Note text',
          maxLines: 5,
          maxLength: 500,
          onChanged: (value) => widget.onText(item, value)),
      const SizedBox(height: 8),
      Row(children: [
        stepper('W', item.width, (v) => widget.onSize(item, v, item.height)),
        const SizedBox(width: 6),
        stepper('H', item.height, (v) => widget.onSize(item, item.width, v)),
      ]),
      const SizedBox(height: 10),
      Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
              style: _outlined(context),
              onPressed: widget.enabled ? widget.onRemoveFromCanvas : null,
              child: const Text('Remove from canvas'))),
    ]);
  }
}
