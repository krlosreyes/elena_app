// SPEC-240: historial completo de comidas del Día Metabólico activo.
//
// Abre como ModalBottomSheet desde ComidasPillarCard. Lee los logs
// directamente de nutritionProvider.state.todayLogs — ninguna query
// adicional a Firestore. Como el sheet es un ConsumerWidget que observa
// nutritionProvider, se reconstruye automáticamente cuando el stream de
// Firestore emite cambios (edición, borrado, nueva comida).
//
// Constitución §1 (SPEC-189): los logs ya están filtrados por
// cycle.startedAt en el NutritionNotifier — este sheet hereda la ventana
// correcta sin lógica adicional de fecha.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/upf_share_computer.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/meal_history_tile.dart';

class MealHistorySheet extends ConsumerWidget {
  const MealHistorySheet({super.key});

  static const Color _accent = Color(0xFFFB923C);

  /// Abre el sheet como ModalBottomSheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MealHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(nutritionProvider).todayLogs;
    // Orden cronológico ascendente (más antigua arriba).
    final sorted = [...logs]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── handle ──────────────────────────────────────────────────
            _Handle(),
            // ── cabecera ─────────────────────────────────────────────────
            _Header(mealCount: sorted.length),
            const Divider(height: 1, color: Colors.white12),
            // ── lista scrollable ─────────────────────────────────────────
            Expanded(
              child: sorted.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) => MealHistoryTile(
                        key: ValueKey(sorted[index].id),
                        log: sorted[index],
                        accent: _accent,
                      ),
                    ),
            ),
            // ── resumen al pie ────────────────────────────────────────────
            if (sorted.isNotEmpty) _SummaryFooter(logs: sorted),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        );
      },
    );
  }
}

// ── handle ──────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ── cabecera ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.mealCount});
  final int mealCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            color: Color(0xFFFB923C),
            size: 20,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Historial de comidas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Día Metabólico activo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

// ── estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.20),
            ),
            const SizedBox(height: 14),
            Text(
              'Sin comidas registradas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Registra tu primera comida del día\ndesde la tarjeta de Comidas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.30),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── resumen al pie ────────────────────────────────────────────────────────────

class _SummaryFooter extends StatelessWidget {
  const _SummaryFooter({required this.logs});
  final List<NutritionLog> logs;

  static const _cocienteService = CocienteAService();

  @override
  Widget build(BuildContext context) {
    final cocienteA = _cocienteService.calculate(logs);
    final cocientePct = (cocienteA * 100).round();

    final upfResult = UpfShareComputer.compute(logs);
    final hasUpfData = upfResult.logsWithNova > 0;

    final cocienteColor = cocientePct >= 67
        ? AppColors.statusGood
        : cocientePct >= 50
            ? AppColors.accent
            : AppColors.statusBad;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FooterStat(
            label: 'Comidas',
            value: '${logs.length}',
            color: Colors.white70,
          ),
          _divider(),
          _FooterStat(
            label: 'Cociente A',
            value: '$cocientePct%',
            color: cocienteColor,
          ),
          if (hasUpfData) ...[
            _divider(),
            _FooterStat(
              label: 'UPF',
              value: '${upfResult.sharePercent}%',
              color: upfResult.sharePercent > 25
                  ? AppColors.statusWarn
                  : AppColors.statusGood,
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.10),
      );
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
