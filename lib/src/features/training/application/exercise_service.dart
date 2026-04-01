import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_logger.dart';
import '../data/repositories/training_repository.dart';
import '../domain/entities/exercise_model.dart';
import '../domain/entities/workout_log.dart';

part 'exercise_service.g.dart';

/// 🏗️ EXERCISE SERVICE - Centraliza operaciones de entrenamiento
///
/// Reemplaza queries dispersas en widgets.
/// Proporciona interfaz limpia y testeable para:
/// - Registrar sesiones de ejercicio
/// - Obtener historial de entrenamientos
/// - Calcular estadísticas de desempeño
class ExerciseService {
  final TrainingRepository _repository;

  ExerciseService(this._repository);

  /// ✅ Registrar nueva sesión de ejercicio
  Future<void> logWorkout({
    required String uid,
    required RecordedWorkoutSession workout,
  }) async {
    try {
      AppLogger.debug(
        'Registrando sesión con ${workout.exercises.length} ejercicios por ${workout.totalDuration.inMinutes} min',
      );
      await _repository.saveWorkoutSession(workout);
      AppLogger.info('Sesión registrada exitosamente');
    } catch (e) {
      AppLogger.error('Error registrando sesión: $e');
      rethrow;
    }
  }

  /// ✅ Obtener entrenamientos recientes
  Future<List<RecordedWorkoutSession>> getRecentWorkouts(
    String uid, {
    int hoursBack = 24,
  }) async {
    try {
      AppLogger.debug(
          'Obteniendo entrenamientos de las últimas $hoursBack horas');
      return await _repository.getRecentWorkoutSessions(uid, hoursBack);
    } catch (e) {
      AppLogger.error('Error obteniendo entrenamientos: $e');
      rethrow;
    }
  }

  /// ✅ Obtener logs de entrenamientos por rango de fechas
  Future<List<WorkoutLog>> getWorkoutLogs(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      AppLogger.debug(
        'Obteniendo entrenamientos entre ${startDate.toIso8601String()} y ${endDate.toIso8601String()}',
      );
      return await _repository.getWorkoutLogs(uid, startDate, endDate);
    } catch (e) {
      AppLogger.error('Error obteniendo logs: $e');
      rethrow;
    }
  }

  /// ✅ Obtener log de entrenamiento para una fecha específica
  Future<WorkoutLog?> getWorkoutForDate(
    String uid,
    DateTime date,
  ) async {
    try {
      AppLogger.debug(
          'Obteniendo entrenamiento para ${date.toIso8601String()}');
      return await _repository.getWorkoutLogForDate(uid, date);
    } catch (e) {
      AppLogger.error('Error obteniendo entrenamiento: $e');
      rethrow;
    }
  }

  /// ✅ Calcular calorías quemadas en sesión
  /// Usa: weight (kg), duration (min), tipo de ejercicio
  double calculateCaloriesBurned({
    required double weightKg,
    required int durationMinutes,
    required String exerciseType,
  }) {
    try {
      // MET (Metabolic Equivalent of Task) values por tipo de ejercicio
      final metValues = <String, double>{
        'cardio': 8.0,
        'strength': 6.0,
        'yoga': 3.0,
        'walking': 3.5,
        'running': 9.8,
        'cycling': 8.0,
        'swimming': 11.0,
        'hiit': 12.0,
      };

      final met = metValues[exerciseType.toLowerCase()] ?? 6.0;
      final calories = (weightKg * met * durationMinutes) / 60;

      AppLogger.debug(
        'Calorías calculadas: $calories (MET: $met, Duration: ${durationMinutes}min)',
      );
      return calories;
    } catch (e) {
      AppLogger.error('Error calculando calorías: $e');
      return 0;
    }
  }

  /// ✅ Obtener músculos activados en las últimas 24h
  Future<Set<String>> getActiveMuscles(String uid) async {
    try {
      AppLogger.debug('Obteniendo músculos activos de las últimas 24h');
      return await _repository.getActiveMusclesLast24Hours(uid);
    } catch (e) {
      AppLogger.error('Error obteniendo músculos activos: $e');
      return {};
    }
  }
}

/// 📱 Riverpod Providers para ExerciseService
///
/// Proporcionan acceso singleton a ExerciseService en toda la app

@riverpod
TrainingRepository trainingRepository(ref) {
  return TrainingRepositoryImpl(FirebaseFirestore.instance);
}

@riverpod
ExerciseService exerciseService(ref) {
  final repository = ref.watch(trainingRepositoryProvider);
  return ExerciseService(repository);
}

/// ✅ Provider para entrenamientos recientes
@riverpod
Future<List<RecordedWorkoutSession>> recentWorkouts(ref, String uid) async {
  final service = ref.watch(exerciseServiceProvider);
  return await service.getRecentWorkouts(uid, hoursBack: 24);
}

/// ✅ Provider para logs de entrenamiento
@riverpod
Future<List<WorkoutLog>> workoutLogs(
  ref,
  String uid,
  DateTime startDate,
  DateTime endDate,
) async {
  final service = ref.watch(exerciseServiceProvider);
  return await service.getWorkoutLogs(uid, startDate, endDate);
}

/// ✅ Provider para músculos activos
@riverpod
Future<Set<String>> activeMuscles(ref, String uid) async {
  final service = ref.watch(exerciseServiceProvider);
  return await service.getActiveMuscles(uid);
}
