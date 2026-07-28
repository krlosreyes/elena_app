// SPEC-164: tests del TemporalAggregator.

import 'package:elena_app/src/features/analysis/application/temporal_aggregator.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sample {
  final DateTime at;
  final double value;
  const _Sample(this.at, this.value);
}

DateTime _d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('SPEC-164 — TemporalAggregator daily mode', () {
    test('agrupa por día calendárico', () {
      final items = [
        _Sample(_d(2026, 6, 1).add(const Duration(hours: 8)), 1),
        _Sample(_d(2026, 6, 1).add(const Duration(hours: 20)), 2),
        _Sample(_d(2026, 6, 2), 3),
      ];
      final res = TemporalAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: TemporalAggregation.sum,
        mode: AggregationMode.daily,
      );
      expect(res.length, 2);
      expect(res[0].weekStart, _d(2026, 6, 1));
      expect(res[0].value, 3);
      expect(res[1].weekStart, _d(2026, 6, 2));
      expect(res[1].value, 3);
    });
  });

  group('SPEC-164 — TemporalAggregator weekly mode', () {
    test('agrupa por lunes ISO', () {
      final items = [
        _Sample(_d(2026, 6, 4), 1),
        _Sample(_d(2026, 6, 5), 2),
        _Sample(_d(2026, 6, 9), 3),
      ];
      final res = TemporalAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: TemporalAggregation.sum,
        mode: AggregationMode.weekly,
      );
      expect(res.length, 2);
      expect(res[0].weekStart, _d(2026, 6, 1));
      expect(res[1].weekStart, _d(2026, 6, 8));
    });
  });

  group('SPEC-164 — TemporalAggregator monthly mode', () {
    test('agrupa por mes calendárico', () {
      final items = [
        _Sample(_d(2026, 5, 15), 10),
        _Sample(_d(2026, 5, 28), 20),
        _Sample(_d(2026, 6, 1), 30),
        _Sample(_d(2026, 6, 30), 40),
      ];
      final res = TemporalAggregator.aggregate<_Sample>(
        items: items,
        timestampOf: (s) => s.at,
        valueOf: (s) => s.value,
        aggregation: TemporalAggregation.sum,
        mode: AggregationMode.monthly,
      );
      expect(res.length, 2);
      expect(res[0].weekStart, _d(2026, 5, 1));
      expect(res[0].value, 30);
      expect(res[1].weekStart, _d(2026, 6, 1));
      expect(res[1].value, 70);
    });
  });

  group('SPEC-164 — AggregationMode.forRange', () {
    test('1W/1M → daily', () {
      expect(AggregationMode.forRange(AnalysisRange.w1), AggregationMode.daily);
      expect(AggregationMode.forRange(AnalysisRange.m1), AggregationMode.daily);
    });
    test('3M/6M → weekly', () {
      expect(
          AggregationMode.forRange(AnalysisRange.m3), AggregationMode.weekly);
      expect(
          AggregationMode.forRange(AnalysisRange.m6), AggregationMode.weekly);
    });
    test('1A → monthly', () {
      expect(
          AggregationMode.forRange(AnalysisRange.y1), AggregationMode.monthly);
    });
  });
}
