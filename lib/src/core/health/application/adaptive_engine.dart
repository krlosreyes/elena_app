import '../domain/decision_output.dart';
import '../domain/user_behavior_profile.dart';
import '../domain/user_health_state.dart';

/// Refines a base decision using user-specific behavioral adaptation signals.
///
/// Pure domain/application logic with deterministic outputs.
class AdaptiveEngine {
  const AdaptiveEngine();

  DecisionOutput adapt({
    required DecisionOutput baseDecision,
    required UserHealthState state,
    required UserBehaviorProfile profile,
  }) {
    String? personalizationReason;

    final sleepHours = _sleepHours(state);
    final severeFatigue =
        state.recoveryScore < 35 || (sleepHours > 0 && sleepHours < 4.5);
    final veryLowEnergy = state.energyScore < 35;

    // Critical rules are never overridden.
    if (veryLowEnergy) {
      return DecisionOutput.eatNow(
        pillarScores: baseDecision.pillarScores,
        mealSuggestion:
            'Comida simple y estable: proteína + carbohidrato complejo + hidratación.',
      ).copyWith(priority: 5);
    }

    if (severeFatigue) {
      final sleepDebt = (8.0 - sleepHours).clamp(0.0, 8.0);
      return DecisionOutput.rest(
        pillarScores: baseDecision.pillarScores,
        sleepDebt: sleepDebt,
      ).copyWith(priority: 5);
    }

    final baseKey = _actionKey(baseDecision);
    final fastingSuccess =
        profile.actionSuccessRates[_ActionKey.fastingContinue.value] ?? 0.5;
    final fastingAttempts =
        profile.actionHistoryCounts[_ActionKey.fastingContinue.value] ?? 0;
    final fastingOftenFails = fastingAttempts >= 3 && fastingSuccess < 0.45;

    final candidates = <_AdaptiveCandidate>[
      _AdaptiveCandidate(
        key: baseKey,
        output: baseDecision,
        score: 600.0 + (baseDecision.priority * 80.0),
      ),
      _AdaptiveCandidate(
        key: _ActionKey.eatNow,
        output: DecisionOutput.eatNow(
          pillarScores: baseDecision.pillarScores,
          mealSuggestion: 'Comida simple: proteína magra + vegetales + agua.',
        ),
        score: 500.0,
      ),
      _AdaptiveCandidate(
        key: _ActionKey.rest,
        output: DecisionOutput.rest(
          pillarScores: baseDecision.pillarScores,
          sleepDebt: (8.0 - sleepHours).clamp(0.0, 8.0),
        ),
        score: 480.0,
      ),
      _AdaptiveCandidate(
        key: _ActionKey.hydrate,
        output: DecisionOutput.hydrate(
          pillarScores: baseDecision.pillarScores,
          currentGlasses: state.dailyLog.waterGlasses,
          targetGlasses: 8,
        ),
        score: 420.0,
      ),
      _AdaptiveCandidate(
        key: _ActionKey.train,
        output: DecisionOutput.train(
          pillarScores: baseDecision.pillarScores,
          routineType: state.isFastingActive ? 'Zona 2' : 'Moderado',
          isFasted: state.isFastingActive,
        ),
        score: 410.0,
      ),
    ];

    if (state.isFastingActive) {
      candidates.add(
        _AdaptiveCandidate(
          key: _ActionKey.fastingContinue,
          output: DecisionOutput.fastingContinue(
            pillarScores: baseDecision.pillarScores,
            hoursElapsed: state
                .metabolicProfile.fastingContext.currentFastingElapsedHours,
          ),
          score: 450.0,
        ),
      );
    }

    for (final candidate in candidates) {
      final successRate =
          profile.actionSuccessRates[candidate.key.value] ?? 0.5;
      final attempts = profile.actionHistoryCounts[candidate.key.value] ?? 0;

      // Requirement 5: use actionSuccessRates to re-rank decisions.
      candidate.score += successRate * 160.0;

      // Slight confidence bonus when we have historical evidence.
      if (attempts >= 3) {
        candidate.score += 20.0;
      }

      // Requirement 1: high fasting tolerance biases toward continuing fasting.
      if (candidate.key == _ActionKey.fastingContinue &&
          profile.fastingTolerance >= 0.7 &&
          !fastingOftenFails) {
        candidate.score += 90.0;
      }

      // Requirement 2: if fasting often fails, reduce fasting recommendations.
      if (candidate.key == _ActionKey.fastingContinue && fastingOftenFails) {
        candidate.score -= 320.0;
      }

      if (candidate.key == _ActionKey.fastingContinue &&
          baseKey == _ActionKey.fastingContinue) {
        candidate.score += 30.0;
      }

      // Requirement 3: low training recovery rate reduces training suggestions.
      if (candidate.key == _ActionKey.train &&
          profile.trainingRecoveryRate < 0.45) {
        candidate.score -= 150.0;
      }
    }

    if (state.isFastingActive &&
        profile.fastingTolerance >= 0.7 &&
        !fastingOftenFails &&
        baseKey != _ActionKey.eatNow &&
        baseKey != _ActionKey.rest) {
      personalizationReason =
          'This recommendation is based on your strong fasting adaptation';
      for (final candidate in candidates) {
        if (candidate.key == _ActionKey.fastingContinue) {
          candidate.score += 320.0;
          break;
        }
      }
    }

    if (fastingOftenFails) {
      personalizationReason =
          'We reduced fasting recommendations because your recent fasting outcomes were low';
      for (final candidate in candidates) {
        if (candidate.key == _ActionKey.fastingContinue) {
          candidate.score -= 180.0;
        }
      }
    }

    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;

      final byPriority = b.output.priority.compareTo(a.output.priority);
      if (byPriority != 0) return byPriority;

      return a.key.value.compareTo(b.key.value);
    });

    var selected = candidates.first.output;

    // Requirement 4: low nutrition compliance => simplify recommendations.
    if (profile.nutritionCompliance < 0.4) {
      final simplifiedSecondary = selected.secondaryActions.take(2).toList();
      selected = selected.copyWith(
        explanation:
            'Enfoque simple y ejecutable hoy. Prioriza una sola acción clave.',
        secondaryActions: simplifiedSecondary,
      );
      personalizationReason =
          'This recommendation was simplified based on your current nutrition compliance';
    }

    final selectedChangedBase =
        selected.primaryAction != baseDecision.primaryAction ||
            selected.priority != baseDecision.priority;

    if (profile.trainingRecoveryRate < 0.45 &&
        _actionKey(selected) != _ActionKey.train) {
      personalizationReason ??=
          'Training intensity was adjusted due to your current recovery trend';
    }

    if (selectedChangedBase || personalizationReason != null) {
      selected = selected.copyWith(
        isPersonalized: true,
        personalizationReason: personalizationReason ??
            'This recommendation was personalized based on your behavioral history',
      );
    }

    return selected;
  }

  double _sleepHours(UserHealthState state) {
    final fromLog = state.sleepLog?.hours;
    if (fromLog != null && fromLog > 0) return fromLog;
    return state.dailyLog.sleepMinutes / 60.0;
  }

  _ActionKey _actionKey(DecisionOutput output) {
    final action = output.primaryAction.toLowerCase();

    if (action.contains('romper el ayuno') ||
        action.contains('momento de comer')) {
      return _ActionKey.eatNow;
    }
    if (action.contains('mantén tu ayuno') ||
        action.contains('mantener ayuno')) {
      return _ActionKey.fastingContinue;
    }
    if (action.contains('descanso')) return _ActionKey.rest;
    if (action.contains('entrenar')) return _ActionKey.train;
    if (action.contains('agua') || action.contains('hidrata')) {
      return _ActionKey.hydrate;
    }

    return _ActionKey.maintain;
  }
}

enum _ActionKey {
  fastingContinue('fasting_continue'),
  eatNow('eat_now'),
  rest('rest'),
  train('train'),
  hydrate('hydrate'),
  maintain('maintain');

  final String value;
  const _ActionKey(this.value);
}

class _AdaptiveCandidate {
  final _ActionKey key;
  final DecisionOutput output;
  double score;

  _AdaptiveCandidate({
    required this.key,
    required this.output,
    required this.score,
  });
}
