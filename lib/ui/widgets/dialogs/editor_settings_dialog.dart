import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../providers/editor_settings_provider.dart';

class EditorSettingsDialog extends ConsumerWidget {
  const EditorSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const EditorSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsNotifierProvider);
    final notifier = ref.read(editorSettingsNotifierProvider.notifier);
    final theme = Theme.of(context);

    // Stylus mode is only relevant on touch devices
    final showStylusOption =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.settings, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text('Editor Settings', style: theme.textTheme.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
            onPressed: () {
              notifier.resetToDefaults();
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input Section
              if (showStylusOption) ...[
                _buildSectionHeader(context, 'Input', Icons.touch_app),
                const SizedBox(height: 8),
                _buildStylusModeOption(context, settings, notifier),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // Display Section
              _buildSectionHeader(context, 'Display', Icons.grid_on),
              const SizedBox(height: 8),
              _buildSwitchTile(
                context,
                title: 'Show Grid',
                subtitle: 'Display grid lines on canvas',
                value: settings.showGrid,
                onChanged: (value) => notifier.setShowGrid(value),
              ),
              _buildSwitchTile(
                context,
                title: 'Pixel Grid Overlay',
                subtitle: 'Show pixel boundaries when zoomed in',
                value: settings.showPixelGrid,
                onChanged: (value) => notifier.setShowPixelGrid(value),
              ),
              if (settings.showPixelGrid)
                _buildSliderTile(
                  context,
                  title: 'Grid Opacity',
                  value: settings.pixelGridOpacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) => notifier.setPixelGridOpacity(value),
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Zoom Section
              _buildSectionHeader(context, 'Zoom & Navigation', Icons.zoom_in),
              const SizedBox(height: 8),
              _buildSliderTile(
                context,
                title: 'Zoom Sensitivity',
                subtitle: 'How fast pinch-to-zoom responds',
                value: settings.zoomSensitivity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (value) => notifier.setZoomSensitivity(value),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactSlider(
                      context,
                      label: 'Min Zoom',
                      value: settings.minZoom,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (v) => notifier.setZoomLimits(min: v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactSlider(
                      context,
                      label: 'Max Zoom',
                      value: settings.maxZoom,
                      min: 2.0,
                      max: 20.0,
                      onChanged: (v) => notifier.setZoomLimits(max: v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Gestures Section
              _buildSectionHeader(context, 'Gestures', Icons.gesture),
              const SizedBox(height: 8),
              _buildSwitchTile(
                context,
                title: 'Two-Finger Tap Undo',
                subtitle: 'Quick tap with two fingers to undo',
                value: settings.twoFingerUndoEnabled,
                onChanged: (value) => notifier.setTwoFingerUndoEnabled(value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStylusModeOption(
    BuildContext context,
    EditorSettings settings,
    EditorSettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isStylusMode = settings.inputMode == InputMode.stylusOnly;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isStylusMode ? theme.colorScheme.primary : theme.dividerColor,
          width: isStylusMode ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isStylusMode ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isStylusMode ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.draw_outlined,
            color: isStylusMode ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: const Text('Stylus Mode'),
        subtitle: Text(
          isStylusMode ? 'Draw with stylus only • Touch for navigation' : 'Draw with both touch and stylus',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Switch(
          value: isStylusMode,
          onChanged: (_) => notifier.toggleStylusMode(),
        ),
        onTap: () => notifier.toggleStylusMode(),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: Text(
            value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCompactSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
