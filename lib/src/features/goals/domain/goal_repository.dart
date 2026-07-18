// SPEC-14: Objetivos del Usuario
// ARCH-05 (auditoría 2026-07-11): interfaz abstracta para invertir la
// dependencia domain→data. Antes `features/goals/data/goal_repository.dart`
// no tenía contrato en `domain/`, así que cualquier feature que necesitara
// el tipo debía importar directo desde `data/`. La implementación Firestore
// (`GoalRepositoryImpl`) vive en `data/goal_repository.dart` e implementa
// este contrato; el provider `goalRepositoryProvider` se expone tipado a
// esta interfaz.

import 'package:elena_app/src/features/goals/domain/user_goal.dart';

abstract class GoalRepository {
  /// Persiste el mapa completo de goals para el usuario.
  Future<void> saveGoals(
    String userId,
    Map<GoalType, UserGoal> goals,
  );

  /// Stream que emite el mapa de goals cada vez que cambia.
  Stream<Map<GoalType, UserGoal>> watchGoals(String userId);

  /// Lee los goals una sola vez (útil para inicialización).
  Future<Map<GoalType, UserGoal>> fetchGoals(String userId);
}
