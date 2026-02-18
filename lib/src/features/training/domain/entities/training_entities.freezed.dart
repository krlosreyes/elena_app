// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) {
  return _WorkoutSession.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSession {
  String get id => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError; // fuerza / cardio
  TargetMuscle get targetMuscle => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  List<ExerciseSet> get sets => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutSessionCopyWith<WorkoutSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSessionCopyWith<$Res> {
  factory $WorkoutSessionCopyWith(
          WorkoutSession value, $Res Function(WorkoutSession) then) =
      _$WorkoutSessionCopyWithImpl<$Res, WorkoutSession>;
  @useResult
  $Res call(
      {String id,
      DateTime date,
      String type,
      TargetMuscle targetMuscle,
      int durationMinutes,
      List<ExerciseSet> sets});
}

/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res, $Val extends WorkoutSession>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? type = null,
    Object? targetMuscle = null,
    Object? durationMinutes = null,
    Object? sets = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: null == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutSessionImplCopyWith<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  factory _$$WorkoutSessionImplCopyWith(_$WorkoutSessionImpl value,
          $Res Function(_$WorkoutSessionImpl) then) =
      __$$WorkoutSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime date,
      String type,
      TargetMuscle targetMuscle,
      int durationMinutes,
      List<ExerciseSet> sets});
}

/// @nodoc
class __$$WorkoutSessionImplCopyWithImpl<$Res>
    extends _$WorkoutSessionCopyWithImpl<$Res, _$WorkoutSessionImpl>
    implements _$$WorkoutSessionImplCopyWith<$Res> {
  __$$WorkoutSessionImplCopyWithImpl(
      _$WorkoutSessionImpl _value, $Res Function(_$WorkoutSessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? type = null,
    Object? targetMuscle = null,
    Object? durationMinutes = null,
    Object? sets = null,
  }) {
    return _then(_$WorkoutSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: null == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      sets: null == sets
          ? _value._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutSessionImpl implements _WorkoutSession {
  const _$WorkoutSessionImpl(
      {required this.id,
      required this.date,
      required this.type,
      required this.targetMuscle,
      required this.durationMinutes,
      final List<ExerciseSet> sets = const []})
      : _sets = sets;

  factory _$WorkoutSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSessionImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime date;
  @override
  final String type;
// fuerza / cardio
  @override
  final TargetMuscle targetMuscle;
  @override
  final int durationMinutes;
  final List<ExerciseSet> _sets;
  @override
  @JsonKey()
  List<ExerciseSet> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  String toString() {
    return 'WorkoutSession(id: $id, date: $date, type: $type, targetMuscle: $targetMuscle, durationMinutes: $durationMinutes, sets: $sets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            const DeepCollectionEquality().equals(other._sets, _sets));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, date, type, targetMuscle,
      durationMinutes, const DeepCollectionEquality().hash(_sets));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      __$$WorkoutSessionImplCopyWithImpl<_$WorkoutSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSessionImplToJson(
      this,
    );
  }
}

abstract class _WorkoutSession implements WorkoutSession {
  const factory _WorkoutSession(
      {required final String id,
      required final DateTime date,
      required final String type,
      required final TargetMuscle targetMuscle,
      required final int durationMinutes,
      final List<ExerciseSet> sets}) = _$WorkoutSessionImpl;

  factory _WorkoutSession.fromJson(Map<String, dynamic> json) =
      _$WorkoutSessionImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get date;
  @override
  String get type;
  @override // fuerza / cardio
  TargetMuscle get targetMuscle;
  @override
  int get durationMinutes;
  @override
  List<ExerciseSet> get sets;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) {
  return _ExerciseSet.fromJson(json);
}

/// @nodoc
mixin _$ExerciseSet {
  String get exerciseName => throw _privateConstructorUsedError;
  double get weight => throw _privateConstructorUsedError;
  int get repsCompleted => throw _privateConstructorUsedError;
  int get rir => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseSetCopyWith<ExerciseSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseSetCopyWith<$Res> {
  factory $ExerciseSetCopyWith(
          ExerciseSet value, $Res Function(ExerciseSet) then) =
      _$ExerciseSetCopyWithImpl<$Res, ExerciseSet>;
  @useResult
  $Res call({String exerciseName, double weight, int repsCompleted, int rir});
}

/// @nodoc
class _$ExerciseSetCopyWithImpl<$Res, $Val extends ExerciseSet>
    implements $ExerciseSetCopyWith<$Res> {
  _$ExerciseSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseName = null,
    Object? weight = null,
    Object? repsCompleted = null,
    Object? rir = null,
  }) {
    return _then(_value.copyWith(
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      repsCompleted: null == repsCompleted
          ? _value.repsCompleted
          : repsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      rir: null == rir
          ? _value.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseSetImplCopyWith<$Res>
    implements $ExerciseSetCopyWith<$Res> {
  factory _$$ExerciseSetImplCopyWith(
          _$ExerciseSetImpl value, $Res Function(_$ExerciseSetImpl) then) =
      __$$ExerciseSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String exerciseName, double weight, int repsCompleted, int rir});
}

/// @nodoc
class __$$ExerciseSetImplCopyWithImpl<$Res>
    extends _$ExerciseSetCopyWithImpl<$Res, _$ExerciseSetImpl>
    implements _$$ExerciseSetImplCopyWith<$Res> {
  __$$ExerciseSetImplCopyWithImpl(
      _$ExerciseSetImpl _value, $Res Function(_$ExerciseSetImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseName = null,
    Object? weight = null,
    Object? repsCompleted = null,
    Object? rir = null,
  }) {
    return _then(_$ExerciseSetImpl(
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      repsCompleted: null == repsCompleted
          ? _value.repsCompleted
          : repsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      rir: null == rir
          ? _value.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseSetImpl implements _ExerciseSet {
  const _$ExerciseSetImpl(
      {required this.exerciseName,
      required this.weight,
      required this.repsCompleted,
      required this.rir});

  factory _$ExerciseSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseSetImplFromJson(json);

  @override
  final String exerciseName;
  @override
  final double weight;
  @override
  final int repsCompleted;
  @override
  final int rir;

  @override
  String toString() {
    return 'ExerciseSet(exerciseName: $exerciseName, weight: $weight, repsCompleted: $repsCompleted, rir: $rir)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseSetImpl &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.repsCompleted, repsCompleted) ||
                other.repsCompleted == repsCompleted) &&
            (identical(other.rir, rir) || other.rir == rir));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, exerciseName, weight, repsCompleted, rir);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseSetImplCopyWith<_$ExerciseSetImpl> get copyWith =>
      __$$ExerciseSetImplCopyWithImpl<_$ExerciseSetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseSetImplToJson(
      this,
    );
  }
}

abstract class _ExerciseSet implements ExerciseSet {
  const factory _ExerciseSet(
      {required final String exerciseName,
      required final double weight,
      required final int repsCompleted,
      required final int rir}) = _$ExerciseSetImpl;

  factory _ExerciseSet.fromJson(Map<String, dynamic> json) =
      _$ExerciseSetImpl.fromJson;

  @override
  String get exerciseName;
  @override
  double get weight;
  @override
  int get repsCompleted;
  @override
  int get rir;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseSetImplCopyWith<_$ExerciseSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoutineExercise _$RoutineExerciseFromJson(Map<String, dynamic> json) {
  return _Exercise.fromJson(json);
}

/// @nodoc
mixin _$RoutineExercise {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get sets => throw _privateConstructorUsedError;
  String get targetReps => throw _privateConstructorUsedError;
  int get rir => throw _privateConstructorUsedError;
  int get restSeconds => throw _privateConstructorUsedError;
  String get targetMuscle => throw _privateConstructorUsedError;
  bool get requiresWeight => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoutineExerciseCopyWith<RoutineExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutineExerciseCopyWith<$Res> {
  factory $RoutineExerciseCopyWith(
          RoutineExercise value, $Res Function(RoutineExercise) then) =
      _$RoutineExerciseCopyWithImpl<$Res, RoutineExercise>;
  @useResult
  $Res call(
      {String id,
      String name,
      int sets,
      String targetReps,
      int rir,
      int restSeconds,
      String targetMuscle,
      bool requiresWeight});
}

/// @nodoc
class _$RoutineExerciseCopyWithImpl<$Res, $Val extends RoutineExercise>
    implements $RoutineExerciseCopyWith<$Res> {
  _$RoutineExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sets = null,
    Object? targetReps = null,
    Object? rir = null,
    Object? restSeconds = null,
    Object? targetMuscle = null,
    Object? requiresWeight = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _value.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      rir: null == rir
          ? _value.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      targetMuscle: null == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String,
      requiresWeight: null == requiresWeight
          ? _value.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseImplCopyWith<$Res>
    implements $RoutineExerciseCopyWith<$Res> {
  factory _$$ExerciseImplCopyWith(
          _$ExerciseImpl value, $Res Function(_$ExerciseImpl) then) =
      __$$ExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int sets,
      String targetReps,
      int rir,
      int restSeconds,
      String targetMuscle,
      bool requiresWeight});
}

/// @nodoc
class __$$ExerciseImplCopyWithImpl<$Res>
    extends _$RoutineExerciseCopyWithImpl<$Res, _$ExerciseImpl>
    implements _$$ExerciseImplCopyWith<$Res> {
  __$$ExerciseImplCopyWithImpl(
      _$ExerciseImpl _value, $Res Function(_$ExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sets = null,
    Object? targetReps = null,
    Object? rir = null,
    Object? restSeconds = null,
    Object? targetMuscle = null,
    Object? requiresWeight = null,
  }) {
    return _then(_$ExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _value.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      rir: null == rir
          ? _value.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      targetMuscle: null == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String,
      requiresWeight: null == requiresWeight
          ? _value.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseImpl implements _Exercise {
  const _$ExerciseImpl(
      {required this.id,
      required this.name,
      required this.sets,
      required this.targetReps,
      required this.rir,
      required this.restSeconds,
      this.targetMuscle = 'Unknown',
      this.requiresWeight = true});

  factory _$ExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int sets;
  @override
  final String targetReps;
  @override
  final int rir;
  @override
  final int restSeconds;
  @override
  @JsonKey()
  final String targetMuscle;
  @override
  @JsonKey()
  final bool requiresWeight;

  @override
  String toString() {
    return 'RoutineExercise(id: $id, name: $name, sets: $sets, targetReps: $targetReps, rir: $rir, restSeconds: $restSeconds, targetMuscle: $targetMuscle, requiresWeight: $requiresWeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.rir, rir) || other.rir == rir) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, sets, targetReps, rir,
      restSeconds, targetMuscle, requiresWeight);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      __$$ExerciseImplCopyWithImpl<_$ExerciseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseImplToJson(
      this,
    );
  }
}

abstract class _Exercise implements RoutineExercise {
  const factory _Exercise(
      {required final String id,
      required final String name,
      required final int sets,
      required final String targetReps,
      required final int rir,
      required final int restSeconds,
      final String targetMuscle,
      final bool requiresWeight}) = _$ExerciseImpl;

  factory _Exercise.fromJson(Map<String, dynamic> json) =
      _$ExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get sets;
  @override
  String get targetReps;
  @override
  int get rir;
  @override
  int get restSeconds;
  @override
  String get targetMuscle;
  @override
  bool get requiresWeight;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WeeklyTrainingStats _$WeeklyTrainingStatsFromJson(Map<String, dynamic> json) {
  return _WeeklyTrainingStats.fromJson(json);
}

/// @nodoc
mixin _$WeeklyTrainingStats {
  int get totalStrengthMins => throw _privateConstructorUsedError;
  int get totalHiitMins => throw _privateConstructorUsedError;
  int get zone2Mins => throw _privateConstructorUsedError;
  int get consecutiveWeeksTrained => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WeeklyTrainingStatsCopyWith<WeeklyTrainingStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeeklyTrainingStatsCopyWith<$Res> {
  factory $WeeklyTrainingStatsCopyWith(
          WeeklyTrainingStats value, $Res Function(WeeklyTrainingStats) then) =
      _$WeeklyTrainingStatsCopyWithImpl<$Res, WeeklyTrainingStats>;
  @useResult
  $Res call(
      {int totalStrengthMins,
      int totalHiitMins,
      int zone2Mins,
      int consecutiveWeeksTrained});
}

/// @nodoc
class _$WeeklyTrainingStatsCopyWithImpl<$Res, $Val extends WeeklyTrainingStats>
    implements $WeeklyTrainingStatsCopyWith<$Res> {
  _$WeeklyTrainingStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalStrengthMins = null,
    Object? totalHiitMins = null,
    Object? zone2Mins = null,
    Object? consecutiveWeeksTrained = null,
  }) {
    return _then(_value.copyWith(
      totalStrengthMins: null == totalStrengthMins
          ? _value.totalStrengthMins
          : totalStrengthMins // ignore: cast_nullable_to_non_nullable
              as int,
      totalHiitMins: null == totalHiitMins
          ? _value.totalHiitMins
          : totalHiitMins // ignore: cast_nullable_to_non_nullable
              as int,
      zone2Mins: null == zone2Mins
          ? _value.zone2Mins
          : zone2Mins // ignore: cast_nullable_to_non_nullable
              as int,
      consecutiveWeeksTrained: null == consecutiveWeeksTrained
          ? _value.consecutiveWeeksTrained
          : consecutiveWeeksTrained // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeeklyTrainingStatsImplCopyWith<$Res>
    implements $WeeklyTrainingStatsCopyWith<$Res> {
  factory _$$WeeklyTrainingStatsImplCopyWith(_$WeeklyTrainingStatsImpl value,
          $Res Function(_$WeeklyTrainingStatsImpl) then) =
      __$$WeeklyTrainingStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalStrengthMins,
      int totalHiitMins,
      int zone2Mins,
      int consecutiveWeeksTrained});
}

/// @nodoc
class __$$WeeklyTrainingStatsImplCopyWithImpl<$Res>
    extends _$WeeklyTrainingStatsCopyWithImpl<$Res, _$WeeklyTrainingStatsImpl>
    implements _$$WeeklyTrainingStatsImplCopyWith<$Res> {
  __$$WeeklyTrainingStatsImplCopyWithImpl(_$WeeklyTrainingStatsImpl _value,
      $Res Function(_$WeeklyTrainingStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalStrengthMins = null,
    Object? totalHiitMins = null,
    Object? zone2Mins = null,
    Object? consecutiveWeeksTrained = null,
  }) {
    return _then(_$WeeklyTrainingStatsImpl(
      totalStrengthMins: null == totalStrengthMins
          ? _value.totalStrengthMins
          : totalStrengthMins // ignore: cast_nullable_to_non_nullable
              as int,
      totalHiitMins: null == totalHiitMins
          ? _value.totalHiitMins
          : totalHiitMins // ignore: cast_nullable_to_non_nullable
              as int,
      zone2Mins: null == zone2Mins
          ? _value.zone2Mins
          : zone2Mins // ignore: cast_nullable_to_non_nullable
              as int,
      consecutiveWeeksTrained: null == consecutiveWeeksTrained
          ? _value.consecutiveWeeksTrained
          : consecutiveWeeksTrained // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeeklyTrainingStatsImpl implements _WeeklyTrainingStats {
  const _$WeeklyTrainingStatsImpl(
      {required this.totalStrengthMins,
      required this.totalHiitMins,
      required this.zone2Mins,
      required this.consecutiveWeeksTrained});

  factory _$WeeklyTrainingStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeeklyTrainingStatsImplFromJson(json);

  @override
  final int totalStrengthMins;
  @override
  final int totalHiitMins;
  @override
  final int zone2Mins;
  @override
  final int consecutiveWeeksTrained;

  @override
  String toString() {
    return 'WeeklyTrainingStats(totalStrengthMins: $totalStrengthMins, totalHiitMins: $totalHiitMins, zone2Mins: $zone2Mins, consecutiveWeeksTrained: $consecutiveWeeksTrained)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeeklyTrainingStatsImpl &&
            (identical(other.totalStrengthMins, totalStrengthMins) ||
                other.totalStrengthMins == totalStrengthMins) &&
            (identical(other.totalHiitMins, totalHiitMins) ||
                other.totalHiitMins == totalHiitMins) &&
            (identical(other.zone2Mins, zone2Mins) ||
                other.zone2Mins == zone2Mins) &&
            (identical(
                    other.consecutiveWeeksTrained, consecutiveWeeksTrained) ||
                other.consecutiveWeeksTrained == consecutiveWeeksTrained));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, totalStrengthMins, totalHiitMins,
      zone2Mins, consecutiveWeeksTrained);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WeeklyTrainingStatsImplCopyWith<_$WeeklyTrainingStatsImpl> get copyWith =>
      __$$WeeklyTrainingStatsImplCopyWithImpl<_$WeeklyTrainingStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeeklyTrainingStatsImplToJson(
      this,
    );
  }
}

abstract class _WeeklyTrainingStats implements WeeklyTrainingStats {
  const factory _WeeklyTrainingStats(
      {required final int totalStrengthMins,
      required final int totalHiitMins,
      required final int zone2Mins,
      required final int consecutiveWeeksTrained}) = _$WeeklyTrainingStatsImpl;

  factory _WeeklyTrainingStats.fromJson(Map<String, dynamic> json) =
      _$WeeklyTrainingStatsImpl.fromJson;

  @override
  int get totalStrengthMins;
  @override
  int get totalHiitMins;
  @override
  int get zone2Mins;
  @override
  int get consecutiveWeeksTrained;
  @override
  @JsonKey(ignore: true)
  _$$WeeklyTrainingStatsImplCopyWith<_$WeeklyTrainingStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutRecommendation _$WorkoutRecommendationFromJson(
    Map<String, dynamic> json) {
  return _WorkoutRecommendation.fromJson(json);
}

/// @nodoc
mixin _$WorkoutRecommendation {
  String get type =>
      throw _privateConstructorUsedError; // Strength, Cardio, ActiveRecovery, Deload
  TargetMuscle? get targetMuscle => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  String get intensity =>
      throw _privateConstructorUsedError; // "Zone 2", "RIR 2"
  String get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutRecommendationCopyWith<WorkoutRecommendation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutRecommendationCopyWith<$Res> {
  factory $WorkoutRecommendationCopyWith(WorkoutRecommendation value,
          $Res Function(WorkoutRecommendation) then) =
      _$WorkoutRecommendationCopyWithImpl<$Res, WorkoutRecommendation>;
  @useResult
  $Res call(
      {String type,
      TargetMuscle? targetMuscle,
      int durationMinutes,
      String intensity,
      String notes});
}

/// @nodoc
class _$WorkoutRecommendationCopyWithImpl<$Res,
        $Val extends WorkoutRecommendation>
    implements $WorkoutRecommendationCopyWith<$Res> {
  _$WorkoutRecommendationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? targetMuscle = freezed,
    Object? durationMinutes = null,
    Object? intensity = null,
    Object? notes = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle?,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      intensity: null == intensity
          ? _value.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutRecommendationImplCopyWith<$Res>
    implements $WorkoutRecommendationCopyWith<$Res> {
  factory _$$WorkoutRecommendationImplCopyWith(
          _$WorkoutRecommendationImpl value,
          $Res Function(_$WorkoutRecommendationImpl) then) =
      __$$WorkoutRecommendationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String type,
      TargetMuscle? targetMuscle,
      int durationMinutes,
      String intensity,
      String notes});
}

/// @nodoc
class __$$WorkoutRecommendationImplCopyWithImpl<$Res>
    extends _$WorkoutRecommendationCopyWithImpl<$Res,
        _$WorkoutRecommendationImpl>
    implements _$$WorkoutRecommendationImplCopyWith<$Res> {
  __$$WorkoutRecommendationImplCopyWithImpl(_$WorkoutRecommendationImpl _value,
      $Res Function(_$WorkoutRecommendationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? targetMuscle = freezed,
    Object? durationMinutes = null,
    Object? intensity = null,
    Object? notes = null,
  }) {
    return _then(_$WorkoutRecommendationImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _value.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle?,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      intensity: null == intensity
          ? _value.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutRecommendationImpl implements _WorkoutRecommendation {
  const _$WorkoutRecommendationImpl(
      {required this.type,
      this.targetMuscle,
      required this.durationMinutes,
      required this.intensity,
      required this.notes});

  factory _$WorkoutRecommendationImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutRecommendationImplFromJson(json);

  @override
  final String type;
// Strength, Cardio, ActiveRecovery, Deload
  @override
  final TargetMuscle? targetMuscle;
  @override
  final int durationMinutes;
  @override
  final String intensity;
// "Zone 2", "RIR 2"
  @override
  final String notes;

  @override
  String toString() {
    return 'WorkoutRecommendation(type: $type, targetMuscle: $targetMuscle, durationMinutes: $durationMinutes, intensity: $intensity, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutRecommendationImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, targetMuscle, durationMinutes, intensity, notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutRecommendationImplCopyWith<_$WorkoutRecommendationImpl>
      get copyWith => __$$WorkoutRecommendationImplCopyWithImpl<
          _$WorkoutRecommendationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutRecommendationImplToJson(
      this,
    );
  }
}

abstract class _WorkoutRecommendation implements WorkoutRecommendation {
  const factory _WorkoutRecommendation(
      {required final String type,
      final TargetMuscle? targetMuscle,
      required final int durationMinutes,
      required final String intensity,
      required final String notes}) = _$WorkoutRecommendationImpl;

  factory _WorkoutRecommendation.fromJson(Map<String, dynamic> json) =
      _$WorkoutRecommendationImpl.fromJson;

  @override
  String get type;
  @override // Strength, Cardio, ActiveRecovery, Deload
  TargetMuscle? get targetMuscle;
  @override
  int get durationMinutes;
  @override
  String get intensity;
  @override // "Zone 2", "RIR 2"
  String get notes;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutRecommendationImplCopyWith<_$WorkoutRecommendationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

TrainingCycle _$TrainingCycleFromJson(Map<String, dynamic> json) {
  return _TrainingCycle.fromJson(json);
}

/// @nodoc
mixin _$TrainingCycle {
  int get sessionCount => throw _privateConstructorUsedError;
  bool get isDeloadActive => throw _privateConstructorUsedError;
  int get cycleNumber => throw _privateConstructorUsedError;
  DateTime? get deloadStartDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TrainingCycleCopyWith<TrainingCycle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainingCycleCopyWith<$Res> {
  factory $TrainingCycleCopyWith(
          TrainingCycle value, $Res Function(TrainingCycle) then) =
      _$TrainingCycleCopyWithImpl<$Res, TrainingCycle>;
  @useResult
  $Res call(
      {int sessionCount,
      bool isDeloadActive,
      int cycleNumber,
      DateTime? deloadStartDate});
}

/// @nodoc
class _$TrainingCycleCopyWithImpl<$Res, $Val extends TrainingCycle>
    implements $TrainingCycleCopyWith<$Res> {
  _$TrainingCycleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionCount = null,
    Object? isDeloadActive = null,
    Object? cycleNumber = null,
    Object? deloadStartDate = freezed,
  }) {
    return _then(_value.copyWith(
      sessionCount: null == sessionCount
          ? _value.sessionCount
          : sessionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isDeloadActive: null == isDeloadActive
          ? _value.isDeloadActive
          : isDeloadActive // ignore: cast_nullable_to_non_nullable
              as bool,
      cycleNumber: null == cycleNumber
          ? _value.cycleNumber
          : cycleNumber // ignore: cast_nullable_to_non_nullable
              as int,
      deloadStartDate: freezed == deloadStartDate
          ? _value.deloadStartDate
          : deloadStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrainingCycleImplCopyWith<$Res>
    implements $TrainingCycleCopyWith<$Res> {
  factory _$$TrainingCycleImplCopyWith(
          _$TrainingCycleImpl value, $Res Function(_$TrainingCycleImpl) then) =
      __$$TrainingCycleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int sessionCount,
      bool isDeloadActive,
      int cycleNumber,
      DateTime? deloadStartDate});
}

/// @nodoc
class __$$TrainingCycleImplCopyWithImpl<$Res>
    extends _$TrainingCycleCopyWithImpl<$Res, _$TrainingCycleImpl>
    implements _$$TrainingCycleImplCopyWith<$Res> {
  __$$TrainingCycleImplCopyWithImpl(
      _$TrainingCycleImpl _value, $Res Function(_$TrainingCycleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionCount = null,
    Object? isDeloadActive = null,
    Object? cycleNumber = null,
    Object? deloadStartDate = freezed,
  }) {
    return _then(_$TrainingCycleImpl(
      sessionCount: null == sessionCount
          ? _value.sessionCount
          : sessionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isDeloadActive: null == isDeloadActive
          ? _value.isDeloadActive
          : isDeloadActive // ignore: cast_nullable_to_non_nullable
              as bool,
      cycleNumber: null == cycleNumber
          ? _value.cycleNumber
          : cycleNumber // ignore: cast_nullable_to_non_nullable
              as int,
      deloadStartDate: freezed == deloadStartDate
          ? _value.deloadStartDate
          : deloadStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrainingCycleImpl implements _TrainingCycle {
  const _$TrainingCycleImpl(
      {required this.sessionCount,
      required this.isDeloadActive,
      required this.cycleNumber,
      this.deloadStartDate});

  factory _$TrainingCycleImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainingCycleImplFromJson(json);

  @override
  final int sessionCount;
  @override
  final bool isDeloadActive;
  @override
  final int cycleNumber;
  @override
  final DateTime? deloadStartDate;

  @override
  String toString() {
    return 'TrainingCycle(sessionCount: $sessionCount, isDeloadActive: $isDeloadActive, cycleNumber: $cycleNumber, deloadStartDate: $deloadStartDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainingCycleImpl &&
            (identical(other.sessionCount, sessionCount) ||
                other.sessionCount == sessionCount) &&
            (identical(other.isDeloadActive, isDeloadActive) ||
                other.isDeloadActive == isDeloadActive) &&
            (identical(other.cycleNumber, cycleNumber) ||
                other.cycleNumber == cycleNumber) &&
            (identical(other.deloadStartDate, deloadStartDate) ||
                other.deloadStartDate == deloadStartDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, sessionCount, isDeloadActive, cycleNumber, deloadStartDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainingCycleImplCopyWith<_$TrainingCycleImpl> get copyWith =>
      __$$TrainingCycleImplCopyWithImpl<_$TrainingCycleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainingCycleImplToJson(
      this,
    );
  }
}

abstract class _TrainingCycle implements TrainingCycle {
  const factory _TrainingCycle(
      {required final int sessionCount,
      required final bool isDeloadActive,
      required final int cycleNumber,
      final DateTime? deloadStartDate}) = _$TrainingCycleImpl;

  factory _TrainingCycle.fromJson(Map<String, dynamic> json) =
      _$TrainingCycleImpl.fromJson;

  @override
  int get sessionCount;
  @override
  bool get isDeloadActive;
  @override
  int get cycleNumber;
  @override
  DateTime? get deloadStartDate;
  @override
  @JsonKey(ignore: true)
  _$$TrainingCycleImplCopyWith<_$TrainingCycleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
