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

typedef NutritionRepositoryRef = ProviderRef<NutritionRepository>;
String _$nutritionEngineHash() => r'ca6c48f164c56afba8380ccf4bf7e36177d12349';

/// See also [nutritionEngine].
@ProviderFor(nutritionEngine)
final nutritionEngineProvider = Provider<NutritionEngine>.internal(
  nutritionEngine,
  name: r'nutritionEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nutritionEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NutritionEngineRef = ProviderRef<NutritionEngine>;
String _$nutritionPlanHash() => r'0eeca4338e049b477fa3e371d968f8b78d1a5b27';

/// See also [nutritionPlan].
@ProviderFor(nutritionPlan)
final nutritionPlanProvider =
    AutoDisposeStreamProvider<NutritionPlan?>.internal(
  nutritionPlan,
  name: r'nutritionPlanProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nutritionPlanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NutritionPlanRef = AutoDisposeStreamProviderRef<NutritionPlan?>;
String _$nutritionServiceHash() => r'39da281efea6c4aa40896962ff2d04d0e9872fd9';

/// See also [NutritionService].
@ProviderFor(NutritionService)
final nutritionServiceProvider =
    AutoDisposeNotifierProvider<NutritionService, void>.internal(
  NutritionService.new,
  name: r'nutritionServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nutritionServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NutritionService = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
