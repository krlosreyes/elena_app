import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/entities/interactive_routine.dart';
import '../domain/entities/routine_cycle.dart';
import 'metabolic_checkin_provider.dart';

part 'training_engine_provider.freezed.dart';
part 'training_engine_provider.g.dart';

// Status Enum
enum TrainingStatus { needsDiagnostic, calculating, active }

// ==============================================================================
// 2. Training Engine (EXECUTION LAYER)
//    Manages the *state* of the active workout (Progress, Index, Validation)
// ==============================================================================

@freezed
sealed class TrainingSessionState with _$TrainingSessionState {
  const factory TrainingSessionState({
    @Default(0) int currentIndex,
    @Default(false) bool isDeload,
    @Default(false) bool isSessionActive,
    @Default(false) bool isExecuting, // Dynamic Feedback Visibility
    @Default(false) bool isResting, // New: Track Rest State
    @Default(TrainingStatus.needsDiagnostic) TrainingStatus status,
  }) = _TrainingSessionState;
}

@Riverpod(keepAlive: true)
class TrainingEngine extends _$TrainingEngine {
  @override
  TrainingSessionState build() {
    // 1. LISTEN: React to Check-in Updates (Submission)
    ref.listen(metabolicCheckinProvider, (prev, next) {
      next.whenData((checkin) {
        if (checkin != null) {
          // Ensure we re-validate date even on listen
          final today = DateTime.now();
          if (checkin.date.year == today.year &&
              checkin.date.month == today.month &&
              checkin.date.day == today.day) {
            state = state.copyWith(status: TrainingStatus.active);
          }
        }
      });
    });

    // 2. WATCH: Strict Initial State Guard
    final checkinAsync = ref.watch(metabolicCheckinProvider);
    final checkin = checkinAsync.asData?.value;

    // STRICT DATE VALIDATION (Application Layer)
    bool isValidForToday = false;
    if (checkin != null) {
      final today = DateTime.now();
      if (checkin.date.year == today.year &&
          checkin.date.month == today.month &&
          checkin.date.day == today.day) {
        isValidForToday = true;
      }
    }

    final impliedStatus = isValidForToday
        ? TrainingStatus.active
        : TrainingStatus.needsDiagnostic;

    return TrainingSessionState(status: impliedStatus);
  }

  void startDiagnostic() {
    state = state.copyWith(status: TrainingStatus.needsDiagnostic);
  }

  void initialize({required bool isDeload, int startIndex = 0}) {
    state = state.copyWith(
      isDeload: isDeload,
      currentIndex: startIndex,
      isSessionActive: true,
      isExecuting: false,
      isResting: false,
    );
  }

  /// Loads the engine state directly from a RoutineDay in the 8-week cycle
  void loadDayFromCycle(RoutineDay day, {RoutineWeek? week}) {
    // If week is provided, use its isDeload flag; otherwise default to false
    // or you could check a global context, but passing it is safer.
    final bool deload = week?.isDeload ?? false;

    initialize(isDeload: deload);
    // Note: Here you would eventually map `day.exercises` to `InteractiveExercise`
    // and store them in a state provider if the Engine manages the list.
    // For now, setting the deload and active state satisfies the infrastructure requirement.
  }

  /// Dynamic Visibility: Hide feedback during sets
  void setExecuting(bool isExecuting) {
    state = state.copyWith(isExecuting: isExecuting);
  }

  /// Rest State Management
  void setResting(bool isResting) {
    state = state.copyWith(
        isResting: isResting,
        isExecuting: !isResting // If resting, we are not executing
        );
  }

  void nextPage() {
    // Reset states on page change
    state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isExecuting: false,
        isResting: false);
  }

  void previousPage() {
    if (state.currentIndex > 0) {
      state = state.copyWith(
          currentIndex: state.currentIndex - 1,
          isExecuting: false,
          isResting: false);
    }
  }

  bool isExerciseComplete(InteractiveExercise exercise) {
    if (exercise.sets.isEmpty) return false;
    return exercise.sets.every((s) => s.isDone);
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void endSession() {
    state = state.copyWith(
        isSessionActive: false,
        currentIndex: 0,
        isExecuting: false,
        isResting: false);
  }
}
