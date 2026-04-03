import 'package:flutter/material.dart';

import '../../../core/science/metabolic_engine.dart' as core_science;

class FastingStage {
  final String name;
  final String description;
  final Duration startHour;
  final IconData icon;

  const FastingStage({
    required this.name,
    required this.description,
    required this.startHour,
    required this.icon,
  });

  static List<FastingStage> getStages() {
    return [
      const FastingStage(
        name: 'Digestión',
        description:
            'Tu cuerpo está procesando los nutrientes de la última comida e incrementando el almacenamiento de energía.',
        startHour: Duration(hours: 0),
        icon: Icons.restaurant_outlined,
      ),
      const FastingStage(
        name: 'Catabolismo',
        description:
            'Los niveles de azúcar bajan y el cuerpo comienza a utilizar el glucógeno almacenado en el hígado.',
        startHour: Duration(hours: 4),
        icon: Icons.water_drop_outlined,
      ),
      const FastingStage(
        name: 'Quema de Grasa',
        description:
            'Las reservas de glucógeno se agotan y tu cuerpo comienza a metabolizar grasas para obtener energía.',
        startHour: Duration(hours: 12),
        icon: Icons.flash_on_outlined,
      ),
      const FastingStage(
        name: 'Cetosis Nutricional',
        description:
            'La producción de cuerpos cetónicos aumenta, proporcionando una fuente de energía eficiente para el cerebro.',
        startHour: Duration(hours: 14),
        icon: Icons.science_outlined,
      ),
      const FastingStage(
        name: 'Autofagia',
        description:
            'Tus células inician un proceso de limpieza y reciclaje profundo de proteínas dañadas.',
        startHour: Duration(hours: 16),
        icon: Icons.auto_fix_high_outlined,
      ),
    ];
  }

  static FastingStage getStageForDuration(Duration elapsed) {
    // Moved to DecisionEngine in Phase 3
    // Stage decision now follows the core metabolic engine zone mapping.
    final zone = core_science.MetabolicEngine.calculateZone(elapsed);

    switch (zone) {
      case core_science.MetabolicZone.sugarBurning:
        if (elapsed.inHours >= 4) return getStages()[1];
        return getStages()[0];
      case core_science.MetabolicZone.fatBurning:
        return getStages()[2];
      case core_science.MetabolicZone.autophagy:
      case core_science.MetabolicZone.deepKetosis:
        return getStages()[4];
    }
  }
}
