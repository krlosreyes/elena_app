// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$workoutLogHash() => r'15b6af314d6a1055ee9b521af1f9c04d92d19b82';

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

/// See also [workoutLog].
@ProviderFor(workoutLog)
const workoutLogProvider = WorkoutLogFamily();

/// See also [workoutLog].
class WorkoutLogFamily extends Family<AsyncValue<WorkoutLog?>> {
  /// See also [workoutLog].
  const WorkoutLogFamily();

  /// See also [workoutLog].
  WorkoutLogProvider call(
    DateTime date,
  ) {
    return WorkoutLogProvider(
      date,
    );
  }

  @override
  WorkoutLogProvider getProviderOverride(
    covariant WorkoutLogProvider provider,
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
  String? get name => r'workoutLogProvider';
}

/// See also [workoutLog].
class WorkoutLogProvider extends AutoDisposeFutureProvider<WorkoutLog?> {
  /// See also [workoutLog].
  WorkoutLogProvider(
    DateTime date,
  ) : this._internal(
          (ref) => workoutLog(
            ref as WorkoutLogRef,
            date,
          ),
          from: workoutLogProvider,
          name: r'workoutLogProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$workoutLogHash,
          dependencies: WorkoutLogFamily._dependencies,
          allTransitiveDependencies:
              WorkoutLogFamily._allTransitiveDependencies,
          date: date,
        );

  WorkoutLogProvider._internal(
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
    FutureOr<WorkoutLog?> Function(WorkoutLogRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WorkoutLogProvider._internal(
        (ref) => create(ref as WorkoutLogRef),
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
  AutoDisposeFutureProviderElement<WorkoutLog?> createElement() {
    return _WorkoutLogProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutLogProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WorkoutLogRef on AutoDisposeFutureProviderRef<WorkoutLog?> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _WorkoutLogProviderElement
    extends AutoDisposeFutureProviderElement<WorkoutLog?> with WorkoutLogRef {
  _WorkoutLogProviderElement(super.provider);

  @override
  DateTime get date => (origin as WorkoutLogProvider).date;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
