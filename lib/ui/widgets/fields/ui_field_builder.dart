import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';
import '../dialogs/save_image_window.dart' show showColorPicker;
import '../painter/checkboard_painter.dart';
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
    final colorScheme = theme.colorScheme;

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          field.formatLabel?.call(doubleValue) ?? _defaultFormat(doubleValue),
          style: TextStyle(
            color: colorScheme.primary,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _defaultFormat(field.min),
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7,
                  elevation: 2,
                  pressedElevation: 4,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.12),
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
          ),
          const SizedBox(width: 4),
          Text(
            _defaultFormat(field.max),
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
    final colorScheme = theme.colorScheme;

    final isTranslucent = color.a < 1.0;
    final hexCode = isTranslucent
        ? '#${colorValue.toRadixString(16).padLeft(8, '0').toUpperCase()}'
        : '#${(colorValue & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    final alphaPercent = (color.a * 100).round();

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showColorPicker(
              context,
              color,
              (newColor) => onChanged(field.key, newColor.toARGB32()),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Color swatch with checkerboard pattern for transparency
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: CheckerboardPainter(
                          cellSize: 4,
                          color1: Colors.white,
                          color2: const Color(0xFFD0D0D0),
                        ),
                      ),
                      Container(color: color),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Hex text
                Text(
                  hexCode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (isTranslucent) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$alphaPercent%',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.colorize_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
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
    final colorScheme = theme.colorScheme;

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      child: DropdownButtonFormField<T>(
        key: ValueKey(currentValue),
        initialValue: currentValue as T?,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        dropdownColor: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        style: TextStyle(
          fontSize: 11.5,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        items: field.options.entries.map((entry) {
          final isSelected = entry.key == currentValue;
          return DropdownMenuItem<T>(
            value: entry.key,
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
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
    final s = Strings.of(context);
    final value = values[field.key] as bool? ?? false;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(field.key, !value),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: value
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value
                    ? colorScheme.primary.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          field.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (field.description != null && field.description!.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        _DescriptionPopupIcon(
                          label: field.label,
                          description: field.description!,
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: value
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          value ? s.uiFieldEnabled : s.uiFieldDisabled,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: value ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: value,
                    onChanged: (v) => onChanged(field.key, v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
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
    final colorScheme = theme.colorScheme;

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      child: TextFormField(
        initialValue: value,
        style: TextStyle(
          fontSize: 11.5,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: field.hint,
          hintStyle: TextStyle(
            fontSize: 11.5,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        maxLines: field.maxLines,
        keyboardType: field.keyboardType,
        onChanged: (v) => onChanged(field.key, v),
      ),
    );
  }

  static Widget _buildSection(BuildContext context, SectionField field) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  height: 1,
                ),
              ),
            ],
          ),
          if (field.description != null) ...[
            const SizedBox(height: 3),
            Text(
              field.description!,
              style: TextStyle(
                fontSize: 9.5,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildGroupHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colorScheme.primary,
            ),
          ),
        ],
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
// Description Popup Icon Button
// ---------------------------------------------------------------------------

class _DescriptionPopupIcon extends StatelessWidget {
  final String label;
  final String description;

  const _DescriptionPopupIcon({
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<void>(
        tooltip: description,
        padding: EdgeInsets.zero,
        iconSize: 15,
        splashRadius: 14,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceContainerHigh,
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(
          minWidth: 180,
          maxWidth: 280,
        ),
        icon: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<void>(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      size: 15,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      _DescriptionPopupIcon(
                        label: label,
                        description: description!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          child,
        ],
      ),
    );
  }
}
