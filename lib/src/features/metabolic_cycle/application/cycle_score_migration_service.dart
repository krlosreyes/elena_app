// SPEC-226: migración one-shot para corregir dailyScore histórico.
//
// Causa raíz: antes de SPEC-225, cuando el usuario iniciaba un nuevo ayuno,
// StreakNotifier reseteaba fastingMagnitude a 0 ANTES de que el evaluador
// capturara el snapshot del ciclo. Todos los cierres `manualNextFasting`
// guardaron fastingMagnitude ≈ 0 → dailyScore ~29 puntos más bajo.
//
// Esta migración lee los últimos 200 ciclos cerrados, identifica los afectados
// (closureReason=manualNextFasting, fastingMagnitude ≈ 0) y los re-guarda con
// fastingMagnitude=1.0 y el dailyScore recomputado.
//
// Guard: SharedPreferences key `cycle_score_migration_v1_done` previene
// re-ejecuciones. El servicio es idempotente — si corre dos veces produce el
// mismo resultado porque vuelve a guardar los mismos valores corregidos.
//
// Las escrituras son fire-and-forget (unawaited) para respetar SPEC-206:
// Firestore escribe en caché local al instante y sincroniza al reconectar.

import 'dart:async';

import 'package:elena_app/src/core/data/app_state_repository.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/cycle_score_computer.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_repository.dart';
import 'package:elena_app/src/shared/utils/fasting_protocol.dart';

class CycleScoreMigrationService {
  // Guard key en Firestore users/{uid}/app_state/migrations (SPEC-228).
  static const String _kMigrationV1Key = 'cycle_score_v1';

  // Umbral: fastingMagnitude < 0.05 se considera "efectivamente 0" (bug).
  // Un ciclo legítimo con ayuno muy corto podría tener ~0.1, pero un ciclo
  // con el bug tiene exactamente 0.0.
  static const double _kBugMagnitudeThreshold = 0.05;

  final MetabolicCycleRepository _repository;
  final AppStateRepository _appState;

  CycleScoreMigrationService({
    required MetabolicCycleRepository repository,
    required AppStateRepository appState,
  })  : _repository = repository,
        _appState = appState;

  /// Ejecuta la migración si no se ha marcado como completada.
  /// Idempotente — safe para llamar en cada arranque de la app.
  Future<void> runIfNeeded(String userId) async {
    if (await _appState.getMigrationFlag(userId, _kMigrationV1Key)) return;

    try {
      AppLogger.info('[CycleScoreMigration] iniciando migración v1…');

      final cycles = await _repository.fetchRecentClosed(userId, limit: 200);
      int fixed = 0;

      for (final cycle in cycles) {
        // Solo aplica a cierres por inicio de nuevo ayuno.
        if (cycle.closureReason != ClosureReason.manualNextFasting) continue;

        final storedFasting = cycle.magnitudes?.fastingMagnitude ?? 0.0;
        if (storedFasting > _kBugMagnitudeThreshold) continue; // ya correcto

        // Reconstruir con fastingMagnitude = 1.0 (el usuario completó su
        // ayuno — si no lo hubiera completado, habría esperado hasta el
        // fallback, no iniciado un nuevo ayuno manualmente).
        const correctedFasting = 1.0;

        final oldMag = cycle.magnitudes;
        final correctedMagnitudes = CycleMagnitudes(
          fastingMagnitude: correctedFasting,
          sleepQualityScore: oldMag?.sleepQualityScore ?? 0,
          hydrationMagnitude: oldMag?.hydrationMagnitude ?? 0,
          exerciseMagnitude: oldMag?.exerciseMagnitude ?? 0,
          nutritionMagnitude: oldMag?.nutritionMagnitude ?? 0,
        );

        final correctedScore = CycleScoreComputer.compute(
          fastingMagnitude: correctedFasting,
          sleepQualityScore: oldMag?.sleepQualityScore,
          hydrationMagnitude: oldMag?.hydrationMagnitude,
          exerciseMagnitude: oldMag?.exerciseMagnitude,
          nutritionMagnitude: oldMag?.nutritionMagnitude,
        );

        // Corregir fastingDurationHours: era mag(0) * targetHours = 0.
        // Ahora debería ser targetHours (100% del protocolo).
        final targetHours = fastingHoursForProtocol(cycle.fastingProtocol);
        final correctedFastingHours =
            targetHours != null ? targetHours.toDouble() : null;

        // Reconstruir el ciclo con los datos corregidos. No tenemos copyWith
        // en MetabolicCycle (diseño inmutable sin it) — reconstruimos campo
        // a campo preservando todos los valores que no cambian.
        final corrected = MetabolicCycle(
          cycleId: cycle.cycleId,
          startedAt: cycle.startedAt,
          closedAt: cycle.closedAt,
          closureReason: cycle.closureReason,
          fastingDurationHours:
              correctedFastingHours ?? cycle.fastingDurationHours,
          feedingWindowHours: cycle.feedingWindowHours,
          dailyScore: correctedScore,
          pillarsCompleted: cycle.pillarsCompleted != null
              ? CyclePillarsCompleted(
                  // completó el ayuno (inició el siguiente a propósito).
                  fasting: true,
                  sleep: cycle.pillarsCompleted!.sleep,
                  hydration: cycle.pillarsCompleted!.hydration,
                  exercise: cycle.pillarsCompleted!.exercise,
                  nutrition: cycle.pillarsCompleted!.nutrition,
                )
              : null,
          magnitudes: correctedMagnitudes,
          feedback: cycle.feedback,
          fastingProtocol: cycle.fastingProtocol,
          tzOffsetMinutes: cycle.tzOffsetMinutes,
          // liveScore no aplica a ciclos históricos cerrados.
        );

        // SPEC-206: fire-and-forget. Firestore escribe en caché al instante.
        unawaited(
          _repository.save(userId, corrected).catchError((Object e) {
            AppLogger.warning(
              '[CycleScoreMigration] save falló para ${cycle.cycleId}: $e',
            );
          }),
        );

        fixed++;
        AppLogger.debug(
          '[CycleScoreMigration] ${cycle.cycleId}: '
          'score ${cycle.dailyScore} → $correctedScore  '
          'fasting 0.0 → $correctedFasting',
        );
      }

      AppLogger.info(
        '[CycleScoreMigration] migración v1 completa — '
        '$fixed/${cycles.length} ciclos corregidos',
      );

      // Marcar como completada DESPUÉS de encolar todos los saves.
      // Si la app cae antes de esta línea, la migración re-corre al
      // arrancar de nuevo (idempotente). Guard en Firestore garantiza
      // que no re-corre en NINGÚN device (SPEC-228 cross-device).
      await _appState.setMigrationFlag(userId, _kMigrationV1Key);
    } catch (e, st) {
      // No marcar como completa — se reintentará en el próximo arranque.
      AppLogger.error('[CycleScoreMigration] error en migración v1', e, st);
    }
  }
}
