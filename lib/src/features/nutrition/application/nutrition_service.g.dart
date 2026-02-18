// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nutritionRepositoryHash() =>
    r'0af92833747359da8c8a15d9b06212ee1abb876a';

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
String _$nutritionEngineHash() => r'7dce7840bdd04aaf4fc72f8f67ade84b9dec4ed8';

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
String _$nutritionPlanHash() => r'0504b88472a52956a982ab28697b0e7b751a18fd';

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
