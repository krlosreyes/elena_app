// SPEC-205 inc1: modelo de dominio del feed "Para ti".
//
// `Post` representa un documento de la colección Firestore `metamorfosis_posts`.
// Parser PURO (sin Firestore ni Flutter) → testeable directo. Tolerante a
// campos faltantes: el editorial sigue publicando y no queremos que un doc
// incompleto rompa el feed.

/// Pilar al que pertenece un artículo. Es la clave de emparejamiento con el
/// estado del usuario (SPEC-205 §4.2). `general` es el fallback cuando el
/// campo `pillar` viene vacío o con un valor desconocido.
enum PillarTag {
  ayuno,
  sueno,
  hidratacion,
  ejercicio,
  nutricion,
  general;

  /// Normaliza el string de Firestore al enum. Insensible a may/min y a
  /// espacios. Valores canónicos (confirmado por Carlos 2026-06-11):
  /// `ayuno` / `sueno` / `hidratacion` / `ejercicio` / `nutricion`.
  static PillarTag parse(Object? raw) {
    final v = raw?.toString().trim().toLowerCase() ?? '';
    switch (v) {
      case 'ayuno':
        return PillarTag.ayuno;
      case 'sueno':
      case 'sueño':
        return PillarTag.sueno;
      case 'hidratacion':
      case 'hidratación':
        return PillarTag.hidratacion;
      case 'ejercicio':
        return PillarTag.ejercicio;
      case 'nutricion':
      case 'nutrición':
        return PillarTag.nutricion;
      default:
        return PillarTag.general;
    }
  }

  /// Etiqueta legible para el chip de la tarjeta.
  String get label {
    switch (this) {
      case PillarTag.ayuno:
        return 'Ayuno';
      case PillarTag.sueno:
        return 'Sueño';
      case PillarTag.hidratacion:
        return 'Hidratación';
      case PillarTag.ejercicio:
        return 'Ejercicio';
      case PillarTag.nutricion:
        return 'Nutrición';
      case PillarTag.general:
        return 'Metabolismo';
    }
  }
}

/// Una pregunta del quiz al final del artículo.
class QuizQuestion {
  final String question;
  final List<String> options;

  /// Índice (0-based) de la opción correcta dentro de [options].
  final int correctIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  static QuizQuestion fromMap(Map<String, dynamic> map) {
    final opts = (map['options'] as List?)
            ?.map((o) => o?.toString() ?? '')
            .where((o) => o.isNotEmpty)
            .toList() ??
        const <String>[];
    final correct = map['correctAnswer'];
    final idx = correct is int
        ? correct
        : int.tryParse(correct?.toString() ?? '') ?? 0;
    return QuizQuestion(
      question: map['question']?.toString() ?? '',
      options: opts,
      // Defensa: si el índice cae fuera de rango lo clampeamos.
      correctIndex: opts.isEmpty ? 0 : idx.clamp(0, opts.length - 1),
    );
  }

  Map<String, dynamic> toCache() => {
        'question': question,
        'options': options,
        'correctAnswer': correctIndex,
      };
}

class Post {
  final String id;
  final String title;
  final String slug;
  final PillarTag pillar;
  final String contentMarkdown;
  final String? imageUrl;
  final List<String> references;
  final List<QuizQuestion> quiz;
  final DateTime publishedAt;
  final String status;

  const Post({
    required this.id,
    required this.title,
    required this.slug,
    required this.pillar,
    required this.contentMarkdown,
    required this.imageUrl,
    required this.references,
    required this.quiz,
    required this.publishedAt,
    required this.status,
  });

  /// Artículo con respaldo científico visible (sello en la tarjeta).
  bool get hasScientificBacking => references.isNotEmpty;

  bool get hasQuiz => quiz.isNotEmpty;

  /// Tiempo de lectura estimado en minutos (≈ 200 palabras/min). Mínimo 1.
  int get readingMinutes {
    final words = contentMarkdown
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (words == 0) return 1;
    return (words / 200).ceil().clamp(1, 99);
  }

  /// Parser desde el doc de Firestore (o desde la caché, mismo shape). El
  /// `id` se inyecta como campo `'id'` del map (doc.id) por el data source.
  static Post fromMap(Map<String, dynamic> map) {
    final metadata = (map['metadata'] as Map?)?.cast<String, dynamic>();

    String pickString(String key, {String fallback = ''}) {
      final top = map[key]?.toString();
      if (top != null && top.isNotEmpty) return top;
      final meta = metadata?[key]?.toString();
      if (meta != null && meta.isNotEmpty) return meta;
      return fallback;
    }

    final images = (map['images'] as List?)
        ?.map((e) => e?.toString())
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toList();

    final refs = (map['references'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final quiz = (map['quiz'] as List?)
            ?.whereType<Map>()
            .map((q) => QuizQuestion.fromMap(q.cast<String, dynamic>()))
            .toList() ??
        const <QuizQuestion>[];

    final published = DateTime.tryParse(map['publishedAt']?.toString() ?? '') ??
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return Post(
      id: map['id']?.toString() ?? pickString('slug'),
      title: pickString('title'),
      slug: pickString('slug'),
      pillar: PillarTag.parse(map['pillar']),
      contentMarkdown: map['content']?.toString() ?? '',
      imageUrl: (images != null && images.isNotEmpty) ? images.first : null,
      references: refs,
      quiz: quiz,
      publishedAt: published,
      status: map['status']?.toString() ?? '',
    );
  }

  /// Serialización mínima para la caché local (SharedPreferences). Solo los
  /// campos que el feed consume — no replicamos analytics ni timestamps de
  /// auditoría.
  Map<String, dynamic> toCache() => {
        'id': id,
        'title': title,
        'slug': slug,
        'pillar': pillar.name,
        'content': contentMarkdown,
        'images': imageUrl == null ? <String>[] : [imageUrl],
        'references': references,
        'quiz': quiz.map((q) => q.toCache()).toList(),
        'publishedAt': publishedAt.toIso8601String(),
        'status': status,
      };
}
