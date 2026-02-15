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
import '../../application/daily_workout_orchestrator.dart';
import '../../domain/enums/workout_enums.dart';
import '../../domain/entities/training_entities.dart';

// Views
import '../widgets/strength_workout_view.dart';
import '../widgets/cardio_workout_view.dart';
import '../widgets/rest_day_view.dart';
import '../widgets/weekly_calendar_strip.dart';
import '../widgets/rest_timer_banner.dart';
import '../widgets/metabolic_insight_banner.dart';

class DailyWorkoutScreen extends ConsumerWidget {
  const DailyWorkoutScreen({super.key});

  static const String routeName = 'daily_workout';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to submission status for global feedback specific to this screen
    ref.listen(workoutSubmitControllerProvider, (prev, next) {
      next.when(
        data: (_) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Entrenamiento registrado con éxito"),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/dashboard'); 
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

    final orchestratorState = ref.watch(dailyWorkoutOrchestratorProvider);

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
          // Metabolic Insight (Conditional)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: MetabolicInsightBanner(),
          ),
          Expanded(
            child: _buildBody(context, orchestratorState),
          ),
          // Timer Banner (Floating)
          const RestTimerBanner(), 
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, SingleWorkoutState state) {
    if (state.isCompleted) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              "¡Entrenamiento completado!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (state.log != null)
               const Padding(
                 padding: EdgeInsets.only(top: 8.0),
                 child: Text("Ver detalles en el historial"),
               ),
          ],
        ),
      );
    }

    switch (state.plan.type) {
      case WorkoutType.strength:
        // Map DailyWorkout plan description to Recommendation object required by view
        // Ideally we fetch the real recommendation, but for now we construct it from the plan
        final recommendation = WorkoutRecommendation(
            type: 'Strength', 
            targetMuscle: null, 
            durationMinutes: state.plan.durationMinutes, 
            intensity: state.plan.details, 
            notes: state.plan.description
        );
        return StrengthWorkoutView(recommendation: recommendation);

      case WorkoutType.cardio:
        return CardioWorkoutView(plan: state.plan, isCompleted: state.isCompleted);

      case WorkoutType.rest:
      default:
        return const RestDayView();
    }
  }
}



