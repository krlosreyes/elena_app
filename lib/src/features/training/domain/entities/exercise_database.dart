// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE DATABASE — Catálogo estático en memoria (no Firestore)
// ═══════════════════════════════════════════════════════════════════════════════

/// Definición inmutable de un ejercicio del catálogo
class ExerciseDefinition {
  final String id;
  final String name; // Display name en español
  final String muscleGroup; // "chest" | "back" | "legs" | "shoulders" | "core"
  final bool requiresDumbbells;
  final bool isBodyweight;
  final String? contraindication; // pathology key que lo excluye

  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.requiresDumbbells = false,
    this.isBodyweight = true,
    this.contraindication,
  });
}

/// Base de datos estática de ejercicios — acceso via ExerciseDatabase.all
class ExerciseDatabase {
  ExerciseDatabase._();

  // ─── PECHO / chest ──────────────────────────────────────────────────────
  static const _chest = [
    ExerciseDefinition(id: 'push_up', name: 'Flexiones', muscleGroup: 'chest'),
    ExerciseDefinition(
      id: 'incline_push_up',
      name: 'Flexiones inclinadas',
      muscleGroup: 'chest',
      contraindication: 'shoulder_pain',
    ),
    ExerciseDefinition(
      id: 'dumbbell_press',
      name: 'Press con mancuernas',
      muscleGroup: 'chest',
      requiresDumbbells: true,
      isBodyweight: false,
    ),
    ExerciseDefinition(
      id: 'dumbbell_fly',
      name: 'Aperturas con mancuernas',
      muscleGroup: 'chest',
      requiresDumbbells: true,
      isBodyweight: false,
    ),
  ];

  // ─── ESPALDA / back ─────────────────────────────────────────────────────
  static const _back = [
    ExerciseDefinition(id: 'superman', name: 'Superman', muscleGroup: 'back'),
    ExerciseDefinition(
      id: 'dumbbell_row',
      name: 'Remo con mancuerna',
      muscleGroup: 'back',
      requiresDumbbells: true,
      isBodyweight: false,
    ),
    ExerciseDefinition(
      id: 'pull_apart',
      name: 'Separaciones sin peso',
      muscleGroup: 'back',
    ),
    ExerciseDefinition(
      id: 'dumbbell_deadlift',
      name: 'Peso muerto con mancuernas',
      muscleGroup: 'back',
      requiresDumbbells: true,
      isBodyweight: false,
    ),
  ];

  // ─── PIERNAS / legs ─────────────────────────────────────────────────────
  static const _legs = [
    ExerciseDefinition(id: 'squat', name: 'Sentadilla', muscleGroup: 'legs'),
    ExerciseDefinition(
      id: 'reverse_lunge',
      name: 'Estocada hacia atrás',
      muscleGroup: 'legs',
    ),
    ExerciseDefinition(
      id: 'dumbbell_squat',
      name: 'Sentadilla con mancuernas',
      muscleGroup: 'legs',
      requiresDumbbells: true,
      isBodyweight: false,
    ),
    ExerciseDefinition(
      id: 'glute_bridge',
      name: 'Puente de glúteos',
      muscleGroup: 'legs',
      contraindication: 'lower_back_pain',
    ),
    ExerciseDefinition(
      id: 'calf_raise',
      name: 'Elevaciones de talón',
      muscleGroup: 'legs',
    ),
    ExerciseDefinition(
      id: 'wall_sit',
      name: 'Sentadilla isométrica',
      muscleGroup: 'legs',
    ),
    ExerciseDefinition(id: 'step_up', name: 'Step Up', muscleGroup: 'legs'),
    ExerciseDefinition(
      id: 'sumo_squat',
      name: 'Sentadilla sumo',
      muscleGroup: 'legs',
    ),
    ExerciseDefinition(
      id: 'dumbbell_romanian_deadlift',
      name: 'Peso muerto rumano',
      muscleGroup: 'legs',
      requiresDumbbells: true,
      isBodyweight: false,
      contraindication: 'lower_back_pain',
    ),
    ExerciseDefinition(
      id: 'single_leg_glute_bridge',
      name: 'Puente a una pierna',
      muscleGroup: 'legs',
    ),
  ];

  // ─── HOMBROS / shoulders ────────────────────────────────────────────────
  static const _shoulders = [
    ExerciseDefinition(
      id: 'shoulder_tap',
      name: 'Toque de hombros',
      muscleGroup: 'shoulders',
    ),
    ExerciseDefinition(
      id: 'dumbbell_lateral_raise',
      name: 'Elevaciones laterales',
      muscleGroup: 'shoulders',
      requiresDumbbells: true,
      isBodyweight: false,
    ),
    ExerciseDefinition(
      id: 'dumbbell_shoulder_press',
      name: 'Press de hombros',
      muscleGroup: 'shoulders',
      requiresDumbbells: true,
      isBodyweight: false,
      contraindication: 'shoulder_pain',
    ),
    ExerciseDefinition(
      id: 'arnold_press',
      name: 'Press Arnold',
      muscleGroup: 'shoulders',
      requiresDumbbells: true,
      isBodyweight: false,
      contraindication: 'shoulder_pain',
    ),
  ];

  // ─── CORE ───────────────────────────────────────────────────────────────
  static const _core = [
    ExerciseDefinition(id: 'plank', name: 'Plancha', muscleGroup: 'core'),
    ExerciseDefinition(id: 'dead_bug', name: 'Dead Bug', muscleGroup: 'core'),
    ExerciseDefinition(
      id: 'bicycle_crunch',
      name: 'Crunch de bicicleta',
      muscleGroup: 'core',
      contraindication: 'lower_back_pain',
    ),
    ExerciseDefinition(
      id: 'mountain_climber',
      name: 'Escalador',
      muscleGroup: 'core',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESO PÚBLICO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Todos los ejercicios del catálogo
  static const List<ExerciseDefinition> all = [
    ..._chest,
    ..._back,
    ..._legs,
    ..._shoulders,
    ..._core,
  ];

  /// Mapa id → ExerciseDefinition para búsqueda rápida
  static final Map<String, ExerciseDefinition> byId = {
    for (final ex in all) ex.id: ex,
  };

  /// Ejercicios filtrados por grupo muscular
  static List<ExerciseDefinition> byMuscleGroup(String group) =>
      all.where((e) => e.muscleGroup == group).toList();

  /// Grupos musculares para tren superior
  static const upperBodyGroups = {'chest', 'back', 'shoulders'};

  /// Grupos musculares para tren inferior
  static const lowerBodyGroups = {'legs'};

  /// Grupos musculares para full body (todos)
  static const fullBodyGroups = {'chest', 'back', 'legs', 'shoulders'};
}
