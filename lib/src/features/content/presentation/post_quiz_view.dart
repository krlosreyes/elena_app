// SPEC-205 inc4: quiz al final del artículo. "Pon a prueba lo que aprendiste".
//
// Interactivo y sin red: al tocar una opción, se bloquea esa pregunta y se
// revela correcta/incorrecta. Lleva el conteo de aciertos.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/content/domain/post.dart';

class PostQuizView extends StatefulWidget {
  const PostQuizView(
      {super.key, required this.questions, required this.accent});
  final List<QuizQuestion> questions;
  final Color accent;

  @override
  State<PostQuizView> createState() => _PostQuizViewState();
}

class _PostQuizViewState extends State<PostQuizView> {
  /// índice de pregunta → índice de opción elegida.
  final Map<int, int> _selected = {};

  int get _answered => _selected.length;
  int get _correct {
    var c = 0;
    _selected.forEach((q, opt) {
      if (widget.questions[q].isCorrect(opt)) c++;
    });
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final allDone = _answered == total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pon a prueba lo que aprendiste',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$_answered/$total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < total; i++) _question(i),
          if (allDone) ...[
            const SizedBox(height: 6),
            _summary(),
          ],
        ],
      ),
    );
  }

  Widget _question(int qi) {
    final q = widget.questions[qi];
    final chosen = _selected[qi];
    final locked = chosen != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          for (var oi = 0; oi < q.options.length; oi++)
            _option(qi, oi, q, chosen, locked),
        ],
      ),
    );
  }

  Widget _option(
    int qi,
    int oi,
    QuizQuestion q,
    int? chosen,
    bool locked,
  ) {
    final isCorrect = oi == q.correctIndex;
    final isChosen = oi == chosen;

    Color border = Colors.white.withValues(alpha: 0.12);
    Color bg = Colors.transparent;
    Color text = Colors.white.withValues(alpha: 0.85);
    Widget? trailing;

    if (locked) {
      if (isCorrect) {
        border = const Color(0xFF10B981);
        bg = const Color(0xFF10B981).withValues(alpha: 0.12);
        text = Colors.white;
        trailing =
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18);
      } else if (isChosen) {
        border = Colors.redAccent;
        bg = Colors.redAccent.withValues(alpha: 0.10);
        trailing = const Icon(Icons.cancel, color: Colors.redAccent, size: 18);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: locked ? null : () => setState(() => _selected[qi] = oi),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  q.options[oi],
                  style: TextStyle(
                    color: text,
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final total = widget.questions.length;
    final c = _correct;
    final perfect = c == total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        perfect
            ? '¡Perfecto! Acertaste las $total. 🎉'
            : 'Acertaste $c de $total. Vuelve al artículo si quieres repasar.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}
