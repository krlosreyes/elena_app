// SPEC-110: provider derivado que agrega el estado del día desde los
// providers de cada pilar y del IMR. Salida tipada para la pantalla
// Análisis sin que esta tenga que conocer los detalles de cada pilar.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';
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
    fastingProgress: fasting.progressPercentage,
    sleepProgress: sleepProgress,
    hydrationProgress: hydration.progressPercentage,
    exerciseProgress:
        (exercise.todayMinutes / exerciseGoal.toDouble()).clamp(0.0, 1.0),
    mealsProgress: nutrition.progressPercentage,
  );
});
