import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/science/training_physiology.dart';

part 'daily_routine_provider.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> dailyRoutine(DailyRoutineRef ref) async {
  final baseExercises = [
    { 'name': 'Sentadilla Goblet', 'sets': '3 series x 10-12 reps', 'targetRir': 2, 'lastWeight': 20.0, 'lastRir': 4 },
    { 'name': 'Flexiones (Push-ups)', 'sets': '3 series al fallo - RIR 2', 'targetRir': 2, 'lastWeight': 0.0, 'lastRir': 2 },
    { 'name': 'Remo con mancuernas', 'sets': '3 series x 10 reps', 'targetRir': 2, 'lastWeight': 15.0, 'lastRir': 3 }
  ];

  return baseExercises.map((e) {
    final lastWeight = (e['lastWeight'] as num).toDouble();
    final lastRir = e['lastRir'] as int;
    final targetRir = e['targetRir'] as int;

    // Calculate recommended weight if there's a previous weight
    double? recommended;
    if (lastWeight > 0) {
      recommended = TrainingPhysiology.calculateNextWeight(lastWeight, lastRir, targetRir);
    }

    // Return new map with recommendation
    return {
      ...e,
      'recommendedWeight': recommended,
    };
  }).toList();
}
