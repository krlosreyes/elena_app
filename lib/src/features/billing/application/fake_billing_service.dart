// SPEC-197/198 — servicio de cobro falso para pruebas en device.
//
// Permite validar el gating (SPEC-197) y el paywall (SPEC-198) sin tener
// los productos configurados en App Store / RevenueCat. Se activa con:
//
//   flutter run --dart-define=BILLING_FAKE=true
//
// Comportamiento:
//   - Arranca como Free (billingEnabledProvider=true, gating activo).
//   - `currentOfferingPackages()` devuelve 2 packages ficticios con
//     precios de muestra (mensual y anual).
//   - `purchase(pkg)` emite Premium (source=trial, 14 días) y retorna
//     `PurchaseResult.success`. Simula el trial de SPEC-198.
//   - `restore()` retorna Premium si ya se "compró" en esta sesión;
//     Free si no.
//
// NOTA: este archivo vive en lib/ (no test/) porque `main.dart` necesita
// referenciarlo en builds de debug. NUNCA incluir RC keys aquí.

import 'dart:async';

import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

class FakeBillingService implements BillingService {
  FakeBillingService() {
    _controller = StreamController<EntitlementStatus>.broadcast();
    _controller.add(const EntitlementStatus.free());
  }

  late final StreamController<EntitlementStatus> _controller;
  EntitlementStatus _current = const EntitlementStatus.free();

  // Emite el estado actual inmediatamente y luego los cambios futuros.
  // El generador async* garantiza que cada nuevo suscriptor (el StreamProvider
  // de Riverpod) reciba el valor actual aunque se suscriba después del
  // constructor — los broadcast streams descartarían el evento inicial.
  @override
  Stream<EntitlementStatus> customerInfoStream() async* {
    yield _current;
    yield* _controller.stream;
  }

  static final List<BillingPackage> _fakePackages = [
    const BillingPackage(
      id: r'$rc_monthly',
      productId: 'elena_premium_monthly',
      title: 'Mensual',
      priceString: 'US\$4.99/mes',
      period: BillingPeriod.monthly,
    ),
    const BillingPackage(
      id: r'$rc_annual',
      productId: 'elena_premium_annual',
      title: 'Anual',
      priceString: 'US\$39.99/año',
      period: BillingPeriod.annual,
    ),
  ];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> login(String appUserId) async {}

  @override
  Future<void> logout() async {
    _current = const EntitlementStatus.free();
    _controller.add(_current);
  }

  @override
  Future<List<BillingPackage>> currentOfferingPackages() async =>
      _fakePackages;

  @override
  Future<PurchaseResult> purchase(BillingPackage pkg) async {
    // Simula latencia de la tienda.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _current = EntitlementStatus(
      isPremium: true,
      willRenew: true,
      expiration: DateTime.now().add(const Duration(days: 14)),
      activeProductId: pkg.productId,
      source: EntitlementSource.trial,
    );
    _controller.add(_current);
    return PurchaseResult.success(_current);
  }

  @override
  Future<PurchaseResult> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (_current.isPremium) {
      return PurchaseResult.success(_current);
    }
    return PurchaseResult.success(const EntitlementStatus.free());
  }

  @override
  void dispose() {
    _controller.close();
  }
}
