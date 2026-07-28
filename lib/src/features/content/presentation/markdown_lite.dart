// SPEC-205 inc3: render Markdown ligero, sin dependencias externas.
//
// Cubre lo que usan los artículos de `metamorfosis_posts`: encabezados (#, ##,
// ###), citas (>), viñetas (*, -), negrita inline (**), y filas de tabla (|)
// como texto monoespaciado. Suficiente para leer el contenido con dignidad.
// inc4 puede sustituirlo por `flutter_markdown` si se aprueba la dependencia
// (mejora tablas y links); el resto de la pantalla no cambiaría.

import 'package:flutter/material.dart';

class MarkdownLite extends StatelessWidget {
  const MarkdownLite(this.source, {super.key});
  final String source;

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<Widget> _parse(String src) {
    final lines = src.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];
    final paragraph = <String>[];
    final quote = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _inline(paragraph.join(' '), fontSize: 15, height: 1.55),
      ));
      paragraph.clear();
    }

    void flushQuote() {
      if (quote.isEmpty) return;
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
                color: const Color(0xFF10B981).withValues(alpha: 0.7),
                width: 3),
          ),
        ),
        child: _inline(quote.join(' '), fontSize: 14.5, height: 1.5),
      ));
      quote.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final t = line.trim();

      if (t.isEmpty) {
        flushParagraph();
        flushQuote();
        continue;
      }
      if (t.startsWith('> ')) {
        flushParagraph();
        quote.add(t.substring(2));
        continue;
      }
      flushQuote();

      if (t.startsWith('### ')) {
        flushParagraph();
        widgets.add(_heading(t.substring(4), 15.5));
      } else if (t.startsWith('## ')) {
        flushParagraph();
        widgets.add(_heading(t.substring(3), 17.5));
      } else if (t.startsWith('# ')) {
        flushParagraph();
        widgets.add(_heading(t.substring(2), 20));
      } else if (t.startsWith('* ') || t.startsWith('- ')) {
        flushParagraph();
        widgets.add(_bullet(t.substring(2)));
      } else if (t.startsWith('|')) {
        flushParagraph();
        // Fila de tabla: texto monoespaciado (fallback honesto).
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            t.replaceAll('|', '  ').trim(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ));
      } else if (t.startsWith('---')) {
        flushParagraph();
        widgets.add(
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 24));
      } else {
        paragraph.add(t);
      }
    }
    flushParagraph();
    flushQuote();
    return widgets;
  }

  Widget _heading(String text, double size) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: _inline(text,
            fontSize: size, weight: FontWeight.w800, color: Colors.white),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(child: _inline(text, fontSize: 14.5, height: 1.5)),
          ],
        ),
      );

  /// Renderiza negrita inline (`**texto**`).
  Widget _inline(
    String text, {
    double fontSize = 15,
    double height = 1.5,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    final base = TextStyle(
      color: color ?? Colors.white.withValues(alpha: 0.85),
      fontSize: fontSize,
      height: height,
      fontWeight: weight,
    );
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i.isOdd; // texto entre ** queda en posiciones impares
      spans.add(TextSpan(
        text: parts[i],
        style: isBold
            ? base.copyWith(fontWeight: FontWeight.w800, color: Colors.white)
            : base,
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
