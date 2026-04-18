// SPEC-13: IMR Explicado al Usuario — Bottom Sheet de Desglose Completo
// Se abre al tocar la IMRScoreCard en el dashboard.
// Muestra: score hero, resumen llano, 3 bloques con barras, acción recomendada.
// NUNCA expone fórmulas matemáticas ni terminología técnica sin explicación.

import 'package:flutter/material.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/features/analysis/domain/imr_explanation.dart';
import 'package:elena_app/src/features/analysis/application/imr_explanation_service.dart';

// ─── Entry point — función de conveniencia para abrir el sheet ────────────────

void showIMRDetailSheet(
  BuildContext context, {
  required IMRv2Result result,
  double fastingHours = 0,
  double sleepHours = 0,
  double exerciseMin = 0,
}) {
  final explanation = IMRExplanationService.explain(
    result,
    fastingHours: fastingHours,
    sleepHours: sleepHours,
    exerciseMin: exerciseMin,
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => IMRDetailSheet(
      result: result,
      explanation: explanation,
    ),
  );
}

// ─── Widget principal del sheet ───────────────────────────────────────────────

class IMRDetailSheet extends StatelessWidget {
  const IMRDetailSheet({
    super.key,
    required this.result,
    required this.explanation,
  });

  final IMRv2Result result;
  final IMRExplanation explanation;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero del score ────────────────────────────────────────
                    _ScoreHero(result: result, explanation: explanation),
                    const SizedBox(height: 24),

                    // ── Resumen en lenguaje llano ─────────────────────────────
                    _PlainSummary(text: explanation.plainSummary),
                    const SizedBox(height: 24),

                    // ── Título de sección ─────────────────────────────────────
                    _SectionLabel('LOS 3 BLOQUES DE TU IMR'),
                    const SizedBox(height: 12),

                    // ── Bloques ───────────────────────────────────────────────
                    ...explanation.blocks.map(
                      (block) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BlockCard(block: block),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Acción recomendada ────────────────────────────────────
                    _ActionCard(
                      weakestBlock: explanation.weakestBlock,
                      recommendation: explanation.actionableRecommendation,
                    ),

                    const SizedBox(height: 24),

                    // ── Nota de periodicidad ──────────────────────────────────
                    _UpdateNote(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero del score ───────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.result, required this.explanation});
  final IMRv2Result result;
  final IMRExplanation explanation;

  @override
  Widget build(BuildContext context) {
    final Color c = explanation.zoneColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.withOpacity(0.15),
            c.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'TU IMR HOY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.totalScore}',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: c,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Zona
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            decoration: BoxDecoration(
              color: c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.withOpacity(0.5)),
            ),
            child: Text(
              '${explanation.zoneEmoji}  ${result.zone}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: c,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Barra de progreso global
          _GlobalProgressBar(score: result.totalScore, color: c),
        ],
      ),
    );
  }
}

class _GlobalProgressBar extends StatelessWidget {
  const _GlobalProgressBar({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _zoneMarker('0', Colors.redAccent),
            _zoneMarker('40', Colors.orangeAccent),
            _zoneMarker('60', Colors.amberAccent),
            _zoneMarker('75', const Color(0xFF27AE60)),
            _zoneMarker('90', const Color(0xFF1ABC9C)),
            _zoneMarker('100', Colors.white54),
          ],
        ),
      ],
    );
  }

  Widget _zoneMarker(String label, Color c) => Text(
    label,
    style: TextStyle(fontSize: 8, color: c.withOpacity(0.6)),
  );
}

// ─── Resumen en lenguaje llano ────────────────────────────────────────────────

class _PlainSummary extends StatelessWidget {
  const _PlainSummary({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💬', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de bloque ────────────────────────────────────────────────────────

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.block});
  final IMRBlockDetail block;

  @override
  Widget build(BuildContext context) {
    final Color c = block.color;
    final bool isWeak = block.isWeakest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWeak
            ? c.withOpacity(0.08)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWeak ? c.withOpacity(0.5) : Colors.white.withOpacity(0.07),
          width: isWeak ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: ícono + nombre + peso + score
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(block.icon, color: c, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          block.functionalName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isWeak ? c : Colors.white,
                          ),
                        ),
                        if (isWeak) ...[
                          const SizedBox(width: 6),
                          _WeakBadge(color: c),
                        ],
                      ],
                    ),
                    Text(
                      'Peso en el IMR: ${block.weightPercent}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Score del bloque
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${block.pointsContributed}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: c,
                    ),
                  ),
                  Text(
                    'pts aportados',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progreso del bloque
          _BlockProgressBar(score: block.rawScore, color: c, weight: block.weightPercent),
          const SizedBox(height: 10),
          // Descripción
          Text(
            block.description,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withOpacity(0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockProgressBar extends StatelessWidget {
  const _BlockProgressBar({
    required this.score,
    required this.color,
    required this.weight,
  });
  final double score;
  final Color color;
  final int weight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        // Fill
        FractionallySizedBox(
          widthFactor: score.clamp(0.0, 1.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeakBadge extends StatelessWidget {
  const _WeakBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        'MAYOR OPORTUNIDAD',
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Tarjeta de acción recomendada ────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.weakestBlock,
    required this.recommendation,
  });
  final IMRBlockDetail weakestBlock;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    const Color accentGold = Color(0xFFF39C12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentGold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGold.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('💡', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCIÓN RECOMENDADA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: accentGold,
                      ),
                    ),
                    Text(
                      'Para ${weakestBlock.functionalName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 13.5,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nota de actualización ────────────────────────────────────────────────────

class _UpdateNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.refresh_rounded,
            size: 13, color: Colors.white.withOpacity(0.25)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Tu IMR se recalcula en tiempo real cada vez que registras '
            'actividad en cualquiera de tus pilares.',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withOpacity(0.3),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Etiqueta de sección ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }
}
