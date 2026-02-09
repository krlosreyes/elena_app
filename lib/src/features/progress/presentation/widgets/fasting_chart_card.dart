import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../fasting_history_controller.dart';

class FastingChartCard extends ConsumerWidget {
  const FastingChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fastingHistoryProvider);
    final controller = ref.read(fastingHistoryProvider.notifier);
    
    final chartData = controller.getAggregatedData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // 1. Selector de Vista (Segmented Control Simplificado)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildSegment(context, 'Semana', MetricType.week, state.view, controller),
                _buildSegment(context, 'Mes', MetricType.month, state.view, controller),
                _buildSegment(context, 'Año', MetricType.year, state.view, controller),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 2. Navegación de Fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton( 
                onPressed: controller.previous, 
                icon: const Icon(Icons.chevron_left),
                color: Colors.grey,
              ),
              Text(
                controller.getDateLabel(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              IconButton( 
                onPressed: controller.next, 
                icon: const Icon(Icons.chevron_right),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 3. Gráfico (Chart)
          SizedBox(
            height: 200,
            child: state.isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 24, // Limite teórico
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[100],
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  // Eje Izquierdo (Horas)
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  // Eje Inferior (Días/Meses)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                         if (value < 0 || value >= chartData.length) return const SizedBox.shrink();
                         return Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(
                             chartData[value.toInt()].label,
                             style: const TextStyle(
                               color: Colors.grey, 
                               fontSize: 10,
                               fontWeight: FontWeight.bold
                             ),
                           ),
                         );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData.map((point) {
                  return BarChartGroupData(
                    x: point.x,
                    barRods: [
                      BarChartRodData(
                        toY: point.y,
                        color: Theme.of(context).primaryColor,
                        width: state.view == MetricType.month ? 6 : 12,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 24, // Full height reference
                            color: Colors.grey[50], 
                        ),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87, // Fixed: use getTooltipColor
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                       final item = chartData[group.x.toInt()];
                       return BarTooltipItem(
                         '${item.y.toStringAsFixed(1)}h\n',
                         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                         children: [
                           TextSpan(
                             text: 'Promedio', // Si es año, o 'Total'
                             style: const TextStyle(
                               color: Colors.white70,
                               fontSize: 10,
                               fontWeight: FontWeight.normal
                             )
                           ),
                         ]
                       );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
           // Leyenda / Info
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
               const SizedBox(width: 4),
               Text(
                 state.view == MetricType.year 
                     ? 'Promedio diario por mes' 
                     : 'Horas totales por día',
                 style: TextStyle(fontSize: 11, color: Colors.grey[500]),
               ),
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildSegment(BuildContext context, String label, MetricType type, MetricType current, FastingHistoryController controller) {
    final isSelected = type == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setView(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected 
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] 
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
