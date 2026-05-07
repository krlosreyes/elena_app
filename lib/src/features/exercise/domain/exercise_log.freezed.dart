// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseLog _$ExerciseLogFromJson(Map<String, dynamic> json) {
  return _ExerciseLog.fromJson(json);
}

/// @nodoc
mixin _$ExerciseLog {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;

  /// Etiqueta libre legacy (SPEC-03). Se mantiene para retrocompatibilidad
  /// con logs antiguos. SPEC-68 introduce `type` como enum tipado.
  String get activityType => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;
  double get intensityMultiplier =>
      throw _privateConstructorUsedError; // ── SPEC-68: tipificación del ejercicio ─────────────────────────────
  /// Tipo de ejercicio según categorías ACSM. `null` para logs legacy
  /// que no tienen el dato; el ScoreEngine usa un multiplicador neutral.
  ExerciseType? get type => throw _privateConstructorUsedError;

  /// Intensidad subjetiva categórica. `null` para logs legacy.
  ExerciseIntensity? get intensity => throw _privateConstructorUsedError;

  /// Rate of Perceived Exertion (1-10, escala Borg modificada).
  /// `null` si el usuario no lo registró. Solo valores en [1, 10].
  int? get rpe => throw _privateConstructorUsedError;

  /// Frecuencia cardíaca promedio durante la sesión, en bpm.
  /// `null` si no se midió. Debe ser >= 30 si presente.
  int? get heartRateAvg => throw _privateConstructorUsedError;

  /// Serializes this ExerciseLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseLogCopyWith<ExerciseLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseLogCopyWith<$Res> {
  factory $ExerciseLogCopyWith(
          ExerciseLog value, $Res Function(ExerciseLog) then) =
      _$ExerciseLogCopyWithImpl<$Res, ExerciseLog>;
  @useResult
  $Res call(
      {String id,
      String userId,
      int durationMinutes,
      String activityType,
      @TimestampConverter() DateTime timestamp,
      double intensityMultiplier,
      ExerciseType? type,
      ExerciseIntensity? intensity,
      int? rpe,
      int? heartRateAvg});
}

/// @nodoc
class _$ExerciseLogCopyWithImpl<$Res, $Val extends ExerciseLog>
    implements $ExerciseLogCopyWith<$Res> {
  _$ExerciseLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? durationMinutes = null,
    Object? activityType = null,
    Object? timestamp = null,
    Object? intensityMultiplier = null,
    Object? type = freezed,
    Object? intensity = freezed,
    Object? rpe = freezed,
    Object? heartRateAvg = freezed,
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
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      activityType: null == activityType
          ? _value.activityType
          : activityType // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      intensityMultiplier: null == intensityMultiplier
          ? _value.intensityMultiplier
          : intensityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExerciseType?,
      intensity: freezed == intensity
          ? _value.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as ExerciseIntensity?,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateAvg: freezed == heartRateAvg
          ? _value.heartRateAvg
          : heartRateAvg // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseLogImplCopyWith<$Res>
    implements $ExerciseLogCopyWith<$Res> {
  factory _$$ExerciseLogImplCopyWith(
          _$ExerciseLogImpl value, $Res Function(_$ExerciseLogImpl) then) =
      __$$ExerciseLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      int durationMinutes,
      String activityType,
      @TimestampConverter() DateTime timestamp,
      double intensityMultiplier,
      ExerciseType? type,
      ExerciseIntensity? intensity,
      int? rpe,
      int? heartRateAvg});
}

/// @nodoc
class __$$ExerciseLogImplCopyWithImpl<$Res>
    extends _$ExerciseLogCopyWithImpl<$Res, _$ExerciseLogImpl>
    implements _$$ExerciseLogImplCopyWith<$Res> {
  __$$ExerciseLogImplCopyWithImpl(
      _$ExerciseLogImpl _value, $Res Function(_$ExerciseLogImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? durationMinutes = null,
    Object? activityType = null,
    Object? timestamp = null,
    Object? intensityMultiplier = null,
    Object? type = freezed,
    Object? intensity = freezed,
    Object? rpe = freezed,
    Object? heartRateAvg = freezed,
  }) {
    return _then(_$ExerciseLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      activityType: null == activityType
          ? _value.activityType
          : activityType // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      intensityMultiplier: null == intensityMultiplier
          ? _value.intensityMultiplier
          : intensityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExerciseType?,
      intensity: freezed == intensity
          ? _value.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as ExerciseIntensity?,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateAvg: freezed == heartRateAvg
          ? _value.heartRateAvg
          : heartRateAvg // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseLogImpl implements _ExerciseLog {
  const _$ExerciseLogImpl(
      {required this.id,
      required this.userId,
      required this.durationMinutes,
      required this.activityType,
      @TimestampConverter() required this.timestamp,
      this.intensityMultiplier = 1.0,
      this.type,
      this.intensity,
      this.rpe,
      this.heartRateAvg});

  factory _$ExerciseLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseLogImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final int durationMinutes;

  /// Etiqueta libre legacy (SPEC-03). Se mantiene para retrocompatibilidad
  /// con logs antiguos. SPEC-68 introduce `type` como enum tipado.
  @override
  final String activityType;
  @override
  @TimestampConverter()
  final DateTime timestamp;
  @override
  @JsonKey()
  final double intensityMultiplier;
// ── SPEC-68: tipificación del ejercicio ─────────────────────────────
  /// Tipo de ejercicio según categorías ACSM. `null` para logs legacy
  /// que no tienen el dato; el ScoreEngine usa un multiplicador neutral.
  @override
  final ExerciseType? type;

  /// Intensidad subjetiva categórica. `null` para logs legacy.
  @override
  final ExerciseIntensity? intensity;

  /// Rate of Perceived Exertion (1-10, escala Borg modificada).
  /// `null` si el usuario no lo registró. Solo valores en [1, 10].
  @override
  final int? rpe;

  /// Frecuencia cardíaca promedio durante la sesión, en bpm.
  /// `null` si no se midió. Debe ser >= 30 si presente.
  @override
  final int? heartRateAvg;

  @override
  String toString() {
    return 'ExerciseLog(id: $id, userId: $userId, durationMinutes: $durationMinutes, activityType: $activityType, timestamp: $timestamp, intensityMultiplier: $intensityMultiplier, type: $type, intensity: $intensity, rpe: $rpe, heartRateAvg: $heartRateAvg)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.activityType, activityType) ||
                other.activityType == activityType) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.intensityMultiplier, intensityMultiplier) ||
                other.intensityMultiplier == intensityMultiplier) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.heartRateAvg, heartRateAvg) ||
                other.heartRateAvg == heartRateAvg));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      durationMinutes,
      activityType,
      timestamp,
      intensityMultiplier,
      type,
      intensity,
      rpe,
      heartRateAvg);

  /// Create a copy of ExerciseLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseLogImplCopyWith<_$ExerciseLogImpl> get copyWith =>
      __$$ExerciseLogImplCopyWithImpl<_$ExerciseLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseLogImplToJson(
      this,
    );
  }
}

abstract class _ExerciseLog implements ExerciseLog {
  const factory _ExerciseLog(
      {required final String id,
      required final String userId,
      required final int durationMinutes,
      required final String activityType,
      @TimestampConverter() required final DateTime timestamp,
      final double intensityMultiplier,
      final ExerciseType? type,
      final ExerciseIntensity? intensity,
      final int? rpe,
      final int? heartRateAvg}) = _$ExerciseLogImpl;

  factory _ExerciseLog.fromJson(Map<String, dynamic> json) =
      _$ExerciseLogImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  int get durationMinutes;

  /// Etiqueta libre legacy (SPEC-03). Se mantiene para retrocompatibilidad
  /// con logs antiguos. SPEC-68 introduce `type` como enum tipado.
  @override
  String get activityType;
  @override
  @TimestampConverter()
  DateTime get timestamp;
  @override
  double
      get intensityMultiplier; // ── SPEC-68: tipificación del ejercicio ─────────────────────────────
  /// Tipo de ejercicio según categorías ACSM. `null` para logs legacy
  /// que no tienen el dato; el ScoreEngine usa un multiplicador neutral.
  @override
  ExerciseType? get type;

  /// Intensidad subjetiva categórica. `null` para logs legacy.
  @override
  ExerciseIntensity? get intensity;

  /// Rate of Perceived Exertion (1-10, escala Borg modificada).
  /// `null` si el usuario no lo registró. Solo valores en [1, 10].
  @override
  int? get rpe;

  /// Frecuencia cardíaca promedio durante la sesión, en bpm.
  /// `null` si no se midió. Debe ser >= 30 si presente.
  @override
  int? get heartRateAvg;

  /// Create a copy of ExerciseLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseLogImplCopyWith<_$ExerciseLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
