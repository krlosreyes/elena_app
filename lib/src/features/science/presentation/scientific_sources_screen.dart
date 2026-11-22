// SPEC-305 — "Fuentes científicas": todas las referencias de Elena en un
// solo lugar, agrupadas por pilar y con enlace.
//
// Se llega desde Perfil ▸ Ajustes ▸ Fuentes científicas, desde Ayuda y
// legal, desde la declaración médica y desde el "Ver todas las fuentes" de
// cada bloque de fuentes. Es la ruta que se le indica a App Review.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/science/domain/scientific_source.dart';
import 'package:elena_app/src/features/science/presentation/widgets/sources_footer.dart';

class ScientificSourcesScreen extends StatelessWidget {
  const ScientificSourcesScreen({super.key});

  static const String routePath = '/profile/fuentes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Fuentes científicas',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text(
            'Cada cálculo y cada recomendación de Elena se apoya en estudios '
            'publicados y guías oficiales. Toca cualquier fuente para leerla.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'El IMR es un índice propio de Elena: combina tus cinco pilares, '
            'y cada uno se apoya en las fuentes de abajo. Elena te acompaña, '
            'pero no reemplaza a tu médico.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          for (final category in SourceCategory.values)
            ..._section(category),
        ],
      ),
    );
  }

  List<Widget> _section(SourceCategory category) {
    final items =
        ScientificSources.all.where((s) => s.category == category).toList();
    if (items.isEmpty) return const [];
    return [
      const SizedBox(height: 22),
      Text(
        category.label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1, color: Colors.white.withValues(alpha: 0.06)),
              SourceTile(source: items[i], showSupports: true),
            ],
          ],
        ),
      ),
    ];
  }
}
