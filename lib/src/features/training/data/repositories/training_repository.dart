import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exercise_model.dart';
import '../../domain/entities/workout_log.dart';
import '../../domain/entities/metabolic_state.dart';
import '../../domain/entities/training_entities.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRAINING REPOSITORY — Data access layer for exercises and workouts
// METAMORFOSIS REAL PROTOCOL INTEGRATION
// ─────────────────────────────────────────────────────────────────────────────

abstract class TrainingRepository {
  /// Get exercise by ID
  Future<ExerciseModel?> getExerciseById(String id);

  /// Get all exercises by category
  Future<List<ExerciseModel>> getExercisesByCategory(ExerciseCategory category);

  /// Search exercises by name
  Future<List<ExerciseModel>> searchExercises(String query);

  /// Save a workout session
  Future<void> saveWorkoutSession(RecordedWorkoutSession session);

  /// Get workout sessions for user in last N hours
  Future<List<RecordedWorkoutSession>> getRecentWorkoutSessions(
    String userId,
    int hoursBack,
  );

  /// Get active muscles from last 24 hours of workouts
  Future<Set<String>> getActiveMusclesLast24Hours(String userId);

  /// Seed initial exercises to Firestore
  Future<void> seedMetamorfosisExercises();

  /// Atomic operation to save workout log and potentially update metabolic state
  Future<void> completeWorkoutSession({
    required String userId,
    required WorkoutLog log,
    required bool isHighIntensity,
  });

  /// Get workout log for a specific date
  Future<WorkoutLog?> getWorkoutLogForDate(String userId, DateTime date);

  /// Get list of workout logs for a range
  Future<List<WorkoutLog>> getWorkoutLogs(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Get daily checkin for metabolic state
  Future<MetabolicState?> getDailyCheckin(String userId, DateTime date);

  /// Save metabolic checkin
  Future<void> saveCheckin(String userId, MetabolicState state);
}

// ─────────────────────────────────────────────────────────────────────────────
// TRAINING REPOSITORY IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class TrainingRepositoryImpl implements TrainingRepository {
  final FirebaseFirestore _firestore;

  static const String _exercisesCollection = 'master_exercises_db';
  static const String _workoutsCollection = 'user_workouts';

  TrainingRepositoryImpl(this._firestore);

  @override
  Future<ExerciseModel?> getExerciseById(String id) async {
    try {
      final doc =
          await _firestore.collection(_exercisesCollection).doc(id).get();

      if (!doc.exists) return null;
      return ExerciseModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error fetching exercise: $e');
    }
  }

  @override
  Future<List<ExerciseModel>> getExercisesByCategory(
    ExerciseCategory category,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_exercisesCollection)
          .where('category', isEqualTo: category.name)
          .get();

      return querySnapshot.docs
          .map((doc) => ExerciseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching exercises by category: $e');
    }
  }

  @override
  Future<List<ExerciseModel>> searchExercises(String query) async {
    try {
      // Simple substring search (upgrade to Algolia for production)
      final querySnapshot =
          await _firestore.collection(_exercisesCollection).limit(20).get();

      final results = querySnapshot.docs
          .map((doc) => ExerciseModel.fromFirestore(doc))
          .where((ex) =>
              ex.name.toLowerCase().contains(query.toLowerCase()) ||
              ex.description.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return results;
    } catch (e) {
      throw Exception('Error searching exercises: $e');
    }
  }

  @override
  Future<void> saveWorkoutSession(RecordedWorkoutSession session) async {
    try {
      await _firestore
          .collection(_workoutsCollection)
          .doc(session.userId)
          .collection('sessions')
          .doc(session.id)
          .set(session.toFirestoreMap());
    } catch (e) {
      throw Exception('Error saving workout session: $e');
    }
  }

  @override
  Future<List<RecordedWorkoutSession>> getRecentWorkoutSessions(
    String userId,
    int hoursBack,
  ) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hoursBack));

      final querySnapshot = await _firestore
          .collection(_workoutsCollection)
          .doc(userId)
          .collection('sessions')
          .where('session_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffTime))
          .orderBy('session_date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RecordedWorkoutSession.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching recent workouts: $e');
    }
  }

  @override
  Future<Set<String>> getActiveMusclesLast24Hours(String userId) async {
    try {
      final sessions = await getRecentWorkoutSessions(userId, 24);

      final activeMuscles = <String>{};
      for (final session in sessions) {
        activeMuscles.addAll(session.uniqueMusclesWorked);
      }

      return activeMuscles;
    } catch (e) {
      throw Exception('Error fetching active muscles: $e');
    }
  }

  @override
  Future<void> completeWorkoutSession({
    required String userId,
    required WorkoutLog log,
    required bool isHighIntensity,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Save Workout Log
      final logRef = _firestore
          .collection('user_workouts')
          .doc(userId)
          .collection('workout_logs')
          .doc(log.id);
      batch.set(logRef, log.toJson());

      // 2. Mark session date for summary stats
      final summaryRef = _firestore
          .collection('user_workouts')
          .doc(userId)
          .collection('summary')
          .doc('latest');
      batch.set(summaryRef, {
        'lastWorkoutDate': Timestamp.fromDate(log.date),
        'lastIsHighIntensity': isHighIntensity,
        'userId': userId,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      throw Exception('Error completing workout session: $e');
    }
  }

  @override
  Future<WorkoutLog?> getWorkoutLogForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('user_workouts')
          .doc(userId)
          .collection('workout_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return WorkoutLog.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Error fetching workout log by date: $e');
    }
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogs(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_workouts')
          .doc(userId)
          .collection('workout_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WorkoutLog.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching workout logs: $e');
    }
  }

  @override
  Future<MetabolicState?> getDailyCheckin(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('user_workouts')
          .doc(userId)
          .collection('checkins')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return MetabolicState.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Error fetching daily checkin: $e');
    }
  }

  @override
  Future<void> saveCheckin(String userId, MetabolicState state) async {
    try {
      await _firestore
          .collection('user_workouts')
          .doc(userId)
          .collection('checkins')
          .add(state.toJson());
    } catch (e) {
      throw Exception('Error saving checkin: $e');
    }
  }

  @override
  Future<void> seedMetamorfosisExercises() async {
    try {
      // Check if already seeded
      final count =
          await _firestore.collection(_exercisesCollection).count().get();

      if (count.count! > 0) {
        return; // Already seeded
      }

      final now = DateTime.now();
      final exercises = _generateMasterExercises(now);

      // Batch write for efficiency
      final batch = _firestore.batch();

      for (final exercise in exercises) {
        final docRef =
            _firestore.collection(_exercisesCollection).doc(exercise.id);
        batch.set(docRef, exercise.toFirestoreMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error seeding exercises: $e');
    }
  }

  /// Generate 20 core exercises from Metamorfosis Real protocol
  List<ExerciseModel> _generateMasterExercises(DateTime now) {
    return [
      // FUERZA — 7 exercises
      ExerciseModel(
        id: 'sentadilla-profunda',
        name: 'Sentadilla Profunda',
        description:
            'Fundamental compound movement for lower body. Progressive overload key.',
        category: ExerciseCategory.fuerza,
        targetMuscles: ['quads', 'glutes', 'hamstrings', 'abs'],
        instructions:
            'Feet shoulder-width. Descend until hip crease below knee. Knees tracking toes. Chest up. Drive through heels. Pause 1-2 seconds bottom position.',
        durationSeconds: 180,
        restSeconds: 90,
        recommendedSets: 4,
        recommendedReps: 6,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'peso-muerto',
        name: 'Peso Muerto',
        description:
            'Maximum posterior chain development. Elite cardiometabolic stimulus.',
        category: ExerciseCategory.fuerza,
        targetMuscles: ['glutes', 'hamstrings', 'back', 'lats', 'traps'],
        instructions:
            'Bar over mid-foot. Chest over bar. Neutral spine. Drive legs first. Lockout at hip and knee simultaneously. Touch and go or reset between reps.',
        durationSeconds: 240,
        restSeconds: 120,
        recommendedSets: 3,
        recommendedReps: 5,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'press-banca',
        name: 'Press de Banca',
        description: 'Upper body pushing power. Chest and triceps foundation.',
        category: ExerciseCategory.fuerza,
        targetMuscles: ['pecs', 'triceps', 'shoulders'],
        instructions:
            'Scapulae retracted. Feet on floor. Lower to mid-chest. Elbows 45-degree angle. Explosive concentric. Full ROM.',
        durationSeconds: 180,
        restSeconds: 90,
        recommendedSets: 4,
        recommendedReps: 6,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'remo-barra',
        name: 'Remo con Barra',
        description:
            'Back thickness and pulling power. Antagonist to bench press.',
        category: ExerciseCategory.fuerza,
        targetMuscles: ['back', 'lats', 'biceps', 'traps'],
        instructions:
            'Bar at shins. Chest over bar. Neutral spine. Row to lower ribs. Squeeze shoulder blades. Control descent. Full extension bottom.',
        durationSeconds: 180,
        restSeconds: 90,
        recommendedSets: 4,
        recommendedReps: 6,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'flexiones',
        name: 'Flexiones (Push-ups)',
        description: 'Calisthenics chest and triceps. Scalable progression.',
        category: ExerciseCategory.fuerza,
        targetMuscles: ['pecs', 'triceps', 'shoulders', 'abs'],
        instructions:
            'Hands slightly wider than shoulders. Plank position. Lower until chest near ground. Elbows 45 degrees. Push explosively. Full ROM each rep.',
        durationSeconds: 120,
        restSeconds: 60,
        recommendedSets: 3,
        recommendedReps: 12,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'dominadas',
        name: 'Dominadas (Pull-ups)',
        description: 'Primary back builder. Upper body pulling strength.',
        category: ExerciseCategory.fuerza,
        targetMuscles: ['lats', 'back', 'biceps', 'traps'],
        instructions:
            'Overhand grip. Shoulder-width. Chest to bar. Full stretch bottom. Control eccentric. Strict form or weighted progression.',
        durationSeconds: 120,
        restSeconds: 90,
        recommendedSets: 4,
        recommendedReps: 8,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'prensa-piernas',
        name: 'Prensa de Piernas',
        description: 'Quad emphasis. Safe deep ROM alternative to squat.',
        category: ExerciseCategory.fuerza,
        targetMuscles: ['quads', 'glutes', 'hamstrings'],
        instructions:
            'Seat position. Feet hip-width. Full ROM without heel lift. Drive through midfoot. Partial lockout top. 2-second concentric.',
        durationSeconds: 150,
        restSeconds: 75,
        recommendedSets: 3,
        recommendedReps: 10,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      // HIIT — 7 exercises
      ExerciseModel(
        id: 'burpees',
        name: 'Burpees',
        description:
            'Full-body metabolic conditioning. Max efficiency movement.',
        category: ExerciseCategory.hiit,
        targetMuscles: ['quads', 'glutes', 'pecs', 'triceps', 'abs'],
        instructions:
            'Stand. Squat. Hands down. Explosive jump to plank. Push-up. Explosive jump back. Explosive jump up. Repeat. Maximum power.',
        durationSeconds: 30,
        restSeconds: 30,
        recommendedSets: 5,
        recommendedReps: 0, // Timed
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'mountain-climbers',
        name: 'Mountain Climbers',
        description: 'Core and cardiovascular spike. Rapid tempo.',
        category: ExerciseCategory.hiit,
        targetMuscles: ['abs', 'obliques', 'shoulders', 'quads'],
        instructions:
            'Plank position. Alternate drive knees to chest. Fast rhythm. 120+ RPM. Maintain core tension. Hips level.',
        durationSeconds: 45,
        restSeconds: 15,
        recommendedSets: 6,
        recommendedReps: 0, // Timed
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'jumping-jacks',
        name: 'Jumping Jacks',
        description: 'Cardiovascular warm-up or finisher. Accessible.',
        category: ExerciseCategory.hiit,
        targetMuscles: ['glutes', 'calves', 'shoulders'],
        instructions:
            'Feet together. Explosive jump. Land feet apart. Arms overhead. Jump back to start. Continuous motion. High cadence.',
        durationSeconds: 60,
        restSeconds: 30,
        recommendedSets: 4,
        recommendedReps: 0, // Timed
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'sprints',
        name: 'Sprints (30-60 segundos)',
        description: 'Maximum anaerobic effort. Short interval work.',
        category: ExerciseCategory.hiit,
        targetMuscles: ['quads', 'glutes', 'hamstrings', 'calves'],
        instructions:
            'All-out effort. 30-60 second intervals. Walk or light jog recovery. 1-2 minutes rest between intervals.',
        durationSeconds: 45,
        restSeconds: 90,
        recommendedSets: 6,
        recommendedReps: 0, // Timed
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'battle-ropes',
        name: 'Battle Ropes',
        description: 'Metabolic circuit element. Upper body conditioning.',
        category: ExerciseCategory.hiit,
        targetMuscles: ['shoulders', 'triceps', 'abs', 'forearms'],
        instructions:
            'Athletic stance. Alternating rope wave pattern. Maximum velocity. 40-50 seconds work. Full body engagement.',
        durationSeconds: 40,
        restSeconds: 20,
        recommendedSets: 8,
        recommendedReps: 0, // Timed
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'box-jumps',
        name: 'Box Jumps',
        description: 'Explosive power development. Lower body plyometric.',
        category: ExerciseCategory.hiit,
        targetMuscles: ['quads', 'glutes', 'calves', 'hamstrings'],
        instructions:
            'Face box. Explosive jump onto platform. Land soft. Step down. Reset. Full power each rep. 24-36 inch box.',
        durationSeconds: 45,
        restSeconds: 45,
        recommendedSets: 5,
        recommendedReps: 0, // Timed
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'kettlebell-swings',
        name: 'Kettlebell Swings',
        description: 'Hip hinge power. Full-body metabolic stimulus.',
        category: ExerciseCategory.hiit,
        targetMuscles: ['glutes', 'hamstrings', 'back', 'abs'],
        instructions:
            'Feet shoulder-width. Hinge at hip. Explosive drive. Hip snap. Kettlebell eye level. Full power concentric. Control eccentric.',
        durationSeconds: 60,
        restSeconds: 30,
        recommendedSets: 5,
        recommendedReps: 0, // Timed
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      // MOVILIDAD — 6 exercises
      ExerciseModel(
        id: 'estiramiento-cuadriceps',
        name: 'Estiramiento de Cuádriceps',
        description: 'Static quad flexibility. Recovery protocol.',
        category: ExerciseCategory.movilidad,
        targetMuscles: ['quads'],
        instructions:
            'Standing or supine. Pull ankle to glutes. Neutral spine. 30-60 second hold. Gentle tension. Both sides.',
        durationSeconds: 60,
        restSeconds: 10,
        recommendedSets: 2,
        recommendedReps: 0, // Timed hold
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'estiramiento-isquiotibiales',
        name: 'Estiramiento de Isquiotibiales',
        description: 'Hamstring and low back mobility.',
        category: ExerciseCategory.movilidad,
        targetMuscles: ['hamstrings', 'back'],
        instructions:
            'Seated or standing. Hinge at hips. Reach towards toes. Gentle stretch. No bouncing. 30-60 second hold per side.',
        durationSeconds: 60,
        restSeconds: 10,
        recommendedSets: 2,
        recommendedReps: 0, // Timed hold
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'cat-cow',
        name: 'Cat-Cow Stretch',
        description: 'Spinal mobility and core engagement.',
        category: ExerciseCategory.movilidad,
        targetMuscles: ['back', 'abs', 'pecs'],
        instructions:
            'Quadruped position. Arch back. Lift head and tailbone (cow). Reverse: round spine. Drop head (cat). Fluid rhythm.',
        durationSeconds: 60,
        restSeconds: 0,
        recommendedSets: 1,
        recommendedReps: 10,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'hip-circles',
        name: 'Hip Mobility Circles',
        description: 'Glute activation and hip ROM.',
        category: ExerciseCategory.movilidad,
        targetMuscles: ['glutes', 'abs', 'obliques'],
        instructions:
            'Hands on hips. Knees bent. Draw circles with hips. Clockwise and counterclockwise. Large ROM. 10 circles each direction.',
        durationSeconds: 45,
        restSeconds: 0,
        recommendedSets: 2,
        recommendedReps: 10,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'shoulder-pass-through',
        name: 'Shoulder Pass-Through',
        description: 'Shoulder mobility and scapular awareness.',
        category: ExerciseCategory.movilidad,
        targetMuscles: ['shoulders', 'pecs', 'back'],
        instructions:
            'Hold band or PVC. Feet shoulder-width. Pass overhead. Behind back. Return. Gradual band narrowing. 15 reps.',
        durationSeconds: 45,
        restSeconds: 0,
        recommendedSets: 2,
        recommendedReps: 15,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
      ExerciseModel(
        id: 'world-greatest-stretch',
        name: 'World\'s Greatest Stretch',
        description: 'Full-body mobility. Complete warm-up movement.',
        category: ExerciseCategory.movilidad,
        targetMuscles: [
          'hamstrings',
          'quads',
          'pecs',
          'shoulders',
          'abs',
          'back'
        ],
        instructions:
            'Stand. Touch toes. Plank. Push-up. Rotate to downward dog. Rotate to crescent lunge. Stand. Repeat other side.',
        durationSeconds: 120,
        restSeconds: 0,
        recommendedSets: 2,
        recommendedReps: 6,
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
