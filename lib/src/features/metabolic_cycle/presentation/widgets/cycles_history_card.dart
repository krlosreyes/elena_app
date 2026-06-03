// SPEC-156: histórico compacto de ciclos cerrados en la pantalla
// Análisis. Resuelve el gap crítico identificado en la auditoría —
// el coaching no acumula narrativa sin vista de progreso ciclo a ciclo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/cycles_history_computer.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/cycles_history_summary.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_detail_sheet.dart';

class CyclesHistoryCard extends ConsumerWidget {
  const CyclesHistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCycles = ref.watch(metabolicCyclesHistoryProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: asyncCycles.when(
        loading: () => _buildLoading(),
        error: (_, __) => _buildError(),
        data: (cycles) {
          final summary = CyclesHistoryComputer.compute(closedCycles: cycles);
          return _buildContent(context, summary);
        },
      ),
    );
  }

  // ─── Estados ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      height: 160,
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
      height: 80,
      alignment: Alignment.center,
      child: Text(
        'No pudimos cargar tus ciclos.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CyclesHistorySummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(summary),
        const SizedBox(height: 16),
        if (summary.isEmpty)
          _buildEmptyState()
        else ...[
          for (int i = 0; i < summary.visibleCycles.length; i++) ...[
            _buildCycleRow(
              context: context,
              cycle: summary.visibleCycles[i],
              isBest: summary.bestCycle?.cycleId ==
                  summary.visibleCycles[i].cycleId,
              isWorst: summary.worstCycle?.cycleId ==
                  summary.visibleCycles[i].cycleId,
            ),
            if (i < summary.visibleCycles.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
          ],
          if (summary.hasBest && summary.bestCycle!.feedback != null) ...[
            const SizedBox(height: 14),
            _buildBestCycleHighlight(summary.bestCycle!),
          ],
        ],
      ],
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(CyclesHistorySummary summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TUS CICLOS RECIENTES',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (!summary.isEmpty)
          Text(
            'últimos ${summary.visibleCycles.length}',
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

  // ─── Empty state ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⏳', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tu historia metabólica arranca acá.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cerrá tu primer Día Metabólico iniciando tu siguiente '
            'ayuno. Ahí vas a ver los scores, logros y enseñanzas '
            'de cada ciclo.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Fila de ciclo ──────────────────────────────────────────────────

  Widget _buildCycleRow({
    required BuildContext context,
    required MetabolicCycle cycle,
    required bool isBest,
    required bool isWorst,
  }) {
    final score = cycle.dailyScore ?? 0;
    final duration = cycle.totalDuration;
    final durationLabel = duration != null
        ? '${duration.inHours}h'
        : '—';
    final dateLabel = _formatDateShort(cycle.closedAt ?? cycle.startedAt);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => CycleDetailSheet.show(context, cycle),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Barra de score discreta (10 niveles).
            SizedBox(
              width: 86,
              child: _buildScoreBar(score, _accentForScore(score)),
            ),
            const SizedBox(width: 10),
            // Score numérico.
            SizedBox(
              width: 30,
              child: Text(
                '$score',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _accentForScore(score),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Fecha.
            SizedBox(
              width: 56,
              child: Text(
                dateLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Duración.
            Expanded(
              child: Text(
                durationLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Flags.
            if (isBest)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('✨', style: TextStyle(fontSize: 14)),
              ),
            if (isWorst)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('⚠️', style: TextStyle(fontSize: 14)),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.30),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(int score, Color accent) {
    const buckets = 10;
    final filled = (score.clamp(0, 100) / 100 * buckets).round();
    return Row(
      children: List.generate(buckets, (i) {
        final isFilled = i < filled;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 8,
            decoration: BoxDecoration(
              color: isFilled ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ─── Bloque "Tu mejor ciclo" ────────────────────────────────────────

  Widget _buildBestCycleHighlight(MetabolicCycle best) {
    final feedback = best.feedback!;
    final dateLabel = _formatDateShort(best.closedAt ?? best.startedAt);
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
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.metabolicGreen,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Tu mejor ciclo: $dateLabel · ${best.dailyScore}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback.insight,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (feedback.citation != null) ...[
            const SizedBox(height: 4),
            Text(
              feedback.citation!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _formatDateShort(DateTime dt) {
    return '${dt.day} ${_monthsShort[dt.month - 1]}';
  }

  Color _accentForScore(int score) {
    if (score >= 80) return AppColors.metabolicGreen;
    if (score >= 60) return const Color(0xFF60A5FA);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
