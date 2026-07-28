// SPEC-141 §RF-141-12 (2026-06-05): WeeklyImrSnapshotService.
//
// Coordina los 3 gatillos de cadencia semanal del IMR longitudinal:
//   A — check-in biométrico manual (siempre dispara, ignora staleness)
//   B — sync nuevo HealthKit (deferred a SPEC-141.2)
//   C — staleness fallback al login (>7 días desde el último snapshot)
//
// En este Bloque B la persistencia es PARCIAL: el service actualiza
// `users/{uid}.imr.current` (cache de lectura rápida usada por Profile
// y el sitio web Metamorfosis Real). La escritura a la subcollection
// `imr_history/{weekISO}` se introduce en Bloque C — el método público
// `recomputeAndPersist` ya recibe el `IMRv2Result` correcto, solo el
// callsite a `imr_history` se completa en C.
//
// CONSTITUTION §3.2: el service NO importa cloud_firestore. Solo
// conoce la interfaz `UserProfileRepository`. La persistencia atómica
// vive en `user_profile_repository_impl.dart`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/shared/data/mappers/user_profile_mapper.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';

/// Gatillo que provocó el recálculo del snapshot. Persistido como
/// metadata del último escrito, útil para debugging y telemetría
/// futura.
enum WeeklyImrTrigger {
  /// Gatillo A — el usuario hizo un check-in biométrico manual.
  /// Siempre dispara recálculo (el usuario explícitamente entregó
  /// data nueva). Ignora staleness.
  biometricCheckin,

  /// Gatillo C — al abrir la app, han pasado >7 días desde
  /// `imr.current.computedAt`. Recálculo automático.
  stalenessFallback,
}

/// SPEC-141 §RF-141-12: período de staleness antes de re-snapshot
/// automático al login.
const Duration kWeeklyImrStaleness = Duration(days: 7);

/// SPEC-141 §RF-141-12 (2026-06-05): construye el ISO week id usado
/// como doc id en `imr_history`. Formato: `YYYY-WNN`.
///
/// Algoritmo: ISO 8601 §3.2.1 — la semana 1 es la que contiene el
/// primer jueves del año. Implementación basada en el patrón de la
/// MDN reference (https://en.wikipedia.org/wiki/ISO_week_date).
String buildWeekISO(DateTime dt) {
  // Move to nearest Thursday for ISO week.
  final thursday = dt.add(Duration(days: 4 - ((dt.weekday + 6) % 7 + 1)));
  final firstThursday = DateTime(thursday.year, 1, 4).add(Duration(
    days: 4 - ((DateTime(thursday.year, 1, 4).weekday + 6) % 7 + 1),
  ));
  final week = 1 + ((thursday.difference(firstThursday).inDays) / 7).round();
  return '${thursday.year.toString().padLeft(4, '0')}-W'
      '${week.toString().padLeft(2, '0')}';
}

class WeeklyImrSnapshotService {
  WeeklyImrSnapshotService({
    required UserProfileRepository userProfileRepo,
    DateTime Function() clock = _systemClock,
  })  : _userProfileRepo = userProfileRepo,
        _clock = clock;

  final UserProfileRepository _userProfileRepo;
  final DateTime Function() _clock;

  static DateTime _systemClock() => DateTime.now();

  /// Recalcula el IMR longitudinal y persiste el snapshot en
  /// `imr.current` cache. El caller (provider de gatillo) ya tiene el
  /// `IMRv2Result` computado vía `longitudinalImrProvider` y lo pasa
  /// acá para evitar acoplar este servicio a Riverpod.
  ///
  /// Idempotente — si el `IMRv2Result.longitudinalScore` es null,
  /// no-op (caso usuario sin lastMealTime aún).
  ///
  /// Bloque C agregará la escritura adicional a
  /// `users/{uid}/imr_history/{weekISO}` con la metadata del trigger.
  Future<void> recomputeAndPersist({
    required String userId,
    required IMRv2Result longitudinal,
    required WeeklyImrTrigger trigger,
  }) async {
    if (longitudinal.longitudinalScore == null) {
      AppLogger.debug(
        '[WeeklyImrSnapshot] skip — longitudinalScore null '
        '(state aún sin lastMealTime)',
      );
      return;
    }
    try {
      // SPEC-141 §RF-141-12 Bloque C (2026-06-05): el shape canónico
      // ya viene con schemaVersion=2, legacyDailyScore y subscores
      // poblados via `imrToCanonicalMap` (que detecta el longitudinal
      // por presencia de `longitudinalScore`). Acá agregamos metadata
      // del evento (`computedAt`, `trigger`, `weekISO`).
      final now = _clock();
      final weekISO = buildWeekISO(now);
      final canonical = imrToCanonicalMap(longitudinal);
      canonical['computedAt'] = now.toUtc().toIso8601String();
      canonical['trigger'] = trigger.name;
      canonical['weekISO'] = weekISO;

      // 1. Cache de lectura rápida (Profile, sitio web).
      await _userProfileRepo.updateCurrentImr(userId, canonical);

      // 2. SPEC-141 §RF-141-12 Bloque C: snapshot semanal persistente.
      // Doc id = weekISO → idempotente; re-snapshots en la misma
      // semana sobreescriben sin duplicar.
      await _userProfileRepo.writeImrHistorySnapshot(
        userId: userId,
        weekISO: weekISO,
        snapshot: canonical,
      );

      AppLogger.info(
        '[WeeklyImrSnapshot] persistido — trigger=${trigger.name} '
        'score=${longitudinal.longitudinalScore} weekISO=$weekISO',
      );
    } catch (e, st) {
      AppLogger.error('[WeeklyImrSnapshot] falló persistencia', e, st);
    }
  }

  /// Decide si debe recalcular por staleness. Lee `imr.current.computedAt`
  /// del cache; si no existe o pasó más de `kWeeklyImrStaleness` desde
  /// ese momento, retorna true.
  ///
  /// El caller hace la lectura de `lastComputedAt` para evitar que el
  /// service consuma el provider del cache (mantiene la dependencia
  /// inyectada).
  bool isSnapshotStale({DateTime? lastComputedAt}) {
    if (lastComputedAt == null) return true;
    final now = _clock();
    return now.difference(lastComputedAt) >= kWeeklyImrStaleness;
  }
}

/// SPEC-141 §RF-141-12: Provider del service. Singleton durante la
/// sesión (sin autoDispose) — preserva el clock inyectable para tests.
final weeklyImrSnapshotServiceProvider =
    Provider<WeeklyImrSnapshotService>((ref) {
  final repo = ref.watch(userProfileRepositoryProvider);
  return WeeklyImrSnapshotService(userProfileRepo: repo);
});
