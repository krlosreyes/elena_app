import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/entities/training_entities.dart';
import '../domain/entities/interactive_routine.dart';
import '../data/repositories/training_repository.dart';
import '../../../core/science/training_physiology.dart';
import 'metabolic_checkin_provider.dart'; // Added Import
import '../domain/entities/metabolic_state.dart'; // Often needed for phase? No, just logic.

import 'metabolic_checkin_provider.dart'; // Added Import

part 'training_engine_provider.freezed.dart';
part 'training_engine_provider.g.dart';

// Status Enum
enum TrainingStatus { needsDiagnostic, calculating, active }

// ==============================================================================
// 2. Training Engine (EXECUTION LAYER)
//    Manages the *state* of the active workout (Progress, Index, Validation)
// ==============================================================================

@freezed
class TrainingSessionState with _$TrainingSessionState {
  const factory TrainingSessionState({
    @Default(0) int currentIndex,
    @Default(false) bool isDeload,
    @Default(false) bool isSessionActive,
    @Default(TrainingStatus.needsDiagnostic) TrainingStatus status, // New Status Logic
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
              // Ensure we re-validate date even on listen, though usually submission is for 'now'.
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
    final checkin = checkinAsync.valueOrNull;

    // STRICT DATE VALIDATION (Application Layer)
    // Check if check-in exists for TODAY (DateTime.now).
    bool isValidForToday = false;
    if (checkin != null) {
       final today = DateTime.now();
       if (checkin.date.year == today.year && 
           checkin.date.month == today.month && 
           checkin.date.day == today.day) {
           isValidForToday = true;
       }
    }

    // Determine status from data availability & validity
    final impliedStatus = isValidForToday 
        ? TrainingStatus.active 
        : TrainingStatus.needsDiagnostic;

    return TrainingSessionState(status: impliedStatus);
  }

  // Explicitly start check-in (optional)
  void startDiagnostic() {
    state = state.copyWith(status: TrainingStatus.needsDiagnostic);
  }

  void initialize({required bool isDeload, int startIndex = 0}) {
    // Preserve status!
    state = state.copyWith(
      isDeload: isDeload,
      currentIndex: startIndex,
      isSessionActive: true,
      // If initialized, it implies active, but let's trust the build logic/watch.
    );
  }

  void nextPage() {
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }
  
  void previousPage() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
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
      state = state.copyWith(isSessionActive: false, currentIndex: 0);
  }
}
