import 'package:flutter/material.dart';

/// A declarative description of a UI parameter field.
///
/// Classes like [Effect], layers, tools, etc. can return a list of [UIField]
/// descriptors via a `getFields()` method. These descriptors are then parsed
/// into Flutter widgets by [UIFieldBuilder].
///
/// Each field is tied to a parameter key so the owner can read/write its value
/// from/to a `Map<String, dynamic>` parameter map.
sealed class UIField {
  /// The parameter key this field maps to.
  final String key;

  /// Human-readable label shown next to the control.
  final String label;

  /// Optional tooltip / helper text.
  final String? description;

  /// Optional grouping key — fields with the same [group] will be visually
  /// grouped together (e.g. inside a section card).
  final String? group;

  const UIField({
    required this.key,
    required this.label,
    this.description,
    this.group,
  });

  /// Read the current value for this field out of [params].
  dynamic readValue(Map<String, dynamic> params) => params[key];
}

// ---------------------------------------------------------------------------
// Slider
// ---------------------------------------------------------------------------

/// A continuous or discrete numeric slider.
class SliderField extends UIField {
  final double min;
  final double max;
  final int? divisions;

  /// When `true` the underlying value is stored / returned as [int].
  final bool isInteger;

  /// Optional custom formatter for the value label displayed alongside the
  /// slider (e.g. "50 %"). If null a sensible default is used.
  final String Function(double value)? formatLabel;

  const SliderField({
    required super.key,
    required super.label,
    super.description,
    super.group,
    required this.min,
    required this.max,
    this.divisions,
    this.isInteger = false,
    this.formatLabel,
  });
}

// ---------------------------------------------------------------------------
// Color Picker
// ---------------------------------------------------------------------------

/// A color swatch that opens a color picker on tap.
class ColorField extends UIField {
  const ColorField({
    required super.key,
    required super.label,
    super.description,
    super.group,
  });
}

// ---------------------------------------------------------------------------
// Select / Dropdown
// ---------------------------------------------------------------------------

/// A drop-down selector with a fixed set of labelled options.
class SelectField<T> extends UIField {
  /// Ordered map of `value → display label`.
  final Map<T, String> options;

  const SelectField({
    required super.key,
    required super.label,
    super.description,
    super.group,
    required this.options,
  });
}

// ---------------------------------------------------------------------------
// Boolean Toggle
// ---------------------------------------------------------------------------

/// A simple on/off switch.
class BoolField extends UIField {
  const BoolField({
    required super.key,
    required super.label,
    super.description,
    super.group,
  });
}

// ---------------------------------------------------------------------------
// Text Input
// ---------------------------------------------------------------------------

/// A text input field.
class TextField_ extends UIField {
  final String? hint;
  final int maxLines;
  final TextInputType keyboardType;

  const TextField_({
    required super.key,
    required super.label,
    super.description,
    super.group,
    this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });
}

// ---------------------------------------------------------------------------
// Section Header (purely visual)
// ---------------------------------------------------------------------------

/// A non-interactive section header / divider used for visual grouping.
class SectionField extends UIField {
  const SectionField({
    required super.label,
    super.description,
  }) : super(key: '');

  @override
  dynamic readValue(Map<String, dynamic> params) => null;
}

// ---------------------------------------------------------------------------
// Mixin for field providers
// ---------------------------------------------------------------------------

/// Any class that can describe its editable parameters as [UIField]s.
///
/// ```dart
/// class BrightnessEffect extends Effect with UIFieldProvider { … }
/// ```
mixin UIFieldProvider {
  /// Return the list of fields that describe the parameters of this object.
  List<UIField> getFields();
}
