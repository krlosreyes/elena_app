// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DailyLog _$DailyLogFromJson(Map<String, dynamic> json) {
  return _DailyLog.fromJson(json);
}

/// @nodoc
mixin _$DailyLog {
  String get id => throw _privateConstructorUsedError; // YYYY-MM-DD
  int get waterGlasses => throw _privateConstructorUsedError;
  int get calories => throw _privateConstructorUsedError;
  int get proteinGrams => throw _privateConstructorUsedError;
  int get carbsGrams => throw _privateConstructorUsedError;
  int get fatGrams => throw _privateConstructorUsedError;
  int get exerciseMinutes => throw _privateConstructorUsedError;
  int get sleepMinutes => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get fastingStartTime => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get fastingEndTime => throw _privateConstructorUsedError;
  double get mtiScore => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get mealEntries =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get exerciseEntries =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DailyLogCopyWith<DailyLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyLogCopyWith<$Res> {
  factory $DailyLogCopyWith(DailyLog value, $Res Function(DailyLog) then) =
      _$DailyLogCopyWithImpl<$Res, DailyLog>;
  @useResult
  $Res call(
      {String id,
      int waterGlasses,
      int calories,
      int proteinGrams,
      int carbsGrams,
      int fatGrams,
      int exerciseMinutes,
      int sleepMinutes,
      @OptionalTimestampConverter() DateTime? fastingStartTime,
      @OptionalTimestampConverter() DateTime? fastingEndTime,
      double mtiScore,
      List<Map<String, dynamic>> mealEntries,
      List<Map<String, dynamic>> exerciseEntries});
}

/// @nodoc
class _$DailyLogCopyWithImpl<$Res, $Val extends DailyLog>
    implements $DailyLogCopyWith<$Res> {
  _$DailyLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? waterGlasses = null,
    Object? calories = null,
    Object? proteinGrams = null,
    Object? carbsGrams = null,
    Object? fatGrams = null,
    Object? exerciseMinutes = null,
    Object? sleepMinutes = null,
    Object? fastingStartTime = freezed,
    Object? fastingEndTime = freezed,
    Object? mtiScore = null,
    Object? mealEntries = null,
    Object? exerciseEntries = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      waterGlasses: null == waterGlasses
          ? _value.waterGlasses
          : waterGlasses // ignore: cast_nullable_to_non_nullable
              as int,
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _value.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _value.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _value.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseMinutes: null == exerciseMinutes
          ? _value.exerciseMinutes
          : exerciseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      sleepMinutes: null == sleepMinutes
          ? _value.sleepMinutes
          : sleepMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      fastingStartTime: freezed == fastingStartTime
          ? _value.fastingStartTime
          : fastingStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fastingEndTime: freezed == fastingEndTime
          ? _value.fastingEndTime
          : fastingEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      mtiScore: null == mtiScore
          ? _value.mtiScore
          : mtiScore // ignore: cast_nullable_to_non_nullable
              as double,
      mealEntries: null == mealEntries
          ? _value.mealEntries
          : mealEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      exerciseEntries: null == exerciseEntries
          ? _value.exerciseEntries
          : exerciseEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyLogImplCopyWith<$Res>
    implements $DailyLogCopyWith<$Res> {
  factory _$$DailyLogImplCopyWith(
          _$DailyLogImpl value, $Res Function(_$DailyLogImpl) then) =
      __$$DailyLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int waterGlasses,
      int calories,
      int proteinGrams,
      int carbsGrams,
      int fatGrams,
      int exerciseMinutes,
      int sleepMinutes,
      @OptionalTimestampConverter() DateTime? fastingStartTime,
      @OptionalTimestampConverter() DateTime? fastingEndTime,
      double mtiScore,
      List<Map<String, dynamic>> mealEntries,
      List<Map<String, dynamic>> exerciseEntries});
}

/// @nodoc
class __$$DailyLogImplCopyWithImpl<$Res>
    extends _$DailyLogCopyWithImpl<$Res, _$DailyLogImpl>
    implements _$$DailyLogImplCopyWith<$Res> {
  __$$DailyLogImplCopyWithImpl(
      _$DailyLogImpl _value, $Res Function(_$DailyLogImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? waterGlasses = null,
    Object? calories = null,
    Object? proteinGrams = null,
    Object? carbsGrams = null,
    Object? fatGrams = null,
    Object? exerciseMinutes = null,
    Object? sleepMinutes = null,
    Object? fastingStartTime = freezed,
    Object? fastingEndTime = freezed,
    Object? mtiScore = null,
    Object? mealEntries = null,
    Object? exerciseEntries = null,
  }) {
    return _then(_$DailyLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      waterGlasses: null == waterGlasses
          ? _value.waterGlasses
          : waterGlasses // ignore: cast_nullable_to_non_nullable
              as int,
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _value.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _value.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _value.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseMinutes: null == exerciseMinutes
          ? _value.exerciseMinutes
          : exerciseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      sleepMinutes: null == sleepMinutes
          ? _value.sleepMinutes
          : sleepMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      fastingStartTime: freezed == fastingStartTime
          ? _value.fastingStartTime
          : fastingStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fastingEndTime: freezed == fastingEndTime
          ? _value.fastingEndTime
          : fastingEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      mtiScore: null == mtiScore
          ? _value.mtiScore
          : mtiScore // ignore: cast_nullable_to_non_nullable
              as double,
      mealEntries: null == mealEntries
          ? _value._mealEntries
          : mealEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      exerciseEntries: null == exerciseEntries
          ? _value._exerciseEntries
          : exerciseEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyLogImpl implements _DailyLog {
  const _$DailyLogImpl(
      {required this.id,
      this.waterGlasses = 0,
      this.calories = 0,
      this.proteinGrams = 0,
      this.carbsGrams = 0,
      this.fatGrams = 0,
      this.exerciseMinutes = 0,
      this.sleepMinutes = 0,
      @OptionalTimestampConverter() this.fastingStartTime,
      @OptionalTimestampConverter() this.fastingEndTime,
      this.mtiScore = 0.0,
      final List<Map<String, dynamic>> mealEntries = const [],
      final List<Map<String, dynamic>> exerciseEntries = const []})
      : _mealEntries = mealEntries,
        _exerciseEntries = exerciseEntries;

  factory _$DailyLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyLogImplFromJson(json);

  @override
  final String id;
// YYYY-MM-DD
  @override
  @JsonKey()
  final int waterGlasses;
  @override
  @JsonKey()
  final int calories;
  @override
  @JsonKey()
  final int proteinGrams;
  @override
  @JsonKey()
  final int carbsGrams;
  @override
  @JsonKey()
  final int fatGrams;
  @override
  @JsonKey()
  final int exerciseMinutes;
  @override
  @JsonKey()
  final int sleepMinutes;
  @override
  @OptionalTimestampConverter()
  final DateTime? fastingStartTime;
  @override
  @OptionalTimestampConverter()
  final DateTime? fastingEndTime;
  @override
  @JsonKey()
  final double mtiScore;
  final List<Map<String, dynamic>> _mealEntries;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get mealEntries {
    if (_mealEntries is EqualUnmodifiableListView) return _mealEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mealEntries);
  }

  final List<Map<String, dynamic>> _exerciseEntries;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get exerciseEntries {
    if (_exerciseEntries is EqualUnmodifiableListView) return _exerciseEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exerciseEntries);
  }

  @override
  String toString() {
    return 'DailyLog(id: $id, waterGlasses: $waterGlasses, calories: $calories, proteinGrams: $proteinGrams, carbsGrams: $carbsGrams, fatGrams: $fatGrams, exerciseMinutes: $exerciseMinutes, sleepMinutes: $sleepMinutes, fastingStartTime: $fastingStartTime, fastingEndTime: $fastingEndTime, mtiScore: $mtiScore, mealEntries: $mealEntries, exerciseEntries: $exerciseEntries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.waterGlasses, waterGlasses) ||
                other.waterGlasses == waterGlasses) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.proteinGrams, proteinGrams) ||
                other.proteinGrams == proteinGrams) &&
            (identical(other.carbsGrams, carbsGrams) ||
                other.carbsGrams == carbsGrams) &&
            (identical(other.fatGrams, fatGrams) ||
                other.fatGrams == fatGrams) &&
            (identical(other.exerciseMinutes, exerciseMinutes) ||
                other.exerciseMinutes == exerciseMinutes) &&
            (identical(other.sleepMinutes, sleepMinutes) ||
                other.sleepMinutes == sleepMinutes) &&
            (identical(other.fastingStartTime, fastingStartTime) ||
                other.fastingStartTime == fastingStartTime) &&
            (identical(other.fastingEndTime, fastingEndTime) ||
                other.fastingEndTime == fastingEndTime) &&
            (identical(other.mtiScore, mtiScore) ||
                other.mtiScore == mtiScore) &&
            const DeepCollectionEquality()
                .equals(other._mealEntries, _mealEntries) &&
            const DeepCollectionEquality()
                .equals(other._exerciseEntries, _exerciseEntries));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      waterGlasses,
      calories,
      proteinGrams,
      carbsGrams,
      fatGrams,
      exerciseMinutes,
      sleepMinutes,
      fastingStartTime,
      fastingEndTime,
      mtiScore,
      const DeepCollectionEquality().hash(_mealEntries),
      const DeepCollectionEquality().hash(_exerciseEntries));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyLogImplCopyWith<_$DailyLogImpl> get copyWith =>
      __$$DailyLogImplCopyWithImpl<_$DailyLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyLogImplToJson(
      this,
    );
  }
}

abstract class _DailyLog implements DailyLog {
  const factory _DailyLog(
      {required final String id,
      final int waterGlasses,
      final int calories,
      final int proteinGrams,
      final int carbsGrams,
      final int fatGrams,
      final int exerciseMinutes,
      final int sleepMinutes,
      @OptionalTimestampConverter() final DateTime? fastingStartTime,
      @OptionalTimestampConverter() final DateTime? fastingEndTime,
      final double mtiScore,
      final List<Map<String, dynamic>> mealEntries,
      final List<Map<String, dynamic>> exerciseEntries}) = _$DailyLogImpl;

  factory _DailyLog.fromJson(Map<String, dynamic> json) =
      _$DailyLogImpl.fromJson;

  @override
  String get id;
  @override // YYYY-MM-DD
  int get waterGlasses;
  @override
  int get calories;
  @override
  int get proteinGrams;
  @override
  int get carbsGrams;
  @override
  int get fatGrams;
  @override
  int get exerciseMinutes;
  @override
  int get sleepMinutes;
  @override
  @OptionalTimestampConverter()
  DateTime? get fastingStartTime;
  @override
  @OptionalTimestampConverter()
  DateTime? get fastingEndTime;
  @override
  double get mtiScore;
  @override
  List<Map<String, dynamic>> get mealEntries;
  @override
  List<Map<String, dynamic>> get exerciseEntries;
  @override
  @JsonKey(ignore: true)
  _$$DailyLogImplCopyWith<_$DailyLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
