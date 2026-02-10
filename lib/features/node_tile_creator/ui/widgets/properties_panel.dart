import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picell/features/node_tile_creator/logic/node_graph_controller.dart';
import 'package:picell/features/node_tile_creator/models/node_graph_model.dart';
import 'package:picell/features/node_tile_creator/models/nodes.dart';

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
    } else if (widget.node is CheckerboardNode) {
      return _buildCheckerboardNodeProperties(widget.node as CheckerboardNode);
    } else if (widget.node is StripesNode) {
      return _buildStripesNodeProperties(widget.node as StripesNode);
    } else if (widget.node is BricksNode) {
      return _buildBricksNodeProperties(widget.node as BricksNode);
    } else if (widget.node is GridNode) {
      return _buildGridNodeProperties(widget.node as GridNode);
    } else if (widget.node is GradientNode) {
      return _buildGradientNodeProperties(widget.node as GradientNode);
    } else if (widget.node is VoronoiNode) {
      return _buildVoronoiNodeProperties(widget.node as VoronoiNode);
    } else if (widget.node is WaveNode) {
      return _buildWaveNodeProperties(widget.node as WaveNode);
    } else if (widget.node is GroundNode) {
      return _buildGroundNodeProperties(widget.node as GroundNode);
    } else if (widget.node is WallNode) {
      return _buildWallNodeProperties(widget.node as WallNode);
    } else if (widget.node is WaterNode) {
      return _buildWaterNodeProperties(widget.node as WaterNode);
    } else if (widget.node is WoodNode) {
      return _buildWoodNodeProperties(widget.node as WoodNode);
    } else if (widget.node is LavaNode) {
      return _buildLavaNodeProperties(widget.node as LavaNode);
    } else if (widget.node is SnowNode) {
      return _buildSnowNodeProperties(widget.node as SnowNode);
    } else if (widget.node is MetalFloorNode) {
      return _buildMetalFloorNodeProperties(widget.node as MetalFloorNode);
    } else if (widget.node is MossyStoneNode) {
      return _buildMossyStoneNodeProperties(widget.node as MossyStoneNode);
    } else if (widget.node is MudNode) {
      return _buildMudNodeProperties(widget.node as MudNode);
    } else if (widget.node is PlatformNode) {
      return _buildPlatformNodeProperties(widget.node as PlatformNode);
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

  Widget _buildCheckerboardNodeProperties(CheckerboardNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Checkerboard Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 1.0,
          max: 20.0,
          onChanged: (value) {
            setState(() {
              node.scale = value;
            });
            ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
          },
        ),
        const SizedBox(height: 12),
        const Text('Colors are controlled via inputs.', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildStripesNodeProperties(StripesNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Stripes Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 1.0,
          max: 20.0,
          onChanged: (value) {
            setState(() {
              node.scale = value;
            });
            ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Angle',
          value: node.angle,
          min: 0.0,
          max: 360.0,
          onChanged: (value) {
            setState(() {
              node.angle = value;
            });
            ref.read(nodeGraphProvider.notifier).updateNodeProperty(node.id);
          },
        ),
        const SizedBox(height: 12),
        const Text('Colors are controlled via inputs.', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildBricksNodeProperties(BricksNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bricks Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 1.0,
          max: 20.0,
          onChanged: (value) => _updateNode(() => node.scale = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Ratio',
          value: node.ratio,
          min: 0.5,
          max: 4.0,
          onChanged: (value) => _updateNode(() => node.ratio = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Mortar',
          value: node.mortar,
          min: 0.0,
          max: 0.5,
          onChanged: (value) => _updateNode(() => node.mortar = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Stagger',
          value: node.stagger,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.stagger = value),
        ),
      ],
    );
  }

  Widget _buildGridNodeProperties(GridNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Grid Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 1.0,
          max: 20.0,
          onChanged: (value) => _updateNode(() => node.scale = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Thickness',
          value: node.thickness,
          min: 0.0,
          max: 0.5,
          onChanged: (value) => _updateNode(() => node.thickness = value),
        ),
      ],
    );
  }

  Widget _buildGradientNodeProperties(GradientNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Gradient Settings'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _updateNode(() =>
              node.gradientType = node.gradientType == GradientType.linear ? GradientType.radial : GradientType.linear),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Type', style: TextStyle(color: Colors.white70)),
                Text(
                  node.gradientType.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoronoiNodeProperties(VoronoiNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Voronoi Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 2.0,
          max: 20.0,
          onChanged: (value) => _updateNode(() => node.scale = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Randomness',
          value: node.randomness,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.randomness = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Seed',
          value: node.seed,
          min: 0.0,
          max: 100.0,
          onChanged: (value) => _updateNode(() => node.seed = value),
        ),
      ],
    );
  }

  Widget _buildWaveNodeProperties(WaveNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Wave Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale/Freq',
          value: node.scale,
          min: 0.1,
          max: 2.0,
          onChanged: (value) => _updateNode(() => node.scale = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Angle',
          value: node.angle,
          min: 0.0,
          max: 360.0,
          onChanged: (value) => _updateNode(() => node.angle = value),
        ),
      ],
    );
  }

  Widget _buildGroundNodeProperties(GroundNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Ground Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Roughness',
          value: node.roughness,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.roughness = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Seed',
          value: node.seed,
          min: 0.0,
          max: 100.0,
          onChanged: (value) => _updateNode(() => node.seed = value),
        ),
      ],
    );
  }

  Widget _buildWallNodeProperties(WallNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Wall Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 1.0,
          max: 20.0,
          onChanged: (value) => _updateNode(() => node.scale = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Roughness',
          value: node.roughness,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.roughness = value),
        ),
      ],
    );
  }

  Widget _buildWaterNodeProperties(WaterNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Water Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 1.0,
          max: 20.0,
          onChanged: (value) => _updateNode(() => node.scale = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Turbulence',
          value: node.turbulence,
          min: 0.0,
          max: 2.0,
          onChanged: (value) => _updateNode(() => node.turbulence = value),
        ),
      ],
    );
  }

  Widget _buildWoodNodeProperties(WoodNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Wood Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Grain',
          value: node.grainScale,
          min: 1.0,
          max: 50.0,
          onChanged: (value) => _updateNode(() => node.grainScale = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Rings',
          value: node.rings,
          min: 1.0,
          max: 10.0,
          onChanged: (value) => _updateNode(() => node.rings = value),
        ),
      ],
    );
  }

  Widget _buildLavaNodeProperties(LavaNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Lava Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Temperature',
          value: node.temperature,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.temperature = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Turbulence',
          value: node.turbulence,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.turbulence = value),
        ),
      ],
    );
  }

  Widget _buildSnowNodeProperties(SnowNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Snow Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Density',
          value: node.density,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.density = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Softness',
          value: node.softness,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.softness = value),
        ),
      ],
    );
  }

  Widget _buildMetalFloorNodeProperties(MetalFloorNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Metal Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Panels',
          value: node.panels,
          min: 1.0,
          max: 10.0,
          onChanged: (value) => _updateNode(() => node.panels = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scratchiness',
          value: node.scratchiness,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.scratchiness = value),
        ),
      ],
    );
  }

  Widget _buildMossyStoneNodeProperties(MossyStoneNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Mossy Stone Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Moss Coverage',
          value: node.mossCoverage,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.mossCoverage = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Scale',
          value: node.scale,
          min: 1.0,
          max: 20.0,
          onChanged: (value) => _updateNode(() => node.scale = value),
        ),
      ],
    );
  }

  Widget _buildMudNodeProperties(MudNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Mud Settings'),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Wetness',
          value: node.wetness,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.wetness = value),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Dirtiness',
          value: node.dirtiness,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => _updateNode(() => node.dirtiness = value),
        ),
      ],
    );
  }

  Widget _buildPlatformNodeProperties(PlatformNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Platform Settings'),
        const SizedBox(height: 16),
        Text('Sides', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToggle('Top', node.top, (v) => _updateNode(() => node.top = v)),
            const SizedBox(width: 8),
            _buildToggle('Left', node.left, (v) => _updateNode(() => node.left = v)),
            const SizedBox(width: 8),
            _buildToggle('Right', node.right, (v) => _updateNode(() => node.right = v)),
            const SizedBox(width: 8),
            _buildToggle('Bottom', node.bottom, (v) => _updateNode(() => node.bottom = v)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Edge Width',
          value: node.edgeWidth.toDouble(),
          min: 1.0,
          max: 20.0,
          onChanged: (value) => _updateNode(() => node.edgeWidth = value.round()),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Corner Radius',
          value: node.cornerRadius.toDouble(),
          min: 0.0,
          max: 10.0,
          onChanged: (value) => _updateNode(() => node.cornerRadius = value.round()),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('Merge Settings'),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Merge Type',
          value: node.mergeType,
          options: ['solid', 'gradient', 'dither', 'wave', 'zigzag', 'noise', 'step', 'shadow'],
          onChanged: (value) => _updateNode(() => node.mergeType = value ?? 'solid'),
        ),
        const SizedBox(height: 16),
        // Wave parameters
        if (node.mergeType == 'wave') ...[
          _buildSlider(
            label: 'Wave Frequency',
            value: node.waveFrequency,
            min: 1.0,
            max: 10.0,
            onChanged: (value) => _updateNode(() => node.waveFrequency = value),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Wave Amplitude',
            value: node.waveAmplitude,
            min: 0.5,
            max: 5.0,
            onChanged: (value) => _updateNode(() => node.waveAmplitude = value),
          ),
          const SizedBox(height: 16),
        ],
        // Noise parameters
        if (node.mergeType == 'noise') ...[
          _buildSlider(
            label: 'Noise Intensity',
            value: node.noiseIntensity,
            min: 0.0,
            max: 1.0,
            onChanged: (value) => _updateNode(() => node.noiseIntensity = value),
          ),
          const SizedBox(height: 16),
        ],
        // Shadow parameters
        if (node.mergeType == 'shadow') ...[
          _buildSlider(
            label: 'Shadow Depth',
            value: node.shadowDepth.toDouble(),
            min: 1.0,
            max: 10.0,
            onChanged: (value) => _updateNode(() => node.shadowDepth = value.round()),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Shadow Opacity',
            value: node.shadowOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: (value) => _updateNode(() => node.shadowOpacity = value),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF2A2A2A),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option[0].toUpperCase() + option.substring(1),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: value ? Colors.blueAccent : Colors.white24,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: value ? Colors.blueAccent : Colors.white54,
            fontSize: 10,
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _updateNode(VoidCallback fn) {
    setState(fn);
    ref.read(nodeGraphProvider.notifier).updateNodeProperty(widget.node.id);
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
    if (widget.node is CheckerboardNode) return Colors.orange;
    if (widget.node is StripesNode) return Colors.red;
    if (widget.node is BricksNode) return Colors.orange;
    if (widget.node is GridNode) return Colors.teal;
    if (widget.node is GradientNode) return Colors.pink;
    if (widget.node is VoronoiNode) return Colors.purpleAccent;
    if (widget.node is WaveNode) return Colors.indigo;
    if (widget.node is GroundNode) return Colors.green;
    if (widget.node is WallNode) return Colors.grey;
    if (widget.node is WaterNode) return Colors.blueAccent;
    if (widget.node is WoodNode) return Colors.brown;
    if (widget.node is LavaNode) return Colors.orange;
    if (widget.node is SnowNode) return Colors.white;
    if (widget.node is MetalFloorNode) return Colors.blueGrey;
    if (widget.node is MossyStoneNode) return Colors.greenAccent;
    if (widget.node is MudNode) return Colors.brown.shade800;
    if (widget.node is PlatformNode) return Colors.indigo;
    return Colors.grey;
  }

  IconData _getNodeIcon() {
    if (widget.node is ColorNode) return Icons.palette;
    if (widget.node is NoiseNode) return Icons.grain;
    if (widget.node is ShapeNode) return Icons.crop_square;
    if (widget.node is MixNode) return Icons.merge_type;
    if (widget.node is OutputNode) return Icons.output;
    if (widget.node is CheckerboardNode) return Icons.grid_on;
    if (widget.node is StripesNode) return Icons.view_week;
    if (widget.node is BricksNode) return Icons.tab;
    if (widget.node is GridNode) return Icons.grid_3x3;
    if (widget.node is GradientNode) return Icons.gradient;
    if (widget.node is VoronoiNode) return Icons.bubble_chart;
    if (widget.node is WaveNode) return Icons.waves;
    if (widget.node is GroundNode) return Icons.grass;
    if (widget.node is WallNode) return Icons.foundation;
    if (widget.node is WaterNode) return Icons.water;
    if (widget.node is WoodNode) return Icons.nature;
    if (widget.node is LavaNode) return Icons.local_fire_department;
    if (widget.node is SnowNode) return Icons.ac_unit;
    if (widget.node is MetalFloorNode) return Icons.build;
    if (widget.node is MossyStoneNode) return Icons.grass;
    if (widget.node is MudNode) return Icons.bubble_chart;
    if (widget.node is PlatformNode) return Icons.layers;
    return Icons.widgets;
  }
}
