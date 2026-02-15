import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_model.dart';
import 'package:elena_app/src/features/glucose/presentation/providers/glucose_provider.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_input_sheet.dart';

class GlucoseChartWidget extends ConsumerWidget {
  const GlucoseChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glucoseAsync = ref.watch(filteredGlucoseProvider);
    final selectedFilter = ref.watch(glucoseTimeFilterProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER with Title and Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Control de Glucemia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showInputSheet(context),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text("Registrar"),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // TIME FILTER
            _buildTimeFilter(ref, selectedFilter),
            const SizedBox(height: 20),

            // CHART
            SizedBox(
              height: 250,
              child: glucoseAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text('Sin registros este periodo',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return _buildChart(logs, context, selectedFilter);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(WidgetRef ref, TimeFilter selectedFilter) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: TimeFilter.values.map((filter) {
          final isSelected = filter == selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(glucoseTimeFilterProvider.notifier).state = filter;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  filter == TimeFilter.semana
                      ? 'Semana'
                      : filter == TimeFilter.mes
                          ? 'Mes'
                          : 'Año',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const GlucoseInputSheet(), 
    );
  }

  Widget _buildChart(List<GlucoseLog> logs, BuildContext context, TimeFilter filter) {
    // 1. Sort logs by date just in case
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 2. Create Spots
    final spots = logs.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      return FlSpot(index, entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 50,
        maxY: 200, // Adjust dynamically if needed
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: Colors.blueGrey, // Deprecated in v0.66+, check version
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final log = logs[spot.x.toInt()];
                return LineTooltipItem(
                  '${log.value.toInt()} mg/dL\n',
                  const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${DateFormat('MMM d, HH:mm').format(log.timestamp)}\n',
                      style: const TextStyle(
                        color: Colors.white70,
                         fontSize: 10,
                      )
                    ),
                    TextSpan(
                      text: log.tag,
                      style: const TextStyle(
                        color: Colors.yellowAccent, 
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30, // Space for labels
              getTitlesWidget: (value, meta) {
                // Show simplified date (Mon, Tue...) for specific indices
                // To avoid overcrowding, show only start/mid/end or map index to weekday
                // Because we map INDEX -> LOG, we just grab the log's date
                final index = value.toInt();
                if (index < 0 || index >= logs.length) return const SizedBox.shrink();
                
                final date = logs[index].timestamp;
                String text;

                if (filter == TimeFilter.semana) {
                  text = DateFormat('E').format(date); // Mon, Tue
                } else if (filter == TimeFilter.mes) {
                  // Show sparsely to avoid overlap
                  if (index % 5 == 0 || index == logs.length - 1) {
                     text = DateFormat('dd/MM').format(date);
                  } else {
                    return const SizedBox.shrink();
                  }
                } else {
                   // Year: Show Month
                   if (index % 30 == 0 || index == logs.length - 1) { // Approximate month intervals if daily data
                     text = DateFormat('MMM').format(date);
                   } else {
                     return const SizedBox.shrink();
                   }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text, 
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                 return Text(
                   value.toInt().toString(),
                   style: const TextStyle(color: Colors.grey, fontSize: 10),
                 );
              }
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50, 
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200],
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final log = logs[index];
                return FlDotCirclePainter(
                  radius: 4, // Smaller dots
                  color: log.statusColor, // Traffic light logic
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
