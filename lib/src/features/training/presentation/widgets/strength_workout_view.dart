import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/daily_routine_provider.dart';
import 'package:go_router/go_router.dart';
import '../../application/workout_submit_controller.dart';
import '../../domain/entities/training_entities.dart';
import '../widgets/exercise_set_row.dart';
import '../widgets/rir_logging_slider.dart';

import '../../domain/enums/workout_enums.dart';

class StrengthWorkoutView extends ConsumerStatefulWidget {
  final WorkoutRecommendation recommendation;
  final WorkoutDisplayMode mode;

  const StrengthWorkoutView({
    super.key, 
    required this.recommendation,
    this.mode = WorkoutDisplayMode.active,
  });

  @override
  ConsumerState<StrengthWorkoutView> createState() => _StrengthWorkoutViewState();
}

class _StrengthWorkoutViewState extends ConsumerState<StrengthWorkoutView> {
  int _currentRir = 2; 

  bool get _isReadOnly => 
    widget.mode == WorkoutDisplayMode.readOnly || 
    widget.mode == WorkoutDisplayMode.completed;

  // Fallback Mock Data
  final List<Map<String, dynamic>> _mockExercises = [
    {
      'id': '1',
      'name': 'Sentadilla con Barra',
      'sets': [
        {'setIndex': 1, 'weight': 60.0, 'reps': 12, 'isDone': false},
        {'setIndex': 2, 'weight': 60.0, 'reps': 12, 'isDone': false},
        {'setIndex': 3, 'weight': 60.0, 'reps': 12, 'isDone': false},
      ]
    },
    {
      'id': '2',
      'name': 'Press Militar',
      'sets': [
        {'setIndex': 1, 'weight': 30.0, 'reps': 10, 'isDone': false},
        {'setIndex': 2, 'weight': 30.0, 'reps': 10, 'isDone': false},
      ]
    },
    {
      'id': '3',
      'name': 'Peso Muerto Rumano',
      'sets': [
        {'setIndex': 1, 'weight': 80.0, 'reps': 10, 'isDone': false},
        {'setIndex': 2, 'weight': 80.0, 'reps': 10, 'isDone': false},
        {'setIndex': 3, 'weight': 80.0, 'reps': 10, 'isDone': false},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
     final routineState = ref.watch(dailyRoutineProvider);
     // Use mock if routine is empty (fallback for future/past days where provider might not be hydrated)
     final dailyExercises = routineState.isEmpty ? _mockExercises : routineState;
     
     final submitState = ref.watch(workoutSubmitControllerProvider);
     final isSubmitting = submitState.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationCard(context, widget.recommendation),
          const SizedBox(height: 24),
          
          // Exercise List
          Text(
            "Tu Circuito de Hoy",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyExercises.length,
            itemBuilder: (context, index) {
              final exercise = dailyExercises[index];
              final sets = exercise['sets'] as List<dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: sets.map((s) {
                          final set = s as Map<String, dynamic>;
                          return ExerciseSetRow(
                            setIndex: set['setIndex'] as int,
                            targetReps: "8-12", // Mock or from data
                            isDone: set['isDone'] as bool,
                            initialWeight: (set['weight'] as num?)?.toDouble(),
                            initialReps: set['reps'] as int?,
                            onToggle: _isReadOnly ? null : (weight, reps) {
                                // Only toggle if not using mock data (or handle mock toggle separately if needed)
                                if (routineState.isNotEmpty) {
                                  ref.read(dailyRoutineProvider.notifier).toggleSet(
                                    exercise['id'] as String,
                                    set['setIndex'] as int,
                                    weight,
                                    reps
                                  );
                                }
                              },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // RIR Slider
          if (!_isReadOnly)
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
          if (!_isReadOnly && (widget.mode == WorkoutDisplayMode.active || widget.mode == WorkoutDisplayMode.retroactive))
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting 
                  ? null 
                  : () async {
                      final log = await ref.read(workoutSubmitControllerProvider.notifier)
                         .submitWorkout(
                           sessionRir: _currentRir,
                           workoutType: 'Strength',
                         );
                      
                      if (context.mounted && log != null) {
                        context.pushNamed('workout_summary', extra: log);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: widget.mode == WorkoutDisplayMode.retroactive 
                    ? Colors.orange 
                    : AppTheme.brandBlue,
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
                      widget.mode == WorkoutDisplayMode.retroactive
                          ? "Guardar Registro Pasado"
                          : "Terminar y Guardar Entrenamiento",
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
  Widget _buildRecommendationCard(BuildContext context, WorkoutRecommendation info) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.fitness_center, color: AppTheme.brandBlue),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.type,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${info.durationMinutes} Min • ${info.intensity}",
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              info.notes,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
