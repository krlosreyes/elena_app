// SPEC-110: pantalla Análisis - Vista de "Hoy".
//
// Composición:
//   - AppBar simple con título y fecha.
//   - Strip semanal (L-D) con micro-anillos del IMR por día.
//   - Anillo central grande con el IMR del día + 5 satélites
//     (uno por pilar) en pentágono.
//   - Card "RACHA ACTIVA".
//   - Lista vertical "PILARES DE HOY" con barra de progreso por
//     pilar y métrica concreta.
//   - BottomNavigationBar (Dashboard / Análisis / Perfil).
//
// MVP: solo data del día actual. Días pasados del strip aparecen
// como placeholders hasta que SPEC-111 agregue persistencia diaria.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_provider.dart';
import 'package:elena_app/src/features/analysis/presentation/monthly_calendar_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_ring_with_satellites.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/pillar_progress_row.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/streak_summary_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/weekly_strip.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart'
    show FastingState;
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailySummaryProvider);
    final fasting = ref.watch(fastingProvider);
    final sleep = ref.watch(sleepProvider);
    final hydration = ref.watch(hydrationProvider);
    final exercise = ref.watch(exerciseProvider);
    final nutrition = ref.watch(nutritionProvider);

    final today = DateTime.now();
    final dateLabel = DateFormat("EEEE d 'de' MMMM", 'es').format(today);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ANÁLISIS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _capitalize(dateLabel),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 64,
        actions: [
          // SPEC-112: acceso a la vista calendario mensual.
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MonthlyCalendarScreen(),
                fullscreenDialog: true,
              ),
            ),
            tooltip: 'Ver mes',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strip semanal
            WeeklyStrip(todaySummary: summary),
            const SizedBox(height: 16),

            // SPEC-110.3: card contenedora del anillo central y los
            // 5 satélites. Agrupa visualmente, conecta strip con
            // racha y elimina la sensación de "5 elementos flotando
            // sueltos en el navy".
            Container(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ImrRingWithSatellites(summary: summary),
            ),
            const SizedBox(height: 16),

            // Racha
            const StreakSummaryCard(),
            const SizedBox(height: 20),

            // Lista de pilares
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'PILARES DE HOY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            PillarProgressRow(
              icon: Icons.timer_rounded,
              color: AppColors.metabolicGreen,
              label: 'Ayuno',
              metric: _fastingMetric(fasting),
              progress: summary.fastingProgress,
            ),
            PillarProgressRow(
              icon: Icons.nightlight_round,
              color: const Color(0xFF818CF8),
              label: 'Sueño',
              metric: _sleepMetric(sleep),
              progress: summary.sleepProgress,
            ),
            PillarProgressRow(
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF38BDF8),
              label: 'Hidratación',
              metric:
                  '${hydration.currentFormatted} / ${hydration.goalFormatted} L',
              progress: summary.hydrationProgress,
            ),
            PillarProgressRow(
              icon: Icons.fitness_center_rounded,
              color: const Color(0xFF14B8A6),
              label: 'Ejercicio',
              metric: '${exercise.todayMinutes} / 60 min',
              progress: summary.exerciseProgress,
            ),
            PillarProgressRow(
              icon: Icons.restaurant_rounded,
              color: const Color(0xFFFB923C),
              label: 'Comidas',
              metric:
                  '${nutrition.mealsLoggedToday} / ${nutrition.targetMeals} comidas',
              progress: summary.mealsProgress,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/analysis');
          if (index == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _fastingMetric(FastingState s) {
    if (!s.isActive) return 'Sin ayuno activo';
    final hours = s.duration.inHours;
    final minutes = s.duration.inMinutes.remainder(60);
    final target = s.targetHours;
    return '${hours}h ${minutes}m / ${target}h · ${s.fastingProtocol}';
  }

  String _sleepMetric(SleepState s) {
    final log = s.lastLog;
    if (log == null) return 'Sin registro';
    final hours = log.duration.inHours;
    final minutes = log.duration.inMinutes.remainder(60);
    final quality = log.subjectiveQuality;
    final qLabel = quality != null ? ' · ★$quality' : '';
    return '${hours}h ${minutes}m$qLabel';
  }
}
