import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../core.dart';
import '../../../tilemap/tilemap_notifier.dart';

/// Export options for tilemap
enum TilemapExportFormat {
  /// Export full map as PNG
  fullMap,

  /// Export individual tiles as PNG sprite sheet
  tileset,

  /// Export map data as JSON
  json,
}

/// Dialog for exporting tilemap with various options
class TilemapExportDialog extends StatefulWidget {
  const TilemapExportDialog({
    super.key,
    required this.state,
    required this.notifier,
    required this.tileWidth,
    required this.tileHeight,
    required this.projectName,
  });

  final TileMapState state;
  final TileMapNotifier notifier;
  final int tileWidth;
  final int tileHeight;
  final String projectName;

  static Future<void> show({
    required BuildContext context,
    required TileMapState state,
    required TileMapNotifier notifier,
    required int tileWidth,
    required int tileHeight,
    required String projectName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TilemapExportDialog(
        state: state,
        notifier: notifier,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        projectName: projectName,
      ),
    );
  }

  @override
  State<TilemapExportDialog> createState() => _TilemapExportDialogState();
}

class _TilemapExportDialogState extends State<TilemapExportDialog> {
  TilemapExportFormat _selectedFormat = TilemapExportFormat.fullMap;
  double _scale = 1.0;
  bool _includeBackground = false;
  Color _backgroundColor = Colors.white;
  bool _isExporting = false;

  // Tileset export options
  int _tilesetColumns = 8;
  int _tilesetSpacing = 0;

  int get _mapPixelWidth => widget.state.gridWidth * widget.tileWidth;
  int get _mapPixelHeight => widget.state.gridHeight * widget.tileHeight;
  int get _exportWidth => (_mapPixelWidth * _scale).round();
  int get _exportHeight => (_mapPixelHeight * _scale).round();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Export Tilemap'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format Selection
              Text('Export Format', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildFormatOption(
                TilemapExportFormat.fullMap,
                'Full Map (PNG)',
                'Export the complete tilemap as a single image',
                Icons.image,
              ),
              _buildFormatOption(
                TilemapExportFormat.tileset,
                'Tileset (PNG)',
                'Export all tiles as a sprite sheet',
                Icons.grid_view,
              ),
              _buildFormatOption(
                TilemapExportFormat.json,
                'Map Data (JSON)',
                'Export tilemap data for use in game engines',
                Icons.data_object,
              ),

              const Divider(height: 32),

              // Format-specific options
              if (_selectedFormat == TilemapExportFormat.fullMap || _selectedFormat == TilemapExportFormat.tileset) ...[
                // Scale
                Text('Scale', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 1.0,
                        max: 8.0,
                        divisions: 7,
                        label: '${_scale.toStringAsFixed(0)}x',
                        onChanged: (value) => setState(() => _scale = value),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${_scale.toStringAsFixed(0)}x',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (_selectedFormat == TilemapExportFormat.fullMap)
                  Text(
                    'Output size: $_exportWidth x $_exportHeight px',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),

                const SizedBox(height: 16),

                // Background option
                CheckboxListTile(
                  value: _includeBackground,
                  onChanged: (value) => setState(() => _includeBackground = value ?? false),
                  title: const Text('Include Background'),
                  subtitle: const Text('Fill transparent areas with color'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),

                if (_includeBackground) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Background Color:', style: textTheme.bodyMedium),
                      const SizedBox(width: 12),
                      _buildColorOption(Colors.white, 'White'),
                      _buildColorOption(Colors.black, 'Black'),
                      _buildColorOption(const Color(0xFF282828), 'Dark Gray'),
                      _buildColorOption(const Color(0xFF1a1a2e), 'Navy'),
                    ],
                  ),
                ],
              ],

              // Tileset-specific options
              if (_selectedFormat == TilemapExportFormat.tileset) ...[
                const SizedBox(height: 16),
                Text('Tileset Layout', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Columns:'),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: DropdownButton<int>(
                        value: _tilesetColumns,
                        isExpanded: true,
                        items: [4, 8, 12, 16, 20].map((v) {
                          return DropdownMenuItem(value: v, child: Text('$v'));
                        }).toList(),
                        onChanged: (v) => setState(() => _tilesetColumns = v ?? 8),
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Text('Spacing:'),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: DropdownButton<int>(
                        value: _tilesetSpacing,
                        isExpanded: true,
                        items: [0, 1, 2, 4].map((v) {
                          return DropdownMenuItem(value: v, child: Text('${v}px'));
                        }).toList(),
                        onChanged: (v) => setState(() => _tilesetSpacing = v ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.state.tiles.length} tiles will be exported',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],

              // JSON info
              if (_selectedFormat == TilemapExportFormat.json) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Export includes:', style: textTheme.labelMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Grid dimensions (${widget.state.gridWidth}x${widget.state.gridHeight})\n'
                        '• Tile size (${widget.tileWidth}x${widget.tileHeight}px)\n'
                        '• ${widget.state.tiles.length} tiles with pixel data\n'
                        '• ${widget.state.layers.length} layer(s) with tile placements',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isExporting ? null : _export,
          icon: _isExporting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
    TilemapExportFormat format,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedFormat == format;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFormat = format),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Radio<TilemapExportFormat>(
                value: format,
                groupValue: _selectedFormat,
                onChanged: (value) => setState(() => _selectedFormat = value!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, String label) {
    final isSelected = _backgroundColor == color;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => setState(() => _backgroundColor = color),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      switch (_selectedFormat) {
        case TilemapExportFormat.fullMap:
          await _exportFullMap();
          break;
        case TilemapExportFormat.tileset:
          await _exportTileset();
          break;
        case TilemapExportFormat.json:
          await _exportJson();
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tilemap exported successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportFullMap() async {
    // Generate full map pixels
    final pixels = widget.notifier.generateThumbnailPixels();

    // Apply background if needed
    if (_includeBackground) {
      final bgColor = (_backgroundColor.alpha << 24) |
          (_backgroundColor.red << 16) |
          (_backgroundColor.green << 8) |
          _backgroundColor.blue;
      for (int i = 0; i < pixels.length; i++) {
        final alpha = (pixels[i] >> 24) & 0xFF;
        if (alpha == 0) {
          pixels[i] = bgColor;
        }
      }
    }

    // Create image
    var image = img.Image.fromBytes(
      width: _mapPixelWidth,
      height: _mapPixelHeight,
      bytes: ImageHelper.fixColorChannels(pixels).buffer,
      numChannels: 4,
    );

    // Scale if needed
    if (_scale > 1.0) {
      image = img.copyResize(
        image,
        width: _exportWidth,
        height: _exportHeight,
        interpolation: img.Interpolation.nearest,
      );
    }

    // Save
    final pngData = Uint8List.fromList(img.encodePng(image));
    await FileUtils(context).saveImage(pngData, '${widget.projectName}_tilemap.png');
  }

  Future<void> _exportTileset() async {
    final tiles = widget.state.tiles;
    if (tiles.isEmpty) {
      throw Exception('No tiles to export');
    }

    final rows = (tiles.length / _tilesetColumns).ceil();
    final scaledTileWidth = (widget.tileWidth * _scale).round();
    final scaledTileHeight = (widget.tileHeight * _scale).round();

    // Calculate total dimensions
    final totalWidth = (scaledTileWidth * _tilesetColumns) + (_tilesetSpacing * (_tilesetColumns - 1));
    final totalHeight = (scaledTileHeight * rows) + (_tilesetSpacing * (rows - 1));

    // Create tileset image
    final tileset = img.Image(
      width: totalWidth,
      height: totalHeight,
      numChannels: 4,
    );

    // Fill background if needed
    if (_includeBackground) {
      for (int y = 0; y < totalHeight; y++) {
        for (int x = 0; x < totalWidth; x++) {
          tileset.setPixelRgba(
            x,
            y,
            _backgroundColor.red,
            _backgroundColor.green,
            _backgroundColor.blue,
            _backgroundColor.alpha,
          );
        }
      }
    }

    // Draw each tile
    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final col = i % _tilesetColumns;
      final row = i ~/ _tilesetColumns;

      final xOffset = col * (scaledTileWidth + _tilesetSpacing);
      final yOffset = row * (scaledTileHeight + _tilesetSpacing);

      // Create tile image
      var tileImage = img.Image.fromBytes(
        width: tile.width,
        height: tile.height,
        bytes: ImageHelper.fixColorChannels(tile.pixels).buffer,
        numChannels: 4,
      );

      // Scale tile if needed
      if (_scale > 1.0) {
        tileImage = img.copyResize(
          tileImage,
          width: scaledTileWidth,
          height: scaledTileHeight,
          interpolation: img.Interpolation.nearest,
        );
      }

      // Copy tile to tileset
      for (int py = 0; py < tileImage.height && yOffset + py < totalHeight; py++) {
        for (int px = 0; px < tileImage.width && xOffset + px < totalWidth; px++) {
          final pixel = tileImage.getPixel(px, py);
          final a = pixel.a.toInt();
          if (a > 0 || !_includeBackground) {
            tileset.setPixelRgba(
              xOffset + px,
              yOffset + py,
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              a,
            );
          }
        }
      }
    }

    // Save
    final pngData = Uint8List.fromList(img.encodePng(tileset));
    await FileUtils(context).saveImage(pngData, '${widget.projectName}_tileset.png');
  }

  Future<void> _exportJson() async {
    final jsonData = _generateExportJson();
    await FileUtils(context).save('${widget.projectName}_tilemap.json', jsonData);
  }

  String _generateExportJson() {
    final Map<String, dynamic> exportData = {
      'version': '1.0',
      'name': widget.projectName,
      'grid': {
        'width': widget.state.gridWidth,
        'height': widget.state.gridHeight,
        'tileWidth': widget.tileWidth,
        'tileHeight': widget.tileHeight,
      },
      'tiles': widget.state.tiles
          .map((tile) => {
                'id': tile.id,
                'name': tile.name,
                'width': tile.width,
                'height': tile.height,
                'pixels': tile.pixels.toList(),
              })
          .toList(),
      'layers': widget.state.layers
          .map((layer) => {
                'id': layer.id,
                'name': layer.name,
                'visible': layer.visible,
                'opacity': layer.opacity,
                'tileIds': layer.tileIds,
              })
          .toList(),
    };

    // Pretty print JSON
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }
}

class JsonEncoder {
  final String? indent;

  const JsonEncoder.withIndent(this.indent);

  String convert(Object? object) {
    if (indent == null) {
      return _encode(object, 0);
    }
    return _encode(object, 0);
  }

  String _encode(Object? object, int depth) {
    if (object == null) return 'null';
    if (object is bool) return object.toString();
    if (object is num) return object.toString();
    if (object is String) return '"${_escapeString(object)}"';

    if (object is List) {
      if (object.isEmpty) return '[]';
      // Check if it's a simple list (numbers or nulls only)
      final isSimple = object.every((e) => e == null || e is num);
      if (isSimple && object.length <= 20) {
        return '[${object.map((e) => _encode(e, depth)).join(', ')}]';
      }
      final items = object.map((e) => '${_indent(depth + 1)}${_encode(e, depth + 1)}').join(',\n');
      return '[\n$items\n${_indent(depth)}]';
    }

    if (object is Map) {
      if (object.isEmpty) return '{}';
      final entries = object.entries.map((e) {
        return '${_indent(depth + 1)}"${e.key}": ${_encode(e.value, depth + 1)}';
      }).join(',\n');
      return '{\n$entries\n${_indent(depth)}}';
    }

    return object.toString();
  }

  String _indent(int depth) => indent! * depth;

  String _escapeString(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
