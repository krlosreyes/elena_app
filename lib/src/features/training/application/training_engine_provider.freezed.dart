// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_engine_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TrainingSessionState {
  int get currentIndex => throw _privateConstructorUsedError;
  bool get isDeload => throw _privateConstructorUsedError;
  bool get isSessionActive => throw _privateConstructorUsedError;
  bool get isExecuting =>
      throw _privateConstructorUsedError; // Dynamic Feedback Visibility
  bool get isResting =>
      throw _privateConstructorUsedError; // New: Track Rest State
  TrainingStatus get status => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TrainingSessionStateCopyWith<TrainingSessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainingSessionStateCopyWith<$Res> {
  factory $TrainingSessionStateCopyWith(TrainingSessionState value,
          $Res Function(TrainingSessionState) then) =
      _$TrainingSessionStateCopyWithImpl<$Res, TrainingSessionState>;
  @useResult
  $Res call(
      {int currentIndex,
      bool isDeload,
      bool isSessionActive,
      bool isExecuting,
      bool isResting,
      TrainingStatus status});
}

/// @nodoc
class _$TrainingSessionStateCopyWithImpl<$Res,
        $Val extends TrainingSessionState>
    implements $TrainingSessionStateCopyWith<$Res> {
  _$TrainingSessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentIndex = null,
    Object? isDeload = null,
    Object? isSessionActive = null,
    Object? isExecuting = null,
    Object? isResting = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _value.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      isSessionActive: null == isSessionActive
          ? _value.isSessionActive
          : isSessionActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isExecuting: null == isExecuting
          ? _value.isExecuting
          : isExecuting // ignore: cast_nullable_to_non_nullable
              as bool,
      isResting: null == isResting
          ? _value.isResting
          : isResting // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TrainingStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrainingSessionStateImplCopyWith<$Res>
    implements $TrainingSessionStateCopyWith<$Res> {
  factory _$$TrainingSessionStateImplCopyWith(_$TrainingSessionStateImpl value,
          $Res Function(_$TrainingSessionStateImpl) then) =
      __$$TrainingSessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int currentIndex,
      bool isDeload,
      bool isSessionActive,
      bool isExecuting,
      bool isResting,
      TrainingStatus status});
}

/// @nodoc
class __$$TrainingSessionStateImplCopyWithImpl<$Res>
    extends _$TrainingSessionStateCopyWithImpl<$Res, _$TrainingSessionStateImpl>
    implements _$$TrainingSessionStateImplCopyWith<$Res> {
  __$$TrainingSessionStateImplCopyWithImpl(_$TrainingSessionStateImpl _value,
      $Res Function(_$TrainingSessionStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentIndex = null,
    Object? isDeload = null,
    Object? isSessionActive = null,
    Object? isExecuting = null,
    Object? isResting = null,
    Object? status = null,
  }) {
    return _then(_$TrainingSessionStateImpl(
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _value.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      isSessionActive: null == isSessionActive
          ? _value.isSessionActive
          : isSessionActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isExecuting: null == isExecuting
          ? _value.isExecuting
          : isExecuting // ignore: cast_nullable_to_non_nullable
              as bool,
      isResting: null == isResting
          ? _value.isResting
          : isResting // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TrainingStatus,
    ));
  }
}

/// @nodoc

class _$TrainingSessionStateImpl implements _TrainingSessionState {
  const _$TrainingSessionStateImpl(
      {this.currentIndex = 0,
      this.isDeload = false,
      this.isSessionActive = false,
      this.isExecuting = false,
      this.isResting = false,
      this.status = TrainingStatus.needsDiagnostic});

  @override
  @JsonKey()
  final int currentIndex;
  @override
  @JsonKey()
  final bool isDeload;
  @override
  @JsonKey()
  final bool isSessionActive;
  @override
  @JsonKey()
  final bool isExecuting;
// Dynamic Feedback Visibility
  @override
  @JsonKey()
  final bool isResting;
// New: Track Rest State
  @override
  @JsonKey()
  final TrainingStatus status;

  @override
  String toString() {
    return 'TrainingSessionState(currentIndex: $currentIndex, isDeload: $isDeload, isSessionActive: $isSessionActive, isExecuting: $isExecuting, isResting: $isResting, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainingSessionStateImpl &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isDeload, isDeload) ||
                other.isDeload == isDeload) &&
            (identical(other.isSessionActive, isSessionActive) ||
                other.isSessionActive == isSessionActive) &&
            (identical(other.isExecuting, isExecuting) ||
                other.isExecuting == isExecuting) &&
            (identical(other.isResting, isResting) ||
                other.isResting == isResting) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentIndex, isDeload,
      isSessionActive, isExecuting, isResting, status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainingSessionStateImplCopyWith<_$TrainingSessionStateImpl>
      get copyWith =>
          __$$TrainingSessionStateImplCopyWithImpl<_$TrainingSessionStateImpl>(
              this, _$identity);
}

abstract class _TrainingSessionState implements TrainingSessionState {
  const factory _TrainingSessionState(
      {final int currentIndex,
      final bool isDeload,
      final bool isSessionActive,
      final bool isExecuting,
      final bool isResting,
      final TrainingStatus status}) = _$TrainingSessionStateImpl;

  @override
  int get currentIndex;
  @override
  bool get isDeload;
  @override
  bool get isSessionActive;
  @override
  bool get isExecuting;
  @override // Dynamic Feedback Visibility
  bool get isResting;
  @override // New: Track Rest State
  TrainingStatus get status;
  @override
  @JsonKey(ignore: true)
  _$$TrainingSessionStateImplCopyWith<_$TrainingSessionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
