// SPEC-137: inferencia del target de comidas según protocolo de ayuno.
//
// El usuario NO responde "¿cuántas comidas al día?" en el onboarding —
// se infiere del protocolo de ayuno + ventana circadiana, porque un
// protocolo 20:4 (ventana de 4h) no admite físicamente 3 comidas, y
// un protocolo "Ninguno" (sin TRF) sí soporta 3 + snack.
//
// Tabla canónica en SPEC-137 §RF-137-03 y NUTRITION_BIBLIOGRAPHY.md §7.1.
//
// IMPORTANTE: el target sirve para COPY informativo (ej. "Llevas 1 de 2
// comidas sugeridas") — NO penaliza la falta de registro. Si el usuario
// registra menos comidas que el target, el cálculo del Cociente A sigue
// operando sobre los logs registrados (ver cociente_a_service.dart).

/// Resultado de la inferencia: target de comidas + si admite snack
/// opcional entre comidas.
class MealTarget {
  /// Número de comidas principales sugeridas para el día.
  final int meals;

  /// True si el protocolo deja espacio para un snack opcional A-dominante
  /// entre comidas (frutos secos, almendras, palta, etc.).
  final bool allowsSnack;

  const MealTarget({
    required this.meals,
    required this.allowsSnack,
  });

  @override
  bool operator ==(Object other) =>
      other is MealTarget &&
      other.meals == meals &&
      other.allowsSnack == allowsSnack;

  @override
  int get hashCode => Object.hash(meals, allowsSnack);

  @override
  String toString() => 'MealTarget(meals: $meals, allowsSnack: $allowsSnack)';
}

/// Servicio puro (sin Riverpod, sin Flutter) que mapea el string del
/// protocolo de ayuno a un [MealTarget].
///
/// Acepta los 8 valores canónicos que el proyecto persiste en
/// `UserModel.fastingProtocol` (SPEC-98): "Ninguno", "12:12", "14:10",
/// "16:8", "18:6", "20:4", "22:2", "OMAD".
/// Cualquier otro string cae al fallback "Ninguno" (3 + snack).
class MealTargetService {
  const MealTargetService();

  /// Tabla canónica de §RF-137-03 / NUTRITION_BIBLIOGRAPHY.md §7.1.
  ///
  /// Regla operacional: el target decrece a medida que la ventana se
  /// comprime. Una ventana ≥ 12h soporta 3 comidas; entre 6h y 10h
  /// sostiene 2; ≤ 4h sostiene 1. El snack opcional se permite cuando
  /// el espaciado entre comidas principales es ≥ 4h (no fragmenta
  /// digestión).
  static const Map<String, MealTarget> _byProtocol = {
    'Ninguno': MealTarget(meals: 3, allowsSnack: true),
    '12:12': MealTarget(meals: 3, allowsSnack: true),
    '14:10': MealTarget(meals: 2, allowsSnack: true),
    '16:8': MealTarget(meals: 2, allowsSnack: true),
    '18:6': MealTarget(meals: 2, allowsSnack: false),
    '20:4': MealTarget(meals: 1, allowsSnack: false),
    '22:2': MealTarget(meals: 1, allowsSnack: false),
    'OMAD': MealTarget(meals: 1, allowsSnack: false),
  };

  /// Default seguro para protocolos desconocidos o vacíos. Coincide con
  /// "Ninguno" — 3 comidas + snack — porque es el comportamiento de un
  /// adulto sano sin TRF.
  static const MealTarget _fallback = MealTarget(meals: 3, allowsSnack: true);

  /// Infiere el [MealTarget] desde el string del protocolo.
  ///
  /// Si el protocolo no está en el conjunto canónico, retorna [_fallback]
  /// en lugar de lanzar — el `UserModel.fastingProtocol` ha sido escrito
  /// por múltiples versiones de la app y del sitio web MR, y queremos
  /// fallar suave en producción.
  MealTarget targetForProtocol(String? protocol) {
    if (protocol == null) return _fallback;
    return _byProtocol[protocol] ?? _fallback;
  }

  /// Devuelve el conjunto de protocolos conocidos. Útil para tests y
  /// para validar que el catálogo del producto está en sync con la SPEC.
  Iterable<String> get knownProtocols => _byProtocol.keys;
}
