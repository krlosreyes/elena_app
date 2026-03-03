import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../authentication/application/auth_controller.dart';


import '../../application/daily_orchestrator_provider.dart';
import '../../application/workout_submit_controller.dart';
import '../../application/training_engine_provider.dart'; 
import '../../application/metabolic_checkin_provider.dart'; // Added Import
// Added Import
import '../../domain/enums/workout_enums.dart';
import '../../domain/entities/training_entities.dart';
import '../../domain/entities/daily_workout.dart';

// Views
import '../widgets/strength_workout_view.dart';
import 'workout_summary_screen.dart'; // Added Import
import '../widgets/cardio_workout_view.dart';
import '../widgets/rest_day_view.dart';
import '../widgets/weekly_calendar_strip.dart';
import '../widgets/metabolic_insight_banner.dart';
// import '../widgets/past_workout_summary_view.dart'; // Unused
import '../widgets/daily_diagnostic_card.dart'; // Added Import


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
          // With new logic, navigation is handled by the specific workout view (Strength/Cardio).
          // We DO NOT invalidate here to avoid unmounting the widget before navigation completes.
          // Invalidation will happen inside the view *after* pushing the summary route.
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
        actions: const [],
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
              data: (state) => _buildBody(context, ref, state),
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

  Widget _buildBody(BuildContext context, WidgetRef ref, DailyWorkoutState state) {
    // Default fallback
    if (state is DailyWorkoutLoading) { 
      return const Center(child: CircularProgressIndicator());
    }

    // BLOCKING NAVIGATION: If Completed, show Summary directly
    if (state is DailyWorkoutPastCompleted) {
       // Use the new summary screen directly
       return WorkoutSummaryScreen(log: state.log);
    }

    // Map State to Display Mode & Plan
    final WorkoutDisplayMode mode;
    final DailyWorkout? plan;
    final bool isCompleted;

    switch (state) {
      // PastCompleted is handled above now.
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
    
    final finalPlan = plan; 
    
    if (finalPlan == null) {
       return const RestDayView(); 
    }

    return _buildWorkoutView(context, ref, finalPlan, isCompleted, mode);
  }

  Widget _buildWorkoutView(BuildContext context, WidgetRef ref, DailyWorkout plan, bool isCompleted, WorkoutDisplayMode mode) {
    switch (plan.type) {
      case WorkoutType.strength:
        // STATE GUARDIAN LOGIC (Revised: Single-Card Flow)
        // 1. Loading Guard (Directly watch checkin provider to prevent flash)
        final checkinAsync = ref.watch(metabolicCheckinProvider);
        
        if (checkinAsync.isLoading) {
           return const Center(child: CircularProgressIndicator());
        }

        if (checkinAsync.hasError) {
           return Center(child: Text("Error: ${checkinAsync.error}"));
        }

        // 2. STATUS ENGINE (Strict Logic from TrainingEngine)
        final engineState = ref.watch(trainingEngineProvider);
        final status = engineState.status;
        final isCompleted = status == TrainingStatus.active; // Strict active check

        final checkin = checkinAsync.asData?.value;

        // User Data for Personalization
        final user = ref.watch(authControllerProvider.notifier).currentUser;
        final displayName = user?.displayName?.split(' ').first ?? 'Atleta';
        
        // Layout Hierarchy:
        if (isCompleted) {
            return StrengthWorkoutView(
                key: const ValueKey('WorkoutView'),
                recommendation: WorkoutRecommendation(
                    type: 'Strength', 
                    targetMuscle: null, 
                    durationMinutes: plan.durationMinutes, 
                    intensity: plan.details, 
                    notes: plan.description
                ),
                mode: mode,
                hideHeader: false, // Internal header can be shown or not depending on its own logic (which we fixed already)
            );
        } else {
            return Column(
            children: [
                // 1. FIXED HEADER
                Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                color: Colors.white,
                child: Column(
                    children: [
                    // Top Row: Title & Badge
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Expanded(
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                    "ENTRENAMIENTO DE HOY",
                                    style: GoogleFonts.outfit(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.grey.shade500,
                                        letterSpacing: 1.2,
                                    ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                    "Diagnóstico Diario",     // Incomplete
                                    style: GoogleFonts.outfit(
                                        fontSize: 22, 
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.1,
                                    ),
                                    ),
                                ],
                                ),
                            ),
                            // Badge
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                color: AppTheme.brandBlue,
                                borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                plan.description, // e.g. "FullBody B"
                                style: GoogleFonts.outfit(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                ),
                                ),
                            ),
                        ],
                    ),
                    
                    const SizedBox(height: 12),
                    ],
                ),
                ),

                // 2. DYNAMIC SPACE (Diagnostic Card)
                Expanded(
                child: SingleChildScrollView(
                    key: const ValueKey('DiagnosticForm'),
                    child: DailyDiagnosticCard(
                        userDisplayName: displayName,
                    ),
                ),
                ),
            ],
            );
        }

      case WorkoutType.cardio:
        return CardioWorkoutView(plan: plan, isCompleted: isCompleted, mode: mode);

      case WorkoutType.rest:
        return const RestDayView();

    }
  }
}






