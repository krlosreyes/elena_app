import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';

import '../widgets/rest_timer_banner.dart';


import '../../application/daily_orchestrator_provider.dart';
import '../../application/workout_submit_controller.dart';
import '../../domain/enums/workout_enums.dart';
import '../../domain/entities/training_entities.dart';
import '../../domain/entities/daily_workout.dart';
import '../../domain/entities/workout_log.dart';

// Views
import '../widgets/strength_workout_view.dart';
import '../widgets/cardio_workout_view.dart';
import '../widgets/rest_day_view.dart';
import '../widgets/weekly_calendar_strip.dart';
import '../widgets/rest_timer_banner.dart';
import '../widgets/metabolic_insight_banner.dart';
import '../widgets/past_workout_summary_view.dart';
import '../widgets/missed_workout_view.dart';
import 'training_stats_screen.dart';

class DailyWorkoutScreen extends ConsumerWidget {
  const DailyWorkoutScreen({super.key});

  static const String routeName = 'daily_workout';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to submission status
    ref.listen(workoutSubmitControllerProvider, (prev, next) {
      next.when(
        data: (_) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Entrenamiento registrado con éxito"),
              backgroundColor: Colors.green,
            ),
          );
          // With new logic, maybe we don't go dashboard but stay on date which now becomes PastCompleted
          // But requirement says go to summary or handled by view. 
          // WorkoutSubmitController should perform navigation or invalidation.
          // Invalidating orchestrator updates the view to PastCompleted.
          ref.invalidate(dailyOrchestratorProvider);
        },
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${err.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {},
      );
    });

    final orchestratorAsync = ref.watch(dailyOrchestratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan de Entrenamiento"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.pushNamed(TrainingStatsScreen.routeName),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: WeeklyCalendarStrip(),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: orchestratorAsync.when(
              data: (state) => _buildBody(context, state),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          
          // Timer Banner (Floating) - Only show if interactive
          // Logic could differ, but keeping it simple for now
          // Ideally check if state is Today and workout is active
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DailyWorkoutState state) {
    // Default fallback
    if (state is DailyWorkoutLoading) { 
      return const Center(child: CircularProgressIndicator());
    }

    // Map State to Display Mode & Plan
    final WorkoutDisplayMode mode;
    final DailyWorkout? plan;
    final bool isCompleted;

    switch (state) {
      case DailyWorkoutPastCompleted(log: final log, plannedWorkout: final p):
         mode = WorkoutDisplayMode.completed;
         plan = p; 
         isCompleted = true;
         break;
      case DailyWorkoutPastMissed(plannedWorkout: final p):
         mode = WorkoutDisplayMode.retroactive;
         plan = p;
         isCompleted = false;
         break;
      case DailyWorkoutFuture(plannedWorkout: final p):
         mode = WorkoutDisplayMode.readOnly;
         plan = p;
         isCompleted = false;
         break;
      case DailyWorkoutToday(plannedWorkout: final p):
         mode = WorkoutDisplayMode.active;
         plan = p;
         isCompleted = false;
         break;
      default:
         mode = WorkoutDisplayMode.readOnly;
         plan = null;
         isCompleted = false;
    }

    // Resolving Plan if null (e.g. PastCompleted didn't carry it in previous step)
    // Actually, DailyWorkoutPastCompleted in orchestrator *should* be updated to carry plan.
    // But let's see if we can get it from context.
    // If plan is null here, we effectively show Rest Day.
    
    // Quick Fix: render Rest Day if plan is null, unless we can get it.
    if (plan == null && mode != WorkoutDisplayMode.completed) return const RestDayView();
    
    // For completed, we might not have the plan if Orchestrator didn't pass it.
    // But we need to show *something*.
    // If it is completed, we prioritize the Log info, but existing views expect a Plan.
    // Let's fallback to "Entrenamiento Completado" simple view if we can't show details.
    // OR, we assume Orchestrator *will* pass plan in next iteration.
    // Let's assume plan is available or return Rest View.
    
    final finalPlan = plan; 
    
    if (finalPlan == null) {
       // If completed, stick to old summary view for now as fallback?
       if (state is DailyWorkoutPastCompleted) return PastWorkoutSummaryView(log: state.log);
       return const RestDayView(); 
    }

    return _buildWorkoutView(context, finalPlan, isCompleted, mode);
  }

  Widget _buildWorkoutView(BuildContext context, DailyWorkout plan, bool isCompleted, WorkoutDisplayMode mode) {
    switch (plan.type) {
      case WorkoutType.strength:
        final recommendation = WorkoutRecommendation(
            type: 'Strength', 
            targetMuscle: null, 
            durationMinutes: plan.durationMinutes, 
            intensity: plan.details, 
            notes: plan.description
        );
        return StrengthWorkoutView(recommendation: recommendation, mode: mode);

      case WorkoutType.cardio:
        return CardioWorkoutView(plan: plan, isCompleted: isCompleted, mode: mode);

      case WorkoutType.rest:
      default:
        return const RestDayView();
    }
  }
}






