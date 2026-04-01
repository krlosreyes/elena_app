// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trainingRepositoryHash() =>
    r'071b944af6742ffec1de8f264c0f4d76df335835';

/// 📱 Riverpod Providers para ExerciseService
///
/// Proporcionan acceso singleton a ExerciseService en toda la app
///
/// Copied from [trainingRepository].
@ProviderFor(trainingRepository)
final trainingRepositoryProvider =
    AutoDisposeProvider<TrainingRepository>.internal(
  trainingRepository,
  name: r'trainingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trainingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrainingRepositoryRef = AutoDisposeProviderRef<TrainingRepository>;
String _$exerciseServiceHash() => r'8e36545f4fe2e4a4f2d1ed011dff5db31253b3b6';

/// See also [exerciseService].
@ProviderFor(exerciseService)
final exerciseServiceProvider = AutoDisposeProvider<ExerciseService>.internal(
  exerciseService,
  name: r'exerciseServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exerciseServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ExerciseServiceRef = AutoDisposeProviderRef<ExerciseService>;
String _$recentWorkoutsHash() => r'73379d570f8b079aceaf7b6b1de3500f359ee663';

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

/// ✅ Provider para entrenamientos recientes
///
/// Copied from [recentWorkouts].
@ProviderFor(recentWorkouts)
const recentWorkoutsProvider = RecentWorkoutsFamily();

/// ✅ Provider para entrenamientos recientes
///
/// Copied from [recentWorkouts].
class RecentWorkoutsFamily
    extends Family<AsyncValue<List<RecordedWorkoutSession>>> {
  /// ✅ Provider para entrenamientos recientes
  ///
  /// Copied from [recentWorkouts].
  const RecentWorkoutsFamily();

  /// ✅ Provider para entrenamientos recientes
  ///
  /// Copied from [recentWorkouts].
  RecentWorkoutsProvider call(
    String uid,
  ) {
    return RecentWorkoutsProvider(
      uid,
    );
  }

  @override
  RecentWorkoutsProvider getProviderOverride(
    covariant RecentWorkoutsProvider provider,
  ) {
    return call(
      provider.uid,
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
  String? get name => r'recentWorkoutsProvider';
}

/// ✅ Provider para entrenamientos recientes
///
/// Copied from [recentWorkouts].
class RecentWorkoutsProvider
    extends AutoDisposeFutureProvider<List<RecordedWorkoutSession>> {
  /// ✅ Provider para entrenamientos recientes
  ///
  /// Copied from [recentWorkouts].
  RecentWorkoutsProvider(
    String uid,
  ) : this._internal(
          (ref) => recentWorkouts(
            ref as RecentWorkoutsRef,
            uid,
          ),
          from: recentWorkoutsProvider,
          name: r'recentWorkoutsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recentWorkoutsHash,
          dependencies: RecentWorkoutsFamily._dependencies,
          allTransitiveDependencies:
              RecentWorkoutsFamily._allTransitiveDependencies,
          uid: uid,
        );

  RecentWorkoutsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
  }) : super.internal();

  final String uid;

  @override
  Override overrideWith(
    FutureOr<List<RecordedWorkoutSession>> Function(RecentWorkoutsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentWorkoutsProvider._internal(
        (ref) => create(ref as RecentWorkoutsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RecordedWorkoutSession>>
      createElement() {
    return _RecentWorkoutsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentWorkoutsProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecentWorkoutsRef
    on AutoDisposeFutureProviderRef<List<RecordedWorkoutSession>> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _RecentWorkoutsProviderElement
    extends AutoDisposeFutureProviderElement<List<RecordedWorkoutSession>>
    with RecentWorkoutsRef {
  _RecentWorkoutsProviderElement(super.provider);

  @override
  String get uid => (origin as RecentWorkoutsProvider).uid;
}

String _$workoutLogsHash() => r'e9b96259621177dbd80c6f781f1cac5ab8eace9d';

/// ✅ Provider para logs de entrenamiento
///
/// Copied from [workoutLogs].
@ProviderFor(workoutLogs)
const workoutLogsProvider = WorkoutLogsFamily();

/// ✅ Provider para logs de entrenamiento
///
/// Copied from [workoutLogs].
class WorkoutLogsFamily extends Family<AsyncValue<List<WorkoutLog>>> {
  /// ✅ Provider para logs de entrenamiento
  ///
  /// Copied from [workoutLogs].
  const WorkoutLogsFamily();

  /// ✅ Provider para logs de entrenamiento
  ///
  /// Copied from [workoutLogs].
  WorkoutLogsProvider call(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) {
    return WorkoutLogsProvider(
      uid,
      startDate,
      endDate,
    );
  }

  @override
  WorkoutLogsProvider getProviderOverride(
    covariant WorkoutLogsProvider provider,
  ) {
    return call(
      provider.uid,
      provider.startDate,
      provider.endDate,
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
  String? get name => r'workoutLogsProvider';
}

/// ✅ Provider para logs de entrenamiento
///
/// Copied from [workoutLogs].
class WorkoutLogsProvider extends AutoDisposeFutureProvider<List<WorkoutLog>> {
  /// ✅ Provider para logs de entrenamiento
  ///
  /// Copied from [workoutLogs].
  WorkoutLogsProvider(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) : this._internal(
          (ref) => workoutLogs(
            ref as WorkoutLogsRef,
            uid,
            startDate,
            endDate,
          ),
          from: workoutLogsProvider,
          name: r'workoutLogsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$workoutLogsHash,
          dependencies: WorkoutLogsFamily._dependencies,
          allTransitiveDependencies:
              WorkoutLogsFamily._allTransitiveDependencies,
          uid: uid,
          startDate: startDate,
          endDate: endDate,
        );

  WorkoutLogsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final String uid;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Override overrideWith(
    FutureOr<List<WorkoutLog>> Function(WorkoutLogsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WorkoutLogsProvider._internal(
        (ref) => create(ref as WorkoutLogsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<WorkoutLog>> createElement() {
    return _WorkoutLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutLogsProvider &&
        other.uid == uid &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WorkoutLogsRef on AutoDisposeFutureProviderRef<List<WorkoutLog>> {
  /// The parameter `uid` of this provider.
  String get uid;

  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;
}

class _WorkoutLogsProviderElement
    extends AutoDisposeFutureProviderElement<List<WorkoutLog>>
    with WorkoutLogsRef {
  _WorkoutLogsProviderElement(super.provider);

  @override
  String get uid => (origin as WorkoutLogsProvider).uid;
  @override
  DateTime get startDate => (origin as WorkoutLogsProvider).startDate;
  @override
  DateTime get endDate => (origin as WorkoutLogsProvider).endDate;
}

String _$activeMusclesHash() => r'2584dc672f8d67894b871e971db967fd8c507a81';

/// ✅ Provider para músculos activos
///
/// Copied from [activeMuscles].
@ProviderFor(activeMuscles)
const activeMusclesProvider = ActiveMusclesFamily();

/// ✅ Provider para músculos activos
///
/// Copied from [activeMuscles].
class ActiveMusclesFamily extends Family<AsyncValue<Set<String>>> {
  /// ✅ Provider para músculos activos
  ///
  /// Copied from [activeMuscles].
  const ActiveMusclesFamily();

  /// ✅ Provider para músculos activos
  ///
  /// Copied from [activeMuscles].
  ActiveMusclesProvider call(
    String uid,
  ) {
    return ActiveMusclesProvider(
      uid,
    );
  }

  @override
  ActiveMusclesProvider getProviderOverride(
    covariant ActiveMusclesProvider provider,
  ) {
    return call(
      provider.uid,
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
  String? get name => r'activeMusclesProvider';
}

/// ✅ Provider para músculos activos
///
/// Copied from [activeMuscles].
class ActiveMusclesProvider extends AutoDisposeFutureProvider<Set<String>> {
  /// ✅ Provider para músculos activos
  ///
  /// Copied from [activeMuscles].
  ActiveMusclesProvider(
    String uid,
  ) : this._internal(
          (ref) => activeMuscles(
            ref as ActiveMusclesRef,
            uid,
          ),
          from: activeMusclesProvider,
          name: r'activeMusclesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeMusclesHash,
          dependencies: ActiveMusclesFamily._dependencies,
          allTransitiveDependencies:
              ActiveMusclesFamily._allTransitiveDependencies,
          uid: uid,
        );

  ActiveMusclesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
  }) : super.internal();

  final String uid;

  @override
  Override overrideWith(
    FutureOr<Set<String>> Function(ActiveMusclesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveMusclesProvider._internal(
        (ref) => create(ref as ActiveMusclesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Set<String>> createElement() {
    return _ActiveMusclesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveMusclesProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ActiveMusclesRef on AutoDisposeFutureProviderRef<Set<String>> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _ActiveMusclesProviderElement
    extends AutoDisposeFutureProviderElement<Set<String>>
    with ActiveMusclesRef {
  _ActiveMusclesProviderElement(super.provider);

  @override
  String get uid => (origin as ActiveMusclesProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
