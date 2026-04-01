import 'package:flutter/material.dart';

enum TrainingSessionStep {
  selection,
  active,
  summary,
}

enum ExerciseCategory {
  strength('FUERZA', 'GLUCÓGENO', Icons.fitness_center_rounded, Colors.orangeAccent),
  hiit('HIIT', 'METABÓLICA', Icons.bolt_rounded, Colors.redAccent),
  mobility('MOVILIDAD', 'REGENERACIÓN', Icons.self_improvement_rounded, Colors.cyanAccent);

  final String title;
  final String objective;
  final IconData icon;
  final Color color;
  const ExerciseCategory(this.title, this.objective, this.icon, this.color);
}
