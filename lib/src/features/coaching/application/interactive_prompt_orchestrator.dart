// SPEC-233: Orquestador de prompts interactivos para los 5 pilares.
//
// Evalúa los 5 pilares en orden de prioridad dinámica y devuelve el prompt
// más relevante del momento. Función PURA (sin providers, sin I/O) →
// testeable directo. Reemplaza la evaluación directa de solo hidratación.
//
// Prioridad base:
//   1. Check-in emocional (SPEC-232) — hito de ayuno activo
//   2. Ayuno — protocolo alcanzado (ventana corta de acción)
//   3. Hidratación — meta no cumplida + gap respetado
//   4. Nutrición — ventana abierta + gap desde última comida
//   5. Ejercicio — meta no cumplida + horario razonable
//   6. Sueño — 90 min antes de sleepTime
//
// Anti-fatiga: si un pilar fue descartado ≥2 veces hoy, baja al final.

import 'package:elena_app/src/features/coaching/application/predictive_trigger_engine.dart';
import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';

/// Pilar de origen del prompt (para colorear la tarjeta).
enum PromptPillar { hydration, fasting, exercise, nutrition, sleep, checkIn }

/// Prompt enriquecido con su pilar de origen.
class PillarPrompt {
  final ActionablePrompt prompt;
  final PromptPillar pillar;
  const PillarPrompt({required this.prompt, required this.pillar});
}

class InteractivePromptOrchestrator {
  InteractivePromptOrchestrator._();

  /// Evalúa los 5 pilares y devuelve el prompt más relevante, o null.
  static PillarPrompt? evaluate({
    // Hidratación
    required bool hydrationGoalReached,
    required Duration? sinceLastGlass,
    // Ayuno
    required bool fastingActive,
    required bool protocolReached,
    required Duration? fastingDuration,
    // Ejercicio
    required bool exerciseGoalReached,
    // Nutrición
    required bool eatingWindowOpen,
    required Duration? sinceLastMeal,
    // Sueño
    required bool sleepLogged,
    // Check-in (SPEC-232)
    required ActionablePrompt? checkInPrompt,
    // Contexto
    required DateTime now,
    required int wakeHour,
    required int sleepHour,
    // Anti-fatiga: IDs descartados hoy (dismiss count >= 2 → deprioritize)
    required Map<String, int> dismissCountToday,
  }) {
    // Generar candidatos de cada pilar.
    final candidates = <PillarPrompt>[];

    // 1. Check-in emocional (prioridad máxima: hito de ayuno activo).
    if (checkInPrompt != null) {
      candidates.add(PillarPrompt(
        prompt: checkInPrompt,
        pillar: PromptPillar.checkIn,
      ));
    }

    // 2. Ayuno — cerrar protocolo (urgencia temporal alta).
    final fasting = PredictiveTriggerEngine.fastingPrompt(
      fastingActive: fastingActive,
      protocolReached: protocolReached,
      now: now,
    );
    if (fasting != null) {
      candidates.add(PillarPrompt(
        prompt: fasting,
        pillar: PromptPillar.fasting,
      ));
    }

    // 3. Hidratación.
    final hydration = PredictiveTriggerEngine.hydrationPrompt(
      goalReached: hydrationGoalReached,
      now: now,
      sinceLastGlass: sinceLastGlass,
      wakeHour: wakeHour,
      sleepHour: sleepHour,
    );
    if (hydration != null) {
      candidates.add(PillarPrompt(
        prompt: hydration,
        pillar: PromptPillar.hydration,
      ));
    }

    // 4. Nutrición.
    final nutrition = PredictiveTriggerEngine.nutritionPrompt(
      windowOpen: eatingWindowOpen,
      now: now,
      sinceLastMeal: sinceLastMeal,
    );
    if (nutrition != null) {
      candidates.add(PillarPrompt(
        prompt: nutrition,
        pillar: PromptPillar.nutrition,
      ));
    }

    // 5. Ejercicio.
    final exercise = PredictiveTriggerEngine.exercisePrompt(
      goalReached: exerciseGoalReached,
      now: now,
      wakeHour: wakeHour,
    );
    if (exercise != null) {
      candidates.add(PillarPrompt(
        prompt: exercise,
        pillar: PromptPillar.exercise,
      ));
    }

    // 6. Sueño — rutina nocturna.
    final sleep = PredictiveTriggerEngine.sleepPrompt(
      now: now,
      sleepHour: sleepHour,
      sleepLogged: sleepLogged,
    );
    if (sleep != null) {
      candidates.add(PillarPrompt(
        prompt: sleep,
        pillar: PromptPillar.sleep,
      ));
    }

    if (candidates.isEmpty) return null;

    // Anti-fatiga: si un prompt se descartó ≥2 veces hoy, moverlo al final.
    // Los que no se han descartado mantienen su orden de prioridad.
    candidates.sort((a, b) {
      final aDismissed = (dismissCountToday[a.prompt.id] ?? 0) >= 2;
      final bDismissed = (dismissCountToday[b.prompt.id] ?? 0) >= 2;
      if (aDismissed && !bDismissed) return 1;
      if (!aDismissed && bDismissed) return -1;
      return 0; // mantener orden de prioridad base
    });

    return candidates.first;
  }
}
