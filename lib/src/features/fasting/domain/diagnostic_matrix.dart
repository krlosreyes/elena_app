import 'fasting_symptom.dart';

class DiagnosticMatrix {
  static const List<SymptomIntervention> interventions = [
    SymptomIntervention(
      symptom: FastingSymptom.intenseFasting,
      label: 'Hambre intensa',
      cause: 'Pico de Grelina — hormona del hambre. '
          'Es una ola hormonal temporal, no inanición real.',
      intervention: 'Bebe agua mineral fría ahora.\n'
          'Alternativas: café negro, té verde '
          'o semillas de chía hidratadas.\n'
          'La ola pasa en 20–30 minutos.',
      requiresBreakFast: false,
    ),
    SymptomIntervention(
      symptom: FastingSymptom.dizziness,
      label: 'Mareos / debilidad',
      cause: 'Pérdida de sodio y fluidos por niveles '
          'bajos de insulina. No es hipoglucemia.',
      intervention: 'AHORA: 1 taza de caldo de hueso '
          'o agua con ¼ cucharadita de sal y magnesio.\n'
          'Si persiste más de 10 minutos: termina el ayuno.',
      requiresBreakFast: true,
    ),
    SymptomIntervention(
      symptom: FastingSymptom.heartburn,
      label: 'Acidez / reflujo',
      cause: 'Estómago vacío con niveles altos de ácido gástrico. '
          'Común al romper ayunos prolongados con comidas copiosas.',
      intervention: 'Si estás en ventana de alimentación: '
          'empieza con porciones pequeñas.\n'
          'No te recuestes por 30 minutos después de comer.\n'
          'Evita alimentos ácidos o grasos para romper el ayuno.',
      requiresBreakFast: false,
    ),
    SymptomIntervention(
      symptom: FastingSymptom.headache,
      label: 'Dolor de cabeza',
      cause: 'Deshidratación leve o descenso de sodio. '
          'Muy común en las primeras semanas de adaptación.',
      intervention: 'Bebe 500ml de agua con una pizca de sal.\n'
          'Si llevas menos de 16h: es parte de la adaptación.\n'
          'Desaparece en 2–4 semanas de práctica consistente.',
      requiresBreakFast: false,
    ),
    SymptomIntervention(
      symptom: FastingSymptom.fatigue,
      label: 'Fatiga inusual',
      cause: 'Tu cuerpo está en transición de glucosa a grasas. '
          'El motor biológico está cambiando de combustible.',
      intervention: 'Reduce la intensidad de cualquier actividad física.\n'
          'Hidrata con electrolitos: Na, K, Mg.\n'
          'Es temporal — señal de que la adaptación está ocurriendo.',
      requiresBreakFast: false,
    ),
    SymptomIntervention(
      symptom: FastingSymptom.palpitations,
      label: 'Palpitaciones',
      cause: 'Desequilibrio de electrolitos, especialmente potasio '
          'y magnesio. Riesgo real si persiste.',
      intervention: 'Termina el ayuno ahora.\n'
          'Consume potasio (plátano, agua de coco) '
          'y magnesio de inmediato.\n'
          'Si persiste más de 5 minutos: busca atención médica.',
      requiresBreakFast: true,
    ),
  ];

  static SymptomIntervention getIntervention(FastingSymptom symptom) {
    return interventions.firstWhere((i) => i.symptom == symptom);
  }
}
