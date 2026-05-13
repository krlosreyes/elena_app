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

/// SPEC-86: snapshot del IMR presentable al usuario.
///
/// Combina dos fuentes:
///   - `imrProvider` (cálculo local reactivo de `ScoreEngine`).
///   - `persistedImrProvider` (lo último escrito a Firestore, que
///     puede venir del sitio web Metamorfosis Real).
///
/// Regla de decisión:
///   - Si el local tiene contribución behavioral (metabolismo o
///     conducta > 0), gana el local (la app tiene más datos).
///   - Si el local es baseline (estructura solo), se prefiere el
///     persistido si existe.
class DisplayedImr {
  final int score;
  final String zone;
  final IMRv2Result? localFull;

  const DisplayedImr({
    required this.score,
    required this.zone,
    this.localFull,
  });

  bool get hasFullLocal => localFull != null;
}

/// Stream del `imr.current` persistido en Firestore. Útil para
/// mostrar el último valor calculado por el sitio cuando la app
/// todavía no tiene data behavioral local.
final persistedImrProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watchCurrentImr(account.uid);
});

/// Decide qué IMR mostrar en el Dashboard y Profile. Lee `imrProvider`
/// y `persistedImrProvider` y aplica la regla de SPEC-86.
final displayedImrProvider = Provider<DisplayedImr>((ref) {
  final local = ref.watch(imrProvider);
  final hasBehavior = local.metabolicScore > 0 || local.behaviorScore > 0;

  if (hasBehavior) {
    return DisplayedImr(
      score: local.totalScore,
      zone: local.zone,
      localFull: local,
    );
  }

  // Baseline o vacío local → preferir el persistido si está.
  final persistedAsync = ref.watch(persistedImrProvider);
  final persisted = persistedAsync.value;
  if (persisted != null && persisted['imrScore'] is num) {
    final rawScore = (persisted['imrScore'] as num).toInt();
    final clampedScore = rawScore.clamp(0, 100);
    final label = persisted['label'];
    return DisplayedImr(
      score: clampedScore,
      zone: label is String && label.isNotEmpty ? label : local.zone,
    );
  }

  // Sin persistido: mostrar el local aunque sea baseline.
  return DisplayedImr(
    score: local.totalScore,
    zone: local.zone,
    localFull: local,
  );
});

final imrPersistenceProvider = Provider<void>((ref) {
  Timer? debounceTimer;
  IMRv2Result? pending;

  ref.onDispose(() {
    debounceTimer?.cancel();
  });

  ref.listen<IMRv2Result>(imrProvider, (previous, next) {
    // No persistir el estado "vacío" (carga inicial sin lastMealTime).
    if (next.totalScore == 0 && next.zone == 'N/A') return;

    // SPEC-85: no pisar un valor del sitio con un baseline parcial.
    // Un IMR sin contribución behavioral (metabolismo y conducta en
    // 0) sólo es comparable al baseline de SPEC-82 — no aporta
    // información nueva sobre lo que el sitio ya pudo haber escrito.
    // Esperamos a que el usuario tenga al menos un log que mueva los
    // bloques Metabolismo o Conducta antes de persistir.
    if (next.metabolicScore == 0 && next.behaviorScore == 0) return;

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
