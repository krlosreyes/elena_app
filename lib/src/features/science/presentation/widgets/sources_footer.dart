// SPEC-305 — piezas visibles de las fuentes científicas.
//
//   SourcesFooter   bloque "Fuentes científicas" bajo un cálculo de salud,
//                   con un enlace tocable por fuente.
//   CitationLink    la cita corta de un insight ("Walker 2017 + AASM")
//                   convertida en enlace: al tocarla abre sus fuentes.
//   SourceTile      una fuente tocable (lo comparten ambos y la pantalla
//                   completa).
//
// Guía 1.4.1: las citas deben tener enlace y ser FÁCILES de encontrar. Por
// eso el bloque usa texto de 13 pt en color de acento —no gris al 35% como
// el antiguo "BASE CIENTÍFICA"— y siempre termina en "Ver todas las
// fuentes".

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/science/application/source_link_opener.dart';
import 'package:elena_app/src/features/science/domain/scientific_source.dart';
import 'package:elena_app/src/features/science/presentation/scientific_sources_screen.dart';

Future<void> openScientificSource(
    BuildContext context, ScientificSource source) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await SourceLinkOpener.open(source.url);
  if (!ok) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text('No pudimos abrir el enlace. Búscalo como: '
            '${source.shortLabel} — ${source.venue}.'),
      ),
    );
  }
}

void openAllScientificSources(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const ScientificSourcesScreen(),
      settings: const RouteSettings(name: ScientificSourcesScreen.routePath),
    ),
  );
}

/// Una fuente tocable: autor/año en acento, título y revista debajo.
class SourceTile extends StatelessWidget {
  const SourceTile({super.key, required this.source, this.showSupports = false});

  final ScientificSource source;

  /// Muestra la línea "Respalda: …" (pantalla completa).
  final bool showSupports;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      link: true,
      label: 'Abrir fuente: ${source.shortLabel}, ${source.venue}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('source-tile-${source.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => openScientificSource(context, source),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.shortLabel,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${source.title}. ${source.venue}.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    if (showSupports) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Respalda: ${source.supports}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.open_in_new_rounded,
                    size: 16, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloque de fuentes que va debajo de cada cálculo de salud.
class SourcesFooter extends StatelessWidget {
  const SourcesFooter({
    super.key,
    required this.sources,
    this.title = 'Fuentes científicas',
    this.intro,
    this.showAllLink = true,
  });

  final List<ScientificSource> sources;
  final String title;

  /// Una línea opcional antes de la lista ("Así calculamos tu % de grasa").
  final String? intro;
  final bool showAllLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sources-footer'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (intro != null) ...[
            const SizedBox(height: 6),
            Text(
              intro!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 4),
          for (final s in sources) SourceTile(source: s),
          if (showAllLink)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('sources-footer-see-all'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  foregroundColor: AppColors.accent,
                ),
                onPressed: () => openAllScientificSources(context),
                child: const Text(
                  'Ver todas las fuentes de Elena',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hoja inferior con las fuentes de una cita.
Future<void> showSourcesSheet(
  BuildContext context, {
  required List<ScientificSource> sources,
  String title = 'Fuentes de este dato',
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgElevated,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SourcesFooter(sources: sources, title: title),
      ),
    ),
  );
}

/// La cita corta de un insight, convertida en enlace.
///
/// Si la cita no resuelve a ninguna fuente del catálogo (p. ej. "Basado en
/// tu progreso") se pinta como texto normal, sin enlace: nunca un enlace
/// que no lleva a nada. El test de cobertura impide que una cita real
/// quede sin fuente.
class CitationLink extends StatelessWidget {
  const CitationLink(
    this.citation, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String citation;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final sources = ScientificSources.resolve(citation);
    if (sources.isEmpty) {
      return Text(citation,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow);
    }
    final base = style ?? DefaultTextStyle.of(context).style;
    final linkStyle = base.copyWith(
      color: AppColors.accent,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.accent.withValues(alpha: 0.6),
    );
    return Semantics(
      button: true,
      link: true,
      label: 'Ver fuentes: $citation',
      excludeSemantics: true,
      // Texto plano (sin WidgetSpan de ícono) a propósito: el subrayado en
      // acento ya comunica "enlace", y así el texto sigue siendo
      // exactamente la cita — lectores de pantalla y finders de test lo
      // ven igual que antes.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showSourcesSheet(context, sources: sources),
        child: Text(
          citation,
          style: linkStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }
}
