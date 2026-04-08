import 'package:flutter/material.dart';
import 'metabolic_phase.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE INSIGHT
// ─────────────────────────────────────────────────────────────────────────────

class DashboardInsight {
  final String message;
  final IconData icon;
  final List<String> riskFlags;

  DashboardInsight({
    required this.message,
    required this.icon,
    this.riskFlags = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MOTOR DE DECISIONES METABÓLICAS (ENGINEER EDITION)
// ─────────────────────────────────────────────────────────────────────────────

class DecisionEngine {
  /// Analiza fase biológica y scores para devolver una recomendación técnica.
  /// Jerarquía: Emergencias Médicas > Fase Biológica > Optimización de Scores.
  static DashboardInsight generateInsight({
    required MetabolicPhase phase,
    required double sleepScore,
    required double hydrationScore,
    required double nutritionScore,
    required double fastingScore,
    required bool isFasting,
    required int fastingElapsedHours,
  }) {
    
    // 1. EVALUACIÓN DE EMERGENCIAS (Overrides)
    if (sleepScore < 35) {
      return DashboardInsight(
        message: "RECUPERACIÓN CRÍTICA: Prioriza el descanso profundo. El entrenamiento intenso hoy elevará el cortisol a niveles catabólicos.",
        icon: Icons.warning_amber_rounded,
        riskFlags: ["Inercia del sueño", "Resistencia a la insulina temporal"],
      );
    }

    if (hydrationScore < 40) {
      return DashboardInsight(
        message: "DÉFICIT DE FLUIDOS: La deshidratación bloquea la lipólisis. Bebe agua con electrolitos antes de continuar.",
        icon: Icons.water_drop,
        riskFlags: ["Fricción metabólica alta"],
      );
    }

    // 2. EVALUACIÓN POR FASE BIOLÓGICA (Cronobiología)
    switch (phase) {
      case MetabolicPhase.dawnPhenomenon:
        return DashboardInsight(
          message: "FENÓMENO DEL AMANECER: El pico de cortisol ha liberado glucosa natural. Disfruta un café negro; tu cuerpo ya tiene energía.",
          icon: Icons.wb_twilight,
          riskFlags: ["Glucosa endógena activa"],
        );

      case MetabolicPhase.cognitivePeak:
        return DashboardInsight(
          message: "PICO COGNITIVO: Tu IQ y atención están en su cenit diario. Ideal para trabajo profundo o toma de decisiones complejas.",
          icon: Icons.psychology,
        );

      case MetabolicPhase.metabolicSwitch:
        return DashboardInsight(
          message: "TRANSICIÓN METABÓLICA: Agotamiento de glucógeno hepático. El hambre es una ola hormonal temporal (Grelina).",
          icon: Icons.cached,
          riskFlags: ["Cambio de combustible activo"],
        );

      case MetabolicPhase.powerWindow:
        return DashboardInsight(
          message: "VENTANA DE PODER: Pico térmico y cardiovascular detectado. Momento óptimo para fuerza máxima o coordinación motora.",
          icon: Icons.bolt,
        );

      case MetabolicPhase.digestiveLock:
        return DashboardInsight(
          message: "BLOQUEO INTESTINAL: Tu cuerpo desvía energía a la reparación celular. Evita ingestas pesadas para no arruinar el sueño profundo.",
          icon: Icons.lock_clock,
          riskFlags: ["Reparación sistémica"],
        );

      case MetabolicPhase.fatBurning:
        return DashboardInsight(
          message: "QUEMA DE GRASA ACTIVA: Autoconsumo de triglicéridos optimizado. Mantén actividad física de baja intensidad (Zona 2).",
          icon: Icons.local_fire_department,
          riskFlags: ["Cetosis inicial", "Autofagia"],
        );

      case MetabolicPhase.neutral:
        // Continúa a la evaluación por scores si no hay fase específica activa
        break;
    }

    // 3. OPTIMIZACIÓN POR SCORES (Fallback)
    if (isFasting && fastingElapsedHours >= 16) {
      return DashboardInsight(
        message: "AYUNO PROLONGADO: Flexibilidad metabólica en aumento. Hidratación mineralizada obligatoria.",
        icon: Icons.timer_outlined,
      );
    }

    if (nutritionScore < 40 && !isFasting) {
      return DashboardInsight(
        message: "DÉFICIT NUTRICIONAL: Prioriza proteínas de alta biodisponibilidad para proteger tu masa muscular (Sarcopenia).",
        icon: Icons.restaurant,
      );
    }

    // DEFAULT: Estado de Mantenimiento
    return DashboardInsight(
      message: "SISTEMAS ESTABLES: Mantén tus protocolos actuales. Estás operando dentro de rangos metabólicos eficientes.",
      icon: Icons.check_circle_outline,
    );
  }
}