// SPEC-196 — wiring Riverpod del cobro.
//
// `billingServiceProvider` arranca con FreeBillingService (todos Free). En
// inc2, main.dart lo sobreescribe con RevenueCatBillingService ya inicializado.
// `entitlementProvider` expone el estado premium en vivo y es lo que consumen
// el gating (SPEC-197) y el paywall (SPEC-198).

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
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

// ─── Trial (SPEC-240) ────────────────────────────────────────────────────────

/// Días restantes del trial. 0 si el trial venció.
/// Si auth aún carga → 0 (sin parpadeo de banner).
/// Si auth cargó pero createdAt es null (metadata ausente) → asumimos usuario
/// nuevo y devolvemos kTrialDurationDays (caso seguro: no tiene entitlement RC).
final trialDaysRemainingProvider = Provider<int>((ref) {
  final authAsync = ref.watch(authStateProvider);
  // Mientras carga, no mostramos el banner (evita parpadeo).
  if (!authAsync.hasValue) return 0;
  final createdAt = authAsync.valueOrNull?.createdAt;
  // createdAt puede ser null si Firebase no populó metadata.creationTime
  // (ocurre en cuentas recién creadas en algunos builds). Asumimos trial
  // completo: el peor caso es darle 14 días a alguien que ya tiene cuenta
  // antigua sin metadata, pero isPremiumProvider lo corrige vía RC.
  if (createdAt == null) return kTrialDurationDays;
  final elapsed = DateTime.now().difference(createdAt).inDays;
  final remaining = kTrialDurationDays - elapsed;
  return remaining > 0 ? remaining : 0;
});

/// True durante los primeros [kTrialDurationDays] días desde el registro.
/// Si el usuario ya es premium, este provider retorna false (el trial
/// "se absorbe" — no tiene efecto sobre la UX del banner).
final isInTrialProvider = Provider<bool>((ref) {
  if (ref.watch(isPremiumProvider)) return false;
  return ref.watch(trialDaysRemainingProvider) > 0;
});

/// SPEC-197 + SPEC-240: gate de features. Los callsites lo watchean para decidir qué
/// mostrar o bloquear. Reacciona en vivo a cambios de entitlement
/// (free→premium desbloquea sin reiniciar). Trial también da acceso completo.
final featureGateProvider = Provider<FeatureGate>((ref) {
  return FeatureGate(
    isPremium: ref.watch(isPremiumProvider),
    isInTrial: ref.watch(isInTrialProvider),
  );
});
