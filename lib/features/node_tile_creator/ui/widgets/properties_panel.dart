import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelverse/features/node_tile_creator/logic/node_graph_controller.dart';
import 'package:pixelverse/features/node_tile_creator/models/node_graph_model.dart';
import 'package:pixelverse/features/node_tile_creator/models/nodes.dart';

class PropertiesPanel extends ConsumerStatefulWidget {
  final NodeData node;
  final VoidCallback onClose;

  const PropertiesPanel({
    super.key,
    required this.node,
    required this.onClose,
  });

  @override
  ConsumerState<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<PropertiesPanel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getNodeColor().withOpacity(0.2),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Icon(_getNodeIcon(), color: _getNodeColor(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.node.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.white54,
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.white10),

        // Properties content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildProperties(),
          ),
        ),
      ],
    );
  }

  Widget _buildProperties() {
    if (widget.node is ColorNode) {
      return _buildColorNodeProperties(widget.node as ColorNode);
    } else if (widget.node is NoiseNode) {
      return _buildNoiseNodeProperties(widget.node as NoiseNode);
    } else if (widget.node is ShapeNode) {
      return _buildShapeNodeProperties(widget.node as ShapeNode);
    } else if (widget.node is MixNode) {
      return _buildMixNodeProperties();
    } else if (widget.node is OutputNode) {
      return _buildOutputNodeProperties();
    }

    return const Center(
      child: Text(
        'No properties available',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildColorNodeProperties(ColorNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Color'),
        const SizedBox(height: 12),

        // Color preview
        GestureDetector(
          onTap: () => _showColorPicker(node),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: node.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: node.color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.colorize,
                color: node.color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Hex value
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Text('HEX:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 8),
              Text(
                '#${node.color.value.toRadixString(16).substring(2).toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: () => _showColorPicker(node),
          icon: const Icon(Icons.palette, size: 18),
          label: const Text('Pick Color'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showColorPicker(ColorNode node) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = node.color;
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text('Pick a Color', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: node.color,
              onColorChanged: (color) {
                tempColor = color;
              },
              enableAlpha: false,
              hexInputBar: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  node.color = tempColor;
                });
                // Trigger state update
                ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoiseNodeProperties(NoiseNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Noise Settings'),
        const SizedBox(height: 16),

        // Scale slider
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 0.01,
          max: 1.0,
          onChanged: (value) {
            setState(() {
              node.scale = value;
            });
            ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
          },
        ),

        const SizedBox(height: 16),

        // Seed slider
        _buildSlider(
          label: 'Seed',
          value: node.seed,
          min: 0,
          max: 100,
          onChanged: (value) {
            setState(() {
              node.seed = value;
            });
            ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
          },
        ),

        const SizedBox(height: 24),

        // Randomize button
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              node.seed = (DateTime.now().millisecondsSinceEpoch % 100).toDouble();
            });
            ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
          },
          icon: const Icon(Icons.shuffle, size: 18),
          label: const Text('Randomize'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purple[300],
            side: BorderSide(color: Colors.purple[300]!),
          ),
        ),
      ],
    );
  }

  Widget _buildShapeNodeProperties(ShapeNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Shape Type'),
        const SizedBox(height: 12),

        // Shape type selector
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ShapeType.values.map((type) {
            final isSelected = node.shapeType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  node.shapeType = type;
                });
                ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
              },
              child: Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getShapeIcon(type),
                      color: isSelected ? Colors.green : Colors.white54,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.name,
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMixNodeProperties() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Mix Settings'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Connect two inputs (A and B) and a factor to blend them together.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputNodeProperties() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Output'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.15),
                Colors.purple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.output, color: Colors.blue[300], size: 32),
              const SizedBox(height: 8),
              const Text(
                'Final Output',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect nodes here to generate the final tile',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.purple[400],
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: Colors.purple[300],
            overlayColor: Colors.purple.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  IconData _getShapeIcon(ShapeType type) {
    switch (type) {
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.square:
        return Icons.square_outlined;
      case ShapeType.diamond:
        return Icons.diamond_outlined;
    }
  }

  Color _getNodeColor() {
    if (widget.node is ColorNode) return Colors.amber;
    if (widget.node is NoiseNode) return Colors.purple;
    if (widget.node is ShapeNode) return Colors.green;
    if (widget.node is MixNode) return Colors.cyan;
    if (widget.node is OutputNode) return Colors.blue;
    return Colors.grey;
  }

  IconData _getNodeIcon() {
    if (widget.node is ColorNode) return Icons.palette;
    if (widget.node is NoiseNode) return Icons.grain;
    if (widget.node is ShapeNode) return Icons.crop_square;
    if (widget.node is MixNode) return Icons.merge_type;
    if (widget.node is OutputNode) return Icons.output;
    return Icons.widgets;
  }
}
