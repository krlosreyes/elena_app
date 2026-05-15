// SPEC-111: tests del mapper Doc ↔ Map de Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/data/mappers/daily_summary_mapper.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DailySummaryMapper();

  group('DailySummaryMapper.toDoc', () {
    test('toma el `date` del `now` inyectado, no del summary', () {
      final summary = DailySummary.compute(
        imrScore: 72,
        fastingProgress: 0.88,
        sleepProgress: 0.94,
        hydrationProgress: 0.84,
        exerciseProgress: 0.58,
        mealsProgress: 1.0,
      );
      final doc = mapper.toDoc(
        summary: summary,
        now: DateTime(2026, 5, 15, 18, 30),
      );

      expect(doc.date, '2026-05-15');
      expect(doc.imrScore, 72);
      expect(doc.fastingProgress, 0.88);
      expect(doc.updatedAt, DateTime(2026, 5, 15, 18, 30));
      expect(doc.schemaVersion, 1);
    });
  });

  group('DailySummaryMapper.docIdFor', () {
    test('devuelve YYYYMMDD sin separadores', () {
      expect(DailySummaryMapper.docIdFor(DateTime(2026, 5, 15)), '20260515');
      expect(DailySummaryMapper.docIdFor(DateTime(2026, 12, 9)), '20261209');
    });

    test('pad de mes y día con cero', () {
      expect(DailySummaryMapper.docIdFor(DateTime(2026, 1, 3)), '20260103');
    });
  });

  group('DailySummaryMapper.toMap + fromMap', () {
    test('round-trip preserva todos los campos', () {
      final doc = DailySummaryDoc(
        date: '2026-05-15',
        imrScore: 72,
        fastingProgress: 0.88,
        sleepProgress: 0.94,
        hydrationProgress: 0.84,
        exerciseProgress: 0.58,
        mealsProgress: 1.0,
        updatedAt: DateTime(2026, 5, 15, 18, 30),
        schemaVersion: 1,
      );

      final map = mapper.toMap(doc);
      expect(map['updatedAt'], isA<Timestamp>());

      final reparsed = mapper.fromMap(map);
      expect(reparsed.date, doc.date);
      expect(reparsed.imrScore, doc.imrScore);
      expect(reparsed.fastingProgress, doc.fastingProgress);
      expect(reparsed.sleepProgress, doc.sleepProgress);
      expect(reparsed.hydrationProgress, doc.hydrationProgress);
      expect(reparsed.exerciseProgress, doc.exerciseProgress);
      expect(reparsed.mealsProgress, doc.mealsProgress);
      expect(reparsed.updatedAt, doc.updatedAt);
      expect(reparsed.schemaVersion, 1);
    });

    test('fromMap tolera campos faltantes con defaults seguros', () {
      final partial = {
        'date': '2026-05-15',
        // los demás campos faltan
      };
      final doc = mapper.fromMap(partial);
      expect(doc.date, '2026-05-15');
      expect(doc.imrScore, 0);
      expect(doc.fastingProgress, 0.0);
      expect(doc.schemaVersion, 1);
    });
  });
}
