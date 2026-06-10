// Mapeo GoalType → ícono (presentación). Mantiene el dominio (UserGoal) libre
// de dependencias de UI: la elección de ícono vive aquí, sobre AppIcons.

import 'package:flutter/widgets.dart';

import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

IconData goalIcon(GoalType type) {
  switch (type) {
    case GoalType.weightTarget:
      return AppIcons.peso;
    case GoalType.bodyFatTarget:
      return AppIcons.grasa;
    case GoalType.fastingDaysPerWeek:
      return AppIcons.ayuno;
    case GoalType.exerciseMinPerDay:
      return AppIcons.ejercicio;
    case GoalType.sleepHoursPerNight:
      return AppIcons.sueno;
    case GoalType.hydrationLitersPerDay:
      return AppIcons.hidratacion;
    case GoalType.nutritionADominantPercent:
      return AppIcons.nutricion;
  }
}
