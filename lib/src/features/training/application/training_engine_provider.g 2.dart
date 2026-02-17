// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trainingRepositoryHash() =>
    r'996884e6a26d7add1c8d16320f410b70e35e9369';

/// See also [trainingRepository].
@ProviderFor(trainingRepository)
final trainingRepositoryProvider =
    AutoDisposeProvider<TrainingRepository>.internal(
  trainingRepository,
  name: r'trainingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trainingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrainingRepositoryRef = AutoDisposeProviderRef<TrainingRepository>;
String _$weeklyTrainingStatsHash() =>
    r'4d30d5a9d1abd4c6d64eb5f02058b866823fc11d';

/// See also [weeklyTrainingStats].
@ProviderFor(weeklyTrainingStats)
final weeklyTrainingStatsProvider =
    AutoDisposeFutureProvider<WeeklyTrainingStats>.internal(
  weeklyTrainingStats,
  name: r'weeklyTrainingStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$weeklyTrainingStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WeeklyTrainingStatsRef
    = AutoDisposeFutureProviderRef<WeeklyTrainingStats>;
String _$trainingEngineHash() => r'570661887d4f32d7f3beed6fecfa21065fe38d80';

/// See also [TrainingEngine].
@ProviderFor(TrainingEngine)
final trainingEngineProvider = AutoDisposeAsyncNotifierProvider<TrainingEngine,
    WorkoutRecommendation>.internal(
  TrainingEngine.new,
  name: r'trainingEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trainingEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrainingEngine = AutoDisposeAsyncNotifier<WorkoutRecommendation>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
