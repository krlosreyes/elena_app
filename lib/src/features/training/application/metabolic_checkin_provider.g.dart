// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metabolic_checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isDailyCheckInCompletedHash() =>
    r'092440373f5f685254af4fd39fe21b63f2a4a4ee';

/// See also [isDailyCheckInCompleted].
@ProviderFor(isDailyCheckInCompleted)
final isDailyCheckInCompletedProvider =
    AutoDisposeFutureProvider<bool>.internal(
  isDailyCheckInCompleted,
  name: r'isDailyCheckInCompletedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isDailyCheckInCompletedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDailyCheckInCompletedRef = AutoDisposeFutureProviderRef<bool>;
String _$metabolicCheckinHash() => r'9d4a704e087fb4ffc66a2e9159b22c5a6cb07c27';

/// See also [MetabolicCheckin].
@ProviderFor(MetabolicCheckin)
final metabolicCheckinProvider =
    AsyncNotifierProvider<MetabolicCheckin, MetabolicState?>.internal(
  MetabolicCheckin.new,
  name: r'metabolicCheckinProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$metabolicCheckinHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MetabolicCheckin = AsyncNotifier<MetabolicState?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
