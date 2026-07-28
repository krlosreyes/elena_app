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
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/crashlytics_service.dart';
import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/data/revenuecat_mapper.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

export 'package:elena_app/src/features/billing/data/revenuecat_mapper.dart'
    show kPremiumEntitlementId;

class RevenueCatBillingService implements BillingService {
  RevenueCatBillingService({required this.apiKey, this.debugLogging = false});

  /// Public SDK key de la plataforma actual (iOS o Android).
  final String apiKey;
  final bool debugLogging;

  final _controller = StreamController<EntitlementStatus>.broadcast();
  final Map<String, Package> _packageCache = {};
  EntitlementStatus _last = const EntitlementStatus.free();
  bool _initialized = false;
  // SPEC-213: referencia al listener para removeCustomerInfoUpdateListener en dispose().
  CustomerInfoUpdateListener? _customerInfoListener;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (debugLogging) await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      // SPEC-213: guardar referencia al listener para poder removerlo en dispose().
      _customerInfoListener = (info) {
        _last = _mapCustomerInfo(info);
        if (!_controller.isClosed) _controller.add(_last);
      };
      Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);
      // Sembrar el estado inicial.
      final info = await Purchases.getCustomerInfo();
      _last = _mapCustomerInfo(info);
      if (!_controller.isClosed) _controller.add(_last);
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
        ..addEntries(
            current.availablePackages.map((p) => MapEntry(p.identifier, p)));
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
      final result = await Purchases.purchase(PurchaseParams.package(rcPkg));
      final status = _mapCustomerInfo(result.customerInfo);
      _last = status;
      if (!_controller.isClosed) _controller.add(status);
      return PurchaseResult.success(status);
    } on PlatformException catch (e, s) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled();
      }
      // AUD-03 (auditoría pre-producción 2026-07-12): antes este catch
      // retornaba el error a la UI sin dejar rastro en AppLogger ni
      // Crashlytics — cero visibilidad de fallos de pago reales.
      AppLogger.warning('RevenueCat purchase falló (code=$code): $e');
      CrashlyticsService.recordError(e, s, reason: 'billing_purchase_failed');
      return PurchaseResult.error(e.message ?? 'Error de compra.');
    } catch (e, s) {
      AppLogger.warning('RevenueCat purchase falló: $e');
      CrashlyticsService.recordError(e, s, reason: 'billing_purchase_failed');
      return PurchaseResult.error('$e');
    }
  }

  @override
  Future<PurchaseResult> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final status = _mapCustomerInfo(info);
      _last = status;
      if (!_controller.isClosed) _controller.add(status);
      return PurchaseResult.success(status);
    } catch (e, s) {
      // AUD-03: mismo fix que purchase() — loggear antes de propagar el error.
      AppLogger.warning('RevenueCat restore falló: $e');
      CrashlyticsService.recordError(e, s, reason: 'billing_restore_failed');
      return PurchaseResult.error('No se pudieron restaurar las compras: $e');
    }
  }

  // ─── Mapeo SDK → dominio ──────────────────────────────────────────────────
  // TEST-01 (auditoría 2026-07-11): el mapeo real vive ahora en
  // revenuecat_mapper.dart (funciones puras, testeables sin mockear
  // `Purchases`). Estos métodos quedan como wrappers finos por
  // compatibilidad con el resto de esta clase.

  EntitlementStatus _mapCustomerInfo(CustomerInfo info) =>
      mapCustomerInfoToEntitlementStatus(info);

  BillingPackage _mapPackage(Package p) => mapRevenueCatPackage(p);

  // SPEC-213: cierra el StreamController y remueve el listener del SDK.
  // Llamado por ref.onDispose en billing_providers.dart.
  @override
  void dispose() {
    if (_customerInfoListener != null) {
      Purchases.removeCustomerInfoUpdateListener(_customerInfoListener!);
      _customerInfoListener = null;
    }
    if (!_controller.isClosed) _controller.close();
  }
}
