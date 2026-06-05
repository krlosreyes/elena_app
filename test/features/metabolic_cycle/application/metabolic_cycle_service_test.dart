// SPEC-149 §8.3: tests del MetabolicCycleService.
//
// Estrategia: FakeFirebaseFirestore + MetabolicCycleRepositoryImpl real.
// Verifica orquestación: bootstrap, apertura, cierre con feedback,
// idempotencia, transición protocolChanged.

import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_service.dart';
import 'package:elena_app/src/features/metabolic_cycle/data/metabolic_cycle_repository_impl.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

CycleMagnitudes _mag(double q) => CycleMagnitudes(
      fastingMagnitude: q,
      sleepQualityScore: q,
      hydrationMagnitude: q,
      exerciseMagnitude: q,
      nutritionMagnitude: q,
    );

CyclePillarsCompleted _pillars(bool v) => CyclePillarsCompleted(
      fasting: v,
      sleep: v,
      hydration: v,
      exercise: v,
      nutrition: v,
    );

MetabolicCycleEvaluationInput _input({
  required DateTime now,
  String protocol = '16:8',
  DateTime? expectedWindowCloseTime,
  DateTime? lastMealTime,
  bool sleepDetected = false,
  bool newFasting = false,
  DateTime? newFastingAt,
  double mag = 0.5,
  int score = 50,
}) =>
    MetabolicCycleEvaluationInput(
      now: now,
      currentProtocol: protocol,
      currentDailyScore: score,
      currentMagnitudes: _mag(mag),
      currentPillarsCompleted: _pillars(mag >= 0.80),
      expectedWindowCloseTime: expectedWindowCloseTime,
      lastMealTime: lastMealTime,
      sleepDetectedAfterLastMeal: sleepDetected,
      newFastingStartedExplicitly: newFasting,
      newFastingStartedAt: newFastingAt,
      actualWindowClosedAt: null,
      recentInsightIds: const {},
      tzOffsetMinutes: 0,
    );

void main() {
  late FakeFirebaseFirestore firestore;
  late MetabolicCycleRepositoryImpl repo;
  late MetabolicCycleService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = MetabolicCycleRepositoryImpl(firestore);
    service = MetabolicCycleService(repository: repo);
  });

  group('SPEC-149 §8.3 — bootstrap', () {
    test('Sin ciclo abierto y con protocolo TRE → crea ciclo retroactivo',
        () async {
      final now = DateTime(2026, 6, 2, 10, 0);
      final lastFasting = DateTime(2026, 6, 1, 21, 0);
      final cycle = await service.bootstrapIfMissing(
        userId: 'u1',
        protocol: '16:8',
        lastFastingStartTime: lastFasting,
        now: now,
      );
      expect(cycle, isNotNull);
      expect(cycle!.startedAt, lastFasting);
      expect(cycle.isOpen, isTrue);
    });

    test('Con ciclo abierto existente → retorna el existente sin duplicar',
        () async {
      await repo.save(
        'u1',
        MetabolicCycle.open(
          startedAt: DateTime(2026, 6, 1, 21, 0),
          fastingProtocol: '16:8',
          tzOffsetMinutes: 0,
        ),
      );
      final result = await service.bootstrapIfMissing(
        userId: 'u1',
        protocol: '16:8',
        lastFastingStartTime: DateTime(2026, 5, 31, 12, 0),
        now: DateTime(2026, 6, 2, 10, 0),
      );
      expect(result!.startedAt, DateTime(2026, 6, 1, 21, 0));
    });

    test('Protocolo "Ninguno" → ciclo calendárico empieza al inicio del día',
        () async {
      final now = DateTime(2026, 6, 2, 14, 30);
      final cycle = await service.bootstrapIfMissing(
        userId: 'u1',
        protocol: 'Ninguno',
        lastFastingStartTime: null,
        now: now,
      );
      expect(cycle!.startedAt, DateTime(2026, 6, 2, 0, 0));
      expect(cycle.fastingProtocol, 'Ninguno');
    });

    // SPEC-185 (2026-06-05): NO crear ciclo huérfano cuando llega null.
    test('SPEC-185 — Protocolo TRE + lastFastingStartTime null → no crea ciclo',
        () async {
      // Caso reproducido: el caller (metabolicCycleBootstrapProvider)
      // lee fastingProvider.startTime ANTES de que el listener al
      // lastFastingIntervalProvider termine de cargar desde Firestore.
      // Race condition → lastFastingStartTime llega null. ANTES del
      // fix esto creaba ciclo con startedAt=now (bug huérfano).
      final now = DateTime(2026, 6, 5, 16, 32);
      final cycle = await service.bootstrapIfMissing(
        userId: 'u1',
        protocol: '16:8',
        lastFastingStartTime: null,
        now: now,
      );
      expect(cycle, isNull,
          reason: 'sin ayuno persistido no debemos crear ciclo automáticamente');
      // Y no debe haber escrito nada en Firestore.
      final after = await repo.fetchOpenCycle('u1');
      expect(after, isNull);
    });

    test('SPEC-185 — Protocolo TRE + lastFastingStartTime presente → SÍ crea',
        () async {
      // Caso legítimo: usuario tiene ayuno persistido válido. El
      // bootstrap reconstruye el ciclo retroactivo con startedAt
      // = hora real del ayuno, no = now.
      final now = DateTime(2026, 6, 5, 16, 32);
      final lastFasting = DateTime(2026, 6, 5, 8, 0);
      final cycle = await service.bootstrapIfMissing(
        userId: 'u1',
        protocol: '18:6',
        lastFastingStartTime: lastFasting,
        now: now,
      );
      expect(cycle, isNotNull);
      expect(cycle!.startedAt, lastFasting,
          reason: 'startedAt debe ser la hora real del ayuno, no now');
    });
  });

  group('SPEC-149 §8.3 — evaluateAndApply: apertura', () {
    test('Sin ciclo abierto + newFasting=true → abre ciclo nuevo', () async {
      final fastingAt = DateTime(2026, 6, 1, 21, 0);
      final result = await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: fastingAt,
          newFasting: true,
          newFastingAt: fastingAt,
        ),
      );
      expect(result.hasOpening, isTrue);
      expect(result.opened!.startedAt, fastingAt);
      expect(result.opened!.isOpen, isTrue);
    });

    test('Sin ciclo abierto + newFasting=false → noop', () async {
      final result = await service.evaluateAndApply(
        userId: 'u1',
        input: _input(now: DateTime(2026, 6, 1, 14, 0)),
      );
      expect(result.isNoop, isTrue);
    });
  });

  group('SPEC-149 §8.3 — evaluateAndApply: cierre con feedback', () {
    test('Cierre por manualNextFasting → persiste cerrado + abre siguiente',
        () async {
      // Setup: ciclo abierto de hace 24h.
      final originalStart = DateTime(2026, 6, 1, 21, 0);
      await repo.save(
        'u1',
        MetabolicCycle.open(
          startedAt: originalStart,
          fastingProtocol: '16:8',
          tzOffsetMinutes: 0,
        ),
      );

      final nextFasting = DateTime(2026, 6, 2, 21, 0);
      final result = await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: nextFasting,
          newFasting: true,
          newFastingAt: nextFasting,
          mag: 0.9,
          score: 87,
        ),
      );

      expect(result.hasClosure, isTrue);
      expect(result.closed!.closureReason, ClosureReason.manualNextFasting);
      expect(result.closed!.dailyScore, 87);
      expect(result.closed!.feedback, isNotNull);
      expect(result.closed!.feedback!.achievements, isNotEmpty);
      expect(result.hasOpening, isTrue);
      expect(result.opened!.startedAt, nextFasting);
    });

    test('Cierre por fallback3hAfterWindow', () async {
      final originalStart = DateTime(2026, 6, 1, 21, 0);
      await repo.save(
        'u1',
        MetabolicCycle.open(
          startedAt: originalStart,
          fastingProtocol: '16:8',
          tzOffsetMinutes: 0,
        ),
      );

      final now = DateTime(2026, 6, 2, 22, 0);
      final windowClose = DateTime(2026, 6, 2, 19, 0);
      final result = await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: now,
          expectedWindowCloseTime: windowClose,
          lastMealTime: DateTime(2026, 6, 2, 18, 30),
        ),
      );

      expect(result.hasClosure, isTrue);
      expect(result.closed!.closureReason, ClosureReason.fallback3hAfterWindow);
      // NO se abre siguiente automáticamente con este fallback.
      expect(result.hasOpening, isFalse);
    });

    test('Cierre por protocolChanged → abre nuevo con nuevo protocolo',
        () async {
      await repo.save(
        'u1',
        MetabolicCycle.open(
          startedAt: DateTime(2026, 6, 1, 21, 0),
          fastingProtocol: '16:8',
          tzOffsetMinutes: 0,
        ),
      );

      final now = DateTime(2026, 6, 2, 10, 0);
      final result = await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: now,
          protocol: '20:4',
        ),
      );

      expect(result.hasClosure, isTrue);
      expect(result.closed!.closureReason, ClosureReason.protocolChanged);
      expect(result.hasOpening, isTrue);
      expect(result.opened!.fastingProtocol, '20:4');
      expect(result.opened!.startedAt, now);
    });
  });

  group('SPEC-149 §8.3 — idempotencia', () {
    test('Misma evaluación dos veces no duplica docs', () async {
      final fastingAt = DateTime(2026, 6, 1, 21, 0);
      await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: fastingAt,
          newFasting: true,
          newFastingAt: fastingAt,
        ),
      );
      // Segunda llamada con el mismo state.
      await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: fastingAt,
          newFasting: true,
          newFastingAt: fastingAt,
        ),
      );
      final snap = await firestore
          .collection('users')
          .doc('u1')
          .collection('metabolic_cycles')
          .get();
      expect(snap.docs.length, 1, reason: 'cycleId estable → no duplicación');
    });
  });

  group('SPEC-149 §8.3 — persistencia mapper', () {
    test('Ciclo cerrado: round-trip preserva campos del feedback', () async {
      final fastingAt = DateTime(2026, 6, 1, 21, 0);
      await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: fastingAt,
          newFasting: true,
          newFastingAt: fastingAt,
        ),
      );
      final nextFasting = DateTime(2026, 6, 2, 21, 0);
      await service.evaluateAndApply(
        userId: 'u1',
        input: _input(
          now: nextFasting,
          newFasting: true,
          newFastingAt: nextFasting,
          mag: 1.0,
          score: 100,
        ),
      );

      // Leer de Firestore y verificar shape persistido.
      final snap = await firestore
          .collection('users')
          .doc('u1')
          .collection('metabolic_cycles')
          .get();
      expect(snap.docs.length, 2);
      final closedDoc = snap.docs.firstWhere(
        (d) => d.data()['closedAt'] != null,
      );
      final data = closedDoc.data();
      expect(data['dailyScore'], 100);
      expect(data['closureReason'], 'manualNextFasting');
      expect(data['pillarsCompleted'], isA<Map<String, dynamic>>());
      expect(data['feedback'], isA<Map<String, dynamic>>());
    });
  });
}
