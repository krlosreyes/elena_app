// TEST-03 (auditoría pre-producción 2026-07-11): SPEC-206 offline-first
// para ExerciseNotifier.registerExercise/removeLastSession.
//
// ExerciseNotifier depende de currentUserStreamProvider,
// currentMetabolicCycleProvider y coachingCompletionProvider — mismo tipo
// de dependencia pesada de Riverpod/Firebase que motivó a
// sleep_notifier_spec216_test.dart a NO instanciar el notifier completo.
// Se sigue la misma convención acá: se replica la mecánica exacta de
// `unawaited(repo.save(...).then(...).catchError(...))` de
// lib/src/features/exercise/application/exercise_notifier.dart en una
// mini-implementación aislada.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Repo mínimo cuyo `save` nunca resuelve — mismo `_HangingSaveRepo` de
/// metabolic_cycle_service_test.dart (SPEC-206), adaptado a la forma de
/// ExerciseRepository.save.
class _HangingExerciseRepo {
  final saved = <int>[];

  Future<void> save(String userId, int durationMinutes) {
    saved.add(durationMinutes);
    return Completer<void>().future; // nunca completa
  }

  Future<void> removeLastSession(String userId, DateTime since) {
    return Completer<void>().future; // nunca completa
  }
}

/// Replica el patrón real de ExerciseNotifier.registerExercise: isSaving
/// se pone en true ANTES del write, y el write en sí es fire-and-forget
/// vía `unawaited(...).then(...).catchError(...)` — isSaving solo vuelve
/// a false cuando el Future del server resuelve o falla, nunca bloqueando
/// el método que lo invoca.
class _ExerciseOfflineMechanic {
  _ExerciseOfflineMechanic(this._repo);
  final _HangingExerciseRepo _repo;

  bool isSaving = false;
  String? error;

  Future<void> registerExercise(String userId, int minutes) async {
    isSaving = true;
    error = null;

    unawaited(
      _repo.save(userId, minutes).then((_) {
        isSaving = false;
      }).catchError((Object e) {
        isSaving = false;
        error = 'Fallo al guardar: $e';
      }),
    );
  }

  Future<void> removeLastSession(String userId, DateTime since) async {
    unawaited(
      _repo.removeLastSession(userId, since).catchError((Object e) {
        error = 'No pudimos eliminar la sesión. Revisa tu conexión.';
      }),
    );
  }
}

void main() {
  group('ExerciseNotifier — SPEC-206 offline-first (mecánica aislada)', () {
    test('registerExercise con repo colgado no bloquea el método', () async {
      final repo = _HangingExerciseRepo();
      final mechanic = _ExerciseOfflineMechanic(repo);

      await mechanic
          .registerExercise('u1', 30)
          .timeout(const Duration(seconds: 2));

      expect(repo.saved, [30],
          reason: 'el write se disparó aunque el Future del server nunca '
              'resuelva');
      // isSaving se queda en true hasta que el server confirme (o falle) —
      // exactamente el comportamiento real: si el device está offline, el
      // sheet puede seguir mostrando "guardando" hasta reconectar, PERO el
      // método público (registerExercise) ya retornó — no bloquea el hilo
      // de UI ni impide seguir navegando.
      expect(mechanic.isSaving, isTrue,
          reason: 'isSaving refleja que el ack de red sigue pendiente; '
              'esto es distinto de "el método se colgó"');
      expect(mechanic.error, isNull);
    });

    test('removeLastSession con repo colgado no bloquea el método', () async {
      final repo = _HangingExerciseRepo();
      final mechanic = _ExerciseOfflineMechanic(repo);

      await mechanic
          .removeLastSession('u1', DateTime(2026, 7, 11))
          .timeout(const Duration(seconds: 2));
    });
  });
}
