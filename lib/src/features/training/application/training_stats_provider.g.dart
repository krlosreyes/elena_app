// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trainingStatsHash() => r'd04a7b1677a5f448f14f00ac6e0ed03dbbe2c6a5';

/// See also [trainingStats].
@ProviderFor(trainingStats)
final trainingStatsProvider =
    AutoDisposeFutureProvider<List<WorkoutLog>>.internal(
  trainingStats,
  name: r'trainingStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trainingStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrainingStatsRef = AutoDisposeFutureProviderRef<List<WorkoutLog>>;
String _$trainingStatsFilterHash() =>
    r'2695aff9cc5cc45f79eeed5b654a60125947caf4';

/// See also [TrainingStatsFilter].
@ProviderFor(TrainingStatsFilter)
final trainingStatsFilterProvider =
    AutoDisposeNotifierProvider<TrainingStatsFilter, StatsRange>.internal(
  TrainingStatsFilter.new,
  name: r'trainingStatsFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trainingStatsFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrainingStatsFilter = AutoDisposeNotifier<StatsRange>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
