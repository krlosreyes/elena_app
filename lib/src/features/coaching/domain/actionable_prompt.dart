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
