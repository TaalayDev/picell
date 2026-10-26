import 'motion_presets.dart';

/// The animations that come with the editor.
///
/// Rotations follow the editor's rule: positive is clockwise on screen.
/// A character that faces right swings a leg forward by turning it
/// anticlockwise (negative), so the side-facing humanoid presets use that convention;
/// the animals are drawn facing left, so theirs are the other way round.
/// Front Walk and Front Run are separate, viewer-facing cycles.
/// "Mirror" swaps left/right motion and reverses lateral sway.
abstract final class MotionPresets {
  static const _humanoid = 'Character';
  static const _animal = 'Animal';
  static const _any = 'Any bone';

  static const idle = MotionPreset(
    id: 'idle',
    name: 'Idle',
    description:
        'Grounded idle: gentle upper-body breathing, head and arm drift, with gentle body rise and settle while both feet stay planted.',
    category: _humanoid,
    plantFeet: true,
    frames: 8,
    fps: 6,
    // The highest pose is the rest height; settling bends the knees without
    // asking planted legs to stretch past their full reach.
    tracks: [
      MotionTrack('hips', rotation: Wave(), ty: Wave(amplitude: .012, bias: .012, phase: .75)),
      MotionTrack('spine', rotation: Wave(amplitude: 1.5, phase: 0.1)),
      MotionTrack('head', rotation: Wave(amplitude: 1.2, phase: 0.25)),
      MotionTrack('arm_l', rotation: Wave(amplitude: 2.5, phase: 0.2)),
      MotionTrack('arm_r', rotation: Wave(amplitude: -2.5, phase: 0.2)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: 1.5, phase: 0.35)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: -1.5, phase: 0.35)),
      MotionTrack('thigh_l', rotation: Wave()),
      MotionTrack('thigh_r', rotation: Wave()),
      MotionTrack('shin_l', rotation: Wave()),
      MotionTrack('shin_r', rotation: Wave()),
    ],
  );

  static const frontIdle = MotionPreset(
    id: 'front_idle',
    name: 'Front Idle',
    description:
        'Relaxed breathing facing the viewer: gentle body rise and settle, symmetric arm breathing and a centered head with optional foot planting and leg joint locks. Loops.',
    category: _humanoid,
    legControls: true,
    plantFeet: true,
    lockedRoles: MotionPreset.legJointRoles,
    frames: 16,
    fps: 8,
    tracks: [
      MotionTrack('hips', rotation: Wave(), ty: Wave(amplitude: .008, bias: .008, phase: .75)),
      MotionTrack('spine', rotation: Wave()),
      MotionTrack('head', rotation: Wave()),
      MotionTrack('arm_l', rotation: Wave(amplitude: 1.5, bias: 1.5, phase: .75)),
      MotionTrack('arm_r', rotation: Wave(amplitude: -1.5, bias: -1.5, phase: .75)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: -.6, bias: -.6, phase: .75)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: .6, bias: .6, phase: .75)),
      MotionTrack('thigh_l', rotation: Wave()),
      MotionTrack('thigh_r', rotation: Wave()),
      MotionTrack('shin_l', rotation: Wave()),
      MotionTrack('shin_r', rotation: Wave()),
    ],
  );

  static const walk = MotionPreset(
    id: 'walk',
    name: 'Walk',
    description:
        'A steady walk cycle, seen from the side, facing right. Legs swing, knees lift, arms swing the other way.',
    category: _humanoid,
    frames: 8,
    fps: 10,
    tracks: [
      MotionTrack('hips', ty: Wave(amplitude: -0.02, shape: WaveShape.bounce)),
      MotionTrack('spine', rotation: Wave(bias: -3)),
      MotionTrack('head', rotation: Wave(bias: 3)),
      MotionTrack('thigh_l', rotation: Wave(amplitude: -28)),
      MotionTrack('thigh_r', rotation: Wave(amplitude: -28, phase: 0.5)),
      MotionTrack('shin_l', rotation: Wave(amplitude: 40, phase: 0.25, shape: WaveShape.lift)),
      MotionTrack('shin_r', rotation: Wave(amplitude: 40, phase: 0.75, shape: WaveShape.lift)),
      MotionTrack('arm_l', rotation: Wave(amplitude: -22, phase: 0.5)),
      MotionTrack('arm_r', rotation: Wave(amplitude: -22)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: -10, phase: 0.5, bias: -14)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: -10, bias: -14)),
    ],
  );

  static const run = MotionPreset(
    id: 'run',
    name: 'Run',
    description: 'A fast run, facing right: longer strides, high knees, a forward lean and pumping arms.',
    category: _humanoid,
    frames: 8,
    fps: 16,
    tracks: [
      MotionTrack('hips', ty: Wave(amplitude: -0.04, shape: WaveShape.bounce)),
      MotionTrack('spine', rotation: Wave(bias: -10)),
      MotionTrack('head', rotation: Wave(bias: 6)),
      MotionTrack('thigh_l', rotation: Wave(amplitude: -45)),
      MotionTrack('thigh_r', rotation: Wave(amplitude: -45, phase: 0.5)),
      MotionTrack('shin_l', rotation: Wave(amplitude: 70, phase: 0.25, shape: WaveShape.lift)),
      MotionTrack('shin_r', rotation: Wave(amplitude: 70, phase: 0.75, shape: WaveShape.lift)),
      MotionTrack('arm_l', rotation: Wave(amplitude: -50, phase: 0.5)),
      MotionTrack('arm_r', rotation: Wave(amplitude: -50)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: -15, phase: 0.5, bias: -60)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: -15, bias: -60)),
    ],
  );

  /// Front-facing motions use modest alternating bends instead of the broad
  /// sagittal swings and forward lean of the side-facing walk/run. All limb
  /// shifts come from rotations so parent/child joints remain connected.
  static const frontWalk = MotionPreset(
    id: 'front_walk',
    name: 'Front Walk',
    description:
        'Walk in place facing the viewer: alternating steps, opposite arm swings, gentle body sway and bounce.',
    category: _humanoid,
    legControls: true,
    frames: 12,
    fps: 12,
    tracks: [
      MotionTrack('hips',
          tx: Wave(amplitude: .006, phase: .25), ty: Wave(amplitude: -.012, phase: .25, shape: WaveShape.bounce)),
      MotionTrack('spine', rotation: Wave(amplitude: 1.5, phase: .25)),
      MotionTrack('head', rotation: Wave(amplitude: -1.5, phase: .25)),
      MotionTrack('thigh_l', rotation: Wave(amplitude: -7, phase: .25, shape: WaveShape.lift)),
      MotionTrack('thigh_r', rotation: Wave(amplitude: 7, phase: .75, shape: WaveShape.lift)),
      MotionTrack('shin_l', rotation: Wave(amplitude: 15, phase: .25, shape: WaveShape.lift)),
      MotionTrack('shin_r', rotation: Wave(amplitude: -15, phase: .75, shape: WaveShape.lift)),
      MotionTrack('arm_l', rotation: Wave(amplitude: 9, phase: .75, shape: WaveShape.lift)),
      MotionTrack('arm_r', rotation: Wave(amplitude: -9, phase: .25, shape: WaveShape.lift)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: 7, phase: .75, shape: WaveShape.lift)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: -7, phase: .25, shape: WaveShape.lift)),
    ],
  );

  static const frontRun = MotionPreset(
    id: 'front_run',
    name: 'Front Run',
    description:
        'Run in place facing the viewer: higher alternating knees, pumping arms and two springy flight beats per cycle.',
    category: _humanoid,
    legControls: true,
    frames: 12,
    fps: 20,
    tracks: [
      MotionTrack('hips',
          tx: Wave(amplitude: .01, phase: .25), ty: Wave(amplitude: -.035, phase: .25, shape: WaveShape.bounce)),
      MotionTrack('spine', rotation: Wave(amplitude: 3, phase: .25)),
      MotionTrack('head', rotation: Wave(amplitude: -2, phase: .25)),
      MotionTrack('thigh_l', rotation: Wave(amplitude: -18, phase: .25, shape: WaveShape.lift)),
      MotionTrack('thigh_r', rotation: Wave(amplitude: 18, phase: .75, shape: WaveShape.lift)),
      MotionTrack('shin_l', rotation: Wave(amplitude: 36, phase: .25, shape: WaveShape.lift)),
      MotionTrack('shin_r', rotation: Wave(amplitude: -36, phase: .75, shape: WaveShape.lift)),
      MotionTrack('arm_l', rotation: Wave(amplitude: 22, phase: .75, shape: WaveShape.lift)),
      MotionTrack('arm_r', rotation: Wave(amplitude: -22, phase: .25, shape: WaveShape.lift)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: 24, phase: .75, shape: WaveShape.lift)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: -24, phase: .25, shape: WaveShape.lift)),
    ],
  );

  static const frontJump = MotionPreset(
    id: 'front_jump',
    name: 'Front Jump',
    description:
        'Jump facing the viewer: a centered crouch, straight upward takeoff, raised arms, tucked knees and a soft landing. Plays once.',
    category: _humanoid,
    legControls: true,
    frames: 16,
    fps: 16,
    loop: false,
    tracks: [
      MotionTrack('hips', keys: [
        MotionKey(0),
        MotionKey(.18, ty: .045),
        MotionKey(.32, ty: -.055),
        MotionKey(.5, ty: -.16),
        MotionKey(.68, ty: -.09),
        MotionKey(.82, ty: .04),
        MotionKey(1),
      ]),
      MotionTrack('spine', keys: [MotionKey(0), MotionKey(1)]),
      MotionTrack('head', keys: [MotionKey(0), MotionKey(1)]),
      MotionTrack('thigh_l', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: 18),
        MotionKey(.32, rotation: 3),
        MotionKey(.5, rotation: 22),
        MotionKey(.68, rotation: 8),
        MotionKey(.82, rotation: 18),
        MotionKey(1),
      ]),
      MotionTrack('thigh_r', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: -18),
        MotionKey(.32, rotation: -3),
        MotionKey(.5, rotation: -22),
        MotionKey(.68, rotation: -8),
        MotionKey(.82, rotation: -18),
        MotionKey(1),
      ]),
      MotionTrack('shin_l', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: -32),
        MotionKey(.32),
        MotionKey(.5, rotation: -42),
        MotionKey(.68, rotation: -12),
        MotionKey(.82, rotation: -32),
        MotionKey(1),
      ]),
      MotionTrack('shin_r', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: 32),
        MotionKey(.32),
        MotionKey(.5, rotation: 42),
        MotionKey(.68, rotation: 12),
        MotionKey(.82, rotation: 32),
        MotionKey(1),
      ]),
      MotionTrack('arm_l', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: -12),
        MotionKey(.32, rotation: 75),
        MotionKey(.5, rotation: 110),
        MotionKey(.68, rotation: 70),
        MotionKey(.82, rotation: 12),
        MotionKey(1),
      ]),
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: 12),
        MotionKey(.32, rotation: -75),
        MotionKey(.5, rotation: -110),
        MotionKey(.68, rotation: -70),
        MotionKey(.82, rotation: -12),
        MotionKey(1),
      ]),
      MotionTrack('forearm_l', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: 15),
        MotionKey(.5, rotation: 20),
        MotionKey(.82, rotation: 10),
        MotionKey(1),
      ]),
      MotionTrack('forearm_r', keys: [
        MotionKey(0),
        MotionKey(.18, rotation: -15),
        MotionKey(.5, rotation: -20),
        MotionKey(.82, rotation: -10),
        MotionKey(1),
      ]),
    ],
  );

  static const frontAttack = MotionPreset(
    id: 'front_attack',
    name: 'Front Attack Swing',
    description:
        'Attack facing the viewer: raise the right arm, swing diagonally across the body, follow through and return to guard. Mirror to use the left arm. Plays once.',
    category: _humanoid,
    legControls: true,
    frames: 14,
    fps: 20,
    loop: false,
    tracks: [
      MotionTrack('hips', keys: [
        MotionKey(0),
        MotionKey(.25, rotation: 3, ty: .01),
        MotionKey(.4, rotation: -3),
        MotionKey(.58, rotation: -4, ty: .015),
        MotionKey(1),
      ]),
      MotionTrack('spine', keys: [
        MotionKey(0),
        MotionKey(.25, rotation: 5),
        MotionKey(.4, rotation: -7),
        MotionKey(.58, rotation: -4),
        MotionKey(1),
      ]),
      MotionTrack('head', keys: [
        MotionKey(0),
        MotionKey(.25, rotation: -6),
        MotionKey(.4, rotation: 8),
        MotionKey(1),
      ]),
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(.25, rotation: -135),
        MotionKey(.4, rotation: -35),
        MotionKey(.58, rotation: 45),
        MotionKey(.78, rotation: 15),
        MotionKey(1),
      ]),
      MotionTrack('forearm_r', keys: [
        MotionKey(0),
        MotionKey(.25, rotation: -35),
        MotionKey(.4, rotation: 25),
        MotionKey(.58, rotation: 60),
        MotionKey(.78, rotation: 15),
        MotionKey(1),
      ]),
      MotionTrack('arm_l', keys: [
        MotionKey(0),
        MotionKey(.25, rotation: -10),
        MotionKey(.58, rotation: -18),
        MotionKey(1),
      ]),
      MotionTrack('forearm_l', keys: [
        MotionKey(0),
        MotionKey(.25, rotation: -30),
        MotionKey(.58, rotation: -40),
        MotionKey(1),
      ]),
      MotionTrack('thigh_l',
          keys: [MotionKey(0), MotionKey(.25, rotation: 5), MotionKey(.58, rotation: 8), MotionKey(1)]),
      MotionTrack('thigh_r',
          keys: [MotionKey(0), MotionKey(.25, rotation: -5), MotionKey(.58, rotation: -8), MotionKey(1)]),
      MotionTrack('shin_l', keys: [MotionKey(0), MotionKey(.58, rotation: -10), MotionKey(1)]),
      MotionTrack('shin_r', keys: [MotionKey(0), MotionKey(.58, rotation: 10), MotionKey(1)]),
    ],
  );

  static const frontHurt = MotionPreset(
    id: 'front_hurt',
    name: 'Front Hurt',
    description:
        'A short hit reaction facing the viewer: recoil, brace the arms, then recover. Mirror the impact direction. Plays once.',
    category: _humanoid,
    legControls: true,
    frames: 10,
    fps: 18,
    loop: false,
    tracks: [
      MotionTrack('hips', keys: [
        MotionKey(0),
        MotionKey(0.18, tx: -0.012, ty: 0.008),
        MotionKey(0.45, tx: 0.006, ty: 0.012),
        MotionKey(0.75),
        MotionKey(1)
      ]),
      MotionTrack('spine', keys: [
        MotionKey(0),
        MotionKey(0.18, rotation: -8),
        MotionKey(0.45, rotation: 4),
        MotionKey(0.75),
        MotionKey(1)
      ]),
      MotionTrack('head', keys: [
        MotionKey(0),
        MotionKey(0.18, rotation: 10),
        MotionKey(0.45, rotation: -4),
        MotionKey(0.75),
        MotionKey(1)
      ]),
      MotionTrack('arm_l', keys: [
        MotionKey(0),
        MotionKey(0.18, rotation: 25),
        MotionKey(0.45, rotation: 12),
        MotionKey(0.75),
        MotionKey(1)
      ]),
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(0.18, rotation: -35),
        MotionKey(0.45, rotation: -15),
        MotionKey(0.75),
        MotionKey(1)
      ]),
      MotionTrack('forearm_l', keys: [
        MotionKey(0),
        MotionKey(0.18, rotation: -30),
        MotionKey(0.45, rotation: -18),
        MotionKey(0.75),
        MotionKey(1)
      ]),
      MotionTrack('forearm_r', keys: [
        MotionKey(0),
        MotionKey(0.18, rotation: 40),
        MotionKey(0.45, rotation: 20),
        MotionKey(0.75),
        MotionKey(1)
      ]),
      MotionTrack('thigh_l',
          keys: [MotionKey(0), MotionKey(0.18, rotation: 6), MotionKey(0.45), MotionKey(0.75), MotionKey(1)]),
      MotionTrack('thigh_r',
          keys: [MotionKey(0), MotionKey(0.18, rotation: -6), MotionKey(0.45), MotionKey(0.75), MotionKey(1)]),
      MotionTrack('shin_l',
          keys: [MotionKey(0), MotionKey(0.18, rotation: -10), MotionKey(0.45), MotionKey(0.75), MotionKey(1)]),
      MotionTrack('shin_r',
          keys: [MotionKey(0), MotionKey(0.18, rotation: 10), MotionKey(0.45), MotionKey(0.75), MotionKey(1)]),
    ],
  );

  static const frontCrouch = MotionPreset(
    id: 'front_crouch',
    name: 'Front Crouch',
    description: 'Lower into a symmetric crouch and hold the final pose. Facing the viewer; plays once.',
    category: _humanoid,
    legControls: true,
    frames: 12,
    fps: 14,
    loop: false,
    tracks: [
      MotionTrack('hips',
          keys: [MotionKey(0), MotionKey(0.45, ty: 0.055), MotionKey(0.8, ty: 0.055), MotionKey(1, ty: 0.055)]),
      MotionTrack('spine',
          keys: [MotionKey(0), MotionKey(0.45, rotation: 3), MotionKey(0.8, rotation: 3), MotionKey(1, rotation: 3)]),
      MotionTrack('head', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: -3),
        MotionKey(0.8, rotation: -3),
        MotionKey(1, rotation: -3)
      ]),
      MotionTrack('arm_l', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: 12),
        MotionKey(0.8, rotation: 12),
        MotionKey(1, rotation: 12)
      ]),
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: -12),
        MotionKey(0.8, rotation: -12),
        MotionKey(1, rotation: -12)
      ]),
      MotionTrack('forearm_l', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: -28),
        MotionKey(0.8, rotation: -28),
        MotionKey(1, rotation: -28)
      ]),
      MotionTrack('forearm_r', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: 28),
        MotionKey(0.8, rotation: 28),
        MotionKey(1, rotation: 28)
      ]),
      MotionTrack('thigh_l', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: 22),
        MotionKey(0.8, rotation: 22),
        MotionKey(1, rotation: 22)
      ]),
      MotionTrack('thigh_r', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: -22),
        MotionKey(0.8, rotation: -22),
        MotionKey(1, rotation: -22)
      ]),
      MotionTrack('shin_l', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: -36),
        MotionKey(0.8, rotation: -36),
        MotionKey(1, rotation: -36)
      ]),
      MotionTrack('shin_r', keys: [
        MotionKey(0),
        MotionKey(0.45, rotation: 36),
        MotionKey(0.8, rotation: 36),
        MotionKey(1, rotation: 36)
      ]),
    ],
  );

  static const frontLand = MotionPreset(
    id: 'front_land',
    name: 'Front Land',
    description:
        'Absorb a landing with bent knees and braced arms, then settle upright. Facing the viewer; plays once.',
    category: _humanoid,
    legControls: true,
    frames: 10,
    fps: 18,
    loop: false,
    tracks: [
      MotionTrack('hips',
          keys: [MotionKey(0), MotionKey(0.22, ty: 0.045), MotionKey(0.55, ty: 0.012), MotionKey(0.8), MotionKey(1)]),
      MotionTrack('spine',
          keys: [MotionKey(0), MotionKey(0.22, rotation: 5), MotionKey(0.55), MotionKey(0.8), MotionKey(1)]),
      MotionTrack('head',
          keys: [MotionKey(0), MotionKey(0.22, rotation: -7), MotionKey(0.55), MotionKey(0.8), MotionKey(1)]),
      MotionTrack('arm_l', keys: [
        MotionKey(0),
        MotionKey(0.22, rotation: 25),
        MotionKey(0.55, rotation: 8),
        MotionKey(0.8),
        MotionKey(1)
      ]),
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(0.22, rotation: -25),
        MotionKey(0.55, rotation: -8),
        MotionKey(0.8),
        MotionKey(1)
      ]),
      MotionTrack('forearm_l',
          keys: [MotionKey(0), MotionKey(0.22, rotation: -20), MotionKey(0.55), MotionKey(0.8), MotionKey(1)]),
      MotionTrack('forearm_r',
          keys: [MotionKey(0), MotionKey(0.22, rotation: 20), MotionKey(0.55), MotionKey(0.8), MotionKey(1)]),
      MotionTrack('thigh_l', keys: [
        MotionKey(0),
        MotionKey(0.22, rotation: 18),
        MotionKey(0.55, rotation: 5),
        MotionKey(0.8),
        MotionKey(1)
      ]),
      MotionTrack('thigh_r', keys: [
        MotionKey(0),
        MotionKey(0.22, rotation: -18),
        MotionKey(0.55, rotation: -5),
        MotionKey(0.8),
        MotionKey(1)
      ]),
      MotionTrack('shin_l', keys: [
        MotionKey(0),
        MotionKey(0.22, rotation: -30),
        MotionKey(0.55, rotation: -8),
        MotionKey(0.8),
        MotionKey(1)
      ]),
      MotionTrack('shin_r', keys: [
        MotionKey(0),
        MotionKey(0.22, rotation: 30),
        MotionKey(0.55, rotation: 8),
        MotionKey(0.8),
        MotionKey(1)
      ]),
    ],
  );

  static const frontInteract = MotionPreset(
    id: 'front_interact',
    name: 'Front Interact',
    description:
        'Reach with the right hand, pause to use or pick up an object, then return. Mirror to use the left hand. Plays once.',
    category: _humanoid,
    legControls: true,
    frames: 16,
    fps: 12,
    loop: false,
    tracks: [
      MotionTrack('hips',
          keys: [MotionKey(0), MotionKey(0.3, ty: 0.008), MotionKey(0.65, ty: 0.008), MotionKey(0.85), MotionKey(1)]),
      MotionTrack('spine', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: -4),
        MotionKey(0.65, rotation: -4),
        MotionKey(0.85),
        MotionKey(1)
      ]),
      MotionTrack('head', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: 3),
        MotionKey(0.65, rotation: 3),
        MotionKey(0.85),
        MotionKey(1)
      ]),
      MotionTrack('arm_l', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: -8),
        MotionKey(0.65, rotation: -8),
        MotionKey(0.85),
        MotionKey(1)
      ]),
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: -65),
        MotionKey(0.65, rotation: -65),
        MotionKey(0.85, rotation: -20),
        MotionKey(1)
      ]),
      MotionTrack('forearm_l', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: -12),
        MotionKey(0.65, rotation: -12),
        MotionKey(0.85),
        MotionKey(1)
      ]),
      MotionTrack('forearm_r', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: -35),
        MotionKey(0.65, rotation: -35),
        MotionKey(0.85, rotation: -10),
        MotionKey(1)
      ]),
      MotionTrack('thigh_l', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: 3),
        MotionKey(0.65, rotation: 3),
        MotionKey(0.85),
        MotionKey(1)
      ]),
      MotionTrack('thigh_r', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: -3),
        MotionKey(0.65, rotation: -3),
        MotionKey(0.85),
        MotionKey(1)
      ]),
      MotionTrack('shin_l', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: -5),
        MotionKey(0.65, rotation: -5),
        MotionKey(0.85),
        MotionKey(1)
      ]),
      MotionTrack('shin_r', keys: [
        MotionKey(0),
        MotionKey(0.3, rotation: 5),
        MotionKey(0.65, rotation: 5),
        MotionKey(0.85),
        MotionKey(1)
      ]),
    ],
  );

  static const frontCelebrate = MotionPreset(
    id: 'front_celebrate',
    name: 'Front Celebrate',
    description: 'Raise both arms and bounce gently in celebration. Facing the viewer; loops in place.',
    category: _humanoid,
    legControls: true,
    frames: 20,
    fps: 12,
    tracks: [
      MotionTrack('hips', ty: Wave(amplitude: .012, bias: .012, phase: .75, cycles: 2)),
      MotionTrack('spine', rotation: Wave(amplitude: 3)),
      MotionTrack('head', rotation: Wave(amplitude: -3)),
      MotionTrack('arm_l', rotation: Wave(amplitude: 8, bias: 115, cycles: 2)),
      MotionTrack('arm_r', rotation: Wave(amplitude: -8, bias: -115, cycles: 2)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: -6, bias: -35, cycles: 2)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: 6, bias: 35, cycles: 2)),
      MotionTrack('thigh_l', rotation: Wave(amplitude: 4, bias: 4, phase: .75, cycles: 2)),
      MotionTrack('thigh_r', rotation: Wave(amplitude: -4, bias: -4, phase: .75, cycles: 2)),
      MotionTrack('shin_l', rotation: Wave(amplitude: -6, bias: -6, phase: .75, cycles: 2)),
      MotionTrack('shin_r', rotation: Wave(amplitude: 6, bias: 6, phase: .75, cycles: 2)),
    ],
  );

  static const dash = MotionPreset(
    id: 'dash',
    name: 'Dash',
    description:
        'A quick in-place burst facing right: anticipate, lean into a long stride, then recover. Mirror to face left. Plays once.',
    category: _humanoid,
    frames: 10,
    fps: 24,
    loop: false,
    tracks: [
      MotionTrack('hips', keys: [
        MotionKey(0),
        MotionKey(0.15, tx: -0.01, ty: 0.02),
        MotionKey(0.4, tx: 0.035, ty: 0.005),
        MotionKey(0.7, tx: 0.012, ty: 0.015),
        MotionKey(1)
      ]),
      MotionTrack('spine', keys: [
        MotionKey(0),
        MotionKey(0.15, rotation: -8),
        MotionKey(0.4, rotation: -28),
        MotionKey(0.7, rotation: -12),
        MotionKey(1)
      ]),
      MotionTrack('head', keys: [
        MotionKey(0),
        MotionKey(0.15, rotation: 5),
        MotionKey(0.4, rotation: 15),
        MotionKey(0.7, rotation: 8),
        MotionKey(1)
      ]),
      MotionTrack('arm_l', keys: [
        MotionKey(0),
        MotionKey(0.15),
        MotionKey(0.4, rotation: 40),
        MotionKey(0.7, rotation: -25),
        MotionKey(1)
      ]),
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(0.15),
        MotionKey(0.4, rotation: -55),
        MotionKey(0.7, rotation: 20),
        MotionKey(1)
      ]),
      MotionTrack('forearm_l', keys: [
        MotionKey(0),
        MotionKey(0.15),
        MotionKey(0.4, rotation: -65),
        MotionKey(0.7, rotation: -25),
        MotionKey(1)
      ]),
      MotionTrack('forearm_r', keys: [
        MotionKey(0),
        MotionKey(0.15),
        MotionKey(0.4, rotation: -35),
        MotionKey(0.7, rotation: -40),
        MotionKey(1)
      ]),
      MotionTrack('thigh_l', keys: [
        MotionKey(0),
        MotionKey(0.15, rotation: -15),
        MotionKey(0.4, rotation: -65),
        MotionKey(0.7, rotation: 20),
        MotionKey(1)
      ]),
      MotionTrack('thigh_r', keys: [
        MotionKey(0),
        MotionKey(0.15, rotation: 12),
        MotionKey(0.4, rotation: 40),
        MotionKey(0.7, rotation: -30),
        MotionKey(1)
      ]),
      MotionTrack('shin_l', keys: [
        MotionKey(0),
        MotionKey(0.15, rotation: 25),
        MotionKey(0.4, rotation: 20),
        MotionKey(0.7, rotation: 40),
        MotionKey(1)
      ]),
      MotionTrack('shin_r', keys: [
        MotionKey(0),
        MotionKey(0.15, rotation: 10),
        MotionKey(0.4, rotation: 65),
        MotionKey(0.7, rotation: 20),
        MotionKey(1)
      ]),
    ],
  );

  static const fall = MotionPreset(
    id: 'fall',
    name: 'Fall',
    description:
        'A falling pose facing right with trailing arms and loose legs. Loops in place; vertical travel stays under your control.',
    category: _humanoid,
    frames: 12,
    fps: 12,
    tracks: [
      MotionTrack('hips', rotation: Wave(amplitude: 2)),
      MotionTrack('spine', rotation: Wave(amplitude: 2, bias: 8)),
      MotionTrack('head', rotation: Wave(amplitude: -2, bias: -5)),
      MotionTrack('arm_l', rotation: Wave(amplitude: 6, bias: -110)),
      MotionTrack('arm_r', rotation: Wave(amplitude: 6, bias: -85, phase: .5)),
      MotionTrack('forearm_l', rotation: Wave(amplitude: 5, bias: -20)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: 5, bias: -35, phase: .5)),
      MotionTrack('thigh_l', rotation: Wave(amplitude: 5, bias: -20)),
      MotionTrack('thigh_r', rotation: Wave(amplitude: 5, bias: 15, phase: .5)),
      MotionTrack('shin_l', rotation: Wave(amplitude: 5, bias: 30)),
      MotionTrack('shin_r', rotation: Wave(amplitude: 5, bias: 15, phase: .5)),
    ],
  );

  static const jump = MotionPreset(
    id: 'jump',
    name: 'Jump',
    description: 'Crouch, spring up with the arms, tuck at the top, land and settle. Plays once, facing right.',
    category: _humanoid,
    frames: 12,
    fps: 12,
    loop: false,
    tracks: [
      MotionTrack('hips', keys: [
        MotionKey(0),
        MotionKey(0.12, ty: 0.04),
        MotionKey(0.30, ty: -0.02),
        MotionKey(0.50, ty: -0.20),
        MotionKey(0.70, ty: -0.12),
        MotionKey(0.88, ty: 0.04),
        MotionKey(1),
      ]),
      MotionTrack('spine', keys: [
        MotionKey(0),
        MotionKey(0.12, rotation: -12),
        MotionKey(0.30, rotation: 5),
        MotionKey(0.50, rotation: -5),
        MotionKey(0.88, rotation: -10),
        MotionKey(1),
      ]),
      MotionTrack('thigh_l', keys: _thighKeys),
      MotionTrack('thigh_r', keys: _thighKeys),
      MotionTrack('shin_l', keys: _shinKeys),
      MotionTrack('shin_r', keys: _shinKeys),
      MotionTrack('arm_l', keys: _armKeys),
      MotionTrack('arm_r', keys: _armKeys),
    ],
  );

  static const _thighKeys = [
    MotionKey(0),
    MotionKey(0.12, rotation: -30),
    MotionKey(0.30, rotation: 5),
    MotionKey(0.50, rotation: -35),
    MotionKey(0.70, rotation: -15),
    MotionKey(0.88, rotation: -30),
    MotionKey(1),
  ];

  static const _shinKeys = [
    MotionKey(0),
    MotionKey(0.12, rotation: 45),
    MotionKey(0.30, rotation: -5),
    MotionKey(0.50, rotation: 55),
    MotionKey(0.70, rotation: 20),
    MotionKey(0.88, rotation: 45),
    MotionKey(1),
  ];

  static const _armKeys = [
    MotionKey(0),
    MotionKey(0.12, rotation: 25),
    MotionKey(0.30, rotation: -120),
    MotionKey(0.50, rotation: -150),
    MotionKey(0.70, rotation: -60),
    MotionKey(0.88, rotation: 20),
    MotionKey(1),
  ];

  static const wave = MotionPreset(
    id: 'wave',
    name: 'Wave hello',
    description: 'Raises the right arm and waves the hand. Mirror it to wave with the left.',
    category: _humanoid,
    frames: 12,
    fps: 12,
    tracks: [
      MotionTrack('arm_r', rotation: Wave(bias: -150)),
      MotionTrack('forearm_r', rotation: Wave(amplitude: 28, cycles: 2, bias: -10)),
      MotionTrack('hand_r', rotation: Wave(amplitude: 20, cycles: 2, phase: 0.15)),
      MotionTrack('head', rotation: Wave(amplitude: 2)),
      MotionTrack('spine', rotation: Wave(amplitude: 1)),
    ],
  );

  static const attack = MotionPreset(
    id: 'attack',
    name: 'Attack swing',
    description: 'Winds the right arm overhead, then brings it down with a lunge. Plays once, facing right.',
    category: _humanoid,
    frames: 10,
    fps: 14,
    loop: false,
    tracks: [
      MotionTrack('arm_r', keys: [
        MotionKey(0),
        MotionKey(0.25, rotation: -160),
        MotionKey(0.45, rotation: -30),
        MotionKey(0.60, rotation: -10),
        MotionKey(1),
      ]),
      MotionTrack('forearm_r', keys: [
        MotionKey(0),
        MotionKey(0.25, rotation: -30),
        MotionKey(0.45, rotation: -5),
        MotionKey(1),
      ]),
      MotionTrack('spine', keys: [
        MotionKey(0),
        MotionKey(0.25, rotation: 8),
        MotionKey(0.45, rotation: -14),
        MotionKey(1),
      ]),
      MotionTrack('hips', keys: [
        MotionKey(0),
        MotionKey(0.25, tx: -0.01),
        MotionKey(0.45, tx: 0.05),
        MotionKey(1),
      ]),
      MotionTrack('thigh_l', keys: [MotionKey(0), MotionKey(0.45, rotation: -25), MotionKey(1)]),
      MotionTrack('thigh_r', keys: [MotionKey(0), MotionKey(0.45, rotation: 15), MotionKey(1)]),
      MotionTrack('head', keys: [MotionKey(0), MotionKey(0.45, rotation: -6), MotionKey(1)]),
    ],
  );

  static const quadrupedWalk = MotionPreset(
    id: 'quadruped_walk',
    name: 'Walk',
    description:
        'A four-legged walk with the legs moving in diagonal pairs, nodding head and swaying tail. Faces left.',
    category: _animal,
    frames: 8,
    fps: 10,
    tracks: [
      MotionTrack('hips', ty: Wave(amplitude: -0.012, shape: WaveShape.bounce)),
      MotionTrack('spine', rotation: Wave(amplitude: 2, phase: 0.25)),
      MotionTrack('neck', rotation: Wave(amplitude: 2, cycles: 2)),
      MotionTrack('head', rotation: Wave(amplitude: 3, cycles: 2, phase: 0.1)),
      MotionTrack('fl_upper', rotation: Wave(amplitude: 25)),
      MotionTrack('fl_lower', rotation: Wave(amplitude: -35, phase: 0.25, shape: WaveShape.lift)),
      MotionTrack('br_upper', rotation: Wave(amplitude: 22)),
      MotionTrack('br_lower', rotation: Wave(amplitude: -30, phase: 0.25, shape: WaveShape.lift)),
      MotionTrack('fr_upper', rotation: Wave(amplitude: 25, phase: 0.5)),
      MotionTrack('fr_lower', rotation: Wave(amplitude: -35, phase: 0.75, shape: WaveShape.lift)),
      MotionTrack('bl_upper', rotation: Wave(amplitude: 22, phase: 0.5)),
      MotionTrack('bl_lower', rotation: Wave(amplitude: -30, phase: 0.75, shape: WaveShape.lift)),
      MotionTrack('tail_1', rotation: Wave(amplitude: 8, phase: 0.2)),
      MotionTrack('tail_2', rotation: Wave(amplitude: 12, phase: 0.3)),
      MotionTrack('tail_3', rotation: Wave(amplitude: 16, phase: 0.4)),
    ],
  );

  static const birdFlap = MotionPreset(
    id: 'bird_flap',
    name: 'Flap',
    description: 'Wings beat with the tip following the shoulder, the body bobs, the legs tuck. Faces left.',
    category: _animal,
    frames: 8,
    fps: 12,
    tracks: [
      MotionTrack('wing_1', rotation: Wave(amplitude: 40)),
      MotionTrack('wing_2', rotation: Wave(amplitude: 30, phase: -0.15)),
      MotionTrack('hips', ty: Wave(amplitude: -0.03, phase: 0.25)),
      MotionTrack('tail', rotation: Wave(amplitude: 6, phase: 0.3)),
      MotionTrack('head', rotation: Wave(amplitude: 3, phase: 0.4)),
      MotionTrack('leg_upper', rotation: Wave(bias: -35)),
      MotionTrack('leg_lower', rotation: Wave(bias: -40)),
    ],
  );

  static const fishSwim = MotionPreset(
    id: 'fish_swim',
    name: 'Swim',
    description: 'A wave runs down the body from head to tail, growing as it goes.',
    category: _animal,
    frames: 8,
    fps: 10,
    tracks: [
      MotionTrack('fish_1', rotation: Wave(amplitude: 3)),
      MotionTrack('fish_2', rotation: Wave(amplitude: 5, phase: -0.12)),
      MotionTrack('fish_3', rotation: Wave(amplitude: 8, phase: -0.24)),
      MotionTrack('fish_4', rotation: Wave(amplitude: 11, phase: -0.36)),
      MotionTrack('fish_5', rotation: Wave(amplitude: 14, phase: -0.48)),
    ],
  );

  static const sway = MotionPreset(
    id: 'sway',
    name: 'Sway',
    description: 'The selected bone swings gently from side to side.',
    category: _any,
    frames: 8,
    fps: 8,
    target: MotionTarget.selectedBone,
    tracks: [MotionTrack('*', rotation: Wave(amplitude: 12))],
  );

  static const followThrough = MotionPreset(
    id: 'follow_through',
    name: 'Wave along',
    description:
        'A wave runs down the selected bone and everything under it, growing as it goes: tails, hair, ropes, tentacles.',
    category: _any,
    frames: 12,
    fps: 12,
    target: MotionTarget.selectedChain,
    lag: 0.1,
    growth: 0.35,
    tracks: [MotionTrack('*', rotation: Wave(amplitude: 10))],
  );

  static const bob = MotionPreset(
    id: 'bob',
    name: 'Bob',
    description: 'The selected bone and what hangs from it move up and down.',
    category: _any,
    frames: 8,
    fps: 8,
    target: MotionTarget.selectedBone,
    tracks: [MotionTrack('*', ty: Wave(amplitude: -0.03))],
  );

  static const shake = MotionPreset(
    id: 'shake',
    name: 'Shake',
    description: 'The selected bone trembles quickly: fear, cold, an engine.',
    category: _any,
    frames: 6,
    fps: 16,
    target: MotionTarget.selectedBone,
    tracks: [MotionTrack('*', rotation: Wave(amplitude: 6, cycles: 3))],
  );

  /// Everything on offer, characters first.
  static const all = <MotionPreset>[
    idle,
    frontIdle,
    walk,
    frontWalk,
    run,
    frontRun,
    jump,
    frontJump,
    wave,
    attack,
    frontAttack,
    frontHurt,
    frontCrouch,
    frontLand,
    frontInteract,
    frontCelebrate,
    dash,
    fall,
    quadrupedWalk,
    birdFlap,
    fishSwim,
    sway,
    followThrough,
    bob,
    shake,
  ];

  static MotionPreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
