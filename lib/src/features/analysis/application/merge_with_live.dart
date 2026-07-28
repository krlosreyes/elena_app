// SPEC-160: extracción del helper `mergeWithLive` para que los tabs
// Resumen y Tendencia lo compartan sin duplicar lógica.
//
// Razón original (SPEC-113.bugfix): el doc persistido de HOY tiene un
// debounce de 30s. Watcheamos el state LIVE de `dailySummaryProvider`
// y lo mezclamos con los docs del período para que la card/snapshot
// del día actual refleje cambios inmediatos (registrar una comida,
// cerrar el ayuno, etc).
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';

/// Reemplaza el doc persistido de HOY por uno construido desde el
/// state LIVE. Si no existía doc para hoy, lo agrega. Mantiene los
/// docs anteriores intactos.
///
/// El consumidor espera lista ordenada por fecha ascendente.
List<DailySummaryDoc> mergeWithLive({
  required List<DailySummaryDoc> persisted,
  required DailySummary live,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final todayKey = _formatDateKey(n);
  final liveDoc = DailySummaryDoc(
    date: todayKey,
    imrScore: live.imrScore,
    fastingProgress: live.fastingProgress,
    sleepProgress: live.sleepProgress,
    hydrationProgress: live.hydrationProgress,
    exerciseProgress: live.exerciseProgress,
    mealsProgress: live.mealsProgress,
    updatedAt: n,
  );
  final result = <DailySummaryDoc>[];
  bool replaced = false;
  for (final d in persisted) {
    if (d.date == todayKey) {
      result.add(liveDoc);
      replaced = true;
    } else {
      result.add(d);
    }
  }
  if (!replaced) result.add(liveDoc);
  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

String _formatDateKey(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';
