import 'dart:developer' as developer;

import '../domain/decision_output.dart';
import '../domain/user_health_state.dart';

/// Rule-based decision engine (no AI) that resolves cross-pillar conflicts
/// and returns a single prioritized decision.
class DecisionEngine {
  const DecisionEngine();

  DecisionOutput decide(UserHealthState state, {DateTime? now}) {
    final referenceNow = now ?? DateTime.now();
    _assertValidState(state);

    final pillarScores = _buildPillarScores(state);
    final candidates = <_DecisionCandidate>[];

    final energy = state.energyScore;
    final recovery = state.recoveryScore;
    final fastingHours =
        state.metabolicProfile.fastingContext.currentFastingElapsedHours;
    final fastingActive = state.isFastingActive;
    final feedingWindow = state.isInFeedingWindow;

    final sleepHours = _sleepHours(state);
    final hydrationDeficit = _hydrationDeficit(state);
    final recentMealHours = _hoursSinceLastMeal(state, referenceNow);

    developer.log(
      'DecisionEngine.decide input energy=${energy.toStringAsFixed(1)} '
      'recovery=${recovery.toStringAsFixed(1)} fastingActive=$fastingActive '
      'fastingHours=${fastingHours.toStringAsFixed(2)} '
      'sleepHours=${sleepHours.toStringAsFixed(2)} '
      'hydrationDeficit=$hydrationDeficit recentMealHours=$recentMealHours',
      name: 'core.health.DecisionEngine',
    );

    final veryLowEnergy = energy < 35;
    final lowEnergy = energy < 50;
    final veryPoorSleep = sleepHours > 0 && sleepHours < 5.0;
    final poorSleep = sleepHours > 0 && sleepHours < 6.5;
    final veryLongFast = fastingActive && fastingHours >= 18.0;
    final lowRecovery = recovery < 45;
    final highEnergy = energy >= 75;
    final dehydrated = hydrationDeficit >= 2;

    // ───────────────────────────────────────────────────────────────────────
    // CRITICAL
    // ───────────────────────────────────────────────────────────────────────

    if (veryLowEnergy || (veryLongFast && lowEnergy)) {
      candidates.add(
        _DecisionCandidate(
          tier: _DecisionTier.critical,
          score: 950 + (veryLongFast ? 20 : 0),
          output: DecisionOutput.eatNow(
            pillarScores: pillarScores,
            mealSuggestion: _mealSuggestion(state),
          ).copyWith(priority: 5),
        ),
      );
    }

    if (veryPoorSleep) {
      candidates.add(
        _DecisionCandidate(
          tier: _DecisionTier.critical,
          score: 920,
          output: DecisionOutput.rest(
            pillarScores: pillarScores,
            sleepDebt: (8.0 - sleepHours).clamp(0.0, 8.0),
          ).copyWith(priority: 5),
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────────────
    // HIGH
    // ───────────────────────────────────────────────────────────────────────

    if (feedingWindow && lowEnergy && _needsMealNow(state, recentMealHours)) {
      candidates.add(
        _DecisionCandidate(
          tier: _DecisionTier.high,
          score: 780,
          output: DecisionOutput.eatNow(
            pillarScores: pillarScores,
            mealSuggestion: _mealSuggestion(state),
          ).copyWith(priority: 4),
        ),
      );
    }

    if (poorSleep || lowRecovery) {
      candidates.add(
        _DecisionCandidate(
          tier: _DecisionTier.high,
          score: 760,
          output: DecisionOutput.rest(
            pillarScores: pillarScores,
            sleepDebt: (8.0 - sleepHours).clamp(0.0, 8.0),
          ).copyWith(priority: 4),
        ),
      );
    }

    if (dehydrated) {
      candidates.add(
        _DecisionCandidate(
          tier: _DecisionTier.high,
          score: 740 + (hydrationDeficit * 5),
          output: DecisionOutput.hydrate(
            pillarScores: pillarScores,
            currentGlasses: state.dailyLog.waterGlasses,
            targetGlasses: 8,
          ).copyWith(priority: 4),
        ),
      );
    }

    if (fastingActive) {
      candidates.add(
        _DecisionCandidate(
          tier: _DecisionTier.high,
          score: 700 + fastingHours.clamp(0.0, 20.0).toInt(),
          output: DecisionOutput.fastingContinue(
            pillarScores: pillarScores,
            hoursElapsed: fastingHours,
          ).copyWith(priority: 3),
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────────────
    // MEDIUM
    // ───────────────────────────────────────────────────────────────────────

    if (highEnergy && recovery >= 65 && !poorSleep) {
      candidates.add(
        _DecisionCandidate(
          tier: _DecisionTier.medium,
          score: 550,
          output: DecisionOutput.train(
            pillarScores: pillarScores,
            routineType: fastingActive ? 'Zona 2' : 'Potencia',
            isFasted: fastingActive,
          ).copyWith(priority: 3),
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────────────
    // LOW (fallback optimization)
    // ───────────────────────────────────────────────────────────────────────

    candidates.add(
      _DecisionCandidate(
        tier: _DecisionTier.low,
        score: 100,
        output: DecisionOutput(
          primaryAction: 'Mantén el plan actual y optimiza detalles.',
          explanation:
              'No hay señales críticas en los pilares. Mantén adherencia y '
              'ajusta calidad de comida, hidratación y descanso.',
          secondaryActions: const [
            'Prioriza proteína en la próxima comida.',
            'Haz 10–20 minutos de caminata suave postprandial.',
            'Mantén consistencia en el horario de sueño.',
          ],
          pillarScores: pillarScores,
          metabolicState: fastingActive ? 'fat_burning' : 'recovery',
          priority: 1,
        ),
      ),
    );

    // Conflict resolution by score: CRITICAL > HIGH > MEDIUM > LOW.
    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;

      final byTier = _tierRank(b.tier).compareTo(_tierRank(a.tier));
      if (byTier != 0) return byTier;

      final byPriority = b.output.priority.compareTo(a.output.priority);
      if (byPriority != 0) return byPriority;

      return a.output.primaryAction.compareTo(b.output.primaryAction);
    });

    final selected = candidates.first.output;
    developer.log(
      'DecisionEngine.decide selected action="${selected.primaryAction}" '
      'priority=${selected.priority} candidates=${candidates.length}',
      name: 'core.health.DecisionEngine',
    );

    return selected;
  }

  void _assertValidState(UserHealthState state) {
    final energy = state.energyScore;
    final recovery = state.recoveryScore;
    final metabolic = state.metabolicScore;
    final fastingHours =
        state.metabolicProfile.fastingContext.currentFastingElapsedHours;

    assert(
      energy.isFinite && energy >= 0.0 && energy <= 100.0,
      'Invalid energyScore: $energy',
    );
    assert(
      recovery.isFinite && recovery >= 0.0 && recovery <= 100.0,
      'Invalid recoveryScore: $recovery',
    );
    assert(
      metabolic.isFinite && metabolic >= 0.0 && metabolic <= 100.0,
      'Invalid metabolicScore: $metabolic',
    );
    assert(
      fastingHours.isFinite && fastingHours >= 0.0,
      'Invalid fasting elapsed hours: $fastingHours',
    );
    assert(
      state.dailyLog.id.isNotEmpty,
      'DailyLog id must not be empty.',
    );
  }

  Map<String, double> _buildPillarScores(UserHealthState state) {
    final fastingHours =
        state.metabolicProfile.fastingContext.currentFastingElapsedHours;
    final hydration =
        (state.dailyLog.waterGlasses / 8.0 * 100.0).clamp(0.0, 100.0);
    final sleep = (_sleepHours(state) / 8.0 * 100.0).clamp(0.0, 100.0);
    final training = state.recoveryScore.clamp(0.0, 100.0);

    final mealCount = state.dailyLog.mealEntries.length;
    final tdee = state.metabolicProfile.tdee;
    final calories = state.dailyLog.calories.toDouble();
    final adherence = tdee > 0
        ? (1.0 - ((calories - tdee).abs() / tdee)).clamp(0.0, 1.0)
        : 0.5;
    final nutrition =
        ((mealCount > 0 ? 40.0 : 20.0) + (adherence * 60.0)).clamp(0.0, 100.0);

    final fasting = state.isFastingActive
        ? (55.0 + (fastingHours * 2.0)).clamp(0.0, 100.0)
        : 50.0;

    return {
      DecisionOutput.fastingPillar: fasting,
      DecisionOutput.nutritionPillar: nutrition,
      DecisionOutput.trainingPillar: training,
      DecisionOutput.hydrationPillar: hydration,
      DecisionOutput.sleepPillar: sleep,
    };
  }

  double _sleepHours(UserHealthState state) {
    final fromLog = state.sleepLog?.hours;
    if (fromLog != null && fromLog > 0) return fromLog;
    return state.dailyLog.sleepMinutes / 60.0;
  }

  int _hydrationDeficit(UserHealthState state) {
    final deficit = 8 - state.dailyLog.waterGlasses;
    return deficit < 0 ? 0 : deficit;
  }

  double? _hoursSinceLastMeal(UserHealthState state, DateTime referenceNow) {
    DateTime? latest;

    for (final meal in state.dailyLog.mealEntries) {
      final timestamp = meal['timestamp'];
      final parsed = _parseDateTime(timestamp);
      if (parsed == null) continue;

      if (latest == null || parsed.isAfter(latest)) {
        latest = parsed;
      }
    }

    if (latest == null) return null;
    return referenceNow.difference(latest).inMinutes / 60.0;
  }

  bool _needsMealNow(UserHealthState state, double? hoursSinceLastMeal) {
    if (state.dailyLog.mealEntries.isEmpty) return true;
    if (hoursSinceLastMeal == null) return false;
    return hoursSinceLastMeal >= 4.0;
  }

  String _mealSuggestion(UserHealthState state) {
    if (state.dailyLog.mealEntries.isEmpty) {
      return 'Inicia con una comida completa: 30–40g proteína + fibra + grasa saludable.';
    }

    return 'Haz una comida de recuperación con proteína magra y carbohidrato complejo.';
  }

  DateTime? _parseDateTime(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input;
    if (input is String) {
      return DateTime.tryParse(input);
    }
    if (input is int) {
      return DateTime.fromMillisecondsSinceEpoch(input);
    }

    try {
      final dynamic toDate = (input as dynamic).toDate();
      if (toDate is DateTime) return toDate;
    } catch (_) {
      // Ignore unsupported timestamp type.
    }

    return null;
  }

  int _tierRank(_DecisionTier tier) {
    return switch (tier) {
      _DecisionTier.critical => 4,
      _DecisionTier.high => 3,
      _DecisionTier.medium => 2,
      _DecisionTier.low => 1,
    };
  }
}

enum _DecisionTier { critical, high, medium, low }

class _DecisionCandidate {
  final _DecisionTier tier;
  final int score;
  final DecisionOutput output;

  const _DecisionCandidate({
    required this.tier,
    required this.score,
    required this.output,
  });
}
