// SPEC-205 inc3: tarjetas del feed "Para ti".
//
// `PostCard` (destacada, con miniatura grande) y `PostCardCompact` (lista de
// adicionales). Ambas muestran chip de pilar, tiempo de lectura y, si hay
// referencias, el sello "con respaldo científico".

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:elena_app/src/features/content/presentation/post_ui.dart';

class _Thumb extends StatelessWidget {
  const _Thumb({required this.post, required this.width, required this.height});
  final Post post;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = PostUi.pillarColor(post.pillar);
    final placeholder = Container(
      width: width,
      height: height,
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(PostUi.pillarEmoji(post.pillar),
          style: const TextStyle(fontSize: 28)),
    );
    final url = post.imageUrl;
    final child = (url == null || url.isEmpty)
        ? placeholder
        : Image.network(
            url,
            width: width,
            height: height,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, w, progress) =>
                progress == null ? w : placeholder,
            // Antes esto se tragaba el fallo en silencio: la imagen se
            // reemplazaba por el emoji del pilar y nadie se enteraba de que
            // la URL original nunca cargó. Ahora queda logueado (Crashlytics
            // en prod vía AppLogger) para poder detectar y corregir la causa
            // en el editorial/Storage en vez de que el placeholder la tape
            // para siempre (bug reportado 2026-07-13).
            errorBuilder: (ctx, error, __) {
              AppLogger.warning(
                'Imagen de artículo no cargó (post=${post.id}, pilar=${post.pillar.name}): $url',
                error,
              );
              return placeholder;
            },
          );
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: child);
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final color = PostUi.pillarColor(post.pillar);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        post.pillar.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.55);
    return Row(
      children: [
        _PillarChip(post: post),
        const SizedBox(width: 8),
        Text('${post.readingMinutes} min',
            style: TextStyle(color: muted, fontSize: 11.5)),
        if (post.hasScientificBacking) ...[
          const SizedBox(width: 8),
          Text('🔬 con respaldo',
              style: TextStyle(color: muted, fontSize: 11.5)),
        ],
      ],
    );
  }
}

/// Tarjeta destacada ("Para ti").
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});
  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(post: post, width: double.infinity, height: 150),
            const SizedBox(height: 12),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            _MetaRow(post: post),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta compacta (artículos adicionales).
class PostCardCompact extends StatelessWidget {
  const PostCardCompact({super.key, required this.post, required this.onTap});
  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(post: post, width: 84, height: 84),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MetaRow(post: post),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
