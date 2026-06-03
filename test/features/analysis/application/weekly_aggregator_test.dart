// SPEC-162: tests del WeeklyAggregator (pure Dart).

import 'package:elena_app/src/features/analysis/application/weekly_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sample {
  final DateTime at;
  final double value;
  const _Sample(this.at, this.value);
}

DateTime _d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('SPEC-162 — WeeklyAggregator.aggregate', () {
    test('items vacío retorna lista vacía', () {
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: const [],
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.sum,
      );
      expect(res, isEmpty);
    });

    test('agrupa por lunes ISO de la semana', () {
      // miércoles 4 jun 2026, jueves 5 jun → misma semana (lunes 2 jun)
      // lunes 9 jun → semana siguiente
      final items = [
        _Sample(_d(2026, 6, 4), 1),
        _Sample(_d(2026, 6, 5), 2),
        _Sample(_d(2026, 6, 9), 3),
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.sum,
      );
      expect(res.length, 2);
      expect(res[0].weekStart, _d(2026, 6, 1)); // lunes 1 jun (jun 4/5 caen acá)
      expect(res[0].value, 3.0);
      expect(res[0].sampleCount, 2);
      expect(res[1].weekStart, _d(2026, 6, 8)); // lunes 8 jun (jun 9 cae acá)
      expect(res[1].value, 3.0);
      expect(res[1].sampleCount, 1);
    });

    test('aggregation sum suma los valores', () {
      final items = [
        _Sample(_d(2026, 6, 1), 10),
        _Sample(_d(2026, 6, 2), 20),
        _Sample(_d(2026, 6, 3), 30),
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.sum,
      );
      expect(res.length, 1);
      expect(res.first.value, 60);
    });

    test('aggregation avg promedia', () {
      final items = [
        _Sample(_d(2026, 6, 1), 10),
        _Sample(_d(2026, 6, 2), 20),
        _Sample(_d(2026, 6, 3), 30),
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.avg,
      );
      expect(res.first.value, 20);
    });

    test('aggregation count cuenta items sin importar value', () {
      final items = [
        _Sample(_d(2026, 6, 1), 999),
        _Sample(_d(2026, 6, 2), 0),
        _Sample(_d(2026, 6, 3), -50),
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.count,
      );
      expect(res.first.value, 3);
    });

    test('aggregation last toma el más reciente', () {
      final items = [
        _Sample(_d(2026, 6, 1), 100),
        _Sample(_d(2026, 6, 3), 50),
        _Sample(_d(2026, 6, 2), 75),
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.last,
      );
      expect(res.first.value, 50);
    });

    test('aggregation max toma el mayor', () {
      final items = [
        _Sample(_d(2026, 6, 1), 5),
        _Sample(_d(2026, 6, 2), 25),
        _Sample(_d(2026, 6, 3), 15),
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.max,
      );
      expect(res.first.value, 25);
    });

    test('semanas sin items no se emiten (no se rellena con 0)', () {
      final items = [
        _Sample(_d(2026, 6, 1), 10), // semana 1
        // semana 2 vacía (sin items entre 8 y 14 jun)
        _Sample(_d(2026, 6, 16), 20), // semana 3
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.sum,
      );
      expect(res.length, 2); // NO 3
    });

    test('weeksToShow limita a las últimas N semanas con data', () {
      final items = [
        _Sample(_d(2026, 5, 4), 1),  // semana 1
        _Sample(_d(2026, 5, 11), 2), // semana 2
        _Sample(_d(2026, 5, 18), 3), // semana 3
        _Sample(_d(2026, 5, 25), 4), // semana 4
        _Sample(_d(2026, 6, 1), 5),  // semana 5
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.sum,
        weeksToShow: 3,
      );
      expect(res.length, 3);
      expect(res.first.value, 3.0); // semana 3
      expect(res.last.value, 5.0); // semana 5
    });

    test('items desordenados quedan ordenados en output', () {
      final items = [
        _Sample(_d(2026, 6, 9), 3),
        _Sample(_d(2026, 6, 2), 1),
        _Sample(_d(2026, 6, 16), 5),
      ];
      final res = WeeklyAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: WeeklyAggregation.sum,
      );
      expect(res.map((p) => p.weekStart).toList(), [
        _d(2026, 6, 1),
        _d(2026, 6, 8),
        _d(2026, 6, 15),
      ]);
    });
  });
}
