import 'package:flutter/material.dart';

import '../../../data/models/rig/rig.dart';
import '../../../pixel/rig/rig_editor_controller.dart';

/// Animate mode's bottom panel: playback and clip settings on top, then one
/// row per bone with a diamond on every frame where it is keyed.
class RigTimeline extends StatelessWidget {
  const RigTimeline({
    super.key,
    required this.controller,
    required this.isPlaying,
    required this.onPlayPause,
    this.onPreviewGif,
    this.onPresets,
  });

  final RigEditorController controller;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  /// Renders the animation as a GIF to look at; the button is hidden when null.
  final VoidCallback? onPreviewGif;

  /// Opens the ready-made animations; the button is hidden when null.
  final VoidCallback? onPresets;

  static const double _cell = 28;
  static const double _rowHeight = 24;
  static const double _labelWidth = 112;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final clip = controller.activeClip;
        final rows = controller.tree;
        final chains = controller.rig.ikChains;
        final rowsHeight = (rows.length + chains.length + 1) * _rowHeight;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                controller: controller,
                isPlaying: isPlaying,
                onPlayPause: onPlayPause,
                onPreviewGif: onPreviewGif,
                onPresets: onPresets,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: rowsHeight.clamp(_rowHeight * 2, 150).toDouble()),
                child: rows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Add bones in Setup to start posing.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _labelWidth,
                              child: Column(
                                children: [
                                  const SizedBox(height: _rowHeight),
                                  for (final row in rows)
                                    _Label(controller: controller, bone: row.bone, depth: row.depth),
                                  for (final chain in chains) _IkLabel(controller: controller, chain: chain),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                  children: [
                                    _Ruler(controller: controller, frames: clip.length),
                                    for (final row in rows)
                                      _BoneTrack(controller: controller, bone: row.bone, frames: clip.length),
                                    for (final chain in chains)
                                      _IkTrack(controller: controller, chain: chain, frames: clip.length),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onPreviewGif,
    required this.onPresets,
  });

  final RigEditorController controller;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onPreviewGif;
  final VoidCallback? onPresets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clip = controller.activeClip;
    final mono = theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace');

    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              tooltip: isPlaying ? 'Pause' : 'Play',
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 18),
              onPressed: onPlayPause,
            ),
            IconButton(
              tooltip: 'Previous frame',
              icon: const Icon(Icons.skip_previous, size: 18),
              onPressed: controller.time > 0 ? () => controller.setTime(controller.time - 1) : null,
            ),
            SizedBox(
              width: 74,
              child: Text('${controller.time + 1} / ${clip.length}', textAlign: TextAlign.center, style: mono),
            ),
            IconButton(
              tooltip: 'Next frame',
              icon: const Icon(Icons.skip_next, size: 18),
              onPressed: controller.time < clip.length - 1 ? () => controller.setTime(controller.time + 1) : null,
            ),
            const SizedBox(width: 8),
            _Stepper(
              label: 'Frames',
              value: clip.length,
              onChanged: (delta) => controller.setClipLength(clip.length + delta),
            ),
            const SizedBox(width: 8),
            _Stepper(label: 'FPS', value: clip.fps, onChanged: (delta) => controller.setFps(clip.fps + delta)),
            IconButton(
              tooltip: clip.loop ? 'Looping' : 'Plays once',
              isSelected: clip.loop,
              icon: Icon(clip.loop ? Icons.repeat_on : Icons.repeat, size: 18),
              onPressed: () => controller.setLoop(!clip.loop),
            ),
            IconButton(
              tooltip: 'Copy this frame\'s pose',
              icon: const Icon(Icons.copy_all, size: 18),
              onPressed: controller.copyPose,
            ),
            IconButton(
              tooltip: 'Paste pose here',
              icon: const Icon(Icons.paste, size: 18),
              onPressed: controller.canPastePose ? controller.pastePose : null,
            ),
            if (onPresets != null)
              IconButton(
                key: const ValueKey('motion-presets-button'),
                tooltip: 'Ready-made animations',
                icon: const Icon(Icons.movie_filter_outlined, size: 18),
                onPressed: onPresets,
              ),
            if (onPreviewGif != null)
              IconButton(
                tooltip: 'Preview as GIF',
                icon: const Icon(Icons.gif_box_outlined, size: 18),
                onPressed: onPreviewGif,
              ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        IconButton(
          tooltip: 'Fewer $label',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove, size: 14),
          onPressed: () => onChanged(-1),
        ),
        SizedBox(
          width: 24,
          child: Text('$value',
              textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace')),
        ),
        IconButton(
          tooltip: 'More $label',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add, size: 14),
          onPressed: () => onChanged(1),
        ),
      ],
    );
  }
}

class _Ruler extends StatelessWidget {
  const _Ruler({required this.controller, required this.frames});

  final RigEditorController controller;
  final int frames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: RigTimeline._rowHeight,
      child: Row(
        children: [
          for (var i = 0; i < frames; i++)
            InkWell(
              key: ValueKey('frame-$i'),
              onTap: () => controller.setTime(i),
              child: Container(
                width: RigTimeline._cell,
                alignment: Alignment.center,
                color: i == controller.time ? theme.colorScheme.primary.withValues(alpha: 0.2) : null,
                child: Text(
                  '${i + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: i == controller.time
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.controller, required this.bone, required this.depth});

  final RigEditorController controller;
  final Bone bone;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = controller.selectedBoneId == bone.id;
    return InkWell(
      onTap: () => controller.selectBone(bone.id),
      child: Container(
        height: RigTimeline._rowHeight,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 10 + depth * 10.0, right: 4),
        color: selected ? theme.colorScheme.primary.withValues(alpha: 0.14) : null,
        child: Text(
          bone.name,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: selected ? theme.colorScheme.primary : null),
        ),
      ),
    );
  }
}

class _BoneTrack extends StatelessWidget {
  const _BoneTrack({required this.controller, required this.bone, required this.frames});

  final RigEditorController controller;
  final Bone bone;
  final int frames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = controller.selectedBoneId == bone.id;
    final keys = controller.keyTimes(bone.id);
    final driven = controller.isIkDriven(bone.id);

    return Container(
      height: RigTimeline._rowHeight,
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          for (var i = 0; i < frames; i++)
            InkWell(
              key: ValueKey('cell-${bone.id}-$i'),
              onTap: () {
                controller.selectBone(bone.id);
                controller.setTime(i);
              },
              child: Container(
                width: RigTimeline._cell,
                height: RigTimeline._rowHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == controller.time ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
                  border: Border(left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35), width: 0.5)),
                ),
                child: keys.contains(i)
                    ? Opacity(
                        // An IK chain steering this bone overrides its own keys.
                        opacity: driven ? 0.35 : 1,
                        child: Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            key: ValueKey('key-${bone.id}-$i'),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: controller.keyAt(bone.id, i)?.easing == RigEasing.stepped
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.primary,
                              border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 0.5),
                            ),
                          ),
                        ))
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _IkLabel extends StatelessWidget {
  const _IkLabel({required this.controller, required this.chain});

  final RigEditorController controller;
  final IkChain chain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = controller.selectedIkChain?.id == chain.id;
    return InkWell(
      onTap: () => controller.selectIkChain(chain.id),
      child: Container(
        height: RigTimeline._rowHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 10, right: 4),
        color: selected ? theme.colorScheme.tertiary.withValues(alpha: 0.14) : null,
        child: Row(
          children: [
            Icon(Icons.gps_fixed, size: 12, color: theme.colorScheme.tertiary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                chain.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the chain's target is keyed.
class _IkTrack extends StatelessWidget {
  const _IkTrack({required this.controller, required this.chain, required this.frames});

  final RigEditorController controller;
  final IkChain chain;
  final int frames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = controller.selectedIkChain?.id == chain.id;
    final keys = controller.ikKeyTimes(chain.id);

    return Container(
      height: RigTimeline._rowHeight,
      color: selected ? theme.colorScheme.tertiary.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          for (var i = 0; i < frames; i++)
            InkWell(
              key: ValueKey('ikcell-${chain.id}-$i'),
              onTap: () {
                controller.selectIkChain(chain.id);
                controller.setTime(i);
              },
              child: Container(
                width: RigTimeline._cell,
                height: RigTimeline._rowHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == controller.time ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
                  border: Border(left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35), width: 0.5)),
                ),
                child: keys.contains(i)
                    ? Container(
                        key: ValueKey('ikkey-${chain.id}-$i'),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          // A round key, to tell targets from bone keys at a glance.
                          shape: BoxShape.circle,
                          color: theme.colorScheme.tertiary,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 0.5),
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
