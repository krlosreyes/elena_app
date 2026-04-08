import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/health/domain/dashboard_helpers.dart';
import '../../../core/health/providers/health_snapshot_provider.dart';
import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../domain/logic/elena_brain.dart';

import '../../fasting/application/fasting_controller.dart';
import '../../profile/application/user_controller.dart';
import '../../training/application/training_controller.dart';
import '../../training/domain/training_enums.dart';
// Corregido según tu árbol: nutrition.dart está en la raíz de la carpeta
import '../../nutrition/nutrition.dart'; 

import '../data/telemetry_repository.dart';
import '../data/metabolic_history_repository.dart'; 
import '../domain/telemetry_data.dart';
import '../domain/metabolic_status_evaluator.dart';
import '../domain/decision_engine.dart';
import '../domain/metabolic_phase.dart';
import 'metabolic_phase_provider.dart';
import 'dashboard_adapter.dart';

class ElenaTodayState {
  final DashboardScoreResult score;
  final FastingWindowState fastingWindow;
  final String suggestion;
  final double hydrationScore;
  final double nutritionScore;
  final double sleepScore;
  final double trainingScore;
  final double fastingScore;
  final int exerciseActiveMinutes;
  final bool isTrainingActive;
  final String exerciseCategoryLabel;
  final double hydrationLiters;
  final double hydrationGoalLiters;
  final double sleepHours;
  final double nutritionKcal;
  final String userName;
  final TelemetryData? telemetry;
  final MetabolicStatus status;
  final String statusLabel;
  final MetabolicPhase phase;

  const ElenaTodayState({
    required this.score,
    required this.fastingWindow,
    required this.suggestion,
    required this.hydrationScore,
    required this.nutritionScore,
    required this.sleepScore,
    required this.trainingScore,
    required this.fastingScore,
    required this.exerciseActiveMinutes,
    required this.isTrainingActive,
    required this.exerciseCategoryLabel,
    required this.hydrationLiters,
    required this.hydrationGoalLiters,
    required this.sleepHours,
    required this.nutritionKcal,
    required this.userName,
    required this.status,
    required this.statusLabel,
    required this.phase,
    this.telemetry,
  });
}

class ElenaTodayNotifier extends Notifier<ElenaTodayState> {
  DateTime? _lastSave;

  @override
  ElenaTodayState build() {
    final telemetry = ref.watch(telemetryStreamProvider).valueOrNull;
    final snapshotData = ref.watch(healthSnapshotProvider).valueOrNull;
    final hub = ref.watch(metabolicHubProvider);
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final fasting = ref.watch(fastingControllerProvider).valueOrNull ?? FastingState.initial();
    final training = ref.watch(trainingControllerProvider);
    final phase = ref.watch(metabolicPhaseProvider);

    final compliance = snapshotData != null
        ? const DashboardAdapter().adapt(snapshotData.state, decision: snapshotData.decision).compliance
        : null;

    final firstName = (user?.name ?? '').split(' ').first;
    final hydrationGoalGlasses = user != null ? (user.currentWeightKg / 7) : 9.0;
    
    // Si el provider de nutrición se llama diferente en nutrition.dart, cámbialo aquí:
    final double calories = telemetry?.nutritionKcal.toDouble() ?? hub.nutritionScore;

    final fastingWindow = getFastingWindowState(
      isFasting: fasting.isFasting,
      elapsed: fasting.elapsed,
      plannedHours: fasting.plannedHours,
    );

    final trainingScore = training.phase == TrainingSessionStep.summary ? 100.0 : compliance?.exerciseScore ?? 
        (telemetry != null ? (telemetry.exerciseMinutes / 30.0 * 100).clamp(0.0, 100.0) : (training.rpe * 10.0));

    final sleepScore = compliance?.sleepScore ?? (telemetry != null ? (telemetry.sleepHours / 8.0 * 100).clamp(0.0, 100.0) : 0.0);
    final nutritionScore = compliance?.nutritionScore ?? hub.nutritionScore;
    final hydrationScore = (telemetry != null) ? (telemetry.hydrationGlasses / 10.0 * 100).clamp(0.0, 100.0) : (compliance?.hydrationScore ?? 0.0);
    final fastingScore = compliance?.fastingScore ?? (fasting.isFasting ? fasting.fastingPercent : 0.0);

    final scoreResult = computeDashboardScore(
      trainingScore: trainingScore, 
      sleepScore: sleepScore, 
      nutritionScore: nutritionScore, 
      hydrationScore: hydrationScore, 
      fastingScore: fastingScore,
    );

    final evaluator = MetabolicStatusEvaluator(scoreResult.score);
    final dynamicInsight = DecisionEngine.generateInsight(
      phase: phase, 
      sleepScore: sleepScore, 
      hydrationScore: hydrationScore, 
      nutritionScore: nutritionScore, 
      fastingScore: fastingScore, 
      isFasting: fasting.isFasting, 
      fastingElapsedHours: fasting.elapsed.inHours,
    );

    final state = ElenaTodayState(
      score: scoreResult, 
      fastingWindow: fastingWindow, 
      suggestion: dynamicInsight.message,
      hydrationScore: hydrationScore, 
      nutritionScore: nutritionScore, 
      sleepScore: sleepScore, 
      trainingScore: trainingScore, 
      fastingScore: fastingScore,
      exerciseActiveMinutes: telemetry?.exerciseMinutes ?? 0, 
      isTrainingActive: training.phase == TrainingSessionStep.active, 
      exerciseCategoryLabel: training.category.title,
      hydrationLiters: telemetry?.hydrationLiters ?? (hub.hydrationLevel * 0.25), 
      hydrationGoalLiters: hydrationGoalGlasses * 0.25,
      sleepHours: telemetry?.sleepHours ?? (hub.sleepMinutes / 60.0), 
      nutritionKcal: calories,
      userName: firstName, 
      status: evaluator.status, 
      statusLabel: evaluator.label, 
      phase: phase,
      telemetry: telemetry,
    );

    if (user != null) {
      final now = DateTime.now();
      if (_lastSave == null || now.difference(_lastSave!).inMinutes >= 10) {
        _persistScore(user.uid, state.score.score);
        _lastSave = now;
      }
    }

    return state;
  }

  Future<void> _persistScore(String uid, double currentScore) async {
    try {
      await ref.read(metabolicHistoryRepositoryProvider).saveDailyScore(uid, currentScore);
    } catch (e) {
      debugPrint("Error persistiendo IMR: $e");
    }
  }
}

final elenaTodayProvider = NotifierProvider<ElenaTodayNotifier, ElenaTodayState>(() => ElenaTodayNotifier());