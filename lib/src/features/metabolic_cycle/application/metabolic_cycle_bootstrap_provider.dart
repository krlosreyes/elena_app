// SPEC-149 §RF-149-10: provider side-effect de bootstrap del ciclo.
//
// Al primer login del usuario (de por vida), si no hay ciclo metabólico
// abierto, dispara `bootstrapIfMissing` para reconstruir un ciclo
// retroactivo desde el ayuno persistido.
//
// SPEC-186 (2026-06-05): flag "ya ejecutado" para evitar re-bootstrap.
// SPEC-228 (2026-06-15): flag migrado de SharedPreferences a Firestore
// (users/{uid}/app_state/migrations.cycle_bootstrap_done) para ser
// cross-device: iOS, Android y Web comparten el mismo flag.
// - Hot reload → flag en Firestore persiste → skip
// - flutter clean + run → flag persiste → skip
// - Logout/login del MISMO usuario → flag persiste → skip
// - Reinstall + mismo uid → flag en Firestore persiste → skip
// - Cuenta nueva o uid nuevo → flag ausente → ejecuta
//
// Patrón gemelo del biometricBackfillProvider (SPEC-143 §RF-143-07).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/data/app_state_repository.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/data/metabolic_cycle_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// SPEC-228: clave Firestore para el flag de bootstrap en
/// users/{uid}/app_state/migrations.
const String _kBootstrapMigrationKey = 'cycle_bootstrap_done';

final metabolicCycleBootstrapProvider = Provider<void>((ref) {
  // SPEC-193 hotfix (2026-06-05): para evitar el deadlock
  // "ayuno activo + ciclo cerrado + flag bootstrap true", la
  // ejecución se dispara por DOS fuentes:
  //   1. Cambio del user stream (caso original — primer login)
  //   2. Cambio del fastingProvider a isActive=true (caso desync —
  //      el listener al lastFastingIntervalProvider restaura el state
  //      después del primer fire del user stream)
  //
  // El método `_runBootstrap` es idempotente y aplica la regla:
  // si hay ayuno activo SIN ciclo abierto, ignorar el flag y crear.

  Future<void> runBootstrap(UserModel user) async {
    final appState = ref.read(appStateRepositoryProvider);
    final fasting = ref.read(fastingProvider);
    final hasActiveFasting = fasting.isActive && fasting.startTime != null;

    // SPEC-193: detectar desync "ayuno activo sin ciclo abierto".
    // Hacemos fetch directo al repo (no al stream) para tener un
    // valor sincronizado.
    final openCycle = await ref
        .read(metabolicCycleRepositoryProvider)
        .fetchOpenCycle(user.id);
    final hasOrphanFasting = hasActiveFasting && openCycle == null;

    final bootstrapDone = await appState.getMigrationFlag(
      user.id,
      _kBootstrapMigrationKey,
    );
    if (bootstrapDone && !hasOrphanFasting) {
      // Flag activo y NO hay desync → respetar el flag.
      return;
    }

    if (hasOrphanFasting) {
      AppLogger.warning(
        '[cycle.bootstrap.desync] userId=${user.id}: ayuno activo '
        'sin ciclo abierto detectado. Reparando con bootstrap.',
      );
    }

    try {
      final result =
          await ref.read(metabolicCycleServiceProvider).bootstrapIfMissing(
                userId: user.id,
                protocol: user.fastingProtocol,
                lastFastingStartTime: fasting.startTime,
                now: DateTime.now(),
                tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
              );
      await appState.setMigrationFlag(user.id, _kBootstrapMigrationKey);
      AppLogger.info(
        '[cycle.bootstrap.done] userId=${user.id} '
        'created=${result != null} '
        'cycleId=${result?.cycleId ?? "null"} '
        'reason=${hasOrphanFasting ? "desync-repair" : "first-login"}',
      );
    } catch (e) {
      AppLogger.warning(
        '[cycle.bootstrap.error] userId=${user.id}: $e',
        e,
      );
    }
  }

  // Disparador 1: cambio en el user stream (caso original).
  ref.listen<AsyncValue<UserModel?>>(
    currentUserStreamProvider,
    (previous, next) async {
      final user = next.valueOrNull;
      if (user == null) return;
      await runBootstrap(user);
    },
    fireImmediately: true,
  );

  // SPEC-193: Disparador 2: el fastingProvider con ayuno activo
  // restaurado desde Firestore (activationSource=bootstrap). Al primer
  // fire del user stream, fasting.startTime puede ser null todavía.
  // `fireImmediately: true` cubre dos casos:
  //   - el state ya está hidratado cuando se monta este provider
  //   - el state cambia mientras este provider está activo
  ref.listen(
    fastingProvider,
    (previous, next) async {
      // Solo nos importa el estado "ayuno activo por bootstrap" SIN
      // ciclo abierto. Si el ayuno está activo por userInitiated, el
      // evaluator (SPEC-187) ya crea el ciclo y este path no aplica.
      if (!next.isActive) return;
      if (next.activationSource != FastingActivationSource.bootstrap) {
        return;
      }
      // Si previous != null y previous.isActive ya era true con el
      // mismo activationSource, no es transición — skip para no
      // repetir runBootstrap en cada tick del state.
      if (previous != null &&
          previous.isActive &&
          previous.activationSource == FastingActivationSource.bootstrap) {
        return;
      }
      final user = ref.read(currentUserStreamProvider).valueOrNull;
      if (user == null) return;
      AppLogger.info(
        '[cycle.bootstrap.trigger] fired by fasting state '
        '(isActive=${next.isActive}, source=${next.activationSource})',
      );
      await runBootstrap(user);
    },
    fireImmediately: true,
  );
});
