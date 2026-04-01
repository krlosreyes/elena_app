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
  @JsonKey(readValue: _readName)
  String get name => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  Gender get gender => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get birthDate =>
      throw _privateConstructorUsedError; // 2. Antropometría
  double get heightCm => throw _privateConstructorUsedError;
  double get currentWeightKg => throw _privateConstructorUsedError;
  double? get waistCircumferenceCm => throw _privateConstructorUsedError;
  double? get neckCircumferenceCm => throw _privateConstructorUsedError;
  double? get hipCircumferenceCm =>
      throw _privateConstructorUsedError; // 3. Perfil Clínico & Hábitos
  List<String> get pathologies => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readActivityLevel)
  ActivityLevel get activityLevel => throw _privateConstructorUsedError;
  List<String> get physicalLimitations => throw _privateConstructorUsedError;
  SnackingHabit get snackingHabit => throw _privateConstructorUsedError;
  DietaryPreference get dietaryPreference => throw _privateConstructorUsedError;
  bool get hasDumbbells => throw _privateConstructorUsedError;
  List<int> get workoutDays => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get lastHighIntensityWorkoutAt =>
      throw _privateConstructorUsedError; // 4. Cronobiología
  String? get wakeUpTime =>
      throw _privateConstructorUsedError; // target_wake_time
  String? get bedTime =>
      throw _privateConstructorUsedError; // target_sleep_time
  String? get usualFirstMealTime => throw _privateConstructorUsedError;
  String? get usualLastMealTime =>
      throw _privateConstructorUsedError; // 5. Estado & Objetivos
  FastingExperience get fastingExperience => throw _privateConstructorUsedError;
  String? get recommendedProtocol => throw _privateConstructorUsedError;
  HealthGoal? get healthGoal =>
      throw _privateConstructorUsedError; // Goals & Progress
  double? get targetWeightKg => throw _privateConstructorUsedError;
  double? get startWeightKg => throw _privateConstructorUsedError;
  double? get targetFatPercentage => throw _privateConstructorUsedError;
  double? get targetLBM => throw _privateConstructorUsedError; // Configuración
  int? get checkInDay =>
      throw _privateConstructorUsedError; // IMX Specific Overrides
  double? get averageSleepHours => throw _privateConstructorUsedError;
  int? get energyLevel1To10 =>
      throw _privateConstructorUsedError; // Legacy / Calculated (Can be stored or calculated)
  double? get metaICA => throw _privateConstructorUsedError;
  double? get metaICC => throw _privateConstructorUsedError; // Metadata
  bool get onboardingCompleted => throw _privateConstructorUsedError;
  bool get hasCompletedTour => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @OptionalTimestampConverter()
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
      @JsonKey(readValue: _readName) String name,
      String? photoUrl,
      Gender gender,
      @OptionalTimestampConverter() DateTime? birthDate,
      double heightCm,
      double currentWeightKg,
      double? waistCircumferenceCm,
      double? neckCircumferenceCm,
      double? hipCircumferenceCm,
      List<String> pathologies,
      @JsonKey(readValue: _readActivityLevel) ActivityLevel activityLevel,
      List<String> physicalLimitations,
      SnackingHabit snackingHabit,
      DietaryPreference dietaryPreference,
      bool hasDumbbells,
      List<int> workoutDays,
      @OptionalTimestampConverter() DateTime? lastHighIntensityWorkoutAt,
      String? wakeUpTime,
      String? bedTime,
      String? usualFirstMealTime,
      String? usualLastMealTime,
      FastingExperience fastingExperience,
      String? recommendedProtocol,
      HealthGoal? healthGoal,
      double? targetWeightKg,
      double? startWeightKg,
      double? targetFatPercentage,
      double? targetLBM,
      int? checkInDay,
      double? averageSleepHours,
      int? energyLevel1To10,
      double? metaICA,
      double? metaICC,
      bool onboardingCompleted,
      bool hasCompletedTour,
      @OptionalTimestampConverter() DateTime? createdAt,
      @OptionalTimestampConverter() DateTime? updatedAt});
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
    Object? name = null,
    Object? photoUrl = freezed,
    Object? gender = null,
    Object? birthDate = freezed,
    Object? heightCm = null,
    Object? currentWeightKg = null,
    Object? waistCircumferenceCm = freezed,
    Object? neckCircumferenceCm = freezed,
    Object? hipCircumferenceCm = freezed,
    Object? pathologies = null,
    Object? activityLevel = null,
    Object? physicalLimitations = null,
    Object? snackingHabit = null,
    Object? dietaryPreference = null,
    Object? hasDumbbells = null,
    Object? workoutDays = null,
    Object? lastHighIntensityWorkoutAt = freezed,
    Object? wakeUpTime = freezed,
    Object? bedTime = freezed,
    Object? usualFirstMealTime = freezed,
    Object? usualLastMealTime = freezed,
    Object? fastingExperience = null,
    Object? recommendedProtocol = freezed,
    Object? healthGoal = freezed,
    Object? targetWeightKg = freezed,
    Object? startWeightKg = freezed,
    Object? targetFatPercentage = freezed,
    Object? targetLBM = freezed,
    Object? checkInDay = freezed,
    Object? averageSleepHours = freezed,
    Object? energyLevel1To10 = freezed,
    Object? metaICA = freezed,
    Object? metaICC = freezed,
    Object? onboardingCompleted = null,
    Object? hasCompletedTour = null,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      heightCm: null == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _value.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: freezed == waistCircumferenceCm
          ? _value.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      neckCircumferenceCm: freezed == neckCircumferenceCm
          ? _value.neckCircumferenceCm
          : neckCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
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
      hasDumbbells: null == hasDumbbells
          ? _value.hasDumbbells
          : hasDumbbells // ignore: cast_nullable_to_non_nullable
              as bool,
      workoutDays: null == workoutDays
          ? _value.workoutDays
          : workoutDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      lastHighIntensityWorkoutAt: freezed == lastHighIntensityWorkoutAt
          ? _value.lastHighIntensityWorkoutAt
          : lastHighIntensityWorkoutAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      wakeUpTime: freezed == wakeUpTime
          ? _value.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as String?,
      bedTime: freezed == bedTime
          ? _value.bedTime
          : bedTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualFirstMealTime: freezed == usualFirstMealTime
          ? _value.usualFirstMealTime
          : usualFirstMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualLastMealTime: freezed == usualLastMealTime
          ? _value.usualLastMealTime
          : usualLastMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
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
      targetWeightKg: freezed == targetWeightKg
          ? _value.targetWeightKg
          : targetWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      startWeightKg: freezed == startWeightKg
          ? _value.startWeightKg
          : startWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      targetFatPercentage: freezed == targetFatPercentage
          ? _value.targetFatPercentage
          : targetFatPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      targetLBM: freezed == targetLBM
          ? _value.targetLBM
          : targetLBM // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInDay: freezed == checkInDay
          ? _value.checkInDay
          : checkInDay // ignore: cast_nullable_to_non_nullable
              as int?,
      averageSleepHours: freezed == averageSleepHours
          ? _value.averageSleepHours
          : averageSleepHours // ignore: cast_nullable_to_non_nullable
              as double?,
      energyLevel1To10: freezed == energyLevel1To10
          ? _value.energyLevel1To10
          : energyLevel1To10 // ignore: cast_nullable_to_non_nullable
              as int?,
      metaICA: freezed == metaICA
          ? _value.metaICA
          : metaICA // ignore: cast_nullable_to_non_nullable
              as double?,
      metaICC: freezed == metaICC
          ? _value.metaICC
          : metaICC // ignore: cast_nullable_to_non_nullable
              as double?,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCompletedTour: null == hasCompletedTour
          ? _value.hasCompletedTour
          : hasCompletedTour // ignore: cast_nullable_to_non_nullable
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
      @JsonKey(readValue: _readName) String name,
      String? photoUrl,
      Gender gender,
      @OptionalTimestampConverter() DateTime? birthDate,
      double heightCm,
      double currentWeightKg,
      double? waistCircumferenceCm,
      double? neckCircumferenceCm,
      double? hipCircumferenceCm,
      List<String> pathologies,
      @JsonKey(readValue: _readActivityLevel) ActivityLevel activityLevel,
      List<String> physicalLimitations,
      SnackingHabit snackingHabit,
      DietaryPreference dietaryPreference,
      bool hasDumbbells,
      List<int> workoutDays,
      @OptionalTimestampConverter() DateTime? lastHighIntensityWorkoutAt,
      String? wakeUpTime,
      String? bedTime,
      String? usualFirstMealTime,
      String? usualLastMealTime,
      FastingExperience fastingExperience,
      String? recommendedProtocol,
      HealthGoal? healthGoal,
      double? targetWeightKg,
      double? startWeightKg,
      double? targetFatPercentage,
      double? targetLBM,
      int? checkInDay,
      double? averageSleepHours,
      int? energyLevel1To10,
      double? metaICA,
      double? metaICC,
      bool onboardingCompleted,
      bool hasCompletedTour,
      @OptionalTimestampConverter() DateTime? createdAt,
      @OptionalTimestampConverter() DateTime? updatedAt});
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
    Object? name = null,
    Object? photoUrl = freezed,
    Object? gender = null,
    Object? birthDate = freezed,
    Object? heightCm = null,
    Object? currentWeightKg = null,
    Object? waistCircumferenceCm = freezed,
    Object? neckCircumferenceCm = freezed,
    Object? hipCircumferenceCm = freezed,
    Object? pathologies = null,
    Object? activityLevel = null,
    Object? physicalLimitations = null,
    Object? snackingHabit = null,
    Object? dietaryPreference = null,
    Object? hasDumbbells = null,
    Object? workoutDays = null,
    Object? lastHighIntensityWorkoutAt = freezed,
    Object? wakeUpTime = freezed,
    Object? bedTime = freezed,
    Object? usualFirstMealTime = freezed,
    Object? usualLastMealTime = freezed,
    Object? fastingExperience = null,
    Object? recommendedProtocol = freezed,
    Object? healthGoal = freezed,
    Object? targetWeightKg = freezed,
    Object? startWeightKg = freezed,
    Object? targetFatPercentage = freezed,
    Object? targetLBM = freezed,
    Object? checkInDay = freezed,
    Object? averageSleepHours = freezed,
    Object? energyLevel1To10 = freezed,
    Object? metaICA = freezed,
    Object? metaICC = freezed,
    Object? onboardingCompleted = null,
    Object? hasCompletedTour = null,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      heightCm: null == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _value.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: freezed == waistCircumferenceCm
          ? _value.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      neckCircumferenceCm: freezed == neckCircumferenceCm
          ? _value.neckCircumferenceCm
          : neckCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
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
      hasDumbbells: null == hasDumbbells
          ? _value.hasDumbbells
          : hasDumbbells // ignore: cast_nullable_to_non_nullable
              as bool,
      workoutDays: null == workoutDays
          ? _value._workoutDays
          : workoutDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      lastHighIntensityWorkoutAt: freezed == lastHighIntensityWorkoutAt
          ? _value.lastHighIntensityWorkoutAt
          : lastHighIntensityWorkoutAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      wakeUpTime: freezed == wakeUpTime
          ? _value.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as String?,
      bedTime: freezed == bedTime
          ? _value.bedTime
          : bedTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualFirstMealTime: freezed == usualFirstMealTime
          ? _value.usualFirstMealTime
          : usualFirstMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualLastMealTime: freezed == usualLastMealTime
          ? _value.usualLastMealTime
          : usualLastMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
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
      targetWeightKg: freezed == targetWeightKg
          ? _value.targetWeightKg
          : targetWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      startWeightKg: freezed == startWeightKg
          ? _value.startWeightKg
          : startWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      targetFatPercentage: freezed == targetFatPercentage
          ? _value.targetFatPercentage
          : targetFatPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      targetLBM: freezed == targetLBM
          ? _value.targetLBM
          : targetLBM // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInDay: freezed == checkInDay
          ? _value.checkInDay
          : checkInDay // ignore: cast_nullable_to_non_nullable
              as int?,
      averageSleepHours: freezed == averageSleepHours
          ? _value.averageSleepHours
          : averageSleepHours // ignore: cast_nullable_to_non_nullable
              as double?,
      energyLevel1To10: freezed == energyLevel1To10
          ? _value.energyLevel1To10
          : energyLevel1To10 // ignore: cast_nullable_to_non_nullable
              as int?,
      metaICA: freezed == metaICA
          ? _value.metaICA
          : metaICA // ignore: cast_nullable_to_non_nullable
              as double?,
      metaICC: freezed == metaICC
          ? _value.metaICC
          : metaICC // ignore: cast_nullable_to_non_nullable
              as double?,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCompletedTour: null == hasCompletedTour
          ? _value.hasCompletedTour
          : hasCompletedTour // ignore: cast_nullable_to_non_nullable
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
class _$UserModelImpl extends _UserModel {
  const _$UserModelImpl(
      {required this.uid,
      required this.email,
      required this.displayName,
      @JsonKey(readValue: _readName) this.name = '',
      this.photoUrl,
      this.gender = Gender.female,
      @OptionalTimestampConverter() this.birthDate,
      this.heightCm = 165.0,
      this.currentWeightKg = 65.0,
      this.waistCircumferenceCm,
      this.neckCircumferenceCm,
      this.hipCircumferenceCm,
      final List<String> pathologies = const [],
      @JsonKey(readValue: _readActivityLevel)
      this.activityLevel = ActivityLevel.sedentary,
      final List<String> physicalLimitations = const [],
      this.snackingHabit = SnackingHabit.sometimes,
      this.dietaryPreference = DietaryPreference.omnivore,
      this.hasDumbbells = false,
      final List<int> workoutDays = const [1, 3, 5],
      @OptionalTimestampConverter() this.lastHighIntensityWorkoutAt,
      this.wakeUpTime,
      this.bedTime,
      this.usualFirstMealTime,
      this.usualLastMealTime,
      this.fastingExperience = FastingExperience.beginner,
      this.recommendedProtocol,
      this.healthGoal,
      this.targetWeightKg,
      this.startWeightKg,
      this.targetFatPercentage,
      this.targetLBM,
      this.checkInDay,
      this.averageSleepHours,
      this.energyLevel1To10,
      this.metaICA,
      this.metaICC,
      this.onboardingCompleted = false,
      this.hasCompletedTour = false,
      @OptionalTimestampConverter() this.createdAt,
      @OptionalTimestampConverter() this.updatedAt})
      : assert(heightCm >= 50 && heightCm <= 250,
            'La altura debe estar entre 50 y 250cm.'),
        assert(currentWeightKg >= 20 && currentWeightKg <= 350,
            'El peso actual debe estar entre 20kg y 350kg.'),
        assert(
            waistCircumferenceCm == null ||
                (waistCircumferenceCm >= 30 && waistCircumferenceCm <= 250),
            'La circunferencia de cintura es ilógica.'),
        _pathologies = pathologies,
        _physicalLimitations = physicalLimitations,
        _workoutDays = workoutDays,
        super._();

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
  @JsonKey(readValue: _readName)
  final String name;
  @override
  final String? photoUrl;
  @override
  @JsonKey()
  final Gender gender;
  @override
  @OptionalTimestampConverter()
  final DateTime? birthDate;
// 2. Antropometría
  @override
  @JsonKey()
  final double heightCm;
  @override
  @JsonKey()
  final double currentWeightKg;
  @override
  final double? waistCircumferenceCm;
  @override
  final double? neckCircumferenceCm;
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
  @JsonKey(readValue: _readActivityLevel)
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
  @JsonKey()
  final SnackingHabit snackingHabit;
  @override
  @JsonKey()
  final DietaryPreference dietaryPreference;
  @override
  @JsonKey()
  final bool hasDumbbells;
  final List<int> _workoutDays;
  @override
  @JsonKey()
  List<int> get workoutDays {
    if (_workoutDays is EqualUnmodifiableListView) return _workoutDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workoutDays);
  }

  @override
  @OptionalTimestampConverter()
  final DateTime? lastHighIntensityWorkoutAt;
// 4. Cronobiología
  @override
  final String? wakeUpTime;
// target_wake_time
  @override
  final String? bedTime;
// target_sleep_time
  @override
  final String? usualFirstMealTime;
  @override
  final String? usualLastMealTime;
// 5. Estado & Objetivos
  @override
  @JsonKey()
  final FastingExperience fastingExperience;
  @override
  final String? recommendedProtocol;
  @override
  final HealthGoal? healthGoal;
// Goals & Progress
  @override
  final double? targetWeightKg;
  @override
  final double? startWeightKg;
  @override
  final double? targetFatPercentage;
  @override
  final double? targetLBM;
// Configuración
  @override
  final int? checkInDay;
// IMX Specific Overrides
  @override
  final double? averageSleepHours;
  @override
  final int? energyLevel1To10;
// Legacy / Calculated (Can be stored or calculated)
  @override
  final double? metaICA;
  @override
  final double? metaICC;
// Metadata
  @override
  @JsonKey()
  final bool onboardingCompleted;
  @override
  @JsonKey()
  final bool hasCompletedTour;
  @override
  @OptionalTimestampConverter()
  final DateTime? createdAt;
  @override
  @OptionalTimestampConverter()
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, name: $name, photoUrl: $photoUrl, gender: $gender, birthDate: $birthDate, heightCm: $heightCm, currentWeightKg: $currentWeightKg, waistCircumferenceCm: $waistCircumferenceCm, neckCircumferenceCm: $neckCircumferenceCm, hipCircumferenceCm: $hipCircumferenceCm, pathologies: $pathologies, activityLevel: $activityLevel, physicalLimitations: $physicalLimitations, snackingHabit: $snackingHabit, dietaryPreference: $dietaryPreference, hasDumbbells: $hasDumbbells, workoutDays: $workoutDays, lastHighIntensityWorkoutAt: $lastHighIntensityWorkoutAt, wakeUpTime: $wakeUpTime, bedTime: $bedTime, usualFirstMealTime: $usualFirstMealTime, usualLastMealTime: $usualLastMealTime, fastingExperience: $fastingExperience, recommendedProtocol: $recommendedProtocol, healthGoal: $healthGoal, targetWeightKg: $targetWeightKg, startWeightKg: $startWeightKg, targetFatPercentage: $targetFatPercentage, targetLBM: $targetLBM, checkInDay: $checkInDay, averageSleepHours: $averageSleepHours, energyLevel1To10: $energyLevel1To10, metaICA: $metaICA, metaICC: $metaICC, onboardingCompleted: $onboardingCompleted, hasCompletedTour: $hasCompletedTour, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.name, name) || other.name == name) &&
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
            (identical(other.hasDumbbells, hasDumbbells) ||
                other.hasDumbbells == hasDumbbells) &&
            const DeepCollectionEquality()
                .equals(other._workoutDays, _workoutDays) &&
            (identical(other.lastHighIntensityWorkoutAt,
                    lastHighIntensityWorkoutAt) ||
                other.lastHighIntensityWorkoutAt ==
                    lastHighIntensityWorkoutAt) &&
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
            (identical(other.targetWeightKg, targetWeightKg) ||
                other.targetWeightKg == targetWeightKg) &&
            (identical(other.startWeightKg, startWeightKg) ||
                other.startWeightKg == startWeightKg) &&
            (identical(other.targetFatPercentage, targetFatPercentage) ||
                other.targetFatPercentage == targetFatPercentage) &&
            (identical(other.targetLBM, targetLBM) ||
                other.targetLBM == targetLBM) &&
            (identical(other.checkInDay, checkInDay) ||
                other.checkInDay == checkInDay) &&
            (identical(other.averageSleepHours, averageSleepHours) ||
                other.averageSleepHours == averageSleepHours) &&
            (identical(other.energyLevel1To10, energyLevel1To10) ||
                other.energyLevel1To10 == energyLevel1To10) &&
            (identical(other.metaICA, metaICA) || other.metaICA == metaICA) &&
            (identical(other.metaICC, metaICC) || other.metaICC == metaICC) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.hasCompletedTour, hasCompletedTour) ||
                other.hasCompletedTour == hasCompletedTour) &&
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
        name,
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
        hasDumbbells,
        const DeepCollectionEquality().hash(_workoutDays),
        lastHighIntensityWorkoutAt,
        wakeUpTime,
        bedTime,
        usualFirstMealTime,
        usualLastMealTime,
        fastingExperience,
        recommendedProtocol,
        healthGoal,
        targetWeightKg,
        startWeightKg,
        targetFatPercentage,
        targetLBM,
        checkInDay,
        averageSleepHours,
        energyLevel1To10,
        metaICA,
        metaICC,
        onboardingCompleted,
        hasCompletedTour,
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

abstract class _UserModel extends UserModel {
  const factory _UserModel(
      {required final String uid,
      required final String email,
      required final String displayName,
      @JsonKey(readValue: _readName) final String name,
      final String? photoUrl,
      final Gender gender,
      @OptionalTimestampConverter() final DateTime? birthDate,
      final double heightCm,
      final double currentWeightKg,
      final double? waistCircumferenceCm,
      final double? neckCircumferenceCm,
      final double? hipCircumferenceCm,
      final List<String> pathologies,
      @JsonKey(readValue: _readActivityLevel) final ActivityLevel activityLevel,
      final List<String> physicalLimitations,
      final SnackingHabit snackingHabit,
      final DietaryPreference dietaryPreference,
      final bool hasDumbbells,
      final List<int> workoutDays,
      @OptionalTimestampConverter() final DateTime? lastHighIntensityWorkoutAt,
      final String? wakeUpTime,
      final String? bedTime,
      final String? usualFirstMealTime,
      final String? usualLastMealTime,
      final FastingExperience fastingExperience,
      final String? recommendedProtocol,
      final HealthGoal? healthGoal,
      final double? targetWeightKg,
      final double? startWeightKg,
      final double? targetFatPercentage,
      final double? targetLBM,
      final int? checkInDay,
      final double? averageSleepHours,
      final int? energyLevel1To10,
      final double? metaICA,
      final double? metaICC,
      final bool onboardingCompleted,
      final bool hasCompletedTour,
      @OptionalTimestampConverter() final DateTime? createdAt,
      @OptionalTimestampConverter()
      final DateTime? updatedAt}) = _$UserModelImpl;
  const _UserModel._() : super._();

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override // 1. Identificación
  String get uid;
  @override
  String get email;
  @override
  String get displayName;
  @override
  @JsonKey(readValue: _readName)
  String get name;
  @override
  String? get photoUrl;
  @override
  Gender get gender;
  @override
  @OptionalTimestampConverter()
  DateTime? get birthDate;
  @override // 2. Antropometría
  double get heightCm;
  @override
  double get currentWeightKg;
  @override
  double? get waistCircumferenceCm;
  @override
  double? get neckCircumferenceCm;
  @override
  double? get hipCircumferenceCm;
  @override // 3. Perfil Clínico & Hábitos
  List<String> get pathologies;
  @override
  @JsonKey(readValue: _readActivityLevel)
  ActivityLevel get activityLevel;
  @override
  List<String> get physicalLimitations;
  @override
  SnackingHabit get snackingHabit;
  @override
  DietaryPreference get dietaryPreference;
  @override
  bool get hasDumbbells;
  @override
  List<int> get workoutDays;
  @override
  @OptionalTimestampConverter()
  DateTime? get lastHighIntensityWorkoutAt;
  @override // 4. Cronobiología
  String? get wakeUpTime;
  @override // target_wake_time
  String? get bedTime;
  @override // target_sleep_time
  String? get usualFirstMealTime;
  @override
  String? get usualLastMealTime;
  @override // 5. Estado & Objetivos
  FastingExperience get fastingExperience;
  @override
  String? get recommendedProtocol;
  @override
  HealthGoal? get healthGoal;
  @override // Goals & Progress
  double? get targetWeightKg;
  @override
  double? get startWeightKg;
  @override
  double? get targetFatPercentage;
  @override
  double? get targetLBM;
  @override // Configuración
  int? get checkInDay;
  @override // IMX Specific Overrides
  double? get averageSleepHours;
  @override
  int? get energyLevel1To10;
  @override // Legacy / Calculated (Can be stored or calculated)
  double? get metaICA;
  @override
  double? get metaICC;
  @override // Metadata
  bool get onboardingCompleted;
  @override
  bool get hasCompletedTour;
  @override
  @OptionalTimestampConverter()
  DateTime? get createdAt;
  @override
  @OptionalTimestampConverter()
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
