import 'package:flutter/material.dart';

import '../../../data/models/layer.dart';
import '../../../data/models/rig/rig.dart';
import '../../../pixel/rig/rig_editor_controller.dart';
import 'rig_presets_dialogs.dart';
import 'rig_workflow_panel.dart';
import 'package:flutter/services.dart';

/// Right-hand panel of the rig editor: bone tree, layer assignment and the
/// selected bone's properties. Rebuilds from [controller].
class RigSidePanel extends StatelessWidget {
  const RigSidePanel({super.key, required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _SectionHeader('Bones', count: controller.rig.bones.length),
            _BoneTree(controller: controller),
            if (controller.mode == RigMode.setup) ...[
              const _SectionHeader('Layers'),
              _PartsList(controller: controller),
              if (controller.selectedBone != null) ...[
                const _SectionHeader('Bone'),
                _BoneProperties(key: ValueKey(controller.selectedBoneId), controller: controller),
              ],
            ] else if (controller.selectedBone != null) ...[
              _SectionHeader('Pose · frame ${controller.time + 1}'),
              _PoseSection(controller: controller),
            ],
            if (controller.selectedBone != null) ...[
              const _SectionHeader('IK'),
              _IkSection(controller: controller),
            ],
            if (controller.mode == RigMode.animate) ...[
              _SectionHeader('Poses', count: controller.savedPoses.length),
              _PosesSection(controller: controller),
            ],
            RigWorkflowPanel(controller: controller),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          if (count != null)
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ── Bones ───────────────────────────────────────────────────────────────────

class _BoneTree extends StatelessWidget {
  const _BoneTree({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.tree;
    if (rows.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick the bone tool and drag on the canvas to draw your first bone.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (controller.mode == RigMode.setup)
              TextButton.icon(
                key: const ValueKey('empty-skeleton-presets'),
                onPressed: () => addSkeletonPreset(context, controller),
                icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
                label: const Text('Or add a ready-made skeleton'),
              ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final row in rows)
          _BoneRow(
            key: ValueKey(row.bone.id),
            controller: controller,
            bone: row.bone,
            depth: row.depth,
          ),
      ],
    );
  }
}

class _BoneRow extends StatelessWidget {
  const _BoneRow({super.key, required this.controller, required this.bone, required this.depth});

  final RigEditorController controller;
  final Bone bone;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = controller.selectedBoneIds.contains(bone.id);
    return Material(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.14) : Colors.transparent,
      child: InkWell(
        onTap: () => HardwareKeyboard.instance.isShiftPressed
            ? controller.toggleBoneSelection(bone.id)
            : controller.selectBone(bone.id),
        child: SizedBox(
          height: 30,
          child: Padding(
            padding: EdgeInsets.only(left: 10 + depth * 14.0, right: 2),
            child: Row(
              children: [
                Icon(
                  depth == 0 ? Icons.account_tree_outlined : Icons.subdirectory_arrow_right,
                  size: 14,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bone.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (controller.mode == RigMode.animate)
                  SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        key: ValueKey('freeze-joint-${bone.id}'),
                        padding: EdgeInsets.zero,
                        tooltip: controller.hasJointFreeze(bone.id) ? 'Unfreeze ${bone.name}' : 'Freeze ${bone.name}',
                        icon: Icon(controller.hasJointFreeze(bone.id) ? Icons.lock : Icons.lock_open, size: 14),
                        onPressed: () => controller.hasJointFreeze(bone.id)
                            ? controller.unfreezeJoint(bone.id)
                            : controller.freezeJoint(bone.id),
                      )),
                PopupMenuButton<_BoneAction>(
                  tooltip: 'Bone actions',
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => _run(context, action),
                  itemBuilder: (_) => [
                    if (controller.mode == RigMode.animate)
                      PopupMenuItem(
                          value: _BoneAction.freeze,
                          child: Text(controller.hasJointFreeze(bone.id) ? 'Unfreeze joint' : 'Freeze joint')),
                    const PopupMenuItem(value: _BoneAction.rename, child: Text('Rename')),
                    const PopupMenuItem(value: _BoneAction.setParent, child: Text('Connect joints…')),
                    if (bone.parentId != null)
                      const PopupMenuItem(value: _BoneAction.unparent, child: Text('Disconnect')),
                    const PopupMenuItem(value: _BoneAction.delete, child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, _BoneAction action) async {
    switch (action) {
      case _BoneAction.freeze:
        controller.hasJointFreeze(bone.id) ? controller.unfreezeJoint(bone.id) : controller.freezeJoint(bone.id);
      case _BoneAction.rename:
        final name = await showRenameBoneDialog(context, bone.name);
        if (name != null) controller.renameBone(bone.id, name);
      case _BoneAction.setParent:
        final parent = await _pickParent(context);
        if (parent != null) controller.connectToBone(bone.id, parent.id);
      case _BoneAction.unparent:
        controller.reparent(bone.id, null);
      case _BoneAction.delete:
        controller.deleteBone(bone.id);
    }
  }

  Future<Bone?> _pickParent(BuildContext context) {
    final blocked = {bone.id, ..._descendantIds()};
    final options = [
      for (final b in controller.rig.bones)
        if (!blocked.contains(b.id)) b,
    ];
    return showDialog<Bone>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Connect ${bone.name} to'),
        children: [
          if (options.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('There are no other bones to attach to.')),
          for (final b in options) SimpleDialogOption(onPressed: () => Navigator.pop(context, b), child: Text(b.name)),
        ],
      ),
    );
  }

  Set<String> _descendantIds() {
    final out = <String>{};
    void walk(String id) {
      for (final c in controller.childrenOf(id)) {
        if (out.add(c.id)) walk(c.id);
      }
    }

    walk(bone.id);
    return out;
  }
}

enum _BoneAction { freeze, rename, setParent, unparent, delete }

Future<String?> showRenameBoneDialog(BuildContext context, String current) =>
    showNameDialog(context, title: 'Rename bone', initial: current, action: 'Rename');

/// Asks for a short name. Returns null if cancelled.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
  required String action,
}) {
  final text = TextEditingController(text: initial);
  text.selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: text,
        autofocus: true,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, text.text), child: Text(action)),
      ],
    ),
  );
}

// ── Layer assignment ────────────────────────────────────────────────────────

class _PartsList extends StatelessWidget {
  const _PartsList({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    // Top layer first, like the layers panel.
    final layers = controller.restLayers.reversed.where((l) => l.stableKey != null).toList();
    if (layers.isEmpty) {
      return const Padding(padding: EdgeInsets.all(12), child: Text('This animation has no layers.'));
    }
    return Column(
      children: [
        for (final layer in layers) _PartRow(key: ValueKey(layer.stableKey), controller: controller, layer: layer),
      ],
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({super.key, required this.controller, required this.layer});

  final RigEditorController controller;
  final Layer layer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = layer.stableKey!;
    final bone = controller.boneOfLayer(key);
    final armed = controller.activeLayerKey == key;
    final muted = theme.colorScheme.onSurfaceVariant;

    // Tapping the row arms the layer: the next bone drawn is bound to it.
    return Material(
      color: armed ? theme.colorScheme.primary.withValues(alpha: 0.14) : Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectLayer(key),
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 6),
            child: Row(
              children: [
                Icon(
                  armed ? Icons.bolt : (layer.isVisible ? Icons.layers_outlined : Icons.layers_clear_outlined),
                  size: 14,
                  color: armed ? theme.colorScheme.primary : muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    layer.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: armed ? theme.colorScheme.primary : null),
                  ),
                ),
                PopupMenuButton<String?>(
                  tooltip: 'Choose the bone that moves ${layer.name}',
                  padding: EdgeInsets.zero,
                  onSelected: (boneId) => controller.assignLayer(key, boneId),
                  itemBuilder: (_) => [
                    const PopupMenuItem<String?>(value: null, child: Text('Stays still')),
                    for (final b in controller.rig.bones) PopupMenuItem<String?>(value: b.id, child: Text(b.name)),
                  ],
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 96),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bone == null ? Colors.transparent : theme.colorScheme.primary.withValues(alpha: 0.14),
                      border: Border.all(color: bone == null ? theme.dividerColor : theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            bone?.name ?? 'Stays still',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: bone == null ? muted : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 14, color: muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Selected bone ───────────────────────────────────────────────────────────

class _BoneProperties extends StatelessWidget {
  const _BoneProperties({super.key, required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final bone = controller.selectedBone;
    if (bone == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final limited = bone.minAngle != null || bone.maxAngle != null;
    final min = bone.minAngle ?? -90;
    final max = bone.maxAngle ?? 90;

    Widget stat(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text(value, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        SwitchListTile(
            dense: true,
            title: const Text('Move connected chain'),
            value: controller.moveConnectedChain,
            onChanged: controller.setConnectedGeometry),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: _BoneNumber(
                      label: 'X',
                      value: bone.head.dx,
                      onApply: (v) {
                        controller.setBoneGeometry(bone.id, x: v);
                        return controller.bone(bone.id)!.head.dx;
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: _BoneNumber(
                      label: 'Y',
                      value: bone.head.dy,
                      onApply: (v) {
                        controller.setBoneGeometry(bone.id, y: v);
                        return controller.bone(bone.id)!.head.dy;
                      })),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _BoneNumber(
                      label: 'Length',
                      value: bone.length,
                      minimum: .5,
                      onApply: (v) {
                        controller.setBoneGeometry(bone.id, length: v);
                        return controller.bone(bone.id)!.length;
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: _BoneNumber(
                      label: 'Angle',
                      value: bone.restAngle,
                      onApply: (v) {
                        controller.setBoneGeometry(bone.id, angle: v);
                        return controller.bone(bone.id)!.restAngle;
                      })),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _BoneNumber(
                      label: 'Tail X',
                      value: bone.tail.dx,
                      onApply: (v) {
                        controller.setBoneEndpoint(bone.id, Offset(v, bone.tail.dy));
                        return controller.bone(bone.id)!.tail.dx;
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: _BoneNumber(
                      label: 'Tail Y',
                      value: bone.tail.dy,
                      onApply: (v) {
                        controller.setBoneEndpoint(bone.id, Offset(bone.tail.dx, v));
                        return controller.bone(bone.id)!.tail.dy;
                      })),
            ]),
            const SizedBox(height: 6),
            Text('Enter to apply · 0.5 px steps',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text('Limit rotation', style: theme.textTheme.bodySmall),
          value: limited,
          onChanged: (on) =>
              on ? controller.setBoneLimits(bone.id, min: -90, max: 90) : controller.setBoneLimits(bone.id),
        ),
        if (limited) ...[
          stat('Range', '${min.round()}° to ${max.round()}°'),
          Row(children: [
            Expanded(
                child: _BoneNumber(
                    label: 'Min angle',
                    value: min,
                    onApply: (v) {
                      controller.setBoneLimits(bone.id, min: v, max: max);
                      return controller.bone(bone.id)!.minAngle!;
                    })),
            Expanded(
                child: _BoneNumber(
                    label: 'Max angle',
                    value: max,
                    onApply: (v) {
                      controller.setBoneLimits(bone.id, min: min, max: v);
                      return controller.bone(bone.id)!.maxAngle!;
                    })),
          ]),
          RangeSlider(
            values: RangeValues(min.clamp(-180, 180).toDouble(), max.clamp(-180, 180).toDouble()),
            min: -180,
            max: 180,
            divisions: 72,
            onChanged: (v) => controller.setBoneLimits(bone.id, min: v.start, max: v.end),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BoneNumber extends StatefulWidget {
  const _BoneNumber({required this.label, required this.value, required this.onApply, this.minimum});
  final String label;
  final double value;
  final double? minimum;
  final double Function(double) onApply;
  @override
  State<_BoneNumber> createState() => _BoneNumberState();
}

class _BoneNumberState extends State<_BoneNumber> {
  late final TextEditingController _text = TextEditingController(text: widget.value.toStringAsFixed(1));
  @override
  void didUpdateWidget(covariant _BoneNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _text.text = widget.value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        key: ValueKey('bone-number-${widget.label}'),
        controller: _text,
        style: Theme.of(context).textTheme.bodySmall,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
            labelText: widget.label,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: SizedBox(
                width: 40,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  InkWell(
                      onTap: () {
                        final value = widget.onApply(
                            widget.value + ((widget.label.contains('angle') || widget.label == 'Angle') ? 1 : .5));
                        _text.text = value.toStringAsFixed(1);
                      },
                      child: const Icon(Icons.arrow_drop_up, size: 18)),
                  InkWell(
                      onTap: () {
                        final n = widget.value - ((widget.label.contains('angle') || widget.label == 'Angle') ? 1 : .5);
                        if (widget.minimum != null && n < widget.minimum!) return;
                        final value = widget.onApply(n);
                        _text.text = value.toStringAsFixed(1);
                      },
                      child: const Icon(Icons.arrow_drop_down, size: 18)),
                ]))),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (text) {
          final n = double.tryParse(text ?? '');
          return n == null || !n.isFinite || (widget.minimum != null && n < widget.minimum!) ? 'Invalid value' : null;
        },
        onFieldSubmitted: (text) {
          final value = double.tryParse(text);
          if (value == null || !value.isFinite || (widget.minimum != null && value < widget.minimum!)) return;
          final actual = widget.onApply(value);
          _text.text = actual.toStringAsFixed(1);
          FocusScope.of(context).unfocus();
        },
      );
}

// ── Pose (animate mode) ─────────────────────────────────────────────────────

const _easingNames = {
  RigEasing.linear: 'Linear',
  RigEasing.easeIn: 'Ease in',
  RigEasing.easeOut: 'Ease out',
  RigEasing.easeInOut: 'Ease in and out',
  RigEasing.stepped: 'Hold, then snap',
};

/// The selected bone's pose on the current frame, and its key there.
class _PoseSection extends StatelessWidget {
  const _PoseSection({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final bone = controller.selectedBone;
    if (bone == null) return const SizedBox.shrink();
    if (controller.jointFrozenAt(bone.id, controller.time)) {
      return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            Text('Joint frozen in this clip. Parent motion and IK cannot move it.',
                style: Theme.of(context).textTheme.bodySmall),
            TextButton(onPressed: () => controller.unfreezeJoint(bone.id), child: const Text('Unfreeze joint')),
          ]));
    }
    final theme = Theme.of(context);
    final driven = controller.isIkDriven(bone.id);
    // An IK-driven bone's own rotation key is only a starting guess.
    final pose = driven ? controller.shownPoseOf(bone.id) : controller.poseOf(bone.id);
    final key = controller.keyAt(bone.id, controller.time);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget stat(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              const Spacer(),
              Text(value, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        stat('Bone', bone.name),
        if (driven)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
            child: Text(
              'Steered by IK: drag its ring on the canvas to pose it.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
            ),
          ),
        stat('Rotation', '${pose.rotation.toStringAsFixed(0)}°'),
        stat('Offset', '${pose.translation.dx.toStringAsFixed(0)}, ${pose.translation.dy.toStringAsFixed(0)}'),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text('Flip horizontally', style: theme.textTheme.bodySmall),
          value: pose.flipX,
          onChanged: (on) => controller.setPose(bone.id, flipX: on),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: Row(
            children: [
              Icon(key == null ? Icons.timeline : Icons.diamond,
                  size: 14, color: key == null ? muted : theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  key == null ? 'Between keys' : 'Keyed on this frame',
                  style: theme.textTheme.bodySmall?.copyWith(color: key == null ? muted : theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: key == null
                ? TextButton(onPressed: () => controller.keyBone(bone.id), child: const Text('Add key'))
                : TextButton(
                    onPressed: () => controller.deleteKey(bone.id, controller.time), child: const Text('Remove key')),
          ),
        ),
        if (key != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButton<RigEasing>(
              isExpanded: true,
              isDense: true,
              value: key.easing,
              items: [
                for (final e in RigEasing.values)
                  DropdownMenuItem(value: e, child: Text(_easingNames[e]!, style: theme.textTheme.bodySmall)),
              ],
              onChanged: (e) {
                if (e != null) controller.setKeyEasing(bone.id, controller.time, e);
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Inverse kinematics ──────────────────────────────────────────────────────

/// IK for the selected bone: make it the end of a chain, shape the chain, and
/// (in animate mode) key where its target is.
class _IkSection extends StatelessWidget {
  const _IkSection({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final bone = controller.selectedBone;
    if (bone == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final hint = theme.textTheme.bodySmall?.copyWith(color: muted);

    final chain = controller.selectedIkChain;
    if (chain != null) return _ChainControls(controller: controller, chain: chain);

    final inChains = controller.ikChainsOf(bone.id);
    final most = controller.rig.maxChainLength(bone.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inChains.isNotEmpty) ...[
            Text('Part of the IK chain "${inChains.first.name}".', style: hint),
            TextButton(
              onPressed: () => controller.selectIkChain(inChains.first.id),
              child: const Text('Edit that chain'),
            ),
          ] else ...[
            Text(
              most < 2
                  ? 'Attach this bone to a parent to make a chain that bends to a target.'
                  : 'Bend this bone and the ones above it to reach a target, like a hand or a foot.',
              style: hint,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                key: const ValueKey('add-ik-chain'),
                onPressed: () => controller.addIkChain(tipBoneId: bone.id),
                child: Text(most < 2 ? 'Add IK to this bone' : 'Add IK chain'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChainControls extends StatelessWidget {
  const _ChainControls({required this.controller, required this.chain});

  final RigEditorController controller;
  final IkChain chain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final animating = controller.mode == RigMode.animate;
    final most = controller.rig.maxChainLength(chain.tipBoneId);
    final key = controller.ikKeyAt(chain.id, controller.time);
    final active = controller.ikTarget(chain.id) != null;

    Widget row(String label, Widget trailing) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              const Spacer(),
              trailing,
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        row('Chain', Text(chain.name, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))),
        row(
          'Bones',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Fewer bones in the chain',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 14),
                onPressed:
                    chain.boneCount > 1 ? () => controller.setIkChain(chain.id, boneCount: chain.boneCount - 1) : null,
              ),
              Text('${controller.rig.chainBones(chain).length}', style: theme.textTheme.bodySmall),
              IconButton(
                tooltip: 'More bones in the chain',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 14),
                onPressed: chain.boneCount < most
                    ? () => controller.setIkChain(chain.id, boneCount: chain.boneCount + 1)
                    : null,
              ),
            ],
          ),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text('Fold the other way', style: theme.textTheme.bodySmall),
          value: chain.bend < 0,
          onChanged: (on) => controller.setIkChain(chain.id, bend: on ? -1 : 1),
        ),
        if (animating) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Row(
              children: [
                Icon(
                  key == null ? Icons.timeline : Icons.diamond,
                  size: 14,
                  color: key == null ? muted : theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    key?.planted == true
                        ? 'Foot planted on this frame'
                        : !active
                            ? 'Off: drag the ring to place the target'
                            : key == null
                                ? 'Target between keys'
                                : 'Target keyed on this frame',
                    style: theme.textTheme.bodySmall?.copyWith(color: key == null ? muted : theme.colorScheme.tertiary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: key == null
                  ? TextButton(onPressed: () => controller.keyIkChain(chain.id), child: const Text('Key target'))
                  : TextButton(
                      onPressed: () => controller.deleteIkKey(chain.id, controller.time),
                      child: const Text('Remove target key'),
                    ),
            ),
          ),
          if (key != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButton<RigEasing>(
                isExpanded: true,
                isDense: true,
                value: key.easing,
                items: [
                  for (final e in RigEasing.values)
                    DropdownMenuItem(value: e, child: Text(_easingNames[e]!, style: theme.textTheme.bodySmall)),
                ],
                onChanged: (e) {
                  if (e != null) controller.setIkKeyEasing(chain.id, controller.time, e);
                },
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('remove-ik-chain'),
              onPressed: () => controller.removeIkChain(chain.id),
              child: const Text('Remove IK'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pose library ────────────────────────────────────────────────────────────

enum _PoseAction { rename, delete }

/// Saved poses: tap one to put it on the current frame.
class _PosesSection extends StatelessWidget {
  const _PosesSection({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final poses = controller.savedPoses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (poses.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              'Save the pose on this frame to reuse it on other frames.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        for (final pose in poses)
          InkWell(
            key: ValueKey('pose-${pose.id}'),
            onTap: () => controller.applyPose(pose.id),
            child: SizedBox(
              height: 32,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 2),
                child: Row(
                  children: [
                    Icon(Icons.accessibility_new, size: 14, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Tooltip(
                        message: 'Put "${pose.name}" on frame ${controller.time + 1}',
                        child: Text(pose.name, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                      ),
                    ),
                    PopupMenuButton<_PoseAction>(
                      tooltip: 'Pose actions',
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) async {
                        if (action == _PoseAction.delete) {
                          controller.deletePose(pose.id);
                          return;
                        }
                        final name = await showNameDialog(
                          context,
                          title: 'Rename pose',
                          initial: pose.name,
                          action: 'Rename',
                        );
                        if (name != null) controller.renamePose(pose.id, name);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: _PoseAction.rename, child: Text('Rename')),
                        PopupMenuItem(value: _PoseAction.delete, child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('save-pose'),
              onPressed: controller.rig.bones.isEmpty
                  ? null
                  : () async {
                      final name = await showNameDialog(
                        context,
                        title: 'Save pose',
                        initial: 'Pose ${poses.length + 1}',
                        action: 'Save',
                      );
                      if (name != null) controller.savePose(name);
                    },
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: Text('Save frame ${controller.time + 1} as a pose'),
            ),
          ),
        ),
      ],
    );
  }
}
