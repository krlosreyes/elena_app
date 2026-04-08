// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyRepositoryHash() => r'3659a56d89e8ce1fd901a959ed4e9df99b0fcc9e';

/// See also [historyRepository].
@ProviderFor(historyRepository)
final historyRepositoryProvider =
    AutoDisposeProvider<HistoryRepository>.internal(
  historyRepository,
  name: r'historyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HistoryRepositoryRef = AutoDisposeProviderRef<HistoryRepository>;
String _$workoutStatsHash() => r'103d31eeca54715b91e84f780f8635fa3a6b3547';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [workoutStats].
@ProviderFor(workoutStats)
const workoutStatsProvider = WorkoutStatsFamily();

/// See also [workoutStats].
class WorkoutStatsFamily extends Family<AsyncValue<WorkoutStats?>> {
  /// See also [workoutStats].
  const WorkoutStatsFamily();

  /// See also [workoutStats].
  WorkoutStatsProvider call(
    DateTime date,
  ) {
    return WorkoutStatsProvider(
      date,
    );
  }

  @override
  WorkoutStatsProvider getProviderOverride(
    covariant WorkoutStatsProvider provider,
  ) {
    return call(
      provider.date,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'workoutStatsProvider';
}

/// See also [workoutStats].
class WorkoutStatsProvider extends AutoDisposeFutureProvider<WorkoutStats?> {
  /// See also [workoutStats].
  WorkoutStatsProvider(
    DateTime date,
  ) : this._internal(
          (ref) => workoutStats(
            ref as WorkoutStatsRef,
            date,
          ),
          from: workoutStatsProvider,
          name: r'workoutStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$workoutStatsHash,
          dependencies: WorkoutStatsFamily._dependencies,
          allTransitiveDependencies:
              WorkoutStatsFamily._allTransitiveDependencies,
          date: date,
        );

  WorkoutStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<WorkoutStats?> Function(WorkoutStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WorkoutStatsProvider._internal(
        (ref) => create(ref as WorkoutStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<WorkoutStats?> createElement() {
    return _WorkoutStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutStatsProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WorkoutStatsRef on AutoDisposeFutureProviderRef<WorkoutStats?> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _WorkoutStatsProviderElement
    extends AutoDisposeFutureProviderElement<WorkoutStats?>
    with WorkoutStatsRef {
  _WorkoutStatsProviderElement(super.provider);

  @override
  DateTime get date => (origin as WorkoutStatsProvider).date;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
