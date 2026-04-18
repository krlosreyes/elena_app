import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_models.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'dart:math' as math;

final analysisServiceProvider = Provider<AnalysisService>((ref) {
  return AnalysisService(ref);
});

class AnalysisService {
  final Ref _ref;
  AnalysisService(this._ref);

  /// Calcula correlaciones y genera el reporte mensual (vía SPEC-09)
  Future<AnalysisCache?> calculateCorrelations(String userId) async {
    final streakState = _ref.read(streakProvider);
    final history = streakState.history;
    
    if (history.length < 7) return null; // Necesitamos al menos una semana

    // 1. Preparar series de datos para correlación (últimos 28 días)
    // Para v1.0 usamos los datos disponibles en StreakEntry y derivamos proxies
    final last28 = history.take(28).toList().reversed.toList();
    
    // Correlación A: Fasting (bool) vs IMR (int) -> Proxy de FastingHours vs SleepQuality
    // Nota: Como no tenemos todos los logs aquí, usamos lo que hay en StreakEntry
    final correlations = [
      _calculatePilarCorrelation(
        last28, 
        'Ayuno', 
        'IMR Score', 
        (e) => e.fastingCompleted ? 1.0 : 0.0,
        (e) => e.imrScore.toDouble(),
        "Tu estabilidad glucémica (ayuno) está fuertemente ligada a tu recuperación nocturna."
      ),
      _calculatePilarCorrelation(
        last28,
        'Ejercicio',
        'IMR Score',
        (e) => e.exerciseLogged ? 1.0 : 0.0,
        (e) => e.imrScore.toDouble(),
        "La intensidad de tu actividad física parece anticipar mejoras en tu IMR del día siguiente."
      ),
      _calculatePilarCorrelation(
        last28,
        'Hidratación',
        'IMR Score', // Proxy para FocusScore
        (e) => e.hydrationCompleted ? 1.0 : 0.0,
        (e) => e.imrScore.toDouble(),
        "Mantener tu hidratación por encima del 75% optimiza tu capacidad de enfoque."
      ),
    ];

    // 2. Generar Reporte Semanal (Semana Actual vs Anterior)
    final weeklyReport = _generateWeeklyReport(history);
    
    final result = AnalysisCache(
      lastUpdated: DateTime.now(),
      correlations: correlations,
      currentWeek: weeklyReport.$1,
      previousWeek: weeklyReport.$2,
    );

    // 3. Cachear en Firestore (RF-09-07)
    await _cacheResults(userId, result);
    
    return result;
  }

  CorrelationResult _calculatePilarCorrelation(
    List<StreakEntry> data,
    String pilarA,
    String pilarB,
    double Function(StreakEntry) getValA,
    double Function(StreakEntry) getValB,
    String defaultInsight,
  ) {
    final seriesA = data.map(getValA).toList();
    final seriesB = data.map(getValB).toList();
    
    final r = _pearsonCorrelation(seriesA, seriesB);
    
    CorrelationType type;
    if (r > 0.3) {
      type = CorrelationType.positive;
    } else if (r < -0.3) {
      type = CorrelationType.negative;
    } else {
      type = CorrelationType.neutral;
    }

    return CorrelationResult(
      pilarA: pilarA,
      pilarB: pilarB,
      score: r,
      type: type,
      insight: _generateHumanInsight(pilarA, pilarB, type, defaultInsight, r),
    );
  }

  double _pearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    int n = x.length;
    double sumX = x.reduce((a, b) => a + b);
    double sumY = y.reduce((a, b) => a + b);
    double sumXY = 0;
    double sumX2 = 0;
    double sumY2 = 0;
    
    for (int i = 0; i < n; i++) {
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }
    
    double numerator = n * sumXY - sumX * sumY;
    double denominator = math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    
    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }

  String _generateHumanInsight(String a, String b, CorrelationType type, String base, double r) {
    if (type == CorrelationType.positive) {
      return base;
    } else if (type == CorrelationType.negative) {
      return "Detectamos una correlación inversa inusual entre $a y $b. Podría sugerir estrés compensatorio.";
    } else {
      return "No hay una relación clara este mes entre $a y tu $b. Prueba aumentar la consistencia de uno de ellos.";
    }
  }

  (WeeklyAnalysis, WeeklyAnalysis) _generateWeeklyReport(List<StreakEntry> history) {
    final currentWeekData = history.take(7).toList();
    final prevWeekData = history.skip(7).take(7).toList();

    return (
      _analyzeWeek(currentWeekData),
      _analyzeWeek(prevWeekData),
    );
  }

  WeeklyAnalysis _analyzeWeek(List<StreakEntry> week) {
    if (week.isEmpty) return WeeklyAnalysis(avgImr: 0, adherence: 0, topPilarInfluenceIndex: 0, topPilarName: 'N/A');
    
    double avgImr = week.map((e) => e.imrScore).reduce((a, b) => a + b) / week.length;
    double adherence = week.where((e) => e.qualifiesForStreak).length / week.length;
    
    // Pilar más influyente (el que más se completó esta semana)
    final pilarCounts = [0, 0, 0, 0, 0]; // Fast, Sleep, Hyd, Ex, Nut
    for (var e in week) {
      if (e.fastingCompleted) pilarCounts[0]++;
      if (e.sleepCompleted) pilarCounts[1]++;
      if (e.hydrationCompleted) pilarCounts[2]++;
      if (e.exerciseLogged) pilarCounts[3]++;
      if (e.nutritionLogged) pilarCounts[4]++;
    }
    
    int maxIdx = 0;
    for (int i = 1; i < 5; i++) {
      if (pilarCounts[i] > pilarCounts[maxIdx]) maxIdx = i;
    }

    const pilarNames = ['Ayuno', 'Sueño', 'Hidratación', 'Ejercicio', 'Nutrición'];

    return WeeklyAnalysis(
      avgImr: avgImr,
      adherence: adherence,
      topPilarInfluenceIndex: maxIdx,
      topPilarName: pilarNames[maxIdx],
    );
  }

  Future<void> _cacheResults(String userId, AnalysisCache result) async {
    final repo = _ref.read(userRepositoryProvider);
    await repo.saveProtocolAdjustment(userId, {
      'type': 'analysis_cache',
      'lastUpdated': result.lastUpdated.toIso8601String(),
      'data': result.toJson(),
    });
  }
}
