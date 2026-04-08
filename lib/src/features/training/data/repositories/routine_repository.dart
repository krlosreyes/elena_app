import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/set_log.dart';
import '../../domain/entities/weekly_routine.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ROUTINE REPOSITORY — CRUD for weekly routines & individual set logs
// Firestore paths:
//   users/{uid}/weekly_routines/{weekId}
//   users/{uid}/weekly_routines/{weekId}/set_logs/{setLogId}
// ═══════════════════════════════════════════════════════════════════════════════

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(FirebaseFirestore.instance);
});

class RoutineRepository {
  final FirebaseFirestore _firestore;

  RoutineRepository(this._firestore);

  // ─── Collection refs ────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _routinesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('weekly_routines');

  CollectionReference<Map<String, dynamic>> _setLogsCol(
    String uid,
    String weekId,
  ) => _routinesCol(uid).doc(weekId).collection('set_logs');

  // ═══════════════════════════════════════════════════════════════════════════
  // READ — Current week routine
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtener la rutina de la semana actual (null si no existe aún)
  Future<WeeklyRoutine?> getCurrentWeekRoutine(String uid) async {
    final weekId = WeeklyRoutine.currentWeekId();
    final doc = await _routinesCol(uid).doc(weekId).get();
    if (!doc.exists || doc.data() == null) return null;
    return WeeklyRoutine.fromJson(doc.data()!);
  }

  /// Stream en tiempo real de la rutina de una semana específica
  Stream<WeeklyRoutine?> weekRoutineStream(String uid, String weekId) {
    return _routinesCol(uid).doc(weekId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return WeeklyRoutine.fromJson(snap.data()!);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE — Save generated routine
  // ═══════════════════════════════════════════════════════════════════════════

  /// Guardar una rutina recién generada
  Future<void> saveWeeklyRoutine(String uid, WeeklyRoutine routine) async {
    await _routinesCol(uid).doc(routine.weekId).set(routine.toJson());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOG SET — Register a completed set + update completedSets atomically
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registrar una serie completada y actualizar completedSets del ejercicio
  Future<void> logSet(
    String uid,
    String weekId,
    int dayIndex,
    String exerciseId,
    SetLog setLog,
  ) async {
    final batch = _firestore.batch();

    // 1. Write the individual set log document
    final setLogRef = _setLogsCol(uid, weekId).doc();
    batch.set(setLogRef, setLog.copyWith(id: setLogRef.id).toJson());

    // 2. Read the current routine to update completedSets
    final routineDoc = await _routinesCol(uid).doc(weekId).get();
    if (routineDoc.exists && routineDoc.data() != null) {
      final routine = WeeklyRoutine.fromJson(routineDoc.data()!);

      // Find the day and exercise, increment completedSets
      final updatedDays = routine.days.map((day) {
        if (day.dayIndex != dayIndex) return day;
        final updatedExercises = day.exercises.map((ex) {
          if (ex.exerciseId != exerciseId) return ex;
          return ex.copyWith(
            completedSets: (ex.completedSets + 1).clamp(0, ex.targetSets),
          );
        }).toList();
        return day.copyWith(exercises: updatedExercises);
      }).toList();

      // 3. Write the updated routine
      final updatedRoutine = routine.copyWith(days: updatedDays);
      batch.set(_routinesCol(uid).doc(weekId), updatedRoutine.toJson());
    }

    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MARK DAY COMPLETED
  // ═══════════════════════════════════════════════════════════════════════════

  /// Marcar un día como completado
  Future<void> markDayCompleted(String uid, String weekId, int dayIndex) async {
    final doc = await _routinesCol(uid).doc(weekId).get();
    if (!doc.exists || doc.data() == null) return;

    final routine = WeeklyRoutine.fromJson(doc.data()!);
    final updatedDays = routine.days.map((day) {
      if (day.dayIndex != dayIndex) return day;
      return day.copyWith(completed: true, completedAt: DateTime.now());
    }).toList();

    // Check if all days are completed
    final allDone = updatedDays.every(
      (d) => d.type == WorkoutDayType.rest || d.completed,
    );

    final updatedRoutine = routine.copyWith(
      days: updatedDays,
      completed: allDone,
    );

    await _routinesCol(uid).doc(weekId).set(updatedRoutine.toJson());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY — Set logs for a specific day
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtener todas las series registradas de un día específico
  Future<List<SetLog>> getSetLogsForDay(
    String uid,
    String weekId,
    int dayIndex,
  ) async {
    final query = await _setLogsCol(
      uid,
      weekId,
    ).where('dayIndex', isEqualTo: dayIndex).orderBy('loggedAt').get();

    return query.docs.map((doc) => SetLog.fromJson(doc.data())).toList();
  }
}
