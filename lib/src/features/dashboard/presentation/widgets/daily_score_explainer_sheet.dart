// SPEC-140 §RF-140-05: BottomSheet educativo del Score del Día.
//
// SPEC-170 (2026-06-04): reescrito en tono humano-cercano (memoria
// `notification-tone-human-not-clinical`) y extendido para cubrir
// AMBOS números del header (HOY + IMR), no solo el Score del Día.
// El bottom sheet se abre desde el DualScoreRing y desde el ⓘ del
// card "TU DÍA".

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

void showDailyScoreExplainerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DailyScoreExplainerSheet(),
  );
}

class _DailyScoreExplainerSheet extends StatelessWidget {
  const _DailyScoreExplainerSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tus dos números',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'En el header del Dashboard ves dos números. Los dos son '
              'tuyos, pero te cuentan cosas distintas.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            // ── HOY ──────────────────────────────────────────────────
            _ScoreSection(
              accent: AppColors.metabolicGreen,
              title: 'HOY',
              subtitle: 'Cómo viviste hoy',
              body: 'Refleja tus 5 pilares en este día. Puede llegar a '
                  '100 cuando los cumples todos — está pensado para '
                  'celebrarte cuando te lo ganaste.',
            ),
            const SizedBox(height: 8),
            const Text(
              'PESOS DEL HOY',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const _WeightRow(label: 'Sueño', value: 25),
            const _WeightRow(label: 'Ayuno', value: 22),
            const _WeightRow(label: 'Ejercicio', value: 20),
            const _WeightRow(label: 'Nutrición', value: 18),
            const _WeightRow(label: 'Hidratación', value: 15),
            const SizedBox(height: 22),
            // ── IMR ──────────────────────────────────────────────────
            _ScoreSection(
              accent: const Color(0xFF22D3EE),
              title: 'IMR',
              subtitle: 'Tu base metabólica',
              body: 'Se mueve más lento, en semanas y meses. Esto es lo '
                  'que importa cuando hablamos de cambios reales en tu '
                  'cuerpo. No está pensado para llegar a 100 — está '
                  'pensado para subir poco a poco.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.metabolicGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.metabolicGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'HOY te dice "hoy cumpliste". IMR te dice "estás '
                      'cambiando". Los dos te acompañan — uno te empuja '
                      'cada día, el otro te muestra el camino largo.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Los pesos del HOY se basan en literatura científica sobre el '
              'impacto metabólico de cada hábito. Fuentes: IMR_BIBLIOGRAPHY '
              '§6 (Score del Día) + §13 (Día Metabólico).',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SPEC-170 (2026-06-04): bloque "icono color + title + subtitle + body"
/// para describir cada uno de los dos scores. Reusado para HOY (verde
/// teal) e IMR (cyan).
class _ScoreSection extends StatelessWidget {
  const _ScoreSection({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 56,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
