import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../l10n/strings.dart';
import '../../../data/models/layer.dart';
import '../../../data/models/rig/rig.dart';
import '../../../pixel/rig/rig_editor_controller.dart';
import '../../../pixel/rig/rig_validator.dart';
import 'rig_canvas.dart' show boneInfluenceColor;
import 'rig_curve_editor.dart';
import 'rig_presets_dialogs.dart';
import 'rig_workflow_panel.dart';
import 'package:flutter/services.dart';

/// Right-hand panel of the rig editor: bone tree, layer assignment and the
/// selected bone's properties. Rebuilds from [controller].
class RigSidePanel extends StatefulWidget {
  const RigSidePanel({super.key, required this.controller});

  final RigEditorController controller;

  @override
  State<RigSidePanel> createState() => _RigSidePanelState();
}

class _RigSidePanelState extends State<RigSidePanel> {
  /// Sections the user folded away; kept for as long as the panel lives.
  final _folded = <String>{};

  RigEditorController get controller => widget.controller;

  /// A header that folds [body] away.
  List<Widget> _section(String id, String title, Widget body, {int? count}) => [
        _SectionHeader(
          title,
          count: count,
          folded: _folded.contains(id),
          onTap: () => setState(() => _folded.contains(id) ? _folded.remove(id) : _folded.add(id)),
        ),
        if (!_folded.contains(id)) body,
      ];

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            ..._section('bones', strings.rigSectionBones, _BoneTree(controller: controller),
                count: controller.rig.bones.length),
            if (controller.mode == RigMode.setup) ...[
              ..._section('layers', strings.rigSectionLayers, _PartsList(controller: controller)),
              if (controller.selectedBone != null)
                ..._section('bone', strings.rigSectionBone,
                    _BoneProperties(key: ValueKey(controller.selectedBoneId), controller: controller)),
            ] else if (controller.selectedBone != null)
              ..._section('pose', strings.rigSectionPose(controller.time + 1), _PoseSection(controller: controller)),
            if (controller.selectedBone != null) ..._section('ik', 'IK', _IkSection(controller: controller)),
            if (controller.mode == RigMode.animate)
              ..._section('poses', strings.rigSectionPoses, _PosesSection(controller: controller),
                  count: controller.savedPoses.length),
            ..._section('rotation', strings.rigSectionRotation, _RotationSettings(controller: controller)),
            if (controller.issues.isNotEmpty)
              ..._section('check', strings.rigSectionCheck, _IssuesList(controller: controller),
                  count: controller.issues.length),
            RigWorkflowPanel(controller: controller),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.count, this.folded = false, this.onTap});

  final String title;
  final int? count;
  final bool folded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pv = context.pv;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.only(left: 6, right: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
              bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
          ),
          child: Row(
            children: [
              Icon(folded ? Icons.chevron_right : Icons.expand_more, size: 18, color: muted),
              const SizedBox(width: 2),
              Text(
                title,
                style: pv.pixelLabel(size: 11, color: muted).copyWith(letterSpacing: 0.8),
              ),
              const Spacer(),
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count', style: pv.mono(size: 11, color: muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pixel rotation ──────────────────────────────────────────────────────────

String _degreesLabel(Strings s, double degrees) =>
    s.rigSnapDegrees(degrees == degrees.roundToDouble() ? degrees.round().toString() : degrees.toString());

/// A drop-down of angle-snap steps. [value] null means "follow the default",
/// offered only when [inheritLabel] is given.
class _SnapDropdown extends StatelessWidget {
  const _SnapDropdown({super.key, required this.value, required this.onChanged, this.inheritLabel});

  final double? value;
  final ValueChanged<double?> onChanged;

  /// Text of the "follow the default" entry; null leaves that entry out.
  final String? inheritLabel;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final choices = {...RigEditorController.snapChoices, if (value != null && value! > 0) value!}.toList()..sort();
    return DropdownButton<double?>(
      isDense: true,
      value: value,
      items: [
        if (inheritLabel != null) DropdownMenuItem<double?>(value: null, child: Text(inheritLabel!)),
        DropdownMenuItem<double?>(value: 0, child: Text(s.rigSnapOff)),
        for (final d in choices) DropdownMenuItem<double?>(value: d, child: Text(_degreesLabel(s, d))),
      ],
      onChanged: onChanged,
    );
  }
}

/// How rotated parts are drawn, and the default angle snap of the rig.
class _RotationSettings extends StatelessWidget {
  const _RotationSettings({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final settings = controller.rig.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const ValueKey('rig-rotsprite'),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text(s.rigRotSprite, style: theme.textTheme.bodySmall),
          subtitle: Text(s.rigRotSpriteHint, style: theme.textTheme.labelSmall),
          value: settings.rotationMode == RigRotationMode.rotsprite,
          onChanged: (on) => controller.setRotationMode(on ? RigRotationMode.rotsprite : RigRotationMode.nearest),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(child: Text(s.rigSnapDefault, style: theme.textTheme.bodySmall)),
              _SnapDropdown(
                key: const ValueKey('rig-default-snap'),
                value: settings.snapAngleDegrees,
                onChanged: (v) => controller.setRigSnap(v ?? 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Checks ──────────────────────────────────────────────────────────────────

class _IssuesList extends StatelessWidget {
  const _IssuesList({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color colorOf(RigIssueSeverity s) => switch (s) {
          RigIssueSeverity.error => theme.colorScheme.error,
          RigIssueSeverity.warning => Colors.orange,
          RigIssueSeverity.info => theme.colorScheme.onSurfaceVariant,
        };
    IconData iconOf(RigIssueSeverity s) => switch (s) {
          RigIssueSeverity.error => Icons.error_outline,
          RigIssueSeverity.warning => Icons.warning_amber_rounded,
          RigIssueSeverity.info => Icons.info_outline,
        };
    return Column(
      children: [
        for (final issue in controller.issues)
          InkWell(
            onTap: () => controller.focusIssue(issue),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconOf(issue.severity), size: 14, color: colorOf(issue.severity)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(issue.message, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
      ],
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
              Strings.of(context).rigEmptyHint,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (controller.mode == RigMode.setup)
              TextButton.icon(
                key: const ValueKey('empty-skeleton-presets'),
                onPressed: () => addSkeletonPreset(context, controller),
                icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
                label: Text(Strings.of(context).rigOrAddSkeleton),
              ),
          ],
        ),
      );
    }
    // Rows under a folded bone are skipped until the depth comes back up.
    final shown = <({Bone bone, int depth})>[];
    int? foldedAt;
    for (final row in rows) {
      if (foldedAt != null) {
        if (row.depth > foldedAt) continue;
        foldedAt = null;
      }
      shown.add(row);
      if (controller.isCollapsed(row.bone.id) && controller.childrenOf(row.bone.id).isNotEmpty) foldedAt = row.depth;
    }
    final colorIndex = {for (final (i, b) in controller.rig.bones.indexed) b.id: i};
    return Column(
      children: [
        for (final row in shown)
          _BoneRow(
            key: ValueKey(row.bone.id),
            controller: controller,
            bone: row.bone,
            depth: row.depth,
            color: boneInfluenceColor(colorIndex[row.bone.id] ?? 0),
          ),
      ],
    );
  }
}

class _BoneRow extends StatelessWidget {
  const _BoneRow({
    super.key,
    required this.controller,
    required this.bone,
    required this.depth,
    required this.color,
  });

  final RigEditorController controller;
  final Bone bone;
  final int depth;

  /// The colour this bone's pixels are tinted with while painting.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = controller.selectedBoneIds.contains(bone.id);
    final hasChildren = controller.childrenOf(bone.id).isNotEmpty;
    final row = _rowBody(context, theme, selected, hasChildren);
    if (controller.mode != RigMode.setup) return row;

    // Long-press and drag a bone onto another to make it that bone's child.
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != bone.id && !_wouldLoop(d.data),
      onAcceptWithDetails: (d) => controller.reparent(d.data, bone.id),
      builder: (context, candidates, _) => LongPressDraggable<String>(
        data: bone.id,
        feedback: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(6),
          child: Padding(padding: const EdgeInsets.all(8), child: Text(bone.name)),
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: candidates.isEmpty ? null : Border.all(color: theme.colorScheme.primary, width: 1.5),
          ),
          child: row,
        ),
      ),
    );
  }

  bool _wouldLoop(String draggedId) {
    // Dropping a bone onto its own descendant would make a cycle.
    var current = bone.parentId;
    final seen = <String>{};
    while (current != null && seen.add(current)) {
      if (current == draggedId) return true;
      current = controller.bone(current)?.parentId;
    }
    return false;
  }

  Widget _rowBody(BuildContext context, ThemeData theme, bool selected, bool hasChildren) {
    return Material(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.14) : Colors.transparent,
      child: InkWell(
        onTap: () => HardwareKeyboard.instance.isShiftPressed
            ? controller.toggleBoneSelection(bone.id)
            : controller.selectBone(bone.id),
        child: SizedBox(
          height: 30,
          child: Padding(
            padding: EdgeInsets.only(left: 4 + depth * 14.0, right: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 28,
                  child: hasChildren
                      ? InkWell(
                          key: ValueKey('fold-bone-${bone.id}'),
                          onTap: () => controller.toggleCollapsed(bone.id),
                          child: Icon(
                            controller.isCollapsed(bone.id) ? Icons.chevron_right : Icons.expand_more,
                            size: 16,
                          ),
                        )
                      : null,
                ),
                if (controller.mode == RigMode.setup)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                Icon(
                  depth == 0
                      ? Icons.account_tree_outlined
                      : (bone.connection == BoneConnection.implicit ? Icons.link : Icons.subdirectory_arrow_right),
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
                        tooltip: controller.hasJointFreeze(bone.id)
                            ? Strings.of(context).rigUnfreezeBone(bone.name)
                            : Strings.of(context).rigFreezeBone(bone.name),
                        icon: Icon(controller.hasJointFreeze(bone.id) ? Icons.lock : Icons.lock_open, size: 14),
                        onPressed: () => controller.hasJointFreeze(bone.id)
                            ? controller.unfreezeJoint(bone.id)
                            : controller.freezeJoint(bone.id),
                      )),
                PopupMenuButton<_BoneAction>(
                  tooltip: Strings.of(context).rigBoneActions,
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => _run(context, action),
                  itemBuilder: (_) => [
                    if (controller.mode == RigMode.animate)
                      PopupMenuItem(
                          value: _BoneAction.freeze,
                          child: Text(controller.hasJointFreeze(bone.id)
                              ? Strings.of(context).rigUnfreezeJoint
                              : Strings.of(context).rigFreezeJoint)),
                    PopupMenuItem(value: _BoneAction.rename, child: Text(Strings.of(context).rename)),
                    PopupMenuItem(value: _BoneAction.setParent, child: Text(Strings.of(context).rigConnectJoints)),
                    PopupMenuItem(value: _BoneAction.implicitParent, child: Text(Strings.of(context).rigInheritMotion)),
                    if (bone.parentId != null) ...[
                      PopupMenuItem<_BoneAction>(
                        enabled: false,
                        child: Text(bone.connection == BoneConnection.implicit
                            ? Strings.of(context).rigImplicitNote
                            : Strings.of(context).rigExplicitNote),
                      ),
                      PopupMenuItem(value: _BoneAction.unparent, child: Text(Strings.of(context).rigDisconnect)),
                    ],
                    PopupMenuItem(value: _BoneAction.delete, child: Text(Strings.of(context).delete)),
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
      case _BoneAction.implicitParent:
        final parent = await _pickParent(context);
        if (parent != null) controller.reparent(bone.id, parent.id, connection: BoneConnection.implicit);
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
        title: Text(Strings.of(context).rigConnectTo(bone.name)),
        children: [
          if (options.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(Strings.of(context).rigNoOtherBones)),
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

enum _BoneAction { freeze, rename, setParent, implicitParent, unparent, delete }

Future<String?> showRenameBoneDialog(BuildContext context, String current) => showNameDialog(context,
    title: Strings.of(context).rigRenameBone, initial: current, action: Strings.of(context).rename);

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
        TextButton(onPressed: () => Navigator.pop(context), child: Text(Strings.of(context).cancel)),
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
      return Padding(padding: const EdgeInsets.all(12), child: Text(Strings.of(context).rigNoLayers));
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
    final layerParts = controller.partsOfLayer(key);
    final bone = controller.boneOfLayer(key);
    final label = layerParts.length > 1
        ? Strings.of(context).rigBoneCount(layerParts.length)
        : (bone?.name ?? Strings.of(context).rigStaysStill);
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
                  tooltip: Strings.of(context).rigChooseBoneFor(layer.name),
                  padding: EdgeInsets.zero,
                  onSelected: (boneId) => controller.assignLayer(key, boneId),
                  itemBuilder: (_) => [
                    PopupMenuItem<String?>(value: null, child: Text(Strings.of(context).rigStaysStill)),
                    for (final b in controller.rig.bones) PopupMenuItem<String?>(value: b.id, child: Text(b.name)),
                  ],
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 96),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          layerParts.isEmpty ? Colors.transparent : theme.colorScheme.primary.withValues(alpha: 0.14),
                      border: Border.all(color: layerParts.isEmpty ? theme.dividerColor : theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: layerParts.isEmpty ? muted : theme.colorScheme.primary,
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

/// Steps a bone's artwork in front of or behind other layers from this frame
/// on, e.g. an arm swinging across the body.
class _DrawOrderRow extends StatelessWidget {
  const _DrawOrderRow({required this.controller, required this.boneId});

  final RigEditorController controller;
  final String boneId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offset = controller.drawOrderOf(boneId);
    final keyed = controller.orderKeyAt(boneId, controller.time) != null;
    final label = offset == 0
        ? Strings.of(context).rigOrderNormal
        : (offset > 0 ? Strings.of(context).rigOrderFront(offset) : Strings.of(context).rigOrderBehind(-offset));
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 0),
      child: Row(
        children: [
          Icon(keyed ? Icons.layers : Icons.layers_outlined,
              size: 14, color: keyed ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(Strings.of(context).rigOrderLabel(label), style: theme.textTheme.bodySmall)),
          IconButton(
            key: const ValueKey('order-back'),
            tooltip: Strings.of(context).rigSendBehind,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.flip_to_back, size: 16),
            onPressed: () => controller.shiftDrawOrder(boneId, -1),
          ),
          IconButton(
            key: const ValueKey('order-front'),
            tooltip: Strings.of(context).rigBringFront,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.flip_to_front, size: 16),
            onPressed: () => controller.shiftDrawOrder(boneId, 1),
          ),
          if (keyed)
            IconButton(
              key: const ValueKey('order-clear'),
              tooltip: Strings.of(context).rigRemoveOrderKey,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => controller.deleteOrderKey(boneId, controller.time),
            ),
        ],
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
            title: Text(Strings.of(context).rigMoveConnected),
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
                      label: Strings.of(context).rigLength,
                      value: bone.length,
                      minimum: .5,
                      onApply: (v) {
                        controller.setBoneGeometry(bone.id, length: v);
                        return controller.bone(bone.id)!.length;
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: _BoneNumber(
                      label: Strings.of(context).rigAngle,
                      step: 1,
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
                      label: Strings.of(context).rigTailX,
                      value: bone.tail.dx,
                      onApply: (v) {
                        controller.setBoneEndpoint(bone.id, Offset(v, bone.tail.dy));
                        return controller.bone(bone.id)!.tail.dx;
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: _BoneNumber(
                      label: Strings.of(context).rigTailY,
                      value: bone.tail.dy,
                      onApply: (v) {
                        controller.setBoneEndpoint(bone.id, Offset(bone.tail.dx, v));
                        return controller.bone(bone.id)!.tail.dy;
                      })),
            ]),
            const SizedBox(height: 6),
            Text(Strings.of(context).rigEnterHint,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(child: Text(Strings.of(context).rigSnapAngle, style: theme.textTheme.bodySmall)),
              _SnapDropdown(
                key: const ValueKey('bone-snap'),
                value: bone.snapAngle,
                inheritLabel: Strings.of(context).rigSnapRigDefault,
                onChanged: (v) => controller.setBoneSnap(bone.id, v),
              ),
            ],
          ),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text(Strings.of(context).rigLimitRotation, style: theme.textTheme.bodySmall),
          value: limited,
          onChanged: (on) =>
              on ? controller.setBoneLimits(bone.id, min: -90, max: 90) : controller.setBoneLimits(bone.id),
        ),
        if (limited) ...[
          stat(Strings.of(context).rigRange, Strings.of(context).rigRangeValue(min.round(), max.round())),
          Row(children: [
            Expanded(
                child: _BoneNumber(
                    label: Strings.of(context).rigMinAngle,
                    step: 1,
                    value: min,
                    onApply: (v) {
                      controller.setBoneLimits(bone.id, min: v, max: max);
                      return controller.bone(bone.id)!.minAngle!;
                    })),
            Expanded(
                child: _BoneNumber(
                    label: Strings.of(context).rigMaxAngle,
                    step: 1,
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
  const _BoneNumber({required this.label, required this.value, required this.onApply, this.minimum, this.step = .5});
  final String label;
  final double value;
  final double? minimum;

  /// How far the arrows nudge the value (degrees for angles, else pixels).
  final double step;
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
        style: context.pv.mono(size: 12),
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
                        final value = widget.onApply(widget.value + widget.step);
                        _text.text = value.toStringAsFixed(1);
                      },
                      child: const Icon(Icons.arrow_drop_up, size: 18)),
                  InkWell(
                      onTap: () {
                        final n = widget.value - widget.step;
                        if (widget.minimum != null && n < widget.minimum!) return;
                        final value = widget.onApply(n);
                        _text.text = value.toStringAsFixed(1);
                      },
                      child: const Icon(Icons.arrow_drop_down, size: 18)),
                ]))),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (text) {
          final n = double.tryParse(text ?? '');
          return n == null || !n.isFinite || (widget.minimum != null && n < widget.minimum!)
              ? Strings.of(context).rigInvalidValue
              : null;
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

/// The words for an easing curve, in the app's language.
String rigEasingName(Strings strings, RigEasing easing) => switch (easing) {
      RigEasing.linear => strings.rigEasingLinear,
      RigEasing.easeIn => strings.rigEasingIn,
      RigEasing.easeOut => strings.rigEasingOut,
      RigEasing.easeInOut => strings.rigEasingInOut,
      RigEasing.stepped => strings.rigEasingStepped,
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
            Text(Strings.of(context).rigJointFrozen, style: Theme.of(context).textTheme.bodySmall),
            TextButton(
                onPressed: () => controller.unfreezeJoint(bone.id), child: Text(Strings.of(context).rigUnfreezeJoint)),
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
        stat(Strings.of(context).rigSectionBone, bone.name),
        if (driven)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
            child: Text(
              Strings.of(context).rigSteeredByIk,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
            ),
          ),
        stat(Strings.of(context).rigRotation, '${pose.rotation.toStringAsFixed(0)}°'),
        stat(Strings.of(context).rigOffset,
            '${pose.translation.dx.toStringAsFixed(0)}, ${pose.translation.dy.toStringAsFixed(0)}'),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text(Strings.of(context).rigFlipH, style: theme.textTheme.bodySmall),
          value: pose.flipX,
          onChanged: (on) => controller.setPose(bone.id, flipX: on),
        ),
        _DrawOrderRow(controller: controller, boneId: bone.id),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: Row(
            children: [
              Icon(key == null ? Icons.timeline : Icons.diamond,
                  size: 14, color: key == null ? muted : theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  key == null ? Strings.of(context).rigBetweenKeys : Strings.of(context).rigKeyedHere,
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
            child: key == null || controller.isPending(bone.id)
                ? TextButton(
                    onPressed: () => controller.keyBone(bone.id),
                    child: Text(key == null ? Strings.of(context).rigAddKey : Strings.of(context).rigUpdateKey))
                : TextButton(
                    onPressed: () => controller.deleteKey(bone.id, controller.time),
                    child: Text(Strings.of(context).rigRemoveKey)),
          ),
        ),
        if (key != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  isDense: true,
                  value: key.curve != null ? -1 : key.easing.index,
                  items: [
                    if (key.curve != null)
                      DropdownMenuItem(
                          value: -1,
                          child: Text(Strings.of(context).rigEasingCustom, style: theme.textTheme.bodySmall)),
                    for (final e in RigEasing.values)
                      DropdownMenuItem(
                          value: e.index,
                          child: Text(rigEasingName(Strings.of(context), e), style: theme.textTheme.bodySmall)),
                  ],
                  onChanged: (i) {
                    if (i != null && i >= 0) controller.setKeyEasing(bone.id, controller.time, RigEasing.values[i]);
                  },
                ),
              ),
              IconButton(
                tooltip: Strings.of(context).rigEditCurve,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.show_chart, size: 18, color: key.curve != null ? theme.colorScheme.primary : null),
                onPressed: () async {
                  final curve = await showEasingCurveDialog(context, key.curve ?? curveOfEasing(key.easing));
                  if (curve != null) controller.setKeyCurve(bone.id, controller.time, curve);
                },
              ),
            ]),
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
            Text(Strings.of(context).rigIkPartOf(inChains.first.name), style: hint),
            TextButton(
              onPressed: () => controller.selectIkChain(inChains.first.id),
              child: Text(Strings.of(context).rigEditChain),
            ),
          ] else ...[
            Text(
              most < 2 ? Strings.of(context).rigIkAttachHint : Strings.of(context).rigIkBendHint,
              style: hint,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                key: const ValueKey('add-ik-chain'),
                onPressed: () => controller.addIkChain(tipBoneId: bone.id),
                child: Text(most < 2 ? Strings.of(context).rigAddIkToBone : Strings.of(context).rigAddIkChain),
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
        row(Strings.of(context).rigChain,
            Text(chain.name, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))),
        row(
          Strings.of(context).rigSectionBones,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: Strings.of(context).rigFewerBones,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 14),
                onPressed:
                    chain.boneCount > 1 ? () => controller.setIkChain(chain.id, boneCount: chain.boneCount - 1) : null,
              ),
              Text('${controller.rig.chainBones(chain).length}', style: theme.textTheme.bodySmall),
              IconButton(
                tooltip: Strings.of(context).rigMoreBones,
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
          title: Text(Strings.of(context).rigFoldOther, style: theme.textTheme.bodySmall),
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
                        ? Strings.of(context).rigFootPlanted
                        : !active
                            ? Strings.of(context).rigIkOff
                            : key == null
                                ? Strings.of(context).rigTargetBetween
                                : Strings.of(context).rigTargetKeyed,
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
                  ? TextButton(
                      onPressed: () => controller.keyIkChain(chain.id), child: Text(Strings.of(context).rigKeyTarget))
                  : TextButton(
                      onPressed: () => controller.deleteIkKey(chain.id, controller.time),
                      child: Text(Strings.of(context).rigRemoveTargetKey),
                    ),
            ),
          ),
          if (key != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    isDense: true,
                    value: key.curve != null ? -1 : key.easing.index,
                    items: [
                      if (key.curve != null)
                        DropdownMenuItem(
                            value: -1,
                            child: Text(Strings.of(context).rigEasingCustom, style: theme.textTheme.bodySmall)),
                      for (final e in RigEasing.values)
                        DropdownMenuItem(
                            value: e.index,
                            child: Text(rigEasingName(Strings.of(context), e), style: theme.textTheme.bodySmall)),
                    ],
                    onChanged: (i) {
                      if (i != null && i >= 0) {
                        controller.setIkKeyEasing(chain.id, controller.time, RigEasing.values[i]);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: Strings.of(context).rigEditCurve,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.show_chart, size: 18, color: key.curve != null ? theme.colorScheme.primary : null),
                  onPressed: () async {
                    final curve = await showEasingCurveDialog(context, key.curve ?? curveOfEasing(key.easing));
                    if (curve != null) controller.setIkKeyCurve(chain.id, controller.time, curve);
                  },
                ),
              ]),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('remove-ik-chain'),
              onPressed: () => controller.removeIkChain(chain.id),
              child: Text(Strings.of(context).rigRemoveIk),
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
              Strings.of(context).rigPoseSaveHint,
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
                        message: Strings.of(context).rigPutPose(pose.name, controller.time + 1),
                        child: Text(pose.name, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                      ),
                    ),
                    PopupMenuButton<_PoseAction>(
                      tooltip: Strings.of(context).rigPoseActions,
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
                          title: Strings.of(context).rigRenamePose,
                          initial: pose.name,
                          action: Strings.of(context).rename,
                        );
                        if (name != null) controller.renamePose(pose.id, name);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: _PoseAction.rename, child: Text(Strings.of(context).rename)),
                        PopupMenuItem(value: _PoseAction.delete, child: Text(Strings.of(context).delete)),
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
                        title: Strings.of(context).rigSavePose,
                        initial: Strings.of(context).rigPoseDefault(poses.length + 1),
                        action: Strings.of(context).save,
                      );
                      if (name != null) controller.savePose(name);
                    },
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: Text(Strings.of(context).rigSaveFrameAsPose(controller.time + 1)),
            ),
          ),
        ),
      ],
    );
  }
}
