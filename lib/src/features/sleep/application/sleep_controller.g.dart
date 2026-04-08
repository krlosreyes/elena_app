// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sleepRepositoryHash() => r'fe943be5b724ee2fb46bf0ba0a41342f19fee6f0';

/// See also [sleepRepository].
@ProviderFor(sleepRepository)
final sleepRepositoryProvider = Provider<SleepRepository>.internal(
  sleepRepository,
  name: r'sleepRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sleepRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SleepRepositoryRef = ProviderRef<SleepRepository>;
String _$recentSleepLogsHash() => r'aa24e73e2ae6f9223b2edfa27b70830658203356';

/// See also [recentSleepLogs].
@ProviderFor(recentSleepLogs)
final recentSleepLogsProvider =
    AutoDisposeStreamProvider<List<SleepLog>>.internal(
  recentSleepLogs,
  name: r'recentSleepLogsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentSleepLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentSleepLogsRef = AutoDisposeStreamProviderRef<List<SleepLog>>;
String _$sleepControllerHash() => r'40e28d737806237c3a49263c90fb994b989e3d2c';

/// See also [SleepController].
@ProviderFor(SleepController)
final sleepControllerProvider =
    AutoDisposeNotifierProvider<SleepController, void>.internal(
  SleepController.new,
  name: r'sleepControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sleepControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SleepController = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
