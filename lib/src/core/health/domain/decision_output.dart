/// Definimos la prioridad con valores numéricos para comparaciones lógicas.
enum DecisionPriority { 
  low(1), 
  medium(2), 
  high(3), 
  critical(5);

  final int value;
  const DecisionPriority(this.value);

  /// Permite comparaciones como: decision.priority >= DecisionPriority.high
  bool operator >=(DecisionPriority other) => value >= other.value;
  bool operator >(DecisionPriority other) => value > other.value;
}

class DecisionOutput {
  final String primaryAction;
  final String secondaryAction;
  final String explanation;
  final DecisionPriority priority;
  final Map<String, dynamic> metadata;

  const DecisionOutput({
    required this.primaryAction,
    required this.secondaryAction,
    required this.explanation,
    this.priority = DecisionPriority.medium,
    this.metadata = const {},
  });

  // 🛡️ FIX: Getters de compatibilidad para evitar errores en Dashboard y Engagement
  List<String> get secondaryActions => [secondaryAction];
  bool get isPersonalized => metadata['personalized'] == true;
  String? get metabolicState => metadata['metabolicState'] as String?;
  Map<String, double>? get pillarScores => metadata['pillarScores'] as Map<String, double>?;

  // Constantes de pilares para evitar "Member not found"
  static const String fastingPillar = 'fasting';
  static const String nutritionPillar = 'nutrition';
  static const String trainingPillar = 'training';
  static const String sleepPillar = 'sleep';
  static const String hydrationPillar = 'hydration';

  DecisionOutput copyWith({
    String? primaryAction,
    String? secondaryAction,
    String? explanation,
    DecisionPriority? priority,
    Map<String, dynamic>? metadata,
  }) {
    return DecisionOutput(
      primaryAction: primaryAction ?? this.primaryAction,
      secondaryAction: secondaryAction ?? this.secondaryAction,
      explanation: explanation ?? this.explanation,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }

  factory DecisionOutput.idle() => const DecisionOutput(
        primaryAction: 'MANTENER PROTOCOLO',
        secondaryAction: 'No se requieren ajustes inmediatos.',
        explanation: 'Estado biológico estable.',
        priority: DecisionPriority.low,
      );
}