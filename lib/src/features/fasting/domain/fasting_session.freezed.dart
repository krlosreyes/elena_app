// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fasting_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FastingSession _$FastingSessionFromJson(Map<String, dynamic> json) {
  return _FastingSession.fromJson(json);
}

/// @nodoc
mixin _$FastingSession {
  String get uid => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;
  int get plannedDurationHours => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FastingSessionCopyWith<FastingSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FastingSessionCopyWith<$Res> {
  factory $FastingSessionCopyWith(
          FastingSession value, $Res Function(FastingSession) then) =
      _$FastingSessionCopyWithImpl<$Res, FastingSession>;
  @useResult
  $Res call(
      {String uid,
      DateTime startTime,
      DateTime? endTime,
      int plannedDurationHours,
      bool isCompleted});
}

/// @nodoc
class _$FastingSessionCopyWithImpl<$Res, $Val extends FastingSession>
    implements $FastingSessionCopyWith<$Res> {
  _$FastingSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? plannedDurationHours = null,
    Object? isCompleted = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      plannedDurationHours: null == plannedDurationHours
          ? _value.plannedDurationHours
          : plannedDurationHours // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FastingSessionImplCopyWith<$Res>
    implements $FastingSessionCopyWith<$Res> {
  factory _$$FastingSessionImplCopyWith(_$FastingSessionImpl value,
          $Res Function(_$FastingSessionImpl) then) =
      __$$FastingSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      DateTime startTime,
      DateTime? endTime,
      int plannedDurationHours,
      bool isCompleted});
}

/// @nodoc
class __$$FastingSessionImplCopyWithImpl<$Res>
    extends _$FastingSessionCopyWithImpl<$Res, _$FastingSessionImpl>
    implements _$$FastingSessionImplCopyWith<$Res> {
  __$$FastingSessionImplCopyWithImpl(
      _$FastingSessionImpl _value, $Res Function(_$FastingSessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? plannedDurationHours = null,
    Object? isCompleted = null,
  }) {
    return _then(_$FastingSessionImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      plannedDurationHours: null == plannedDurationHours
          ? _value.plannedDurationHours
          : plannedDurationHours // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FastingSessionImpl implements _FastingSession {
  const _$FastingSessionImpl(
      {required this.uid,
      required this.startTime,
      this.endTime,
      required this.plannedDurationHours,
      this.isCompleted = false});

  factory _$FastingSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FastingSessionImplFromJson(json);

  @override
  final String uid;
  @override
  final DateTime startTime;
  @override
  final DateTime? endTime;
  @override
  final int plannedDurationHours;
  @override
  @JsonKey()
  final bool isCompleted;

  @override
  String toString() {
    return 'FastingSession(uid: $uid, startTime: $startTime, endTime: $endTime, plannedDurationHours: $plannedDurationHours, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FastingSessionImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.plannedDurationHours, plannedDurationHours) ||
                other.plannedDurationHours == plannedDurationHours) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, uid, startTime, endTime, plannedDurationHours, isCompleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FastingSessionImplCopyWith<_$FastingSessionImpl> get copyWith =>
      __$$FastingSessionImplCopyWithImpl<_$FastingSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FastingSessionImplToJson(
      this,
    );
  }
}

abstract class _FastingSession implements FastingSession {
  const factory _FastingSession(
      {required final String uid,
      required final DateTime startTime,
      final DateTime? endTime,
      required final int plannedDurationHours,
      final bool isCompleted}) = _$FastingSessionImpl;

  factory _FastingSession.fromJson(Map<String, dynamic> json) =
      _$FastingSessionImpl.fromJson;

  @override
  String get uid;
  @override
  DateTime get startTime;
  @override
  DateTime? get endTime;
  @override
  int get plannedDurationHours;
  @override
  bool get isCompleted;
  @override
  @JsonKey(ignore: true)
  _$$FastingSessionImplCopyWith<_$FastingSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
