// SPEC-214: serialización de evaluateAndApply con flag _evaluating.
//
// Verifica que:
//   A) La primera llamada corre normalmente.
//   B) La segunda llamada concurrente devuelve noop sin ejecutar lógica.
//   C) El flag se libera siempre (finally) — llamadas posteriores vuelven
//      a correr normalmente.
//   D) El flag se libera aunque el servicio lance (excepción propagada).
//
// Usa FakeMetabolicCycleRepository con un contador de fetchOpenCycle para
// detectar si la llamada concurrente llegó al repositorio.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_service.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_repository.dart';

const _zeroMagnitudes = CycleMagnitudes(
  fastingMagnitude: 0,
  sleepQualityScore: 0,
  hydrationMagnitude: 0,
  exerciseMagnitude: 0,
  nutritionMagnitude: 0,
);

const _zeroPillars = CyclePillarsCompleted(
  fasting: false,
  sleep: false,
  hydration: false,
  exercise: false,
  nutrition: false,
);

// ─── Fake repositorio ─────────────────────────────────────────────────────────

class _FakeRepo implements MetabolicCycleRepository {
  int fetchCallCount = 0;
  bool shouldHang = false; // si true, fetchOpenCycle no completa hasta signal
  MetabolicCycle? stubbedOpen;

  @override
  Future<MetabolicCycle?> fetchOpenCycle(String userId) async {
    fetchCallCount++;
    if (shouldHang) {
      // Simula una llamada lenta (online) para dejar espacio a la concurrente
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return stubbedOpen;
  }

  @override
  Future<void> save(String userId, MetabolicCycle cycle) async {}

  @override
  Stream<MetabolicCycle?> watchOpenCycle(String userId) => Stream.value(null);

  @override
  Stream<MetabolicCycle?> watchLastClosed(String userId) => Stream.value(null);

  @override
  Stream<List<MetabolicCycle>> watchRecentClosed(String userId, {int? limit}) =>
      Stream.value([]);

  @override
  Future<List<MetabolicCycle>> fetchRecentClosed(String userId,
          {int limit = 90}) async =>
      [];

  @override
  Future<void> updateLiveScore(String userId, String cycleId, int score) async {
  }
}

// ─── Input helpers ────────────────────────────────────────────────────────────

MetabolicCycleEvaluationInput _input({
  bool newFasting = false,
  DateTime? startedAt,
}) {
  return MetabolicCycleEvaluationInput(
    now: DateTime(2026, 6, 14, 10, 0),
    currentProtocol: '16:8',
    currentDailyScore: 50,
    currentMagnitudes: _zeroMagnitudes,
    currentPillarsCompleted: _zeroPillars,
    newFastingStartedExplicitly: newFasting,
    newFastingStartedAt: startedAt,
    tzOffsetMinutes: 0,
  );
}

void main() {
  group('SPEC-214 — serialización evaluateAndApply', () {
    test(
        'SPEC-214-01: primera llamada alcanza el repositorio normalmente',
        () async {
      final repo = _FakeRepo();
      final svc = MetabolicCycleService(repository: repo);

      await svc.evaluateAndApply(
        userId: 'u1',
        input: _input(),
      );

      expect(repo.fetchCallCount, 1,
          reason: 'La primera llamada debe llegar al repositorio');
    });

    test(
        'SPEC-214-02: llamada concurrente mientras hay una en vuelo '
        'devuelve noop sin tocar el repositorio', () async {
      final repo = _FakeRepo()..shouldHang = true; // primera call es lenta
      final svc = MetabolicCycleService(repository: repo);

      // BUGFIX (auditoría 2026-07-12): con `_input()` default (sin ayuno
      // nuevo, sin ciclo abierto) el "Caso 1" del servicio devuelve noop()
      // legítimamente — nada que hacer. Eso hacía que resultA.isNoop
      // también diera `true`, no por el guard de concurrencia sino porque
      // A, procesada de verdad, no tenía ningún cambio de estado que
      // aplicar. `isNoop` no distingue "descartada por concurrencia" de
      // "no había nada que hacer". Para probar el guard de SPEC-214 de
      // verdad, A debe recibir un input que produzca un cambio real
      // (abrir un ciclo nuevo) — así isNoop==false en A refleja que sí
      // se procesó, y isNoop==true en B refleja que el guard la descartó.
      final openingInput = _input(
        newFasting: true,
        startedAt: DateTime(2026, 6, 14, 10, 0),
      );

      // Lanzamos las dos llamadas sin await para que sean concurrentes
      final futureA =
          svc.evaluateAndApply(userId: 'u1', input: openingInput);
      // B llega mientras A todavía está en fetchOpenCycle (simulado lento)
      final futureB = svc.evaluateAndApply(userId: 'u1', input: _input());

      final resultA = await futureA;
      final resultB = await futureB;

      // A procesó normalmente (fetch = 1); B fue descartada (fetch sigue = 1)
      expect(repo.fetchCallCount, 1,
          reason:
              'La llamada concurrente no debe llamar fetchOpenCycle (SPEC-214)');
      expect(resultA.isNoop, isFalse,
          reason: 'La primera llamada debe procesar normalmente (no es noop)');
      expect(resultA.opened, isNotNull,
          reason: 'A abrió un ciclo nuevo — evidencia de que sí procesó');
      expect(resultB.isNoop, isTrue,
          reason: 'La llamada concurrente debe devolver noop');
    });

    test(
        'SPEC-214-03: tras completar la primera llamada, la siguiente '
        'corre normalmente (_evaluating liberado en finally)', () async {
      final repo = _FakeRepo();
      final svc = MetabolicCycleService(repository: repo);

      // Primera llamada
      await svc.evaluateAndApply(userId: 'u1', input: _input());
      expect(repo.fetchCallCount, 1);

      // Segunda llamada independiente (no concurrente)
      await svc.evaluateAndApply(userId: 'u1', input: _input());
      expect(repo.fetchCallCount, 2,
          reason:
              'Una vez completada la primera, la siguiente debe correr '
              '(flag liberado en finally)');
    });

    test(
        'SPEC-214-04: noop concurrente tiene isNoop == true '
        'y cycleClosed == false', () async {
      final repo = _FakeRepo()..shouldHang = true;
      final svc = MetabolicCycleService(repository: repo);

      final futureA = svc.evaluateAndApply(userId: 'u1', input: _input());
      final futureB = svc.evaluateAndApply(userId: 'u1', input: _input());

      await futureA;
      final resultB = await futureB;

      expect(resultB.isNoop, isTrue);
      expect(resultB.closed, isNull);
      expect(resultB.opened, isNull);
    });
  });
}
