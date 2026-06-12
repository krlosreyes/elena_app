// SPEC-205 inc2: motor de emparejamiento (puro, sin Flutter ni Riverpod).
//
// Reutiliza la señal del motor de observaciones (SPEC-201) para elegir el
// pilar relevante del usuario y emparejarlo con un artículo. Es determinístico
// y testeable directo.

import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/content/domain/personalized_feed.dart';
import 'package:elena_app/src/features/content/domain/post.dart';

class FeedMatcher {
  FeedMatcher._();

  /// Construye el feed "Para ti".
  ///
  /// - [observations]: salida de `ObservationDetector` (SPEC-201). La más
  ///   fuerte (priorizando las accionables, `action != null`) define el pilar
  ///   objetivo y la línea de contexto.
  /// - [posts]: artículos publicados (se ordenan por fecha desc por defensa).
  /// - [readPostIds]: ids ya leídos por el usuario → se evita repetir.
  /// - [maxMore]: cuántos artículos adicionales bajo el destacado.
  static PersonalizedFeed build({
    required List<Observation> observations,
    required List<Post> posts,
    Set<String> readPostIds = const {},
    int maxMore = 2,
  }) {
    if (posts.isEmpty) return PersonalizedFeed.empty;

    final sorted = [...posts]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    bool isRead(Post p) => readPostIds.contains(p.id);
    final unread = sorted.where((p) => !isRead(p)).toList();

    // 1. Línea de contexto: observación más fuerte, priorizando accionables.
    final context = _pickContext(observations);
    final PillarTag? target =
        context == null ? null : pillarOfObservation(context);

    // 2. Destacado "Para ti".
    Post? forYou;
    if (target != null && target != PillarTag.general) {
      forYou = _firstWhere(unread, (p) => p.pillar == target) ??
          _firstOrNull(unread) ?? // fresco de cualquier pilar antes que repetir
          _firstWhere(sorted, (p) => p.pillar == target) ?? // todos leídos
          _firstOrNull(sorted);
    } else {
      forYou = _firstOrNull(unread) ?? _firstOrNull(sorted);
    }

    // 3. Adicionales: preferir no leídos y diversificar pilar.
    final more = <Post>[];
    final used = <String>{if (forYou != null) forYou.id};

    void fill(Iterable<Post> source, {required bool differentPillar}) {
      for (final p in source) {
        if (more.length >= maxMore) break;
        if (used.contains(p.id)) continue;
        if (differentPillar && forYou != null && p.pillar == forYou.pillar) {
          continue;
        }
        more.add(p);
        used.add(p.id);
      }
    }

    fill(unread, differentPillar: true); // no leídos, otro pilar
    fill(unread, differentPillar: false); // no leídos, cualquier pilar
    fill(sorted, differentPillar: false); // leídos, para no quedar vacío

    return PersonalizedFeed(context: context, forYou: forYou, more: more);
  }

  /// Mapea una observación a su pilar. Quita prefijos `racha-`/`meta-` y
  /// normaliza vía `PillarTag.parse` (que tolera acentos).
  static PillarTag pillarOfObservation(Observation o) {
    var s = o.subject.trim();
    final lower = s.toLowerCase();
    for (final prefix in const ['racha-', 'meta-']) {
      if (lower.startsWith(prefix)) {
        s = s.substring(prefix.length);
        break;
      }
    }
    return PillarTag.parse(s);
  }

  static Observation? _pickContext(List<Observation> observations) {
    if (observations.isEmpty) return null;
    final actionable = observations.where((o) => o.action != null).toList()
      ..sort((a, b) => b.strength.compareTo(a.strength));
    if (actionable.isNotEmpty) return actionable.first;
    final any = [...observations]
      ..sort((a, b) => b.strength.compareTo(a.strength));
    return any.first;
  }

  static Post? _firstWhere(List<Post> list, bool Function(Post) test) {
    for (final p in list) {
      if (test(p)) return p;
    }
    return null;
  }

  static Post? _firstOrNull(List<Post> list) =>
      list.isEmpty ? null : list.first;
}
