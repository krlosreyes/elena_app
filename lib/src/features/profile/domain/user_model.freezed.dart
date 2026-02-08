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
// 1. Identificación
  String get uid => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  Gender get gender => throw _privateConstructorUsedError;
  DateTime get birthDate =>
      throw _privateConstructorUsedError; // 2. Antropometría
  double get heightCm => throw _privateConstructorUsedError;
  double get currentWeightKg => throw _privateConstructorUsedError;
  double get waistCircumferenceCm => throw _privateConstructorUsedError;
  double get neckCircumferenceCm => throw _privateConstructorUsedError;
  double? get hipCircumferenceCm =>
      throw _privateConstructorUsedError; // 3. Perfil Clínico & Hábitos
  List<String> get pathologies => throw _privateConstructorUsedError;
  ActivityLevel get activityLevel => throw _privateConstructorUsedError;
  List<String> get physicalLimitations => throw _privateConstructorUsedError;
  SnackingHabit get snackingHabit => throw _privateConstructorUsedError;
  DietaryPreference get dietaryPreference =>
      throw _privateConstructorUsedError; // 4. Cronobiología (Guardado como String 'HH:mm')
  String get wakeUpTime => throw _privateConstructorUsedError;
  String get bedTime => throw _privateConstructorUsedError;
  String get usualFirstMealTime => throw _privateConstructorUsedError;
  String get usualLastMealTime =>
      throw _privateConstructorUsedError; // 5. Estado del Ayuno (Calculado)
  FastingExperience get fastingExperience => throw _privateConstructorUsedError;
  String? get recommendedProtocol => throw _privateConstructorUsedError;
  HealthGoal? get healthGoal =>
      throw _privateConstructorUsedError; // Configuración
  int? get checkInDay =>
      throw _privateConstructorUsedError; // 1 = Lunes, 7 = Domingo
// Metadata
  bool get onboardingCompleted => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String uid,
      String email,
      String displayName,
      String? photoUrl,
      Gender gender,
      DateTime birthDate,
      double heightCm,
      double currentWeightKg,
      double waistCircumferenceCm,
      double neckCircumferenceCm,
      double? hipCircumferenceCm,
      List<String> pathologies,
      ActivityLevel activityLevel,
      List<String> physicalLimitations,
      SnackingHabit snackingHabit,
      DietaryPreference dietaryPreference,
      String wakeUpTime,
      String bedTime,
      String usualFirstMealTime,
      String usualLastMealTime,
      FastingExperience fastingExperience,
      String? recommendedProtocol,
      HealthGoal? healthGoal,
      int? checkInDay,
      bool onboardingCompleted,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? displayName = null,
    Object? photoUrl = freezed,
    Object? gender = null,
    Object? birthDate = null,
    Object? heightCm = null,
    Object? currentWeightKg = null,
    Object? waistCircumferenceCm = null,
    Object? neckCircumferenceCm = null,
    Object? hipCircumferenceCm = freezed,
    Object? pathologies = null,
    Object? activityLevel = null,
    Object? physicalLimitations = null,
    Object? snackingHabit = null,
    Object? dietaryPreference = null,
    Object? wakeUpTime = null,
    Object? bedTime = null,
    Object? usualFirstMealTime = null,
    Object? usualLastMealTime = null,
    Object? fastingExperience = null,
    Object? recommendedProtocol = freezed,
    Object? healthGoal = freezed,
    Object? checkInDay = freezed,
    Object? onboardingCompleted = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      heightCm: null == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _value.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: null == waistCircumferenceCm
          ? _value.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double,
      neckCircumferenceCm: null == neckCircumferenceCm
          ? _value.neckCircumferenceCm
          : neckCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double,
      hipCircumferenceCm: freezed == hipCircumferenceCm
          ? _value.hipCircumferenceCm
          : hipCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      pathologies: null == pathologies
          ? _value.pathologies
          : pathologies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      physicalLimitations: null == physicalLimitations
          ? _value.physicalLimitations
          : physicalLimitations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      snackingHabit: null == snackingHabit
          ? _value.snackingHabit
          : snackingHabit // ignore: cast_nullable_to_non_nullable
              as SnackingHabit,
      dietaryPreference: null == dietaryPreference
          ? _value.dietaryPreference
          : dietaryPreference // ignore: cast_nullable_to_non_nullable
              as DietaryPreference,
      wakeUpTime: null == wakeUpTime
          ? _value.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as String,
      bedTime: null == bedTime
          ? _value.bedTime
          : bedTime // ignore: cast_nullable_to_non_nullable
              as String,
      usualFirstMealTime: null == usualFirstMealTime
          ? _value.usualFirstMealTime
          : usualFirstMealTime // ignore: cast_nullable_to_non_nullable
              as String,
      usualLastMealTime: null == usualLastMealTime
          ? _value.usualLastMealTime
          : usualLastMealTime // ignore: cast_nullable_to_non_nullable
              as String,
      fastingExperience: null == fastingExperience
          ? _value.fastingExperience
          : fastingExperience // ignore: cast_nullable_to_non_nullable
              as FastingExperience,
      recommendedProtocol: freezed == recommendedProtocol
          ? _value.recommendedProtocol
          : recommendedProtocol // ignore: cast_nullable_to_non_nullable
              as String?,
      healthGoal: freezed == healthGoal
          ? _value.healthGoal
          : healthGoal // ignore: cast_nullable_to_non_nullable
              as HealthGoal?,
      checkInDay: freezed == checkInDay
          ? _value.checkInDay
          : checkInDay // ignore: cast_nullable_to_non_nullable
              as int?,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
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
      {String uid,
      String email,
      String displayName,
      String? photoUrl,
      Gender gender,
      DateTime birthDate,
      double heightCm,
      double currentWeightKg,
      double waistCircumferenceCm,
      double neckCircumferenceCm,
      double? hipCircumferenceCm,
      List<String> pathologies,
      ActivityLevel activityLevel,
      List<String> physicalLimitations,
      SnackingHabit snackingHabit,
      DietaryPreference dietaryPreference,
      String wakeUpTime,
      String bedTime,
      String usualFirstMealTime,
      String usualLastMealTime,
      FastingExperience fastingExperience,
      String? recommendedProtocol,
      HealthGoal? healthGoal,
      int? checkInDay,
      bool onboardingCompleted,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? displayName = null,
    Object? photoUrl = freezed,
    Object? gender = null,
    Object? birthDate = null,
    Object? heightCm = null,
    Object? currentWeightKg = null,
    Object? waistCircumferenceCm = null,
    Object? neckCircumferenceCm = null,
    Object? hipCircumferenceCm = freezed,
    Object? pathologies = null,
    Object? activityLevel = null,
    Object? physicalLimitations = null,
    Object? snackingHabit = null,
    Object? dietaryPreference = null,
    Object? wakeUpTime = null,
    Object? bedTime = null,
    Object? usualFirstMealTime = null,
    Object? usualLastMealTime = null,
    Object? fastingExperience = null,
    Object? recommendedProtocol = freezed,
    Object? healthGoal = freezed,
    Object? checkInDay = freezed,
    Object? onboardingCompleted = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$UserModelImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      heightCm: null == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _value.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: null == waistCircumferenceCm
          ? _value.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double,
      neckCircumferenceCm: null == neckCircumferenceCm
          ? _value.neckCircumferenceCm
          : neckCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double,
      hipCircumferenceCm: freezed == hipCircumferenceCm
          ? _value.hipCircumferenceCm
          : hipCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      pathologies: null == pathologies
          ? _value._pathologies
          : pathologies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      physicalLimitations: null == physicalLimitations
          ? _value._physicalLimitations
          : physicalLimitations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      snackingHabit: null == snackingHabit
          ? _value.snackingHabit
          : snackingHabit // ignore: cast_nullable_to_non_nullable
              as SnackingHabit,
      dietaryPreference: null == dietaryPreference
          ? _value.dietaryPreference
          : dietaryPreference // ignore: cast_nullable_to_non_nullable
              as DietaryPreference,
      wakeUpTime: null == wakeUpTime
          ? _value.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as String,
      bedTime: null == bedTime
          ? _value.bedTime
          : bedTime // ignore: cast_nullable_to_non_nullable
              as String,
      usualFirstMealTime: null == usualFirstMealTime
          ? _value.usualFirstMealTime
          : usualFirstMealTime // ignore: cast_nullable_to_non_nullable
              as String,
      usualLastMealTime: null == usualLastMealTime
          ? _value.usualLastMealTime
          : usualLastMealTime // ignore: cast_nullable_to_non_nullable
              as String,
      fastingExperience: null == fastingExperience
          ? _value.fastingExperience
          : fastingExperience // ignore: cast_nullable_to_non_nullable
              as FastingExperience,
      recommendedProtocol: freezed == recommendedProtocol
          ? _value.recommendedProtocol
          : recommendedProtocol // ignore: cast_nullable_to_non_nullable
              as String?,
      healthGoal: freezed == healthGoal
          ? _value.healthGoal
          : healthGoal // ignore: cast_nullable_to_non_nullable
              as HealthGoal?,
      checkInDay: freezed == checkInDay
          ? _value.checkInDay
          : checkInDay // ignore: cast_nullable_to_non_nullable
              as int?,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.uid,
      required this.email,
      required this.displayName,
      this.photoUrl,
      required this.gender,
      required this.birthDate,
      required this.heightCm,
      required this.currentWeightKg,
      required this.waistCircumferenceCm,
      required this.neckCircumferenceCm,
      this.hipCircumferenceCm,
      final List<String> pathologies = const [],
      required this.activityLevel,
      final List<String> physicalLimitations = const [],
      required this.snackingHabit,
      required this.dietaryPreference,
      required this.wakeUpTime,
      required this.bedTime,
      required this.usualFirstMealTime,
      required this.usualLastMealTime,
      this.fastingExperience = FastingExperience.beginner,
      this.recommendedProtocol,
      this.healthGoal,
      this.checkInDay,
      this.onboardingCompleted = false,
      this.createdAt,
      this.updatedAt})
      : _pathologies = pathologies,
        _physicalLimitations = physicalLimitations;

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

// 1. Identificación
  @override
  final String uid;
  @override
  final String email;
  @override
  final String displayName;
  @override
  final String? photoUrl;
  @override
  final Gender gender;
  @override
  final DateTime birthDate;
// 2. Antropometría
  @override
  final double heightCm;
  @override
  final double currentWeightKg;
  @override
  final double waistCircumferenceCm;
  @override
  final double neckCircumferenceCm;
  @override
  final double? hipCircumferenceCm;
// 3. Perfil Clínico & Hábitos
  final List<String> _pathologies;
// 3. Perfil Clínico & Hábitos
  @override
  @JsonKey()
  List<String> get pathologies {
    if (_pathologies is EqualUnmodifiableListView) return _pathologies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pathologies);
  }

  @override
  final ActivityLevel activityLevel;
  final List<String> _physicalLimitations;
  @override
  @JsonKey()
  List<String> get physicalLimitations {
    if (_physicalLimitations is EqualUnmodifiableListView)
      return _physicalLimitations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_physicalLimitations);
  }

  @override
  final SnackingHabit snackingHabit;
  @override
  final DietaryPreference dietaryPreference;
// 4. Cronobiología (Guardado como String 'HH:mm')
  @override
  final String wakeUpTime;
  @override
  final String bedTime;
  @override
  final String usualFirstMealTime;
  @override
  final String usualLastMealTime;
// 5. Estado del Ayuno (Calculado)
  @override
  @JsonKey()
  final FastingExperience fastingExperience;
  @override
  final String? recommendedProtocol;
  @override
  final HealthGoal? healthGoal;
// Configuración
  @override
  final int? checkInDay;
// 1 = Lunes, 7 = Domingo
// Metadata
  @override
  @JsonKey()
  final bool onboardingCompleted;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, photoUrl: $photoUrl, gender: $gender, birthDate: $birthDate, heightCm: $heightCm, currentWeightKg: $currentWeightKg, waistCircumferenceCm: $waistCircumferenceCm, neckCircumferenceCm: $neckCircumferenceCm, hipCircumferenceCm: $hipCircumferenceCm, pathologies: $pathologies, activityLevel: $activityLevel, physicalLimitations: $physicalLimitations, snackingHabit: $snackingHabit, dietaryPreference: $dietaryPreference, wakeUpTime: $wakeUpTime, bedTime: $bedTime, usualFirstMealTime: $usualFirstMealTime, usualLastMealTime: $usualLastMealTime, fastingExperience: $fastingExperience, recommendedProtocol: $recommendedProtocol, healthGoal: $healthGoal, checkInDay: $checkInDay, onboardingCompleted: $onboardingCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.currentWeightKg, currentWeightKg) ||
                other.currentWeightKg == currentWeightKg) &&
            (identical(other.waistCircumferenceCm, waistCircumferenceCm) ||
                other.waistCircumferenceCm == waistCircumferenceCm) &&
            (identical(other.neckCircumferenceCm, neckCircumferenceCm) ||
                other.neckCircumferenceCm == neckCircumferenceCm) &&
            (identical(other.hipCircumferenceCm, hipCircumferenceCm) ||
                other.hipCircumferenceCm == hipCircumferenceCm) &&
            const DeepCollectionEquality()
                .equals(other._pathologies, _pathologies) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            const DeepCollectionEquality()
                .equals(other._physicalLimitations, _physicalLimitations) &&
            (identical(other.snackingHabit, snackingHabit) ||
                other.snackingHabit == snackingHabit) &&
            (identical(other.dietaryPreference, dietaryPreference) ||
                other.dietaryPreference == dietaryPreference) &&
            (identical(other.wakeUpTime, wakeUpTime) ||
                other.wakeUpTime == wakeUpTime) &&
            (identical(other.bedTime, bedTime) || other.bedTime == bedTime) &&
            (identical(other.usualFirstMealTime, usualFirstMealTime) ||
                other.usualFirstMealTime == usualFirstMealTime) &&
            (identical(other.usualLastMealTime, usualLastMealTime) ||
                other.usualLastMealTime == usualLastMealTime) &&
            (identical(other.fastingExperience, fastingExperience) ||
                other.fastingExperience == fastingExperience) &&
            (identical(other.recommendedProtocol, recommendedProtocol) ||
                other.recommendedProtocol == recommendedProtocol) &&
            (identical(other.healthGoal, healthGoal) ||
                other.healthGoal == healthGoal) &&
            (identical(other.checkInDay, checkInDay) ||
                other.checkInDay == checkInDay) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        uid,
        email,
        displayName,
        photoUrl,
        gender,
        birthDate,
        heightCm,
        currentWeightKg,
        waistCircumferenceCm,
        neckCircumferenceCm,
        hipCircumferenceCm,
        const DeepCollectionEquality().hash(_pathologies),
        activityLevel,
        const DeepCollectionEquality().hash(_physicalLimitations),
        snackingHabit,
        dietaryPreference,
        wakeUpTime,
        bedTime,
        usualFirstMealTime,
        usualLastMealTime,
        fastingExperience,
        recommendedProtocol,
        healthGoal,
        checkInDay,
        onboardingCompleted,
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
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
      {required final String uid,
      required final String email,
      required final String displayName,
      final String? photoUrl,
      required final Gender gender,
      required final DateTime birthDate,
      required final double heightCm,
      required final double currentWeightKg,
      required final double waistCircumferenceCm,
      required final double neckCircumferenceCm,
      final double? hipCircumferenceCm,
      final List<String> pathologies,
      required final ActivityLevel activityLevel,
      final List<String> physicalLimitations,
      required final SnackingHabit snackingHabit,
      required final DietaryPreference dietaryPreference,
      required final String wakeUpTime,
      required final String bedTime,
      required final String usualFirstMealTime,
      required final String usualLastMealTime,
      final FastingExperience fastingExperience,
      final String? recommendedProtocol,
      final HealthGoal? healthGoal,
      final int? checkInDay,
      final bool onboardingCompleted,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override // 1. Identificación
  String get uid;
  @override
  String get email;
  @override
  String get displayName;
  @override
  String? get photoUrl;
  @override
  Gender get gender;
  @override
  DateTime get birthDate;
  @override // 2. Antropometría
  double get heightCm;
  @override
  double get currentWeightKg;
  @override
  double get waistCircumferenceCm;
  @override
  double get neckCircumferenceCm;
  @override
  double? get hipCircumferenceCm;
  @override // 3. Perfil Clínico & Hábitos
  List<String> get pathologies;
  @override
  ActivityLevel get activityLevel;
  @override
  List<String> get physicalLimitations;
  @override
  SnackingHabit get snackingHabit;
  @override
  DietaryPreference get dietaryPreference;
  @override // 4. Cronobiología (Guardado como String 'HH:mm')
  String get wakeUpTime;
  @override
  String get bedTime;
  @override
  String get usualFirstMealTime;
  @override
  String get usualLastMealTime;
  @override // 5. Estado del Ayuno (Calculado)
  FastingExperience get fastingExperience;
  @override
  String? get recommendedProtocol;
  @override
  HealthGoal? get healthGoal;
  @override // Configuración
  int? get checkInDay;
  @override // 1 = Lunes, 7 = Domingo
// Metadata
  bool get onboardingCompleted;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
