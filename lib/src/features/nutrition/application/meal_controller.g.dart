// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentMealsHash() => r'ac45332e8f4d3dcf45c9d09b36a0520add237768';

/// See also [recentMeals].
@ProviderFor(recentMeals)
final recentMealsProvider = AutoDisposeStreamProvider<List<MealLog>>.internal(
  recentMeals,
  name: r'recentMealsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$recentMealsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RecentMealsRef = AutoDisposeStreamProviderRef<List<MealLog>>;
String _$mealControllerHash() => r'1e102c5757e8441e2f7dd5bc890a29f0cdd3273d';

/// See also [MealController].
@ProviderFor(MealController)
final mealControllerProvider =
    AutoDisposeNotifierProvider<MealController, void>.internal(
  MealController.new,
  name: r'mealControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mealControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MealController = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
