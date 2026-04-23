import 'biological_phases.dart';

import 'package:flutter/material.dart';
import 'biological_phases.dart';

class PhaseInfo {
  final String title;
  final String description;
  final String action;
  final IconData icon;

  const PhaseInfo({
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
  });
}

class PhaseInfoMapper {
  static PhaseInfo map(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.sueno:
        return const PhaseInfo(
          title: "Modo Recuperación",
          description:
              "Tu cuerpo está trabajando a máxima potencia para limpiar toxinas y renovar tus energías. Es el taller mecánico de tu salud.",
          action: "Regálate un descanso total. Apaga las luces y deja que tu cuerpo se encargue de todo.",
          actionLabel: "A descansar",
        );

      case CircadianPhase.alerta:
        return const PhaseInfo(
          title: "Despegue Matutino",
          description:
              "Es el momento de encender tus motores. Una chispa de luz y movimiento hoy garantiza tu energía para mañana.",
          action: "Busca un poco de sol y estira tu cuerpo. ¡Dale la bienvenida al día!",
          actionLabel: "¡A darle!",
        );

      case CircadianPhase.cognitivo:
        return const PhaseInfo(
          title: "Máxima Claridad",
          description:
              "Tu mente está en su mejor momento. Tienes todo el potencial para resolver retos y avanzar en tus metas más importantes.",
          action: "Aprovecha este impulso. Concéntrate en lo que más importa y haz que suceda.",
          actionLabel: "Enfocarme ahora",
        );

      case CircadianPhase.receso:
        return const PhaseInfo(
          title: "Pausa Inteligente",
          description:
              "Tu sistema pide un respiro para mantenerse equilibrado. Es el momento de bajar el ritmo y recargar de forma consciente.",
          action: "Come algo ligero y prepárate para cerrar el ciclo del día con calma.",
          actionLabel: "Registrar y pausar",
        );

      case CircadianPhase.motorFuerza:
        return const PhaseInfo(
          title: "Potencia Total",
          description:
              "Tu cuerpo está listo para el desafío físico. Es cuando eres más fuerte, más rápido y más resistente.",
          action: "Mueve tus músculos. ¡Es el momento perfecto para entrenar y sentirte vital!",
          actionLabel: "¡A entrenar!",
        );

      case CircadianPhase.creatividad:
        return const PhaseInfo(
          title: "Momento de Inspiración",
          description:
              "Tu cerebro se vuelve más flexible y abierto. Las mejores ideas suelen aparecer cuando te permites fluir un poco más.",
          action: "Suelta la estructura. Anota ideas, planea el futuro o simplemente disfruta tu talento.",
          actionLabel: "Crear algo nuevo",
        );
    }
  }
}