// SPEC-196 — wiring Riverpod del cobro.
//
// `billingServiceProvider` arranca con FreeBillingService (todos Free). En
// inc2, main.dart lo sobreescribe con RevenueCatBillingService ya inicializado.
// `entitlementProvider` expone el estado premium en vivo y es lo que consumen
// el gating (SPEC-197) y el paywall (SPEC-198).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/application/feature_gate.dart';
import 'package:elena_app/src/features/billing/application/free_billing_service.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

/// Servicio de cobro activo. Default: Free. Se sobreescribe en main.dart
/// (inc2) con la implementación real de RevenueCat.
final billingServiceProvider = Provider<BillingService>(
  (ref) => const FreeBillingService(),
);

/// SPEC-197: ¿está el cobro habilitado (RevenueCat configurado con keys)?
/// Default `false`. main.dart lo sobreescribe a `true` cuando inicializa
/// RevenueCat. Mientras es `false`, el gating queda INERTE (todos se tratan
/// como premium) para que la app funcione completa antes de lanzar el cobro.
final billingEnabledProvider = Provider<bool>((ref) => false);

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
