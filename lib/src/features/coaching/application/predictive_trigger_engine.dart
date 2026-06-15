// SPEC-199 Fase A (RF-199-05) — motor predictivo de prompts.
//
// Decide CONTEXTUALMENTE si mostrar un prompt accionable, en vez de a hora
// fija. Función PURA (sin providers, sin I/O) → testeable directo. La misma
// lógica de supresión alimenta la tarjeta in-app (RF-04) y, a futuro, la
// supresión de notificaciones.
//
// Regla de hidratación: NO molestar si ya cumplió la meta, si está fuera de
// la ventana de vigilia (respeta sueño + cutoff de reparación 21h, alineado
// con SPEC-70.5 / SPEC-150), o si tomó agua hace muy poco.

import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';

class PredictiveTriggerEngine {
  PredictiveTriggerEngine._();

  /// Cutoff de reparación: no proponer hidratación pasada esta hora aunque el
  /// usuario duerma más tarde (alineado con SPEC-70.5).
  static const int kRepairCutoffHour = 21;

  /// Gap mínimo desde el último vaso para volver a proponer.
  static const Duration kMinGapBetweenPrompts = Duration(minutes: 60);

  /// Devuelve el prompt de hidratación a mostrar, o `null` si se debe SUPRIMIR.
  static ActionablePrompt? hydrationPrompt({
    required bool goalReached,
    required DateTime now,
    required Duration? sinceLastGlass,
    required int wakeHour,
    required int sleepHour,
    Duration minGap = kMinGapBetweenPrompts,
  }) {
    // 1. Meta cumplida → no molestar.
    if (goalReached) return null;

    // 2. Fuera de la ventana de vigilia (antes de despertar o tras el cutoff).
    final cutoff = sleepHour < kRepairCutoffHour ? sleepHour : kRepairCutoffHour;
    if (now.hour < wakeHour || now.hour >= cutoff) return null;

    // 3. Tomó agua hace muy poco → dar espacio.
    if (sinceLastGlass != null && sinceLastGlass < minGap) return null;

    final bucket = '${now.year}'
        '${_two(now.month)}${_two(now.day)}${_two(now.hour)}';
    return ActionablePrompt(
      id: 'hydration_$bucket',
      title: 'Momento de hidratarte',
      message: 'Un vaso ahora mantiene tu energía estable. ¿Lo tomamos?',
      options: const [
        PromptOption(
          label: 'Sí, lo registro',
          action: PromptActionType.logWater,
          isPrimary: true,
        ),
        PromptOption(
          label: 'Ahora no',
          action: PromptActionType.snooze,
        ),
      ],
    );
  }

  // ── SPEC-224: prompts de los otros 3 pilares ────────────────────────────────

  /// Prompt de ayuno accionable: aparece cuando el protocolo está completado
  /// o a punto de completarse (decision del caller). Devuelve `null` si el
  /// ayuno ya está cerrado o no está activo.
  static ActionablePrompt? fastingPrompt({
    required bool fastingActive,
    required bool protocolReached,
    required DateTime now,
  }) {
    if (!fastingActive || !protocolReached) return null;

    final bucket = '${now.year}'
        '${_two(now.month)}${_two(now.day)}${_two(now.hour)}';
    return ActionablePrompt(
      id: 'fasting_close_$bucket',
      title: '¡Protocolo completado! 🎉',
      message: 'Alcanzaste tu meta de ayuno. ¿Lo cerramos y abrimos la ventana de alimentación?',
      options: const [
        PromptOption(
          label: 'Cerrar ayuno',
          action: PromptActionType.closeFasting,
          isPrimary: true,
        ),
        PromptOption(
          label: 'Continuar un poco más',
          action: PromptActionType.snooze,
        ),
      ],
    );
  }

  /// Prompt de ejercicio: se suprime si ya cumplió la meta del día o si está
  /// fuera de la ventana circadiana óptima de actividad física (15-17h).
  static ActionablePrompt? exercisePrompt({
    required bool goalReached,
    required DateTime now,
    /// Hora mínima para proponer ejercicio (default: 6h, tras despertar).
    int wakeHour = 6,
    /// Hora de corte — no molestar después de esta hora.
    int cutoffHour = 20,
  }) {
    if (goalReached) return null;
    if (now.hour < wakeHour || now.hour >= cutoffHour) return null;

    final bucket = '${now.year}'
        '${_two(now.month)}${_two(now.day)}${_two(now.hour)}';
    return ActionablePrompt(
      id: 'exercise_$bucket',
      title: 'Momento de moverte 💪',
      message: '30 minutos de actividad moderada hoy marcan la diferencia. ¿Ya lo hiciste?',
      options: const [
        PromptOption(
          label: 'Sí, lo registro',
          action: PromptActionType.logExercise,
          isPrimary: true,
        ),
        PromptOption(
          label: 'Luego lo hago',
          action: PromptActionType.snooze,
        ),
      ],
    );
  }

  /// Prompt de nutrición: se suprime si la ventana de alimentación aún no
  /// abrió, si ya cerró, o si comió recientemente.
  static ActionablePrompt? nutritionPrompt({
    required bool windowOpen,
    required DateTime now,
    /// Tiempo desde la última comida; null = nunca ha comido hoy.
    required Duration? sinceLastMeal,
    /// Gap mínimo para no molestar si comió hace poco (default: 2h).
    Duration minGap = const Duration(hours: 2),
  }) {
    if (!windowOpen) return null;
    if (sinceLastMeal != null && sinceLastMeal < minGap) return null;

    final bucket = '${now.year}'
        '${_two(now.month)}${_two(now.day)}${_two(now.hour)}';
    return ActionablePrompt(
      id: 'nutrition_$bucket',
      title: 'Tu ventana está abierta 🍽',
      message: 'Es buen momento para tu próxima comida. ¿Ya comiste?',
      options: const [
        PromptOption(
          label: 'Registrar comida',
          action: PromptActionType.logMeal,
          isPrimary: true,
        ),
        PromptOption(
          label: 'Aún no',
          action: PromptActionType.snooze,
        ),
      ],
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
