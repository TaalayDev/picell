import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../tilemap/generator/tile_base.dart';
import '../../tilemap/generator/tile_palette.dart';

class TileMapGeneratorScreen extends StatefulWidget {
  const TileMapGeneratorScreen({
    super.key,
    this.initialTileWidth = 16,
    this.initialTileHeight = 16,
    this.initialColumns = 8,
    this.initialRows = 8,
  });

  final int initialTileWidth;
  final int initialTileHeight;
  final int initialColumns;
  final int initialRows;

  @override
  State<TileMapGeneratorScreen> createState() => _TileMapGeneratorScreenState();
}

class _TileMapGeneratorScreenState extends State<TileMapGeneratorScreen> {
  late final Map<TileCategory, List<_TemplateOption>> _templatesByCategory;
  final Set<String> _selectedTemplateIds = <String>{};

  TileCategory? _selectedCategory;
  String _searchQuery = '';
  bool _dedupeOutputTiles = true;

  late int _tileWidth;
  late int _tileHeight;
  late int _columns;
  late int _rows;
  late int _seed;

  bool _isGenerating = false;
  Uint32List? _mapPixels;
  int _mapPixelWidth = 0;
  int _mapPixelHeight = 0;
  List<_GeneratedCellTile> _generatedCells = const [];
  List<_GeneratedOutputTile> _outputTiles = const [];

  @override
  void initState() {
    super.initState();
    _tileWidth = widget.initialTileWidth.clamp(8, 64);
    _tileHeight = widget.initialTileHeight.clamp(8, 64);
    _columns = widget.initialColumns.clamp(2, 32);
    _rows = widget.initialRows.clamp(2, 32);
    _seed = DateTime.now().millisecondsSinceEpoch;

    _templatesByCategory = _buildTemplateCatalog(
      TileRegistry.instance.tilesByCategory,
    );
    _selectedCategory = _templatesByCategory.keys.isNotEmpty
        ? _templatesByCategory.keys.first
        : null;

    for (final option in _allTemplates.take(6)) {
      _selectedTemplateIds.add(option.id);
    }

    if (_selectedTemplateIds.isNotEmpty) {
      _generateTilemap();
    }
  }

  List<_TemplateOption> get _allTemplates {
    return _templatesByCategory.values.expand((list) => list).toList();
  }

  List<_TemplateOption> get _filteredTemplates {
    final source = _selectedCategory == null
        ? _allTemplates
        : (_templatesByCategory[_selectedCategory] ??
              const <_TemplateOption>[]);

    if (_searchQuery.trim().isEmpty) {
      return source;
    }
    final query = _searchQuery.trim().toLowerCase();
    return source.where((option) {
      return option.name.toLowerCase().contains(query) ||
          option.description.toLowerCase().contains(query) ||
          option.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tilemap Generator'),
        actions: [
          IconButton(
            tooltip: 'Random Seed',
            onPressed: _randomizeSeedAndGenerate,
            icon: const Icon(Icons.casino_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _outputTiles.isEmpty ? null : _returnGeneratedTiles,
              icon: const Icon(Icons.grid_view_outlined, size: 18),
              label: Text(
                'Add ${_outputTiles.length} Tile${_outputTiles.length == 1 ? '' : 's'}',
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 980;

          if (isNarrow) {
            return Column(
              children: [
                Expanded(
                  flex: 4,
                  child: _buildPreviewPanel(context, colorScheme),
                ),
                const Divider(height: 1),
                Expanded(
                  flex: 5,
                  child: _buildControlsPanel(context, colorScheme),
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 340,
                child: _buildControlsPanel(context, colorScheme),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _buildPreviewPanel(context, colorScheme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlsPanel(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionCard(
          context,
          title: 'Map Settings',
          icon: Icons.tune,
          child: Column(
            children: [
              _buildSliderField(
                context,
                label: 'Columns',
                value: _columns.toDouble(),
                min: 2,
                max: 32,
                divisions: 30,
                valueLabel: '$_columns',
                onChanged: (v) => setState(() => _columns = v.round()),
              ),
              const SizedBox(height: 8),
              _buildSliderField(
                context,
                label: 'Rows',
                value: _rows.toDouble(),
                min: 2,
                max: 32,
                divisions: 30,
                valueLabel: '$_rows',
                onChanged: (v) => setState(() => _rows = v.round()),
              ),
              const SizedBox(height: 8),
              _buildSliderField(
                context,
                label: 'Tile Width',
                value: _tileWidth.toDouble(),
                min: 8,
                max: 64,
                divisions: 14,
                valueLabel: '$_tileWidth px',
                onChanged: (v) => setState(() => _tileWidth = v.round()),
              ),
              const SizedBox(height: 8),
              _buildSliderField(
                context,
                label: 'Tile Height',
                value: _tileHeight.toDouble(),
                min: 8,
                max: 64,
                divisions: 14,
                valueLabel: '$_tileHeight px',
                onChanged: (v) => setState(() => _tileHeight = v.round()),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _dedupeOutputTiles,
                onChanged: (value) {
                  setState(() => _dedupeOutputTiles = value);
                  if (_generatedCells.isNotEmpty) {
                    setState(
                      () => _outputTiles = _sliceOutputTiles(_generatedCells),
                    );
                  }
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('Unique Tiles Only'),
                subtitle: const Text('Avoid duplicate tile outputs'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _randomizeSeedAndGenerate,
                      icon: const Icon(Icons.casino_outlined, size: 16),
                      label: const Text('Randomize Seed'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isGenerating || _selectedTemplateIds.isEmpty
                          ? null
                          : _generateTilemap,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Generate Tilemap'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          context,
          title: 'Templates',
          icon: Icons.apps_outlined,
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search templates...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      context,
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ..._templatesByCategory.keys.map((category) {
                      return _buildCategoryChip(
                        context,
                        label: category.name,
                        selected: _selectedCategory == category,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: _filteredTemplates.length,
                  itemBuilder: (context, index) {
                    final option = _filteredTemplates[index];
                    final isSelected = _selectedTemplateIds.contains(option.id);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            _selectedTemplateIds.add(option.id);
                          } else {
                            _selectedTemplateIds.remove(option.id);
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _PaletteStrip(palette: option.palette),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(BuildContext context, ColorScheme colorScheme) {
    final hasPreview =
        _mapPixels != null && _mapPixelWidth > 0 && _mapPixelHeight > 0;
    final aspect = hasPreview ? _mapPixelWidth / _mapPixelHeight : 1.0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text('Map: $_columns x $_rows'),
                  Text('Tile: ${_tileWidth}x$_tileHeight px'),
                  Text('Cells: ${_generatedCells.length}'),
                  Text('Output Tiles: ${_outputTiles.length}'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Center(
                child: hasPreview
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: CustomPaint(
                            painter: _TileMapPreviewPainter(
                              pixels: _mapPixels!,
                              width: _mapPixelWidth,
                              height: _mapPixelHeight,
                              tileWidth: _tileWidth,
                              tileHeight: _tileHeight,
                            ),
                          ),
                        ),
                      )
                    : const Text('Select templates and generate a tilemap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderField(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(valueLabel, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  void _randomizeSeedAndGenerate() {
    setState(() {
      _seed = DateTime.now().microsecondsSinceEpoch;
    });
    if (_selectedTemplateIds.isNotEmpty) {
      _generateTilemap();
    }
  }

  Future<void> _generateTilemap() async {
    if (_selectedTemplateIds.isEmpty || _isGenerating) return;

    setState(() => _isGenerating = true);
    await Future<void>.delayed(Duration.zero);

    final registry = TileRegistry.instance;
    final templates = _allTemplates
        .where((option) => _selectedTemplateIds.contains(option.id))
        .toList(growable: false);
    if (templates.isEmpty) {
      setState(() {
        _isGenerating = false;
        _mapPixels = null;
        _generatedCells = const [];
        _outputTiles = const [];
      });
      return;
    }

    final mapPixelWidth = _columns * _tileWidth;
    final mapPixelHeight = _rows * _tileHeight;
    final mapPixels = Uint32List(mapPixelWidth * mapPixelHeight);
    final random = Random(_seed);
    final cells = <_GeneratedCellTile>[];

    for (int row = 0; row < _rows; row++) {
      for (int col = 0; col < _columns; col++) {
        final template = templates[random.nextInt(templates.length)];
        final tile = registry.getTile(template.id) ?? template.prototype;
        final variation =
            TileVariation.values[random.nextInt(TileVariation.values.length)];
        final seed = random.nextInt(0x7FFFFFFF);
        final pixels = tile.generate(
          width: _tileWidth,
          height: _tileHeight,
          seed: seed,
          variation: variation,
        );

        cells.add(
          _GeneratedCellTile(
            templateId: template.id,
            templateName: template.name,
            tags: tile.tags,
            row: row,
            col: col,
            pixels: Uint32List.fromList(pixels),
          ),
        );

        _blitTilePixels(
          target: mapPixels,
          targetWidth: mapPixelWidth,
          targetHeight: mapPixelHeight,
          tilePixels: pixels,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
          tileColumn: col,
          tileRow: row,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _mapPixelWidth = mapPixelWidth;
      _mapPixelHeight = mapPixelHeight;
      _mapPixels = mapPixels;
      _generatedCells = cells;
      _outputTiles = _sliceOutputTiles(cells);
      _isGenerating = false;
    });
  }

  List<_GeneratedOutputTile> _sliceOutputTiles(List<_GeneratedCellTile> cells) {
    if (!_dedupeOutputTiles) {
      return List<_GeneratedOutputTile>.generate(cells.length, (index) {
        final cell = cells[index];
        return _GeneratedOutputTile(
          templateId: cell.templateId,
          name: '${cell.templateName} (${cell.row + 1}, ${cell.col + 1})',
          tags: cell.tags,
          width: _tileWidth,
          height: _tileHeight,
          pixels: Uint32List.fromList(cell.pixels),
        );
      });
    }

    final uniqueTiles = <_GeneratedOutputTile>[];
    final buckets = <int, List<_GeneratedOutputTile>>{};

    for (final cell in cells) {
      final hash = Object.hashAll(cell.pixels);
      final bucket = buckets.putIfAbsent(hash, () => <_GeneratedOutputTile>[]);

      bool exists = false;
      for (final existing in bucket) {
        if (_pixelsEqual(existing.pixels, cell.pixels)) {
          exists = true;
          break;
        }
      }
      if (exists) continue;

      final output = _GeneratedOutputTile(
        templateId: cell.templateId,
        name: '${cell.templateName} ${bucket.length + 1}',
        tags: cell.tags,
        width: _tileWidth,
        height: _tileHeight,
        pixels: Uint32List.fromList(cell.pixels),
      );
      bucket.add(output);
      uniqueTiles.add(output);
    }

    return uniqueTiles;
  }

  bool _pixelsEqual(Uint32List a, Uint32List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _blitTilePixels({
    required Uint32List target,
    required int targetWidth,
    required int targetHeight,
    required Uint32List tilePixels,
    required int tileWidth,
    required int tileHeight,
    required int tileColumn,
    required int tileRow,
  }) {
    final offsetX = tileColumn * tileWidth;
    final offsetY = tileRow * tileHeight;

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final sourceIndex = y * tileWidth + x;
        if (sourceIndex >= tilePixels.length) continue;

        final destX = offsetX + x;
        final destY = offsetY + y;
        if (destX < 0 ||
            destX >= targetWidth ||
            destY < 0 ||
            destY >= targetHeight) {
          continue;
        }

        final destIndex = destY * targetWidth + destX;
        final color = tilePixels[sourceIndex];
        final alpha = (color >> 24) & 0xFF;
        if (alpha == 0) continue;
        target[destIndex] = color;
      }
    }
  }

  void _returnGeneratedTiles() {
    if (_outputTiles.isEmpty) return;
    Navigator.of(context).pop<Map<String, dynamic>>({
      'tiles': _outputTiles
          .map(
            (tile) => <String, dynamic>{
              'name': tile.name,
              'pixels': Uint32List.fromList(tile.pixels),
              'width': tile.width,
              'height': tile.height,
              'templateId': tile.templateId,
              'tags': tile.tags,
            },
          )
          .toList(),
      'columns': _columns,
      'rows': _rows,
    });
  }

  Map<TileCategory, List<_TemplateOption>> _buildTemplateCatalog(
    Map<TileCategory, List<TileBase>> source,
  ) {
    final catalog = <TileCategory, List<_TemplateOption>>{};
    for (final entry in source.entries) {
      final seen = <String>{};
      final options = <_TemplateOption>[];
      for (final tile in entry.value) {
        final key = '${tile.runtimeType}:${tile.name}';
        if (!seen.add(key)) continue;
        options.add(
          _TemplateOption(
            id: tile.id,
            name: tile.name,
            description: tile.description,
            category: tile.category,
            palette: tile.palette,
            prototype: tile,
            tags: tile.tags,
          ),
        );
      }
      options.sort((a, b) => a.name.compareTo(b.name));
      if (options.isNotEmpty) {
        catalog[entry.key] = options;
      }
    }
    return catalog;
  }
}

class _TemplateOption {
  const _TemplateOption({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.palette,
    required this.prototype,
    required this.tags,
  });

  final String id;
  final String name;
  final String description;
  final TileCategory category;
  final TilePalette palette;
  final TileBase prototype;
  final List<String> tags;
}

class _GeneratedCellTile {
  const _GeneratedCellTile({
    required this.templateId,
    required this.templateName,
    required this.tags,
    required this.row,
    required this.col,
    required this.pixels,
  });

  final String templateId;
  final String templateName;
  final List<String> tags;
  final int row;
  final int col;
  final Uint32List pixels;
}

class _GeneratedOutputTile {
  const _GeneratedOutputTile({
    required this.templateId,
    required this.name,
    required this.tags,
    required this.width,
    required this.height,
    required this.pixels,
  });

  final String templateId;
  final String name;
  final List<String> tags;
  final int width;
  final int height;
  final Uint32List pixels;
}

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.palette});

  final TilePalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: palette.colors
              .take(4)
              .map((color) => Expanded(child: ColoredBox(color: color)))
              .toList(),
        ),
      ),
    );
  }
}

class _TileMapPreviewPainter extends CustomPainter {
  _TileMapPreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
  });

  final Uint32List pixels;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final pixelW = size.width / width;
    final pixelH = size.height / height;

    final checkerA = Paint()..color = const Color(0xFFE5E5E5);
    final checkerB = Paint()..color = const Color(0xFFCACACA);

    final checkerSize = max(2.0, min(pixelW, pixelH) * 2);
    final cols = (size.width / checkerSize).ceil();
    final rows = (size.height / checkerSize).ceil();
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            col * checkerSize,
            row * checkerSize,
            checkerSize,
            checkerSize,
          ),
          (row + col).isEven ? checkerA : checkerB,
        );
      }
    }

    final paint = Paint();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final color = pixels[y * width + x];
        final alpha = (color >> 24) & 0xFF;
        if (alpha == 0) continue;
        paint.color = Color(color);
        canvas.drawRect(
          Rect.fromLTWH(x * pixelW, y * pixelH, pixelW, pixelH),
          paint,
        );
      }
    }

    final gridPaint = Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1;
    if (tileWidth > 0 && tileHeight > 0) {
      final columns = width ~/ tileWidth;
      final rowsCount = height ~/ tileHeight;

      for (int col = 1; col < columns; col++) {
        final dx = col * tileWidth * pixelW;
        canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      }
      for (int row = 1; row < rowsCount; row++) {
        final dy = row * tileHeight * pixelH;
        canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TileMapPreviewPainter oldDelegate) {
    return oldDelegate.pixels != pixels ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight;
  }
}
