import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/models/user_model.dart';
import '../../authentication/application/auth_controller.dart';
import '../data/repositories/routine_repository.dart';
import '../domain/entities/weekly_routine.dart';
import 'workout_personalizer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ROUTINE CONTROLLER — Gestión de la rutina semanal
// ═══════════════════════════════════════════════════════════════════════════════

/// Stream en tiempo real de la rutina de la semana actual
final weeklyRoutineProvider = StreamProvider.autoDispose<WeeklyRoutine?>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  final weekId = WeeklyRoutine.currentWeekId();
  return ref.read(routineRepositoryProvider).weekRoutineStream(uid, weekId);
});

/// Controller para generar o regenerar la rutina de la semana
final routineControllerProvider = Provider<RoutineController>((ref) {
  return RoutineController(ref);
});

class RoutineController {
  final Ref _ref;

  RoutineController(this._ref);

  /// Generar la rutina de esta semana si no existe aún
  Future<void> ensureWeeklyRoutineExists(UserModel user) async {
    try {
      final existing = await _ref
          .read(routineRepositoryProvider)
          .getCurrentWeekRoutine(user.uid);

      if (existing != null) {
        debugPrint('✅ [Routine] Rutina semanal ya existe: ${existing.weekId}');
        return;
      }

      final weekId = WeeklyRoutine.currentWeekId();
      final routine = WorkoutPersonalizer.generate(user, weekId: weekId);

      await _ref
          .read(routineRepositoryProvider)
          .saveWeeklyRoutine(user.uid, routine);

      debugPrint('🏋️ [Routine] Rutina generada y guardada: $weekId');
    } catch (e) {
      debugPrint('⚠️ [Routine] Error al generar rutina: $e');
      rethrow;
    }
  }

  /// Forzar regeneración (el usuario resetea la rutina manualmente)
  Future<void> regenerateRoutine(UserModel user) async {
    try {
      final weekId = WeeklyRoutine.currentWeekId();
      final routine = WorkoutPersonalizer.generate(user, weekId: weekId);

      await _ref
          .read(routineRepositoryProvider)
          .saveWeeklyRoutine(user.uid, routine);

      debugPrint('🔄 [Routine] Rutina regenerada: $weekId');
    } catch (e) {
      debugPrint('⚠️ [Routine] Error al regenerar rutina: $e');
      rethrow;
    }
  }
}
