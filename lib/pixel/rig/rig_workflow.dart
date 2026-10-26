part of 'rig_editor_controller.dart';

extension RigWorkflow on RigEditorController {
  Set<String> get selectedBoneIds => Set.unmodifiable({
        ..._selectedBoneIds.where((id) => bone(id) != null),
        if (_selectedBoneId != null && bone(_selectedBoneId) != null) _selectedBoneId!,
      });
  void toggleMultiSelect() {
    multiSelectEnabled = !multiSelectEnabled;
    _notifyWorkflow();
  }

  void toggleBoneSelection(String id) {
    if (bone(id) == null) return;
    if (_selectedBoneIds.isEmpty && _selectedBoneId != null) _selectedBoneIds.add(_selectedBoneId!);
    if (!_selectedBoneIds.add(id)) _selectedBoneIds.remove(id);
    _selectedBoneId = _selectedBoneIds.contains(id) ? id : _selectedBoneIds.firstOrNull;
    _selectedIkChainId = null;
    _notifyWorkflow();
  }

  void selectDescendants() {
    for (final id in selectedBoneIds) {
      _selectedBoneIds
        ..add(id)
        ..addAll(_descendants(id));
    }
    _notifyWorkflow();
  }

  void selectBox(Rect box, {bool additive = false}) {
    if (!additive) _selectedBoneIds.clear();
    for (final b in displayBones) {
      bool crosses() {
        final delta = b.tail - b.head;
        if (delta.dx != 0) {
          for (final x in [box.left, box.right]) {
            final t = (x - b.head.dx) / delta.dx;
            final y = b.head.dy + t * delta.dy;
            if (t >= 0 && t <= 1 && y >= box.top && y <= box.bottom) return true;
          }
        }
        if (delta.dy != 0) {
          for (final y in [box.top, box.bottom]) {
            final t = (y - b.head.dy) / delta.dy;
            final x = b.head.dx + t * delta.dx;
            if (t >= 0 && t <= 1 && x >= box.left && x <= box.right) return true;
          }
        }
        return false;
      }

      if (box.contains(b.head) || box.contains(b.tail) || crosses()) {
        _selectedBoneIds.add(b.bone.id);
      }
    }
    _selectedBoneId = _selectedBoneIds.firstOrNull;
    _notifyWorkflow();
  }

  void setConnectedGeometry(bool enabled) {
    moveConnectedChain = enabled;
    _notifyWorkflow();
  }

  void setSnapping(bool enabled) {
    snappingEnabled = enabled;
    _notifyWorkflow();
  }

  void updateGhosts(
      {bool? skeleton, bool? artwork, double? opacity, int? spacing, bool pin = false, bool unpin = false}) {
    ghostSkeleton = skeleton ?? ghostSkeleton;
    ghostArtwork = artwork ?? ghostArtwork;
    ghostOpacity = (opacity ?? ghostOpacity).clamp(.05, .8);
    ghostSpacing = (spacing ?? ghostSpacing).clamp(1, 12);
    if (pin) pinnedGhostFrame = time;
    if (unpin) pinnedGhostFrame = null;
    _notifyWorkflow();
  }

  void setGhostPlayback(bool playing) {
    if (ghostsSuppressed == playing) return;
    ghostsSuppressed = playing;
    _notifyWorkflow();
  }

  List<int> get ghostFrames {
    if (ghostsSuppressed || _mode != RigMode.animate || (!ghostSkeleton && !ghostArtwork)) return const [];
    int? at(int t) => activeClip.loop ? t % activeClip.length : (t >= 0 && t < activeClip.length ? t : null);
    return {at(time - ghostSpacing), at(time + ghostSpacing), pinnedGhostFrame}
        .whereType<int>()
        .where((t) => t != time && t >= 0 && t < activeClip.length)
        .toList();
  }

  List<DisplayBone> bonesAt(int frame) {
    final world = RigSolver.solveClip(_rig, activeClip, frame.toDouble()).world;
    return [
      for (final b in _rig.bones)
        (
          bone: b,
          head: (world[b.id] ?? Affine2.identity).apply(b.head),
          tail: (world[b.id] ?? Affine2.identity).apply(b.tail)
        )
    ];
  }

  /// Topmost selected bones carry descendants once; frozen joints remain fixed.
  Set<String> get selectionRoots {
    final ids = selectedBoneIds;
    return {
      for (final id in ids)
        if (!ids.any(
            (p) => p != id && !(_mode == RigMode.animate && jointFrozenAt(p, time)) && _descendants(p).contains(id)))
          id
    };
  }

  void setGroupPivot(bool active) {
    groupActivePivot = active;
    _notifyWorkflow();
  }

  void transformSelection({Offset translation = Offset.zero, double rotation = 0, bool? activePivot}) {
    if (!translation.dx.isFinite || !translation.dy.isFinite || !rotation.isFinite) return;
    final roots = selectionRoots;
    if (roots.isEmpty) return;
    final shown = {for (final b in displayBones) b.bone.id: b};
    final heads = [for (final id in selectedBoneIds) shown[id]!.head];
    final pivot = (activePivot ?? groupActivePivot) && _selectedBoneId != null
        ? shown[_selectedBoneId]!.head
        : heads.reduce((a, b) => a + b) / heads.length.toDouble();
    final turn = Affine2.rotationAbout(rotation, pivot).thenTranslate(translation.dx, translation.dy);
    if (_mode == RigMode.setup) {
      final owners = <String, String>{
        for (final id in roots)
          for (final child in {id, ..._descendants(id)}) child: id
      };
      final corrections = {
        for (final id in roots) id: snapToPixel(turn.apply(bone(id)!.head)) - turn.apply(bone(id)!.head)
      };
      _commit(_rig.copyWith(bones: [
        for (final b in _rig.bones)
          owners.containsKey(b.id)
              ? b.copyWith(head: turn.apply(b.head) + corrections[owners[b.id]]!, restAngle: b.restAngle + rotation)
              : b
      ]));
      return;
    }
    final ownGesture = _gestureBase == null;
    if (ownGesture) beginGesture();
    try {
      for (final id in roots) {
        if (!jointFrozenAt(id, time)) {
          final pose = poseOf(id);
          final delta = turn.apply(shown[id]!.head) - shown[id]!.head;
          setPose(id,
              rotation: pose.rotation + rotationSign(id) * rotation,
              translation: pose.translation + toLocalDelta(id, delta));
        }
      }
    } finally {
      if (ownGesture) endGesture();
    }
  }

  void freezeSelection(bool freeze) {
    beginGesture();
    try {
      for (final id in selectedBoneIds) {
        freeze ? freezeJoint(id) : unfreezeJoint(id);
      }
    } finally {
      endGesture();
    }
  }

  void setBoneEndpoint(String id, Offset tail) {
    if (_mode != RigMode.setup || !tail.dx.isFinite || !tail.dy.isFinite) return;
    if (moveConnectedChain) {
      setBoneTail(id, tail);
    } else {
      final b = bone(id);
      if (b == null) return;
      final delta = snapToPixel(tail) - b.head;
      if (delta.distance >= .5) setBoneGeometry(id, length: delta.distance, angle: RigEditorController._degrees(delta));
    }
  }

  String? addAttachment(String boneId, String name) {
    final b = bone(boneId);
    if (b == null || _mode != RigMode.setup || name.trim().isEmpty) return null;
    final a = RigAttachment(id: _newId(), boneId: boneId, name: name.trim(), offset: Offset(b.length, 0));
    _commit(_rig.copyWith(attachments: [..._rig.attachments, a]));
    return a.id;
  }

  void updateAttachment(String id, {String? name, double? x, double? y, double? angle}) {
    if (_mode != RigMode.setup || [x, y, angle].whereType<double>().any((n) => !n.isFinite)) return;
    _commit(_rig.copyWith(attachments: [
      for (final a in _rig.attachments)
        a.id == id
            ? a.copyWith(
                name: name == null || name.trim().isEmpty ? a.name : name.trim(),
                offset: Offset(x ?? a.offset.dx, y ?? a.offset.dy),
                angle: angle)
            : a
    ]));
  }

  void deleteAttachment(String id) {
    if (_mode != RigMode.setup) return;
    _commit(_rig.copyWith(attachments: [
      for (final a in _rig.attachments)
        if (a.id != id) a
    ], ikChains: [
      for (final chain in _rig.ikChains) chain.tipSocketId == id ? chain.copyWith(tipSocketId: () => null) : chain
    ], parts: [
      for (final p in _rig.parts) p.attachmentId == id ? p.copyWith(attachmentId: () => null) : p
    ]));
  }

  Offset attachmentPosition(RigAttachment a) =>
      RigSolver.attachmentTransform(_rig, a, _mode == RigMode.animate ? _world : const {}).apply(Offset.zero);
  void attachLayerToSocket(String layerKey, String socketId, {Offset? artworkPivot}) {
    final a = _rig.attachments.where((a) => a.id == socketId).firstOrNull;
    if (a == null || _mode != RigMode.setup) return;
    final parts = _partsBinding(layerKey, a.boneId);
    if (parts == null) return;
    _commit(_rig.copyWith(parts: [
      for (final p in parts)
        p.layerKey == layerKey
            ? p.copyWith(attachmentId: () => socketId, pivotOverride: () => artworkPivot ?? bone(a.boneId)!.head)
            : p
    ]));
  }

  void setAttachmentArtworkPivot(String layerKey, Offset pivot) {
    if (_mode != RigMode.setup || !pivot.dx.isFinite || !pivot.dy.isFinite) return;
    _commit(_rig.copyWith(
        parts: [for (final p in _rig.parts) p.layerKey == layerKey ? p.copyWith(pivotOverride: () => pivot) : p]));
  }

  bool _trackIncluded(String id) => !timelineSelectedTracksOnly || selectedBoneIds.contains(id);
  bool _chainIncluded(String id) {
    final chain = ikChain(id);
    return chain != null &&
        (!timelineSelectedTracksOnly || _rig.chainBones(chain).any((b) => selectedBoneIds.contains(b.id)));
  }

  void setTimelineScope({bool? selectedOnly, bool? ripple}) {
    timelineSelectedTracksOnly = selectedOnly ?? timelineSelectedTracksOnly;
    rippleTimeline = ripple ?? rippleTimeline;
    _notifyWorkflow();
  }

  void copyTimelineKeys() {
    _keyClipboardStart = rangeStart;
    _keyClipboardLength = rangeEnd - rangeStart + 1;
    bool inside(int t) => t >= rangeStart && t <= rangeEnd;
    _keyClipboard = activeClip.copyWith(keyframes: [
      for (final k in activeClip.keyframes)
        if (inside(k.time) && _trackIncluded(k.boneId)) k
    ], ikKeyframes: [
      for (final k in activeClip.ikKeyframes)
        if (inside(k.time) && _chainIncluded(k.chainId)) k
    ], freezes: [
      for (final f in activeClip.freezes)
        if (inside(f.time) && _trackIncluded(f.boneId)) f
    ]);
    _notifyWorkflow();
  }

  bool get canPasteTimelineKeys => _keyClipboard != null;
  void pasteTimelineKeys() {
    final copied = _keyClipboard;
    if (copied == null || (rippleTimeline && activeClip.length + _keyClipboardLength > 240)) return;
    final at = time;
    final shift = at - _keyClipboardStart;
    final clip = activeClip;
    int later(int t) => rippleTimeline && t >= at ? t + _keyClipboardLength : t;
    final keys = [
      for (final k in copied.keyframes)
        if (k.time + shift < 240) k.copyWith(time: k.time + shift)
    ];
    final ik = [
      for (final k in copied.ikKeyframes)
        if (k.time + shift < 240) k.copyWith(time: k.time + shift)
    ];
    final locks = [
      for (final f in copied.freezes)
        if (f.time + shift < 240) f.copyWith(time: f.time + shift)
    ];
    final lockDest = {for (final f in locks) (f.boneId, f.time)};
    var base = clip.copyWith(
        length:
            math.min(240, math.max(clip.length + (rippleTimeline ? _keyClipboardLength : 0), at + _keyClipboardLength)),
        keyframes: [
          for (final k in clip.keyframes) k.copyWith(time: later(k.time))
        ],
        ikKeyframes: [
          for (final k in clip.ikKeyframes) k.copyWith(time: later(k.time))
        ],
        orderKeyframes: [
          for (final k in clip.orderKeyframes) k.copyWith(time: later(k.time))
        ],
        freezes: [
          for (final f in clip.freezes)
            if (!lockDest.contains((f.boneId, later(f.time)))) f.copyWith(time: later(f.time)),
          ...locks
        ]);
    base = _withIkKeys(_withKeys(base, keys), ik);
    _updateClip((_) => base);
  }

  void editTimelineKeys({int delta = 0, bool delete = false, RigEasing? easing, EasingCurve? curve}) {
    final clip = activeClip;
    final start = rangeStart, end = rangeEnd;
    delta = delta.clamp(-start, 239 - end);
    bool inside(int t) => t >= start && t <= end;
    final movedKeys = [
      for (final k in clip.keyframes)
        if (inside(k.time) && _trackIncluded(k.boneId) && !delete)
          k.copyWith(time: k.time + delta, easing: easing, curve: easing != null || curve != null ? () => curve : null)
    ];
    final movedIk = [
      for (final k in clip.ikKeyframes)
        if (inside(k.time) && _chainIncluded(k.chainId) && !delete)
          k.copyWith(time: k.time + delta, easing: easing, curve: easing != null || curve != null ? () => curve : null)
    ];
    final movedLocks = [
      for (final f in clip.freezes)
        if (inside(f.time) && _trackIncluded(f.boneId) && !delete) f.copyWith(time: f.time + delta)
    ];
    final dest = {for (final f in movedLocks) (f.boneId, f.time)};
    final base = clip.copyWith(length: math.max(clip.length, end + delta + 1), keyframes: [
      for (final k in clip.keyframes)
        if (!inside(k.time) || !_trackIncluded(k.boneId)) k
    ], ikKeyframes: [
      for (final k in clip.ikKeyframes)
        if (!inside(k.time) || !_chainIncluded(k.chainId)) k
    ], freezes: [
      for (final f in clip.freezes)
        if ((!inside(f.time) || !_trackIncluded(f.boneId)) && !dest.contains((f.boneId, f.time))) f,
      ...movedLocks
    ]);
    _updateClip((_) => _withIkKeys(_withKeys(base, movedKeys), movedIk));
    if (delta != 0) {
      selectFrameRange(start + delta, end + delta);
      setTime(start + delta);
    }
  }
}
