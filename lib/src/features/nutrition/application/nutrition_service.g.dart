// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nutritionRepositoryHash() =>
    r'e6a422cab39c6252e693528db8aa2755b9550f6e';

/// See also [nutritionRepository].
@ProviderFor(nutritionRepository)
final nutritionRepositoryProvider = Provider<NutritionRepository>.internal(
  nutritionRepository,
  name: r'nutritionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nutritionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NutritionRepositoryRef = ProviderRef<NutritionRepository>;
String _$activeMetabolicPlanHash() =>
    r'7db92070630459e4354d475cc1bc0c4fba751945';

/// See also [activeMetabolicPlan].
@ProviderFor(activeMetabolicPlan)
final activeMetabolicPlanProvider =
    AutoDisposeStreamProvider<MetabolicNutritionPlan?>.internal(
  activeMetabolicPlan,
  name: r'activeMetabolicPlanProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeMetabolicPlanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveMetabolicPlanRef
    = AutoDisposeStreamProviderRef<MetabolicNutritionPlan?>;
String _$todayMacroTargetsHash() => r'c6c67b86efff04e7ac28267a0abc25601ae26ae1';

/// Quick access to today's macro targets (used by dashboard)
///
/// Copied from [todayMacroTargets].
@ProviderFor(todayMacroTargets)
final todayMacroTargetsProvider = AutoDisposeProvider<
    ({int calories, int protein, int fat, int carbs})?>.internal(
  todayMacroTargets,
  name: r'todayMacroTargetsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayMacroTargetsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayMacroTargetsRef = AutoDisposeProviderRef<
    ({int calories, int protein, int fat, int carbs})?>;
String _$activeStrategyNameHash() =>
    r'9ef4cee9301a3a3accbd1adf250d8dee38d701fc';

/// Strategy name for display in UI
///
/// Copied from [activeStrategyName].
@ProviderFor(activeStrategyName)
final activeStrategyNameProvider = AutoDisposeProvider<String>.internal(
  activeStrategyName,
  name: r'activeStrategyNameProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeStrategyNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveStrategyNameRef = AutoDisposeProviderRef<String>;
String _$nutritionServiceHash() => r'23e4872e72c2a3a9d83fc0488b4544cf95d7f3b8';

/// See also [NutritionService].
@ProviderFor(NutritionService)
final nutritionServiceProvider = AutoDisposeNotifierProvider<NutritionService,
    AsyncValue<MetabolicNutritionPlan?>>.internal(
  NutritionService.new,
  name: r'nutritionServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nutritionServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NutritionService
    = AutoDisposeNotifier<AsyncValue<MetabolicNutritionPlan?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
