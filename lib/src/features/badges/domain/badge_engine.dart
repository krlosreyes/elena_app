// Sistema de insignias (2026-07-15) — motor puro que decide QUÉ insignias
// nuevas corresponden dado el estado real del usuario. Sin Firestore, sin
// Riverpod — mismo espíritu que StreakEngine: fácil de testear, sin
// efectos secundarios.
//
// IMPORTANTE — historial "ancho", no el de 90 días del Dashboard:
// `StreakNotifier` carga solo los últimos 90 días de `streak_history`
// (ver comentario en streak_repository_impl.dart, SPEC-141). Para
// insignias con umbrales altos (ej. racha_365, ayuno_150) eso
// subcontaría a un usuario veterano. `BadgeEngine` recibe un historial
// SIN ese recorte — `BadgeNotifier` lo pide con una consulta propia
// (mismo `FirestoreStreakV1Source.streamSince`, pero con un cutoff muy
// antiguo en vez de 90 días) para no depender del historial ya acotado
// que usa el resto del Dashboard.
//
// Por qué esto es seguro de recalcular (a diferencia de `qualifiesForStreak`,
// que si es una REGLA que podría cambiar): acá solo se CUENTAN hechos ya
// guardados (¿ese día se completó el pilar de ayuno? ¿el IMR fue ≥60?),
// no se reinterpreta ninguna regla de negocio. Si mañana se agrega un
// nivel nuevo a una categoría, el conteo de días ya completados sigue
// siendo válido — nunca le quita una insignia a nadie, solo puede sumar.

import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/badges/domain/earned_badge.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/progress/domain/biometric_delta.dart';
import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

class BadgeEngine {
  BadgeEngine._();

  /// Evalúa el estado completo y devuelve solo las insignias NUEVAS
  /// (que no están en [alreadyUnlockedIds]) que ya corresponden ahora.
  ///
  /// [fullStreakHistory]: historial de racha SIN recorte de 90 días.
  /// [biometricHistory]: historial biométrico (ya sin recorte agresivo —
  /// `BiometricRepository.watchHistory` por defecto trae hasta 2000 docs).
  /// [alreadyUnlockedIds]: badgeId de las insignias que el usuario ya tiene
  /// en Firestore — evita re-evaluar/re-emitir las que ya se ganaron.
  static List<EarnedBadge> evaluate({
    required List<StreakEntry> fullStreakHistory,
    required List<BiometricCheckIn> biometricHistory,
    required Set<String> alreadyUnlockedIds,
  }) {
    final now = DateTime.now();
    final newly = <EarnedBadge>[];

    bool isNew(String badgeId) => !alreadyUnlockedIds.contains(badgeId);

    void checkThresholdCategory(String category, int actualCount, {String contextKey = 'daysCompleted'}) {
      for (final def in BadgeCatalog.forCategory(category)) {
        if (isNew(def.badgeId) && actualCount >= def.threshold) {
          newly.add(EarnedBadge(
            badgeId: def.badgeId,
            category: category,
            level: def.level,
            unlockedAt: now,
            contextSnapshot: {contextKey: actualCount},
          ));
        }
      }
    }

    // ── Bienvenida: el primer pilar del primer día ──────────────────────
    if (isNew('bienvenida_1') &&
        fullStreakHistory.any((e) => e.pillarsCompleted >= 1)) {
      newly.add(EarnedBadge(
        badgeId: 'bienvenida_1',
        category: BadgeCategory.bienvenida,
        level: 1,
        unlockedAt: now,
      ));
    }

    // ── Racha: mejor racha histórica (no la actual — una insignia no se
    // pierde si la racha se rompe después de haberla ganado) ───────────
    final longest = StreakEngine.computeLongestStreak(fullStreakHistory);
    checkThresholdCategory(BadgeCategory.racha, longest, contextKey: 'streakLength');

    // ── 5 pilares: días completados (dato booleano ya validado) ─────────
    checkThresholdCategory(
      BadgeCategory.ayuno,
      fullStreakHistory.where((e) => e.fastingCompleted).length,
    );
    checkThresholdCategory(
      BadgeCategory.sueno,
      fullStreakHistory.where((e) => e.sleepCompleted).length,
    );
    checkThresholdCategory(
      BadgeCategory.hidratacion,
      fullStreakHistory.where((e) => e.hydrationCompleted).length,
    );
    checkThresholdCategory(
      BadgeCategory.ejercicio,
      fullStreakHistory.where((e) => e.exerciseLogged).length,
    );
    checkThresholdCategory(
      BadgeCategory.nutricion,
      fullStreakHistory.where((e) => e.nutritionLogged).length,
    );

    // ── Transformación: días con IMR ≥ 60 ────────────────────────────────
    checkThresholdCategory(
      BadgeCategory.imr,
      fullStreakHistory.where((e) => e.imrScore >= 60).length,
    );

    // ── Autoconocimiento: check-ins REALES (excluye backfill/baseline/
    // sync automático — solo cuenta cuando el usuario mismo lo hizo desde
    // el sheet de check-in, para que la insignia sea "pertinente" y no
    // un artefacto de datos generados por el sistema) ───────────────────
    final realCheckIns = biometricHistory
        .where((c) => c.source == BiometricSource.checkinSheet)
        .length;
    checkThresholdCategory(BadgeCategory.checkin, realCheckIns, contextKey: 'checkIns');

    // ── Resiliencia: volviste a 7+ días de racha después de haber roto
    // una racha más larga. Un solo nivel — usa datos ya calculados por
    // StreakEngine (computeLongestStreak + computeCurrentStreakWithFreezes),
    // sin reimplementar la reconstrucción día a día del historial. ───────
    if (isNew('resiliencia_1')) {
      final currentProtected =
          StreakEngine.computeCurrentStreakWithFreezes(fullStreakHistory)
              .currentStreak;
      if (currentProtected >= 7 && longest > currentProtected) {
        newly.add(EarnedBadge(
          badgeId: 'resiliencia_1',
          category: BadgeCategory.resiliencia,
          level: 1,
          unlockedAt: now,
          contextSnapshot: {
            'currentStreak': currentProtected,
            'longestStreak': longest,
          },
        ));
      }
    }

    return newly;
  }
}
