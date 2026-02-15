import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/training_engine_provider.dart';
import '../../application/daily_routine_provider.dart';
import '../../domain/entities/training_entities.dart';
import '../../domain/entities/exercise.dart';
import '../widgets/rir_logging_slider.dart';
import '../widgets/exercise_set_row.dart';

class DailyWorkoutScreen extends ConsumerWidget {
  const DailyWorkoutScreen({super.key});

  static const String routeName = 'daily_workout';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationAsync = ref.watch(trainingEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrenamiento de Hoy"),
      ),
      body: recommendationAsync.when(
        data: (recommendation) => _buildContent(context, ref, recommendation),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WorkoutRecommendation recommendation) {
    final dailyExercises = ref.watch(dailyRoutineProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationCard(context, recommendation),
          const SizedBox(height: 24),
          
          // Weekly Calendar
          _buildWeeklyCalendar(context),
          const SizedBox(height: 24),

          // Exercise List
          Text(
            "Tu Circuito de Hoy",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildExerciseList(context, dailyExercises, ref),
          const SizedBox(height: 32),

          // CTA Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Entrenamiento registrado con éxito")),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
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

  Widget _buildWeeklyCalendar(BuildContext context) {
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final todayIndex = DateTime.now().weekday - 1; // 1=Mon -> 0

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        final isToday = index == todayIndex;
        
        return Column(
          children: [
            Container(
              width: 40, 
              height: 40,
              decoration: BoxDecoration(
                color: isToday ? AppTheme.brandBlue : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                days[index],
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 6),
              const CircleAvatar(radius: 3, backgroundColor: Colors.orange),
            ] else 
               const SizedBox(height: 12), // Placeholder to align
          ],
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
