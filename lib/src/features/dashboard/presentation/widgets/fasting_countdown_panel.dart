// Rediseño ayuno (2026-11-01): cuenta regresiva HH:MM:SS + barra por etapas.
//
// - La barra se corta en las etapas fisiológicas que caben en la meta del
//   protocolo (umbrales de FastingPhase.startsAt: 0, 12, 18, 24 h). En 16:8
//   son dos tramos; en 18:6 o más aparece "Quema de grasa".
// - El color avanza de ámbar a verde según el % de la meta. Sin rojo: el
//   rojo al inicio castiga justo cuando el usuario está haciendo lo correcto.
// - Al cumplir la meta, el reloj cuenta hacia arriba (+HH:MM:SS).
// - Tiene su propio Timer de 1 s: solo se redibuja este panel, no la card.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/services/metabolic_day_reminders.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/metabolic_day_ring.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';

/// Ámbar → lima → verde según avance [p] (0..1).
Color fastingProgressColor(double p) {
  const amber = Color(0xFFEF9F27);
  const lime = Color(0xFF97C459);
  const green = Color(0xFF1D9E75);
  final t = p.clamp(0.0, 1.0);
  if (t <= 0.6) return Color.lerp(amber, lime, t / 0.6)!;
  return Color.lerp(lime, green, (t - 0.6) / 0.4)!;
}

/// Nombre corto y sin jerga de cada etapa, para la barra.
String fastingStageLabel(FastingPhase phase) => switch (phase) {
      FastingPhase.none || FastingPhase.postAbsorption => 'Bajando insulina',
      FastingPhase.transition => 'Transición',
      FastingPhase.fatBurning => 'Quema de grasa',
      FastingPhase.autophagy => 'Autofagia',
      FastingPhase.survival => 'Conservación',
    };

/// Etapas (inicio en horas) que caben antes de la meta [targetHours].
List<(FastingPhase, int)> stagesForTarget(int targetHours) {
  const phases = [
    FastingPhase.postAbsorption,
    FastingPhase.transition,
    FastingPhase.fatBurning,
    FastingPhase.autophagy,
  ];
  return [
    for (final p in phases)
      if (p.startsAt.inHours < targetHours) (p, p.startsAt.inHours),
  ];
}

class FastingCountdownPanel extends StatefulWidget {
  const FastingCountdownPanel({
    super.key,
    required this.startTime,
    required this.targetHours,
    this.protocolLabel,
  });

  final DateTime startTime;
  final int targetHours;

  /// "16:8", "OMAD"… para el encabezado del anillo.
  final String? protocolLabel;

  @override
  State<FastingCountdownPanel> createState() => _FastingCountdownPanelState();
}

class _FastingCountdownPanelState extends State<FastingCountdownPanel> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _hms(Duration d) =>
      '${_two(d.inHours)}:${_two(d.inMinutes.remainder(60))}:'
      '${_two(d.inSeconds.remainder(60))}';

  static String _hora12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final suf = t.hour < 12 ? 'a. m.' : 'p. m.';
    return '$h:${_two(t.minute)} $suf';
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.targetHours <= 0 ? 16 : widget.targetHours;
    var elapsed = _now.difference(widget.startTime);
    if (elapsed.isNegative) elapsed = Duration.zero;
    final targetDur = Duration(hours: target);
    final end = widget.startTime.add(targetDur);
    final remaining = targetDur - elapsed;
    final done = remaining <= Duration.zero;
    final elapsedH = elapsed.inSeconds / 3600;
    final p = (elapsedH / target).clamp(0.0, 1.0);
    final color = fastingProgressColor(p);

    final stages = stagesForTarget(target);
    var current = stages.first.$1;
    for (final s in stages) {
      if (elapsedH >= s.$2) current = s.$1;
    }
    final stageText = done ? 'Meta cumplida' : fastingStageLabel(current);

    // Próxima etapa dentro de la meta: "Siguiente: Transición en 2 h 10 min".
    String? nextText;
    for (final st in stages) {
      if (st.$2 > elapsedH) {
        final falta = Duration(seconds: ((st.$2 - elapsedH) * 3600).round());
        final fh = falta.inHours;
        final fm = falta.inMinutes.remainder(60);
        nextText = 'Siguiente: ${fastingStageLabel(st.$1)} en '
            '${fh > 0 ? '$fh h ' : ''}$fm min';
        break;
      }
    }

    final windowH =
        MetabolicDayReminders.windowFor(target).inMinutes / 60.0;
    final muted = Colors.white.withValues(alpha: 0.55);

    // Rediseño Hoy (2026-11-04): el anillo del día metabólico es el
    // protagonista. La barra de etapas queda debajo como "mapa".
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AYUNANDO${widget.protocolLabel != null ? ' · ${widget.protocolLabel}' : ''}',
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Empezó ${relativeStartLabel(widget.startTime, _now)}',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MetabolicDayRing(
          fastHours: target.toDouble(),
          windowHours: windowH,
          elapsedHours: elapsedH,
          fastColor: color,
          windowColor: const Color(0xFF00C49A),
          semanticLabel: done
              ? 'Meta de ayuno cumplida'
              : 'Ayuno: ${elapsed.inHours} h de $target h',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                done ? 'Superaste tu meta por' : 'Tu ventana abre en',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                done ? '+${_hms(-remaining)}' : _hms(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stageText,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                done
                    ? 'Rompe el ayuno cuando quieras'
                    : '${(p * 100).round()} % · terminas ${_hora12(end)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StageBar(
          stages: stages,
          target: target,
          elapsedHours: elapsedH,
          color: color,
        ),
        if (!done && nextText != null) ...[
          const SizedBox(height: 10),
          Text(
            nextText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// "hoy 7:10 a. m." · "ayer 8:10 p. m." · "2 nov, 7:10 p. m.".
String relativeStartLabel(DateTime t, DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final hora = '$h:${two(t.minute)} ${t.hour < 12 ? 'a. m.' : 'p. m.'}';
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(t.year, t.month, t.day))
      .inDays;
  if (days <= 0) return 'hoy $hora';
  if (days == 1) return 'ayer $hora';
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${t.day} ${meses[t.month - 1]}, $hora';
}

class _StageBar extends StatelessWidget {
  const _StageBar({
    required this.stages,
    required this.target,
    required this.elapsedHours,
    required this.color,
  });

  final List<(FastingPhase, int)> stages;
  final int target;
  final double elapsedHours;
  final Color color;

  static TextStyle _hourStyle(bool reached) => TextStyle(
        color: Colors.white.withValues(alpha: reached ? 0.75 : 0.4),
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      );

  @override
  Widget build(BuildContext context) {
    final segments = <(FastingPhase, int, int)>[
      for (var i = 0; i < stages.length; i++)
        (
          stages[i].$1,
          stages[i].$2,
          i + 1 < stages.length ? stages[i + 1].$2 : target,
        ),
    ];

    return Column(
      children: [
        LayoutBuilder(builder: (context, c) {
          final p = (elapsedHours / target).clamp(0.0, 1.0);
          return SizedBox(
            height: 20,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < segments.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        flex: segments[i].$3 - segments[i].$2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(i == 0 ? 6 : 0),
                            right: Radius.circular(
                                i == segments.length - 1 ? 6 : 0),
                          ),
                          child: SizedBox(
                            height: 12,
                            child: LinearProgressIndicator(
                              value: ((elapsedHours - segments[i].$2) /
                                      (segments[i].$3 - segments[i].$2))
                                  .clamp(0.0, 1.0),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Positioned(
                  left: (c.maxWidth * p - 10).clamp(0.0, c.maxWidth - 20),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        // Solo las horas de corte bajo la barra; los nombres de etapa
        // van en la etiqueta de arriba y en "Siguiente: …" para que nunca
        // se corten en tramos angostos.
        Row(
          children: [
            for (var i = 0; i < segments.length; i++)
              Expanded(
                flex: segments[i].$3 - segments[i].$2,
                child: Text(
                  '${segments[i].$2} h',
                  style: _hourStyle(elapsedHours >= segments[i].$2),
                ),
              ),
            Text('$target h', style: _hourStyle(elapsedHours >= target)),
          ],
        ),
      ],
    );
  }
}

/// Rediseño Hoy (2026-11-04): anillo en fase "ventana abierta".
///
/// [windowStart] = momento en que terminó el ayuno. El anillo muestra el
/// ayuno completo y cuánto de la ventana ya pasó; al centro, cuánto falta
/// para que cierre.
class EatingWindowPanel extends StatefulWidget {
  const EatingWindowPanel({
    super.key,
    required this.windowStart,
    required this.targetHours,
    this.mealsCount = 0,
    this.lastMealAt,
  });

  final DateTime windowStart;
  final int targetHours;
  final int mealsCount;
  final DateTime? lastMealAt;

  @override
  State<EatingWindowPanel> createState() => _EatingWindowPanelState();
}

class _EatingWindowPanelState extends State<EatingWindowPanel> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _hora12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${_two(t.minute)} ${t.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C49A);
    final target = widget.targetHours <= 0 ? 16 : widget.targetHours;
    final windowDur = MetabolicDayReminders.windowFor(target);
    final windowEnd = widget.windowStart.add(windowDur);
    var inWindow = _now.difference(widget.windowStart);
    if (inWindow.isNegative) inWindow = Duration.zero;
    var left = windowEnd.difference(_now);
    if (left.isNegative) left = Duration.zero;
    final muted = Colors.white.withValues(alpha: 0.55);

    String hms(Duration d) => '${_two(d.inHours)}:'
        '${_two(d.inMinutes.remainder(60))}:${_two(d.inSeconds.remainder(60))}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'VENTANA ABIERTA',
              style: TextStyle(
                color: teal,
                fontSize: 11.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Abrió ${relativeStartLabel(widget.windowStart, _now)}',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MetabolicDayRing(
          fastHours: target.toDouble(),
          windowHours: windowDur.inMinutes / 60.0,
          elapsedHours: target + inWindow.inSeconds / 3600,
          fastColor: const Color(0xFF1D9E75),
          windowColor: teal,
          semanticLabel:
              'Ventana de comida: faltan ${left.inHours} h ${left.inMinutes.remainder(60)} min',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tu ventana cierra en',
                  style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                hms(left),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Comiendo · ${inWindow.inHours} h ${inWindow.inMinutes.remainder(60)} m',
                style: const TextStyle(
                  color: teal,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Cierra cerca de las ${_hora12(windowEnd)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MealChip(
                title: widget.mealsCount == 0
                    ? 'Sin comidas aún'
                    : '${widget.mealsCount} '
                        '${widget.mealsCount == 1 ? 'comida' : 'comidas'}',
                subtitle: widget.lastMealAt == null
                    ? 'Registra la primera'
                    : 'Última ${_hora12(widget.lastMealAt!)}',
                filled: widget.mealsCount > 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MealChip(
                title: 'Ventana de ${windowDur.inHours} h',
                subtitle: 'Protocolo $target:${24 - target > 0 ? 24 - target : 1}',
                filled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MealChip extends StatelessWidget {
  const _MealChip({
    required this.title,
    required this.subtitle,
    required this.filled,
  });

  final String title;
  final String subtitle;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF1A2332) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: filled ? 0.0 : 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
