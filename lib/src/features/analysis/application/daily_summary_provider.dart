// SPEC-110: provider derivado que agrega el estado del día desde los
// providers de cada pilar y del IMR. Salida tipada para la pantalla
// Análisis sin que esta tenga que conocer los detalles de cada pilar.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_history_provider.dart'
    show hasCompletedFastingTodayProvider;
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart'
    show fastingProvider;
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart'
    show hydrationProvider;
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart'
    show sleepProvider;
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart'
    show exerciseProvider;
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart'
    show nutritionProvider;
import 'package:elena_app/src/shared/providers/user_provider.dart'
    show currentUserStreamProvider;

/// Provider derivado: estado agregado del día actual.
///
/// La pantalla Análisis lo consume para pintar el anillo central y
/// los 5 satélites. Se recompute automáticamente cuando cualquier
/// provider de pilar emite.
final dailySummaryProvider = Provider<DailySummary>((ref) {
  final fasting = ref.watch(fastingProvider);
  final sleep = ref.watch(sleepProvider);
  final hydration = ref.watch(hydrationProvider);
  final exercise = ref.watch(exerciseProvider);
  final nutrition = ref.watch(nutritionProvider);
  final imr = ref.watch(displayedImrProvider);
  // SPEC-113.bugfix: el objetivo de ejercicio es `user.exerciseGoalMinutes`
  // (default 20 min). Antes el provider dividía por 60 hardcoded, lo
  // que hacía que cumplir el objetivo (20 min) se viera como 33%.
  final user = ref.watch(currentUserStreamProvider).value;
  final exerciseGoal = (user?.exerciseGoalMinutes ?? 20).clamp(1, 240);

  // SPEC-113.bugfix: doble fuente de verdad para "ayuno completado HOY".
  // El flag in-memory `state.completedToday` puede no setearse por
  // timing al inicio. `hasCompletedFastingTodayProvider` consulta BD
  // directamente. Si CUALQUIERA reporta "completado", forzamos 1.0.
  final completedFromBd = ref.watch(hasCompletedFastingTodayProvider);

  // SPEC-113.feat: regla canónica de atribución temporal para ayuno.
  //
  // Un ayuno multi-día (cruza medianoche) se atribuye al día calendario
  // donde se proyecta cerrar (`startTime + targetHours`). Mientras esté
  // activo y el cierre proyectado caiga MAÑANA o después, su progreso
  // NO cuenta para HOY. Esto evita contaminar el daily_summary de hoy
  // con un ayuno que en realidad pertenece al día siguiente, y a la
  // inversa, evita que mañana el satélite Ayuno arranque a 0% por un
  // ayuno que ya estás cerrando.
  //
  // Reglas en orden de precedencia:
  //   1. Si BD o memoria reportan "completado HOY" → 1.0.
  //   2. Si hay ayuno activo, atribuir por el día calendario del cierre
  //      proyectado:
  //        - Cierre proyectado = HOY → contribuye con `progressPercentage`.
  //        - Cierre proyectado = MAÑANA → 0 (aún no es de hoy).
  //        - Cierre proyectado = AYER (pero sigue activo: el usuario
  //          sobrepasó el target) → 1.0.
  //   3. Sin ayuno activo y sin completedToday → 0.
  //
  // El Dashboard sigue usando `fasting.progressPercentage` directo (sin
  // esta regla) para que el usuario vea el progreso real-time. Esta
  // regla solo aplica a la atribución diaria (análisis + persistencia).
  double fastingProgressFinal;
  if (completedFromBd || fasting.completedToday == true) {
    fastingProgressFinal = 1.0;
  } else if (fasting.isActive &&
      fasting.startTime != null &&
      fasting.targetHours > 0) {
    final now = DateTime.now();
    final projectedEnd =
        fasting.startTime!.add(Duration(hours: fasting.targetHours));
    final closesToday = projectedEnd.year == now.year &&
        projectedEnd.month == now.month &&
        projectedEnd.day == now.day;
    final closesInFuture = projectedEnd.isAfter(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    if (closesToday) {
      // El ayuno proyectado cierra HOY → contribuye con su progreso real.
      fastingProgressFinal = fasting.progressPercentage;
    } else if (closesInFuture) {
      // El cierre proyectado cae MAÑANA o después → aún no cuenta para HOY.
      fastingProgressFinal = 0.0;
    } else {
      // El cierre proyectado ya pasó pero el ayuno sigue activo
      // (sobrepasó el target). Atribuir a HOY como 100%.
      fastingProgressFinal = 1.0;
    }
  } else {
    fastingProgressFinal = 0.0;
  }

  // Sueño: combinamos duración objetivo 8h (70%) + calidad 1-5 (30%).
  // Si no hay log de hoy o no hay calidad, degradamos al peso solo
  // de la duración.
  //
  // SPEC-110.1 FIX: solo cuenta como progreso de HOY si el log
  // tiene `wokeUp` en el día calendario actual. Antes el provider
  // tomaba CUALQUIER `lastLog` (incluso de hace varios días) y lo
  // pintaba como 100% del satélite Sueño — engañoso para el usuario.
  final sleepLog = sleep.lastLog;
  double sleepProgress = 0;
  if (sleepLog != null) {
    final now = DateTime.now();
    final isToday = sleepLog.wokeUp.year == now.year &&
        sleepLog.wokeUp.month == now.month &&
        sleepLog.wokeUp.day == now.day;
    if (isToday) {
      final durationHours = sleepLog.duration.inMinutes / 60.0;
      final durationPct = (durationHours / 8.0).clamp(0.0, 1.0);
      final quality = sleepLog.subjectiveQuality;
      if (quality != null) {
        sleepProgress = durationPct * 0.7 + (quality / 5.0) * 0.3;
      } else {
        sleepProgress = durationPct;
      }
    }
  }

  return DailySummary.compute(
    imrScore: imr.score,
    fastingProgress: fastingProgressFinal,
    sleepProgress: sleepProgress,
    hydrationProgress: hydration.progressPercentage,
    exerciseProgress:
        (exercise.todayMinutes / exerciseGoal.toDouble()).clamp(0.0, 1.0),
    mealsProgress: nutrition.progressPercentage,
  );
});
