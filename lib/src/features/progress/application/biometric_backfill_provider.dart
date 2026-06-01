// SPEC-143 §RF-143-07: backfill client-side de biometric_history.
//
// Cuando un usuario abre la app post-deploy y aún no tiene ninguna
// entrada en `users/{uid}/biometric_history`, este provider dispara
// UNA escritura inicial con los valores biométricos actuales del doc
// raíz, marcada `source: 'spec_143_backfill'`.
//
// Garantiza que SPEC-141 (IMR longitudinal) tenga al menos un punto
// de partida histórico para todos los usuarios — sin esto, los que
// existían pre-SPEC-143 nunca recibirían entrada baseline (su
// onboarding ya pasó, y el dialog manual de check-in tampoco lo cubre).
//
// Diseño:
//   - `ref.listen(currentUserStreamProvider, ...)` observa al usuario.
//   - Cuando emite un UserModel no-null por primera vez en la sesión,
//     consulta `repo.fetchLatest`. Si retorna null (historia vacía),
//     invoca `service.writeSpec143BackfillEntry`.
//   - Flag `_ranThisSession` evita repetir si el stream re-emite por
//     cualquier razón (token refresh, edición de profile, etc.).
//   - Errores se loguean y silencian — esto es denormalización, no
//     debe romper el flujo principal de la app.
//
// IMPORTANTE: este provider es side-effect-only (`Provider<void>`).
// Para que ejecute hay que watch'arlo desde un widget vivo. El
// DashboardScreen ya monta `imrPersistenceProvider` con el mismo
// patrón; este provider se monta junto a él.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/progress/application/biometric_history_service.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final biometricBackfillProvider = Provider<void>((ref) {
  bool ranThisSession = false;

  ref.listen<AsyncValue<UserModel?>>(
    currentUserStreamProvider,
    (previous, next) async {
      if (ranThisSession) return;
      final user = next.valueOrNull;
      if (user == null) return;

      // Marcamos antes de hacer I/O para evitar dobles disparos si el
      // stream re-emite mientras estamos esperando la I/O.
      ranThisSession = true;

      try {
        final repo = ref.read(biometricRepositoryProvider);
        final latest = await repo.fetchLatest(user.id);

        if (latest != null) {
          // El usuario ya tiene historial — no necesita backfill.
          AppLogger.info(
            '[spec143Backfill] Usuario ${user.id} ya tiene historial biométrico; skip.',
          );
          return;
        }

        // Historia vacía → crear entrada inicial con los valores actuales.
        await ref
            .read(biometricHistoryServiceProvider)
            .writeSpec143BackfillEntry(currentUser: user);

        AppLogger.info(
          '[spec143Backfill] Entrada inicial escrita para usuario ${user.id}.',
        );
      } catch (e) {
        // Denormalización — no rompe el flujo. Si falla, el usuario
        // recibirá entrada cuando haga el primer check-in manual o
        // edit de Profile, lo que ocurra primero.
        AppLogger.warning(
          '[spec143Backfill] No se escribió backfill para usuario ${user.id}: $e',
          e,
        );
        // Reseteamos el flag para reintentar en la siguiente emisión.
        // Si el error es transitorio (red), la próxima vez puede pasar.
        ranThisSession = false;
      }
    },
    fireImmediately: true,
  );
});
