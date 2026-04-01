// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentMealsHash() => r'0c36032cedb4c3b5e272f410e53496bcb8928ea6';

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
String _$mealControllerHash() => r'862da7477d854b1ed495447ac78e9390f83edfbb';

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
