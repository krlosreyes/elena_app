// SPEC-140: card del Score del Día.
//
// Renderiza el score 0-100 motivacional como número grande monospace,
// barra de progreso lineal con color contextual (rojo/amarillo/verde),
// y delta vs ayer cuando hay historial. Icono ⓘ abre BottomSheet
// educativo con los pesos y el disclaimer Score vs IMR.
//
// Ubicación en el Dashboard: entre el reloj circadiano y la fila
// PILARES HOY. Comparte jerarquía visual con los pilares — el Score
// del Día es el agregado de esos 5 anillos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/daily_score_explainer_sheet.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';

class DailyScoreCard extends ConsumerWidget {
  const DailyScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(dailyScoreProvider);
    final delta = ref.watch(dailyScoreDeltaProvider);
    final progress = (score / 100).clamp(0.0, 1.0);
    final color = _scoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TU DÍA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                key: const Key('daily_score_info_button'),
                icon: Icon(
                  Icons.info_outline,
                  color: Colors.white.withValues(alpha: 0.45),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: () => showDailyScoreExplainerSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progreso con color contextual.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 10),
            _DeltaLabel(delta: delta),
          ],
        ],
      ),
    );
  }

  /// SPEC-140 §RF-140-04: color de la barra según el rango del score.
  /// Rojo < 40, amarillo 40-69, verde >= 70.
  Color _scoreColor(int score) {
    if (score < 40) return const Color(0xFFEF4444); // rojo
    if (score < 70) return const Color(0xFFF59E0B); // amarillo / ámbar
    return AppColors.metabolicGreen;
  }
}

class _DeltaLabel extends StatelessWidget {
  const _DeltaLabel({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) {
      return Text(
        'igual que ayer',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    final isPositive = delta > 0;
    final arrow = isPositive ? '↑' : '↓';
    final magnitude = delta.abs();
    final color = isPositive
        ? AppColors.metabolicGreen
        : const Color(0xFFEF4444);
    return Row(
      children: [
        Text(
          arrow,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$magnitude vs ayer',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
