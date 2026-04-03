// ─────────────────────────────────────────────────────────────────────────────
// EMPTY PREFERENCES ERROR — Signals the user hasn't selected enough foods
// ─────────────────────────────────────────────────────────────────────────────

class EmptyPreferencesError implements Exception {
  final String message;

  const EmptyPreferencesError([
    this.message = 'No has seleccionado suficientes alimentos. '
        'Completa tus preferencias para generar tu minuta personalizada.',
  ]);

  @override
  String toString() => 'EmptyPreferencesError: $message';
}
