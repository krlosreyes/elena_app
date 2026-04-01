// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$progressServiceHash() => r'fb1d8d1883c7b89067da829d6267765092c503ac';

/// 🔌 ProgressService provider (singleton)
///
/// Copied from [progressService].
@ProviderFor(progressService)
final progressServiceProvider = AutoDisposeProvider<ProgressService>.internal(
  progressService,
  name: r'progressServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progressServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProgressServiceRef = AutoDisposeProviderRef<ProgressService>;
String _$latestMeasurementHash() => r'2b9caa3827e96f0b83eea8ecc27ac21a569a1f77';

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

/// 🔌 Latest measurement provider
///
/// Copied from [latestMeasurement].
@ProviderFor(latestMeasurement)
const latestMeasurementProvider = LatestMeasurementFamily();

/// 🔌 Latest measurement provider
///
/// Copied from [latestMeasurement].
class LatestMeasurementFamily extends Family<AsyncValue<MeasurementLog?>> {
  /// 🔌 Latest measurement provider
  ///
  /// Copied from [latestMeasurement].
  const LatestMeasurementFamily();

  /// 🔌 Latest measurement provider
  ///
  /// Copied from [latestMeasurement].
  LatestMeasurementProvider call(
    String uid,
  ) {
    return LatestMeasurementProvider(
      uid,
    );
  }

  @override
  LatestMeasurementProvider getProviderOverride(
    covariant LatestMeasurementProvider provider,
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
  String? get name => r'latestMeasurementProvider';
}

/// 🔌 Latest measurement provider
///
/// Copied from [latestMeasurement].
class LatestMeasurementProvider
    extends AutoDisposeFutureProvider<MeasurementLog?> {
  /// 🔌 Latest measurement provider
  ///
  /// Copied from [latestMeasurement].
  LatestMeasurementProvider(
    String uid,
  ) : this._internal(
          (ref) => latestMeasurement(
            ref as LatestMeasurementRef,
            uid,
          ),
          from: latestMeasurementProvider,
          name: r'latestMeasurementProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$latestMeasurementHash,
          dependencies: LatestMeasurementFamily._dependencies,
          allTransitiveDependencies:
              LatestMeasurementFamily._allTransitiveDependencies,
          uid: uid,
        );

  LatestMeasurementProvider._internal(
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
    FutureOr<MeasurementLog?> Function(LatestMeasurementRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LatestMeasurementProvider._internal(
        (ref) => create(ref as LatestMeasurementRef),
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
  AutoDisposeFutureProviderElement<MeasurementLog?> createElement() {
    return _LatestMeasurementProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LatestMeasurementProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LatestMeasurementRef on AutoDisposeFutureProviderRef<MeasurementLog?> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _LatestMeasurementProviderElement
    extends AutoDisposeFutureProviderElement<MeasurementLog?>
    with LatestMeasurementRef {
  _LatestMeasurementProviderElement(super.provider);

  @override
  String get uid => (origin as LatestMeasurementProvider).uid;
}

String _$measurementHistoryHash() =>
    r'f6943775108cb0fcc9788ff0c54a96924fb9b6f1';

/// 🔌 Measurement history provider
///
/// Copied from [measurementHistory].
@ProviderFor(measurementHistory)
const measurementHistoryProvider = MeasurementHistoryFamily();

/// 🔌 Measurement history provider
///
/// Copied from [measurementHistory].
class MeasurementHistoryFamily
    extends Family<AsyncValue<List<MeasurementLog>>> {
  /// 🔌 Measurement history provider
  ///
  /// Copied from [measurementHistory].
  const MeasurementHistoryFamily();

  /// 🔌 Measurement history provider
  ///
  /// Copied from [measurementHistory].
  MeasurementHistoryProvider call(
    String uid, {
    int days = 30,
  }) {
    return MeasurementHistoryProvider(
      uid,
      days: days,
    );
  }

  @override
  MeasurementHistoryProvider getProviderOverride(
    covariant MeasurementHistoryProvider provider,
  ) {
    return call(
      provider.uid,
      days: provider.days,
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
  String? get name => r'measurementHistoryProvider';
}

/// 🔌 Measurement history provider
///
/// Copied from [measurementHistory].
class MeasurementHistoryProvider
    extends AutoDisposeFutureProvider<List<MeasurementLog>> {
  /// 🔌 Measurement history provider
  ///
  /// Copied from [measurementHistory].
  MeasurementHistoryProvider(
    String uid, {
    int days = 30,
  }) : this._internal(
          (ref) => measurementHistory(
            ref as MeasurementHistoryRef,
            uid,
            days: days,
          ),
          from: measurementHistoryProvider,
          name: r'measurementHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$measurementHistoryHash,
          dependencies: MeasurementHistoryFamily._dependencies,
          allTransitiveDependencies:
              MeasurementHistoryFamily._allTransitiveDependencies,
          uid: uid,
          days: days,
        );

  MeasurementHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
    required this.days,
  }) : super.internal();

  final String uid;
  final int days;

  @override
  Override overrideWith(
    FutureOr<List<MeasurementLog>> Function(MeasurementHistoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeasurementHistoryProvider._internal(
        (ref) => create(ref as MeasurementHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<MeasurementLog>> createElement() {
    return _MeasurementHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeasurementHistoryProvider &&
        other.uid == uid &&
        other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MeasurementHistoryRef
    on AutoDisposeFutureProviderRef<List<MeasurementLog>> {
  /// The parameter `uid` of this provider.
  String get uid;

  /// The parameter `days` of this provider.
  int get days;
}

class _MeasurementHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<MeasurementLog>>
    with MeasurementHistoryRef {
  _MeasurementHistoryProviderElement(super.provider);

  @override
  String get uid => (origin as MeasurementHistoryProvider).uid;
  @override
  int get days => (origin as MeasurementHistoryProvider).days;
}

String _$weightProgressHash() => r'7c69214a624ba53793e830eba3e6b6633fb36540';

/// 🔌 Weight progress provider
///
/// Copied from [weightProgress].
@ProviderFor(weightProgress)
const weightProgressProvider = WeightProgressFamily();

/// 🔌 Weight progress provider
///
/// Copied from [weightProgress].
class WeightProgressFamily extends Family<AsyncValue<double?>> {
  /// 🔌 Weight progress provider
  ///
  /// Copied from [weightProgress].
  const WeightProgressFamily();

  /// 🔌 Weight progress provider
  ///
  /// Copied from [weightProgress].
  WeightProgressProvider call(
    String uid, {
    int days = 30,
  }) {
    return WeightProgressProvider(
      uid,
      days: days,
    );
  }

  @override
  WeightProgressProvider getProviderOverride(
    covariant WeightProgressProvider provider,
  ) {
    return call(
      provider.uid,
      days: provider.days,
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
  String? get name => r'weightProgressProvider';
}

/// 🔌 Weight progress provider
///
/// Copied from [weightProgress].
class WeightProgressProvider extends AutoDisposeFutureProvider<double?> {
  /// 🔌 Weight progress provider
  ///
  /// Copied from [weightProgress].
  WeightProgressProvider(
    String uid, {
    int days = 30,
  }) : this._internal(
          (ref) => weightProgress(
            ref as WeightProgressRef,
            uid,
            days: days,
          ),
          from: weightProgressProvider,
          name: r'weightProgressProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weightProgressHash,
          dependencies: WeightProgressFamily._dependencies,
          allTransitiveDependencies:
              WeightProgressFamily._allTransitiveDependencies,
          uid: uid,
          days: days,
        );

  WeightProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
    required this.days,
  }) : super.internal();

  final String uid;
  final int days;

  @override
  Override overrideWith(
    FutureOr<double?> Function(WeightProgressRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeightProgressProvider._internal(
        (ref) => create(ref as WeightProgressRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<double?> createElement() {
    return _WeightProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeightProgressProvider &&
        other.uid == uid &&
        other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeightProgressRef on AutoDisposeFutureProviderRef<double?> {
  /// The parameter `uid` of this provider.
  String get uid;

  /// The parameter `days` of this provider.
  int get days;
}

class _WeightProgressProviderElement
    extends AutoDisposeFutureProviderElement<double?> with WeightProgressRef {
  _WeightProgressProviderElement(super.provider);

  @override
  String get uid => (origin as WeightProgressProvider).uid;
  @override
  int get days => (origin as WeightProgressProvider).days;
}

String _$measurementStatsHash() => r'f2c7b1d460dd360c79d97fbd0821c079068cb728';

/// 🔌 Measurement statistics provider
///
/// Copied from [measurementStats].
@ProviderFor(measurementStats)
const measurementStatsProvider = MeasurementStatsFamily();

/// 🔌 Measurement statistics provider
///
/// Copied from [measurementStats].
class MeasurementStatsFamily extends Family<AsyncValue<Map<String, double>>> {
  /// 🔌 Measurement statistics provider
  ///
  /// Copied from [measurementStats].
  const MeasurementStatsFamily();

  /// 🔌 Measurement statistics provider
  ///
  /// Copied from [measurementStats].
  MeasurementStatsProvider call(
    String uid, {
    int days = 30,
  }) {
    return MeasurementStatsProvider(
      uid,
      days: days,
    );
  }

  @override
  MeasurementStatsProvider getProviderOverride(
    covariant MeasurementStatsProvider provider,
  ) {
    return call(
      provider.uid,
      days: provider.days,
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
  String? get name => r'measurementStatsProvider';
}

/// 🔌 Measurement statistics provider
///
/// Copied from [measurementStats].
class MeasurementStatsProvider
    extends AutoDisposeFutureProvider<Map<String, double>> {
  /// 🔌 Measurement statistics provider
  ///
  /// Copied from [measurementStats].
  MeasurementStatsProvider(
    String uid, {
    int days = 30,
  }) : this._internal(
          (ref) => measurementStats(
            ref as MeasurementStatsRef,
            uid,
            days: days,
          ),
          from: measurementStatsProvider,
          name: r'measurementStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$measurementStatsHash,
          dependencies: MeasurementStatsFamily._dependencies,
          allTransitiveDependencies:
              MeasurementStatsFamily._allTransitiveDependencies,
          uid: uid,
          days: days,
        );

  MeasurementStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
    required this.days,
  }) : super.internal();

  final String uid;
  final int days;

  @override
  Override overrideWith(
    FutureOr<Map<String, double>> Function(MeasurementStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeasurementStatsProvider._internal(
        (ref) => create(ref as MeasurementStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, double>> createElement() {
    return _MeasurementStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeasurementStatsProvider &&
        other.uid == uid &&
        other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MeasurementStatsRef on AutoDisposeFutureProviderRef<Map<String, double>> {
  /// The parameter `uid` of this provider.
  String get uid;

  /// The parameter `days` of this provider.
  int get days;
}

class _MeasurementStatsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, double>>
    with MeasurementStatsRef {
  _MeasurementStatsProviderElement(super.provider);

  @override
  String get uid => (origin as MeasurementStatsProvider).uid;
  @override
  int get days => (origin as MeasurementStatsProvider).days;
}

String _$watchMeasurementsHash() => r'ee4a3c660528ba62d45949a86c549859c165cda2';

/// 🔌 Watch measurement history (stream)
///
/// Copied from [watchMeasurements].
@ProviderFor(watchMeasurements)
const watchMeasurementsProvider = WatchMeasurementsFamily();

/// 🔌 Watch measurement history (stream)
///
/// Copied from [watchMeasurements].
class WatchMeasurementsFamily extends Family<AsyncValue<List<MeasurementLog>>> {
  /// 🔌 Watch measurement history (stream)
  ///
  /// Copied from [watchMeasurements].
  const WatchMeasurementsFamily();

  /// 🔌 Watch measurement history (stream)
  ///
  /// Copied from [watchMeasurements].
  WatchMeasurementsProvider call(
    String uid,
  ) {
    return WatchMeasurementsProvider(
      uid,
    );
  }

  @override
  WatchMeasurementsProvider getProviderOverride(
    covariant WatchMeasurementsProvider provider,
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
  String? get name => r'watchMeasurementsProvider';
}

/// 🔌 Watch measurement history (stream)
///
/// Copied from [watchMeasurements].
class WatchMeasurementsProvider
    extends AutoDisposeStreamProvider<List<MeasurementLog>> {
  /// 🔌 Watch measurement history (stream)
  ///
  /// Copied from [watchMeasurements].
  WatchMeasurementsProvider(
    String uid,
  ) : this._internal(
          (ref) => watchMeasurements(
            ref as WatchMeasurementsRef,
            uid,
          ),
          from: watchMeasurementsProvider,
          name: r'watchMeasurementsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchMeasurementsHash,
          dependencies: WatchMeasurementsFamily._dependencies,
          allTransitiveDependencies:
              WatchMeasurementsFamily._allTransitiveDependencies,
          uid: uid,
        );

  WatchMeasurementsProvider._internal(
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
    Stream<List<MeasurementLog>> Function(WatchMeasurementsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchMeasurementsProvider._internal(
        (ref) => create(ref as WatchMeasurementsRef),
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
  AutoDisposeStreamProviderElement<List<MeasurementLog>> createElement() {
    return _WatchMeasurementsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMeasurementsProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WatchMeasurementsRef
    on AutoDisposeStreamProviderRef<List<MeasurementLog>> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _WatchMeasurementsProviderElement
    extends AutoDisposeStreamProviderElement<List<MeasurementLog>>
    with WatchMeasurementsRef {
  _WatchMeasurementsProviderElement(super.provider);

  @override
  String get uid => (origin as WatchMeasurementsProvider).uid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
