// SPEC-137 §RF-137-12: vista semanal del pilar Nutrición.
//
// Pantalla navegable desde la tarjeta "Nutrición Científica" del
// Dashboard. Muestra los últimos 7 días con:
// - Header: Cociente A semanal (promedio ponderado de los días con
//   logs, excluyendo cheat days).
// - Heatmap: una fila por día, una celda por plato registrado.
// - Leyenda de colores A/E.
// - Badge en celdas de cheat day.
//
// IMPORTANTE: la fuente de logs es el stream del NutritionRepository
// (todayLogs). Para semanas históricas existe una colección más
// amplia, pero para el MVP partimos del state local (que tiene los
// logs HOY). Para días anteriores leemos de Firestore via la API
// existente del NutritionRepository (que ya expone watchTodayLogs
// para hoy; ampliar a histórico vive en SPEC-138 post-MVP).
//
// En este MVP, los 7 días son: hoy + 6 días previos derivados del
// state.todayLogs si existen, o vacíos en placeholder. La SPEC-138
// agrega la query histórica completa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
import 'package:elena_app/src/features/nutrition/application/meal_target_service.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class NutritionWeeklyScreen extends ConsumerWidget {
  const NutritionWeeklyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(nutritionProvider);
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final protocol = user?.fastingProtocol ?? 'Ninguno';
    final target = const MealTargetService().targetForProtocol(protocol);
    const cocienteService = CocienteAService();

    final todayLogs = nutrition.todayLogs;
    final cocienteAHoy = cocienteService.calculate(todayLogs);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        title: const Text(
          'Tu semana de nutrición',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CocienteHeader(
                cocienteHoy: cocienteAHoy,
                logsHoyCount: todayLogs.length,
                aDominantCount: cocienteService.aDominantCount(todayLogs),
                targetMeals: target.meals,
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Heatmap de la semana'),
              const SizedBox(height: 12),
              _WeekHeatmap(
                todayLogs: todayLogs,
                target: target,
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Cómo leer este heatmap'),
              const SizedBox(height: 12),
              _Legend(),
              const SizedBox(height: 24),
              const _EmptyHistoricalNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
}

class _CocienteHeader extends StatelessWidget {
  final double cocienteHoy;
  final int logsHoyCount;
  final int aDominantCount;
  final int targetMeals;

  const _CocienteHeader({
    required this.cocienteHoy,
    required this.logsHoyCount,
    required this.aDominantCount,
    required this.targetMeals,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (cocienteHoy * 100).round();
    final color = _colorForCociente(cocienteHoy);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COCIENTE A · HOY',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$pct%',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  logsHoyCount == 0
                      ? 'Aún no registraste platos hoy'
                      : '$aDominantCount de $logsHoyCount platos A-dominantes',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (logsHoyCount < targetMeals)
            Text(
              'Tu protocolo sugiere $targetMeals platos hoy. Llevas $logsHoyCount.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          else if (cocienteHoy >= 0.75)
            Text(
              'Excelente día. Mantén el ritmo.',
              style: TextStyle(
                color: AppColors.statusGood,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Si quieres llegar a 75% de Cociente A, tu próximo plato '
              'debe ser A-dominante.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Color _colorForCociente(double v) {
    if (v >= 0.75) return AppColors.statusGood;
    if (v >= 0.50) return AppColors.accent;
    if (v >= 0.25) return AppColors.statusWarn;
    return AppColors.statusBad;
  }
}

class _WeekHeatmap extends StatelessWidget {
  final List<NutritionLog> todayLogs;
  final MealTarget target;

  const _WeekHeatmap({
    required this.todayLogs,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 7 días: hoy + 6 previos. Para días previos al de hoy no tenemos
    // logs en el state actual (el provider sólo expone todayLogs);
    // MVP los pinta como placeholder. SPEC-138 agrega la query
    // histórica.
    final days = List<DateTime>.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );

    return Column(
      children: days.map((day) {
        final isToday = _isSameDay(day, now);
        final logsForDay = isToday ? todayLogs : const <NutritionLog>[];
        return _DayRow(
          day: day,
          logs: logsForDay,
          target: target,
          isToday: isToday,
        );
      }).toList(),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayRow extends StatelessWidget {
  final DateTime day;
  final List<NutritionLog> logs;
  final MealTarget target;
  final bool isToday;

  const _DayRow({
    required this.day,
    required this.logs,
    required this.target,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final hasCheatDay = logs.any((l) => l.isCheatDay);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdayShort(day.weekday),
                  style: TextStyle(
                    color: isToday
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(target.meals, (i) {
                final log = i < logs.length ? logs[i] : null;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _Cell(log: log),
                  ),
                );
              }),
            ),
          ),
          if (hasCheatDay)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusWarn.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Permitidos',
                style: TextStyle(
                  color: AppColors.statusWarn,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _weekdayShort(int w) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[(w - 1).clamp(0, 6)];
  }
}

class _Cell extends StatelessWidget {
  final NutritionLog? log;
  const _Cell({this.log});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(log?.ratio);
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: log == null
            ? Border.all(
                color: AppColors.borderDefault,
                width: 1,
              )
            : null,
      ),
    );
  }

  Color _colorFor(MealRatio? ratio) {
    if (ratio == null) return AppColors.bgElevated;
    return switch (ratio) {
      MealRatio.allA => AppColors.statusGood,
      MealRatio.a3e1 => AppColors.statusGood,
      MealRatio.a2e1 => AppColors.accent,
      MealRatio.a1e1 => AppColors.statusWarn,
      MealRatio.allE => AppColors.statusBad,
    };
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendChip(color: AppColors.statusGood, label: 'A-dominante'),
        _LegendChip(color: AppColors.accent, label: '2 a 1'),
        _LegendChip(color: AppColors.statusWarn, label: '1 a 1'),
        _LegendChip(color: AppColors.statusBad, label: 'Todo E'),
        _LegendChip(color: AppColors.bgElevated, label: 'Sin registrar'),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: AppColors.borderDefault,
              width: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoricalNote extends StatelessWidget {
  const _EmptyHistoricalNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu historial completo se construye con cada plato '
              'registrado. En unos días tendrás la semana completa.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
