// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pixel_canvas_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PixelCanvasState {
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  List<AnimationStateModel> get animationStates =>
      throw _privateConstructorUsedError;
  List<AnimationFrame> get frames => throw _privateConstructorUsedError;
  int get currentAnimationStateIndex => throw _privateConstructorUsedError;
  int get currentFrameIndex => throw _privateConstructorUsedError;
  int get currentLayerIndex => throw _privateConstructorUsedError;
  Color get currentColor => throw _privateConstructorUsedError;
  PixelTool get currentTool => throw _privateConstructorUsedError;
  MirrorAxis get mirrorAxis => throw _privateConstructorUsedError;
  SelectionState? get selectionState => throw _privateConstructorUsedError;
  bool get canUndo => throw _privateConstructorUsedError;
  bool get canRedo => throw _privateConstructorUsedError;
  PixelModifier get currentModifier => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PixelCanvasStateCopyWith<PixelCanvasState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PixelCanvasStateCopyWith<$Res> {
  factory $PixelCanvasStateCopyWith(
          PixelCanvasState value, $Res Function(PixelCanvasState) then) =
      _$PixelCanvasStateCopyWithImpl<$Res, PixelCanvasState>;
  @useResult
  $Res call(
      {int width,
      int height,
      List<AnimationStateModel> animationStates,
      List<AnimationFrame> frames,
      int currentAnimationStateIndex,
      int currentFrameIndex,
      int currentLayerIndex,
      Color currentColor,
      PixelTool currentTool,
      MirrorAxis mirrorAxis,
      SelectionState? selectionState,
      bool canUndo,
      bool canRedo,
      PixelModifier currentModifier});
}

/// @nodoc
class _$PixelCanvasStateCopyWithImpl<$Res, $Val extends PixelCanvasState>
    implements $PixelCanvasStateCopyWith<$Res> {
  _$PixelCanvasStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
    Object? animationStates = null,
    Object? frames = null,
    Object? currentAnimationStateIndex = null,
    Object? currentFrameIndex = null,
    Object? currentLayerIndex = null,
    Object? currentColor = freezed,
    Object? currentTool = null,
    Object? mirrorAxis = null,
    Object? selectionState = freezed,
    Object? canUndo = null,
    Object? canRedo = null,
    Object? currentModifier = null,
  }) {
    return _then(_value.copyWith(
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      animationStates: null == animationStates
          ? _value.animationStates
          : animationStates // ignore: cast_nullable_to_non_nullable
              as List<AnimationStateModel>,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<AnimationFrame>,
      currentAnimationStateIndex: null == currentAnimationStateIndex
          ? _value.currentAnimationStateIndex
          : currentAnimationStateIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentFrameIndex: null == currentFrameIndex
          ? _value.currentFrameIndex
          : currentFrameIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentLayerIndex: null == currentLayerIndex
          ? _value.currentLayerIndex
          : currentLayerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentColor: freezed == currentColor
          ? _value.currentColor
          : currentColor // ignore: cast_nullable_to_non_nullable
              as Color,
      currentTool: null == currentTool
          ? _value.currentTool
          : currentTool // ignore: cast_nullable_to_non_nullable
              as PixelTool,
      mirrorAxis: null == mirrorAxis
          ? _value.mirrorAxis
          : mirrorAxis // ignore: cast_nullable_to_non_nullable
              as MirrorAxis,
      selectionState: freezed == selectionState
          ? _value.selectionState
          : selectionState // ignore: cast_nullable_to_non_nullable
              as SelectionState?,
      canUndo: null == canUndo
          ? _value.canUndo
          : canUndo // ignore: cast_nullable_to_non_nullable
              as bool,
      canRedo: null == canRedo
          ? _value.canRedo
          : canRedo // ignore: cast_nullable_to_non_nullable
              as bool,
      currentModifier: null == currentModifier
          ? _value.currentModifier
          : currentModifier // ignore: cast_nullable_to_non_nullable
              as PixelModifier,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PixelCanvasStateImplCopyWith<$Res>
    implements $PixelCanvasStateCopyWith<$Res> {
  factory _$$PixelCanvasStateImplCopyWith(_$PixelCanvasStateImpl value,
          $Res Function(_$PixelCanvasStateImpl) then) =
      __$$PixelCanvasStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int width,
      int height,
      List<AnimationStateModel> animationStates,
      List<AnimationFrame> frames,
      int currentAnimationStateIndex,
      int currentFrameIndex,
      int currentLayerIndex,
      Color currentColor,
      PixelTool currentTool,
      MirrorAxis mirrorAxis,
      SelectionState? selectionState,
      bool canUndo,
      bool canRedo,
      PixelModifier currentModifier});
}

/// @nodoc
class __$$PixelCanvasStateImplCopyWithImpl<$Res>
    extends _$PixelCanvasStateCopyWithImpl<$Res, _$PixelCanvasStateImpl>
    implements _$$PixelCanvasStateImplCopyWith<$Res> {
  __$$PixelCanvasStateImplCopyWithImpl(_$PixelCanvasStateImpl _value,
      $Res Function(_$PixelCanvasStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
    Object? animationStates = null,
    Object? frames = null,
    Object? currentAnimationStateIndex = null,
    Object? currentFrameIndex = null,
    Object? currentLayerIndex = null,
    Object? currentColor = freezed,
    Object? currentTool = null,
    Object? mirrorAxis = null,
    Object? selectionState = freezed,
    Object? canUndo = null,
    Object? canRedo = null,
    Object? currentModifier = null,
  }) {
    return _then(_$PixelCanvasStateImpl(
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      animationStates: null == animationStates
          ? _value._animationStates
          : animationStates // ignore: cast_nullable_to_non_nullable
              as List<AnimationStateModel>,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<AnimationFrame>,
      currentAnimationStateIndex: null == currentAnimationStateIndex
          ? _value.currentAnimationStateIndex
          : currentAnimationStateIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentFrameIndex: null == currentFrameIndex
          ? _value.currentFrameIndex
          : currentFrameIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentLayerIndex: null == currentLayerIndex
          ? _value.currentLayerIndex
          : currentLayerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentColor: freezed == currentColor
          ? _value.currentColor
          : currentColor // ignore: cast_nullable_to_non_nullable
              as Color,
      currentTool: null == currentTool
          ? _value.currentTool
          : currentTool // ignore: cast_nullable_to_non_nullable
              as PixelTool,
      mirrorAxis: null == mirrorAxis
          ? _value.mirrorAxis
          : mirrorAxis // ignore: cast_nullable_to_non_nullable
              as MirrorAxis,
      selectionState: freezed == selectionState
          ? _value.selectionState
          : selectionState // ignore: cast_nullable_to_non_nullable
              as SelectionState?,
      canUndo: null == canUndo
          ? _value.canUndo
          : canUndo // ignore: cast_nullable_to_non_nullable
              as bool,
      canRedo: null == canRedo
          ? _value.canRedo
          : canRedo // ignore: cast_nullable_to_non_nullable
              as bool,
      currentModifier: null == currentModifier
          ? _value.currentModifier
          : currentModifier // ignore: cast_nullable_to_non_nullable
              as PixelModifier,
    ));
  }
}

/// @nodoc

class _$PixelCanvasStateImpl extends _PixelCanvasState {
  const _$PixelCanvasStateImpl(
      {required this.width,
      required this.height,
      required final List<AnimationStateModel> animationStates,
      required final List<AnimationFrame> frames,
      this.currentAnimationStateIndex = 0,
      this.currentFrameIndex = 0,
      this.currentLayerIndex = 0,
      required this.currentColor,
      required this.currentTool,
      required this.mirrorAxis,
      this.selectionState,
      this.canUndo = false,
      this.canRedo = false,
      this.currentModifier = PixelModifier.none})
      : _animationStates = animationStates,
        _frames = frames,
        super._();

  @override
  final int width;
  @override
  final int height;
  final List<AnimationStateModel> _animationStates;
  @override
  List<AnimationStateModel> get animationStates {
    if (_animationStates is EqualUnmodifiableListView) return _animationStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animationStates);
  }

  final List<AnimationFrame> _frames;
  @override
  List<AnimationFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  @JsonKey()
  final int currentAnimationStateIndex;
  @override
  @JsonKey()
  final int currentFrameIndex;
  @override
  @JsonKey()
  final int currentLayerIndex;
  @override
  final Color currentColor;
  @override
  final PixelTool currentTool;
  @override
  final MirrorAxis mirrorAxis;
  @override
  final SelectionState? selectionState;
  @override
  @JsonKey()
  final bool canUndo;
  @override
  @JsonKey()
  final bool canRedo;
  @override
  @JsonKey()
  final PixelModifier currentModifier;

  @override
  String toString() {
    return 'PixelCanvasState(width: $width, height: $height, animationStates: $animationStates, frames: $frames, currentAnimationStateIndex: $currentAnimationStateIndex, currentFrameIndex: $currentFrameIndex, currentLayerIndex: $currentLayerIndex, currentColor: $currentColor, currentTool: $currentTool, mirrorAxis: $mirrorAxis, selectionState: $selectionState, canUndo: $canUndo, canRedo: $canRedo, currentModifier: $currentModifier)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PixelCanvasStateImpl &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            const DeepCollectionEquality()
                .equals(other._animationStates, _animationStates) &&
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.currentAnimationStateIndex,
                    currentAnimationStateIndex) ||
                other.currentAnimationStateIndex ==
                    currentAnimationStateIndex) &&
            (identical(other.currentFrameIndex, currentFrameIndex) ||
                other.currentFrameIndex == currentFrameIndex) &&
            (identical(other.currentLayerIndex, currentLayerIndex) ||
                other.currentLayerIndex == currentLayerIndex) &&
            const DeepCollectionEquality()
                .equals(other.currentColor, currentColor) &&
            (identical(other.currentTool, currentTool) ||
                other.currentTool == currentTool) &&
            (identical(other.mirrorAxis, mirrorAxis) ||
                other.mirrorAxis == mirrorAxis) &&
            (identical(other.selectionState, selectionState) ||
                other.selectionState == selectionState) &&
            (identical(other.canUndo, canUndo) || other.canUndo == canUndo) &&
            (identical(other.canRedo, canRedo) || other.canRedo == canRedo) &&
            (identical(other.currentModifier, currentModifier) ||
                other.currentModifier == currentModifier));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      width,
      height,
      const DeepCollectionEquality().hash(_animationStates),
      const DeepCollectionEquality().hash(_frames),
      currentAnimationStateIndex,
      currentFrameIndex,
      currentLayerIndex,
      const DeepCollectionEquality().hash(currentColor),
      currentTool,
      mirrorAxis,
      selectionState,
      canUndo,
      canRedo,
      currentModifier);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PixelCanvasStateImplCopyWith<_$PixelCanvasStateImpl> get copyWith =>
      __$$PixelCanvasStateImplCopyWithImpl<_$PixelCanvasStateImpl>(
          this, _$identity);
}

abstract class _PixelCanvasState extends PixelCanvasState {
  const factory _PixelCanvasState(
      {required final int width,
      required final int height,
      required final List<AnimationStateModel> animationStates,
      required final List<AnimationFrame> frames,
      final int currentAnimationStateIndex,
      final int currentFrameIndex,
      final int currentLayerIndex,
      required final Color currentColor,
      required final PixelTool currentTool,
      required final MirrorAxis mirrorAxis,
      final SelectionState? selectionState,
      final bool canUndo,
      final bool canRedo,
      final PixelModifier currentModifier}) = _$PixelCanvasStateImpl;
  const _PixelCanvasState._() : super._();

  @override
  int get width;
  @override
  int get height;
  @override
  List<AnimationStateModel> get animationStates;
  @override
  List<AnimationFrame> get frames;
  @override
  int get currentAnimationStateIndex;
  @override
  int get currentFrameIndex;
  @override
  int get currentLayerIndex;
  @override
  Color get currentColor;
  @override
  PixelTool get currentTool;
  @override
  MirrorAxis get mirrorAxis;
  @override
  SelectionState? get selectionState;
  @override
  bool get canUndo;
  @override
  bool get canRedo;
  @override
  PixelModifier get currentModifier;
  @override
  @JsonKey(ignore: true)
  _$$PixelCanvasStateImplCopyWith<_$PixelCanvasStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BackgroundImageState {
  Uint8List? get image => throw _privateConstructorUsedError;
  double get opacity => throw _privateConstructorUsedError;
  double get scale => throw _privateConstructorUsedError;
  Offset get offset => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BackgroundImageStateCopyWith<BackgroundImageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackgroundImageStateCopyWith<$Res> {
  factory $BackgroundImageStateCopyWith(BackgroundImageState value,
          $Res Function(BackgroundImageState) then) =
      _$BackgroundImageStateCopyWithImpl<$Res, BackgroundImageState>;
  @useResult
  $Res call({Uint8List? image, double opacity, double scale, Offset offset});
}

/// @nodoc
class _$BackgroundImageStateCopyWithImpl<$Res,
        $Val extends BackgroundImageState>
    implements $BackgroundImageStateCopyWith<$Res> {
  _$BackgroundImageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image = freezed,
    Object? opacity = null,
    Object? scale = null,
    Object? offset = freezed,
  }) {
    return _then(_value.copyWith(
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      offset: freezed == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as Offset,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackgroundImageStateImplCopyWith<$Res>
    implements $BackgroundImageStateCopyWith<$Res> {
  factory _$$BackgroundImageStateImplCopyWith(_$BackgroundImageStateImpl value,
          $Res Function(_$BackgroundImageStateImpl) then) =
      __$$BackgroundImageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Uint8List? image, double opacity, double scale, Offset offset});
}

/// @nodoc
class __$$BackgroundImageStateImplCopyWithImpl<$Res>
    extends _$BackgroundImageStateCopyWithImpl<$Res, _$BackgroundImageStateImpl>
    implements _$$BackgroundImageStateImplCopyWith<$Res> {
  __$$BackgroundImageStateImplCopyWithImpl(_$BackgroundImageStateImpl _value,
      $Res Function(_$BackgroundImageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image = freezed,
    Object? opacity = null,
    Object? scale = null,
    Object? offset = freezed,
  }) {
    return _then(_$BackgroundImageStateImpl(
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      offset: freezed == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as Offset,
    ));
  }
}

/// @nodoc

class _$BackgroundImageStateImpl extends _BackgroundImageState {
  const _$BackgroundImageStateImpl(
      {this.image,
      this.opacity = 0.3,
      this.scale = 1.0,
      this.offset = Offset.zero})
      : super._();

  @override
  final Uint8List? image;
  @override
  @JsonKey()
  final double opacity;
  @override
  @JsonKey()
  final double scale;
  @override
  @JsonKey()
  final Offset offset;

  @override
  String toString() {
    return 'BackgroundImageState(image: $image, opacity: $opacity, scale: $scale, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackgroundImageStateImpl &&
            const DeepCollectionEquality().equals(other.image, image) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            (identical(other.scale, scale) || other.scale == scale) &&
            const DeepCollectionEquality().equals(other.offset, offset));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(image),
      opacity,
      scale,
      const DeepCollectionEquality().hash(offset));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackgroundImageStateImplCopyWith<_$BackgroundImageStateImpl>
      get copyWith =>
          __$$BackgroundImageStateImplCopyWithImpl<_$BackgroundImageStateImpl>(
              this, _$identity);
}

abstract class _BackgroundImageState extends BackgroundImageState {
  const factory _BackgroundImageState(
      {final Uint8List? image,
      final double opacity,
      final double scale,
      final Offset offset}) = _$BackgroundImageStateImpl;
  const _BackgroundImageState._() : super._();

  @override
  Uint8List? get image;
  @override
  double get opacity;
  @override
  double get scale;
  @override
  Offset get offset;
  @override
  @JsonKey(ignore: true)
  _$$BackgroundImageStateImplCopyWith<_$BackgroundImageStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
