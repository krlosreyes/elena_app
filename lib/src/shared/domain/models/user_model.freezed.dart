// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {
// 1. Identificación
  String get uid;
  String get email;
  String get displayName;
  @JsonKey(readValue: _readName)
  String get name;
  String? get photoUrl;
  Gender get gender;
  @OptionalTimestampConverter()
  DateTime? get birthDate; // 2. Antropometría
  double get heightCm;
  double get currentWeightKg;
  double? get waistCircumferenceCm;
  double? get neckCircumferenceCm;
  double? get hipCircumferenceCm; // 3. Perfil Clínico & Hábitos
  List<String> get pathologies;
  @JsonKey(readValue: _readActivityLevel)
  ActivityLevel get activityLevel;
  List<String> get physicalLimitations;
  SnackingHabit get snackingHabit;
  DietaryPreference get dietaryPreference;
  bool get hasDumbbells;
  List<int> get workoutDays;
  @OptionalTimestampConverter()
  DateTime? get lastHighIntensityWorkoutAt; // 4. Cronobiología
  String? get wakeUpTime; // target_wake_time
  String? get bedTime; // target_sleep_time
  String? get usualFirstMealTime;
  String? get usualLastMealTime; // 5. Estado & Objetivos
  FastingExperience get fastingExperience;
  String? get recommendedProtocol;
  HealthGoal? get healthGoal; // Goals & Progress
  double? get targetWeightKg;
  double? get startWeightKg;
  double? get targetFatPercentage;
  double? get targetLBM; // Configuración
  int? get checkInDay; // IMR Specific Overrides
  double? get averageSleepHours;
  int? get energyLevel1To10;
  double? get initialImr; // IMR basal calculado al completar onboarding
// Legacy / Calculated (Can be stored or calculated)
  double? get metaICA;
  double? get metaICC;
  int get numberOfMeals; // 2 is typically the default for fasting, but see MetabolicHub for overrides.
// Metadata
  bool get onboardingCompleted;
  bool get hasCompletedTour;
  @OptionalTimestampConverter()
  DateTime? get createdAt;
  @OptionalTimestampConverter()
  DateTime? get updatedAt;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserModelCopyWith<UserModel> get copyWith =>
      _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserModel &&
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
                .equals(other.pathologies, pathologies) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            const DeepCollectionEquality()
                .equals(other.physicalLimitations, physicalLimitations) &&
            (identical(other.snackingHabit, snackingHabit) ||
                other.snackingHabit == snackingHabit) &&
            (identical(other.dietaryPreference, dietaryPreference) ||
                other.dietaryPreference == dietaryPreference) &&
            (identical(other.hasDumbbells, hasDumbbells) ||
                other.hasDumbbells == hasDumbbells) &&
            const DeepCollectionEquality()
                .equals(other.workoutDays, workoutDays) &&
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
            (identical(other.initialImr, initialImr) ||
                other.initialImr == initialImr) &&
            (identical(other.metaICA, metaICA) || other.metaICA == metaICA) &&
            (identical(other.metaICC, metaICC) || other.metaICC == metaICC) &&
            (identical(other.numberOfMeals, numberOfMeals) ||
                other.numberOfMeals == numberOfMeals) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.hasCompletedTour, hasCompletedTour) ||
                other.hasCompletedTour == hasCompletedTour) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
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
        const DeepCollectionEquality().hash(pathologies),
        activityLevel,
        const DeepCollectionEquality().hash(physicalLimitations),
        snackingHabit,
        dietaryPreference,
        hasDumbbells,
        const DeepCollectionEquality().hash(workoutDays),
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
        initialImr,
        metaICA,
        metaICC,
        numberOfMeals,
        onboardingCompleted,
        hasCompletedTour,
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, name: $name, photoUrl: $photoUrl, gender: $gender, birthDate: $birthDate, heightCm: $heightCm, currentWeightKg: $currentWeightKg, waistCircumferenceCm: $waistCircumferenceCm, neckCircumferenceCm: $neckCircumferenceCm, hipCircumferenceCm: $hipCircumferenceCm, pathologies: $pathologies, activityLevel: $activityLevel, physicalLimitations: $physicalLimitations, snackingHabit: $snackingHabit, dietaryPreference: $dietaryPreference, hasDumbbells: $hasDumbbells, workoutDays: $workoutDays, lastHighIntensityWorkoutAt: $lastHighIntensityWorkoutAt, wakeUpTime: $wakeUpTime, bedTime: $bedTime, usualFirstMealTime: $usualFirstMealTime, usualLastMealTime: $usualLastMealTime, fastingExperience: $fastingExperience, recommendedProtocol: $recommendedProtocol, healthGoal: $healthGoal, targetWeightKg: $targetWeightKg, startWeightKg: $startWeightKg, targetFatPercentage: $targetFatPercentage, targetLBM: $targetLBM, checkInDay: $checkInDay, averageSleepHours: $averageSleepHours, energyLevel1To10: $energyLevel1To10, initialImr: $initialImr, metaICA: $metaICA, metaICC: $metaICC, numberOfMeals: $numberOfMeals, onboardingCompleted: $onboardingCompleted, hasCompletedTour: $hasCompletedTour, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) =
      _$UserModelCopyWithImpl;
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
      double? initialImr,
      double? metaICA,
      double? metaICC,
      int numberOfMeals,
      bool onboardingCompleted,
      bool hasCompletedTour,
      @OptionalTimestampConverter() DateTime? createdAt,
      @OptionalTimestampConverter() DateTime? updatedAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res> implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
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
    Object? initialImr = freezed,
    Object? metaICA = freezed,
    Object? metaICC = freezed,
    Object? numberOfMeals = null,
    Object? onboardingCompleted = null,
    Object? hasCompletedTour = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      birthDate: freezed == birthDate
          ? _self.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      heightCm: null == heightCm
          ? _self.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _self.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: freezed == waistCircumferenceCm
          ? _self.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      neckCircumferenceCm: freezed == neckCircumferenceCm
          ? _self.neckCircumferenceCm
          : neckCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      hipCircumferenceCm: freezed == hipCircumferenceCm
          ? _self.hipCircumferenceCm
          : hipCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      pathologies: null == pathologies
          ? _self.pathologies
          : pathologies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activityLevel: null == activityLevel
          ? _self.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      physicalLimitations: null == physicalLimitations
          ? _self.physicalLimitations
          : physicalLimitations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      snackingHabit: null == snackingHabit
          ? _self.snackingHabit
          : snackingHabit // ignore: cast_nullable_to_non_nullable
              as SnackingHabit,
      dietaryPreference: null == dietaryPreference
          ? _self.dietaryPreference
          : dietaryPreference // ignore: cast_nullable_to_non_nullable
              as DietaryPreference,
      hasDumbbells: null == hasDumbbells
          ? _self.hasDumbbells
          : hasDumbbells // ignore: cast_nullable_to_non_nullable
              as bool,
      workoutDays: null == workoutDays
          ? _self.workoutDays
          : workoutDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      lastHighIntensityWorkoutAt: freezed == lastHighIntensityWorkoutAt
          ? _self.lastHighIntensityWorkoutAt
          : lastHighIntensityWorkoutAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      wakeUpTime: freezed == wakeUpTime
          ? _self.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as String?,
      bedTime: freezed == bedTime
          ? _self.bedTime
          : bedTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualFirstMealTime: freezed == usualFirstMealTime
          ? _self.usualFirstMealTime
          : usualFirstMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualLastMealTime: freezed == usualLastMealTime
          ? _self.usualLastMealTime
          : usualLastMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
      fastingExperience: null == fastingExperience
          ? _self.fastingExperience
          : fastingExperience // ignore: cast_nullable_to_non_nullable
              as FastingExperience,
      recommendedProtocol: freezed == recommendedProtocol
          ? _self.recommendedProtocol
          : recommendedProtocol // ignore: cast_nullable_to_non_nullable
              as String?,
      healthGoal: freezed == healthGoal
          ? _self.healthGoal
          : healthGoal // ignore: cast_nullable_to_non_nullable
              as HealthGoal?,
      targetWeightKg: freezed == targetWeightKg
          ? _self.targetWeightKg
          : targetWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      startWeightKg: freezed == startWeightKg
          ? _self.startWeightKg
          : startWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      targetFatPercentage: freezed == targetFatPercentage
          ? _self.targetFatPercentage
          : targetFatPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      targetLBM: freezed == targetLBM
          ? _self.targetLBM
          : targetLBM // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInDay: freezed == checkInDay
          ? _self.checkInDay
          : checkInDay // ignore: cast_nullable_to_non_nullable
              as int?,
      averageSleepHours: freezed == averageSleepHours
          ? _self.averageSleepHours
          : averageSleepHours // ignore: cast_nullable_to_non_nullable
              as double?,
      energyLevel1To10: freezed == energyLevel1To10
          ? _self.energyLevel1To10
          : energyLevel1To10 // ignore: cast_nullable_to_non_nullable
              as int?,
      initialImr: freezed == initialImr
          ? _self.initialImr
          : initialImr // ignore: cast_nullable_to_non_nullable
              as double?,
      metaICA: freezed == metaICA
          ? _self.metaICA
          : metaICA // ignore: cast_nullable_to_non_nullable
              as double?,
      metaICC: freezed == metaICC
          ? _self.metaICC
          : metaICC // ignore: cast_nullable_to_non_nullable
              as double?,
      numberOfMeals: null == numberOfMeals
          ? _self.numberOfMeals
          : numberOfMeals // ignore: cast_nullable_to_non_nullable
              as int,
      onboardingCompleted: null == onboardingCompleted
          ? _self.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCompletedTour: null == hasCompletedTour
          ? _self.hasCompletedTour
          : hasCompletedTour // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UserModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String uid,
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
            double? initialImr,
            double? metaICA,
            double? metaICC,
            int numberOfMeals,
            bool onboardingCompleted,
            bool hasCompletedTour,
            @OptionalTimestampConverter() DateTime? createdAt,
            @OptionalTimestampConverter() DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UserModel() when $default != null:
        return $default(
            _that.uid,
            _that.email,
            _that.displayName,
            _that.name,
            _that.photoUrl,
            _that.gender,
            _that.birthDate,
            _that.heightCm,
            _that.currentWeightKg,
            _that.waistCircumferenceCm,
            _that.neckCircumferenceCm,
            _that.hipCircumferenceCm,
            _that.pathologies,
            _that.activityLevel,
            _that.physicalLimitations,
            _that.snackingHabit,
            _that.dietaryPreference,
            _that.hasDumbbells,
            _that.workoutDays,
            _that.lastHighIntensityWorkoutAt,
            _that.wakeUpTime,
            _that.bedTime,
            _that.usualFirstMealTime,
            _that.usualLastMealTime,
            _that.fastingExperience,
            _that.recommendedProtocol,
            _that.healthGoal,
            _that.targetWeightKg,
            _that.startWeightKg,
            _that.targetFatPercentage,
            _that.targetLBM,
            _that.checkInDay,
            _that.averageSleepHours,
            _that.energyLevel1To10,
            _that.initialImr,
            _that.metaICA,
            _that.metaICC,
            _that.numberOfMeals,
            _that.onboardingCompleted,
            _that.hasCompletedTour,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String uid,
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
            double? initialImr,
            double? metaICA,
            double? metaICC,
            int numberOfMeals,
            bool onboardingCompleted,
            bool hasCompletedTour,
            @OptionalTimestampConverter() DateTime? createdAt,
            @OptionalTimestampConverter() DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserModel():
        return $default(
            _that.uid,
            _that.email,
            _that.displayName,
            _that.name,
            _that.photoUrl,
            _that.gender,
            _that.birthDate,
            _that.heightCm,
            _that.currentWeightKg,
            _that.waistCircumferenceCm,
            _that.neckCircumferenceCm,
            _that.hipCircumferenceCm,
            _that.pathologies,
            _that.activityLevel,
            _that.physicalLimitations,
            _that.snackingHabit,
            _that.dietaryPreference,
            _that.hasDumbbells,
            _that.workoutDays,
            _that.lastHighIntensityWorkoutAt,
            _that.wakeUpTime,
            _that.bedTime,
            _that.usualFirstMealTime,
            _that.usualLastMealTime,
            _that.fastingExperience,
            _that.recommendedProtocol,
            _that.healthGoal,
            _that.targetWeightKg,
            _that.startWeightKg,
            _that.targetFatPercentage,
            _that.targetLBM,
            _that.checkInDay,
            _that.averageSleepHours,
            _that.energyLevel1To10,
            _that.initialImr,
            _that.metaICA,
            _that.metaICC,
            _that.numberOfMeals,
            _that.onboardingCompleted,
            _that.hasCompletedTour,
            _that.createdAt,
            _that.updatedAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String uid,
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
            double? initialImr,
            double? metaICA,
            double? metaICC,
            int numberOfMeals,
            bool onboardingCompleted,
            bool hasCompletedTour,
            @OptionalTimestampConverter() DateTime? createdAt,
            @OptionalTimestampConverter() DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UserModel() when $default != null:
        return $default(
            _that.uid,
            _that.email,
            _that.displayName,
            _that.name,
            _that.photoUrl,
            _that.gender,
            _that.birthDate,
            _that.heightCm,
            _that.currentWeightKg,
            _that.waistCircumferenceCm,
            _that.neckCircumferenceCm,
            _that.hipCircumferenceCm,
            _that.pathologies,
            _that.activityLevel,
            _that.physicalLimitations,
            _that.snackingHabit,
            _that.dietaryPreference,
            _that.hasDumbbells,
            _that.workoutDays,
            _that.lastHighIntensityWorkoutAt,
            _that.wakeUpTime,
            _that.bedTime,
            _that.usualFirstMealTime,
            _that.usualLastMealTime,
            _that.fastingExperience,
            _that.recommendedProtocol,
            _that.healthGoal,
            _that.targetWeightKg,
            _that.startWeightKg,
            _that.targetFatPercentage,
            _that.targetLBM,
            _that.checkInDay,
            _that.averageSleepHours,
            _that.energyLevel1To10,
            _that.initialImr,
            _that.metaICA,
            _that.metaICC,
            _that.numberOfMeals,
            _that.onboardingCompleted,
            _that.hasCompletedTour,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UserModel extends UserModel {
  const _UserModel(
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
      this.initialImr,
      this.metaICA,
      this.metaICC,
      this.numberOfMeals = 2,
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
  factory _UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

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
// IMR Specific Overrides
  @override
  final double? averageSleepHours;
  @override
  final int? energyLevel1To10;
  @override
  final double? initialImr;
// IMR basal calculado al completar onboarding
// Legacy / Calculated (Can be stored or calculated)
  @override
  final double? metaICA;
  @override
  final double? metaICC;
  @override
  @JsonKey()
  final int numberOfMeals;
// 2 is typically the default for fasting, but see MetabolicHub for overrides.
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

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserModelCopyWith<_UserModel> get copyWith =>
      __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UserModel &&
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
            (identical(other.initialImr, initialImr) ||
                other.initialImr == initialImr) &&
            (identical(other.metaICA, metaICA) || other.metaICA == metaICA) &&
            (identical(other.metaICC, metaICC) || other.metaICC == metaICC) &&
            (identical(other.numberOfMeals, numberOfMeals) ||
                other.numberOfMeals == numberOfMeals) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.hasCompletedTour, hasCompletedTour) ||
                other.hasCompletedTour == hasCompletedTour) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
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
        initialImr,
        metaICA,
        metaICC,
        numberOfMeals,
        onboardingCompleted,
        hasCompletedTour,
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, name: $name, photoUrl: $photoUrl, gender: $gender, birthDate: $birthDate, heightCm: $heightCm, currentWeightKg: $currentWeightKg, waistCircumferenceCm: $waistCircumferenceCm, neckCircumferenceCm: $neckCircumferenceCm, hipCircumferenceCm: $hipCircumferenceCm, pathologies: $pathologies, activityLevel: $activityLevel, physicalLimitations: $physicalLimitations, snackingHabit: $snackingHabit, dietaryPreference: $dietaryPreference, hasDumbbells: $hasDumbbells, workoutDays: $workoutDays, lastHighIntensityWorkoutAt: $lastHighIntensityWorkoutAt, wakeUpTime: $wakeUpTime, bedTime: $bedTime, usualFirstMealTime: $usualFirstMealTime, usualLastMealTime: $usualLastMealTime, fastingExperience: $fastingExperience, recommendedProtocol: $recommendedProtocol, healthGoal: $healthGoal, targetWeightKg: $targetWeightKg, startWeightKg: $startWeightKg, targetFatPercentage: $targetFatPercentage, targetLBM: $targetLBM, checkInDay: $checkInDay, averageSleepHours: $averageSleepHours, energyLevel1To10: $energyLevel1To10, initialImr: $initialImr, metaICA: $metaICA, metaICC: $metaICC, numberOfMeals: $numberOfMeals, onboardingCompleted: $onboardingCompleted, hasCompletedTour: $hasCompletedTour, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(
          _UserModel value, $Res Function(_UserModel) _then) =
      __$UserModelCopyWithImpl;
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
      double? initialImr,
      double? metaICA,
      double? metaICC,
      int numberOfMeals,
      bool onboardingCompleted,
      bool hasCompletedTour,
      @OptionalTimestampConverter() DateTime? createdAt,
      @OptionalTimestampConverter() DateTime? updatedAt});
}

/// @nodoc
class __$UserModelCopyWithImpl<$Res> implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    Object? initialImr = freezed,
    Object? metaICA = freezed,
    Object? metaICC = freezed,
    Object? numberOfMeals = null,
    Object? onboardingCompleted = null,
    Object? hasCompletedTour = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_UserModel(
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _self.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      birthDate: freezed == birthDate
          ? _self.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      heightCm: null == heightCm
          ? _self.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _self.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: freezed == waistCircumferenceCm
          ? _self.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      neckCircumferenceCm: freezed == neckCircumferenceCm
          ? _self.neckCircumferenceCm
          : neckCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      hipCircumferenceCm: freezed == hipCircumferenceCm
          ? _self.hipCircumferenceCm
          : hipCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double?,
      pathologies: null == pathologies
          ? _self._pathologies
          : pathologies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activityLevel: null == activityLevel
          ? _self.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      physicalLimitations: null == physicalLimitations
          ? _self._physicalLimitations
          : physicalLimitations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      snackingHabit: null == snackingHabit
          ? _self.snackingHabit
          : snackingHabit // ignore: cast_nullable_to_non_nullable
              as SnackingHabit,
      dietaryPreference: null == dietaryPreference
          ? _self.dietaryPreference
          : dietaryPreference // ignore: cast_nullable_to_non_nullable
              as DietaryPreference,
      hasDumbbells: null == hasDumbbells
          ? _self.hasDumbbells
          : hasDumbbells // ignore: cast_nullable_to_non_nullable
              as bool,
      workoutDays: null == workoutDays
          ? _self._workoutDays
          : workoutDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      lastHighIntensityWorkoutAt: freezed == lastHighIntensityWorkoutAt
          ? _self.lastHighIntensityWorkoutAt
          : lastHighIntensityWorkoutAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      wakeUpTime: freezed == wakeUpTime
          ? _self.wakeUpTime
          : wakeUpTime // ignore: cast_nullable_to_non_nullable
              as String?,
      bedTime: freezed == bedTime
          ? _self.bedTime
          : bedTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualFirstMealTime: freezed == usualFirstMealTime
          ? _self.usualFirstMealTime
          : usualFirstMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
      usualLastMealTime: freezed == usualLastMealTime
          ? _self.usualLastMealTime
          : usualLastMealTime // ignore: cast_nullable_to_non_nullable
              as String?,
      fastingExperience: null == fastingExperience
          ? _self.fastingExperience
          : fastingExperience // ignore: cast_nullable_to_non_nullable
              as FastingExperience,
      recommendedProtocol: freezed == recommendedProtocol
          ? _self.recommendedProtocol
          : recommendedProtocol // ignore: cast_nullable_to_non_nullable
              as String?,
      healthGoal: freezed == healthGoal
          ? _self.healthGoal
          : healthGoal // ignore: cast_nullable_to_non_nullable
              as HealthGoal?,
      targetWeightKg: freezed == targetWeightKg
          ? _self.targetWeightKg
          : targetWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      startWeightKg: freezed == startWeightKg
          ? _self.startWeightKg
          : startWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      targetFatPercentage: freezed == targetFatPercentage
          ? _self.targetFatPercentage
          : targetFatPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      targetLBM: freezed == targetLBM
          ? _self.targetLBM
          : targetLBM // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInDay: freezed == checkInDay
          ? _self.checkInDay
          : checkInDay // ignore: cast_nullable_to_non_nullable
              as int?,
      averageSleepHours: freezed == averageSleepHours
          ? _self.averageSleepHours
          : averageSleepHours // ignore: cast_nullable_to_non_nullable
              as double?,
      energyLevel1To10: freezed == energyLevel1To10
          ? _self.energyLevel1To10
          : energyLevel1To10 // ignore: cast_nullable_to_non_nullable
              as int?,
      initialImr: freezed == initialImr
          ? _self.initialImr
          : initialImr // ignore: cast_nullable_to_non_nullable
              as double?,
      metaICA: freezed == metaICA
          ? _self.metaICA
          : metaICA // ignore: cast_nullable_to_non_nullable
              as double?,
      metaICC: freezed == metaICC
          ? _self.metaICC
          : metaICC // ignore: cast_nullable_to_non_nullable
              as double?,
      numberOfMeals: null == numberOfMeals
          ? _self.numberOfMeals
          : numberOfMeals // ignore: cast_nullable_to_non_nullable
              as int,
      onboardingCompleted: null == onboardingCompleted
          ? _self.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCompletedTour: null == hasCompletedTour
          ? _self.hasCompletedTour
          : hasCompletedTour // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
