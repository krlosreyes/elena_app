import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/pending_action_queue.dart';
import 'package:elena_app/src/features/coaching/application/check_in_provider.dart';
import 'package:elena_app/src/features/coaching/data/check_in_repository.dart';
import 'package:elena_app/src/features/coaching/domain/fasting_check_in.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-199 Fase A — Router de acciones de coaching
// ─────────────────────────────────────────────────────────────────────────────
//
// Vacía la `PendingActionQueue` (encolada por el handler de la notificación)
// llamando al notifier correcto. Vive en la capa feature porque conoce los
// providers concretos (hydrationProvider). Se invoca desde `app.dart` al
// reanudar la app y cuando aparece un usuario (cold start).
//
// `addWater` requiere usuario: si todavía no hay (cold start), la acción se
// MANTIENE en la cola y se reintenta en el próximo flush. Idempotente: cada
// acción se remueve solo tras aplicarse.

class CoachingActionRouter {
  CoachingActionRouter._();

  /// Aplica las acciones pendientes. Devuelve cuántas se aplicaron.
  static Future<int> flush(WidgetRef ref) async {
    final actions = await PendingActionQueue.peekAll();
    if (actions.isEmpty) return 0;

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    int applied = 0;

    for (final action in actions) {
      switch (action.type) {
        case PendingActionType.addWater:
          // Sin usuario aún (cold start): conservar para el próximo flush.
          if (user == null || user.id.isEmpty) continue;
          await ref
              .read(hydrationProvider.notifier)
              .addWater(action.amount ?? kHydrationGlassLiters);
          await PendingActionQueue.remove(action.id);
          applied++;
          AnalyticsService.logEvent(
            'coaching_prompt_answered',
            params: const {
              'type': 'hydration',
              'option': 'yes',
              'surface': 'notification',
            },
          );
          AppLogger.debug('[CoachingActionRouter] vaso registrado vía prompt');
          break;

        case PendingActionType.hydrationSnoozed:
          // "Aún no" → re-recordar en +15 min (one-shot, también accionable).
          await PendingActionQueue.remove(action.id);
          await NotificationService.scheduleAt(
            id: NotificationIds.hydrationSnooze,
            title: '💧 ¿Lo tomamos ahora?',
            body:
                'Tu cuerpo sigue esperando ese vaso. Un toque y queda '
                'registrado.',
            scheduledTime: DateTime.now().add(const Duration(minutes: 15)),
            repeatsDaily: false,
            actionableHydration: true,
          );
          AnalyticsService.logEvent(
            'coaching_prompt_answered',
            params: const {
              'type': 'hydration',
              'option': 'snooze',
              'surface': 'notification',
            },
          );
          break;

        // SPEC-224: Ayuno — cerrar ventana en el momento del prompt.
        case PendingActionType.closeFasting:
          if (user == null || user.id.isEmpty) continue;
          await ref
              .read(fastingProvider.notifier)
              .confirmManualFastingEnd(DateTime.now());
          await PendingActionQueue.remove(action.id);
          applied++;
          AnalyticsService.logEvent(
            'coaching_prompt_answered',
            params: const {
              'type': 'fasting',
              'option': 'close',
              'surface': 'notification',
            },
          );
          AppLogger.debug('[CoachingActionRouter] ayuno cerrado vía prompt');
          break;

        // SPEC-224: Ejercicio — sesión de 30 min a la hora del prompt.
        case PendingActionType.logExercise:
          if (user == null || user.id.isEmpty) continue;
          try {
            await ref.read(exerciseProvider.notifier).registerExercise(
                  minutes: (action.amount ?? kExercisePromptMinutes).toInt(),
                  activityType: 'Actividad moderada',
                  timestamp: DateTime.fromMillisecondsSinceEpoch(
                      action.millisSinceEpoch),
                );
          } catch (e) {
            // Validación fallida (p. ej. >120 min): descartamos igual para
            // no bloquear la cola. El usuario puede registrar desde el pilar.
            AppLogger.warning(
                '[CoachingActionRouter] logExercise descartado: $e');
          }
          await PendingActionQueue.remove(action.id);
          applied++;
          AnalyticsService.logEvent(
            'coaching_prompt_answered',
            params: const {
              'type': 'exercise',
              'option': 'log',
              'surface': 'notification',
            },
          );
          AppLogger.debug('[CoachingActionRouter] ejercicio registrado vía prompt');
          break;

        // SPEC-224: Nutrición — comida simple con defaults seguros.
        case PendingActionType.logMeal:
          if (user == null || user.id.isEmpty) continue;
          try {
            await ref.read(nutritionProvider.notifier).logMeal(
                  label: 'Comida',
                  mealTime: DateTime.fromMillisecondsSinceEpoch(
                      action.millisSinceEpoch),
                  // forceLog evita el warning de intervalo (2-3h), pero
                  // el bloqueo duro (<2h) sigue activo — si falla,
                  // descartamos sin romper la cola.
                  forceLog: true,
                );
          } catch (e) {
            AppLogger.warning(
                '[CoachingActionRouter] logMeal descartado: $e');
          }
          await PendingActionQueue.remove(action.id);
          applied++;
          AnalyticsService.logEvent(
            'coaching_prompt_answered',
            params: const {
              'type': 'nutrition',
              'option': 'log',
              'surface': 'notification',
            },
          );
          AppLogger.debug('[CoachingActionRouter] comida registrada vía prompt');
          break;

        // SPEC-232: check-in emocional durante ayuno.
        // `amount` codifica el ordinal de FastingFeeling (0-5).
        case PendingActionType.checkInFeeling:
          if (user == null || user.id.isEmpty) continue;
          final ordinal = (action.amount ?? 0).toInt();
          final feeling = ordinal >= 0 &&
                  ordinal < FastingFeeling.values.length
              ? FastingFeeling.values[ordinal]
              : FastingFeeling.good; // fallback seguro
          final fastingState = ref.read(fastingProvider);
          saveCheckIn(
            userId: user.id,
            feeling: feeling,
            repo: ref.read(checkInRepositoryProvider),
            fastingStart: fastingState.startTime,
            cycleId: null, // cycleId opcional; se resuelve en el provider
          );
          await PendingActionQueue.remove(action.id);
          applied++;
          AnalyticsService.logEvent(
            'coaching_prompt_answered',
            params: {
              'type': 'check_in',
              'option': feeling.name,
              'surface': 'notification',
            },
          );
          AppLogger.debug(
              '[CoachingActionRouter] check-in ${feeling.name} vía prompt');
          break;
      }
    }

    if (applied > 0) {
      AnalyticsService.logEvent(
        'pending_action_flushed',
        params: {'count': applied},
      );
    }
    return applied;
  }
}
