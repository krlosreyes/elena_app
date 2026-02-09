import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../fasting/presentation/fasting_controller.dart';
import '../../../fasting/presentation/fasting_helper.dart';
import 'fasting_timeline.dart';
import 'fasting_motivation_card.dart';
import 'fast_completion_dialog.dart';

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
              onPressed: () => _showStartDialog(context, ref),
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
                    // 1. Seleccionar Fecha (Permitir corrección de días pasados)
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startTime,
                      firstDate: DateTime.now().subtract(const Duration(days: 7)),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Theme.of(context).primaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    
                    if (date == null) return;

                    // 2. Seleccionar Hora
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                    );

                    if (time != null) {
                      final newStart = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                      
                      if (newStart.isAfter(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La fecha de inicio no puede ser en el futuro')),
                        );
                        return;
                      }

                      ref.read(fastingControllerProvider.notifier).updateStartTime(newStart);
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
              onPressed: () => _handleStopFast(context, ref, state),
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

  void _handleStopFast(BuildContext context, WidgetRef ref, FastingState state) {
    final elapsed = state.elapsed;
    final planned = Duration(hours: state.plannedHours);
    final isEarlyExit = elapsed < planned;

    if (isEarlyExit) {
      _showEarlyExitDialog(context, ref, elapsed, planned);
    } else {
      _finishFast(context, ref, elapsed);
    }
  }

  void _finishFast(BuildContext context, WidgetRef ref, Duration duration) {
    final startTime = ref.read(fastingControllerProvider).value?.startTime;
    if (startTime == null) return;

    showDialog(
      context: context,
      builder: (context) => FastCompletionDialog(
        startTime: startTime,
        onConfirm: (endTime) async {
           // Calcular duración real basada en el endTime editado
           final realDuration = endTime.difference(startTime);
           
           await ref.read(fastingControllerProvider.notifier).saveManualFast(startTime, endTime);
           
           if (context.mounted) {
             _showSuccessDialog(context, realDuration);
           }
        },
      ),
    );
  }

  void _showEarlyExitDialog(BuildContext context, WidgetRef ref, Duration elapsed, Duration plan) {
    final benefit = FastingHelper.getBenefit(elapsed);
    final hours = elapsed.inHours;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Terminar ya?'),
        content: Text(
          'Llevas ${hours}h. Hasta ahora has logrado:\n\n$benefit\n\n¿Seguro que quieres detenerte?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar Ayunando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _finishFast(context, ref, elapsed);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Terminar'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Duration duration) {
    final benefit = FastingHelper.getBenefit(duration);
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final h = twoDigits(d.inHours);
      final m = twoDigits(d.inMinutes.remainder(60));
      return '$h:$m';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '¡Ayuno Finalizado!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tiempo total: ${formatDuration(duration)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Logro desbloqueado:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              benefit,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('¡Excelente!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _StartFastDialog(ref: ref),
    );
  }
}

class _StartFastDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _StartFastDialog({super.key, required this.ref});

  @override
  ConsumerState<_StartFastDialog> createState() => _StartFastDialogState();
}

class _StartFastDialogState extends ConsumerState<_StartFastDialog> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 3)),
      lastDate: now,
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _confirmStart() {
    final now = DateTime.now();
    // 5 min buffer para considerar que es "pasado" y no solo un delay de UX
    final isRetroactive = _selectedDate.isBefore(now.subtract(const Duration(minutes: 5))); 

    if (isRetroactive) {
      final diff = now.difference(_selectedDate);
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      final timeAgo = "${h > 0 ? '$h h ' : ''}${m}m";

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('¿Ya estabas ayunando?'),
          content: Text(
            'Has seleccionado una hora pasada ($timeAgo atrás).\n\n¿Quieres registrar que tu ayuno comenzó a esa hora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, corregir'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar alerta
                _start();
              },
              child: const Text('Sí, empezar desde ahí'),
            ),
          ],
        ),
      );
    } else {
      if (_selectedDate.isAfter(now)) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La fecha de inicio no puede ser futura.'))
         );
         return;
      }
      _start();
    }
  }

  void _start() {
    final state = ref.read(fastingControllerProvider).value;
    final int hours = state?.plannedHours ?? 16;
    
    ref.read(fastingControllerProvider.notifier).startFast(
      startTime: _selectedDate,
      hours: hours,
    );
    Navigator.pop(context); // Cerrar dialogo principal
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
    final dateStr = isToday ? 'Hoy' : DateFormat('d MMM', 'es').format(_selectedDate);
    final timeStr = DateFormat('HH:mm').format(_selectedDate);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Comenzar Ayuno', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¿Cuándo empezaste a ayunar?',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _pickDateTime(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_filled, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmStart,
          style: ElevatedButton.styleFrom(
             backgroundColor: Theme.of(context).primaryColor,
             foregroundColor: Colors.white,
             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('COMENZAR', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
