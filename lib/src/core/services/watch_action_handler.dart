// SPEC-236: handler de acciones provenientes del Apple Watch.
//
// Traduce las acciones del Watch (strings) a PendingActions que el
// CoachingActionRouter ya sabe procesar. Reutiliza 100% la infra de
// SPEC-199 (PendingActionQueue + flush).
//
// Acciones soportadas:
//   "logWater"     → PendingActionType.addWater (amount = 250ml default)
//   "closeFasting" → PendingActionType.closeFasting
//   "checkIn"      → PendingActionType.checkInFeeling (amount = feeling ordinal)

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/pending_action_queue.dart';

class WatchActionHandler {
  WatchActionHandler._();

  /// Procesa una acción recibida del Watch.
  ///
  /// Encola en PendingActionQueue para que el próximo flush() la aplique
  /// (ocurre automáticamente al reanudar la app o en el tick del lifecycle).
  static Future<void> handleWatchAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'logWater':
        await PendingActionQueue.enqueue(PendingAction(
          type: PendingActionType.addWater,
          amount: (data['amount'] as num?)?.toDouble() ?? 250.0,
        ));
        AppLogger.debug('[WatchAction] Enqueued logWater from Watch');

      case 'closeFasting':
        await PendingActionQueue.enqueue(PendingAction(
          type: PendingActionType.closeFasting,
        ));
        AppLogger.debug('[WatchAction] Enqueued closeFasting from Watch');

      case 'checkIn':
        final feeling = (data['feeling'] as num?)?.toInt() ?? 0;
        await PendingActionQueue.enqueue(PendingAction(
          type: PendingActionType.checkInFeeling,
          amount: feeling.toDouble(),
        ));
        AppLogger.debug(
          '[WatchAction] Enqueued checkInFeeling from Watch (feeling=$feeling)',
        );

      default:
        AppLogger.warning(
          '[WatchAction] Acción desconocida del Watch: $action',
        );
    }
  }
}
