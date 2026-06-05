// SPEC-138 §16.9: pool de copies humano-cercanos con cita bibliográfica.
//
// Aplica memoria `notification-tone-human-not-clinical`: cálido,
// empático, sin culpa, con respaldo trazable. Toda cita lleva formato
// "· Autor Año" al final del copy.
//
// Tres severidades coherentes con `UpfThresholds`:
// - alerta:    UPF semanal > weeklyAlertPercent (40%) → patrón a corregir.
// - mejora:    UPF semanal cayó vs período anterior → reforzar.
// - mantenimiento: UPF estable bajo → reconocimiento puntual.
//
// El selector rotativo evita repetir el mismo copy en logs sucesivos —
// patrón heredado del `TransformationNarrator` (SPEC-148).

class UpfInsight {
  /// Identificador estable para evitar repetir el mismo copy en logs
  /// sucesivos (cooldown del narrador).
  final String id;

  /// Headline del insight, mostrado en cards de coaching.
  final String headline;

  /// Cuerpo del insight (1-2 frases). Tono humano-cercano.
  final String body;

  /// Cita bibliográfica corta. Formato "· Autor Año" o
  /// "· Autor Año · Autor Año" si hay dos referencias.
  final String citation;

  /// Severidad — controla qué pool consultar.
  final UpfInsightSeverity severity;

  const UpfInsight({
    required this.id,
    required this.headline,
    required this.body,
    required this.citation,
    required this.severity,
  });
}

enum UpfInsightSeverity {
  /// UPF semanal cruzó el umbral de alerta.
  alert,

  /// UPF semanal bajó respecto al período anterior.
  improvement,

  /// UPF semanal se mantiene bajo, sin variación.
  maintenance,
}

class UpfCoachingPool {
  UpfCoachingPool._();

  // ── Pool ALERTA — UPF semanal > 40% ───────────────────────────────
  // Justificación científica de los copies: Hall 2019 + Monteiro 2019.
  // Tono cálido (memoria notification-tone-human-not-clinical).

  static const List<UpfInsight> alerts = [
    UpfInsight(
      id: 'upf-alert-pattern-not-episode',
      headline: 'Tu cuerpo lee patrón, no plato puntual',
      body: 'Esta semana hubo más comida industrial que natural en '
          'tu plato. Mañana puede ser otro día — sin culpa, solo '
          'una pista para mirar.',
      citation: '· Monteiro 2019',
      severity: UpfInsightSeverity.alert,
    ),
    UpfInsight(
      id: 'upf-alert-body-thanks',
      headline: 'Cuando le das menos industrial, se nota',
      body: 'Estudios con personas reales encuentran que al bajar el '
          'consumo de ultraprocesados, el cuerpo regula el hambre '
          'más rápido.',
      citation: '· Hall 2019 · Monteiro 2019',
      severity: UpfInsightSeverity.alert,
    ),
    UpfInsight(
      id: 'upf-alert-small-swaps',
      headline: 'Pequeños cambios cuentan',
      body: 'Reemplazar un plato industrial por algo natural unas '
          'veces a la semana mueve el patrón. No tiene que ser '
          'perfecto.',
      citation: '· Monteiro 2019',
      severity: UpfInsightSeverity.alert,
    ),
    UpfInsight(
      id: 'upf-alert-noticing-matters',
      headline: 'Notarlo ya es la mitad',
      body: 'Reconocer cuánto industrial estás comiendo cambia la '
          'próxima compra. Vamos paso a paso.',
      citation: '· Hall 2019',
      severity: UpfInsightSeverity.alert,
    ),
  ];

  // ── Pool MEJORA — UPF semanal bajó respecto al período anterior ──

  static const List<UpfInsight> improvements = [
    UpfInsight(
      id: 'upf-improvement-less-industrial',
      headline: 'Menos industrial esta semana',
      body: 'Notamos que tu plato tuvo más comida natural que el '
          'período anterior. Tu cuerpo lee esa diferencia.',
      citation: '· Hall 2019',
      severity: UpfInsightSeverity.improvement,
    ),
    UpfInsight(
      id: 'upf-improvement-direction-matters',
      headline: 'La dirección importa',
      body: 'Bajar el ultraprocesado, aunque sea un poco, mueve el '
          'patrón en la dirección correcta. Buen trabajo.',
      citation: '· Monteiro 2019',
      severity: UpfInsightSeverity.improvement,
    ),
    UpfInsight(
      id: 'upf-improvement-keep-going',
      headline: 'Vas en buen camino',
      body: 'Cada plato natural cuenta. Esta semana se nota — sigamos '
          'la racha sin presión.',
      citation: '· Hall 2019 · Monteiro 2019',
      severity: UpfInsightSeverity.improvement,
    ),
  ];

  // ── Pool MANTENIMIENTO — UPF estable bajo ─────────────────────────

  static const List<UpfInsight> maintenance = [
    UpfInsight(
      id: 'upf-maintenance-steady-low',
      headline: 'Plato natural sostenido',
      body: 'Tu plato esta semana fue mayormente natural. Es el patrón '
          'que más rinde a largo plazo.',
      citation: '· Monteiro 2019',
      severity: UpfInsightSeverity.maintenance,
    ),
    UpfInsight(
      id: 'upf-maintenance-foundation',
      headline: 'Estás construyendo base',
      body: 'Mantener bajo el industrial semana tras semana es lo que '
          'el cuerpo aprovecha de verdad.',
      citation: '· Hall 2019',
      severity: UpfInsightSeverity.maintenance,
    ),
  ];

  /// Selecciona un insight del pool de [severity], evitando los IDs en
  /// [recentIds] (memoria corta del narrador para no repetir).
  ///
  /// Si todos los del pool están en `recentIds`, devuelve el primero
  /// del pool — preferimos repetir antes que devolver null.
  static UpfInsight select({
    required UpfInsightSeverity severity,
    Set<String> recentIds = const {},
  }) {
    final pool = switch (severity) {
      UpfInsightSeverity.alert => alerts,
      UpfInsightSeverity.improvement => improvements,
      UpfInsightSeverity.maintenance => maintenance,
    };
    if (pool.isEmpty) {
      throw StateError('UpfCoachingPool: pool vacío para $severity');
    }
    for (final insight in pool) {
      if (!recentIds.contains(insight.id)) return insight;
    }
    // Todos vistos recientemente — repetimos el primero (mejor que
    // no devolver nada).
    return pool.first;
  }
}
