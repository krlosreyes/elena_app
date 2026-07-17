// SPEC-205 inc3: feed "Para ti" — reemplaza "Tus tendencias" en Análisis.
//
// 17-jul: rebautizado "Aprende con Elena" y sacado del scroll de Dashboard
// — ver AprendeEntryCard (card colapsada) + AprendeDetailScreen (pantalla
// de detalle que envuelve este widget). El título propio se quitó de acá
// porque ahora vive en el AppBar de AprendeDetailScreen — este widget
// vuelve a ser solo el contenido (línea de contexto + artículos).
//
// Combina la observación de dato más fuerte (línea de contexto) con artículos
// emparejados al estado del usuario. Autocontenida: observa
// `personalizedFeedProvider` y maneja sus estados.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/content/application/personalized_feed_provider.dart';
import 'package:elena_app/src/features/content/domain/personalized_feed.dart';
import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:elena_app/src/features/content/presentation/post_card.dart';
import 'package:elena_app/src/features/content/presentation/post_reader_screen.dart';

class ForYouSection extends ConsumerWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(personalizedFeedProvider);

    return feedAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF818CF8)),
          ),
        ),
      ),
      error: (_, __) => _muted(
        'No pudimos cargar el contenido. Revisa tu conexión.',
      ),
      data: (feed) => _content(context, feed),
    );
  }

  Widget _content(BuildContext context, PersonalizedFeed feed) {
    if (feed.isEmpty) {
      return _muted(
        'Pronto vas a ver aquí artículos elegidos para ti según cómo vienes '
        'con tus pilares.',
      );
    }

    void open(Post post) =>
        Navigator.of(context).push(PostReaderScreen.route(post));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (feed.context != null) ...[
          _contextLine(feed.context!),
          const SizedBox(height: 12),
        ],
        if (feed.forYou != null)
          PostCard(post: feed.forYou!, onTap: () => open(feed.forYou!)),
        if (feed.more.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(
              'Más para leer',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...feed.more.map(
            (p) => PostCardCompact(post: p, onTap: () => open(p)),
          ),
        ],
      ],
    );
  }

  /// Línea de contexto: el dato fuerte que justifica el artículo destacado.
  Widget _contextLine(Observation o) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1, right: 8),
            child: Text('📈', style: TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Esto te puede ayudar 👇',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _muted(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
