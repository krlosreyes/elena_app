import '../domain/user_health_state.dart';
import '../domain/decision_output.dart';
import '../../science/metabolic_engine.dart';

class DecisionEngine {
  const DecisionEngine();

  DecisionOutput decide(UserHealthState state, {DateTime? now}) {
    final phase = MetabolicEngine.getCurrentCircadianPhase(now: now);
    
    // 📊 MAPEO DE TELEMETRÍA CORREGIDO
    final pillarScores = {
      // AYUNO: Basado en horas transcurridas vs meta (ej. 16h)
      DecisionOutput.fastingPillar: (state.metabolicProfile.fastingContext.currentFastingElapsedHours / 16.0).clamp(0.0, 1.0),
      
      // NUTRI: Mapeado a la ingesta de Nutrición (Calorías/Proteína)
      DecisionOutput.nutritionPillar: (state.dailyLog.calories > 0) ? 1.0 : 0.0,
      
      // TREN: Mapeado a Ejercicio (Workouts o minutos manuales)
      DecisionOutput.trainingPillar: (state.workouts.isNotEmpty || state.dailyLog.exerciseMinutes > 0) ? 1.0 : 0.0,
      
      // SUEÑO: Basado en horas de descanso
      DecisionOutput.sleepPillar: (state.sleepLog?.hours ?? 0) / 8.0,
      
      // AGUA: Basado en vasos de agua
      DecisionOutput.hydrationPillar: (state.dailyLog.waterGlasses / 10.0).clamp(0.0, 1.0),
    };

    final baseMetadata = {
      'personalized': true,
      'metabolicState': state.metabolicProfile.adaptationState.name,
      'pillarScores': pillarScores.map((k, v) => MapEntry(k, v.clamp(0.0, 1.0))),
    };

    // Alerta de Catabolismo corregida: TREN alto + NUTRI cero
    if (state.dailyLog.exerciseMinutes > 30 && state.dailyLog.calories == 0 && !state.metabolicProfile.fastingContext.isCurrentlyFasting) {
      return DecisionOutput(
        primaryAction: 'ALERTA DE NUTRICIÓN',
        secondaryAction: 'Registra tu ingesta post-entreno.',
        explanation: 'Has completado tu TREN pero el marcador de NUTRI está en cero. Riesgo de catabolismo.',
        priority: DecisionPriority.high,
        metadata: baseMetadata,
      );
    }

    return DecisionOutput.idle().copyWith(metadata: baseMetadata);
  }
}