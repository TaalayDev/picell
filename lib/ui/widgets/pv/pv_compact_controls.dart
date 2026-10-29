import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/theme.dart';

/// Compact pill switch: 34×20 by default, themed from [PvTokens].
///
/// Smaller than the Material switch so it fits dense side panels; the whole
/// widget is the hit target and it reports as a toggle to assistive tech.
class PvSwitch extends StatelessWidget {
  const PvSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.small = false,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Track color when on. Defaults to the theme primary.
  final Color? activeColor;

  /// 28×16 variant for toolbars and pills.
  final bool small;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final enabled = onChanged != null;
    final w = small ? 28.0 : 34.0, h = small ? 16.0 : 20.0, knob = h - 6;
    final on = activeColor ?? pv.primary;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: value ? on : pv.background,
                borderRadius: BorderRadius.circular(h / 2),
                border: Border.all(color: value ? on : pv.divider),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? pv.ink : pv.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dense row with a title, optional one-line description and a [PvSwitch].
/// Tapping anywhere on the row toggles it.
class PvSwitchTile extends StatelessWidget {
  const PvSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.activeColor,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final enabled = onChanged != null;
    return Semantics(
      container: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(pv.buttonRadius),
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        pv.body(size: 12, weight: FontWeight.w600, color: enabled ? pv.textPrimary : pv.textSecondary)),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: pv.body(size: 10, color: pv.textSecondary, weight: FontWeight.w400)),
              ]),
            ),
            const SizedBox(width: 10),
            ExcludeSemantics(child: PvSwitch(value: value, onChanged: onChanged, activeColor: activeColor)),
          ]),
        ),
      ),
    );
  }
}

/// Compact outlined text field (38 px tall by default).
///
/// Wraps a real [TextField] so focus, selection and tests behave normally;
/// only the chrome is slimmer than the app's default input decoration.
class PvTextField extends StatelessWidget {
  const PvTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.mono = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.height = 38,
    this.textAlign = TextAlign.start,
    this.fieldKey,
  });

  final TextEditingController? controller;
  final String? hint;

  /// Small caption drawn inside the field, left of the text.
  final String? label;
  final IconData? prefixIcon;

  /// Trailing widget inside the field, e.g. a shuffle button.
  final Widget? suffix;
  final ValueChanged<String>? onChanged, onSubmitted;
  final bool enabled, autofocus, mono;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;

  /// Height of a single-line field. Multi-line fields grow with content.
  final double height;
  final TextAlign textAlign;

  /// Key for the inner [TextField], for tests that read its controller.
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final radius = BorderRadius.circular(pv.buttonRadius.clamp(4, 10));
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color, width: width));
    final style = mono ? pv.mono(size: 13, weight: FontWeight.w600) : pv.body(size: 13, weight: FontWeight.w600);
    final single = maxLines == 1;
    final field = TextField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: single ? 1 : null,
      textAlign: textAlign,
      textAlignVertical: TextAlignVertical.center,
      style: style.copyWith(color: enabled ? pv.textPrimary : pv.textSecondary),
      cursorColor: pv.primary,
      cursorHeight: single ? 16 : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        isDense: !single,
        filled: true,
        fillColor: pv.background,
        // A never-floating label reads like a placeholder but also names the field for assistive tech.
        labelText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: style.copyWith(color: pv.textSecondary.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
        counterText: '',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: single ? 0 : 10),
        prefixIcon: label != null || prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 11, right: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (prefixIcon != null) Icon(prefixIcon, size: 16, color: pv.textSecondary),
                  if (prefixIcon != null && label != null) const SizedBox(width: 6),
                  if (label != null)
                    Text(label!, style: pv.body(size: 11, color: pv.textSecondary, weight: FontWeight.w600)),
                ]),
              )
            : null,
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: single ? height : 0),
        suffixIcon: suffix,
        suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0, maxHeight: height),
        border: border(pv.divider),
        enabledBorder: border(pv.divider),
        disabledBorder: border(pv.divider.withValues(alpha: 0.5)),
        focusedBorder: border(pv.primary, 1.5),
      ),
    );
    return single ? SizedBox(height: height, child: field) : field;
  }
}

/// Compact −/value/+ stepper in a single outlined box.
class PvStepper extends StatelessWidget {
  const PvStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.label,
    this.decreaseTooltip,
    this.increaseTooltip,
    this.height = 38,
  });

  final int value, min, max;
  final ValueChanged<int>? onChanged;

  /// Caption shown before the value inside the box.
  final String? label;
  final String? decreaseTooltip, increaseTooltip;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    Widget step(IconData icon, String tip, int? next) => SizedBox.square(
          dimension: height - 2,
          child: IconButton(
            tooltip: tip,
            padding: EdgeInsets.zero,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            color: pv.textPrimary,
            disabledColor: pv.textSecondary.withValues(alpha: 0.4),
            onPressed: onChanged == null || next == null ? null : () => onChanged!(next),
            icon: Icon(icon),
          ),
        );
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: pv.background,
        borderRadius: BorderRadius.circular(pv.buttonRadius.clamp(4, 10)),
        border: Border.all(color: pv.divider),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 11, right: 2),
            child: Text(label!, style: pv.body(size: 11, color: pv.textSecondary, weight: FontWeight.w600)),
          ),
        step(Icons.remove, decreaseTooltip ?? 'Decrease', value > min ? value - 1 : null),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 24),
          child: Text('$value', textAlign: TextAlign.center, style: pv.mono(size: 13, weight: FontWeight.w700)),
        ),
        step(Icons.add, increaseTooltip ?? 'Increase', value < max ? value + 1 : null),
      ]),
    );
  }
}

/// Two-option mode switch for choosing between Pixel Art and Tileset projects.
class PvProjectTypeSwitch extends StatelessWidget {
  const PvProjectTypeSwitch({
    super.key,
    required this.isTileset,
    required this.onChanged,
  });

  final bool isTileset;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final outerRadius = pv.cardRadius.clamp(8.0, 14.0);
    final innerRadius = (outerRadius - 3).clamp(6.0, 11.0);

    Widget option({
      required bool tileset,
      required IconData icon,
      required String title,
      required String subtitle,
    }) {
      final selected = isTileset == tileset;
      final enabled = onChanged != null;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          enabled: enabled,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: ValueKey(tileset ? 'project-type-tileset' : 'project-type-pixel-art'),
              borderRadius: BorderRadius.circular(innerRadius),
              onTap: enabled ? () => onChanged!(tileset) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? pv.tint(pv.primary, pv.isDark ? 0.18 : 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(innerRadius),
                  border: Border.all(
                    color: selected ? pv.primary : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: pv.primary.withValues(alpha: 0.16),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: selected ? pv.gradient : null,
                        color: selected ? null : pv.surfaceHigh,
                        borderRadius: BorderRadius.circular((innerRadius - 2).clamp(4.0, 8.0)),
                        border: selected ? null : Border.all(color: pv.divider),
                      ),
                      child: Icon(
                        icon,
                        size: 15,
                        color: selected ? pv.ink : pv.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pv.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: selected ? pv.textPrimary : pv.textSecondary,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pv.body(
                              size: 10,
                              weight: FontWeight.w500,
                              color: pv.textSecondary.withValues(alpha: selected ? 0.9 : 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pv.background,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(color: pv.divider),
      ),
      child: Row(
        children: [
          option(
            tileset: false,
            icon: Icons.brush_rounded,
            title: 'Pixel Art',
            subtitle: 'Sprites & animations',
          ),
          const SizedBox(width: 6),
          option(
            tileset: true,
            icon: Icons.grid_view_rounded,
            title: 'Tileset',
            subtitle: 'Connected terrain',
          ),
        ],
      ),
    );
  }
}
