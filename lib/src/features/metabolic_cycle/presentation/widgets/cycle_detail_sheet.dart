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
  const CycleDetailSheet({super.key, required this.cycle});

  final MetabolicCycle cycle;

  /// Helper para abrir el sheet con el patrón habitual del proyecto.
  static Future<void> show(BuildContext context, MetabolicCycle cycle) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CycleDetailSheet(cycle: cycle),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CIERRE DE TU DÍA METABÓLICO',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatDateLong(cycle.closedAt ?? cycle.startedAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    final score = cycle.dailyScore ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            height: 1.0,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '/100',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
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
        return 'cierre automático a las 28h';
      case ClosureReason.fallbackCalendar:
        return 'cierre calendárico';
      case ClosureReason.protocolChanged:
        return 'cambiaste tu protocolo';
    }
  }
}
