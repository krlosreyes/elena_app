// Propuesta módulo Ejercicio (2026-07-21), Fase 2/3: provider que arma
// el WeeklyExercisePlan del usuario activo combinando:
//   · BodyZone (ACSM) derivada de `UserModel.bodyFatPercentage` — misma
//     fórmula que `analysis/domain/body_zone.dart` / GoalSuggestionEngine.
//   · Sistema nervioso (Frank Suárez) — `UserModel.nervousSystem`.
//   · ExerciseProfile — hábitos/preferencias/lesiones (Fase 1).
//
// Consumido por la UI del "plan de hoy" (Fase 3).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/body_zone.dart';
import 'package:elena_app/src/features/exercise/application/exercise_profile_providers.dart';
import 'package:elena_app/src/features/exercise/application/weekly_exercise_plan_engine.dart';
import 'package:elena_app/src/features/exercise/domain/weekly_exercise_plan.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// `null` cuando falta el usuario o el perfil de ejercicio todavía no
/// se capturó (onboarding sin completar el paso 5, o usuarios que
/// hicieron onboarding antes de que este paso existiera).
final weeklyExercisePlanProvider =
    Provider.autoDispose<WeeklyExercisePlan?>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final profile = ref.watch(exerciseProfileStreamProvider).valueOrNull;
  if (user == null || profile == null || profile.isInitial) return null;

  final zone = bodyZoneFor(user.bodyFatPercentage, _isMale(user));
  if (zone == null) return null;

  final isExcited = _isExcited(user);

  return WeeklyExercisePlanEngine.generate(
    zone: zone,
    isExcited: isExcited,
    profile: profile,
  );
});

bool _isMale(UserModel user) {
  final g = user.gender.toLowerCase();
  return g == 'masculino' || g == 'male' || g == 'm';
}

bool _isExcited(UserModel user) {
  final ns = user.nervousSystem.toLowerCase();
  return ns == 'excitado' || ns == 'excited';
}
