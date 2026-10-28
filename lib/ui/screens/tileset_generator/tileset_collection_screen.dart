import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/pv_tokens.dart';
import '../../../core/utils/file_utils.dart';
import '../../../pixel/tileset/tileset_collection.dart';
import '../../../pixel/tileset/tileset_generator.dart';
import 'tileset_generator_screen.dart';
import '../../../pixel/tileset/tileset_canvas.dart';
import 'tileset_geometry_picker.dart';
import 'tileset_workspace.dart';
import '../../../pixel/tileset/tileset_configuration.dart';

/// Project landing page. Generation is a separate screen with a draft session.
class TilesetCollectionScreen extends StatefulWidget {
  const TilesetCollectionScreen(
      {super.key,
      this.projectName,
      this.initialDocument,
      this.initialGeometry,
      this.onSaveCollection,
      this.onDirtyChanged,
      this.embedded = false});
  final String? projectName, initialDocument;

  /// Project geometry chosen before this screen opened. Without it (and without
  /// saved data) the screen asks for the geometry before anything else.
  final TilesetGeometry? initialGeometry;
  final Future<void> Function(TilesetCollection collection)? onSaveCollection;
  final ValueChanged<bool>? onDirtyChanged;
  final bool embedded;
  @override
  State<TilesetCollectionScreen> createState() => TilesetCollectionScreenState();
}

class TilesetCollectionScreenState extends State<TilesetCollectionScreen> {
  final _name = TextEditingController();
  final _editorKey = GlobalKey<TilesetGeneratorScreenState>();
  late TilesetCollection _collection;
  TilesetEntry? _editingEntry;
  TilesetConfiguration _configuration = TilesetConfiguration();
  bool _generating = false;
  bool _editing = false, _changed = false, _draftDirty = false, _busy = false;
  String? _loadError;
  bool _geometryPending = false;
  TilesetPerspective? _pendingPerspective;
  int? _pendingSize;
  bool get _dirty => _changed || _draftDirty;
  Color get _surface => Theme.of(context).extension<PvTokens>()?.surface ?? Theme.of(context).colorScheme.surface;
  @override
  void initState() {
    super.initState();
    _collection = TilesetCollection(
        name: widget.projectName ?? 'Tileset collection',
        perspective: widget.initialGeometry?.perspective ?? TilesetPerspective.side,
        tileSize: widget.initialGeometry?.size ?? 16);
    _geometryPending = widget.initialDocument == null && widget.initialGeometry == null;
    if (widget.initialDocument != null) {
      try {
        _collection = TilesetCollection.fromJson(jsonDecode(widget.initialDocument!) as Map<String, dynamic>);
      } catch (e) {
        _loadError = 'Could not load collection: $e';
      }
    }
    _name.text = widget.projectName ?? _collection.name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _notify() => widget.onDirtyChanged?.call(_dirty);
  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  TilesetCollection _candidate(List<TilesetEntry> entries) =>
      _collection.copyWith(name: _name.text.trim(), entries: entries);
  bool _validName() {
    if (_name.text.trim().isEmpty || _name.text.trim().length > 100) {
      _message('Use a collection name between 1 and 100 characters.');
      return false;
    }
    return true;
  }

  Future<bool> flushPendingSave() async {
    if (_busy || _loadError != null) return false;
    if (_editing && _generating && !await (_editorKey.currentState?.flushPendingSave() ?? Future.value(false))) {
      return false;
    }
    if (!_changed) return true;
    if (widget.onSaveCollection == null || !_validName()) return false;
    setState(() => _busy = true);
    try {
      final next = _candidate(_collection.entries);
      await widget.onSaveCollection!(next);
      if (mounted) {
        setState(() {
          _collection = next;
          _changed = false;
        });
        _notify();
      }
      return true;
    } catch (e) {
      _message('Could not save collection: $e');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (widget.onSaveCollection != null) {
      await flushPendingSave();
      return;
    }
    if (!_validName()) return;
    setState(() => _busy = true);
    try {
      final next = _candidate(_collection.entries);
      final saved = await FileUtils(context).saveBinaryFile(Uint8List.fromList(utf8.encode(jsonEncode(next.toJson()))),
          '${next.name.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}.pvtiles');
      if (saved && mounted) {
        setState(() {
          _collection = next;
          _changed = false;
        });
        _notify();
      }
    } catch (e) {
      _message('Could not save collection: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commit(TilesetDocument document) async {
    if (!_validName()) throw StateError('Invalid collection name');
    final id = _editingEntry?.id ?? _newId();
    final entry = TilesetEntry(id: id, document: document, configuration: TilesetConfiguration.fromDocument(document));
    final isNew = !_collection.entries.any((old) => old.id == id);
    var next = _candidate([
      for (final old in _collection.entries)
        if (old.id == id) entry else old,
      if (isNew) entry,
    ]);
    if (isNew) next = _withSetOnCanvas(next, id);
    // Persist first: a rejected write keeps the editor and its protected pixels alive.
    await widget.onSaveCollection?.call(next);
    if (!mounted) return;
    setState(() {
      _collection = next;
      _changed = widget.onSaveCollection == null;
      _draftDirty = false;
      _editing = false;
      _generating = false;
      _editingEntry = null;
    });
    _notify();
  }

  /// New sets land on a free spot of the canvas.
  TilesetCollection _withSetOnCanvas(TilesetCollection collection, String entryId) => collection.copyWith(
      canvas: placeOnTilesetCanvas(
          collection.canvas,
          TilesetCanvasItem(id: 'set-$entryId', kind: TilesetCanvasKind.set, entryId: entryId, x: 0, y: 0),
          collection.entriesById,
          collection.tileSize));

  void _setCanvas(TilesetCanvas canvas) {
    setState(() {
      _collection = _collection.copyWith(canvas: canvas);
      _changed = true;
    });
    _notify();
  }

  String _newId() {
    var id = DateTime.now().microsecondsSinceEpoch.toString();
    while (_collection.entries.any((entry) => entry.id == id)) {
      id = '${id}_copy';
    }
    return id;
  }

  void _edit([TilesetEntry? entry]) => setState(() {
        _editingEntry = entry;
        _editing = true;
        _generating = true;
        // Geometry belongs to the project; a set generated elsewhere adopts it on regeneration.
        _configuration = (entry?.resolvedConfiguration ?? TilesetConfiguration())
            .copyWith(perspective: _collection.perspective, size: _collection.tileSize);
        _draftDirty = false;
      });
  Future<void> _backToCollection() async {
    if (_busy) return;
    if (_generating && (!await (_editorKey.currentState?.confirmLeave() ?? Future.value(false)) || !mounted)) return;
    setState(() {
      _editing = false;
      _generating = false;
      _editingEntry = null;
      _draftDirty = false;
    });
    _notify();
  }

  Future<bool> _discardCollection() async =>
      !_dirty ||
      await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                      title: const Text('Leave collection?'),
                      content: const Text('Save the collection to keep your changes.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard changes')),
                      ])) ==
          true;
  Future<void> _open() async {
    if (!await _discardCollection() || !mounted) return;
    setState(() => _busy = true);
    try {
      final file = await FilePicker.platform.pickFiles(withData: true, type: FileType.any);
      if (file == null) return;
      final bytes = file.files.single.bytes;
      if (bytes == null || bytes.length > 30 * 1024 * 1024) throw const FormatException('File missing or too large');
      final next = TilesetCollection.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          _collection = next;
          _name.text = next.name;
          _geometryPending = false;
          _changed = widget.onSaveCollection != null;
          _loadError = null;
        });
        _notify();
      }
    } catch (e) {
      _message('Could not open collection: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setGeometry(TilesetGeometry geometry) {
    setState(() {
      _collection = _collection.copyWith(perspective: geometry.perspective, tileSize: geometry.size);
      _geometryPending = false;
      _changed = true;
    });
    _notify();
  }

  Future<void> _changeGeometry() async {
    final geometry = await showTilesetGeometryDialog(context,
        title: 'Project geometry', confirm: 'Apply', initial: _collection.geometry);
    if (geometry != null && mounted) _setGeometry(geometry);
  }

  Widget _pendingGeometry() => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Set up your tileset project', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Choose the perspective and tile size first. They apply to every tileset in this project.'),
                const SizedBox(height: 20),
                TilesetGeometryPicker(
                    perspective: _pendingPerspective,
                    size: _pendingSize,
                    onPerspective: (value) => setState(() => _pendingPerspective = value),
                    onSize: (value) => setState(() => _pendingSize = value)),
                const SizedBox(height: 20),
                FilledButton(
                    key: const ValueKey('tileset-geometry-continue'),
                    onPressed: _pendingPerspective == null || _pendingSize == null
                        ? null
                        : () => _setGeometry((perspective: _pendingPerspective!, size: _pendingSize!)),
                    child: const Text('Continue')),
              ]))));

  Future<void> _rename(TilesetEntry entry) async {
    final name = await showDialog<String>(
        context: context, builder: (_) => _RenameTilesetDialog(initialName: entry.document.name));
    if (name == null || !mounted) return;
    final d = entry.document;
    final renamed = TilesetDocument(
        name: name, settings: d.settings, tiles: d.tiles, cells: d.cells, columns: d.columns, rows: d.rows);
    setState(() {
      _collection = _candidate([
        for (final e in _collection.entries)
          e.id == entry.id
              ? TilesetEntry(id: e.id, document: renamed, configuration: e.configuration?.copyWith(name: name))
              : e
      ]);
      _changed = true;
    });
    _notify();
  }

  void _duplicate(TilesetEntry entry) {
    final copyName = '${entry.resolvedConfiguration.name} copy';
    final json = entry.document.toJson()..['name'] = copyName;
    final id = _newId();
    setState(() {
      _collection = _withSetOnCanvas(
          _candidate([
            ..._collection.entries,
            TilesetEntry(
                id: id,
                document: TilesetDocument.fromJson(json),
                configuration: entry.resolvedConfiguration.copyWith(name: copyName))
          ]),
          id);
      _changed = true;
    });
    _notify();
  }

  Future<void> _delete(TilesetEntry entry) async {
    final remove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Delete ${entry.document.name}?'),
                content: const Text('Remove this set from the collection?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))
                ]));
    if (remove != true || !mounted) return;
    setState(() {
      _collection = _candidate(_collection.entries.where((e) => e.id != entry.id).toList());
      _changed = true;
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return PopScope(
          canPop: widget.embedded,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !widget.embedded) _backToCollection();
          },
          child: Column(children: [
            Material(
                color: _surface,
                child: Row(children: [
                  TextButton.icon(
                      onPressed: _busy ? null : _backToCollection,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to collection')),
                  Expanded(
                      child: Text(_editingEntry == null ? 'New tileset' : 'Edit tileset',
                          overflow: TextOverflow.ellipsis)),
                ])),
            Expanded(
                child: TilesetGeneratorScreen(
                    configuration: _configuration,
                    key: _editorKey,
                    embedded: true,
                    recipeMode: true,
                    initialDocument: _editingEntry == null ? null : jsonEncode(_editingEntry!.document.toJson()),
                    onSaveProject: _commit,
                    onDirtyChanged: (dirty) {
                      _draftDirty = dirty;
                      _notify();
                    }))
          ]));
    }
    return PopScope(
        canPop: widget.embedded || !_dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop && await _discardCollection() && mounted) {
            setState(() {
              _changed = false;
              _draftDirty = false;
            });
            _notify();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).maybePop();
            });
          }
        },
        child: Scaffold(
            backgroundColor: Theme.of(context).extension<PvTokens>()?.background,
            appBar:
                AppBar(automaticallyImplyLeading: !widget.embedded, title: const Text('Tileset collection'), actions: [
              IconButton(
                  tooltip: 'Open collection or legacy tileset',
                  onPressed: _busy ? null : _open,
                  icon: const Icon(Icons.folder_open_outlined)),
              IconButton(
                  tooltip: 'Save collection',
                  onPressed: _busy || _loadError != null ? null : _save,
                  icon: const Icon(Icons.save_outlined)),
            ]),
            body: _geometryPending
                ? _pendingGeometry()
                : Column(children: [
                    if (_busy) const LinearProgressIndicator(),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                      width: 260,
                                      child: TextField(
                                          controller: _name,
                                          enabled: !_busy && _loadError == null,
                                          decoration: const InputDecoration(labelText: 'Collection name'),
                                          onChanged: (_) {
                                            setState(() => _changed = true);
                                            _notify();
                                          })),
                                  Chip(
                                      key: const ValueKey('tileset-geometry-chip'),
                                      avatar: const Icon(Icons.grid_view, size: 16),
                                      label: Text('${_collection.perspective.label} · ${_collection.tileSize}px')),
                                  IconButton(
                                      key: const ValueKey('tileset-geometry-change'),
                                      tooltip: _collection.entries.isEmpty
                                          ? 'Change perspective and tile size'
                                          : 'Geometry is locked once the project has tilesets',
                                      onPressed: _busy || _loadError != null || _collection.entries.isNotEmpty
                                          ? null
                                          : _changeGeometry,
                                      icon: const Icon(Icons.tune)),
                                  Text(
                                      '${_collection.entries.length} sets · ${_collection.entries.fold<int>(0, (n, e) => n + e.document.tiles.length)} tiles${_dirty ? ' · Unsaved changes' : ''}'),
                                ]))),
                    if (_loadError != null) Padding(padding: const EdgeInsets.all(24), child: Text(_loadError!)),
                    Expanded(
                        child: TilesetWorkspace(
                            collection: _collection,
                            enabled: !_busy && _loadError == null,
                            onCanvasChanged: _setCanvas,
                            onCreate: () => _edit(),
                            onEdit: _edit,
                            onRename: _rename,
                            onDuplicate: _duplicate,
                            onDelete: _delete)),
                  ])));
  }
}

class _RenameTilesetDialog extends StatefulWidget {
  const _RenameTilesetDialog({required this.initialName});
  final String initialName;
  @override
  State<_RenameTilesetDialog> createState() => _RenameTilesetDialogState();
}

class _RenameTilesetDialogState extends State<_RenameTilesetDialog> {
  late final _controller = TextEditingController(text: widget.initialName);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Rename tileset'),
          content:
              TextField(controller: _controller, autofocus: true, maxLength: 100, onChanged: (_) => setState(() {})),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
                onPressed:
                    _controller.text.trim().isEmpty ? null : () => Navigator.pop(context, _controller.text.trim()),
                child: const Text('Rename'))
          ]);
}
