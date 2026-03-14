import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../fasting/presentation/fasting_controller.dart';
import '../../../fasting/presentation/fasting_helper.dart';
import 'fasting_timeline.dart';
import 'fasting_motivation_card.dart';
import 'fast_completion_dialog.dart';
import 'protocol_selector.dart';
import '../../../profile/application/user_controller.dart';
import '../../../onboarding/logic/elena_brain.dart';
import '../../../../core/utils/dark_picker_theme.dart';

class FastingCard extends ConsumerWidget {
  const FastingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFasting = ref.watch(fastingControllerProvider.select((s) => s.value?.isFasting ?? false));

    if (isFasting) {
      return const _ActiveFastingView();
    }
    
    final isLoading = ref.watch(fastingControllerProvider.select((s) => s.isLoading));
    if (isLoading) {
      return _buildLoadingState(context);
    }

    final hasError = ref.watch(fastingControllerProvider.select((s) => s.hasError));
    if (hasError) {
      final error = ref.watch(fastingControllerProvider).error;
      return _buildErrorState(context, error.toString());
    }

    return _buildInactiveState(context, ref);
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(
            'Error de conexión: $error',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 40,
              color: Color(0xFF009688),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Próximo Ayuno: 16h', 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu cuerpo está listo para la reparación celular.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showStartDialog(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  const SizedBox(width: 8),
                  Text('INICIAR AYUNO',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFastingView extends ConsumerWidget {
  const _ActiveFastingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fastingControllerProvider).value!;
    final startTime = state.startTime!;
    final plannedDuration = Duration(hours: state.plannedHours);
    final endTime = startTime.add(plannedDuration);
    final dateFormat = DateFormat('HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 0. Protocol Row
          const _ProtocolRow(),
          const SizedBox(height: 20),
          
          // 1. Tarjeta de Motivación
          _MotivationDisplay(elapsed: state.elapsed),
          const SizedBox(height: 24),

          // 2. Contador Principal (Atomizado)
          const _FastingTimerText(),
          const SizedBox(height: 32),

          // 3. Línea de Tiempo Metabólica
          const _MetabolicTimelineDisplay(),
          const SizedBox(height: 32),

          // 4. Controles de Tiempo
          _TimeControlRow(startTime: startTime, endTime: endTime),
          const SizedBox(height: 24),

          // 5. Botón Terminar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleStop(context, ref, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Text('TERMINAR AYUNO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStop(BuildContext context, WidgetRef ref, FastingState state) {
    // Re-use logic from FastingCard helper methods (already in same file as top-level functions)
    _handleStopFast(context, ref, state);
  }
}

class _FastingTimerText extends ConsumerWidget {
  const _FastingTimerText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ONLY this small widget rebuilds every second
    final fastingState = ref.watch(fastingControllerProvider).value;
    if (fastingState == null) return const SizedBox.shrink();

    final startTime = fastingState.startTime!;
    final plannedDuration = Duration(hours: fastingState.plannedHours);
    final endTime = startTime.add(plannedDuration);
    final now = DateTime.now();
    final remaining = endTime.difference(now);
    final isCompleted = remaining.isNegative;

    String timerText;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (isCompleted) {
      final extra = now.difference(endTime);
      timerText = '+ ${twoDigits(extra.inHours)}:${twoDigits(extra.inMinutes.remainder(60))}:${twoDigits(extra.inSeconds.remainder(60))}';
    } else {
      timerText = '${twoDigits(remaining.inHours)}:${twoDigits(remaining.inMinutes.remainder(60))}:${twoDigits(remaining.inSeconds.remainder(60))}';
    }

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            timerText,
            style: GoogleFonts.robotoMono(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.greenAccent : const Color(0xFF00FFB2),
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        Text(
          isCompleted ? 'TIEMPO EXTRA' : 'TIEMPO RESTANTE',
          style: const TextStyle(color: Color(0xFFAAAAAA), fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
      ],
    );
  }
}

class _MetabolicTimelineDisplay extends ConsumerWidget {
  const _MetabolicTimelineDisplay();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fastingControllerProvider).value;
    if (state == null) return const SizedBox.shrink();
    return FastingTimeline(
      progress: state.progress,
      elapsed: state.elapsed,
      plannedHours: state.plannedHours,
    );
  }
}

class _ProtocolRow extends ConsumerWidget {
  const _ProtocolRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final fastStateAsync = ref.watch(fastingControllerProvider);
    
    String protocol = '16/8';
    if (userAsync.hasValue && userAsync.value != null) {
      final healthPlan = ElenaBrain.generateHealthPlan(userAsync.value!);
      protocol = healthPlan.protocol.replaceAll(':', '/');
    }
    if (fastStateAsync.hasValue) {
      final fs = fastStateAsync.value!;
      protocol = '${fs.plannedHours}/${24 - fs.plannedHours}';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Tu plan para hoy:',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        ProtocolSelector(currentProtocol: protocol),
      ],
    );
  }
}

class _MotivationDisplay extends StatelessWidget {
  final Duration elapsed;
  const _MotivationDisplay({required this.elapsed});
  @override
  Widget build(BuildContext context) {
    return FastingMotivationCard(elapsed: elapsed);
  }
}

class _TimeControlRow extends ConsumerWidget {
  final DateTime startTime;
  final DateTime endTime;
  const _TimeControlRow({required this.startTime, required this.endTime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('HH:mm');
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              // Dialog logic extracted but kept consistent
              final date = await showDatePicker(
                context: context,
                initialDate: startTime,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
              );
              if (date == null) return;
              if (!context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(startTime),
                builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
              );
              if (time != null) {
                final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                if (newStart.isAfter(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La fecha de inicio no puede ser futura')));
                  return;
                }
                ref.read(fastingControllerProvider.notifier).updateStartTime(newStart);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 10, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('INICIO DEL AYUNO', style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(dateFormat.format(startTime), style: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                const FittedBox(fit: BoxFit.scaleDown, child: Text('FIN DEL AYUNO', style: TextStyle(color: Color(0xFF424242), fontSize: 9, fontWeight: FontWeight.bold))),
                const SizedBox(height: 2),
                Text(dateFormat.format(endTime), style: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey[800]!),
        ),
        title: const Text(
          '¿Terminar ya?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Llevas ${hours}h',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hasta ahora has logrado:',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              benefit,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Seguro que quieres detenerte?',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF009688)), // Teal
            child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _finishFast(context, ref, elapsed);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2), // Light red background
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Terminar', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _StartFastDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _StartFastDialog({required this.ref});

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
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      title: const Text('Comenzar Ayuno', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  Icon(Icons.access_time_filled, color: const Color(0xFF009688)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.edit, size: 16, color: Colors.grey[500]),
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
          style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmStart,
          style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFF009688),
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
