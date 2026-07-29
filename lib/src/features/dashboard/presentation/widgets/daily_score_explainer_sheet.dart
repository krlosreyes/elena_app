// SPEC-140 §RF-140-05: BottomSheet educativo del Score del Día.
//
// SPEC-170 (2026-06-04): reescrito en tono humano-cercano (memoria
// `notification-tone-human-not-clinical`).
//
// Decisión de producto (22-jul): este sheet volvió a ser SOLO sobre HOY.
// Entre el 04-jun y el 22-jul cubría también el IMR longitudinal (para
// explicar el segundo ring del Dashboard) — al sacarse ese ring del
// Dashboard (el IMR ahora se comunica solo en Perfil y en la gráfica de
// Resultados de Progreso), mantener la sección de IMR acá habría sido
// contradictorio: el sheet se abre EXCLUSIVAMENTE desde el Dashboard
// (ver daily_score_hero.dart), así que hablarle de "el otro número que
// ves" a alguien que ya no lo ve en pantalla generaba confusión en vez
// de aclarar. La explicación de IMR completa vive en Análisis/Progreso.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/metabolic_day_explainer_sheet.dart';

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
              'Tu Progreso de Hoy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Es el número que se mueve cada día — un resumen en tiempo '
              'real de tus 5 pilares. No mide semanas ni meses: mide hoy.',
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
                      'Este número te empuja cada día. Tu progreso de fondo '
                      '— el que se acumula en semanas — lo ves en Perfil y '
                      'en Resultados, dentro de Progreso.',
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
            // 28-jul: esto decía "Fuentes: IMR_BIBLIOGRAPHY §6 (Score del
            // Día) + §13 (Día Metabólico)". Le estábamos mostrando al
            // usuario números de sección de un documento interno que no
            // puede abrir. La afirmación (que los pesos vienen de
            // literatura) es cierta y se queda; la referencia de archivo
            // sobra.
            Text(
              'Los pesos del HOY se basan en literatura científica sobre el '
              'impacto metabólico de cada hábito.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            // El score se calcula por día metabólico, no por día de
            // calendario. Sin esta entrada, el usuario que ve su score
            // "reiniciarse" a una hora rara no tiene dónde entenderlo.
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                showMetabolicDayExplainerSheet(context);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.autorenew_rounded,
                        size: 15,
                        color: AppColors.metabolicGreen.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¿Qué es tu Día Metabólico?',
                        style: TextStyle(
                          color:
                              AppColors.metabolicGreen.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: Colors.white.withValues(alpha: 0.35)),
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

/// SPEC-170 (2026-06-04): bloque "icono color + title + subtitle + body".
/// Hasta el 22-jul describía HOY e IMR (ver nota de archivo); ahora solo
/// se usa para HOY, pero se deja como widget reusable por si otro
/// explainer necesita el mismo patrón visual.
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
