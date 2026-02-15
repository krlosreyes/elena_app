
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../training/application/training_stats_provider.dart';
import '../../../training/domain/entities/workout_log.dart';

class TrainingStatsSection extends ConsumerStatefulWidget {
  const TrainingStatsSection({super.key});

  @override
  ConsumerState<TrainingStatsSection> createState() => _TrainingStatsSectionState();
}

class _TrainingStatsSectionState extends ConsumerState<TrainingStatsSection> {
  // To track selected bar index for details
  int? touchedIndex; 

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(trainingStatsFilterProvider);
    final statsAsync = ref.watch(trainingStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entrenamiento',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Range Selector
                SegmentedButton<StatsRange>(
                  segments: const [
                    ButtonSegment(value: StatsRange.week, label: Text("Semana")),
                    ButtonSegment(value: StatsRange.month, label: Text("Mes")),
                    ButtonSegment(value: StatsRange.year, label: Text("Año")),
                  ],
                  selected: {range},
                  onSelectionChanged: (Set<StatsRange> newSelection) {
                    ref.read(trainingStatsFilterProvider.notifier).setRange(newSelection.first);
                    setState(() {
                      touchedIndex = null; // Reset selection
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                       if (states.contains(MaterialState.selected)) {
                         return AppTheme.primaryColor.withOpacity(0.1); 
                       }
                       return Colors.white;
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Chart
                SizedBox(
                  height: 200,
                  child: statsAsync.when(
                    data: (logs) {
                      if (logs.isEmpty) {
                        return const Center(child: Text("No hay datos en este periodo."));
                      }
                      return _buildChart(logs, range);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text("Error: $err")),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Details Section
                if (touchedIndex != null && statsAsync.hasValue)
                   _buildDetails(statsAsync.value!, touchedIndex!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<WorkoutLog> logs, StatsRange range) {
    // Determine days count
    int daysCount = 7;
    if (range == StatsRange.month) daysCount = 30;
    if (range == StatsRange.year) daysCount = 12;

    List<BarChartGroupData> barGroups = [];
    final now = DateTime.now();
    
    // Find max value for normalization or scaling if needed (optional)
    // fl_chart auto-scales but good to check.

    for (int i = 0; i < daysCount; i++) {
       double value = 0;
       
       if (range == StatsRange.year) {
           final monthDate = DateTime(now.year, now.month - (daysCount - 1 - i));
           final monthlyLogs = logs.where((l) => l.date.year == monthDate.year && l.date.month == monthDate.month);
           value = monthlyLogs.fold(0, (sum, l) => sum + (l.durationMinutes ?? 0));
       } else {
          final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysCount - 1 - i));
          final dayLogs = logs.where((l) => 
            l.date.year == date.year && 
            l.date.month == date.month && 
            l.date.day == date.day
          );
          value = dayLogs.fold(0, (sum, l) => sum + (l.durationMinutes ?? 0));
       }

       barGroups.add(
         BarChartGroupData(
           x: i,
           barRods: [
             BarChartRodData(
               toY: value,
               color: (touchedIndex == i) ? AppTheme.primaryColor : Colors.grey.shade300,
               width: range == StatsRange.month ? 6 : 12,
               borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
             )
           ],
         )
       );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                if (index < 0 || index >= daysCount) return const SizedBox.shrink();
                
                if (range == StatsRange.month && index % 5 != 0) return const SizedBox.shrink();

                if (range == StatsRange.year) {
                   final monthDate = DateTime(now.year, now.month - (daysCount - 1 - index));
                   return Text(DateFormat('MMM').format(monthDate), style: const TextStyle(fontSize: 10));
                } else {
                   final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysCount - 1 - index));
                   return Text(DateFormat('E').format(date).substring(0, 1), style: const TextStyle(fontSize: 10));
                }
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, barTouchResponse) {
             if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
               return;
             }
             if (event is FlTapUpEvent) {
                setState(() {
                  touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                });
             }
          },
        ),
      ),
    );
  }

  Widget _buildDetails(List<WorkoutLog> logs, int index) {
    final now = DateTime.now();
    final range = ref.watch(trainingStatsFilterProvider);
    
    int daysCount = 7;
    if (range == StatsRange.month) daysCount = 30;
    if (range == StatsRange.year) daysCount = 12;

    List<WorkoutLog> selectedLogs = [];
    String dateLabel = "";

    if (range == StatsRange.year) {
       final monthDate = DateTime(now.year, now.month - (daysCount - 1 - index));
       dateLabel = DateFormat('MMMM yyyy', 'es_ES').format(monthDate);
       selectedLogs = logs.where((l) => l.date.year == monthDate.year && l.date.month == monthDate.month).toList();
    } else {
       final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysCount - 1 - index));
       dateLabel = DateFormat('EEEE d, MMMM', 'es_ES').format(date);
       selectedLogs = logs.where((l) => 
          l.date.year == date.year && 
          l.date.month == date.month && 
          l.date.day == date.day
       ).toList();
    }

    if (selectedLogs.isEmpty) {
        return Text("Sin actividad: $dateLabel", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12));
    }

    final totalDuration = selectedLogs.fold(0, (sum, l) => sum + (l.durationMinutes ?? 0));
    final totalCals = selectedLogs.fold(0, (sum, l) => sum + (l.caloriesBurned ?? 0));
    final totalVolume = selectedLogs.fold(0.0, (sum, l) {
         double vol = 0;
         for(var ex in l.completedExercises) {
            for(var s in (ex['sets'] as List)) {
               if(s['isDone'] == true) vol += (s['weight'] as num? ?? 0) * (s['reps'] as num? ?? 0);
            }
         }
         return sum + vol;
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(dateLabel.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                 _MiniStat("Min", "$totalDuration", Icons.timer),
                 _MiniStat("Kcal", "$totalCals", Icons.local_fire_department),
                 _MiniStat("Vol", "${(totalVolume/1000).toStringAsFixed(1)}k", Icons.fitness_center),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
