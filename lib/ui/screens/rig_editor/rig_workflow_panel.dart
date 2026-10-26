import 'package:flutter/material.dart';
import '../../../pixel/rig/rig_editor_controller.dart';

/// Less frequent tools stay collapsible to leave the bone tree accessible.
class RigWorkflowPanel extends StatelessWidget {
  const RigWorkflowPanel({super.key, required this.controller});
  final RigEditorController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(children: [
      ExpansionTile(title: Text('Selection · ${c.selectedBoneIds.length} bones'), children: [
        SwitchListTile(
            title: const Text('Select multiple bones'),
            value: c.multiSelectEnabled,
            onChanged: (_) => c.toggleMultiSelect()),
        TextButton(
            onPressed: c.selectedBoneIds.isEmpty ? null : c.selectDescendants, child: const Text('Select descendants')),
        if (c.selectedBoneIds.isNotEmpty) ...[
          RigValueField(
              label: 'Move X', value: 0, step: .5, apply: (v) => c.transformSelection(translation: Offset(v, 0))),
          RigValueField(
              label: 'Move Y', value: 0, step: .5, apply: (v) => c.transformSelection(translation: Offset(0, v))),
          RigValueField(label: 'Rotate group', value: 0, apply: (v) => c.transformSelection(rotation: v)),
          SwitchListTile(
              title: const Text('Rotate about active joint'), value: c.groupActivePivot, onChanged: c.setGroupPivot),
          if (c.mode == RigMode.animate)
            Wrap(children: [
              TextButton(onPressed: () => c.freezeSelection(true), child: const Text('Lock selected joints')),
              TextButton(onPressed: () => c.freezeSelection(false), child: const Text('Unlock selected joints')),
            ]),
        ],
      ]),
      if (c.mode == RigMode.animate &&
          c.selectedBone != null &&
          !c.jointFrozenAt(c.selectedBoneId!, c.time) &&
          !c.isIkDriven(c.selectedBoneId!))
        ExpansionTile(title: const Text('Numeric pose'), children: [
          RigValueField(
              label: 'Pose rotation',
              value: c.poseOf(c.selectedBoneId!).rotation,
              apply: (v) => c.setPose(c.selectedBoneId!, rotation: v)),
          RigValueField(
              label: 'Offset X',
              value: c.poseOf(c.selectedBoneId!).translation.dx,
              step: .5,
              apply: (v) =>
                  c.setPose(c.selectedBoneId!, translation: Offset(v, c.poseOf(c.selectedBoneId!).translation.dy))),
          RigValueField(
              label: 'Offset Y',
              value: c.poseOf(c.selectedBoneId!).translation.dy,
              step: .5,
              apply: (v) =>
                  c.setPose(c.selectedBoneId!, translation: Offset(c.poseOf(c.selectedBoneId!).translation.dx, v))),
        ]),
      if (c.mode == RigMode.animate)
        ExpansionTile(title: const Text('Pose ghosting'), children: [
          SwitchListTile(
              key: const ValueKey('rig-ghost-skeleton'),
              title: const Text('Skeleton ghosts'),
              value: c.ghostSkeleton,
              onChanged: (v) => c.updateGhosts(skeleton: v)),
          SwitchListTile(
              key: const ValueKey('rig-ghost-artwork'),
              title: const Text('Artwork ghosts'),
              value: c.ghostArtwork,
              onChanged: (v) => c.updateGhosts(artwork: v)),
          const Text('Opacity'),
          Slider(value: c.ghostOpacity, min: .05, max: .8, onChanged: (v) => c.updateGhosts(opacity: v)),
          RigValueField(
              label: 'Frame spacing',
              value: c.ghostSpacing.toDouble(),
              apply: (v) => c.updateGhosts(spacing: v.round())),
          TextButton(
              onPressed: () => c.updateGhosts(pin: c.pinnedGhostFrame == null, unpin: c.pinnedGhostFrame != null),
              child: Text(c.pinnedGhostFrame == null ? 'Pin current pose' : 'Unpin reference pose')),
        ]),
      if (c.mode == RigMode.setup)
        ExpansionTile(title: const Text('Attachment points'), children: [
          const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Name a foot socket foot_contact to use it as a planting anchor. Offsets follow the bone.')),
          TextButton.icon(
              key: const ValueKey('rig-add-attachment'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add to selected bone'),
              onPressed: c.selectedBoneId == null ? null : () => c.addAttachment(c.selectedBoneId!, 'grip')),
          for (final a in c.rig.attachments)
            ExpansionTile(
                key: ValueKey('socket-${a.id}'),
                title: Text(a.name),
                subtitle: Text(c.bone(a.boneId)?.name ?? 'Missing bone'),
                children: [
                  TextFormField(
                      initialValue: a.name,
                      decoration: const InputDecoration(labelText: 'Socket name'),
                      onFieldSubmitted: (v) => c.updateAttachment(a.id, name: v)),
                  RigValueField(
                      label: 'Local X', value: a.offset.dx, step: .5, apply: (v) => c.updateAttachment(a.id, x: v)),
                  RigValueField(
                      label: 'Local Y', value: a.offset.dy, step: .5, apply: (v) => c.updateAttachment(a.id, y: v)),
                  RigValueField(
                      label: 'Socket angle', value: a.angle, apply: (v) => c.updateAttachment(a.id, angle: v)),
                  for (final layer in c.restLayers.where((l) => l.stableKey != null))
                    ListTile(
                        dense: true,
                        title: Text(layer.name),
                        trailing:
                            Icon(c.partOfLayer(layer.stableKey!)?.attachmentId == a.id ? Icons.link : Icons.add_link),
                        onTap: () => c.attachLayerToSocket(layer.stableKey!, a.id)),
                  for (final part in c.rig.parts.where((p) => p.attachmentId == a.id)) ...[
                    Text(
                        'Artwork pivot · ${c.restLayers.where((l) => l.stableKey == part.layerKey).firstOrNull?.name ?? part.layerKey}'),
                    RigValueField(
                        label: 'Artwork X',
                        value: (part.pivotOverride ?? c.bone(a.boneId)!.head).dx,
                        step: .5,
                        apply: (v) => c.setAttachmentArtworkPivot(
                            part.layerKey, Offset(v, (part.pivotOverride ?? c.bone(a.boneId)!.head).dy))),
                    RigValueField(
                        label: 'Artwork Y',
                        value: (part.pivotOverride ?? c.bone(a.boneId)!.head).dy,
                        step: .5,
                        apply: (v) => c.setAttachmentArtworkPivot(
                            part.layerKey, Offset((part.pivotOverride ?? c.bone(a.boneId)!.head).dx, v))),
                  ],
                  TextButton(onPressed: () => c.deleteAttachment(a.id), child: const Text('Delete attachment')),
                ]),
        ]),
    ]);
  }
}

class RigValueField extends StatefulWidget {
  const RigValueField({super.key, required this.label, required this.value, required this.apply, this.step = 1});
  final String label;
  final double value, step;
  final ValueChanged<double> apply;
  @override
  State<RigValueField> createState() => _RigValueFieldState();
}

class _RigValueFieldState extends State<RigValueField> {
  late final _text = TextEditingController(text: widget.value.toStringAsFixed(1));
  @override
  void didUpdateWidget(covariant RigValueField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _text.text = widget.value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _apply(double value) {
    if (!value.isFinite) return;
    widget.apply(value);
    _text.text = widget.value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        controller: _text,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
            labelText: widget.label,
            isDense: true,
            suffixIcon: SizedBox(
                width: 64,
                child: Row(children: [
                  InkWell(onTap: () => _apply(widget.value - widget.step), child: const Icon(Icons.remove, size: 20)),
                  const SizedBox(width: 16),
                  InkWell(onTap: () => _apply(widget.value + widget.step), child: const Icon(Icons.add, size: 20)),
                ]))),
        onFieldSubmitted: (v) {
          final n = double.tryParse(v);
          if (n != null) _apply(n);
        },
      ));
}
