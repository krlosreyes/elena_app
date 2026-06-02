// SPEC-149 §RF-149-10: provider side-effect de bootstrap del ciclo.
//
// Al primer login post-deploy (o primer login del usuario), si no hay
// ciclo metabólico abierto, dispara `bootstrapIfMissing` para crear
// uno inicial.
//
// Patrón gemelo del biometricBackfillProvider (SPEC-143 §RF-143-07):
// one-shot por sesión, idempotente, falla silenciosa con log.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final metabolicCycleBootstrapProvider = Provider<void>((ref) {
  bool ranThisSession = false;

  ref.listen<AsyncValue<UserModel?>>(
    currentUserStreamProvider,
    (previous, next) async {
      if (ranThisSession) return;
      final user = next.valueOrNull;
      if (user == null) return;

      ranThisSession = true;

      try {
        final lastFasting = ref.read(fastingProvider).startTime;
        await ref.read(metabolicCycleServiceProvider).bootstrapIfMissing(
              userId: user.id,
              protocol: user.fastingProtocol,
              lastFastingStartTime: lastFasting,
              now: DateTime.now(),
              tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
            );
        AppLogger.info(
          '[metabolicCycleBootstrap] verificado/creado para ${user.id}',
        );
      } catch (e) {
        AppLogger.warning(
          '[metabolicCycleBootstrap] no se pudo bootstrap para ${user.id}: $e',
          e,
        );
        ranThisSession = false; // permitir reintento
      }
    },
    fireImmediately: true,
  );
});
