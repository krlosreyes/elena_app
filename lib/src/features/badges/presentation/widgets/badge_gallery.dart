// Sistema de insignias (2026-07-15) — galería en Perfil: "identidad, no
// solo mecánica" (Propuesta §6). Un grid de 10 categorías, cada una
// mostrando el nivel más alto ganado; tocar una abre el detalle con
// todos sus niveles (ganados a color, pendientes en silueta) — mismo
// patrón visual de "grid con estado bloqueado/desbloqueado" que usan
// Duolingo y Apple Fitness (ver Propuesta §2.1).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';

class _CategoryMeta {
  final String displayName;
  final IconData icon;
  final Color color;
  const _CategoryMeta(this.displayName, this.icon, this.color);
}

const Map<String, _CategoryMeta> _kCategoryMeta = {
  BadgeCategory.racha: _CategoryMeta('Racha', Icons.local_fire_department_rounded, Color(0xFFF97316)),
  BadgeCategory.ayuno: _CategoryMeta('Ayuno consciente', Icons.hourglass_bottom_rounded, Color(0xFF22D3EE)),
  BadgeCategory.sueno: _CategoryMeta('Sueño reparador', Icons.nightlight_round, Color(0xFF818CF8)),
  BadgeCategory.hidratacion: _CategoryMeta('Hidratación constante', Icons.water_drop_rounded, Colors.blueAccent),
  BadgeCategory.ejercicio: _CategoryMeta('Movimiento', Icons.directions_run_rounded, Color(0xFF34D399)),
  BadgeCategory.nutricion: _CategoryMeta('Nutrición consciente', Icons.restaurant_rounded, Color(0xFFF59E0B)),
  BadgeCategory.imr: _CategoryMeta('Transformación', Icons.trending_up_rounded, Color(0xFF10B981)),
  BadgeCategory.checkin: _CategoryMeta('Autoconocimiento', Icons.monitor_weight_outlined, Color(0xFFEC4899)),
  BadgeCategory.resiliencia: _CategoryMeta('Resiliencia', Icons.spa_rounded, Color(0xFF14B8A6)),
  BadgeCategory.bienvenida: _CategoryMeta('Bienvenida', Icons.emoji_events_rounded, Color(0xFFFBBF24)),
};

class BadgeGallery extends ConsumerWidget {
  const BadgeGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedIds = ref.watch(badgeProvider.select((s) => s.earnedIds));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
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
    final meta = _kCategoryMeta[category]!;
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: hasAny ? 0.4 : 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: hasAny ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meta.displayName,
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
    final meta = _kCategoryMeta[category]!;
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
