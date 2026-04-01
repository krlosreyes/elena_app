import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXERCISE MODEL — Core entity for training exercises
// ─────────────────────────────────────────────────────────────────────────────

/// Exercise categories aligned with Metamorfosis Real protocol
enum ExerciseCategory {
  fuerza, // Strength training (weights, resistance)
  hiit, // High-intensity interval training
  movilidad, // Mobility and flexibility
}

/// Body parts that match SVG IDs for muscle glow effect
enum MuscleName {
  quads, // Quadriceps
  glutes, // Gluteus maximus
  hamstrings, // Hamstring group
  abs, // Abdominal core
  obliques, // Lateral core
  pecs, // Chest
  back, // Latissimus dorsi
  shoulders, // Deltoid group
  biceps, // Biceps
  triceps, // Triceps
  forearms, // Forearm extensors
  lats, // Back wings
  traps, // Trapezius
  calves, // Calf muscles
}

class ExerciseModel {
  final String id; // slug: 'sentadilla-profunda'
  final String name; // 'Sentadilla Profunda'
  final String description; // Narrative description
  final ExerciseCategory category; // fuerza | hiit | movilidad
  final List<String> targetMuscles; // SVG IDs: ['quads', 'glutes', 'abs']
  final String instructions; // Technical, direct engineer tone
  final int durationSeconds; // Typical duration (45-300s)
  final int restSeconds; // Rest between sets
  final int recommendedSets; // Typical 3-5 sets
  final int recommendedReps; // Or null for timed exercises
  final bool isVerified; // Quality assurance flag
  final DateTime createdAt;
  final DateTime updatedAt;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.targetMuscles,
    required this.instructions,
    required this.durationSeconds,
    required this.restSeconds,
    required this.recommendedSets,
    required this.recommendedReps,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Firestore-friendly map (all doubles for precision)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'target_muscles': targetMuscles,
      'instructions': instructions,
      'duration_seconds': durationSeconds.toDouble(),
      'rest_seconds': restSeconds.toDouble(),
      'recommended_sets': recommendedSets.toDouble(),
      'recommended_reps': recommendedReps.toDouble(),
      'is_verified': isVerified,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Safe deserialization from Firestore
  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: _parseCategory(data['category'] as String? ?? 'fuerza'),
      targetMuscles: List<String>.from(data['target_muscles'] as List? ?? []),
      instructions: data['instructions'] as String? ?? '',
      durationSeconds: ((data['duration_seconds'] as num?)?.toInt()) ?? 60,
      restSeconds: ((data['rest_seconds'] as num?)?.toInt()) ?? 30,
      recommendedSets: ((data['recommended_sets'] as num?)?.toInt()) ?? 3,
      recommendedReps: ((data['recommended_reps'] as num?)?.toInt()) ?? 10,
      isVerified: data['is_verified'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Parse category from string
  static ExerciseCategory _parseCategory(String category) {
    switch (category) {
      case 'hiit':
        return ExerciseCategory.hiit;
      case 'movilidad':
        return ExerciseCategory.movilidad;
      default:
        return ExerciseCategory.fuerza;
    }
  }

  /// JSON serialization for API responses
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'target_muscles': targetMuscles,
      'instructions': instructions,
      'duration_seconds': durationSeconds,
      'rest_seconds': restSeconds,
      'recommended_sets': recommendedSets,
      'recommended_reps': recommendedReps,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method for immutability patterns
  ExerciseModel copyWith({
    String? id,
    String? name,
    String? description,
    ExerciseCategory? category,
    List<String>? targetMuscles,
    String? instructions,
    int? durationSeconds,
    int? restSeconds,
    int? recommendedSets,
    int? recommendedReps,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      instructions: instructions ?? this.instructions,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      recommendedSets: recommendedSets ?? this.recommendedSets,
      recommendedReps: recommendedReps ?? this.recommendedReps,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERFORMED EXERCISE — Record of a single exercise instance
// ─────────────────────────────────────────────────────────────────────────────

class PerformedExercise {
  final String exerciseId; // Reference to ExerciseModel
  final int setsCompleted;
  final int repsPerSet; // Could be null for timed
  final int durationSeconds; // Actual time taken
  final DateTime performedAt;
  final List<String>
      musclesWorked; // Copy of target_muscles at time of performance

  PerformedExercise({
    required this.exerciseId,
    required this.setsCompleted,
    required this.repsPerSet,
    required this.durationSeconds,
    required this.performedAt,
    required this.musclesWorked,
  });

  Map<String, dynamic> toMap() => {
        'exercise_id': exerciseId,
        'sets_completed': setsCompleted.toDouble(),
        'reps_per_set': repsPerSet.toDouble(),
        'duration_seconds': durationSeconds.toDouble(),
        'performed_at': Timestamp.fromDate(performedAt),
        'muscles_worked': musclesWorked,
      };

  factory PerformedExercise.fromMap(Map<String, dynamic> data) {
    return PerformedExercise(
      exerciseId: data['exercise_id'] as String? ?? '',
      setsCompleted: ((data['sets_completed'] as num?)?.toInt()) ?? 0,
      repsPerSet: ((data['reps_per_set'] as num?)?.toInt()) ?? 0,
      durationSeconds: ((data['duration_seconds'] as num?)?.toInt()) ?? 0,
      performedAt:
          (data['performed_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      musclesWorked: List<String>.from(data['muscles_worked'] as List? ?? []),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORDED WORKOUT SESSION — Daily training record with aggregate muscle work
// ─────────────────────────────────────────────────────────────────────────────

class RecordedWorkoutSession {
  final String id; // Auto-generated
  final String userId; // Foreign key to User
  final DateTime sessionDate; // When the workout occurred
  final List<PerformedExercise> exercises; // All exercises in session
  final Duration totalDuration; // Sum of all durations
  final Set<String>
      uniqueMusclesWorked; // Aggregated muscle IDs for glow effect
  final String? notes; // Optional session notes
  final DateTime createdAt;
  final DateTime updatedAt;

  RecordedWorkoutSession({
    required this.id,
    required this.userId,
    required this.sessionDate,
    required this.exercises,
    required this.totalDuration,
    required this.uniqueMusclesWorked,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate unique muscles from all exercises
  static Set<String> calculateUniqueMuscles(List<PerformedExercise> exercises) {
    final muscles = <String>{};
    for (final exercise in exercises) {
      muscles.addAll(exercise.musclesWorked);
    }
    return muscles;
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'user_id': userId,
      'session_date': Timestamp.fromDate(sessionDate),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'total_duration_seconds': totalDuration.inSeconds.toDouble(),
      'unique_muscles_worked': uniqueMusclesWorked.toList(),
      'notes': notes ?? '',
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory RecordedWorkoutSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final exercisesList =
        (data['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RecordedWorkoutSession(
      id: data['id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      sessionDate:
          (data['session_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exercises:
          exercisesList.map((e) => PerformedExercise.fromMap(e)).toList(),
      totalDuration: Duration(
        seconds: ((data['total_duration_seconds'] as num?)?.toInt()) ?? 0,
      ),
      uniqueMusclesWorked: Set<String>.from(
        data['unique_muscles_worked'] as List? ?? [],
      ),
      notes: data['notes'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
