// SPEC-149 §RF-149-10: provider side-effect de bootstrap del ciclo.
//
// Al primer login del usuario (de por vida en este dispositivo), si no
// hay ciclo metabólico abierto, dispara `bootstrapIfMissing` para
// reconstruir un ciclo retroactivo desde el ayuno persistido.
//
// SPEC-186 (2026-06-05): el flag "ya ejecutado" persiste en
// SharedPreferences por userId. ANTES era una variable local de la
// closure del provider que se RESETEABA con cada hot reload, causando
// que bootstrapIfMissing se ejecutara una y otra vez cada vez que
// Carlos modificaba código. Con el flag persistido:
// - Hot reload → flag persiste → skip → NO crea ciclo huérfano
// - flutter clean + run → flag persiste → skip
// - Logout/login del MISMO usuario → flag persiste → skip
// - Reinstall de la app (storage borrado) → flag se pierde → re-ejecuta
//
// Patrón gemelo del biometricBackfillProvider (SPEC-143 §RF-143-07).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// SPEC-186: clave de SharedPreferences que indica que el bootstrap
/// retroactivo ya corrió para un usuario específico. Persiste entre
/// hot reloads, restarts y logout/login.
///
/// Para forzar re-ejecución (admin debug o reset manual), borrar la
/// clave correspondiente o usar `clearBootstrapFlag(prefs, userId)`.
String _bootstrapFlagKey(String userId) => 'cycle_bootstrap_done_$userId';

/// Helper público para tests y debugging — borra la flag de un usuario
/// para forzar re-ejecución del bootstrap. NO se llama desde código
/// de producción normalmente.
Future<void> clearMetabolicCycleBootstrapFlag(
  SharedPreferences prefs,
  String userId,
) async {
  await prefs.remove(_bootstrapFlagKey(userId));
}

final metabolicCycleBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<UserModel?>>(
    currentUserStreamProvider,
    (previous, next) async {
      final user = next.valueOrNull;
      if (user == null) return;

      // SPEC-186: chequeo persistente. Si ya corrió para este usuario,
      // no volver a ejecutar — el ciclo ya fue creado en una sesión
      // previa (o el usuario decidió no tenerlo).
      final prefs = ref.read(sharedPreferencesProvider);
      final flagKey = _bootstrapFlagKey(user.id);
      if (prefs.getBool(flagKey) == true) {
        return;
      }

      try {
        final lastFasting = ref.read(fastingProvider).startTime;
        final result =
            await ref.read(metabolicCycleServiceProvider).bootstrapIfMissing(
                  userId: user.id,
                  protocol: user.fastingProtocol,
                  lastFastingStartTime: lastFasting,
                  now: DateTime.now(),
                  tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
                );
        // SPEC-186: persistir flag SIEMPRE que la llamada haya
        // completado sin excepción. Incluso si `result == null`
        // (SPEC-185: sin lastFastingStartTime no se crea ciclo),
        // el flag se setea para que NO se intente de nuevo en este
        // dispositivo — el siguiente tap "Iniciar ayuno" creará el
        // ciclo legítimamente vía el evaluator (SPEC-183).
        await prefs.setBool(flagKey, true);
        AppLogger.info(
          '[cycle.bootstrap.done] userId=${user.id} '
          'created=${result != null} '
          'cycleId=${result?.cycleId ?? "null"}',
        );
      } catch (e) {
        AppLogger.warning(
          '[cycle.bootstrap.error] userId=${user.id}: $e',
          e,
        );
        // NO seteamos el flag en caso de error — permitir reintento
        // en la siguiente sesión (cold start nuevo).
      }
    },
    fireImmediately: true,
  );
});
