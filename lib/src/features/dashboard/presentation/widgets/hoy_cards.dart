// Rediseño Hoy (2026-11-04): tarjetas que le dan contexto y consecuencia al
// día metabólico.
//
//   - [BodyNowCard]: "Tu cuerpo ahora" (en ayuno) / "Cómo comer ahora" (en
//     ventana). Una frase corta por etapa, en lenguaje llano.
//     ⚠ Textos de salud: revisarlos con un médico antes de la App Store.
//   - [WeekClosedCard]: "Tu semana" — los últimos días y cuáles cerraste tú.
//     Es la consecuencia visible de cerrar (o no) el día.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/metabolic_day_widgets.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

/// Texto de "Tu cuerpo ahora" para una etapa del ayuno.
String bodyNowText(FastingPhase phase, {required bool goalReached}) {
  if (goalReached) {
    return 'Cumpliste tu meta. Rompe el ayuno cuando quieras: empieza con '
        'proteína y verduras.';
  }
  return switch (phase) {
    FastingPhase.none || FastingPhase.postAbsorption =>
      'Estás terminando de digerir y tu insulina empieza a bajar. Agua, '
          'café o té sin azúcar no rompen el ayuno.',
    FastingPhase.transition =>
      'Tus reservas rápidas de azúcar se van agotando y tu cuerpo empieza a '
          'usar grasa. Si sientes hambre, es una ola: suele pasar en unos '
          '20 minutos.',
    FastingPhase.fatBurning =>
      'Tu insulina está baja y tu cuerpo usa más grasa como energía. '
          'Mantente hidratado.',
    FastingPhase.autophagy || FastingPhase.survival =>
      'Llevas un ayuno largo. Escucha a tu cuerpo: si sientes mareo, temblor '
          'o palpitaciones, termina el ayuno.',
  };
}

const String kEatNowText =
    'Empieza por proteína y verduras y deja los carbohidratos para el final. '
    'Una caminata corta después de comer ayuda con la glucosa.';

class BodyNowCard extends ConsumerWidget {
  const BodyNowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(metabolicDayViewProvider);
    if (!view.hasProtocol) return const SizedBox.shrink();
    final fasting = ref.watch(fastingProvider);

    final String title;
    final String body;
    final Color color;
    final IconData icon;
    if (view.phase == MetabolicDayPhase.ayuno) {
      final goal = fasting.duration.inMinutes >= fasting.targetHours * 60;
      title = 'Tu cuerpo ahora';
      body = bodyNowText(fasting.phase, goalReached: goal);
      color = const Color(0xFF97C459);
      icon = Icons.bolt_rounded;
    } else if (view.phase == MetabolicDayPhase.ventana) {
      title = 'Cómo comer ahora';
      body = kEatNowText;
      color = AppColors.metabolicGreen;
      icon = Icons.restaurant_menu_rounded;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1422),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de un día en "Tu semana".
enum WeekDayState {
  /// El usuario cerró ese día metabólico (inició un nuevo ayuno).
  closedByYou,

  /// El día se cerró solo (respaldo del sistema).
  closedAuto,

  /// No hubo día metabólico ese día.
  none,
}

/// Un día del calendario en "Tu semana".
class WeekDot {
  const WeekDot({
    required this.date,
    required this.state,
    required this.isToday,
  });

  /// Fecha local (medianoche).
  final DateTime date;
  final WeekDayState state;
  final bool isToday;

  bool get closedByYou => state == WeekDayState.closedByYou;

  /// "L", "M", … o "Hoy".
  String get label => isToday ? 'Hoy' : _letras[date.weekday - 1];

  /// Día del mes ("6").
  String get dayNumber => '${date.day}';
}

const _letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Fecha del calendario a la que pertenece un día metabólico cerrado: la
/// del punto medio entre inicio y cierre. Un día que va de las 20:00 del
/// lunes a las 20:00 del martes se vive casi todo el martes, así que cuenta
/// como martes (si se usara el inicio, aparecería un hueco falso).
DateTime cycleCalendarDate(MetabolicCycle c) {
  final start = c.startedAt.toLocal();
  final end = (c.closedAt ?? c.startedAt).toLocal();
  return _dateOnly(start.add(end.difference(start) ~/ 2));
}

/// Los 7 días del calendario que terminan hoy, del más viejo al más nuevo.
/// Si dos días metabólicos caen en la misma fecha, basta con que uno lo
/// hayas cerrado tú.
List<WeekDot> buildWeekDots(List<MetabolicCycle> recentClosed, DateTime now) {
  final today = _dateOnly(now);
  final byDate = <DateTime, WeekDayState>{};
  for (final c in recentClosed) {
    final d = cycleCalendarDate(c);
    final st = c.closureReason == ClosureReason.manualNextFasting
        ? WeekDayState.closedByYou
        : WeekDayState.closedAuto;
    if (byDate[d] != WeekDayState.closedByYou) byDate[d] = st;
  }
  return [
    for (var i = 6; i >= 0; i--)
      () {
        final d = DateTime(today.year, today.month, today.day - i);
        return WeekDot(
          date: d,
          state: byDate[d] ?? WeekDayState.none,
          isToday: i == 0,
        );
      }(),
  ];
}

/// "31 oct – 6 nov" / "1 – 7 nov".
String weekRangeLabel(List<WeekDot> dots) {
  final a = dots.first.date;
  final b = dots.last.date;
  if (a.month == b.month) return '${a.day} – ${b.day} ${_meses[b.month - 1]}';
  return '${a.day} ${_meses[a.month - 1]} – ${b.day} ${_meses[b.month - 1]}';
}

/// (cerrados por ti, días contados). Cuenta los días pasados desde el
/// primero con registro: un usuario nuevo no ve "1 de 6" por días en los
/// que todavía no usaba la app.
(int, int) weekClosedCount(List<WeekDot> dots) {
  final past = dots.where((d) => !d.isToday).toList();
  final first = past.indexWhere((d) => d.state != WeekDayState.none);
  if (first < 0) return (0, 0);
  final counted = past.sublist(first);
  return (counted.where((d) => d.closedByYou).length, counted.length);
}

class WeekClosedCard extends ConsumerWidget {
  const WeekClosedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(last7ClosedCyclesProvider).valueOrNull;
    if (recent == null || recent.isEmpty) return const SizedBox.shrink();
    final dots = buildWeekDots(recent, DateTime.now());
    final (byYou, total) = weekClosedCount(dots);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1422),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu semana',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weekRangeLabel(dots),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0)
                Text(
                  'Cerraste tú $byYou de $total '
                  '${total == 1 ? 'día' : 'días'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final d in dots) Expanded(child: _WeekDayCell(dot: d)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({required this.dot});

  final WeekDot dot;

  @override
  Widget build(BuildContext context) {
    final d = dot;
    final Color fill;
    final Border? border;
    Widget? icon;
    switch (d.state) {
      case WeekDayState.closedByYou:
        fill = AppColors.metabolicGreen;
        border = null;
        icon = const Icon(Icons.check_rounded,
            size: 16, color: Color(0xFF032A22));
      case WeekDayState.closedAuto:
        fill = Colors.white.withValues(alpha: 0.10);
        border = null;
        icon = Icon(Icons.remove_rounded,
            size: 14, color: Colors.white.withValues(alpha: 0.45));
      case WeekDayState.none:
        fill = Colors.transparent;
        border = Border.all(
          width: d.isToday ? 2 : 1.5,
          color: d.isToday
              ? const Color(0xFF97C459)
              : Colors.white.withValues(alpha: 0.14),
        );
    }
    final labelColor =
        d.isToday ? Colors.white : Colors.white.withValues(alpha: 0.4);

    return Semantics(
      label: '${d.isToday ? 'Hoy' : _letras[d.date.weekday - 1]} '
          '${d.date.day}: ${switch (d.state) {
        WeekDayState.closedByYou => 'lo cerraste tú',
        WeekDayState.closedAuto => 'se cerró solo',
        WeekDayState.none => d.isToday ? 'en curso' : 'sin registro',
      }}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            d.label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: border,
            ),
            child: icon,
          ),
          const SizedBox(height: 4),
          Text(
            d.dayNumber,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
