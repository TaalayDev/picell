import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data.dart';
import '../../../pixel/effects/effects.dart';
import '../../../tilemap/tile_generator_notifier.dart';

class EffectSettingsPanel extends HookConsumerWidget {
  const EffectSettingsPanel({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tileGeneratorProvider(project);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    // Remove unused colorScheme if not used in this scope, but used below
    // final colorScheme = Theme.of(context).colorScheme;

    final activeLayer = state.activeLayer;

    if (activeLayer == null) {
      return Center(
        child: Text(
          'No active layer',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Effects',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              PopupMenuButton<EffectType>(
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Add Effect',
                onSelected: (type) => notifier.addEffect(type),
                itemBuilder: (context) {
                  return EffectType.values.where((e) => !EffectsManager.createEffect(e).isAnimation).map((type) {
                    return PopupMenuItem(
                      value: type,
                      child: Text(EffectsManager.createEffect(type).getName(context)),
                    );
                  }).toList();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Effects List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: activeLayer.effects.length,
            itemBuilder: (context, index) {
              final effect = activeLayer.effects[index];
              return _EffectItem(
                effect: effect,
                index: index,
                onUpdate: (updated) => notifier.updateEffect(index, updated),
                onRemove: () => notifier.removeEffect(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EffectItem extends StatelessWidget {
  const _EffectItem({
    required this.effect,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  final Effect effect;
  final int index;
  final ValueChanged<Effect> onUpdate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: effect.getIcon(size: 16, color: colorScheme.primary),
          ),
        ),
        title: Text(
          effect.getName(context),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 16),
          onPressed: onRemove,
          tooltip: 'Remove Effect',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildParameterEditors(context, effect),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterEditors(BuildContext context, Effect effect) {
    // Generate UI based on parameter keys/values
    // This assumes sensible defaults or explicit checking

    final params = Map<String, dynamic>.from(effect.parameters);
    final editors = <Widget>[];
    final metadata = effect.getMetadata();

    params.forEach((key, value) {
      final meta = metadata[key] as Map<String, dynamic>?;
      final label = meta?['label'] as String? ?? _formatKey(key);

      if (value is num) {
        // Number slider
        // Use metadata or defaults
        double min = (meta?['min'] as num?)?.toDouble() ?? 0.0;
        double max = (meta?['max'] as num?)?.toDouble() ?? 100.0;
        int? divisions;

        // Heuristics if no metadata (fallback)
        if (meta == null) {
          if (key.contains('opacity') || key.contains('intensity') || key.contains('Amount')) {
            max = 1.0;
          } else if (key.contains('angle')) {
            max = 360.0;
            divisions = 360;
          } else if (value is int) {
            max = 100.0; // Generous default for ints
          }
        } else {
          divisions = (meta?['divisions'] as num?)?.toInt();
        }

        // Use value type to decide if integer
        bool isInt = value is int;
        double doubleVal = value.toDouble();

        if (doubleVal > max) max = doubleVal * 2; // Expand range if value exceeds it
        if (doubleVal < min) min = doubleVal;

        editors.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  isInt ? doubleVal.toInt().toString() : doubleVal.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 2,
              ),
              child: Slider(
                value: doubleVal.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: (newValue) {
                  final newParams = Map<String, dynamic>.from(effect.parameters);
                  newParams[key] = isInt ? newValue.toInt() : newValue;
                  onUpdate(EffectsManager.createEffect(effect.type, newParams));
                },
              ),
            ),
          ],
        ));
      } else if (value is bool) {
        editors.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
            Switch(
              value: value,
              onChanged: (newValue) {
                final newParams = Map<String, dynamic>.from(effect.parameters);
                newParams[key] = newValue;
                onUpdate(EffectsManager.createEffect(effect.type, newParams));
              },
            ),
          ],
        ));
      } else if (value is String) {
        // Dropdown for string enums - check metadata for options
        List<String> options = [];
        if (meta != null && meta['type'] == 'select' && meta['options'] is List) {
          options = (meta['options'] as List).cast<String>();
        } else {
          // Fallback to just the current value
          options = [value];
        }

        // Only show dropdown if we have options
        if (options.length > 1) {
          editors.add(Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11),
              ),
              DropdownButton<String>(
                value: options.contains(value) ? value : options.first,
                isDense: true,
                style: Theme.of(context).textTheme.bodySmall,
                underline: Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                items: options.map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(_capitalizeFirst(val),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    final newParams = Map<String, dynamic>.from(effect.parameters);
                    newParams[key] = newValue;
                    onUpdate(EffectsManager.createEffect(effect.type, newParams));
                  }
                },
              ),
            ],
          ));
        }
      } else if (value is Color || (value is int && key.toLowerCase().contains('color'))) {
        // Color picker
        Color color = value is Color ? value : Color(value as int);
        editors.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11),
              ),
              GestureDetector(
                onTap: () {
                  _showColorPicker(context, color, (newColor) {
                    final newParams = Map<String, dynamic>.from(effect.parameters);
                    newParams[key] = newColor.value;
                    onUpdate(EffectsManager.createEffect(effect.type, newParams));
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    });

    if (editors.isEmpty) {
      return const Text('No parameters', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11));
    }

    return Column(children: editors);
  }

  void _showColorPicker(BuildContext context, Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatKey(String key) {
    // Convert camelCase to Title Case
    // e.g. "intensity" -> "Intensity", "radiusX" -> "Radius X"
    if (key.isEmpty) return key;

    final buffer = StringBuffer();
    for (int i = 0; i < key.length; i++) {
      final char = key[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
      } else if (char.toUpperCase() == char && char != char.toLowerCase()) {
        buffer.write(' $char');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
