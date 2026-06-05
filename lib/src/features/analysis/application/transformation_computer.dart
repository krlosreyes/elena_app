// SPEC-148 §RF-148-02 (2026-06-05): TransformationComputer.
//
// Pure Dart, sin Riverpod ni Flutter. Recibe los tres historiales
// (biometría, IMR semanal, streak) + `now` y produce el snapshot de
// la comparativa 30 días.
//
// Diseñado para ser testeable end-to-end sin Firestore — el caller
// provee las listas ya cargadas.

import 'package:elena_app/src/features/analysis/domain/transformation_snapshot.dart';
import 'package:elena_app/src/features/nutrition/application/upf_share_computer.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

/// SPEC-148 §RF-148-02: ventana flexible para el "past" — tolera que
/// el usuario no se mida exactamente cada 30 días.
const Duration kPastWindowStart = Duration(days: 35);
const Duration kPastWindowEnd = Duration(days: 25);

/// Ventana para el "current" — el último valor en este rango se toma
/// como medición actual. Si el usuario se midió hace 6 días, eso
/// cuenta como "hoy".
const Duration kCurrentWindowMax = Duration(days: 7);

class TransformationComputer {
  TransformationComputer._();

  /// Computa el snapshot de la transformación 30d.
  ///
  /// - `biometricHistory` debe venir ordenado por `recordedAt`
  ///   descendente (más reciente primero) — el shape canónico de
  ///   `BiometricRepository.watchHistory`.
  /// - `imrHistory` son los docs de `users/{uid}/imr_history/{weekISO}`
  ///   en el shape canónico de SPEC-141 (campos `imrScore`,
  ///   `computedAt`). Ordenado por `computedAt` descendente.
  /// - `streakHistory` orden indistinto (el computer ordena
  ///   internamente).
  static TransformationSnapshot compute({
    required List<BiometricCheckIn> biometricHistory,
    required List<Map<String, dynamic>> imrHistory,
    required List<StreakEntry> streakHistory,
    required DateTime now,
    // SPEC-138 (2026-06-05): logs nutricionales de los últimos ~35
    // días. Opcional para retrocompat: callers que no pasen logs
    // verán `upfSharePct` como `empty` (lo cual la card ignora).
    List<NutritionLog> nutritionHistory = const [],
  }) {
    return TransformationSnapshot(
      weightKg: _biometricDelta(
        biometricHistory,
        now,
        label: 'Peso',
        unit: 'kg',
        extract: (c) => c.weight,
      ),
      imr: _imrDelta(imrHistory, now),
      waistCm: _biometricDelta(
        biometricHistory,
        now,
        label: 'Cintura',
        unit: 'cm',
        extract: (c) => c.waistCircumference,
      ),
      bodyFatPct: _biometricDelta(
        biometricHistory,
        now,
        label: '% Grasa',
        unit: '%',
        extract: (c) => c.bodyFatPercentage,
      ),
      sleepHoursAvg: _sleepDelta(streakHistory, now),
      fastingDaysOf7: _fastingDelta(streakHistory, now),
      upfSharePct: _upfDelta(nutritionHistory, now),
    );
  }

  /// SPEC-138 §16.4: delta del % UPF semanal vs el período de hace 30d.
  ///
  /// - `current` = % UPF agregado de los últimos 7 días.
  /// - `past` = % UPF agregado en la ventana [now-35d, now-28d]
  ///   (la "semana antes del mes pasado").
  ///
  /// Si cualquiera de los dos lados no tiene suficientes logs con
  /// datos NOVA (umbral `UpfThresholds.weeklyMinLogsWithNova`), el
  /// lado queda en null — el delta no se muestra. Política conservadora:
  /// preferimos no opinar antes que con datos pobres.
  static TransformationDelta<int> _upfDelta(
    List<NutritionLog> nutritionHistory,
    DateTime now,
  ) {
    if (nutritionHistory.isEmpty) {
      return TransformationDelta.empty(
        label: 'Ultraprocesado',
        unit: '%',
      );
    }

    bool inWindow(NutritionLog log, Duration start, Duration end) {
      final from = now.subtract(start);
      final to = now.subtract(end);
      return !log.timestamp.isBefore(from) &&
          !log.timestamp.isAfter(to);
    }

    final currentLogs = nutritionHistory
        .where((l) => inWindow(l, const Duration(days: 7), Duration.zero))
        .toList();
    final pastLogs = nutritionHistory
        .where((l) => inWindow(l, kPastWindowStart, const Duration(days: 28)))
        .toList();

    final currentResult = UpfShareComputer.compute(currentLogs);
    final pastResult = UpfShareComputer.compute(pastLogs);

    // Política: solo poblamos un lado si tiene logsWithNova >= 3 en
    // su ventana (umbral más laxo que el semanal "accionable" porque
    // aquí solo necesitamos un punto de referencia para comparar).
    const minLogsForDelta = 3;
    final current = currentResult.logsWithNova >= minLogsForDelta
        ? currentResult.sharePercent
        : null;
    final past = pastResult.logsWithNova >= minLogsForDelta
        ? pastResult.sharePercent
        : null;

    return TransformationDelta<int>(
      past: past,
      current: current,
      label: 'Ultraprocesado',
      unit: '%',
    );
  }

  // ─── Helpers privados ────────────────────────────────────────────────

  /// Busca el último check-in cuyo `recordedAt` cae en la ventana
  /// `[now - end, now - start]` (más viejo a más reciente).
  static BiometricCheckIn? _latestInWindow(
    List<BiometricCheckIn> history,
    DateTime now, {
    required Duration start,
    required Duration end,
  }) {
    final from = now.subtract(start);
    final to = now.subtract(end);
    for (final c in history) {
      final at = c.recordedAt;
      if (at == null) continue;
      if (at.isBefore(from)) continue;
      if (at.isAfter(to)) continue;
      return c;
    }
    return null;
  }

  /// Construye un `TransformationDelta<double>` para un campo biométrico.
  static TransformationDelta<double> _biometricDelta(
    List<BiometricCheckIn> history,
    DateTime now, {
    required String label,
    required String unit,
    required double? Function(BiometricCheckIn) extract,
  }) {
    if (history.isEmpty) {
      return TransformationDelta.empty(label: label, unit: unit);
    }

    // "Current" — última medición dentro de los últimos 7 días con valor
    // no-null para el campo. Si no hay nada en 7 días, usar el último
    // disponible (modo permisivo).
    BiometricCheckIn? current;
    for (final c in history) {
      if (extract(c) == null) continue;
      current = c;
      break;
    }
    final currentValue = current == null ? null : extract(current);

    // "Past" — primera medición con valor dentro de [now-35d, now-25d].
    BiometricCheckIn? past;
    final from = now.subtract(kPastWindowStart);
    final to = now.subtract(kPastWindowEnd);
    for (final c in history) {
      final at = c.recordedAt;
      if (at == null) continue;
      if (at.isBefore(from) || at.isAfter(to)) continue;
      if (extract(c) == null) continue;
      past = c;
      break;
    }
    final pastValue = past == null ? null : extract(past);

    return TransformationDelta<double>(
      past: pastValue,
      current: currentValue,
      label: label,
      unit: unit,
      pastAgeDays: past?.recordedAt == null
          ? null
          : now.difference(past!.recordedAt!).inDays,
      currentAgeDays: current?.recordedAt == null
          ? null
          : now.difference(current!.recordedAt!).inDays,
    );
  }

  /// SPEC-141: lee el `imrScore` (longitudinal cuando schemaVersion=2,
  /// daily cuando v1) de la subcollection `imr_history`.
  static TransformationDelta<int> _imrDelta(
    List<Map<String, dynamic>> imrHistory,
    DateTime now,
  ) {
    if (imrHistory.isEmpty) {
      return TransformationDelta.empty(label: 'IMR', unit: '');
    }

    final from = now.subtract(kPastWindowStart);
    final to = now.subtract(kPastWindowEnd);
    int? past;
    int? current;
    int? pastAge;
    int? currentAge;

    // imr_history viene desc — primer doc = más reciente.
    for (final doc in imrHistory) {
      final score = _readImrScore(doc);
      final at = _readComputedAt(doc);
      if (score == null) continue;
      // Current: cualquier doc en los últimos 7 días (cadencia semanal
      // SPEC-141 garantiza que siempre habrá uno reciente si el feature
      // está activo o si el cache se persistió).
      if (current == null) {
        current = score;
        currentAge = at == null ? null : now.difference(at).inDays;
      }
      // Past: primer doc dentro de la ventana 25-35d.
      if (past == null && at != null && !at.isBefore(from) && !at.isAfter(to)) {
        past = score;
        pastAge = now.difference(at).inDays;
      }
      if (current != null && past != null) break;
    }

    return TransformationDelta<int>(
      past: past,
      current: current,
      label: 'IMR',
      unit: '',
      pastAgeDays: pastAge,
      currentAgeDays: currentAge,
    );
  }

  static int? _readImrScore(Map<String, dynamic> doc) {
    final raw = doc['imrScore'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  static DateTime? _readComputedAt(Map<String, dynamic> doc) {
    final raw = doc['computedAt'];
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  /// Promedio de horas de sueño en las últimas 30 entradas vs las 30
  /// anteriores. Proxy: `sleepQualityScore * 8` (SPEC-65 normaliza
  /// horas a 0-1; multiplicando por 8 retornamos horas).
  static TransformationDelta<double> _sleepDelta(
    List<StreakEntry> streakHistory,
    DateTime now,
  ) {
    if (streakHistory.isEmpty) {
      return TransformationDelta.empty(label: 'Sueño', unit: 'h prom');
    }
    final sorted = [...streakHistory]
      ..sort((a, b) => b.date.compareTo(a.date));

    double? avgInWindow(List<StreakEntry> window) {
      final values = window
          .where((e) => e.sleepQualityScore != null)
          .map((e) => e.sleepQualityScore!.clamp(0.0, 1.0) * 8.0)
          .toList();
      if (values.isEmpty) return null;
      final sum = values.fold<double>(0, (a, b) => a + b);
      return sum / values.length;
    }

    // Últimos 30 días (recientes).
    final currentWindow = sorted
        .where((e) {
          final d = DateTime.tryParse(e.date);
          return d != null && d.isAfter(now.subtract(const Duration(days: 30)));
        })
        .toList();
    final current = avgInWindow(currentWindow);

    // 30 días anteriores: [now-60d, now-30d].
    final pastWindow = sorted.where((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return false;
      return d.isAfter(now.subtract(const Duration(days: 60))) &&
          !d.isAfter(now.subtract(const Duration(days: 30)));
    }).toList();
    final past = avgInWindow(pastWindow);

    return TransformationDelta<double>(
      past: past,
      current: current,
      label: 'Sueño',
      unit: 'h prom',
    );
  }

  /// Días de ayuno cumplido (`fastingMagnitude ≥ 0.80`) en los últimos
  /// 7 días vs los 7 días equivalentes hace 30d ([now-37d, now-30d]).
  static TransformationDelta<int> _fastingDelta(
    List<StreakEntry> streakHistory,
    DateTime now,
  ) {
    if (streakHistory.isEmpty) {
      return TransformationDelta.empty(label: 'Ayuno', unit: 'd/7');
    }
    int countInWindow(DateTime from, DateTime to) {
      var count = 0;
      for (final e in streakHistory) {
        final d = DateTime.tryParse(e.date);
        if (d == null) continue;
        if (d.isBefore(from) || d.isAfter(to)) continue;
        if ((e.fastingMagnitude ?? 0.0) >= 0.80) count++;
      }
      return count;
    }

    final currentFrom = now.subtract(const Duration(days: 7));
    final pastFrom = now.subtract(const Duration(days: 37));
    final pastTo = now.subtract(const Duration(days: 30));

    final currentCount = countInWindow(currentFrom, now);
    final pastCount = countInWindow(pastFrom, pastTo);

    // Si NINGUNA de las ventanas tiene un solo entry con magnitud
    // poblada → ambos null (caso usuario completamente nuevo).
    final hasAnyPast = streakHistory.any((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return false;
      return !d.isBefore(pastFrom) &&
          !d.isAfter(pastTo) &&
          e.fastingMagnitude != null;
    });
    final hasAnyCurrent = streakHistory.any((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return false;
      return !d.isBefore(currentFrom) &&
          !d.isAfter(now) &&
          e.fastingMagnitude != null;
    });

    return TransformationDelta<int>(
      past: hasAnyPast ? pastCount : null,
      current: hasAnyCurrent ? currentCount : null,
      label: 'Ayuno',
      unit: 'd/7',
    );
  }
}
