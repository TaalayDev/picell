import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../pixel/tileset/tileset_canvas.dart';
import '../../../pixel/tileset/tileset_collection.dart';
import '../../../pixel/tileset/tileset_generator.dart';
import 'tileset_atlas_cache.dart';
import 'tileset_canvas_painter.dart';
import 'tileset_workspace_panels.dart';

enum _Mode { none, pan, drag, marquee }

enum _Overlay { none, sets, inspector }

const _minZoom = 0.25, _maxZoom = 16.0, _undoLimit = 100;

/// Project landing page body: a sets panel, an infinite canvas to arrange sets,
/// single tiles and notes, and an inspector.
class TilesetWorkspace extends StatefulWidget {
  const TilesetWorkspace({
    super.key,
    required this.collection,
    required this.onCanvasChanged,
    required this.onCreate,
    required this.onEdit,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    this.enabled = true,
  });

  final TilesetCollection collection;
  final ValueChanged<TilesetCanvas> onCanvasChanged;
  final VoidCallback onCreate;
  final ValueChanged<TilesetEntry> onEdit, onRename, onDuplicate, onDelete;
  final bool enabled;

  @override
  State<TilesetWorkspace> createState() => TilesetWorkspaceState();
}

class TilesetWorkspaceState extends State<TilesetWorkspace> {
  final _atlas = TilesetAtlasCache();
  final _focus = FocusNode(debugLabel: 'tileset canvas');
  final _selection = <String>{};
  final _undo = <TilesetCanvas>[];
  final _redo = <TilesetCanvas>[];
  Offset _offset = const Offset(56, 64);
  double _zoom = 2;
  Size _viewport = Size.zero;
  bool _grid = true, _handTool = false, _fitted = false, _leftOpen = true, _rightOpen = true;
  _Overlay _overlay = _Overlay.none;
  _Mode _mode = _Mode.none;
  TilesetCanvas? _live;
  Rect? _marquee;
  Offset _startFocal = Offset.zero, _anchorWorld = Offset.zero;
  double _startZoom = 2;
  Map<String, ({int x, int y})> _origins = {};
  Set<String> _baseSelection = {};
  String? _coalesceKey;
  Offset _down = Offset.zero;
  DateTime? _lastTapAt;
  String? _lastTapId;

  TilesetCollection get _collection => widget.collection;
  TilesetCanvas get _canvas => _live ?? _collection.canvas;
  int get _tileSize => _collection.tileSize;
  Map<String, TilesetEntry> get _entries => _collection.entriesById;
  bool get _enabled => widget.enabled;

  @override
  void didUpdateWidget(TilesetWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collection.tileSize != _tileSize) {
      _undo.clear();
      _redo.clear();
    }
    final ids = {for (final item in _collection.canvas.items) item.id};
    _selection.removeWhere((id) => !ids.contains(id));
    _atlas.retain({for (final entry in _collection.entries) entry.id});
  }

  @override
  void dispose() {
    _focus.dispose();
    _atlas.dispose();
    super.dispose();
  }

  // ---- history ----------------------------------------------------------

  void _commit(TilesetCanvas next, {String? coalesce}) {
    final current = _collection.canvas;
    if (identical(next, current)) return;
    if (coalesce == null || coalesce != _coalesceKey) {
      _undo.add(current);
      if (_undo.length > _undoLimit) _undo.removeAt(0);
    }
    _coalesceKey = coalesce;
    _redo.clear();
    widget.onCanvasChanged(next);
  }

  void undo() {
    if (_undo.isEmpty || !_enabled) return;
    _redo.add(_collection.canvas);
    _coalesceKey = null;
    widget.onCanvasChanged(_undo.removeLast());
  }

  void redo() {
    if (_redo.isEmpty || !_enabled) return;
    _undo.add(_collection.canvas);
    _coalesceKey = null;
    widget.onCanvasChanged(_redo.removeLast());
  }

  // ---- view ---------------------------------------------------------------

  void _zoomAround(Offset focal, double zoom) {
    final next = zoom.clamp(_minZoom, _maxZoom).toDouble();
    final world = (focal - _offset) / _zoom;
    setState(() {
      _zoom = next;
      _offset = focal - world * next;
    });
  }

  Rect? _worldBounds(Iterable<TilesetCanvasItem> items) {
    Rect? bounds;
    for (final item in items) {
      final cells = tilesetCanvasItemCells(item, _entries, _tileSize);
      if (cells == null) continue;
      final rect = Rect.fromLTWH(item.x * _tileSize.toDouble(), item.y * _tileSize.toDouble(),
          cells.width * _tileSize.toDouble(), cells.height * _tileSize.toDouble());
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds;
  }

  void fit() {
    final bounds = _worldBounds(_canvas.items);
    if (bounds == null || _viewport.isEmpty) {
      setState(() {
        _zoom = 2;
        _offset = const Offset(56, 64);
      });
      return;
    }
    const margin = 72.0;
    final raw =
        math.min((_viewport.width - margin * 2) / bounds.width, (_viewport.height - margin * 2) / bounds.height);
    final zoom = (raw < 1 ? raw : (raw * 4).floorToDouble() / 4).clamp(_minZoom, 8.0).toDouble();
    setState(() {
      _zoom = zoom;
      _offset = Offset((_viewport.width - bounds.width * zoom) / 2 - bounds.left * zoom,
          (_viewport.height - bounds.height * zoom) / 2 - bounds.top * zoom);
    });
  }

  void _reveal(Iterable<String> ids) {
    final bounds = _worldBounds(_canvas.items.where((i) => ids.contains(i.id)));
    if (bounds == null || _viewport.isEmpty) return;
    final screen = Rect.fromLTWH(
        _offset.dx + bounds.left * _zoom, _offset.dy + bounds.top * _zoom, bounds.width * _zoom, bounds.height * _zoom);
    if ((Offset.zero & _viewport).deflate(24).overlaps(screen)) return;
    setState(() => _offset =
        Offset(_viewport.width / 2 - bounds.center.dx * _zoom, _viewport.height / 2 - bounds.center.dy * _zoom));
  }

  ({int x, int y}) get _viewCenterCell {
    final cell = _tileSize * _zoom;
    return (
      x: ((_viewport.width / 2 - _offset.dx) / cell).floor(),
      y: ((_viewport.height / 2 - _offset.dy) / cell).floor()
    );
  }

  // ---- items --------------------------------------------------------------

  String _newId(String prefix) {
    var id = '$prefix-${DateTime.now().microsecondsSinceEpoch}';
    while (_canvas.byId(id) != null) {
      id = '${id}_';
    }
    return id;
  }

  void _place(TilesetCanvasItem item) {
    final next = placeOnTilesetCanvas(_collection.canvas, item, _entries, _tileSize, anchor: _viewCenterCell);
    if (identical(next, _collection.canvas)) return;
    _commit(next);
    setState(() {
      _selection
        ..clear()
        ..add(item.id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal([item.id]);
    });
  }

  void _addSet(TilesetEntry entry) {
    final existing = _collection.canvas.items.where((i) => i.kind == TilesetCanvasKind.set && i.entryId == entry.id);
    if (existing.isNotEmpty) {
      setState(() {
        _selection
          ..clear()
          ..add(existing.first.id);
      });
      _reveal([existing.first.id]);
      return;
    }
    _place(TilesetCanvasItem(id: _newId('set'), kind: TilesetCanvasKind.set, entryId: entry.id, x: 0, y: 0));
  }

  void _addTile(TilesetEntry entry, GeneratedTile tile) => _place(TilesetCanvasItem(
      id: _newId('tile'), kind: TilesetCanvasKind.tile, entryId: entry.id, tileId: tile.id, x: 0, y: 0));

  void _addNote() => _place(TilesetCanvasItem(id: _newId('note'), kind: TilesetCanvasKind.note, x: 0, y: 0, text: ''));

  List<TilesetCanvasItem> get _selected => [
        for (final item in _canvas.items)
          if (_selection.contains(item.id)) item
      ];

  void _removeSelected() {
    if (_selection.isEmpty || !_enabled) return;
    _commit(_collection.canvas.removing(Set.of(_selection)));
    setState(_selection.clear);
  }

  void _moveSelected(int dx, int dy) {
    if (_selection.isEmpty || !_enabled) return;
    _commit(
        _collection.canvas.replacing([for (final item in _selected) item.copyWith(x: item.x + dx, y: item.y + dy)]));
  }

  void _duplicateSelected() {
    if (!_enabled) return;
    var canvas = _collection.canvas;
    final copies = <String>{};
    for (final item in _selected) {
      if (item.kind == TilesetCanvasKind.set) continue; // duplicating the board would not copy the set
      final id = _newId(item.kind.name);
      canvas = canvas.adding(TilesetCanvasItem(
          id: id,
          kind: item.kind,
          entryId: item.entryId,
          tileId: item.tileId,
          text: item.text,
          width: item.width,
          height: item.height,
          x: item.x + 1,
          y: item.y + 1));
      copies.add(id);
    }
    if (copies.isEmpty) return;
    _commit(canvas);
    setState(() {
      _selection
        ..clear()
        ..addAll(copies);
    });
  }

  void _align(bool horizontal) {
    final items = _selected;
    if (items.length < 2 || !_enabled) return;
    final target = horizontal ? items.map((i) => i.x).reduce(math.min) : items.map((i) => i.y).reduce(math.min);
    _commit(_collection.canvas
        .replacing([for (final i in items) horizontal ? i.copyWith(x: target) : i.copyWith(y: target)]));
  }

  void _noteText(TilesetCanvasItem item, String text) {
    if (!_enabled) return;
    _commit(_collection.canvas.replacing([item.copyWith(text: text)]), coalesce: 'note-${item.id}');
  }

  void _noteSize(TilesetCanvasItem item, int width, int height) {
    if (!_enabled) return;
    _commit(_collection.canvas.replacing([item.copyWith(width: width, height: height)]));
  }

  void _selectEntry(String entryId) {
    for (final item in _collection.canvas.items) {
      if (item.kind == TilesetCanvasKind.set && item.entryId == entryId) {
        setState(() {
          _selection
            ..clear()
            ..add(item.id);
        });
        _reveal([item.id]);
        return;
      }
    }
    final entry = _entries[entryId];
    if (entry != null) _addSet(entry);
  }

  // ---- hit testing & gestures --------------------------------------------

  Rect? _screenRect(TilesetCanvasItem item) {
    final cells = tilesetCanvasItemCells(item, _entries, _tileSize);
    return cells == null ? null : tilesetItemRect(item, cells, _tileSize, _offset, _zoom);
  }

  TilesetCanvasItem? _hit(Offset point) {
    for (final item in _canvas.items.reversed) {
      final rect = _screenRect(item);
      if (rect != null && rect.contains(point)) return item;
    }
    return null;
  }

  bool get _shift => HardwareKeyboard.instance.isShiftPressed;

  /// Position, size and zoom for tests; keeps gesture tests independent of the fit logic.
  @visibleForTesting
  Offset? debugItemCenter(String id) {
    final item = _canvas.byId(id), rect = item == null ? null : _screenRect(item);
    return rect?.center;
  }

  @visibleForTesting
  double get debugZoom => _zoom;

  void _scaleStart(ScaleStartDetails d) {
    _focus.requestFocus();
    // Pointer-down, not the point where the slop was exceeded, so drags cover the full distance.
    final grab = d.pointerCount >= 2 ? d.localFocalPoint : _down;
    _startFocal = grab;
    _startZoom = _zoom;
    _anchorWorld = (d.localFocalPoint - _offset) / _zoom;
    if (_overlay != _Overlay.none) setState(() => _overlay = _Overlay.none);
    if (d.pointerCount >= 2 || _handTool) {
      _mode = _Mode.pan;
      return;
    }
    final hit = _hit(grab);
    if (hit != null && _enabled) {
      setState(() {
        if (!_selection.contains(hit.id)) {
          if (!_shift) _selection.clear();
          _selection.add(hit.id);
        } else if (_shift) {
          _selection.remove(hit.id);
        }
      });
      _origins = {for (final item in _selected) item.id: (x: item.x, y: item.y)};
      _mode = _origins.isEmpty ? _Mode.none : _Mode.drag;
    } else {
      _baseSelection = _shift ? Set.of(_selection) : {};
      setState(() {
        _selection
          ..clear()
          ..addAll(_baseSelection);
        _marquee = Rect.fromPoints(_startFocal, _startFocal);
      });
      _mode = _Mode.marquee;
    }
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 && _mode != _Mode.pan) {
      // A second finger turns any drag or marquee into a pan/zoom.
      setState(() {
        _live = null;
        _marquee = null;
      });
      _mode = _Mode.pan;
      _startFocal = d.localFocalPoint;
      _startZoom = _zoom;
      _anchorWorld = (d.localFocalPoint - _offset) / _zoom;
    }
    switch (_mode) {
      case _Mode.pan:
        final zoom = (_startZoom * d.scale).clamp(_minZoom, _maxZoom).toDouble();
        setState(() {
          _zoom = zoom;
          _offset = d.localFocalPoint - _anchorWorld * zoom;
        });
      case _Mode.drag:
        final cell = _tileSize * _zoom;
        final dx = ((d.localFocalPoint.dx - _startFocal.dx) / cell).round();
        final dy = ((d.localFocalPoint.dy - _startFocal.dy) / cell).round();
        setState(() => _live = _collection.canvas.replacing([
              for (final item in _selected)
                if (_origins[item.id] case final o?) item.copyWith(x: o.x + dx, y: o.y + dy)
            ]));
      case _Mode.marquee:
        final box = Rect.fromPoints(_startFocal, d.localFocalPoint);
        setState(() {
          _marquee = box;
          _selection
            ..clear()
            ..addAll(_baseSelection)
            ..addAll([
              for (final item in _canvas.items)
                if (_screenRect(item)?.overlaps(box) ?? false) item.id
            ]);
        });
      case _Mode.none:
        break;
    }
  }

  void _scaleEnd(ScaleEndDetails d) {
    final live = _live;
    setState(() {
      _marquee = null;
      _live = null;
    });
    if (_mode == _Mode.drag && live != null) {
      final moved =
          live.items.any((i) => _origins[i.id] != null && (_origins[i.id]!.x != i.x || _origins[i.id]!.y != i.y));
      if (moved) _commit(live);
    }
    _mode = _Mode.none;
  }

  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final scroll = e as PointerScrollEvent;
      final zoomKey = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      if (zoomKey) {
        _zoomAround(scroll.localPosition, _zoom * math.exp(-scroll.scrollDelta.dy / 300));
      } else {
        setState(() => _offset -= scroll.scrollDelta);
      }
    });
  }

  /// A tap selects; a second tap on the same item within 350 ms opens its tileset.
  void _tapUp(TapUpDetails d) {
    _focus.requestFocus();
    final hit = _hit(d.localPosition), now = DateTime.now();
    if (_overlay != _Overlay.none) _overlay = _Overlay.none;
    final again = hit != null &&
        hit.id == _lastTapId &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!) < const Duration(milliseconds: 350);
    _lastTapAt = again ? null : now;
    _lastTapId = again ? null : hit?.id;
    if (again && _enabled && hit.kind != TilesetCanvasKind.note) {
      final entry = _entries[hit.entryId];
      if (entry != null) widget.onEdit(entry);
    }
    setState(() {
      if (hit == null) {
        if (!_shift) _selection.clear();
      } else if (_shift) {
        if (!_selection.remove(hit.id)) _selection.add(hit.id);
      } else {
        _selection
          ..clear()
          ..add(hit.id);
      }
    });
  }

  // ---- build ---------------------------------------------------------------

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
        for (final meta in [true, false]) ...{
          SingleActivator(LogicalKeyboardKey.keyZ, meta: meta, control: !meta): undo,
          SingleActivator(LogicalKeyboardKey.keyZ, meta: meta, control: !meta, shift: true): redo,
          SingleActivator(LogicalKeyboardKey.keyY, meta: meta, control: !meta): redo,
          SingleActivator(LogicalKeyboardKey.keyD, meta: meta, control: !meta): _duplicateSelected,
          SingleActivator(LogicalKeyboardKey.keyA, meta: meta, control: !meta): () => setState(() => _selection
            ..clear()
            ..addAll(_canvas.items.map((i) => i.id))),
        },
        const SingleActivator(LogicalKeyboardKey.delete): _removeSelected,
        const SingleActivator(LogicalKeyboardKey.backspace): _removeSelected,
        const SingleActivator(LogicalKeyboardKey.escape): () => setState(_selection.clear),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _moveSelected(-1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _moveSelected(1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveSelected(0, -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _moveSelected(0, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () => _moveSelected(-8, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () => _moveSelected(8, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () => _moveSelected(0, -8),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () => _moveSelected(0, 8),
        const SingleActivator(LogicalKeyboardKey.keyF): fit,
        const SingleActivator(LogicalKeyboardKey.keyG): () => setState(() => _grid = !_grid),
      };

  Widget _toolbar(TilesetWorkspaceColors colors, bool wide) {
    Widget button(String tip, IconData icon, VoidCallback? onTap, {bool selected = false, Key? key}) => IconButton(
        key: key,
        tooltip: tip,
        isSelected: selected,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        style: IconButton.styleFrom(
            foregroundColor: colors.textMuted,
            backgroundColor: selected ? colors.primary.withValues(alpha: 0.16) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        selectedIcon: Icon(icon, size: 18, color: colors.primary),
        icon: Icon(icon, size: 18));
    final divider = SizedBox(height: 18, child: VerticalDivider(width: 10, color: colors.divider));
    final inspector = button(
        wide ? (_rightOpen ? 'Hide inspector' : 'Show inspector') : 'Inspector',
        Icons.view_sidebar_outlined,
        () => setState(() {
              if (wide) {
                _rightOpen = !_rightOpen;
              } else {
                _overlay = _overlay == _Overlay.inspector ? _Overlay.none : _Overlay.inspector;
              }
            }),
        selected: wide ? _rightOpen : _overlay == _Overlay.inspector,
        key: const ValueKey('toggle-inspector-panel'));
    return Material(
      color: colors.surface.withValues(alpha: 0.96),
      elevation: 2,
      // borderRadius: BorderRadius.circular(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: colors.divider)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
                wide ? (_leftOpen ? 'Hide tilesets' : 'Show tilesets') : 'Tilesets',
                Icons.view_sidebar_outlined,
                () => setState(() {
                      if (wide) {
                        _leftOpen = !_leftOpen;
                      } else {
                        _overlay = _overlay == _Overlay.sets ? _Overlay.none : _Overlay.sets;
                      }
                    }),
                selected: wide ? _leftOpen : _overlay == _Overlay.sets,
                key: const ValueKey('toggle-sets-panel')),
            if (!wide) inspector,
            divider,
            button('Select tool', Icons.near_me_outlined, () => setState(() => _handTool = false),
                selected: !_handTool, key: const ValueKey('tool-select')),
            button('Hand tool', Icons.pan_tool_outlined, () => setState(() => _handTool = true),
                selected: _handTool, key: const ValueKey('tool-hand')),
            divider,
            button('Undo', Icons.undo, _undo.isEmpty || !_enabled ? null : undo, key: const ValueKey('canvas-undo')),
            button('Redo', Icons.redo, _redo.isEmpty || !_enabled ? null : redo, key: const ValueKey('canvas-redo')),
            divider,
            button('Add note', Icons.sticky_note_2_outlined, _enabled ? _addNote : null,
                key: const ValueKey('canvas-add-note')),
            button('Toggle grid', Icons.grid_on, () => setState(() => _grid = !_grid), selected: _grid),
            button('Fit all', Icons.fit_screen_outlined, fit, key: const ValueKey('canvas-fit')),
            divider,
            button('Zoom out', Icons.remove, () => _zoomAround(_viewport.center(Offset.zero), _zoom / 1.25)),
            SizedBox(
                width: 44,
                child: Text('${(_zoom * 100).round()}%',
                    key: const ValueKey('canvas-zoom'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.text))),
            button('Zoom in', Icons.add, () => _zoomAround(_viewport.center(Offset.zero), _zoom * 1.25)),
            if (wide) ...[divider, inspector],
          ],
        ),
      ),
    );
  }

  Widget _canvasArea(TilesetWorkspaceColors colors, bool wide) => LayoutBuilder(builder: (context, constraints) {
        _viewport = constraints.biggest;
        if (!_fitted && !_viewport.isEmpty) {
          _fitted = true;
          if (_collection.canvas.items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) fit();
            });
          }
        }
        final empty = _collection.entries.isEmpty && _canvas.items.isEmpty;
        return ClipRect(
            child: Stack(children: [
          Positioned.fill(
              child: Listener(
                  onPointerDown: (e) => _down = e.localPosition,
                  onPointerSignal: _onSignal,
                  child: MouseRegion(
                      cursor: _handTool ? SystemMouseCursors.grab : MouseCursor.defer,
                      child: GestureDetector(
                          key: const ValueKey('tileset-canvas'),
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _scaleStart,
                          onScaleUpdate: _scaleUpdate,
                          onScaleEnd: _scaleEnd,
                          onTapUp: _tapUp,
                          child: CustomPaint(
                              painter: TilesetCanvasPainter(
                                  canvas: _canvas,
                                  entries: _entries,
                                  tileSize: _tileSize,
                                  offset: _offset,
                                  zoom: _zoom,
                                  selection: Set.of(_selection),
                                  marquee: _marquee,
                                  showGrid: _grid,
                                  colors: colors,
                                  atlas: _atlas)))))),
          if (empty)
            Center(
                child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.divider)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.collections_outlined, size: 40, color: colors.primary),
                      const SizedBox(height: 10),
                      Text('Build your tileset board',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.text)),
                      const SizedBox(height: 6),
                      Text('Create ground, walls, floors and paths, then arrange them here.',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textMuted)),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                          key: const ValueKey('canvas-empty-create'),
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 34), visualDensity: VisualDensity.compact),
                          onPressed: _enabled ? widget.onCreate : null,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create your first tileset')),
                    ])))
          else if (_canvas.items.isEmpty)
            Center(
                child: IgnorePointer(
                    child: Text('Add tilesets or tiles from the Tilesets panel.',
                        style: TextStyle(color: colors.textMuted)))),
          Positioned(
              top: 8, left: 8, right: 8, child: Align(alignment: Alignment.topLeft, child: _toolbar(colors, wide))),
        ]));
      });

  TilesetSetsPanel _setsPanel(TilesetWorkspaceColors colors, {VoidCallback? onClose}) => TilesetSetsPanel(
      collection: _collection,
      atlas: _atlas,
      colors: colors,
      enabled: _enabled,
      onCreate: widget.onCreate,
      onAddSet: _addSet,
      onAddTile: _addTile,
      onEdit: widget.onEdit,
      onRename: widget.onRename,
      onDuplicate: widget.onDuplicate,
      onDelete: widget.onDelete,
      onClose: onClose);

  TilesetInspectorPanel _inspector(TilesetWorkspaceColors colors, {VoidCallback? onClose}) => TilesetInspectorPanel(
      collection: _collection,
      atlas: _atlas,
      colors: colors,
      selection: _selected,
      enabled: _enabled,
      zoom: _zoom,
      onEdit: widget.onEdit,
      onRename: widget.onRename,
      onDuplicate: widget.onDuplicate,
      onDelete: widget.onDelete,
      onRemoveFromCanvas: _removeSelected,
      onNoteText: _noteText,
      onNoteSize: _noteSize,
      onAlign: _align,
      onSelectEntry: _selectEntry,
      onClose: onClose);

  @override
  Widget build(BuildContext context) {
    final colors = TilesetWorkspaceColors.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 960;
      final canvas =
          CallbackShortcuts(bindings: _shortcuts, child: Focus(focusNode: _focus, child: _canvasArea(colors, wide)));
      if (wide) {
        return Row(children: [
          if (_leftOpen) SizedBox(width: 264, child: _setsPanel(colors)),
          if (_leftOpen) VerticalDivider(width: 1, color: colors.divider),
          Expanded(child: canvas),
          if (_rightOpen) VerticalDivider(width: 1, color: colors.divider),
          if (_rightOpen) SizedBox(width: 280, child: _inspector(colors)),
        ]);
      }
      final panelWidth = math.min(constraints.maxWidth * 0.88, 340.0);
      return Stack(children: [
        Positioned.fill(child: canvas),
        if (_overlay != _Overlay.none)
          Positioned.fill(
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _overlay = _Overlay.none),
                  child: const ColoredBox(color: Color(0x66000000)))),
        if (_overlay == _Overlay.sets)
          Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: panelWidth,
              child: _setsPanel(colors, onClose: () => setState(() => _overlay = _Overlay.none))),
        if (_overlay == _Overlay.inspector)
          Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: panelWidth,
              child: _inspector(colors, onClose: () => setState(() => _overlay = _Overlay.none))),
      ]);
    });
  }
}
