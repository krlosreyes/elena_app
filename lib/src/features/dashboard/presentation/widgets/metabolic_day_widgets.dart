// Día metabólico visible en Hoy (2026-11-04).
//
// Feedback de Carlos tras 2 días con la build 74: "se perdió el concepto del
// día metabólico… se me olvidó pero a la app le da igual". Dos piezas:
//
//   - [MetabolicDayStrip]: siempre visible. Dice cuándo empezó tu día y en qué
//     fase vas (ayuno → ventana → cierre).
//   - [CloseDayPrompt]: aparece cuando la ventana estimada ya terminó y no
//     iniciaste el próximo ayuno. Pregunta a qué hora fue tu última comida e
//     inicia el ayuno con esa hora — así el día cierra cuando de verdad
//     cerró, aunque lo registres tarde (o a la mañana siguiente).
//
// La regla no cambia: el día lo abre y lo cierra solo el usuario al iniciar el
// ayuno. Esto solo hace visible el día y repara el olvido.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/metabolic_day_reminders.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/utils/fasting_protocol.dart';

/// Fases visibles del día metabólico.
enum MetabolicDayPhase { ayuno, ventana, cierre }

/// "Todavía estoy comiendo": oculta el aviso de cierre hasta esta hora.
final closeDayPromptSnoozeProvider = StateProvider<DateTime?>((ref) => null);

/// Estado derivado del día metabólico para la UI de Hoy.
class MetabolicDayView {
  const MetabolicDayView({
    required this.cycleStartedAt,
    required this.phase,
    required this.windowEnd,
    required this.windowStart,
    required this.hasProtocol,
  });

  final DateTime? cycleStartedAt;
  final MetabolicDayPhase phase;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final bool hasProtocol;
}

final metabolicDayViewProvider = Provider<MetabolicDayView>((ref) {
  final fasting = ref.watch(fastingProvider);
  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  // Se recalcula con el pulso del ayuno (el notifier emite cada tick).
  final now = DateTime.now();
  final target =
      fastingHoursForProtocol(user?.fastingProtocol ?? fasting.fastingProtocol) ??
          0;

  final windowEnd = MetabolicDayReminders.estimatedWindowEnd(
    isFasting: fasting.isActive,
    anchor: fasting.startTime,
    targetHours: target,
  );
  final DateTime? windowStart = fasting.startTime == null
      ? null
      : (fasting.isActive
          ? fasting.startTime!.add(Duration(hours: target))
          : fasting.startTime);

  final MetabolicDayPhase phase;
  if (fasting.isActive) {
    phase = MetabolicDayPhase.ayuno;
  } else if (windowEnd != null && now.isBefore(windowEnd)) {
    phase = MetabolicDayPhase.ventana;
  } else {
    phase = MetabolicDayPhase.cierre;
  }

  return MetabolicDayView(
    cycleStartedAt: cycle?.startedAt,
    phase: phase,
    windowStart: windowStart,
    windowEnd: windowEnd,
    hasProtocol: target > 0,
  );
});

String _hora12(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  final suf = t.hour < 12 ? 'a. m.' : 'p. m.';
  return '$h:$m $suf';
}

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "hoy 7:10 a. m." · "ayer 7:10 p. m." · "2 nov, 7:10 p. m.".
String relativeDayLabel(DateTime t, DateTime now) {
  final d0 = DateTime(now.year, now.month, now.day);
  final d1 = DateTime(t.year, t.month, t.day);
  final days = d0.difference(d1).inDays;
  if (days == 0) return 'hoy ${_hora12(t)}';
  if (days == 1) return 'ayer ${_hora12(t)}';
  return '${t.day} ${_meses[t.month - 1]}, ${_hora12(t)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Franja "Día metabólico"
// ─────────────────────────────────────────────────────────────────────────────

class MetabolicDayStrip extends ConsumerWidget {
  const MetabolicDayStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(metabolicDayViewProvider);
    if (!view.hasProtocol) return const SizedBox.shrink();
    final now = DateTime.now();
    final started = view.cycleStartedAt;
    final subtitle = started == null
        ? 'Empieza cuando inicies tu ayuno'
        : 'Empezó ${relativeDayLabel(started, now)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Día metabólico',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _phaseChip('Ayuno', MetabolicDayPhase.ayuno, view.phase),
              const SizedBox(width: 6),
              _phaseChip('Ventana', MetabolicDayPhase.ventana, view.phase),
              const SizedBox(width: 6),
              _phaseChip('Cierre', MetabolicDayPhase.cierre, view.phase),
            ],
          ),
        ],
      ),
    );
  }

  Widget _phaseChip(
    String label,
    MetabolicDayPhase me,
    MetabolicDayPhase current,
  ) {
    final isCurrent = me == current;
    final isPast = me.index < current.index;
    final Color color = isCurrent
        ? AppColors.metabolicGreen
        : (isPast
            ? AppColors.metabolicGreen.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.14));
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isCurrent
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              fontSize: 11.5,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aviso "¿Ya terminaste de comer?"
// ─────────────────────────────────────────────────────────────────────────────

class CloseDayPrompt extends ConsumerWidget {
  const CloseDayPrompt({super.key});

  /// Hora sugerida: la última comida registrada en el día (si es posterior a
  /// la apertura de la ventana); si no hay, el fin estimado de la ventana.
  static DateTime suggestedTime(
    MetabolicDayView view,
    DateTime? lastMeal,
    DateTime now,
  ) {
    DateTime t;
    if (lastMeal != null &&
        (view.windowStart == null || !lastMeal.isBefore(view.windowStart!))) {
      t = lastMeal;
    } else {
      t = view.windowEnd ?? now;
    }
    return t.isAfter(now) ? now : t;
  }

  /// True si el aviso debe mostrarse.
  static bool shouldShow(MetabolicDayView view, DateTime? snoozeUntil,
      bool isFasting, DateTime now) {
    if (!view.hasProtocol || isFasting) return false;
    if (view.windowEnd == null || now.isBefore(view.windowEnd!)) return false;
    if (snoozeUntil != null && now.isBefore(snoozeUntil)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(metabolicDayViewProvider);
    final fasting = ref.watch(fastingProvider);
    final snooze = ref.watch(closeDayPromptSnoozeProvider);
    final now = DateTime.now();
    if (!shouldShow(view, snooze, fasting.isActive, now)) {
      return const SizedBox.shrink();
    }

    final logs = ref.watch(nutritionProvider).todayLogs;
    DateTime? lastMeal;
    for (final l in logs) {
      if (lastMeal == null || l.timestamp.isAfter(lastMeal)) {
        lastMeal = l.timestamp;
      }
    }
    final suggested = suggestedTime(view, lastMeal, now);

    final since = now.difference(view.windowEnd!);
    final sameDay = view.windowEnd!.day == now.day &&
        view.windowEnd!.month == now.month;
    final String title = (sameDay || since.inHours < 6)
        ? (since.inMinutes < 60
            ? 'Tu ventana de comida terminó'
            : 'Tu ventana terminó hace ${since.inHours} h')
        : 'Tu día de ayer sigue abierto';

    const amber = Color(0xFFEF9F27);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: amber.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿A qué hora fue tu última comida? Con esa hora cerramos tu día '
            'e inicia tu ayuno.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: fasting.isSaving
                  ? null
                  : () => _close(context, ref, suggested, lastMeal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Fue a las ${_hora12(suggested)} · cerrar mi día',
                style: const TextStyle(
                  color: Color(0xFF0B1020),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: fasting.isSaving
                    ? null
                    : () => _pickOther(context, ref, suggested, lastMeal),
                child: const Text(
                  'Fue a otra hora',
                  style: TextStyle(
                    color: amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(closeDayPromptSnoozeProvider.notifier)
                    .state = DateTime.now().add(const Duration(hours: 1)),
                child: Text(
                  'Todavía estoy comiendo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickOther(
    BuildContext context,
    WidgetRef ref,
    DateTime suggested,
    DateTime? lastMeal,
  ) async {
    final now = DateTime.now();
    final view = ref.read(metabolicDayViewProvider);
    final first = view.cycleStartedAt ?? now.subtract(const Duration(days: 2));
    final theme = ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(primary: AppColors.metabolicGreen),
      dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E293B)),
    );

    DateTime day = DateTime(suggested.year, suggested.month, suggested.day);
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(first.year, first.month, first.day);
    if (firstDay.isBefore(today)) {
      final picked = await showDatePicker(
        context: context,
        initialDate: day.isBefore(firstDay) ? firstDay : day,
        firstDate: firstDay,
        lastDate: today,
        builder: (c, child) => Theme(data: theme, child: child!),
      );
      if (picked == null) return;
      day = picked;
    }
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(suggested),
      builder: (c, child) => Theme(data: theme, child: child!),
    );
    if (time == null || !context.mounted) return;
    await _close(
      context,
      ref,
      DateTime(day.year, day.month, day.day, time.hour, time.minute),
      lastMeal,
    );
  }

  Future<void> _close(
    BuildContext context,
    WidgetRef ref,
    DateTime at,
    DateTime? lastMeal,
  ) async {
    final now = DateTime.now();
    final cycleStart = ref.read(metabolicDayViewProvider).cycleStartedAt;
    String? error;
    if (at.isAfter(now)) {
      error = 'La hora no puede ser futura.';
    } else if (lastMeal != null &&
        at.isBefore(lastMeal.subtract(const Duration(minutes: 1)))) {
      error = 'Tienes una comida registrada a las ${_hora12(lastMeal)}. '
          'Elige esa hora o una posterior.';
    } else if (cycleStart != null &&
        at.difference(cycleStart) < const Duration(minutes: 30)) {
      error = 'Esa hora es anterior al inicio de tu día metabólico.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }
    ref.read(closeDayPromptSnoozeProvider.notifier).state = null;
    // Mismo camino que "Iniciar ayuno" (userInitiated): el evaluador cierra
    // el día en [at] y abre el siguiente en [at]. El resumen del día aparece
    // solo (cycleClosureMomentProvider → CycleDetailSheet).
    await ref.read(fastingProvider.notifier).startFastingManual(at);
  }
}
