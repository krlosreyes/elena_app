// SPEC-111: tests del FirestoreDailySummaryV1Source con fake_cloud_firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/analysis/data/sources/firestore_daily_summary_v1_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreDailySummaryV1Source source;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = FirestoreDailySummaryV1Source(firestore: firestore);
  });

  const userId = 'user-1';

  group('persist + readDoc', () {
    test('upsert crea el doc con los campos esperados', () async {
      await source.persist(
        userId: userId,
        docId: '20260515',
        data: {
          'date': '2026-05-15',
          'imrScore': 72,
          'fastingProgress': 0.88,
          'sleepProgress': 0.94,
          'hydrationProgress': 0.84,
          'exerciseProgress': 0.58,
          'mealsProgress': 1.0,
          'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 15, 20)),
          'schemaVersion': 1,
        },
      );

      final read = await source.readDoc(userId: userId, docId: '20260515');
      expect(read, isNotNull);
      expect(read!['imrScore'], 72);
      expect(read['date'], '2026-05-15');
    });

    test('readDoc inexistente devuelve null', () async {
      final read = await source.readDoc(userId: userId, docId: '20990101');
      expect(read, isNull);
    });

    test('persist con mismo docId sobrescribe (idempotente)', () async {
      await source.persist(
        userId: userId,
        docId: '20260515',
        data: {'date': '2026-05-15', 'imrScore': 50},
      );
      await source.persist(
        userId: userId,
        docId: '20260515',
        data: {'date': '2026-05-15', 'imrScore': 72},
      );
      final read = await source.readDoc(userId: userId, docId: '20260515');
      expect(read!['imrScore'], 72);

      final col =
          firestore.collection('users').doc(userId).collection('daily_summary');
      final all = await col.get();
      expect(all.docs.length, 1, reason: 'No se duplica');
    });
  });

  group('watchRange', () {
    Future<void> seed(String date, int imr) async {
      await source.persist(
        userId: userId,
        docId: date.replaceAll('-', ''),
        data: {'date': date, 'imrScore': imr},
      );
    }

    test('devuelve docs en el rango inclusivo, ordenados por fecha', () async {
      await seed('2026-05-13', 60);
      await seed('2026-05-14', 65);
      await seed('2026-05-15', 70);
      await seed('2026-05-16', 75);
      await seed('2026-05-17', 80);

      final emitted = await source
          .watchRange(
            userId: userId,
            fromIncl: '2026-05-14',
            toIncl: '2026-05-16',
          )
          .first;

      expect(emitted.length, 3);
      expect(emitted.map((m) => m['date']).toList(),
          ['2026-05-14', '2026-05-15', '2026-05-16']);
    });

    test('rango sin docs emite lista vacía', () async {
      await seed('2026-05-15', 70);
      final emitted = await source
          .watchRange(
            userId: userId,
            fromIncl: '2026-06-01',
            toIncl: '2026-06-30',
          )
          .first;
      expect(emitted, isEmpty);
    });

    test('no incluye docs de otros usuarios', () async {
      await seed('2026-05-15', 70);
      await source.persist(
        userId: 'other-user',
        docId: '20260515',
        data: {'date': '2026-05-15', 'imrScore': 99},
      );

      final emitted = await source
          .watchRange(
            userId: userId,
            fromIncl: '2026-05-15',
            toIncl: '2026-05-15',
          )
          .first;
      expect(emitted.length, 1);
      expect(emitted.first['imrScore'], 70);
    });
  });
}
