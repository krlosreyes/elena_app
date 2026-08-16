// SPEC-304 — Vista de las etapas del sueño (cuando el dispositivo las mide):
// barra proporcional, duración por etapa, y un veredicto de cómo afectó tu
// metabolismo, con ciencia citada (ver sleep_stage_science.dart).
//
// Widget puro de presentación: recibe `SleepStages` ya calculado (la card del
// pilar lo obtiene del SleepLog del ciclo actual). Se autooculta si no hay
// etapas medidas.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/sleep/domain/sleep_stage_science.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_stages.dart';

class SleepStagesView extends StatefulWidget {
  const SleepStagesView({super.key, required this.stages});
  final SleepStages stages;

  @override
  State<SleepStagesView> createState() => _SleepStagesViewState();
}

class _SleepStagesViewState extends State<SleepStagesView> {
  bool _expanded = false;

  static String _dur(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stages;
    if (!s.hasData) return const SizedBox.shrink();

    final total = s.totalMinutes;
    final segments = <({SleepStageKind kind, int minutes})>[
      (kind: SleepStageKind.deep, minutes: s.deepMinutes),
      (kind: SleepStageKind.rem, minutes: s.remMinutes),
      (kind: SleepStageKind.light, minutes: s.lightMinutes),
      (kind: SleepStageKind.awake, minutes: s.awakeMinutes),
    ].where((e) => e.minutes > 0).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ETAPAS DE TU SUEÑO',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          // Barra proporcional apilada.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                for (final seg in segments)
                  Expanded(
                    flex: total > 0 ? seg.minutes : 1,
                    child: Container(
                      height: 12,
                      color: SleepStageScience.of(seg.kind).color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final seg in segments) _row(seg.kind, seg.minutes),
          const SizedBox(height: 6),
          _verdict(s),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    _expanded ? 'Ocultar detalle' : 'Qué significa cada etapa',
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF818CF8),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (final seg in segments) _science(seg.kind),
        ],
      ),
    );
  }

  Widget _row(SleepStageKind kind, int minutes) {
    final sci = SleepStageScience.of(kind);
    final total = widget.stages.totalMinutes;
    final pct = total > 0 ? (minutes / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: sci.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(sci.label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Text(_dur(minutes),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text('$pct%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Veredicto metabólico corto derivado de los datos, con cita.
  Widget _verdict(SleepStages s) {
    // Sueño profundo saludable ≈ 13-23% del sueño real (Tasali et al., PNAS 2008
    // muestra su rol restaurador metabólico).
    final deepOk = s.deepFraction >= 0.13;
    final fragmented = s.awakeMinutes >= 40 ||
        (s.totalMinutes > 0 && s.awakeMinutes / s.totalMinutes >= 0.15);

    final String text;
    final Color color;
    final String citation;
    if (!deepOk) {
      text = 'Tuviste poco sueño profundo, la fase que más restaura tu '
          'sensibilidad a la insulina. Cuida el horario y el ambiente.';
      color = const Color(0xFFFB923C);
      citation = SleepStageScience.deep.citation;
    } else if (fragmented) {
      text = 'Buen sueño profundo, pero varios despertares: la fragmentación '
          'sube el cortisol matutino y baja la sensibilidad a la insulina.';
      color = const Color(0xFFFB923C);
      citation = SleepStageScience.awake.citation;
    } else {
      text = 'Buen sueño profundo y poca fragmentación: apoyaste tu hormona de '
          'crecimiento y tu sensibilidad a la insulina.';
      color = const Color(0xFF34D399);
      citation = SleepStageScience.deep.citation;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.insights_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(citation,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _science(SleepStageKind kind) {
    final sci = SleepStageScience.of(kind);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: sci.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sci.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sci.metabolicImpact,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.4)),
                const SizedBox(height: 3),
                Text(sci.citation,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
