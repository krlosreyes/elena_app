import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../fasting_history_controller.dart';
import 'package:elena_app/src/features/fasting/presentation/widgets/manual_fast_input_sheet.dart';
import '../../../fasting/presentation/fasting_controller.dart';

class FastingChartCard extends ConsumerWidget {
  const FastingChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fastingHistoryProvider);
    final controller = ref.read(fastingHistoryProvider.notifier);
    
    // Get target hours to calculate consistency percentage
    final fastingStateAsync = ref.watch(fastingControllerProvider);
    final targetHours = fastingStateAsync.value?.plannedHours ?? 16.0;

    final chartData = controller.getAggregatedData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [


// ... (existing imports)

          // 1. Header con Título y Botón
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Consistencia',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                   showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => const ManualFastInputSheet(),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Registrar"),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Selector de Vista (Segmented Control Simplificado)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                  color: Theme.of(context).textTheme.titleLarge?.color,
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
                    color: Theme.of(context).dividerColor,
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
                  // Porcentaje de cumplimiento del ayuno
                  final double pct = targetHours > 0 ? (point.y / targetHours) : 0.0;
                  
                  // Colores de la paleta de la app
                  const Color colorRed    = Color(0xFFFF5252); // <50%  rojo
                  const Color colorYellow = Color(0xFFFFB300); // 50-90% ámbar
                  const Color colorGreen  = Color(0xFF00FFB2); // ≥90%  cyan/verde app

                  Color barColor;
                  Color glowColor;
                  if (point.y == 0) {
                    barColor = Colors.transparent;
                    glowColor = Colors.transparent;
                  } else if (pct < 0.5) {
                    barColor = colorRed;
                    glowColor = colorRed.withOpacity(0.25);
                  } else if (pct < 0.9) {
                    barColor = colorYellow;
                    glowColor = colorYellow.withOpacity(0.25);
                  } else {
                    barColor = colorGreen;
                    glowColor = colorGreen.withOpacity(0.2);
                  }

                  return BarChartGroupData(
                    x: point.x,
                    barRods: [
                      BarChartRodData(
                        toY: point.y > 24 ? 24 : point.y,
                        gradient: point.y > 0
                          ? LinearGradient(
                              colors: [barColor.withOpacity(0.6), barColor],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            )
                          : null,
                        color: point.y > 0 ? null : Colors.transparent,
                        width: state.view == MetricType.month ? 6 : 12,
                        borderRadius: BorderRadius.circular(6),
                        borderSide: point.y > 0
                          ? BorderSide(color: barColor.withOpacity(0.7), width: 1.5)
                          : BorderSide.none,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 24,
                          color: glowColor.withOpacity(0.06),
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
                       // Concatenamos todo en un solo string para evitar fallos de renderizado de TextSpans en Flutter Web con fl_chart
                       final isYear = state.view == MetricType.year;
                       final subtitleText = isYear ? 'Promedio' : 'Completado';
                       return BarTooltipItem(
                         '${item.y.toStringAsFixed(1)}h\n$subtitleText',
                         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
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
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
