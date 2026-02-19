import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../authentication/data/auth_repository.dart'; // Corrected Import
import '../../application/daily_routine_provider.dart';
import '../../application/metabolic_checkin_provider.dart';
import '../../application/training_cycle_provider.dart';
import '../../application/training_engine_provider.dart';
import 'metabolic_insight_banner.dart';
import 'package:elena_app/src/features/training/application/daily_orchestrator_provider.dart' as orchestrator;
import 'package:go_router/go_router.dart';
import '../../application/workout_submit_controller.dart';
import '../../domain/entities/training_entities.dart';
import '../../domain/entities/interactive_routine.dart';
import '../widgets/exercise_set_row.dart';
import '../widgets/rir_logging_slider.dart';

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
     final sessionState = ref.watch(trainingEngineProvider); // Watch Engine
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

        return Column(
          children: [
            // 1. FIXED HEADER (Wrapped in Theme for Deload)
            if (!widget.hideHeader)
            _buildFixedHeader(context, widget.recommendation, cycleState.isDeloadActive),
            
            // 2. PAGE VIEW (Expanded)
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
            
            // 3. STICKY FOOTER (Action Button)
            _buildStickyFooter(
               context, 
               isCurrentComplete, 
               isLastExercise, 
               isSubmitting,
               dailyExercises.length, // Total exercises
               currentExerciseIndex + 1, // Current 1-based
               currentExercise // Pass to check sets
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
  
  Widget _buildFixedHeader(BuildContext context, WorkoutRecommendation info, bool isDeload) {
    // Get User Name for personalization
    final user = ref.watch(authRepositoryProvider).currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Atleta';
    
    // Auto-map Emoji based on Notes/Type
    String badgeEmoji = "💪";
    if (info.notes.contains("Potencia")) badgeEmoji = "🏋️";
    if (info.notes.contains("Definición")) badgeEmoji = "🔥";
    if (info.notes.contains("Esencial")) badgeEmoji = "⚡";
    if (isDeload) badgeEmoji = "🧊";

    // Colors based on type
    Color badgeColor = AppTheme.brandBlue;
    if (info.notes.contains("Potencia")) badgeColor = Colors.orange;
    if (info.notes.contains("Definición")) badgeColor = Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDeload ? Colors.teal.shade50 : AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          // Header Row: Title/Time vs Badge
          ConstrainedBox( // Requirement check: Prevent shrinking
             constraints: const BoxConstraints(minHeight: 40),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                             fontWeight: FontWeight.bold, // BOLD
                             color: Colors.grey.shade500,
                             letterSpacing: 1.0,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           "¡A darle, $name! • ${info.durationMinutes} Min",
                           style: GoogleFonts.outfit(
                             fontSize: 16, 
                             fontWeight: FontWeight.w600,
                             color: Colors.black87,
                           ),
                         ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Routine Badge (Pill with Opacity)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1), // Subtle background
                      borderRadius: BorderRadius.circular(20), // Pill shape
                      border: Border.all(color: badgeColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      "$badgeEmoji ${isDeload ? 'Descarga' : info.notes}", 
                      style: GoogleFonts.outfit(
                        color: badgeColor, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
               ],
             ),
          ),
          
          const SizedBox(height: 16),

          // Metabolic Insight (Full Width)
          Consumer(
            builder: (context, ref, _) {
               final checkin = ref.watch(metabolicCheckinProvider).valueOrNull;
               
               if (isDeload) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.science, color: Colors.teal.shade700),
                        const SizedBox(width: 12),
                         Expanded(
                           child: Text(
                            "Semana de Descarga: Volumen al 50%.",
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.teal.shade900),
                           ),
                         ),
                      ],
                    ),
                  );
               }
               
               if (checkin?.insightMessage != null) {
                  return SizedBox(
                    width: double.infinity,
                    child: Padding( 
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: MetabolicInsightBanner(
                         message: checkin!.insightMessage!, 
                         compact: false
                      ),
                    ),
                  );
               }
               
               return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePage(BuildContext context, InteractiveExercise exercise, bool isDeload) {
    return SingleChildScrollView( 
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technique Carousel (Fixed Height 180px)
          Container(
            height: 180, 
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

          // Exercise Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                         exercise.id.substring(0, 1), 
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
                             "Objetivo: ${exercise.sets.first.targetReps} Reps${exercise.requiresWeight ? '' : ''}", 
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

                 // Sets Header Row (Static Titles)
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                   child: Row(
                      children: [
                        SizedBox(
                          width: 24, 
                          child: Text("Set", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400))
                        ),
                        const SizedBox(width: 8),
                        const Spacer(), // Labels aligned with content in Row?
                        // Actually, aligning with ExerciseSetRow is tricky without fixed widths.
                        // ExerciseSetRow: 24(Index) + 8 + Expanded(Target) + 8 + Weight?(50) + 6 + Reps(50/80) + 8 + Check(28)
                        
                        // Let's rely on standard "Series" title?
                        // Or try to align:
                      ],
                   ),
                 ),
                 // BETTER IMPLEMENTATION:
                 // ExerciseSetRow structure is flexible.
                 // To make a header row align, we should perhaps construct it similarly.
                 // But simply putting labels above the columns works if widths are fixed.
                 // My ExerciseSetRow uses constrained widths for inputs.
                 Row(
                    children: [
                       SizedBox(width: 32, child: Text("Serie", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       Expanded(child: Text("Objetivo", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
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
                     // If we have 3 sets initially, set 3 (index 2) is the trigger.
                     // If we add a bonus set (index 3), it shouldn't trigger again?
                     // "Al marcar el ÚLTIMO checkbox programado (ej. la serie 3)"
                     // How do we know it's scheduled?
                     // IsBonus flag! 
                     // We check if this is the last *non-bonus* set?
                     // Or just check if it's the last set AND !isBonus AND sets.length < limit.
                     
                     // Identifying "Last Scheduled": It's the last set where isBonus is false?
                     // Or simply: If this is the last set in the list, and it's NOT a bonus set?
                     // Actually, if we add set 4, set 3 is no longer last.
                     // But we want to trigger when set 3 is done.
                     // So we should trigger when *any* non-bonus set that IS the last non-bonus set is done?
                     // No, simpler: When checking the last item in the list, if it's not a bonus set (or even if it is? User said "Serie extra" implies one).
                     // Let's say we trigger on the last set of the list, provided we haven't maxed out.
                     
                     final isLastInList = index == exercise.sets.length - 1;

                     return ExerciseSetRow(
                       exerciseId: exercise.id, 
                       setIndex: set.setIndex,
                       targetReps: set.targetReps,
                       isDone: set.isDone,
                       initialWeight: set.weight,
                       initialReps: set.reps,
                       requiresWeight: exercise.requiresWeight, 
                       // Highlight Bonus Sets?
                       // We can add a property or style wrapper.
                       // For now, standard row.
                       
                       onToggle: _isReadOnly ? null : (weight, reps) async {
                          // Bonus Trigger Logic
                          if (isLastInList && !set.isDone) {
                             // Marking last set as done.
                             final user = ref.read(authRepositoryProvider).currentUser;
                             final name = user?.displayName?.split(' ').first ?? 'Atleta';
                             
                             // Limit bonus sets (Max 1 bonus set for now to avoid loop?)
                             // Prompt: "Al marcar el ÚLTIMO checkbox programado"
                             // If we add a set, the new set becomes last.
                             // We don't want to trigger again on the bonus set?
                             // "Dopamina Metabólica" implies one extra push.
                             // Let's limit to if (!set.isBonus).
                             if (!set.isBonus) {
                                await showDialog(context: context, builder: (ctx) {
                                   return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text("¡Bien hecho, $name!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                      content: Text("¡Completaste tu objetivo! Tus niveles de energía hoy son buenos. ¿Quieres intentar una serie extra?", style: GoogleFonts.outfit()),
                                      actions: [
                                         TextButton(
                                           onPressed: () {
                                             Navigator.pop(ctx);
                                             // No action, user can proceed to next exercise via footer button.
                                           }, 
                                           child: Text("NO, SIGUIENTE", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold))
                                         ),
                                         FilledButton(
                                            onPressed: () {
                                               Navigator.pop(ctx);
                                               ref.read(dailyRoutineProvider.notifier).addBonusSet(exercise.id);
                                            },
                                            style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
                                            child: Text("SÍ, ¡VAMOS!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))
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
    InteractiveExercise currentExercise
  ) {
     final user = ref.read(authRepositoryProvider).currentUser;
     final name = user?.displayName?.split(' ').first ?? 'Atleta';
  
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                           : (isComplete || _isReadOnly ? "Siguiente Ejercicio ->" : "Completa las series"),
                       style: GoogleFonts.outfit(
                         fontSize: 16,
                         fontWeight: FontWeight.bold, 
                         color: (!isComplete && !_isReadOnly) ? Colors.grey : Colors.white
                       ),
                     ),
             ),
           ),
           if (!isComplete && !_isReadOnly)
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

