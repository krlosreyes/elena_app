// SPEC-196 — wiring Riverpod del cobro.
//
// `billingServiceProvider` arranca con FreeBillingService (todos Free). En
// inc2, main.dart lo sobreescribe con RevenueCatBillingService ya inicializado.
// `entitlementProvider` expone el estado premium en vivo y es lo que consumen
// el gating (SPEC-197) y el paywall (SPEC-198).

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
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
  final elapsed = _trialClockNow(ref).difference(createdAt).inDays;
  final remaining = kTrialDurationDays - elapsed;
  return remaining > 0 ? remaining : 0;
});

/// SEC-02 (auditoría 2026-07-11): `DateTime.now()` es manipulable por el
/// usuario — basta con atrasar el reloj del dispositivo para que `elapsed`
/// nunca avance y el trial de [kTrialDurationDays] días no expire jamás.
///
/// Mitigación client-side (no reemplaza una validación server-side, que
/// sigue siendo la corrección definitiva recomendada en la auditoría vía
/// Cloud Function con hora de servidor — pendiente, ver checklist P1):
/// se persiste en SharedPreferences la mayor hora "vista" en este
/// dispositivo (high-water-mark). El `now` efectivo usado para calcular
/// el trial nunca retrocede respecto de esa marca, aunque el usuario
/// retrase el reloj después. Esto bloquea el ataque casual de "atrasar
/// el reloj para congelar el trial" sin tocar backend.
///
/// Si `sharedPreferencesProvider` no está disponible (tests que no lo
/// overridean), se degrada silenciosamente a `DateTime.now()` sin HWM —
/// no rompe ningún test existente, solo pierde la protección en ese caso.
///
/// ACTUALIZACIÓN (2026-07-11): ya existe la corrección server-side —
/// `functions/src/index.ts` exporta `onUserCreated` (auth.user().onCreate),
/// que al registrar la cuenta fija `trialExpiresAt` (createdAt + 14 días,
/// calculado en el servidor) como custom claim del usuario, inmune a
/// manipulación del reloj del dispositivo. PENDIENTE conectar este archivo
/// a ese claim: no se hizo en esta pasada porque `cloud_functions` no está
/// en pubspec.yaml y no se pudo compilar/validar en este sandbox el flujo
/// de lectura (`FirebaseAuth.instance.currentUser.getIdTokenResult()`,
/// incluyendo el caso de carrera "claim aún no propagado al token recién
/// emitido" y el fallback para cuentas creadas antes de este trigger). El
/// HWM de abajo sigue siendo la única protección activa hasta que se
/// complete ese wiring.
const _trialClockHwmKey = 'trial_clock_hwm_millis';

DateTime _trialClockNow(Ref ref) {
  final now = DateTime.now();
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    final hwmMillis = prefs.getInt(_trialClockHwmKey);
    final nowMillis = now.millisecondsSinceEpoch;
    if (hwmMillis != null && hwmMillis > nowMillis) {
      // Reloj retrocedido respecto de lo ya visto: usamos la marca previa.
      return DateTime.fromMillisecondsSinceEpoch(hwmMillis);
    }
    if (hwmMillis == null || nowMillis > hwmMillis) {
      unawaited(
        prefs.setInt(_trialClockHwmKey, nowMillis).catchError((Object e) {
          AppLogger.warning('trialClockNow: no se pudo persistir HWM', e);
          return false;
        }),
      );
    }
    return now;
  } catch (_) {
    return now;
  }
}

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
