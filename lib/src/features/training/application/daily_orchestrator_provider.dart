import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/entities/daily_workout.dart';
import '../domain/entities/workout_log.dart';
import '../data/repositories/training_repository.dart';
import 'calendar_state_provider.dart';
import 'weekly_plan_provider.dart';

part 'daily_orchestrator_provider.g.dart';

sealed class DailyWorkoutState {
  const DailyWorkoutState();
}

class DailyWorkoutLoading extends DailyWorkoutState {
  const DailyWorkoutLoading();
}

class DailyWorkoutPastCompleted extends DailyWorkoutState {
  final WorkoutLog log;
  final DailyWorkout? plannedWorkout;
  const DailyWorkoutPastCompleted(this.log, this.plannedWorkout);
}

class DailyWorkoutPastMissed extends DailyWorkoutState {
  final DailyWorkout? plannedWorkout;
  const DailyWorkoutPastMissed(this.plannedWorkout);
}

class DailyWorkoutToday extends DailyWorkoutState {
  final DailyWorkout? plannedWorkout;
  const DailyWorkoutToday(this.plannedWorkout);
}

class DailyWorkoutFuture extends DailyWorkoutState {
  final DailyWorkout? plannedWorkout;
  const DailyWorkoutFuture(this.plannedWorkout);
}

@riverpod
Future<DailyWorkoutState> dailyOrchestrator(Ref ref) async {
  final selectedDate = ref.watch(calendarStateProvider);
  final userAsync = ref.watch(authStateChangesProvider);
  
  final user = userAsync.value;
  if (user == null) {
      return const DailyWorkoutLoading();
  }

  final now = DateTime.now();
  
  // Normalize dates to midnight for comparison
  final today = DateTime(now.year, now.month, now.day);
  final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  
  // Get the plan for the selected day
  final weeklyPlan = ref.watch(weeklyPlanProvider);
  DailyWorkout? planForDay;
  
  try {
    // Weekday is 1-7 (Mon-Sun)
    // firstWhere throws if no element found unless orElse is provided, 
    // but here we catch the exception. Or we can use firstWhere(..., orElse: () => null) 
    // but DailyWorkout is not nullable in the list, so we can't return null from orElse easily 
    // without casting or using collection package firstWhereOrNull.
    // The try-catch block handles the StateError from firstWhere.
    planForDay = weeklyPlan.firstWhere((p) => p.dayIndex == selectedDate.weekday);
  } catch (_) {
    planForDay = null; 
  }

  // Future
  if (selected.isAfter(today)) {
    return DailyWorkoutFuture(planForDay);
  }

  // Today
  if (selected.isAtSameMomentAs(today)) {
    return DailyWorkoutToday(planForDay);
  }

  // Past
  if (selected.isBefore(today)) {
    // Check if there is a log for this date
    final repository = ref.watch(trainingRepositoryProvider);
    
    // Fetch log for the specific date
    final log = await repository.getWorkoutLogForDate(user.uid, selected);

    if (log != null) {
      return DailyWorkoutPastCompleted(log, planForDay);
    } else {
      return DailyWorkoutPastMissed(planForDay);
    }
  }

  return const DailyWorkoutLoading();
} 
