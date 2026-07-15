// Sistema de insignias (2026-07-15) — galería en Perfil: "identidad, no
// solo mecánica" (Propuesta §6). Un grid de 10 categorías, cada una
// mostrando el nivel más alto ganado; tocar una abre el detalle con
// todos sus niveles (ganados a color, pendientes en silueta) — mismo
// patrón visual de "grid con estado bloqueado/desbloqueado" que usan
// Duolingo y Apple Fitness (ver Propuesta §2.1).
//
// Rediseño "Avances / Tu camino" (15-jul): las tarjetas pasaban de fila
// plana (ícono cuadrado + texto en línea) a un tratamiento tipo medalla
// (círculo + texto debajo) — mismo lenguaje visual que los nodos de
// TuCaminoTimeline, para que ambas pantallas se sientan como una sola
// experiencia. La metadata de categoría (ícono/color/nombre) se movió a
// badge_category_meta.dart porque ahora la comparten dos widgets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/badges/presentation/badge_category_meta.dart';

class BadgeGallery extends ConsumerWidget {
  const BadgeGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedIds = ref.watch(badgeProvider.select((s) => s.earnedIds));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      // 15-jul: era SliverGridDelegateWithFixedCrossAxisCount(2 columnas).
      // Eso hace que el ancho de cada card sea "mitad de pantalla" sin
      // tope — en el build web de Carlos (ventana de Chrome ancha) cada
      // card terminaba gigante, con el ícono de 52px perdido en medio de
      // muchísimo espacio vacío. MaxCrossAxisExtent pone un techo fijo al
      // ancho de card (168) sin importar qué tan ancha sea la pantalla;
      // en un teléfono real (~380-430px) sigue dando 2 columnas, igual
      // que antes.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 168,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: BadgeCategory.all.length,
      itemBuilder: (context, i) {
        final category = BadgeCategory.all[i];
        return _CategoryCard(category: category, earnedIds: earnedIds);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final Set<String> earnedIds;

  const _CategoryCard({required this.category, required this.earnedIds});

  @override
  Widget build(BuildContext context) {
    final meta = kBadgeCategoryMeta[category]!;
    final defs = BadgeCatalog.forCategory(category);
    final earnedInCategory = defs.where((d) => earnedIds.contains(d.badgeId)).toList();
    final hasAny = earnedInCategory.isNotEmpty;
    final highest = hasAny
        ? earnedInCategory.reduce((a, b) => a.level > b.level ? a : b)
        : null;
    final color = hasAny ? meta.color : Colors.white.withValues(alpha: 0.25);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showCategorySheet(context, category, earnedIds),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: hasAny ? 0.4 : 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: hasAny ? 0.18 : 0.08),
                border: Border.all(color: color.withValues(alpha: hasAny ? 0.6 : 0.2), width: 1.5),
              ),
              child: Icon(meta.icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              meta.displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hasAny ? highest!.name.split('—').last.trim() : 'Sin desbloquear',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasAny ? color : Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCategorySheet(BuildContext context, String category, Set<String> earnedIds) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryDetailSheet(category: category, earnedIds: earnedIds),
  );
}

class _CategoryDetailSheet extends StatelessWidget {
  final String category;
  final Set<String> earnedIds;

  const _CategoryDetailSheet({required this.category, required this.earnedIds});

  @override
  Widget build(BuildContext context) {
    final meta = kBadgeCategoryMeta[category]!;
    final defs = BadgeCatalog.forCategory(category);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(meta.icon, color: meta.color, size: 24),
                const SizedBox(width: 10),
                Text(
                  meta.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final def in defs) _LevelTile(def: def, earned: earnedIds.contains(def.badgeId), color: meta.color),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final BadgeDefinition def;
  final bool earned;
  final Color color;

  const _LevelTile({required this.def, required this.earned, required this.color});

  @override
  Widget build(BuildContext context) {
    final tileColor = earned ? color : Colors.white.withValues(alpha: 0.15);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: earned ? 0.05 : 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tileColor.withValues(alpha: earned ? 0.4 : 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            earned ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: tileColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.name,
                  style: TextStyle(
                    color: earned ? Colors.white : Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  def.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: earned ? 0.65 : 0.35),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
