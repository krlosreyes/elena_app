import 'package:flutter/material.dart';

/// Define las propiedades visuales de las fases para la capa de presentación
class CircadianTheme {
  static Color getColorForPhase(String label) {
    switch (label) {
      case "SUEÑO":
        return const Color(0xFF1E293B);
      case "ALERTA":
        return const Color(0xFF334155);
      case "COGNITIVO":
        return const Color(0xFFF97316);
      case "RECESO":
        return const Color(0xFF3B82F6);
      case "MOTOR / FUERZA":
        return const Color(0xFFEF4444);
      case "CREATIVIDAD":
        return const Color(0xFFEAB308);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
