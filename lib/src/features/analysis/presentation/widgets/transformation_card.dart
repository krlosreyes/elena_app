// SPEC-148 §RF-148-05 (2026-06-05): TransformationCard widget.
//
// Card grande en Análisis → tab Resultados. Muestra la comparativa
// "hace 30 días vs hoy" para 6 indicadores + un bloque de
// interpretación humana con cita bibliográfica.
//
// Stateless puro — recibe el `TransformationSnapshot` y la narrativa
// elegida por el `TransformationNarrator`. No conoce Riverpod. La
// versión ConsumerWidget que watch el provider y arma estos inputs
// vive abajo en el mismo archivo (`TransformationCardLive`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/transformation_narrator.dart';
import 'package:elena_app/src/features/analysis/application/transformation_provider.dart';
import 'package:elena_app/src/features/analysis/domain/transformation_snapshot.dart';

/// Versión "live" del card que watch el provider del snapshot.
class TransformationCardLive extends ConsumerWidget {
  const TransformationCardLive({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(transformationSnapshotProvider);

    if (snapshot == null) {
      // Loading inicial — skeleton ligero.
      return const _LoadingShell();
    }

    if (snapshot.isEmpty) {
      // Usuario sin 30 días de data — placeholder cálido del SPEC §2.4.
      return const _EmptyPlaceholder();
    }

    final narrative = TransformationNarrator.pick(snapshot);
    return TransformationCard(
      snapshot: snapshot,
      narrative: narrative,
    );
  }
}

/// Card stateless puro. Testeable sin Riverpod.
class TransformationCard extends StatelessWidget {
  const TransformationCard({
    super.key,
    required this.snapshot,
    required this.narrative,
  });

  final TransformationSnapshot snapshot;
  final TransformationNarrative? narrative;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Headers de las dos columnas.
          Row(
            children: [
              const SizedBox(width: 80), // espacio del label izquierdo
              Expanded(
                child: Center(
                  child: Text(
                    'HACE 30 DÍAS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'HOY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // espacio del delta
            ],
          ),
          const SizedBox(height: 12),
          // Grilla de indicadores.
          for (final d in snapshot.all) ...[
            _IndicatorRow(delta: d),
            const SizedBox(height: 8),
          ],
          if (narrative != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 14),
            _NarrativeBlock(narrative: narrative!),
          ],
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.delta});
  final TransformationDelta delta;

  @override
  Widget build(BuildContext context) {
    final past = delta.past;
    final current = delta.current;
    final showDelta = delta.hasBoth;
    final deltaVal = delta.delta;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            delta.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              past == null ? '—' : _formatValue(past, delta.unit),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              current == null ? '—' : _formatValue(current, delta.unit),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: showDelta && deltaVal != null
              ? _DeltaPill(deltaValue: deltaVal, unit: delta.unit)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _formatValue(num value, String unit) {
    if (value is int) return '$value';
    // double — un decimal para peso/cintura/etc., entero si es entero.
    final d = value.toDouble();
    if (d == d.roundToDouble()) return d.toStringAsFixed(0);
    return d.toStringAsFixed(1);
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.deltaValue, required this.unit});
  final num deltaValue;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final isUp = deltaValue > 0;
    final isStable = deltaValue == 0;
    // Convención: para indicadores donde "subir" es positivo (IMR,
    // sueño, ayuno) → verde flecha arriba. Para indicadores donde
    // "bajar" es positivo (peso, cintura, %grasa) → verde flecha abajo.
    // El widget no conoce el contexto del indicador — usa flecha
    // simple y deja la interpretación al copy del narrador.
    final color =
        isStable ? Colors.white.withValues(alpha: 0.40) : AppColors.accent;
    final arrow = isStable ? '↔' : (isUp ? '↑' : '↓');
    final absVal = deltaValue.abs();
    final formatted = absVal is int
        ? '$absVal'
        : (absVal == absVal.roundToDouble()
            ? absVal.toStringAsFixed(0)
            : absVal.toStringAsFixed(1));
    return Text(
      '$arrow$formatted',
      textAlign: TextAlign.right,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _NarrativeBlock extends StatelessWidget {
  const _NarrativeBlock({required this.narrative});
  final TransformationNarrative narrative;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU INTERPRETACIÓN',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 9.5,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          narrative.headline,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (narrative.citation != null) ...[
          const SizedBox(height: 6),
          Text(
            '· ${narrative.citation}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.timelapse_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'En 30 días tu transformación va a tener su primera foto '
              'comparable. Sigue registrando.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
