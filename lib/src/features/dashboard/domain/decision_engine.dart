import 'package:flutter/material.dart';
import 'metabolic_phase.dart';

class DashboardInsight {
  final String message;
  final IconData icon;
  final List<String> riskFlags;

  DashboardInsight({required this.message, required this.icon, this.riskFlags = const []});
}

class DecisionEngine {
  static DashboardInsight generateInsight({
    required MetabolicPhase phase,
    required double sleepScore,
    required double hydrationScore,
    required double nutritionScore,
    required double fastingScore,
    required bool isFasting,
    required int fastingElapsedHours,
  }) {
    
    // 🔴 REGLA CRÍTICA (B-3): Sueño insuficiente + Ventana de Reparación
    if (sleepScore < 40 && phase == MetabolicPhase.digestiveLock) {
      return DashboardInsight(
        message: "ALERTA CRÍTICA: Sueño insuficiente en fase de reparación celular. Tu metabolismo está en modo supervivencia. Prioriza descanso absoluto.",
        icon: Icons.dangerous_outlined,
        riskFlags: ["Falla de reparación sistémica", "Cortisol elevado"],
      );
    }

    // Emergencia de hidratación
    if (hydrationScore < 40) {
      return DashboardInsight(
        message: "DÉFICIT DE FLUIDOS: Bebe agua con electrolitos. La deshidratación está frenando tu quema de grasa.",
        icon: Icons.water_drop,
        riskFlags: ["Fricción metabólica"],
      );
    }

    // Evaluación por fase
    switch (phase) {
      case MetabolicPhase.fatBurning:
        return DashboardInsight(
          message: "QUEMA DE GRASA ACTIVA: Mantén actividad de baja intensidad. Estás en modo autofagia.",
          icon: Icons.local_fire_department,
        );
      case MetabolicPhase.digestiveLock:
        return DashboardInsight(
          message: "BLOQUEO DIGESTIVO: Tu sistema está reparando tejidos. No ingieras sólidos ahora.",
          icon: Icons.lock_clock,
        );
      default:
        return DashboardInsight(
          message: "SISTEMAS ESTABLES: Protocolo ejecutándose correctamente.",
          icon: Icons.check_circle_outline,
        );
    }
  }
}