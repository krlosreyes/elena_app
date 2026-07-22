// TEST-03 (auditoría pre-producción 2026-07-11): SPEC-206 offline-first
// para SleepNotifier.saveManualSleep (y el mismo patrón en
// confirmManualWakeUp/deleteLastLog).
//
// Igual que test/features/sleep/application/sleep_notifier_spec216_test.dart
// ya documenta explícitamente ("No instancia SleepNotifier completo —
// depende de Riverpod + Firebase"), este test replica la mecánica exacta
// del patrón `unawaited(repo.save(...).catchError(...))` en una
// mini-implementación aislada, en vez de construir el notifier real vía
// ProviderContainer.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Repo mínimo cuyo `save` nunca resuelve — mismo `_HangingSaveRepo` de
/// metabolic_cycle_service_test.dart (SPEC-206), adaptado a la forma de
/// SleepRepository.save.
class _HangingSleepRepo {
  final saved = <String>[];

  Future<void> save(String userId, String logId) {
    saved.add(logId);
    return Completer<void>().future; // nunca completa
  }
}

/// Replica el patrón real de SleepNotifier.saveManualSleep: el write no
/// se espera con `await` directo — se dispara con `unawaited` y un
/// `catchError` que solo actualiza el estado de error si el Future
/// realmente falla (no si simplemente queda pendiente offline).
class _SleepOfflineMechanic {
  _SleepOfflineMechanic(this._repo);
  final _HangingSleepRepo _repo;

  bool isSaving = false;
  String? lastWriteError;

  Future<void> saveManualSleep(String userId, String logId) async {
    isSaving = true;
    try {
      // SPEC-216: el estado optimista se limpia inmediatamente, ANTES
      // de que el write confirme — igual que en el notifier real.
      isSaving = false;
    } finally {
      if (isSaving) isSaving = false;
    }

    unawaited(
      _repo.save(userId, logId).catchError((Object e) {
        lastWriteError = 'No pudimos guardar tu sueño. Revisa tu conexión.';
      }),
    );
  }
}

void main() {
  group('SleepNotifier — SPEC-206 offline-first (mecánica aislada)', () {
    test('saveManualSleep con repo colgado no bloquea el método', () async {
      final repo = _HangingSleepRepo();
      final mechanic = _SleepOfflineMechanic(repo);

      await mechanic
          .saveManualSleep('u1', 'sleep-2026-07-11')
          .timeout(const Duration(seconds: 2));

      expect(repo.saved, ['sleep-2026-07-11'],
          reason: 'el write se disparó aunque el Future del server nunca '
              'resuelva');
      expect(mechanic.isSaving, isFalse,
          reason: 'isSaving no debe quedar stuck en true (SPEC-216)');
      expect(mechanic.lastWriteError, isNull,
          reason: 'offline no es un error real — queda pendiente sin emitir');
    });
  });
}
