// SPEC-300 — "Tu semana": boletín retrospectivo del tab Progreso.
//
// Fusiona la nota general de la semana (calificación) + la tendencia por pilar
// (barra + % + delta vs la semana pasada) + el foco accionable. Reusa el motor
// que ya existía (weeklyCoachingProvider / WeeklyCoachingInsight, SPEC-153):
// solo cambia la presentación — de heatmap plano a un reporte con jerarquía.
// Toca → detalle de Hábitos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/constants/pillar_constants.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/weekly_coaching_provider.dart';
import 'package:elena_app/src/features/analysis/application/weekly_window.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';

class WeeklyReportCard extends ConsumerWidget {
  const WeeklyReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyCoachingProvider);
    // Fix números (2026-10-30): cada pilar se muestra como "X de 7 días".
    // Mientras carga, se usa `empty` (0 días) en vez de bloquear la card.
    final days = ref.watch(weeklyPillarDaysProvider).valueOrNull ??
        WeeklyPillarDays.empty;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/analysis/habitos'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: async.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.metabolicGreen),
              ),
            ),
          ),
          error: (_, __) => _msg('No pudimos cargar tu semana.'),
          data: (i) => i.isEmpty ? _empty() : _content(i, days),
        ),
      ),
    );
  }

  Widget _content(WeeklyCoachingInsight i, WeeklyPillarDays days) {
    // Fix números (2026-10-30): se quitó la nota en letra (A/B/C…). Se
    // calculaba con una fórmula distinta al puntaje del día y podía decir
    // "A" con hidratación al 21% y ejercicio al 29%. El rango del encabezado
    // es ahora la ventana real de 7 días, no el de los ciclos encontrados.
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU SEMANA · ${_formatRange(weeklyWindowStart(now), weeklyWindowEnd(now))}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tu boletín',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _row(PillarConstants.trackingLabelAyuno, days.fasting,
            const Color(0xFF22D3A8)),
        _row(PillarConstants.trackingLabelSueno, days.sleep,
            const Color(0xFF818CF8)),
        _row(PillarConstants.trackingLabelHidratacion, days.hydration,
            const Color(0xFF38BDF8)),
        _row(PillarConstants.trackingLabelEjercicio, days.exercise,
            const Color(0xFF14B8A6)),
        _row(PillarConstants.trackingLabelNutricion, days.nutrition,
            const Color(0xFFFB923C)),
        const SizedBox(height: 6),
        if (i.weakest != null)
          _focus(i.weakest!)
        else if (i.isFullySustained)
          _sustained()
        else
          _neutral(),
      ],
    );
  }

  // ── Fila de pilar ──────────────────────────────────────────────────────
  Widget _row(String label, int daysMet, Color accent) {
    // Fix números (2026-10-30): antes mostraba "% + flecha con % de cambio"
    // ("100% ↑269%"), un porcentaje de un porcentaje que nadie entendía.
    // Ahora: barra de 7 segmentos (uno por día) y "X de 7 días".
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: 8),
          Expanded(child: _bar(daysMet / kWeeklyWindowDays, accent)),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: Text('$daysMet de $kWeeklyWindowDays días',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ),
        ],
      ),
    );
  }

  Widget _bar(double value, Color accent) {
    const buckets = 7;
    final filled = (value.clamp(0.0, 1.0) * buckets).round();
    return Row(
      children: List.generate(buckets, (i) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 10,
            decoration: BoxDecoration(
              color: i < filled ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ── Foco / sostenido / neutro ──────────────────────────────────────────
  Widget _focus(WeakPillar weak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.metabolicGreen.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flag_rounded,
                  color: AppColors.metabolicGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Tu foco: ${weak.insightHeadline}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('→ ${weak.suggestedAction}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Text(weak.citation,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sustained() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.metabolicGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded,
              color: AppColors.metabolicGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Semana sólida: sostienes los 5 pilares. Mantén el ritmo.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _neutral() =>
      _msg('Registra unos días más para darte un foco afinado de la semana.');

  Widget _msg(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            )),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TU SEMANA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes registros esta semana. Cierra tus pilares y aquí '
              'verás tu boletín.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );

  // ── Helpers ────────────────────────────────────────────────────────────
  static const _monthsShort = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', //
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
  ];

  String _formatRange(DateTime start, DateTime end) {
    final sm = _monthsShort[start.month - 1];
    final em = _monthsShort[end.month - 1];
    if (start.month == end.month && start.day == end.day) {
      return '$sm ${start.day}';
    }
    if (start.month == end.month) return '$sm ${start.day}–${end.day}';
    return '$sm ${start.day} – $em ${end.day}';
  }
}
