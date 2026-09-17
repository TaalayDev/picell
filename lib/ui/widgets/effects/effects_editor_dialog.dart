import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/extensions/primitive_extensions.dart';
import '../../../pixel/effects/effects.dart';
import '../dialogs/save_image_window.dart';
import '../fields/ui_field_builder.dart';
import '../animated_background.dart';
import 'pixlel_preview_painter.dart';
import '../../../l10n/strings.dart';

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
      final effect =
          EffectsManager.createEffect(widget.effect.type, _parameters);
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
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
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
                        Strings.of(context).editEffect(effectName),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _resetToDefaults,
                      tooltip: Strings.of(context).resetToDefaults,
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(widget.effect.getDescription(context)),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const Divider(),

                // Content - Different layouts for mobile and desktop
                Expanded(
                  child:
                      isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(Strings.of(context).cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyChanges,
                        child: Text(Strings.of(context).applyChanges),
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
                Strings.of(context).preview,
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
                  Strings.of(context).quickPresets,
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
                Strings.of(context).parameters,
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
      return Center(child: Text(Strings.of(context).previewNotAvailable));
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

  Widget _buildParameterFromMetadata(
      String key, dynamic value, Map<String, dynamic> metadata) {
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
        parameterControl =
            const SizedBox(); // _buildSliderControl(key, value, metadata);
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (type != 'bool') // Boolean already shows its value
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 12),
          parameterControl,
        ],
      ),
    );
  }

  Widget _buildSliderControl(
      String key, dynamic value, Map<String, dynamic> metadata) {
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

  Widget _buildColorControl(
      String key, dynamic value, Map<String, dynamic> metadata) {
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
                  Strings.of(context).tapToChange,
                  style: TextStyle(
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
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

  Widget _buildSelectControl(
      String key, dynamic value, Map<String, dynamic> metadata) {
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
          child:
              Text(entry.value, style: Theme.of(context).textTheme.bodyMedium),
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

  Widget _buildBooleanControl(
      String key, dynamic value, Map<String, dynamic> metadata) {
    return SwitchListTile(
      title: Text(Strings.of(context).enable),
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

  Widget _buildLegacySelector(
      String paramName, EffectType type, dynamic value) {
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
        widget.effect.type == EffectType.vignette ||
        widget.effect.type == EffectType.crt ||
        widget.effect.type == EffectType.lcdMatrix ||
        widget.effect.type == EffectType.chromaticAberration ||
        widget.effect.type == EffectType.dropShadow ||
        widget.effect.type == EffectType.normalMap ||
        widget.effect.type == EffectType.colorCycling ||
        widget.effect.type == EffectType.rimLight ||
        widget.effect.type == EffectType.squashStretch ||
        widget.effect.type == EffectType.windSway ||
        widget.effect.type == EffectType.hitFlash ||
        widget.effect.type == EffectType.ghostTrail ||
        widget.effect.type == EffectType.starfield ||
        widget.effect.type == EffectType.electricArc ||
        widget.effect.type == EffectType.blizzard ||
        widget.effect.type == EffectType.portalVortex ||
        widget.effect.type == EffectType.energyShield ||
        widget.effect.type == EffectType.radiantRays ||
        widget.effect.type == EffectType.burningEmbers ||
        widget.effect.type == EffectType.underwaterCaustics ||
        widget.effect.type == EffectType.risingBubbles ||
        widget.effect.type == EffectType.slimeDrip ||
        widget.effect.type == EffectType.radialShockwave ||
        widget.effect.type == EffectType.slashArc ||
        widget.effect.type == EffectType.hologramGlitch;
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
          _localizePreset(preset.key),
          style: const TextStyle(fontSize: 12),
        ),
      );
    }).toList();
  }

  String _localizePreset(String key) {
    return switch (key) {
      'Darker' => Strings.of(context).presetDarker,
      'Normal' => Strings.of(context).presetNormal,
      'Brighter' => Strings.of(context).presetBrighter,
      'Very Bright' => Strings.of(context).presetVeryBright,
      'Low' => Strings.of(context).presetLow,
      'High' => Strings.of(context).presetHigh,
      'Very High' => Strings.of(context).presetVeryHigh,
      'Subtle' => Strings.of(context).presetSubtle,
      'Soft' => Strings.of(context).presetSoft,
      'Medium' => Strings.of(context).presetMedium,
      'Strong' => Strings.of(context).presetStrong,
      _ => key,
    };
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
      case EffectType.crt:
        return {
          'Arcade CRT': {
            'scanlineIntensity': 0.45,
            'scanlineSpacing': 2,
            'rgbSubpixel': 0.35,
            'curvature': 0.15,
            'vignette': 0.35,
            'brightnessBoost': 0.2,
            'preserveAlpha': true,
          },
          'Subtle TV': {
            'scanlineIntensity': 0.2,
            'scanlineSpacing': 2,
            'rgbSubpixel': 0.15,
            'curvature': 0.05,
            'vignette': 0.15,
            'brightnessBoost': 0.1,
            'preserveAlpha': true,
          },
          'Curved Monitor': {
            'scanlineIntensity': 0.3,
            'scanlineSpacing': 2,
            'rgbSubpixel': 0.25,
            'curvature': 0.28,
            'vignette': 0.4,
            'brightnessBoost': 0.15,
            'preserveAlpha': true,
          },
          'Scanlines Only': {
            'scanlineIntensity': 0.5,
            'scanlineSpacing': 2,
            'rgbSubpixel': 0.0,
            'curvature': 0.0,
            'vignette': 0.0,
            'brightnessBoost': 0.0,
            'preserveAlpha': true,
          },
        };
      case EffectType.lcdMatrix:
        return {
          'DMG Game Boy': {
            'palette': 'dmg_green',
            'ditherMode': 'bayer2x2',
            'pixelGrid': 0.35,
            'pixelSize': 2,
            'contrast': 0.1,
            'brightness': 0.0,
            'preserveAlpha': true,
          },
          'Pocket Mono': {
            'palette': 'pocket_gray',
            'ditherMode': 'bayer2x2',
            'pixelGrid': 0.25,
            'pixelSize': 2,
            'contrast': 0.15,
            'brightness': 0.05,
            'preserveAlpha': true,
          },
          'GB Light': {
            'palette': 'gb_light',
            'ditherMode': 'bayer4x4',
            'pixelGrid': 0.3,
            'pixelSize': 2,
            'contrast': 0.1,
            'brightness': 0.05,
            'preserveAlpha': true,
          },
          'Virtual Boy': {
            'palette': 'virtual_boy',
            'ditherMode': 'bayer2x2',
            'pixelGrid': 0.4,
            'pixelSize': 2,
            'contrast': 0.2,
            'brightness': 0.0,
            'preserveAlpha': true,
          },
          'Amber LCD': {
            'palette': 'amber',
            'ditherMode': 'bayer4x4',
            'pixelGrid': 0.35,
            'pixelSize': 2,
            'contrast': 0.1,
            'brightness': 0.0,
            'preserveAlpha': true,
          },
        };
      case EffectType.chromaticAberration:
        return {
          'Classic RGB Split': {
            'mode': 'linear',
            'distance': 3.0,
            'angle': 0.0,
            'blueFactor': 1.0,
            'preserveAlpha': true,
          },
          'Diagonal Shift': {
            'mode': 'linear',
            'distance': 4.0,
            'angle': 45.0,
            'blueFactor': 1.0,
            'preserveAlpha': true,
          },
          'Radial Lens Edge': {
            'mode': 'radial',
            'distance': 5.0,
            'angle': 0.0,
            'blueFactor': 1.0,
            'preserveAlpha': true,
          },
          'Glitch Dispersion': {
            'mode': 'linear',
            'distance': 8.0,
            'angle': 0.0,
            'blueFactor': 1.2,
            'preserveAlpha': true,
          },
        };
      case EffectType.dropShadow:
        return {
          'Soft 2D Shadow': {
            'mode': 'drop',
            'shadowColor': 0x99000000,
            'offsetX': 2,
            'offsetY': 3,
            'softness': 1,
            'shadowOnly': false,
          },
          'Isometric Ground': {
            'mode': 'isometric',
            'shadowColor': 0x88000000,
            'offsetX': 2,
            'offsetY': 2,
            'isometricAngle': 30.0,
            'isometricScale': 0.5,
            'softness': 0,
            'shadowOnly': false,
          },
          'Crisp Retro': {
            'mode': 'drop',
            'shadowColor': 0xFF000000,
            'offsetX': 1,
            'offsetY': 1,
            'softness': 0,
            'shadowOnly': false,
          },
          'Deep Cast': {
            'mode': 'drop',
            'shadowColor': 0x80000000,
            'offsetX': 4,
            'offsetY': 6,
            'softness': 2,
            'shadowOnly': false,
          },
        };
      case EffectType.normalMap:
        return {
          'Standard 2D Bump': {
            'strength': 2.5,
            'bevelEdges': true,
            'bevelRadius': 2,
            'invertY': false,
            'smoothness': 0,
            'preserveAlpha': true,
          },
          'Hard Beveled Volume': {
            'strength': 4.5,
            'bevelEdges': true,
            'bevelRadius': 3,
            'invertY': false,
            'smoothness': 0,
            'preserveAlpha': true,
          },
          'Soft Pillow': {
            'strength': 1.8,
            'bevelEdges': true,
            'bevelRadius': 3,
            'invertY': false,
            'smoothness': 1,
            'preserveAlpha': true,
          },
          'DirectX Inverted': {
            'strength': 2.5,
            'bevelEdges': true,
            'bevelRadius': 2,
            'invertY': true,
            'smoothness': 0,
            'preserveAlpha': true,
          },
        };
      case EffectType.colorCycling:
        return {
          'Rainbow Flow': {
            'mode': 'hueCycle',
            'speed': 1.0,
            'phase': 0.0,
            'preserveAlpha': true,
          },
          'Retro Waterfall': {
            'mode': 'waterfall',
            'speed': 1.5,
            'phase': 0.0,
            'preserveAlpha': true,
          },
          'Lava Glow': {
            'mode': 'fireLava',
            'speed': 1.2,
            'phase': 0.0,
            'preserveAlpha': true,
          },
          'Neon Pulse': {
            'mode': 'neonPulse',
            'speed': 1.0,
            'phase': 0.0,
            'preserveAlpha': true,
          },
        };
      case EffectType.rimLight:
        return {
          'Sunlit Rim (Top-Right)': {
            'lightColor': 0xFFFFE082,
            'lightAngle': 45.0,
            'brightness': 1.0,
            'thickness': 1,
            'wrap': 0.2,
            'preserveAlpha': true,
          },
          'Moonlit Rim (Top-Left)': {
            'lightColor': 0xFF80DEEA,
            'lightAngle': 135.0,
            'brightness': 1.2,
            'thickness': 1,
            'wrap': 0.2,
            'preserveAlpha': true,
          },
          'Dramatic Silhouette': {
            'lightColor': 0xFFFFFFFF,
            'lightAngle': 90.0,
            'brightness': 1.5,
            'thickness': 1,
            'wrap': 0.0,
            'preserveAlpha': true,
          },
          'All-Round Neon Glow': {
            'lightColor': 0xFFFF4081,
            'lightAngle': 45.0,
            'brightness': 0.8,
            'thickness': 2,
            'wrap': 0.8,
            'preserveAlpha': true,
          },
        };
      case EffectType.squashStretch:
        return {
          'Ground Impact': {
            'amount': 0.35,
            'frequency': 1.0,
            'phase': 0.75,
            'anchor': 'bottom',
            'preserveAlpha': true,
          },
          'Jump Takeoff': {
            'amount': 0.25,
            'frequency': 1.0,
            'phase': 0.25,
            'anchor': 'bottom',
            'preserveAlpha': true,
          },
          'Breathing Idle': {
            'amount': 0.08,
            'frequency': 0.8,
            'phase': 0.0,
            'anchor': 'center',
            'preserveAlpha': true,
          },
          'Bouncing Ball': {
            'amount': 0.3,
            'frequency': 2.0,
            'phase': 0.0,
            'anchor': 'bottom',
            'preserveAlpha': true,
          },
        };
      case EffectType.windSway:
        return {
          'Gentle Breeze': {
            'amplitude': 4.0,
            'speed': 0.8,
            'frequency': 0.5,
            'stiffness': 1.5,
            'anchor': 'bottom',
            'preserveAlpha': true,
          },
          'Storm Gust': {
            'amplitude': 12.0,
            'speed': 2.0,
            'frequency': 1.2,
            'stiffness': 1.3,
            'anchor': 'bottom',
            'preserveAlpha': true,
          },
          'Hanging Vine': {
            'amplitude': 8.0,
            'speed': 1.0,
            'frequency': 0.8,
            'stiffness': 1.8,
            'anchor': 'top',
            'preserveAlpha': true,
          },
          'Flag Flutter': {
            'amplitude': 6.0,
            'speed': 2.5,
            'frequency': 1.8,
            'stiffness': 1.2,
            'anchor': 'left',
            'preserveAlpha': true,
          },
        };
      case EffectType.hitFlash:
        return {
          'Classic White Flash': {
            'mode': 'flashDecay',
            'flashColor': 0xFFFFFFFF,
            'intensity': 1.0,
            'blinkCount': 4,
            'preserveAlpha': true,
          },
          'Red Injury Pulse': {
            'mode': 'flashDecay',
            'flashColor': 0xFFFF1744,
            'intensity': 0.9,
            'blinkCount': 4,
            'preserveAlpha': true,
          },
          'Invulnerability Blink': {
            'mode': 'blink',
            'flashColor': 0xFFFFFFFF,
            'intensity': 1.0,
            'blinkCount': 5,
            'preserveAlpha': true,
          },
          'Boss Critical Hit': {
            'mode': 'flashAndBlink',
            'flashColor': 0xFFFFD700,
            'intensity': 1.0,
            'blinkCount': 6,
            'preserveAlpha': true,
          },
        };
      case EffectType.ghostTrail:
        return {
          'Horizontal Dash': {
            'ghostCount': 3,
            'spacing': 8.0,
            'direction': 0.0,
            'tintColor': 0xFF00E5FF,
            'tintStrength': 0.7,
            'fade': 0.6,
            'preserveAlpha': true,
          },
          'Super Sonic Echo': {
            'ghostCount': 4,
            'spacing': 6.0,
            'direction': 0.0,
            'tintColor': 0xFFFFD700,
            'tintStrength': 0.8,
            'fade': 0.5,
            'preserveAlpha': true,
          },
          'Shadow Teleport': {
            'ghostCount': 3,
            'spacing': 12.0,
            'direction': 180.0,
            'tintColor': 0xFF7C4DFF,
            'tintStrength': 0.85,
            'fade': 0.7,
            'preserveAlpha': true,
          },
          'Upward Launch': {
            'ghostCount': 3,
            'spacing': 10.0,
            'direction': 90.0,
            'tintColor': 0xFF69F0AE,
            'tintStrength': 0.6,
            'fade': 0.6,
            'preserveAlpha': true,
          },
        };
      case EffectType.starfield:
        return {
          'Deep Cosmos & Nebula': {
            'starDensity': 0.6,
            'twinkleSpeed': 1.5,
            'nebulaIntensity': 0.6,
            'nebulaTheme': 'violet',
            'shootingStars': true,
            'preserveAlpha': false,
          },
          'Twinkling Night Sky': {
            'starDensity': 0.5,
            'twinkleSpeed': 2.0,
            'nebulaIntensity': 0.0,
            'nebulaTheme': 'cyanBlue',
            'shootingStars': false,
            'preserveAlpha': true,
          },
          'Synthwave Orbit': {
            'starDensity': 0.7,
            'twinkleSpeed': 2.2,
            'nebulaIntensity': 0.8,
            'nebulaTheme': 'synthwave',
            'shootingStars': true,
            'preserveAlpha': false,
          },
          'Solar Gold Dust': {
            'starDensity': 0.4,
            'twinkleSpeed': 1.2,
            'nebulaIntensity': 0.5,
            'nebulaTheme': 'golden',
            'shootingStars': true,
            'preserveAlpha': true,
          },
        };
      case EffectType.electricArc:
        return {
          'Tesla Coil Discharge': {
            'strikeMode': 'radial',
            'arcColor': 0xFF00E5FF,
            'branching': 0.7,
            'jaggedness': 1.0,
            'glowRadius': 2,
            'flashIntensity': 0.3,
            'preserveAlpha': true,
          },
          'Thunderbolt Strike': {
            'strikeMode': 'vertical',
            'arcColor': 0xFF80D8FF,
            'branching': 0.8,
            'jaggedness': 1.2,
            'glowRadius': 2,
            'flashIntensity': 0.5,
            'preserveAlpha': true,
          },
          'Contour Plasma Aura': {
            'strikeMode': 'contourAura',
            'arcColor': 0xFFE040FB,
            'branching': 0.4,
            'jaggedness': 0.6,
            'glowRadius': 1,
            'flashIntensity': 0.2,
            'preserveAlpha': true,
          },
          'Golden Spark Shock': {
            'strikeMode': 'horizontal',
            'arcColor': 0xFFFFD700,
            'branching': 0.5,
            'jaggedness': 0.9,
            'glowRadius': 2,
            'flashIntensity': 0.4,
            'preserveAlpha': true,
          },
        };
      case EffectType.blizzard:
        return {
          'Gentle Winter Flurry': {
            'intensity': 0.4,
            'windAngle': 10.0,
            'swirlTurbulence': 0.3,
            'blizzardHaze': 0.1,
            'frostSurfaces': true,
            'preserveAlpha': true,
          },
          'Howling Whiteout': {
            'intensity': 0.9,
            'windAngle': 35.0,
            'swirlTurbulence': 0.8,
            'blizzardHaze': 0.6,
            'frostSurfaces': true,
            'preserveAlpha': false,
          },
          'Side Wind Gale': {
            'intensity': 0.7,
            'windAngle': -40.0,
            'swirlTurbulence': 0.5,
            'blizzardHaze': 0.3,
            'frostSurfaces': true,
            'preserveAlpha': true,
          },
          'Frosty Midnight': {
            'intensity': 0.5,
            'windAngle': 15.0,
            'swirlTurbulence': 0.4,
            'blizzardHaze': 0.2,
            'frostSurfaces': true,
            'preserveAlpha': false,
          },
        };
      case EffectType.portalVortex:
        return {
          'Cosmic Wormhole': {
            'spinSpeed': 1.8,
            'swirlTwist': 2.0,
            'coreRadius': 0.25,
            'glowColor': 0xFFD500F9,
            'particlePull': 0.8,
            'portalMode': 'warpSprite',
            'preserveAlpha': true,
          },
          'Nether Void Gate': {
            'spinSpeed': 1.2,
            'swirlTwist': 1.5,
            'coreRadius': 0.35,
            'glowColor': 0xFF00E676,
            'particlePull': 0.6,
            'portalMode': 'portalOverlay',
            'preserveAlpha': true,
          },
          'Cyber Warp Ring': {
            'spinSpeed': 2.5,
            'swirlTwist': 2.5,
            'coreRadius': 0.2,
            'glowColor': 0xFF00E5FF,
            'particlePull': 0.9,
            'portalMode': 'warpSprite',
            'preserveAlpha': false,
          },
          'Solar Singularity': {
            'spinSpeed': 1.0,
            'swirlTwist': 1.0,
            'coreRadius': 0.15,
            'glowColor': 0xFFFFD600,
            'particlePull': 0.5,
            'portalMode': 'warpSprite',
            'preserveAlpha': true,
          },
        };
      case EffectType.energyShield:
        return {
          'Hex Deflector Matrix': {
            'shieldShape': 'hexMatrix',
            'barrierColor': 0xFF00B0FF,
            'pulseRate': 1.5,
            'impactRipple': 0.7,
            'shieldThickness': 2,
            'preserveAlpha': true,
          },
          'Plasma Bubble Shield': {
            'shieldShape': 'spherical',
            'barrierColor': 0xFF7C4DFF,
            'pulseRate': 1.8,
            'impactRipple': 0.5,
            'shieldThickness': 3,
            'preserveAlpha': true,
          },
          'Overcharged Contour': {
            'shieldShape': 'contourAura',
            'barrierColor': 0xFF00E676,
            'pulseRate': 2.2,
            'impactRipple': 0.8,
            'shieldThickness': 2,
            'preserveAlpha': true,
          },
          'Golden Aegis Barrier': {
            'shieldShape': 'spherical',
            'barrierColor': 0xFFFFD700,
            'pulseRate': 1.0,
            'impactRipple': 0.6,
            'shieldThickness': 2,
            'preserveAlpha': true,
          },
        };
      case EffectType.radiantRays:
        return {
          'Holy Level-Up': {
            'beamCount': 4,
            'rayIntensity': 0.8,
            'dustDensity': 0.7,
            'ascendSpeed': 1.5,
            'auraColor': 0xFFFFD700,
            'preserveAlpha': true,
          },
          'Celestial Blessing': {
            'beamCount': 5,
            'rayIntensity': 0.6,
            'dustDensity': 0.5,
            'ascendSpeed': 1.0,
            'auraColor': 0xFF18FFFF,
            'preserveAlpha': true,
          },
          'Dark Mana Ascension': {
            'beamCount': 3,
            'rayIntensity': 0.7,
            'dustDensity': 0.6,
            'ascendSpeed': 1.2,
            'auraColor': 0xFFE040FB,
            'preserveAlpha': true,
          },
          'Sunbeam Sanctuary': {
            'beamCount': 6,
            'rayIntensity': 0.5,
            'dustDensity': 0.3,
            'ascendSpeed': 0.8,
            'auraColor': 0xFFFFF176,
            'preserveAlpha': false,
          },
        };
      case EffectType.burningEmbers:
        return {
          'Infernal Boss Death': {
            'emberColor': 0xFFFF6D00,
            'decayDirection': 'bottomToTop',
            'wispSpread': 0.6,
            'sparkCount': 60,
            'burnProgress': 0.5,
            'preserveAlpha': true,
          },
          'Phantom Soul Wisps': {
            'emberColor': 0xFF9C27B0,
            'decayDirection': 'bottomToTop',
            'wispSpread': 0.8,
            'sparkCount': 50,
            'burnProgress': 0.5,
            'preserveAlpha': true,
          },
          'Necrotic Decay': {
            'emberColor': 0xFF00E676,
            'decayDirection': 'radialOutward',
            'wispSpread': 0.5,
            'sparkCount': 40,
            'burnProgress': 0.5,
            'preserveAlpha': true,
          },
          'Phoenix Rebirth': {
            'emberColor': 0xFFFFD600,
            'decayDirection': 'topToBottom',
            'wispSpread': 0.7,
            'sparkCount': 70,
            'burnProgress': 0.5,
            'preserveAlpha': false,
          },
        };
      case EffectType.underwaterCaustics:
        return {
          'Shallow Coral Reef': {
            'causticScale': 1.8,
            'rippleSpeed': 1.6,
            'waterTint': 0xFF00E5FF,
            'tintStrength': 0.35,
            'buoyancySway': 2.0,
            'preserveAlpha': true,
          },
          'Deep Abyssal Blue': {
            'causticScale': 1.2,
            'rippleSpeed': 0.8,
            'waterTint': 0xFF0D47A1,
            'tintStrength': 0.55,
            'buoyancySway': 1.0,
            'preserveAlpha': true,
          },
          'Emerald Swamp Waters': {
            'causticScale': 1.5,
            'rippleSpeed': 1.0,
            'waterTint': 0xFF00BFA5,
            'tintStrength': 0.45,
            'buoyancySway': 1.5,
            'preserveAlpha': true,
          },
          'Sunlit Pool': {
            'causticScale': 2.2,
            'rippleSpeed': 2.0,
            'waterTint': 0xFF40C4FF,
            'tintStrength': 0.25,
            'buoyancySway': 2.5,
            'preserveAlpha': false,
          },
        };
      case EffectType.risingBubbles:
        return {
          'Magic Mana Potion': {
            'bubbleCount': 28,
            'bubbleSize': 'mixed',
            'riseSpeed': 1.2,
            'wobbleSpeed': 2.0,
            'bubbleColor': 0xFF00E5FF,
            'popSplashes': true,
            'preserveAlpha': true,
          },
          'Toxic Cauldron Fizz': {
            'bubbleCount': 36,
            'bubbleSize': 'large',
            'riseSpeed': 1.6,
            'wobbleSpeed': 2.5,
            'bubbleColor': 0xFF76FF03,
            'popSplashes': true,
            'preserveAlpha': true,
          },
          'Champagne Soda': {
            'bubbleCount': 45,
            'bubbleSize': 'small',
            'riseSpeed': 2.2,
            'wobbleSpeed': 1.2,
            'bubbleColor': 0xFFFFF9C4,
            'popSplashes': true,
            'preserveAlpha': false,
          },
          'Deep Sea Diver': {
            'bubbleCount': 18,
            'bubbleSize': 'mixed',
            'riseSpeed': 0.9,
            'wobbleSpeed': 1.0,
            'bubbleColor': 0xFFE0F7FA,
            'popSplashes': true,
            'preserveAlpha': true,
          },
        };
      case EffectType.slimeDrip:
        return {
          'Alien Acid Ooze': {
            'dripFrequency': 2,
            'viscosity': 0.7,
            'liquidColor': 0xFF76FF03,
            'splashSize': 3,
            'gravity': 1.4,
            'preserveAlpha': true,
          },
          'Vampiric Blood Drip': {
            'dripFrequency': 2,
            'viscosity': 0.5,
            'liquidColor': 0xFFD50000,
            'splashSize': 2,
            'gravity': 1.8,
            'preserveAlpha': true,
          },
          'Shadow Tar': {
            'dripFrequency': 1,
            'viscosity': 0.9,
            'liquidColor': 0xFF212121,
            'splashSize': 3,
            'gravity': 0.9,
            'preserveAlpha': true,
          },
          'Toxic Sludge': {
            'dripFrequency': 3,
            'viscosity': 0.6,
            'liquidColor': 0xFFAA00FF,
            'splashSize': 4,
            'gravity': 1.6,
            'preserveAlpha': true,
          },
        };
      case EffectType.radialShockwave:
        return {
          'Seismic Ground Pound': {
            'waveThickness': 3,
            'expansionSpeed': 1.2,
            'ringShape': 'isometricDisc',
            'shockwaveColor': 0xFFFFB300,
            'dustDebris': true,
            'debrisCount': 40,
            'preserveAlpha': true,
          },
          'Parry Deflection Flash': {
            'waveThickness': 2,
            'expansionSpeed': 2.2,
            'ringShape': 'circular',
            'shockwaveColor': 0xFFFFD700,
            'dustDebris': true,
            'debrisCount': 20,
            'preserveAlpha': true,
          },
          'Sonic Boom Ring': {
            'waveThickness': 4,
            'expansionSpeed': 1.8,
            'ringShape': 'circular',
            'shockwaveColor': 0xFF00E5FF,
            'dustDebris': false,
            'debrisCount': 10,
            'preserveAlpha': false,
          },
          'Supernova Burst': {
            'waveThickness': 3,
            'expansionSpeed': 1.5,
            'ringShape': 'circular',
            'shockwaveColor': 0xFFFF1744,
            'dustDebris': true,
            'debrisCount': 50,
            'preserveAlpha': true,
          },
        };
      case EffectType.slashArc:
        return {
          'Muramasa Crimson Slash': {
            'slashAngle': -35.0,
            'arcCurvature': 0.45,
            'slashWidth': 4,
            'bladeColor': 0xFFFF1744,
            'sparkSpray': true,
            'sparkCount': 35,
            'preserveAlpha': true,
          },
          'Cyber Katana Beam': {
            'slashAngle': 0.0,
            'arcCurvature': 0.2,
            'slashWidth': 3,
            'bladeColor': 0xFF00E5FF,
            'sparkSpray': true,
            'sparkCount': 25,
            'preserveAlpha': true,
          },
          'Anime Critical Cleave': {
            'slashAngle': 45.0,
            'arcCurvature': 0.6,
            'slashWidth': 5,
            'bladeColor': 0xFFFFD700,
            'sparkSpray': true,
            'sparkCount': 45,
            'preserveAlpha': true,
          },
          'Void Crescent Scythe': {
            'slashAngle': -60.0,
            'arcCurvature': 0.5,
            'slashWidth': 3,
            'bladeColor': 0xFFB388FF,
            'sparkSpray': true,
            'sparkCount': 20,
            'preserveAlpha': false,
          },
        };
      case EffectType.hologramGlitch:
        return {
          'Cyberpunk Sci-Fi Holo': {
            'holoColor': 0xFF00E5FF,
            'colorIntensity': 0.85,
            'scanlineDensity': 2,
            'flickerInterval': 1.5,
            'glitchDropout': 0.25,
            'jitterSpread': 2,
            'preserveAlpha': true,
          },
          'Vintage Amber Terminal': {
            'holoColor': 0xFFFFB300,
            'colorIntensity': 0.8,
            'scanlineDensity': 3,
            'flickerInterval': 1.2,
            'glitchDropout': 0.35,
            'jitterSpread': 3,
            'preserveAlpha': true,
          },
          'Corrupted Malfunction': {
            'holoColor': 0xFF00E676,
            'colorIntensity': 0.9,
            'scanlineDensity': 2,
            'flickerInterval': 2.2,
            'glitchDropout': 0.6,
            'jitterSpread': 5,
            'preserveAlpha': true,
          },
          'Ghostly Spirit Projection': {
            'holoColor': 0xFFB388FF,
            'colorIntensity': 0.6,
            'scanlineDensity': 4,
            'flickerInterval': 0.8,
            'glitchDropout': 0.1,
            'jitterSpread': 1,
            'preserveAlpha': false,
          },
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
    if (paramName == 'value' &&
        (type == EffectType.brightness || type == EffectType.contrast)) {
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
        return 0xFFFFFFFF.toDouble();
      case 'startColor':
        return 0xFFFFFFFF.toDouble();
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
    final updatedEffect =
        EffectsManager.createEffect(widget.effect.type, _parameters);

    widget.onEffectUpdated(updatedEffect);
    Navigator.of(context).pop();
  }
}
