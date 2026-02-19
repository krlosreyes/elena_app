// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metabolic_checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isDailyCheckInCompletedHash() =>
    r'3ff220b35d7b47548420f7e3886e2be8b27bb88a';

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

typedef IsDailyCheckInCompletedRef = AutoDisposeFutureProviderRef<bool>;
String _$metabolicCheckinHash() => r'89082613c9b4bfa17bf82fc37b8c12503f798bc3';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
