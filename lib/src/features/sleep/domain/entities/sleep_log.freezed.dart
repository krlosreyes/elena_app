// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sleep_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SleepLog _$SleepLogFromJson(Map<String, dynamic> json) {
  return _SleepLog.fromJson(json);
}

/// @nodoc
mixin _$SleepLog {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get hours => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SleepLogCopyWith<SleepLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SleepLogCopyWith<$Res> {
  factory $SleepLogCopyWith(SleepLog value, $Res Function(SleepLog) then) =
      _$SleepLogCopyWithImpl<$Res, SleepLog>;
  @useResult
  $Res call(
      {String id,
      String userId,
      double hours,
      @TimestampConverter() DateTime timestamp});
}

/// @nodoc
class _$SleepLogCopyWithImpl<$Res, $Val extends SleepLog>
    implements $SleepLogCopyWith<$Res> {
  _$SleepLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? hours = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      hours: null == hours
          ? _value.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SleepLogImplCopyWith<$Res>
    implements $SleepLogCopyWith<$Res> {
  factory _$$SleepLogImplCopyWith(
          _$SleepLogImpl value, $Res Function(_$SleepLogImpl) then) =
      __$$SleepLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      double hours,
      @TimestampConverter() DateTime timestamp});
}

/// @nodoc
class __$$SleepLogImplCopyWithImpl<$Res>
    extends _$SleepLogCopyWithImpl<$Res, _$SleepLogImpl>
    implements _$$SleepLogImplCopyWith<$Res> {
  __$$SleepLogImplCopyWithImpl(
      _$SleepLogImpl _value, $Res Function(_$SleepLogImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? hours = null,
    Object? timestamp = null,
  }) {
    return _then(_$SleepLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      hours: null == hours
          ? _value.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SleepLogImpl implements _SleepLog {
  const _$SleepLogImpl(
      {required this.id,
      required this.userId,
      required this.hours,
      @TimestampConverter() required this.timestamp});

  factory _$SleepLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$SleepLogImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final double hours;
  @override
  @TimestampConverter()
  final DateTime timestamp;

  @override
  String toString() {
    return 'SleepLog(id: $id, userId: $userId, hours: $hours, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SleepLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, hours, timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SleepLogImplCopyWith<_$SleepLogImpl> get copyWith =>
      __$$SleepLogImplCopyWithImpl<_$SleepLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SleepLogImplToJson(
      this,
    );
  }
}

abstract class _SleepLog implements SleepLog {
  const factory _SleepLog(
          {required final String id,
          required final String userId,
          required final double hours,
          @TimestampConverter() required final DateTime timestamp}) =
      _$SleepLogImpl;

  factory _SleepLog.fromJson(Map<String, dynamic> json) =
      _$SleepLogImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  double get hours;
  @override
  @TimestampConverter()
  DateTime get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$SleepLogImplCopyWith<_$SleepLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
