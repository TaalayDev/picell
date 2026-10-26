import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

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
    this.onClearAnimations,
    this.onBeforeEdit,
  });

  final RigEditorController controller;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  /// Renders the animation as a GIF to look at; the button is hidden when null.
  final VoidCallback? onPreviewGif;

  /// Opens the ready-made animations; the button is hidden when null.
  final VoidCallback? onPresets;
  final VoidCallback? onClearAnimations;
  final VoidCallback? onBeforeEdit;

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
              _ClipBar(controller: controller, onBeforeEdit: onBeforeEdit),
              _KeyEditBar(controller: controller, onBeforeEdit: onBeforeEdit),
              _Header(
                controller: controller,
                isPlaying: isPlaying,
                onPlayPause: onPlayPause,
                onPreviewGif: onPreviewGif,
                onPresets: onPresets,
                onClearAnimations: onClearAnimations ?? controller.clearAnimations,
                onBeforeEdit: onBeforeEdit,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: rowsHeight.clamp(_rowHeight * 2, 150).toDouble()),
                child: rows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Add bones in Setup to start posing.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
                                      _BoneTrack(
                                          controller: controller,
                                          bone: row.bone,
                                          frames: clip.length,
                                          onBeforeEdit: onBeforeEdit),
                                    for (final chain in chains)
                                      _IkTrack(
                                          controller: controller,
                                          chain: chain,
                                          frames: clip.length,
                                          onBeforeEdit: onBeforeEdit),
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

class _ClipBar extends StatelessWidget {
  const _ClipBar({required this.controller, this.onBeforeEdit});
  final RigEditorController controller;
  final VoidCallback? onBeforeEdit;

  Future<void> _name(BuildContext context, {required bool creating}) async {
    onBeforeEdit?.call();
    var value = creating ? 'Animation' : controller.activeClip.name;
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(creating ? 'New animation clip' : 'Rename animation clip'),
              content: TextFormField(
                  key: const ValueKey('rig-clip-name'),
                  initialValue: value,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Clip name'),
                  onChanged: (text) => value = text,
                  onFieldSubmitted: (text) {
                    if (text.trim().isNotEmpty) Navigator.pop(context, text.trim());
                  }),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
                    },
                    child: Text(creating ? 'Create' : 'Save')),
              ],
            ));
    if (name == null || !context.mounted) return;
    if (creating) {
      controller.createClip(name);
    } else {
      controller.renameClip(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clips = controller.rig.clips.isEmpty ? [controller.activeClip] : controller.rig.clips;
    final selected = controller.selectedBoneId;
    final frozen = selected != null && controller.hasJointFreeze(selected);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        Icon(Icons.video_library_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
          key: const ValueKey('rig-clip-picker'),
          value: controller.activeClip.id,
          isExpanded: true,
          isDense: true,
          dropdownColor: theme.colorScheme.surface,
          style: theme.textTheme.bodySmall,
          items: [
            for (final clip in clips)
              DropdownMenuItem(value: clip.id, child: Text(clip.name, maxLines: 1, overflow: TextOverflow.ellipsis))
          ],
          onChanged: (id) {
            if (id != null) {
              onBeforeEdit?.call();
              controller.selectClip(id);
            }
          },
        ))),
        IconButton(
            key: const ValueKey('rig-new-clip'),
            tooltip: 'New animation clip',
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _name(context, creating: true)),
        PopupMenuButton<String>(
            key: const ValueKey('rig-clip-actions'),
            tooltip: 'Animation clip actions',
            icon: const Icon(Icons.more_horiz, size: 18),
            itemBuilder: (_) => [
                  const PopupMenuItem(value: 'duplicate', child: Text('Duplicate clip')),
                  const PopupMenuItem(value: 'rename', child: Text('Rename clip')),
                  PopupMenuItem(
                      value: 'delete', enabled: controller.rig.clips.isNotEmpty, child: const Text('Delete clip')),
                ],
            onSelected: (action) {
              onBeforeEdit?.call();
              if (action == 'duplicate') controller.duplicateClip();
              if (action == 'rename') _name(context, creating: false);
              if (action == 'delete') controller.deleteClip();
            }),
        IconButton(
            key: const ValueKey('rig-freeze-joint'),
            tooltip: frozen
                ? 'Unfreeze joint (selected frames or whole clip)'
                : 'Freeze joint (selected frames or whole clip)',
            icon: Icon(frozen ? Icons.lock : Icons.lock_open, size: 18),
            onPressed: selected == null
                ? null
                : () {
                    onBeforeEdit?.call();
                    if (frozen) {
                      controller.unfreezeJoint(selected);
                    } else {
                      controller.freezeJoint(selected);
                    }
                  }),
      ]),
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
    required this.onClearAnimations,
    this.onBeforeEdit,
  });

  final RigEditorController controller;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onPreviewGif;
  final VoidCallback? onPresets;
  final VoidCallback onClearAnimations;
  final VoidCallback? onBeforeEdit;

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
            IconButton(
              key: const ValueKey('clear-rig-animations'),
              tooltip: 'Clear all animations and frames',
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              onPressed: controller.canClearAnimations ? onClearAnimations : null,
            ),
            IconButton(
              key: const ValueKey('rig-select-frames'),
              tooltip: 'Select frame range (Shift-click or long-press frames)',
              isSelected: controller.rangeSelectionEnabled,
              icon: const Icon(Icons.select_all, size: 18),
              onPressed: controller.toggleFrameSelection,
            ),
            if (controller.hasFrameSelection) ...[
              _Stepper(
                  label: 'From',
                  value: controller.rangeStart + 1,
                  onChanged: (d) => controller.selectFrameRange(controller.rangeStart + d, controller.rangeEnd)),
              _Stepper(
                  label: 'To',
                  value: controller.rangeEnd + 1,
                  onChanged: (d) => controller.selectFrameRange(controller.rangeStart, controller.rangeEnd + d)),
              IconButton(
                  tooltip: 'Move selected keys left (replaces destination keys)',
                  icon: const Icon(Icons.keyboard_arrow_left, size: 18),
                  onPressed: controller.rangeStart > 0
                      ? () {
                          onBeforeEdit?.call();
                          controller.moveFrameRange(-1);
                        }
                      : null),
              IconButton(
                  tooltip: 'Move selected keys right (replaces destination keys)',
                  icon: const Icon(Icons.keyboard_arrow_right, size: 18),
                  onPressed: controller.rangeEnd < 239
                      ? () {
                          onBeforeEdit?.call();
                          controller.moveFrameRange(1);
                        }
                      : null),
              IconButton(
                  key: const ValueKey('rig-duplicate-range'),
                  tooltip: 'Duplicate selected frames',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: controller.activeClip.length + controller.rangeEnd - controller.rangeStart + 1 <= 240
                      ? () {
                          onBeforeEdit?.call();
                          controller.duplicateFrameRange();
                        }
                      : null),
              IconButton(
                  key: const ValueKey('rig-delete-range'),
                  tooltip: 'Delete selected frames',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    onBeforeEdit?.call();
                    controller.deleteFrameRange();
                  }),
            ],
            IconButton(
                key: const ValueKey('rig-plant-foot'),
                tooltip: 'Plant selected foot for selected frames (current contact point)',
                icon: const Icon(Icons.push_pin_outlined, size: 18),
                onPressed: controller.canPlantFoot
                    ? () {
                        onBeforeEdit?.call();
                        controller.plantFoot();
                      }
                    : null),
            IconButton(
                key: const ValueKey('rig-release-foot'),
                tooltip: 'Release foot plant in selected frames',
                icon: const Icon(Icons.pin_end_outlined, size: 18),
                onPressed: controller.hasFootPlant
                    ? () {
                        onBeforeEdit?.call();
                        controller.releaseFootPlant();
                      }
                    : null),
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
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              onTap: () => controller.selectTimelineFrame(i, extend: HardwareKeyboard.instance.isShiftPressed),
              onLongPress: () {
                if (!controller.rangeSelectionEnabled) controller.toggleFrameSelection();
                controller.selectFrameRange(i, i);
                controller.selectTimelineFrame(i, extend: HardwareKeyboard.instance.isShiftPressed);
              },
              child: Container(
                width: RigTimeline._cell,
                alignment: Alignment.center,
                color: controller.frameInSelection(i)
                    ? theme.colorScheme.primaryContainer
                    : i == controller.time
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : null,
                child: Text(
                  '${i + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: controller.frameInSelection(i)
                        ? theme.colorScheme.onPrimaryContainer
                        : i == controller.time
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
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
  const _BoneTrack({required this.controller, required this.bone, required this.frames, this.onBeforeEdit});
  final VoidCallback? onBeforeEdit;

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
            _KeyDrag(
                controller: controller,
                boneId: bone.id,
                frame: i,
                onBeforeEdit: onBeforeEdit,
                enabled: keys.contains(i) || controller.jointFrozenAt(bone.id, i),
                child: InkWell(
                  key: ValueKey('cell-${bone.id}-$i'),
                  onTap: () {
                    controller.selectBone(bone.id);
                    controller.selectTimelineFrame(i, extend: HardwareKeyboard.instance.isShiftPressed);
                  },
                  child: Container(
                    width: RigTimeline._cell,
                    height: RigTimeline._rowHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.frameInSelection(i)
                          ? theme.colorScheme.primaryContainer
                          : i == controller.time
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : null,
                      border: Border(left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35), width: 0.5)),
                    ),
                    child: controller.jointFrozenAt(bone.id, i)
                        ? Icon(Icons.lock,
                            key: ValueKey('frozen-${bone.id}-$i'),
                            size: 12,
                            color: controller.frameInSelection(i)
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.primary)
                        : keys.contains(i)
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
                )),
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
  const _IkTrack({required this.controller, required this.chain, required this.frames, this.onBeforeEdit});
  final VoidCallback? onBeforeEdit;

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
            _KeyDrag(
                controller: controller,
                boneId: chain.tipBoneId,
                frame: i,
                onBeforeEdit: onBeforeEdit,
                enabled: keys.contains(i),
                child: InkWell(
                  key: ValueKey('ikcell-${chain.id}-$i'),
                  onTap: () {
                    controller.selectIkChain(chain.id);
                    controller.selectTimelineFrame(i, extend: HardwareKeyboard.instance.isShiftPressed);
                  },
                  child: Container(
                    width: RigTimeline._cell,
                    height: RigTimeline._rowHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.frameInSelection(i)
                          ? theme.colorScheme.primaryContainer
                          : i == controller.time
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : null,
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
                )),
        ],
      ),
    );
  }
}

class _KeyEditBar extends StatelessWidget {
  const _KeyEditBar({required this.controller, this.onBeforeEdit});
  final RigEditorController controller;
  final VoidCallback? onBeforeEdit;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    void edit(VoidCallback action) {
      onBeforeEdit?.call();
      action();
    }

    return SizedBox(
        height: 36,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              TextButton(
                  key: const ValueKey('rig-track-scope'),
                  onPressed: () => c.setTimelineScope(selectedOnly: !c.timelineSelectedTracksOnly),
                  child: Text(c.timelineSelectedTracksOnly ? 'Selected tracks' : 'All tracks')),
              IconButton(
                  tooltip: 'Copy keys in range', icon: const Icon(Icons.copy, size: 16), onPressed: c.copyTimelineKeys),
              IconButton(
                  tooltip: 'Paste keys at current frame',
                  icon: const Icon(Icons.content_paste, size: 16),
                  onPressed: c.canPasteTimelineKeys ? () => edit(c.pasteTimelineKeys) : null),
              IconButton(
                  tooltip: 'Move keys left',
                  icon: const Icon(Icons.keyboard_arrow_left, size: 16),
                  onPressed: () => edit(() => c.editTimelineKeys(delta: -1))),
              IconButton(
                  tooltip: 'Move keys right',
                  icon: const Icon(Icons.keyboard_arrow_right, size: 16),
                  onPressed: () => edit(() => c.editTimelineKeys(delta: 1))),
              IconButton(
                  tooltip: 'Delete keys without removing frames',
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: () => edit(() => c.editTimelineKeys(delete: true))),
              PopupMenuButton<RigEasing>(
                  tooltip: 'Set selected keys easing',
                  icon: const Icon(Icons.timeline, size: 16),
                  itemBuilder: (_) => [for (final e in RigEasing.values) PopupMenuItem(value: e, child: Text(e.name))],
                  onSelected: (e) => edit(() => c.editTimelineKeys(easing: e))),
              TextButton(
                  onPressed: () => c.setTimelineScope(ripple: !c.rippleTimeline),
                  child: Text(c.rippleTimeline ? 'Ripple paste: on' : 'Ripple paste: off')),
            ])));
  }
}

class _KeyDrag extends StatefulWidget {
  const _KeyDrag(
      {required this.controller,
      required this.boneId,
      required this.frame,
      required this.enabled,
      required this.child,
      this.onBeforeEdit});
  final RigEditorController controller;
  final String boneId;
  final int frame;
  final bool enabled;
  final Widget child;
  final VoidCallback? onBeforeEdit;
  @override
  State<_KeyDrag> createState() => _KeyDragState();
}

class _KeyDragState extends State<_KeyDrag> {
  double _distance = 0;
  @override
  Widget build(BuildContext context) => GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: !widget.enabled
            ? null
            : (_) {
                widget.onBeforeEdit?.call();
                _distance = 0;
                final c = widget.controller;
                if (!c.selectedBoneIds.contains(widget.boneId)) c.selectBone(widget.boneId);
                c.setTimelineScope(selectedOnly: true);
                if (!c.frameInSelection(widget.frame)) c.selectFrameRange(widget.frame, widget.frame);
              },
        onHorizontalDragUpdate: !widget.enabled ? null : (e) => _distance += e.delta.dx,
        onHorizontalDragEnd: !widget.enabled
            ? null
            : (_) {
                final delta = (_distance / RigTimeline._cell).round();
                if (delta != 0) widget.controller.editTimelineKeys(delta: delta);
              },
        child: widget.child,
      );
}
