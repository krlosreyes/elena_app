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
    final now = DateTime.now();
    // Idempotencia (ver comentario de PendingActionQueue): id determinista
    // acción + minuto, para que un doble-tap del Watch no encole 2 veces.
    final minuteBucket = now.millisecondsSinceEpoch ~/ 60000;

    switch (action) {
      case 'logWater':
        final amount = (data['amount'] as num?)?.toDouble() ?? 250.0;
        await PendingActionQueue.enqueue(PendingAction(
          id: 'watch_logWater_${amount}_$minuteBucket',
          type: PendingActionType.addWater,
          amount: amount,
          millisSinceEpoch: now.millisecondsSinceEpoch,
        ));
        AppLogger.debug('[WatchAction] Enqueued logWater from Watch');

      case 'closeFasting':
        await PendingActionQueue.enqueue(PendingAction(
          id: 'watch_closeFasting_$minuteBucket',
          type: PendingActionType.closeFasting,
          millisSinceEpoch: now.millisecondsSinceEpoch,
        ));
        AppLogger.debug('[WatchAction] Enqueued closeFasting from Watch');

      case 'checkIn':
        final feeling = (data['feeling'] as num?)?.toInt() ?? 0;
        await PendingActionQueue.enqueue(PendingAction(
          id: 'watch_checkIn_${feeling}_$minuteBucket',
          type: PendingActionType.checkInFeeling,
          amount: feeling.toDouble(),
          millisSinceEpoch: now.millisecondsSinceEpoch,
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
