// SPEC-82: sink debounced del IMR comportamental al doc raíz
// `users/{uid}.imr.current`.
//
// El sitio web Metamorfosis Real lee ese campo para mostrar el score
// actualizado del usuario. Sin este provider, el IMR se calcula
// reactivamente en `imrProvider` pero vive sólo en memoria — el sitio
// nunca lo ve.
//
// Diseño:
//   - `ref.listen(imrProvider, ...)` dispara en cada recompute.
//   - Un Timer de 15s acumula cambios y solo escribe una vez al
//     expirar (debounce). Evita saturar Firestore con un write por
//     cada tick del `metabolicPulseProvider` (10s).
//   - `ref.onDispose` cancela el Timer pendiente al desmontarse.
//
// Importante: este provider es side-effect-only (`Provider<void>`).
// Para que ejecute hay que watch'arlo desde un widget vivo. El
// `DashboardScreen` ya lo hace en su `build` (ver dashboard_screen.dart).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/data/mappers/user_profile_mapper.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';

/// Duración del debounce. Suficiente para acumular ráfagas de
/// recomputes consecutivos (típicamente el pulso de 10s + cambios
/// breves del usuario) sin saturar Firestore.
const Duration _debounceDuration = Duration(seconds: 15);

final imrPersistenceProvider = Provider<void>((ref) {
  Timer? debounceTimer;
  IMRv2Result? pending;

  ref.onDispose(() {
    debounceTimer?.cancel();
  });

  ref.listen<IMRv2Result>(imrProvider, (previous, next) {
    // No persistir el estado "vacío" (carga inicial sin lastMealTime).
    if (next.totalScore == 0 && next.zone == 'N/A') return;

    final account = ref.read(authStateProvider).value;
    if (account == null) return;

    pending = next;
    debounceTimer?.cancel();
    debounceTimer = Timer(_debounceDuration, () {
      final toWrite = pending;
      if (toWrite == null) return;
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) return;

      ref
          .read(userProfileRepositoryProvider)
          .updateCurrentImr(uid, imrToCanonicalMap(toWrite))
          .catchError((Object error, StackTrace stack) {
        AppLogger.warning(
          '[imrPersistence] No se persistió imr.current: $error',
          error,
        );
      });
    });
  });
});
