import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';

import '../widgets/rest_timer_banner.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/workout_submit_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/workout_submit_controller.dart';
import '../../application/daily_orchestrator_provider.dart';
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
    return switch (state) {
      DailyWorkoutLoading() => const Center(child: CircularProgressIndicator()),
      
      DailyWorkoutPastCompleted(log: final log) => PastWorkoutSummaryView(log: log),
      
      DailyWorkoutPastMissed() => MissedWorkoutView(onManualLog: () {
            // TODO: Navigate to manual log screen or open dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registro manual pendiente de implementar")),
            );
          }),
      
      DailyWorkoutFuture(plannedWorkout: final plan) => _buildReadOnlyPlan(plan),
      
      DailyWorkoutToday(plannedWorkout: final plan) => _buildInteractivePlan(context, plan),
    };
  }

  Widget _buildReadOnlyPlan(DailyWorkout? plan) {
    if (plan == null) return const RestDayView();
    // Re-use views but maybe in read-only mode, or simple text for now
    // For MVP, just showing the plan description
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Plan Futuro: ${plan.description}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            plan.details,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePlan(BuildContext context, DailyWorkout? plan) {
    if (plan == null) return const RestDayView();

    // Show Metabolic Banner for active days
    // We can wrap it in a Column
    
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: MetabolicInsightBanner(),
        ),
        Expanded(
          child: _buildWorkoutView(context, plan, false),
        ),
        const RestTimerBanner(), 
      ],
    );
  }

  Widget _buildWorkoutView(BuildContext context, DailyWorkout plan, bool isCompleted) {
    switch (plan.type) {
      case WorkoutType.strength:
        // Map DailyWorkout plan description to Recommendation object required by view
        final recommendation = WorkoutRecommendation(
            type: 'Strength', 
            targetMuscle: null, 
            durationMinutes: plan.durationMinutes, 
            intensity: plan.details, 
            notes: plan.description
        );
        return StrengthWorkoutView(recommendation: recommendation);

      case WorkoutType.cardio:
        return CardioWorkoutView(plan: plan, isCompleted: isCompleted);

      case WorkoutType.rest:
      default:
        return const RestDayView();
    }
  }
}






