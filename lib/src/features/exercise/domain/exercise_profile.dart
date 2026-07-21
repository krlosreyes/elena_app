// Propuesta módulo Ejercicio (2026-07-21, ver
// documentacion/propuestas/Propuesta_Modulo_Ejercicio_2026-07-21.docx):
// perfil de hábitos y preferencias de ejercicio del usuario.
//
// Hoy el onboarding no captura NADA sobre la relación del usuario con
// el ejercicio (nivel, experiencia, equipo, preferencias, lesiones).
// Este perfil cierra ese vacío y alimenta a WeeklyExercisePlanEngine
// (junto con BodyZone + sistema nervioso Frank Suárez) para generar el
// plan semanal de 6 días.
//
// Clase plana (sin @freezed / json_serializable): este repo no tiene
// toolchain de codegen (build_runner) disponible en el entorno donde se
// escribió este archivo, así que se sigue el mismo patrón de clases
// inmutables con copyWith manual que ya usa GoalSuggestionEngine /
// GoalSuggestion (goals/application/goal_suggestion_engine.dart) — cero
// dependencia de código generado.

/// Frecuencia actual de ejercicio declarada por el usuario en onboarding.
enum ExerciseFrequencyLevel { sedentary, occasional, regular, advanced }

extension ExerciseFrequencyLevelLabel on ExerciseFrequencyLevel {
  String get label {
    switch (this) {
      case ExerciseFrequencyLevel.sedentary:
        return 'Sedentario';
      case ExerciseFrequencyLevel.occasional:
        return 'Ocasional (1-2x/semana)';
      case ExerciseFrequencyLevel.regular:
        return 'Regular (3-4x/semana)';
      case ExerciseFrequencyLevel.advanced:
        return 'Avanzado (5+/semana)';
    }
  }
}

/// Experiencia con entrenamiento de fuerza — determina cuán agresiva
/// puede ser la progresión que sugiere el plan (ACSM 2025/2026: los
/// principiantes no necesitan cargas pesadas desde el día uno).
enum ExerciseExperienceLevel {
  none,
  lessThan6Months,
  sixTo24Months,
  moreThan2Years,
}

extension ExerciseExperienceLevelLabel on ExerciseExperienceLevel {
  String get label {
    switch (this) {
      case ExerciseExperienceLevel.none:
        return 'Ninguna';
      case ExerciseExperienceLevel.lessThan6Months:
        return 'Menos de 6 meses';
      case ExerciseExperienceLevel.sixTo24Months:
        return '6-24 meses';
      case ExerciseExperienceLevel.moreThan2Years:
        return 'Más de 2 años';
    }
  }
}

/// Equipo disponible — condiciona qué tan literal puede ser la
/// sugerencia de "fuerza" (gimnasio completo vs. peso corporal).
enum ExerciseEquipment { fullGym, homeBasic, bodyweightOnly }

extension ExerciseEquipmentLabel on ExerciseEquipment {
  String get label {
    switch (this) {
      case ExerciseEquipment.fullGym:
        return 'Gimnasio completo';
      case ExerciseEquipment.homeBasic:
        return 'Mancuernas / banda en casa';
      case ExerciseEquipment.bodyweightOnly:
        return 'Solo peso corporal';
    }
  }
}

/// Preferencias/aversiones explícitas de actividad — insumo cualitativo,
/// no determina el split pero sí el copy y, a futuro, qué actividades
/// evitar al detallar una sesión.
enum ExercisePreferenceTag {
  pesas,
  caminar,
  correr,
  bicicleta,
  natacion,
  clasesGrupales,
  ninguna,
}

extension ExercisePreferenceTagLabel on ExercisePreferenceTag {
  String get label {
    switch (this) {
      case ExercisePreferenceTag.pesas:
        return 'Pesas';
      case ExercisePreferenceTag.caminar:
        return 'Caminar';
      case ExercisePreferenceTag.correr:
        return 'Correr';
      case ExercisePreferenceTag.bicicleta:
        return 'Bicicleta';
      case ExercisePreferenceTag.natacion:
        return 'Natación';
      case ExercisePreferenceTag.clasesGrupales:
        return 'Clases grupales';
      case ExercisePreferenceTag.ninguna:
        return 'Ninguna me gusta particularmente';
    }
  }
}

/// Lesiones o limitaciones — gate de seguridad. Ver §4.5 de la
/// propuesta: nunca se prescribe carga sobre una lesión activa.
enum InjuryTag { rodilla, espaldaBaja, hombro, otra }

extension InjuryTagLabel on InjuryTag {
  String get label {
    switch (this) {
      case InjuryTag.rodilla:
        return 'Rodilla';
      case InjuryTag.espaldaBaja:
        return 'Espalda baja';
      case InjuryTag.hombro:
        return 'Hombro';
      case InjuryTag.otra:
        return 'Otra';
    }
  }
}

/// Intención explícita de composición corporal — complementa (no
/// reemplaza) la zona ACSM que ya se deriva de `bodyFatPercentage`.
enum BodyCompositionGoal { loseFat, buildMuscle, recomposition, performance }

extension BodyCompositionGoalLabel on BodyCompositionGoal {
  String get label {
    switch (this) {
      case BodyCompositionGoal.loseFat:
        return 'Bajar grasa';
      case BodyCompositionGoal.buildMuscle:
        return 'Ganar músculo';
      case BodyCompositionGoal.recomposition:
        return 'Recomposición';
      case BodyCompositionGoal.performance:
        return 'Rendimiento';
    }
  }
}

/// Perfil de hábitos y preferencias de ejercicio del usuario.
/// Vive independiente de `UserModel` — no requiere tocar el modelo
/// principal (freezed, con generación de código) para agregar estos
/// campos.
class ExerciseProfile {
  final ExerciseFrequencyLevel currentLevel;
  final ExerciseExperienceLevel strengthExperience;
  final ExerciseEquipment equipment;
  final List<ExercisePreferenceTag> likedActivities;

  /// Días de la semana en que el usuario realmente puede entrenar.
  /// 1 = lunes … 7 = domingo. Vacío = sin restricción declarada (el
  /// motor de plan asume disponibilidad los 7 días y elige el descanso).
  final List<int> availableWeekdays;
  final List<InjuryTag> injuries;
  final String injuryNotes;
  final BodyCompositionGoal goal;
  final DateTime updatedAt;

  const ExerciseProfile({
    required this.currentLevel,
    required this.strengthExperience,
    required this.equipment,
    required this.likedActivities,
    required this.availableWeekdays,
    required this.injuries,
    required this.injuryNotes,
    required this.goal,
    required this.updatedAt,
  });

  factory ExerciseProfile.initial() => ExerciseProfile(
        currentLevel: ExerciseFrequencyLevel.sedentary,
        strengthExperience: ExerciseExperienceLevel.none,
        equipment: ExerciseEquipment.bodyweightOnly,
        likedActivities: const [],
        availableWeekdays: const [],
        injuries: const [],
        injuryNotes: '',
        goal: BodyCompositionGoal.recomposition,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  bool get isInitial => updatedAt.millisecondsSinceEpoch == 0;

  /// §4.5 de la propuesta: gate de seguridad. Si hay lesión activa
  /// declarada, el motor de plan debe degradar a modalidades seguras.
  bool get hasInjuries => injuries.isNotEmpty || injuryNotes.trim().isNotEmpty;

  ExerciseProfile copyWith({
    ExerciseFrequencyLevel? currentLevel,
    ExerciseExperienceLevel? strengthExperience,
    ExerciseEquipment? equipment,
    List<ExercisePreferenceTag>? likedActivities,
    List<int>? availableWeekdays,
    List<InjuryTag>? injuries,
    String? injuryNotes,
    BodyCompositionGoal? goal,
    DateTime? updatedAt,
  }) {
    return ExerciseProfile(
      currentLevel: currentLevel ?? this.currentLevel,
      strengthExperience: strengthExperience ?? this.strengthExperience,
      equipment: equipment ?? this.equipment,
      likedActivities: likedActivities ?? this.likedActivities,
      availableWeekdays: availableWeekdays ?? this.availableWeekdays,
      injuries: injuries ?? this.injuries,
      injuryNotes: injuryNotes ?? this.injuryNotes,
      goal: goal ?? this.goal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'currentLevel': currentLevel.name,
        'strengthExperience': strengthExperience.name,
        'equipment': equipment.name,
        'likedActivities': likedActivities.map((e) => e.name).toList(),
        'availableWeekdays': availableWeekdays,
        'injuries': injuries.map((e) => e.name).toList(),
        'injuryNotes': injuryNotes,
        'goal': goal.name,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ExerciseProfile.fromMap(Map<String, dynamic> map) {
    return ExerciseProfile(
      currentLevel: _enumFromName(
        ExerciseFrequencyLevel.values,
        map['currentLevel'] as String?,
        ExerciseFrequencyLevel.sedentary,
      ),
      strengthExperience: _enumFromName(
        ExerciseExperienceLevel.values,
        map['strengthExperience'] as String?,
        ExerciseExperienceLevel.none,
      ),
      equipment: _enumFromName(
        ExerciseEquipment.values,
        map['equipment'] as String?,
        ExerciseEquipment.bodyweightOnly,
      ),
      likedActivities: ((map['likedActivities'] as List?) ?? const [])
          .map((e) => _enumFromName(
                ExercisePreferenceTag.values,
                e as String?,
                ExercisePreferenceTag.ninguna,
              ))
          .toList(),
      availableWeekdays: ((map['availableWeekdays'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      injuries: ((map['injuries'] as List?) ?? const [])
          .map((e) => _enumFromName(
                InjuryTag.values,
                e as String?,
                InjuryTag.otra,
              ))
          .toList(),
      injuryNotes: (map['injuryNotes'] as String?) ?? '',
      goal: _enumFromName(
        BodyCompositionGoal.values,
        map['goal'] as String?,
        BodyCompositionGoal.recomposition,
      ),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
