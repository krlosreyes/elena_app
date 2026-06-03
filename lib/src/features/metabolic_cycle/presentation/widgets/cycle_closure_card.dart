// SPEC-149 §RF-149-08: card de cierre del Día Metabólico.
//
// Se renderiza en el Dashboard cuando hay un ciclo cerrado reciente
// que el usuario aún no descartó. Es el "coaching moment" — score
// del ciclo + lo que logró + lo que faltó + insight científico + CTA
// para iniciar el siguiente ayuno.
//
// Arquitectura:
// - `CycleClosureCard`: ConsumerWidget que lee providers y monta el View.
//   Se oculta automáticamente cuando no hay cierre no leído.
// - `CycleClosureCardView`: StatelessWidget puro que recibe los datos
//   por constructor. Testeable sin Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

/// Card del Dashboard que muestra el cierre del último ciclo metabólico.
/// Se oculta cuando no hay cierre no leído.
class CycleClosureCard extends ConsumerWidget {
  const CycleClosureCard({
    super.key,
    this.onStartNextFasting,
  });

  /// Callback invocado al tap del CTA. El integrador decide qué hacer
  /// (típicamente: dispatch fastingProvider.startFasting + navegar al
  /// dashboard). Si null, el botón se renderiza inactivo.
  final VoidCallback? onStartNextFasting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastClosedAsync = ref.watch(lastClosedMetabolicCycleProvider);
    final hasUnread = ref.watch(hasUnreadCycleClosureProvider);

    final cycle = lastClosedAsync.valueOrNull;
    if (cycle == null || !hasUnread || cycle.feedback == null) {
      return const SizedBox.shrink();
    }

    return CycleClosureCardView(
      cycle: cycle,
      onDismiss: () async {
        // SPEC-149.1 Bug 1a: dismiss via notifier reactivo. Antes
        // escribía a prefs directo y el provider no se invalidaba.
        await ref
            .read(cycleClosureDismissalProvider.notifier)
            .dismiss(cycle.cycleId);
      },
      onStartNextFasting: onStartNextFasting == null
          ? null
          : () async {
              await ref
                  .read(cycleClosureDismissalProvider.notifier)
                  .dismiss(cycle.cycleId);
              onStartNextFasting!();
            },
    );
  }
}

/// View stateless puro. Recibe MetabolicCycle + callbacks por constructor.
/// Garantiza que el ciclo está cerrado y tiene feedback (precondición
/// validada por el caller).
class CycleClosureCardView extends StatelessWidget {
  const CycleClosureCardView({
    super.key,
    required this.cycle,
    required this.onDismiss,
    this.onStartNextFasting,
  });

  final MetabolicCycle cycle;
  final VoidCallback onDismiss;
  final VoidCallback? onStartNextFasting;

  @override
  Widget build(BuildContext context) {
    assert(
      cycle.isClosed && cycle.feedback != null,
      'CycleClosureCardView requiere un ciclo cerrado con feedback. '
      'El wrapper CycleClosureCard valida esta precondición.',
    );
    final feedback = cycle.feedback!;
    final score = cycle.dailyScore ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildScore(score),
          if (feedback.achievements.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildSection(
              title: 'LOGRASTE',
              titleColor: AppColors.metabolicGreen,
              items: feedback.achievements,
              iconBuilder: (_) => const Icon(
                Icons.check_circle_rounded,
                color: AppColors.metabolicGreen,
                size: 16,
              ),
            ),
          ],
          if (feedback.gaps.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSection(
              title: 'TE FALTÓ',
              titleColor: const Color(0xFFF59E0B),
              items: feedback.gaps,
              iconBuilder: (_) => const Icon(
                Icons.trending_down_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildInsight(feedback.insight, feedback.citation),
          if (onStartNextFasting != null) ...[
            const SizedBox(height: 16),
            _buildCta(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'TU CICLO METABÓLICO CERRÓ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GestureDetector(
          key: const Key('cycle_closure_dismiss_button'),
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.50),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScore(int score) {
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
    required Widget Function(int index) iconBuilder,
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
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: iconBuilder(i),
                ),
                Expanded(
                  child: Text(
                    items[i],
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

  Widget _buildInsight(String insight, String? citation) {
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
                  insight,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (citation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    citation,
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

  Widget _buildCta() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        key: const Key('cycle_closure_start_next_fasting_button'),
        onPressed: onStartNextFasting,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.metabolicGreen.withValues(alpha: 0.15),
          foregroundColor: AppColors.metabolicGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.metabolicGreen.withValues(alpha: 0.40),
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        child: const Text('Empezar mi siguiente ayuno'),
      ),
    );
  }
}
