import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../providers/editor_settings_provider.dart';
import '../../../l10n/strings.dart';

class EditorSettingsDialog extends ConsumerWidget {
  const EditorSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const _EditorSettingsSheet(),
      );
    }

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
    final s = Strings.of(context);

    final showStylusOption = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tune_rounded,
                size: 18, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Text(s.editorSettings,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.restore_rounded, size: 20),
            tooltip: s.resetToDefaults,
            visualDensity: VisualDensity.compact,
            onPressed: notifier.resetToDefaults,
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: _SettingsBody(
          settings: settings,
          notifier: notifier,
          showStylusOption: showStylusOption,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      actions: [
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.done),
        ),
      ],
    );
  }
}

// ── Mobile bottom sheet ──────────────────────────────────────────────────────

class _EditorSettingsSheet extends ConsumerWidget {
  const _EditorSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsNotifierProvider);
    final notifier = ref.read(editorSettingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final s = Strings.of(context);

    final showStylusOption = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded,
                      size: 18, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text(s.editorSettings,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  tooltip: s.resetToDefaults,
                  visualDensity: VisualDensity.compact,
                  onPressed: notifier.resetToDefaults,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _SettingsBody(
                settings: settings,
                notifier: notifier,
                showStylusOption: showStylusOption,
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared settings body ─────────────────────────────────────────────────────

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.settings,
    required this.notifier,
    required this.showStylusOption,
    this.compact = false,
  });

  final EditorSettings settings;
  final EditorSettingsNotifier notifier;
  final bool showStylusOption;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final gap = compact ? 10.0 : 16.0;
    final divGap = compact ? 8.0 : 16.0;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Input (Stylus) ────────────────────────────────────────────────
          if (showStylusOption) ...[
            _SectionChip(icon: Icons.touch_app_rounded, label: s.input),
            SizedBox(height: compact ? 6 : 8),
            _StylusTile(
                settings: settings, notifier: notifier, compact: compact),
            SizedBox(height: gap),
            const _ThinDivider(),
            SizedBox(height: divGap),
          ],

          // ── Display ───────────────────────────────────────────────────────
          _SectionChip(icon: Icons.grid_on_rounded, label: s.display),
          SizedBox(height: compact ? 4 : 8),
          _CompactSwitchTile(
            title: s.showGrid,
            subtitle: compact ? null : s.showGridSubtitle,
            icon: Icons.grid_3x3_rounded,
            value: settings.showGrid,
            onChanged: notifier.setShowGrid,
          ),
          _CompactSwitchTile(
            title: s.pixelGridOverlay,
            subtitle: compact ? null : s.pixelGridSubtitle,
            icon: Icons.grain_rounded,
            value: settings.showPixelGrid,
            onChanged: notifier.setShowPixelGrid,
          ),
          if (settings.showPixelGrid) ...[
            SizedBox(height: compact ? 2 : 4),
            _InlineSliderTile(
              label: s.gridOpacity,
              value: settings.pixelGridOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: notifier.setPixelGridOpacity,
            ),
          ],

          SizedBox(height: gap),
          const _ThinDivider(),
          SizedBox(height: divGap),

          _SectionChip(
            icon: Icons.rotate_right_rounded,
            label: s.selectionTransforms,
          ),
          SizedBox(height: compact ? 4 : 8),
          _TransformInterpolationTile(
            settings: settings,
            notifier: notifier,
            compact: compact,
          ),

          SizedBox(height: gap),
          const _ThinDivider(),
          SizedBox(height: divGap),

          // ── Zoom & Navigation ─────────────────────────────────────────────
          _SectionChip(icon: Icons.zoom_in_rounded, label: s.zoomNavigation),
          SizedBox(height: compact ? 4 : 8),
          _InlineSliderTile(
            label: s.zoomSensitivity,
            value: settings.zoomSensitivity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: notifier.setZoomSensitivity,
          ),
          SizedBox(height: compact ? 2 : 6),
          Row(
            children: [
              Expanded(
                child: _MiniSlider(
                  label: s.minZoom,
                  value: settings.minZoom,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) => notifier.setZoomLimits(min: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniSlider(
                  label: s.maxZoom,
                  value: settings.maxZoom,
                  min: 2.0,
                  max: 20.0,
                  onChanged: (v) => notifier.setZoomLimits(max: v),
                ),
              ),
            ],
          ),

          SizedBox(height: gap),
          const _ThinDivider(),
          SizedBox(height: divGap),

          // ── Gestures ──────────────────────────────────────────────────────
          _SectionChip(icon: Icons.gesture_rounded, label: s.gestures),
          SizedBox(height: compact ? 4 : 8),
          _CompactSwitchTile(
            title: s.twoFingerUndo,
            subtitle: compact ? null : s.twoFingerUndoSubtitle,
            icon: Icons.undo_rounded,
            value: settings.twoFingerUndoEnabled,
            onChanged: notifier.setTwoFingerUndoEnabled,
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) => Divider(
      height: 1,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5));
}

class _CompactSwitchTile extends StatelessWidget {
  const _CompactSwitchTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: value
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: value
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSliderTile extends StatelessWidget {
  const _InlineSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSlider extends StatelessWidget {
  const _MiniSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(
              value.toStringAsFixed(1),
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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

class _TransformInterpolationTile extends StatelessWidget {
  const _TransformInterpolationTile({
    required this.settings,
    required this.notifier,
    this.compact = false,
  });

  final EditorSettings settings;
  final EditorSettingsNotifier notifier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Strings.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.transformInterpolation,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              s.transformInterpolationSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: compact ? 10 : 12),
          SegmentedButton<TransformInterpolation>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment<TransformInterpolation>(
                value: TransformInterpolation.nearest,
                label: Text(s.nearestNeighbor),
              ),
              ButtonSegment<TransformInterpolation>(
                value: TransformInterpolation.bilinear,
                label: Text(s.bilinear),
              ),
            ],
            selected: {settings.transformInterpolation},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              notifier.setTransformInterpolation(selection.first);
            },
          ),
        ],
      ),
    );
  }
}

class _StylusTile extends StatelessWidget {
  const _StylusTile({
    required this.settings,
    required this.notifier,
    this.compact = false,
  });

  final EditorSettings settings;
  final EditorSettingsNotifier notifier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStylusMode = settings.inputMode == InputMode.stylusOnly;
    final s = Strings.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border.all(
          color: isStylusMode
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isStylusMode ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isStylusMode
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
      ),
      child: InkWell(
        onTap: notifier.toggleStylusMode,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isStylusMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.draw_outlined,
                  size: 18,
                  color: isStylusMode
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.stylusMode,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    Text(
                      isStylusMode
                          ? s.stylusModeSubtitleOn
                          : s.stylusModeSubtitleOff,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isStylusMode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isStylusMode,
                onChanged: (_) => notifier.toggleStylusMode(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
