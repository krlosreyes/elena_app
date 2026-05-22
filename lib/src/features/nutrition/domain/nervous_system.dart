// SPEC-137: clasificación del sistema nervioso del usuario.
//
// Concepto operacional de Frank Suárez (NUTRITION_BIBLIOGRAPHY.md §5):
// el dominio autonómico Pasivo (parasimpático) o Excitado (simpático)
// determina qué proporción A:E sugerimos y qué protocolo de ayuno
// recomendamos al onboarding.
//
// IMPORTANTE: este NO es un diagnóstico clínico. La app NO afirma que
// el usuario "es" pasivo o excitado a nivel fisiológico — afirma que
// una recomendación específica le sirve mejor. El copy es blando
// (NUTRITION_BIBLIOGRAPHY.md §5.4).
//
// El usuario lo captura en el onboarding Paso 3.A con 5 preguntas
// (SPEC-137 §RF-137-08.A). Mecánica de scoring en §RF-137-08.B.

import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';

/// Clasificación del tono autonómico del usuario.
///
/// Tres valores:
/// - [passive]: parasimpático dominante. Metabolismo lento, apetito
///   matutino, tolera carnes rojas. Default seguro.
/// - [excited]: simpático dominante. Tensión baseline, sueño superficial,
///   prefiere proteínas blancas. Tolera mejor 16:8 que 20:4.
/// - [unknown]: el usuario respondió "no sé" en ≥ 3 preguntas o saltó el
///   sub-step. NO clasificamos con datos insuficientes.
enum NervousSystem {
  passive,
  excited,
  unknown;

  /// Proporción A:E sugerida por defecto para este perfil.
  ///
  /// Esta sugerencia alimenta:
  /// - La posición inicial del slider en `PlateRatioSheet`.
  /// - El tooltip bajo el Cociente A en la tarjeta de Hoy.
  ///
  /// Para [unknown] devolvemos el mismo default que [passive] porque
  /// 2x1 funciona para más perfiles (NUTRITION_BIBLIOGRAPHY §3.3).
  MealRatio get suggestedRatio => switch (this) {
        NervousSystem.passive => MealRatio.a2e1,
        NervousSystem.excited => MealRatio.a3e1,
        NervousSystem.unknown => MealRatio.a2e1,
      };

  /// Etiqueta corta y localizada para UI.
  ///
  /// Se usa en la tarjeta de contexto del onboarding 3.B
  /// (§RF-137-08.C) y en el Perfil del usuario.
  String get label => switch (this) {
        NervousSystem.passive => 'Pasivo',
        NervousSystem.excited => 'Excitado',
        NervousSystem.unknown => 'Por conocer',
      };

  /// Clave estable para persistencia en Firestore.
  String get persistenceKey => switch (this) {
        NervousSystem.passive => 'passive',
        NervousSystem.excited => 'excited',
        NervousSystem.unknown => 'unknown',
      };

  /// Parsea desde el string persistido en Firestore.
  ///
  /// Para null / vacío / clave desconocida cae a [NervousSystem.unknown]
  /// (más conservador que [passive]: deja claro al sistema que aún no
  /// hay data del usuario y dispara el banner de "responder después"
  /// en el Dashboard según §RF-137-08.E).
  static NervousSystem fromPersistenceKey(String? key) {
    return switch (key) {
      'passive' => NervousSystem.passive,
      'excited' => NervousSystem.excited,
      'unknown' => NervousSystem.unknown,
      _ => NervousSystem.unknown,
    };
  }
}

/// Respuesta a una de las 5 preguntas del onboarding 3.A.
///
/// Cada pregunta tiene tres opciones: una clasifica al usuario como
/// Pasivo, otra como Excitado, y "no sé" no clasifica (devuelve null).
/// Ver §RF-137-08.A para el copy exacto.
enum NervousSystemAnswer {
  /// La opción que sugiere perfil Pasivo (parasimpático).
  classifiesAsPassive,

  /// La opción que sugiere perfil Excitado (simpático).
  classifiesAsExcited,

  /// "No sé / depende / no aplica" — no clasifica.
  unknown;

  /// El enum [NervousSystem] que esta respuesta puntúa, o null si no
  /// clasifica. Útil para el agregador en `nervousSystemScore`.
  NervousSystem? get classifies => switch (this) {
        NervousSystemAnswer.classifiesAsPassive => NervousSystem.passive,
        NervousSystemAnswer.classifiesAsExcited => NervousSystem.excited,
        NervousSystemAnswer.unknown => null,
      };
}

/// Resultado agregado de las 5 preguntas del onboarding 3.A.
///
/// Persiste en `users/{uid}.nervousSystemScore` para futura recalibración
/// (§RF-137-08.F). El campo principal `nervousSystem` se deriva de aquí.
class NervousSystemScore {
  /// Conteo de respuestas que clasifican como Pasivo (0-5).
  final int passive;

  /// Conteo de respuestas que clasifican como Excitado (0-5).
  final int excited;

  /// Conteo de respuestas "no sé" (0-5).
  final int unknown;

  const NervousSystemScore({
    required this.passive,
    required this.excited,
    required this.unknown,
  });

  /// Total de respuestas. Debe ser 5 en un onboarding completo.
  int get totalAnswered => passive + excited + unknown;

  /// El [NervousSystem] resultante según la mecánica de §RF-137-08.B.
  ///
  /// Reglas en orden de prioridad:
  /// 1. Si "no sé" ≥ 3 → [NervousSystem.unknown]. No clasificamos con
  ///    datos insuficientes.
  /// 2. Si excitado ≥ 3 → [NervousSystem.excited].
  /// 3. Cualquier otro caso → [NervousSystem.passive] (default seguro
  ///    porque más perfiles toleran el 2x1).
  NervousSystem classify() {
    if (unknown >= 3) return NervousSystem.unknown;
    if (excited >= 3) return NervousSystem.excited;
    return NervousSystem.passive;
  }

  /// Construye un [NervousSystemScore] desde una lista de respuestas.
  ///
  /// Tipicamente la lista tiene 5 elementos (las 5 preguntas), pero
  /// acepta cualquier cantidad — útil para tests y para el flujo de
  /// "skip" donde se pueden tener < 5 respuestas.
  factory NervousSystemScore.fromAnswers(List<NervousSystemAnswer> answers) {
    var passive = 0;
    var excited = 0;
    var unknown = 0;
    for (final a in answers) {
      switch (a) {
        case NervousSystemAnswer.classifiesAsPassive:
          passive++;
        case NervousSystemAnswer.classifiesAsExcited:
          excited++;
        case NervousSystemAnswer.unknown:
          unknown++;
      }
    }
    return NervousSystemScore(
      passive: passive,
      excited: excited,
      unknown: unknown,
    );
  }

  /// Serializa para persistencia en Firestore (campo
  /// `nervousSystemScore`).
  Map<String, int> toMap() => {
        'passive': passive,
        'excited': excited,
        'unknown': unknown,
      };

  /// Parsea desde el mapa persistido. Cualquier campo faltante se
  /// asume 0 (logs de usuarios pre-SPEC-137).
  factory NervousSystemScore.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const NervousSystemScore(passive: 0, excited: 0, unknown: 0);
    }
    return NervousSystemScore(
      passive: _toInt(map['passive']) ?? 0,
      excited: _toInt(map['excited']) ?? 0,
      unknown: _toInt(map['unknown']) ?? 0,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is NervousSystemScore &&
      other.passive == passive &&
      other.excited == excited &&
      other.unknown == unknown;

  @override
  int get hashCode => Object.hash(passive, excited, unknown);

  @override
  String toString() =>
      'NervousSystemScore(passive: $passive, excited: $excited, unknown: $unknown)';
}
