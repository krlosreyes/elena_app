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

  group('SPEC-99 — streamLatest prioriza intervalo abierto sobre cerrado más reciente', () {
    const userId = 'user-1';

    test(
        'doc abierto con startTime MENOR a doc cerrado → streamLatest '
        'devuelve el abierto', () async {
      // Caso reportado por Carlos: tiene una ventana cerrada de ayer
      // a las 21:00, y un ayuno abierto que corrigió a las 06:00 de
      // hoy. Por startTime descending, el cerrado de ayer 21:00 es
      // "más reciente". Pero semánticamente el abierto debe ganar.
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 13, 21, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 14, 5, 0)),
        'isFasting': false,
      });
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 14, 6, 0)),
        'endTime': null,
        'isFasting': true,
      });

      final emitted = await source.streamLatest(userId).first;
      expect(emitted, isNotNull);
      expect(emitted!['isFasting'], true,
          reason: 'Debe devolver el ayuno abierto, no la ventana cerrada');
      expect(emitted['endTime'], isNull);
    });

    test('sin doc abierto → devuelve el más reciente cerrado', () async {
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 13, 6, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 13, 14, 0)),
        'isFasting': true,
      });
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 13, 14, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 13, 21, 0)),
        'isFasting': false,
      });

      final emitted = await source.streamLatest(userId).first;
      expect(emitted, isNotNull);
      expect(emitted!['isFasting'], false);
      // Es el de 14:00 (más reciente por startTime entre los cerrados).
      expect(
        (emitted['startTime'] as Timestamp).toDate(),
        DateTime(2026, 5, 13, 14, 0),
      );
    });

    test('sin historial → emite null', () async {
      final emitted = await source.streamLatest(userId).first;
      expect(emitted, isNull);
    });
  });

  group('SPEC-100 — aislamiento por isFasting y tolerancia a data fantasma',
      () {
    const userId = 'user-1';

    test(
        'updateOpenIntervalStartTime con isFastingFilter=true NO toca ventana '
        'fantasma abierta (isFasting=false, endTime=null)', () async {
      final ayunoStart = DateTime(2026, 5, 14, 8, 0);
      final fantasmaStart = DateTime(2026, 5, 13, 21, 0);
      final correctedStart = DateTime(2026, 5, 14, 6, 0);

      final ayunoRef = await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(ayunoStart),
        'endTime': null,
        'isFasting': true,
      });
      final fantasmaRef = await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(fantasmaStart),
        'endTime': null,
        'isFasting': false,
      });

      await source.updateOpenIntervalStartTime(
        userId: userId,
        newStartTime: correctedStart,
        isFastingFilter: true,
      );

      final ayunoAfter = await ayunoRef.get();
      final fantasmaAfter = await fantasmaRef.get();

      expect(
        (ayunoAfter.data()!['startTime'] as Timestamp).toDate(),
        correctedStart,
        reason: 'El ayuno SÍ debe actualizar',
      );
      expect(
        (fantasmaAfter.data()!['startTime'] as Timestamp).toDate(),
        fantasmaStart,
        reason: 'La ventana fantasma NO debe mutar con isFastingFilter=true',
      );
    });

    test(
        'streamLatest con ayuno abierto + ventana fantasma abierta → '
        'emite el ayuno', () async {
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 14, 8, 0)),
        'endTime': null,
        'isFasting': true,
      });
      // Ventana fantasma con startTime MAYOR (más reciente en el orden).
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 14, 20, 0)),
        'endTime': null,
        'isFasting': false,
      });

      final emitted = await source.streamLatest(userId).first;
      expect(emitted, isNotNull);
      expect(emitted!['isFasting'], true,
          reason: 'Debe ganar el ayuno aunque la ventana fantasma '
              'tenga startTime mayor');
    });

    test(
        'streamLatest sin ayuno abierto pero con ventana abierta → emite '
        'la ventana', () async {
      // Caso normal: usuario en ventana de comida (sin ayuno en curso).
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 14, 13, 0)),
        'endTime': null,
        'isFasting': false,
      });

      final emitted = await source.streamLatest(userId).first;
      expect(emitted, isNotNull);
      expect(emitted!['isFasting'], false);
    });
  });

  group('SPEC-101 — streamLastCompletedFasting', () {
    const userId = 'user-1';

    test('emite el último ayuno cerrado del usuario', () async {
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 13, 20, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 14, 12, 0)),
        'isFasting': true,
      });
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 14, 12, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 14, 20, 0)),
        'isFasting': false, // Ventana de comida, NO debe contar.
      });

      final emitted = await source.streamLastCompletedFasting(userId).first;
      expect(emitted, isNotNull);
      expect(emitted!['isFasting'], true);
      expect(
        (emitted['endTime'] as Timestamp).toDate(),
        DateTime(2026, 5, 14, 12, 0),
      );
    });

    test('ignora ayuno abierto (endTime null)', () async {
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 14, 8, 0)),
        'endTime': null,
        'isFasting': true,
      });

      final emitted = await source.streamLastCompletedFasting(userId).first;
      expect(emitted, isNull);
    });

    test('ignora ventanas de comida (isFasting=false) cerradas', () async {
      await firestore.collection('fasting_history').add({
        'userId': userId,
        'startTime': Timestamp.fromDate(DateTime(2026, 5, 14, 12, 0)),
        'endTime': Timestamp.fromDate(DateTime(2026, 5, 14, 20, 0)),
        'isFasting': false,
      });

      final emitted = await source.streamLastCompletedFasting(userId).first;
      expect(emitted, isNull);
    });

    test('sin historial → null', () async {
      final emitted = await source.streamLastCompletedFasting(userId).first;
      expect(emitted, isNull);
    });
  });
}
