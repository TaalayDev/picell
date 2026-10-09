import 'dart:typed_data';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import '../../../core/extensions/primitive_extensions.dart';
import '../../../pixel/effects/effects.dart';
import '../dialogs/save_image_window.dart';
import '../fields/ui_field_builder.dart';
import '../animated_background.dart';
import 'pixlel_preview_painter.dart';
import '../../../l10n/strings.dart';
import '../notifications/app_notification.dart';

class EffectEditorDialog extends StatefulWidget {
  final Effect effect;
  final int layerWidth;
  final int layerHeight;
  final Uint32List layerPixels;
  final Function(Effect) onEffectUpdated;
  final String? title;
  final String? applyButtonText;

  const EffectEditorDialog({
    super.key,
    required this.effect,
    required this.layerWidth,
    required this.layerHeight,
    required this.layerPixels,
    required this.onEffectUpdated,
    this.title,
    this.applyButtonText,
  });

  static Future<void> show({
    required BuildContext context,
    required Effect effect,
    required int layerWidth,
    required int layerHeight,
    required Uint32List layerPixels,
    required ValueChanged<Effect> onApply,
    String? title,
    String? applyButtonText,
  }) {
    Widget builder(BuildContext context) => EffectEditorDialog(
          effect: effect,
          layerWidth: layerWidth,
          layerHeight: layerHeight,
          layerPixels: layerPixels,
          onEffectUpdated: onApply,
          title: title,
          applyButtonText: applyButtonText,
        );
    if (MediaQuery.sizeOf(context).width < 600) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            FractionallySizedBox(heightFactor: .94, child: builder(context)),
      );
    }
    return showDialog<void>(context: context, builder: builder);
  }

  @override
  State<EffectEditorDialog> createState() => _EffectEditorDialogState();
}

class _EffectEditorDialogState extends State<EffectEditorDialog> {
  late Map<String, dynamic> _parameters;
  late final Map<String, dynamic> _initialParameters;
  bool _showOriginal = false;
  bool _compareEnabled = false;
  late Map<String, dynamic> _metadata;
  Uint32List? _previewPixels;
  bool _isProcessing = false;
  bool _needsUpdate = false;

  @override
  void initState() {
    super.initState();
    _parameters = Map<String, dynamic>.from(widget.effect.parameters);
    _initialParameters = Map<String, dynamic>.from(widget.effect.parameters);
    _metadata = widget.effect.getMetadata();
    _updatePreview();
  }

  Future<void> _updatePreview() async {
    if (_isProcessing) {
      _needsUpdate = true;
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    while (mounted) {
      _needsUpdate = false;
      final currentParams = Map<String, dynamic>.from(_parameters);
      // Large canvases are processed off the main thread so dragging a slider
      // never freezes the dialog.
      final preview = await EffectsManager.applyMultipleEffectsAsync(
        widget.layerPixels,
        widget.layerWidth,
        widget.layerHeight,
        [EffectsManager.createEffect(widget.effect.type, currentParams)],
      );

      if (!mounted) break;
      _previewPixels = preview;

      if (!_needsUpdate) break;
    }

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

    final screen = MediaQuery.sizeOf(context);
    final content = SizedBox(
      key: const ValueKey('effect-editor-content'),
      width:
          isMobile ? double.infinity : (screen.width - 48).clamp(0.0, 1280.0),
      height:
          isMobile ? double.infinity : (screen.height - 48).clamp(0.0, 940.0),
      child: AnimatedBackground(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
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
                      widget.title ??
                          Strings.of(context).editEffect(effectName),
                      style: (isMobile
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.headlineSmall)
                          ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: isMobile ? 2 : null,
                      overflow: isMobile ? TextOverflow.ellipsis : null,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: _hasChanges ? _revertChanges : null,
                    tooltip: Strings.of(context).revertChanges,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _resetToDefaults,
                    tooltip: Strings.of(context).resetToDefaults,
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () {
                      AppNotification.info(
                        context,
                        widget.effect.getDescription(context),
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
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(Strings.of(context).cancel),
                    ),
                    ElevatedButton(
                      onPressed: _applyChanges,
                      child: Text(
                        widget.applyButtonText ??
                            Strings.of(context).applyChanges,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ModalRoute.of(context) is ModalBottomSheetRoute) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(child: SafeArea(top: false, child: content)),
      );
    }
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24, vertical: isMobile ? 20 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        LayoutBuilder(
            builder: (context, constraints) => SizedBox(
                  height: (MediaQuery.sizeOf(context).height * .25)
                      .clamp(140.0, 240.0),
                  child: _compareEnabled
                      ? Row(children: [
                          Expanded(child: _buildComparisonPane(original: true)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildComparisonPane(original: false)),
                        ])
                      : Center(child: _buildPreviewCard(maxHeight: 240)),
                )),
        SwitchListTile.adaptive(
          key: const ValueKey('effect-mobile-compare-switch'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
              '${Strings.of(context).original} / ${Strings.of(context).effectResultLabel}'),
          secondary: const Icon(Icons.compare_outlined),
          value: _compareEnabled,
          onChanged: (value) => setState(() => _compareEnabled = value),
        ),
        if (!_compareEnabled) _buildCompareToggle(),
        if (_hasPresets()) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final button in _buildPresetButtons())
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: button,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Parameters
        Expanded(
          child: ListView(
            children: _buildParameterWidgets(),
          ),
        ),
      ],
    );
  }

  bool get _hasChanges => !mapEquals(_parameters, _initialParameters);

  void _revertChanges() {
    setState(() {
      _parameters = Map<String, dynamic>.from(_initialParameters);
    });
    _updatePreview();
  }

  /// Original / Result switch for comparing the effect against the source.
  Widget _buildCompareToggle() {
    final strings = Strings.of(context);
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(value: false, label: Text(strings.effectResultLabel)),
        ButtonSegment(value: true, label: Text(strings.original)),
      ],
      selected: {_showOriginal},
      onSelectionChanged: (value) =>
          setState(() => _showOriginal = value.first),
    );
  }

  Widget _buildPreviewCard({required double maxHeight}) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _buildPreview(),
    );
  }

  Widget _buildDesktopLayout() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Strings.of(context).preview,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildComparisonPane(original: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildComparisonPane(original: false)),
                  ],
                ),
              ),
              if (_hasPresets()) ...[
                const SizedBox(height: 16),
                Text(Strings.of(context).quickPresets,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SingleChildScrollView(
                    child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildPresetButtons()),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Strings.of(context).parameters,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Expanded(child: ListView(children: _buildParameterWidgets())),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonPane({required bool original}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key:
          ValueKey(original ? 'effect-before-preview' : 'effect-after-preview'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: original ? colors.outlineVariant : colors.primary),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(original ? Icons.image_outlined : Icons.auto_awesome,
                  size: 18,
                  color: original ? colors.onSurfaceVariant : colors.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      original
                          ? Strings.of(context).original
                          : Strings.of(context).effectResultLabel,
                      style: Theme.of(context).textTheme.titleSmall)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(child: _buildPreview(original: original)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview({bool? original}) {
    final showOriginal = original ?? _showOriginal;
    final shown = showOriginal ? widget.layerPixels : _previewPixels;
    if (shown == null && _isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shown == null) {
      return Center(child: Text(Strings.of(context).previewNotAvailable));
    }

    return AspectRatio(
      aspectRatio: widget.layerWidth / widget.layerHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: PixelPreviewPainter(
              pixels: shown,
              width: widget.layerWidth,
              height: widget.layerHeight,
            ),
          ),
          if (_isProcessing && !showOriginal)
            const Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
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
        widget.effect.type == EffectType.breathing ||
        widget.effect.type == EffectType.glowPulse ||
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
        widget.effect.type == EffectType.hologramGlitch ||
        widget.effect.type == EffectType.solarEclipse ||
        widget.effect.type == EffectType.meteorShower ||
        widget.effect.type == EffectType.autumnWind ||
        widget.effect.type == EffectType.soulWisps ||
        widget.effect.type == EffectType.abyssalTentacles ||
        widget.effect.type == EffectType.cursedChains ||
        widget.effect.type == EffectType.beamTeleport ||
        widget.effect.type == EffectType.dangerAlarm ||
        widget.effect.type == EffectType.coinFountain ||
        widget.effect.type == EffectType.magmaFissures ||
        widget.effect.type == EffectType.frostGlaze ||
        widget.effect.type == EffectType.dragonAura ||
        widget.effect.type == EffectType.cellularDungeon ||
        widget.effect.type == EffectType.gothicRosette ||
        widget.effect.type == EffectType.runicMaze ||
        widget.effect.type == EffectType.circuitBoard ||
        widget.effect.type == EffectType.deepSpaceNebula ||
        widget.effect.type == EffectType.spaceshipHull ||
        widget.effect.type == EffectType.bismuthCrystals ||
        widget.effect.type == EffectType.coralReef ||
        widget.effect.type == EffectType.basaltColumns ||
        widget.effect.type == EffectType.mountainRange ||
        widget.effect.type == EffectType.waterfallCascade ||
        widget.effect.type == EffectType.fireflySwarm ||
        widget.effect.type == EffectType.whisperingReeds ||
        widget.effect.type == EffectType.geyserVent ||
        widget.effect.type == EffectType.stalactiteDrips ||
        widget.effect.type == EffectType.woodblockUkiyoe ||
        widget.effect.type == EffectType.cyanotypePrint ||
        widget.effect.type == EffectType.linocutStamp ||
        widget.effect.type == EffectType.byzantineMosaic ||
        widget.effect.type == EffectType.chalkPastel ||
        widget.effect.type == EffectType.waxSgraffito ||
        widget.effect.type == EffectType.benDayComic ||
        widget.effect.type == EffectType.delftwareTile ||
        widget.effect.type == EffectType.thermalReceipt ||
        widget.effect.type == EffectType.lichenMoss ||
        widget.effect.type == EffectType.sporeBloom ||
        widget.effect.type == EffectType.banyanMangrove ||
        widget.effect.type == EffectType.sunbeamGodRays ||
        widget.effect.type == EffectType.dustDevil ||
        widget.effect.type == EffectType.auroraCurtains ||
        widget.effect.type == EffectType.glacialCrevasse ||
        widget.effect.type == EffectType.sandDunes ||
        widget.effect.type == EffectType.tidalRockPool ||
        widget.effect.type == EffectType.romanTravertine ||
        widget.effect.type == EffectType.kintsugiLacquer ||
        widget.effect.type == EffectType.petrifiedAgate ||
        widget.effect.type == EffectType.voronoiShatter ||
        widget.effect.type == EffectType.windAshDispersal ||
        widget.effect.type == EffectType.lateralSliceGlitch ||
        widget.effect.type == EffectType.directionalMotionBlur ||
        widget.effect.type == EffectType.radialZoomBlur ||
        widget.effect.type == EffectType.ditheredFrostedBlur ||
        widget.effect.type == EffectType.luminanceGradientMap ||
        widget.effect.type == EffectType.directionalLightRamp ||
        widget.effect.type == EffectType.silhouetteDepthBevel ||
        widget.effect.type == EffectType.actionSpeedLines ||
        widget.effect.type == EffectType.chromaticEchoDash ||
        widget.effect.type == EffectType.boosterThruster ||
        widget.effect.type == EffectType.crownSoulFire ||
        widget.effect.type == EffectType.hangingIcicles ||
        widget.effect.type == EffectType.viscousSlime ||
        widget.effect.type == EffectType.arcLightning ||
        widget.effect.type == EffectType.kiFlareAura ||
        widget.effect.type == EffectType.orbitingRunesHalo ||
        widget.effect.type == EffectType.hexagonalAegis ||
        widget.effect.type == EffectType.crystalShardReflector ||
        widget.effect.type == EffectType.gravitySingularity ||
        widget.effect.type == EffectType.stompDustImpact ||
        widget.effect.type == EffectType.waterRippleWake ||
        widget.effect.type == EffectType.sproutingBramble ||
        widget.effect.type == EffectType.abyssalTendrilMiasma ||
        widget.effect.type == EffectType.lostSoulWisps ||
        widget.effect.type == EffectType.eldritchPeepingEyes ||
        widget.effect.type == EffectType.tacticalReticle ||
        widget.effect.type == EffectType.holoScanlineGlitch ||
        widget.effect.type == EffectType.nanotechCircuit ||
        widget.effect.type == EffectType.alchemicalCircle ||
        widget.effect.type == EffectType.floatingSigils ||
        widget.effect.type == EffectType.sacredGeometryHalo ||
        widget.effect.type == EffectType.supernovaCorona ||
        widget.effect.type == EffectType.orbitingMoons ||
        widget.effect.type == EffectType.zodiacConstellation ||
        widget.effect.type == EffectType.shimmer ||
        widget.effect.type == EffectType.colorShift ||
        widget.effect.type == EffectType.outlineShine;
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
      case EffectType.breathing:
        return {
          'Classic 2-Frame Idle': {
            'frames': 2,
            'style': 'bob',
            'anchor': 'bottom',
            'depth': 1,
            'plantedRatio': 0.4,
            'chestExpand': 0,
            'easing': 'step',
            'hold': 0.0,
            'cycles': 1,
          },
          'Calm Hero': {
            'frames': 8,
            'style': 'chest',
            'anchor': 'bottom',
            'depth': 0,
            'plantedRatio': 0.35,
            'rigidRatio': 0.3,
            'chestExpand': 0,
            'easing': 'organic',
            'hold': 0.15,
            'cycles': 1,
          },
          'Heavy Brute': {
            'frames': 10,
            'style': 'chest',
            'anchor': 'bottom',
            'depth': 2,
            'plantedRatio': 0.3,
            'rigidRatio': 0.25,
            'chestExpand': 1,
            'easing': 'organic',
            'hold': 0.1,
            'cycles': 1,
          },
          'Panting / Tired': {
            'frames': 8,
            'style': 'chest',
            'anchor': 'bottom',
            'depth': 1,
            'plantedRatio': 0.4,
            'rigidRatio': 0.3,
            'chestExpand': 0,
            'easing': 'smooth',
            'hold': 0.0,
            'cycles': 2,
          },
          'Floating Spirit': {
            'frames': 12,
            'style': 'scale',
            'anchor': 'center',
            'depth': 2,
            'chestExpand': 1,
            'easing': 'smooth',
            'hold': 0.0,
            'cycles': 1,
          },
          'Hanging Bat': {
            'frames': 8,
            'style': 'chest',
            'anchor': 'top',
            'depth': 1,
            'plantedRatio': 0.2,
            'rigidRatio': 0.35,
            'chestExpand': 1,
            'easing': 'organic',
            'hold': 0.2,
            'cycles': 1,
          },
        };
      case EffectType.shimmer:
        return {
          'Diamond Glint': {
            'shimmerColor': 0xFFFFFFFF,
            'intensity': 0.9,
            'width': 6.0,
            'angle': 45.0,
            'mode': 'specular',
            'sparkles': true,
            'sparkleDensity': 0.4,
            'holdDuration': 0.25,
            'cycles': 1,
            'preserveAlpha': true,
          },
          'Golden Sheen': {
            'shimmerColor': 0xFFFFD700,
            'intensity': 0.85,
            'width': 8.0,
            'angle': 45.0,
            'mode': 'metallic',
            'sparkles': true,
            'sparkleDensity': 0.3,
            'holdDuration': 0.2,
            'cycles': 1,
            'preserveAlpha': true,
          },
          'Prismatic Hologram': {
            'shimmerColor': 0xFFFFFFFF,
            'intensity': 0.95,
            'width': 10.0,
            'angle': 60.0,
            'mode': 'rainbow',
            'sparkles': true,
            'sparkleDensity': 0.5,
            'holdDuration': 0.15,
            'cycles': 1,
            'preserveAlpha': true,
          },
          'Cyber Cyan': {
            'shimmerColor': 0xFF00E5FF,
            'intensity': 0.8,
            'width': 5.0,
            'angle': 135.0,
            'mode': 'dodge',
            'sparkles': false,
            'sparkleDensity': 0.0,
            'holdDuration': 0.3,
            'cycles': 1,
            'preserveAlpha': true,
          },
        };
      case EffectType.outlineShine:
        return {
          'Classic Black': {
            'outlineEnabled': true,
            'outlineColor': 0xFF000000,
            'outlineThickness': 1,
            'shineEnabled': true,
            'autoShineColor': true,
            'shineLighten': 0.5,
            'shineIntensity': 0.85,
            'shineDepth': 2,
            'lightAngle': 135.0,
          },
          'Glossy Sticker': {
            'outlineEnabled': true,
            'outlineColor': 0xFFFFFFFF,
            'outlineThickness': 2,
            'shineEnabled': true,
            'autoShineColor': true,
            'shineLighten': 0.7,
            'shineIntensity': 1.0,
            'shineDepth': 3,
            'glint': true,
          },
          'Flat Cartoon': {
            'outlineEnabled': true,
            'outlineColor': 0xFF000000,
            'outlineThickness': 1,
            'shineEnabled': true,
            'shineStyle': 'flat',
            'autoShineColor': true,
            'shineLighten': 0.35,
            'shineIntensity': 1.0,
            'shineDepth': 1,
            'lightAngle': 135.0,
            'glint': false,
          },
          'Bold Shine': {
            'outlineEnabled': true,
            'outlineColor': 0xFF000000,
            'outlineThickness': 1,
            'shineEnabled': true,
            'shineStyle': 'bold',
            'autoShineColor': true,
            'shineLighten': 0.45,
            'shineIntensity': 1.0,
            'shineDepth': 3,
            'lightAngle': 135.0,
          },
          'Gloss Streak': {
            'outlineEnabled': true,
            'outlineColor': 0xFF000000,
            'outlineThickness': 1,
            'shineEnabled': true,
            'shineStyle': 'gloss',
            'glossPosition': 0.3,
            'glossWidth': 2,
            'autoShineColor': true,
            'shineLighten': 0.6,
            'shineIntensity': 0.8,
            'lightAngle': 135.0,
          },
          'Outline Only': {
            'outlineEnabled': true,
            'outlineColor': 0xFF000000,
            'outlineThickness': 1,
            'shineEnabled': false,
          },
          'Shine Only': {
            'outlineEnabled': false,
            'shineEnabled': true,
            'autoShineColor': true,
            'shineLighten': 0.6,
            'shineIntensity': 0.9,
            'shineDepth': 2,
          },
        };
      case EffectType.colorShift:
        return {
          'Rainbow Cycle': {
            'shiftMode': 'cycle',
            'hueShift': 0.0,
            'saturation': 1.1,
            'brightness': 1.0,
            'channelSplit': 0.0,
            'tintAmount': 0.5,
            'preserveAlpha': true,
          },
          'Prism Split': {
            'shiftMode': 'channelSplit',
            'hueShift': 45.0,
            'saturation': 1.2,
            'brightness': 1.05,
            'channelSplit': 2.0,
            'preserveAlpha': true,
          },
          'Neon Wave': {
            'shiftMode': 'wave',
            'hueShift': 90.0,
            'saturation': 1.3,
            'brightness': 1.0,
            'waveDirection': 'diagonal',
            'waveFrequency': 2.0,
            'preserveAlpha': true,
          },
          'Retro 8-Bit': {
            'shiftMode': 'paletteStep',
            'hueShift': 60.0,
            'saturation': 1.0,
            'brightness': 1.0,
            'paletteSteps': 8,
            'preserveAlpha': true,
          },
          'Bubblegum Tint': {
            'shiftMode': 'tint',
            'tintColor': 0xFFFF4081,
            'tintAmount': 0.65,
            'saturation': 1.2,
            'brightness': 1.0,
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
      case EffectType.solarEclipse:
        return {
          'Totality Diamond Ring': {
            'coronaRadius': 0.25,
            'flareTurbulence': 0.6,
            'eclipsePhase': 0.25,
            'glowColor': 0xFFFFB300,
            'diamondRing': true,
            'preserveAlpha': true,
          },
          'Blood Moon Eclipse': {
            'coronaRadius': 0.3,
            'flareTurbulence': 0.8,
            'eclipsePhase': 0.0,
            'glowColor': 0xFFFF1744,
            'diamondRing': false,
            'preserveAlpha': true,
          },
          'Eldritch Dark Sun': {
            'coronaRadius': 0.35,
            'flareTurbulence': 0.9,
            'eclipsePhase': 0.0,
            'glowColor': 0xFF7C4DFF,
            'diamondRing': false,
            'preserveAlpha': false,
          },
          'Celestial Dawn Corona': {
            'coronaRadius': 0.22,
            'flareTurbulence': 0.4,
            'eclipsePhase': -0.2,
            'glowColor': 0xFF00E5FF,
            'diamondRing': true,
            'preserveAlpha': true,
          },
        };
      case EffectType.meteorShower:
        return {
          'Perseid Gold Shower': {
            'meteorAngle': -45.0,
            'showerDensity': 14,
            'trailLength': 15,
            'meteorSpeed': 1.8,
            'burnColor': 0xFFFFF59D,
            'burstFlashes': true,
            'preserveAlpha': true,
          },
          'Comet Neon Cyan': {
            'meteorAngle': -55.0,
            'showerDensity': 10,
            'trailLength': 18,
            'meteorSpeed': 2.2,
            'burnColor': 0xFF00E5FF,
            'burstFlashes': true,
            'preserveAlpha': false,
          },
          'Apocalyptic Firefall': {
            'meteorAngle': -40.0,
            'showerDensity': 22,
            'trailLength': 12,
            'meteorSpeed': 1.5,
            'burnColor': 0xFFFF5722,
            'burstFlashes': true,
            'preserveAlpha': true,
          },
          'Emerald Starfall': {
            'meteorAngle': -60.0,
            'showerDensity': 8,
            'trailLength': 14,
            'meteorSpeed': 1.2,
            'burnColor': 0xFF69F0AE,
            'burstFlashes': false,
            'preserveAlpha': true,
          },
        };
      case EffectType.autumnWind:
        return {
          'Kyoto Sakura Breeze': {
            'foliageType': 'sakura',
            'leafCount': 30,
            'windStrength': 1.0,
            'gustFrequency': 1.2,
            'swirlVortex': true,
            'preserveAlpha': true,
          },
          'October Maple Storm': {
            'foliageType': 'maple',
            'leafCount': 35,
            'windStrength': 2.0,
            'gustFrequency': 2.2,
            'swirlVortex': true,
            'preserveAlpha': true,
          },
          'Golden Ginkgo Spiral': {
            'foliageType': 'ginkgo',
            'leafCount': 25,
            'windStrength': 1.4,
            'gustFrequency': 1.6,
            'swirlVortex': true,
            'preserveAlpha': true,
          },
          'Breezy Forest Whispers': {
            'foliageType': 'maple',
            'leafCount': 15,
            'windStrength': 0.8,
            'gustFrequency': 0.9,
            'swirlVortex': false,
            'preserveAlpha': false,
          },
        };
      case EffectType.soulWisps:
        return {
          'Necromantic Soul Well': {
            'soulCount': 4,
            'orbitRadius': 0.38,
            'orbitSpeed': 1.2,
            'wispColor': 0xFF00E676,
            'trailLength': 9,
            'whisperJitter': 0.4,
            'preserveAlpha': true,
          },
          'Banshee Spirit Wail': {
            'soulCount': 6,
            'orbitRadius': 0.48,
            'orbitSpeed': 2.0,
            'wispColor': 0xFF00E5FF,
            'trailLength': 12,
            'whisperJitter': 0.7,
            'preserveAlpha': false,
          },
          'Shadow Nether Wisps': {
            'soulCount': 3,
            'orbitRadius': 0.30,
            'orbitSpeed': 0.8,
            'wispColor': 0xFFB388FF,
            'trailLength': 6,
            'whisperJitter': 0.25,
            'preserveAlpha': true,
          },
          'Phlegethon Soul Fire': {
            'soulCount': 5,
            'orbitRadius': 0.42,
            'orbitSpeed': 1.6,
            'wispColor': 0xFFFF5252,
            'trailLength': 10,
            'whisperJitter': 0.5,
            'preserveAlpha': true,
          },
        };
      case EffectType.abyssalTentacles:
        return {
          'Cthulhu Deep Horror': {
            'tentacleCount': 6,
            'tentacleLength': 16,
            'wriggleSpeed': 1.4,
            'eyeBlinkRate': 1.5,
            'eyeColor': 0xFFFFD600,
            'tentacleColor': 0xFF1B5E20,
            'preserveAlpha': false,
          },
          'Occult Purple Void': {
            'tentacleCount': 5,
            'tentacleLength': 14,
            'wriggleSpeed': 1.0,
            'eyeBlinkRate': 1.0,
            'eyeColor': 0xFFFF1744,
            'tentacleColor': 0xFF311B92,
            'preserveAlpha': true,
          },
          'Blood God Carcass': {
            'tentacleCount': 7,
            'tentacleLength': 18,
            'wriggleSpeed': 2.0,
            'eyeBlinkRate': 2.2,
            'eyeColor': 0xFFFFFFFF,
            'tentacleColor': 0xFFB71C1C,
            'preserveAlpha': true,
          },
          'Grave Shadow Creepers': {
            'tentacleCount': 4,
            'tentacleLength': 12,
            'wriggleSpeed': 0.7,
            'eyeBlinkRate': 0.8,
            'eyeColor': 0xFF00E676,
            'tentacleColor': 0xFF212121,
            'preserveAlpha': true,
          },
        };
      case EffectType.cursedChains:
        return {
          'Demon Binding Chains': {
            'chainCount': 3,
            'chainTightness': 1.0,
            'runeColor': 0xFFFF1744,
            'strainVibration': 0.5,
            'shatterTrigger': 0.75,
            'preserveAlpha': true,
          },
          'Astral Seal Break': {
            'chainCount': 4,
            'chainTightness': 1.2,
            'runeColor': 0xFF00E5FF,
            'strainVibration': 0.8,
            'shatterTrigger': 0.65,
            'preserveAlpha': false,
          },
          'Tartarus Nether Shackles': {
            'chainCount': 5,
            'chainTightness': 0.9,
            'runeColor': 0xFF7C4DFF,
            'strainVibration': 0.6,
            'shatterTrigger': 0.85,
            'preserveAlpha': true,
          },
          'Infernal Molten Lock': {
            'chainCount': 2,
            'chainTightness': 1.4,
            'runeColor': 0xFFFF6D00,
            'strainVibration': 0.4,
            'shatterTrigger': 0.70,
            'preserveAlpha': true,
          },
        };
      case EffectType.beamTeleport:
        return {
          'Mega Beam Landing': {
            'teleportMode': 'beamDown',
            'beamWidth': 8,
            'laserColor': 0xFF00E5FF,
            'impactDust': true,
            'preserveAlpha': false,
          },
          'Cyber Digitize Spawn': {
            'teleportMode': 'digitizeBlocks',
            'beamWidth': 4,
            'laserColor': 0xFF00E676,
            'impactDust': false,
            'preserveAlpha': true,
          },
          'Warp Column Escape': {
            'teleportMode': 'beamDown',
            'beamWidth': 12,
            'laserColor': 0xFFFFD600,
            'impactDust': true,
            'preserveAlpha': false,
          },
          'Alien Holo Transport': {
            'teleportMode': 'digitizeBlocks',
            'beamWidth': 6,
            'laserColor': 0xFFD500F9,
            'impactDust': true,
            'preserveAlpha': true,
          },
        };
      case EffectType.dangerAlarm:
        return {
          'Critical Low HP': {
            'pulseBPM': 130.0,
            'vignetteThickness': 0.5,
            'alarmColor': 0xFFFF1744,
            'monochromeDepth': 0.6,
            'doublePulse': true,
            'preserveAlpha': true,
          },
          'Nuclear Meltdown Strobe': {
            'pulseBPM': 160.0,
            'vignetteThickness': 0.7,
            'alarmColor': 0xFFFF9100,
            'monochromeDepth': 0.2,
            'doublePulse': false,
            'preserveAlpha': false,
          },
          'Horror Heartbeat Tense': {
            'pulseBPM': 85.0,
            'vignetteThickness': 0.65,
            'alarmColor': 0xFF880000,
            'monochromeDepth': 0.85,
            'doublePulse': true,
            'preserveAlpha': true,
          },
          'Stealth Detected Alert': {
            'pulseBPM': 140.0,
            'vignetteThickness': 0.35,
            'alarmColor': 0xFFFFD600,
            'monochromeDepth': 0.3,
            'doublePulse': false,
            'preserveAlpha': false,
          },
        };
      case EffectType.coinFountain:
        return {
          'Jackpot Gold Rush': {
            'itemType': 'coins',
            'particleCount': 32,
            'fountainForce': 1.4,
            'gravity': 1.0,
            'bounceFloor': true,
            'preserveAlpha': false,
          },
          'Victory Confetti Burst': {
            'itemType': 'confetti',
            'particleCount': 40,
            'fountainForce': 1.2,
            'gravity': 0.6,
            'bounceFloor': false,
            'preserveAlpha': false,
          },
          'Jeweled Treasure Vault': {
            'itemType': 'gems',
            'particleCount': 20,
            'fountainForce': 1.0,
            'gravity': 1.1,
            'bounceFloor': true,
            'preserveAlpha': true,
          },
          'Stage Clear Superstars': {
            'itemType': 'stars',
            'particleCount': 28,
            'fountainForce': 1.5,
            'gravity': 0.9,
            'bounceFloor': true,
            'preserveAlpha': true,
          },
        };
      case EffectType.magmaFissures:
        return {
          'Volcanic Berserk Core': {
            'fissureDensity': 5,
            'magmaColor': 0xFFFF3D00,
            'heatHazeDistortion': 0.8,
            'pulseSpeed': 1.5,
            'crustDarkening': 0.55,
            'preserveAlpha': true,
          },
          'Abyssal Blue Magma': {
            'fissureDensity': 4,
            'magmaColor': 0xFF00E5FF,
            'heatHazeDistortion': 0.5,
            'pulseSpeed': 1.0,
            'crustDarkening': 0.4,
            'preserveAlpha': true,
          },
          'Hellforge Smelt': {
            'fissureDensity': 6,
            'magmaColor': 0xFFFFD600,
            'heatHazeDistortion': 1.0,
            'pulseSpeed': 2.0,
            'crustDarkening': 0.7,
            'preserveAlpha': false,
          },
          'Smoldering Obsidian': {
            'fissureDensity': 3,
            'magmaColor': 0xFFFF6D00,
            'heatHazeDistortion': 0.3,
            'pulseSpeed': 0.8,
            'crustDarkening': 0.6,
            'preserveAlpha': true,
          },
        };
      case EffectType.frostGlaze:
        return {
          'Glacial Cryo Trap': {
            'crystalDensity': 6,
            'iceTint': 0xFF80D8FF,
            'frostBranching': 0.8,
            'specularShimmer': 0.7,
            'preserveAlpha': true,
          },
          'Absolute Zero Flash': {
            'crystalDensity': 8,
            'iceTint': 0xFFB3E5FC,
            'frostBranching': 0.9,
            'specularShimmer': 0.9,
            'preserveAlpha': false,
          },
          'Permafrost Rime': {
            'crystalDensity': 4,
            'iceTint': 0xFFE0F7FA,
            'frostBranching': 0.5,
            'specularShimmer': 0.4,
            'preserveAlpha': true,
          },
          'Boreal Diamond Dust': {
            'crystalDensity': 7,
            'iceTint': 0xFF00E5FF,
            'frostBranching': 0.75,
            'specularShimmer': 1.0,
            'preserveAlpha': true,
          },
        };
      case EffectType.dragonAura:
        return {
          'Supercharged Golden Saiyan': {
            'auraColor': 0xFFFFD600,
            'spikiness': 0.8,
            'riseSpeed': 1.8,
            'coreLuminance': 0.7,
            'miniArcs': true,
            'preserveAlpha': false,
          },
          'Crimson Dragon Rage': {
            'auraColor': 0xFFFF1744,
            'spikiness': 0.85,
            'riseSpeed': 2.0,
            'coreLuminance': 0.8,
            'miniArcs': true,
            'preserveAlpha': false,
          },
          'Azure God Flame': {
            'auraColor': 0xFF00E5FF,
            'spikiness': 0.6,
            'riseSpeed': 1.4,
            'coreLuminance': 0.55,
            'miniArcs': false,
            'preserveAlpha': true,
          },
          'Dark Matter Void Surge': {
            'auraColor': 0xFF7C4DFF,
            'spikiness': 0.75,
            'riseSpeed': 1.2,
            'coreLuminance': 0.65,
            'miniArcs': true,
            'preserveAlpha': true,
          },
        };
      case EffectType.cellularDungeon:
        return {
          'Classic Stone Keep': {
            'dungeonType': 'stoneDungeon',
            'roomCount': 6,
            'corridorWidth': 3,
            'wallPalette': 'granite',
            'torchPlacement': true,
            'preserveAlpha': false,
          },
          'Underdark Grotto': {
            'dungeonType': 'organicCave',
            'roomCount': 8,
            'corridorWidth': 4,
            'wallPalette': 'obsidian',
            'torchPlacement': true,
            'preserveAlpha': false,
          },
          'Catacomb of the Damned': {
            'dungeonType': 'cryptCatacombs',
            'roomCount': 5,
            'corridorWidth': 2,
            'wallPalette': 'mossy',
            'torchPlacement': true,
            'preserveAlpha': false,
          },
          'Sunken Sandstone Ruins': {
            'dungeonType': 'stoneDungeon',
            'roomCount': 4,
            'corridorWidth': 3,
            'wallPalette': 'sandstone',
            'torchPlacement': false,
            'preserveAlpha': false,
          },
        };
      case EffectType.gothicRosette:
        return {
          'Notre-Dame Rose Window': {
            'symmetryOrder': 8,
            'leadThickness': 1,
            'glassPalette': 'roseCathedral',
            'innerRings': 3,
            'sunlightShaft': 0.6,
            'preserveAlpha': false,
          },
          'Gothic Saint Sanctuary': {
            'symmetryOrder': 12,
            'leadThickness': 2,
            'glassPalette': 'jewel',
            'innerRings': 4,
            'sunlightShaft': 0.8,
            'preserveAlpha': false,
          },
          'Celestial Astral Mandala': {
            'symmetryOrder': 8,
            'leadThickness': 1,
            'glassPalette': 'celestial',
            'innerRings': 3,
            'sunlightShaft': 0.4,
            'preserveAlpha': false,
          },
          'Monochrome Crypt Oriel': {
            'symmetryOrder': 6,
            'leadThickness': 1,
            'glassPalette': 'monochrome',
            'innerRings': 2,
            'sunlightShaft': 0.3,
            'preserveAlpha': false,
          },
        };
      case EffectType.runicMaze:
        return {
          'Arcane Celtic Stele': {
            'mazeStyle': 'celticKnot',
            'grooveDepth': 0.8,
            'runePulse': true,
            'runeColor': 0xFF00E5FF,
            'weatheringNoise': 0.4,
            'preserveAlpha': false,
          },
          'Crete Labyrinth Floor': {
            'mazeStyle': 'greekMeander',
            'grooveDepth': 0.6,
            'runePulse': true,
            'runeColor': 0xFFFFD600,
            'weatheringNoise': 0.3,
            'preserveAlpha': false,
          },
          'Temple of the Sun Spiral': {
            'mazeStyle': 'aztecStepped',
            'grooveDepth': 0.9,
            'runePulse': true,
            'runeColor': 0xFFFF6D00,
            'weatheringNoise': 0.5,
            'preserveAlpha': false,
          },
          'Ancient Weathered Monolith': {
            'mazeStyle': 'celticKnot',
            'grooveDepth': 0.5,
            'runePulse': false,
            'runeColor': 0xFF00E5FF,
            'weatheringNoise': 0.7,
            'preserveAlpha': false,
          },
        };
      case EffectType.circuitBoard:
        return {
          'Cyber Emerald Mainboard': {
            'traceDensity': 6,
            'substrateColor': 'cyberEmerald',
            'solderPadRatio': 0.5,
            'activeGlowTraces': true,
            'glowColor': 0xFF00E5FF,
            'preserveAlpha': false,
          },
          'Stealth Black Nanotech': {
            'traceDensity': 8,
            'substrateColor': 'matteBlack',
            'solderPadRatio': 0.7,
            'activeGlowTraces': true,
            'glowColor': 0xFF76FF03,
            'preserveAlpha': false,
          },
          'Industrial Navy Avionics': {
            'traceDensity': 5,
            'substrateColor': 'industrialNavy',
            'solderPadRatio': 0.4,
            'activeGlowTraces': true,
            'glowColor': 0xFFFFD600,
            'preserveAlpha': false,
          },
          'Golden Cyberdeck Core': {
            'traceDensity': 7,
            'substrateColor': 'solarGold',
            'solderPadRatio': 0.6,
            'activeGlowTraces': true,
            'glowColor': 0xFFFF1744,
            'preserveAlpha': false,
          },
        };
      case EffectType.deepSpaceNebula:
        return {
          'Orion Violet Nursery': {
            'nebulaPalette': 'orionViolet',
            'fractalTurbulence': 0.6,
            'starClusterDensity': 40,
            'showGasGiant': true,
            'ringInclination': 20.0,
            'preserveAlpha': false,
          },
          'Solar Pillars of Creation': {
            'nebulaPalette': 'solarGold',
            'fractalTurbulence': 0.8,
            'starClusterDensity': 50,
            'showGasGiant': false,
            'ringInclination': 0.0,
            'preserveAlpha': false,
          },
          'Emerald Exoplanet Horizon': {
            'nebulaPalette': 'emeraldPillars',
            'fractalTurbulence': 0.5,
            'starClusterDensity': 30,
            'showGasGiant': true,
            'ringInclination': -25.0,
            'preserveAlpha': false,
          },
          'Abyssal Void & Gas Giant': {
            'nebulaPalette': 'deepVoid',
            'fractalTurbulence': 0.3,
            'starClusterDensity': 45,
            'showGasGiant': true,
            'ringInclination': 30.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.spaceshipHull:
        return {
          'Battlestar Armor Bulkhead': {
            'panelGridSize': 8,
            'greebleDensity': 0.5,
            'rivetSpacing': 3,
            'hullWeathering': 0.3,
            'hazardStripes': true,
            'preserveAlpha': false,
          },
          'Heavy Dreadnought Plating': {
            'panelGridSize': 12,
            'greebleDensity': 0.7,
            'rivetSpacing': 2,
            'hullWeathering': 0.6,
            'hazardStripes': true,
            'preserveAlpha': false,
          },
          'Sleek Interceptor Chassis': {
            'panelGridSize': 6,
            'greebleDensity': 0.3,
            'rivetSpacing': 0,
            'hullWeathering': 0.1,
            'hazardStripes': false,
            'preserveAlpha': false,
          },
          'Industrial Mining Rig': {
            'panelGridSize': 10,
            'greebleDensity': 0.8,
            'rivetSpacing': 3,
            'hullWeathering': 0.7,
            'hazardStripes': true,
            'preserveAlpha': false,
          },
        };
      case EffectType.bismuthCrystals:
        return {
          'Vivid Rainbow Hopper Geode': {
            'hopperStepCount': 6,
            'iridescencePalette': 'rainbowOxide',
            'hollowCoreRatio': 0.4,
            'specularEdge': 0.7,
            'preserveAlpha': false,
          },
          'Amethyst Opal Crystal': {
            'hopperStepCount': 8,
            'iridescencePalette': 'amethystOpal',
            'hollowCoreRatio': 0.3,
            'specularEdge': 0.8,
            'preserveAlpha': false,
          },
          'Solar Fire Bismuth Node': {
            'hopperStepCount': 5,
            'iridescencePalette': 'solarAura',
            'hollowCoreRatio': 0.5,
            'specularEdge': 0.9,
            'preserveAlpha': false,
          },
          'Peacock Cyan Mineral': {
            'hopperStepCount': 7,
            'iridescencePalette': 'peacockCyan',
            'hollowCoreRatio': 0.35,
            'specularEdge': 0.6,
            'preserveAlpha': false,
          },
        };
      case EffectType.coralReef:
        return {
          'Neon Brain Coral Maze': {
            'coralPattern': 'turingBrain',
            'bioluminescenceGlow': 0.7,
            'polypDensity': 30,
            'waterDepthTint': 'tropicalLagoon',
            'preserveAlpha': false,
          },
          'Abyssal Trench Gorgonian': {
            'coralPattern': 'branchingFan',
            'bioluminescenceGlow': 0.8,
            'polypDensity': 35,
            'waterDepthTint': 'abyssalDeep',
            'preserveAlpha': false,
          },
          'Bioluminescent Spire Colony': {
            'coralPattern': 'tubeSponge',
            'bioluminescenceGlow': 0.9,
            'polypDensity': 40,
            'waterDepthTint': 'bioluminescentTrench',
            'preserveAlpha': false,
          },
          'Sunlit Lagoon Barrier Reef': {
            'coralPattern': 'turingBrain',
            'bioluminescenceGlow': 0.3,
            'polypDensity': 15,
            'waterDepthTint': 'tropicalLagoon',
            'preserveAlpha': false,
          },
        };
      case EffectType.basaltColumns:
        return {
          'Giant\'s Causeway Coast': {
            'columnScale': 8,
            'heightVariation': 0.6,
            'hexBevel': 0.7,
            'lavaSeepage': false,
            'columnTexture': 'volcanicBasalt',
            'preserveAlpha': false,
          },
          'Molten Caldera Hex Pillars': {
            'columnScale': 8,
            'heightVariation': 0.5,
            'hexBevel': 0.6,
            'lavaSeepage': true,
            'columnTexture': 'volcanicBasalt',
            'preserveAlpha': false,
          },
          'Obsidian Mirror Terraces': {
            'columnScale': 10,
            'heightVariation': 0.4,
            'hexBevel': 0.9,
            'lavaSeepage': true,
            'columnTexture': 'obsidianGlass',
            'preserveAlpha': false,
          },
          'Ancient Mossy Sea Steppes': {
            'columnScale': 6,
            'heightVariation': 0.7,
            'hexBevel': 0.5,
            'lavaSeepage': false,
            'columnTexture': 'ancientMoss',
            'preserveAlpha': false,
          },
        };
      case EffectType.mountainRange:
        return {
          'Alpine Snow Peaks Sunset': {
            'style': 3,
            'colorScheme': 1,
            'layers': 4,
            'heightVariation': 0.65,
            'baseHeight': 0.05,
            'snowCaps': 0.45,
            'mistIntensity': 0.3,
            'atmosphericHaze': 0.45,
            'skyGradient': true,
            'sunPosition': 0.7,
            'parallaxScroll': true,
            'preserveAlpha': false,
          },
          'Mystic Blue Parallax Ridge': {
            'style': 1,
            'colorScheme': 0,
            'layers': 3,
            'heightVariation': 0.55,
            'baseHeight': 0.0,
            'snowCaps': 0.2,
            'mistIntensity': 0.25,
            'atmosphericHaze': 0.5,
            'skyGradient': true,
            'sunPosition': 0.5,
            'parallaxScroll': true,
            'preserveAlpha': false,
          },
          'Emerald Highland Valleys': {
            'style': 2,
            'colorScheme': 3,
            'layers': 3,
            'heightVariation': 0.45,
            'baseHeight': 0.0,
            'snowCaps': 0.0,
            'mistIntensity': 0.4,
            'atmosphericHaze': 0.35,
            'skyGradient': true,
            'sunPosition': 0.65,
            'parallaxScroll': true,
            'preserveAlpha': false,
          },
          'Volcanic Caldera Horizon': {
            'style': 4,
            'colorScheme': 4,
            'layers': 3,
            'heightVariation': 0.7,
            'baseHeight': 0.1,
            'snowCaps': 0.0,
            'mistIntensity': 0.35,
            'atmosphericHaze': 0.6,
            'skyGradient': true,
            'sunPosition': 0.3,
            'parallaxScroll': true,
            'preserveAlpha': false,
          },
        };
      case EffectType.waterfallCascade:
        return {
          'Alpine Glacier Torrent': {
            'flowSpeed': 2.8,
            'cascadeWidth': 0.6,
            'foamTurbulence': 0.6,
            'sprayDroplets': 40,
            'mistRisingDensity': 0.5,
            'rockTiers': 2,
            'waterPalette': 'mountainGlacier',
            'preserveAlpha': false,
          },
          'Tropical Jungle Veil': {
            'flowSpeed': 1.8,
            'cascadeWidth': 0.75,
            'foamTurbulence': 0.45,
            'sprayDroplets': 50,
            'mistRisingDensity': 0.4,
            'rockTiers': 3,
            'waterPalette': 'tropicalLagoon',
            'preserveAlpha': false,
          },
          'Ancient Temple Spillway': {
            'flowSpeed': 1.5,
            'cascadeWidth': 0.45,
            'foamTurbulence': 0.35,
            'sprayDroplets': 25,
            'mistRisingDensity': 0.3,
            'rockTiers': 1,
            'waterPalette': 'mysticArcane',
            'preserveAlpha': false,
          },
          'Canyon Rapid Cascades': {
            'flowSpeed': 3.2,
            'cascadeWidth': 0.7,
            'foamTurbulence': 0.8,
            'sprayDroplets': 60,
            'mistRisingDensity': 0.6,
            'rockTiers': 3,
            'waterPalette': 'muddyCanyon',
            'preserveAlpha': false,
          },
        };
      case EffectType.fireflySwarm:
        return {
          'Enchanted Fairy Grove': {
            'fireflyCount': 30,
            'blinkFrequency': 1.5,
            'glowRadius': 3.0,
            'swarmWanderRadius': 0.65,
            'synchronousBlink': false,
            'lightColor': 'phosphorGreen',
            'twilightTint': true,
            'preserveAlpha': false,
          },
          'Golden Dusk Meadow': {
            'fireflyCount': 25,
            'blinkFrequency': 1.2,
            'glowRadius': 2.5,
            'swarmWanderRadius': 0.55,
            'synchronousBlink': false,
            'lightColor': 'goldenAmber',
            'twilightTint': true,
            'preserveAlpha': false,
          },
          'Mystic Swamp Wisps': {
            'fireflyCount': 35,
            'blinkFrequency': 1.8,
            'glowRadius': 2.8,
            'swarmWanderRadius': 0.75,
            'synchronousBlink': true,
            'lightColor': 'spectralCyan',
            'twilightTint': true,
            'preserveAlpha': false,
          },
          'Starlit Firefly Cluster': {
            'fireflyCount': 18,
            'blinkFrequency': 2.2,
            'glowRadius': 3.5,
            'swarmWanderRadius': 0.4,
            'synchronousBlink': false,
            'lightColor': 'fairyBlue',
            'twilightTint': true,
            'preserveAlpha': false,
          },
        };
      case EffectType.whisperingReeds:
        return {
          'Serene Cattail Pond': {
            'reedDensity': 16,
            'windGustSpeed': 1.5,
            'rippleFrequency': 5,
            'reflectionShimmer': 0.6,
            'waterClarity': 0.7,
            'reedStyle': 'cattails',
            'preserveAlpha': false,
          },
          'Windblown Marsh Shoreline': {
            'reedDensity': 24,
            'windGustSpeed': 2.8,
            'rippleFrequency': 8,
            'reflectionShimmer': 0.45,
            'waterClarity': 0.5,
            'reedStyle': 'marshGrass',
            'preserveAlpha': false,
          },
          'Zen Garden Bamboo Pool': {
            'reedDensity': 10,
            'windGustSpeed': 1.0,
            'rippleFrequency': 3,
            'reflectionShimmer': 0.75,
            'waterClarity': 0.85,
            'reedStyle': 'bambooReeds',
            'preserveAlpha': false,
          },
          'Misty Twilight Lagoon': {
            'reedDensity': 18,
            'windGustSpeed': 1.2,
            'rippleFrequency': 6,
            'reflectionShimmer': 0.5,
            'waterClarity': 0.4,
            'reedStyle': 'cattails',
            'preserveAlpha': false,
          },
        };
      case EffectType.geyserVent:
        return {
          'Yellowstone Sulfur Basin': {
            'eruptionInterval': 5.0,
            'plumeHeight': 0.8,
            'bubbleBoilRate': 2.0,
            'steamDispersion': 0.6,
            'mineralPalette': 'sulfurYellow',
            'preserveAlpha': false,
          },
          'Iron Mountain Mud Pot': {
            'eruptionInterval': 4.0,
            'plumeHeight': 0.55,
            'bubbleBoilRate': 3.2,
            'steamDispersion': 0.45,
            'mineralPalette': 'ironRed',
            'preserveAlpha': false,
          },
          'Silica Sinter Thermal Spring': {
            'eruptionInterval': 7.0,
            'plumeHeight': 0.7,
            'bubbleBoilRate': 1.5,
            'steamDispersion': 0.8,
            'mineralPalette': 'silicaWhite',
            'preserveAlpha': false,
          },
          'Abyssal Obsidian Jet': {
            'eruptionInterval': 3.5,
            'plumeHeight': 0.95,
            'bubbleBoilRate': 2.5,
            'steamDispersion': 0.5,
            'mineralPalette': 'abyssalBasalt',
            'preserveAlpha': false,
          },
        };
      case EffectType.stalactiteDrips:
        return {
          'Ancient Limestone Grotto': {
            'dripRate': 1.5,
            'stalactiteDensity': 6,
            'splashImpactParticles': 8,
            'acousticRippleDecay': 0.5,
            'caveAmbiance': 'limestoneEcho',
            'preserveAlpha': false,
          },
          'Bioluminescent Deep Cavern': {
            'dripRate': 2.0,
            'stalactiteDensity': 8,
            'splashImpactParticles': 12,
            'acousticRippleDecay': 0.75,
            'caveAmbiance': 'bioluminescentCyan',
            'preserveAlpha': false,
          },
          'Amethyst Crystal Mine': {
            'dripRate': 1.2,
            'stalactiteDensity': 5,
            'splashImpactParticles': 10,
            'acousticRippleDecay': 0.6,
            'caveAmbiance': 'crystalGrotto',
            'preserveAlpha': false,
          },
          'Dungeon Crypt Cistern': {
            'dripRate': 2.5,
            'stalactiteDensity': 7,
            'splashImpactParticles': 6,
            'acousticRippleDecay': 0.4,
            'caveAmbiance': 'dungeonCrypt',
            'preserveAlpha': false,
          },
        };
      case EffectType.woodblockUkiyoe:
        return {
          'Edo Master Woodblock': {
            'keylineThickness': 1.2,
            'bokashiFade': 0.5,
            'paperGrainIntensity': 0.35,
            'pigmentPalette': 'traditionalEdo',
            'woodcutRelief': 0.4,
            'preserveAlpha': false,
          },
          'Great Wave Indigo': {
            'keylineThickness': 1.5,
            'bokashiFade': 0.7,
            'paperGrainIntensity': 0.3,
            'pigmentPalette': 'greatWaveIndigo',
            'woodcutRelief': 0.5,
            'preserveAlpha': false,
          },
          'Vermilion Sunset Over Edo': {
            'keylineThickness': 1.1,
            'bokashiFade': 0.6,
            'paperGrainIntensity': 0.4,
            'pigmentPalette': 'vermilionSunset',
            'woodcutRelief': 0.35,
            'preserveAlpha': false,
          },
          'Sumi-e Ink Brush Monochrome': {
            'keylineThickness': 1.6,
            'bokashiFade': 0.4,
            'paperGrainIntensity': 0.5,
            'pigmentPalette': 'sumiMonochrome',
            'woodcutRelief': 0.45,
            'preserveAlpha': false,
          },
        };
      case EffectType.cyanotypePrint:
        return {
          'Victorian Botanical Photogram': {
            'exposureDepth': 1.2,
            'prussianHueShift': 0.0,
            'edgeVignetteBleach': 0.45,
            'paperToothTexture': 0.4,
            'solarizationCurve': 0.3,
            'preserveAlpha': false,
          },
          'Deep Abyssal Indigo': {
            'exposureDepth': 1.8,
            'prussianHueShift': -0.15,
            'edgeVignetteBleach': 0.3,
            'paperToothTexture': 0.45,
            'solarizationCurve': 0.15,
            'preserveAlpha': false,
          },
          'Sun-Bleached Architectural Blueprint': {
            'exposureDepth': 1.0,
            'prussianHueShift': 0.1,
            'edgeVignetteBleach': 0.6,
            'paperToothTexture': 0.25,
            'solarizationCurve': 0.55,
            'preserveAlpha': false,
          },
          'Faded Antique Cyanotype': {
            'exposureDepth': 0.8,
            'prussianHueShift': 0.15,
            'edgeVignetteBleach': 0.5,
            'paperToothTexture': 0.6,
            'solarizationCurve': 0.4,
            'preserveAlpha': false,
          },
        };
      case EffectType.linocutStamp:
        return {
          'Classic Black Linocut': {
            'chiselGougeAngle': 45.0,
            'inkPressure': 1.0,
            'chatterNoise': 0.4,
            'inkColor': 'carbonBlack',
            'paperColor': 'warmWhite',
            'preserveAlpha': false,
          },
          'Punk Zine Stamp': {
            'chiselGougeAngle': 30.0,
            'inkPressure': 1.4,
            'chatterNoise': 0.65,
            'inkColor': 'carbonBlack',
            'paperColor': 'newsprintYellow',
            'preserveAlpha': false,
          },
          'Folk Art Vermilion Relief': {
            'chiselGougeAngle': 60.0,
            'inkPressure': 1.1,
            'chatterNoise': 0.3,
            'inkColor': 'vermilionRed',
            'paperColor': 'kraftPaper',
            'preserveAlpha': false,
          },
          'Midnight Prussian Woodcut': {
            'chiselGougeAngle': 45.0,
            'inkPressure': 0.9,
            'chatterNoise': 0.25,
            'inkColor': 'prussianBlue',
            'paperColor': 'warmWhite',
            'preserveAlpha': false,
          },
        };
      case EffectType.byzantineMosaic:
        return {
          'Ravenna Imperial Basilica': {
            'tesseraeSize': 5.5,
            'groutThickness': 1.0,
            'groutColor': 'charcoalBlack',
            'goldLeafRatio': 0.35,
            'tileAngleJitter': 0.5,
            'preserveAlpha': false,
          },
          'Hagia Sophia Golden Dome': {
            'tesseraeSize': 6.0,
            'groutThickness': 0.8,
            'groutColor': 'antiqueSand',
            'goldLeafRatio': 0.65,
            'tileAngleJitter': 0.4,
            'preserveAlpha': false,
          },
          'Roman Villa Terracotta Floor': {
            'tesseraeSize': 7.0,
            'groutThickness': 1.3,
            'groutColor': 'terracottaGrout',
            'goldLeafRatio': 0.05,
            'tileAngleJitter': 0.3,
            'preserveAlpha': false,
          },
          'Venetian Smalti Glass': {
            'tesseraeSize': 4.5,
            'groutThickness': 0.9,
            'groutColor': 'darkMortar',
            'goldLeafRatio': 0.25,
            'tileAngleJitter': 0.6,
            'preserveAlpha': false,
          },
        };
      case EffectType.chalkPastel:
        return {
          'Noir Charcoal Study': {
            'smudgeRadius': 3.5,
            'charcoalSoftness': 0.6,
            'paperToothRoughness': 0.5,
            'chalkPalette': 'charcoalMonochrome',
            'dustGrainDensity': 0.45,
            'preserveAlpha': false,
          },
          'Renaissance Sanguine & Sepia': {
            'smudgeRadius': 2.5,
            'charcoalSoftness': 0.45,
            'paperToothRoughness': 0.35,
            'chalkPalette': 'sanguineChalk',
            'dustGrainDensity': 0.3,
            'preserveAlpha': false,
          },
          'French Impressionist Pastel': {
            'smudgeRadius': 4.0,
            'charcoalSoftness': 0.7,
            'paperToothRoughness': 0.4,
            'chalkPalette': 'frenchPastel',
            'dustGrainDensity': 0.25,
            'preserveAlpha': false,
          },
          'Sepia Conté Sketch': {
            'smudgeRadius': 3.0,
            'charcoalSoftness': 0.5,
            'paperToothRoughness': 0.45,
            'chalkPalette': 'sepiaConte',
            'dustGrainDensity': 0.35,
            'preserveAlpha': false,
          },
        };
      case EffectType.waxSgraffito:
        return {
          'Rainbow Scratchboard': {
            'sgraffitoScratchDensity': 0.55,
            'waxThickImpasto': 0.6,
            'scratchStrokeLength': 5.0,
            'underlayerPalette': 'rainbowSpectrum',
            'waxRoughness': 0.35,
            'preserveAlpha': false,
          },
          'Neon Night Sgraffito': {
            'sgraffitoScratchDensity': 0.7,
            'waxThickImpasto': 0.5,
            'scratchStrokeLength': 4.0,
            'underlayerPalette': 'neonGlow',
            'waxRoughness': 0.3,
            'preserveAlpha': false,
          },
          'Solar Gold Etching': {
            'sgraffitoScratchDensity': 0.4,
            'waxThickImpasto': 0.45,
            'scratchStrokeLength': 6.0,
            'underlayerPalette': 'solarAmber',
            'waxRoughness': 0.25,
            'preserveAlpha': false,
          },
          'Aurora Folk Sgraffito': {
            'sgraffitoScratchDensity': 0.5,
            'waxThickImpasto': 0.65,
            'scratchStrokeLength': 5.5,
            'underlayerPalette': 'auroraBorealis',
            'waxRoughness': 0.4,
            'preserveAlpha': false,
          },
        };
      case EffectType.benDayComic:
        return {
          '1960s Silver-Age Comic': {
            'dotPitch': 4.0,
            'misregistrationShift': 1.2,
            'newsprintYellowing': 0.45,
            'cmykDotGain': 0.35,
            'paperInkBleed': 0.25,
            'preserveAlpha': false,
          },
          'Pop Art Warhol Print': {
            'dotPitch': 6.5,
            'misregistrationShift': 2.2,
            'newsprintYellowing': 0.15,
            'cmykDotGain': 0.2,
            'paperInkBleed': 0.15,
            'preserveAlpha': false,
          },
          'Vintage Newspaper Comic Strip': {
            'dotPitch': 3.5,
            'misregistrationShift': 0.8,
            'newsprintYellowing': 0.65,
            'cmykDotGain': 0.45,
            'paperInkBleed': 0.35,
            'preserveAlpha': false,
          },
          'Muted Pulp Detective': {
            'dotPitch': 4.5,
            'misregistrationShift': 1.5,
            'newsprintYellowing': 0.55,
            'cmykDotGain': 0.4,
            'paperInkBleed': 0.3,
            'preserveAlpha': false,
          },
        };
      case EffectType.delftwareTile:
        return {
          'Royal Delft Antique Tile': {
            'cobaltBleed': 0.45,
            'crazingCrackDensity': 0.35,
            'enamelGloss': 0.55,
            'tileBevelDepth': 0.45,
            'porcelainWarmth': 0.25,
            'tilePalette': 'delftClassicBlue',
            'preserveAlpha': false,
          },
          'Mediterranean Majolica': {
            'cobaltBleed': 0.35,
            'crazingCrackDensity': 0.25,
            'enamelGloss': 0.6,
            'tileBevelDepth': 0.5,
            'porcelainWarmth': 0.3,
            'tilePalette': 'majolicaPolychrome',
            'preserveAlpha': false,
          },
          'Hairline Crazed Porcelain': {
            'cobaltBleed': 0.55,
            'crazingCrackDensity': 0.75,
            'enamelGloss': 0.4,
            'tileBevelDepth': 0.35,
            'porcelainWarmth': 0.5,
            'tilePalette': 'antiqueMutedCobalt',
            'preserveAlpha': false,
          },
          'Earthenware Blue Fireplace': {
            'cobaltBleed': 0.4,
            'crazingCrackDensity': 0.3,
            'enamelGloss': 0.45,
            'tileBevelDepth': 0.6,
            'porcelainWarmth': 0.4,
            'tilePalette': 'terracottaGlaze',
            'preserveAlpha': false,
          },
        };
      case EffectType.thermalReceipt:
        return {
          'Convenience Store Receipt': {
            'pinDensity': 2.0,
            'thermalBurnStrength': 0.65,
            'paperFadeAge': 0.25,
            'feedLineJitter': 0.25,
            'creaseDistortion': 0.2,
            'receiptTheme': 'posThermalBlack',
            'preserveAlpha': false,
          },
          '9-Pin Ribbon Impact Slip': {
            'pinDensity': 2.5,
            'thermalBurnStrength': 0.7,
            'paperFadeAge': 0.15,
            'feedLineJitter': 0.4,
            'creaseDistortion': 0.15,
            'receiptTheme': 'retroDotMatrix',
            'preserveAlpha': false,
          },
          'Faded 90s Taxi Voucher': {
            'pinDensity': 2.0,
            'thermalBurnStrength': 0.45,
            'paperFadeAge': 0.7,
            'feedLineJitter': 0.35,
            'creaseDistortion': 0.55,
            'receiptTheme': 'fadedYellowReceipt',
            'preserveAlpha': false,
          },
          'Cyberpunk Evidence Stencil': {
            'pinDensity': 1.5,
            'thermalBurnStrength': 0.9,
            'paperFadeAge': 0.1,
            'feedLineJitter': 0.5,
            'creaseDistortion': 0.3,
            'receiptTheme': 'cyberpunkSurveillance',
            'preserveAlpha': false,
          },
        };
      case EffectType.lichenMoss:
        return {
          'Golden Sun Lichen (Xanthoria)': {
            'lichenCoverage': 0.55,
            'growthPattern': 'crustoseRings',
            'sporePustules': 0.45,
            'lichenPalette': 'arcticOrange',
            'edgeCreepDepth': 4.0,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Deep Forest Velvet Moss': {
            'lichenCoverage': 0.7,
            'growthPattern': 'velvetPatches',
            'sporePustules': 0.3,
            'lichenPalette': 'deepForestEmerald',
            'edgeCreepDepth': 5.0,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Creeping Alpine Shield': {
            'lichenCoverage': 0.4,
            'growthPattern': 'creepingMoss',
            'sporePustules': 0.5,
            'lichenPalette': 'alpineWhite',
            'edgeCreepDepth': 3.0,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Desert Canyon Rust': {
            'lichenCoverage': 0.5,
            'growthPattern': 'crustoseRings',
            'sporePustules': 0.4,
            'lichenPalette': 'desertRust',
            'edgeCreepDepth': 4.5,
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.sporeBloom:
        return {
          'Luminous Mycena Grove': {
            'mushroomCount': 7,
            'bioluminescenceGlow': 0.75,
            'sporeCloudDensity': 0.6,
            'capPalette': 'mycenaCyan',
            'airDriftSpeed': 1.0,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Ghost Fungus Hollow': {
            'mushroomCount': 5,
            'bioluminescenceGlow': 0.85,
            'sporeCloudDensity': 0.7,
            'capPalette': 'ghostFungusEmerald',
            'airDriftSpeed': 0.8,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Scarlet Waxcap Meadow': {
            'mushroomCount': 8,
            'bioluminescenceGlow': 0.6,
            'sporeCloudDensity': 0.45,
            'capPalette': 'scarletWaxcap',
            'airDriftSpeed': 1.2,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Amethyst Fairy Ring': {
            'mushroomCount': 6,
            'bioluminescenceGlow': 0.7,
            'sporeCloudDensity': 0.55,
            'capPalette': 'amethystDeceiver',
            'airDriftSpeed': 0.9,
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.banyanMangrove:
        return {
          'Southern Cypress Bayou': {
            'rootDensity': 8,
            'tangleTwist': 0.45,
            'waterlineTideMark': 0.65,
            'mossDrapeLength': 0.6,
            'barkShade': 'cypressGrey',
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Red Mangrove Coral Lagoon': {
            'rootDensity': 10,
            'tangleTwist': 0.6,
            'waterlineTideMark': 0.55,
            'mossDrapeLength': 0.35,
            'barkShade': 'mangroveRed',
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Ancient Banyan Temple': {
            'rootDensity': 12,
            'tangleTwist': 0.5,
            'waterlineTideMark': 0.75,
            'mossDrapeLength': 0.7,
            'barkShade': 'stranglerFig',
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Primeval Blackwater Stilt': {
            'rootDensity': 7,
            'tangleTwist': 0.35,
            'waterlineTideMark': 0.6,
            'mossDrapeLength': 0.45,
            'barkShade': 'primevalEbony',
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.sunbeamGodRays:
        return {
          'Morning Forest Clearing': {
            'rayAngle': 32.0,
            'rayIntensity': 0.7,
            'dustMoteCount': 50,
            'atmosphereTint': 'goldenDawn',
            'canopyShadowScale': 3.5,
            'decayRate': 1.0,
            'moteSpeed': 1.0,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Cathedral Nave Sanctuary': {
            'rayAngle': 15.0,
            'rayIntensity': 0.85,
            'dustMoteCount': 65,
            'atmosphereTint': 'celestialWhite',
            'canopyShadowScale': 5.0,
            'decayRate': 0.8,
            'moteSpeed': 0.7,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Jungle Canopy Haze': {
            'rayAngle': -25.0,
            'rayIntensity': 0.6,
            'dustMoteCount': 40,
            'atmosphereTint': 'mistyJungleCyan',
            'canopyShadowScale': 2.8,
            'decayRate': 1.4,
            'moteSpeed': 1.2,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Twilight Crepuscular Glory': {
            'rayAngle': 48.0,
            'rayIntensity': 0.75,
            'dustMoteCount': 35,
            'atmosphereTint': 'twilightAmber',
            'canopyShadowScale': 4.0,
            'decayRate': 1.2,
            'moteSpeed': 0.9,
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.dustDevil:
        return {
          'Sahara Desert Twister': {
            'vortexRadius': 0.32,
            'sandstormDensity': 0.75,
            'orbitSpeed': 2.2,
            'funnelWobble': 0.45,
            'dustPalette': 'saharaOchre',
            'heatMirageDistortion': 0.4,
            'groundSkirtScale': 0.55,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Mars Crimson Dust Storm': {
            'vortexRadius': 0.42,
            'sandstormDensity': 0.85,
            'orbitSpeed': 2.8,
            'funnelWobble': 0.35,
            'dustPalette': 'marsCrimson',
            'heatMirageDistortion': 0.2,
            'groundSkirtScale': 0.65,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Salt Flats Whiteout': {
            'vortexRadius': 0.25,
            'sandstormDensity': 0.6,
            'orbitSpeed': 1.8,
            'funnelWobble': 0.5,
            'dustPalette': 'saltFlatsWhite',
            'heatMirageDistortion': 0.6,
            'groundSkirtScale': 0.45,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Gobi Dune Haboob': {
            'vortexRadius': 0.48,
            'sandstormDensity': 0.8,
            'orbitSpeed': 1.5,
            'funnelWobble': 0.3,
            'dustPalette': 'gobiDune',
            'heatMirageDistortion': 0.3,
            'groundSkirtScale': 0.7,
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.auroraCurtains:
        return {
          'Arctic Midnight Emerald': {
            'curtainWaveSpeed': 1.5,
            'auroraBrightness': 0.85,
            'verticalRayDetail': 0.7,
            'curtainCount': 2,
            'auroraPalette': 'arcticEmerald',
            'starsVisibility': 0.7,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Solar Storm Geomagnetic Surge': {
            'curtainWaveSpeed': 2.2,
            'auroraBrightness': 0.95,
            'verticalRayDetail': 0.85,
            'curtainCount': 3,
            'auroraPalette': 'solarStormViolet',
            'starsVisibility': 0.5,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Celestial Azure Ribbon': {
            'curtainWaveSpeed': 1.0,
            'auroraBrightness': 0.75,
            'verticalRayDetail': 0.5,
            'curtainCount': 2,
            'auroraPalette': 'celestialAzure',
            'starsVisibility': 0.8,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Polar Rainbow Mirage': {
            'curtainWaveSpeed': 1.8,
            'auroraBrightness': 0.9,
            'verticalRayDetail': 0.65,
            'curtainCount': 3,
            'auroraPalette': 'deepAuroraRainbow',
            'starsVisibility': 0.6,
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.glacialCrevasse:
        return {
          'Perilous Alpine Serac Chasm': {
            'crevasseDepth': 0.8,
            'iceTurquoiseGlow': 0.85,
            'snowCorniceThickness': 4.0,
            'fractureFacetJitter': 0.55,
            'chasmWidth': 0.45,
            'icePalette': 'sapphireGlacier',
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Greenland Sapphire Wall': {
            'crevasseDepth': 0.9,
            'iceTurquoiseGlow': 0.95,
            'snowCorniceThickness': 5.5,
            'fractureFacetJitter': 0.35,
            'chasmWidth': 0.5,
            'icePalette': 'abyssalNavy',
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Arctic Emerald Deep Crevasse': {
            'crevasseDepth': 0.65,
            'iceTurquoiseGlow': 0.75,
            'snowCorniceThickness': 3.0,
            'fractureFacetJitter': 0.45,
            'chasmWidth': 0.35,
            'icePalette': 'emeraldArctic',
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Antarctic Twilight Pinnacle': {
            'crevasseDepth': 0.7,
            'iceTurquoiseGlow': 0.8,
            'snowCorniceThickness': 3.5,
            'fractureFacetJitter': 0.5,
            'chasmWidth': 0.4,
            'icePalette': 'antarcticRose',
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.sandDunes:
        return {
          'Namib Desert Barchan Erg': {
            'duneScale': 2.5,
            'windAngle': 22.0,
            'rippleFrequency': 5.5,
            'crestPlumeDensity': 0.65,
            'sandPalette': 'namibRed',
            'duneShadowContrast': 0.7,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Sahara Golden Sea of Dunes': {
            'duneScale': 3.2,
            'windAngle': 15.0,
            'rippleFrequency': 6.0,
            'crestPlumeDensity': 0.55,
            'sandPalette': 'saharaGold',
            'duneShadowContrast': 0.6,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'White Sands Gypsum Dunes': {
            'duneScale': 2.0,
            'windAngle': -18.0,
            'rippleFrequency': 4.5,
            'crestPlumeDensity': 0.45,
            'sandPalette': 'gypsumWhite',
            'duneShadowContrast': 0.55,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Rub\' al Khali Amber Storm': {
            'duneScale': 3.8,
            'windAngle': 30.0,
            'rippleFrequency': 7.0,
            'crestPlumeDensity': 0.85,
            'sandPalette': 'rubAlKhaliAmber',
            'duneShadowContrast': 0.75,
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.tidalRockPool:
        return {
          'Pacific Granite Tidepool': {
            'poolDepth': 0.65,
            'causticShimmer': 0.75,
            'kelpWaveSpeed': 1.4,
            'biomassColor': 'anemonePink',
            'saltRimCrust': 0.45,
            'waterClarity': 0.8,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Tropical Coral Lagoon Grotto': {
            'poolDepth': 0.55,
            'causticShimmer': 0.9,
            'kelpWaveSpeed': 1.8,
            'biomassColor': 'corallineViolet',
            'saltRimCrust': 0.35,
            'waterClarity': 0.9,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Deep Kelp Forest Basin': {
            'poolDepth': 0.85,
            'causticShimmer': 0.6,
            'kelpWaveSpeed': 1.2,
            'biomassColor': 'seaEmerald',
            'saltRimCrust': 0.25,
            'waterClarity': 0.7,
            'time': 0.0,
            'preserveAlpha': false,
          },
          'Saline Crystal Tide Basin': {
            'poolDepth': 0.5,
            'causticShimmer': 0.8,
            'kelpWaveSpeed': 1.0,
            'biomassColor': 'goldenSargassum',
            'saltRimCrust': 0.75,
            'waterClarity': 0.85,
            'time': 0.0,
            'preserveAlpha': false,
          },
        };
      case EffectType.romanTravertine:
        return {
          'Classic Colosseum Ashlar': {
            'blockScale': 7.0,
            'poreDensity': 0.6,
            'beddingBands': 0.65,
            'mortarWidth': 2.2,
            'stoneErosion': 0.5,
            'travertinePalette': 'classicIvory',
            'preserveAlpha': true,
          },
          'Tuscan Walnut Pave': {
            'blockScale': 5.0,
            'poreDensity': 0.4,
            'beddingBands': 0.8,
            'mortarWidth': 1.8,
            'stoneErosion': 0.6,
            'travertinePalette': 'tuscanyNoce',
            'preserveAlpha': true,
          },
          'Silver Vein Monolith': {
            'blockScale': 9.0,
            'poreDensity': 0.3,
            'beddingBands': 0.9,
            'mortarWidth': 1.4,
            'stoneErosion': 0.35,
            'travertinePalette': 'silverVein',
            'preserveAlpha': true,
          },
          'Pompeian Weathered Brick': {
            'blockScale': 4.0,
            'poreDensity': 0.75,
            'beddingBands': 0.5,
            'mortarWidth': 2.8,
            'stoneErosion': 0.8,
            'travertinePalette': 'pompeiiOchre',
            'preserveAlpha': true,
          },
        };
      case EffectType.kintsugiLacquer:
        return {
          'Urushi Gold Leaf': {
            'fractureDensity': 0.5,
            'goldSeamWidth': 2.2,
            'seamImpastoRelief': 0.8,
            'lacquerSheen': 0.7,
            'goldDustSpatter': 0.5,
            'kintsugiStyle': 'goldUrushi',
            'preserveAlpha': true,
          },
          'Celadon Golden Crazing': {
            'fractureDensity': 0.75,
            'goldSeamWidth': 1.6,
            'seamImpastoRelief': 0.6,
            'lacquerSheen': 0.85,
            'goldDustSpatter': 0.35,
            'kintsugiStyle': 'celadonCrackle',
            'preserveAlpha': true,
          },
          'Cinnabar Royal Seams': {
            'fractureDensity': 0.4,
            'goldSeamWidth': 3.0,
            'seamImpastoRelief': 0.9,
            'lacquerSheen': 0.65,
            'goldDustSpatter': 0.6,
            'kintsugiStyle': 'vermilionMend',
            'preserveAlpha': true,
          },
          'Slate Silver Platinum': {
            'fractureDensity': 0.6,
            'goldSeamWidth': 2.0,
            'seamImpastoRelief': 0.7,
            'lacquerSheen': 0.5,
            'goldDustSpatter': 0.4,
            'kintsugiStyle': 'silverPlatinum',
            'preserveAlpha': true,
          },
        };
      case EffectType.petrifiedAgate:
        return {
          'Carnelian Fire & Sardonyx': {
            'ringFrequency': 7.0,
            'agateBanding': 0.8,
            'druseCavityScale': 0.45,
            'mineralOxide': 0.7,
            'woodFiberGrain': 0.55,
            'agatePalette': 'carnelianFire',
            'preserveAlpha': true,
          },
          'Arizona Petrified Forest': {
            'ringFrequency': 6.0,
            'agateBanding': 0.85,
            'druseCavityScale': 0.4,
            'mineralOxide': 0.6,
            'woodFiberGrain': 0.65,
            'agatePalette': 'arizonaRainbow',
            'preserveAlpha': true,
          },
          'Blue Lace Chalcedony': {
            'ringFrequency': 8.0,
            'agateBanding': 0.65,
            'druseCavityScale': 0.5,
            'mineralOxide': 0.4,
            'woodFiberGrain': 0.5,
            'agatePalette': 'blueLace',
            'preserveAlpha': true,
          },
          'Banded Onyx Charcoal': {
            'ringFrequency': 5.0,
            'agateBanding': 0.9,
            'druseCavityScale': 0.35,
            'mineralOxide': 0.45,
            'woodFiberGrain': 0.4,
            'agatePalette': 'blackOnyx',
            'preserveAlpha': true,
          },
        };
      case EffectType.voronoiShatter:
        return {
          'Tempered Glass Shatter': {
            'impactCenterX': 0.5,
            'impactCenterY': 0.5,
            'shardCount': 24.0,
            'explosionForce': 4.0,
            'fractureGap': 1.2,
            'shardRotation': 0.25,
            'specularBevel': 0.7,
            'preserveAlpha': true,
          },
          'Heavy Impact Blast': {
            'impactCenterX': 0.2,
            'impactCenterY': 0.3,
            'shardCount': 14.0,
            'explosionForce': 8.0,
            'fractureGap': 2.2,
            'shardRotation': 0.6,
            'specularBevel': 0.4,
            'preserveAlpha': true,
          },
          'Porcelain Micro-Crackle': {
            'impactCenterX': 0.5,
            'impactCenterY': 0.5,
            'shardCount': 32.0,
            'explosionForce': 1.5,
            'fractureGap': 0.8,
            'shardRotation': 0.1,
            'specularBevel': 0.85,
            'preserveAlpha': true,
          },
          'Catastrophic Fracture': {
            'impactCenterX': 0.5,
            'impactCenterY': 0.8,
            'shardCount': 18.0,
            'explosionForce': 10.0,
            'fractureGap': 3.0,
            'shardRotation': 0.75,
            'specularBevel': 0.5,
            'preserveAlpha': true,
          },
        };
      case EffectType.windAshDispersal:
        return {
          'Volcanic Ember Ash': {
            'disperseProgress': 0.45,
            'windAngle': 25.0,
            'scatterSpread': 0.5,
            'particleDensity': 0.7,
            'driftDistance': 12.0,
            'emberGlow': 0.65,
            'ashPalette': 'volcanicAsh',
            'preserveAlpha': true,
          },
          'Desert Sand Dissolution': {
            'disperseProgress': 0.5,
            'windAngle': 0.0,
            'scatterSpread': 0.4,
            'particleDensity': 0.8,
            'driftDistance': 10.0,
            'emberGlow': 0.2,
            'ashPalette': 'desertSand',
            'preserveAlpha': true,
          },
          'Ethereal Spectral Wraith': {
            'disperseProgress': 0.6,
            'windAngle': 45.0,
            'scatterSpread': 0.7,
            'particleDensity': 0.6,
            'driftDistance': 16.0,
            'emberGlow': 0.8,
            'ashPalette': 'spiritEctoplasm',
            'preserveAlpha': true,
          },
          'Charcoal Soot Crumble': {
            'disperseProgress': 0.35,
            'windAngle': -20.0,
            'scatterSpread': 0.35,
            'particleDensity': 0.6,
            'driftDistance': 8.0,
            'emberGlow': 0.15,
            'ashPalette': 'charcoalBlack',
            'preserveAlpha': true,
          },
        };
      case EffectType.lateralSliceGlitch:
        return {
          'Subtle Scanline Jitter': {
            'sliceCount': 18.0,
            'maxShift': 3.0,
            'shiftProbability': 0.5,
            'sliceAngle': 0.0,
            'chromaticSplit': 1.2,
            'faultNoise': 0.25,
            'preserveAlpha': true,
          },
          'Heavy Digital Glitch': {
            'sliceCount': 12.0,
            'maxShift': 9.0,
            'shiftProbability': 0.8,
            'sliceAngle': 0.0,
            'chromaticSplit': 3.0,
            'faultNoise': 0.6,
            'preserveAlpha': true,
          },
          'Diagonal Shear Fault': {
            'sliceCount': 10.0,
            'maxShift': 7.0,
            'shiftProbability': 0.7,
            'sliceAngle': 15.0,
            'chromaticSplit': 2.0,
            'faultNoise': 0.4,
            'preserveAlpha': true,
          },
          'Chromatic Phase Tear': {
            'sliceCount': 24.0,
            'maxShift': 2.5,
            'shiftProbability': 0.9,
            'sliceAngle': -10.0,
            'chromaticSplit': 4.5,
            'faultNoise': 0.3,
            'preserveAlpha': true,
          },
        };
      case EffectType.directionalMotionBlur:
        return {
          'High-Speed Dash': {
            'blurLength': 12.0,
            'angle': 0.0,
            'blurProfile': 'trailing',
            'intensity': 0.85,
            'preserveAlpha': true,
          },
          'Sword Slash Arc': {
            'blurLength': 8.0,
            'angle': 45.0,
            'blurProfile': 'trailing',
            'intensity': 0.8,
            'preserveAlpha': true,
          },
          'Vertical Plunge': {
            'blurLength': 14.0,
            'angle': 90.0,
            'blurProfile': 'trailing',
            'intensity': 0.9,
            'preserveAlpha': true,
          },
          'Symmetric Vibration': {
            'blurLength': 5.0,
            'angle': 0.0,
            'blurProfile': 'symmetric',
            'intensity': 0.65,
            'preserveAlpha': true,
          },
        };
      case EffectType.radialZoomBlur:
        return {
          'Explosive Warp': {
            'focalCenterX': 0.5,
            'focalCenterY': 0.5,
            'zoomStrength': 0.7,
            'deadzoneRadius': 0.1,
            'blurDirection': 'zoomOut',
            'sampleCount': 14.0,
            'preserveAlpha': true,
          },
          'Impact Focus': {
            'focalCenterX': 0.5,
            'focalCenterY': 0.5,
            'zoomStrength': 0.4,
            'deadzoneRadius': 0.2,
            'blurDirection': 'zoomOut',
            'sampleCount': 10.0,
            'preserveAlpha': true,
          },
          'Inward Vortex': {
            'focalCenterX': 0.5,
            'focalCenterY': 0.5,
            'zoomStrength': 0.6,
            'deadzoneRadius': 0.08,
            'blurDirection': 'zoomIn',
            'sampleCount': 12.0,
            'preserveAlpha': true,
          },
          'Subtle Speed Vignette': {
            'focalCenterX': 0.5,
            'focalCenterY': 0.5,
            'zoomStrength': 0.25,
            'deadzoneRadius': 0.25,
            'blurDirection': 'zoomOut',
            'sampleCount': 8.0,
            'preserveAlpha': true,
          },
        };
      case EffectType.ditheredFrostedBlur:
        return {
          'Bayer 4x4 Diffusion': {
            'diffusionRadius': 3.5,
            'ditherPattern': 'bayer4x4',
            'colorQuantization': 8.0,
            'intensity': 0.8,
            'preserveAlpha': true,
          },
          'Stochastic Frosted Glass': {
            'diffusionRadius': 4.0,
            'ditherPattern': 'stochasticNoise',
            'colorQuantization': 12.0,
            'intensity': 0.75,
            'preserveAlpha': true,
          },
          'Diagonal Wax Rubbing': {
            'diffusionRadius': 3.0,
            'ditherPattern': 'crosshatch',
            'colorQuantization': 6.0,
            'intensity': 0.85,
            'preserveAlpha': true,
          },
          'Subtle Halftone Stipple': {
            'diffusionRadius': 2.0,
            'ditherPattern': 'bayer4x4',
            'colorQuantization': 16.0,
            'intensity': 0.6,
            'preserveAlpha': true,
          },
        };
      case EffectType.luminanceGradientMap:
        return {
          'Cyberpunk Neon Glow': {
            'palette': 'cyberpunkNeon',
            'contrastBoost': 1.2,
            'ditherBands': true,
            'blendMode': 'replace',
            'blendStrength': 1.0,
            'preserveAlpha': true,
          },
          'Game Boy Retro': {
            'palette': 'gameboyClassic',
            'contrastBoost': 1.0,
            'ditherBands': true,
            'blendMode': 'replace',
            'blendStrength': 1.0,
            'preserveAlpha': true,
          },
          'Thermal Heat Vision': {
            'palette': 'heatVision',
            'contrastBoost': 1.3,
            'ditherBands': true,
            'blendMode': 'replace',
            'blendStrength': 1.0,
            'preserveAlpha': true,
          },
          'Film Noir Monochrome': {
            'palette': 'monochromeNoir',
            'contrastBoost': 1.1,
            'ditherBands': false,
            'blendMode': 'replace',
            'blendStrength': 1.0,
            'preserveAlpha': true,
          },
        };
      case EffectType.directionalLightRamp:
        return {
          'Sunlight & Lava Bounce': {
            'lightAngle': 270.0,
            'primaryLightColor': 0xFFFFE082,
            'secondaryLightColor': 0xFFFF3D00,
            'rampSpread': 1.1,
            'rampOffset': 0.0,
            'lightingBlend': 'overlay',
            'intensity': 0.85,
            'preserveAlpha': true,
          },
          'Moonlight & Campfire': {
            'lightAngle': 290.0,
            'primaryLightColor': 0xFF80D8FF,
            'secondaryLightColor': 0xFFFF6E40,
            'rampSpread': 1.3,
            'rampOffset': 0.1,
            'lightingBlend': 'softLight',
            'intensity': 0.8,
            'preserveAlpha': true,
          },
          'Top-Down Key Light': {
            'lightAngle': 270.0,
            'primaryLightColor': 0xFFFFFFFF,
            'secondaryLightColor': 0xFF212121,
            'rampSpread': 0.9,
            'rampOffset': 0.0,
            'lightingBlend': 'multiply',
            'intensity': 0.75,
            'preserveAlpha': true,
          },
          'Sunset Golden Hour': {
            'lightAngle': 240.0,
            'primaryLightColor': 0xFFFFAB40,
            'secondaryLightColor': 0xFF7C4DFF,
            'rampSpread': 1.2,
            'rampOffset': 0.0,
            'lightingBlend': 'overlay',
            'intensity': 0.75,
            'preserveAlpha': true,
          },
        };
      case EffectType.silhouetteDepthBevel:
        return {
          'Smooth Cushion Bevel': {
            'bevelDepth': 3.5,
            'lightAngle': 315.0,
            'bevelProfile': 'smoothCurved',
            'specularIntensity': 0.7,
            'ambientOcclusion': 0.55,
            'highlightTint': 0xFFFFFFFF,
            'preserveAlpha': true,
          },
          'Chiseled Facet 45°': {
            'bevelDepth': 3.0,
            'lightAngle': 315.0,
            'bevelProfile': 'chiseled',
            'specularIntensity': 0.8,
            'ambientOcclusion': 0.65,
            'highlightTint': 0xFFFFFFFF,
            'preserveAlpha': true,
          },
          'Embossed Plateau': {
            'bevelDepth': 4.5,
            'lightAngle': 315.0,
            'bevelProfile': 'embossed',
            'specularIntensity': 0.6,
            'ambientOcclusion': 0.5,
            'highlightTint': 0xFFFFFFFF,
            'preserveAlpha': true,
          },
          'Golden Specular Edge': {
            'bevelDepth': 2.5,
            'lightAngle': 45.0,
            'bevelProfile': 'chiseled',
            'specularIntensity': 0.85,
            'ambientOcclusion': 0.5,
            'highlightTint': 0xFFFFD700,
            'preserveAlpha': true,
          },
        };
      case EffectType.actionSpeedLines:
        return {
          'Manga Dash Right': {
            'motionAngle': 0.0,
            'lineLength': 28.0,
            'lineDensity': 0.65,
            'strokeWidth': 1.5,
            'taperFalloff': 1.0,
            'strokeColor': 0xFFFFFFFF,
            'speedDust': true,
            'behindOnly': true,
          },
          'Katana Slash Up': {
            'motionAngle': 270.0,
            'lineLength': 36.0,
            'lineDensity': 0.8,
            'strokeWidth': 2.0,
            'taperFalloff': 1.2,
            'strokeColor': 0xFFE0F7FA,
            'speedDust': true,
            'behindOnly': true,
          },
          'Cyber Hyperdrive': {
            'motionAngle': 0.0,
            'lineLength': 42.0,
            'lineDensity': 0.85,
            'strokeWidth': 1.8,
            'taperFalloff': 0.8,
            'strokeColor': 0xFF00E5FF,
            'speedDust': true,
            'behindOnly': true,
          },
          'Shadow Ink Burst': {
            'motionAngle': 180.0,
            'lineLength': 20.0,
            'lineDensity': 0.5,
            'strokeWidth': 2.2,
            'taperFalloff': 1.5,
            'strokeColor': 0xFF212121,
            'speedDust': false,
            'behindOnly': true,
          },
        };
      case EffectType.chromaticEchoDash:
        return {
          'Cyber RGB Dash': {
            'motionAngle': 0.0,
            'echoCount': 3.0,
            'trailDistance': 14.0,
            'colorMode': 'chromaticRGB',
            'glowColor': 0xFF00E5FF,
            'ditherFade': true,
            'behindOnly': true,
          },
          'Phantom Mirage': {
            'motionAngle': 180.0,
            'echoCount': 4.0,
            'trailDistance': 18.0,
            'colorMode': 'sourceAlpha',
            'glowColor': 0xFFFFFFFF,
            'ditherFade': true,
            'behindOnly': true,
          },
          'Spectral Astral Projection': {
            'motionAngle': 270.0,
            'echoCount': 5.0,
            'trailDistance': 24.0,
            'colorMode': 'spectralGlow',
            'glowColor': 0xFFE040FB,
            'ditherFade': true,
            'behindOnly': true,
          },
          'Supersonic Micro-Trail': {
            'motionAngle': 0.0,
            'echoCount': 2.0,
            'trailDistance': 6.0,
            'colorMode': 'spectralGlow',
            'glowColor': 0xFF00E5FF,
            'ditherFade': false,
            'behindOnly': true,
          },
        };
      case EffectType.boosterThruster:
        return {
          'Kerosene Rocket Liftoff': {
            'thrustAngle': 90.0,
            'flameLength': 28.0,
            'plumeWidth': 0.8,
            'shockDiamonds': true,
            'exhaustPalette': 'rocketOrange',
            'smokeBillow': 0.6,
            'behindOnly': true,
          },
          'Ion Plasma Thruster': {
            'thrustAngle': 180.0,
            'flameLength': 32.0,
            'plumeWidth': 0.6,
            'shockDiamonds': true,
            'exhaustPalette': 'plasmaBlue',
            'smokeBillow': 0.2,
            'behindOnly': true,
          },
          'Hyperdrive Warp Jet': {
            'thrustAngle': 180.0,
            'flameLength': 40.0,
            'plumeWidth': 1.1,
            'shockDiamonds': true,
            'exhaustPalette': 'cyberViolet',
            'smokeBillow': 0.4,
            'behindOnly': true,
          },
          'Toxic Acid Booster': {
            'thrustAngle': 90.0,
            'flameLength': 22.0,
            'plumeWidth': 0.9,
            'shockDiamonds': false,
            'exhaustPalette': 'toxicGreen',
            'smokeBillow': 0.75,
            'behindOnly': true,
          },
        };
      case EffectType.crownSoulFire:
        return {
          'Hellfire Crown': {
            'fireHeight': 14.0,
            'flameTurbulence': 0.6,
            'firePalette': 'hellfireCrimson',
            'emberRate': 0.5,
            'anchorMode': 'topEdgesOnly',
            'behindOnly': false,
          },
          'Soulfire Blade Aura': {
            'fireHeight': 10.0,
            'flameTurbulence': 0.4,
            'firePalette': 'soulBlue',
            'emberRate': 0.3,
            'anchorMode': 'fullSilhouette',
            'behindOnly': false,
          },
          'Holy Halo Radiance': {
            'fireHeight': 8.0,
            'flameTurbulence': 0.3,
            'firePalette': 'holyGold',
            'emberRate': 0.25,
            'anchorMode': 'topEdgesOnly',
            'behindOnly': false,
          },
          'Necrotic Curse': {
            'fireHeight': 16.0,
            'flameTurbulence': 0.7,
            'firePalette': 'necroGreen',
            'emberRate': 0.6,
            'anchorMode': 'fullSilhouette',
            'behindOnly': false,
          },
        };
      case EffectType.hangingIcicles:
        return {
          'Glacial Freeze & Stalactites': {
            'frostCoverage': 0.75,
            'icicleLength': 14.0,
            'iceOpacity': 0.9,
            'crystalPalette': 'arcticCyan',
            'drippingDrops': true,
            'glintSparkles': true,
          },
          'Rime & Frozen Needle Drops': {
            'frostCoverage': 0.5,
            'icicleLength': 8.0,
            'iceOpacity': 0.8,
            'crystalPalette': 'frozenLilac',
            'drippingDrops': true,
            'glintSparkles': true,
          },
          'Deep Navy Frostbite': {
            'frostCoverage': 0.65,
            'icicleLength': 16.0,
            'iceOpacity': 0.95,
            'crystalPalette': 'glacialNavy',
            'drippingDrops': false,
            'glintSparkles': true,
          },
          'Delicate Hoarfrost Edge': {
            'frostCoverage': 0.4,
            'icicleLength': 5.0,
            'iceOpacity': 0.75,
            'crystalPalette': 'arcticCyan',
            'drippingDrops': false,
            'glintSparkles': false,
          },
        };
      case EffectType.viscousSlime:
        return {
          'Toxic Acid Ooze': {
            'slimeViscosity': 0.6,
            'dripFrequency': 0.55,
            'slimeHeight': 4.0,
            'slimePalette': 'toxicLime',
            'specularGloss': 0.85,
            'hangDripLength': 10.0,
          },
          'Eldritch Amethyst Goo': {
            'slimeViscosity': 0.8,
            'dripFrequency': 0.4,
            'slimeHeight': 5.0,
            'slimePalette': 'eldritchPurple',
            'specularGloss': 0.8,
            'hangDripLength': 12.0,
          },
          'Molten Magma Slag': {
            'slimeViscosity': 0.5,
            'dripFrequency': 0.65,
            'slimeHeight': 3.0,
            'slimePalette': 'magmaOrange',
            'specularGloss': 0.9,
            'hangDripLength': 8.0,
          },
          'Viscous Fresh Blood': {
            'slimeViscosity': 0.7,
            'dripFrequency': 0.45,
            'slimeHeight': 3.5,
            'slimePalette': 'bloodCrimson',
            'specularGloss': 0.9,
            'hangDripLength': 9.0,
          },
        };
      case EffectType.arcLightning:
        return {
          'Tesla Overcharge': {
            'arcDensity': 0.8,
            'boltThickness': 1.5,
            'branchingProbability': 0.5,
            'electricPalette': 'teslaCyan',
            'crackleJitter': 1.8,
            'behindOnly': false,
          },
          'Golden Thunderstorm': {
            'arcDensity': 0.65,
            'boltThickness': 2.0,
            'branchingProbability': 0.35,
            'electricPalette': 'goldenThunder',
            'crackleJitter': 2.0,
            'behindOnly': false,
          },
          'Dark Plasma Discharge': {
            'arcDensity': 0.75,
            'boltThickness': 1.75,
            'branchingProbability': 0.4,
            'electricPalette': 'darkPlasma',
            'crackleJitter': 1.6,
            'behindOnly': false,
          },
          'Micro Static Field': {
            'arcDensity': 0.4,
            'boltThickness': 1.0,
            'branchingProbability': 0.15,
            'electricPalette': 'jadeVolt',
            'crackleJitter': 1.0,
            'behindOnly': false,
          },
        };
      case EffectType.kiFlareAura:
        return {
          'Super Saiyan Ascended': {
            'auraRadius': 8.0,
            'flameSway': 0.7,
            'auraPalette': 'superSaiyanGold',
            'innerRimIllumination': 0.65,
            'energyMotes': true,
            'behindOnly': false,
          },
          'Kaioken x20 Burst': {
            'auraRadius': 10.0,
            'flameSway': 0.85,
            'auraPalette': 'dragonRageRed',
            'innerRimIllumination': 0.7,
            'energyMotes': true,
            'behindOnly': false,
          },
          'Ultra Instinct Platinum': {
            'auraRadius': 6.0,
            'flameSway': 0.45,
            'auraPalette': 'ultraInstinctSilver',
            'innerRimIllumination': 0.5,
            'energyMotes': true,
            'behindOnly': false,
          },
          'Spirit Ki Godhood': {
            'auraRadius': 7.5,
            'flameSway': 0.6,
            'auraPalette': 'spiritCyan',
            'innerRimIllumination': 0.8,
            'energyMotes': true,
            'behindOnly': false,
          },
        };
      case EffectType.orbitingRunesHalo:
        return {
          'Elder Arcane Runes': {
            'orbitRadiusX': 14.0,
            'orbitRadiusY': 6.0,
            'runeCount': 5.0,
            'haloStyle': 'elderRunes',
            'runePalette': 'arcaneAmethyst',
            'heightAboveSprite': 6.0,
          },
          'Angelic Seraph Halo': {
            'orbitRadiusX': 12.0,
            'orbitRadiusY': 5.0,
            'runeCount': 4.0,
            'haloStyle': 'angelicRing',
            'runePalette': 'celestialGold',
            'heightAboveSprite': 8.0,
          },
          'Magus Mana Orbs': {
            'orbitRadiusX': 16.0,
            'orbitRadiusY': 7.0,
            'runeCount': 4.0,
            'haloStyle': 'magusOrbs',
            'runePalette': 'etherCyan',
            'heightAboveSprite': 5.0,
          },
          'Forbidden Blood Sigils': {
            'orbitRadiusX': 18.0,
            'orbitRadiusY': 7.5,
            'runeCount': 6.0,
            'haloStyle': 'elderRunes',
            'runePalette': 'bloodRune',
            'heightAboveSprite': 7.0,
          },
        };
      case EffectType.hexagonalAegis:
        return {
          'Holo-Cyan Matrix': {
            'barrierOffset': 3.0,
            'hexRadius': 4.0,
            'shieldCoverage': 'fullBubble',
            'barrierPalette': 'holoCyan',
            'innerDither': true,
            'edgeGlow': 0.8,
            'behindOnly': false,
          },
          'Overwatch Heavy Shield': {
            'barrierOffset': 4.0,
            'hexRadius': 5.0,
            'shieldCoverage': 'forwardRight',
            'barrierPalette': 'neonOrange',
            'innerDither': true,
            'edgeGlow': 0.9,
            'behindOnly': false,
          },
          'Terminal Green Aegis': {
            'barrierOffset': 2.5,
            'hexRadius': 3.5,
            'shieldCoverage': 'fullBubble',
            'barrierPalette': 'matrixGreen',
            'innerDither': false,
            'edgeGlow': 0.7,
            'behindOnly': false,
          },
          'Void Warp Barrier': {
            'barrierOffset': 3.5,
            'hexRadius': 4.5,
            'shieldCoverage': 'overheadDome',
            'barrierPalette': 'voidPurple',
            'innerDither': true,
            'edgeGlow': 0.85,
            'behindOnly': false,
          },
        };
      case EffectType.crystalShardReflector:
        return {
          'Prismatic Diamond Crown': {
            'shardCount': 8,
            'orbitDistance': 4.5,
            'shardSize': 4.5,
            'crystalPalette': 'prismaticDiamond',
            'sparkleGlints': true,
            'behindOnly': false,
          },
          'Blood Ruby Defense': {
            'shardCount': 6,
            'orbitDistance': 3.5,
            'shardSize': 4.0,
            'crystalPalette': 'bloodRuby',
            'sparkleGlints': true,
            'behindOnly': false,
          },
          'Abyssal Void Shards': {
            'shardCount': 10,
            'orbitDistance': 5.0,
            'shardSize': 3.5,
            'crystalPalette': 'abyssalObsidian',
            'sparkleGlints': true,
            'behindOnly': false,
          },
          'Sacred Sun Topaz': {
            'shardCount': 7,
            'orbitDistance': 4.0,
            'shardSize': 5.0,
            'crystalPalette': 'sacredTopaz',
            'sparkleGlints': false,
            'behindOnly': false,
          },
        };
      case EffectType.gravitySingularity:
        return {
          'Cosmic Event Horizon': {
            'singularityRadius': 4.5,
            'diskRadius': 12.0,
            'swirlTwist': 2.5,
            'singularityPalette': 'cosmicVoid',
            'distortionStrength': 0.6,
            'behindOnly': false,
          },
          'Solar Flare Accretion': {
            'singularityRadius': 5.0,
            'diskRadius': 14.0,
            'swirlTwist': 3.0,
            'singularityPalette': 'solarAccretion',
            'distortionStrength': 0.4,
            'behindOnly': false,
          },
          'Neutron Star Well': {
            'singularityRadius': 3.5,
            'diskRadius': 9.0,
            'swirlTwist': 4.0,
            'singularityPalette': 'neutronCyan',
            'distortionStrength': 0.8,
            'behindOnly': false,
          },
          'Antimatter Singularity': {
            'singularityRadius': 4.0,
            'diskRadius': 11.0,
            'swirlTwist': 2.0,
            'singularityPalette': 'antimatterNegative',
            'distortionStrength': 0.5,
            'behindOnly': false,
          },
        };
      case EffectType.stompDustImpact:
        return {
          'Desert Sand Skid': {
            'plumeWidth': 14.0,
            'plumeHeight': 6.0,
            'dustDensity': 0.75,
            'groundCracks': true,
            'dustPalette': 'desertSand',
            'behindOnly': false,
          },
          'Volcanic Heavy Slam': {
            'plumeWidth': 18.0,
            'plumeHeight': 9.0,
            'dustDensity': 0.9,
            'groundCracks': true,
            'dustPalette': 'volcanicAsh',
            'behindOnly': false,
          },
          'Dungeon Footsteps': {
            'plumeWidth': 8.0,
            'plumeHeight': 4.5,
            'dustDensity': 0.6,
            'groundCracks': false,
            'dustPalette': 'dungeonStone',
            'behindOnly': false,
          },
          'Toxic Spore Eruption': {
            'plumeWidth': 16.0,
            'plumeHeight': 8.0,
            'dustDensity': 0.85,
            'groundCracks': true,
            'dustPalette': 'toxicSpore',
            'behindOnly': false,
          },
        };
      case EffectType.waterRippleWake:
        return {
          'Clear Spring Pool': {
            'rippleRadius': 14.0,
            'waveCount': 3,
            'reflectionDepth': 5.0,
            'waterPalette': 'springWater',
            'behindOnly': false,
          },
          'Murky Toxic Bog': {
            'rippleRadius': 12.0,
            'waveCount': 2,
            'reflectionDepth': 3.0,
            'waterPalette': 'toxicSwamp',
            'behindOnly': false,
          },
          'Blood Ritual Basin': {
            'rippleRadius': 16.0,
            'waveCount': 4,
            'reflectionDepth': 6.0,
            'waterPalette': 'bloodPool',
            'behindOnly': false,
          },
          'Cosmic Starlight Puddle': {
            'rippleRadius': 18.0,
            'waveCount': 3,
            'reflectionDepth': 4.0,
            'waterPalette': 'abyssalVoid',
            'behindOnly': false,
          },
        };
      case EffectType.sproutingBramble:
        return {
          'Enchanted Meadow Bloom': {
            'growthSpread': 12.0,
            'brambleHeight': 6.0,
            'flowerDensity': 0.7,
            'naturePalette': 'enchantedMeadow',
            'behindOnly': false,
          },
          'Cursed Wither Thorns': {
            'growthSpread': 10.0,
            'brambleHeight': 7.0,
            'flowerDensity': 0.3,
            'naturePalette': 'witherThorn',
            'behindOnly': false,
          },
          'Autumn Forest Undergrowth': {
            'growthSpread': 14.0,
            'brambleHeight': 5.0,
            'flowerDensity': 0.5,
            'naturePalette': 'autumnFoliage',
            'behindOnly': false,
          },
          'Celestial Star Flora': {
            'growthSpread': 16.0,
            'brambleHeight': 8.0,
            'flowerDensity': 0.8,
            'naturePalette': 'celestialFlora',
            'behindOnly': false,
          },
        };
      case EffectType.abyssalTendrilMiasma:
        return {
          'Void Matter Symbiote': {
            'tendrilCount': 6,
            'reachLength': 12.0,
            'curlTwist': 1.75,
            'bubbleMotes': true,
            'inkPalette': 'voidBlack',
            'behindOnly': false,
          },
          'Vampiric Blood Tendrils': {
            'tendrilCount': 8,
            'reachLength': 14.0,
            'curlTwist': 2.0,
            'bubbleMotes': true,
            'inkPalette': 'vampireBlood',
            'behindOnly': false,
          },
          'Necrotic Bile Sludge': {
            'tendrilCount': 5,
            'reachLength': 10.0,
            'curlTwist': 1.25,
            'bubbleMotes': true,
            'inkPalette': 'toxicBile',
            'behindOnly': false,
          },
          'Cursed Golden Siphon': {
            'tendrilCount': 7,
            'reachLength': 11.0,
            'curlTwist': 1.5,
            'bubbleMotes': false,
            'inkPalette': 'curseGold',
            'behindOnly': false,
          },
        };
      case EffectType.lostSoulWisps:
        return {
          'Ethereal Spirit Familiar': {
            'soulCount': 4,
            'wispDistance': 9.0,
            'tailLength': 7.0,
            'spectralPalette': 'ghastlyCyan',
            'eyeGlow': true,
            'behindOnly': false,
          },
          'Banshee Wail Wisps': {
            'soulCount': 3,
            'wispDistance': 11.0,
            'tailLength': 8.0,
            'spectralPalette': 'bansheeGreen',
            'eyeGlow': true,
            'behindOnly': false,
          },
          'Tormented Souls': {
            'soulCount': 6,
            'wispDistance': 8.0,
            'tailLength': 5.0,
            'spectralPalette': 'tormentCrimson',
            'eyeGlow': true,
            'behindOnly': false,
          },
          'Nether Phantom Veil': {
            'soulCount': 5,
            'wispDistance': 10.0,
            'tailLength': 6.0,
            'spectralPalette': 'phantomPurple',
            'eyeGlow': false,
            'behindOnly': false,
          },
        };
      case EffectType.eldritchPeepingEyes:
        return {
          'Crimson Curse Gaze': {
            'eyeCount': 5,
            'pupilType': 'slitCat',
            'eyeSize': 4.5,
            'veinGlow': true,
            'eyePalette': 'crimsonCurse',
            'behindOnly': false,
          },
          'Void Watcher Slits': {
            'eyeCount': 7,
            'pupilType': 'roundVoid',
            'eyeSize': 4.0,
            'veinGlow': true,
            'eyePalette': 'voidWatcher',
            'behindOnly': false,
          },
          'Golden Omen Eyes': {
            'eyeCount': 4,
            'pupilType': 'demonicCross',
            'eyeSize': 5.0,
            'veinGlow': false,
            'eyePalette': 'goldenOmen',
            'behindOnly': false,
          },
          'Emerald Madness Crosses': {
            'eyeCount': 6,
            'pupilType': 'demonicCross',
            'eyeSize': 4.5,
            'veinGlow': true,
            'eyePalette': 'emeraldMadness',
            'behindOnly': false,
          },
        };
      case EffectType.tacticalReticle:
        return {
          'Military Lock-On': {
            'bracketPadding': 2.0,
            'bracketLength': 7.0,
            'showCrosshairs': true,
            'deadzoneRadius': 5.0,
            'showTelemetry': true,
            'reticlePalette': 'targetingRed',
            'behindOnly': false,
          },
          'Cyberpunk HUD': {
            'bracketPadding': 4.0,
            'bracketLength': 8.0,
            'showCrosshairs': true,
            'deadzoneRadius': 7.0,
            'showTelemetry': true,
            'reticlePalette': 'cyberCyan',
            'behindOnly': false,
          },
          'Amber Tracking Frame': {
            'bracketPadding': 3.0,
            'bracketLength': 6.0,
            'showCrosshairs': false,
            'deadzoneRadius': 6.0,
            'showTelemetry': true,
            'reticlePalette': 'dangerAmber',
            'behindOnly': false,
          },
          'Matrix Scan Target': {
            'bracketPadding': 1.0,
            'bracketLength': 5.0,
            'showCrosshairs': true,
            'deadzoneRadius': 8.0,
            'showTelemetry': false,
            'reticlePalette': 'matrixGreen',
            'behindOnly': false,
          },
        };
      case EffectType.holoScanlineGlitch:
        return {
          'Faulty Hologram': {
            'scanlineGap': 2.0,
            'scanlineOpacity': 0.35,
            'glitchIntensity': 3.0,
            'chromaticSplit': true,
            'holoPalette': 'holoCyan',
            'preserveAlpha': true,
          },
          'Corrupted Holo-Deck': {
            'scanlineGap': 3.0,
            'scanlineOpacity': 0.5,
            'glitchIntensity': 6.0,
            'chromaticSplit': true,
            'holoPalette': 'vividMagenta',
            'preserveAlpha': true,
          },
          'Amber CRT Monitor': {
            'scanlineGap': 2.0,
            'scanlineOpacity': 0.4,
            'glitchIntensity': 1.0,
            'chromaticSplit': false,
            'holoPalette': 'terminalAmber',
            'preserveAlpha': true,
          },
          'Emerald Matrix Stream': {
            'scanlineGap': 4.0,
            'scanlineOpacity': 0.3,
            'glitchIntensity': 2.0,
            'chromaticSplit': true,
            'holoPalette': 'ghostEmerald',
            'preserveAlpha': true,
          },
        };
      case EffectType.nanotechCircuit:
        return {
          'Subdermal Cyberware': {
            'traceDensity': 6.0,
            'angleMode': 'angled45',
            'showPads': true,
            'dataPackets': true,
            'circuitPalette': 'neonCyanPCB',
            'behindOnly': false,
          },
          'Gold Motherboard Bus': {
            'traceDensity': 8.0,
            'angleMode': 'orthogonal90',
            'showPads': true,
            'dataPackets': false,
            'circuitPalette': 'goldTraces',
            'behindOnly': false,
          },
          'Overclocked Overheat': {
            'traceDensity': 7.0,
            'angleMode': 'bothMixed',
            'showPads': true,
            'dataPackets': true,
            'circuitPalette': 'crimsonOverclock',
            'behindOnly': false,
          },
          'Quantum Processor': {
            'traceDensity': 9.0,
            'angleMode': 'bothMixed',
            'showPads': true,
            'dataPackets': true,
            'circuitPalette': 'quantumPurple',
            'behindOnly': false,
          },
        };
      case EffectType.alchemicalCircle:
        return {
          "Philosopher's Hexagram": {
            'circleRadius': 13.0,
            'polygonSides': 'hexagram6',
            'spokeRays': true,
            'outerRings': true,
            'alchemyPalette': 'hermeticGold',
            'behindOnly': false,
          },
          "Solomon's Pentacle": {
            'circleRadius': 11.0,
            'polygonSides': 'pentagram5',
            'spokeRays': true,
            'outerRings': true,
            'alchemyPalette': 'bloodPhilosopher',
            'behindOnly': false,
          },
          'Astral Heptagon': {
            'circleRadius': 15.0,
            'polygonSides': 'octagram8',
            'spokeRays': true,
            'outerRings': true,
            'alchemyPalette': 'astralCyan',
            'behindOnly': false,
          },
          'Hermetic Trine': {
            'circleRadius': 10.0,
            'polygonSides': 'triangle3',
            'spokeRays': false,
            'outerRings': false,
            'alchemyPalette': 'amethystOccult',
            'behindOnly': false,
          },
        };
      case EffectType.floatingSigils:
        return {
          'Elder Futhark Orbit': {
            'sigilCount': 6.0,
            'orbitRadius': 12.0,
            'runeStyle': 'elderFuthark',
            'linkThreads': true,
            'sigilPalette': 'elderGold',
            'behindOnly': false,
          },
          'Valkyrie Ward Sigils': {
            'sigilCount': 4.0,
            'orbitRadius': 9.0,
            'runeStyle': 'celestialSigil',
            'linkThreads': false,
            'sigilPalette': 'valkyrieCyan',
            'behindOnly': false,
          },
          'Infernal Blood Seals': {
            'sigilCount': 7.0,
            'orbitRadius': 14.0,
            'runeStyle': 'linearStaves',
            'linkThreads': true,
            'sigilPalette': 'infernalCrimson',
            'behindOnly': false,
          },
          'Void Constellation': {
            'sigilCount': 5.0,
            'orbitRadius': 11.0,
            'runeStyle': 'celestialSigil',
            'linkThreads': true,
            'sigilPalette': 'voidViolet',
            'behindOnly': false,
          },
        };
      case EffectType.sacredGeometryHalo:
        return {
          "Metatron's Archangel Cube": {
            'geometryType': 'metatronCube',
            'haloRadius': 14.0,
            'showNodes': true,
            'isometricLines': true,
            'sacredPalette': 'divineGold',
            'behindOnly': false,
          },
          'Flower of Creation': {
            'geometryType': 'flowerOfLife',
            'haloRadius': 12.0,
            'showNodes': false,
            'isometricLines': true,
            'sacredPalette': 'solarPrism',
            'behindOnly': false,
          },
          'Merkaba Star Tetrahedron': {
            'geometryType': 'merkabaStar',
            'haloRadius': 13.0,
            'showNodes': true,
            'isometricLines': true,
            'sacredPalette': 'cosmicPlatonic',
            'behindOnly': false,
          },
          'Platonic Geodesic Icosa': {
            'geometryType': 'platonicIcosa',
            'haloRadius': 15.0,
            'showNodes': true,
            'isometricLines': true,
            'sacredPalette': 'monochromeSilver',
            'behindOnly': false,
          },
        };
      case EffectType.supernovaCorona:
        return {
          'Solar Hypernova': {
            'coronaRadius': 12.0,
            'spikeLength': 20.0,
            'spikePattern': 'star8',
            'prominences': true,
            'coronaPalette': 'solarWhite',
            'behindOnly': false,
          },
          'Sirius Starburst': {
            'coronaRadius': 8.0,
            'spikeLength': 24.0,
            'spikePattern': 'cross4',
            'prominences': false,
            'coronaPalette': 'hypernovaBlue',
            'behindOnly': false,
          },
          'Pulsar Magenta Flare': {
            'coronaRadius': 10.0,
            'spikeLength': 16.0,
            'spikePattern': 'cross4',
            'prominences': true,
            'coronaPalette': 'pulsarMagenta',
            'behindOnly': false,
          },
          'Anamorphic Solar Glare': {
            'coronaRadius': 14.0,
            'spikeLength': 28.0,
            'spikePattern': 'anamorphic2',
            'prominences': true,
            'coronaPalette': 'goldenDawn',
            'behindOnly': false,
          },
        };
      case EffectType.orbitingMoons:
        return {
          'Twin Galilean Moons': {
            'moonCount': 2.0,
            'orbitRadius': 12.0,
            'orbitTilt': 15.0,
            'showTracks': true,
            'celestialPalette': 'terrestrialMoons',
            'behindOnly': false,
          },
          'Saturnian System': {
            'moonCount': 4.0,
            'orbitRadius': 16.0,
            'orbitTilt': -10.0,
            'showTracks': true,
            'celestialPalette': 'gasGiantSatellites',
            'behindOnly': false,
          },
          'Crystalline Ice Orbits': {
            'moonCount': 3.0,
            'orbitRadius': 14.0,
            'orbitTilt': 30.0,
            'showTracks': true,
            'celestialPalette': 'crystallineIce',
            'behindOnly': false,
          },
          'Volcanic Eclipse Moons': {
            'moonCount': 5.0,
            'orbitRadius': 18.0,
            'orbitTilt': 0.0,
            'showTracks': false,
            'celestialPalette': 'volcanicIo',
            'behindOnly': false,
          },
        };
      case EffectType.zodiacConstellation:
        return {
          "Orion's Celestial Belt": {
            'starScale': 14.0,
            'constellationPattern': 'orionHunter',
            'crossGlints': true,
            'dustDensity': 10.0,
            'starPalette': 'polarWhite',
            'behindOnly': false,
          },
          "Cassiopeia's Crown": {
            'starScale': 12.0,
            'constellationPattern': 'cassiopeiaCrown',
            'crossGlints': true,
            'dustDensity': 6.0,
            'starPalette': 'celestialGold',
            'behindOnly': false,
          },
          'Phoenix Ascendant': {
            'starScale': 15.0,
            'constellationPattern': 'phoenixAscendant',
            'crossGlints': true,
            'dustDensity': 12.0,
            'starPalette': 'nebulaAzure',
            'behindOnly': false,
          },
          'Cygnus Northern Cross': {
            'starScale': 13.0,
            'constellationPattern': 'cygnusCross',
            'crossGlints': true,
            'dustDensity': 8.0,
            'starPalette': 'stellarRuby',
            'behindOnly': false,
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
