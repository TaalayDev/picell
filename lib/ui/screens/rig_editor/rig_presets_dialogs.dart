import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/theme.dart';

import '../../../l10n/strings.dart';
import '../../../pixel/rig/presets/bone_presets.dart';
import '../../../pixel/rig/presets/motion_catalog.dart';
import '../../../pixel/rig/presets/motion_presets.dart';
import '../../../data/models/rig/rig.dart';
import '../../../pixel/rig/rig_editor_controller.dart';
import '../../../pixel/rig/rig_solver.dart';
import '../../widgets/pv/pv.dart';
import 'rig_motion_configuration.dart';

export 'rig_motion_configuration.dart' show MotionChoice;

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
    final muted = theme.colorScheme.onSurfaceVariant;
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
                  Expanded(child: Text(Strings.of(context).rigSkeletonsTitle, style: theme.textTheme.titleMedium)),
                  IconButton(
                    tooltip: Strings.of(context).close,
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
                  Strings.of(context).rigSkeletonsHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  section(Strings.of(context).rigWholeFigures, figures),
                  section(Strings.of(context).rigPartsToAdd, parts),
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
    final pv = context.pv;
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
                color: pv.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pv.divider),
              ),
              child: CustomPaint(painter: _SkeletonThumb(preset, PvTokens.rigSetup)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Strings.of(context).rigPresetBones(preset.name, preset.bones.length),
                      style: pv.body(size: 14, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    preset.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

/// Pick a preset, then preview and configure it before applying.
Future<MotionChoice?> pickMotionPreset(BuildContext context, RigEditorController controller) async {
  final preset = await showDialog<MotionPreset>(
    context: context,
    builder: (_) => _MotionPresetsDialog(controller: controller),
  );
  if (preset == null || !context.mounted) return null;
  return configureMotionPreset(context, controller, preset);
}

class _MotionPresetsDialog extends StatefulWidget {
  const _MotionPresetsDialog({required this.controller});

  final RigEditorController controller;

  @override
  State<_MotionPresetsDialog> createState() => _MotionPresetsDialogState();
}

class _MotionPresetsDialogState extends State<_MotionPresetsDialog> with SingleTickerProviderStateMixin {
  /// Time since the dialog opened; every preview picks its frame from it, so
  /// one ticker drives them all and only their painters redraw.
  final _clock = ValueNotifier(Duration.zero);
  late final Ticker _ticker = createTicker((elapsed) => _clock.value = elapsed);

  /// Null shows every category.
  String? _category;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final s = Strings.of(context);
    final categories = <String>[];
    for (final p in MotionPresets.all) {
      if (!categories.contains(p.category)) categories.add(p.category);
    }
    final shown = [
      for (final c in categories)
        if (_category == null || _category == c) c
    ];

    return Dialog(
      backgroundColor: pv.surface,
      insetPadding: const EdgeInsets.all(PvSpace.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pv.cardRadius.clamp(8, 20)),
        side: BorderSide(color: pv.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(PvSpace.xl - 4, PvSpace.lg, PvSpace.sm, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: ShapeDecoration(shape: const PixelCutBorder(), gradient: pv.gradient),
                    child: Icon(Icons.directions_run, size: 18, color: pv.ink),
                  ),
                  const SizedBox(width: PvSpace.md),
                  Expanded(
                    child: Text(s.rigAnimationsTitle, style: pv.body(size: 18, weight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: s.close,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(PvSpace.xl - 4, PvSpace.md, PvSpace.xl - 4, PvSpace.md),
              child: Row(
                children: [
                  _CategoryChip(
                      label: s.all, selected: _category == null, onTap: () => setState(() => _category = null)),
                  for (final c in categories)
                    _CategoryChip(
                      label: c,
                      icon: _categoryIcon(c),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: pv.divider),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = PvSpace.md;
                  const side = PvSpace.xl - 4;
                  final columns = constraints.maxWidth >= 600 ? 2 : 1;
                  final tileWidth = (constraints.maxWidth - side * 2 - gap * (columns - 1)) / columns;
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(side, PvSpace.sm, side, PvSpace.xl),
                    children: [
                      for (final category in shown) ...[
                        PvSectionHeader(title: category, icon: _categoryIcon(category), padding: EdgeInsets.zero),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final p in MotionPresets.all.where((p) => p.category == category))
                              SizedBox(
                                width: tileWidth,
                                child: _MotionTile(
                                  preset: p,
                                  controller: widget.controller,
                                  mirror: false,
                                  clock: _clock,
                                  onPick: () => Navigator.pop(context, p),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: PvSpace.sm),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) => switch (category) {
        'Character' => Icons.accessibility_new,
        'Animal' => Icons.pets,
        _ => Icons.timeline,
      };
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final fg = selected ? pv.ink : pv.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: PvSpace.sm),
      child: PvPressable(
        onTap: onTap,
        semanticLabel: label,
        builder: (context, hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: PvSpace.md),
          decoration: BoxDecoration(
            gradient: selected ? pv.gradient : null,
            color: selected ? null : (hovered ? pv.surfaceHigh : pv.background),
            borderRadius: BorderRadius.circular(pv.chipRadius.clamp(6, 16)),
            border: Border.all(color: selected ? Colors.transparent : (hovered ? pv.accent : pv.divider)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(label, style: pv.body(size: 13, weight: FontWeight.w600, color: fg)),
            ],
          ),
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
    required this.clock,
    required this.onPick,
  });

  final MotionPreset preset;
  final RigEditorController controller;
  final bool mirror;
  final ValueListenable<Duration> clock;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final s = Strings.of(context);

    // Whether the rig has what this animation needs.
    final String status;
    final Color statusColor;
    final IconData statusIcon;
    final bool usable;
    if (preset.target == MotionTarget.roles) {
      final c = controller.motionCoverage(preset, mirror: mirror);
      usable = c.matched > 0;
      final complete = c.matched >= c.total;
      status = usable ? s.rigBonesFound(c.matched, c.total) : s.rigNoBonesNamedLike(_examples(preset));
      statusColor = !usable ? pv.err : (complete ? pv.ok : pv.warn);
      statusIcon = !usable ? Icons.link_off : (complete ? Icons.check_circle_outline : Icons.error_outline);
    } else {
      usable = controller.selectedBone != null;
      status = usable
          ? (preset.target == MotionTarget.selectedChain ? s.rigSelectedBoneAndBelow : s.rigSelectedBone)
          : s.rigSelectBoneFirstShort;
      statusColor = usable ? pv.ok : pv.warn;
      statusIcon = usable ? Icons.ads_click : Icons.touch_app_outlined;
    }

    return Opacity(
      opacity: usable ? 1 : 0.6,
      child: PvCard(
        key: ValueKey('motion-${preset.id}'),
        onTap: onPick,
        semanticLabel: preset.name,
        padding: const EdgeInsets.all(PvSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MotionPreview(preset: preset, clock: clock),
            const SizedBox(width: PvSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pv.body(size: 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: PvSpace.xxs),
                  Tooltip(
                    message: preset.description,
                    waitDuration: const Duration(milliseconds: 600),
                    child: Text(
                      preset.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.35),
                    ),
                  ),
                  const SizedBox(height: PvSpace.sm),
                  PvChip(
                    dense: true,
                    icon: preset.loop ? Icons.repeat : Icons.play_arrow_rounded,
                    label: preset.loop
                        ? s.rigMotionMeta(preset.frames, preset.fps)
                        : s.rigMotionMetaOnce(preset.frames, preset.fps),
                  ),
                  const SizedBox(height: 6),
                  // A line rather than a chip: "no bones named like ..." can be long.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          status,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: pv.body(size: 11.5, color: statusColor, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _examples(MotionPreset preset) => preset.roles.take(3).join(', ');
}

/// A preset playing on the skeleton it was written for, as a small stick
/// figure: the left side in the accent, the right in the primary color.
class _MotionPreview extends StatelessWidget {
  const _MotionPreview({required this.preset, required this.clock});

  final MotionPreset preset;
  final ValueListenable<Duration> clock;

  static const double size = 76;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: pv.background,
        borderRadius: BorderRadius.circular(pv.chipRadius.clamp(6, 12)),
        border: Border.all(color: pv.divider),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _MotionPreviewPainter(
            frames: _MotionPreviewFrames.of(preset),
            fps: preset.fps,
            clock: clock,
            left: pv.accent,
            right: pv.primary,
            centre: pv.textPrimary,
            ground: pv.divider,
          ),
        ),
      ),
    );
  }
}

/// Bone segments of every frame of a preset, solved once and kept.
class _MotionPreviewFrames {
  _MotionPreviewFrames(this.frames, this.bounds, this.groundY);

  /// Per frame: (head, tail, side) with side -1 left, 1 right, 0 centre.
  final List<List<(Offset, Offset, int)>> frames;
  final Rect bounds;
  final double? groundY;

  static final _cache = <String, _MotionPreviewFrames>{};

  static _MotionPreviewFrames of(MotionPreset preset) => _cache[preset.id] ??= _solve(preset);

  static BonePreset _skeletonFor(MotionPreset p) {
    final roles = p.roles.toSet();
    if (p.target != MotionTarget.roles) return BonePresets.tail;
    if (roles.contains('wing_1')) return BonePresets.bird;
    if (roles.contains('fish_1')) return BonePresets.fish;
    if (roles.contains('fl_upper')) return BonePresets.quadruped;
    return p.id.startsWith('front_') ? BonePresets.humanoid : BonePresets.humanoidSide;
  }

  static _MotionPreviewFrames _solve(MotionPreset preset) {
    var n = 0;
    final bones = BonePresetBuilder.build(
      _skeletonFor(preset),
      box: const Rect.fromLTWH(0, 0, 64, 64),
      snap: (o) => o,
      newId: () => 'preview-${n++}',
    ).bones;
    final root = bones.firstWhere((b) => b.parentId == null, orElse: () => bones.first);
    final built = MotionBuilder.build(preset, bones: bones, canvasHeight: 64, selectedBoneId: root.id);
    final rig = Rig(id: 'preview', stateId: 0, bones: bones);
    final clip = RigClip(
      id: 'preview',
      name: preset.name,
      fps: preset.fps,
      length: preset.frames,
      loop: preset.loop,
      keyframes: built.keyframes,
    );

    var bounds = Rect.zero;
    var first = true;
    final frames = <List<(Offset, Offset, int)>>[];
    for (var f = 0; f < preset.frames; f++) {
      final world = RigSolver.solveClip(rig, clip, f.toDouble()).world;
      final segments = <(Offset, Offset, int)>[];
      for (final b in bones) {
        final m = world[b.id];
        if (m == null) continue;
        final a = m.apply(b.head), t = m.apply(b.tail);
        final side = b.name.endsWith('_l') ? -1 : (b.name.endsWith('_r') ? 1 : 0);
        segments.add((a, t, side));
        final r = Rect.fromPoints(a, t);
        bounds = first ? r : bounds.expandToInclude(r);
        first = false;
      }
      frames.add(segments);
    }
    // Characters get a floor line under their rest-pose feet.
    final standing = preset.category == 'Character' && preset.id != 'fall';
    double? ground;
    if (standing && frames.isNotEmpty) {
      ground = frames.first.map((s) => math.max(s.$1.dy, s.$2.dy)).reduce(math.max);
    }
    return _MotionPreviewFrames(frames, bounds, ground);
  }
}

class _MotionPreviewPainter extends CustomPainter {
  _MotionPreviewPainter({
    required this.frames,
    required this.fps,
    required this.clock,
    required this.left,
    required this.right,
    required this.centre,
    required this.ground,
  }) : super(repaint: clock);

  final _MotionPreviewFrames frames;
  final int fps;
  final ValueListenable<Duration> clock;
  final Color left, right, centre, ground;

  @override
  void paint(Canvas canvas, Size size) {
    if (frames.frames.isEmpty) return;
    final count = frames.frames.length;
    // One-shot clips rest a moment on their last pose before playing again.
    final hold = count + fps ~/ 2;
    final tick = clock.value.inMicroseconds * fps ~/ Duration.microsecondsPerSecond;
    final frame = math.min(tick % hold, count - 1);

    const pad = 8.0;
    final b = frames.bounds;
    final scale = math.min(
      (size.width - 2 * pad) / math.max(b.width, 1),
      (size.height - 2 * pad) / math.max(b.height, 1),
    );
    final origin = Offset(
      (size.width - b.width * scale) / 2 - b.left * scale,
      (size.height - b.height * scale) / 2 - b.top * scale,
    );
    Offset at(Offset p) => origin + p * scale;

    if (frames.groundY case final y?) {
      final gy = at(Offset(0, y)).dy + 1.5;
      canvas.drawLine(
          Offset(pad - 2, gy),
          Offset(size.width - pad + 2, gy),
          Paint()
            ..color = ground
            ..strokeWidth = 1);
    }

    final segments = frames.frames[frame];
    // Centre bones over the far side, the near side on top.
    for (final pass in const [1, 0, -1]) {
      final paint = Paint()
        ..color = switch (pass) { -1 => left, 1 => right, _ => centre }
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (final (a, t, side) in segments) {
        if (side != pass) continue;
        canvas.drawLine(at(a), at(t), paint);
        canvas.drawCircle(at(a), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MotionPreviewPainter old) =>
      old.frames != frames || old.left != left || old.right != right || old.centre != centre;
}
