import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/utils/image_helper.dart';
import '../../../pixel/rig/presets/motion_presets.dart';
import '../../../pixel/rig/rig_baker.dart';
import '../../../pixel/rig/rig_editor_controller.dart';
import 'rig_canvas.dart';

class MotionChoice {
  const MotionChoice(this.preset, {required this.intensity, required this.mirror});
  final MotionPreset preset;
  final double intensity;
  final bool mirror;
}

Future<MotionChoice?> configureMotionPreset(BuildContext context, RigEditorController controller, MotionPreset preset) {
  final mobile = MediaQuery.sizeOf(context).width < 760;
  final content = _MotionConfiguration(controller: controller, preset: preset);
  if (mobile) {
    return showModalBottomSheet<MotionChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(height: MediaQuery.sizeOf(context).height * .92, child: content),
    );
  }
  return showDialog<MotionChoice>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: 880, height: 640, child: content),
    ),
  );
}

class _MotionConfiguration extends StatefulWidget {
  const _MotionConfiguration({required this.controller, required this.preset});
  final RigEditorController controller;
  final MotionPreset preset;

  @override
  State<_MotionConfiguration> createState() => _MotionConfigurationState();
}

class _MotionConfigurationState extends State<_MotionConfiguration> {
  late int _frames;
  late int _fps;
  late bool _loop;
  late bool _plantFeet;
  late bool _lockLegs;
  late Map<String, String> _roles;
  bool _proportions = false, _alignGround = false, _keepPosition = true;
  late double _groundY;
  double _intensity = 1;
  bool _mirror = false;
  late RigEditorController _preview;
  late RigBaker _baker;
  ui.Image? _image;
  Timer? _timer;
  int _version = 0;
  bool _usable = false;
  List<String> _missingRoles = const [];

  MotionPreset get _configured => widget.preset.copyWith(
        roleBindings: _roles,
        proportionScale: _proportions,
        keepPosition: _keepPosition,
        groundY: () => _alignGround ? _groundY : null,
        frames: _frames,
        fps: _fps,
        loop: _loop,
        plantFeet: _plantFeet,
        lockedRoles:
            _lockLegs ? (widget.preset.legControls ? MotionPreset.legJointRoles : widget.preset.lockedRoles) : const [],
      );

  @override
  void initState() {
    super.initState();
    _roles = {
      for (final e in widget.controller.rig.roleBindings.entries)
        if (widget.controller.bone(e.value) != null) e.key: e.value
    };
    _groundY = widget.controller.height.toDouble();
    _frames = widget.preset.frames;
    _fps = widget.preset.fps;
    _loop = widget.preset.loop;
    _plantFeet = widget.preset.plantFeet;
    _lockLegs = widget.preset.lockedRoles.isNotEmpty;
    _buildPreview();
  }

  // The working rig and its undo history are untouched until Apply.
  void _buildPreview() {
    final source = widget.controller;
    _preview = RigEditorController(
      rig: source.rig,
      restLayers: source.restLayers,
      width: source.width,
      height: source.height,
    )..mode = RigMode.animate;
    _preview.selectBone(source.selectedBoneId);
    final result = _preview.applyMotion(_configured, intensity: _intensity, mirror: _mirror);
    _usable = !result.isEmpty;
    _missingRoles = result.missing;
    _baker = RigBaker(rig: _preview.rig, width: source.width, height: source.height, layers: source.restLayers);
    _render();
  }

  void _change(VoidCallback update) {
    _stop();
    _preview.dispose();
    setState(() {
      update();
      _buildPreview();
    });
  }

  Future<void> _render() async {
    final version = ++_version;
    final pixels = _baker.bakeFrame(_preview.activeClip, _preview.time.toDouble());
    final image = await ImageHelper.createImageFromPixels(pixels, _preview.width, _preview.height);
    if (!mounted || version != _version) {
      image.dispose();
      return;
    }
    final old = _image;
    setState(() => _image = image);
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _frame(int frame) {
    setState(() => _preview.setTime(frame));
    _render();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _play() {
    if (_timer != null) {
      setState(_stop);
      return;
    }
    if (_preview.time == _frames - 1) _frame(0);
    setState(() {
      _timer = Timer.periodic(Duration(milliseconds: (1000 / _fps).round()), (_) {
        final next = _preview.time + 1;
        if (next < _frames) {
          _frame(next);
        } else if (_loop) {
          _frame(0);
        } else {
          setState(_stop);
        }
      });
    });
  }

  @override
  void dispose() {
    _stop();
    _version++;
    _preview.dispose();
    _image?.dispose();
    super.dispose();
  }

  Widget _slider(String title, String key, double value, double min, double max, int divisions, String label,
          ValueChanged<double> change) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(title)), Text(label)]),
          Slider(
              key: ValueKey(key),
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: (v) => _change(() => change(v))),
        ],
      );

  Widget _properties() => ListView(
        key: const ValueKey('motion-properties'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.preset.description, style: Theme.of(context).textTheme.bodySmall),
          if (_usable && _missingRoles.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Unmapped roles: ${_missingRoles.join(', ')}. Choose bones under Bone role mapping.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 16),
          _slider('Strength', 'motion-intensity', _intensity, .5, 2, 6, '${(_intensity * 100).round()}%',
              (v) => _intensity = v),
          _slider('Frames', 'motion-frames', _frames.toDouble(), 1, 240, 239, '$_frames', (v) => _frames = v.round()),
          _slider('Frame rate', 'motion-fps', _fps.toDouble(), 1, 60, 59, '$_fps fps', (v) => _fps = v.round()),
          SwitchListTile(
            key: const ValueKey('motion-loop'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Loop'),
            value: _loop,
            onChanged: (v) => _change(() => _loop = v),
          ),
          SwitchListTile(
            key: const ValueKey('motion-mirror'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Face the other way'),
            subtitle: const Text('Swap left and right and reverse the swings.'),
            value: _mirror,
            onChanged: (v) => _change(() => _mirror = v),
          ),
          SwitchListTile(
              title: const Text('Scale motion to body proportions'),
              value: _proportions,
              onChanged: (v) => _change(() => _proportions = v)),
          if (widget.preset.target == MotionTarget.roles) ...[
            SwitchListTile(
                title: const Text('Keep current position'),
                value: _keepPosition,
                onChanged: (v) => _change(() => _keepPosition = v)),
            SwitchListTile(
                title: const Text('Align feet to ground'),
                value: _alignGround,
                onChanged: (v) => _change(() => _alignGround = v)),
            if (_alignGround)
              _slider('Ground Y', 'motion-ground-y', _groundY, 0, widget.controller.height.toDouble(),
                  widget.controller.height * 2, _groundY.toStringAsFixed(1), (v) => _groundY = v),
            ExpansionTile(title: const Text('Bone role mapping'), children: [
              for (final role in {...widget.preset.roles, if (widget.preset.legControls) ...MotionPreset.legJointRoles})
                DropdownButtonFormField<String>(
                    initialValue: _roles[role] ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(labelText: role),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Automatic (by name)')),
                      for (final b in widget.controller.rig.bones) DropdownMenuItem(value: b.id, child: Text(b.name)),
                    ],
                    onChanged: (id) => _change(() {
                          if (id == null || id.isEmpty) {
                            _roles.remove(role);
                          } else {
                            _roles[role] = id;
                          }
                        })),
            ]),
          ],
          if (widget.preset.legControls || widget.preset.plantFeet)
            SwitchListTile(
              key: const ValueKey('motion-plant-feet'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Plant feet'),
              subtitle: const Text('Keep foot contacts on the ground.'),
              value: _plantFeet,
              onChanged: (v) => _change(() => _plantFeet = v),
            ),
          if (widget.preset.legControls || widget.preset.lockedRoles.isNotEmpty)
            SwitchListTile(
              key: const ValueKey('motion-lock-legs'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Lock leg joints'),
              subtitle: const Text('Hold thighs, shins and feet in place.'),
              value: _lockLegs,
              onChanged: (v) => _change(() => _lockLegs = v),
            ),
        ],
      );

  Widget _previewPanel() => Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(child: Text('Preview', style: Theme.of(context).textTheme.titleSmall)),
              Text('${(_frames / _fps).toStringAsFixed(2)} s', style: Theme.of(context).textTheme.bodySmall),
            ])),
        Expanded(
            child: ClipRect(
                child: IgnorePointer(
          child: RigCanvas(key: const ValueKey('motion-preview'), controller: _preview, image: _image),
        ))),
        Row(children: [
          IconButton(
              key: const ValueKey('motion-preview-play'),
              tooltip: _timer == null ? 'Play preview' : 'Pause preview',
              onPressed: _usable ? _play : null,
              icon: Icon(_timer == null ? Icons.play_arrow : Icons.pause)),
          Expanded(
              child: Slider(
                  key: const ValueKey('motion-preview-frame'),
                  value: _preview.time.toDouble(),
                  min: 0,
                  max: (_frames - 1).clamp(1, 239).toDouble(),
                  divisions: (_frames - 1).clamp(1, 239),
                  onChanged: _usable && _frames > 1
                      ? (v) {
                          _stop();
                          _frame(v.round());
                        }
                      : null)),
          Padding(padding: const EdgeInsets.only(right: 12), child: Text('${_preview.time + 1} / $_frames')),
        ]),
      ]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
        top: false,
        child: Column(
          key: const ValueKey('motion-configuration'),
          children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: Text('Configure ${widget.preset.name}', style: theme.textTheme.titleMedium)),
                  IconButton(
                      tooltip: 'Close configuration',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ])),
            const Divider(height: 1),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 620) {
                return Column(children: [
                  SizedBox(height: constraints.maxHeight * .47, child: _previewPanel()),
                  const Divider(height: 1),
                  Expanded(child: _properties()),
                ]);
              }
              return Row(children: [
                Expanded(child: _previewPanel()),
                const VerticalDivider(width: 1),
                SizedBox(width: 330, child: _properties()),
              ]);
            })),
            if (!_usable)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                      widget.preset.target == MotionTarget.roles
                          ? 'No matching bones. Name bones like ${widget.preset.roles.take(3).join(', ')}.'
                          : 'Select a bone before choosing this preset.',
                      style: TextStyle(color: theme.colorScheme.error))),
            const Divider(height: 1),
            Padding(
                padding: const EdgeInsets.all(12),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      key: const ValueKey('motion-cancel'),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                      key: const ValueKey('motion-apply'),
                      onPressed: _usable
                          ? () =>
                              Navigator.pop(context, MotionChoice(_configured, intensity: _intensity, mirror: _mirror))
                          : null,
                      child: const Text('Apply')),
                ])),
          ],
        ));
  }
}
