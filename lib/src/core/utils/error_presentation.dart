// Fix P0 (validación de ejecución real, 23-jul-2026): las pantallas de
// auth mostraban `err.toString()` directamente en el SnackBar de error.
// El repositorio (firebase_auth_repository.dart) siempre lanza
// `Exception('mensaje amigable en español')`, pero el `toString()` por
// defecto de la clase `Exception` de Dart antepone el prefijo
// "Exception: ", así que el usuario final veía literalmente
// "Exception: Credenciales incorrectas." en pantalla.
//
// Este helper centraliza la conversión de un error crudo a un mensaje
// presentable, para no repetir la lógica de "quitar el prefijo" en cada
// pantalla y para que cualquier error futuro (no solo de auth) que se
// muestre al usuario pase por el mismo punto único.

/// Convierte un error crudo (típicamente una `Exception` lanzada por un
/// repositorio) en un mensaje apto para mostrar al usuario final.
///
/// - Si el error es una `Exception` con mensaje, se retorna solo el
///   mensaje, sin el prefijo técnico "Exception: ".
/// - Si el resultado queda vacío o irreconocible, se retorna un mensaje
///   neutro en vez de arriesgarse a mostrar texto técnico sin traducir.
String presentableError(Object error) {
  final raw = error.toString();
  const exceptionPrefix = 'Exception: ';

  final withoutPrefix =
      raw.startsWith(exceptionPrefix) ? raw.substring(exceptionPrefix.length) : raw;

  final trimmed = withoutPrefix.trim();
  if (trimmed.isEmpty) {
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
  return trimmed;
}
