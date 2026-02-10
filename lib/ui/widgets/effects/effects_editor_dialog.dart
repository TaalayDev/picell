import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/extensions/primitive_extensions.dart';
import '../../../pixel/effects/effects.dart';
import '../dialogs/save_image_window.dart';
import '../fields/ui_field_builder.dart';
import '../animated_background.dart';
import 'pixlel_preview_painter.dart';

class EffectEditorDialog extends StatefulWidget {
  final Effect effect;
  final int layerWidth;
  final int layerHeight;
  final Uint32List layerPixels;
  final Function(Effect) onEffectUpdated;

  const EffectEditorDialog({
    super.key,
    required this.effect,
    required this.layerWidth,
    required this.layerHeight,
    required this.layerPixels,
    required this.onEffectUpdated,
  });

  @override
  State<EffectEditorDialog> createState() => _EffectEditorDialogState();
}

class _EffectEditorDialogState extends State<EffectEditorDialog> {
  late Map<String, dynamic> _parameters;
  late Map<String, dynamic> _metadata;
  Uint32List? _previewPixels;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _parameters = Map<String, dynamic>.from(widget.effect.parameters);
    _metadata = widget.effect.getMetadata();
    _updatePreview();
  }

  Future<void> _updatePreview() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    await Future.microtask(() {
      final effect = EffectsManager.createEffect(widget.effect.type, _parameters);
      _previewPixels = effect.apply(
        widget.layerPixels,
        widget.layerWidth,
        widget.layerHeight,
      );
    });

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final effectName = widget.effect.getName(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile ? double.infinity : 700,
        height: isMobile ? double.infinity : 600,
        child: AnimatedBackground(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Edit $effectName Effect',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _resetToDefaults,
                      tooltip: 'Reset to defaults',
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.effect.getDescription(context)),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const Divider(),

                // Content - Different layouts for mobile and desktop
                Expanded(
                  child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyChanges,
                        child: const Text('Apply Changes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Preview
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _buildPreview(),
        ),

        // Parameters
        Expanded(
          child: ListView(
            children: _buildParameterWidgets(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Preview
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildPreview(),
              ),

              const SizedBox(height: 16),

              // Quick presets section
              if (_hasPresets()) ...[
                Text(
                  'Quick Presets',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildPresetButtons(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right side - Parameters
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parameters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _buildParameterWidgets(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_previewPixels == null) {
      return const Center(child: Text('Preview not available'));
    }

    return AspectRatio(
      aspectRatio: widget.layerWidth / widget.layerHeight,
      child: CustomPaint(
        painter: PixelPreviewPainter(
          pixels: _previewPixels!,
          width: widget.layerWidth,
          height: widget.layerHeight,
        ),
      ),
    );
  }

  List<Widget> _buildParameterWidgets() {
    // Prefer the new UIField-based approach
    final fields = widget.effect.getFields();
    if (fields.isNotEmpty) {
      return UIFieldBuilder.buildAll(
        context: context,
        fields: fields,
        values: _parameters,
        onChanged: (key, value) {
          setState(() {
            _parameters[key] = value;
          });
          _updatePreview();
        },
      );
    }

    // Fallback to legacy metadata-driven approach
    final widgets = <Widget>[];

    _parameters.forEach((key, value) {
      final paramMetadata = _metadata[key] as Map<String, dynamic>?;

      if (paramMetadata != null) {
        widgets.add(_buildParameterFromMetadata(key, value, paramMetadata));
      } else {
        // Fallback to old system for parameters without metadata
        widgets.add(_buildLegacyParameter(key, value));
      }
    });

    return widgets;
  }

  Widget _buildParameterFromMetadata(String key, dynamic value, Map<String, dynamic> metadata) {
    final label = metadata['label'] as String? ?? key.capitalize();
    final description = metadata['description'] as String? ?? '';
    final type = metadata['type'] as String? ?? 'slider';

    Widget parameterControl;

    switch (type) {
      case 'slider':
        parameterControl = _buildSliderControl(key, value, metadata);
        break;
      case 'color':
        parameterControl = _buildColorControl(key, value, metadata);
        break;
      case 'select':
        parameterControl = _buildSelectControl(key, value, metadata);
        break;
      case 'bool':
        parameterControl = _buildBooleanControl(key, value, metadata);
        break;
      default:
        parameterControl = const SizedBox(); // _buildSliderControl(key, value, metadata);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (type != 'bool') // Boolean already shows its value
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatValue(value, type),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 12),
          parameterControl,
        ],
      ),
    );
  }

  Widget _buildSliderControl(String key, dynamic value, Map<String, dynamic> metadata) {
    final min = (metadata['min'] as num?)?.toDouble() ?? 0.0;
    final max = (metadata['max'] as num?)?.toDouble() ?? 1.0;
    final divisions = metadata['divisions'] as int?;

    final doubleValue = (value is int) ? value.toDouble() : (value as double);

    return Column(
      children: [
        Slider(
          value: doubleValue.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: _formatValue(doubleValue, 'slider'),
          onChanged: (newValue) {
            setState(() {
              if (value is int) {
                _parameters[key] = newValue.round();
              } else {
                _parameters[key] = newValue;
              }
            });
            _updatePreview();
          },
        ),
        // Add min/max labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatValue(min, 'slider'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _formatValue(max, 'slider'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorControl(String key, dynamic value, Map<String, dynamic> metadata) {
    final color = Color(value as int);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              showColorPicker(
                context,
                color,
                (newColor) {
                  setState(() {
                    _parameters[key] = newColor.value;
                  });
                  _updatePreview();
                },
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  'Tap to change',
                  style: TextStyle(
                    color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectControl(String key, dynamic value, Map<String, dynamic> metadata) {
    final options = () {
      if (metadata['options'] is List) {
        final list = metadata['options'] as List;
        return {for (var item in list) item.toString(): item.toString()};
      }
      return metadata['options'] as Map<dynamic, String>? ?? {};
    }();

    return DropdownButtonFormField<dynamic>(
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.entries.map((entry) {
        return DropdownMenuItem<dynamic>(
          value: entry.key,
          child: Text(entry.value, style: Theme.of(context).textTheme.bodyMedium),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _parameters[key] = newValue;
          });
          _updatePreview();
        }
      },
    );
  }

  Widget _buildBooleanControl(String key, dynamic value, Map<String, dynamic> metadata) {
    return SwitchListTile(
      title: const Text('Enable'),
      value: value as bool,
      onChanged: (newValue) {
        setState(() {
          _parameters[key] = newValue;
        });
        _updatePreview();
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLegacyParameter(String key, dynamic value) {
    // Fallback for parameters without metadata
    if (value is double) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key.capitalize(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: _getMinValue(key, widget.effect.type),
            max: _getMaxValue(key, widget.effect.type),
            divisions: 100,
            label: value.toStringAsFixed(2),
            onChanged: (newValue) {
              setState(() {
                _parameters[key] = newValue;
              });
              _updatePreview();
            },
          ),
          const SizedBox(height: 16),
        ],
      );
    } else if (value is int) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key.capitalize(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          _buildLegacySelector(key, widget.effect.type, value),
          const SizedBox(height: 16),
        ],
      );
    } else if (value is bool) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SwitchListTile(
          title: Text(
            key.capitalize(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          value: value,
          onChanged: (newValue) {
            setState(() {
              _parameters[key] = newValue;
            });
            _updatePreview();
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLegacySelector(String paramName, EffectType type, dynamic value) {
    return switch (paramName) {
      'startColor' || 'endColor' => InkWell(
          onTap: () {
            showColorPicker(
              context,
              Color(value),
              (color) {
                setState(() {
                  _parameters[paramName] = color.value;
                });
                _updatePreview();
              },
            );
          },
          child: Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: Color(value),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ),
      _ => () {
          final minValue = _getMinValue(paramName, type);
          final maxValue = _getMaxValue(paramName, type);
          return Slider(
            value: value.toDouble().clamp(minValue, maxValue),
            min: minValue,
            max: maxValue,
            divisions: maxValue.toInt() - minValue.toInt(),
            label: value.toString(),
            onChanged: (newValue) {
              setState(() {
                _parameters[paramName] = newValue.toInt();
              });
              _updatePreview();
            },
          );
        }(),
    };
  }

  String _formatValue(dynamic value, String type) {
    if (type == 'color') {
      return '#${(value as int).toRadixString(16).substring(2).toUpperCase()}';
    } else if (value is double) {
      return value.toStringAsFixed(2);
    } else {
      return value.toString();
    }
  }

  bool _hasPresets() {
    // Add preset support for certain effects
    return widget.effect.type == EffectType.brightness ||
        widget.effect.type == EffectType.contrast ||
        widget.effect.type == EffectType.blur ||
        widget.effect.type == EffectType.vignette;
  }

  List<Widget> _buildPresetButtons() {
    final presets = _getPresetsForEffect(widget.effect.type);

    return presets.entries.map((preset) {
      return ElevatedButton(
        onPressed: () {
          setState(() {
            _parameters.addAll(preset.value);
          });
          _updatePreview();
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          preset.key,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }).toList();
  }

  Map<String, Map<String, dynamic>> _getPresetsForEffect(EffectType type) {
    switch (type) {
      case EffectType.brightness:
        return {
          'Darker': {'value': -0.3},
          'Normal': {'value': 0.0},
          'Brighter': {'value': 0.3},
          'Very Bright': {'value': 0.6},
        };
      case EffectType.contrast:
        return {
          'Low': {'value': -0.5},
          'Normal': {'value': 0.0},
          'High': {'value': 0.5},
          'Very High': {'value': 0.8},
        };
      case EffectType.blur:
        return {
          'Subtle': {'radius': 1},
          'Soft': {'radius': 2},
          'Medium': {'radius': 4},
          'Strong': {'radius': 6},
        };
      case EffectType.vignette:
        return {
          'Subtle': {'intensity': 0.3, 'size': 0.7},
          'Medium': {'intensity': 0.5, 'size': 0.5},
          'Strong': {'intensity': 0.7, 'size': 0.3},
        };
      default:
        return {};
    }
  }

  void _resetToDefaults() {
    setState(() {
      _parameters = widget.effect.getDefaultParameters();
    });
    _updatePreview();
  }

  // Legacy fallback methods
  double _getMinValue(String paramName, EffectType type) {
    if (paramName == 'value' && (type == EffectType.brightness || type == EffectType.contrast)) {
      return -1.0;
    } else if (paramName == 'colors' && type == EffectType.paletteReduction) {
      return 2.0;
    } else if (paramName == 'startColor' || paramName == 'endColor') {
      return 0.0;
    } else if (paramName == 'radius' || paramName == 'blockSize') {
      return 1.0;
    } else if (paramName == 'strength') {
      return 0.0;
    } else if (paramName == 'direction') {
      return -3.0;
    }
    return 0.0;
  }

  double _getMaxValue(String paramName, EffectType type) {
    switch (paramName) {
      case 'radius':
        return 10.0;
      case 'blockSize':
        return 10.0;
      case 'strength':
        return 5.0;
      case 'direction':
        return 7.0;
      case 'colors':
        return type == EffectType.paletteReduction ? 64 : 1.0;
      case 'endColor':
        return 0x7FFFFFFFFFFFFFFF.toDouble();
      case 'startColor':
        return 0x7FFFFFFFFFFFFFFF.toDouble();
      case 'colorSteps':
        return 255;
      case 'ringSpacing':
        return 20.0;
      case 'grainIntensity':
        return 1.0;
      case 'knotCount':
        return 10.0;
      default:
        return 1.0;
    }
  }

  void _applyChanges() {
    // Create a new effect with updated parameters
    final updatedEffect = EffectsManager.createEffect(widget.effect.type, _parameters);

    widget.onEffectUpdated(updatedEffect);
    Navigator.of(context).pop();
  }
}
