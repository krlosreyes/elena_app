// SPEC-296 — Deduplicación de workouts de múltiples fuentes (bug: sesiones
// duplicadas en el pilar de ejercicio).

import 'package:elena_app/src/features/health_sync/application/health_import_service.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:flutter_test/flutter_test.dart';

HealthSample workout({
  required DateTime start,
  required int minutes,
  String type = 'TRADITIONAL_STRENGTH_TRAINING',
  String source = 'com.apple.health',
}) =>
    HealthSample(
      metric: HealthMetric.workout,
      value: minutes.toDouble(),
      start: start,
      end: start.add(Duration(minutes: minutes)),
      sourceName: source,
      workoutActivityType: type,
    );

void main() {
  final t0 = DateTime(2026, 8, 14, 7, 24);

  test('misma sesión de dos fuentes se colapsa en una (la más larga)', () {
    final out = HealthImportService.dedupWorkoutSamples([
      workout(start: t0, minutes: 31, source: 'com.apple.health'),
      workout(
          start: t0.add(const Duration(minutes: 1)),
          minutes: 28,
          source: 'com.gym.app'),
    ]);
    expect(out.length, 1);
    expect(out.single.value, 31); // conserva la más completa
  });

  test('sesiones distintas que NO se solapan se conservan ambas', () {
    final out = HealthImportService.dedupWorkoutSamples([
      workout(start: t0, minutes: 31),
      workout(
          start: t0.add(const Duration(hours: 2)),
          minutes: 23,
          type: 'WALKING'),
    ]);
    expect(out.length, 2);
  });

  test('solapadas pero de distinto tipo se conservan ambas', () {
    final out = HealthImportService.dedupWorkoutSamples([
      workout(start: t0, minutes: 31, type: 'TRADITIONAL_STRENGTH_TRAINING'),
      workout(start: t0, minutes: 30, type: 'YOGA'),
    ]);
    expect(out.length, 2);
  });

  test('lista vacía o de un elemento no cambia', () {
    expect(HealthImportService.dedupWorkoutSamples(const []), isEmpty);
    final one = [workout(start: t0, minutes: 31)];
    expect(HealthImportService.dedupWorkoutSamples(one).length, 1);
  });
}
