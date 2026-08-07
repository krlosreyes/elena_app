// SPEC-270 — Cálculo del objetivo proteico diario (regla 2 del método).
//
// El Milagro Metabólico (Jaramillo, 2019, cap. 10) fija dos reglas:
//   1. La proteína se calcula sobre el PESO IDEAL, no el peso actual.
//   2. El aporte es 0.8-1.0 g/kg para actividad moderada, y hasta 1.5 g/kg
//      para entrenamiento frecuente (rechaza los 3 g/kg de algunos autores).
//
// Este servicio es PURO (sin Riverpod, sin Flutter, sin I/O) — mismo
// criterio que MealTargetService y CocienteAService. Lee sus insumos del
// UserModel ya capturado en el onboarding (height, gender, activityLevel);
// NO pide datos biométricos nuevos (ver specs/SPEC-270-*.md §3).
//
// Peso ideal: fórmula de Devine (Devine BJ, Drug Intell Clin Pharm 1974) —
// el estándar clínico de "ideal body weight" a partir de estatura + sexo:
//   hombre : 50.0 kg + 2.3 kg por pulgada sobre 5 pies (152.4 cm)
//   mujer  : 45.5 kg + 2.3 kg por pulgada sobre 5 pies
// Se eligió Devine porque reproduce muy de cerca los ejemplos del libro
// (hombre 1.85 m → 79.5 kg ≈ "80"; mujer 1.60 m → 52.4 kg ≈ "55", ambos
// "más o menos" en palabras del autor) y es una referencia citable, a
// diferencia de un IMC-objetivo elegido a mano. Los tests anclan estos
// valores (protein_target_service_test.dart).

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

/// Nivel de actividad para el factor proteico (g/kg). Se deriva del
/// `activityLevel` (PAL) del UserModel, no se pregunta aparte.
enum ProteinActivity {
  /// Vida sedentaria / trabajo de oficina. 0.8 g/kg (piso del libro).
  sedentary,

  /// Actividad moderada (se ejercita de vez en cuando). 1.0 g/kg.
  moderate,

  /// Entrenamiento frecuente y activo. 1.5 g/kg (techo del libro).
  active;

  /// Gramos de proteína por kg de peso ideal (El Milagro Metabólico c.10).
  double get gramsPerKg => switch (this) {
        ProteinActivity.sedentary => 0.8,
        ProteinActivity.moderate => 1.0,
        ProteinActivity.active => 1.5,
      };
}

class ProteinTargetService {
  const ProteinTargetService();

  static const double _kgPerInchOver5ft = 2.3;
  static const double _maleBaseKg = 50.0;
  static const double _femaleBaseKg = 45.5;
  static const double _cmPer5ft = 152.4; // 5 pies
  static const double _cmPerInch = 2.54;

  /// Peso ideal en kg (Devine) desde estatura (cm) y sexo.
  ///
  /// [gender] es tolerante: 'M'/'male'/'masculino'/'hombre' → hombre;
  /// 'F'/'female'/'femenino'/'mujer' → mujer; desconocido → promedio de
  /// ambas bases (fallar suave, nunca lanzar). Estaturas por debajo de
  /// 5 pies no restan (se clampa a la base) — Devine no está definida
  /// hacia abajo y un peso ideal negativo no tiene sentido.
  double idealWeightKg({required double heightCm, required String gender}) {
    final base = _baseForGender(gender);
    final inchesOver5ft = (heightCm - _cmPer5ft) / _cmPerInch;
    if (inchesOver5ft <= 0) return base;
    return base + _kgPerInchOver5ft * inchesOver5ft;
  }

  double _baseForGender(String gender) {
    final g = gender.trim().toLowerCase();
    const male = {'m', 'male', 'masculino', 'hombre', 'h'};
    const female = {'f', 'female', 'femenino', 'mujer'};
    if (male.contains(g)) return _maleBaseKg;
    if (female.contains(g)) return _femaleBaseKg;
    // Desconocido / no-binario / vacío: promedio de ambas bases.
    return (_maleBaseKg + _femaleBaseKg) / 2;
  }

  /// Mapea el PAL (`UserModel.activityLevel`, default 1.2) al nivel
  /// proteico. Umbrales convencionales del PAL:
  ///   < 1.40  sedentario · 1.40-1.60 moderado · > 1.60 activo.
  ProteinActivity activityFromPal(double pal) {
    if (pal < 1.4) return ProteinActivity.sedentary;
    if (pal <= 1.6) return ProteinActivity.moderate;
    return ProteinActivity.active;
  }

  /// Objetivo proteico diario en gramos (peso ideal × factor g/kg).
  double targetProteinG({
    required double heightCm,
    required String gender,
    required double pal,
  }) {
    final ideal = idealWeightKg(heightCm: heightCm, gender: gender);
    return ideal * activityFromPal(pal).gramsPerKg;
  }

  /// Objetivo proteico redondeado al gramo (para copy/UI).
  int targetProteinGRounded({
    required double heightCm,
    required String gender,
    required double pal,
  }) =>
      targetProteinG(heightCm: heightCm, gender: gender, pal: pal).round();

  /// Construye el bloque `DerivedTargets` del intake a partir de la
  /// biometría y (opcionalmente) la ventana circadiana ya formateada.
  /// La ventana se pasa como "HH:mm" desde el CircadianProfile del
  /// UserModel — este servicio no la calcula, solo la empaqueta.
  DerivedTargets deriveTargets({
    required double heightCm,
    required String gender,
    required double pal,
    String windowFirst = '',
    String windowLast = '',
  }) {
    return DerivedTargets(
      idealWeightKg: idealWeightKg(heightCm: heightCm, gender: gender),
      targetProteinG:
          targetProteinG(heightCm: heightCm, gender: gender, pal: pal),
      windowFirst: windowFirst,
      windowLast: windowLast,
    );
  }
}
