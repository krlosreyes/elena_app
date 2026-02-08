import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../fasting/presentation/fasting_controller.dart';
import 'fasting_timeline.dart';
import 'fasting_motivation_card.dart';

class FastingCard extends ConsumerWidget {
  const FastingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(fastingControllerProvider);

    return fastingState.when(
      data: (state) {
        if (state.isFasting) {
          return _buildActiveState(context, ref, state);
        } else {
          return _buildInactiveState(context, ref);
        }
      },
      loading: () => _buildLoadingState(context),
      error: (e, st) => Text('Error: $e'),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
     return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildInactiveState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Próximo Ayuno: 16h', // TODO: Leer del HealthPlan
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(fastingControllerProvider.notifier).startFast(hours: 16);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('INICIAR AYUNO AHORA',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveState(BuildContext context, WidgetRef ref, FastingState state) {
    // 1. Cálculos de Tiempo
    final startTime = state.startTime!;
    final plannedDuration = Duration(hours: state.plannedHours);
    final endTime = startTime.add(plannedDuration);
    final now = DateTime.now();
    
    // Countdown Logic: Tiempo Restante
    final remaining = endTime.difference(now);
    final isCompleted = remaining.isNegative;

    String timerText;
    if (isCompleted) {
      // Si ya terminó, mostramos cuánto tiempo extra lleva (+ HH:MM:SS)
      final extra = now.difference(endTime);
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(extra.inHours);
      final minutes = twoDigits(extra.inMinutes.remainder(60));
      final seconds = twoDigits(extra.inSeconds.remainder(60));
      timerText = '+ $hours:$minutes:$seconds';
    } else {
      // Si falta, mostramos cuenta regresiva (HH:MM:SS)
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(remaining.inHours);
      final minutes = twoDigits(remaining.inMinutes.remainder(60));
      final seconds = twoDigits(remaining.inSeconds.remainder(60));
      timerText = '$hours:$minutes:$seconds';
    }

    final dateFormat = DateFormat('HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // 1. Tarjeta de Motivación
          FastingMotivationCard(elapsed: state.elapsed),
          const SizedBox(height: 24),

          // 2. Contador Principal (Countdown)
          Text(
            timerText,
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          Text(
            isCompleted ? 'Tiempo Extra' : 'Tiempo Restante',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // 3. Línea de Tiempo Metabólica
          FastingTimeline(
            progress: state.progress,
            elapsed: state.elapsed,
            plannedHours: state.plannedHours,
          ),
          const SizedBox(height: 32),

          // 4. Controles de Tiempo (Inicio / Fin)
          Row(
            children: [
              // Botón Inicio (Editable)
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                    );
                    if (time != null) {
                      final now = DateTime.now();
                      final newStart = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        time.hour,
                        time.minute,
                      );
                      // Ajuste: Si la hora seleccionada es mayor a la actual, asumimos que fue ayer.
                      final adjustedStart = newStart.isAfter(now)
                          ? newStart.subtract(const Duration(days: 1))
                          : newStart;
                          
                      ref.read(fastingControllerProvider.notifier).updateStartTime(adjustedStart);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 12, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 4),
                            Text('INICIO DEL AYUNO', style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(startTime),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Botón Fin (Solo Lectura)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], // Fondo gris para denotar no editable
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Text('FIN DEL AYUNO', style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(endTime),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Botón Terminar (Destacado)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(fastingControllerProvider.notifier).stopFast();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'TERMINAR AYUNO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
