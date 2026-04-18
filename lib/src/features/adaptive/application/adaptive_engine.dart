import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

enum SuggestionType { levelUp, simplify }

class AdaptiveSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final String? newProtocol;
  final int? newExerciseGoal;
  final String reason;

  const AdaptiveSuggestion({
    required this.type,
    required this.title,
    required this.description,
    this.newProtocol,
    this.newExerciseGoal,
    required this.reason,
  });
}

class AdaptiveEngine {
  static const List<String> _fastingLevels = ['Ninguno', '12:12', '14:10', '16:8'];

  /// Evalúa estabilidad: al menos 6 de los últimos 7 días con IMR >= 75 (SPEC-08)
  static bool isIMRStable(List<StreakEntry> history) {
    if (history.length < 7) return false;
    
    // Tomar los últimos 7 días
    final last7 = history.take(7);
    final stableDays = last7.where((e) => e.imrScore >= 75).length;
    
    return stableDays >= 6;
  }

  static AdaptiveSuggestion? evaluateProtocolAdjustment({
    required EngagementLevel engagement,
    required List<StreakEntry> history,
    required String currentProtocol,
    required int currentExerciseGoal,
  }) {
    // 0. Período de gracia: no sugerir cambios si el nivel es neutro (pocos datos)
    if (engagement == EngagementLevel.neutro) return null;

    // 1. Lógica de LEVEL UP (Engagement Excelente + Estabilidad IMR)
    if (engagement == EngagementLevel.excelente && isIMRStable(history)) {
      final currentIndex = _fastingLevels.indexOf(currentProtocol);
      if (currentIndex != -1 && currentIndex < _fastingLevels.length - 1) {
        final nextProtocol = _fastingLevels[currentIndex + 1];
        return AdaptiveSuggestion(
          type: SuggestionType.levelUp,
          title: 'Subida de Nivel Sugerida',
          description: 'Tu estabilidad metabólica es excepcional. Podrías beneficiarte de ampliar tu ventana de ayuno a $nextProtocol.',
          newProtocol: nextProtocol,
          reason: 'Alta adherencia y IMR estable detectados.',
        );
      }
      
      // Si ya está en 16:8, sugerir micro-entrenamiento
      if (currentExerciseGoal < 45) {
        return AdaptiveSuggestion(
          type: SuggestionType.levelUp,
          title: 'Mejora de Intensidad',
          description: 'Estás dominando tu protocolo. ¿Te gustaría añadir un micro-entrenamiento aumentando tu meta de ejercicio a ${currentExerciseGoal + 10} min?',
          newExerciseGoal: currentExerciseGoal + 10,
          reason: 'Protocolo actual dominado.',
        );
      }
    }

    // 2. Lógica de SIMPLIFICACIÓN (Engagement Regular o Crítico)
    if (engagement == EngagementLevel.critico || engagement == EngagementLevel.regular) {
      if (currentProtocol != 'Ninguno' && currentProtocol != '12:12') {
        return AdaptiveSuggestion(
          type: SuggestionType.simplify,
          title: 'Recuperar Ritmo',
          description: 'Parece que el ritmo actual es exigente. Simplificar a un protocolo de 12:12 te ayudará a recuperar consistencia sin estrés.',
          newProtocol: '12:12',
          reason: 'Baja adherencia detectada.',
        );
      }
      
      // Si ya está en 12:12 o Ninguno, sugerir priorizar Hidratación
      if (engagement == EngagementLevel.critico) {
        return const AdaptiveSuggestion(
          type: SuggestionType.simplify,
          title: 'Enfoque en lo Esencial',
          description: 'Para retomar el control, ignora el ayuno hoy y enfócate únicamente en tu hidratación. Mañana será otro día.',
          reason: 'Nivel de compromiso crítico.',
        );
      }
    }

    return null;
  }
}

final adaptiveProvider = Provider<AdaptiveSuggestion?>((ref) {
  final engagement = ref.watch(engagementProvider);
  final streak = ref.watch(streakProvider);
  final user = ref.watch(currentUserStreamProvider).valueOrNull;

  if (user == null) return null;

  return AdaptiveEngine.evaluateProtocolAdjustment(
    engagement: engagement.level,
    history: streak.history,
    currentProtocol: user.fastingProtocol,
    currentExerciseGoal: user.exerciseGoalMinutes,
  );
});
