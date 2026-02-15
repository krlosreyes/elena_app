
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_theme.dart';
import '../../application/training_stats_provider.dart';
import '../../domain/entities/workout_log.dart';

class TrainingStatsScreen extends ConsumerStatefulWidget {
  static const String routeName = 'training_stats';

  const TrainingStatsScreen({super.key});

  @override
  ConsumerState<TrainingStatsScreen> createState() => _TrainingStatsScreenState();
}

class _TrainingStatsScreenState extends ConsumerState<TrainingStatsScreen> {
  // To track selected bar index for details
  int? touchedIndex; 

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(trainingStatsFilterProvider);
    final statsAsync = ref.watch(trainingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Estadísticas"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Range Selector
            Center(
              child: SegmentedButton<StatsRange>(
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
            ),
            const SizedBox(height: 32),

            // Chart
            SizedBox(
              height: 300,
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

            const SizedBox(height: 32),

            // Details Section for Selected Day (or most recent if distinct)
            if (touchedIndex != null && statsAsync.hasValue)
               _buildDetails(statsAsync.value!, touchedIndex!),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<WorkoutLog> logs, StatsRange range) {
    // Aggregate logs by day
    // Map dates to daily volume/duration/count
    final grouped = <int, double>{}; // Index -> Value
    // We need to map dates to x-axis indices based on range
    
    // Simplification for Week: 7 bars (Day 0 to 6)
    // We need complete range filling even with 0s
    
    // Prepare spots
    List<BarChartGroupData> barGroups = [];
    final now = DateTime.now();
    
    int daysCount = 7;
    if (range == StatsRange.month) daysCount = 30;
    if (range == StatsRange.year) daysCount = 12; // Months

    for (int i = 0; i < daysCount; i++) {
       // Logic to map i to date
       DateTime date;
       double value = 0;
       
       if (range == StatsRange.year) {
          // Monthly bars
          // Go back i months from now (reverse order?)
          // Usually charts go Left -> Right (Past -> Future)
          // i=0 is oldest?
          // Let's make index 0 = (now - daysCount)
           final monthDate = DateTime(now.year, now.month - (daysCount - 1 - i));
           // Sum logs in this month
           final monthlyLogs = logs.where((l) => l.date.year == monthDate.year && l.date.month == monthDate.month);
           value = monthlyLogs.fold(0, (sum, l) => sum + (l.durationMinutes ?? 0));
       } else {
          // Daily bars
          date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysCount - 1 - i));
          // Find logs for this date
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
               width: range == StatsRange.month ? 8 : 16,
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
                // Show label logic based on range and index
                if (index < 0 || index >= daysCount) return const SizedBox.shrink();
                
                // Show less labels for Month
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
    // Reconstruct date/month from index to find logs
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
      return Center(
        child: Text("Sin actividad en $dateLabel", style: GoogleFonts.outfit(color: Colors.grey)),
      );
    }

    // Aggregate stats for the selection
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

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                 _MiniStat("Minutos", "$totalDuration", Icons.timer),
                 _MiniStat("Kcal", "$totalCals", Icons.local_fire_department),
                 _MiniStat("Volumen", "${(totalVolume/1000).toStringAsFixed(1)}k", Icons.fitness_center),
              ],
            ),
            if (selectedLogs.isNotEmpty)
            Padding(
               padding: const EdgeInsets.only(top: 16),
               child: SizedBox(
                 width: double.infinity,
                 child: OutlinedButton(
                   onPressed: () {
                     // Navigate to detail of the first log found? Or list them?
                     // For simplicity, verify user story: "mostrar detalles de ese día" -> done above.
                     // But maybe navigate to summary view of specific workout?
                     if (selectedLogs.length == 1) {
                        context.pushNamed('workout_summary', extra: selectedLogs.first);
                     }
                   },
                   child: const Text("Ver Detalle Completo"),
                 ),
               )
            )
          ],
        ),
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
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
