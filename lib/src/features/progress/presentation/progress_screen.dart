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
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';
import 'package:elena_app/src/features/progress/presentation/biometric_checkin_sheet.dart';
import 'package:elena_app/src/features/progress/presentation/widgets/biometric_evolution_section.dart';
import 'package:elena_app/src/features/progress/presentation/widgets/goal_progress_section.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_chart.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final goals = ref.watch(goalsProvider);
    final userAsync = ref.watch(currentUserStreamProvider);
    // SPEC-116: streakProvider y user no se consumen aquí pero el
    // watch del primero se mantiene como side-effect para que el
    // provider se mantenga vivo mientras la pantalla está montada.
    ref.watch(streakProvider);
    // ignore: unused_local_variable
    final user = userAsync.valueOrNull;

    // SPEC-52: IMR central desde el provider — sin cálculos locales.
    final int currentImr = ref.watch(imrProvider).totalScore;

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
                    currentImr: currentImr,
                    baselineImr: progress.baselineImr,
                    delta: progress.imrDelta,
                    daysTracked: progress.imrHistory.length,
                  ),
                  const SizedBox(height: 20),

                  // ── 2. Evolución IMR ───────────────────────────────────────
                  _SectionLabel('EVOLUCIÓN METABÓLICA'),
                  const SizedBox(height: 10),
                  progress.hasEnoughImrData
                      ? TrendChart(
                          data: progress.imrChartPoints,
                          label:
                              'IMR — últimos ${progress.imrHistory.length} días',
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
                  BiometricEvolutionSection(
                    history: progress.biometricHistory,
                    hasEnoughWeight: progress.weightChartPoints.length >= 2,
                    hasEnoughBf: progress.hasEnoughBfData,
                    weightPoints: progress.weightChartPoints,
                    bfPoints: progress.bodyFatChartPoints,
                    latestWeight: progress.latestWeight,
                    latestBf: progress.latestBodyFat,
                    onCheckIn: () => showBiometricCheckInSheet(context),
                  ),
                  const SizedBox(height: 20),

                  // ── 4. Progreso hacia objetivos ───────────────────────────
                  if (activeGoals.isNotEmpty) ...[
                    _SectionLabel('MIS OBJETIVOS'),
                    const SizedBox(height: 10),
                    GoalProgressSection(goals: activeGoals),
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

  final int currentImr;
  final int? baselineImr;
  final int? delta;
  final int daysTracked;

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
          colors: [c.withValues(alpha: 0.15), c.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1.5),
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
                  color: Colors.white.withValues(alpha: 0.35),
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
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),
          Container(
              width: 1,
              height: 70,
              color: Colors.white.withValues(alpha: 0.08)),
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
            color: Colors.white.withValues(alpha: 0.3),
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

// SPEC-119: sección biométrica (_BiometricSection + _LastCheckInCard +
// _MetricChip + _CheckInHistory + _EmptyBiometric) → BiometricEvolutionSection
// (widgets/biometric_evolution_section.dart). Extraído en ARCH-03.

// SPEC-119: sección de objetivos (_GoalProgressSection) → GoalProgressSection
// (widgets/goal_progress_section.dart). Extraído en ARCH-03/PERF-01
// (ver comentario de PERF-01 en ese archivo).

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
              const Color(0xFF1ABC9C).withValues(alpha: 0.12),
              const Color(0xFF1ABC9C).withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1ABC9C).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1ABC9C).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(AppIcons.cinturaEstatura,
                  size: 20, color: Colors.white.withValues(alpha: 0.85)),
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
        color: Colors.white.withValues(alpha: 0.3),
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
  final int current;
  final int required;
  final String message;

  @override
  Widget build(BuildContext context) {
    final double prog = (current / required).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(AppIcons.bloqueado,
                  size: 18, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Necesitas $required $message',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                '$current / $required',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prog,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
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
