// SPEC-196 — wiring Riverpod del cobro.
//
// `billingServiceProvider` arranca con FreeBillingService (todos Free). En
// inc2, main.dart lo sobreescribe con RevenueCatBillingService ya inicializado.
// `entitlementProvider` expone el estado premium en vivo y es lo que consumen
// el gating (SPEC-197) y el paywall (SPEC-198).

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/application/feature_gate.dart';
import 'package:elena_app/src/features/billing/application/free_billing_service.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

/// Servicio de cobro activo. Default: Free.
/// En debug, main.dart sobreescribe con FakeBillingService (sin tienda).
/// En producción, main.dart sobreescribe con RevenueCatBillingService.
final billingServiceProvider = Provider<BillingService>(
  (ref) => const FreeBillingService(),
);

/// SPEC-197: ¿está el cobro habilitado?
/// - Debug (kDebugMode=true): `true` por defecto — gating activo sin override.
///   Así los candados son visibles en cualquier debug build, independientemente
///   de si main.dart logró aplicar el override (Xcode, caché, release scheme...).
/// - Release (kDebugMode=false): `false` por defecto — gating inerte hasta que
///   main.dart aplique el override con RC keys reales.
final billingEnabledProvider = Provider<bool>((ref) => kDebugMode);

/// Estado de entitlement en vivo. Default `free()` mientras carga o si el
/// stream falla (degradación segura: nunca regala premium por un error).
final entitlementProvider = StreamProvider<EntitlementStatus>((ref) {
  final billing = ref.watch(billingServiceProvider);
  return billing.customerInfoStream();
});

/// Helper booleano síncrono para gating rápido (SPEC-197). Free mientras carga.
/// Si el cobro NO está habilitado, devuelve `true` (gating inerte) para no
/// bloquear features antes de lanzar la monetización.
final isPremiumProvider = Provider<bool>((ref) {
  if (!ref.watch(billingEnabledProvider)) return true;
  return ref.watch(entitlementProvider).maybeWhen(
        data: (s) => s.isPremium,
        orElse: () => false,
      );
});

/// SPEC-197: gate de features. Los callsites lo watchean para decidir qué
/// mostrar o bloquear. Reacciona en vivo a cambios de entitlement
/// (free→premium desbloquea sin reiniciar).
final featureGateProvider = Provider<FeatureGate>((ref) {
  return FeatureGate(isPremium: ref.watch(isPremiumProvider));
});
