// SPEC-196 inc2 — implementación real de BillingService con RevenueCat.
//
// ÚNICO archivo de la app que importa `purchases_flutter`. El resto del código
// depende de la interfaz `BillingService` (application). Mapea los tipos del
// SDK a los del dominio (EntitlementStatus, BillingPackage) y nunca propaga
// excepciones del SDK a la UI sin envolverlas en PurchaseResult.
//
// La key pública por plataforma se inyecta desde main.dart (vía --dart-define).

import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart'
    hide PurchaseResult;

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

/// Identificador del entitlement en el dashboard de RevenueCat (SPEC-196 §2.2).
const String kPremiumEntitlementId = 'premium';

class RevenueCatBillingService implements BillingService {
  RevenueCatBillingService({required this.apiKey, this.debugLogging = false});

  /// Public SDK key de la plataforma actual (iOS o Android).
  final String apiKey;
  final bool debugLogging;

  final _controller = StreamController<EntitlementStatus>.broadcast();
  final Map<String, Package> _packageCache = {};
  EntitlementStatus _last = const EntitlementStatus.free();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (debugLogging) await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener((info) {
        _last = _mapCustomerInfo(info);
        _controller.add(_last);
      });
      // Sembrar el estado inicial.
      final info = await Purchases.getCustomerInfo();
      _last = _mapCustomerInfo(info);
      _controller.add(_last);
      _initialized = true;
    } catch (e) {
      // Degradación segura: si el SDK no arranca, todos quedan Free.
      AppLogger.warning('RevenueCat no se inicializó (se queda Free): $e');
      _controller.add(const EntitlementStatus.free());
    }
  }

  @override
  Future<void> login(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
    } catch (e) {
      AppLogger.warning('RevenueCat login falló: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      // logOut lanza si ya es anónimo — no es un error real.
      AppLogger.debug('RevenueCat logout: $e');
    }
  }

  @override
  Stream<EntitlementStatus> customerInfoStream() async* {
    yield _last;
    yield* _controller.stream;
  }

  @override
  Future<List<BillingPackage>> currentOfferingPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return const [];
      _packageCache
        ..clear()
        ..addEntries(current.availablePackages.map((p) => MapEntry(p.identifier, p)));
      return current.availablePackages.map(_mapPackage).toList();
    } catch (e) {
      AppLogger.warning('RevenueCat getOfferings falló: $e');
      return const [];
    }
  }

  @override
  Future<PurchaseResult> purchase(BillingPackage pkg) async {
    try {
      var rcPkg = _packageCache[pkg.id];
      if (rcPkg == null) {
        await currentOfferingPackages(); // repoblar caché
        rcPkg = _packageCache[pkg.id];
      }
      if (rcPkg == null) {
        return PurchaseResult.error('Paquete no disponible.');
      }
      final result = await Purchases.purchasePackage(rcPkg);
      final status = _mapCustomerInfo(result.customerInfo);
      _last = status;
      _controller.add(status);
      return PurchaseResult.success(status);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled();
      }
      return PurchaseResult.error(e.message ?? 'Error de compra.');
    } catch (e) {
      return PurchaseResult.error('$e');
    }
  }

  @override
  Future<PurchaseResult> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final status = _mapCustomerInfo(info);
      _last = status;
      _controller.add(status);
      return PurchaseResult.success(status);
    } catch (e) {
      return PurchaseResult.error('No se pudieron restaurar las compras: $e');
    }
  }

  // ─── Mapeo SDK → dominio ──────────────────────────────────────────────────

  EntitlementStatus _mapCustomerInfo(CustomerInfo info) {
    final ent = info.entitlements.all[kPremiumEntitlementId];
    if (ent == null || !ent.isActive) return const EntitlementStatus.free();

    final exp = ent.expirationDate != null
        ? DateTime.tryParse(ent.expirationDate!)
        : null;
    final isTrial = ent.periodType == PeriodType.trial ||
        ent.periodType == PeriodType.intro;

    return EntitlementStatus(
      isPremium: true,
      willRenew: ent.willRenew,
      expiration: exp,
      activeProductId: ent.productIdentifier,
      source: isTrial ? EntitlementSource.trial : EntitlementSource.paid,
    );
  }

  BillingPackage _mapPackage(Package p) {
    final sp = p.storeProduct;
    return BillingPackage(
      id: p.identifier,
      productId: sp.identifier,
      title: sp.title,
      priceString: sp.priceString,
      period: _mapPeriod(p.packageType),
    );
  }

  BillingPeriod _mapPeriod(PackageType type) {
    switch (type) {
      case PackageType.monthly:
        return BillingPeriod.monthly;
      case PackageType.annual:
        return BillingPeriod.annual;
      default:
        return BillingPeriod.unknown;
    }
  }

  void dispose() => _controller.close();
}
