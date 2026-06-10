import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/pending_action_queue.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
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
