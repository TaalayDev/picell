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
  ///
  /// Optional niceties, all off by default:
  /// * [defaults] — a field whose value differs from its default gets a small
  ///   reset button.
  /// * [collapsibleGroups] — fields that share a `group` are put in a section
  ///   that can be folded away.
  /// * [segmentedSelects] — selects with two or three short options are shown
  ///   as a segmented control instead of a drop-down.
  static List<Widget> buildAll({
    required BuildContext context,
    required List<UIField> fields,
    required Map<String, dynamic> values,
    required void Function(String key, dynamic value) onChanged,
    Map<String, dynamic>? defaults,
    bool collapsibleGroups = false,
    bool segmentedSelects = false,
  }) {
    final widgets = <Widget>[];
    String? currentGroup;
    // The open group's children when groups are collapsible.
    List<Widget>? groupChildren;

    void closeGroup() {
      final title = currentGroup;
      final children = groupChildren;
      if (children != null && title != null) {
        widgets.add(_CollapsibleGroup(key: ValueKey('group:$title'), title: title, children: children));
      }
      groupChildren = null;
    }

    for (final field in fields) {
      if (field.group != currentGroup) {
        if (collapsibleGroups) closeGroup();
        currentGroup = field.group;
        if (field.group != null) {
          if (collapsibleGroups) {
            groupChildren = [];
          } else {
            if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
            widgets.add(_buildGroupHeader(context, field.group!));
          }
        }
      }

      final built = build(
        context: context,
        field: field,
        values: values,
        onChanged: onChanged,
        defaults: defaults,
        segmentedSelects: segmentedSelects,
      );
      (groupChildren ?? widgets).add(built);
    }
    if (collapsibleGroups) closeGroup();

    return widgets;
  }

  /// Build a single widget from a [UIField].
  static Widget build({
    required BuildContext context,
    required UIField field,
    required Map<String, dynamic> values,
    required void Function(String key, dynamic value) onChanged,
    Map<String, dynamic>? defaults,
    bool segmentedSelects = false,
  }) {
    final reset = _resetFor(field, values, defaults, onChanged);
    return switch (field) {
      SliderField f => _buildSlider(context, f, values, onChanged, reset),
      ColorField f => _buildColor(context, f, values, onChanged, reset),
      SelectField f => _buildSelect(context, f, values, onChanged, reset, segmentedSelects),
      BoolField f => _buildBool(context, f, values, onChanged),
      TextField_ f => _buildText(context, f, values, onChanged, reset),
      SectionField f => _buildSection(context, f),
    };
  }

  /// A callback that puts [field] back to its default, or null when it already
  /// is at its default (or no defaults were given).
  static VoidCallback? _resetFor(
    UIField field,
    Map<String, dynamic> values,
    Map<String, dynamic>? defaults,
    void Function(String, dynamic) onChanged,
  ) {
    if (defaults == null || field.key.isEmpty || !defaults.containsKey(field.key)) return null;
    final current = values[field.key];
    final fallback = defaults[field.key];
    final same = current is num && fallback is num ? (current - fallback).abs() < 1e-9 : current == fallback;
    return same ? null : () => onChanged(field.key, fallback);
  }

  // ---------------------------------------------------------------------------
  // Individual builders
  // ---------------------------------------------------------------------------

  static Widget _buildSlider(
    BuildContext context,
    SliderField field,
    Map<String, dynamic> values,
    void Function(String, dynamic) onChanged,
    VoidCallback? onReset,
  ) {
    final raw = values[field.key];
    final doubleValue = (raw is int ? raw.toDouble() : (raw as double?) ?? field.min).clamp(field.min, field.max);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      onReset: onReset,
      // Tap the value to type an exact number.
      trailing: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _editSliderValue(context, field, doubleValue, onChanged),
        child: Container(
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
    VoidCallback? onReset,
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
      onReset: onReset,
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
    VoidCallback? onReset,
    bool segmentedSelects,
  ) {
    final currentValue = values[field.key];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fitsSegments = field.options.length >= 2 &&
        field.options.length <= 3 &&
        field.options.values.every((label) => label.length <= 16);
    if (segmentedSelects && fitsSegments) {
      return _FieldWrapper(
        label: field.label,
        description: field.description,
        onReset: onReset,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              emptySelectionAllowed: true,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
              ),
              segments: [
                for (final entry in field.options.entries)
                  ButtonSegment<T>(
                      value: entry.key, label: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              selected: currentValue is T && field.options.containsKey(currentValue) ? {currentValue} : <T>{},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onChanged(field.key, selection.first);
              },
            ),
          ),
        ),
      );
    }

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      onReset: onReset,
      child: DropdownButtonFormField<T>(
        key: ValueKey(currentValue),
        initialValue: currentValue as T?,
        // Long option names shorten with an ellipsis instead of overflowing.
        isExpanded: true,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                      // const SizedBox(width: 8),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      //   decoration: BoxDecoration(
                      //     color: value
                      //         ? colorScheme.primary.withValues(alpha: 0.15)
                      //         : colorScheme.onSurface.withValues(alpha: 0.08),
                      //     borderRadius: BorderRadius.circular(4),
                      //   ),
                      //   child: Text(
                      //     value ? s.uiFieldEnabled : s.uiFieldDisabled,
                      //     style: TextStyle(
                      //       fontSize: 9.5,
                      //       fontWeight: FontWeight.w600,
                      //       color: value ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      //     ),
                      //   ),
                      // ),
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
    VoidCallback? onReset,
  ) {
    final value = values[field.key]?.toString() ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _FieldWrapper(
      label: field.label,
      description: field.description,
      onReset: onReset,
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

  /// Asks for an exact value for [field]; snaps it to the slider's steps.
  static Future<void> _editSliderValue(
    BuildContext context,
    SliderField field,
    double current,
    void Function(String, dynamic) onChanged,
  ) async {
    final typed = await showDialog<double>(
      context: context,
      builder: (_) => _NumberEntryDialog(
        title: field.label,
        initial: _defaultFormat(current),
        helper: '${_defaultFormat(field.min)} – ${_defaultFormat(field.max)}',
      ),
    );
    if (typed == null) return;
    var value = typed.clamp(field.min, field.max).toDouble();
    final divisions = field.divisions;
    if (divisions != null && divisions > 0) {
      final step = (field.max - field.min) / divisions;
      value = (field.min + ((value - field.min) / step).round() * step).clamp(field.min, field.max).toDouble();
    }
    onChanged(field.key, field.isInteger ? value.round() : value);
  }

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
  final VoidCallback? onReset;
  final Widget child;

  const _FieldWrapper({
    required this.label,
    this.description,
    this.trailing,
    this.onReset,
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
              if (onReset != null)
                IconButton(
                  onPressed: onReset,
                  tooltip: Strings.of(context).reset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  iconSize: 15,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 24, height: 24),
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

// ---------------------------------------------------------------------------
// Collapsible group
// ---------------------------------------------------------------------------

/// A titled section of fields that can be folded away.
class _CollapsibleGroup extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const _CollapsibleGroup({super.key, required this.title, required this.children});

  @override
  State<_CollapsibleGroup> createState() => _CollapsibleGroupState();
}

class _CollapsibleGroupState extends State<_CollapsibleGroup> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...widget.children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Number entry dialog
// ---------------------------------------------------------------------------

/// Asks for one number and pops it (or nothing when cancelled).
class _NumberEntryDialog extends StatefulWidget {
  final String title;
  final String initial;
  final String helper;

  const _NumberEntryDialog({required this.title, required this.initial, required this.helper});

  @override
  State<_NumberEntryDialog> createState() => _NumberEntryDialogState();
}

class _NumberEntryDialogState extends State<_NumberEntryDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initial.length);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(double.tryParse(_controller.text.trim().replaceAll(',', '.')));

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(helperText: widget.helper),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
        FilledButton(onPressed: _submit, child: Text(s.ok)),
      ],
    );
  }
}
