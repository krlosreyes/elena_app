import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/core/services/notification_policy.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_resolver.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';

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
  bool _policyLoaded = false;

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

    // Consciencia ayuno↔alimentación: cuando el estado de ayuno cambia,
    // reprogramar para suprimir/restaurar notificaciones de comida.
    _ref.listen(
      fastingProvider.select((s) => s.isActive),
      (previous, next) {
        if (previous == next) return;
        final user = _ref.read(currentUserStreamProvider).valueOrNull;
        if (user != null) _maybeReschedule(user, force: true);
      },
    );

    // 20-jul: si el usuario edita sus objetivos ("Mis objetivos" en
    // Perfil), el resumen de la notificación diaria de "tus 5
    // objetivos de hoy" queda desactualizado hasta el próximo cambio
    // de perfil/ciclo — hay que forzar reprogramación acá también.
    _ref.listen<GoalsMap>(
      goalsProvider,
      (previous, next) {
        if (previous == next) return;
        final user = _ref.read(currentUserStreamProvider).valueOrNull;
        if (user != null) _maybeReschedule(user, force: true);
      },
    );

    // Módulo "Tu Glucosa" (23-jul): si el protocolo se activa/pausa/
    // desactiva desde Perfil o el consentimiento automático, el
    // recordatorio matutino (109) queda desactualizado hasta el próximo
    // cambio de perfil/ciclo — forzar reprogramación acá también, mismo
    // criterio que goalsProvider arriba.
    _ref.listen<bool>(
      glucoseProtocolStateProvider.select(
        (s) =>
            (s.valueOrNull?.protocolActive ?? false) &&
            !(s.valueOrNull?.paused ?? false),
      ),
      (previous, next) {
        if (previous == next) return;
        final user = _ref.read(currentUserStreamProvider).valueOrNull;
        if (user != null) _maybeReschedule(user, force: true);
      },
    );
  }

  /// 20-jul: resumen compacto de "tus 5 objetivos de hoy" para la
  /// notificación matutina. Mismos emojis que ya usa `PillarRing` en
  /// el Dashboard (⏱️🌙💧💪🥦) para que el usuario reconozca de
  /// inmediato a qué pilar corresponde cada valor.
  ///
  /// Usa `PillarGoalResolver` (mismas fórmulas que alimentan los
  /// anillos y la pantalla de Objetivos) para ejercicio/sueño/
  /// hidratación, y `nutritionProvider.targetMeals` para comidas — no
  /// hay resolver puro equivalente para nutrición, y el provider ya
  /// resuelve protocolo → comidas sugeridas en vivo.
  String _buildGoalsSummary(UserModel user) {
    final goals = _ref.read(goalsProvider);
    final exerciseMin = PillarGoalResolver.exerciseMinutes(goals, user);
    final sleepH = PillarGoalResolver.sleepHours(goals);
    final hydrationL = PillarGoalResolver.hydrationLiters(goals, user);
    final targetMeals = _ref.read(nutritionProvider).targetMeals;
    final protocol = user.fastingProtocol;

    final sleepLabel = sleepH == sleepH.roundToDouble()
        ? sleepH.toStringAsFixed(0)
        : sleepH.toStringAsFixed(1);
    final hydrationLabel = hydrationL.toStringAsFixed(1);

    return '⏱️$protocol · 🌙${sleepLabel}h · 💧${hydrationLabel}L · '
        '💪${exerciseMin}min · 🥦$targetMeals comidas';
  }

  Future<void> _maybeReschedule(UserModel? user, {bool force = false}) async {
    if (user == null) return;
    // Solo reprogramar si el perfil cambió o si el caller forzó (cambio
    // de ciclo). Evita re-schedules en cada tick del stream del usuario.
    if (!force && _lastProfile == user.profile) return;
    _lastProfile = user.profile;
    // Fix notificaciones (2026-10-30): cargar la configuración del usuario
    // (tipos activos, límite diario) y limpiar del sistema operativo los
    // avisos que ya no están permitidos — incluidos los que dejaron
    // agendados versiones anteriores (hidratación cada 45 min, etc.).
    if (!_policyLoaded) {
      await NotificationPolicy.load();
      _policyLoaded = true;
    }
    await NotificationService.purgeDisallowed();
    final openCycle = _ref.read(currentMetabolicCycleProvider).valueOrNull;
    AppLogger.info(
      '[NotificationProvider] Reprogramando agenda '
      '(cycle=${openCycle?.cycleId ?? "-"}).',
    );
    // Consciencia ayuno↔alimentación: suprimir notificaciones de comida
    // mientras el usuario está en ayuno activo.
    final isFasting = _ref.read(fastingProvider).isActive;
    final glucoseState = _ref.read(glucoseProtocolStateProvider).valueOrNull;
    final glucoseProtocolActive = (glucoseState?.protocolActive ?? false) &&
        !(glucoseState?.paused ?? false);
    await NotificationScheduler.scheduleCircadianDay(
      user,
      openCycle: openCycle,
      isFasting: isFasting,
      goalsSummaryBody: _buildGoalsSummary(user),
      glucoseProtocolActive: glucoseProtocolActive,
    );
    // Fix notificaciones (2026-10-30): un solo recordatorio de agua al día,
    // y solo si el usuario lo activó (NotificationPolicy).
    await NotificationScheduler.scheduleHydrationReminders(user);
  }

  /// Fix notificaciones (2026-10-30): la pantalla de ajustes llama esto al
  /// cambiar un interruptor o el límite diario. Guarda, purga y reprograma.
  Future<void> applyPolicy({
    required Set<NotificationKind> enabled,
    required int maxPerDay,
  }) async {
    await NotificationPolicy.save(enabled: enabled, maxPerDay: maxPerDay);
    _policyLoaded = true;
    final user = _ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) {
      await NotificationService.purgeDisallowed();
      return;
    }
    await _maybeReschedule(user, force: true);
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
