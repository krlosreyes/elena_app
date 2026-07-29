// SPEC-153: WeeklyCoachingCard — reemplaza el PillarsHeatmap por un
// bloque de coaching que dice qué importa y qué hacer.
//
// Estructura:
//   header "TU SEMANA" + rango de fechas
//   5 filas (label + barra discreta 7 niveles + % + delta con icono/color)
//   separador
//   insight (lightbulb + headline + acción + cita) cuando hay débil
//   o mensaje sostenido cuando todos ≥80%
//   o empty state si no hay docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/weekly_coaching_provider.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';
import 'package:elena_app/src/core/constants/pillar_constants.dart';

/// Umbral para considerar un delta "significativo" en la UI. Coincide
/// con el patrón del CycleClosureCard (SPEC-149) — ±5% es ruido,
/// arriba es señal.
const double _kSignificantDelta = 0.05;

class WeeklyCoachingCard extends ConsumerWidget {
  const WeeklyCoachingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInsight = ref.watch(weeklyCoachingProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: asyncInsight.when(
        loading: _buildLoading,
        error: (_, __) => _buildError(),
        data: (insight) => _buildContent(insight),
      ),
    );
  }

  // ─── Estados ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.metabolicGreen,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(
        'No pudimos cargar tu semana.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(WeeklyCoachingInsight i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(i),
        const SizedBox(height: 16),
        if (i.isEmpty)
          _buildEmptyState()
        else ...[
          // 29-jul: las cinco filas usaban etiquetas propias, dos de
          // ellas truncadas ("Hidrat.", "Ejerc.") porque la columna de
          // 64 px no daba para "Hidratación". Se ensancha la columna y
          // se consumen las etiquetas canónicas — el usuario ve el
          // mismo nombre acá que en los anillos del Dashboard.
          _buildPillarRow(PillarConstants.trackingLabelAyuno, i.fastingAvg,
              i.fastingDelta, const Color(0xFF22D3A8)),
          _buildPillarRow(PillarConstants.trackingLabelSueno, i.sleepAvg,
              i.sleepDelta, const Color(0xFF818CF8)),
          _buildPillarRow(PillarConstants.trackingLabelHidratacion,
              i.hydrationAvg, i.hydrationDelta, const Color(0xFF38BDF8)),
          _buildPillarRow(PillarConstants.trackingLabelEjercicio, i.exerciseAvg,
              i.exerciseDelta, const Color(0xFF14B8A6)),
          _buildPillarRow(PillarConstants.trackingLabelNutricion, i.mealsAvg,
              i.mealsDelta, const Color(0xFFFB923C)),
          const SizedBox(height: 14),
          _buildDivider(),
          const SizedBox(height: 14),
          if (i.weakest != null)
            _buildInsightBlock(i.weakest!)
          else if (i.isFullySustained)
            _buildSustainedBlock()
          else
            _buildNeutralBlock(),
        ],
      ],
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(WeeklyCoachingInsight i) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TU SEMANA',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          _formatRange(i.rangeStart, i.rangeEnd),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  static const _monthsShort = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];

  String _formatRange(DateTime start, DateTime end) {
    final sm = _monthsShort[start.month - 1];
    final em = _monthsShort[end.month - 1];
    // 29-jul: al primer día de uso, inicio y fin son el mismo día y el
    // header mostraba "JUL 29–29" — un rango de un día a sí mismo.
    // Justo lo que ve un usuario recién registrado, que es cuando peor
    // cae que la app se vea descuidada.
    if (start.month == end.month && start.day == end.day) {
      return '$sm ${start.day}';
    }
    if (start.month == end.month) {
      return '$sm ${start.day}–${end.day}';
    }
    return '$sm ${start.day} – $em ${end.day}';
  }

  // ─── Fila de pilar ──────────────────────────────────────────────────

  Widget _buildPillarRow(
    String label,
    double avg,
    double? delta,
    Color accent,
  ) {
    final pct = (avg.clamp(0.0, 1.0) * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            // 80 y no 64: "Hidratación" completa no entra en 64 px a
            // 12 px w700, que es lo que forzó las abreviaturas.
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildDiscreteBar(avg, accent)),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 48, child: _buildDeltaIndicator(delta)),
        ],
      ),
    );
  }

  /// Barra de 7 niveles discretos — cada "tick" representa ~14.3%.
  /// Lectura inmediata, sin gradiente continuo.
  Widget _buildDiscreteBar(double value, Color accent) {
    const buckets = 7;
    final filled = (value.clamp(0.0, 1.0) * buckets).round();
    return Row(
      children: List.generate(buckets, (i) {
        final isFilled = i < filled;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 10,
            decoration: BoxDecoration(
              color: isFilled ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  /// Indicador de delta con icono + color + texto corto.
  /// null → texto "—" en gris (no había semana anterior).
  Widget _buildDeltaIndicator(double? delta) {
    if (delta == null) {
      return Text(
        '—',
        textAlign: TextAlign.left,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final pctPoints = (delta * 100).round();
    if (delta.abs() < _kSignificantDelta) {
      return Text(
        '=',
        textAlign: TextAlign.left,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    final isDown = delta < 0;
    final color = isDown ? const Color(0xFFEF4444) : AppColors.metabolicGreen;
    final icon =
        isDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 2),
        Text(
          '${pctPoints.abs()}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ─── Separador + bloques de coaching ────────────────────────────────

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  Widget _buildInsightBlock(WeakPillar weak) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.metabolicGreen,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  weak.insightHeadline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '→ ${weak.suggestedAction}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weak.citation,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
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

  Widget _buildSustainedBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: AppColors.metabolicGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estás sostenido en los 5 pilares esta semana. Mantén el ritmo.',
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

  /// Fallback neutro cuando no hay weakest pero tampoco está full sustained.
  /// En la práctica el algoritmo siempre devuelve weakest si hay caída
  /// o si no todos ≥80%, así que este bloque es defensivo.
  Widget _buildNeutralBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Registra unos días más para que podamos darte feedback más afinado.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        'Aún no tienes registros en los últimos 7 días.\nRegistra tus pilares y verás tu semana aquí.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }
}
