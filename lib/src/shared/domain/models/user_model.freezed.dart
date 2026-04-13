// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get age => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  double get weight => throw _privateConstructorUsedError;
  double get height =>
      throw _privateConstructorUsedError; // --- Biometría (cm) ---
  double? get waistCircumference => throw _privateConstructorUsedError;
  double? get neckCircumference => throw _privateConstructorUsedError;
  double get bodyFatPercentage =>
      throw _privateConstructorUsedError; // --- Inferencia ---
  int get pantSize => throw _privateConstructorUsedError;
  String get shirtSize => throw _privateConstructorUsedError;
  bool get isMeasurementEstimated => throw _privateConstructorUsedError;
  double get imrStdDev => throw _privateConstructorUsedError;
  String get confidenceLevel =>
      throw _privateConstructorUsedError; // --- Hábitos Metabólicos (NUEVOS CAMPOS) ---
  int get mealsPerDay => throw _privateConstructorUsedError;
  String get fastingProtocol => throw _privateConstructorUsedError;
  List<String> get pathologies => throw _privateConstructorUsedError;
  double get activityLevel => throw _privateConstructorUsedError;
  CircadianProfile get profile => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      int age,
      String gender,
      double weight,
      double height,
      double? waistCircumference,
      double? neckCircumference,
      double bodyFatPercentage,
      int pantSize,
      String shirtSize,
      bool isMeasurementEstimated,
      double imrStdDev,
      String confidenceLevel,
      int mealsPerDay,
      String fastingProtocol,
      List<String> pathologies,
      double activityLevel,
      CircadianProfile profile});

  $CircadianProfileCopyWith<$Res> get profile;
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? age = null,
    Object? gender = null,
    Object? weight = null,
    Object? height = null,
    Object? waistCircumference = freezed,
    Object? neckCircumference = freezed,
    Object? bodyFatPercentage = null,
    Object? pantSize = null,
    Object? shirtSize = null,
    Object? isMeasurementEstimated = null,
    Object? imrStdDev = null,
    Object? confidenceLevel = null,
    Object? mealsPerDay = null,
    Object? fastingProtocol = null,
    Object? pathologies = null,
    Object? activityLevel = null,
    Object? profile = null,
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
      age: null == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumference: freezed == waistCircumference
          ? _value.waistCircumference
          : waistCircumference // ignore: cast_nullable_to_non_nullable
              as double?,
      neckCircumference: freezed == neckCircumference
          ? _value.neckCircumference
          : neckCircumference // ignore: cast_nullable_to_non_nullable
              as double?,
      bodyFatPercentage: null == bodyFatPercentage
          ? _value.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      pantSize: null == pantSize
          ? _value.pantSize
          : pantSize // ignore: cast_nullable_to_non_nullable
              as int,
      shirtSize: null == shirtSize
          ? _value.shirtSize
          : shirtSize // ignore: cast_nullable_to_non_nullable
              as String,
      isMeasurementEstimated: null == isMeasurementEstimated
          ? _value.isMeasurementEstimated
          : isMeasurementEstimated // ignore: cast_nullable_to_non_nullable
              as bool,
      imrStdDev: null == imrStdDev
          ? _value.imrStdDev
          : imrStdDev // ignore: cast_nullable_to_non_nullable
              as double,
      confidenceLevel: null == confidenceLevel
          ? _value.confidenceLevel
          : confidenceLevel // ignore: cast_nullable_to_non_nullable
              as String,
      mealsPerDay: null == mealsPerDay
          ? _value.mealsPerDay
          : mealsPerDay // ignore: cast_nullable_to_non_nullable
              as int,
      fastingProtocol: null == fastingProtocol
          ? _value.fastingProtocol
          : fastingProtocol // ignore: cast_nullable_to_non_nullable
              as String,
      pathologies: null == pathologies
          ? _value.pathologies
          : pathologies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as double,
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as CircadianProfile,
    ) as $Val);
  }

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CircadianProfileCopyWith<$Res> get profile {
    return $CircadianProfileCopyWith<$Res>(_value.profile, (value) {
      return _then(_value.copyWith(profile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int age,
      String gender,
      double weight,
      double height,
      double? waistCircumference,
      double? neckCircumference,
      double bodyFatPercentage,
      int pantSize,
      String shirtSize,
      bool isMeasurementEstimated,
      double imrStdDev,
      String confidenceLevel,
      int mealsPerDay,
      String fastingProtocol,
      List<String> pathologies,
      double activityLevel,
      CircadianProfile profile});

  @override
  $CircadianProfileCopyWith<$Res> get profile;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? age = null,
    Object? gender = null,
    Object? weight = null,
    Object? height = null,
    Object? waistCircumference = freezed,
    Object? neckCircumference = freezed,
    Object? bodyFatPercentage = null,
    Object? pantSize = null,
    Object? shirtSize = null,
    Object? isMeasurementEstimated = null,
    Object? imrStdDev = null,
    Object? confidenceLevel = null,
    Object? mealsPerDay = null,
    Object? fastingProtocol = null,
    Object? pathologies = null,
    Object? activityLevel = null,
    Object? profile = null,
  }) {
    return _then(_$UserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      age: null == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumference: freezed == waistCircumference
          ? _value.waistCircumference
          : waistCircumference // ignore: cast_nullable_to_non_nullable
              as double?,
      neckCircumference: freezed == neckCircumference
          ? _value.neckCircumference
          : neckCircumference // ignore: cast_nullable_to_non_nullable
              as double?,
      bodyFatPercentage: null == bodyFatPercentage
          ? _value.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      pantSize: null == pantSize
          ? _value.pantSize
          : pantSize // ignore: cast_nullable_to_non_nullable
              as int,
      shirtSize: null == shirtSize
          ? _value.shirtSize
          : shirtSize // ignore: cast_nullable_to_non_nullable
              as String,
      isMeasurementEstimated: null == isMeasurementEstimated
          ? _value.isMeasurementEstimated
          : isMeasurementEstimated // ignore: cast_nullable_to_non_nullable
              as bool,
      imrStdDev: null == imrStdDev
          ? _value.imrStdDev
          : imrStdDev // ignore: cast_nullable_to_non_nullable
              as double,
      confidenceLevel: null == confidenceLevel
          ? _value.confidenceLevel
          : confidenceLevel // ignore: cast_nullable_to_non_nullable
              as String,
      mealsPerDay: null == mealsPerDay
          ? _value.mealsPerDay
          : mealsPerDay // ignore: cast_nullable_to_non_nullable
              as int,
      fastingProtocol: null == fastingProtocol
          ? _value.fastingProtocol
          : fastingProtocol // ignore: cast_nullable_to_non_nullable
              as String,
      pathologies: null == pathologies
          ? _value._pathologies
          : pathologies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as double,
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as CircadianProfile,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {this.id = '',
      this.name = 'Usuario',
      required this.age,
      required this.gender,
      required this.weight,
      required this.height,
      this.waistCircumference,
      this.neckCircumference,
      this.bodyFatPercentage = 20.0,
      this.pantSize = 30,
      this.shirtSize = 'M',
      this.isMeasurementEstimated = true,
      this.imrStdDev = 0.0,
      this.confidenceLevel = 'BAJA',
      this.mealsPerDay = 3,
      this.fastingProtocol = 'Ninguno',
      final List<String> pathologies = const ['Ninguna'],
      this.activityLevel = 1.2,
      required this.profile})
      : _pathologies = pathologies;

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  final int age;
  @override
  final String gender;
  @override
  final double weight;
  @override
  final double height;
// --- Biometría (cm) ---
  @override
  final double? waistCircumference;
  @override
  final double? neckCircumference;
  @override
  @JsonKey()
  final double bodyFatPercentage;
// --- Inferencia ---
  @override
  @JsonKey()
  final int pantSize;
  @override
  @JsonKey()
  final String shirtSize;
  @override
  @JsonKey()
  final bool isMeasurementEstimated;
  @override
  @JsonKey()
  final double imrStdDev;
  @override
  @JsonKey()
  final String confidenceLevel;
// --- Hábitos Metabólicos (NUEVOS CAMPOS) ---
  @override
  @JsonKey()
  final int mealsPerDay;
  @override
  @JsonKey()
  final String fastingProtocol;
  final List<String> _pathologies;
  @override
  @JsonKey()
  List<String> get pathologies {
    if (_pathologies is EqualUnmodifiableListView) return _pathologies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pathologies);
  }

  @override
  @JsonKey()
  final double activityLevel;
  @override
  final CircadianProfile profile;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, age: $age, gender: $gender, weight: $weight, height: $height, waistCircumference: $waistCircumference, neckCircumference: $neckCircumference, bodyFatPercentage: $bodyFatPercentage, pantSize: $pantSize, shirtSize: $shirtSize, isMeasurementEstimated: $isMeasurementEstimated, imrStdDev: $imrStdDev, confidenceLevel: $confidenceLevel, mealsPerDay: $mealsPerDay, fastingProtocol: $fastingProtocol, pathologies: $pathologies, activityLevel: $activityLevel, profile: $profile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.waistCircumference, waistCircumference) ||
                other.waistCircumference == waistCircumference) &&
            (identical(other.neckCircumference, neckCircumference) ||
                other.neckCircumference == neckCircumference) &&
            (identical(other.bodyFatPercentage, bodyFatPercentage) ||
                other.bodyFatPercentage == bodyFatPercentage) &&
            (identical(other.pantSize, pantSize) ||
                other.pantSize == pantSize) &&
            (identical(other.shirtSize, shirtSize) ||
                other.shirtSize == shirtSize) &&
            (identical(other.isMeasurementEstimated, isMeasurementEstimated) ||
                other.isMeasurementEstimated == isMeasurementEstimated) &&
            (identical(other.imrStdDev, imrStdDev) ||
                other.imrStdDev == imrStdDev) &&
            (identical(other.confidenceLevel, confidenceLevel) ||
                other.confidenceLevel == confidenceLevel) &&
            (identical(other.mealsPerDay, mealsPerDay) ||
                other.mealsPerDay == mealsPerDay) &&
            (identical(other.fastingProtocol, fastingProtocol) ||
                other.fastingProtocol == fastingProtocol) &&
            const DeepCollectionEquality()
                .equals(other._pathologies, _pathologies) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            (identical(other.profile, profile) || other.profile == profile));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        age,
        gender,
        weight,
        height,
        waistCircumference,
        neckCircumference,
        bodyFatPercentage,
        pantSize,
        shirtSize,
        isMeasurementEstimated,
        imrStdDev,
        confidenceLevel,
        mealsPerDay,
        fastingProtocol,
        const DeepCollectionEquality().hash(_pathologies),
        activityLevel,
        profile
      ]);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {final String id,
      final String name,
      required final int age,
      required final String gender,
      required final double weight,
      required final double height,
      final double? waistCircumference,
      final double? neckCircumference,
      final double bodyFatPercentage,
      final int pantSize,
      final String shirtSize,
      final bool isMeasurementEstimated,
      final double imrStdDev,
      final String confidenceLevel,
      final int mealsPerDay,
      final String fastingProtocol,
      final List<String> pathologies,
      final double activityLevel,
      required final CircadianProfile profile}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get age;
  @override
  String get gender;
  @override
  double get weight;
  @override
  double get height; // --- Biometría (cm) ---
  @override
  double? get waistCircumference;
  @override
  double? get neckCircumference;
  @override
  double get bodyFatPercentage; // --- Inferencia ---
  @override
  int get pantSize;
  @override
  String get shirtSize;
  @override
  bool get isMeasurementEstimated;
  @override
  double get imrStdDev;
  @override
  String get confidenceLevel; // --- Hábitos Metabólicos (NUEVOS CAMPOS) ---
  @override
  int get mealsPerDay;
  @override
  String get fastingProtocol;
  @override
  List<String> get pathologies;
  @override
  double get activityLevel;
  @override
  CircadianProfile get profile;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CircadianProfile _$CircadianProfileFromJson(Map<String, dynamic> json) {
  return _CircadianProfile.fromJson(json);
}

/// @nodoc
mixin _$CircadianProfile {
  DateTime get wakeUpTime => throw _privateConstructorUsedError;
  DateTime get sleepTime => throw _privateConstructorUsedError;
  DateTime? get firstMealGoal => throw _privateConstructorUsedError;
  DateTime? get lastMealGoal => throw _privateConstructorUsedError;

  /// Serializes this CircadianProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CircadianProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CircadianProfileCopyWith<CircadianProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CircadianProfileCopyWith<$Res> {
  factory $CircadianProfileCopyWith(
          CircadianProfile value, $Res Function(CircadianProfile) then) =
      _$CircadianProfileCopyWithImpl<$Res, CircadianProfile>;
  @useResult
  $Res call(
      {DateTime wakeUpTime,
      DateTime sleepTime,
      DateTime? firstMealGoal,
      DateTime? lastMealGoal});
}

/// @nodoc
class _$CircadianProfileCopyWithImpl<$Res, $Val extends CircadianProfile>
    implements $CircadianProfileCopyWith<$Res> {
  _$CircadianProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CircadianProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wakeUpTime = null,
    Object? sleepTime = null,
    Object? firstMealGoal = freezed,
    Object? lastMealGoal = freezed,
  }) {
    return _then(_value.copyWith(
      wakeUpTime: null == wakeUpTime
          ? _value.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sleepTime: null == sleepTime
          ? _value.sleepTime
          : sleepTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      firstMealGoal: freezed == firstMealGoal
          ? _value.firstMealGoal
          : firstMealGoal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMealGoal: freezed == lastMealGoal
          ? _value.lastMealGoal
          : lastMealGoal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CircadianProfileImplCopyWith<$Res>
    implements $CircadianProfileCopyWith<$Res> {
  factory _$$CircadianProfileImplCopyWith(_$CircadianProfileImpl value,
          $Res Function(_$CircadianProfileImpl) then) =
      __$$CircadianProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime wakeUpTime,
      DateTime sleepTime,
      DateTime? firstMealGoal,
      DateTime? lastMealGoal});
}

/// @nodoc
class __$$CircadianProfileImplCopyWithImpl<$Res>
    extends _$CircadianProfileCopyWithImpl<$Res, _$CircadianProfileImpl>
    implements _$$CircadianProfileImplCopyWith<$Res> {
  __$$CircadianProfileImplCopyWithImpl(_$CircadianProfileImpl _value,
      $Res Function(_$CircadianProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of CircadianProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wakeUpTime = null,
    Object? sleepTime = null,
    Object? firstMealGoal = freezed,
    Object? lastMealGoal = freezed,
  }) {
    return _then(_$CircadianProfileImpl(
      wakeUpTime: null == wakeUpTime
          ? _value.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sleepTime: null == sleepTime
          ? _value.sleepTime
          : sleepTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      firstMealGoal: freezed == firstMealGoal
          ? _value.firstMealGoal
          : firstMealGoal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMealGoal: freezed == lastMealGoal
          ? _value.lastMealGoal
          : lastMealGoal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CircadianProfileImpl implements _CircadianProfile {
  const _$CircadianProfileImpl(
      {required this.wakeUpTime,
      required this.sleepTime,
      this.firstMealGoal,
      this.lastMealGoal});

  factory _$CircadianProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$CircadianProfileImplFromJson(json);

  @override
  final DateTime wakeUpTime;
  @override
  final DateTime sleepTime;
  @override
  final DateTime? firstMealGoal;
  @override
  final DateTime? lastMealGoal;

  @override
  String toString() {
    return 'CircadianProfile(wakeUpTime: $wakeUpTime, sleepTime: $sleepTime, firstMealGoal: $firstMealGoal, lastMealGoal: $lastMealGoal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CircadianProfileImpl &&
            (identical(other.wakeUpTime, wakeUpTime) ||
                other.wakeUpTime == wakeUpTime) &&
            (identical(other.sleepTime, sleepTime) ||
                other.sleepTime == sleepTime) &&
            (identical(other.firstMealGoal, firstMealGoal) ||
                other.firstMealGoal == firstMealGoal) &&
            (identical(other.lastMealGoal, lastMealGoal) ||
                other.lastMealGoal == lastMealGoal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, wakeUpTime, sleepTime, firstMealGoal, lastMealGoal);

  /// Create a copy of CircadianProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CircadianProfileImplCopyWith<_$CircadianProfileImpl> get copyWith =>
      __$$CircadianProfileImplCopyWithImpl<_$CircadianProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CircadianProfileImplToJson(
      this,
    );
  }
}

abstract class _CircadianProfile implements CircadianProfile {
  const factory _CircadianProfile(
      {required final DateTime wakeUpTime,
      required final DateTime sleepTime,
      final DateTime? firstMealGoal,
      final DateTime? lastMealGoal}) = _$CircadianProfileImpl;

  factory _CircadianProfile.fromJson(Map<String, dynamic> json) =
      _$CircadianProfileImpl.fromJson;

  @override
  DateTime get wakeUpTime;
  @override
  DateTime get sleepTime;
  @override
  DateTime? get firstMealGoal;
  @override
  DateTime? get lastMealGoal;

  /// Create a copy of CircadianProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CircadianProfileImplCopyWith<_$CircadianProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
