import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine_template.dart';
import '../../domain/entities/workout_log.dart';
import '../../domain/entities/training_entities.dart'; // Keep for WeeklyTrainingStats

part 'training_repository.g.dart';

class TrainingRepository {
  final FirebaseFirestore _firestore;

  TrainingRepository(this._firestore);

  // 1. Get Routine Template
  Future<RoutineTemplate?> getRoutineTemplate(String goal, String level) async {
    try {
      final querySnapshot = await _firestore
          .collection('routine_templates')
          .where('goal', isEqualTo: goal)
          .where('level', isEqualTo: level)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return RoutineTemplate.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      // Log error
      print('Error getting routine template: $e');
      return null;
    }
  }

  // 2. Get Exercises by IDs
  Future<List<Exercise>> getExercisesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      // Firestore 'whereIn' is limited to 10 items.
      // If ids > 10, we'd need to batch. For now assuming < 10 for daily workout.
      final querySnapshot = await _firestore
          .collection('exercises')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      return querySnapshot.docs
          .map((doc) => Exercise.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting exercises: $e');
      return [];
    }
  }

  // 3. Save Workout Log
  Future<void> saveWorkoutLog(String userId, WorkoutLog log) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_logs')
          .doc(log.id)
          .set(log.toJson());
    } catch (e) {
      print('Error saving workout log: $e');
      throw e;
    }
  }

  // Existing method stub - Keeping integration
  Future<WeeklyTrainingStats> getWeeklyStats() async {
     // TODO: Implement actual logic
     await Future.delayed(const Duration(milliseconds: 500));
     return const WeeklyTrainingStats(
       totalStrengthMins: 120, 
       totalHiitMins: 30, 
       zone2Mins: 45, 
       consecutiveWeeksTrained: 4
     );
  }
  
  // Existing method stub - Keeping integration
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    // Legacy support or alias to saveWorkoutLog
  }
}

@Riverpod(keepAlive: true)
TrainingRepository trainingRepository(TrainingRepositoryRef ref) {
  return TrainingRepository(FirebaseFirestore.instance);
}
