// SPEC-97: tests del FirestoreFastingIntervalV1Source con énfasis en
// `updateOpenIntervalStartTime` — el método nuevo que corrige hora de
// inicio sin cerrar el intervalo.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/dashboard/data/sources/firestore_fasting_interval_v1_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreFastingIntervalV1Source source;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = FirestoreFastingIntervalV1Source(firestore: firestore);
  });

  group('SPEC-97 — updateOpenIntervalStartTime', () {
    const userId = 'user-1';

    test('muta el startTime del único intervalo abierto', () async {
      final originalStart = DateTime(2026, 5, 14, 19, 0);
      final correctedStart = DateTime(2026, 5, 14, 18, 0);

      // Sembrar un intervalo abierto.
      final docRef = await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(originalStart),
        'endTime': null,
        'isFasting': true,
      });

      await source.updateOpenIntervalStartTime(
        userId: userId,
        newStartTime: correctedStart,
      );

      final updated = await docRef.get();
      final ts = updated.data()!['startTime'] as Timestamp;
      expect(ts.toDate(), correctedStart);

      // endTime sigue null → no se cerró.
      expect(updated.data()!['endTime'], isNull);
      // isFasting no cambia.
      expect(updated.data()!['isFasting'], true);
    });

    test('NO toca intervalos cerrados del mismo usuario', () async {
      final closedStart = DateTime(2026, 5, 13, 10, 0);
      final closedEnd = DateTime(2026, 5, 13, 20, 0);
      final openStart = DateTime(2026, 5, 14, 19, 0);
      final correctedStart = DateTime(2026, 5, 14, 18, 0);

      // Intervalo cerrado (debe quedar intacto).
      final closedRef = await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(closedStart),
        'endTime': Timestamp.fromDate(closedEnd),
        'isFasting': true,
      });

      // Intervalo abierto (debe corregirse).
      final openRef = await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(openStart),
        'endTime': null,
        'isFasting': true,
      });

      await source.updateOpenIntervalStartTime(
        userId: userId,
        newStartTime: correctedStart,
      );

      final closedAfter = await closedRef.get();
      final openAfter = await openRef.get();

      expect(
        (closedAfter.data()!['startTime'] as Timestamp).toDate(),
        closedStart,
        reason: 'El cerrado NO debe mutar',
      );
      expect(
        (openAfter.data()!['startTime'] as Timestamp).toDate(),
        correctedStart,
        reason: 'El abierto SÍ debe mutar',
      );
    });

    test('NO toca intervalos abiertos de OTRO usuario', () async {
      final mineStart = DateTime(2026, 5, 14, 19, 0);
      final otherStart = DateTime(2026, 5, 14, 17, 0);
      final correctedStart = DateTime(2026, 5, 14, 18, 0);

      final mineRef = await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(mineStart),
        'endTime': null,
        'isFasting': true,
      });

      final otherRef = await firestore.collection('fasting_history').add({
        'userId': 'OTHER',
        'startTime': Timestamp.fromDate(otherStart),
        'endTime': null,
        'isFasting': true,
      });

      await source.updateOpenIntervalStartTime(
        userId: userId,
        newStartTime: correctedStart,
      );

      final mineAfter = await mineRef.get();
      final otherAfter = await otherRef.get();

      expect(
        (mineAfter.data()!['startTime'] as Timestamp).toDate(),
        correctedStart,
      );
      expect(
        (otherAfter.data()!['startTime'] as Timestamp).toDate(),
        otherStart,
        reason: 'El abierto del otro usuario no se toca',
      );
    });

    test('sin intervalo abierto → lanza StateError', () async {
      // Solo cerrados.
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 13)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 13, 20)),
        'isFasting': true,
      });

      expect(
        () => source.updateOpenIntervalStartTime(
          userId: userId,
          newStartTime: DateTime(2026, 5, 14, 18),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
