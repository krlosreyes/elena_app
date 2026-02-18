// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metabolic_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MetabolicState _$MetabolicStateFromJson(Map<String, dynamic> json) {
  return _MetabolicState.fromJson(json);
}

/// @nodoc
mixin _$MetabolicState {
  DateTime get date => throw _privateConstructorUsedError;
  double get sleepHours => throw _privateConstructorUsedError;
  int get sorenessLevel => throw _privateConstructorUsedError; // 1-5
  String get nutritionStatus =>
      throw _privateConstructorUsedError; // "fasted", "fed"
  double get energyLevel => throw _privateConstructorUsedError; // 1-10
  String? get insightMessage => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MetabolicStateCopyWith<MetabolicState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MetabolicStateCopyWith<$Res> {
  factory $MetabolicStateCopyWith(
          MetabolicState value, $Res Function(MetabolicState) then) =
      _$MetabolicStateCopyWithImpl<$Res, MetabolicState>;
  @useResult
  $Res call(
      {DateTime date,
      double sleepHours,
      int sorenessLevel,
      String nutritionStatus,
      double energyLevel,
      String? insightMessage});
}

/// @nodoc
class _$MetabolicStateCopyWithImpl<$Res, $Val extends MetabolicState>
    implements $MetabolicStateCopyWith<$Res> {
  _$MetabolicStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? sleepHours = null,
    Object? sorenessLevel = null,
    Object? nutritionStatus = null,
    Object? energyLevel = null,
    Object? insightMessage = freezed,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sleepHours: null == sleepHours
          ? _value.sleepHours
          : sleepHours // ignore: cast_nullable_to_non_nullable
              as double,
      sorenessLevel: null == sorenessLevel
          ? _value.sorenessLevel
          : sorenessLevel // ignore: cast_nullable_to_non_nullable
              as int,
      nutritionStatus: null == nutritionStatus
          ? _value.nutritionStatus
          : nutritionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      energyLevel: null == energyLevel
          ? _value.energyLevel
          : energyLevel // ignore: cast_nullable_to_non_nullable
              as double,
      insightMessage: freezed == insightMessage
          ? _value.insightMessage
          : insightMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MetabolicStateImplCopyWith<$Res>
    implements $MetabolicStateCopyWith<$Res> {
  factory _$$MetabolicStateImplCopyWith(_$MetabolicStateImpl value,
          $Res Function(_$MetabolicStateImpl) then) =
      __$$MetabolicStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime date,
      double sleepHours,
      int sorenessLevel,
      String nutritionStatus,
      double energyLevel,
      String? insightMessage});
}

/// @nodoc
class __$$MetabolicStateImplCopyWithImpl<$Res>
    extends _$MetabolicStateCopyWithImpl<$Res, _$MetabolicStateImpl>
    implements _$$MetabolicStateImplCopyWith<$Res> {
  __$$MetabolicStateImplCopyWithImpl(
      _$MetabolicStateImpl _value, $Res Function(_$MetabolicStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? sleepHours = null,
    Object? sorenessLevel = null,
    Object? nutritionStatus = null,
    Object? energyLevel = null,
    Object? insightMessage = freezed,
  }) {
    return _then(_$MetabolicStateImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sleepHours: null == sleepHours
          ? _value.sleepHours
          : sleepHours // ignore: cast_nullable_to_non_nullable
              as double,
      sorenessLevel: null == sorenessLevel
          ? _value.sorenessLevel
          : sorenessLevel // ignore: cast_nullable_to_non_nullable
              as int,
      nutritionStatus: null == nutritionStatus
          ? _value.nutritionStatus
          : nutritionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      energyLevel: null == energyLevel
          ? _value.energyLevel
          : energyLevel // ignore: cast_nullable_to_non_nullable
              as double,
      insightMessage: freezed == insightMessage
          ? _value.insightMessage
          : insightMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MetabolicStateImpl implements _MetabolicState {
  const _$MetabolicStateImpl(
      {required this.date,
      required this.sleepHours,
      required this.sorenessLevel,
      required this.nutritionStatus,
      required this.energyLevel,
      required this.insightMessage});

  factory _$MetabolicStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$MetabolicStateImplFromJson(json);

  @override
  final DateTime date;
  @override
  final double sleepHours;
  @override
  final int sorenessLevel;
// 1-5
  @override
  final String nutritionStatus;
// "fasted", "fed"
  @override
  final double energyLevel;
// 1-10
  @override
  final String? insightMessage;

  @override
  String toString() {
    return 'MetabolicState(date: $date, sleepHours: $sleepHours, sorenessLevel: $sorenessLevel, nutritionStatus: $nutritionStatus, energyLevel: $energyLevel, insightMessage: $insightMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetabolicStateImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.sleepHours, sleepHours) ||
                other.sleepHours == sleepHours) &&
            (identical(other.sorenessLevel, sorenessLevel) ||
                other.sorenessLevel == sorenessLevel) &&
            (identical(other.nutritionStatus, nutritionStatus) ||
                other.nutritionStatus == nutritionStatus) &&
            (identical(other.energyLevel, energyLevel) ||
                other.energyLevel == energyLevel) &&
            (identical(other.insightMessage, insightMessage) ||
                other.insightMessage == insightMessage));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, date, sleepHours, sorenessLevel,
      nutritionStatus, energyLevel, insightMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MetabolicStateImplCopyWith<_$MetabolicStateImpl> get copyWith =>
      __$$MetabolicStateImplCopyWithImpl<_$MetabolicStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MetabolicStateImplToJson(
      this,
    );
  }
}

abstract class _MetabolicState implements MetabolicState {
  const factory _MetabolicState(
      {required final DateTime date,
      required final double sleepHours,
      required final int sorenessLevel,
      required final String nutritionStatus,
      required final double energyLevel,
      required final String? insightMessage}) = _$MetabolicStateImpl;

  factory _MetabolicState.fromJson(Map<String, dynamic> json) =
      _$MetabolicStateImpl.fromJson;

  @override
  DateTime get date;
  @override
  double get sleepHours;
  @override
  int get sorenessLevel;
  @override // 1-5
  String get nutritionStatus;
  @override // "fasted", "fed"
  double get energyLevel;
  @override // 1-10
  String? get insightMessage;
  @override
  @JsonKey(ignore: true)
  _$$MetabolicStateImplCopyWith<_$MetabolicStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
