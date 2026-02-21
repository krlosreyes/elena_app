import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine_template.dart';
import '../../domain/entities/workout_log.dart';
import '../../domain/entities/training_entities.dart'; // Keep for WeeklyTrainingStats
import '../../domain/entities/metabolic_state.dart';

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
          .set(log.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving workout log: $e');
      rethrow;
    }
  }

  // 4. Get Last Exercise Log (Progressive Overload)
  Future<Map<String, dynamic>?> getLastExerciseLog(String userId, String exerciseId) async {
    try {
      // Query the last workout log for the user
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_logs')
          .orderBy('date', descending: true)
          .limit(1) // As requested, check the very last workout. 
          // Ideally, we'd search deeper if the exercise wasn't in the last workout, 
          // but strict instructions specify limit(1).
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final lastLog = WorkoutLog.fromJson(querySnapshot.docs.first.data());

      // Search for the specific exercise validation in the completed list
      // We assume the map has keys 'exerciseId' or similar to identify it.
      // Based on previous context, we know completedExercises is List<Map<String, dynamic>>.
      // We need to find the map where exerciseId matches.
      
      try {
        final exerciseLog = lastLog.completedExercises.firstWhere(
          (logMap) => logMap['exerciseId'] == exerciseId,
        );
        return exerciseLog;
      } catch (e) {
        // Exercise not found in this specific log
        return null; 
      }

    } catch (e) {
      print('Error getting last exercise log: $e');
      return null;
    }
  }

  // 5. Get Workout Log by Date
  Future<WorkoutLog?> getWorkoutLogForDate(String userId, DateTime date) async {
    try {
      // Create range for the entire day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return WorkoutLog.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      print('Error getting workout log for date: $e');
      return null;
    }
  }

  // 6. Get Workout Logs by Range (for Stats)
  Future<List<WorkoutLog>> getWorkoutLogs(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => WorkoutLog.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting workout logs by range: $e');
      return [];
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
// 8. Get Daily Metabolic Check-in
  Future<MetabolicState?> getDailyCheckin(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('metabolic_checkins')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      
      // Need to handle Timestamp conversion manually if not done by json_serializable custom converter
      final data = querySnapshot.docs.first.data();
      // Adjust timestamp if needed (MetabolicState uses DateTime)
      // Assuming generated toJson handles DateTime as String or Timestamp?
      // Freezed/JsonSerializable usually uses String ISO8601 by default unless configured.
      // Firestore returns Timestamp. 
      // Let's safe-convert.
      if (data['date'] is Timestamp) {
         data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
      }
      
      return MetabolicState.fromJson(data);
    } catch (e) {
      print('Error getting metabolic checkin: $e');
      return null;
    }
  }

  // 9. Save Daily Metabolic Check-in
  Future<void> saveCheckin(String userId, MetabolicState checkin) async {
    try {
      // Logic to use a consistent ID for the day could be useful to avoid duplicates,
      // but query limits to 1 anyway. Let's just add().
      // Actually, better to use date string as ID to enforce uniqueness at DB level?
      // Or just add. The use case prevents double submission at app layer.
      
      // Convert to Json.
      final json = checkin.toJson();
      // Ensure date is saved as Timestamp for querying if needed, or keep ISO string.
      // Above query compares Timestamp, so we should save as Timestamp or ensure comparison works.
      // If we save as ISO String, range query on 'date' (Timestamp) won't match String field.
      // CRITICAL: We need consistent types.
      // Let's save 'date' as FieldValue.serverTimestamp() or Timestamp.fromDate(checkin.date).
      // But MetabolicState has DateTime. 
      // Let's overwrite 'date' in the json map before saving to Firestore.
      json['date'] = Timestamp.fromDate(checkin.date);
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('metabolic_checkins')
          .add(json);
    } catch (e) {
      print('Error saving metabolic checkin: $e');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
TrainingRepository trainingRepository(Ref ref) {
  return TrainingRepository(FirebaseFirestore.instance);
}
