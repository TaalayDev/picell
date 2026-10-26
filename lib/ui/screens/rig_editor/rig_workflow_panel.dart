import 'package:flutter/material.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/rig/rig_editor_controller.dart';

/// Less frequent tools stay collapsible to leave the bone tree accessible.
class RigWorkflowPanel extends StatelessWidget {
  const RigWorkflowPanel({super.key, required this.controller});
  final RigEditorController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(children: [
      ExpansionTile(title: Text(Strings.of(context).rigSelectionTitle(c.selectedBoneIds.length)), children: [
        SwitchListTile(
            title: Text(Strings.of(context).rigSelectMultiple),
            value: c.multiSelectEnabled,
            onChanged: (_) => c.toggleMultiSelect()),
        TextButton(
            onPressed: c.selectedBoneIds.isEmpty ? null : c.selectDescendants, child: Text(Strings.of(context).rigSelectDescendants)),
        if (c.selectedBoneIds.isNotEmpty) ...[
          RigValueField(
              label: Strings.of(context).rigMoveX, value: 0, step: .5, apply: (v) => c.transformSelection(translation: Offset(v, 0))),
          RigValueField(
              label: Strings.of(context).rigMoveY, value: 0, step: .5, apply: (v) => c.transformSelection(translation: Offset(0, v))),
          RigValueField(label: Strings.of(context).rigRotateGroup, value: 0, apply: (v) => c.transformSelection(rotation: v)),
          SwitchListTile(
              title: Text(Strings.of(context).rigRotateAboutActive), value: c.groupActivePivot, onChanged: c.setGroupPivot),
          if (c.mode == RigMode.animate)
            Wrap(children: [
              TextButton(onPressed: () => c.freezeSelection(true), child: Text(Strings.of(context).rigLockSelected)),
              TextButton(onPressed: () => c.freezeSelection(false), child: Text(Strings.of(context).rigUnlockSelected)),
            ]),
        ],
      ]),
      if (c.mode == RigMode.animate &&
          c.selectedBone != null &&
          !c.jointFrozenAt(c.selectedBoneId!, c.time) &&
          !c.isIkDriven(c.selectedBoneId!))
        ExpansionTile(title: Text(Strings.of(context).rigNumericPose), children: [
          RigValueField(
              label: Strings.of(context).rigPoseRotation,
              value: c.poseOf(c.selectedBoneId!).rotation,
              apply: (v) => c.setPose(c.selectedBoneId!, rotation: v)),
          RigValueField(
              label: Strings.of(context).rigOffsetX,
              value: c.poseOf(c.selectedBoneId!).translation.dx,
              step: .5,
              apply: (v) =>
                  c.setPose(c.selectedBoneId!, translation: Offset(v, c.poseOf(c.selectedBoneId!).translation.dy))),
          RigValueField(
              label: Strings.of(context).rigOffsetY,
              value: c.poseOf(c.selectedBoneId!).translation.dy,
              step: .5,
              apply: (v) =>
                  c.setPose(c.selectedBoneId!, translation: Offset(c.poseOf(c.selectedBoneId!).translation.dx, v))),
        ]),
      if (c.mode == RigMode.animate)
        ExpansionTile(title: Text(Strings.of(context).rigPoseGhosting), children: [
          SwitchListTile(
              key: const ValueKey('rig-ghost-skeleton'),
              title: Text(Strings.of(context).rigSkeletonGhosts),
              value: c.ghostSkeleton,
              onChanged: (v) => c.updateGhosts(skeleton: v)),
          SwitchListTile(
              key: const ValueKey('rig-ghost-artwork'),
              title: Text(Strings.of(context).rigArtworkGhosts),
              value: c.ghostArtwork,
              onChanged: (v) => c.updateGhosts(artwork: v)),
          Text(Strings.of(context).rigOpacity),
          Slider(value: c.ghostOpacity, min: .05, max: .8, onChanged: (v) => c.updateGhosts(opacity: v)),
          RigValueField(
              label: Strings.of(context).rigFrameSpacing,
              value: c.ghostSpacing.toDouble(),
              apply: (v) => c.updateGhosts(spacing: v.round())),
          TextButton(
              onPressed: () => c.updateGhosts(pin: c.pinnedGhostFrame == null, unpin: c.pinnedGhostFrame != null),
              child: Text(c.pinnedGhostFrame == null ? Strings.of(context).rigPinPose : Strings.of(context).rigUnpinPose)),
        ]),
      if (c.mode == RigMode.setup)
        ExpansionTile(title: Text(Strings.of(context).rigAttachmentPoints), children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(Strings.of(context).rigSocketHint)),
          TextButton.icon(
              key: const ValueKey('rig-add-attachment'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(Strings.of(context).rigAddToBone),
              onPressed: c.selectedBoneId == null ? null : () => c.addAttachment(c.selectedBoneId!, 'grip')),
          for (final a in c.rig.attachments)
            ExpansionTile(
                key: ValueKey('socket-${a.id}'),
                title: Text(a.name),
                subtitle: Text(c.bone(a.boneId)?.name ?? Strings.of(context).rigMissingBone),
                children: [
                  TextFormField(
                      initialValue: a.name,
                      decoration: InputDecoration(labelText: Strings.of(context).rigSocketName),
                      onFieldSubmitted: (v) => c.updateAttachment(a.id, name: v)),
                  RigValueField(
                      label: Strings.of(context).rigLocalX, value: a.offset.dx, step: .5, apply: (v) => c.updateAttachment(a.id, x: v)),
                  RigValueField(
                      label: Strings.of(context).rigLocalY, value: a.offset.dy, step: .5, apply: (v) => c.updateAttachment(a.id, y: v)),
                  RigValueField(
                      label: Strings.of(context).rigSocketAngle, value: a.angle, apply: (v) => c.updateAttachment(a.id, angle: v)),
                  for (final layer in c.restLayers.where((l) => l.stableKey != null))
                    ListTile(
                        dense: true,
                        title: Text(layer.name),
                        trailing:
                            Icon(c.partOfLayer(layer.stableKey!)?.attachmentId == a.id ? Icons.link : Icons.add_link),
                        onTap: () => c.attachLayerToSocket(layer.stableKey!, a.id)),
                  for (final part in c.rig.parts.where((p) => p.attachmentId == a.id)) ...[
                    Text(
                        Strings.of(context).rigArtworkPivot(c.restLayers.where((l) => l.stableKey == part.layerKey).firstOrNull?.name ?? part.layerKey)),
                    RigValueField(
                        label: Strings.of(context).rigArtworkX,
                        value: (part.pivotOverride ?? c.bone(a.boneId)!.head).dx,
                        step: .5,
                        apply: (v) => c.setAttachmentArtworkPivot(
                            part.layerKey, Offset(v, (part.pivotOverride ?? c.bone(a.boneId)!.head).dy))),
                    RigValueField(
                        label: Strings.of(context).rigArtworkY,
                        value: (part.pivotOverride ?? c.bone(a.boneId)!.head).dy,
                        step: .5,
                        apply: (v) => c.setAttachmentArtworkPivot(
                            part.layerKey, Offset((part.pivotOverride ?? c.bone(a.boneId)!.head).dx, v))),
                  ],
                  TextButton(onPressed: () => c.deleteAttachment(a.id), child: Text(Strings.of(context).rigDeleteAttachment)),
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
