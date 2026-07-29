// SPEC-257 Eje A: elegibilidad médica del protocolo de ayuno.
//
// Fuente única de verdad de qué protocolo puede alcanzar un usuario,
// derivada de datos que UserModel YA captura — no se agregan campos
// nuevos. UserModel es @freezed (build_runner) y este sandbox no puede
// regenerar `.freezed.dart`/`.g.dart` de forma segura, así que las
// condiciones nuevas que Fung marca como contraindicación (embarazo,
// trastorno alimentario, diabetes medicada, supervisión médica activa)
// viven como strings nuevos dentro de `pathologies` — el mismo campo
// `List<String>` que el onboarding ya captura y que antes no hacía nada
// (ver SPEC-257 §1, "gap más importante").
//
// Marco normativo: specs/SPEC-257-clasificacion-protocolo-ayuno.md §4 Eje A.

import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Valores nuevos de `pathologies` introducidos por SPEC-257. Se agregan
/// a las opciones del multi-select de onboarding (`_pathologyOptions` en
/// `onboarding_screen.dart`) — este archivo solo los referencia para el
/// gate de elegibilidad.
class FastingPathologyFlags {
  FastingPathologyFlags._();

  static const String embarazoLactancia = 'Embarazo o lactancia';
  static const String trastornoAlimentario = 'Trastorno alimentario';
  static const String diabetesMedicada =
      'Diabetes con insulina o sulfonilureas';
  static const String supervisionMedicaActiva =
      'Bajo supervisión médica para ayuno prolongado';
}

/// Resultado del gate de elegibilidad: el protocolo más largo que el
/// usuario puede seleccionar hoy, y por qué.
class FastingEligibility {
  /// Protocolo tope permitido. Uno de [ladder].
  final String maxProtocol;

  /// true si `maxProtocol == 'Ninguno'` — el ayuno queda bloqueado del todo.
  final bool blocked;

  /// true si el usuario declaró supervisión médica activa
  /// ([FastingPathologyFlags.supervisionMedicaActiva]) — es lo único que
  /// desbloquea OMAD.
  final bool hasMedicalSupervision;

  /// Motivo legible del tope. `null` cuando no hay restricción de Eje A
  /// más allá del techo por defecto (22:2 sin supervisión médica).
  final String? reason;

  const FastingEligibility({
    required this.maxProtocol,
    required this.blocked,
    required this.hasMedicalSupervision,
    this.reason,
  });

  /// Orden canónico de protocolos, de menor a mayor duración/exigencia.
  /// Única fuente de verdad del orden — reutilizada por Eje A (este
  /// archivo) y Eje B (`AdaptiveEngine`).
  static const List<String> ladder = [
    'Ninguno',
    '12:12',
    '14:10',
    '16:8',
    '18:6',
    '20:4',
    '22:2',
    'OMAD',
  ];

  // RF-257-VERIFICACION fix: un protocolo fuera de `ladder` caía a rank
  // 0 (el mismo que 'Ninguno'), así que `allows()` lo dejaba pasar SIEMPRE
  // (rank 0 <= cualquier maxProtocol) — justo lo contrario de lo que
  // `clamp()` promete en su doc ("cae a maxProtocol, conservador"). Un
  // string corrupto o legacy no reconocido quedaba sin recortar. Ahora
  // rank desconocido = `ladder.length` (mayor que cualquier índice real),
  // así que un protocolo no reconocido nunca pasa `allows()` y `clamp()`
  // sí cae al tope.
  static int _rank(String protocol) {
    final i = ladder.indexOf(protocol);
    return i == -1 ? ladder.length : i;
  }

  /// true si [protocol] está permitido bajo este gate.
  bool allows(String protocol) => _rank(protocol) <= _rank(maxProtocol);

  /// Recorta [desired] al máximo permitido por este gate. Si [desired]
  /// no es un protocolo reconocido, cae a `maxProtocol` (conservador).
  String clamp(String desired) => allows(desired) ? desired : maxProtocol;

  static double _imc(UserModel user) {
    if (user.height <= 0) return 0.0;
    final hMeters = user.height / 100;
    return user.weight / (hMeters * hMeters);
  }

  /// Qué le va a pasar al protocolo de ayuno si el usuario declara
  /// [flag]. `null` si esa condición no afecta al ayuno.
  ///
  /// Existe para poder AVISAR en el momento de declarar, no después.
  /// Verificado en Simulador (28-jul-2026): al declarar embarazo en el
  /// cribado, el usuario seguía viendo "Ayuno 16:8" durante el resto del
  /// onboarding y solo al terminar se encontraba el ayuno bloqueado, sin
  /// que nadie le hubiera explicado por qué. El recorte lo hace
  /// [clamp] justo antes de guardar (ver `_applyFastingEligibility` en
  /// onboarding_screen), y eso no se puede adelantar porque el protocolo
  /// se elige en un paso anterior al cribado — pero sí se puede avisar.
  ///
  /// Vive junto a `assess()` a propósito: si cambian las reglas de
  /// arriba, el aviso está a la vista y no se queda desactualizado en
  /// otro archivo.
  static String? efectoSobreElAyuno(String flag) => switch (flag) {
        FastingPathologyFlags.embarazoLactancia =>
          'el ayuno queda desactivado mientras dure',
        FastingPathologyFlags.trastornoAlimentario =>
          'el ayuno queda desactivado hasta que lo evalúe un profesional '
              'de salud mental',
        FastingPathologyFlags.diabetesMedicada =>
          'tu protocolo se limita a 14/10 hasta que ajustes la medicación '
              'con tu médico',
        _ => null,
      };

  /// SPEC-257 §4 Eje A — evalúa las contraindicaciones ya citadas en el
  /// spec (Fung: menores, embarazo/lactancia, trastorno alimentario,
  /// IMC<18.5, IMC 18.5–20, diabetes medicada con insulina/sulfonilureas).
  /// Reglas en orden de severidad — la primera que aplica define el tope;
  /// no hace falta combinarlas porque están ordenadas de más a menos
  /// restrictivas.
  factory FastingEligibility.assess(UserModel user) {
    final pathologies = user.pathologies;
    bool has(String flag) => pathologies.contains(flag);
    final hasMedicalSupervision =
        has(FastingPathologyFlags.supervisionMedicaActiva);

    // 1. Menor de edad — bloqueo total, sin excepción de supervisión.
    if (user.age < 18) {
      return const FastingEligibility(
        maxProtocol: 'Ninguno',
        blocked: true,
        hasMedicalSupervision: false,
        reason: 'El ayuno intermitente no está diseñado para menores de edad.',
      );
    }

    // 2. Embarazo / lactancia — bloqueo total.
    if (has(FastingPathologyFlags.embarazoLactancia)) {
      return const FastingEligibility(
        maxProtocol: 'Ninguno',
        blocked: true,
        hasMedicalSupervision: false,
        reason:
            'Durante el embarazo o la lactancia el ayuno intermitente no es recomendable.',
      );
    }

    // 3. Trastorno alimentario declarado — bloqueo total.
    if (has(FastingPathologyFlags.trastornoAlimentario)) {
      return const FastingEligibility(
        maxProtocol: 'Ninguno',
        blocked: true,
        hasMedicalSupervision: false,
        reason:
            'Con un trastorno alimentario declarado, el ayuno debe evaluarlo primero un profesional de salud mental.',
      );
    }

    // 4. IMC < 18.5 — bajo peso, bloqueo total.
    final imc = _imc(user);
    if (imc > 0 && imc < 18.5) {
      return const FastingEligibility(
        maxProtocol: 'Ninguno',
        blocked: true,
        hasMedicalSupervision: false,
        reason:
            'Tu IMC está por debajo de 18.5 — el ayuno no es seguro en bajo peso.',
      );
    }

    // 5. IMC 18.5–20 — margen de seguridad, tope 20:4 (ningún protocolo
    // de este catálogo alcanza el ayuno continuo >24h que Fung marca como
    // límite duro; 20:4 es el techo conservador antes de esa zona).
    if (imc > 0 && imc < 20.0) {
      return const FastingEligibility(
        maxProtocol: '20:4',
        blocked: false,
        hasMedicalSupervision: false,
        reason:
            'Con IMC entre 18.5 y 20 mantenemos un margen de seguridad: no sugerimos ventanas más largas que 20:4.',
      );
    }

    // 6. Diabetes medicada con insulina o sulfonilureas — riesgo real de
    // hipoglucemia severa. Tope 14:10 salvo supervisión médica activa
    // (que implica ajuste de dosis ya conversado con su médico).
    if (has(FastingPathologyFlags.diabetesMedicada) && !hasMedicalSupervision) {
      return const FastingEligibility(
        maxProtocol: '14:10',
        blocked: false,
        hasMedicalSupervision: false,
        reason:
            'Con medicación para la diabetes (insulina o sulfonilureas), extender el ayuno requiere ajustar la dosis con tu médico antes de avanzar.',
      );
    }

    // 7. Supervisión médica activa declarada — desbloquea el catálogo
    // completo, incluido OMAD.
    if (hasMedicalSupervision) {
      return const FastingEligibility(
        maxProtocol: 'OMAD',
        blocked: false,
        hasMedicalSupervision: true,
      );
    }

    // 8. Sin contraindicaciones: techo por defecto en 22:2. OMAD queda
    // reservado a la regla 7 — coherente con la propia descripción que
    // `ProtocolSelectorSheet` ya le da ("protocolo extremo, solo con
    // supervisión médica activa"), que hasta ahora era copy sin gate real.
    return const FastingEligibility(
      maxProtocol: '22:2',
      blocked: false,
      hasMedicalSupervision: false,
    );
  }
}
