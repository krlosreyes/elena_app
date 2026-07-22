// SPEC-162 + SPEC-164: providers que construyen las 7 series.
//
//   Resultados:
//     - IMR (avg de daily_summary.imrScore)
//     - Peso (last de biometric_history.weight)
//
//   Hábitos (5 pilares oficiales):
//     - Ayuno: días cumplidos por bucket (fastingProgress >= 0.95)
//     - Nutrición: % A-dominante
//     - Hidratación: % vs target diario
//     - Ejercicio: minutos/día promedio
//     - Sueño: horas/noche promedio
//
// SPEC-164: el modo de agregación se decide en runtime según el rango
// seleccionado por el usuario (daily/weekly/monthly).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/temporal_aggregator.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_repository_impl.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/fasting/data/fasting_interval_repository_impl.dart';
import 'package:elena_app/src/features/hydration/data/hydration_repository_impl.dart';
import 'package:elena_app/src/features/sleep/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_quality_classifier.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

import '../../../core/services/app_logger.dart';
import '../../metabolic_cycle/application/metabolic_cycle_providers.dart';
import '../domain/metric_series.dart';
import 'analysis_range_provider.dart';
import 'temporal_aggregator.dart';

/// SPEC-177 (2026-06-04): bump que cambia cada vez que se cierra un
/// nuevo ciclo metabólico. Las series del Análisis lo watch como
/// dependencia → cuando cambia, los providers se re-evalúan, se
/// re-suscriben a sus streams Firestore y emiten el día recién cerrado
/// (que entró a `daily_summary/{YYYYMMDD}` vía SPEC-111 persistence).
///
/// Sin esto, las gráficas Apple-Fitness style del Análisis se quedaban
/// con los datos cacheados — el usuario cerraba el ciclo, veía la
/// CycleClosureCard, pero los charts no reflejaban el cierre hasta el
/// próximo cold start o nuevo log.
final cycleClosureBumpProvider = Provider<String?>((ref) {
  final lastClosed = ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;
  return lastClosed?.cycleId;
});

String _dateIso(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

DateTime _todayLocal() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Helper que devuelve el `AggregationMode` actual a partir del
/// rango seleccionado. Los providers lo usan para adaptar la
/// granularidad de los buckets.
AggregationMode _currentMode(Ref ref) {
  final range = ref.watch(analysisRangeProvider);
  return AggregationMode.forRange(range);
}

/// SPEC-200.1 rev2 (2026-06-13): serie del Score del Día usando el score
/// registrado al CIERRE del ciclo metabólico (`MetabolicCycle.dailyScore`).
/// Fuente: `metabolicCyclesHistoryProvider` (90 últimos ciclos cerrados).
/// Se abandona `StreakEntry.dailyQualityScore` (score en vivo del día) porque
/// el valor definitivo es el que queda grabado cuando el usuario cierra su
/// ciclo conscientemente — no el snapshot en tiempo real de mitad del día.
// BUGFIX (2026-06-17): NO autoDispose. Con autoDispose, cada vez que el
// usuario navega fuera del Análisis o cambia el rango, el provider se
// destruye y recrea → pasa por AsyncLoading SIN valor previo →
// resolvedDailyScoreSeriesProvider cae al fallback de streak (scores
// distintos) → el chart parpadea entre dos fuentes de datos.
// Sin autoDispose, Riverpod mantiene el último AsyncData como
// previousValue durante re-evaluación, y .valueOrNull nunca es null
// después de la primera emisión.
final closedCycleScoreSeriesProvider =
    StreamProvider<MetricSeries>((ref) async* {
  // Bump: refresca cuando se cierra un ciclo.
  ref.watch(cycleClosureBumpProvider);
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);

  await for (final cycles
      in ref.watch(metabolicCyclesHistoryProvider.stream)) {
    // ── DIAGNÓSTICO (2026-06-17) ──────────────────────────────────────
    // Log cada emisión del stream para rastrear exactamente qué data llega.
    final withScore = cycles.where((c) => c.dailyScore != null).length;
    final withoutScore = cycles.where((c) => c.dailyScore == null).length;
    AppLogger.debug(
      '[closedCycleScoreSeries] stream emitió ${cycles.length} ciclos: '
      '$withScore con dailyScore, $withoutScore sin dailyScore, '
      'rangeStart=$rangeStart',
    );

    // Filtra por rango y descarta ciclos sin closedAt o sin dailyScore.
    final inRange = cycles.where((c) {
      final dt = c.closedAt;
      final score = c.dailyScore;
      return dt != null && score != null && !dt.isBefore(rangeStart);
    }).toList();

    // Log cada ciclo en rango con su score para validar visualmente.
    for (final c in inRange) {
      AppLogger.debug(
        '[closedCycleScoreSeries]   → ${c.closedAt} score=${c.dailyScore} '
        'reason=${c.closureReason}',
      );
    }

    final closedPoints = TemporalAggregator.aggregate(
      items: inRange,
      timestampOf: (c) => c.closedAt!,
      valueOf: (c) => c.dailyScore!.toDouble(),
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    AppLogger.debug(
      '[closedCycleScoreSeries] → ${closedPoints.length} puntos agregados '
      '(mode=$mode)',
    );

    // SPEC-245 (2026-07-07): punto "en vivo" del ciclo abierto.
    //
    // Un ayuno extendido (p.ej. 33h) permanece abierto mientras el usuario
    // sigue en ayuno — la gráfica mostraba un gap entre el último ciclo
    // cerrado y hoy. Ahora el liveScore del ciclo abierto se agrega como
    // punto de hoy para que el usuario vea su progreso en tiempo real.
    //
    // Solo se agrega si:
    //   1. Hay ciclo abierto con liveScore stampado (evaluador lo actualiza
    //      cada ~10s vía SPEC-227).
    //   2. El timestamp de hoy está dentro del rango seleccionado.
    //   3. No hay ya un punto de ciclo cerrado para hoy (evita duplicado
    //      si el ciclo acaba de cerrar y Firestore no se actualizó todavía).
    var allPoints = closedPoints;
    final openCycle = ref.read(currentMetabolicCycleProvider).valueOrNull;
    if (openCycle != null &&
        openCycle.isOpen &&
        openCycle.liveScore != null) {
      final now = DateTime.now();
      if (!now.isBefore(rangeStart)) {
        final todayKey = _dateIso(now);
        final alreadyHasToday =
            closedPoints.any((p) => _dateIso(p.weekStart) == todayKey);
        if (!alreadyHasToday) {
          final livePoint = TimeSeriesPoint(
            weekStart: now,
            value: openCycle.liveScore!.toDouble(),
            sampleCount: 1,
          );
          allPoints = [...closedPoints, livePoint];
          AppLogger.debug(
            '[closedCycleScoreSeries] + punto en vivo: '
            'score=${openCycle.liveScore} cycleId=${openCycle.cycleId}',
          );
        }
      }
    }

    yield MetricSeries(label: 'Score del día', unit: '', points: allPoints);
  }
});

// ────────────────────────────────────────────────────────────────────────
// SPEC-219 rev2 (2026-06-17): fuente canónica ÚNICA para Score del Día.
//
// REGLA: cualquier widget que muestre el Score del Día DEBE usar
// `resolvedDailyScoreSeriesProvider`. NUNCA usar `dailyScoreSeriesProvider`
// ni `closedCycleScoreSeriesProvider` directamente como fuente primaria.
//
// CAMBIO CRÍTICO (2026-06-17): se ELIMINA el fallback a streak
// calendárico (dailyScoreSeriesProvider). Motivo: el streak produce
// scores DISTINTOS a los del cierre del ciclo metabólico porque es un
// snapshot en vivo del día calendario, no el score al cierre. Mezclar
// las dos fuentes causa que la gráfica oscile entre dos conjuntos de
// valores, confundiendo al usuario.
//
// Si no hay ciclos cerrados con dailyScore en el rango, la gráfica
// muestra vacío. Es preferible un chart vacío a uno con datos erróneos.
// ────────────────────────────────────────────────────────────────────────

/// SPEC-219 rev2: fuente canónica del Score del Día para toda la UI.
/// Fuente ÚNICA: ciclos metabólicos cerrados (MetabolicCycle.dailyScore).
/// Sin fallback a streak — si no hay datos, retorna serie vacía.
final resolvedDailyScoreSeriesProvider =
    Provider.autoDispose<MetricSeries>((ref) {
  final closedAsync = ref.watch(closedCycleScoreSeriesProvider);

  // 1. Stream tiene datos (o está refrescando con valor previo) → usar.
  final closed = closedAsync.valueOrNull;
  if (closed != null && closed.points.isNotEmpty) {
    AppLogger.debug(
      '[resolvedDailyScore] usando ciclos cerrados: '
      '${closed.points.length} puntos',
    );
    return closed;
  }

  // 2. Sin datos (loading o vacío) → serie vacía. La UI muestra spinner
  //    o estado vacío. NUNCA caer al streak.
  AppLogger.debug(
    '[resolvedDailyScore] sin datos de ciclos cerrados '
    '(isLoading=${closedAsync.isLoading}, '
    'valueOrNull=${closed == null ? "null" : "${closed.points.length}pts"})',
  );
  return MetricSeries(label: 'Score del día', unit: '', points: const []);
});

/// Fallback calendárico para Score del Día. Fuente: StreakEntry.dailyQualityScore
/// (snapshot en vivo del día calendario, persistido cada 30s por
/// DailySummaryPersistenceService). NO usar como fuente primaria en la UI.
///
/// Usar `resolvedDailyScoreSeriesProvider` en su lugar.
// ignore: deprecated_member_use_from_same_package
@Deprecated(
  'No usar directamente en la UI. '
  'Usar resolvedDailyScoreSeriesProvider que aplica la jerarquía correcta '
  '(ciclos cerrados primero, streak como fallback). SPEC-219 (2026-06-14).',
)
final dailyScoreSeriesProvider = Provider.autoDispose<MetricSeries>((ref) {
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  final history = ref.watch(streakProvider).history;
  final inRange = history.where((StreakEntry e) {
    final d = DateTime.tryParse(e.date);
    return d != null && !d.isBefore(rangeStart);
  }).toList();
  final points = TemporalAggregator.aggregate<StreakEntry>(
    items: inRange,
    timestampOf: (e) => DateTime.parse(e.date),
    valueOf: (e) => (e.dailyQualityScore * 100).clamp(0.0, 100.0),
    aggregation: TemporalAggregation.avg,
    mode: mode,
  );
  return MetricSeries(label: 'Score del día', unit: '', points: points);
});

// ─── Resultados ────────────────────────────────────────────────────────

final imrSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'IMR', unit: '');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  final repo = ref.watch(dailySummaryRepositoryProvider);
  await for (final docs in repo.watchRange(
    userId: account.uid,
    fromIncl: _dateIso(rangeStart),
    toIncl: _dateIso(_todayLocal()),
  )) {
    final points = TemporalAggregator.aggregate(
      items: docs,
      timestampOf: (d) => DateTime.parse(d.date),
      valueOf: (d) => d.imrScore.toDouble(),
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'IMR', unit: '', points: points);
  }
});

// SPEC-168.4.2 (2026-06-03): serie temporal del % de grasa corporal.
// Reusa `biometricRepository.watchHistory()` (mismo stream que peso)
// y filtra los check-ins que NO tienen bodyFatPercentage.
final bodyFatSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Grasa corporal', unit: '%');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  final repo = ref.watch(biometricRepositoryProvider);
  await for (final history in repo.watchHistory(account.uid)) {
    final filtered = history.where((c) {
      if (c.bodyFatPercentage == null) return false;
      final ts = DateTime.parse(c.date);
      return ts.isAfter(rangeStart) || ts == rangeStart;
    }).toList();
    final points = TemporalAggregator.aggregate(
      items: filtered,
      timestampOf: (c) => DateTime.parse(c.date),
      valueOf: (c) => c.bodyFatPercentage!,
      aggregation: TemporalAggregation.last,
      mode: mode,
    );
    yield MetricSeries(label: 'Grasa corporal', unit: '%', points: points);
  }
});

final weightSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Peso', unit: 'kg');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  final repo = ref.watch(biometricRepositoryProvider);
  await for (final history in repo.watchHistory(account.uid)) {
    final filtered = history.where((c) {
      final ts = DateTime.parse(c.date);
      return ts.isAfter(rangeStart) || ts == rangeStart;
    }).toList();
    final points = TemporalAggregator.aggregate(
      items: filtered,
      timestampOf: (c) => DateTime.parse(c.date),
      valueOf: (c) => c.weight,
      aggregation: TemporalAggregation.last,
      mode: mode,
    );
    yield MetricSeries(label: 'Peso', unit: 'kg', points: points);
  }
});

// ─── Hábitos ───────────────────────────────────────────────────────────

final fastingHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Ayuno', unit: 'h');
    return;
  }
  // SPEC-162.bugfix (2026-06-02): antes leíamos daily_summary, que
  // tiene debounce de 30s y flush a medianoche → los ayunos cerrados
  // de HOY no aparecían en el gráfico hasta el día siguiente. Ahora
  // leemos directamente de fasting_history (los FastingInterval
  // cerrados aparecen en Firestore al instante).
  //
  // SPEC-168.5.2 (2026-06-03): el eje Y representa HORAS DE AYUNO
  // (no días cumplidos 0/1). Carlos: el usuario ya tiene el target
  // visible (línea de objetivo) y la lectura de "16h promedio esta
  // semana" comunica mucho más que "5 días cumplidos". El cómputo
  // de achievement (SPEC-168.3) se preserva: comparar value (horas
  // reales) vs target (horas del protocolo activo).
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  await for (final intervals in ref
      .watch(fastingIntervalRepositoryProvider)
      // SPEC-168.4.7: 2000 cubre ~5 años de uso diario sin egress
      // problemático y elimina el corte silencioso para rango "Todo".
      .watchRecentCompleted(account.uid, limit: 2000)) {
    final inRange = intervals
        .where((i) => !i.startTime.isBefore(rangeStart))
        .toList();
    final points = TemporalAggregator.aggregate(
      items: inRange,
      timestampOf: (i) => i.startTime,
      valueOf: (i) {
        final endTime = i.endTime;
        if (endTime == null) return 0.0;
        return endTime.difference(i.startTime).inMinutes / 60.0;
      },
      // Promedio en todos los modos: en daily da las horas del ayuno
      // de ese día; en weekly/monthly da el promedio de horas por
      // bucket. Lectura directa del esfuerzo metabólico real.
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Ayuno', unit: 'h', points: points);
  }
});

final nutritionHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Nutrición A', unit: '%');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  await for (final logs in ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(
    account.uid,
    rangeStart,
    until: _todayLocal().add(const Duration(days: 1)),
  )) {
    final fractionPoints = TemporalAggregator.aggregate(
      items: logs,
      timestampOf: (l) => l.timestamp,
      valueOf: (l) => l.ratio.isADominant ? 1.0 : 0.0,
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    final pctPoints = fractionPoints
        .map((p) => TimeSeriesPoint(
              weekStart: p.weekStart,
              value: p.value * 100,
              sampleCount: p.sampleCount,
            ))
        .toList();
    yield MetricSeries(label: 'Nutrición A', unit: '%', points: pctPoints);
  }
});

final hydrationHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Hidratación', unit: 'L');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  await for (final logs in ref.watch(hydrationRepositoryProvider).watchSince(
        account.uid,
        rangeStart,
        until: _todayLocal().add(const Duration(days: 1)),
      )) {
    // SPEC-168.5.3 (2026-06-03): el eje Y muestra LITROS por día (no %
    // vs un target hard-coded). Lectura directa del consumo real; el
    // target line es el goal del usuario en hydrationLitersPerDay.
    final byDay = <String, double>{};
    for (final log in logs) {
      // SPEC-230 BUG-A: log.timestamp es UTC (Firestore Timestamp.toDate()).
      // Sin toLocal(), un log a las 11pm local cae en el día UTC siguiente.
      final key = _dateIso(log.timestamp.toLocal());
      byDay[key] = (byDay[key] ?? 0) + log.amountInLiters;
    }
    final dayEntries = byDay.entries
        .map((e) => _DayLiters(_parseDateIso(e.key), e.value))
        .toList();
    final points = TemporalAggregator.aggregate(
      items: dayEntries,
      timestampOf: (d) => d.date,
      valueOf: (d) => d.liters,
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Hidratación', unit: 'L', points: points);
  }
});

final exerciseHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Ejercicio', unit: 'min');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  await for (final logs in ref.watch(exerciseRepositoryProvider).watchSince(
        account.uid,
        rangeStart,
        until: _todayLocal().add(const Duration(days: 1)),
      )) {
    final byDay = <String, int>{};
    for (final log in logs) {
      // SPEC-230 BUG-A: mismo fix timezone que hydration (ver arriba).
      final key = _dateIso(log.timestamp.toLocal());
      byDay[key] = (byDay[key] ?? 0) + log.durationMinutes;
    }
    final dayEntries = byDay.entries
        .map((e) => _DayMinutes(_parseDateIso(e.key), e.value))
        .toList();
    // En modo daily mostramos el valor directo del día.
    // En weekly/monthly promediamos los minutos por día.
    final points = TemporalAggregator.aggregate(
      items: dayEntries,
      timestampOf: (d) => d.date,
      valueOf: (d) => d.minutes.toDouble(),
      aggregation: mode == AggregationMode.daily
          ? TemporalAggregation.sum
          : TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Ejercicio', unit: 'min', points: points);
  }
});

final sleepHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  // SPEC-177 (2026-06-04): watch del bump para refrescar al cierre del ciclo.
  ref.watch(cycleClosureBumpProvider);
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Sueño', unit: 'h');
    return;
  }
  // SPEC-230 BUG-B: ref.watch FUERA del await-for para que el provider
  // se re-evalúe cuando el usuario cambia el rango de análisis (antes era
  // ref.read DENTRO del loop → el sleep chart se quedaba congelado).
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  await for (final logs in ref
      .watch(sleepRepositoryProvider)
      // SPEC-168.4.7: 2000 cubre ~5 años de uso diario sin egress
      // problemático y elimina el corte silencioso para rango "Todo".
      .watchRecent(account.uid, limit: 2000)) {
    // 17-jul (Carlos: "solo tenemos en cuenta el sueño nocturno y de
    // calidad"): sin este filtro, una siesta y el sueño real de la
    // misma noche caen en el mismo bucket diario y `avg` los diluye
    // (7h reales + 0.5h de siesta = 3.75h reportadas). Ver
    // SleepQualityClassifier.
    final filtered = logs
        .where((l) => !l.wokeUp.isBefore(rangeStart))
        .where(SleepQualityClassifier.isNocturnalQualitySleep)
        .toList();
    final points = TemporalAggregator.aggregate(
      items: filtered,
      timestampOf: (l) => l.wokeUp,
      valueOf: (l) => l.wokeUp.difference(l.fellAsleep).inMinutes / 60.0,
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Sueño', unit: 'h', points: points);
  }
});

// ─── Helpers internos ──────────────────────────────────────────────────

class _DayLiters {
  final DateTime date;
  final double liters;
  const _DayLiters(this.date, this.liters);
}

class _DayMinutes {
  final DateTime date;
  final int minutes;
  const _DayMinutes(this.date, this.minutes);
}

DateTime _parseDateIso(String s) {
  final parts = s.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
