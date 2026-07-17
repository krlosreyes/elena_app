// 17-jul: el feed "Para ti" (SPEC-205) vivía inline en Dashboard, siempre
// expandido — Carlos pidió (mismo patrón ya aplicado en Progreso, ver
// results_entry_card.dart) colapsarlo en una card de entrada y renombrarlo
// a algo más coherente con el contenido y más atractivo que "Para ti".
//
// "Aprende con Elena": ata el contenido educativo a la voz de la app
// (Elena, tu guía metabólica) en vez de un genérico "para ti" que no dice
// qué hay adentro. Tap navega a AprendeDetailScreen (/aprende).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/content/application/personalized_feed_provider.dart';

class AprendeEntryCard extends ConsumerWidget {
  const AprendeEntryCard({super.key});

  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(personalizedFeedProvider).valueOrNull;
    final count = feed?.allPosts.length ?? 0;
    final subtitle = feed == null
        ? 'Contenido con respaldo científico, curado para ti'
        : (count == 0
            ? 'Muy pronto: artículos elegidos según tus hábitos'
            : '$count ${count == 1 ? "lectura" : "lecturas"} con respaldo científico');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/aprende'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aprende con Elena',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
