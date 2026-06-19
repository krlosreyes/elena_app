// SPEC-199 Fase A (RF-199-04) — modelo de prompt accionable.
//
// Unidad común del coaching interactivo: una pregunta con opciones de un
// toque, cada una asociada a una acción real. Reemplaza el texto pasivo.
// Es agnóstico de superficie: lo consume la tarjeta in-app (RF-04) y, a
// futuro, las superficies ambientales (Fase B).

enum PromptActionType {
  /// Registra un vaso de agua (in-app: directo; notif: vía cola).
  logWater,

  /// Posponer: ocultar el prompt por ahora (in-app) / re-recordar (notif).
  snooze,

  // SPEC-224: acciones de los otros 3 pilares accionables.

  /// Cierra la ventana de ayuno en el momento actual.
  closeFasting,

  /// Registra una sesión de ejercicio (defaults del prompt).
  logExercise,

  /// Registra una comida simple (defaults seguros).
  logMeal,

  // SPEC-232: check-ins emocionales durante el ayuno.

  /// Registra cómo se siente el usuario durante un hito de ayuno.
  /// El label de la opción determina qué FastingFeeling se persiste.
  checkInFeeling,
}

class PromptOption {
  final String label;
  final PromptActionType action;

  /// La opción destacada (botón relleno). El resto van como texto/secundario.
  final bool isPrimary;

  const PromptOption({
    required this.label,
    required this.action,
    this.isPrimary = false,
  });
}

class ActionablePrompt {
  /// Id estable por contexto (incluye bucket de tiempo) para deduplicar y
  /// para que "posponer" oculte solo esta instancia.
  final String id;
  final String title;
  final String message;
  final List<PromptOption> options;

  const ActionablePrompt({
    required this.id,
    required this.title,
    required this.message,
    required this.options,
  });
}
