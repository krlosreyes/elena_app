// Propuesta "Avances / Tu camino" (15-jul, rediseño de la sección de
// insignias): encabezado de tres cifras grandes, mismo principio que la
// captura de referencia que compartió Carlos (racha / logros / tercer
// indicador) — pero el tercer indicador reemplaza la "Liga" (ranking
// social) por "constancia semanal", una métrica de comparación contigo
// mismo. Ver Propuesta - Avances Tu Camino.docx §4: los rankings sociales
// generan ansiedad de posición en categorías de salud sensibles como
// nutrición, sueño y composición corporal — exactamente lo que mide
// ElenaApp — así que se descartan a propósito, no por omisión.
//
// Los tres datos ya existían en el código, solo no se mostraban juntos
// como una cifra agregada en ningún lugar:
// - Racha actual: StreakState.currentStreak.
// - Insignias: earned.length / BadgeCatalog.all.length.
// - Constancia semanal: StreakState.weeklyAdherence (SPEC-219, proporción
//   de días con ≥3 pilares en los últimos 7 días) — ya calculado, nunca
//   expuesto en la UI hasta ahora.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class AvancesHeader extends ConsumerWidget {
  const AvancesHeader({super.key});

  static const _rachaColor = Color(0xFFF97316);
  static const _insigniasColor = Color(0xFFFBBF24);
  static const _constanciaColor = Color(0xFF34D399);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final earnedCount = ref.watch(badgeProvider.select((s) => s.earned.length));
    final totalBadges = BadgeCatalog.all.length;
    final constancyPct = (streak.weeklyAdherence.clamp(0.0, 1.0) * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            color: _rachaColor,
            value: '${streak.currentStreak}',
            label: streak.currentStreak == 1 ? 'día de racha' : 'días de racha',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_rounded,
            color: _insigniasColor,
            value: '$earnedCount/$totalBadges',
            label: 'insignias',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.track_changes_rounded,
            color: _constanciaColor,
            value: '$constancyPct%',
            label: 'constancia semanal',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
