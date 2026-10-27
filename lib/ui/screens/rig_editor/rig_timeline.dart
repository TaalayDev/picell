import 'rig_curve_editor.dart';
import 'rig_panels.dart' show rigEasingName;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../../l10n/strings.dart';
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                constraints: BoxConstraints(maxHeight: rowsHeight.clamp(_rowHeight * 2, 156).toDouble()),
                child: rows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          Strings.of(context).rigAddBonesHint,
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
              title: Text(creating ? Strings.of(context).rigNewClip : Strings.of(context).rigRenameClip),
              content: TextFormField(
                  key: const ValueKey('rig-clip-name'),
                  initialValue: value,
                  autofocus: true,
                  decoration: InputDecoration(labelText: Strings.of(context).rigClipName),
                  onChanged: (text) => value = text,
                  onFieldSubmitted: (text) {
                    if (text.trim().isNotEmpty) Navigator.pop(context, text.trim());
                  }),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(Strings.of(context).cancel)),
                FilledButton(
                    onPressed: () {
                      if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
                    },
                    child: Text(creating ? Strings.of(context).create : Strings.of(context).save)),
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
            tooltip: Strings.of(context).rigNewClip,
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _name(context, creating: true)),
        PopupMenuButton<String>(
            key: const ValueKey('rig-clip-actions'),
            tooltip: Strings.of(context).rigClipActions,
            icon: const Icon(Icons.more_horiz, size: 18),
            itemBuilder: (_) => [
                  PopupMenuItem(value: 'duplicate', child: Text(Strings.of(context).rigDuplicateClip)),
                  PopupMenuItem(value: 'rename', child: Text(Strings.of(context).rigRenameClipItem)),
                  PopupMenuItem(
                      value: 'delete',
                      enabled: controller.rig.clips.isNotEmpty,
                      child: Text(Strings.of(context).rigDeleteClip)),
                ],
            onSelected: (action) {
              onBeforeEdit?.call();
              if (action == 'duplicate') controller.duplicateClip();
              if (action == 'rename') _name(context, creating: false);
              if (action == 'delete') controller.deleteClip();
            }),
        IconButton(
            key: const ValueKey('rig-freeze-joint'),
            tooltip: frozen ? Strings.of(context).rigUnfreezeRange : Strings.of(context).rigFreezeRange,
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

    return Container(
      height: 40,
      color: theme.colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              tooltip: isPlaying ? Strings.of(context).pause : Strings.of(context).play,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 18),
              onPressed: onPlayPause,
            ),
            IconButton(
              key: const ValueKey('rig-auto-key'),
              tooltip: controller.autoKey ? Strings.of(context).rigAutoKeyOn : Strings.of(context).rigAutoKeyOff,
              isSelected: controller.autoKey,
              color: controller.autoKey ? theme.colorScheme.error : null,
              icon: Icon(controller.autoKey ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined, size: 18),
              onPressed: () => controller.autoKey = !controller.autoKey,
            ),
            if (controller.hasPendingPose) ...[
              TextButton.icon(
                key: const ValueKey('rig-key-pending'),
                onPressed: controller.keyPending,
                icon: const Icon(Icons.vpn_key, size: 14),
                label: Text(Strings.of(context).rigKeyPose),
              ),
              IconButton(
                key: const ValueKey('rig-discard-pending'),
                tooltip: Strings.of(context).rigDiscardUnkeyed,
                icon: const Icon(Icons.undo, size: 18),
                onPressed: controller.discardPending,
              ),
            ],
            IconButton(
              tooltip: Strings.of(context).rigPrevFrame,
              icon: const Icon(Icons.skip_previous, size: 18),
              onPressed: controller.time > 0 ? () => controller.setTime(controller.time - 1) : null,
            ),
            SizedBox(
              width: 74,
              child: Text('${controller.time + 1} / ${clip.length}', textAlign: TextAlign.center, style: mono),
            ),
            IconButton(
              tooltip: Strings.of(context).rigNextFrame,
              icon: const Icon(Icons.skip_next, size: 18),
              onPressed: controller.time < clip.length - 1 ? () => controller.setTime(controller.time + 1) : null,
            ),
            const _Sep(),
            _Stepper(
              label: Strings.of(context).rigFrames,
              value: clip.length,
              onChanged: (delta) => controller.setClipLength(clip.length + delta),
            ),
            const SizedBox(width: 4),
            _Stepper(
                label: Strings.of(context).fps,
                value: clip.fps,
                onChanged: (delta) => controller.setFps(clip.fps + delta)),
            IconButton(
              tooltip: clip.loop ? Strings.of(context).rigLooping : Strings.of(context).rigPlaysOnce,
              isSelected: clip.loop,
              icon: Icon(clip.loop ? Icons.repeat_on : Icons.repeat, size: 18),
              onPressed: () => controller.setLoop(!clip.loop),
            ),
            const _Sep(),
            PopupMenuButton<bool>(
              key: const ValueKey('rig-mirror-pose'),
              tooltip: Strings.of(context).rigMirrorFramePose,
              enabled: controller.canMirrorPose,
              icon: const Icon(Icons.flip, size: 18),
              onSelected: (reflect) {
                onBeforeEdit?.call();
                controller.mirrorPose(reflect: reflect);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: false, child: Text(Strings.of(context).rigSwapLeftRight)),
                PopupMenuItem(value: true, child: Text(Strings.of(context).rigMirrorCentre)),
              ],
            ),
            if (controller.hasLoopSeamIssue)
              TextButton.icon(
                key: const ValueKey('rig-fix-loop'),
                onPressed: () {
                  onBeforeEdit?.call();
                  controller.fixLoopSeam();
                },
                icon: const Icon(Icons.sync_problem, size: 14),
                label: Text(Strings.of(context).rigFixLoop),
              ),
            IconButton(
              tooltip: Strings.of(context).rigCopyPose,
              icon: const Icon(Icons.copy_all, size: 18),
              onPressed: controller.copyPose,
            ),
            IconButton(
              tooltip: Strings.of(context).rigPastePose,
              icon: const Icon(Icons.paste, size: 18),
              onPressed: controller.canPastePose ? controller.pastePose : null,
            ),
            IconButton(
              key: const ValueKey('clear-rig-animations'),
              tooltip: Strings.of(context).rigClearAll,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              onPressed: controller.canClearAnimations ? onClearAnimations : null,
            ),
            const _Sep(),
            IconButton(
              key: const ValueKey('rig-select-frames'),
              tooltip: Strings.of(context).rigSelectRange,
              isSelected: controller.rangeSelectionEnabled,
              icon: const Icon(Icons.select_all, size: 18),
              onPressed: controller.toggleFrameSelection,
            ),
            if (controller.hasFrameSelection) ...[
              _Stepper(
                  label: Strings.of(context).rigFrom,
                  value: controller.rangeStart + 1,
                  onChanged: (d) => controller.selectFrameRange(controller.rangeStart + d, controller.rangeEnd)),
              _Stepper(
                  label: Strings.of(context).rigTo,
                  value: controller.rangeEnd + 1,
                  onChanged: (d) => controller.selectFrameRange(controller.rangeStart, controller.rangeEnd + d)),
              IconButton(
                  tooltip: Strings.of(context).rigMoveKeysLeftReplace,
                  icon: const Icon(Icons.keyboard_arrow_left, size: 18),
                  onPressed: controller.rangeStart > 0
                      ? () {
                          onBeforeEdit?.call();
                          controller.moveFrameRange(-1);
                        }
                      : null),
              IconButton(
                  tooltip: Strings.of(context).rigMoveKeysRightReplace,
                  icon: const Icon(Icons.keyboard_arrow_right, size: 18),
                  onPressed: controller.rangeEnd < 239
                      ? () {
                          onBeforeEdit?.call();
                          controller.moveFrameRange(1);
                        }
                      : null),
              IconButton(
                  key: const ValueKey('rig-duplicate-range'),
                  tooltip: Strings.of(context).rigDuplicateFrames,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: controller.activeClip.length + controller.rangeEnd - controller.rangeStart + 1 <= 240
                      ? () {
                          onBeforeEdit?.call();
                          controller.duplicateFrameRange();
                        }
                      : null),
              IconButton(
                  key: const ValueKey('rig-delete-range'),
                  tooltip: Strings.of(context).rigDeleteFrames,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    onBeforeEdit?.call();
                    controller.deleteFrameRange();
                  }),
            ],
            const _Sep(),
            IconButton(
                key: const ValueKey('rig-plant-foot'),
                tooltip: Strings.of(context).rigPlantFoot,
                icon: const Icon(Icons.push_pin_outlined, size: 18),
                onPressed: controller.canPlantFoot
                    ? () {
                        onBeforeEdit?.call();
                        controller.plantFoot();
                      }
                    : null),
            IconButton(
                key: const ValueKey('rig-release-foot'),
                tooltip: Strings.of(context).rigReleaseFoot,
                icon: const Icon(Icons.pin_end_outlined, size: 18),
                onPressed: controller.hasFootPlant
                    ? () {
                        onBeforeEdit?.call();
                        controller.releaseFootPlant();
                      }
                    : null),
            const _Sep(),
            if (onPresets != null)
              IconButton(
                key: const ValueKey('motion-presets-button'),
                tooltip: Strings.of(context).rigAnimationsTitle,
                icon: const Icon(Icons.movie_filter_outlined, size: 18),
                onPressed: onPresets,
              ),
            if (onPreviewGif != null)
              IconButton(
                tooltip: Strings.of(context).rigPreviewGif,
                icon: const Icon(Icons.gif_box_outlined, size: 18),
                onPressed: onPreviewGif,
              ),
          ],
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
      );
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
          tooltip: Strings.of(context).rigFewer(label),
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
          tooltip: Strings.of(context).rigMore(label),
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
                color: controller.frameInSelection(i) ? theme.colorScheme.primaryContainer : null,
                child: Container(
                  width: i == controller.time ? 22 : null,
                  height: i == controller.time ? 20 : null,
                  alignment: Alignment.center,
                  decoration: i == controller.time
                      ? BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(10))
                      : null,
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: controller.frameInSelection(i)
                          ? theme.colorScheme.onPrimaryContainer
                          : i == controller.time
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                      fontWeight: i == controller.time ? FontWeight.w700 : null,
                    ),
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
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.14) : null,
          border: Border(
            left: BorderSide(color: selected ? theme.colorScheme.primary : Colors.transparent, width: 2),
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.account_tree_outlined,
                size: 12, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                bone.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: selected ? theme.colorScheme.primary : null),
              ),
            ),
          ],
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
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25), width: 0.5)),
      ),
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
                      border: Border(
                        left: i == controller.time
                            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                            : BorderSide(color: theme.dividerColor.withValues(alpha: 0.35), width: 0.5),
                      ),
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
                                          : controller.keyAt(bone.id, i)?.curve != null
                                              ? theme.colorScheme.secondary
                                              : theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                          color:
                                              i == controller.time ? Colors.white : Colors.black.withValues(alpha: 0.5),
                                          width: i == controller.time ? 1.5 : 0.5),
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
                      border: Border(
                        left: i == controller.time
                            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                            : BorderSide(color: theme.dividerColor.withValues(alpha: 0.35), width: 0.5),
                      ),
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
                  child: Text(c.timelineSelectedTracksOnly
                      ? Strings.of(context).rigSelectedTracks
                      : Strings.of(context).rigAllTracks)),
              IconButton(
                  tooltip: Strings.of(context).rigCopyKeys,
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: c.copyTimelineKeys),
              IconButton(
                  tooltip: Strings.of(context).rigPasteKeys,
                  icon: const Icon(Icons.content_paste, size: 16),
                  onPressed: c.canPasteTimelineKeys ? () => edit(c.pasteTimelineKeys) : null),
              IconButton(
                  tooltip: Strings.of(context).rigMoveKeysLeft,
                  icon: const Icon(Icons.keyboard_arrow_left, size: 16),
                  onPressed: () => edit(() => c.editTimelineKeys(delta: -1))),
              IconButton(
                  tooltip: Strings.of(context).rigMoveKeysRight,
                  icon: const Icon(Icons.keyboard_arrow_right, size: 16),
                  onPressed: () => edit(() => c.editTimelineKeys(delta: 1))),
              IconButton(
                  tooltip: Strings.of(context).rigDeleteKeys,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: () => edit(() => c.editTimelineKeys(delete: true))),
              PopupMenuButton<int>(
                  tooltip: Strings.of(context).rigSetEasing,
                  icon: const Icon(Icons.timeline, size: 16),
                  itemBuilder: (_) => [
                        for (final e in RigEasing.values)
                          PopupMenuItem(value: e.index, child: Text(rigEasingName(Strings.of(context), e))),
                        PopupMenuItem(value: -1, child: Text(Strings.of(context).rigEasingCustom)),
                      ],
                  onSelected: (i) async {
                    if (i >= 0) return edit(() => c.editTimelineKeys(easing: RigEasing.values[i]));
                    final curve = await showEasingCurveDialog(context, EasingCurve.easeInOut);
                    if (curve != null) edit(() => c.editTimelineKeys(curve: curve));
                  }),
              TextButton(
                  onPressed: () => c.setTimelineScope(ripple: !c.rippleTimeline),
                  child: Text(c.rippleTimeline ? Strings.of(context).rigRippleOn : Strings.of(context).rigRippleOff)),
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
