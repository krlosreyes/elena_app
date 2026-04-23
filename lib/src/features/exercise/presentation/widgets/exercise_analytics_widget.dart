import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

/// SPEC-37-05: Widget de analytics de intensidad vs efectividad
/// Muestra cómo se sintió el usuario post-ejercicio vs intensidad realizada
class ExerciseAnalyticsWidget extends ConsumerWidget {
  final List<ExerciseLog> weekLogs;

  const ExerciseAnalyticsWidget({
    Key? key,
    required this.weekLogs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = _calculateExerciseStats(weekLogs);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análisis de Intensidad vs Efectividad (7 días)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildIntensityDistribution(stats),
            const SizedBox(height: 20),
            _buildEffectivenessAnalysis(stats),
            const SizedBox(height: 20),
            _buildMetabolicLoadChart(stats),
            const SizedBox(height: 20),
            _buildUserPerceptionVsIntensity(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityDistribution(ExerciseStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución de Intensidad',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildIntensityBar(
          label: 'LISS (<40%)',
          count: stats.lissCount,
          total: stats.totalExercises,
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _buildIntensityBar(
          label: 'STRENGTH (40-70%)',
          count: stats.strengthCount,
          total: stats.totalExercises,
          color: Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildIntensityBar(
          label: 'HIIT (>70%)',
          count: stats.hiitCount,
          total: stats.totalExercises,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildIntensityBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percent = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              '$count sesiones (${percent.toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 16,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildEffectivenessAnalysis(ExerciseStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carga Metabólica Acumulada',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: 'Total',
                value: '${stats.totalMetabolicLoad.toStringAsFixed(1)}',
                unit: 'unidades',
              ),
              _buildStatItem(
                label: 'Promedio/sesión',
                value: stats.totalExercises > 0
                    ? '${(stats.totalMetabolicLoad / stats.totalExercises).toStringAsFixed(2)}'
                    : '0',
                unit: 'unidades',
              ),
              _buildStatItem(
                label: 'Sesiones',
                value: '${stats.totalExercises}',
                unit: 'veces',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicLoadChart(ExerciseStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progresión de Carga (últimos 7 días)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildLoadBar(
                    day: 'L',
                    load: stats.dailyLoads.isNotEmpty
                        ? stats.dailyLoads[0]
                        : 0,
                  ),
                  _buildLoadBar(
                    day: 'M',
                    load: stats.dailyLoads.length > 1
                        ? stats.dailyLoads[1]
                        : 0,
                  ),
                  _buildLoadBar(
                    day: 'X',
                    load: stats.dailyLoads.length > 2
                        ? stats.dailyLoads[2]
                        : 0,
                  ),
                  _buildLoadBar(
                    day: 'J',
                    load: stats.dailyLoads.length > 3
                        ? stats.dailyLoads[3]
                        : 0,
                  ),
                  _buildLoadBar(
                    day: 'V',
                    load: stats.dailyLoads.length > 4
                        ? stats.dailyLoads[4]
                        : 0,
                  ),
                  _buildLoadBar(
                    day: 'S',
                    load: stats.dailyLoads.length > 5
                        ? stats.dailyLoads[5]
                        : 0,
                  ),
                  _buildLoadBar(
                    day: 'D',
                    load: stats.dailyLoads.length > 6
                        ? stats.dailyLoads[6]
                        : 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadBar({required String day, required double load}) {
    final maxLoad = 5.0;
    final height = (load / maxLoad) * 80;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: height,
          decoration: BoxDecoration(
            color: _getLoadColor(load),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildUserPerceptionVsIntensity(ExerciseStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback del Usuario (SPEC-37-05)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (stats.exercisesWithFeedback == 0)
            const Text(
              'Sin feedback registrado aún',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  label: 'Percepción Promedio',
                  value: stats.avgPerceptionScore
                      .toStringAsFixed(1),
                  unit: '/10',
                ),
                _buildStatItem(
                  label: 'Ejercicios Evaluados',
                  value: '${stats.exercisesWithFeedback}',
                  unit: 'sesiones',
                ),
                _buildStatItem(
                  label: 'Satisfacción',
                  value: stats.avgPerceptionScore > 7
                      ? '🟢 Excelente'
                      : stats.avgPerceptionScore > 5
                          ? '🟡 Buena'
                          : '🔴 Mejorar',
                  unit: '',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
      ],
    );
  }

  Color _getLoadColor(double load) {
    if (load < 1) return Colors.grey[300]!;
    if (load < 2) return Colors.green;
    if (load < 3) return Colors.orange;
    return Colors.red;
  }

  ExerciseStats _calculateExerciseStats(List<ExerciseLog> logs) {
    int lissCount = 0;
    int strengthCount = 0;
    int hiitCount = 0;
    double totalMetabolicLoad = 0;
    int exercisesWithFeedback = 0;
    double totalPerceptionScore = 0;
    final dailyLoads = List<double>.filled(7, 0);

    for (final log in logs) {
      if (log.intensityPercent == null) continue;

      // Categorizar
      if (log.intensityPercent! < 40) {
        lissCount++;
      } else if (log.intensityPercent! < 70) {
        strengthCount++;
      } else {
        hiitCount++;
      }

      // Acumular carga
      if (log.metabolicLoad != null) {
        totalMetabolicLoad += log.metabolicLoad!;
      }

      // Feedback
      if (log.userPerceptionScore != null) {
        exercisesWithFeedback++;
        totalPerceptionScore += log.userPerceptionScore!;
      }
    }

    final avgPerceptionScore =
        exercisesWithFeedback > 0 ? totalPerceptionScore / exercisesWithFeedback : 0;

    return ExerciseStats(
      lissCount: lissCount,
      strengthCount: strengthCount,
      hiitCount: hiitCount,
      totalExercises: logs.length,
      totalMetabolicLoad: totalMetabolicLoad,
      dailyLoads: dailyLoads,
      exercisesWithFeedback: exercisesWithFeedback,
      avgPerceptionScore: avgPerceptionScore,
    );
  }
}

/// Modelo para estadísticas de ejercicio
class ExerciseStats {
  final int lissCount;
  final int strengthCount;
  final int hiitCount;
  final int totalExercises;
  final double totalMetabolicLoad;
  final List<double> dailyLoads;
  final int exercisesWithFeedback;
  final double avgPerceptionScore;

  ExerciseStats({
    required this.lissCount,
    required this.strengthCount,
    required this.hiitCount,
    required this.totalExercises,
    required this.totalMetabolicLoad,
    required this.dailyLoads,
    required this.exercisesWithFeedback,
    required this.avgPerceptionScore,
  });
}
