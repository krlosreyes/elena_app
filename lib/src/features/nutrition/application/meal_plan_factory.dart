// SPEC-273 — Fábrica pura de la Minuta del día.
//
// Une las piezas de SPEC-270..272 en un solo paso, PURO (sin Riverpod /
// Firestore / Flutter): a partir de la biometría del usuario + el intake,
// deriva la proteína objetivo (ProteinTargetService) y llama al motor
// (MealPlanGenerator). El notifier (meal_plan_notifier.dart) solo aporta el
// I/O (leer user/intake, persistir el MealPlan); toda la decisión vive aquí
// y en el generador, ambos testeables sin montar la app.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/protein_target_service.dart';

class MealPlanFactory {
  const MealPlanFactory();

  static const ProteinTargetService _protein = ProteinTargetService();
  static const MealPlanGenerator _generator = MealPlanGenerator();

  /// Construye la minuta del día [now] (por defecto hoy). Toma primitivas
  /// —no el UserModel— para poder testearse sin construir todo el modelo:
  /// el notifier las extrae del UserModel (height/gender/activityLevel y la
  /// ventana firstMealGoal/lastMealGoal ya formateada a "HH:mm").
  MealPlan build({
    required NutritionIntake intake,
    required double heightCm,
    required String gender,
    required double pal,
    String windowFirst = '',
    String windowLast = '',
    int phase = 1,
    DateTime? now,
  }) {
    final when = now ?? DateTime.now();
    final target = _protein.targetProteinG(
      heightCm: heightCm,
      gender: gender,
      pal: pal,
    );
    return _generator
        .generate(
          intake: intake,
          targetProteinG: target,
          dateId: MealPlan.dateId(when),
          windowFirst: windowFirst,
          windowLast: windowLast,
          phase: phase,
          now: when,
        )
        // SPEC-295: sella el plan con la marca del intake con que se generó,
        // para detectar que quedó obsoleto si el usuario edita sus preferencias.
        .copyWith(intakeStampMs: intake.updatedAt.millisecondsSinceEpoch);
  }
}
