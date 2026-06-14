// IMR FEEDBACK CARD — Análisis del desempeño por pilar.
//
// Clasifica los 5 pilares en tres categorías:
//   • Mejor pilar    (avg >= 0.70 Y el más alto)
//   • Mantener       (avg >= 0.55)
//   • Oportunidad    (avg < 0.55)
//
// Inputs: List<DailySummaryDoc> del período visible en la pantalla.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_pillar_bar_chart.dart'
    show ImrWeekData;

// ─── Modelo de análisis ────────────────────────────────────────────────────

enum _PillarStatus { best, maintain, improve }

class _PillarResult {
  final String name;
  final String emoji;
  final Color color;
  final double avg;
  _PillarStatus status;

  _PillarResult({
    required this.name,
    required this.emoji,
    required this.color,
    required this.avg,
    required this.status,
  });
}

// ─── Widget ────────────────────────────────────────────────────────────────

class ImrPillarFeedbackCard extends StatelessWidget {
  final List<DailySummaryDoc> docs;

  const ImrPillarFeedbackCard({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const SizedBox.shrink();

    final results = _analyze(docs);
    if (results.isEmpty) return const SizedBox.shrink();

    final best = results.where((r) => r.status == _PillarStatus.best).toList();
    final maintain =
        results.where((r) => r.status == _PillarStatus.maintain).toList();
    final improve =
        results.where((r) => r.status == _PillarStatus.improve).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ANÁLISIS DE PILARES',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Sección: Mejor desempeño
          if (best.isNotEmpty) ...[
            _sectionHeader('⭐ Mejor desempeño', const Color(0xFFFFD700)),
            const SizedBox(height: 8),
            ...best.map((r) => _pillarRow(r, highlight: true)),
            const SizedBox(height: 14),
          ],

          // Sección: Mantener
          if (maintain.isNotEmpty) ...[
            _sectionHeader('✅ Vas bien — mantén el ritmo',
                const Color(0xFF10B981)),
            const SizedBox(height: 8),
            ...maintain.map((r) => _pillarRow(r)),
            const SizedBox(height: 14),
          ],

          // Sección: Oportunidad de mejora
          if (improve.isNotEmpty) ...[
            _sectionHeader(
                '🎯 Oportunidad de mejora', const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            ...improve.map((r) => _pillarRow(r)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _pillarRow(_PillarResult r, {bool highlight = false}) {
    final pct = (r.avg * 100).round();
    final barFill = r.avg.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Emoji + nombre
          Text(r.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              r.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: highlight ? 1.0 : 0.75),
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          // Barra progreso
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barFill,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(r.color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Porcentaje
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: highlight
                    ? r.color
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Análisis ──────────────────────────────────────────────────────────

  static double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static List<_PillarResult> _analyze(List<DailySummaryDoc> docs) {
    final results = [
      _PillarResult(
        name: 'Ayuno',
        emoji: '⏱',
        color: const Color(0xFF10B981),
        avg: _avg(docs.map((d) => d.fastingProgress).toList()),
        status: _PillarStatus.improve,
      ),
      _PillarResult(
        name: 'Nutrición',
        emoji: '🥗',
        color: const Color(0xFFF59E0B),
        avg: _avg(docs.map((d) => d.mealsProgress).toList()),
        status: _PillarStatus.improve,
      ),
      _PillarResult(
        name: 'Hidratación',
        emoji: '💧',
        color: const Color(0xFF38BDF8),
        avg: _avg(docs.map((d) => d.hydrationProgress).toList()),
        status: _PillarStatus.improve,
      ),
      _PillarResult(
        name: 'Ejercicio',
        emoji: '🏃',
        color: const Color(0xFFEF4444),
        avg: _avg(docs.map((d) => d.exerciseProgress).toList()),
        status: _PillarStatus.improve,
      ),
      _PillarResult(
        name: 'Sueño',
        emoji: '🌙',
        color: const Color(0xFF818CF8),
        avg: _avg(docs.map((d) => d.sleepProgress).toList()),
        status: _PillarStatus.improve,
      ),
    ];

    // Ordenar de mayor a menor avg
    results.sort((a, b) => b.avg.compareTo(a.avg));

    // Clasificar
    _PillarResult? bestCandidate;
    for (final r in results) {
      if (r.avg >= 0.55) {
        if (bestCandidate == null && r.avg >= 0.65) {
          r.status = _PillarStatus.best;
          bestCandidate = r;
        } else {
          r.status = _PillarStatus.maintain;
        }
      } else {
        r.status = _PillarStatus.improve;
      }
    }

    // Si ninguno alcanza 0.65 pero hay pilares ≥0.55, el mejor de esos es "best"
    if (bestCandidate == null) {
      final topMaintain =
          results.where((r) => r.status == _PillarStatus.maintain).toList();
      if (topMaintain.isNotEmpty) {
        topMaintain.first.status = _PillarStatus.best;
      }
    }

    return results;
  }
}
