
import 'package:elena_app/src/features/profile/data/user_repository.dart';
import 'package:elena_app/src/features/profile/domain/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'widgets/fasting_chart_card.dart';

// ... (existing imports)

                    // SECCIÓN 2: Check-in Semanal
                    _CheckInWeekStrip(
                      checkInDay: user.checkInDay ?? 1, // Default Lunes
                      latestLogDate: latest?.date,
                      onCheckInTap: () => _showAddMeasurementModal(context, user),
                    ),
                    const SizedBox(height: 24),
                    
                    // SECCIÓN 2.5: Historial de Ayunos
                    Text(
                      'Consistencia de Ayuno',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const FastingChartCard(),
                    const SizedBox(height: 24),

                    // SECCIÓN 3: Gráfico
                    Text(
                      'Tendencia Peso (Últimas 12 semanas)',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            // Necesitamos el usuario para el formulario... 
            // Podríamos pasarlo de userAsync si estuviéramos dentro, 
            // pero aquí userAsync.valueOrNull podría servir
             final user = userAsync.valueOrNull;
             if (user != null) _showAddMeasurementModal(context, user);
        },
        label: const Text('Registrar'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: _AddMeasurementForm(user: user),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECCIÓN 1: BioMetrics Grid
// -----------------------------------------------------------------------------
class _BioMetricsGrid extends StatelessWidget {
  final MeasurementLog? latest;
  final MeasurementLog? previous;
  final double userHeightCm;

  const _BioMetricsGrid({this.latest, this.previous, required this.userHeightCm});

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
            color: Colors.grey.withOpacity(0.1),
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
class _CheckInWeekStrip extends StatelessWidget {
  final int checkInDay; // 1 = Monday
  final DateTime? latestLogDate;
  final VoidCallback onCheckInTap;

  const _CheckInWeekStrip({
    required this.checkInDay,
    this.latestLogDate,
    required this.onCheckInTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Start of current week (Monday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    // Check if check-in done this week
    bool isCheckInDone = false;
    if (latestLogDate != null) {
       // Si el último log es de esta semana (>= lunes)
       // Simplificación: solo miramos si es después del inicio de la semana
       final startOfWeek = DateTime(monday.year, monday.month, monday.day);
       if (latestLogDate!.isAfter(startOfWeek)) {
         isCheckInDone = true;
       }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Semana Actual',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNum = index + 1; // 1-7 (Mon-Sun)
              final isCheckInDay = dayNum == checkInDay;
              final isToday = dayNum == now.weekday;
              
              // Estado visual
              Color bgColor = Colors.transparent;
              Color textColor = Colors.grey;
              Widget? icon;

              if (isCheckInDay) {
                if (isCheckInDone) {
                  bgColor = Colors.green.withOpacity(0.1);
                  icon = const Icon(Icons.check_circle, size: 20, color: Colors.green);
                } else if (isToday) {
                  // Hoy toca check-in y no está hecho -> Pulsar/Resaltar
                  bgColor = Theme.of(context).primaryColor;
                  textColor = Colors.white;
                  icon = const Icon(Icons.add, size: 20, color: Colors.white);
                } else if (dayNum < now.weekday) {
                  // Pasó el día y no se hizo
                  bgColor = Colors.red.withOpacity(0.1);
                  icon = const Icon(Icons.close, size: 20, color: Colors.red);
                } else {
                  // Futuro
                  bgColor = Colors.white;
                  textColor = Colors.black;
                }
              }

              return InkWell(
                 onTap: (isCheckInDay && isToday && !isCheckInDone) ? onCheckInTap : null,
                 child: Container(
                  width: 36,
                  height: 50,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday ? Border.all(color: Theme.of(context).primaryColor) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayLetter(dayNum),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (icon != null) icon else const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _dayLetter(int day) {
    const letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return letters[day - 1];
  }
}

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
                  Theme.of(context).primaryColor.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.0),
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
class _HistoryTable extends StatelessWidget {
  final List<MeasurementLog> history;

  const _HistoryTable({required this.history});

  @override
  Widget build(BuildContext context) {
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
              return Padding(
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

// -----------------------------------------------------------------------------
// Formulario de Registro Actualizado
// -----------------------------------------------------------------------------
class _AddMeasurementForm extends ConsumerStatefulWidget {
  final UserModel user;
  const _AddMeasurementForm({required this.user});

  @override
  ConsumerState<_AddMeasurementForm> createState() => _AddMeasurementFormState();
}

class _AddMeasurementFormState extends ConsumerState<_AddMeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _weightController;
  late TextEditingController _waistController;
  late TextEditingController _neckController;
  late TextEditingController _hipController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill con valores actuales
    _weightController = TextEditingController(text: widget.user.currentWeightKg.toString());
    _waistController = TextEditingController(text: widget.user.waistCircumferenceCm.toString());
    _neckController = TextEditingController(text: widget.user.neckCircumferenceCm.toString());
    _hipController = TextEditingController(text: widget.user.hipCircumferenceCm?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _neckController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final weight = double.parse(_weightController.text.replaceAll(',', '.'));
      final waist = double.tryParse(_waistController.text.replaceAll(',', '.'));
      final neck = double.tryParse(_neckController.text.replaceAll(',', '.'));
      final hip = double.tryParse(_hipController.text.replaceAll(',', '.'));

      // Auto-calcular Grasa (Navy Method)
      double? calculatedBodyFat;
      double? calculatedLeanMass;
      
      if (waist != null && neck != null) {
        calculatedBodyFat = MeasurementLog.calculateBodyFat(
          heightCm: widget.user.heightCm,
          waistCm: waist,
          neckCm: neck,
          hipCm: hip,
          isMale: widget.user.gender == Gender.male,
        );
        
        if (calculatedBodyFat != null) {
          calculatedLeanMass = 100.0 - calculatedBodyFat;
        }
      }

      // Crear objeto log temporal (sin ID aún)
      final tempLog = MeasurementLog(
        id: '',
        date: DateTime.now(),
        weight: weight,
        waistCircumference: waist,
        neckCircumference: neck,
        hipCircumference: hip,
        bodyFatPercentage: calculatedBodyFat,
        muscleMassPercentage: calculatedLeanMass,
      );
      
      // Guardar en Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('measurements')
          .add(tempLog.toJson());

      // Recrear log con ID correcto para el servicio
      final logWithId = MeasurementLog(
        id: docRef.id,
        date: tempLog.date,
        weight: tempLog.weight,
        waistCircumference: tempLog.waistCircumference,
        neckCircumference: tempLog.neckCircumference,
        hipCircumference: tempLog.hipCircumference,
        bodyFatPercentage: tempLog.bodyFatPercentage,
        muscleMassPercentage: tempLog.muscleMassPercentage,
        energyLevel: tempLog.energyLevel,
      );

      // Generar Plan Automático
      // Usamos read porque estamos dentro de una función, no build
      await ref.read(coachingProvider).generatePlanFromMeasurement(logWithId, widget.user);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro guardado y Plan actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actualizar Medidas',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grasa y Masa Magra se calcularán automáticamente.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _waistController,
                    decoration: const InputDecoration(labelText: 'Cintura (cm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                     validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _neckController,
                    decoration: const InputDecoration(labelText: 'Cuello (cm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                     validator: (v) => v!.isEmpty ? 'Requerido' : null, // Vital para grasa
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _hipController,
                    decoration: const InputDecoration(labelText: 'Cadera (cm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar y Calcular', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
