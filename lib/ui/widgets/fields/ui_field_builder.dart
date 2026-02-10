import 'package:flutter/material.dart';

import '../dialogs/save_image_window.dart' show showColorPicker;
import 'ui_field.dart';

/// Builds Flutter widgets from a list of [UIField] descriptors.
///
/// Usage:
/// ```dart
/// UIFieldBuilder.buildAll(
///   fields: effect.getFields(),
///   values: parameters,
///   onChanged: (key, value) { … },
///   context: context,
/// )
/// ```
class UIFieldBuilder {
  const UIFieldBuilder._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Build a list of widgets from [fields], reading current values from [values].
  ///
  /// [onChanged] is called whenever the user modifies a value.
  static List<Widget> buildAll({
    required BuildContext context,
    required List<UIField> fields,
    required Map<String, dynamic> values,
    required void Function(String key, dynamic value) onChanged,
  }) {
    final widgets = <Widget>[];
    String? currentGroup;

    for (final field in fields) {
      // Group header
      if (field.group != null && field.group != currentGroup) {
        currentGroup = field.group;
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 8));
        }
        widgets.add(_buildGroupHeader(context, field.group!));
      }

      widgets.add(
        build(
          context: context,
          field: field,
          values: values,
          onChanged: onChanged,
        ),
      );
    }

    return widgets;
  }

  /// Build a single widget from a [UIField].
  static Widget build({
    required BuildContext context,
    required UIField field,
    required Map<String, dynamic> values,
    required void Function(String key, dynamic value) onChanged,
  }) {
    return switch (field) {
      SliderField f => _buildSlider(context, f, values, onChanged),
      ColorField f => _buildColor(context, f, values, onChanged),
      SelectField f => _buildSelect(context, f, values, onChanged),
      BoolField f => _buildBool(context, f, values, onChanged),
      TextField_ f => _buildText(context, f, values, onChanged),
      SectionField f => _buildSection(context, f),
    };
  }

  // ---------------------------------------------------------------------------
  // Individual builders
  // ---------------------------------------------------------------------------

  static Widget _buildSlider(
    BuildContext context,
    SliderField field,
    Map<String, dynamic> values,
    void Function(String, dynamic) onChanged,
  ) {
    final raw = values[field.key];
    final doubleValue = (raw is int ? raw.toDouble() : (raw as double?) ?? field.min).clamp(field.min, field.max);

    final theme = Theme.of(context);

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          field.formatLabel?.call(doubleValue) ?? _defaultFormat(doubleValue),
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: doubleValue,
              min: field.min,
              max: field.max,
              divisions: field.divisions,
              label: field.formatLabel?.call(doubleValue) ?? _defaultFormat(doubleValue),
              onChanged: (v) => onChanged(field.key, field.isInteger ? v.round() : v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _defaultFormat(field.min),
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _defaultFormat(field.max),
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildColor(
    BuildContext context,
    ColorField field,
    Map<String, dynamic> values,
    void Function(String, dynamic) onChanged,
  ) {
    final colorValue = values[field.key] as int? ?? 0xFF000000;
    final color = Color(colorValue);
    final theme = Theme.of(context);

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showColorPicker(
                    context,
                    color,
                    (newColor) => onChanged(field.key, newColor.value),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Tap',
                      style: TextStyle(
                        color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${colorValue.toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSelect<T>(
    BuildContext context,
    SelectField<T> field,
    Map<String, dynamic> values,
    void Function(String, dynamic) onChanged,
  ) {
    final currentValue = values[field.key];
    final theme = Theme.of(context);

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      child: DropdownButtonFormField<T>(
        value: currentValue as T?,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onSurface,
        ),
        isDense: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        items: field.options.entries.map((entry) {
          return DropdownMenuItem<T>(
            value: entry.key,
            child: Text(
              entry.value,
              style: const TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(field.key, v);
        },
      ),
    );
  }

  static Widget _buildBool(
    BuildContext context,
    BoolField field,
    Map<String, dynamic> values,
    void Function(String, dynamic) onChanged,
  ) {
    final value = values[field.key] as bool? ?? false;
    final theme = Theme.of(context);

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  value ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: (v) => onChanged(field.key, v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  static Widget _buildText(
    BuildContext context,
    TextField_ field,
    Map<String, dynamic> values,
    void Function(String, dynamic) onChanged,
  ) {
    final value = values[field.key]?.toString() ?? '';
    final theme = Theme.of(context);

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      child: TextFormField(
        initialValue: value,
        style: const TextStyle(fontSize: 11),
        decoration: InputDecoration(
          hintText: field.hint,
          hintStyle: const TextStyle(fontSize: 11),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        maxLines: field.maxLines,
        keyboardType: field.keyboardType,
        onChanged: (v) => onChanged(field.key, v),
      ),
    );
  }

  static Widget _buildSection(BuildContext context, SectionField field) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (field.description != null) ...[
            const SizedBox(height: 2),
            Text(
              field.description!,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
        ],
      ),
    );
  }

  static Widget _buildGroupHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _defaultFormat(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

// ---------------------------------------------------------------------------
// Shared wrapper
// ---------------------------------------------------------------------------

class _FieldWrapper extends StatelessWidget {
  final String label;
  final String? description;
  final Widget? trailing;
  final Widget child;

  const _FieldWrapper({
    required this.label,
    this.description,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
