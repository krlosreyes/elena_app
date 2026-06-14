// SPEC-196 — implementación por defecto "todo Free".
//
// Es el `billingServiceProvider` activo MIENTRAS el cobro no está habilitado
// (sin SDK ni keys configuradas). Hace que la app compile y corra tratando a
// todos como Free. En SPEC-196 inc2, `main.dart` sobreescribe el provider con
// `RevenueCatBillingService`. Dart puro — sin dependencias del SDK.

import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

class FreeBillingService implements BillingService {
  const FreeBillingService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> login(String appUserId) async {}

  @override
  Future<void> logout() async {}

  @override
  Stream<EntitlementStatus> customerInfoStream() =>
      Stream<EntitlementStatus>.value(const EntitlementStatus.free());

  @override
  Future<List<BillingPackage>> currentOfferingPackages() async => const [];

  @override
  Future<PurchaseResult> purchase(BillingPackage pkg) async =>
      PurchaseResult.error('El cobro aún no está habilitado.');

  @override
  Future<PurchaseResult> restore() async =>
      PurchaseResult.success(const EntitlementStatus.free());

  // SPEC-213: no-op — FreeBillingService no tiene recursos que liberar.
  @override
  void dispose() {}
}
