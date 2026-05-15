// SPEC-113: tests puros del InsightsService.

import 'package:elena_app/src/features/analysis/application/insights_service.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:flutter_test/flutter_test.dart';

DailySummaryDoc _doc({
  required String date,
  int imr = 70,
  double f = 0,
  double s = 0,
  double h = 0,
  double e = 0,
  double m = 0,
}) {
  return DailySummaryDoc(
    date: date,
    imrScore: imr,
    fastingProgress: f,
    sleepProgress: s,
    hydrationProgress: h,
    exerciseProgress: e,
    mealsProgress: m,
    updatedAt: DateTime(2026, 5, 15),
  );
}

void main() {
  group('InsightsService.generate', () {
    test('lista vacía → insight motivacional único', () {
      final out = InsightsService.generate([]);
      expect(out, hasLength(1));
      expect(out.first.title.toLowerCase(), contains('sin'));
    });

    test('detecta pilar más constante (Ayuno al 100% siempre)', () {
      final docs = List<DailySummaryDoc>.generate(
        7,
        (i) => _doc(date: '2026-05-0${i + 1}', imr: 70, f: 1.0),
      );
      final out = InsightsService.generate(docs);
      final strongest = out.firstWhere(
        (i) => i.title.toLowerCase().contains('constante'),
      );
      expect(strongest.description.toLowerCase(), contains('ayuno'));
    });

    test('detecta pilar a trabajar (Hidratación siempre baja)', () {
      final docs = List<DailySummaryDoc>.generate(
        7,
        (i) => _doc(date: '2026-05-0${i + 1}', imr: 70, f: 1.0, s: 1.0, e: 1.0, m: 1.0, h: 0.1),
      );
      final out = InsightsService.generate(docs);
      final weak = out.firstWhere(
        (i) => i.title.toLowerCase().contains('trabajar'),
      );
      expect(weak.description.toLowerCase(), contains('hidratación'));
    });

    test('detecta mejor día (IMR máximo)', () {
      final docs = [
        _doc(date: '2026-05-09', imr: 50),
        _doc(date: '2026-05-10', imr: 88),
        _doc(date: '2026-05-11', imr: 60),
      ];
      final out = InsightsService.generate(docs);
      final best = out.firstWhere(
        (i) => i.title.toLowerCase().contains('mejor'),
      );
      expect(best.description, contains('88'));
      expect(best.description.toLowerCase(), contains('may'));
    });

    test('incluye un insight de promedio del período', () {
      final docs = [
        _doc(date: '2026-05-09', imr: 60),
        _doc(date: '2026-05-10', imr: 80),
      ];
      final out = InsightsService.generate(docs);
      final avg = out.firstWhere(
        (i) => i.title.toLowerCase().contains('promedio'),
      );
      expect(avg.description, contains('70'));
    });
  });
}
