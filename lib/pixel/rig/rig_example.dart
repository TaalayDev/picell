import '../../data/models/layer.dart';
import '../../data/models/rig/rig.dart';
import 'presets/bone_presets.dart';
import 'presets/motion_catalog.dart';
import 'rig_editor_controller.dart';

/// Rigs the layered "Simple Hero" example: the Basic character skeleton placed
/// on [restLayers] (bound by layer name) with ready-made idle, walk and jump
/// clips, so the rig editor opens on a working example. [base] supplies the
/// rig's id, animation state and rest frame.
Rig buildBoneRigExample({
  required Rig base,
  required List<Layer> restLayers,
  required int width,
  required int height,
  int fps = 12,
}) {
  final c = RigEditorController(
    rig: base,
    restLayers: restLayers,
    width: width,
    height: height,
    defaultFps: fps,
    clipName: 'Idle',
  );
  c.beginPlacement(BonePresets.humanoidBasic);
  c.commitPlacement();
  c.mode = RigMode.animate;

  c.applyMotion(MotionPresets.frontIdle);
  c.createClip('Walk');
  c.applyMotion(MotionPresets.frontWalk);
  final walkId = c.activeClip.id;
  c.createClip('Jump');
  c.applyMotion(MotionPresets.frontJump);
  c.selectClip(walkId);
  c.mode = RigMode.setup;
  return c.rig;
}
