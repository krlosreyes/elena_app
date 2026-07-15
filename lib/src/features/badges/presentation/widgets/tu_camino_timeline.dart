// Propuesta "Avances / Tu camino" (15-jul, §5.2): línea de tiempo
// horizontal de insignias ganadas EN ORDEN CRONOLÓGICO — la pieza que
// antes no existía en ningún lugar de la app. `EarnedBadge.unlockedAt` ya
// se guardaba desde el sistema de insignias original (15-jul), pero nunca
// se usaba para nada visual hasta ahora.
//
// El nodo final (bloqueado, con candado) muestra la PRÓXIMA insignia
// alcanzable con la distancia real que falta — no una lista abstracta de
// las 38 insignias posibles, solo la siguiente meta concreta. El cálculo
// de "cuál es la más cercana" vive en BadgeEngine.nextClosest y se computa
// en BadgeNotifier (ver comentario ahí sobre por qué no puede vivir acá:
// necesita el historial ANCHO de racha, que este widget no tiene).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/badges/domain/badge_engine.dart';
import 'package:elena_app/src/features/badges/domain/earned_badge.dart';
import 'package:elena_app/src/features/badges/presentation/badge_category_meta.dart';

class TuCaminoTimeline extends ConsumerWidget {
  const TuCaminoTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(badgeProvider.select((s) => s.earned));
    final nextProgress = ref.watch(badgeProvider.select((s) => s.nextProgress));

    // Sin insignias ganadas todavía no hay "camino" que mostrar — el
    // encabezado (racha/insignias/constancia) y la galería ya cubren el
    // estado inicial; evita una línea de tiempo vacía con un solo nodo
    // bloqueado flotando sin contexto.
    if (earned.isEmpty) return const SizedBox.shrink();

    final sorted = [...earned]..sort((a, b) => a.unlockedAt.compareTo(b.unlockedAt));
    final nodeCount = sorted.length + (nextProgress != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tu camino',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: nodeCount,
            itemBuilder: (context, i) {
              final showConnector = i > 0;
              if (i == sorted.length && nextProgress != null) {
                return _TimelineNode(
                  icon: Icons.lock_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  filled: false,
                  label: _levelLabel(nextProgress.definition),
                  showConnector: showConnector,
                );
              }
              final badge = sorted[i];
              final meta = kBadgeCategoryMeta[badge.category];
              return _TimelineNode(
                icon: meta?.icon ?? Icons.emoji_events_rounded,
                color: meta?.color ?? Colors.white,
                filled: true,
                label: meta?.displayName ?? badge.category,
                showConnector: showConnector,
              );
            },
          ),
        ),
        if (nextProgress != null) ...[
          const SizedBox(height: 8),
          Text(
            _remainingText(nextProgress),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
        ],
      ],
    );
  }

  String _levelLabel(BadgeDefinition def) => def.name.contains('—') ? def.name.split('—').last.trim() : def.name;

  String _remainingText(BadgeProgress progress) {
    final unit = progress.definition.category == BadgeCategory.checkin ? 'check-in' : 'día';
    final unitPlural = progress.definition.category == BadgeCategory.checkin ? 'check-ins' : 'días';
    final n = progress.remaining;
    return n == 1
        ? 'Te falta 1 $unit más para tu próxima insignia'
        : 'Te faltan $n $unitPlural más para tu próxima insignia';
  }
}

class _TimelineNode extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final String label;
  final bool showConnector;

  const _TimelineNode({
    required this.icon,
    required this.color,
    required this.filled,
    required this.label,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showConnector)
          Container(
            width: 18,
            height: 1.5,
            margin: const EdgeInsets.only(bottom: 20),
            color: Colors.white.withValues(alpha: 0.15),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: filled ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: filled ? color : Colors.white.withValues(alpha: 0.4),
                size: filled ? 19 : 16,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 58,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: filled ? 0.5 : 0.35),
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
