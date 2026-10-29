import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/storage/local_storage.dart';
import '../pixel/gradient/gradient_options.dart';
import '../pixel/gradient/gradient_renderer.dart';
import 'providers.dart';

part 'editor_settings_provider.g.dart';

/// Input mode for touch/stylus handling
enum InputMode {
  /// Both touch and stylus can draw
  standard,

  /// Only stylus can draw, touch is for navigation only
  stylusOnly,
}

enum TransformInterpolation {
  nearest,
  bilinear,

  /// Nearest-neighbour resizing; RotSprite rotation (clean pixel-art
  /// diagonals). Stored by index, so it must stay last.
  rotSprite;

  /// The `PixelUtils` sampler: RotSprite resizes with nearest neighbour.
  int get pixelUtilsValue => this == rotSprite ? nearest.index : index;
}

/// Which colours the gradient uses. Persisted by index.
enum GradientEnd {
  /// Primary → secondary colour.
  secondaryColor,

  /// Primary → transparent.
  transparent,

  /// The saved colour ramp, used verbatim as the bands (no new colours).
  ramp,
}

/// Most colours a gradient ramp may hold.
const kMaxGradientRampColors = 16;

/// Editor settings state
class EditorSettings {
  const EditorSettings({
    this.inputMode = InputMode.standard,
    this.showGrid = true,
    this.zoomSensitivity = 0.5,
    this.minZoom = 0.5,
    this.maxZoom = 5.0,
    this.twoFingerUndoEnabled = true,
    this.showPixelGrid = true,
    this.pixelGridOpacity = 0.3,
    this.transformInterpolation = TransformInterpolation.bilinear,
    this.wandTolerance = 0,
    this.wandContiguous = true,
    this.secondaryColor = const Color(0xFFFFFFFF),
    this.gradientType = GradientType.linear,
    this.gradientTarget = GradientTarget.layer,
    this.gradientEnd = GradientEnd.secondaryColor,
    this.gradientSteps = 6,
    this.gradientDither = GradientDither.bayer4,
    this.gradientDitherSpread = 0.5,
    this.gradientBlend = GradientBlend.over,
    this.gradientRamp = const [],
  });

  /// Current input mode (standard or stylus-only)
  final InputMode inputMode;

  /// Whether to show the canvas grid
  final bool showGrid;

  /// Zoom sensitivity (0.1 - 1.0)
  final double zoomSensitivity;

  /// Minimum zoom level
  final double minZoom;

  /// Maximum zoom level
  final double maxZoom;

  /// Whether two-finger tap triggers undo
  final bool twoFingerUndoEnabled;

  /// Whether to show pixel grid overlay
  final bool showPixelGrid;

  /// Pixel grid opacity (0.0 - 1.0)
  final double pixelGridOpacity;

  /// Sampling used for selection resize/rotate transforms
  final TransformInterpolation transformInterpolation;

  /// Magic wand color tolerance as a percentage (0-100). Mapped onto the
  /// service's Euclidean ARGB distance threshold (0-255).
  final int wandTolerance;

  /// Magic wand: flood-fill from the tapped pixel (true) or select every
  /// matching color on the layer (false).
  final bool wandContiguous;

  /// Background/secondary colour; X swaps it with the primary colour.
  final Color secondaryColor;

  final GradientType gradientType;
  final GradientTarget gradientTarget;
  final GradientEnd gradientEnd;

  /// Solid colour bands, or 0 for a smooth gradient.
  final int gradientSteps;
  final GradientDither gradientDither;
  final double gradientDitherSpread;
  final GradientBlend gradientBlend;

  /// Colours for [GradientEnd.ramp], first to last.
  final List<Color> gradientRamp;

  /// Ramp mode is only active with at least two colours; otherwise it falls
  /// back to primary → secondary.
  bool get usesGradientRamp =>
      gradientEnd == GradientEnd.ramp && gradientRamp.length >= 2;

  GradientOptions get gradientOptions => GradientOptions(
        type: gradientType,
        target: gradientTarget,
        endColor: gradientEnd == GradientEnd.transparent
            ? const Color(0x00000000)
            : secondaryColor,
        stops: usesGradientRamp ? gradientRamp : null,
        // A ramp always renders one band per colour, so only its own
        // colours appear (dither mixes neighbours).
        steps: usesGradientRamp
            ? gradientRamp.length
            : (gradientSteps < 2 ? null : gradientSteps),
        dither: gradientDither,
        ditherSpread: gradientDitherSpread,
        blend: gradientBlend,
      );

  /// Whether stylus mode is active
  bool get isStylusMode => inputMode == InputMode.stylusOnly;

  EditorSettings copyWith({
    InputMode? inputMode,
    bool? showGrid,
    double? zoomSensitivity,
    double? minZoom,
    double? maxZoom,
    bool? twoFingerUndoEnabled,
    bool? showPixelGrid,
    double? pixelGridOpacity,
    TransformInterpolation? transformInterpolation,
    int? wandTolerance,
    bool? wandContiguous,
    Color? secondaryColor,
    GradientType? gradientType,
    GradientTarget? gradientTarget,
    GradientEnd? gradientEnd,
    int? gradientSteps,
    GradientDither? gradientDither,
    double? gradientDitherSpread,
    GradientBlend? gradientBlend,
    List<Color>? gradientRamp,
  }) {
    return EditorSettings(
      inputMode: inputMode ?? this.inputMode,
      showGrid: showGrid ?? this.showGrid,
      zoomSensitivity: zoomSensitivity ?? this.zoomSensitivity,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      twoFingerUndoEnabled: twoFingerUndoEnabled ?? this.twoFingerUndoEnabled,
      showPixelGrid: showPixelGrid ?? this.showPixelGrid,
      pixelGridOpacity: pixelGridOpacity ?? this.pixelGridOpacity,
      transformInterpolation:
          transformInterpolation ?? this.transformInterpolation,
      wandTolerance: wandTolerance ?? this.wandTolerance,
      wandContiguous: wandContiguous ?? this.wandContiguous,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      gradientType: gradientType ?? this.gradientType,
      gradientTarget: gradientTarget ?? this.gradientTarget,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      gradientSteps: gradientSteps ?? this.gradientSteps,
      gradientDither: gradientDither ?? this.gradientDither,
      gradientDitherSpread: gradientDitherSpread ?? this.gradientDitherSpread,
      gradientBlend: gradientBlend ?? this.gradientBlend,
      gradientRamp: gradientRamp ?? this.gradientRamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditorSettings &&
        other.inputMode == inputMode &&
        other.showGrid == showGrid &&
        other.zoomSensitivity == zoomSensitivity &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        other.twoFingerUndoEnabled == twoFingerUndoEnabled &&
        other.showPixelGrid == showPixelGrid &&
        other.pixelGridOpacity == pixelGridOpacity &&
        other.transformInterpolation == transformInterpolation &&
        other.wandTolerance == wandTolerance &&
        other.wandContiguous == wandContiguous &&
        other.secondaryColor == secondaryColor &&
        other.gradientType == gradientType &&
        other.gradientTarget == gradientTarget &&
        other.gradientEnd == gradientEnd &&
        other.gradientSteps == gradientSteps &&
        other.gradientDither == gradientDither &&
        other.gradientDitherSpread == gradientDitherSpread &&
        other.gradientBlend == gradientBlend &&
        _listEquals(other.gradientRamp, gradientRamp);
  }

  @override
  int get hashCode => Object.hashAll([
        inputMode,
        showGrid,
        zoomSensitivity,
        minZoom,
        maxZoom,
        twoFingerUndoEnabled,
        showPixelGrid,
        pixelGridOpacity,
        transformInterpolation,
        wandTolerance,
        wandContiguous,
        secondaryColor,
        gradientType,
        gradientTarget,
        gradientEnd,
        gradientSteps,
        gradientDither,
        gradientDitherSpread,
        gradientBlend,
        Object.hashAll(gradientRamp),
      ]);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// Storage keys for editor settings
const _kInputMode = 'editor_input_mode';
const _kShowGrid = 'editor_show_grid';
const _kZoomSensitivity = 'editor_zoom_sensitivity';
const _kMinZoom = 'editor_min_zoom';
const _kMaxZoom = 'editor_max_zoom';
const _kTwoFingerUndo = 'editor_two_finger_undo';
const _kShowPixelGrid = 'editor_show_pixel_grid';
const _kPixelGridOpacity = 'editor_pixel_grid_opacity';
const _kTransformInterpolation = 'editor_transform_interpolation';
const _kWandTolerance = 'editor_wand_tolerance';
const _kWandContiguous = 'editor_wand_contiguous';
const _kSecondaryColor = 'editor_secondary_color';
const _kGradientType = 'editor_gradient_type';
const _kGradientTarget = 'editor_gradient_target';
const _kGradientEnd = 'editor_gradient_end';
const _kGradientSteps = 'editor_gradient_steps';
const _kGradientDither = 'editor_gradient_dither';
const _kGradientDitherSpread = 'editor_gradient_dither_spread';
const _kGradientBlend = 'editor_gradient_blend';
const _kGradientRamp = 'editor_gradient_ramp';

T _enumAt<T>(List<T> values, int? index, T fallback) =>
    index == null || index < 0 || index >= values.length
        ? fallback
        : values[index];

@riverpod
class EditorSettingsNotifier extends _$EditorSettingsNotifier {
  late LocalStorage _storage;

  @override
  EditorSettings build() {
    _storage = ref.read(localStorageProvider);
    return _loadSettings();
  }

  EditorSettings _loadSettings() {
    final inputModeIndex = _storage.getInt(_kInputMode) ?? 0;
    final showGrid = _storage.getBool(_kShowGrid) ?? true;
    final zoomSensitivity = _storage.getDouble(_kZoomSensitivity) ?? 0.5;
    final minZoom = _storage.getDouble(_kMinZoom) ?? 0.5;
    final maxZoom = _storage.getDouble(_kMaxZoom) ?? 5.0;
    final twoFingerUndo = _storage.getBool(_kTwoFingerUndo) ?? true;
    final showPixelGrid = _storage.getBool(_kShowPixelGrid) ?? true;
    final pixelGridOpacity = _storage.getDouble(_kPixelGridOpacity) ?? 0.3;
    final transformInterpolationIndex =
        _storage.getInt(_kTransformInterpolation) ??
            TransformInterpolation.bilinear.index;
    final wandTolerance = _storage.getInt(_kWandTolerance) ?? 0;
    final wandContiguous = _storage.getBool(_kWandContiguous) ?? true;
    const defaults = EditorSettings();

    return EditorSettings(
      inputMode: InputMode
          .values[inputModeIndex.clamp(0, InputMode.values.length - 1)],
      showGrid: showGrid,
      zoomSensitivity: zoomSensitivity.clamp(0.1, 1.0),
      minZoom: minZoom.clamp(0.1, 1.0),
      maxZoom: maxZoom.clamp(2.0, 20.0),
      twoFingerUndoEnabled: twoFingerUndo,
      showPixelGrid: showPixelGrid,
      pixelGridOpacity: pixelGridOpacity.clamp(0.0, 1.0),
      transformInterpolation:
          TransformInterpolation.values[transformInterpolationIndex.clamp(
        0,
        TransformInterpolation.values.length - 1,
      )],
      wandTolerance: wandTolerance.clamp(0, 100),
      wandContiguous: wandContiguous,
      secondaryColor: Color(
          _storage.getInt(_kSecondaryColor) ??
              defaults.secondaryColor.toARGB32()),
      gradientType: _enumAt(GradientType.values,
          _storage.getInt(_kGradientType), defaults.gradientType),
      gradientTarget: _enumAt(GradientTarget.values,
          _storage.getInt(_kGradientTarget), defaults.gradientTarget),
      gradientEnd: _enumAt(GradientEnd.values, _storage.getInt(_kGradientEnd),
          defaults.gradientEnd),
      gradientSteps: (_storage.getInt(_kGradientSteps) ??
              defaults.gradientSteps)
          .clamp(0, 32),
      gradientDither: _enumAt(GradientDither.values,
          _storage.getInt(_kGradientDither), defaults.gradientDither),
      gradientDitherSpread: (_storage.getDouble(_kGradientDitherSpread) ??
              defaults.gradientDitherSpread)
          .clamp(0.0, 1.0),
      gradientBlend: _enumAt(GradientBlend.values,
          _storage.getInt(_kGradientBlend), defaults.gradientBlend),
      gradientRamp: [
        for (final hex in _storage.getStringList(_kGradientRamp) ?? const [])
          if (int.tryParse(hex, radix: 16) case final v?) Color(v),
      ].take(kMaxGradientRampColors).toList(),
    );
  }

  void _saveSettings() {
    _storage.setInt(_kInputMode, state.inputMode.index);
    _storage.setBool(_kShowGrid, state.showGrid);
    _storage.setDouble(_kZoomSensitivity, state.zoomSensitivity);
    _storage.setDouble(_kMinZoom, state.minZoom);
    _storage.setDouble(_kMaxZoom, state.maxZoom);
    _storage.setBool(_kTwoFingerUndo, state.twoFingerUndoEnabled);
    _storage.setBool(_kShowPixelGrid, state.showPixelGrid);
    _storage.setDouble(_kPixelGridOpacity, state.pixelGridOpacity);
    _storage.setInt(
      _kTransformInterpolation,
      state.transformInterpolation.index,
    );
    _storage.setInt(_kWandTolerance, state.wandTolerance);
    _storage.setBool(_kWandContiguous, state.wandContiguous);
    _storage.setInt(_kSecondaryColor, state.secondaryColor.toARGB32());
    _storage.setInt(_kGradientType, state.gradientType.index);
    _storage.setInt(_kGradientTarget, state.gradientTarget.index);
    _storage.setInt(_kGradientEnd, state.gradientEnd.index);
    _storage.setInt(_kGradientSteps, state.gradientSteps);
    _storage.setInt(_kGradientDither, state.gradientDither.index);
    _storage.setDouble(_kGradientDitherSpread, state.gradientDitherSpread);
    _storage.setInt(_kGradientBlend, state.gradientBlend.index);
    _storage.setStringList(_kGradientRamp, [
      for (final c in state.gradientRamp) c.toARGB32().toRadixString(16),
    ]);
  }

  void setInputMode(InputMode mode) {
    state = state.copyWith(inputMode: mode);
    _saveSettings();
  }

  void toggleStylusMode() {
    final newMode = state.inputMode == InputMode.stylusOnly
        ? InputMode.standard
        : InputMode.stylusOnly;
    setInputMode(newMode);
  }

  void setShowGrid(bool show) {
    state = state.copyWith(showGrid: show);
    _saveSettings();
  }

  void setZoomSensitivity(double sensitivity) {
    state = state.copyWith(zoomSensitivity: sensitivity.clamp(0.1, 1.0));
    _saveSettings();
  }

  void setZoomLimits({double? min, double? max}) {
    state = state.copyWith(
      minZoom: min?.clamp(0.1, 1.0),
      maxZoom: max?.clamp(2.0, 20.0),
    );
    _saveSettings();
  }

  void setTwoFingerUndoEnabled(bool enabled) {
    state = state.copyWith(twoFingerUndoEnabled: enabled);
    _saveSettings();
  }

  void setShowPixelGrid(bool show) {
    state = state.copyWith(showPixelGrid: show);
    _saveSettings();
  }

  void setPixelGridOpacity(double opacity) {
    state = state.copyWith(pixelGridOpacity: opacity.clamp(0.0, 1.0));
    _saveSettings();
  }

  void setTransformInterpolation(TransformInterpolation interpolation) {
    state = state.copyWith(transformInterpolation: interpolation);
    _saveSettings();
  }

  void setWandTolerance(int tolerance) {
    state = state.copyWith(wandTolerance: tolerance.clamp(0, 100));
    _saveSettings();
  }

  void setWandContiguous(bool contiguous) {
    state = state.copyWith(wandContiguous: contiguous);
    _saveSettings();
  }

  void setSecondaryColor(Color color) {
    state = state.copyWith(secondaryColor: color);
    _saveSettings();
  }

  void setGradientType(GradientType type) {
    state = state.copyWith(gradientType: type);
    _saveSettings();
  }

  void setGradientTarget(GradientTarget target) {
    state = state.copyWith(gradientTarget: target);
    _saveSettings();
  }

  void setGradientEnd(GradientEnd end) {
    state = state.copyWith(gradientEnd: end);
    _saveSettings();
  }

  /// 0 (or 1) means smooth.
  void setGradientSteps(int steps) {
    state = state.copyWith(gradientSteps: steps.clamp(0, 32));
    _saveSettings();
  }

  void setGradientDither(GradientDither dither) {
    state = state.copyWith(gradientDither: dither);
    _saveSettings();
  }

  void setGradientDitherSpread(double spread) {
    state = state.copyWith(gradientDitherSpread: spread.clamp(0.0, 1.0));
    _saveSettings();
  }

  void setGradientBlend(GradientBlend blend) {
    state = state.copyWith(gradientBlend: blend);
    _saveSettings();
  }

  void setGradientRamp(List<Color> colors) {
    state = state.copyWith(
      gradientRamp: List.unmodifiable(colors.take(kMaxGradientRampColors)),
    );
    _saveSettings();
  }

  void resetToDefaults() {
    state = const EditorSettings();
    _saveSettings();
  }
}
