// 17-jul: "Tu racha" (StreakSummaryCard + StreakBarChart de 30 días,
// SPEC-256) se saca del scroll único de AnalysisScreen y pasa a vivir en
// su propia pantalla — ver comentario en resultados_detail_screen.dart,
// mismo movimiento aplicado acá. El contenido no cambió, solo se movió
// de archivo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/streak_bar_chart.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/streak_summary_card.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_engine.dart';

class RachaDetailScreen extends ConsumerWidget {
  const RachaDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakHistory = ref.watch(streakProvider.select((s) => s.history));
    final protectedDates = StreakEngine.computeProtectedDates(streakHistory);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tu racha',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            const StreakSummaryCard(),
            const SizedBox(height: 10),
            StreakBarChart(
              history: streakHistory,
              protectedDates: protectedDates,
            ),
          ],
        ),
      ),
    );
  }
}
