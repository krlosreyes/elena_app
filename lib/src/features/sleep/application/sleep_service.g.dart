// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sleepRepositoryHash() => r'6d451243b05bff314f755b02d1d7cc59c4c1d397';

/// 📱 Riverpod Providers para SleepService
///
/// Proporcionan acceso singleton a SleepService en toda la app
///
/// Copied from [sleepRepository].
@ProviderFor(sleepRepository)
final sleepRepositoryProvider = AutoDisposeProvider<SleepRepository>.internal(
  sleepRepository,
  name: r'sleepRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sleepRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SleepRepositoryRef = AutoDisposeProviderRef<SleepRepository>;
String _$sleepServiceHash() => r'27cc3706a7520cadaf9cb3960bb7ed51e6180411';

/// See also [sleepService].
@ProviderFor(sleepService)
final sleepServiceProvider = AutoDisposeProvider<SleepService>.internal(
  sleepService,
  name: r'sleepServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sleepServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SleepServiceRef = AutoDisposeProviderRef<SleepService>;
String _$recentSleepHash() => r'1ee772b0572fb39e76ca98f7818e45990cc03c0c';

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

/// ✅ Provider para sueño reciente
///
/// Copied from [recentSleep].
@ProviderFor(recentSleep)
const recentSleepProvider = RecentSleepFamily();

/// ✅ Provider para sueño reciente
///
/// Copied from [recentSleep].
class RecentSleepFamily extends Family<AsyncValue<List<SleepLog>>> {
  /// ✅ Provider para sueño reciente
  ///
  /// Copied from [recentSleep].
  const RecentSleepFamily();

  /// ✅ Provider para sueño reciente
  ///
  /// Copied from [recentSleep].
  RecentSleepProvider call(
    String uid, {
    int limit = 7,
  }) {
    return RecentSleepProvider(
      uid,
      limit: limit,
    );
  }

  @override
  RecentSleepProvider getProviderOverride(
    covariant RecentSleepProvider provider,
  ) {
    return call(
      provider.uid,
      limit: provider.limit,
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
  String? get name => r'recentSleepProvider';
}

/// ✅ Provider para sueño reciente
///
/// Copied from [recentSleep].
class RecentSleepProvider extends AutoDisposeFutureProvider<List<SleepLog>> {
  /// ✅ Provider para sueño reciente
  ///
  /// Copied from [recentSleep].
  RecentSleepProvider(
    String uid, {
    int limit = 7,
  }) : this._internal(
          (ref) => recentSleep(
            ref as RecentSleepRef,
            uid,
            limit: limit,
          ),
          from: recentSleepProvider,
          name: r'recentSleepProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recentSleepHash,
          dependencies: RecentSleepFamily._dependencies,
          allTransitiveDependencies:
              RecentSleepFamily._allTransitiveDependencies,
          uid: uid,
          limit: limit,
        );

  RecentSleepProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
    required this.limit,
  }) : super.internal();

  final String uid;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<SleepLog>> Function(RecentSleepRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentSleepProvider._internal(
        (ref) => create(ref as RecentSleepRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SleepLog>> createElement() {
    return _RecentSleepProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentSleepProvider &&
        other.uid == uid &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecentSleepRef on AutoDisposeFutureProviderRef<List<SleepLog>> {
  /// The parameter `uid` of this provider.
  String get uid;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _RecentSleepProviderElement
    extends AutoDisposeFutureProviderElement<List<SleepLog>>
    with RecentSleepRef {
  _RecentSleepProviderElement(super.provider);

  @override
  String get uid => (origin as RecentSleepProvider).uid;
  @override
  int get limit => (origin as RecentSleepProvider).limit;
}

String _$sleepStreamHash() => r'f7fdb2009b896d5591aad1df30110a4f71c757b3';

/// ✅ Stream provider para sueño en tiempo real
///
/// Copied from [sleepStream].
@ProviderFor(sleepStream)
const sleepStreamProvider = SleepStreamFamily();

/// ✅ Stream provider para sueño en tiempo real
///
/// Copied from [sleepStream].
class SleepStreamFamily extends Family<AsyncValue<List<SleepLog>>> {
  /// ✅ Stream provider para sueño en tiempo real
  ///
  /// Copied from [sleepStream].
  const SleepStreamFamily();

  /// ✅ Stream provider para sueño en tiempo real
  ///
  /// Copied from [sleepStream].
  SleepStreamProvider call(
    String uid, {
    int limit = 7,
  }) {
    return SleepStreamProvider(
      uid,
      limit: limit,
    );
  }

  @override
  SleepStreamProvider getProviderOverride(
    covariant SleepStreamProvider provider,
  ) {
    return call(
      provider.uid,
      limit: provider.limit,
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
  String? get name => r'sleepStreamProvider';
}

/// ✅ Stream provider para sueño en tiempo real
///
/// Copied from [sleepStream].
class SleepStreamProvider extends AutoDisposeStreamProvider<List<SleepLog>> {
  /// ✅ Stream provider para sueño en tiempo real
  ///
  /// Copied from [sleepStream].
  SleepStreamProvider(
    String uid, {
    int limit = 7,
  }) : this._internal(
          (ref) => sleepStream(
            ref as SleepStreamRef,
            uid,
            limit: limit,
          ),
          from: sleepStreamProvider,
          name: r'sleepStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sleepStreamHash,
          dependencies: SleepStreamFamily._dependencies,
          allTransitiveDependencies:
              SleepStreamFamily._allTransitiveDependencies,
          uid: uid,
          limit: limit,
        );

  SleepStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
    required this.limit,
  }) : super.internal();

  final String uid;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<SleepLog>> Function(SleepStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SleepStreamProvider._internal(
        (ref) => create(ref as SleepStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SleepLog>> createElement() {
    return _SleepStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SleepStreamProvider &&
        other.uid == uid &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SleepStreamRef on AutoDisposeStreamProviderRef<List<SleepLog>> {
  /// The parameter `uid` of this provider.
  String get uid;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _SleepStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<SleepLog>>
    with SleepStreamRef {
  _SleepStreamProviderElement(super.provider);

  @override
  String get uid => (origin as SleepStreamProvider).uid;
  @override
  int get limit => (origin as SleepStreamProvider).limit;
}

String _$averageSleepHash() => r'3d2ae02e8f93dda36170f6e0d28cac843eadbf3e';

/// ✅ Provider para promedio de sueño
///
/// Copied from [averageSleep].
@ProviderFor(averageSleep)
const averageSleepProvider = AverageSleepFamily();

/// ✅ Provider para promedio de sueño
///
/// Copied from [averageSleep].
class AverageSleepFamily extends Family<AsyncValue<double>> {
  /// ✅ Provider para promedio de sueño
  ///
  /// Copied from [averageSleep].
  const AverageSleepFamily();

  /// ✅ Provider para promedio de sueño
  ///
  /// Copied from [averageSleep].
  AverageSleepProvider call(
    String uid, {
    int limit = 7,
  }) {
    return AverageSleepProvider(
      uid,
      limit: limit,
    );
  }

  @override
  AverageSleepProvider getProviderOverride(
    covariant AverageSleepProvider provider,
  ) {
    return call(
      provider.uid,
      limit: provider.limit,
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
  String? get name => r'averageSleepProvider';
}

/// ✅ Provider para promedio de sueño
///
/// Copied from [averageSleep].
class AverageSleepProvider extends AutoDisposeFutureProvider<double> {
  /// ✅ Provider para promedio de sueño
  ///
  /// Copied from [averageSleep].
  AverageSleepProvider(
    String uid, {
    int limit = 7,
  }) : this._internal(
          (ref) => averageSleep(
            ref as AverageSleepRef,
            uid,
            limit: limit,
          ),
          from: averageSleepProvider,
          name: r'averageSleepProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$averageSleepHash,
          dependencies: AverageSleepFamily._dependencies,
          allTransitiveDependencies:
              AverageSleepFamily._allTransitiveDependencies,
          uid: uid,
          limit: limit,
        );

  AverageSleepProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
    required this.limit,
  }) : super.internal();

  final String uid;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<double> Function(AverageSleepRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AverageSleepProvider._internal(
        (ref) => create(ref as AverageSleepRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<double> createElement() {
    return _AverageSleepProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AverageSleepProvider &&
        other.uid == uid &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AverageSleepRef on AutoDisposeFutureProviderRef<double> {
  /// The parameter `uid` of this provider.
  String get uid;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _AverageSleepProviderElement
    extends AutoDisposeFutureProviderElement<double> with AverageSleepRef {
  _AverageSleepProviderElement(super.provider);

  @override
  String get uid => (origin as AverageSleepProvider).uid;
  @override
  int get limit => (origin as AverageSleepProvider).limit;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
