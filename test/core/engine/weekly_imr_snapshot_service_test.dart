// SPEC-141 §RF-141-12 (2026-06-05): tests del WeeklyImrSnapshotService.
//
// Valida:
//  - isSnapshotStale: lógica de staleness 7 días
//  - recomputeAndPersist: skip cuando longitudinalScore == null
//  - recomputeAndPersist: persiste cuando hay datos válidos
//  - trigger metadata se propaga al payload

import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/engine/weekly_imr_snapshot_service.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake del repo que captura el payload recibido.
class _CapturingProfileRepo implements UserProfileRepository {
  Map<String, dynamic>? lastWrittenImr;
  Map<String, dynamic>? lastHistorySnapshot;
  String? lastUserId;
  String? lastWeekISO;
  int writeCount = 0;
  int historyWriteCount = 0;

  @override
  Future<void> updateCurrentImr(
    String userId,
    Map<String, dynamic> imrCurrent,
  ) async {
    lastUserId = userId;
    lastWrittenImr = imrCurrent;
    writeCount++;
  }

  @override
  Future<void> writeImrHistorySnapshot({
    required String userId,
    required String weekISO,
    required Map<String, dynamic> snapshot,
  }) async {
    lastUserId = userId;
    lastWeekISO = weekISO;
    lastHistorySnapshot = snapshot;
    historyWriteCount++;
  }

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Method ${invocation.memberName} not stubbed in fake',
    );
  }
}

/// Helper que arma un IMRv2Result con longitudinalScore poblado.
IMRv2Result _longitudinalResult({int? longScore = 64}) {
  return IMRv2Result(
    totalScore: 50,
    structureScore: 0.7,
    metabolicScore: 0.6,
    behaviorScore: 0.5,
    circadianAlignment: 1.0,
    zone: 'EFICIENTE',
    description: 'mock',
    imc: 25,
    tmb: 1700,
    metabolicAge: 35,
    ica: 0.5,
    ffmi: 18,
    whtr: 0.5,
    longitudinalScore: longScore,
    subscoreBehaviorTrend: 0.55,
    subscoreAdherence: 0.40,
    subscoreCoherence: 0.85,
  );
}

void main() {
  group('SPEC-141 §RF-141-12 — isSnapshotStale', () {
    final fixedNow = DateTime.utc(2026, 6, 5, 12, 0, 0);
    final service = WeeklyImrSnapshotService(
      userProfileRepo: _CapturingProfileRepo(),
      clock: () => fixedNow,
    );

    test('null lastComputedAt → true (nunca se computó)', () {
      expect(service.isSnapshotStale(lastComputedAt: null), isTrue);
    });

    test('hace 6 días → false (aún fresco)', () {
      final past = fixedNow.subtract(const Duration(days: 6));
      expect(service.isSnapshotStale(lastComputedAt: past), isFalse);
    });

    test('hace exactamente 7 días → true (umbral inclusive)', () {
      final past = fixedNow.subtract(const Duration(days: 7));
      expect(service.isSnapshotStale(lastComputedAt: past), isTrue);
    });

    test('hace 30 días → true (stale)', () {
      final past = fixedNow.subtract(const Duration(days: 30));
      expect(service.isSnapshotStale(lastComputedAt: past), isTrue);
    });
  });

  group('SPEC-141 §RF-141-12 — recomputeAndPersist', () {
    test('skip cuando longitudinalScore es null', () async {
      final repo = _CapturingProfileRepo();
      final service = WeeklyImrSnapshotService(userProfileRepo: repo);
      final emptyLong = _longitudinalResult(longScore: null);

      await service.recomputeAndPersist(
        userId: 'u1',
        longitudinal: emptyLong,
        trigger: WeeklyImrTrigger.biometricCheckin,
      );

      expect(repo.writeCount, 0);
    });

    test('persiste cuando hay longitudinalScore válido', () async {
      final repo = _CapturingProfileRepo();
      final fixedNow = DateTime.utc(2026, 6, 5, 12, 0, 0);
      final service = WeeklyImrSnapshotService(
        userProfileRepo: repo,
        clock: () => fixedNow,
      );

      await service.recomputeAndPersist(
        userId: 'u1',
        longitudinal: _longitudinalResult(longScore: 64),
        trigger: WeeklyImrTrigger.biometricCheckin,
      );

      expect(repo.writeCount, 1);
      expect(repo.lastUserId, 'u1');
      expect(repo.lastWrittenImr!['scoreVariant'], 'longitudinal');
      expect(repo.lastWrittenImr!['trigger'], 'biometricCheckin');
      expect(repo.lastWrittenImr!['computedAt'],
          fixedNow.toIso8601String());
    });

    test('trigger stalenessFallback se propaga', () async {
      final repo = _CapturingProfileRepo();
      final service = WeeklyImrSnapshotService(userProfileRepo: repo);

      await service.recomputeAndPersist(
        userId: 'u2',
        longitudinal: _longitudinalResult(),
        trigger: WeeklyImrTrigger.stalenessFallback,
      );

      expect(repo.lastWrittenImr!['trigger'], 'stalenessFallback');
    });

    test('escribe TAMBIÉN al imr_history con weekISO computado', () async {
      final repo = _CapturingProfileRepo();
      final fixedNow = DateTime.utc(2026, 6, 5, 12, 0, 0);
      final service = WeeklyImrSnapshotService(
        userProfileRepo: repo,
        clock: () => fixedNow,
      );

      await service.recomputeAndPersist(
        userId: 'u1',
        longitudinal: _longitudinalResult(),
        trigger: WeeklyImrTrigger.biometricCheckin,
      );

      expect(repo.historyWriteCount, 1);
      expect(repo.lastWeekISO, isNotNull);
      expect(repo.lastWeekISO!.startsWith('2026-W'), isTrue);
      expect(repo.lastHistorySnapshot!['weekISO'], repo.lastWeekISO);
    });

    test('payload del history incluye subscores del longitudinal', () async {
      final repo = _CapturingProfileRepo();
      final service = WeeklyImrSnapshotService(userProfileRepo: repo);

      await service.recomputeAndPersist(
        userId: 'u1',
        longitudinal: _longitudinalResult(),
        trigger: WeeklyImrTrigger.biometricCheckin,
      );

      // Mapper SPEC-141: schemaVersion=2 cuando hay longitudinalScore.
      expect(repo.lastHistorySnapshot!['schemaVersion'], 2);
      expect(repo.lastHistorySnapshot!['scoreVariant'], 'longitudinal');
      expect(repo.lastHistorySnapshot!['legacyDailyScore'], 50);
      final sub = repo.lastHistorySnapshot!['subscores'] as Map;
      expect(sub['behaviorTrend'], 0.55);
      expect(sub['adherence'], 0.40);
      expect(sub['coherence'], 0.85);
    });
  });

  group('SPEC-141 §RF-141-12 — buildWeekISO', () {
    test('lunes 1-jun-2026 cae en W23 del año', () {
      // ISO week 23 of 2026 contains Mon 1-jun.
      expect(buildWeekISO(DateTime.utc(2026, 6, 1)), '2026-W23');
    });

    test('jueves 1-ene-2026 → W01', () {
      // Thursday in week 1 by ISO rule.
      expect(buildWeekISO(DateTime.utc(2026, 1, 1)), '2026-W01');
    });

    test('mismo weekISO para todos los días de la semana', () {
      final monday = DateTime.utc(2026, 6, 1);
      final sunday = DateTime.utc(2026, 6, 7);
      expect(buildWeekISO(monday), buildWeekISO(sunday));
    });
  });
}
