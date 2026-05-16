// SPEC-106: tests del FirestoreSleepV1Source con énfasis en `deleteDoc`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/dashboard/data/sources/firestore_sleep_v1_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreSleepV1Source source;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = FirestoreSleepV1Source(firestore: firestore);
  });

  group('SPEC-106 — deleteDoc', () {
    const userId = 'user-1';

    test('borra el doc especificado y no afecta otros del mismo usuario',
        () async {
      final col =
          firestore.collection('users').doc(userId).collection('sleep_history');

      await col.doc('manual_20260513').set({
        'fellAsleep': Timestamp.fromDate(DateTime(2026, 5, 12, 22, 30)),
        'wokeUp': Timestamp.fromDate(DateTime(2026, 5, 13, 6, 30)),
        'subjectiveQuality': 4,
      });
      await col.doc('manual_20260514').set({
        'fellAsleep': Timestamp.fromDate(DateTime(2026, 5, 13, 23, 0)),
        'wokeUp': Timestamp.fromDate(DateTime(2026, 5, 14, 7, 0)),
        'subjectiveQuality': 3,
      });

      await source.deleteDoc(userId: userId, docId: 'manual_20260514');

      final remaining = await col.get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.id, 'manual_20260513');
    });

    test('deleteDoc de un id inexistente NO lanza (idempotente)', () async {
      // No hay docs sembrados; aún así no debe fallar.
      await expectLater(
        source.deleteDoc(userId: userId, docId: 'no-existe'),
        completes,
      );
    });

    test('no afecta logs de otros usuarios', () async {
      final mine =
          firestore.collection('users').doc(userId).collection('sleep_history');
      final other = firestore
          .collection('users')
          .doc('other-user')
          .collection('sleep_history');

      await mine.doc('manual_20260514').set({
        'fellAsleep': Timestamp.fromDate(DateTime(2026, 5, 13, 23, 0)),
        'wokeUp': Timestamp.fromDate(DateTime(2026, 5, 14, 7, 0)),
      });
      await other.doc('manual_20260514').set({
        'fellAsleep': Timestamp.fromDate(DateTime(2026, 5, 13, 22, 0)),
        'wokeUp': Timestamp.fromDate(DateTime(2026, 5, 14, 6, 30)),
      });

      await source.deleteDoc(userId: userId, docId: 'manual_20260514');

      final mineAfter = await mine.get();
      final otherAfter = await other.get();

      expect(mineAfter.docs, isEmpty);
      expect(otherAfter.docs.length, 1,
          reason: 'Doc del otro usuario debe seguir intacto');
    });
  });
}
