import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../authentication/data/auth_repository.dart';
import '../../health/data/health_repository.dart';
import '../../profile/application/user_controller.dart';
import '../application/routine_controller.dart';
import '../domain/entities/weekly_routine.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — Consistentes con exercise_tracking_view.dart
// ═══════════════════════════════════════════════════════════════════════════════
const _kBg = Color(0xFF020205);
const _kSurface = Color(0xFF141414);
const _kSurfaceLight = Color(0xFF1C1C1C);
const _kAccent = Color(0xFFFF9D00);
const _kGreen = Color(0xFF00E676);
const _kWhite = Colors.white;
const _kWhite70 = Color(0xB3FFFFFF);
const _kWhite50 = Color(0x80FFFFFF);
const _kWhite30 = Color(0x4DFFFFFF);
const _kWhite12 = Color(0x1FFFFFFF);
const _kCyan = Color(0xFF00E5FF);

// ── Active Recovery Constants ──
/// MET value for brisk walking (~5.6 km/h). Source: Compendium of Physical Activities.
const _kWalkMet = 3.5;
const _kWalkMinutes = 30;

// ═══════════════════════════════════════════════════════════════════════════════
// WEEKLY ROUTINE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class WeeklyRoutineScreen extends ConsumerStatefulWidget {
  const WeeklyRoutineScreen({super.key});

  @override
  ConsumerState<WeeklyRoutineScreen> createState() =>
      _WeeklyRoutineScreenState();
}

class _WeeklyRoutineScreenState extends ConsumerState<WeeklyRoutineScreen> {
  bool _isGenerating = false;
  bool _isRegisteringWalk = false;
  bool _walkRegisteredToday = false;
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday - 1; // 0=Lun
    // Intentar generar rutina automáticamente si no existe
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoGenerate());
  }

  Future<void> _autoGenerate() async {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;
    await ref.read(routineControllerProvider).ensureWeeklyRoutineExists(user);
  }

  Future<void> _regenerate() async {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;
    setState(() => _isGenerating = true);
    try {
      await ref.read(routineControllerProvider).regenerateRoutine(user);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateFirst() async {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;
    setState(() => _isGenerating = true);
    try {
      await ref.read(routineControllerProvider).ensureWeeklyRoutineExists(user);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _startWorkout(WorkoutDay day) {
    context.go('/weekly_routine/session', extra: day);
  }

  /// Calories burned during brisk walking.
  /// Formula: kcal/min = MET × 3.5 × weightKg / 200
  int _estimateWalkCalories(double weightKg) {
    final kcalPerMin = _kWalkMet * 3.5 * weightKg / 200;
    return (kcalPerMin * _kWalkMinutes).round();
  }

  Future<void> _registerWalk() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    final weightKg = user?.currentWeightKg ?? 65.0;
    final kcal = _estimateWalkCalories(weightKg);

    setState(() => _isRegisteringWalk = true);
    try {
      await ref.read(healthRepositoryProvider).logExercise(uid, {
        'type': 'walk',
        'name': 'Caminata a paso ligero',
        'minutes': _kWalkMinutes,
        'calories': kcal,
        'met': _kWalkMet,
        'intensity': 'light',
        'isActiveRecovery': true,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isRegisteringWalk = false;
          _walkRegisteredToday = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅  Caminata registrada — $kcal kcal · ${_kWalkMinutes} min',
              style: GoogleFonts.jetBrainsMono(fontSize: 12),
            ),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegisteringWalk = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al registrar: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineAsync = ref.watch(weeklyRoutineProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: routineAsync.when(
          loading: () => _buildShimmer(),
          error: (e, _) => _buildError(e.toString()),
          data: (routine) {
            if (routine == null) return _buildEmpty();
            return _buildRoutineContent(routine);
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT — Rutina cargada
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRoutineContent(WeeklyRoutine routine) {
    final todayIndex = DateTime.now().weekday - 1; // 0=Lun

    // Día seleccionado (puede ser hoy u otro)
    final selectedDay = routine.days.firstWhere(
      (d) => d.dayIndex == _selectedDayIndex,
      orElse: () =>
          WorkoutDay(dayIndex: _selectedDayIndex, type: WorkoutDayType.rest),
    );
    final selectedType = selectedDay.type;
    final isRest = selectedType == WorkoutDayType.rest;
    final isDone = selectedDay.completed;
    final isToday = _selectedDayIndex == todayIndex;

    return Column(
      children: [
        // ─── Header ───
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: _kWhite70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RUTINA SEMANAL',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _kWhite,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _weekLabel(routine.weekId),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _kAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress ring
              _buildProgressRing(routine.completionProgress),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ─── Week strip (7 days) ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(7, (i) {
              final day = routine.days.firstWhere(
                (d) => d.dayIndex == i,
                orElse: () =>
                    WorkoutDay(dayIndex: i, type: WorkoutDayType.rest),
              );
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: _buildDayChip(
                    day,
                    isToday: i == todayIndex,
                    isSelected: i == _selectedDayIndex,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),

        // ─── Today detail ───
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today header
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${isToday ? "HOY: " : ""}${_dayName(_selectedDayIndex).toUpperCase()} — ${_dayTypeLabel(selectedType)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kWhite,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '✅ COMPLETADO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _kGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Exercise list
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isRest && selectedType == WorkoutDayType.zone2)
                        Opacity(
                          opacity: 1.0,
                          child: Text(
                            '🏃',
                            style: const TextStyle(fontSize: 180),
                          ),
                        ),
                      isRest
                          ? _buildRestDay()
                          : _buildExerciseList(selectedDay),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Action buttons ───
                _buildStartButton(selectedDay, isRest, isDone),
                const SizedBox(height: 12),

                // Bottom actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _isGenerating ? null : _regenerate,
                      child: Text(
                        'Regenerar rutina',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kWhite30,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAY CHIP — Individual day in the week strip
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDayChip(
    WorkoutDay day, {
    required bool isToday,
    required bool isSelected,
  }) {
    final isCompleted = day.completed;
    final isRest = day.type == WorkoutDayType.rest;
    final icon = _dayTypeIcon(day.type);
    final bgColor = isSelected ? _kAccent.withValues(alpha: 0.15) : _kSurface;
    final borderColor = isSelected
        ? _kAccent
        : isToday
        ? _kAccent.withValues(alpha: 0.4)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _dayAbbr(day.dayIndex),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isSelected ? _kAccent : _kWhite50,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          if (isRest)
            Text(
              '—',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _kWhite30),
            )
          else if (isCompleted)
            Icon(Icons.check_circle, size: 12, color: _kAccent)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kWhite12,
                border: Border.all(color: _kWhite30, width: 1),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE LIST — Today's exercises
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExerciseList(WorkoutDay day) {
    if (day.exercises.isEmpty) {
      return Center(
        child: Text(
          'Sin ejercicios para hoy',
          style: GoogleFonts.jetBrainsMono(fontSize: 13, color: _kWhite30),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: day.exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final ex = day.exercises[i];
        final isDone = ex.completedSets >= ex.targetSets;
        final isCardio = ex.muscleGroup == 'cardio';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone ? _kGreen.withValues(alpha: 0.3) : _kWhite12,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 10,
                height: 10,
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
              const SizedBox(width: 12),
              // Exercise name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDone ? _kWhite50 : _kWhite,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ex.muscleGroup.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: _kWhite30,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              // Sets × Reps or Minutes
              Text(
                isCardio
                    ? '${ex.targetMinutes} min'
                    : '${ex.targetSets} × ${ex.targetReps}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _kAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REST DAY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRestDay() {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final weightKg = user?.currentWeightKg ?? 65.0;
    final kcal = _estimateWalkCalories(weightKg);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Active Recovery Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _kCyan.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _kCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: _kCyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DESCANSO ACTIVO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _kCyan,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Caminata a paso ligero',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kWhite50,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_walkRegisteredToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✅',
                          style: GoogleFonts.jetBrainsMono(fontSize: 14),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Stats Row ──
                Row(
                  children: [
                    _buildWalkStat(
                      Icons.timer_outlined,
                      '${_kWalkMinutes} min',
                      'DURACIÓN',
                    ),
                    const SizedBox(width: 12),
                    _buildWalkStat(
                      Icons.local_fire_department_outlined,
                      '$kcal kcal',
                      'CALORÍAS EST.',
                    ),
                    const SizedBox(width: 12),
                    _buildWalkStat(Icons.speed_outlined, '5.6 km/h', 'RITMO'),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Benefits ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kSurfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿POR QUÉ CAMINAR EN DÍA DE DESCANSO?',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildBenefit(
                        '🔄',
                        'Acelera la recuperación muscular aumentando flujo sanguíneo',
                      ),
                      const SizedBox(height: 6),
                      _buildBenefit(
                        '📉',
                        'Reduce glucosa postprandial hasta un 30%',
                      ),
                      const SizedBox(height: 6),
                      _buildBenefit(
                        '🧠',
                        'Mejora estado de ánimo y reduce cortisol',
                      ),
                      const SizedBox(height: 6),
                      _buildBenefit(
                        '❤️',
                        'Mantiene tu zona cardiovascular activa sin estrés',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kAccent.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ideal después de comer. Camina 15–30 min post-comida para optimizar tu respuesta metabólica.',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: _kAccent,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _kSurfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kCyan, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kWhite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: _kWhite30,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: _kWhite70,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // START BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStartButton(WorkoutDay? day, bool isRest, bool isDone) {
    // ── Rest day: walk registration button ──
    if (isRest) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: (_walkRegisteredToday || _isRegisteringWalk)
              ? null
              : _registerWalk,
          icon: _isRegisteringWalk
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Icon(
                  _walkRegisteredToday
                      ? Icons.check_circle_rounded
                      : Icons.directions_walk_rounded,
                  size: 20,
                ),
          label: Text(
            _walkRegisteredToday
                ? 'CAMINATA REGISTRADA ✅'
                : 'REGISTRAR CAMINATA · $_kWalkMinutes MIN',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _walkRegisteredToday ? _kSurfaceLight : _kCyan,
            foregroundColor: _walkRegisteredToday ? _kGreen : Colors.black,
            disabledBackgroundColor: _kSurfaceLight,
            disabledForegroundColor: _kGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    // ── Workout day: normal start button ──
    final canStart = !isDone && day != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canStart ? () => _startWorkout(day) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart ? _kAccent : _kSurfaceLight,
          foregroundColor: canStart ? Colors.black : _kWhite30,
          disabledBackgroundColor: _kSurfaceLight,
          disabledForegroundColor: _kWhite30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          isDone ? 'ENTRENAMIENTO COMPLETADO ✅' : 'INICIAR ENTRENAMIENTO',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROGRESS RING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressRing(double progress) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: _kWhite12,
            valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _kAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE — No routine exists
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏋️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              'SIN RUTINA SEMANAL',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _kWhite,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Genera tu rutina personalizada basada\nen tu perfil metabólico.',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: _kWhite50,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateFirst,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'GENERAR MI RUTINA SEMANAL',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIMMER / LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            width: 180,
            height: 22,
            decoration: BoxDecoration(
              color: _kSurfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 24),
          // Week strip skeleton
          Row(
            children: List.generate(
              7,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 72,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Exercise list skeleton
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _kSurfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar rutina',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _kWhite30),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static const _dayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const _dayAbbrs = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  String _dayName(int index) => _dayNames[index.clamp(0, 6)];
  String _dayAbbr(int index) => _dayAbbrs[index.clamp(0, 6)];

  String _dayTypeIcon(WorkoutDayType type) {
    return switch (type) {
      WorkoutDayType.strengthUpper => '💪',
      WorkoutDayType.strengthLower => '🦵',
      WorkoutDayType.strengthFull => '💪',
      WorkoutDayType.zone2 => '🏃',
      WorkoutDayType.hiit => '⚡',
      WorkoutDayType.rest => '😴',
    };
  }

  String _dayTypeLabel(WorkoutDayType type) {
    return switch (type) {
      WorkoutDayType.strengthUpper => 'TREN SUPERIOR',
      WorkoutDayType.strengthLower => 'TREN INFERIOR',
      WorkoutDayType.strengthFull => 'FULL BODY',
      WorkoutDayType.zone2 => 'CARDIO ZONA 2',
      WorkoutDayType.hiit => 'HIIT',
      WorkoutDayType.rest => 'DESCANSO',
    };
  }

  String _weekLabel(String weekId) {
    // weekId = "2026-W14"
    final parts = weekId.split('-W');
    if (parts.length == 2) {
      final monthNames = [
        '',
        'ENE',
        'FEB',
        'MAR',
        'ABR',
        'MAY',
        'JUN',
        'JUL',
        'AGO',
        'SEP',
        'OCT',
        'NOV',
        'DIC',
      ];
      final month = DateTime.now().month;
      return 'SEMANA ${parts[1]} · ${monthNames[month]}';
    }
    return weekId;
  }
}
