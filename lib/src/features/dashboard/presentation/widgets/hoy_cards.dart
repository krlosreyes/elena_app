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

/// Un punto de "Tu semana".
class WeekDot {
  const WeekDot({
    required this.label,
    required this.closedByYou,
    required this.isToday,
  });

  final String label;
  final bool closedByYou;
  final bool isToday;
}

const _letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Últimos días cerrados (hasta 6, del más viejo al más nuevo) + hoy.
List<WeekDot> buildWeekDots(List<MetabolicCycle> recentClosed) {
  final sorted = [...recentClosed]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final last6 =
      sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;
  return [
    for (final c in last6)
      WeekDot(
        label: _letras[c.startedAt.weekday - 1],
        closedByYou: c.closureReason == ClosureReason.manualNextFasting,
        isToday: false,
      ),
    const WeekDot(label: 'Hoy', closedByYou: false, isToday: true),
  ];
}

class WeekClosedCard extends ConsumerWidget {
  const WeekClosedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(last7ClosedCyclesProvider).valueOrNull;
    if (recent == null || recent.isEmpty) return const SizedBox.shrink();
    final dots = buildWeekDots(recent);
    final closedDays = dots.where((d) => !d.isToday).toList();
    final byYou = closedDays.where((d) => d.closedByYou).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1422),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Tu semana',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Cerraste tú $byYou de ${closedDays.length} '
                '${closedDays.length == 1 ? 'día' : 'días'}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final d in dots)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.closedByYou
                              ? AppColors.metabolicGreen
                              : Colors.transparent,
                          border: d.closedByYou
                              ? null
                              : Border.all(
                                  width: 2,
                                  color: d.isToday
                                      ? const Color(0xFF97C459)
                                      : Colors.white.withValues(alpha: 0.14),
                                ),
                        ),
                        child: d.closedByYou
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Color(0xFF032A22))
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.label,
                        style: TextStyle(
                          color: d.isToday
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight:
                              d.isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
