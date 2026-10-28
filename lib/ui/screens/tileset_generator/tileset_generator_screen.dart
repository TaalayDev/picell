import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/file_utils.dart';
import '../../../pixel/tileset/tileset_generator.dart';
import '../../../pixel/tileset/tileset_configuration.dart';
import '../../../app/theme/pv_tokens.dart';
import '../../../pixel/tileset/tileset_export.dart';
import '../../../pixel/tileset/tileset_geometry.dart';

part 'tileset_generator_widgets.dart';
part 'tileset_recipe_controls.dart';
part 'tileset_surface_editor.dart';

List<GeneratedTile> _generate(TilesetSettings settings) => generateTileset(settings);

/// Generator session, either standalone or backed by a library project.
class TilesetGeneratorScreen extends StatefulWidget {
  const TilesetGeneratorScreen(
      {super.key,
      this.projectName,
      this.initialDocument,
      this.onSaveProject,
      this.onDirtyChanged,
      this.embedded = false,
      this.recipeMode = false,
      this.configuration});
  final String? projectName;
  final String? initialDocument;
  final Future<void> Function(TilesetDocument document)? onSaveProject;
  final ValueChanged<bool>? onDirtyChanged;
  final bool embedded;
  final bool recipeMode;
  final TilesetConfiguration? configuration;
  @override
  State<TilesetGeneratorScreen> createState() => TilesetGeneratorScreenState();
}

class TilesetGeneratorScreenState extends State<TilesetGeneratorScreen> {
  _Tg get _tg => _Tg.of(context);
  void _updateDraft(VoidCallback update) => setState(update);
  final _name = TextEditingController(text: 'Meadow Platforms');
  final _seed = TextEditingController(text: '48213');
  var _perspective = TilesetPerspective.side;
  var _type = TilesetType.platforms;
  var _recipe = const TilesetRecipe();
  final _specName = TextEditingController();
  final List<TilesetSurfaceSpec> _specUndo = [], _specRedo = [];
  var _layer = 0, _layerTab = 0;
  String? _editKey;
  DateTime? _editAt;
  int? _liveKey;
  Uint32List? _liveTile;
  var _liveSeamless = true;
  Set<int> _parts = platformMasks.toSet();
  var _size = 16, _variations = 4;
  var _density = 45.0;
  var _material = 'Grass & Dirt';
  var _palette = List<int>.of(materialPalettes.values.first);
  TilesetSettings? _generatedSettings;
  List<GeneratedTile> _tiles = [];
  Map<String, ui.Image> _images = {};
  String? _selected;
  var _cells = _sample();
  var _columns = 24, _rows = 14;
  final List<List<int>> _undo = [], _redo = [];
  bool _busy = false, _hasChanges = false, _atlas = false, _grid = true, _erase = false;
  String? _loadError;
  int _swatch = 0;
  String _activity = 'Preparing tileset';
  bool get _dirty => _hasChanges;
  set _dirty(bool value) {
    if (_hasChanges == value) return;
    _hasChanges = value;
    widget.onDirtyChanged?.call(value);
  }

  @override
  void initState() {
    super.initState();
    if (widget.recipeMode) {
      if (widget.initialDocument == null) {
        final start = TilesetSurfacePresets.grass;
        _recipe = _recipe.copyWith(surface: TilesetMaterial.custom(start.spec));
        _palette = List.of(start.palette);
      }
      _type = _recipe.rendererFor(_perspective);
      _specName.text = _customSpec?.name ?? '';
      if (widget.initialDocument == null && widget.projectName == null) _name.text = 'Ground tileset';
    }
    if (widget.configuration != null) _applyConfiguration(widget.configuration!);
    if (widget.projectName != null) _name.text = widget.projectName!;
    if (widget.initialDocument != null) {
      _busy = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final doc = TilesetDocument.fromJson(jsonDecode(widget.initialDocument!) as Map<String, dynamic>);
          await _restore(doc);
          if (mounted && widget.configuration != null) setState(() => _applyConfiguration(widget.configuration!));
          if (mounted && widget.projectName != null) _name.text = widget.projectName!;
        } catch (error) {
          if (mounted) setState(() => _loadError = 'Could not load this tileset: $error');
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      });
    }
  }

  /// Workspace eviction and navigation must await this before disposing a tab.
  Future<bool> flushPendingSave({bool force = false}) async {
    if (_busy) return false;
    if (!_dirty && !force) return true;
    if (_loadError != null) return false;
    if (widget.onSaveProject == null) return false;
    if (_tiles.isEmpty) {
      await _generateTiles();
      if (!mounted || _tiles.isEmpty) return false;
    }
    setState(() {
      _busy = true;
      _activity = 'Saving tileset';
    });
    try {
      if (_name.text.trim().isEmpty || _name.text.trim().length > 100) {
        _message('Use a tileset name between 1 and 100 characters.');
        return false;
      }
      await widget.onSaveProject!(_document);
      if (mounted) setState(() => _dirty = false);
      return true;
    } catch (error) {
      _message('Could not save project: $error');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(TilesetDocument doc) async {
    await _replace(doc.tiles, doc.settings);
    if (!mounted) return;
    setState(() {
      _name.text = doc.name;
      _seed.text = '${doc.settings.seed}';
      _perspective = doc.settings.perspective;
      _type = doc.settings.type;
      _recipe = TilesetRecipe.fromSettings(doc.settings);
      _parts = doc.settings.parts.toSet();
      _size = doc.settings.size;
      _background = _defaultBackground(_perspective, _type);
      _density = doc.settings.density.toDouble();
      _variations = doc.settings.variations;
      _material =
          materialPalettes.containsKey(doc.settings.material) ? doc.settings.material : materialPalettes.keys.first;
      _palette = List.of(doc.settings.palette);
      _cells = doc.cells;
      _columns = doc.columns;
      _rows = doc.rows;
      _undo.clear();
      _redo.clear();
      _loadError = null;
    });
  }

  void _applyConfiguration(TilesetConfiguration config) {
    _name.text = config.name;
    _perspective = config.perspective;
    _size = config.size;
    _seed.text = '${config.seed}';
    _material = config.material;
    _palette = List.of(config.palette);
    if (!TilesetRecipe.basesFor(_perspective).contains(_recipe.base)) _recipe = const TilesetRecipe();
    if (!_recipe.canPlatform(_perspective)) _recipe = _recipe.copyWith(platform: false);
    _type = _recipe.rendererFor(_perspective);
  }

  String _background = 'Sky';
  double _zoom = 2;
  Offset? _lastCell;
  bool _stroke = false;

  static List<int> _sample() => List.generate(24 * 14, (i) {
        final x = i % 24, y = i ~/ 24;
        return y >= 11 && !(x >= 7 && x <= 9 && y < 13) ||
                y >= 3 && y <= 4 && x >= 4 && x <= 8 ||
                y == 7 && x >= 12 && x <= 17 ||
                x == 20 && y >= 6
            ? 1
            : 0;
      });

  static List<int> _terrainSample() => List.generate(24 * 14, (i) {
        final x = i % 24, y = i ~/ 24;
        final island = x >= 2 && x <= 12 && y >= 2 && y <= 11;
        final pond = x >= 5 && x <= 8 && y >= 5 && y <= 7;
        final peninsula = x >= 13 && x <= 17 && y >= 7 && y <= 9;
        final smallIsland = x >= 18 && x <= 21 && y >= 2 && y <= 4;
        return island && !pond || peninsula || smallIsland ? 1 : 0;
      });

  TilesetPerspective get _renderPerspective => _generatedSettings?.perspective ?? _perspective;
  TilesetType get _renderType => _generatedSettings?.type ?? _type;
  String _tileName(GeneratedTile tile) {
    final name = tile.nameFor(_renderPerspective, type: _renderType);
    return name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _tileGroup(GeneratedTile tile) => tile.groupFor(_renderPerspective, type: _renderType);
  void _selectPerspective(TilesetPerspective perspective) {
    if (perspective == _perspective) return;
    setState(() {
      _perspective = perspective;
      if (widget.recipeMode) {
        if (!TilesetRecipe.basesFor(perspective).contains(_recipe.base)) _recipe = const TilesetRecipe();
        if (!_recipe.canPlatform(perspective)) _recipe = _recipe.copyWith(platform: false);
        _type = _recipe.rendererFor(perspective);
      } else {
        _type = defaultTilesetType(perspective);
      }
      if (_tiles.isEmpty) {
        _cells = _sampleFor(perspective, _type);
        _background = _defaultBackground(perspective, _type);
      }
    });
  }

  static String _defaultBackground(TilesetPerspective perspective, TilesetType type) =>
      perspective == TilesetPerspective.side && type != TilesetType.walls ? 'Sky' : 'Flat';

  void _selectType(TilesetType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      if (_tiles.isEmpty) {
        _cells = _sampleFor(_perspective, type);
        _background = _defaultBackground(_perspective, type);
      }
    });
  }

  static List<int> _sampleFor(TilesetPerspective perspective, TilesetType type) {
    if (perspective == TilesetPerspective.isometric) {
      return type == TilesetType.walls ? _sampleFor(TilesetPerspective.topDown, TilesetType.walls) : _terrainSample();
    }
    if (type == TilesetType.platforms) return _sample();
    if (type == TilesetType.terrain) return _terrainSample();
    return List.generate(24 * 14, (i) {
      final x = i % 24, y = i ~/ 24;
      final occupied = switch (type) {
        TilesetType.ground => y >= 10 || (x <= 6 && y >= 7) || (x >= 17 && y >= 5),
        TilesetType.paths => (y == 7 && x >= 2 && x <= 21) ||
            (x == 7 && y >= 2 && y <= 10) ||
            (x == 17 && y >= 4 && y <= 11) ||
            (y == 2 && x >= 7 && x <= 12),
        TilesetType.floors => (x >= 2 && x <= 9 && y >= 2 && y <= 11) ||
            (x >= 14 && x <= 21 && y >= 4 && y <= 10) ||
            (y >= 6 && y <= 7 && x >= 10 && x <= 13),
        TilesetType.walls => perspective == TilesetPerspective.side
            ? (x >= 3 && x <= 20 && y >= 3 && y <= 11 && !(x >= 10 && x <= 13 && y >= 7))
            : ((x == 3 || x == 20) && y >= 2 && y <= 11) ||
                ((y == 2 || y == 11) && x >= 3 && x <= 20 && x != 11 && x != 12) ||
                (x == 12 && y >= 2 && y <= 7),
        _ => false,
      };
      return occupied ? 1 : 0;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _specName.dispose();
    _seed.dispose();
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<Map<String, ui.Image>> _decode(List<GeneratedTile> tiles, TilesetSettings settings) async {
    final width = settings.spriteWidth, height = settings.spriteHeight;
    final images = <String, ui.Image>{};
    try {
      for (final tile in tiles) {
        final rgba = Uint8List(width * height * 4);
        for (var i = 0; i < tile.pixels.length; i++) {
          final c = tile.pixels[i];
          rgba[i * 4] = (c >> 16) & 255;
          rgba[i * 4 + 1] = (c >> 8) & 255;
          rgba[i * 4 + 2] = c & 255;
          rgba[i * 4 + 3] = c >> 24;
        }
        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, completer.complete);
        images[tile.id] = await completer.future;
      }
      return images;
    } catch (_) {
      for (final image in images.values) {
        image.dispose();
      }
      rethrow;
    }
  }

  Future<void> _replace(List<GeneratedTile> tiles, TilesetSettings settings) async {
    final images = await _decode(tiles, settings);
    if (!mounted) {
      for (final image in images.values) {
        image.dispose();
      }
      return;
    }
    final old = _images;
    setState(() {
      _tiles = tiles;
      _images = images;
      _generatedSettings = settings;
      if (!tiles.any((t) => t.id == _selected)) {
        _selected = tiles.firstWhere((t) => t.mask == 110 && t.variation == 0, orElse: () => tiles.first).id;
      }
    });
    for (final image in old.values) {
      image.dispose();
    }
  }

  Future<void> _generateTiles() async {
    if (_loadError != null) {
      _message('Open a replacement document before changing this project.');
      return;
    }
    final seed = int.tryParse(_seed.text);
    if (seed == null || seed < 0 || seed > 0x7fffffff) {
      _message('Enter a seed between 0 and 2147483647.');
      return;
    }
    if (_parts.isEmpty) {
      _message('Select at least one connection part.');
      return;
    }
    final protected = _tiles.where((t) => t.protected).toList();
    if (protected.isNotEmpty && _generatedSettings!.perspective != _perspective) {
      _message('Save your tileset, then unlock protected tiles before changing perspective.');
      return;
    }
    if (protected.isNotEmpty && _generatedSettings!.type != _type) {
      _message('Save your tileset, then unlock protected tiles before changing tileset type.');
      return;
    }
    if (protected
        .any((t) => _generatedSettings!.size != _size || t.variation >= _variations || !_parts.contains(t.mask))) {
      _message(
          'Save your tileset, then unlock protected tiles before changing their size or removing protected parts/variations.');
      return;
    }
    setState(() {
      _busy = true;
      _activity = 'Generating tileset';
    });
    try {
      final settings = TilesetSettings(
          perspective: _perspective,
          type: _type,
          size: _size,
          seed: seed,
          density: _density.round(),
          variations: _variations,
          material: _material,
          palette: _palette,
          parts: _parts.toList(),
          recipe: widget.recipeMode ? _recipe : _generatedSettings?.recipe);
      final generated = await compute(_generate, settings);
      final kept = {for (final t in protected) t.id: t};
      final changedPerspective = _generatedSettings != null &&
          (_generatedSettings!.perspective != _perspective || _generatedSettings!.type != _type);
      await _replace(generated.map((t) => kept[t.id] ?? t).toList(), settings);
      if (changedPerspective && mounted) {
        setState(() => _background = _defaultBackground(_perspective, _type));
      }
      if (mounted) setState(() => _dirty = true);
    } catch (e) {
      _message('Generation failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  TilesetDocument get _document => TilesetDocument(
      name: _name.text.trim(),
      settings: _generatedSettings!,
      tiles: _tiles,
      cells: _cells,
      columns: _columns,
      rows: _rows);
  String get _fileName {
    final safe = _name.text.trim().replaceAll(RegExp(r'[^\w\- ]'), '_');
    return safe.isEmpty ? 'tileset' : safe;
  }

  Future<void> _save(String kind) async {
    setState(() {
      _busy = true;
      _activity = 'Exporting tileset';
    });
    try {
      final files = FileUtils(context);
      if (kind == 'png') {
        final bytes = await compute(encodeTilesetAtlas, (tiles: _tiles, settings: _generatedSettings!));
        if (mounted) await files.saveBinaryFile(bytes, '$_fileName.png');
      } else {
        final Map<String, dynamic> json;
        if (kind == 'document') {
          json = _document.toJson();
        } else {
          json = tilesetManifest(_document, '$_fileName.png');
        }
        final saved = await files.saveBinaryFile(
            Uint8List.fromList(utf8.encode(jsonEncode(json))), '$_fileName.${kind == 'document' ? 'pvtiles' : 'json'}');
        if (saved && kind == 'document' && widget.onSaveProject == null && mounted) setState(() => _dirty = false);
      }
    } catch (e) {
      _message('Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    if (_dirty && !await _confirmDiscard()) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _activity = 'Opening tileset';
    });
    try {
      final picked = await FilePicker.platform.pickFiles(withData: true, type: FileType.any);
      if (picked == null) return;
      final bytes = picked.files.single.bytes;
      if (bytes == null || bytes.length > 30 * 1024 * 1024) throw const FormatException('File missing or too large');
      final doc = TilesetDocument.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      await _restore(doc);
      if (mounted && widget.configuration != null) setState(() => _applyConfiguration(widget.configuration!));
      if (mounted) setState(() => _dirty = widget.onSaveProject != null);
    } catch (e) {
      _message('Could not open tileset: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> confirmLeave() async => !_busy && (!_dirty || await _confirmDiscard());

  Future<bool> _confirmDiscard() async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Leave this tileset?'),
                  content: Text(widget.recipeMode
                      ? 'Add this result to the collection before leaving to keep your changes.'
                      : 'Save a .pvtiles document first to keep this session.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard session')),
                  ])) ??
      false;

  void _history(bool redo) {
    final from = redo ? _redo : _undo, to = redo ? _undo : _redo;
    if (from.isEmpty) return;
    setState(() {
      to.add(List.of(_cells));
      _cells = from.removeLast();
      _dirty = true;
    });
  }

  void _paint(Offset position, {bool start = false}) {
    if (_busy || _tiles.isEmpty) return;
    final picked = pickTilesetCell(_document, position.dx / _zoom, position.dy / _zoom);
    if (picked == null) {
      _lastCell = null;
      return;
    }
    final cell = Offset(picked.column.toDouble(), picked.row.toDouble());
    if (start) {
      _stroke = true;
      _lastCell = null;
      _undo.add(List.of(_cells));
      _redo.clear();
      if (_undo.length > 100) _undo.removeAt(0);
    }
    if (!_stroke) return;
    final last = _lastCell ?? cell;
    final steps = math.max((cell.dx - last.dx).abs(), (cell.dy - last.dy).abs()).toInt();
    setState(() {
      for (var i = 0; i <= steps; i++) {
        final point = Offset.lerp(last, cell, steps == 0 ? 1 : i / steps)!;
        final x = point.dx.round(), y = point.dy.round();
        if (x >= 0 && y >= 0 && x < _columns && y < _rows) _cells[y * _columns + x] = _erase ? 0 : 1;
      }
      _lastCell = cell;
      _dirty = true;
    });
  }

  Future<void> _regenerate(GeneratedTile tile) async {
    setState(() {
      _busy = true;
      _activity = 'Regenerating tile';
    });
    try {
      final next = generateTilesetTile(_generatedSettings!, tile.mask, tile.variation, revision: tile.revision + 1);
      await _replace(_tiles.map((t) => t.id == tile.id ? next : t).toList(), _generatedSettings!);
      if (mounted) setState(() => _dirty = true);
    } catch (e) {
      _message('Could not regenerate tile: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(GeneratedTile tile) async {
    final pixels = await showDialog<Uint32List>(
        context: context,
        builder: (_) => Theme(
            data: Theme.of(context),
            child: _PixelDialog(
                tile: tile,
                width: _generatedSettings!.spriteWidth,
                height: _generatedSettings!.spriteHeight,
                palette: _generatedSettings!.palette)));
    if (pixels == null || !mounted) return;
    setState(() {
      _busy = true;
      _activity = 'Applying tile edit';
    });
    try {
      await _replace(_tiles.map((t) => t.id == tile.id ? t.copyWith(pixels: pixels, protected: true) : t).toList(),
          _generatedSettings!);
      if (mounted) setState(() => _dirty = true);
    } catch (e) {
      _message('Could not apply tile edit: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: Theme.of(context),
      child: Builder(
          builder: (context) => PopScope(
                canPop: widget.embedded || (!_dirty && !_busy),
                onPopInvokedWithResult: (didPop, result) async {
                  if (didPop || _busy || widget.embedded) return;
                  if (await _confirmDiscard() && mounted) {
                    setState(() => _dirty = false);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) Navigator.pop(context);
                    });
                  }
                },
                child: Scaffold(
                    backgroundColor: _tg.background,
                    body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1100;
                      return Column(children: [
                        _header(constraints.maxWidth),
                        if (_generatedSettings != null &&
                            (_generatedSettings!.perspective != _perspective || _generatedSettings!.type != _type))
                          Container(
                              width: double.infinity,
                              color: _tg.tint,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              child: Text(
                                  'Showing ${_generatedSettings!.perspective.label} · ${_generatedSettings!.type.label}. Generate to apply ${_perspective.label} · ${_type.label}.',
                                  style: TextStyle(fontSize: 12, color: _tg.amber))),
                        if (_loadError != null)
                          MaterialBanner(content: Text(_loadError!), actions: [
                            TextButton(onPressed: _busy ? null : _open, child: const Text('Open replacement document'))
                          ]),
                        Expanded(
                            child: wide
                                ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    SizedBox(width: widget.recipeMode ? 420 : 296, child: _settings()),
                                    const VerticalDivider(width: 1),
                                    Expanded(child: _preview()),
                                    const VerticalDivider(width: 1),
                                    SizedBox(width: 316, child: _browser()),
                                  ])
                                : DefaultTabController(
                                    length: 3,
                                    child: Column(children: [
                                      TabBar(labelColor: _tg.highlight, indicatorColor: _tg.accent, tabs: const [
                                        Tab(text: 'Settings'),
                                        Tab(text: 'Preview'),
                                        Tab(text: 'Tiles')
                                      ]),
                                      Expanded(child: TabBarView(children: [_settings(), _preview(), _browser()])),
                                    ]))),
                        _footer(constraints.maxWidth),
                      ]);
                    }))),
              )));

  Widget _nameField() => SizedBox(
      height: 32,
      child: TextField(
          controller: _name,
          enabled: !_busy,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
              labelText: 'Tileset name',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: Icon(Icons.edit_outlined, size: 15),
              prefixIconConstraints: BoxConstraints(minWidth: 30),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          onChanged: (_) => setState(() => _dirty = true)));

  Widget _statusBadge({bool compact = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: _tg.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _busy
                  ? _tg.accent
                  : _tiles.isEmpty
                      ? _tg.border
                      : _tg.green.withValues(alpha: 0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_busy)
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(_tiles.isEmpty ? Icons.circle_outlined : Icons.check_circle,
              size: 14, color: _tiles.isEmpty ? _tg.muted : _tg.green),
        const SizedBox(width: 6),
        Flexible(
            child: Text(
                _busy
                    ? 'Working…'
                    : _tiles.isEmpty
                        ? 'Not generated yet'
                        : compact
                            ? 'Ready'
                            : 'Ready · ${_tiles.length} tiles · seed ${_generatedSettings!.seed}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
      ]));

  Widget _header(double width) {
    final small = width < 900;
    final logo = Row(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(_tg.buttonRadius),
          child: CustomPaint(size: const Size.square(24), painter: _TgLogo(_tg.accent, _tg.highlight))),
      if (width >= 500) const SizedBox(width: 10),
      if (width >= 500)
        Text(small ? 'TILESET' : 'TILESET GENERATOR',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
    ]);
    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
      _TgIconButton(label: 'Open .pvtiles document', icon: Icons.folder_open_outlined, onPressed: _busy ? null : _open),
      const SizedBox(width: 6),
      OutlinedButton.icon(
          onPressed: _busy || _loadError != null || _tiles.isEmpty
              ? null
              : () async {
                  if (widget.onSaveProject != null) {
                    await flushPendingSave(force: widget.recipeMode);
                  } else {
                    await _save('document');
                  }
                },
          icon: Icon(_dirty ? Icons.save_outlined : Icons.save, size: 16),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          label: width < 360
              ? const SizedBox.shrink()
              : Text(widget.recipeMode
                  ? (widget.initialDocument == null ? 'Add to collection' : 'Save to collection')
                  : 'Save')),
      const SizedBox(width: 8),
      PopupMenuButton<String>(
          enabled: !_busy && _tiles.isNotEmpty,
          onSelected: _save,
          tooltip: 'Export tileset',
          offset: const Offset(0, 38),
          itemBuilder: (_) => [
                _exportItem(
                    'png',
                    Icons.grid_view,
                    'PNG atlas',
                    _generatedSettings == null
                        ? 'Pixel-perfect sprites'
                        : '${8 * _generatedSettings!.spriteWidth} × ${((_tiles.length + 7) ~/ 8) * _generatedSettings!.spriteHeight} px · all variations'),
                _exportItem('json', Icons.data_object, 'JSON connection data', 'Roles, sockets and variations'),
                _exportItem('document', Icons.description_outlined, 'Editable .pvtiles document',
                    'Pixels, settings and protected edits'),
              ],
          child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: _tiles.isEmpty || _busy ? _tg.accent.withValues(alpha: 0.35) : _tg.accent,
                  borderRadius: BorderRadius.circular(_tg.buttonRadius)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tg.ink)),
                const SizedBox(width: 5),
                Icon(Icons.expand_more, size: 16, color: _tg.ink)
              ]))),
    ]);
    return Container(
        decoration: BoxDecoration(color: _tg.panel, border: Border(bottom: BorderSide(color: _tg.border))),
        padding: EdgeInsets.symmetric(horizontal: small ? 10 : 16),
        child: Column(children: [
          SizedBox(
              height: 52,
              child: Row(children: [
                if (!widget.embedded) ...[
                  _TgIconButton(
                      label: 'Back', icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 6)
                ],
                logo,
                if (!small) ...[
                  const SizedBox(width: 16),
                  const SizedBox(height: 24, child: VerticalDivider(width: 1)),
                  const SizedBox(width: 16),
                  SizedBox(width: 190, child: _nameField())
                ],
                if (!small) const Spacer(),
                if (width >= 1200) ...[
                  ConstrainedBox(constraints: const BoxConstraints(maxWidth: 252), child: _statusBadge()),
                  const SizedBox(width: 12)
                ],
                if (small)
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerRight, child: FittedBox(fit: BoxFit.scaleDown, child: actions)))
                else
                  actions,
              ])),
          if (small)
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                    children: [Expanded(child: _nameField()), const SizedBox(width: 8), _statusBadge(compact: true)])),
        ]));
  }

  PopupMenuEntry<String> _exportItem(String value, IconData icon, String title, String subtitle) => PopupMenuItem(
      value: value,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Icon(icon, color: _tg.highlight, size: 21),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 11, color: _tg.muted))
            ])
          ])));

  Widget _footer(double width) {
    final status = _tiles.isEmpty
        ? 'Choose perspective and type, then generate.'
        : '${_tiles.length} tiles · ${_generatedSettings!.parts.length} connection shapes · ${_tiles.where((t) => t.protected).length} protected · ${_dirty ? 'Unsaved changes' : 'All changes saved'}';
    final layout = _generatedSettings == null ? null : TilesetLayout(_generatedSettings!, _columns, _rows);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(color: _tg.panel, border: Border(top: BorderSide(color: _tg.border))),
        child: Row(children: [
          Expanded(
              child: Text(status,
                  key: const ValueKey('tileset-session-status'),
                  maxLines: width < 700 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: _tg.muted))),
          if (width >= 900 && layout != null) ...[
            const SizedBox(width: 16),
            Text('$_columns×$_rows tiles · ${layout.width}×${layout.height} px', style: _tg.mono)
          ],
        ]));
  }

  Widget _settings() => ColoredBox(
      color: _tg.panel,
      child: Column(children: [
        Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), children: [
          if (widget.configuration == null) ...[
            const _TgLabel('1 · PERSPECTIVE'),
            const SizedBox(height: 9),
            LayoutBuilder(
                builder: (context, constraints) => Row(children: [
                      for (final perspective in TilesetPerspective.values) ...[
                        if (perspective != TilesetPerspective.values.first) const SizedBox(width: 8),
                        Expanded(
                            child: ChoiceChip(
                                selectedColor: _tg.tint,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.chipRadius)),
                                selected: _perspective == perspective,
                                showCheckmark: false,
                                side: BorderSide(
                                    color: _perspective == perspective ? _tg.accent : _tg.border,
                                    width: _perspective == perspective ? 2 : 1),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                labelPadding: EdgeInsets.zero,
                                onSelected: _busy ? null : (_) => _selectPerspective(perspective),
                                label: SizedBox(
                                    width: (constraints.maxWidth - 16) / 3 - 12,
                                    child: Stack(children: [
                                      Column(mainAxisSize: MainAxisSize.min, children: [
                                        ClipRRect(
                                            borderRadius: BorderRadius.circular(_tg.buttonRadius),
                                            child: CustomPaint(
                                                size: const Size(64, 43), painter: _TgPerspectiveArt(perspective))),
                                        const SizedBox(height: 7),
                                        Text(perspective.label,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                            maxLines: 1),
                                      ]),
                                      if (_perspective == perspective)
                                        Positioned(
                                            right: 0,
                                            top: 0,
                                            child: DecoratedBox(
                                                decoration: BoxDecoration(color: _tg.accent, shape: BoxShape.circle),
                                                child: const Icon(Icons.check, size: 13))),
                                    ])))),
                      ]
                    ])),
            const SizedBox(height: 18),
          ] else ...[
            const _TgLabel('PROJECT GEOMETRY'),
            const SizedBox(height: 8),
            ListTile(
                key: const ValueKey('set-geometry-summary'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline, size: 18),
                title: Text('${_perspective.label} · ${_size}px'),
                subtitle: const Text('Shared by every tileset in this project.', style: TextStyle(fontSize: 11))),
            if (_perspective == TilesetPerspective.isometric)
              Text('Size is the logical diamond height. Sprite width is twice this value.',
                  style: TextStyle(fontSize: 11, color: _tg.muted)),
            const SizedBox(height: 18),
          ],
          if (widget.recipeMode)
            ..._recipeControls()
          else ...[
            const _TgLabel('2 · TILESET TYPE'),
            const SizedBox(height: 5),
            Wrap(spacing: 6, runSpacing: 0, children: [
              for (final type in supportedTilesetTypes(_perspective))
                ChoiceChip(
                    selectedColor: _tg.tint,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.chipRadius)),
                    label: Text(type.label),
                    selected: _type == type,
                    side: BorderSide(color: _type == type ? _tg.accent : _tg.border),
                    onSelected: _busy ? null : (_) => _selectType(type))
            ]),
            const SizedBox(height: 4),
            Text(tilesetTypeDescription(_perspective, _type),
                style: TextStyle(fontSize: 11, height: 1.4, color: _tg.muted)),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          ...[
            const Text('Material preset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
                initialValue: _material,
                key: ValueKey(_material),
                isExpanded: true,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: _tg.text),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                items: materialPalettes.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: _busy
                    ? null
                    : (v) => setState(() {
                          _material = v!;
                          _palette = List.of(materialPalettes[v]!);
                        })),
            const SizedBox(height: 14),
            if (widget.configuration == null) ...[
              const Text('Tile size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          side: BorderSide(color: _tg.border),
                          selectedBackgroundColor: _tg.tint,
                          selectedForegroundColor: _tg.text,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.buttonRadius))),
                      segments: [
                        for (final size in [16, 32, 48]) ButtonSegment(value: size, label: Text('${size}px'))
                      ],
                      selected: {_size},
                      onSelectionChanged: _busy ? null : (v) => setState(() => _size = v.first))),
              if (_perspective == TilesetPerspective.isometric)
                Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                        '2:1 grid · ${_size * 2}×${_size + (_type == TilesetType.walls ? _size : _type == TilesetType.raisedBlocks ? _size ~/ 2 : 0)}px sprites',
                        style: _tg.mono)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              const Text('Palette', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('#${(_palette[_swatch] & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                  style: _tg.mono)
            ]),
            const SizedBox(height: 7),
            Row(children: [
              for (var i = 0; i < (_type == TilesetType.terrain ? 4 : 8); i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                    child: Tooltip(
                        message: 'Edit palette color ${i + 1}',
                        child: InkWell(
                            onTap: _busy ? null : () => _choosePalette(i),
                            borderRadius: BorderRadius.circular(_tg.buttonRadius),
                            child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                    color: Color(_palette[i]),
                                    borderRadius: BorderRadius.circular(_tg.buttonRadius),
                                    border: Border.all(color: _swatch == i ? _tg.text : _tg.background, width: 2))))))
              ]
            ]),
            const SizedBox(height: 14),
            const Text('Seed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 34,
                      child: TextField(
                          controller: _seed,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                              labelText: 'Seed', floatingLabelBehavior: FloatingLabelBehavior.never)))),
              const SizedBox(width: 6),
              DecoratedBox(
                  decoration: BoxDecoration(
                      border: Border.all(color: _tg.strongBorder),
                      borderRadius: BorderRadius.circular(_tg.buttonRadius)),
                  child: _TgIconButton(
                      label: 'Shuffle seed',
                      icon: Icons.shuffle,
                      onPressed:
                          _busy ? null : () => setState(() => _seed.text = '${math.Random().nextInt(0x7fffffff)}')))
            ]),
          ],
          const SizedBox(height: 15),
          Row(children: [
            const Text('Texture density', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_density.round()}%', style: _tg.mono)
          ]),
          SizedBox(
              height: 28,
              child: Slider(
                  value: _density,
                  min: 0,
                  max: 100,
                  padding: EdgeInsets.zero,
                  onChanged: _busy ? null : (v) => setState(() => _density = v))),
          const SizedBox(height: 10),
          Row(children: [
            const Expanded(child: Text('Variation count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DecoratedBox(
                decoration: BoxDecoration(
                    color: _tg.background,
                    border: Border.all(color: _tg.border),
                    borderRadius: BorderRadius.circular(_tg.buttonRadius)),
                child: Row(children: [
                  _TgIconButton(
                      label: 'Fewer variations',
                      icon: Icons.remove,
                      onPressed: _busy || _variations == 1 ? null : () => setState(() => _variations--)),
                  SizedBox(
                      width: 24,
                      child: Text('$_variations',
                          textAlign: TextAlign.center,
                          style: _tg.mono.copyWith(color: _tg.text, fontWeight: FontWeight.w600))),
                  _TgIconButton(
                      label: 'More variations',
                      icon: Icons.add,
                      onPressed: _busy || _variations == 6 ? null : () => setState(() => _variations++))
                ]))
          ]),
        ])),
        Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: _tg.border))),
            child: Column(children: [
              SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: DecoratedBox(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(_tg.cardRadius), boxShadow: [
                        BoxShadow(color: _tg.shadowColor, blurRadius: _tg.shadowBlur, offset: const Offset(0, 2))
                      ]),
                      child: FilledButton.icon(
                          onPressed: _busy ? null : _generateTiles,
                          icon: const Icon(Icons.auto_awesome, size: 19),
                          label: Text(
                              widget.recipeMode
                                  ? 'Generate selected parts'
                                  : _tiles.isEmpty
                                      ? 'Generate Tileset'
                                      : 'Regenerate Tileset',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))))),
              const SizedBox(height: 8),
              Text(
                  _tiles.any((t) => t.protected)
                      ? 'Protected tiles are kept on regenerate'
                      : 'Same seed always gives the same tileset',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, height: 1.4, color: _tg.muted)),
            ])),
      ]));

  Future<void> _choosePalette(int index) async {
    setState(() => _swatch = index);
    var color = Color(_palette[index]);
    final picked = await showDialog<Color>(
        context: context,
        builder: (context) => Theme(
            data: Theme.of(context),
            child: AlertDialog(
                title: const Text('Palette color'),
                content: SingleChildScrollView(
                    child: ColorPicker(pickerColor: color, enableAlpha: false, onColorChanged: (v) => color = v)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, color), child: const Text('Apply'))
                ])));
    if (picked != null && mounted) setState(() => _palette[index] = picked.toARGB32());
  }

  Future<void> _generateMissingParts() async {
    final current = _generatedSettings;
    final missing = _missingParts;
    if (_busy || current == null || missing.isEmpty) return;
    TilesetSettings withParts(List<int> parts) => TilesetSettings(
        perspective: current.perspective,
        type: current.type,
        size: current.size,
        seed: current.seed,
        density: current.density,
        variations: current.variations,
        material: current.material,
        palette: current.palette,
        recipe: current.recipe,
        parts: parts);
    setState(() {
      _busy = true;
      _activity = 'Generating missing parts';
    });
    try {
      final added = await compute(_generate, withParts(missing.toList()));
      final all = [..._tiles, ...added]
        ..sort((a, b) => a.mask == b.mask ? a.variation.compareTo(b.variation) : a.mask.compareTo(b.mask));
      final next = withParts({...current.parts, ...missing}.toList());
      await _replace(all, next);
      if (mounted) {
        setState(() {
          _parts = next.parts.toSet();
          _dirty = true;
        });
      }
    } catch (e) {
      _message('Could not generate missing parts: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Set<int> get _missingParts => _generatedSettings == null ? {} : missingTilesetParts(_document);

  Widget _preview() => Column(children: [
        _previewToolbar(),
        if (_missingParts.isNotEmpty && !_atlas)
          Container(
              color: _tg.tint,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(children: [
                Expanded(
                    child: Text('${_missingParts.length} connection shapes missing from this sample',
                        style: TextStyle(fontSize: 11, color: _tg.text))),
                TextButton(onPressed: _busy ? null : _generateMissingParts, child: const Text('Generate missing parts'))
              ])),
        Expanded(
            child: ColoredBox(
                color: _tg.canvas,
                child: Stack(children: [
                  Positioned.fill(
                      child: _tiles.isEmpty
                          ? _emptyPreview()
                          : _atlas
                              ? _atlasPreview()
                              : _mapPreview()),
                  if (_tiles.isNotEmpty && !_atlas) ...[
                    Positioned(left: 12, top: 12, child: _canvasTools()),
                    Positioned(
                        left: 12,
                        bottom: 12,
                        child: IgnorePointer(
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                    color: _tg.panel.withValues(alpha: 0.95),
                                    border: Border.all(color: _tg.strongBorder),
                                    borderRadius: BorderRadius.circular(_tg.buttonRadius)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.auto_fix_high, size: 15, color: _tg.highlight),
                                  const SizedBox(width: 6),
                                  Text(
                                      _erase
                                          ? 'Drag to erase. Neighbours reconnect.'
                                          : 'Draw shapes. Edges and corners connect.',
                                      style: TextStyle(fontSize: 10, color: _tg.muted))
                                ])))),
                  ],
                  if (_busy)
                    Positioned.fill(
                        child: ColoredBox(
                            color: _tg.canvas.withValues(alpha: 0.8),
                            child: Center(
                                child: Container(
                                    width: 320,
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        color: _tg.panel,
                                        borderRadius: BorderRadius.circular(_tg.cardRadius),
                                        border: Border.all(color: _tg.strongBorder),
                                        boxShadow: [BoxShadow(color: _tg.shadowColor, blurRadius: _tg.shadowBlur)]),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Icon(Icons.auto_awesome, size: 18, color: _tg.highlight),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Text(_activity,
                                                    style: const TextStyle(fontWeight: FontWeight.w600)))
                                          ]),
                                          const SizedBox(height: 16),
                                          const LinearProgressIndicator(
                                              minHeight: 4, borderRadius: BorderRadius.all(Radius.circular(4))),
                                          const SizedBox(height: 12),
                                          Text('Preparing a complete, connected tileset.',
                                              style: TextStyle(fontSize: 11, color: _tg.muted)),
                                        ]))))),
                ]))),
      ]);

  Widget _previewToolbar() => Container(
      decoration: BoxDecoration(color: _tg.background, border: Border(bottom: BorderSide(color: _tg.border))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: LayoutBuilder(builder: (context, constraints) {
        final tabs = Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                color: _tg.panel,
                border: Border.all(color: _tg.border),
                borderRadius: BorderRadius.circular(_tg.buttonRadius)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _viewTab(_renderPerspective == TilesetPerspective.side ? 'Sample Level' : 'Sample Map',
                  Icons.landscape_outlined, !_atlas, () => setState(() => _atlas = false)),
              _viewTab('Tileset Atlas', Icons.grid_view, _atlas, () => setState(() => _atlas = true))
            ]));
        final controls = Row(mainAxisSize: MainAxisSize.min, children: [
          if (constraints.maxWidth > 680) ...[
            Text('Background', style: TextStyle(fontSize: 11, color: _tg.muted)),
            const SizedBox(width: 6)
          ],
          for (final background in ['Sky', 'Dusk', 'Checker', 'Flat'])
            Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                    message: '$background background',
                    child: InkWell(
                        onTap: () => setState(() => _background = background),
                        borderRadius: BorderRadius.circular(_tg.buttonRadius),
                        child: Container(
                            width: 22,
                            height: 24,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: _background == background ? _tg.accent : _tg.strongBorder, width: 2),
                                borderRadius: BorderRadius.circular(_tg.buttonRadius)),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: background == 'Checker'
                                    ? CustomPaint(painter: _TgChecker(_tg.checkerA, _tg.checkerB))
                                    : DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: background == 'Flat' ? _tg.elevated : null,
                                            gradient: background == 'Sky'
                                                ? const LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [Color(0xff5eb4ee), Color(0xffd4effc)])
                                                : background == 'Dusk'
                                                    ? const LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [Color(0xff2b2a63), Color(0xfff0966f)])
                                                    : null))))))),
          const SizedBox(width: 6),
          Tooltip(
              message: 'Grid',
              child: OutlinedButton.icon(
                  onPressed: () => setState(() => _grid = !_grid),
                  style: OutlinedButton.styleFrom(
                      backgroundColor: _grid ? _tg.tint : null,
                      foregroundColor: _grid ? _tg.highlight : _tg.muted,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  icon: Icon(_grid ? Icons.grid_on : Icons.grid_off, size: 15),
                  label: const Text('Grid', style: TextStyle(fontSize: 11)))),
          const SizedBox(width: 8),
          DecoratedBox(
              decoration: BoxDecoration(
                  border: Border.all(color: _tg.border), borderRadius: BorderRadius.circular(_tg.buttonRadius)),
              child: Row(children: [
                _TgIconButton(
                    size: 28,
                    label: 'Zoom out',
                    icon: Icons.zoom_out,
                    onPressed: () => setState(() => _zoom = math.max(1, _zoom - 1))),
                Text('${_zoom.toInt()}×', style: _tg.mono.copyWith(color: _tg.text)),
                _TgIconButton(
                    size: 28,
                    label: 'Zoom in',
                    icon: Icons.zoom_in,
                    onPressed: () => setState(() => _zoom = math.min(6, _zoom + 1)))
              ])),
        ]);
        if (constraints.maxWidth >= 760) {
          return Row(children: [
            Expanded(
                flex: 5,
                child: Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, child: tabs))),
            const SizedBox(width: 12),
            Expanded(
                flex: 7,
                child:
                    Align(alignment: Alignment.centerRight, child: FittedBox(fit: BoxFit.scaleDown, child: controls))),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: constraints.maxWidth,
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: tabs)),
          const SizedBox(height: 8),
          SizedBox(
              width: constraints.maxWidth,
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: controls))
        ]);
      }));

  Widget _viewTab(String title, IconData icon, bool selected, VoidCallback onPressed) => TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
          backgroundColor: selected ? _tg.tint : null,
          foregroundColor: selected ? _tg.text : _tg.muted,
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.buttonRadius))),
      icon: Icon(icon, size: 15),
      label: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)));

  Widget _emptyPreview() => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                  color: _tg.background,
                  border: Border.all(color: _tg.strongBorder),
                  borderRadius: BorderRadius.circular(_tg.cardRadius)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CustomPaint(size: const Size(240, 120), painter: _TgEmptyArt(_tg.border, _tg.elevated, _tg.background)),
                const SizedBox(height: 16),
                const Text('One click, one matching tileset',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(
                    'Pick a perspective and type, tune the look, then generate. Fill, edges, corners and caps share one palette, light direction and texture scale.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.6, color: _tg.muted)),
                const SizedBox(height: 20),
                for (final line in ['Perspective: ${_perspective.label}', 'Type: ${_type.label}'])
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle, size: 16, color: _tg.green),
                        const SizedBox(width: 8),
                        Flexible(child: Text(line, style: const TextStyle(fontSize: 12)))
                      ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.radio_button_unchecked, size: 16, color: _tg.highlight),
                  const SizedBox(width: 8),
                  Flexible(child: Text('Generate tileset', style: TextStyle(fontSize: 12, color: _tg.muted)))
                ]),
              ]))));

  Widget _mapPreview() => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: DecoratedBox(
                              decoration: BoxDecoration(border: Border.all(color: _tg.border), boxShadow: [
                                BoxShadow(
                                    color: _tg.shadowColor, blurRadius: _tg.shadowBlur, offset: const Offset(0, 4))
                              ]),
                              child: MouseRegion(
                                  cursor: SystemMouseCursors.precise,
                                  child: Listener(
                                    onPointerDown: (e) => _paint(e.localPosition, start: true),
                                    onPointerMove: (e) => _paint(e.localPosition),
                                    onPointerUp: (_) => _stroke = false,
                                    onPointerCancel: (_) => _stroke = false,
                                    child: CustomPaint(
                                        key: const ValueKey('tileset-map-canvas'),
                                        size: Size(TilesetLayout(_generatedSettings!, _columns, _rows).width * _zoom,
                                            TilesetLayout(_generatedSettings!, _columns, _rows).height * _zoom),
                                        painter: _LevelPainter(
                                            cells: List.of(_cells),
                                            columns: _columns,
                                            rows: _rows,
                                            settings: _generatedSettings!,
                                            images: _images,
                                            grid: _grid,
                                            background: _background,
                                            selected: _selected,
                                            colors: _tg)),
                                  )))))))));

  Widget _canvasTools() => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: _tg.panel.withValues(alpha: 0.96),
          border: Border.all(color: _tg.strongBorder),
          borderRadius: BorderRadius.circular(_tg.cardRadius),
          boxShadow: [BoxShadow(color: _tg.shadowColor, blurRadius: _tg.shadowBlur)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _TgIconButton(
            size: 36,
            label: 'Paint',
            icon: Icons.brush_outlined,
            selected: !_erase,
            onPressed: () => setState(() => _erase = false)),
        _TgIconButton(
            size: 36,
            label: 'Erase',
            icon: Icons.auto_fix_normal_outlined,
            selected: _erase,
            onPressed: () => setState(() => _erase = true)),
        _TgIconButton(
            size: 36,
            label: _renderPerspective == TilesetPerspective.side ? 'Reset level' : 'Reset map',
            icon: Icons.restart_alt,
            onPressed: _busy
                ? null
                : () => setState(() {
                      _undo.add(List.of(_cells));
                      _redo.clear();
                      _cells = _columns == 24 && _rows == 14
                          ? _sampleFor(_renderPerspective, _renderType)
                          : List.filled(_columns * _rows, 0);
                      _dirty = true;
                    })),
        const SizedBox(height: 4),
        const SizedBox(width: 24, child: Divider()),
        const SizedBox(height: 4),
        _TgIconButton(
            size: 36,
            label: 'Undo stroke',
            icon: Icons.undo,
            onPressed: _undo.isEmpty || _busy ? null : () => _history(false)),
        _TgIconButton(
            size: 36,
            label: 'Redo stroke',
            icon: Icons.redo,
            onPressed: _redo.isEmpty || _busy ? null : () => _history(true)),
      ]));

  List<GeneratedTile> get _representatives => _tiles.where((t) => t.variation == 0).toList();
  List<GeneratedTile> get _primaryRepresentatives =>
      [for (final mask in _Tg.primaryMasks) ..._representatives.where((t) => t.mask == mask)];
  String _shortLabel(GeneratedTile tile) {
    if (tile.mask == 255) return 'Center';
    if (tile.mask == 0) return 'Single';
    final name = _tileName(tile);
    return name
        .replaceAll(' corner', '')
        .replaceAll(' edge', '')
        .replaceAll(' end cap', '')
        .replaceAll('Horizontal strip', 'Thin H')
        .replaceAll('Vertical strip', 'Thin V');
  }

  Widget _thumbnail(GeneratedTile tile, {bool atlas = false}) {
    final selected = _tiles.where((t) => t.id == _selected).firstOrNull;
    final variants = _tiles.where((t) => t.mask == tile.mask).toList();
    final protected = variants.any((t) => t.protected), active = selected?.mask == tile.mask;
    return Tooltip(
        message: '${_tileName(tile)} · ${variants.length} variations',
        child: InkWell(
            onTap: () => setState(() => _selected = tile.id),
            borderRadius: BorderRadius.circular(_tg.buttonRadius),
            child: Column(children: [
              Expanded(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_tg.buttonRadius),
                          border: Border.all(color: active ? _tg.accent : _tg.border, width: active ? 2 : 1),
                          boxShadow: active
                              ? [BoxShadow(color: _tg.accent.withValues(alpha: 0.22), blurRadius: 0, spreadRadius: 2)]
                              : null),
                      child: Stack(fit: StackFit.expand, children: [
                        _TgPixelFrame(image: _images[tile.id], padding: atlas ? 8 : 6),
                        if (variants.length > 1)
                          Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: _tg.panel,
                                      borderRadius: BorderRadius.circular(_tg.buttonRadius),
                                      border: Border.all(color: _tg.strongBorder)),
                                  child: Text('×${variants.length}',
                                      style: _tg.mono.copyWith(fontSize: 9, color: _tg.text)))),
                        if (protected)
                          Positioned(
                              left: 2,
                              top: 2,
                              child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                      color: _tg.panel, borderRadius: BorderRadius.circular(_tg.buttonRadius)),
                                  child: Icon(Icons.lock, size: 12, color: _tg.amber))),
                        if (active)
                          Positioned(right: 2, top: 2, child: Icon(Icons.check_circle, size: 14, color: _tg.highlight)),
                      ]))),
              const SizedBox(height: 5),
              Text(_shortLabel(tile),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      color: active ? _tg.text : _tg.muted,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ])));
  }

  Widget _atlasPreview() => ListView(padding: const EdgeInsets.all(20), children: [
        Text(
            '${_generatedSettings?.parts.length ?? _parts.length} shapes · ${_tiles.length} tiles with variations · shared palette, light and texture scale',
            style: TextStyle(fontSize: 11, color: _tg.muted)),
        const SizedBox(height: 20),
        for (final group in tilesetGroups(_renderPerspective, type: _renderType)) ...[
          _TgLabel(group.toUpperCase()),
          const SizedBox(height: 10),
          LayoutBuilder(
              builder: (context, constraints) => Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final tile in _representatives.where((t) => _tileGroup(t) == group))
                      SizedBox(width: 80, height: 102, child: _thumbnail(tile, atlas: true))
                  ])),
          const SizedBox(height: 22),
        ]
      ]);

  Widget _browser() {
    final selected = _tiles.where((t) => t.id == _selected).firstOrNull;
    return ColoredBox(
        color: _tg.panel,
        child: Column(children: [
          Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tg.border))),
              child: Row(children: [
                const Expanded(child: _TgLabel('GENERATED TILES')),
                if (_tiles.any((t) => t.protected)) ...[
                  Icon(Icons.lock, size: 12, color: _tg.amber),
                  const SizedBox(width: 3),
                  Text('${_tiles.where((t) => t.protected).length}', style: _tg.mono),
                  const SizedBox(width: 10)
                ],
                Text(_tiles.isEmpty ? '—' : '${_generatedSettings!.parts.length} shapes', style: _tg.mono)
              ])),
          Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final group in tilesetGroups(_renderPerspective, type: _renderType)) ...[
              Row(children: [
                Expanded(
                    child: Text(group,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: _tg.muted))),
                Text('${_primaryRepresentatives.where((t) => _tileGroup(t) == group).length}',
                    style: _tg.mono.copyWith(fontSize: 10))
              ]),
              const SizedBox(height: 8),
              if (_tiles.isEmpty)
                SizedBox(
                    height: 58,
                    child: Row(
                        children: List.generate(
                            4,
                            (_) => Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: _tg.background,
                                            border: Border.all(color: _tg.border),
                                            borderRadius: BorderRadius.circular(_tg.buttonRadius))))))))
              else
                GridView.count(
                    crossAxisCount: 4,
                    childAspectRatio: 0.78,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 9,
                    children: _primaryRepresentatives
                        .where((t) => _tileGroup(t) == group)
                        .map((t) => _thumbnail(t))
                        .toList()),
              const SizedBox(height: 16),
            ],
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text('Additional connections', style: TextStyle(fontSize: 11, color: _tg.muted)),
                subtitle: Text(
                    '${_representatives.where((t) => !_Tg.primaryMasks.contains(t.mask)).length} combined corner shapes',
                    style: TextStyle(fontSize: 10, color: _tg.muted)),
                children: [
                  GridView.count(
                      crossAxisCount: 4,
                      childAspectRatio: 0.78,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 9,
                      children: _representatives
                          .where((t) => !_Tg.primaryMasks.contains(t.mask))
                          .map((t) => _thumbnail(t))
                          .toList())
                ])
          ])),
          if (selected != null)
            _inspector(selected)
          else
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                decoration: BoxDecoration(color: _tg.elevated, border: Border(top: BorderSide(color: _tg.border))),
                child: Text('Select a generated tile to inspect, edit or regenerate it.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.5, color: _tg.muted))),
        ]));
  }

  Widget _inspector(GeneratedTile selected) {
    final variants = _tiles.where((t) => t.mask == selected.mask).toList();
    final used = tilesetPlacements(_document).where((p) => p.tile.id == selected.id).length;
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(color: _tg.elevated, border: Border(top: BorderSide(color: _tg.border))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 108,
                height: 108,
                child: Stack(fit: StackFit.expand, children: [
                  DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border.all(color: _tg.strongBorder),
                          borderRadius: BorderRadius.circular(_tg.cardRadius)),
                      child: _TgPixelFrame(image: _images[selected.id], padding: 8)),
                  if (selected.protected)
                    Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                            decoration: BoxDecoration(
                                color: _tg.panel,
                                borderRadius: BorderRadius.circular(_tg.buttonRadius),
                                border: Border.all(color: _tg.amber)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.lock, size: 11, color: _tg.amber),
                              const SizedBox(width: 3),
                              Text('Edited', style: TextStyle(fontSize: 9, color: _tg.amber))
                            ]))),
                ])),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tileName(selected),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${_tileGroup(selected)} · ${variants.length} variations',
                  style: TextStyle(fontSize: 10, color: _tg.muted)),
              const SizedBox(height: 7),
              Row(children: [
                Text(_renderPerspective == TilesetPerspective.isometric ? 'Grid' : 'Sockets',
                    style: TextStyle(fontSize: 10, color: _tg.muted)),
                const SizedBox(width: 5),
                for (var i = 0; i < 4; i++)
                  Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Tooltip(
                          message: '${[
                            'North',
                            'East',
                            'South',
                            'West'
                          ][i]} ${selected.mask & (1 << i) != 0 ? 'connects' : 'open edge'}',
                          child: Container(
                              width: 18,
                              height: 19,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: selected.mask & (1 << i) != 0 ? _tg.tint : _tg.background,
                                  border:
                                      Border.all(color: selected.mask & (1 << i) != 0 ? _tg.accent : _tg.strongBorder),
                                  borderRadius: BorderRadius.circular(_tg.buttonRadius)),
                              child: Text(['N', 'E', 'S', 'W'][i], style: const TextStyle(fontSize: 9)))))
              ]),
              const SizedBox(height: 7),
              Text('Used $used in ${_renderPerspective == TilesetPerspective.side ? 'level' : 'map'}',
                  style: TextStyle(fontSize: 11, color: _tg.muted)),
            ]))
          ]),
          if (variants.length > 1)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 6, children: [
                  Text('Variations', style: TextStyle(fontSize: 10, color: _tg.muted)),
                  const SizedBox(width: 8),
                  for (final variant in variants)
                    Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                            message: 'Variation ${variant.variation + 1}',
                            child: InkWell(
                                key: ValueKey('tileset-variant-${variant.id}'),
                                onTap: () => setState(() => _selected = variant.id),
                                child: Container(
                                    width: 27,
                                    height: 27,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(_tg.buttonRadius),
                                        border: Border.all(
                                            color: _selected == variant.id ? _tg.accent : _tg.strongBorder, width: 2)),
                                    child: _TgPixelFrame(image: _images[variant.id], padding: 2)))))
                ])),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _edit(selected),
                    icon: const Icon(Icons.brush_outlined, size: 15),
                    label: const Text('Edit Pixels', style: TextStyle(fontSize: 11)))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _busy || selected.protected ? null : () => _regenerate(selected),
                    icon: const Icon(Icons.refresh, size: 15),
                    label: const Text('Regenerate Tile', style: TextStyle(fontSize: 10))))
          ]),
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                  color: _tg.background,
                  border: Border.all(color: selected.protected ? _tg.amber : _tg.border),
                  borderRadius: BorderRadius.circular(_tg.buttonRadius)),
              child: Row(children: [
                Icon(selected.protected ? Icons.lock : Icons.lock_open,
                    size: 16, color: selected.protected ? _tg.amber : _tg.muted),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        selected.protected ? 'Protected. Skipped on regenerate.' : 'Protect tile from regeneration',
                        style: const TextStyle(fontSize: 10, height: 1.4))),
                SizedBox(
                    width: 38,
                    height: 28,
                    child: Transform.scale(
                        scale: 0.72,
                        child: Switch(
                            value: selected.protected,
                            activeThumbColor: _tg.amber,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() {
                                      _tiles = _tiles
                                          .map((t) => t.id == selected.id ? t.copyWith(protected: v) : t)
                                          .toList();
                                      _dirty = true;
                                    })))),
              ])),
        ]));
  }
}

class _LevelPainter extends CustomPainter {
  _LevelPainter(
      {required this.cells,
      required this.columns,
      required this.rows,
      required this.settings,
      required this.images,
      required this.grid,
      required this.background,
      required this.selected,
      required this.colors});
  final List<int> cells;
  final int columns, rows;
  final TilesetSettings settings;
  final Map<String, ui.Image> images;
  final bool grid;
  final String background;
  final String? selected;
  final _Tg colors;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    if (background == 'Sky' || background == 'Dusk') {
      paint.shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          background == 'Sky'
              ? [const Color(0xff5eb4ee), const Color(0xffd4effc)]
              : [const Color(0xff2b2a63), const Color(0xfff0966f)]);
      canvas.drawRect(Offset.zero & size, paint);
      paint.shader = null;
    } else {
      // Custom painters share a canvas with the surrounding workspace.
      // drawColor fills the entire canvas clip, not this painter's bounds.
      canvas.drawRect(Offset.zero & size, Paint()..color = colors.elevated);
      if (background == 'Checker') {
        paint.color = colors.checkerB;
        for (var y = 0; y < size.height; y += 12) {
          for (var x = 0; x < size.width; x += 12) {
            if ((x ~/ 12 + y ~/ 12).isEven) canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 12, 12), paint);
          }
        }
      }
    }
    final layout = TilesetLayout(settings, columns, rows);
    final scale = size.width / layout.width;
    // Only images are needed here; use the same ordering and origins as export.
    for (final cell in layout.drawOrder) {
      final x = cell.column, y = cell.row;
      if (cells[y * columns + x] == 0) continue;
      final mask = tileMaskAt(cells, columns, rows, x, y);
      final variant = tileHash(x, y, settings.seed) % settings.variations;
      final id = '$mask:$variant', image = images[id];
      final origin = layout.origin(x, y);
      final rect = Rect.fromLTWH(
          origin.x * scale, origin.y * scale, settings.spriteWidth * scale, settings.spriteHeight * scale);
      if (image == null) {
        final missing = Paint()..color = colors.amber.withValues(alpha: 0.25);
        canvas.drawRect(rect, missing);
        missing
          ..color = colors.amber
          ..strokeWidth = 1;
        canvas.drawLine(rect.topLeft, rect.bottomRight, missing);
        canvas.drawLine(rect.topRight, rect.bottomLeft, missing);
        continue;
      }
      paint.color = Colors.white;
      canvas.drawImageRect(
          image, Rect.fromLTWH(0, 0, settings.spriteWidth.toDouble(), settings.spriteHeight.toDouble()), rect, paint);
      if (id == selected) {
        final outline = Paint()
          ..color = colors.highlight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        if (layout.isometric) {
          final path = Path();
          for (final corner in [
            (x.toDouble(), y.toDouble()),
            (x + 1.0, y.toDouble()),
            (x + 1.0, y + 1.0),
            (x.toDouble(), y + 1.0)
          ]) {
            final vertex = layout.vertex(corner.$1, corner.$2);
            if (corner == (x.toDouble(), y.toDouble())) {
              path.moveTo(vertex.x * scale, vertex.y * scale);
            } else {
              path.lineTo(vertex.x * scale, vertex.y * scale);
            }
          }
          path.close();
          canvas.drawPath(path, outline);
        } else {
          canvas.drawRect(rect.deflate(1), outline);
        }
      }
    }
    if (grid) {
      paint.color = colors.text.withValues(alpha: 0.2);
      paint.strokeWidth = 1;
      for (var x = 0; x <= columns; x++) {
        final a = layout.vertex(x.toDouble(), 0), b = layout.vertex(x.toDouble(), rows.toDouble());
        canvas.drawLine(Offset(a.x * scale, a.y * scale), Offset(b.x * scale, b.y * scale), paint);
      }
      for (var y = 0; y <= rows; y++) {
        final a = layout.vertex(0, y.toDouble()), b = layout.vertex(columns.toDouble(), y.toDouble());
        canvas.drawLine(Offset(a.x * scale, a.y * scale), Offset(b.x * scale, b.y * scale), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPainter oldDelegate) => true;
}

class _PixelDialog extends StatefulWidget {
  const _PixelDialog({required this.tile, required this.width, required this.height, required this.palette});
  final GeneratedTile tile;
  final int width, height;
  final List<int> palette;
  @override
  State<_PixelDialog> createState() => _PixelDialogState();
}

class _PixelDialogState extends State<_PixelDialog> {
  _Tg get _tg => _Tg.of(context);
  late final pixels = Uint32List.fromList(widget.tile.pixels);
  late int color = widget.palette[1];
  void _draw(Offset point, double extent) {
    final x = (point.dx / extent * widget.width).floor(), y = (point.dy / extent * widget.width).floor();
    if (x >= 0 && y >= 0 && x < widget.width && y < widget.height) setState(() => pixels[y * widget.width + x] = color);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Edit tile pixels'),
          content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Boundary edits may break tile connections. Applied edits are protected.'),
                const SizedBox(height: 12),
                Wrap(spacing: 4, children: [
                  for (final c in [...widget.palette, 0])
                    InkWell(
                        onTap: () => setState(() => color = c),
                        child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: Color(c),
                                border: Border.all(color: color == c ? _tg.accent : _tg.border, width: 2)),
                            child: c == 0 ? const Icon(Icons.close, size: 18) : null))
                ]),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (_, constraints) {
                  final extent = constraints.maxWidth;
                  return Listener(
                      onPointerDown: (e) => _draw(e.localPosition, extent),
                      onPointerMove: (e) => _draw(e.localPosition, extent),
                      child: CustomPaint(
                          key: const ValueKey('tileset-pixel-editor'),
                          size: Size(extent, extent * widget.height / widget.width),
                          painter: _PixelsPainter(pixels, widget.width, widget.height, _tg.checkerA, _tg.checkerB)));
                }),
              ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, pixels), child: const Text('Apply & Protect'))
          ]);
}

class _PixelsPainter extends CustomPainter {
  _PixelsPainter(this.pixels, this.width, this.height, this.checkerA, this.checkerB);
  final Color checkerA, checkerB;
  final Uint32List pixels;
  final int width, height;
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / width, paint = Paint();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        paint.color = Color(pixels[y * width + x]);
        if (paint.color.a == 0) paint.color = (x + y).isEven ? checkerA : checkerB;
        canvas.drawRect(Rect.fromLTWH(x * unit, y * unit, unit, unit), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelsPainter oldDelegate) => true;
}
