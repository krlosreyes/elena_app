import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../authentication/data/auth_repository.dart'; // Corrected Import
import '../../application/daily_routine_provider.dart';
import '../../application/training_cycle_provider.dart';
import '../../application/training_engine_provider.dart';
import 'package:elena_app/src/features/training/application/daily_orchestrator_provider.dart' as orchestrator;
import 'package:go_router/go_router.dart';
import '../../application/workout_submit_controller.dart';
import '../../domain/entities/training_entities.dart';
import '../../domain/entities/interactive_routine.dart';
import '../widgets/exercise_set_row.dart';
import '../widgets/rir_logging_slider.dart';
import '../widgets/training_feedback_card.dart';
import '../widgets/rest_timer_banner.dart';
import '../../application/rest_timer_provider.dart';

import '../../domain/enums/workout_enums.dart';

class StrengthWorkoutView extends ConsumerStatefulWidget {
  final WorkoutRecommendation recommendation;
  final WorkoutDisplayMode mode;
  final bool hideHeader; // New Prop

  const StrengthWorkoutView({
    super.key, 
    required this.recommendation,
    this.mode = WorkoutDisplayMode.active,
    this.hideHeader = false,
  });

  @override
  ConsumerState<StrengthWorkoutView> createState() => _StrengthWorkoutViewState();
}

class _StrengthWorkoutViewState extends ConsumerState<StrengthWorkoutView> {
  late PageController _pageController;
  int _currentRir = 2; 

  bool get _isReadOnly => 
    widget.mode == WorkoutDisplayMode.readOnly || 
    widget.mode == WorkoutDisplayMode.completed;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize Engine on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final cycle = ref.read(trainingCycleProviderProvider);
       ref.read(trainingEngineProvider.notifier).initialize(
         isDeload: cycle.isDeloadActive
       );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


// ... imports ...

  @override
  Widget build(BuildContext context) {
     final dailyExercisesAsync = ref.watch(dailyRoutineProvider);
     final sessionState = ref.watch(trainingEngineProvider); 
     final cycleState = ref.watch(trainingCycleProviderProvider);
     
     final submitState = ref.watch(workoutSubmitControllerProvider);
     final isSubmitting = submitState.isLoading;

     // Listen to index changes for PageView sync
     ref.listen(trainingEngineProvider, (prev, next) {
       if (prev?.currentIndex != next.currentIndex) {
         _pageController.animateToPage(
           next.currentIndex, 
           duration: const Duration(milliseconds: 300), 
           curve: Curves.easeInOut,
         );
       }
     });

    return dailyExercisesAsync.when(
      data: (dailyExercises) {
        if (dailyExercises.isEmpty) {
          return const Center(child: Text('No hay ejercicios asignados.'));
        }

        final currentExerciseIndex = sessionState.currentIndex;
        // Safety check
        if (currentExerciseIndex >= dailyExercises.length) {
            return const Center(child: Text("Entrenamiento finalizado."));
        }
        
        final currentExercise = dailyExercises[currentExerciseIndex];
        final isLastExercise = currentExerciseIndex == dailyExercises.length - 1;
        
        // Check if current exercise is complete
        final isCurrentComplete = ref.read(trainingEngineProvider.notifier).isExerciseComplete(currentExercise);

        // STACK for Overlay (Rest Timer)
        return Stack( 
          children: [
            // SCROLLABLE CONTENT (Header + Body)
            // Use Column with Expanded to ensure PageView takes available space
            Column(
              children: [
                // 1. DYNAMIC HEADER (Feedback Card) - Pushes content down
                if (!widget.hideHeader)
                TrainingFeedbackCard(
                   recommendation: widget.recommendation, 
                   isDeload: cycleState.isDeloadActive
                ),
                
                // 2. PAGE VIEW (Body) - Takes remaining space
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Engine controlled
                    itemCount: dailyExercises.length,
                    itemBuilder: (context, index) {
                       final exercise = dailyExercises[index];
                       return _buildExercisePage(context, exercise, cycleState.isDeloadActive);
                    },
                  ),
                ),
                
                // 3. STICKY FOOTER (Action Button) - Always visible at bottom of Column
                _buildStickyFooter(
                   context, 
                   isCurrentComplete, 
                   isLastExercise, 
                   isSubmitting,
                   dailyExercises.length, // Total exercises
                   currentExerciseIndex + 1, // Current 1-based
                   currentExercise, // Pass to check sets
                   sessionState.isResting // New Prop
                ),
              ],
            ),

            // 4. REST TIMER OVERLAY (Floating Z-Index)
            // Positioned above the footer or sticking to bottom?
            // User requested "Rest Timer Banner".
            Positioned(
              bottom: 100, // Above Footer
              left: 20,
              right: 20,
              child: Consumer(
                 builder: (context, ref, _) {
                    final seconds = ref.watch(restTimerProvider);
                    // Only show if timer > 0
                    if (seconds > 0) {
                       return const RestTimerBanner();
                    }
                    return const SizedBox.shrink();
                 }
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  // ... (Removed old _buildFixedHeader) ...

  Widget _buildExercisePage(BuildContext context, InteractiveExercise exercise, bool isDeload) {
    return SingleChildScrollView( 
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technique Carousel 
          // 1. LAYOUT FIX: AspectRatio
          AspectRatio( 
            aspectRatio: 16/9,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                 color: Colors.grey.shade200,
                 borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                 alignment: Alignment.bottomCenter,
                 children: [
                   PageView(
                      children: [
                         Center(child: Icon(Icons.fitness_center, size: 64, color: Colors.grey.shade400)), 
                         Center(child: Icon(Icons.accessibility_new, size: 64, color: Colors.grey.shade400)),
                      ],
                   ),
                   Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Container(width: 8, height: 8, margin: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle)),
                           Container(width: 8, height: 8, margin: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle)),
                        ],
                     ),
                   )
                 ],
              ),
            ),
          ),

          // Exercise Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: isDeload ? Border.all(color: Colors.teal.shade100, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Header: Name & Target
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                         color: Colors.grey.shade50,
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         exercise.id.substring(0, 1).toUpperCase(), 
                         style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             exercise.name,
                             style: GoogleFonts.outfit(
                               fontSize: 20,
                               fontWeight: FontWeight.bold,
                               height: 1.2,
                             ),
                           ),
                           Text(
                             "Objetivo: ${exercise.sets.first.targetReps} Reps", 
                             style: GoogleFonts.outfit(
                               fontSize: 12,
                               color: Colors.grey.shade500,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),

                 // Sets Header Row (Dynamic Inputs)
                 Row(
                    children: [
                       SizedBox(width: 32, child: Text("Serie", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       Expanded(child: Text("Objetivo", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       
                       // 2. DYNAMIC INPUTS
                       if (exercise.requiresWeight)
                       SizedBox(width: 58, child: Text("Peso", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       
                       SizedBox(width: exercise.requiresWeight ? 58 : 88, child: Text("Reps", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       const SizedBox(width: 28), // Checkbox space
                    ],
                 ),
                 const SizedBox(height: 8),
                 
                 // Sets List
                 Column(
                   children: exercise.sets.asMap().entries.map((entry) {
                     final index = entry.key;
                     final set = entry.value;
                     // Logic: "Last Scheduled Set". 
                     // We consider the last item in the list as the potential trigger for Extra Set.
                     
                     final isLastInList = index == exercise.sets.length - 1;

                     return ExerciseSetRow(
                       exerciseId: exercise.id, 
                       setIndex: set.setIndex,
                       targetReps: set.targetReps,
                       isDone: set.isDone,
                       initialWeight: set.weight,
                       initialReps: set.reps,
                       requiresWeight: exercise.requiresWeight, 
                       
                       onToggle: _isReadOnly ? null : (weight, reps) async {

                          // 3. REST TIMER LOGIC & STATE UPDATE
                          if (!set.isDone) { // User just marked as Done
                             
                             // Start Rest Timer (30s) if not last set
                             if (!isLastInList) {
                                // Update State
                                ref.read(trainingEngineProvider.notifier).setResting(true);
                                ref.read(restTimerProvider.notifier).startTimer(30);
                             }
                          }

                          // 4. EXTRA SET CHALLENGE
                          if (isLastInList && !set.isDone) {
                             // User completing the last available set
                             if (!set.isBonus) {
                                ref.read(restTimerProvider.notifier).stopTimer(); // Ensure timer is off
                                ref.read(trainingEngineProvider.notifier).setResting(false); // Ensure not "resting" state during dialog?
                                
                                await showDialog(context: context, builder: (ctx) {
                                   return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text("¡Bien hecho!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                      content: Text("Vas muy bien. ¿Crees que puedes hacer una serie más?", style: GoogleFonts.outfit()),
                                      actions: [
                                         TextButton(
                                           onPressed: () {
                                             Navigator.pop(ctx);
                                           }, 
                                           child: Text("NO", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold))
                                         ),
                                         FilledButton(
                                            onPressed: () {
                                               Navigator.pop(ctx);
                                               ref.read(dailyRoutineProvider.notifier).addBonusSet(exercise.id);
                                            },
                                            style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
                                            child: Text("SÍ", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))
                                         ),
                                      ],
                                   );
                                });
                             }
                          }
                       },
                     );
                   }).toList(),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
// ... footer remains mostly same ...

  Widget _buildStickyFooter(
    BuildContext context, 
    bool isComplete, 
    bool isLast, 
    bool isSubmitting,
    int totalExercises,
    int currentExerciseNum,
    InteractiveExercise currentExercise,
    bool isResting, // New Prop
  ) {
     final user = ref.read(authRepositoryProvider).currentUser;
     final name = user?.displayName?.split(' ').first ?? 'Atleta';
  
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           // Progress Indicator
           LinearProgressIndicator(
             value: currentExerciseNum / totalExercises,
             backgroundColor: Colors.grey.shade100,
             valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandBlue),
             borderRadius: BorderRadius.circular(4),
           ),
           const SizedBox(height: 16),
           
           // Slider only on last step? Or always?
           // The prompt said "Single-Exercise". It didn't mention RIR slider per exercise.
           // Usually RIR is per Session (Session RIR) at the end.
           // Let's show RIR slider ONLY if it's the last exercise AND completed.
           if (isLast && isComplete) ...[
              RirLoggingSlider(
                value: _currentRir,
                onChanged: (val) => setState(() => _currentRir = val),
              ),
              const SizedBox(height: 16),
           ],

           SizedBox(
             width: double.infinity,
             height: 56,
             child: FilledButton(
               onPressed: (!isComplete && !_isReadOnly) 
                   ? null // Disabled if not complete
                   : () async {
                       if (isLast) {
                          // FINISH
                          final log = await ref.read(workoutSubmitControllerProvider.notifier)
                             .submitWorkout(
                               sessionRir: _currentRir,
                               workoutType: 'Strength',
                             );
                          
                          if (context.mounted && log != null) {
                            await context.pushNamed('workout_summary', extra: log);
                            ref.invalidate(orchestrator.dailyOrchestratorProvider);
                             // Reset Engine
                            ref.read(trainingEngineProvider.notifier).endSession();
                          }
                       } else {
                          // NEXT
                          ref.read(trainingEngineProvider.notifier).nextPage();
                       }
                   },
               style: FilledButton.styleFrom(
                 backgroundColor: (!isComplete && !_isReadOnly)
                     ? Colors.grey.shade300 
                     : (isLast ? Colors.green : AppTheme.brandBlue),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               ),
               child: isSubmitting
                   ? const CircularProgressIndicator(color: Colors.white)
                   : Text(
                       isLast 
                           ? "¡Lo lograste, $name! Ver resultados 🏆"
                           : (isResting ? "Descansando... (Omitir)" : (isComplete || _isReadOnly ? "Siguiente Ejercicio ->" : "Completa las series")),
                       style: GoogleFonts.outfit(
                         fontSize: 16,
                         fontWeight: FontWeight.bold, 
                         color: (!isComplete && !_isReadOnly) ? Colors.grey : Colors.white
                       ),
                     ),
             ),
           ),
           if (!isComplete && !_isReadOnly && !isResting)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Text(
                 "Marca todas las series para avanzar",
                 style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
               ),
             ),
        ],
      ),
    );
  }
}

