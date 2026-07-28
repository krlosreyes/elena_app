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

/// Propuesta "Avances / Tu camino" (15-jul): insignia no ganada más
/// cercana en una categoría de progreso contable, para mostrar como
/// próxima meta en la línea de tiempo ("te faltan N días").
class BadgeProgress {
  final BadgeDefinition definition;
  final int currentValue;

  /// Siempre > 0 — cuánto falta para alcanzar [definition.threshold].
  final int remaining;

  const BadgeProgress({
    required this.definition,
    required this.currentValue,
    required this.remaining,
  });
}

class BadgeEngine {
  BadgeEngine._();

  /// Conteo actual por categoría de progreso contable (todas menos
  /// `bienvenida`/`resiliencia`, que son binarias por naturaleza — no
  /// tienen una "distancia" numérica, se ganan o no se ganan). Factorizado
  /// como método propio porque tanto [evaluate] como [nextClosest]
  /// necesitan exactamente el mismo conteo — mantenerlo en un solo lugar
  /// evita que ambos terminen midiendo la misma categoría de forma
  /// distinta si el criterio cambia más adelante.
  static Map<String, int> _categoryCounts(
    List<StreakEntry> fullStreakHistory,
    List<BiometricCheckIn> biometricHistory,
  ) {
    return {
      BadgeCategory.racha: StreakEngine.computeLongestStreak(fullStreakHistory),
      BadgeCategory.ayuno:
          fullStreakHistory.where((e) => e.fastingCompleted).length,
      BadgeCategory.sueno:
          fullStreakHistory.where((e) => e.sleepCompleted).length,
      BadgeCategory.hidratacion:
          fullStreakHistory.where((e) => e.hydrationCompleted).length,
      BadgeCategory.ejercicio:
          fullStreakHistory.where((e) => e.exerciseLogged).length,
      BadgeCategory.nutricion:
          fullStreakHistory.where((e) => e.nutritionLogged).length,
      BadgeCategory.imr:
          fullStreakHistory.where((e) => e.imrScore >= 60).length,
      BadgeCategory.checkin: biometricHistory
          .where((c) => c.source == BiometricSource.checkinSheet)
          .length,
    };
  }

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

    void checkThresholdCategory(String category, int actualCount,
        {String contextKey = 'daysCompleted'}) {
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

    final counts = _categoryCounts(fullStreakHistory, biometricHistory);
    // Racha usa un contextKey distinto ('streakLength') al resto
    // ('daysCompleted' por defecto) — todas las demás categorías de
    // counts comparten el default.
    checkThresholdCategory(BadgeCategory.racha, counts[BadgeCategory.racha]!,
        contextKey: 'streakLength');
    checkThresholdCategory(BadgeCategory.ayuno, counts[BadgeCategory.ayuno]!);
    checkThresholdCategory(BadgeCategory.sueno, counts[BadgeCategory.sueno]!);
    checkThresholdCategory(
        BadgeCategory.hidratacion, counts[BadgeCategory.hidratacion]!);
    checkThresholdCategory(
        BadgeCategory.ejercicio, counts[BadgeCategory.ejercicio]!);
    checkThresholdCategory(
        BadgeCategory.nutricion, counts[BadgeCategory.nutricion]!);
    checkThresholdCategory(BadgeCategory.imr, counts[BadgeCategory.imr]!);
    checkThresholdCategory(
        BadgeCategory.checkin, counts[BadgeCategory.checkin]!,
        contextKey: 'checkIns');

    // ── Resiliencia: volviste a 7+ días de racha después de haber roto
    // una racha más larga. Un solo nivel — usa datos ya calculados por
    // StreakEngine (computeLongestStreak + computeCurrentStreakWithFreezes),
    // sin reimplementar la reconstrucción día a día del historial. ───────
    final longest = counts[BadgeCategory.racha]!;
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

  /// Propuesta "Avances / Tu camino" (15-jul): la insignia no ganada más
  /// cercana entre todas las categorías de progreso contable — para
  /// mostrar como el nodo bloqueado al final de la línea de tiempo, con
  /// la distancia real ("te faltan 4 días"). Deliberadamente NO considera
  /// `bienvenida` (se gana casi siempre el día uno, no hay "camino" que
  /// mostrar) ni `resiliencia` (su condición no es una distancia contable
  /// — es "romper una racha larga y volver a 7", no algo que se acerque
  /// gradualmente).
  static BadgeProgress? nextClosest({
    required List<StreakEntry> fullStreakHistory,
    required List<BiometricCheckIn> biometricHistory,
    required Set<String> alreadyUnlockedIds,
  }) {
    final counts = _categoryCounts(fullStreakHistory, biometricHistory);
    BadgeProgress? closest;

    for (final entry in counts.entries) {
      final pending = BadgeCatalog.forCategory(entry.key)
          .where((d) => !alreadyUnlockedIds.contains(d.badgeId))
          .toList()
        ..sort((a, b) => a.threshold.compareTo(b.threshold));
      if (pending.isEmpty) continue;

      final next = pending.first;
      final remaining = next.threshold - entry.value;
      // Si ya se alcanzó el umbral, `evaluate()` la habrá otorgado en la
      // misma pasada — no debería quedar pendiente con remaining <= 0,
      // pero se descarta por seguridad en vez de mostrar una distancia
      // negativa o cero como "próxima meta".
      if (remaining <= 0) continue;

      if (closest == null || remaining < closest.remaining) {
        closest = BadgeProgress(
            definition: next, currentValue: entry.value, remaining: remaining);
      }
    }

    return closest;
  }
}
