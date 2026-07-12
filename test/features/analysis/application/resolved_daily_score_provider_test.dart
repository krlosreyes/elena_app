// SPEC-219 rev2 (2026-06-17): blinda resolvedDailyScoreSeriesProvider.
//
// Regla de negocio crítica que estos tests protegen:
//   1. Cuando hay ciclos metabólicos cerrados con score → usarlos.
//   2. Cuando los ciclos están vacíos o cargando → serie vacía, SIN
//      fallback a streak calendárico (el fallback se eliminó en rev2
//      porque el streak es un snapshot en vivo del día calendario que
//      produce scores distintos al del cierre del ciclo metabólico —
//      mezclarlos hacía parpadear el chart entre dos fuentes).
//
// Si estos tests fallan, alguien rompió la jerarquía de fuentes del
// Score del Día. El tile de Progreso y el detalle mostrarán datos
// calendáricos en vez de datos de ciclo metabólico.

import 'dart:async';

import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

MetricSeries _series(List<double> values) {
  final base = DateTime(2026, 6, 14);
  final points = List<TimeSeriesPoint>.generate(
    values.length,
    (i) => TimeSeriesPoint(
      weekStart: base.subtract(Duration(days: i * 7)),
      value: values[i],
      sampleCount: 1,
    ),
  );
  return MetricSeries(label: 'Score del día', unit: '', points: points);
}

/// Helper para tests donde el stream de ciclos cerrados EMITE un valor.
/// Usa `.future` para esperar la primera emisión real del StreamProvider
/// (un solo `await Future<void>.value()` no alcanza — Riverpod procesa
/// la emisión en un microtask posterior al de suscripción).
Future<ProviderContainer> _makeContainerWithEmission({
  required MetricSeries closed,
  required MetricSeries streak,
}) async {
  final container = ProviderContainer(overrides: [
    closedCycleScoreSeriesProvider.overrideWith(
      (ref) => Stream.value(closed),
    ),
    // ignore: deprecated_member_use
    dailyScoreSeriesProvider.overrideWith((ref) => streak),
  ]);
  addTearDown(container.dispose);
  // `.future` completa cuando el StreamProvider emite su primer valor.
  await container.read(closedCycleScoreSeriesProvider.future);
  return container;
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('resolvedDailyScoreSeriesProvider — jerarquía de fuentes (SPEC-219)', () {
    test(
      'usa ciclos cerrados cuando tienen puntos',
      () async {
        final closed = _series([85.0, 72.0, 91.0]);
        final streak = _series([50.0, 48.0]);
        final container = await _makeContainerWithEmission(
          closed: closed,
          streak: streak,
        );

        final result = container.read(resolvedDailyScoreSeriesProvider);

        expect(result.points.length, 3,
            reason: 'debe devolver los 3 puntos de ciclos cerrados');
        expect(result.points.map((p) => p.value).toList(),
            containsAllInOrder([85.0, 72.0, 91.0]));
      },
    );

    test(
      'retorna serie vacía cuando ciclos cerrados no tienen puntos (rev2, sin fallback)',
      () async {
        final closed = MetricSeries.empty(label: 'Score del día', unit: '');
        final streak = _series([55.0, 60.0]);
        final container = await _makeContainerWithEmission(
          closed: closed,
          streak: streak,
        );

        final result = container.read(resolvedDailyScoreSeriesProvider);

        expect(result.points, isEmpty,
            reason: 'ciclos vacíos → serie vacía, SPEC-219 rev2 eliminó el '
                'fallback a streak');
      },
    );

    test(
      'retorna serie vacía mientras ciclos cerrados aún están cargando (rev2, sin fallback)',
      () async {
        // StreamController que nunca emite → el StreamProvider queda en
        // AsyncLoading permanente. No podemos usar `.future` aquí porque
        // nunca completaría. Usamos Future.delayed(Duration.zero) para
        // dejar que Riverpod suscriba al stream sin recibir datos.
        final neverController = StreamController<MetricSeries>();
        addTearDown(neverController.close);

        final streak = _series([42.0]);
        final container = ProviderContainer(overrides: [
          closedCycleScoreSeriesProvider.overrideWith(
            (ref) => neverController.stream,
          ),
          // ignore: deprecated_member_use
          dailyScoreSeriesProvider.overrideWith((ref) => streak),
        ]);
        addTearDown(container.dispose);
        await Future.delayed(Duration.zero); // Pump para subscribirse sin emitir.

        // Verificar que efectivamente está en AsyncLoading.
        final closedState = container.read(closedCycleScoreSeriesProvider);
        expect(closedState, isA<AsyncLoading<MetricSeries>>());

        final result = container.read(resolvedDailyScoreSeriesProvider);

        // isLoading → .valueOrNull == null → serie vacía (rev2 eliminó
        // el fallback a streak: mezclar snapshot en vivo con cierre de
        // ciclo producía scores inconsistentes en el chart).
        expect(result.points, isEmpty,
            reason: 'isLoading en ciclos → serie vacía, sin fallback a streak');
      },
    );

    test(
      'ciclos cerrados tienen prioridad aunque streak tenga más puntos',
      () async {
        final closed = _series([88.0]); // 1 punto de ciclo
        final streak = _series(List.generate(10, (_) => 50.0)); // 10 de streak
        final container = await _makeContainerWithEmission(
          closed: closed,
          streak: streak,
        );

        final result = container.read(resolvedDailyScoreSeriesProvider);

        expect(result.points.length, 1,
            reason: 'debe elegir ciclos (1 punto) no streak (10 puntos)');
        expect(result.points.first.value, 88.0);
      },
    );

    test(
      'retorna serie con label correcto independiente de la fuente',
      () async {
        final closed = _series([75.0]);
        final container = await _makeContainerWithEmission(
          closed: closed,
          streak: MetricSeries.empty(label: 'Score del día', unit: ''),
        );

        final result = container.read(resolvedDailyScoreSeriesProvider);
        expect(result.label, 'Score del día');
        expect(result.unit, '');
      },
    );
  });
}
