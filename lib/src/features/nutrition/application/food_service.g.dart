// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$foodRepositoryHash() => r'd7394a50beb0d9b5ba3719edaebdaa157d4d026c';

/// 📱 Riverpod Providers para FoodService
///
/// Copied from [foodRepository].
@ProviderFor(foodRepository)
final foodRepositoryProvider = AutoDisposeProvider<FoodRepository>.internal(
  foodRepository,
  name: r'foodRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$foodRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FoodRepositoryRef = AutoDisposeProviderRef<FoodRepository>;
String _$foodServiceHash() => r'd17a01a9a5eab0d5fe037e22093a1e4d0a1b1d8e';

/// See also [foodService].
@ProviderFor(foodService)
final foodServiceProvider = AutoDisposeProvider<FoodService>.internal(
  foodService,
  name: r'foodServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$foodServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FoodServiceRef = AutoDisposeProviderRef<FoodService>;
String _$foodsByCategoryHash() => r'd18a19e3aedebbc3153861882fa2bcf73882d1b9';

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

/// ✅ Obtener comidas por categoría (Future)
///
/// Copied from [foodsByCategory].
@ProviderFor(foodsByCategory)
const foodsByCategoryProvider = FoodsByCategoryFamily();

/// ✅ Obtener comidas por categoría (Future)
///
/// Copied from [foodsByCategory].
class FoodsByCategoryFamily extends Family<AsyncValue<List<FoodModel>>> {
  /// ✅ Obtener comidas por categoría (Future)
  ///
  /// Copied from [foodsByCategory].
  const FoodsByCategoryFamily();

  /// ✅ Obtener comidas por categoría (Future)
  ///
  /// Copied from [foodsByCategory].
  FoodsByCategoryProvider call(
    String category,
  ) {
    return FoodsByCategoryProvider(
      category,
    );
  }

  @override
  FoodsByCategoryProvider getProviderOverride(
    covariant FoodsByCategoryProvider provider,
  ) {
    return call(
      provider.category,
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
  String? get name => r'foodsByCategoryProvider';
}

/// ✅ Obtener comidas por categoría (Future)
///
/// Copied from [foodsByCategory].
class FoodsByCategoryProvider
    extends AutoDisposeFutureProvider<List<FoodModel>> {
  /// ✅ Obtener comidas por categoría (Future)
  ///
  /// Copied from [foodsByCategory].
  FoodsByCategoryProvider(
    String category,
  ) : this._internal(
          (ref) => foodsByCategory(
            ref as FoodsByCategoryRef,
            category,
          ),
          from: foodsByCategoryProvider,
          name: r'foodsByCategoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$foodsByCategoryHash,
          dependencies: FoodsByCategoryFamily._dependencies,
          allTransitiveDependencies:
              FoodsByCategoryFamily._allTransitiveDependencies,
          category: category,
        );

  FoodsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final String category;

  @override
  Override overrideWith(
    FutureOr<List<FoodModel>> Function(FoodsByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FoodsByCategoryProvider._internal(
        (ref) => create(ref as FoodsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<FoodModel>> createElement() {
    return _FoodsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FoodsByCategoryProvider && other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FoodsByCategoryRef on AutoDisposeFutureProviderRef<List<FoodModel>> {
  /// The parameter `category` of this provider.
  String get category;
}

class _FoodsByCategoryProviderElement
    extends AutoDisposeFutureProviderElement<List<FoodModel>>
    with FoodsByCategoryRef {
  _FoodsByCategoryProviderElement(super.provider);

  @override
  String get category => (origin as FoodsByCategoryProvider).category;
}

String _$searchFoodHash() => r'2d2a2a4b838693ea00721b014950f14c63ad0b81';

/// ✅ Buscar comida (AsyncValue)
///
/// Copied from [searchFood].
@ProviderFor(searchFood)
const searchFoodProvider = SearchFoodFamily();

/// ✅ Buscar comida (AsyncValue)
///
/// Copied from [searchFood].
class SearchFoodFamily extends Family<AsyncValue<FoodModel?>> {
  /// ✅ Buscar comida (AsyncValue)
  ///
  /// Copied from [searchFood].
  const SearchFoodFamily();

  /// ✅ Buscar comida (AsyncValue)
  ///
  /// Copied from [searchFood].
  SearchFoodProvider call(
    String query,
  ) {
    return SearchFoodProvider(
      query,
    );
  }

  @override
  SearchFoodProvider getProviderOverride(
    covariant SearchFoodProvider provider,
  ) {
    return call(
      provider.query,
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
  String? get name => r'searchFoodProvider';
}

/// ✅ Buscar comida (AsyncValue)
///
/// Copied from [searchFood].
class SearchFoodProvider extends AutoDisposeFutureProvider<FoodModel?> {
  /// ✅ Buscar comida (AsyncValue)
  ///
  /// Copied from [searchFood].
  SearchFoodProvider(
    String query,
  ) : this._internal(
          (ref) => searchFood(
            ref as SearchFoodRef,
            query,
          ),
          from: searchFoodProvider,
          name: r'searchFoodProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchFoodHash,
          dependencies: SearchFoodFamily._dependencies,
          allTransitiveDependencies:
              SearchFoodFamily._allTransitiveDependencies,
          query: query,
        );

  SearchFoodProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<FoodModel?> Function(SearchFoodRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchFoodProvider._internal(
        (ref) => create(ref as SearchFoodRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FoodModel?> createElement() {
    return _SearchFoodProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchFoodProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SearchFoodRef on AutoDisposeFutureProviderRef<FoodModel?> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchFoodProviderElement
    extends AutoDisposeFutureProviderElement<FoodModel?> with SearchFoodRef {
  _SearchFoodProviderElement(super.provider);

  @override
  String get query => (origin as SearchFoodProvider).query;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
