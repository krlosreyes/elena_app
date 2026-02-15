import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import '../domain/entities/daily_workout.dart';
import '../domain/enums/workout_enums.dart';
import '../domain/services/weekly_plan_generator.dart';

part 'weekly_plan_provider.g.dart';

@riverpod
List<DailyWorkout> weeklyPlan(WeeklyPlanRef ref) {
  // Watch the current user
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return WeeklyPlanGenerator.generate(WorkoutGoal.fatLoss, age: 30, hasDumbbells: false);
  }

  // Watch the full profile
  // Note: We use existing provider from user_repository
  // Since this is synchronous/provider-based, we need to handle AsyncValue if using a stream
  // Or simpler: just watch the stream and return [] when loading, or default.
  
  final userProfileAsync = ref.watch(userStreamProvider(user.uid));
  
  return userProfileAsync.when(
    data: (profile) {
      if (profile == null) return WeeklyPlanGenerator.generate(WorkoutGoal.fatLoss, age: 30, hasDumbbells: false);
      
      // Map HealthGoal to WorkoutGoal if needed, or use directly if they match
      // HealthGoal: fat_loss, muscle_gain, metabolic_health
      WorkoutGoal goal = WorkoutGoal.fatLoss;
      if (profile.healthGoal == HealthGoal.metabolic_health) goal = WorkoutGoal.recomp;

      return WeeklyPlanGenerator.generate(
        goal, 
        age: profile.age, 
        hasDumbbells: profile.hasDumbbells // <--- Passing equipment
      );
    },
    loading: () => [],
    error: (_, __) => WeeklyPlanGenerator.generate(WorkoutGoal.fatLoss, age: 30, hasDumbbells: false), // Fallback
  );
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
