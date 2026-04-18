import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/core/services/app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationSchedulerNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Observa el perfil circadiano del usuario y reprograma las notificaciones
/// diarias cuando detecta un cambio en [CircadianProfile].
///
/// Patrón: StateNotifier sin estado visible — su valor es `void`.
/// Solo tiene efectos secundarios (scheduling).
class NotificationSchedulerNotifier extends StateNotifier<void> {
  final Ref _ref;
  CircadianProfile? _lastProfile;

  NotificationSchedulerNotifier(this._ref) : super(null) {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) async {
          if (user == null) return;

          // Solo reprogramar si el perfil circadiano cambió
          // (evita reprogramaciones innecesarias en cada tick del stream)
          if (_lastProfile == user.profile) return;

          _lastProfile = user.profile;
          AppLogger.info(
            '[NotificationProvider] Perfil circadiano actualizado. Reprogramando agenda.',
          );
          await NotificationScheduler.scheduleCircadianDay(user);
        });
      },
      fireImmediately: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provider que mantiene vivo el [NotificationSchedulerNotifier].
///
/// Debe leerse en el widget raíz (ElenaApp) para que permanezca activo
/// durante toda la sesión:
///   ```dart
///   ref.watch(notificationSchedulerProvider);
///   ```
final notificationSchedulerProvider =
    StateNotifierProvider<NotificationSchedulerNotifier, void>((ref) {
  return NotificationSchedulerNotifier(ref);
});
