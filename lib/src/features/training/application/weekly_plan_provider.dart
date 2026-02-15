import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/daily_workout.dart';
import '../domain/enums/workout_enums.dart';
import '../domain/services/weekly_plan_generator.dart';

part 'weekly_plan_provider.g.dart';

@riverpod
List<DailyWorkout> weeklyPlan(WeeklyPlanRef ref) {
  // TODO: Retrieve actual user goal from Onboarding/User Provider
  const userGoal = WorkoutGoal.fatLoss; 

  return WeeklyPlanGenerator.generate(userGoal);
}

@riverpod
DailyWorkout? todayWorkout(TodayWorkoutRef ref) {
  final plan = ref.watch(weeklyPlanProvider);
  final todayIndex = DateTime.now().weekday; // 1=Mon, 7=Sun

  // Generate a plan if empty (shouldn't happen with sync generator but safe)
  if (plan.isEmpty) return null;

  try {
    return plan.firstWhere((w) => w.dayIndex == todayIndex);
  } catch (e) {
    return null;
  }
}
