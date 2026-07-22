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

/// FIRE-01 (P1, auditoría técnica 21-jul): lee el custom claim
/// `trialExpiresAt` del ID token del usuario autenticado (ver doc
/// completa en `auth_repository.dart` y `functions/src/index.ts`).
///
/// Se pide con `forceRefresh: true` porque, justo después del signup, el
/// primer token del cliente puede no incluir el claim todavía (el
/// trigger `onUserCreated` corre server-side, en paralelo, no antes del
/// primer token) — sin forzar el refresh, un usuario nuevo podría no ver
/// nunca el claim hasta su próximo login natural.
///
/// Solo se dispara cuando hay un uid (evita tocar el repository — y por
/// lo tanto Firebase — mientras auth sigue cargando o no hay sesión, el
/// mismo criterio de corte que ya usa `trialDaysRemainingProvider`).
/// Si falla o el claim no existe, resuelve a `null` — el provider de
/// abajo cae al cálculo local (HWM) sin cambiar el comportamiento previo
/// a este fix.
final trialExpiresAtClaimProvider = FutureProvider<int?>((ref) async {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return null;
  return ref.read(authRepositoryProvider).getTrialExpiresAtClaimMillis(
        forceRefresh: true,
      );
});

/// Días restantes del trial. 0 si el trial venció.
/// Si auth aún carga → 0 (sin parpadeo de banner).
/// Si auth cargó pero createdAt es null (metadata ausente) → asumimos usuario
/// nuevo y devolvemos kTrialDurationDays (caso seguro: no tiene entitlement RC).
final trialDaysRemainingProvider = Provider<int>((ref) {
  final authAsync = ref.watch(authStateProvider);
  // Mientras carga, no mostramos el banner (evita parpadeo).
  if (!authAsync.hasValue) return 0;

  // FIRE-01: si el claim server-side ya está disponible, se usa como
  // fuente de la fecha de creación real en vez de `AppAccount.createdAt`
  // (metadata local de Firebase Auth, vulnerable a reinstalar la app —
  // ver nota en billing_providers.dart de la auditoría del 11-jul). El
  // resto de la fórmula (elapsed/remaining) queda IDÉNTICO al cálculo
  // previo: solo cambia de qué timestamp de "creación" parte, no cómo se
  // calculan los días restantes. Mientras el claim carga o no existe
  // (`valueOrNull` es null en loading/error/ausente), se preserva el
  // comportamiento exacto de antes de este fix.
  final claimMillis = ref.watch(trialExpiresAtClaimProvider).valueOrNull;
  final createdAt = claimMillis != null
      ? DateTime.fromMillisecondsSinceEpoch(claimMillis)
          .subtract(const Duration(days: kTrialDurationDays))
      : authAsync.valueOrNull?.createdAt;

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
/// manipulación del reloj del dispositivo.
///
/// ACTUALIZACIÓN (FIRE-01, 21-jul): ya está conectado. `AuthRepository`
/// gana `getTrialExpiresAtClaimMillis()` (implementado con
/// `User.getIdTokenResult()` de `firebase_auth`, ya en pubspec.yaml —
/// NO se necesitó agregar el paquete `cloud_functions`, la lectura del
/// claim no pasa por una Cloud Function callable, solo por el token ya
/// emitido). Ver `trialExpiresAtClaimProvider` arriba: hace
/// `forceRefresh: true` para cubrir el caso de carrera del signup, y
/// `trialDaysRemainingProvider` lo usa como fuente de `createdAt` cuando
/// está disponible. El HWM de abajo sigue activo como respaldo mientras
/// el claim no exista (cuentas viejas) o la lectura falle (sin red).
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
