import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../pixel/rig/presets/bone_presets.dart';
import '../../../pixel/rig/presets/motion_catalog.dart';
import '../../../pixel/rig/presets/motion_presets.dart';
import '../../../pixel/rig/rig_editor_controller.dart';

/// Lets the user pick a ready-made skeleton and starts placing it: the canvas
/// then shows a box to move and stretch before anything is added.
Future<void> addSkeletonPreset(BuildContext context, RigEditorController controller) async {
  final preset = await showDialog<BonePreset>(
    context: context,
    builder: (_) => const _SkeletonPresetsDialog(),
  );
  if (preset != null) controller.beginPlacement(preset);
}

class _SkeletonPresetsDialog extends StatelessWidget {
  const _SkeletonPresetsDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final figures = BonePresets.all.where((p) => !p.addOn).toList();
    final parts = BonePresets.all.where((p) => p.addOn).toList();

    Widget section(String title, List<BonePreset> presets) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(title, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
            ),
            for (final p in presets) _SkeletonTile(preset: p),
          ],
        );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
              child: Row(
                children: [
                  Expanded(child: Text('Ready-made skeletons', style: theme.textTheme.titleMedium)),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pick one, then move and stretch it over your artwork before adding it.',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  section('Whole figures', figures),
                  section('Parts to add to a bone', parts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({required this.preset});

  final BonePreset preset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('skeleton-${preset.id}'),
      onTap: () => Navigator.pop(context, preset),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(painter: _SkeletonThumb(preset, theme.colorScheme.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${preset.name} · ${preset.bones.length} bones', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    preset.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A preset's bones drawn small, fitted in the box.
class _SkeletonThumb extends CustomPainter {
  _SkeletonThumb(this.preset, this.color);

  final BonePreset preset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the unit box's used area, keeping its proportions.
    var minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (final b in preset.bones) {
      for (final p in [b.head, b.tail]) {
        minX = math.min(minX, p.dx);
        maxX = math.max(maxX, p.dx);
        minY = math.min(minY, p.dy);
        maxY = math.max(maxY, p.dy);
      }
    }
    const pad = 8.0;
    final spanX = math.max(0.001, maxX - minX), spanY = math.max(0.001, maxY - minY);
    final scale = math.min((size.width - 2 * pad) / spanX, (size.height - 2 * pad) / spanY);
    final origin = Offset(
      (size.width - spanX * scale) / 2 - minX * scale,
      (size.height - spanY * scale) / 2 - minY * scale,
    );
    Offset at(Offset u) => origin + u * scale;

    final line = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final joint = Paint()..color = color;
    for (final b in preset.bones) {
      canvas.drawLine(at(b.head), at(b.tail), line);
      canvas.drawCircle(at(b.head), 1.8, joint);
    }
  }

  @override
  bool shouldRepaint(_SkeletonThumb old) => old.preset != preset || old.color != color;
}

// ── Animation presets ───────────────────────────────────────────────────────

/// What the user chose in the animation presets dialog.
class MotionChoice {
  const MotionChoice(this.preset, {required this.intensity, required this.mirror});

  final MotionPreset preset;
  final double intensity;
  final bool mirror;
}

/// Lets the user pick a ready-made animation, how strong it is, and which way
/// it faces. Returns null if cancelled.
Future<MotionChoice?> pickMotionPreset(BuildContext context, RigEditorController controller) {
  return showDialog<MotionChoice>(
    context: context,
    builder: (_) => _MotionPresetsDialog(controller: controller),
  );
}

class _MotionPresetsDialog extends StatefulWidget {
  const _MotionPresetsDialog({required this.controller});

  final RigEditorController controller;

  @override
  State<_MotionPresetsDialog> createState() => _MotionPresetsDialogState();
}

class _MotionPresetsDialogState extends State<_MotionPresetsDialog> {
  double _intensity = 1;
  bool _mirror = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final categories = <String>[];
    for (final p in MotionPresets.all) {
      if (!categories.contains(p.category)) categories.add(p.category);
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Ready-made animations', style: theme.textTheme.titleMedium)),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Text('Strength', style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('motion-intensity'),
                      value: _intensity,
                      min: 0.5,
                      max: 2,
                      divisions: 6,
                      label: '${(_intensity * 100).round()}%',
                      onChanged: (v) => setState(() => _intensity = v),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('${(_intensity * 100).round()}%', textAlign: TextAlign.end, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              key: const ValueKey('motion-mirror'),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text('Face the other way', style: theme.textTheme.bodySmall),
              subtitle: Text('Swaps left and right and flips every swing.', style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              value: _mirror,
              onChanged: (v) => setState(() => _mirror = v),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final category in categories) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(category, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
                    ),
                    for (final p in MotionPresets.all.where((p) => p.category == category))
                      _MotionTile(
                        preset: p,
                        controller: widget.controller,
                        mirror: _mirror,
                        onPick: () => Navigator.pop(context, MotionChoice(p, intensity: _intensity, mirror: _mirror)),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotionTile extends StatelessWidget {
  const _MotionTile({
    required this.preset,
    required this.controller,
    required this.mirror,
    required this.onPick,
  });

  final MotionPreset preset;
  final RigEditorController controller;
  final bool mirror;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    // Whether the rig has what this animation needs.
    final String status;
    final bool usable;
    if (preset.target == MotionTarget.roles) {
      final c = controller.motionCoverage(preset, mirror: mirror);
      usable = c.matched > 0;
      status = usable ? '${c.matched} of ${c.total} bones found' : 'No bones named like ${_examples(preset)}';
    } else {
      usable = controller.selectedBone != null;
      status = usable
          ? (preset.target == MotionTarget.selectedChain ? 'Selected bone and below' : 'Selected bone')
          : 'Select a bone first';
    }

    return InkWell(
      key: ValueKey('motion-${preset.id}'),
      onTap: onPick,
      child: Opacity(
        opacity: usable ? 1 : 0.55,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(preset.name, style: theme.textTheme.bodyMedium)),
                  Text(
                    '${preset.frames} frames · ${preset.fps} fps${preset.loop ? '' : ' · once'}',
                    style: theme.textTheme.labelSmall?.copyWith(color: muted, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(preset.description, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              const SizedBox(height: 4),
              Text(
                status,
                style: theme.textTheme.labelSmall?.copyWith(color: usable ? theme.colorScheme.primary : theme.colorScheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _examples(MotionPreset preset) => preset.roles.take(3).join(', ');
}
