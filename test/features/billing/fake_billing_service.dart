// SPEC-196 — implementación falsa de BillingService para tests.
//
// Simula compra/restauración/logout en memoria, sin red ni SDK. La usan los
// tests de billing (inc1) y los widget tests del paywall (SPEC-198).

import 'dart:async';

import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

class FakeBillingService implements BillingService {
  FakeBillingService({List<BillingPackage>? packages})
      : _packages = packages ?? _defaultPackages;

  final List<BillingPackage> _packages;
  final _controller = StreamController<EntitlementStatus>.broadcast();
  EntitlementStatus _current = const EntitlementStatus.free();

  /// Permite a los tests forzar errores de compra.
  bool failNextPurchase = false;

  /// Permite a los tests simular que el usuario cancela.
  bool cancelNextPurchase = false;

  static final List<BillingPackage> _defaultPackages = [
    const BillingPackage(
      id: '\$rc_monthly',
      productId: 'elena_premium_monthly',
      title: 'Premium mensual',
      priceString: 'US\$9.99',
      period: BillingPeriod.monthly,
    ),
    const BillingPackage(
      id: '\$rc_annual',
      productId: 'elena_premium_annual',
      title: 'Premium anual',
      priceString: 'US\$79.99',
      period: BillingPeriod.annual,
    ),
  ];

  void _emit(EntitlementStatus s) {
    _current = s;
    _controller.add(s);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> login(String appUserId) async {}

  @override
  Future<void> logout() async => _emit(const EntitlementStatus.free());

  @override
  Stream<EntitlementStatus> customerInfoStream() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<List<BillingPackage>> currentOfferingPackages() async => _packages;

  @override
  Future<PurchaseResult> purchase(BillingPackage pkg) async {
    if (cancelNextPurchase) {
      cancelNextPurchase = false;
      return PurchaseResult.cancelled();
    }
    if (failNextPurchase) {
      failNextPurchase = false;
      return PurchaseResult.error('compra falló (fake)');
    }
    final status = EntitlementStatus(
      isPremium: true,
      willRenew: true,
      activeProductId: pkg.productId,
      source: EntitlementSource.paid,
    );
    _emit(status);
    return PurchaseResult.success(status);
  }

  @override
  Future<PurchaseResult> restore() async => PurchaseResult.success(_current);

  @override
  void dispose() => _controller.close();
}
