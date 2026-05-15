// SPEC-111: servicio que escucha el `dailySummaryProvider` y persiste
// el resumen del día actual a Firestore con debounce.
//
// Reglas:
//   - Cada emisión del summary reinicia un timer de 30s. Si no llegan
//     cambios en 30s, persistimos el snapshot.
//   - Si la fecha actual (YYYYMMDD) es distinta al último día
//     persistido en esta sesión, persistimos INMEDIATAMENTE sin
//     debounce. Esto cierra el día anterior cuando cruza medianoche.
//   - Si `authStateProvider` no tiene uid, no escribimos.
//   - El servicio se inicializa una vez al arrancar la app
//     (`dailySummaryPersistenceServiceProvider`).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/firestore_errors.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_provider.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_repository_impl.dart';
import 'package:elena_app/src/features/analysis/data/mappers/daily_summary_mapper.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

class DailySummaryPersistenceService {
  final Ref _ref;
  Timer? _debounceTimer;
  String? _lastPersistedDocId;
  DailySummary? _lastSummary;
  static const Duration _debounceWindow = Duration(seconds: 30);
  final DailySummaryMapper _mapper = const DailySummaryMapper();

  DailySummaryPersistenceService(this._ref) {
    _init();
  }

  void _init() {
    _ref.listen<DailySummary>(dailySummaryProvider, (previous, next) {
      _handleSummary(previous, next);
    }, fireImmediately: false);
  }

  void _handleSummary(DailySummary? previous, DailySummary summary) {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final currentDocId = DailySummaryMapper.docIdFor(now);

    // Si cambió el día calendario respecto al último persistido en
    // esta sesión → escribir inmediatamente para cerrar el día previo.
    final isNewDay = _lastPersistedDocId != null &&
        _lastPersistedDocId != currentDocId;
    if (isNewDay) {
      _debounceTimer?.cancel();
      _persistNow(uid, summary, now);
      return;
    }

    // SPEC-113.bugfix: detectar transición a "pilar completado" (cualquier
    // *Progress que cruza el umbral hacia 1.0). Cuando esto pasa,
    // persistimos INMEDIATAMENTE sin debounce. Razón: si el usuario
    // cierra un ayuno completo y abre Análisis a los 5s, sin esto el
    // doc persistido sigue mostrando el valor viejo (<1.0) por hasta
    // 30s — y el satélite cae a 0% al cambiar de pantalla.
    final reference = previous ?? _lastSummary;
    final completionTransition =
        _crossedCompletion(reference, summary);
    if (completionTransition) {
      _debounceTimer?.cancel();
      _persistNow(uid, summary, now);
      return;
    }

    // Caso normal: debounce 30s.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceWindow, () {
      _persistNow(uid, summary, DateTime.now());
    });
  }

  /// True si `next` tiene algún pilar al 100% que en `prev` no lo
  /// estaba. Si `prev` es null, comparamos contra "0" — la primera
  /// emisión que ya viene completa también vale como transición.
  bool _crossedCompletion(DailySummary? prev, DailySummary next) {
    bool crossed(double? p, double n) =>
        n >= 1.0 && (p == null || p < 1.0);
    return crossed(prev?.fastingProgress, next.fastingProgress) ||
        crossed(prev?.sleepProgress, next.sleepProgress) ||
        crossed(prev?.hydrationProgress, next.hydrationProgress) ||
        crossed(prev?.exerciseProgress, next.exerciseProgress) ||
        crossed(prev?.mealsProgress, next.mealsProgress);
  }

  Future<void> _persistNow(
      String uid, DailySummary summary, DateTime now) async {
    final doc = _mapper.toDoc(summary: summary, now: now);
    final repo = _ref.read(dailySummaryRepositoryProvider);
    try {
      await repo.save(uid, doc);
      _lastPersistedDocId = DailySummaryMapper.docIdFor(now);
      _lastSummary = summary;
      AppLogger.debug(
        '[DailySummaryPersistence] Snapshot guardado (${doc.date}, IMR ${doc.imrScore})',
      );
    } catch (e, stack) {
      // SPEC-107: si es permission-denied (logout en curso), degradar
      // a debug. Cualquier otro error sí merece warning.
      if (FirestoreErrors.isPermissionDenied(e)) {
        AppLogger.debug(
          '[DailySummaryPersistence] Persist abortado por logout: $e',
        );
      } else {
        AppLogger.warning(
          '[DailySummaryPersistence] Error al persistir snapshot',
          e,
        );
        AppLogger.debug('$stack');
      }
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Provider que crea y mantiene vivo el servicio durante toda la
/// sesión. Se debe `ref.read` una vez en `main.dart` después de
/// `runApp` para que el listener arranque.
final dailySummaryPersistenceServiceProvider =
    Provider<DailySummaryPersistenceService>((ref) {
  final service = DailySummaryPersistenceService(ref);
  ref.onDispose(service.dispose);
  return service;
});
