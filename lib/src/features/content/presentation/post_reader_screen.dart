// SPEC-205 inc3: lector in-app del artículo.
//
// Renderiza portada + título + meta + contenido (MarkdownLite) + referencias.
// inc4 añade el quiz al final, el incremento de `analytics.views` y el registro
// de lectura (users/{uid}/post_reads).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/content/application/post_providers.dart';
import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:elena_app/src/features/content/presentation/markdown_lite.dart';
import 'package:elena_app/src/features/content/presentation/post_quiz_view.dart';
import 'package:elena_app/src/features/content/presentation/post_ui.dart';

class PostReaderScreen extends ConsumerStatefulWidget {
  const PostReaderScreen({super.key, required this.post});
  final Post post;

  static Route<void> route(Post post) =>
      MaterialPageRoute(builder: (_) => PostReaderScreen(post: post));

  @override
  ConsumerState<PostReaderScreen> createState() => _PostReaderScreenState();
}

class _PostReaderScreenState extends ConsumerState<PostReaderScreen> {
  @override
  void initState() {
    super.initState();
    // inc4: al abrir registramos vista + lectura (best-effort, fuera del build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(postRepositoryProvider);
      final post = widget.post;
      repo.registerView(post.id);
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid != null) {
        repo.markRead(userId: uid, postId: post.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final color = PostUi.pillarColor(post.pillar);
    final muted = Colors.white.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post.imageUrl!,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Mismo bug que en post_card.dart: antes fallaba en
                  // silencio (portada desaparecía sin dejar rastro). Ahora
                  // queda logueado para poder detectar la causa real.
                  errorBuilder: (_, error, ___) {
                    AppLogger.warning(
                      'Imagen de portada no cargó (post=${post.id}): ${post.imageUrl}',
                      error,
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text(
              post.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${PostUi.pillarEmoji(post.pillar)} ${post.pillar.label}',
                    style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${post.readingMinutes} min de lectura',
                    style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            MarkdownLite(post.contentMarkdown),
            if (post.hasQuiz) ...[
              const SizedBox(height: 28),
              PostQuizView(questions: post.quiz, accent: color),
            ],
            if (post.references.isNotEmpty) ...[
              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              const Text(
                'Fuentes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...post.references.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• $r',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
