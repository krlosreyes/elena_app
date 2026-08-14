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

  bool get _fromApple => (log.sourceName ?? '').toLowerCase().contains('apple');

  /// "Hoy, 11:17 · 30 min" — hora de inicio + duración en una sola línea.
  String get _metaLine {
    final h = log.timestamp.hour.toString().padLeft(2, '0');
    final m = log.timestamp.minute.toString().padLeft(2, '0');
    return 'Hoy, $h:$m · ${log.durationMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    // Chips de datos duros: solo se pintan si el dato existe (evita la card
    // vacía de una entrada manual sin calorías/distancia).
    final metrics = <Widget>[
      if (_fromApple)
        _MetricChip(
          icon: Icons.favorite,
          iconColor: AppColors.statusBad,
          label: 'Apple Health',
        ),
      if (log.caloriesKcal != null)
        _MetricChip(label: '🔥 ${log.caloriesKcal!.round()} kcal'),
      if (log.distanceKm != null)
        _MetricChip(label: '📍 ${log.distanceKm!.toStringAsFixed(2)} km'),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(ExerciseBenefit.emojiFor(log.type),
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.activityType,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(_metaLine,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: metrics),
          ],
          const SizedBox(height: 12),
          // Beneficio: una línea educativa + el sello de que cuenta al pilar.
          Text(ExerciseBenefit.forType(log.type),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 15, color: _accent),
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
    );
  }
}

/// Chip compacto para un dato duro (fuente, calorías, distancia).
class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, this.icon, this.iconColor});

  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(9),
        border:
            Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
