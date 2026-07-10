import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../data.dart';

part 'animation_frame_controller.g.dart';

// Animation settings
class AnimationSettings extends Equatable {
  final bool loop;
  final int fps;
  final bool pingPong; // Play forward then backward
  final bool autoPlay;

  const AnimationSettings({
    this.loop = true,
    this.fps = 12,
    this.pingPong = false,
    this.autoPlay = false,
  });

  AnimationSettings copyWith({
    bool? loop,
    int? fps,
    bool? pingPong,
    bool? autoPlay,
  }) {
    return AnimationSettings(
      loop: loop ?? this.loop,
      fps: fps ?? this.fps,
      pingPong: pingPong ?? this.pingPong,
      autoPlay: autoPlay ?? this.autoPlay,
    );
  }

  @override
  List<Object?> get props => [loop, fps, pingPong, autoPlay];
}

// Animation state for the controller
class AnimationState extends Equatable {
  final List<AnimationFrame> frames;
  final int currentFrameIndex;
  final bool isPlaying;
  final AnimationSettings settings;
  final bool isDirty;

  const AnimationState({
    required this.frames,
    this.currentFrameIndex = 0,
    this.isPlaying = false,
    required this.settings,
    this.isDirty = false,
  });

  AnimationState copyWith({
    List<AnimationFrame>? frames,
    int? currentFrameIndex,
    bool? isPlaying,
    AnimationSettings? settings,
    bool? isDirty,
  }) {
    return AnimationState(
      frames: frames ?? this.frames,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      settings: settings ?? this.settings,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props =>
      [frames, currentFrameIndex, isPlaying, settings, isDirty];
}

// Animation controller notifier
@riverpod
class AnimationController extends _$AnimationController {
  Timer? _timer;
  bool _isForward = true;

  @override
  AnimationState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    return const AnimationState(
      frames: [],
      settings: AnimationSettings(),
    );
  }

  // Frame management
  void addFrame(AnimationFrame frame) {
    state = state.copyWith(
      frames: [...state.frames, frame],
      isDirty: true,
    );
  }

  void removeFrame(int index) {
    final frames = List<AnimationFrame>.from(state.frames);
    frames.removeAt(index);
    state = state.copyWith(
      frames: frames,
      isDirty: true,
    );
  }

  void updateFrame(int index, AnimationFrame frame) {
    final frames = List<AnimationFrame>.from(state.frames);
    frames[index] = frame;
    state = state.copyWith(
      frames: frames,
      isDirty: true,
    );
  }

  void reorderFrames(int oldIndex, int newIndex) {
    final frames = List<AnimationFrame>.from(state.frames);
    final frame = frames.removeAt(oldIndex);
    frames.insert(newIndex, frame);
    state = state.copyWith(
      frames: frames,
      isDirty: true,
    );
  }

  // Playback controls
  void play() {
    if (state.frames.isEmpty) return;

    state = state.copyWith(isPlaying: true);
    _startAnimation();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isPlaying: false);
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(
      isPlaying: false,
      currentFrameIndex: 0,
    );
  }

  void nextFrame() {
    if (state.frames.isEmpty) return;

    final nextIndex = _getNextFrameIndex();
    if (nextIndex != null) {
      state = state.copyWith(currentFrameIndex: nextIndex);
    }
  }

  void previousFrame() {
    if (state.frames.isEmpty) return;

    final prevIndex = _getPreviousFrameIndex();
    if (prevIndex != null) {
      state = state.copyWith(currentFrameIndex: prevIndex);
    }
  }

  // Settings
  void updateSettings(AnimationSettings settings) {
    state = state.copyWith(settings: settings);
    if (state.isPlaying) {
      _restartAnimation();
    }
  }

  // Private methods
  void _startAnimation() {
    _timer?.cancel();
    _scheduleNextFrame();
  }

  // One-shot timer per frame (rather than Timer.periodic) so each frame is
  // held for its own `duration`, matching AnimationPreview. settings.fps is
  // only the fallback for frames without a usable duration.
  void _scheduleNextFrame() {
    if (state.frames.isEmpty) return;

    final index = state.currentFrameIndex.clamp(0, state.frames.length - 1);
    final duration = state.frames[index].duration;
    final delay = duration > 0 ? duration : 1000 ~/ state.settings.fps;

    _timer = Timer(Duration(milliseconds: delay), () {
      final nextIndex = _getNextFrameIndex();
      if (nextIndex != null) {
        state = state.copyWith(currentFrameIndex: nextIndex);
        _scheduleNextFrame();
      } else {
        state = state.copyWith(isPlaying: false);
      }
    });
  }

  void _restartAnimation() {
    _timer?.cancel();
    if (state.isPlaying) {
      _startAnimation();
    }
  }

  int? _getNextFrameIndex() {
    if (state.frames.isEmpty) return null;

    final currentIndex = state.currentFrameIndex;
    final lastIndex = state.frames.length - 1;

    if (state.settings.pingPong) {
      if (_isForward) {
        if (currentIndex < lastIndex) {
          return currentIndex + 1;
        } else {
          _isForward = false;
          return currentIndex - 1;
        }
      } else {
        if (currentIndex > 0) {
          return currentIndex - 1;
        } else {
          _isForward = true;
          if (state.settings.loop) {
            return currentIndex + 1;
          }
          return null;
        }
      }
    } else {
      if (currentIndex < lastIndex) {
        return currentIndex + 1;
      } else if (state.settings.loop) {
        return 0;
      }
      return null;
    }
  }

  int? _getPreviousFrameIndex() {
    if (state.frames.isEmpty) return null;

    final currentIndex = state.currentFrameIndex;
    final lastIndex = state.frames.length - 1;

    if (currentIndex > 0) {
      return currentIndex - 1;
    } else if (state.settings.loop) {
      return lastIndex;
    }
    return null;
  }
}
