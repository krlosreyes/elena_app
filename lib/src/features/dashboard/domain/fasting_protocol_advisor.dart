/// SPEC-26: Asesor de Protocolo de Ayuno
/// Sugiere el protocolo óptimo basado en perfil científico del usuario

import 'package:elena_app/src/shared/domain/models/user_model.dart';

class FastingProtocol {
  final String name;        // "16:8", "18:6", "20:4", etc.
  final int fastingHours;   // Horas de ayuno (16, 18, 20, etc.)
  final int feedingHours;   // Horas de ventana alimentaria (8, 6, 4, etc.)
  final String description; // Descripción científica
  final String difficulty;  // "Principiante", "Intermedio", "Avanzado"

  FastingProtocol({
    required this.name,
    required this.fastingHours,
    required this.feedingHours,
    required this.description,
    required this.difficulty,
  });

  static final List<FastingProtocol> allProtocols = [
    FastingProtocol(
      name: 'Ninguno',
      fastingHours: 0,
      feedingHours: 24,
      description: 'Sin restricción de horario. Recomendado solo en transición.',
      difficulty: 'N/A',
    ),
    FastingProtocol(
      name: '12:12',
      fastingHours: 12,
      feedingHours: 12,
      description: 'Ayuno moderado. Ideal para principiantes y transición circadiana.',
      difficulty: 'Principiante',
    ),
    FastingProtocol(
      name: '14:10',
      fastingHours: 14,
      feedingHours: 10,
      description: 'Ayuno ligero. Buen balance sin restricción extrema.',
      difficulty: 'Principiante',
    ),
    FastingProtocol(
      name: '16:8',
      fastingHours: 16,
      feedingHours: 8,
      description: 'El más popular. Excelente para pérdida de grasa y claridad mental.',
      difficulty: 'Intermedio',
    ),
    FastingProtocol(
      name: '18:6',
      fastingHours: 18,
      feedingHours: 6,
      description: 'Ayuno moderado-intenso. Aumenta autofagia sin extremo.',
      difficulty: 'Intermedio',
    ),
    FastingProtocol(
      name: '20:4',
      fastingHours: 20,
      feedingHours: 4,
      description: 'Ayuno intenso (Warrior Diet). Requiere experiencia previa.',
      difficulty: 'Avanzado',
    ),
    FastingProtocol(
      name: '22:2',
      fastingHours: 22,
      feedingHours: 2,
      description: 'Ayuno muy intenso. Solo para usuarios experimentados.',
      difficulty: 'Avanzado',
    ),
    FastingProtocol(
      name: 'OMAD',
      fastingHours: 23,
      feedingHours: 1,
      description: 'Una comida al día. Máximo ayuno fisiológico.',
      difficulty: 'Avanzado',
    ),
  ];
}

class FastingProtocolAdvisor {
  /// Sugiere el protocolo óptimo basado en perfil científico
  static FastingProtocol suggestProtocol(UserModel user) {
    // Puntuación de tolerancia: 0-100
    int toleranceScore = _calculateToleranceScore(user);

    // Basado en tolerancia, sugerir protocolo
    if (toleranceScore < 20) {
      return _findProtocol('12:12');
    } else if (toleranceScore < 40) {
      return _findProtocol('14:10');
    } else if (toleranceScore < 60) {
      return _findProtocol('16:8');
    } else if (toleranceScore < 80) {
      return _findProtocol('18:6');
    } else {
      return _findProtocol('20:4');
    }
  }

  /// Calcula puntuación de tolerancia al ayuno (0-100)
  /// Basado en: edad, género, IMR, actividad, metas
  static int _calculateToleranceScore(UserModel user) {
    int score = 50; // Base

    // Factor edad: usuarios >40 años más tolerantes
    if (user.age > 40) score += 10;
    if (user.age > 50) score += 5;
    if (user.age < 25) score -= 10;

    // Factor género: hombres típicamente más tolerantes
    if (user.gender == Gender.male) score += 5;

    // Factor experiencia: si ya tiene un protocolo, mantener cercanía
    // (esto se evalúa en la UI al comparar actual vs sugerido)

    // Factor IMR: usuarios con buen IMR pueden tolerancia más intenso
    // (Se evaluaría con scoreEngine.calculateIMR(), pero omitido por contexto)

    // Factor metabolismo basal: usuarios con actividad alta toleran mejor
    // (Requerería datos de exerciseState)

    // Clamping final
    return score.clamp(0, 100);
  }

  /// Busca un protocolo por nombre
  static FastingProtocol _findProtocol(String name) {
    return FastingProtocol.allProtocols.firstWhere(
      (p) => p.name == name,
      orElse: () => FastingProtocol.allProtocols.first, // Fallback: "Ninguno"
    );
  }

  /// Calcula diferencia entre protocolo actual y sugerido
  static String getDifferenceLabel(
    FastingProtocol current,
    FastingProtocol suggested,
  ) {
    if (current.name == suggested.name) {
      return 'Siguiendo recomendación';
    }

    final diff = current.fastingHours - suggested.fastingHours;
    if (diff > 0) {
      return 'Más intenso de lo recomendado (+$diff h)';
    } else {
      return 'Menos intenso de lo recomendado (${diff.abs()}h menos)';
    }
  }
}
