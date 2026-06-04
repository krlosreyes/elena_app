import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationSchedulerNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Observa el perfil circadiano del usuario y reprograma las notificaciones
/// diarias cuando detecta un cambio en [CircadianProfile].
///
/// SPEC-169 (2026-06-04): también observa `currentMetabolicCycleProvider`
/// — al abrir/cerrar ciclo se reprograma la agenda para que el aviso
/// "30 minutos para cerrar tu ventana" quede anclado al ciclo real del
/// usuario, no a la hora fija del perfil.
///
/// Patrón: StateNotifier sin estado visible — su valor es `void`.
/// Solo tiene efectos secundarios (scheduling).
class NotificationSchedulerNotifier extends StateNotifier<void> {
  final Ref _ref;
  CircadianProfile? _lastProfile;
  String? _lastCycleId;

  NotificationSchedulerNotifier(this._ref) : super(null) {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) => _maybeReschedule(user));
      },
      fireImmediately: true,
    );

    // SPEC-169: re-trigger cuando el ciclo metabólico abierto cambia.
    _ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final user = _ref.read(currentUserStreamProvider).valueOrNull;
          if (user == null) return;
          // Mismo cycleId ⇒ ya programado; evita work duplicado por
          // re-emisiones del stream.
          if (_lastCycleId == cycle?.cycleId) return;
          _lastCycleId = cycle?.cycleId;
          _maybeReschedule(user, force: true);
        });
      },
    );
  }

  Future<void> _maybeReschedule(UserModel? user, {bool force = false}) async {
    if (user == null) return;
    // Solo reprogramar si el perfil cambió o si el caller forzó (cambio
    // de ciclo). Evita re-schedules en cada tick del stream del usuario.
    if (!force && _lastProfile == user.profile) return;
    _lastProfile = user.profile;
    final openCycle =
        _ref.read(currentMetabolicCycleProvider).valueOrNull;
    AppLogger.info(
      '[NotificationProvider] Reprogramando agenda '
      '(cycle=${openCycle?.cycleId ?? "-"}).',
    );
    await NotificationScheduler.scheduleCircadianDay(
      user,
      openCycle: openCycle,
    );
    // SPEC-150: hidratación reprograma junto con la agenda circadiana.
    // Default 90 min entre slots durante la ventana de despertar,
    // cutoff 21:00 (respeta bloqueo intestinal).
    await NotificationScheduler.scheduleHydrationReminders(user);
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
