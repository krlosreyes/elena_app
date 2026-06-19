// SPEC-159: SleepQualityCard — calidad subjetiva semanal en Análisis.
//
// Una fila por noche: día abreviado + barra discreta + duración +
// estrellas + flags de latencia/despertares. Insight adaptativo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/last_week_sleep_logs_provider.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_weekly_insight.dart';

/// Color base del pilar Sueño en la app — coherente con
/// `WeeklyCoachingCard` y `PillarsHeatmap` legacy (purple-indigo).
const Color _kSleepAccent = Color(0xFF818CF8);

class SleepQualityCard extends ConsumerWidget {
  const SleepQualityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInsight = ref.watch(lastWeekSleepLogsProvider);
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
        data: _buildContent,
      ),
    );
  }

  // ─── Estados ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _kSleepAccent,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: Text(
        'No pudimos cargar tu sueño.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(SleepWeeklyInsight i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(i),
        const SizedBox(height: 14),
        if (i.isEmpty)
          _buildEmptyState()
        else ...[
          _buildHeadline(i),
          const SizedBox(height: 16),
          for (final log in i.logs) _buildNightRow(log),
          const SizedBox(height: 12),
          _buildInsightBlock(i),
        ],
      ],
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(SleepWeeklyInsight i) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TU SUEÑO',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (!i.isEmpty)
          Text(
            '${i.logs.length} NOCHES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }

  // ─── Headline ───────────────────────────────────────────────────────

  Widget _buildHeadline(SleepWeeklyInsight i) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${i.durationAvgHours.toStringAsFixed(1)}h',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            height: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            i.qualityAvg != null
                ? 'promedio · ★ ${i.qualityAvg!.toStringAsFixed(1)}'
                : 'promedio',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Fila de noche ──────────────────────────────────────────────────

  Widget _buildNightRow(SleepLog log) {
    final hours = log.wokeUp.difference(log.fellAsleep).inMinutes / 60.0;
    final dayLabel = _dayShort(log.wokeUp.weekday);
    final accent = _accentForHours(hours);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Día.
          SizedBox(
            width: 32,
            child: Text(
              dayLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Barra discreta de duración.
          SizedBox(
            width: 86,
            child: _buildDurationBar(hours, accent),
          ),
          const SizedBox(width: 10),
          // Horas.
          SizedBox(
            width: 36,
            child: Text(
              '${hours.toStringAsFixed(1)}h',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Estrellas.
          _buildStars(log.subjectiveQuality),
          const SizedBox(width: 8),
          // Flags.
          if (log.sleepLatencyMinutes != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFlag(
                  icon: Icons.access_time_rounded,
                  text: '${log.sleepLatencyMinutes}'),
            ),
          if (log.nightAwakenings != null && log.nightAwakenings! >= 1)
            _buildFlag(
              icon: Icons.refresh_rounded,
              text: '${log.nightAwakenings}',
            ),
        ],
      ),
    );
  }

  Widget _buildDurationBar(double hours, Color accent) {
    const buckets = 10;
    // 10 buckets = 8h target.
    final filled = (hours / 8.0 * buckets).round().clamp(0, buckets);
    return Row(
      children: List.generate(buckets, (i) {
        final isFilled = i < filled;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 6,
            decoration: BoxDecoration(
              color: isFilled ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStars(int? quality) {
    final q = quality ?? 0;
    return Row(
      children: List.generate(5, (i) {
        final isOn = i < q;
        return Icon(
          isOn ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: isOn
              ? const Color(0xFFFBBF24) // amarillo
              : Colors.white.withValues(alpha: 0.20),
        );
      }),
    );
  }

  Widget _buildFlag({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.50),
          size: 11,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.60),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ─── Insight ────────────────────────────────────────────────────────

  Widget _buildInsightBlock(SleepWeeklyInsight i) {
    final m = SleepCoachingMessage.forTier(i.tier);
    if (m == null) return const SizedBox.shrink();
    final accent = _colorForTier(i.tier);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.headline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m.action,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m.citation,
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
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🌙', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tu reparación comienza aquí.',
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
            'Registra tu próximo despertar para empezar a ver tu '
            'patrón de sueño y calidad subjetiva.',
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

  // ─── Helpers ────────────────────────────────────────────────────────

  static const _daysShort = [
    'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom',
  ];

  String _dayShort(int weekday) {
    // weekday: 1=Monday..7=Sunday
    return _daysShort[(weekday - 1).clamp(0, 6)];
  }

  Color _accentForHours(double hours) {
    if (hours >= 7) return AppColors.metabolicGreen;
    if (hours >= 6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _colorForTier(SleepInsightTier t) {
    switch (t) {
      case SleepInsightTier.sustained:
        return AppColors.metabolicGreen;
      case SleepInsightTier.neutral:
        return _kSleepAccent;
      case SleepInsightTier.lowQuality:
      case SleepInsightTier.fragmented:
      case SleepInsightTier.latencyHigh:
        return const Color(0xFFF59E0B);
      case SleepInsightTier.deprivation:
        return const Color(0xFFEF4444);
      case SleepInsightTier.empty:
        return Colors.grey;
    }
  }
}
