import 'metabolic_phase.dart';

class MetabolicSnapshot {
  final DateTime date;
  final double globalScore;
  final double sleepScore;
  final double trainingScore;
  final double nutritionScore;
  final double hydrationScore;
  final double fastingScore;
  final MetabolicPhase primaryPhase;

  MetabolicSnapshot({
    required this.date,
    required this.globalScore,
    required this.sleepScore,
    required this.trainingScore,
    required this.nutritionScore,
    required this.hydrationScore,
    required this.fastingScore,
    required this.primaryPhase,
  });

  // Factory para crear desde Firestore o desde el estado actual
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'globalScore': globalScore,
      'sleepScore': sleepScore,
      'trainingScore': trainingScore,
      'nutritionScore': nutritionScore,
      'hydrationScore': hydrationScore,
      'fastingScore': fastingScore,
      'primaryPhase': primaryPhase.name,
    };
  }
}