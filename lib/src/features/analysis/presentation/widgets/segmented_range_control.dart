// SPEC-165: segmented control estilo iOS para el rango temporal.
//
// Reemplaza RangeSelectorChips. Look más cálido y nativo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';

class SegmentedRangeControl extends ConsumerWidget {
  const SegmentedRangeControl({
    super.key,
    this.locked = false,
    this.onLockedTap,
  });

  /// UX-PROGRESO (auditoría técnica 21-jul, P1): cuando es `true`, solo
  /// `AnalysisRange.w1` (Semana) queda seleccionable — el resto de
  /// opciones se muestra atenuado con un candado y, al tocarlas,
  /// dispara [onLockedTap] en vez de cambiar el rango. Da una vista
  /// gratuita de 7 días en los detalles de pilar/Score sin exponer
  /// rangos que requieren histórico Premium.
  final bool locked;

  /// Callback al tocar una opción bloqueada (ej. abrir el paywall).
  /// Ignorado si [locked] es `false`.
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(analysisRangeProvider);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: AnalysisRange.values.map((r) {
          final isSelected = r == active;
          final isLockedOption = locked && r != AnalysisRange.w1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isLockedOption) {
                  onLockedTap?.call();
                  return;
                }
                ref.read(analysisRangeProvider.notifier).state = r;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF3A3A3C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLockedOption) ...[
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        r.label,
                        style: TextStyle(
                          color: isLockedOption
                              ? Colors.white.withValues(alpha: 0.30)
                              : (isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.55)),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
