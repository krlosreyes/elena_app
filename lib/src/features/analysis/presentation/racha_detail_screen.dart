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
import 'package:elena_app/src/features/streak/presentation/widgets/rest_day_settings_sheet.dart';

class RachaDetailScreen extends ConsumerWidget {
  const RachaDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakHistory = ref.watch(streakProvider.select((s) => s.history));
    final restPolicy = ref.watch(streakProvider.select((s) => s.restPolicy));
    // 28-jul: la política entra en el cálculo para que el histórico no
    // pinte como "perdonado por reserva" un día que en realidad fue un
    // descanso planificado. Son cosas distintas y el usuario tiene que
    // poder distinguirlas de un vistazo.
    final protectedDates = StreakEngine.computeProtectedDates(
      streakHistory,
      restPolicy: restPolicy,
    );

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
            const SizedBox(height: 16),
            const _RestDayEntry(),
          ],
        ),
      ),
    );
  }
}

/// Entrada a los ajustes del día de descanso (28-jul).
///
/// Vive aquí, junto al histórico, y no enterrada en Configuración: el
/// descanso es parte de cómo funciona la racha, así que se explica y se
/// configura donde el usuario está mirando la racha. Si hay que ir a
/// buscarlo, no lo encuentra el que más lo necesita.
class _RestDayEntry extends ConsumerWidget {
  const _RestDayEntry();

  static const _amber = Color(0xFFF59E0B);

  static const _nombres = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(streakProvider.select((s) => s.restPolicy));
    final nextRest = ref.watch(streakProvider.select((s) => s.nextRestDate));
    final weekday = policy.weeklyRestWeekday;

    // Si el descanso de esta semana está movido, decir "Cada domingo"
    // sería mentir sobre lo que va a pasar. Gana lo concreto.
    final String subtitle;
    if (nextRest != null && policy.isMovedWeekOf(nextRest)) {
      final d = DateTime.parse(nextRest);
      subtitle = 'Esta semana: ${_nombres[d.weekday - 1]} ${d.day}';
    } else if (weekday == null) {
      subtitle = 'Sin configurar — elige un día';
    } else {
      subtitle = 'Cada ${_nombres[weekday - 1]}';
    }

    return InkWell(
      onTap: () => showRestDaySettingsSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.nightlight_round,
                size: 18, color: _amber.withValues(alpha: 0.9)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu día de descanso',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}
