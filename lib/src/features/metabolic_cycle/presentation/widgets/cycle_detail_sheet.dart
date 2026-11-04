// SPEC-156: BottomSheet con el detalle de un ciclo cerrado.
//
// Reutiliza el patrón visual de `CycleClosureCardView` (SPEC-149) para
// que el lenguaje del producto sea consistente: achievements verdes
// con check, gaps ámbar con triángulo, insight con bombilla + cita.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

class CycleDetailSheet extends StatelessWidget {
  const CycleDetailSheet({
    super.key,
    required this.cycle,
    this.closedByYou,
    this.closedOutOf,
    this.previousScore,
  });

  final MetabolicCycle cycle;

  /// Rediseño Hoy (2026-11-04): puntaje del día anterior para el
  /// "+X vs. ayer". Null = no se muestra.
  final int? previousScore;

  /// Día metabólico (2026-11-04): de los últimos [closedOutOf] días, cuántos
  /// cerró el usuario iniciando su ayuno. Null = no se muestra.
  final int? closedByYou;
  final int? closedOutOf;

  /// Helper para abrir el sheet con el patrón habitual del proyecto.
  static Future<void> show(
    BuildContext context,
    MetabolicCycle cycle, {
    int? closedByYou,
    int? closedOutOf,
    int? previousScore,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CycleDetailSheet(
        cycle: cycle,
        closedByYou: closedByYou,
        closedOutOf: closedOutOf,
        previousScore: previousScore,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 14),
              _buildHeader(),
              const SizedBox(height: 14),
              _buildScore(),
              if (closedByYou != null &&
                  closedOutOf != null &&
                  closedOutOf! > 0) ...[
                const SizedBox(height: 12),
                _buildClosedByYou(),
              ],
              if (cycle.feedback != null) ...[
                if (cycle.feedback!.achievements.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _buildSection(
                    title: 'LOGRASTE',
                    titleColor: AppColors.metabolicGreen,
                    items: cycle.feedback!.achievements,
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.metabolicGreen,
                  ),
                ],
                if (cycle.feedback!.gaps.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'TE FALTÓ',
                    titleColor: const Color(0xFFF59E0B),
                    items: cycle.feedback!.gaps,
                    icon: Icons.trending_down_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
                const SizedBox(height: 18),
                _buildInsight(),
              ],
              const SizedBox(height: 18),
              _buildMeta(),
            ],
          ),
        );
      },
    );
  }

  // ─── Componentes ────────────────────────────────────────────────────

  Widget _buildClosedByYou() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.metabolicGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cerraste tú $closedByYou de tus últimos $closedOutOf '
              '${closedOutOf == 1 ? 'día' : 'días'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Rediseño Hoy (2026-11-04): el cierre es la recompensa del gesto.
    final byYou = cycle.closureReason == ClosureReason.manualNextFasting;
    return Column(
      children: [
        const Text(
          'DÍA METABÓLICO CERRADO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.metabolicGreen,
            fontSize: 11.5,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          byYou ? 'Lo cerraste tú.' : 'Tu día se cerró solo.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatDateLong(cycle.closedAt ?? cycle.startedAt),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    final score = cycle.dailyScore ?? 0;
    final delta = previousScore == null ? null : score - previousScore!;
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.metabolicGreen),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  delta == null
                      ? 'de 100'
                      : (delta == 0
                          ? 'igual que ayer'
                          : '${delta > 0 ? '+' : ''}$delta vs. ayer'),
                  style: TextStyle(
                    color: delta != null && delta > 0
                        ? AppColors.metabolicGreen
                        : Colors.white.withValues(alpha: 0.55),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color titleColor,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInsight() {
    final fb = cycle.feedback!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.metabolicGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fb.insight,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fb.citation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    fb.citation!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta() {
    final parts = <String>[];
    if (cycle.fastingDurationHours != null) {
      parts.add('Ayuno ${cycle.fastingDurationHours!.toStringAsFixed(1)}h');
    }
    if (cycle.feedingWindowHours != null) {
      parts.add('Ventana ${cycle.feedingWindowHours!.toStringAsFixed(1)}h');
    }
    parts.add('Protocolo ${cycle.fastingProtocol}');
    final reason = cycle.closureReason;
    if (reason != null) {
      parts.add('Cierre: ${_humanReason(reason)}');
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        parts.join(' · '),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 11,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String _formatDateLong(DateTime dt) {
    return '${dt.day} de ${_monthsLong[dt.month - 1]}';
  }

  String _humanReason(ClosureReason r) {
    switch (r) {
      case ClosureReason.manualNextFasting:
        return 'iniciaste tu siguiente ayuno';
      case ClosureReason.fallback3hAfterWindow:
        return '3h después del cierre de ventana';
      case ClosureReason.fallbackSleepDetected:
        return 'detección de sueño';
      case ClosureReason.fallbackAbsolute:
        return 'cierre automático (no lo cerraste tú)';
      case ClosureReason.fallbackCalendar:
        return 'cierre calendárico';
      case ClosureReason.protocolChanged:
        return 'cambiaste tu protocolo';
    }
  }
}
