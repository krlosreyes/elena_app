/// Modelo puro de datos para definir las fases circadiana (Sin dependencias de UI)
class CircadianPhase {
  final String label;
  final double startHour;
  final double endHour;

  const CircadianPhase({
    required this.label,
    required this.startHour,
    required this.endHour,
  });
}
