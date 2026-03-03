import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../authentication/application/auth_controller.dart';
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
import '../../application/rest_timer_provider.dart';
import '../../domain/enums/workout_enums.dart';

class StrengthWorkoutView extends ConsumerStatefulWidget {
  final WorkoutRecommendation recommendation;
  final WorkoutDisplayMode mode;
  final bool hideHeader; 

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
  bool _hasConfiguredWorkout = false;

  bool get _isReadOnly => 
    widget.mode == WorkoutDisplayMode.readOnly || 
    widget.mode == WorkoutDisplayMode.completed;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // If read only, bypass setup.
       if (_isReadOnly) {
          _initializeEngine();
          setState(() => _hasConfiguredWorkout = true);
       } else {
          // Trigger Pre-Workout Setup
          _showPreWorkoutBottomSheet();
       }
    });
  }

  void _initializeEngine() {
      final cycle = ref.read(trainingCycleProviderProvider);
      ref.read(trainingEngineProvider.notifier).initialize(
         isDeload: cycle.isDeloadActive
      );
  }

  void _showPreWorkoutBottomSheet() {
    bool hasDumbbells = true;
    double weight = 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Force them to choose or pop back
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 24, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 24
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("¡Preparados!", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Antes de empezar, define tu equipo de hoy:", style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  
                  // dumbbels toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: true,
                          groupValue: hasDumbbells,
                          activeColor: AppTheme.brandBlue,
                          title: Text("Con Mancuernas", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          onChanged: (val) => setModalState(() => hasDumbbells = val!),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          groupValue: hasDumbbells,
                          activeColor: AppTheme.brandBlue,
                          title: Text("Sin Mancuernas (Solo Peso Corporal)", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          onChanged: (val) => setModalState(() => hasDumbbells = val!),
                        ),
                      ],
                    ),
                  ),
                  
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: hasDumbbells 
                     ? Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Peso base (kg):", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: "Ej. 5",
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              onChanged: (val) => weight = double.tryParse(val) ?? 5.0,
                            ),
                          ],
                        ),
                     )
                     : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                         // 1. Update Provider State
                         ref.read(dailyRoutineProvider.notifier).setEquipmentPreference(hasDumbbells, weight);
                         // 2. Init Engine
                         _initializeEngine();
                         // 3. Close modal & allow UI to load
                         setState(() => _hasConfiguredWorkout = true);
                         Navigator.pop(ctx);
                      },
                      child: Text("Empezar Entrenamiento 🚀", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     if (!_hasConfiguredWorkout && !_isReadOnly) {
        // While the BottomSheet is overlaid, show a clean skeleton or loading background
        return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
     }

     final dailyExercisesAsync = ref.watch(dailyRoutineProvider);
     final sessionState = ref.watch(trainingEngineProvider); 
     final cycleState = ref.watch(trainingCycleProviderProvider);
     final submitState = ref.watch(workoutSubmitControllerProvider);
     final isSubmitting = submitState.isLoading;

     // Sync PageView
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
        if (dailyExercises.isEmpty) return const Center(child: Text('No hay ejercicios asignados.'));
        
        final currentExerciseIndex = sessionState.currentIndex;
        if (currentExerciseIndex >= dailyExercises.length) return const Center(child: Text("Entrenamiento finalizado."));
        
        final currentExercise = dailyExercises[currentExerciseIndex];
        final isLastExercise = currentExerciseIndex == dailyExercises.length - 1;
        final isCurrentComplete = ref.read(trainingEngineProvider.notifier).isExerciseComplete(currentExercise);

        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), 
                itemCount: dailyExercises.length,
                itemBuilder: (context, index) {
                   return _buildExercisePage(context, dailyExercises[index], cycleState.isDeloadActive);
                },
              ),
            ),
            
            _buildStickyFooter(context, isCurrentComplete, isLastExercise, isSubmitting, dailyExercises.length, currentExerciseIndex + 1, sessionState.isResting),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildExercisePage(BuildContext context, InteractiveExercise exercise, bool isDeload) {
    // Determine if all existing sets are completed to show the bonus set button
    final bool allSetsDone = exercise.sets.isNotEmpty && exercise.sets.every((s) => s.isDone);

    return SingleChildScrollView( 
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PREMIUM FIX 1: Exact AspectRatio, Elegant Shadows
          AspectRatio( 
            aspectRatio: 16/9,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                 color: const Color(0xFFF3F4F6), // Smooth standard gray
                 borderRadius: BorderRadius.circular(24),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.05),
                     blurRadius: 15,
                     offset: const Offset(0, 10),
                   ),
                 ]
              ),
              child: Stack(
                 alignment: Alignment.bottomCenter,
                 children: [
                   PageView(
                      children: [
                         Center(child: Icon(Icons.play_circle_fill_rounded, size: 72, color: Colors.grey.shade400)), 
                      ],
                   ),
                 ],
              ),
            ),
          ),

          // PREMIUM FIX 2: Refined Card styling
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32), // More rounded and premium
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
              border: isDeload ? Border.all(color: Colors.teal.shade100, width: 2) : Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: AppTheme.brandBlue.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(16),
                       ),
                       child: Text(
                         exercise.id.substring(0, 1).toUpperCase(), 
                         style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.brandBlue),
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
                               fontSize: 22, // Slightly larger
                               fontWeight: FontWeight.bold,
                               height: 1.2,
                             ),
                           ),
                           const SizedBox(height: 4),
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "Objetivo: ${exercise.sets.first.targetReps} Reps", 
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                              ),
                           )
                         ],
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 24),

                 // Sets Header Row 
                 Row(
                    children: [
                       SizedBox(width: 32, child: Text("Serie", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       Expanded(child: Text("Objetivo", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       
                       // Dynamic Header
                       if (exercise.requiresWeight)
                       SizedBox(width: 58, child: Text("Peso", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       
                       SizedBox(width: exercise.requiresWeight ? 58 : 88, child: Text("Reps", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
                       const SizedBox(width: 28),
                    ],
                 ),
                 const SizedBox(height: 12),
                 
                 // Sets List
                 Column(
                   children: exercise.sets.asMap().entries.map((entry) {
                     final index = entry.key;
                     final set = entry.value;
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
                          if (!set.isDone) { 
                             if (!isLastInList) {
                                ref.read(trainingEngineProvider.notifier).setResting(true);
                                ref.read(restTimerProvider.notifier).startTimer(90);
                             } else {
                                // Added slight tick if this was the last set marked
                                ref.read(restTimerProvider.notifier).stopTimer(); 
                                ref.read(trainingEngineProvider.notifier).setResting(false); 
                             }
                          }
                       },
                     );
                   }).toList(),
                 ),

                 // PUMP / BONUS SET LOGIC
                 if (allSetsDone && !_isReadOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: InkWell(
                         onTap: () {
                             ref.read(dailyRoutineProvider.notifier).addBonusSet(exercise.id);
                         },
                         borderRadius: BorderRadius.circular(16),
                         child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                               color: Colors.red.withValues(alpha: 0.05),
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1.5, strokeAlign: BorderSide.strokeAlignInside)
                            ),
                            child: Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                  const Text("🔥", style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "¿No sientes el Pump? Añadir 1 serie extra", 
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red.shade700)
                                  ),
                               ]
                            )
                         ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 60), // Breathing room for footer
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context, bool isComplete, bool isLast, bool isSubmitting, int totalExercises, int currentExerciseNum, bool isResting) {
     final user = ref.watch(authControllerProvider.notifier).currentUser;
     final name = user?.displayName?.split(' ').first ?? 'Atleta';
  
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           LinearProgressIndicator(
             value: currentExerciseNum / totalExercises,
             backgroundColor: Colors.grey.shade100,
             valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandBlue),
             borderRadius: BorderRadius.circular(8),
             minHeight: 6,
           ),
           const SizedBox(height: 20),
           
           if (isLast && isComplete) ...[
              RirLoggingSlider(
                value: _currentRir,
                onChanged: (val) => setState(() => _currentRir = val),
              ),
              const SizedBox(height: 20),
           ],

           SizedBox(
             width: double.infinity,
             height: 60, // Taller button
             child: FilledButton(
               onPressed: (!isComplete && !_isReadOnly) 
                   ? null 
                   : () async {
                       if (isLast) {
                          final log = await ref.read(workoutSubmitControllerProvider.notifier).submitWorkout(sessionRir: _currentRir, workoutType: 'Strength');
                          if (context.mounted && log != null) {
                            await context.pushNamed('workout_summary', extra: log);
                            ref.invalidate(orchestrator.dailyOrchestratorProvider);
                            ref.read(trainingEngineProvider.notifier).endSession();
                          }
                       } else {
                          ref.read(trainingEngineProvider.notifier).nextPage();
                       }
                   },
               style: FilledButton.styleFrom(
                 backgroundColor: (!isComplete && !_isReadOnly) ? Colors.grey.shade200 : (isLast ? Colors.green : AppTheme.brandBlue),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 elevation: (!isComplete && !_isReadOnly) ? 0 : 4,
               ),
               child: isSubmitting
                   ? const CircularProgressIndicator(color: Colors.white)
                   : Text(
                       isLast ? "¡Lo lograste, $name! Ver resultados 🏆" : (isResting ? "Descansando... (Omitir)" : (isComplete || _isReadOnly ? "Siguiente Ejercicio" : "Completa las series")),
                       style: GoogleFonts.outfit(
                         fontSize: 18,
                         fontWeight: FontWeight.w600, 
                         color: (!isComplete && !_isReadOnly) ? Colors.grey.shade500 : Colors.white
                       ),
                     ),
             ),
           ),
        ],
      ),
    );
  }
}
