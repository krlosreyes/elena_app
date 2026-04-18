import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

enum EngagementLevel {
  neutro,      // < 3 días de datos — período de calentamiento
  excelente,
  bueno,
  regular,
  critico,
}

class EngagementState {
  final EngagementLevel level;
  final String status;
  final String message;
  final double adherence;

  const EngagementState({
    required this.level,
    required this.status,
    required this.message,
    required this.adherence,
  });
}

class EngagementService {
  /// Días mínimos de historial necesarios para que el análisis sea significativo.
  static const int kGracePeriodDays = 3;

  static EngagementState calculateEngagement(double adherence, {int historyDays = 0}) {
    // Período de gracia: no emitir juicios con datos insuficientes.
    if (historyDays < kGracePeriodDays) {
      return const EngagementState(
        level: EngagementLevel.neutro,
        status: 'Calibrando',
        message: 'Elena está aprendiendo tu ritmo. Continúa registrando tus pilares.',
        adherence: 0,
      );
    }

    if (adherence >= 0.85) {
      return EngagementState(
        level: EngagementLevel.excelente,
        status: 'Excelente',
        message: '¡Nivel Élite! Tu metabolismo está en su punto máximo de eficiencia.',
        adherence: adherence,
      );
    } else if (adherence >= 0.70) {
      return EngagementState(
        level: EngagementLevel.bueno,
        status: 'Bueno',
        message: 'Gran consistencia. Estás protegiendo tu salud metabólica con éxito.',
        adherence: adherence,
      );
    } else if (adherence >= 0.50) {
      return EngagementState(
        level: EngagementLevel.regular,
        status: 'Regular',
        message: 'Buen ritmo, pero hay espacio para ganar más energía. ¡Tú puedes!',
        adherence: adherence,
      );
    } else {
      return EngagementState(
        level: EngagementLevel.critico,
        status: 'Crítico',
        message: 'Elena te extraña. Mañana es una nueva oportunidad para reconectar con tu ritmo.',
        adherence: adherence,
      );
    }
  }
}

final engagementProvider = Provider<EngagementState>((ref) {
  final streak = ref.watch(streakProvider);
  // Pasar la cantidad de días con historial para activar el período de gracia
  return EngagementService.calculateEngagement(
    streak.weeklyAdherence,
    historyDays: streak.history.length,
  );
});
