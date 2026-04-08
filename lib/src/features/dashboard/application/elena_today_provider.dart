import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/health/domain/dashboard_helpers.dart';
import '../../../core/health/providers/health_snapshot_provider.dart';
import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../domain/logic/elena_brain.dart';

import '../../fasting/application/fasting_controller.dart';
import '../../health/data/health_repository.dart';
import '../../profile/application/user_controller.dart';
import '../../training/application/training_controller.dart';
import '../../training/domain/training_enums.dart';

import '../data/telemetry_repository.dart';
import '../data/metabolic_history_repository.dart'; 
import '../domain/telemetry_data.dart';
import '../domain/metabolic_status_evaluator.dart';
import '../domain/decision_engine.dart';
import '../domain/metabolic_phase.dart';
import 'metabolic_phase_provider.dart';
import 'dashboard_adapter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ELENA TODAY STATE
// ─────────────────────────────────────────────────────────────────────────────

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
  final List<MetamorfosisPost> contextSuggestions;
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
    this.contextSuggestions = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ELENA TODAY NOTIFIER (Agregador con Auto-Snapshot)
// ─────────────────────────────────────────────────────────────────────────────

// FIX: Quitamos Family para que el ref.watch(elenaTodayProvider) funcione directo
class ElenaTodayNotifier extends Notifier<ElenaTodayState> {
  @override
  ElenaTodayState build() {
    final telemetry = ref.watch(telemetryStreamProvider).valueOrNull;
    final contextSuggestions = ref.watch(suggestionsStreamProvider).valueOrNull ?? [];
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
    final todayLog = user != null ? ref.watch(todayLogProvider(user.uid)).valueOrNull : null;

    final fastingWindow = getFastingWindowState(
      isFasting: fasting.isFasting,
      elapsed: fasting.elapsed,
      plannedHours: fasting.plannedHours,
    );

    final exerciseMinutes = telemetry != null ? telemetry.exerciseMinutes : (training.elapsedSeconds / 60).ceil();
    final dailyGoalMinutes = user != null ? ElenaBrain.getDailyExerciseGoalMinutes(user) : 30.0;
    final isWorkoutDone = training.phase == TrainingSessionStep.summary;

    final trainingScore = isWorkoutDone ? 100.0 : compliance?.exerciseScore ?? 
        (telemetry != null && dailyGoalMinutes > 0 
          ? (telemetry.exerciseMinutes / dailyGoalMinutes * 100).clamp(0.0, 100.0) 
          : (training.rpe * 10.0).clamp(0.0, 100.0));

    final sleepScore = compliance?.sleepScore ?? (telemetry != null && telemetry.sleepHours > 0 ? (telemetry.sleepHours / 8.0 * 100).clamp(0.0, 100.0) : 0.0);
    final nutritionScore = compliance?.nutritionScore ?? hub.nutritionScore;
    final hydrationScore = (telemetry != null && telemetry.hydrationGoalGlasses > 0) 
        ? (telemetry.hydrationGlasses / telemetry.hydrationGoalGlasses * 100).clamp(0.0, 100.0) 
        : (compliance?.hydrationScore ?? 0.0);
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
      suggestion: contextSuggestions.isNotEmpty ? contextSuggestions.first.body : dynamicInsight.message,
      hydrationScore: hydrationScore,
      nutritionScore: nutritionScore,
      sleepScore: sleepScore,
      trainingScore: trainingScore,
      fastingScore: fastingScore,
      exerciseActiveMinutes: exerciseMinutes,
      isTrainingActive: training.phase == TrainingSessionStep.active,
      exerciseCategoryLabel: training.category.title,
      hydrationLiters: telemetry?.hydrationLiters ?? (hub.hydrationLevel * 0.25),
      hydrationGoalLiters: telemetry?.hydrationGoalLiters ?? (hydrationGoalGlasses * 0.25),
      sleepHours: telemetry?.sleepHours ?? (hub.sleepMinutes / 60.0),
      nutritionKcal: telemetry?.nutritionKcal.toDouble() ?? todayLog?.calories.toDouble() ?? 0.0,
      userName: firstName.isNotEmpty ? firstName : 'tú',
      status: evaluator.status,
      statusLabel: evaluator.label,
      phase: phase,
      telemetry: telemetry,
      contextSuggestions: contextSuggestions,
    );

    // Persistencia Automática
    if (user != null) {
      _persistScore(user.uid, state.score.score);
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

// FIX: Declaración limpia de NotifierProvider
final elenaTodayProvider = NotifierProvider<ElenaTodayNotifier, ElenaTodayState>(() {
  return ElenaTodayNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// AUX PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final telemetryLoadingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(telemetryStreamProvider).isLoading;
});

final telemetryErrorProvider = Provider.autoDispose<Object?>((ref) {
  return ref.watch(telemetryStreamProvider).error;
});

final exerciseJustCompletedProvider = StateProvider<bool>((ref) => false);