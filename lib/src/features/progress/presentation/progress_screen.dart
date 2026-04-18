// SPEC-15: Road Map de Avance Personal
// Pantalla principal de evolución del usuario.
// Secciones:
//   1. Hero — IMR hoy vs inicio + delta con tendencia
//   2. Evolución IMR — TrendChart 30 días
//   3. Evolución Biométrica — peso y %grasa en check-ins
//   4. Progreso hacia Objetivos — cards de SPEC-14
//   5. CTA — Registrar medidas hoy

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/progress/presentation/biometric_checkin_sheet.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_chart.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress      = ref.watch(progressProvider);
    final goals         = ref.watch(goalsProvider);
    final userAsync     = ref.watch(currentUserStreamProvider);
    final streakState   = ref.watch(streakProvider);
    final fastingState  = ref.watch(fastingProvider);
    final sleepState    = ref.watch(sleepProvider);
    final exerciseState = ref.watch(exerciseProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final engine        = ref.watch(scoreEngineProvider);

    final user = userAsync.valueOrNull;

    // IMR actual
    int currentImr = 0;
    if (user != null) {
      final double realFastingHours = fastingState.isActive
          ? fastingState.duration.inSeconds / 3600
          : 0;
      currentImr = engine.calculateIMR(
        user,
        fastingHours:    realFastingHours,
        weeklyAdherence: streakState.weeklyAdherence,
        exerciseMin:     exerciseState.todayMinutes.toDouble(),
        sleepHours:      sleepState.lastLog?.duration.inHours.toDouble() ?? 7.0,
        lastMealTime:    fastingState.startTime ?? user.profile.lastMealGoal ?? DateTime.now(),
        nutritionScore:  nutritionState.nutritionScore,
      ).totalScore;
    }

    final activeGoals = goals.values.where((g) => g.isActive).toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MI AVANCE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => showBiometricCheckInSheet(context),
            icon: const Icon(Icons.add_rounded,
                color: Color(0xFF1ABC9C), size: 16),
            label: const Text(
              'Medir',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1ABC9C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: progress.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1ABC9C)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── 1. Hero IMR ────────────────────────────────────────────
                  _ImrHero(
                    currentImr:  currentImr,
                    baselineImr: progress.baselineImr,
                    delta:       progress.imrDelta,
                    daysTracked: progress.imrHistory.length,
                  ),
                  const SizedBox(height: 20),

                  // ── 2. Evolución IMR ───────────────────────────────────────
                  _SectionLabel('EVOLUCIÓN METABÓLICA'),
                  const SizedBox(height: 10),
                  progress.hasEnoughImrData
                      ? TrendChart(
                          data:  progress.imrChartPoints,
                          label: 'IMR — últimos ${progress.imrHistory.length} días',
                          color: const Color(0xFF1ABC9C),
                        )
                      : _UnlockCard(
                          current: progress.imrHistory.length,
                          required: 3,
                          message: 'días para ver tu evolución IMR',
                        ),
                  const SizedBox(height: 20),

                  // ── 3. Evolución Biométrica ───────────────────────────────
                  _SectionLabel('COMPOSICIÓN CORPORAL'),
                  const SizedBox(height: 10),
                  _BiometricSection(
                    history:   progress.biometricHistory,
                    hasEnoughWeight: progress.weightChartPoints.length >= 2,
                    hasEnoughBf:    progress.hasEnoughBfData,
                    weightPoints:   progress.weightChartPoints,
                    bfPoints:       progress.bodyFatChartPoints,
                    latestWeight:   progress.latestWeight,
                    latestBf:       progress.latestBodyFat,
                    onCheckIn: () => showBiometricCheckInSheet(context),
                  ),
                  const SizedBox(height: 20),

                  // ── 4. Progreso hacia objetivos ───────────────────────────
                  if (activeGoals.isNotEmpty) ...[
                    _SectionLabel('MIS OBJETIVOS'),
                    const SizedBox(height: 10),
                    _GoalProgressSection(goals: activeGoals),
                    const SizedBox(height: 20),
                  ],

                  // ── 5. CTA check-in ────────────────────────────────────────
                  _CheckInCTA(onTap: () => showBiometricCheckInSheet(context)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ─── Hero IMR ─────────────────────────────────────────────────────────────────

class _ImrHero extends StatelessWidget {
  const _ImrHero({
    required this.currentImr,
    required this.baselineImr,
    required this.delta,
    required this.daysTracked,
  });

  final int  currentImr;
  final int? baselineImr;
  final int? delta;
  final int  daysTracked;

  Color get _zoneColor {
    if (currentImr >= 90) return const Color(0xFF1ABC9C);
    if (currentImr >= 75) return const Color(0xFF27AE60);
    if (currentImr >= 60) return const Color(0xFFF39C12);
    if (currentImr >= 40) return const Color(0xFFE67E22);
    return const Color(0xFFC0392B);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBaseline = baselineImr != null && daysTracked > 1;
    final Color c = _zoneColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withOpacity(0.15), c.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // IMR actual
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMR HOY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currentImr',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: c,
                  height: 1.0,
                ),
              ),
              Text(
                '/ 100',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),
          Container(width: 1, height: 70, color: Colors.white.withOpacity(0.08)),
          const SizedBox(width: 20),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBaseline) ...[
                  _StatRow(
                    label: 'Al inicio',
                    value: '$baselineImr pts',
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Cambio',
                    value: '${delta! >= 0 ? '+' : ''}$delta pts',
                    color: delta! >= 0
                        ? const Color(0xFF1ABC9C)
                        : const Color(0xFFE67E22),
                  ),
                  const SizedBox(height: 8),
                ],
                _StatRow(
                  label: 'Días registrados',
                  value: '$daysTracked días',
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Sección biométrica ───────────────────────────────────────────────────────

class _BiometricSection extends StatelessWidget {
  const _BiometricSection({
    required this.history,
    required this.hasEnoughWeight,
    required this.hasEnoughBf,
    required this.weightPoints,
    required this.bfPoints,
    required this.latestWeight,
    required this.latestBf,
    required this.onCheckIn,
  });

  final List<BiometricCheckIn> history;
  final bool    hasEnoughWeight;
  final bool    hasEnoughBf;
  final List<double> weightPoints;
  final List<double> bfPoints;
  final double? latestWeight;
  final double? latestBf;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _EmptyBiometric(onTap: onCheckIn);
    }

    return Column(
      children: [
        // Stats del último check-in
        _LastCheckInCard(latest: history.last),
        const SizedBox(height: 12),

        // Gráfica de peso
        if (hasEnoughWeight) ...[
          TrendChart(
            data:  weightPoints,
            label: 'Peso — ${history.length} mediciones',
            color: const Color(0xFF3498DB),
          ),
          const SizedBox(height: 12),
        ],

        // Gráfica de %grasa
        if (hasEnoughBf) ...[
          TrendChart(
            data:  bfPoints,
            label: '% Grasa — ${bfPoints.length} mediciones',
            color: const Color(0xFFF39C12),
          ),
          const SizedBox(height: 12),
        ],

        // Historial de check-ins (últimos 5)
        if (history.length > 1)
          _CheckInHistory(history: history.reversed.take(5).toList()),
      ],
    );
  }
}

class _LastCheckInCard extends StatelessWidget {
  const _LastCheckInCard({required this.latest});
  final BiometricCheckIn latest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricChip(
            emoji: '⚖️',
            label: 'Peso',
            value: '${latest.weight.toStringAsFixed(1)} kg',
            color: const Color(0xFF3498DB),
          ),
          if (latest.bodyFatPercentage != null)
            _MetricChip(
              emoji: '🔥',
              label: '%Grasa',
              value: '${latest.bodyFatPercentage!.toStringAsFixed(0)}%',
              color: const Color(0xFFF39C12),
            ),
          if (latest.waistCircumference != null)
            _MetricChip(
              emoji: '📐',
              label: 'Cintura',
              value: '${latest.waistCircumference!.toStringAsFixed(0)} cm',
              color: const Color(0xFF9B59B6),
            ),
          if (latest.imrScore != null)
            _MetricChip(
              emoji: '📊',
              label: 'IMR',
              value: '${latest.imrScore}',
              color: const Color(0xFF1ABC9C),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
  final String emoji;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}

class _CheckInHistory extends StatelessWidget {
  const _CheckInHistory({required this.history});
  final List<BiometricCheckIn> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: history.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      c.date,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.4),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${c.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                    if (c.bodyFatPercentage != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${c.bodyFatPercentage!.toStringAsFixed(0)}% grasa',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                    if (c.imrScore != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'IMR ${c.imrScore}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1ABC9C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (i < history.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.05),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyBiometric extends StatelessWidget {
  const _EmptyBiometric({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3498DB).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('📏', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin medidas registradas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Registra tu primer check-in para ver tu evolución corporal.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.45),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: const Color(0xFF3498DB).withOpacity(0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sección de objetivos ─────────────────────────────────────────────────────

class _GoalProgressSection extends ConsumerWidget {
  const _GoalProgressSection({required this.goals});

  final List<UserGoal> goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user          = ref.watch(currentUserStreamProvider).valueOrNull;
    final streakState   = ref.watch(streakProvider);
    final sleepState    = ref.watch(sleepProvider);
    final exerciseState = ref.watch(exerciseProvider);
    final hydrationState = ref.watch(hydrationProvider);

    double _current(GoalType type) {
      switch (type) {
        case GoalType.weightTarget:
          return user?.weight ?? 0;
        case GoalType.bodyFatTarget:
          return user?.bodyFatPercentage ?? 0;
        case GoalType.fastingDaysPerWeek:
          return (streakState.weeklyAdherence * 7).clamp(0.0, 7.0);
        case GoalType.exerciseMinPerDay:
          return exerciseState.todayMinutes.toDouble();
        case GoalType.sleepHoursPerNight:
          return sleepState.lastLog?.duration.inMinutes != null
              ? sleepState.lastLog!.duration.inMinutes / 60.0
              : 0;
        case GoalType.hydrationLitersPerDay:
          return hydrationState.currentAmountLiters;
      }
    }

    return Column(
      children: goals.map((goal) {
        final double current = _current(goal.type);
        final double prog    = goal.progress(current);
        final Color  c       = goal.pillarColor;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(goal.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${(prog * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: c,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: prog,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(color: c.withOpacity(0.4), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inicio: ${goal.startValue.toStringAsFixed(1)} ${goal.unit}',
                      style: TextStyle(
                        fontSize: 9, color: Colors.white.withOpacity(0.3)),
                    ),
                    Text(
                      'Meta: ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                      style: TextStyle(
                        fontSize: 9, color: c.withOpacity(0.7),
                        fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── CTA Check-in ─────────────────────────────────────────────────────────────

class _CheckInCTA extends StatelessWidget {
  const _CheckInCTA({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1ABC9C).withOpacity(0.12),
              const Color(0xFF1ABC9C).withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1ABC9C).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1ABC9C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('📏', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar medidas hoy',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Peso · %Grasa · Cintura — con IMR automático',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1ABC9C),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_rounded,
              color: Color(0xFF1ABC9C),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard({
    required this.current,
    required this.required,
    required this.message,
  });
  final int    current;
  final int    required;
  final String message;

  @override
  Widget build(BuildContext context) {
    final double prog = (current / this.required).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔒', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Necesitas $required $message',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
              Text(
                '$current / $required',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           prog,
              minHeight:       6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1ABC9C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
