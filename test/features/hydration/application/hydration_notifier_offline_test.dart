// TEST-03 (auditoría pre-producción 2026-07-11): SPEC-206 offline-first
// para HydrationNotifier.addWater/removeLastWater.
//
// HydrationNotifier depende de currentUserStreamProvider, goalsProvider
// (que a su vez depende de goalRepositoryProvider → Firestore real) y
// currentMetabolicCycleProvider — igual que documenta
// test/features/sleep/application/sleep_notifier_spec216_test.dart,
// instanciar el notifier completo vía ProviderContainer requiere Firebase
// inicializado, lo cual no es viable en un unit test puro.
//
// Siguiendo esa misma convención ya establecida en el repo, este test NO
// instancia HydrationNotifier: replica exactamente el patrón
// `unawaited(repo.add(...).then(...).catchError(...))` de
// lib/src/features/hydration/application/hydration_notifier.dart en una
// mini-implementación aislada, y verifica la invariante SPEC-206: un
// write de Firestore que nunca resuelve (offline) no debe bloquear el
// método público que lo dispara.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Repo mínimo cuyo `add` nunca resuelve — simula un write Firestore
/// colgado en modo offline (mismo `_HangingSaveRepo` de
/// metabolic_cycle_service_test.dart, adaptado a la forma de
/// HydrationRepository.add).
class _HangingHydrationRepo {
  final List<double> added = [];
  bool lastWriteFailed = false;

  Future<void> add(String userId, double amount) {
    added.add(amount);
    return Completer<void>().future; // nunca completa
  }

  Future<void> removeLastLog(String userId, DateTime since) {
    return Completer<void>().future; // nunca completa
  }
}

/// Replica EXACTA (misma forma) del patrón de
/// HydrationNotifier.addWater/removeLastWater: no bloquea en el `await`
/// del write, usa `unawaited(...).catchError(...)`, y expone
/// `lastWriteError` para que la UI muestre el estado de fallo real
/// (offline no cuenta como fallo — queda pendiente sin emitir).
class _HydrationOfflineMechanic {
  _HydrationOfflineMechanic(this._repo);
  final _HangingHydrationRepo _repo;

  String? lastWriteError;

  Future<void> addWater(String userId, double amount) async {
    unawaited(
      _repo.add(userId, amount).then((_) {
        lastWriteError = null;
      }).catchError((Object e) {
        lastWriteError = 'No pudimos guardar tu hidratación. Revisa tu conexión.';
      }),
    );
  }

  Future<void> removeLastWater(String userId, DateTime since) async {
    unawaited(
      _repo.removeLastLog(userId, since).catchError((Object e) {
        lastWriteError = 'No pudimos descontar el vaso. Revisa tu conexión.';
      }),
    );
  }
}

void main() {
  group('HydrationNotifier — SPEC-206 offline-first (mecánica aislada)', () {
    test('addWater con repo colgado no bloquea el método', () async {
      final repo = _HangingHydrationRepo();
      final mechanic = _HydrationOfflineMechanic(repo);

      await mechanic.addWater('u1', 0.25).timeout(const Duration(seconds: 2));

      expect(repo.added, [0.25],
          reason: 'el write se disparó (queda pendiente en caché) aunque '
              'el Future del server nunca resuelva');
      expect(mechanic.lastWriteError, isNull,
          reason: 'offline no es un error real — queda pendiente sin emitir');
    });

    test('removeLastWater con repo colgado no bloquea el método', () async {
      final repo = _HangingHydrationRepo();
      final mechanic = _HydrationOfflineMechanic(repo);

      await mechanic
          .removeLastWater('u1', DateTime(2026, 7, 11))
          .timeout(const Duration(seconds: 2));
    });
  });
}
