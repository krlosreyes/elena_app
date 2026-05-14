// SPEC-80: scrubber puro de PII para mensajes que van a Crashlytics.
//
// Reemplaza patrones reconocibles (emails, UIDs de Firebase Auth,
// bearer tokens) con placeholders antes de enviar al backend de
// observabilidad. Sin estado, sin dependencias — testeable como
// función pura.

class PiiScrubber {
  PiiScrubber._();

  /// Reemplaza patrones reconocibles de PII por placeholders.
  /// Si el input es null o vacío, retorna sin cambios.
  static String scrub(String input) {
    if (input.isEmpty) return input;

    var result = input;

    // Bearer tokens: detectar primero (más específico que UIDs sueltos).
    result = result.replaceAllMapped(
      _bearerTokenPattern,
      (_) => 'Bearer [REDACTED_TOKEN]',
    );

    // Emails: detectar antes de UIDs porque pueden contener
    // alfanuméricos que el patrón de UID matchearia parcialmente.
    result = result.replaceAll(_emailPattern, '[REDACTED_EMAIL]');

    // Firebase Auth UIDs: 28 caracteres alfanuméricos.
    // Aplicamos con boundary explícito para evitar matchear words
    // genéricas que casualmente midan 28 chars.
    result = result.replaceAllMapped(
      _firebaseUidPattern,
      (_) => '[REDACTED_UID]',
    );

    return result;
  }

  // ── Patrones ──────────────────────────────────────────────────────

  // Email "estándar" (RFC simplificado, suficiente para scrubbing).
  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  // Firebase Auth UID: 28 chars alfanuméricos. Boundary previene
  // matchear substrings dentro de hashes más largos.
  static final RegExp _firebaseUidPattern = RegExp(
    r'\b[a-zA-Z0-9]{28}\b',
  );

  // Bearer tokens en headers (Authorization: Bearer xxx) o pegados
  // en mensajes de error.
  static final RegExp _bearerTokenPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9._\-]+',
  );
}
