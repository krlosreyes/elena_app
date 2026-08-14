// SPEC-296 — Sección "Actividades": las sesiones importadas de Apple Health /
// Health Connect con sus datos reales (calorías, inicio, duración, distancia)
// y un beneficio por tipo. Lee `exerciseProvider.history`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_benefit.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

const Color _accent = AppColors.pillarEjercicio;

class ImportedActivitiesSection extends ConsumerWidget {
  const ImportedActivitiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(exerciseProvider).history;
    final now = DateTime.now();
    bool sameDay(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    // Actividades de HOY, más recientes primero.
    final today = history.where((l) => sameDay(l.timestamp)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (today.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Actividades',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ),
        for (final log in today) _ActivityCard(log: log),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ExerciseLog log;
  const _ActivityCard({required this.log});

  static String _timeLabel(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return 'Hoy, $h:$m h';
  }

  bool get _fromApple => (log.sourceName ?? '').toLowerCase().contains('apple');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(ExerciseBenefit.emojiFor(log.type),
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.activityType,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const Text('Hoy',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (_fromApple) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.favorite,
                    size: 14, color: AppColors.statusBad),
                const SizedBox(width: 6),
                Text('Importado desde Apple Health',
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 12.5)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(
              height: 1, color: AppColors.borderDefault.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          if (log.caloriesKcal != null)
            _row(
              'Calorías de actividad',
              '🔥 ${log.caloriesKcal!.round()} kcal',
              highlight: true,
            ),
          _row('Inicio', _timeLabel(log.timestamp)),
          _row('Duración', '${log.durationMinutes} minutos'),
          if (log.distanceKm != null)
            _row('Distancia', '${log.distanceKm!.toStringAsFixed(2)} km'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ExerciseBenefit.forType(log.type),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: _accent),
                    const SizedBox(width: 6),
                    const Text('Cuenta para tu pilar de Ejercicio de hoy',
                        style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.statusBad.withValues(alpha: 0.10)
                  : AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value,
                style: TextStyle(
                    color: highlight
                        ? AppColors.statusBad
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
