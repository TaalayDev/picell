import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/storage/local_storage.dart';
import 'providers.dart';

part 'editor_settings_provider.g.dart';

/// Input mode for touch/stylus handling
enum InputMode {
  /// Both touch and stylus can draw
  standard,

  /// Only stylus can draw, touch is for navigation only
  stylusOnly,
}

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
        other.pixelGridOpacity == pixelGridOpacity;
  }

  @override
  int get hashCode => Object.hash(
        inputMode,
        showGrid,
        zoomSensitivity,
        minZoom,
        maxZoom,
        twoFingerUndoEnabled,
        showPixelGrid,
        pixelGridOpacity,
      );
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

    return EditorSettings(
      inputMode: InputMode.values[inputModeIndex.clamp(0, InputMode.values.length - 1)],
      showGrid: showGrid,
      zoomSensitivity: zoomSensitivity.clamp(0.1, 1.0),
      minZoom: minZoom.clamp(0.1, 1.0),
      maxZoom: maxZoom.clamp(2.0, 20.0),
      twoFingerUndoEnabled: twoFingerUndo,
      showPixelGrid: showPixelGrid,
      pixelGridOpacity: pixelGridOpacity.clamp(0.0, 1.0),
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
  }

  void setInputMode(InputMode mode) {
    state = state.copyWith(inputMode: mode);
    _saveSettings();
  }

  void toggleStylusMode() {
    final newMode = state.inputMode == InputMode.stylusOnly ? InputMode.standard : InputMode.stylusOnly;
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

  void resetToDefaults() {
    state = const EditorSettings();
    _saveSettings();
  }
}
