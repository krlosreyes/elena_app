import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/training_entities.dart';

part 'training_cycle_controller.g.dart';

@Riverpod(keepAlive: true)
class TrainingCycleController extends _$TrainingCycleController {
  @override
  TrainingCycle build() {
    // TODO: Load from Repository. For now, default start.
    // Ideally: return ref.read(trainingRepositoryProvider).getTrainingCycle() ?? initial;
    return const TrainingCycle(
        sessionCount: 0, isDeloadActive: false, cycleNumber: 1);
  }

  void incrementSession() {
    final current = state;
    if (current.isDeloadActive) {
      return; // Don't count deload sessions towards the next block yet? Or do we?
    }
    // User story: "Al llegar a la sesión #24... activa isDeloadWeek"

    int newCount = current.sessionCount + 1;
    bool triggerDeload = newCount >= 24;

    // Auto-trigger Deload
    if (triggerDeload) {
      state = current.copyWith(
        sessionCount: newCount,
        isDeloadActive: true,
        deloadStartDate: DateTime.now(),
      );
    } else {
      state = current.copyWith(sessionCount: newCount);
    }

    // Save to Repo
    _saveState();
  }

  void completeDeload() {
    final current = state;
    // Reset for next cycle
    state = current.copyWith(
      sessionCount: 0,
      isDeloadActive: false,
      cycleNumber: current.cycleNumber + 1,
      deloadStartDate: null,
    );
    _saveState();
  }

  // Debug/Dev tools
  void setDeloadMode(bool isActive) {
    state = state.copyWith(isDeloadActive: isActive);
    _saveState();
  }

  void _saveState() {
    // ref.read(trainingRepositoryProvider).saveCycle(state);
  }
}
