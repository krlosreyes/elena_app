enum FastingSymptom {
  intenseFasting, // Hambre punzante intensa
  dizziness, // Mareos / debilidad
  heartburn, // Acidez / reflujo
  headache, // Dolor de cabeza
  fatigue, // Fatiga inusual
  palpitations, // Palpitaciones
}

class SymptomIntervention {
  final FastingSymptom symptom;
  final String label; // Texto del botón SOS
  final String cause; // Causa biológica explicada
  final String intervention; // Acción concreta inmediata
  final bool requiresBreakFast; // Si debe terminar el ayuno

  const SymptomIntervention({
    required this.symptom,
    required this.label,
    required this.cause,
    required this.intervention,
    required this.requiresBreakFast,
  });
}
