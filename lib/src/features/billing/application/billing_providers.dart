// SPEC-196 — wiring Riverpod del cobro.
//
// `billingServiceProvider` arranca con FreeBillingService (todos Free). En
// inc2, main.dart lo sobreescribe con RevenueCatBillingService ya inicializado.
// `entitlementProvider` expone el estado premium en vivo y es lo que consumen
// el gating (SPEC-197) y el paywall (SPEC-198).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/application/free_billing_service.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

/// Servicio de cobro activo. Default: Free. Se sobreescribe en main.dart
/// (inc2) con la implementación real de RevenueCat.
final billingServiceProvider = Provider<BillingService>(
  (ref) => const FreeBillingService(),
);

/// Estado de entitlement en vivo. Default `free()` mientras carga o si el
/// stream falla (degradación segura: nunca regala premium por un error).
final entitlementProvider = StreamProvider<EntitlementStatus>((ref) {
  final billing = ref.watch(billingServiceProvider);
  return billing.customerInfoStream();
});

/// Helper booleano síncrono para gating rápido (SPEC-197). Free mientras carga.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(entitlementProvider).maybeWhen(
        data: (s) => s.isPremium,
        orElse: () => false,
      );
});
