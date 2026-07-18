// TEST-01 (auditoría pre-producción 2026-07-11).
//
// Cubre las funciones puras de revenuecat_mapper.dart (mapCustomerInfo
// ToEntitlementStatus, mapRevenueCatPackage, mapRevenueCatPackageType), que
// antes vivían como métodos privados de RevenueCatBillingService y no tenían
// ningún test (ver historial de comentarios en revenuecat_mapper.dart).
//
// Las instancias de CustomerInfo/EntitlementInfo/EntitlementInfos/Package/
// StoreProduct/PresentedOfferingContext del SDK `purchases_flutter` se
// construyen aquí usando los constructores PÚBLICOS reales de la versión
// 10.2.2 (la que fija pubspec.yaml), verificados leyendo el código fuente
// tageado en https://github.com/RevenueCat/purchases-flutter/tree/10.2.2/lib/models
// (no se pudo ejecutar `flutter pub get` en el sandbox de esta sesión para
// leer el paquete cacheado localmente, así que se confirmó cada firma
// contra el repo oficial en el tag exacto instalado, no por memoria).

import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;

import 'package:elena_app/src/features/billing/data/revenuecat_mapper.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

/// Construye un CustomerInfo mínimo con el entitlement 'Premium' que se le
/// pase (o sin entitlements si `all` es {}). Los campos no relevantes para
/// el mapeo (fechas de compra, ids de usuario, etc.) llevan valores dummy
/// pero con el tipo/formato exacto que exige el constructor real del SDK.
CustomerInfo _customerInfo(Map<String, EntitlementInfo> all) {
  return CustomerInfo(
    EntitlementInfos(all, const <String, EntitlementInfo>{}),
    const <String, String?>{},
    const <String>[],
    const <String>[],
    const [],
    '2026-01-01T00:00:00Z',
    'user_123',
    const <String, String?>{},
    '2026-07-11T00:00:00Z',
  );
}

EntitlementInfo _entitlement({
  required bool isActive,
  required bool willRenew,
  PeriodType periodType = PeriodType.normal,
  String? expirationDate = '2026-08-11T00:00:00Z',
  String productIdentifier = 'elena_premium_monthly',
}) {
  return EntitlementInfo(
    kPremiumEntitlementId,
    isActive,
    willRenew,
    '2026-01-01T00:00:00Z',
    '2026-01-01T00:00:00Z',
    productIdentifier,
    false,
    periodType: periodType,
    expirationDate: expirationDate,
  );
}

Package _package({
  required PackageType packageType,
  required String identifier,
  required String productId,
  required String title,
  required String priceString,
}) {
  final storeProduct = StoreProduct(
    productId,
    'Descripción de prueba',
    title,
    9.99,
    priceString,
    'USD',
  );
  const offeringContext = PresentedOfferingContext('default', null, null);
  return Package(identifier, packageType, storeProduct, offeringContext);
}

void main() {
  group('mapCustomerInfoToEntitlementStatus', () {
    test('entitlement activo pagado → Premium con source paid', () {
      final info = _customerInfo({
        kPremiumEntitlementId: _entitlement(isActive: true, willRenew: true),
      });

      final status = mapCustomerInfoToEntitlementStatus(info);

      expect(status.isPremium, true);
      expect(status.willRenew, true);
      expect(status.source, EntitlementSource.paid);
      expect(status.activeProductId, 'elena_premium_monthly');
      expect(status.expiration, DateTime.tryParse('2026-08-11T00:00:00Z'));
    });

    test('entitlement activo en trial → source trial', () {
      final info = _customerInfo({
        kPremiumEntitlementId: _entitlement(
          isActive: true,
          willRenew: true,
          periodType: PeriodType.trial,
        ),
      });

      final status = mapCustomerInfoToEntitlementStatus(info);

      expect(status.isPremium, true);
      expect(status.source, EntitlementSource.trial);
      expect(status.isTrial, true);
    });

    test('entitlement activo en intro → también cuenta como trial', () {
      final info = _customerInfo({
        kPremiumEntitlementId: _entitlement(
          isActive: true,
          willRenew: true,
          periodType: PeriodType.intro,
        ),
      });

      final status = mapCustomerInfoToEntitlementStatus(info);

      expect(status.source, EntitlementSource.trial);
    });

    test('entitlement expirado (isActive=false) → Free', () {
      final info = _customerInfo({
        kPremiumEntitlementId: _entitlement(isActive: false, willRenew: false),
      });

      final status = mapCustomerInfoToEntitlementStatus(info);

      expect(status, const EntitlementStatus.free());
    });

    test('sin entitlement Premium en el mapa → Free', () {
      final info = _customerInfo(const <String, EntitlementInfo>{});

      final status = mapCustomerInfoToEntitlementStatus(info);

      expect(status, const EntitlementStatus.free());
    });
  });

  group('mapRevenueCatPackage / mapRevenueCatPackageType', () {
    test('paquete mensual se mapea a BillingPeriod.monthly', () {
      final pkg = _package(
        packageType: PackageType.monthly,
        identifier: '\$rc_monthly',
        productId: 'elena_premium_monthly',
        title: 'Premium mensual',
        priceString: 'US\$9.99',
      );

      final result = mapRevenueCatPackage(pkg);

      expect(
        result,
        const BillingPackage(
          id: '\$rc_monthly',
          productId: 'elena_premium_monthly',
          title: 'Premium mensual',
          priceString: 'US\$9.99',
          period: BillingPeriod.monthly,
        ),
      );
    });

    test('paquete anual se mapea a BillingPeriod.annual', () {
      final pkg = _package(
        packageType: PackageType.annual,
        identifier: '\$rc_annual',
        productId: 'elena_premium_annual',
        title: 'Premium anual',
        priceString: 'US\$79.99',
      );

      final result = mapRevenueCatPackage(pkg);

      expect(result.period, BillingPeriod.annual);
      expect(result.productId, 'elena_premium_annual');
    });

    test('un PackageType no mapeado explícitamente cae en unknown', () {
      expect(mapRevenueCatPackageType(PackageType.weekly), BillingPeriod.unknown);
      expect(mapRevenueCatPackageType(PackageType.lifetime), BillingPeriod.unknown);
    });
  });
}
