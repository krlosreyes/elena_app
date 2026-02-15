import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/daily_workout.dart';
import '../domain/entities/workout_log.dart';
import '../domain/enums/workout_enums.dart';
import 'selected_date_provider.dart';
import 'weekly_plan_provider.dart';

part 'daily_workout_orchestrator.freezed.dart';
part 'daily_workout_orchestrator.g.dart';

@freezed
class SingleWorkoutState with _$SingleWorkoutState {
  const factory SingleWorkoutState({
    required DailyWorkout plan,
    required DateTime date,
    required bool isCompleted,
    WorkoutLog? log,
  }) = _SingleWorkoutState;
}

@riverpod
SingleWorkoutState dailyWorkoutOrchestrator(DailyWorkoutOrchestratorRef ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final weeklyPlan = ref.watch(weeklyPlanProvider);
  
  // 1. Determine Plan for the selected date
  final dayIndex = selectedDate.weekday; // 1=Mon, 7=Sun
  
  final plannedWorkout = weeklyPlan.firstWhere(
    (w) => w.dayIndex == dayIndex,
    orElse: () => const DailyWorkout(
      dayIndex: 0,
      type: WorkoutType.rest,
      durationMinutes: 0,
      description: 'Descanso',
      details: 'Recuperación',
    ),
  );

  // 2. Mock History Check
  // In a real app, this would watch a 'workoutHistoryProvider' or call a Repository
  final isToday = selectedDate.year == DateTime.now().year &&
      selectedDate.month == DateTime.now().month &&
      selectedDate.day == DateTime.now().day;
  
  final isPast = selectedDate.isBefore(DateTime(
    DateTime.now().year, 
    DateTime.now().month, 
    DateTime.now().day
  ));

  // Mock: If it's a past date and it was a strength day (Mon/Wed/Fri logic), assume completed.
  // Just for demonstration purposes as per user request.
  bool isCompleted = false;
  WorkoutLog? mockLog;

  if (isPast && (dayIndex == 1 || dayIndex == 3)) { // Mon or Wed in past
     isCompleted = true;
     // Create a mock log if needed
  }

  return SingleWorkoutState(
    plan: plannedWorkout,
    date: selectedDate,
    isCompleted: isCompleted,
    log: mockLog,
  );
}
