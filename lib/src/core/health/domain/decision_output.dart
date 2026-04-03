import 'dart:collection';

/// Unified decision output from the metabolic intelligence pipeline.
///
/// Represents a single actionable recommendation derived from the current
/// [UserHealthState]. Framework-agnostic — no UI, no Riverpod, no Flutter.
class DecisionOutput {
  static const String fastingPillar = 'fasting';
  static const String nutritionPillar = 'nutrition';
  static const String trainingPillar = 'training';
  static const String hydrationPillar = 'hydration';
  static const String sleepPillar = 'sleep';

  static const Set<String> requiredPillarKeys = {
    fastingPillar,
    nutritionPillar,
    trainingPillar,
    hydrationPillar,
    sleepPillar,
  };

  /// What the user should do **right now** (imperative, one sentence).
  final String primaryAction;

  /// Clinical / metabolic rationale behind the recommendation.
  final String explanation;

  /// Optional follow-up actions ordered by relevance.
  final List<String> secondaryActions;

  /// Normalized 0–100 scores for each health pillar.
  ///
  /// Keys: `fasting`, `nutrition`, `training`, `hydration`, `sleep`.
  final Map<String, double> pillarScores;

  /// Current metabolic state label.
  ///
  /// Examples: `fat_burning`, `recovery`, `energy_boost`, `autophagy`,
  /// `insulin_high`, `glycogen_depletion`.
  final String metabolicState;

  /// Urgency level (1 = lowest, 5 = critical).
  final int priority;

  /// Indicates whether this recommendation was personalized.
  ///
  /// Backward-compatible default: `false`.
  final bool isPersonalized;

  /// Human-readable reason for personalization.
  ///
  /// Example: "This recommendation is based on your strong fasting adaptation".
  /// Backward-compatible default: empty string.
  final String personalizationReason;

  DecisionOutput({
    required this.primaryAction,
    required this.explanation,
    List<String> secondaryActions = const [],
    Map<String, double> pillarScores = const {},
    required this.metabolicState,
    this.priority = 3,
    this.isPersonalized = false,
    this.personalizationReason = '',
  })  : secondaryActions = List.unmodifiable(secondaryActions),
        pillarScores =
            UnmodifiableMapView(Map<String, double>.from(pillarScores)),
        assert(priority >= 1 && priority <= 5),
        assert(
          _containsRequiredPillars(pillarScores),
          'pillarScores must include: fasting, nutrition, training, hydration, sleep',
        );

  static bool _containsRequiredPillars(Map<String, double> scores) {
    return scores.keys.toSet().containsAll(requiredPillarKeys);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FACTORY CONSTRUCTORS — Common metabolic decisions
  // ─────────────────────────────────────────────────────────────────────────

  /// Continue the current fasting window.
  factory DecisionOutput.fastingContinue({
    required Map<String, double> pillarScores,
    required double hoursElapsed,
  }) {
    return DecisionOutput(
      primaryAction:
          'Mantén tu ayuno — llevas ${hoursElapsed.toStringAsFixed(1)} h.',
      explanation:
          'Tus niveles de insulina siguen bajando y la lipólisis está activa. '
          'Romper ahora desperdiciaría la ventana de oxidación de grasa.',
      secondaryActions: const [
        'Bebe agua o agua mineral con gas.',
        'Si sientes mareo, añade una pizca de sal.',
      ],
      pillarScores: pillarScores,
      metabolicState: 'fat_burning',
      priority: 2,
    );
  }

  /// Break the fast — time to eat.
  factory DecisionOutput.eatNow({
    required Map<String, double> pillarScores,
    required String mealSuggestion,
  }) {
    return DecisionOutput(
      primaryAction: 'Es momento de romper el ayuno.',
      explanation:
          'Has alcanzado tu ventana de alimentación. Prioriza proteína y '
          'grasas saludables para mantener la sensibilidad a la insulina.',
      secondaryActions: [
        mealSuggestion,
        'Mastica lento — mínimo 20 min por comida.',
        'Evita azúcares simples en la primera ingesta.',
      ],
      pillarScores: pillarScores,
      metabolicState: 'recovery',
      priority: 3,
    );
  }

  /// Hydration reminder.
  factory DecisionOutput.hydrate({
    required Map<String, double> pillarScores,
    required int currentGlasses,
    required int targetGlasses,
  }) {
    final deficit = targetGlasses - currentGlasses;
    return DecisionOutput(
      primaryAction: 'Bebe un vaso de agua ahora.',
      explanation: 'Llevas $currentGlasses de $targetGlasses vasos. '
          'La deshidratación reduce la volemia y eleva el cortisol, '
          'frenando la lipólisis.',
      secondaryActions: [
        'Te faltan $deficit vasos para cumplir tu meta.',
        'Añade limón o jengibre si necesitas variedad.',
      ],
      pillarScores: pillarScores,
      metabolicState: 'energy_boost',
      priority: deficit > 4 ? 4 : 2,
    );
  }

  /// Rest / recovery recommendation.
  factory DecisionOutput.rest({
    required Map<String, double> pillarScores,
    required double sleepDebt,
  }) {
    return DecisionOutput(
      primaryAction: 'Prioriza el descanso hoy.',
      explanation:
          'Tu deuda de sueño acumulada es de ${sleepDebt.toStringAsFixed(1)} h. '
          'El cortisol elevado por falta de sueño bloquea la recuperación '
          'muscular y la oxidación de grasa.',
      secondaryActions: const [
        'Evita pantallas 1 h antes de dormir.',
        'Reduce la intensidad del entrenamiento.',
        'Considera una siesta de 20 min si es posible.',
      ],
      pillarScores: pillarScores,
      metabolicState: 'recovery',
      priority: sleepDebt > 3.0 ? 5 : 3,
    );
  }

  /// Training recommendation.
  factory DecisionOutput.train({
    required Map<String, double> pillarScores,
    required String routineType,
    required bool isFasted,
  }) {
    return DecisionOutput(
      primaryAction: 'Es buen momento para entrenar ($routineType).',
      explanation: isFasted
          ? 'Entrenar en ayuno potencia la oxidación de lípidos. '
              'Mantén la intensidad en Zona 2 para proteger la masa muscular.'
          : 'Tu estado metabólico indica buena disponibilidad de glucógeno. '
              'Puedes entrenar a intensidad moderada-alta.',
      secondaryActions: [
        if (isFasted) 'Hidratación extra: 250 ml antes de empezar.',
        'Calienta al menos 5 min.',
        'Registra la sesión al terminar para ajustar tu plan.',
      ],
      pillarScores: pillarScores,
      metabolicState: isFasted ? 'fat_burning' : 'energy_boost',
      priority: 3,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EQUALITY & DEBUG
  // ─────────────────────────────────────────────────────────────────────────

  DecisionOutput copyWith({
    String? primaryAction,
    String? explanation,
    List<String>? secondaryActions,
    Map<String, double>? pillarScores,
    String? metabolicState,
    int? priority,
    bool? isPersonalized,
    String? personalizationReason,
  }) {
    return DecisionOutput(
      primaryAction: primaryAction ?? this.primaryAction,
      explanation: explanation ?? this.explanation,
      secondaryActions: secondaryActions ?? this.secondaryActions,
      pillarScores: pillarScores ?? this.pillarScores,
      metabolicState: metabolicState ?? this.metabolicState,
      priority: priority ?? this.priority,
      isPersonalized: isPersonalized ?? this.isPersonalized,
      personalizationReason:
          personalizationReason ?? this.personalizationReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecisionOutput &&
          runtimeType == other.runtimeType &&
          primaryAction == other.primaryAction &&
          metabolicState == other.metabolicState &&
          priority == other.priority;

  @override
  int get hashCode =>
      primaryAction.hashCode ^ metabolicState.hashCode ^ priority.hashCode;

  @override
  String toString() =>
      'DecisionOutput(priority=$priority, state=$metabolicState, '
      'personalized=$isPersonalized, action="$primaryAction")';
}
