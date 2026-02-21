// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routine_cycle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoutineCycle _$RoutineCycleFromJson(Map<String, dynamic> json) {
  return _RoutineCycle.fromJson(json);
}

/// @nodoc
mixin _$RoutineCycle {
  DateTime get startDate => throw _privateConstructorUsedError;
  List<RoutineWeek> get weeks => throw _privateConstructorUsedError;
  String get goalDescriptive => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoutineCycleCopyWith<RoutineCycle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutineCycleCopyWith<$Res> {
  factory $RoutineCycleCopyWith(
          RoutineCycle value, $Res Function(RoutineCycle) then) =
      _$RoutineCycleCopyWithImpl<$Res, RoutineCycle>;
  @useResult
  $Res call(
      {DateTime startDate, List<RoutineWeek> weeks, String goalDescriptive});
}

/// @nodoc
class _$RoutineCycleCopyWithImpl<$Res, $Val extends RoutineCycle>
    implements $RoutineCycleCopyWith<$Res> {
  _$RoutineCycleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startDate = null,
    Object? weeks = null,
    Object? goalDescriptive = null,
  }) {
    return _then(_value.copyWith(
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      weeks: null == weeks
          ? _value.weeks
          : weeks // ignore: cast_nullable_to_non_nullable
              as List<RoutineWeek>,
      goalDescriptive: null == goalDescriptive
          ? _value.goalDescriptive
          : goalDescriptive // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoutineCycleImplCopyWith<$Res>
    implements $RoutineCycleCopyWith<$Res> {
  factory _$$RoutineCycleImplCopyWith(
          _$RoutineCycleImpl value, $Res Function(_$RoutineCycleImpl) then) =
      __$$RoutineCycleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime startDate, List<RoutineWeek> weeks, String goalDescriptive});
}

/// @nodoc
class __$$RoutineCycleImplCopyWithImpl<$Res>
    extends _$RoutineCycleCopyWithImpl<$Res, _$RoutineCycleImpl>
    implements _$$RoutineCycleImplCopyWith<$Res> {
  __$$RoutineCycleImplCopyWithImpl(
      _$RoutineCycleImpl _value, $Res Function(_$RoutineCycleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startDate = null,
    Object? weeks = null,
    Object? goalDescriptive = null,
  }) {
    return _then(_$RoutineCycleImpl(
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      weeks: null == weeks
          ? _value._weeks
          : weeks // ignore: cast_nullable_to_non_nullable
              as List<RoutineWeek>,
      goalDescriptive: null == goalDescriptive
          ? _value.goalDescriptive
          : goalDescriptive // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoutineCycleImpl implements _RoutineCycle {
  const _$RoutineCycleImpl(
      {required this.startDate,
      required final List<RoutineWeek> weeks,
      required this.goalDescriptive})
      : _weeks = weeks;

  factory _$RoutineCycleImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoutineCycleImplFromJson(json);

  @override
  final DateTime startDate;
  final List<RoutineWeek> _weeks;
  @override
  List<RoutineWeek> get weeks {
    if (_weeks is EqualUnmodifiableListView) return _weeks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weeks);
  }

  @override
  final String goalDescriptive;

  @override
  String toString() {
    return 'RoutineCycle(startDate: $startDate, weeks: $weeks, goalDescriptive: $goalDescriptive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoutineCycleImpl &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            const DeepCollectionEquality().equals(other._weeks, _weeks) &&
            (identical(other.goalDescriptive, goalDescriptive) ||
                other.goalDescriptive == goalDescriptive));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, startDate,
      const DeepCollectionEquality().hash(_weeks), goalDescriptive);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoutineCycleImplCopyWith<_$RoutineCycleImpl> get copyWith =>
      __$$RoutineCycleImplCopyWithImpl<_$RoutineCycleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoutineCycleImplToJson(
      this,
    );
  }
}

abstract class _RoutineCycle implements RoutineCycle {
  const factory _RoutineCycle(
      {required final DateTime startDate,
      required final List<RoutineWeek> weeks,
      required final String goalDescriptive}) = _$RoutineCycleImpl;

  factory _RoutineCycle.fromJson(Map<String, dynamic> json) =
      _$RoutineCycleImpl.fromJson;

  @override
  DateTime get startDate;
  @override
  List<RoutineWeek> get weeks;
  @override
  String get goalDescriptive;
  @override
  @JsonKey(ignore: true)
  _$$RoutineCycleImplCopyWith<_$RoutineCycleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoutineWeek _$RoutineWeekFromJson(Map<String, dynamic> json) {
  return _RoutineWeek.fromJson(json);
}

/// @nodoc
mixin _$RoutineWeek {
  int get weekNumber => throw _privateConstructorUsedError; // 1 through 8
  bool get isDeload =>
      throw _privateConstructorUsedError; // True if weekNumber == 5
  List<RoutineDay> get days => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoutineWeekCopyWith<RoutineWeek> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutineWeekCopyWith<$Res> {
  factory $RoutineWeekCopyWith(
          RoutineWeek value, $Res Function(RoutineWeek) then) =
      _$RoutineWeekCopyWithImpl<$Res, RoutineWeek>;
  @useResult
  $Res call({int weekNumber, bool isDeload, List<RoutineDay> days});
}

/// @nodoc
class _$RoutineWeekCopyWithImpl<$Res, $Val extends RoutineWeek>
    implements $RoutineWeekCopyWith<$Res> {
  _$RoutineWeekCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekNumber = null,
    Object? isDeload = null,
    Object? days = null,
  }) {
    return _then(_value.copyWith(
      weekNumber: null == weekNumber
          ? _value.weekNumber
          : weekNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _value.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<RoutineDay>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoutineWeekImplCopyWith<$Res>
    implements $RoutineWeekCopyWith<$Res> {
  factory _$$RoutineWeekImplCopyWith(
          _$RoutineWeekImpl value, $Res Function(_$RoutineWeekImpl) then) =
      __$$RoutineWeekImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int weekNumber, bool isDeload, List<RoutineDay> days});
}

/// @nodoc
class __$$RoutineWeekImplCopyWithImpl<$Res>
    extends _$RoutineWeekCopyWithImpl<$Res, _$RoutineWeekImpl>
    implements _$$RoutineWeekImplCopyWith<$Res> {
  __$$RoutineWeekImplCopyWithImpl(
      _$RoutineWeekImpl _value, $Res Function(_$RoutineWeekImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekNumber = null,
    Object? isDeload = null,
    Object? days = null,
  }) {
    return _then(_$RoutineWeekImpl(
      weekNumber: null == weekNumber
          ? _value.weekNumber
          : weekNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _value.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<RoutineDay>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoutineWeekImpl implements _RoutineWeek {
  const _$RoutineWeekImpl(
      {required this.weekNumber,
      this.isDeload = false,
      required final List<RoutineDay> days})
      : _days = days;

  factory _$RoutineWeekImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoutineWeekImplFromJson(json);

  @override
  final int weekNumber;
// 1 through 8
  @override
  @JsonKey()
  final bool isDeload;
// True if weekNumber == 5
  final List<RoutineDay> _days;
// True if weekNumber == 5
  @override
  List<RoutineDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  String toString() {
    return 'RoutineWeek(weekNumber: $weekNumber, isDeload: $isDeload, days: $days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoutineWeekImpl &&
            (identical(other.weekNumber, weekNumber) ||
                other.weekNumber == weekNumber) &&
            (identical(other.isDeload, isDeload) ||
                other.isDeload == isDeload) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, weekNumber, isDeload,
      const DeepCollectionEquality().hash(_days));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoutineWeekImplCopyWith<_$RoutineWeekImpl> get copyWith =>
      __$$RoutineWeekImplCopyWithImpl<_$RoutineWeekImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoutineWeekImplToJson(
      this,
    );
  }
}

abstract class _RoutineWeek implements RoutineWeek {
  const factory _RoutineWeek(
      {required final int weekNumber,
      final bool isDeload,
      required final List<RoutineDay> days}) = _$RoutineWeekImpl;

  factory _RoutineWeek.fromJson(Map<String, dynamic> json) =
      _$RoutineWeekImpl.fromJson;

  @override
  int get weekNumber;
  @override // 1 through 8
  bool get isDeload;
  @override // True if weekNumber == 5
  List<RoutineDay> get days;
  @override
  @JsonKey(ignore: true)
  _$$RoutineWeekImplCopyWith<_$RoutineWeekImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoutineDay _$RoutineDayFromJson(Map<String, dynamic> json) {
  return _RoutineDay.fromJson(json);
}

/// @nodoc
mixin _$RoutineDay {
  int get dayNumber => throw _privateConstructorUsedError; // 1 through 7
  bool get isRestDay => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // "Full Body", "Cardio Zona 2", "Descanso Activo"
  String get description => throw _privateConstructorUsedError;
  List<RoutineExercise> get exercises => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoutineDayCopyWith<RoutineDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutineDayCopyWith<$Res> {
  factory $RoutineDayCopyWith(
          RoutineDay value, $Res Function(RoutineDay) then) =
      _$RoutineDayCopyWithImpl<$Res, RoutineDay>;
  @useResult
  $Res call(
      {int dayNumber,
      bool isRestDay,
      String type,
      String description,
      List<RoutineExercise> exercises});
}

/// @nodoc
class _$RoutineDayCopyWithImpl<$Res, $Val extends RoutineDay>
    implements $RoutineDayCopyWith<$Res> {
  _$RoutineDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? isRestDay = null,
    Object? type = null,
    Object? description = null,
    Object? exercises = null,
  }) {
    return _then(_value.copyWith(
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isRestDay: null == isRestDay
          ? _value.isRestDay
          : isRestDay // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoutineDayImplCopyWith<$Res>
    implements $RoutineDayCopyWith<$Res> {
  factory _$$RoutineDayImplCopyWith(
          _$RoutineDayImpl value, $Res Function(_$RoutineDayImpl) then) =
      __$$RoutineDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int dayNumber,
      bool isRestDay,
      String type,
      String description,
      List<RoutineExercise> exercises});
}

/// @nodoc
class __$$RoutineDayImplCopyWithImpl<$Res>
    extends _$RoutineDayCopyWithImpl<$Res, _$RoutineDayImpl>
    implements _$$RoutineDayImplCopyWith<$Res> {
  __$$RoutineDayImplCopyWithImpl(
      _$RoutineDayImpl _value, $Res Function(_$RoutineDayImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? isRestDay = null,
    Object? type = null,
    Object? description = null,
    Object? exercises = null,
  }) {
    return _then(_$RoutineDayImpl(
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isRestDay: null == isRestDay
          ? _value.isRestDay
          : isRestDay // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoutineDayImpl implements _RoutineDay {
  const _$RoutineDayImpl(
      {required this.dayNumber,
      required this.isRestDay,
      this.type = 'Descanso',
      this.description = '',
      final List<RoutineExercise> exercises = const []})
      : _exercises = exercises;

  factory _$RoutineDayImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoutineDayImplFromJson(json);

  @override
  final int dayNumber;
// 1 through 7
  @override
  final bool isRestDay;
  @override
  @JsonKey()
  final String type;
// "Full Body", "Cardio Zona 2", "Descanso Activo"
  @override
  @JsonKey()
  final String description;
  final List<RoutineExercise> _exercises;
  @override
  @JsonKey()
  List<RoutineExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'RoutineDay(dayNumber: $dayNumber, isRestDay: $isRestDay, type: $type, description: $description, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoutineDayImpl &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.isRestDay, isRestDay) ||
                other.isRestDay == isRestDay) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, dayNumber, isRestDay, type,
      description, const DeepCollectionEquality().hash(_exercises));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoutineDayImplCopyWith<_$RoutineDayImpl> get copyWith =>
      __$$RoutineDayImplCopyWithImpl<_$RoutineDayImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoutineDayImplToJson(
      this,
    );
  }
}

abstract class _RoutineDay implements RoutineDay {
  const factory _RoutineDay(
      {required final int dayNumber,
      required final bool isRestDay,
      final String type,
      final String description,
      final List<RoutineExercise> exercises}) = _$RoutineDayImpl;

  factory _RoutineDay.fromJson(Map<String, dynamic> json) =
      _$RoutineDayImpl.fromJson;

  @override
  int get dayNumber;
  @override // 1 through 7
  bool get isRestDay;
  @override
  String get type;
  @override // "Full Body", "Cardio Zona 2", "Descanso Activo"
  String get description;
  @override
  List<RoutineExercise> get exercises;
  @override
  @JsonKey(ignore: true)
  _$$RoutineDayImplCopyWith<_$RoutineDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
