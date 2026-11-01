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
  });

  final DateTime startTime;
  final int targetHours;

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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                stageText,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Meta $target h',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          done ? 'Superaste tu meta por' : 'Te falta',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12.5,
          ),
        ),
        Text(
          done ? '+${_hms(-remaining)}' : _hms(remaining),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          done
              ? 'Puedes romper el ayuno cuando quieras.'
              : 'Terminas a las ${_hora12(end)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        _StageBar(
          stages: stages,
          target: target,
          elapsedHours: elapsedH,
          color: color,
        ),
        const SizedBox(height: 12),
        if (!done && nextText != null) ...[
          Text(
            nextText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          'Llevas ${elapsed.inHours} h ${elapsed.inMinutes.remainder(60)} min',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
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
