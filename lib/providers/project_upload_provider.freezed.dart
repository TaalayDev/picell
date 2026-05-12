// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_upload_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProjectUploadState {
  bool get isUploading => throw _privateConstructorUsedError;
  double get uploadProgress => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  ApiProject? get uploadedProject => throw _privateConstructorUsedError;
  bool get isSuccess => throw _privateConstructorUsedError;
  bool get isUpdating =>
      throw _privateConstructorUsedError; // Background silent sync (no UI modal)
  bool get isSilentSyncing => throw _privateConstructorUsedError;
  int? get lastSyncedRemoteId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ProjectUploadStateCopyWith<ProjectUploadState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectUploadStateCopyWith<$Res> {
  factory $ProjectUploadStateCopyWith(
          ProjectUploadState value, $Res Function(ProjectUploadState) then) =
      _$ProjectUploadStateCopyWithImpl<$Res, ProjectUploadState>;
  @useResult
  $Res call(
      {bool isUploading,
      double uploadProgress,
      String? error,
      ApiProject? uploadedProject,
      bool isSuccess,
      bool isUpdating,
      bool isSilentSyncing,
      int? lastSyncedRemoteId});

  $ApiProjectCopyWith<$Res>? get uploadedProject;
}

/// @nodoc
class _$ProjectUploadStateCopyWithImpl<$Res, $Val extends ProjectUploadState>
    implements $ProjectUploadStateCopyWith<$Res> {
  _$ProjectUploadStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isUploading = null,
    Object? uploadProgress = null,
    Object? error = freezed,
    Object? uploadedProject = freezed,
    Object? isSuccess = null,
    Object? isUpdating = null,
    Object? isSilentSyncing = null,
    Object? lastSyncedRemoteId = freezed,
  }) {
    return _then(_value.copyWith(
      isUploading: null == isUploading
          ? _value.isUploading
          : isUploading // ignore: cast_nullable_to_non_nullable
              as bool,
      uploadProgress: null == uploadProgress
          ? _value.uploadProgress
          : uploadProgress // ignore: cast_nullable_to_non_nullable
              as double,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadedProject: freezed == uploadedProject
          ? _value.uploadedProject
          : uploadedProject // ignore: cast_nullable_to_non_nullable
              as ApiProject?,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdating: null == isUpdating
          ? _value.isUpdating
          : isUpdating // ignore: cast_nullable_to_non_nullable
              as bool,
      isSilentSyncing: null == isSilentSyncing
          ? _value.isSilentSyncing
          : isSilentSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSyncedRemoteId: freezed == lastSyncedRemoteId
          ? _value.lastSyncedRemoteId
          : lastSyncedRemoteId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ApiProjectCopyWith<$Res>? get uploadedProject {
    if (_value.uploadedProject == null) {
      return null;
    }

    return $ApiProjectCopyWith<$Res>(_value.uploadedProject!, (value) {
      return _then(_value.copyWith(uploadedProject: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectUploadStateImplCopyWith<$Res>
    implements $ProjectUploadStateCopyWith<$Res> {
  factory _$$ProjectUploadStateImplCopyWith(_$ProjectUploadStateImpl value,
          $Res Function(_$ProjectUploadStateImpl) then) =
      __$$ProjectUploadStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isUploading,
      double uploadProgress,
      String? error,
      ApiProject? uploadedProject,
      bool isSuccess,
      bool isUpdating,
      bool isSilentSyncing,
      int? lastSyncedRemoteId});

  @override
  $ApiProjectCopyWith<$Res>? get uploadedProject;
}

/// @nodoc
class __$$ProjectUploadStateImplCopyWithImpl<$Res>
    extends _$ProjectUploadStateCopyWithImpl<$Res, _$ProjectUploadStateImpl>
    implements _$$ProjectUploadStateImplCopyWith<$Res> {
  __$$ProjectUploadStateImplCopyWithImpl(_$ProjectUploadStateImpl _value,
      $Res Function(_$ProjectUploadStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isUploading = null,
    Object? uploadProgress = null,
    Object? error = freezed,
    Object? uploadedProject = freezed,
    Object? isSuccess = null,
    Object? isUpdating = null,
    Object? isSilentSyncing = null,
    Object? lastSyncedRemoteId = freezed,
  }) {
    return _then(_$ProjectUploadStateImpl(
      isUploading: null == isUploading
          ? _value.isUploading
          : isUploading // ignore: cast_nullable_to_non_nullable
              as bool,
      uploadProgress: null == uploadProgress
          ? _value.uploadProgress
          : uploadProgress // ignore: cast_nullable_to_non_nullable
              as double,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadedProject: freezed == uploadedProject
          ? _value.uploadedProject
          : uploadedProject // ignore: cast_nullable_to_non_nullable
              as ApiProject?,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdating: null == isUpdating
          ? _value.isUpdating
          : isUpdating // ignore: cast_nullable_to_non_nullable
              as bool,
      isSilentSyncing: null == isSilentSyncing
          ? _value.isSilentSyncing
          : isSilentSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSyncedRemoteId: freezed == lastSyncedRemoteId
          ? _value.lastSyncedRemoteId
          : lastSyncedRemoteId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$ProjectUploadStateImpl implements _ProjectUploadState {
  const _$ProjectUploadStateImpl(
      {this.isUploading = false,
      this.uploadProgress = 0.0,
      this.error,
      this.uploadedProject,
      this.isSuccess = false,
      this.isUpdating = false,
      this.isSilentSyncing = false,
      this.lastSyncedRemoteId});

  @override
  @JsonKey()
  final bool isUploading;
  @override
  @JsonKey()
  final double uploadProgress;
  @override
  final String? error;
  @override
  final ApiProject? uploadedProject;
  @override
  @JsonKey()
  final bool isSuccess;
  @override
  @JsonKey()
  final bool isUpdating;
// Background silent sync (no UI modal)
  @override
  @JsonKey()
  final bool isSilentSyncing;
  @override
  final int? lastSyncedRemoteId;

  @override
  String toString() {
    return 'ProjectUploadState(isUploading: $isUploading, uploadProgress: $uploadProgress, error: $error, uploadedProject: $uploadedProject, isSuccess: $isSuccess, isUpdating: $isUpdating, isSilentSyncing: $isSilentSyncing, lastSyncedRemoteId: $lastSyncedRemoteId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectUploadStateImpl &&
            (identical(other.isUploading, isUploading) ||
                other.isUploading == isUploading) &&
            (identical(other.uploadProgress, uploadProgress) ||
                other.uploadProgress == uploadProgress) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.uploadedProject, uploadedProject) ||
                other.uploadedProject == uploadedProject) &&
            (identical(other.isSuccess, isSuccess) ||
                other.isSuccess == isSuccess) &&
            (identical(other.isUpdating, isUpdating) ||
                other.isUpdating == isUpdating) &&
            (identical(other.isSilentSyncing, isSilentSyncing) ||
                other.isSilentSyncing == isSilentSyncing) &&
            (identical(other.lastSyncedRemoteId, lastSyncedRemoteId) ||
                other.lastSyncedRemoteId == lastSyncedRemoteId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isUploading,
      uploadProgress,
      error,
      uploadedProject,
      isSuccess,
      isUpdating,
      isSilentSyncing,
      lastSyncedRemoteId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectUploadStateImplCopyWith<_$ProjectUploadStateImpl> get copyWith =>
      __$$ProjectUploadStateImplCopyWithImpl<_$ProjectUploadStateImpl>(
          this, _$identity);
}

abstract class _ProjectUploadState implements ProjectUploadState {
  const factory _ProjectUploadState(
      {final bool isUploading,
      final double uploadProgress,
      final String? error,
      final ApiProject? uploadedProject,
      final bool isSuccess,
      final bool isUpdating,
      final bool isSilentSyncing,
      final int? lastSyncedRemoteId}) = _$ProjectUploadStateImpl;

  @override
  bool get isUploading;
  @override
  double get uploadProgress;
  @override
  String? get error;
  @override
  ApiProject? get uploadedProject;
  @override
  bool get isSuccess;
  @override
  bool get isUpdating;
  @override // Background silent sync (no UI modal)
  bool get isSilentSyncing;
  @override
  int? get lastSyncedRemoteId;
  @override
  @JsonKey(ignore: true)
  _$$ProjectUploadStateImplCopyWith<_$ProjectUploadStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
