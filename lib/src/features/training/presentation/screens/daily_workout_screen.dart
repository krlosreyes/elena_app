import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/training_engine_provider.dart';
import '../../application/daily_routine_provider.dart';
import '../../application/workout_submit_controller.dart';
import '../../domain/entities/training_entities.dart';
import '../../domain/entities/exercise.dart';
import '../../application/weekly_plan_provider.dart';
import '../../domain/entities/daily_workout.dart';
import '../../domain/enums/workout_enums.dart';
import '../../application/selected_day_provider.dart';
import '../widgets/rir_logging_slider.dart';
import '../widgets/exercise_set_row.dart';
import '../widgets/rest_timer_banner.dart';

class DailyWorkoutScreen extends ConsumerStatefulWidget {
  const DailyWorkoutScreen({super.key});

  static const String routeName = 'daily_workout';

  @override
  ConsumerState<DailyWorkoutScreen> createState() => _DailyWorkoutScreenState();
}

class _DailyWorkoutScreenState extends ConsumerState<DailyWorkoutScreen> {
  int _currentRir = 2; // Default starting value

  @override
  Widget build(BuildContext context) {
    // Listen to controller state changes
    ref.listen(workoutSubmitControllerProvider, (prev, next) {
      next.when(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Entrenamiento registrado con éxito"),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to Dashboard
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
        loading: () {}, // Handled by button state
      );
    });

    final recommendationAsync = ref.watch(trainingEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrenamiento de Hoy"),
      ),
      body: recommendationAsync.when(
        data: (recommendation) => Stack(
          children: [
            _buildContent(context, ref, recommendation),
            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: RestTimerBanner(),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WorkoutRecommendation recommendation) {
    final dailyExercises = ref.watch(dailyRoutineProvider);
    final submitState = ref.watch(workoutSubmitControllerProvider);
    final isSubmitting = submitState.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationCard(context, recommendation),
          const SizedBox(height: 24),
          
          // Weekly Calendar
          _buildWeeklyCalendar(context, ref),
          const SizedBox(height: 24),

          // Exercise List
          Text(
            "Tu Circuito de Hoy",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildExerciseList(context, dailyExercises, ref),
          const SizedBox(height: 32),

          // RIR Slider
          RirLoggingSlider(
            value: _currentRir,
            onChanged: (val) {
              setState(() {
                _currentRir = val;
              });
            },
          ),
          const SizedBox(height: 24),

          // CTA Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting 
                  ? null 
                  : () {
                      ref.read(workoutSubmitControllerProvider.notifier)
                         .submitWorkout(sessionRir: _currentRir);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Text(
                      "Terminar y Guardar Entrenamiento",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(BuildContext context, WidgetRef ref) {
    final weeklyPlan = ref.watch(weeklyPlanProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final todayIndex = DateTime.now().weekday; // 1=Mon, 7=Sun

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        final dayIndex = index + 1; // 1-based index
        final isToday = dayIndex == todayIndex;
        final isSelected = dayIndex == selectedDay;

        // dayIndex in plan is 1-based (Mon=1)
        final plannedWorkout = weeklyPlan.firstWhere(
            (w) => w.dayIndex == dayIndex,
            orElse: () => const DailyWorkout(
                dayIndex: 0,
                type: WorkoutType.rest,
                durationMinutes: 0,
                description: '',
                details: ''));

        Color backgroundColor;
        Color textColor;
        BoxBorder? border;

        if (isToday) {
          backgroundColor = Colors.green; // Requirement: Today always Green
          textColor = Colors.white;
        } else if (isSelected) {
          backgroundColor = AppTheme.brandBlue; // Requirement: Selected = Primary
          textColor = Colors.white;
        } else {
          backgroundColor = Colors.grey.shade100; // Inactive
          textColor = Colors.grey.shade600;
        }

        // Indicator dot color (Workout Type)
        Color indicatorColor;
        switch (plannedWorkout.type) {
          case WorkoutType.strength:
            indicatorColor = AppTheme.brandBlue;
            break;
          case WorkoutType.cardio:
            indicatorColor = Colors.orange;
            break;
          case WorkoutType.rest:
          default:
            indicatorColor = Colors.grey.shade300;
        }
        
        // If the day background is blue, the blue indicator disappears, 
        // so we might want to adjust logic or just keep it simple as requirement says "highlight backgound".
        if (isSelected && !isToday && plannedWorkout.type == WorkoutType.strength) {
             indicatorColor = Colors.white; 
        }

        return GestureDetector(
          onTap: () {
            ref.read(selectedDayProvider.notifier).selectDay(dayIndex);
          },
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: border,
                ),
                alignment: Alignment.center,
                child: Text(
                  days[index],
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Indicator dot
              CircleAvatar(
                  radius: 3,
                  backgroundColor: indicatorColor
              ),
            ],
          ),
        );
      }),
    );
  }



  Widget _buildRecommendationCard(BuildContext context, WorkoutRecommendation recommendation) {
    Color cardColor;
    IconData icon;

    switch (recommendation.type) {
      case 'Strength':
        cardColor = AppTheme.brandBlue;
        icon = Icons.fitness_center;
        break;
      case 'Cardio':
        cardColor = Colors.orange;
        icon = Icons.directions_run;
        break;
      case 'ActiveRecovery':
        cardColor = AppTheme.brandTeal;
        icon = Icons.spa;
        break;
      case 'Deload':
        cardColor = Colors.purple;
        icon = Icons.battery_charging_full;
        break;
      default:
        cardColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                recommendation.type.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            recommendation.targetMuscle != null 
                ? "Objetivo: ${recommendation.targetMuscle!.name.toUpperCase()}" 
                : "Objetivo: GENERAL",
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${recommendation.durationMinutes} Minutos  •  ${recommendation.intensity}",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              recommendation.notes,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildExerciseList(BuildContext context, List<Map<String, dynamic>> exercises, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final sets = exercise['sets'] as List<dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise['name'] as String,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        ),
                      ),
                    ),
                    Icon(Icons.info_outline, size: 20, color: Colors.grey.shade400)
                  ],
                ),
                const SizedBox(height: 12),
                
                // Sets List
                ...sets.map((set) {
                  return ExerciseSetRow(
                    setIndex: set['setIndex'] as int,
                    targetReps: set['targetReps'] as String, 
                    isDone: set['isDone'] as bool,
                    initialWeight: set['weight'] as double?,
                    initialReps: set['reps'] as int?,
                    onToggle: (weight, reps) {
                      ref.read(dailyRoutineProvider.notifier).toggleSet(
                        exercise['id'] as String,
                        set['setIndex'] as int,
                        weight,
                        reps
                      );
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
