import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StreakEngine — Motor de cómputo puro (sin estado, sin side-effects)
// ─────────────────────────────────────────────────────────────────────────────

/// Computa métricas de racha a partir del historial de [StreakEntry].
///
/// Todas las funciones son estáticas y puras: misma entrada → misma salida.
/// Esto facilita testing unitario sin mocks ni providers.
class StreakEngine {
  StreakEngine._();

  // ─────────────────────────────────────────────────────────────────────────
  // Evaluación de cumplimiento diario por pilar
  // ─────────────────────────────────────────────────────────────────────────

  /// Evalúa si el ayuno del día cumple el umbral.
  ///
  /// - Protocolo activo: ≥80% de las horas objetivo.
  /// - Sin protocolo ('Ninguno'): ≥10h (ayuno nocturno natural suficiente).
  static bool evaluateFasting({
    required double fastingHours,
    required String fastingProtocol,
  }) {
    if (fastingProtocol == 'Ninguno') {
      return fastingHours >= 10.0;
    }
    final parts = fastingProtocol.split(':');
    final targetHours = double.tryParse(parts.first) ?? 16.0;
    return fastingHours >= targetHours * 0.8;
  }

  /// Evalúa si el sueño cumple el mínimo restaurador (6.5h = umbral AASM).
  static bool evaluateSleep({required double sleepHours}) =>
      sleepHours >= 6.5;

  /// Evalúa si la hidratación alcanzó el 75% de la meta.
  static bool evaluateHydration({required double progressPercentage}) =>
      progressPercentage >= 0.75;

  /// Evalúa si se registró ejercicio suficiente (≥20 min = dosis mínima ACSM).
  static bool evaluateExercise({required int exerciseMinutes}) =>
      exerciseMinutes >= 20;

  /// Evalúa si se registró al menos 1 comida en el día.
  static bool evaluateNutrition({required int mealsLogged}) =>
      mealsLogged >= 1;

  // ─────────────────────────────────────────────────────────────────────────
  // Métricas de racha desde historial
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcula la racha actual: días consecutivos hacia atrás desde hoy/ayer
  /// en que [StreakEntry.qualifiesForStreak] es true.
  ///
  /// La racha no se rompe si "hoy" aún no califica — se cuenta desde ayer.
  /// Se rompe cuando hay un día no calificado o una brecha en el calendario.
  static int computeCurrentStreak(List<StreakEntry> history) {
    if (history.isEmpty) return 0;

    final sorted = _sortedDescending(history);
    final today = _todayKey();
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    // Punto de partida: si hoy califica, empezar desde hoy; si no, desde ayer.
    int start = 0;
    if (sorted.isNotEmpty && sorted.first.date == today && !sorted.first.qualifiesForStreak) {
      start = 1; // Saltar el día de hoy incompleto
    }

    int streak = 0;
    String? expectedDate;

    for (int i = start; i < sorted.length; i++) {
      final entry = sorted[i];

      if (!entry.qualifiesForStreak) break;

      if (expectedDate == null) {
        // Primer día válido — debe ser hoy o ayer para que la racha sea activa
        if (entry.date != today && entry.date != yesterday && i == start) break;
        expectedDate = entry.date;
        streak++;
      } else {
        final expected = DateTime.parse(expectedDate).subtract(const Duration(days: 1));
        if (entry.date == _dateKey(expected)) {
          streak++;
          expectedDate = entry.date;
        } else {
          break; // Brecha en el calendario
        }
      }
    }

    return streak;
  }

  /// Calcula la racha más larga de toda la historia.
  static int computeLongestStreak(List<StreakEntry> history) {
    if (history.isEmpty) return 0;

    final sorted = _sortedAscending(history);
    int longest = 0;
    int current = 0;
    String? prevDate;

    for (final entry in sorted) {
      if (!entry.qualifiesForStreak) {
        current = 0;
        prevDate = null;
        continue;
      }

      if (prevDate == null) {
        current = 1;
      } else {
        final prev = DateTime.parse(prevDate);
        final curr = DateTime.parse(entry.date);
        final diff = curr.difference(prev).inDays;
        current = (diff == 1) ? current + 1 : 1;
      }

      prevDate = entry.date;
      if (current > longest) longest = current;
    }

    return longest;
  }

  /// Adherencia semanal: proporción de los últimos 7 días que calificaron (SPEC-07).
  /// Retorna 0.0-1.0. Usado como [weeklyAdherence] en el ScoreEngine.
  /// Un día califica si tiene IMR >= 60 y al menos 3 pilares activos.
  static double computeWeeklyAdherence(List<StreakEntry> history) {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    
    // Ventana de los últimos 7 días terminando hoy
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6)); // 1 día (hoy) + 6 anteriores = 7
    
    final lastWeek = history.where((e) {
      final eDate = DateTime.tryParse(e.date);
      return eDate != null && !eDate.isBefore(cutoff);
    });

    if (lastWeek.isEmpty) return 0.0;

    final qualified = lastWeek.where((e) => e.isEngaged).length;
    return (qualified / 7.0).clamp(0.0, 1.0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers privados
  // ─────────────────────────────────────────────────────────────────────────

  static List<StreakEntry> _sortedDescending(List<StreakEntry> history) =>
      [...history]..sort((a, b) => b.date.compareTo(a.date));

  static List<StreakEntry> _sortedAscending(List<StreakEntry> history) =>
      [...history]..sort((a, b) => a.date.compareTo(b.date));

  static String _todayKey() => _dateKey(DateTime.now());

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
