import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// SPEC-36-05: Widget de analytics de distribución de macros
/// Muestra pie chart y estadísticas de la semana pasada
class MacroAnalyticsWidget extends ConsumerWidget {
  final List<NutritionLog> weekLogs;

  const MacroAnalyticsWidget({
    Key? key,
    required this.weekLogs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = _calculateMacroStats(weekLogs);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Macros (7 días)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMacroPieChart(stats),
            const SizedBox(height: 20),
            _buildMacroBreakdown(stats),
            const SizedBox(height: 20),
            _buildAverageMetrics(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPieChart(MacroStats stats) {
    final totalMacros = stats.totalCarbsG + stats.totalProteinG + stats.totalFatG;
    if (totalMacros == 0) {
      return const Center(
        child: Text('Sin datos de macros esta semana'),
      );
    }

    final carbsPercent = (stats.totalCarbsG / totalMacros) * 100;
    final proteinPercent = (stats.totalProteinG / totalMacros) * 100;
    final fatPercent = (stats.totalFatG / totalMacros) * 100;

    return Column(
      children: [
        // Pie chart simplificado con barras
        Column(
          children: [
            _buildMacroBar(
              label: 'Carbohidratos',
              percent: carbsPercent,
              color: Colors.orange,
              value: '${stats.totalCarbsG.toStringAsFixed(0)}g',
            ),
            const SizedBox(height: 12),
            _buildMacroBar(
              label: 'Proteína',
              percent: proteinPercent,
              color: Colors.red,
              value: '${stats.totalProteinG.toStringAsFixed(0)}g',
            ),
            const SizedBox(height: 12),
            _buildMacroBar(
              label: 'Grasas',
              percent: fatPercent,
              color: Colors.blue,
              value: '${stats.totalFatG.toStringAsFixed(0)}g',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroBar({
    required String label,
    required double percent,
    required Color color,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '${percent.toStringAsFixed(1)}% ($value)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 20,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBreakdown(MacroStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Totales Semanales',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: 'Carbs',
                value: '${stats.totalCarbsG.toStringAsFixed(0)}g',
                color: Colors.orange,
              ),
              _buildStatItem(
                label: 'Proteína',
                value: '${stats.totalProteinG.toStringAsFixed(0)}g',
                color: Colors.red,
              ),
              _buildStatItem(
                label: 'Grasas',
                value: '${stats.totalFatG.toStringAsFixed(0)}g',
                color: Colors.blue,
              ),
              _buildStatItem(
                label: 'Fibra',
                value: '${stats.totalFiberG.toStringAsFixed(0)}g',
                color: Colors.green,
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
    required Color color,
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAverageMetrics(MacroStats stats) {
    final daysWithData = weekLogs.where((log) => log.carbsG != null).length;
    if (daysWithData == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promedios Diarios (días con registro)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAvgItem(
                label: 'Carbs/día',
                value: '${(stats.totalCarbsG / daysWithData).toStringAsFixed(0)}g',
              ),
              _buildAvgItem(
                label: 'Proteína/día',
                value: '${(stats.totalProteinG / daysWithData).toStringAsFixed(0)}g',
              ),
              _buildAvgItem(
                label: 'Grasas/día',
                value: '${(stats.totalFatG / daysWithData).toStringAsFixed(0)}g',
              ),
              _buildAvgItem(
                label: 'Calorías/día',
                value: '${(stats.totalCalories / daysWithData).toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvgItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  MacroStats _calculateMacroStats(List<NutritionLog> logs) {
    double totalCarbsG = 0;
    double totalProteinG = 0;
    double totalFatG = 0;
    double totalFiberG = 0;
    int totalCalories = 0;
    int daysWithData = 0;

    for (final log in logs) {
      if (log.carbsG != null &&
          log.proteinG != null &&
          log.fatG != null) {
        totalCarbsG += log.carbsG!;
        totalProteinG += log.proteinG!;
        totalFatG += log.fatG!;
        totalFiberG += log.fiberG ?? 0;
        totalCalories += log.totalCalories ?? 0;
        daysWithData++;
      }
    }

    return MacroStats(
      totalCarbsG: totalCarbsG,
      totalProteinG: totalProteinG,
      totalFatG: totalFatG,
      totalFiberG: totalFiberG,
      totalCalories: totalCalories,
      daysWithData: daysWithData,
    );
  }
}

/// Modelo para estadísticas de macros
class MacroStats {
  final double totalCarbsG;
  final double totalProteinG;
  final double totalFatG;
  final double totalFiberG;
  final int totalCalories;
  final int daysWithData;

  MacroStats({
    required this.totalCarbsG,
    required this.totalProteinG,
    required this.totalFatG,
    required this.totalFiberG,
    required this.totalCalories,
    required this.daysWithData,
  });
}
