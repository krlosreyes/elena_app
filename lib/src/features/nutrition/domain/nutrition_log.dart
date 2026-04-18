/// Registro de una comida individual dentro de la ventana circadiana.
/// Se mantiene en memoria (sin persistencia Firestore en esta versión),
/// ya que el score nutricional se resetea con cada día nuevo.
class NutritionLog {
  final String id;
  final DateTime timestamp;

  /// Etiqueta semántica: "Desayuno", "Almuerzo", "Cena", "Snack"
  final String label;

  /// True si la comida se registró dentro de la ventana
  /// [firstMealGoal, lastMealGoal] del CircadianProfile del usuario.
  final bool withinCircadianWindow;

  const NutritionLog({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.withinCircadianWindow,
  });
}
