// SPEC-205 inc2: resultado del feed "Para ti".

import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/content/domain/post.dart';

/// Lo que pinta la sección "Para ti":
///   - [context]: la observación de dato más fuerte (línea de contexto). Null
///     en período de calentamiento (sin señal de datos).
///   - [forYou]: el artículo destacado, emparejado al pilar de [context].
///   - [more]: artículos adicionales (diversificados por pilar).
class PersonalizedFeed {
  final Observation? context;
  final Post? forYou;
  final List<Post> more;

  const PersonalizedFeed({
    this.context,
    this.forYou,
    this.more = const [],
  });

  static const PersonalizedFeed empty = PersonalizedFeed();

  bool get isEmpty => forYou == null && more.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Todos los posts mostrados (destacado + adicionales), en orden.
  List<Post> get allPosts => [if (forYou != null) forYou!, ...more];
}
