// SPEC-141 §RF-141-12.C (2026-06-05): gatillo C — staleness fallback.
//
// Side-effect provider que se monta en app.dart. Al primer login (y a
// cada cambio de usuario), lee `imr.current.computedAt` del cache de
// Firestore vía `persistedImrProvider` y, si la diferencia con `now` es
// ≥ 7 días (o no hay cache), recalcula el longitudinal IMR y lo
// persiste vía `WeeklyImrSnapshotService.recomputeAndPersist`.
//
// One-shot por sesión por usuario — no se vuelve a disparar hasta que
// cambie el `userId`. La razón: si Carlos abre la app 10 veces en un
// día, el snapshot que ve es el mismo (refuerza la semántica
// "longitudinal = no se mueve a diario", §3.7).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/longitudinal_imr_provider.dart';
import 'package:elena_app/src/core/engine/weekly_imr_snapshot_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Provider side-effect-only. Se monta con `ref.watch` en app.dart.
final weeklyImrStalenessTriggerProvider = Provider<void>((ref) {
  final processed = <String>{};

  ref.listen<AsyncValue<Map<String, dynamic>?>>(
    persistedImrProvider,
    (previous, next) {
      final account = ref.read(authStateProvider).value;
      if (account == null) return;
      final userId = account.uid;
      if (processed.contains(userId)) return;

      final cache = next.valueOrNull;
      final service = ref.read(weeklyImrSnapshotServiceProvider);

      DateTime? lastComputedAt;
      final raw = cache?['computedAt'];
      if (raw is String) {
        lastComputedAt = DateTime.tryParse(raw);
      } else if (raw is DateTime) {
        lastComputedAt = raw;
      }

      if (!service.isSnapshotStale(lastComputedAt: lastComputedAt)) {
        // Cache fresco — marcar como procesado para no reevaluar
        // hasta que cambie el userId.
        processed.add(userId);
        return;
      }

      // Computar live el longitudinal y persistir.
      final longitudinal = ref.read(longitudinalImrProvider);
      if (longitudinal.longitudinalScore == null) {
        // State aún no listo (sin lastMealTime). No marcamos como
        // procesado para que el próximo emit del cache reintente.
        return;
      }

      processed.add(userId);
      AppLogger.info(
        '[WeeklyImrStaleness] cache stale o ausente → recompute '
        '(userId=$userId, lastComputedAt=$lastComputedAt)',
      );
      service.recomputeAndPersist(
        userId: userId,
        longitudinal: longitudinal,
        trigger: WeeklyImrTrigger.stalenessFallback,
      );
    },
    fireImmediately: true,
  );
});
