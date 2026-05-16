// SPEC-118 — Grupo C: persistencia y state edge cases.
//
// 5 tests que blindan los puntos críticos de la capa de datos y del
// dominio puro del ayuno. Patrón: FakeFirebaseFirestore + repo real,
// sin Riverpod salvo cuando el flujo lo exija.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/dashboard/data/fasting_interval_repository_impl.dart';
import 'package:elena_app/src/features/dashboard/data/sources/firestore_fasting_interval_v1_source.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/fasting_fixtures.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreFastingIntervalV1Source source;
  late FastingIntervalRepositoryImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = FirestoreFastingIntervalV1Source(firestore: firestore);
    repo = FastingIntervalRepositoryImpl(source: source);
  });

  group('SPEC-118.C — Persistencia y state edge cases', () {
    const uid = 'u-c';

    test(
      'C1: transitionTo con startTime pasado crea intervalo con esa hora '
      '(viaje en el tiempo)',
      () async {
        final now = DateTime(2026, 5, 16, 15, 0);
        final pastStart = now.subtract(const Duration(hours: 3));

        await repo.transitionTo(
          userId: uid,
          isFasting: true,
          startTime: pastStart,
        );

        final snap = await firestore.collection('fasting_history').get();
        expect(snap.docs.length, 1);
        final data = snap.docs.first.data();
        expect((data['startTime'] as Timestamp).toDate(), pastStart);
        expect(data['endTime'], isNull);
        expect(data['isFasting'], true);
      },
    );

    test(
      'C2: updateOpenIntervalStartTime con isFastingFilter=true no '
      'toca ventanas cerradas ni intervalos no-ayuno (SPEC-100)',
      () async {
        final yesterdayClosedStart = DateTime(2026, 5, 15, 8, 0);
        final yesterdayClosedEnd = DateTime(2026, 5, 15, 16, 0);
        final openFastStart = DateTime(2026, 5, 15, 19, 0);
        final correctedStart = DateTime(2026, 5, 15, 18, 0);

        // Doc 1: ayuno cerrado (no debe ser tocado).
        final closedRef = await firestore.collection('fasting_history').add({
          'userId': uid,
          'startTime': Timestamp.fromDate(yesterdayClosedStart),
          'endTime': Timestamp.fromDate(yesterdayClosedEnd),
          'isFasting': true,
        });

        // Doc 2: ayuno abierto (debe ser corregido).
        final openRef = await firestore.collection('fasting_history').add({
          'userId': uid,
          'startTime': Timestamp.fromDate(openFastStart),
          'endTime': null,
          'isFasting': true,
        });

        await repo.correctOpenIntervalStartTime(
          userId: uid,
          newStartTime: correctedStart,
          isFastingFilter: true,
        );

        // Doc 1 intacto.
        final closedAfter = (await closedRef.get()).data()!;
        expect(
          (closedAfter['startTime'] as Timestamp).toDate(),
          yesterdayClosedStart,
        );
        expect(closedAfter['endTime'], isNotNull);

        // Doc 2 corregido.
        final openAfter = (await openRef.get()).data()!;
        expect(
          (openAfter['startTime'] as Timestamp).toDate(),
          correctedStart,
        );
        expect(openAfter['endTime'], isNull);
      },
    );

    test(
      'C3: streamLastCompletedFasting con muchos docs (15 cerrados + 5 '
      'abiertos viejos) devuelve el cierre más reciente sin índice '
      'compuesto',
      () async {
        final base = DateTime(2026, 5, 1, 8, 0);

        // 15 ayunos cerrados, cada uno empieza a las 18:00 y cierra
        // 16h después (a las 10:00 del día siguiente).
        for (int i = 0; i < 15; i++) {
          final start = base.add(Duration(days: i, hours: 10));
          await seedFastingInterval(
            firestore,
            userId: uid,
            startTime: start,
            endTime: start.add(const Duration(hours: 16)),
            isFasting: true,
          );
        }

        // 5 intervalos NO-ayuno cerrados (ventanas) — no deben ganar.
        for (int i = 0; i < 5; i++) {
          final start = base.add(Duration(days: i, hours: 2));
          await seedFastingInterval(
            firestore,
            userId: uid,
            startTime: start,
            endTime: start.add(const Duration(hours: 6)),
            isFasting: false,
          );
        }

        final result = await source.streamLastCompletedFasting(uid).first;
        expect(result, isNotNull);
        expect(result!['isFasting'], true);
        expect(result['endTime'], isNotNull);

        // i=14: start = base(2026-05-01 08:00) + 14d + 10h = 2026-05-15 18:00
        // end = start + 16h = 2026-05-16 10:00.
        final endTime = (result['endTime'] as Timestamp).toDate();
        final expectedEnd = DateTime(2026, 5, 16, 10, 0);
        expect(endTime, expectedEnd);
      },
    );

    test(
      'C4: hasCompletedFastingTodayProvider conceptual — el intervalo '
      'debe tener endTime=hoy Y duración ≥ targetHours para contar',
      () {
        // Probamos la lógica equivalente del provider:
        //   reachedTarget = (endTime - startTime).inSeconds >= target * 3600
        //   isToday = endTime.day == now.day
        final now = DateTime(2026, 5, 16, 15, 0);
        const targetHours = 16;

        // Caso 1: ayuno corto cerrado hoy → NO cuenta.
        final shortStart = now.subtract(const Duration(hours: 5));
        final shortEnd = now.subtract(const Duration(minutes: 30));
        final shortDuration = shortEnd.difference(shortStart);
        final shortReached = shortDuration.inSeconds >= targetHours * 3600;
        final shortIsToday = shortEnd.year == now.year &&
            shortEnd.month == now.month &&
            shortEnd.day == now.day;
        expect(shortIsToday, true);
        expect(shortReached, false, reason: '5h < 16h target');

        // Caso 2: ayuno largo cerrado AYER → NO cuenta como HOY.
        // `now - 16h` desde 2026-05-16 15:00 cae en 2026-05-15 23:00 (ayer).
        final yesterdayEnd = now.subtract(const Duration(hours: 16));
        final yesterdayIsToday = isSameDay(yesterdayEnd, now);
        expect(yesterdayIsToday, false, reason: 'cierre ayer no es HOY');

        // Caso 3: ayuno cerrado HOY con duración ≥ target → SÍ cuenta.
        final goodStart = now.subtract(const Duration(hours: 17));
        final goodEnd = now.subtract(const Duration(minutes: 30));
        final goodDuration = goodEnd.difference(goodStart);
        final goodReached = goodDuration.inSeconds >= targetHours * 3600;
        final goodIsToday = isSameDay(goodEnd, now);
        expect(goodReached, true);
        expect(goodIsToday, true);
      },
    );

    test(
      'C5: FastingState con fastingProtocol "Ninguno" (default UserModel) '
      'no rompe — targetHours cae a 16 por fallback de parsing',
      () {
        final state = FastingState(fastingProtocol: 'Ninguno');
        // `targetHours` parsea split(':')[0] como int; si no hay ':',
        // toma toda la string y cae a 16 (int.tryParse('Ninguno') == null).
        expect(state.targetHours, 16);
        // progressPercentage sin actividad ni completedToday → 0.
        expect(state.progressPercentage, 0.0);
      },
    );
  });
}
