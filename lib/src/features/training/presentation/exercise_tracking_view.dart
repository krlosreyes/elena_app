import 'dart:async';

import 'package:elena_app/src/core/providers/metabolic_hub_provider.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/features/health/data/health_repository.dart';
import 'package:elena_app/src/features/profile/application/user_controller.dart';
import 'package:elena_app/src/features/training/application/training_controller.dart';
import 'package:elena_app/src/features/training/application/training_provider.dart';
import 'package:elena_app/src/features/training/data/repositories/routine_repository.dart';
import 'package:elena_app/src/features/training/domain/entities/set_log.dart';
import 'package:elena_app/src/features/training/domain/entities/weekly_routine.dart';
import 'package:elena_app/src/features/training/domain/entities/workout_log.dart';
import 'package:elena_app/src/features/training/domain/training_enums.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — Dark Mode Premium Elena
// ═══════════════════════════════════════════════════════════════════════════════
const _kBg = Color(0xFF0C0C0C);
const _kSurface = Color(0xFF141414);
const _kSurfaceLight = Color(0xFF1C1C1C);
const _kCyan = Color(0xFF00E5FF);
const _kOrange = Color(0xFFFFB300);
const _kGreen = Color(0xFF00E676);
const _kWhite = Colors.white;
const _kWhite70 = Color(0xB3FFFFFF);
const _kWhite50 = Color(0x80FFFFFF);
const _kWhite30 = Color(0x4DFFFFFF);
const _kWhite12 = Color(0x1FFFFFFF);

final exerciseJustCompletedProvider = StateProvider<bool>((ref) => false);

// ═══════════════════════════════════════════════════════════════════════════════
// SET MODEL
// ═══════════════════════════════════════════════════════════════════════════════
class _SetEntry {
  final double kg;
  final int reps;
  final int rpe;
  _SetEntry({required this.kg, required this.reps, required this.rpe});
}

// ═══════════════════════════════════════════════════════════════════════════════
// METABOLIC CARD — reusable container
// ═══════════════════════════════════════════════════════════════════════════════
class MetabolicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const MetabolicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? _kCyan.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE TRACKING VIEW
// ═══════════════════════════════════════════════════════════════════════════════
class ExerciseTrackingView extends ConsumerStatefulWidget {
  /// Si se pasa un WorkoutDay, se activa el modo rutina guiada directamente
  /// sin necesidad de consultar Firestore en _loadActiveRoutine().
  final WorkoutDay? initialWorkoutDay;

  const ExerciseTrackingView({super.key, this.initialWorkoutDay});

  @override
  ConsumerState<ExerciseTrackingView> createState() =>
      _ExerciseTrackingViewState();
}

class _ExerciseTrackingViewState extends ConsumerState<ExerciseTrackingView>
    with TickerProviderStateMixin {
  // ─── Local state ───
  final List<_SetEntry> _sessionSets = [];
  bool _isLowerBody = true;
  double _currentKg = 45.0;
  int _currentReps = 12;
  int _currentRpe = 3;
  late AnimationController _pulseController;

  /// Workout de la rutina (sincronizado con TrainingController)
  WorkoutDay? get _activeWorkoutDay =>
      ref.watch(trainingControllerProvider).activeWorkoutDay;

  int get _currentExerciseIndex =>
      ref.watch(trainingControllerProvider).currentExerciseIndex;

  int get _setsCompletedThisExercise =>
      ref.watch(trainingControllerProvider).setsCompletedThisExercise;

  bool _isTransitioning = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideOutAnim;
  late Animation<Offset> _slideInAnim;
  double get _weightIncrement => _isLowerBody ? 5.0 : 1.0;

  /// Ejercicio actual de la rutina activa (null en flujo libre)
  ExerciseTemplate? get _currentExercise {
    final day = _activeWorkoutDay;
    if (day == null) return null;
    final index = _currentExerciseIndex;
    final exercises = day.exercises;
    if (index >= exercises.length) return null;
    return exercises[index];
  }

  // ─── RPE micro-copies ───
  static const _rpeMicroCopy = {
    1: 'Podrías hacer 4+ más',
    2: 'Podrías hacer 3 más',
    3: '¿Podrías haber hecho 2 más?',
    4: 'Tal vez 1 más',
    5: 'Fallo muscular',
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Slide animation for auto-advance between exercises
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideOutAnim =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.2, 0)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInBack),
        );
    _slideInAnim = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    // Try to load active routine on init
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveRoutine());
  }

  void _startCardioTimer() {
    // La lógica del timer ahora la maneja TrainingController
    ref.read(trainingControllerProvider.notifier).startCardio();
  }

  void _stopCardioTimer() {
    ref.read(trainingControllerProvider.notifier).stopCardio();
  }

  void _handleCardioFinished() {
    // trainingControllerProvider ya avanzará o completará el día
  }

  void _setupCardio(int totalMinutes) {
    ref.read(trainingControllerProvider.notifier).initCardio(totalMinutes);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Carga la rutina de la semana actual y extrae el día de hoy.
  /// Si se pasó initialWorkoutDay como parámetro, se usa directamente.
  Future<void> _loadActiveRoutine() async {
    // Si se proporcionó un WorkoutDay directo (desde WeeklyRoutineScreen)
    final injected = widget.initialWorkoutDay;
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    final weightKg = user?.currentWeightKg ?? 65.0;

    if (injected != null &&
        !injected.completed &&
        injected.type != WorkoutDayType.rest) {
      ref
          .read(trainingControllerProvider.notifier)
          .initSession(injected, weightKg: weightKg);
      return;
    }

    // Fallback: intentar cargar desde Firestore
    if (user == null) return;
    try {
      final routine = await ref
          .read(routineRepositoryProvider)
          .getCurrentWeekRoutine(user.uid);
      if (routine != null && mounted) {
        final today = routine.todayWorkout;
        if (today != null &&
            !today.completed &&
            today.type != WorkoutDayType.rest) {
          ref
              .read(trainingControllerProvider.notifier)
              .initSession(today, weightKg: weightKg);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Routine] No se pudo cargar rutina activa: $e');
      // Graceful fallback: flujo libre
    }
  }

  // ─── IMR Calculation: +0.1 per effective set (RPE > 3) lower body ───
  double _calculateImrDelta() {
    int effectiveSets = 0;
    for (final s in _sessionSets) {
      if (s.rpe > 3 && _isLowerBody) {
        effectiveSets++;
      }
    }
    return effectiveSets * 0.1;
  }

  // ─── Submit workout ───────────────────────────────────────────────────
  Future<void> _submitWorkout(
    TrainingStatusState state,
    TrainingController controller,
  ) async {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    final durationMinutes = (state.elapsedSeconds / 60).ceil().clamp(1, 180);

    final setsData = _sessionSets
        .map((s) => {'kg': s.kg, 'reps': s.reps, 'rpe': s.rpe})
        .toList();

    final log = WorkoutLog(
      id: const Uuid().v4(),
      templateId: 'manual_${state.category.name}',
      date: DateTime.now(),
      sessionRirScore: (10 - state.rpe).clamp(0, 10),
      durationMinutes: durationMinutes,
      type: state.category.title,
      completedExercises: [
        {
          'exerciseId': 'manual_mission',
          'name': 'Misión Elena: ${state.category.title}',
          'muscleGroup': _isLowerBody ? 'Tren Inferior' : 'Tren Superior',
          'sets': setsData.isNotEmpty
              ? setsData
              : [
                  {'reps': 1, 'intensity': state.rpe},
                ],
        },
      ],
    );

    final isHighIntensity =
        state.category == ExerciseCategory.strength ||
        state.category == ExerciseCategory.hiit;

    try {
      await ref
          .read(trainingRepositoryProvider)
          .completeWorkoutSession(
            userId: user.uid,
            log: log,
            isHighIntensity: isHighIntensity,
          );

      await ref.read(healthRepositoryProvider).logExercise(user.uid, {
        'id': log.id,
        'type': state.category.title,
        'minutes': durationMinutes,
        'intensity': isHighIntensity ? 'high' : 'moderate',
        'timestamp': log.date.toIso8601String(),
      });

      ref.read(exerciseJustCompletedProvider.notifier).state = true;

      if (mounted) {
        controller.resetSession();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: _kCyan),
                const SizedBox(width: 12),
                Text(
                  'EJERCICIO REGISTRADO',
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0A0A0A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      debugPrint('❌ [ExerciseTracking] Error al registrar workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Error al guardar. Verifica tu conexión e intenta de nuevo.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A0000),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addSet() {
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionSets.add(
        _SetEntry(kg: _currentKg, reps: _currentReps, rpe: _currentRpe),
      );
    });

    // ─── Auto-advance: registrar serie en Firestore si hay rutina activa ───
    final exercise = _currentExercise;
    if (_activeWorkoutDay != null && exercise != null) {
      _handleRoutineSetLogged(exercise);
    }
  }

  /// Lógica de auto-advance cuando se registra una serie con rutina activa
  Future<void> _handleRoutineSetLogged(ExerciseTemplate exercise) async {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    final weekId = WeeklyRoutine.currentWeekId();
    final dayIndex = _activeWorkoutDay!.dayIndex;

    // Increment through controller – it is now the single source of truth
    final newSetsCount = _setsCompletedThisExercise + 1;
    ref
        .read(trainingControllerProvider.notifier)
        .updateRoutineProgress(setsCompleted: newSetsCount);

    // Registrar la serie en Firestore
    try {
      await ref
          .read(routineRepositoryProvider)
          .logSet(
            user.uid,
            weekId,
            dayIndex,
            exercise.exerciseId,
            SetLog(
              exerciseId: exercise.exerciseId,
              dayIndex: dayIndex,
              setNumber: newSetsCount,
              reps: _currentReps,
              weightKg: _currentKg,
              rpe: _currentRpe,
              loggedAt: DateTime.now(),
            ),
          );
    } catch (e) {
      debugPrint('⚠️ [Routine] Error al registrar serie: $e');
    }

    if (!mounted) return;

    // ¿Última serie de este ejercicio?
    if (newSetsCount >= exercise.targetSets) {
      final exercises = _activeWorkoutDay!.exercises;
      final isLastExercise = _currentExerciseIndex >= exercises.length - 1;

      if (isLastExercise) {
        // Último ejercicio del día → marcar día completado
        try {
          await ref
              .read(routineRepositoryProvider)
              .markDayCompleted(user.uid, weekId, dayIndex);
        } catch (e) {
          debugPrint('⚠️ [Routine] Error al marcar día completado: $e');
        }
        // Mostrar bottom sheet de resumen del día
        if (mounted) _showDayCompletedSheet(exercises);
      } else {
        // Hay siguiente ejercicio → animación slide y avanzar
        await _advanceToNextExercise();
      }
    }
  }

  /// Animación slide-out → slide-in al siguiente ejercicio
  Future<void> _advanceToNextExercise() async {
    if (!mounted) return;

    // Phase 1: Slide out current exercise to the left
    setState(() => _isTransitioning = true);
    _slideController.reset();
    await _slideController.forward();
    if (!mounted) return;

    // Advance index through controller (no local setState for routine state)
    final nextIndex = _currentExerciseIndex + 1;
    ref
        .read(trainingControllerProvider.notifier)
        .updateRoutineProgress(exerciseIndex: nextIndex, setsCompleted: 0);
    if (mounted)
      setState(() {
        _sessionSets.clear();
        // Update lower body flag based on next exercise
        final nextEx = _currentExercise;
        if (nextEx != null) {
          _isLowerBody = _isLowerBodyMuscle(nextEx.muscleGroup);
          if (nextEx.muscleGroup.toLowerCase() == 'cardio' &&
              nextEx.targetMinutes > 0) {
            _setupCardio(nextEx.targetMinutes);
          }
        }
        _isTransitioning = false;
      });

    // Slide in new exercise from the right
    if (!mounted) return;
    _slideController.reset();
    await _slideController.forward();
  }

  bool _isLowerBodyMuscle(String muscleGroup) {
    const lowerGroups = {'legs', 'glutes', 'hamstrings', 'quads', 'calves'};
    return lowerGroups.contains(muscleGroup.toLowerCase());
  }

  /// Bottom sheet de resumen cuando se completa el día
  void _showDayCompletedSheet(List<ExerciseTemplate> exercises) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Icono y título ───
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGreen.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_rounded, color: _kGreen, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              '¡DÍA COMPLETADO!',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _kGreen,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${exercises.length} ejercicios realizados',
              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: _kWhite50),
            ),
            const SizedBox(height: 20),
            // ─── Lista de ejercicios completados ───
            ...exercises.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: _kGreen, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.name,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: _kWhite70,
                        ),
                      ),
                    ),
                    Text(
                      '${e.targetSets}×${e.targetReps}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: _kWhite30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // ─── Botón volver ───
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/weekly_routine');
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(
                  'VOLVER A MI SEMANA',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: _kBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainingState = ref.watch(trainingControllerProvider);
    final controller = ref.read(trainingControllerProvider.notifier);
    final hub = ref.watch(metabolicHubProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: trainingState.phase == TrainingSessionStep.summary
            ? _SessionSummaryScreen(
                sets: _sessionSets,
                isLowerBody: _isLowerBody,
                imrBase: hub.totalImr,
                imrDelta: _calculateImrDelta(),
                duration: trainingState.elapsedSeconds,
                category: trainingState.category,
                onFinish: () => _submitWorkout(trainingState, controller),
              )
            : _buildMetabolicScreen(trainingState, controller, hub),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 1 — METABOLIC (Main Log)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMetabolicScreen(
    TrainingStatusState state,
    TrainingController controller,
    MetabolicContext hub,
  ) {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1=Mon
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    return Column(
      children: [
        // ─── Top Bar ───
        if (user != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ElenaHeader(title: 'ENTRENAMIENTO', user: user),
          ),
        // ─── 7-day Timeline ───
        _buildWeekTimeline(todayWeekday),
        // ─── Body ───
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prescription banner
                _buildPrescriptionBanner(),
                const SizedBox(height: 14),

                // Switch between Strength and Cardio views
                if (_currentExercise?.muscleGroup.toLowerCase() == 'cardio')
                  _buildCardioTrackingView(state)
                else ...[
                  // Strength UI
                  _buildFuerzaActivaCard(state, controller),
                  const SizedBox(height: 16),
                  // RPE Slider
                  _buildRpeSlider(),
                  const SizedBox(height: 16),
                  // Register set button
                  _buildRegisterSetButton(state, controller),
                ],

                const SizedBox(height: 16),
                // Session sets capsules (only for strength)
                if (_currentExercise?.muscleGroup.toLowerCase() != 'cardio' &&
                    _sessionSets.isNotEmpty) ...[
                  _buildSessionSets(),
                  const SizedBox(height: 16),
                ],
                // Finish button
                if (state.phase == TrainingSessionStep.active &&
                    (_sessionSets.isNotEmpty ||
                        _currentExercise?.muscleGroup.toLowerCase() ==
                            'cardio')) ...[
                  _buildFinishButton(controller),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 16),
                // SEMANA METAMORFOSIS progress
                _buildWeekProgress(),
                const SizedBox(height: 16),
                // Footer cards
                _buildFooterCards(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── TOP BAR REMOVED — Unified with ElenaHeader ────────────────────────────

  // ─── 7-DAY TIMELINE with icons ─────────────────────────────────────────
  Widget _buildWeekTimeline(int todayWeekday) {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    // Icons per day — J (Thu) gets dumbbell, others get minimal icons
    const dayIcons = [
      Icons.check_circle_rounded, // L - completed
      Icons.check_circle_rounded, // M - completed
      Icons.directions_run_rounded, // M - run
      Icons.fitness_center_rounded, // J - dumbbell (TODAY)
      Icons.bolt_rounded, // V - hiit
      Icons.directions_run_rounded, // S - run
      Icons.nightlight_round, // D - rest
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kWhite12, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final dayIndex = i + 1;
          final isToday = dayIndex == todayWeekday;
          final isPast = dayIndex < todayWeekday;
          final iconColor = isToday
              ? _kOrange
              : isPast
              ? _kCyan.withValues(alpha: 0.7)
              : _kWhite30;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with glow for today
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? _kOrange.withValues(alpha: 0.15)
                      : Colors.transparent,
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: _kOrange.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  dayIcons[i],
                  color: iconColor,
                  size: isToday ? 24 : 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday ? _kOrange : _kWhite50,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── PRESCRIPTION BANNER ───────────────────────────────────────────────
  Widget _buildPrescriptionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
      ),
      child: Text(
        'RECOMENDADO PARA TU SENSIBILIDAD A LA INSULINA',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kOrange,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARDIO TRACKING VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCardioTrackingView(TrainingStatusState state) {
    return MetabolicCard(
      borderColor: _kOrange.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ─── Background Emoji ───
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 1.0,
              child: Text('🏃', style: const TextStyle(fontSize: 160)),
            ),
          ),

          Column(
            children: [
              // ─── Phase Indicator ───
              _buildCardioPhaseBadge(state),
              const SizedBox(height: 24),

              // ─── Timer ───
              Text(
                _formatTime(state.cardioRemainingSeconds),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: _kWhite,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 8),

              // ─── Progress Bar ───
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.cardioTotalSeconds > 0
                      ? (1 -
                            state.cardioRemainingSeconds /
                                state.cardioTotalSeconds)
                      : 0,
                  backgroundColor: _kWhite12,
                  valueColor: AlwaysStoppedAnimation<Color>(_kOrange),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 32),

              // ─── Stats Row ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCardioStat(
                    'CALORÍAS',
                    '${state.cardioCalsBurned.toInt()}',
                    'kcal',
                  ),
                  Container(width: 1, height: 30, color: _kWhite12),
                  _buildCardioStat('ESFUERZO', 'ZONA 2', ''),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Zone 2 Explanation ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kWhite.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'RITMO CONVERSACIONAL',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _kOrange,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'En Zona 2 utilizas principalmente grasas como combustible. Debes poder hablar sin jadear.',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        height: 1.5,
                        color: _kWhite50,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardioPhaseBadge(TrainingStatusState state) {
    String label = 'MAIN';
    Color color = _kOrange;

    switch (state.cardioPhase) {
      case 'WARMUP':
        label = 'CALENTAMIENTO';
        color = _kCyan;
        break;
      case 'COOLDOWN':
        label = 'ENFRIAMIENTO';
        color = _kGreen;
        break;
      default:
        label = 'ZONA 2 ACTIVA';
        color = _kOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCardioStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(fontSize: 9, color: _kWhite30),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _kWhite,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: _kWhite50,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FUERZA ACTIVA — Main card: Silhouette + Weight/Reps inputs
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFuerzaActivaCard(
    TrainingStatusState state,
    TrainingController controller,
  ) {
    final exercise = _currentExercise;
    final isRoutineGuided = exercise != null;

    return MetabolicCard(
      borderColor: _kCyan.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Title row ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRoutineGuided
                          ? exercise.muscleGroup.toUpperCase()
                          : 'SARCOPENIA PREVENTION',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kWhite50,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRoutineGuided
                          ? exercise.name.toUpperCase()
                          : 'FUERZA ACTIVA',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: isRoutineGuided ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: _kWhite,
                        letterSpacing: 1,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isRoutineGuided) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ejercicio ${_currentExerciseIndex + 1} de ${_activeWorkoutDay!.exercises.length}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: _kCyan.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Metabolic load dots + icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    color: _kCyan.withValues(alpha: 0.6),
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  isRoutineGuided
                      ? _buildSeriesProgressDots(exercise)
                      : _buildMetabolicLoadDots(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ─── Body: Silhouette + Inputs (con SlideTransition si rutina activa) ───
          if (isRoutineGuided)
            SlideTransition(
              position: _isTransitioning ? _slideOutAnim : _slideInAnim,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSilhouette(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildWeightInput(),
                        const SizedBox(height: 14),
                        _buildRepsInput(),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSilhouette(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildWeightInput(),
                      const SizedBox(height: 14),
                      _buildRepsInput(),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Series progress dots (rutina guiada) ───────────────────────────────
  Widget _buildSeriesProgressDots(ExerciseTemplate exercise) {
    final target = exercise.targetSets;
    final completed = _setsCompletedThisExercise;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kSurfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SERIES ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: _kWhite50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          ...List.generate(target, (i) {
            final isDone = i < completed;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? _kGreen : _kWhite12,
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: _kGreen.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${i + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: isDone ? _kGreen : _kWhite30,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── CARGA METABÓLICA dots ─────────────────────────────────────────────
  Widget _buildMetabolicLoadDots() {
    final filled = _sessionSets.length.clamp(0, 5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kSurfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SERIES ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: _kWhite50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          ...List.generate(5, (i) {
            final isActive = i < filled;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? _kCyan : _kWhite12,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: _kCyan.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${i + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: isActive ? _kCyan : _kWhite30,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── SILHOUETTE — SVG-based premium anatomical figure ────────────────
  Widget _buildSilhouette() {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final isFemale = user?.gender == Gender.female;
    final String svgAsset = isFemale
        ? 'assets/images/mujer.svg'
        : 'assets/images/hombre.svg';

    final Color activeColor = _isLowerBody ? _kOrange : _kCyan;

    return GestureDetector(
      onTapDown: (details) {
        HapticFeedback.lightImpact();
        final tapY = details.localPosition.dy;
        setState(() {
          _isLowerBody = tapY > 107; // 58% of 185 — matches _HalfClipper split
        });
      },
      child: SizedBox(
        width: 120,
        height: 185,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Glow aura for selected zone
            Positioned(
              top: _isLowerBody ? 105 : 20,
              child: Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // 2. Base silhouette — dark teal blueprint
            SvgPicture.asset(
              svgAsset,
              height: 155,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                _kCyan.withValues(alpha: 0.18),
                BlendMode.srcIn,
              ),
            ),

            // 3. Upper body overlay (clipped top half)
            ClipRect(
              clipper: _HalfClipper(isTop: true),
              child: SvgPicture.asset(
                svgAsset,
                height: 155,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  _isLowerBody
                      ? _kCyan.withValues(alpha: 0.25)
                      : _kCyan.withValues(alpha: 0.7),
                  BlendMode.srcIn,
                ),
              ),
            ),

            // 4. Lower body overlay (clipped bottom half)
            ClipRect(
              clipper: _HalfClipper(isTop: false),
              child: SvgPicture.asset(
                svgAsset,
                height: 155,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  _isLowerBody
                      ? _kOrange.withValues(alpha: 0.7)
                      : _kOrange.withValues(alpha: 0.25),
                  BlendMode.srcIn,
                ),
              ),
            ),

            // 5. Edge glow outline for selected zone
            ClipRect(
              clipper: _HalfClipper(isTop: !_isLowerBody),
              child: SvgPicture.asset(
                svgAsset,
                height: 155,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  activeColor.withValues(alpha: 0.4),
                  BlendMode.srcIn,
                ),
              ),
            ),

            // 6. Label at the bottom
            Positioned(
              bottom: 0,
              child: Text(
                _isLowerBody ? 'TREN INFERIOR' : 'TREN SUPERIOR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: activeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WEIGHT INPUT — dark rectangular box with +/- ──────────────────────
  Widget _buildWeightInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _kSurfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kWhite12),
      ),
      child: Column(
        children: [
          Text(
            'PESO (KG)',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kWhite50,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus button — dark rectangle
              _RectButton(
                label: '-',
                onTap: () => setState(() {
                  _currentKg = (_currentKg - _weightIncrement).clamp(0, 500);
                }),
              ),
              const SizedBox(width: 14),
              Text(
                _currentKg.toStringAsFixed(_currentKg % 1 == 0 ? 0 : 1),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _kWhite,
                ),
              ),
              const SizedBox(width: 14),
              // Plus button
              _RectButton(
                label: '+',
                onTap: () => setState(() {
                  _currentKg = (_currentKg + _weightIncrement).clamp(0, 500);
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // +5KG micro-copy when lower body
          Text(
            '+${_weightIncrement.toStringAsFixed(0)}KG',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _isLowerBody ? _kOrange : _kCyan,
            ),
          ),
        ],
      ),
    );
  }

  // ─── REPS INPUT ────────────────────────────────────────────────────────
  Widget _buildRepsInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _kSurfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kWhite12),
      ),
      child: Column(
        children: [
          Text(
            'REPS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kWhite50,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RectButton(
                label: '-',
                onTap: () => setState(() {
                  _currentReps = (_currentReps - 1).clamp(1, 100);
                }),
              ),
              const SizedBox(width: 14),
              Text(
                '$_currentReps',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _kWhite,
                ),
              ),
              const SizedBox(width: 14),
              _RectButton(
                label: '+',
                onTap: () => setState(() {
                  _currentReps = (_currentReps + 1).clamp(1, 100);
                }),
              ),
            ],
          ),
          if (_activeWorkoutDay != null && _currentExercise != null) ...[
            const SizedBox(height: 6),
            Text(
              'Objetivo: ${_currentExercise!.targetReps} reps',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kCyan.withValues(alpha: 0.6),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── RPE SLIDER ────────────────────────────────────────────────────────
  Widget _buildRpeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'ESFUERZO RPE (1-5)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kWhite70,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                _rpeMicroCopy[_currentRpe] ?? '',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: _kCyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: _kOrange,
            inactiveTrackColor: _kSurfaceLight,
            thumbColor: _kOrange,
            overlayColor: _kOrange.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _currentRpe.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _currentRpe = v.round());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MIN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: _kWhite30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'MAX',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: _kWhite30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── REGISTER SET BUTTON — orange ──────────────────────────────────────
  Widget _buildRegisterSetButton(
    TrainingStatusState state,
    TrainingController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          if (state.phase == TrainingSessionStep.selection) {
            controller.startMission();
          }
          _addSet();
        },
        icon: const Icon(Icons.add_rounded, size: 22, color: _kBg),
        label: Text(
          '+ REGISTRAR SERIE',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: _kBg,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kOrange,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ─── SESSION SETS CAPSULES ─────────────────────────────────────────────
  Widget _buildSessionSets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SERIES DE ESTA SESIÓN',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kWhite50,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sessionSets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = _sessionSets[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _kCyan.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kCyan.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'S${i + 1}: ${s.kg.toStringAsFixed(s.kg % 1 == 0 ? 0 : 1)}kg x ${s.reps}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kWhite70,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── FINISH BUTTON ─────────────────────────────────────────────────────
  Widget _buildFinishButton(TrainingController controller) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.heavyImpact();
          controller.finishSession();
        },
        icon: const Icon(Icons.flag_rounded, size: 18),
        label: Text(
          'FINALIZAR SESIÓN',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kOrange,
          side: const BorderSide(color: _kOrange, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ─── COLLAPSED MODULE ──────────────────────────────────────────────────
  Widget _buildCollapsedModule(IconData icon, String title) {
    return MetabolicCard(
      borderColor: _kWhite12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _kWhite30, size: 22),
          const SizedBox(width: 14),
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kWhite50,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: _kWhite30, size: 22),
        ],
      ),
    );
  }

  // ─── SEMANA METAMORFOSIS PROGRESS ──────────────────────────────────────
  Widget _buildWeekProgress() {
    return MetabolicCard(
      borderColor: _kWhite12,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SEMANA METAMORFOSIS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kWhite70,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '60% COMPLETADO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 6,
              backgroundColor: _kSurfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(_kCyan),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Has protegido 1.2kg de masa muscular magra esta semana',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _kWhite50,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── FOOTER CARDS — Puntos Mitocondriales + Estímulo Anabólico ─────────
  Widget _buildFooterCards() {
    return Row(
      children: [
        Expanded(
          child: MetabolicCard(
            borderColor: _kWhite12,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                // Sparkles icon
                Text('✦', style: TextStyle(fontSize: 22, color: _kCyan)),
                const SizedBox(height: 8),
                Text(
                  'PUNTOS MITOCONDRIALES',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _kWhite50,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '+12.4',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _kCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetabolicCard(
            borderColor: _kWhite12,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                // Anabolic wave icon
                Text('√∿', style: TextStyle(fontSize: 20, color: _kCyan)),
                const SizedBox(height: 8),
                Text(
                  'ESTÍMULO ANABÓLICO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _kWhite50,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'ÓPTIMO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _kWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HALF CLIPPER — clips SVG to top or bottom half for zone highlighting
// Split at 58% so hands (which extend below the waist) stay in upper body
// ═══════════════════════════════════════════════════════════════════════════════
class _HalfClipper extends CustomClipper<Rect> {
  final bool isTop;
  _HalfClipper({required this.isTop});

  static const double _splitRatio = 0.58; // hands end ~57% down the SVG

  @override
  Rect getClip(Size size) {
    if (isTop) {
      return Rect.fromLTWH(0, 0, size.width, size.height * _splitRatio);
    } else {
      return Rect.fromLTWH(
        0,
        size.height * _splitRatio,
        size.width,
        size.height * (1.0 - _splitRatio),
      );
    }
  }

  @override
  bool shouldReclip(covariant _HalfClipper oldClipper) =>
      oldClipper.isTop != isTop;
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECT BUTTON — dark rectangular +/- control
// ═══════════════════════════════════════════════════════════════════════════════
class _RectButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RectButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kWhite12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kWhite70,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — SESSION SUMMARY
// ═══════════════════════════════════════════════════════════════════════════════
class _SessionSummaryScreen extends StatefulWidget {
  final List<_SetEntry> sets;
  final bool isLowerBody;
  final double imrBase;
  final double imrDelta;
  final int duration;
  final ExerciseCategory category;
  final VoidCallback onFinish;

  const _SessionSummaryScreen({
    required this.sets,
    required this.isLowerBody,
    required this.imrBase,
    required this.imrDelta,
    required this.duration,
    required this.category,
    required this.onFinish,
  });

  @override
  State<_SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<_SessionSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _imrAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _imrAnimation =
        Tween<double>(
          begin: widget.imrBase,
          end: widget.imrBase + widget.imrDelta,
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _totalVolume {
    double vol = 0;
    for (final s in widget.sets) {
      vol += s.kg * s.reps;
    }
    return vol.round();
  }

  int get _effectiveSets => widget.sets.where((s) => s.rpe > 3).length;

  @override
  Widget build(BuildContext context) {
    final durationMin = (widget.duration / 60).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: _kOrange, size: 24),
              const SizedBox(width: 10),
              Text(
                'RESUMEN DE SESIÓN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kOrange,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // IMR Count-Up
          MetabolicCard(
            borderColor: _kCyan.withValues(alpha: 0.3),
            child: Column(
              children: [
                Text(
                  'ÍNDICE METABÓLICO RELATIVO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: _kWhite50,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _imrAnimation,
                  builder: (context, child) {
                    return Text(
                      _imrAnimation.value.toStringAsFixed(1),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _kCyan,
                        height: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (widget.imrDelta > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${widget.imrDelta.toStringAsFixed(1)} pts',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.timer_outlined,
                  label: 'DURACIÓN',
                  value: '$durationMin min',
                  color: _kCyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.fitness_center_rounded,
                  label: 'SERIES',
                  value: '${widget.sets.length}',
                  color: _kOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatMiniCard(
                  icon: Icons.speed_rounded,
                  label: 'VOLUMEN',
                  value: '${_totalVolume}kg',
                  color: _kCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Impact cards
          _ImpactCard(
            icon: Icons.shield_rounded,
            iconColor: _kCyan,
            title: 'Protección Sarcopenia',
            description: _effectiveSets >= 3
                ? 'Has completado $_effectiveSets series efectivas. Estímulo suficiente para preservación de masa magra.'
                : 'Se recomiendan al menos 3 series efectivas (RPE > 3) para protección contra sarcopenia.',
          ),
          const SizedBox(height: 10),
          _ImpactCard(
            icon: Icons.sensors_rounded,
            iconColor: _kOrange,
            title: 'Sensibilidad a la Insulina',
            description:
                'El entrenamiento de ${widget.category.title} activa GLUT4, mejorando la captación de glucosa muscular durante las próximas 48h.',
          ),
          const SizedBox(height: 10),
          _ImpactCard(
            icon: Icons.bolt_rounded,
            iconColor: Colors.redAccent,
            title: 'EPOC Post-Ejercicio',
            description:
                'Volumen total: ${_totalVolume}kg. Gasto energético elevado estimado durante 24-72h post-sesión.',
          ),
          const SizedBox(height: 20),
          // AI Coach
          _AiCoachBox(
            isLowerBody: widget.isLowerBody,
            effectiveSets: _effectiveSets,
            category: widget.category,
          ),
          const SizedBox(height: 24),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onFinish,
              icon: const Icon(Icons.save_rounded, size: 20, color: _kBg),
              label: Text(
                'GUARDAR Y SALIR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kBg,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MetabolicCard(
      padding: const EdgeInsets.all(12),
      borderColor: _kWhite12,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: _kWhite50,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ImpactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return MetabolicCard(
      padding: const EdgeInsets.all(14),
      borderColor: _kWhite12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _kWhite50,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCoachBox extends StatelessWidget {
  final bool isLowerBody;
  final int effectiveSets;
  final ExerciseCategory category;

  const _AiCoachBox({
    required this.isLowerBody,
    required this.effectiveSets,
    required this.category,
  });

  String get _muscleGroup => isLowerBody ? 'Tren Inferior' : 'Tren Superior';

  String get _recoveryText {
    if (effectiveSets >= 5) {
      return 'Sesión de alto volumen para $_muscleGroup. Prescripción: 48-72h de recuperación para este grupo. Prioriza proteína (1.6-2.2g/kg) y sueño >7h para máxima síntesis proteica.';
    } else if (effectiveSets >= 3) {
      return 'Estímulo adecuado para $_muscleGroup. Recuperación estimada: 24-48h. Mantén hidratación óptima y considera movilidad activa mañana.';
    } else {
      return 'Volumen bajo para $_muscleGroup. Puedes entrenar este grupo nuevamente en 24h. Considera aumentar series efectivas (RPE > 3) en tu próxima sesión.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.08),
            AppTheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'COACH IA — RECUPERACIÓN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _recoveryText,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _kWhite.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
