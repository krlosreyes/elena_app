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

  static String _two(int n) => n.toString().padLeft(2, '0');
}
