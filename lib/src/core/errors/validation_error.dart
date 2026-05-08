// SPEC-62: ValidationError tipado.
//
// Antes: las validaciones de modelos lanzaban `FormatException` con
// mensajes string. Caller que quería distinguir "valor fuera de rango"
// de "campo vacío" tenía que hacer `if (e.message.contains('inválido'))`
// — frágil, no localizable, rompe silenciosamente al cambiar el mensaje.
//
// Ahora: jerarquía sellada. Cada caso es una clase concreta con sus
// campos. Los callers hacen pattern matching exhaustivo (el compilador
// les exige cubrir todos los casos vía `switch` sobre la sealed). La UI
// puede mapear cada caso a un mensaje localizable sin parsear strings.
//
// `ValidationError` implementa `Exception` para que cualquier `try/catch`
// existente lo siga capturando. NO extiende `FormatException` — es un
// tipo nuevo. Si algún caller quiere ambos, debe atrapar `Exception`
// genéricamente o las dos jerarquías por separado.

/// Error de validación de invariante de un modelo.
///
/// Sealed: cualquier `switch` sobre instancias debe cubrir todos los
/// casos. Esa exhaustividad es el punto de la migración — al añadir un
/// caso nuevo, todos los call sites de pattern matching avisan.
sealed class ValidationError implements Exception {
  /// Nombre del campo que falló la validación. Usado para mensajes y
  /// para que la UI pueda enfocar el input correspondiente.
  final String fieldName;

  const ValidationError(this.fieldName);

  /// Mensaje por defecto en español. La UI puede ignorarlo y construir
  /// su propio mensaje localizable a partir de los campos tipados.
  String get defaultMessage;

  @override
  String toString() => 'ValidationError($fieldName): $defaultMessage';
}

/// Un valor numérico requerido como `>= 0` resultó negativo.
///
/// Caso muy común — la mayoría de campos cuantitativos (calorías,
/// macros, latencia, despertares) lo usan. Por eso recibe su clase
/// dedicada en lugar de instanciar [OutOfRange] con `min: 0, max: ∞`.
class NegativeValue extends ValidationError {
  final num value;

  const NegativeValue({
    required String field,
    required this.value,
  }) : super(field);

  @override
  String get defaultMessage =>
      '$fieldName inválido: $value. Debe ser >= 0.';
}

/// Un valor numérico cayó fuera de un rango cerrado [min, max].
///
/// Ejemplos: `subjectiveQuality` debe estar en [1, 5], `glycemicIndex`
/// en [0, 100].
class OutOfRange extends ValidationError {
  final num value;
  final num min;
  final num max;

  const OutOfRange({
    required String field,
    required this.value,
    required this.min,
    required this.max,
  }) : super(field);

  @override
  String get defaultMessage =>
      '$fieldName inválido: $value. Debe estar en [$min, $max].';
}

/// Un campo string requerido vino vacío o solo con whitespace.
class EmptyField extends ValidationError {
  const EmptyField({required String field}) : super(field);

  @override
  String get defaultMessage => '$fieldName no puede estar vacío.';
}

/// Un valor no está en el conjunto esperado (enum-like).
///
/// Ejemplo: `label` debe ser uno de "Desayuno", "Almuerzo", "Cena",
/// "Snack". Si llega "Brunch", se lanza este error con
/// `expectedOneOf: ["Desayuno", "Almuerzo", "Cena", "Snack"]`.
class InvalidValue extends ValidationError {
  final Object value;
  final List<Object>? expectedOneOf;

  const InvalidValue({
    required String field,
    required this.value,
    this.expectedOneOf,
  }) : super(field);

  @override
  String get defaultMessage {
    final base = '$fieldName inválido: "$value".';
    if (expectedOneOf == null || expectedOneOf!.isEmpty) return base;
    return '$base Esperado uno de: ${expectedOneOf!.join(", ")}.';
  }
}

/// Un timestamp llegó más adelantado del presente que la tolerancia
/// permitida (típicamente para detectar relojes desincronizados o datos
/// sintéticos del futuro).
class FutureTimestamp extends ValidationError {
  final DateTime value;
  final Duration toleranceFromNow;

  const FutureTimestamp({
    required String field,
    required this.value,
    required this.toleranceFromNow,
  }) : super(field);

  @override
  String get defaultMessage =>
      '$fieldName ${value.toIso8601String()} está más de '
      '${toleranceFromNow.inSeconds}s en el futuro.';
}
