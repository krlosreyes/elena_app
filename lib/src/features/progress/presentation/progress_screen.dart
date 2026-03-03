
import 'package:elena_app/src/features/profile/application/user_controller.dart';
import 'package:elena_app/src/features/profile/domain/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../progress/application/progress_controller.dart';
import '../../progress/domain/measurement_log.dart';
import '../../authentication/application/auth_controller.dart';
import '../../glucose/presentation/widgets/glucose_chart_widget.dart';
import 'widgets/fasting_chart_card.dart';
import 'widgets/measurement_bottom_sheet.dart';
import 'package:elena_app/src/features/progress/presentation/widgets/weight_input_sheet.dart';
import 'widgets/week_calendar.dart';
import 'widgets/training_stats_section.dart';
import '../../dashboard/presentation/widgets/dashboard_header.dart';


class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userMeasurementsStreamProvider); // Usar el provider del servicio
    final authUser = ref.read(authControllerProvider.notifier).currentUser;
    // Necesitamos perfil del usuario para altura/género
    final userAsync = authUser != null 
        ? ref.watch(currentUserStreamProvider) 
        : const AsyncValue<UserModel?>.loading();

    // Convert string day name to int (Mon=1..Sun=7) if needed, 
    // or assume user.checkInDay is already int 1-7.
    // Assuming userModel has logic or is integer.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text("Perfil no cargado"));
            
            return historyAsync.when(
              data: (history) {
                final latest = history.isNotEmpty ? history.last : null;
                final previous = history.length > 1 ? history[history.length - 2] : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DashboardHeader(), // <-- CABECERA REUTILIZADA
                      const SizedBox(height: 20),

                      // SECCIÓN 2: Check-in Semanal
                      WeekCalendar(
                        checkInDay: user.checkInDay ?? 1, // Default Lunes
                        onCheckInTap: () => _showAddMeasurementModal(context, user),
                      ),
                      const SizedBox(height: 24),
                      
                      // SECCIÓN 2.5: Historial de Ayunos
                      const FastingChartCard(),
                      const SizedBox(height: 24),

                      // SECCIÓN 2.6: Control de Glucosa (CONDICIONAL)
                      if (user.shouldTrackGlucose) ...[
                        const GlucoseChartWidget(),
                        const SizedBox(height: 24),
                      ],
                      
                      // SECCIÓN 2.7: Estadísticas de Entrenamiento
                      const TrainingStatsSection(),
                      const SizedBox(height: 24),

                      // SECCIÓN 3: Gráfico
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tendencia Peso (12 sem)',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
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
                                 builder: (context) => const WeightInputSheet(),
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
                      if (history.isNotEmpty)
                        SizedBox(
                          height: 250,
                          child: _WeightChart(history: history),
                        )
                      else 
                         const Center(child: Text("Sin datos para graficar")),

                      const SizedBox(height: 32),

                      // SECCIÓN 4: Tabla Histórica
                      Text(
                        'Historial Detallado',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HistoryTable(history: history),
                       const SizedBox(height: 80), // Espacio para FAB si hubiera
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const Center(child: Text("Error cargando perfil")),
        ),
      ),
    );
  }

  void _showAddMeasurementModal(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MeasurementBottomSheet(user: user),
    );
  }
}

// ... other classes ...
class _BioMetricsGrid extends StatelessWidget {
  final MeasurementLog? latest;
  final MeasurementLog? previous;
  final double userHeightCm;

  const _BioMetricsGrid({
    required this.userHeightCm,
    this.latest,
    this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final weight = latest?.weight ?? 0.0;
    final bmi = latest?.calculateBmi(userHeightCm / 100) ?? 0.0;
    final bodyFat = latest?.bodyFatPercentage;
    final muscle = latest?.muscleMassPercentage;
    
    // Cálculo de cambios
    double? weightChange;
    if (latest != null && previous != null) {
      weightChange = latest!.weight - previous!.weight;
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _MetricCard(
          title: 'Peso',
          value: '${weight.toStringAsFixed(1)} kg',
          change: weightChange,
          icon: Icons.monitor_weight_outlined,
          color: Colors.blueAccent,
        ),
        _MetricCard(
          title: 'IMC',
          value: bmi.toStringAsFixed(1),
          subtitle: _getBmiLabel(bmi),
          icon: Icons.accessibility_new,
          color: _getBmiColor(bmi),
        ),
        _MetricCard(
          title: 'Estimado (Marina)',
          value: bodyFat != null ? '${bodyFat.toStringAsFixed(1)}%' : '--',
          icon: Icons.opacity,
          color: Colors.orangeAccent,
        ),
        _MetricCard(
          title: 'Masa Magra',
          value: muscle != null ? '${muscle.toStringAsFixed(1)}%' : '--',
          icon: Icons.fitness_center,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  String _getBmiLabel(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 24.9) return 'Normal';
    if (bmi < 29.9) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24.9) return Colors.green;
    if (bmi < 29.9) return Colors.orange;
    return Colors.red;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? change;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 4),
                Icon(
                  change! < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 12,
                  color: change! < 0 ? Colors.green : Colors.red,
                ),
                Text(
                  change!.abs().toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: change! < 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECCIÓN 2: Check-In Week Strip
// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// SECCIÓN 3: Gráfico (Limitado a 12 semanas)
// -----------------------------------------------------------------------------
class _WeightChart extends StatelessWidget {
  final List<MeasurementLog> history;

  const _WeightChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // Tomar solo últimas 12 semanas (últimos 12 registros aprox si es 1 por semana)
    // O mejor, filtrar por fecha. Simplificamos tomando últimos 12 items.
    final data = history.length > 12 ? history.sublist(history.length - 12) : history;

    if (data.isEmpty) return const SizedBox.shrink();

    final points = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final weights = data.map((e) => e.weight).toList();
    final minWeight = weights.reduce(min);
    final maxWeight = weights.reduce(max);
    final range = maxWeight - minWeight;
    final minY = minWeight - (range * 0.2); // Más margen

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                // Mostrar solo algunos
                if (data.length > 6 && index % 2 != 0) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('d/M').format(data[index].date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY < 0 ? 0 : minY,
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  Theme.of(context).primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
}

// -----------------------------------------------------------------------------
// SECCIÓN 4: Historial - Tabla Simple
// -----------------------------------------------------------------------------
class _HistoryTable extends ConsumerWidget {
  final List<MeasurementLog> history;

  const _HistoryTable({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Orden inverso para lista (más reciente arriba)
    final reversedList = history.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _headerText('Fecha')),
                Expanded(child: _headerText('Peso')),
                Expanded(child: _headerText('Cintura')),
                Expanded(child: _headerText('% Grasa')),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversedList.length > 10 ? 10 : reversedList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = reversedList[index];
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar registro'),
                      content: const Text('¿Estás seguro de que deseas eliminar este registro? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  final user = ref.read(authControllerProvider.notifier).currentUser;
                  if (user != null) {
                    ref.read(progressControllerProvider.notifier).deleteMeasurement(user.uid, item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registro eliminado')),
                    );
                  }
                },
                child: InkWell(
                  onTap: () {
                    // Abrir el modal en modo edición
                    final authUser = ref.read(authControllerProvider.notifier).currentUser;
                    if (authUser != null) {
                      final user = ref.read(currentUserStreamProvider).asData?.value;
                      if (user != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => MeasurementBottomSheet(
                            user: user,
                            existingLog: item,
                          ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                           child: Text(
                            DateFormat('dd MMM').format(item.date),
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item.weight}', 
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.waistCircumference != null ? '${item.waistCircumference}' : '-',
                             style: GoogleFonts.outfit(),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.bodyFatPercentage != null ? '${item.bodyFatPercentage?.toStringAsFixed(1)}%' : '-',
                            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
      ),
    );
  }
}


