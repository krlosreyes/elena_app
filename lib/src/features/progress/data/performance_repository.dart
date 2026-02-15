import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

// Modelo simple para representar el score de un día
class DailyPerformance {
  final DateTime date;
  final bool hasFasting;
  final bool hasWorkout;
  final bool hasNutrition;

  DailyPerformance({
    required this.date,
    this.hasFasting = false,
    this.hasWorkout = false,
    this.hasNutrition = false,
  });

  int get score {
    int s = 0;
    if (hasFasting) s++;
    if (hasWorkout) s++;
    if (hasNutrition) s++;
    return s;
  }
}

class PerformanceRepository {
  final FirebaseFirestore _firestore;

  PerformanceRepository(this._firestore);

  Stream<Map<DateTime, int>> getWeeklyScores(String uid) {
    final now = DateTime.now();
    // Lunes de la semana actual (a las 00:00)
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    // 1. FASTING Stream
    final fastingStream = _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .where('startTime', isGreaterThanOrEqualTo: startOfWeek.toIso8601String()) // Asumiendo formato ISO string por el fix anterior
        // Nota: Si hay mezclados Timestamps y Strings, esto podría ser complejo. 
        // Asumiremos que el fix anterior estandarizó a String o que Firestore maneja la query si es Timestamp.
        // CORRECCIÓN: El fix anterior solo afectó la lectura, no la escritura masiva.
        // Sin embargo, para no complicar, traeremos los últimos 7 días sin filtro estricto de query si es posible, 
        // o filtraremos en memoria.
        .snapshots()
        .map((percent) => percent.docs);

    // 2. WORKOUTS Stream (Colección nueva/futura)
    final workoutsStream = _firestore
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .snapshots()
        .map((percent) => percent.docs);

    // 3. MEALS Stream (Colección nueva/futura)
    final mealsStream = _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .snapshots()
        .map((percent) => percent.docs);

    // COMBINE
    return Rx.combineLatest3(
      fastingStream,
      workoutsStream,
      mealsStream,
      (List<DocumentSnapshot> fasts, List<DocumentSnapshot> workouts, List<DocumentSnapshot> meals) {
        final Map<DateTime, int> scores = {};

        // Iterar los 7 días de la semana
        for (int i = 0; i < 7; i++) {
          final day = startOfWeek.add(Duration(days: i));
          // Normalizar día para usar como clave del mapa
          final dayKey = DateTime(day.year, day.month, day.day);

          // Si es futuro, no calculamos (o score 0/null, pero UI lo manejará)
          if (dayKey.isAfter(DateTime(now.year, now.month, now.day))) {
            continue; 
          }

          // A. Fasting
          // Criterio: Algún ayuno completado ese día o activo que cubra el día?
          // Simplificación: StartTime cae en ese día.
          bool hasFasting = fasts.any((doc) {
             final data = doc.data() as Map<String, dynamic>;
             final rawStart = data['startTime'];
             DateTime start;
             if (rawStart is Timestamp) start = rawStart.toDate();
             else if (rawStart is String) start = DateTime.parse(rawStart);
             else return false;

             return start.year == day.year && start.month == day.month && start.day == day.day;
          });

          // B. Workout
          bool hasWorkout = workouts.any((doc) {
             final data = doc.data() as Map<String, dynamic>;
             // Asumimos campo 'date' Timestamp
             if (data['date'] is! Timestamp) return false;
             final date = (data['date'] as Timestamp).toDate();
             return date.year == day.year && date.month == day.month && date.day == day.day;
          });

          // C. Nutrition (Criteria: >= 2 meals)
          int mealCount = meals.where((doc) {
             final data = doc.data() as Map<String, dynamic>;
             if (data['date'] is! Timestamp) return false;
             final date = (data['date'] as Timestamp).toDate();
             return date.year == day.year && date.month == day.month && date.day == day.day;
          }).length;
          bool hasNutrition = mealCount >= 2;

          // Calc Score
          int score = 0;
          if (hasFasting) score++;
          if (hasWorkout) score++;
          if (hasNutrition) score++;

          scores[dayKey] = score;
        }

        return scores;
      },
    );
  }
}

final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  return PerformanceRepository(FirebaseFirestore.instance);
});
