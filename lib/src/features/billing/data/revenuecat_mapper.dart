// TEST-01 (auditoría pre-producción 2026-07-11).
//
// Antes, el mapeo CustomerInfo/Package (SDK RevenueCat) → EntitlementStatus/
// BillingPackage (dominio) vivía como métodos PRIVADOS de
// RevenueCatBillingService. Al ser privados (privacidad de Dart es por
// archivo, no por clase), ningún test fuera de ese archivo podía ejercitarlos
// directamente, y la clase completa depende de la API estática
// `Purchases.*` del SDK (no mockeable con mocktail sin interceptar el
// MethodChannel interno del plugin). Resultado: 0% de cobertura sobre la
// lógica que decide si un usuario es Premium — justo la superficie con
// dinero real en juego.
//
// Este archivo extrae esa lógica de mapeo a funciones puras y públicas,
// sin ninguna dependencia de `Purchases` (solo de los tipos de datos del
// SDK, que SÍ son serializables/constructibles en Dart puro). Son ahora
// testeables de forma aislada sin necesitar un dispositivo real ni mockear
// el SDK completo.
//
// PENDIENTE (ver informe final de auditoría): escribir
// test/features/billing/revenuecat_mapper_test.dart construyendo instancias
// de CustomerInfo/EntitlementInfo/Package/StoreProduct. No se escribió en
// esta pasada porque requiere confirmar los constructores exactos del
// paquete `purchases_flutter` instalado (no se pudo ejecutar `flutter pub
// get` en el sandbox de esta sesión — ver limitación documentada en el
// informe). Es el primer paso a completar en la Mac de Carlos.

import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;

import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

/// Identificador del entitlement en el dashboard de RevenueCat (SPEC-196 §2.2).
const String kPremiumEntitlementId = 'Premium';

/// Mapea el `CustomerInfo` del SDK al `EntitlementStatus` de dominio.
///
/// Reglas (idénticas a las que ya regían dentro de
/// RevenueCatBillingService, solo relocadas):
///   - Sin entitlement 'Premium' o inactivo → Free.
///   - Con entitlement activo → Premium; `source` es `trial` si
///     `periodType` es trial/intro, `paid` en cualquier otro caso.
EntitlementStatus mapCustomerInfoToEntitlementStatus(CustomerInfo info) {
  final ent = info.entitlements.all[kPremiumEntitlementId];
  if (ent == null || !ent.isActive) return const EntitlementStatus.free();

  final exp = ent.expirationDate != null
      ? DateTime.tryParse(ent.expirationDate!)
      : null;
  final isTrial =
      ent.periodType == PeriodType.trial || ent.periodType == PeriodType.intro;

  return EntitlementStatus(
    isPremium: true,
    willRenew: ent.willRenew,
    expiration: exp,
    activeProductId: ent.productIdentifier,
    source: isTrial ? EntitlementSource.trial : EntitlementSource.paid,
  );
}

/// Mapea un `Package` del SDK al `BillingPackage` de dominio.
BillingPackage mapRevenueCatPackage(Package p) {
  final sp = p.storeProduct;
  return BillingPackage(
    id: p.identifier,
    productId: sp.identifier,
    title: sp.title,
    priceString: sp.priceString,
    period: mapRevenueCatPackageType(p.packageType),
  );
}

/// Mapea el `PackageType` del SDK al `BillingPeriod` de dominio.
BillingPeriod mapRevenueCatPackageType(PackageType type) {
  switch (type) {
    case PackageType.monthly:
      return BillingPeriod.monthly;
    case PackageType.annual:
      return BillingPeriod.annual;
    default:
      return BillingPeriod.unknown;
  }
}
