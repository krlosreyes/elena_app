// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ExerciseState {
  int get todayMinutes => throw _privateConstructorUsedError;
  bool get isSaving => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseStateCopyWith<ExerciseState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseStateCopyWith<$Res> {
  factory $ExerciseStateCopyWith(
          ExerciseState value, $Res Function(ExerciseState) then) =
      _$ExerciseStateCopyWithImpl<$Res, ExerciseState>;
  @useResult
  $Res call({int todayMinutes, bool isSaving, String? error});
}

/// @nodoc
class _$ExerciseStateCopyWithImpl<$Res, $Val extends ExerciseState>
    implements $ExerciseStateCopyWith<$Res> {
  _$ExerciseStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todayMinutes = null,
    Object? isSaving = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      todayMinutes: null == todayMinutes
          ? _value.todayMinutes
          : todayMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseStateImplCopyWith<$Res>
    implements $ExerciseStateCopyWith<$Res> {
  factory _$$ExerciseStateImplCopyWith(
          _$ExerciseStateImpl value, $Res Function(_$ExerciseStateImpl) then) =
      __$$ExerciseStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int todayMinutes, bool isSaving, String? error});
}

/// @nodoc
class __$$ExerciseStateImplCopyWithImpl<$Res>
    extends _$ExerciseStateCopyWithImpl<$Res, _$ExerciseStateImpl>
    implements _$$ExerciseStateImplCopyWith<$Res> {
  __$$ExerciseStateImplCopyWithImpl(
      _$ExerciseStateImpl _value, $Res Function(_$ExerciseStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todayMinutes = null,
    Object? isSaving = null,
    Object? error = freezed,
  }) {
    return _then(_$ExerciseStateImpl(
      todayMinutes: null == todayMinutes
          ? _value.todayMinutes
          : todayMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ExerciseStateImpl implements _ExerciseState {
  const _$ExerciseStateImpl(
      {this.todayMinutes = 0, this.isSaving = false, this.error});

  @override
  @JsonKey()
  final int todayMinutes;
  @override
  @JsonKey()
  final bool isSaving;
  @override
  final String? error;

  @override
  String toString() {
    return 'ExerciseState(todayMinutes: $todayMinutes, isSaving: $isSaving, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseStateImpl &&
            (identical(other.todayMinutes, todayMinutes) ||
                other.todayMinutes == todayMinutes) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, todayMinutes, isSaving, error);

  /// Create a copy of ExerciseState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseStateImplCopyWith<_$ExerciseStateImpl> get copyWith =>
      __$$ExerciseStateImplCopyWithImpl<_$ExerciseStateImpl>(this, _$identity);
}

abstract class _ExerciseState implements ExerciseState {
  const factory _ExerciseState(
      {final int todayMinutes,
      final bool isSaving,
      final String? error}) = _$ExerciseStateImpl;

  @override
  int get todayMinutes;
  @override
  bool get isSaving;
  @override
  String? get error;

  /// Create a copy of ExerciseState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseStateImplCopyWith<_$ExerciseStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
