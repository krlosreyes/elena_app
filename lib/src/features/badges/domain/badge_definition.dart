// Sistema de insignias (2026-07-15) — catálogo estático de qué insignias
// existen, en qué categoría, con qué umbral y qué nivel. Contenido puro,
// sin lógica — la lógica de CUÁNDO se desbloquean vive en badge_engine.dart.
//
// Diseño: pocas categorías (10) con varios niveles cada una — no decenas
// de insignias sueltas sin relación (ver Propuesta - Sistema de Insignias
// §3, basado en el modelo de Duolingo/Apple Fitness). Todas ancladas en
// comportamiento real de los 5 pilares, el IMR o la racha — nada de
// insignias por abrir la app.
//
// Métrica elegida — "días completados", no "horas/litros/minutos
// acumulados": la Propuesta usaba esas unidades como ejemplo ilustrativo,
// pero `StreakEntry` guarda magnitudes como RATIOS (ej. fastingMagnitude =
// horas / horas objetivo), no unidades absolutas — convertirlas de vuelta
// a horas/litros reales requeriría multiplicar por la meta de cada
// usuario en cada día histórico, lo que agrega riesgo de cálculo sin
// cambiar el valor real de la insignia. Contar días donde el pilar
// realmente se completó (`StreakEntry.fastingCompleted`, etc.) es un dato
// ya validado, booleano, e igual de significativo.

class BadgeCategory {
  BadgeCategory._();

  static const String racha = 'racha';
  static const String ayuno = 'ayuno';
  static const String sueno = 'sueno';
  static const String hidratacion = 'hidratacion';
  static const String ejercicio = 'ejercicio';
  static const String nutricion = 'nutricion';
  static const String imr = 'imr';
  static const String checkin = 'checkin';
  static const String resiliencia = 'resiliencia';
  static const String bienvenida = 'bienvenida';

  /// Whitelist cerrada — también se usa para validar `category` en
  /// firestore.rules, así un cliente comprometido no puede inventar
  /// categorías arbitrarias.
  ///
  /// Orden (15-jul, feedback de Carlos): `BadgeGallery` recorre esta
  /// lista tal cual para pintar el grid, y debe verse en el mismo orden
  /// que `TuCaminoTimeline` — que ordena por `unlockedAt` real del
  /// usuario. "Bienvenida" es la primera insignia que cualquier usuario
  /// gana (al completar onboarding), así que va primero acá también en
  /// vez de al final; el resto sigue el orden típico de aparición
  /// (racha y ayuno se ganan temprano, imr/checkin/resiliencia son
  /// logros más tardíos). El orden es un valor fijo de catálogo, no se
  /// deriva dinámicamente por usuario — dos usuarios distintos pueden
  /// ganar las insignias en secuencias distintas, pero el grid (a
  /// diferencia del timeline) no es por-usuario.
  static const List<String> all = [
    bienvenida,
    racha,
    ayuno,
    sueno,
    hidratacion,
    ejercicio,
    nutricion,
    imr,
    checkin,
    resiliencia,
  ];
}

class BadgeDefinition {
  final String badgeId;
  final String category;
  final int level;

  /// Unidad según la categoría: días de racha para `racha`, días
  /// completados para los 5 pilares e IMR, check-ins reales para
  /// `checkin`. Sin uso en `resiliencia`/`bienvenida` (umbral fijo,
  /// evaluado con lógica propia en BadgeEngine).
  final int threshold;

  final String name;
  final String description;

  const BadgeDefinition({
    required this.badgeId,
    required this.category,
    required this.level,
    required this.threshold,
    required this.name,
    required this.description,
  });
}

class BadgeCatalog {
  BadgeCatalog._();

  static const List<BadgeDefinition> all = [
    // ── Racha — días consecutivos que calificaron (StreakEngine) ────────
    BadgeDefinition(
        badgeId: 'racha_3',
        category: BadgeCategory.racha,
        level: 1,
        threshold: 3,
        name: 'Primeros pasos',
        description: 'Alcanzaste 3 días seguidos de racha.'),
    BadgeDefinition(
        badgeId: 'racha_7',
        category: BadgeCategory.racha,
        level: 2,
        threshold: 7,
        name: 'Una semana',
        description: 'Alcanzaste 7 días seguidos de racha.'),
    BadgeDefinition(
        badgeId: 'racha_14',
        category: BadgeCategory.racha,
        level: 3,
        threshold: 14,
        name: 'Dos semanas',
        description: 'Alcanzaste 14 días seguidos de racha.'),
    BadgeDefinition(
        badgeId: 'racha_30',
        category: BadgeCategory.racha,
        level: 4,
        threshold: 30,
        name: 'Un mes',
        description: 'Alcanzaste 30 días seguidos de racha.'),
    BadgeDefinition(
        badgeId: 'racha_60',
        category: BadgeCategory.racha,
        level: 5,
        threshold: 60,
        name: 'Dos meses',
        description: 'Alcanzaste 60 días seguidos de racha.'),
    BadgeDefinition(
        badgeId: 'racha_100',
        category: BadgeCategory.racha,
        level: 6,
        threshold: 100,
        name: 'Cien días',
        description: 'Alcanzaste 100 días seguidos de racha.'),
    BadgeDefinition(
        badgeId: 'racha_180',
        category: BadgeCategory.racha,
        level: 7,
        threshold: 180,
        name: 'Medio año',
        description: 'Alcanzaste 180 días seguidos de racha.'),
    BadgeDefinition(
        badgeId: 'racha_365',
        category: BadgeCategory.racha,
        level: 8,
        threshold: 365,
        name: 'Un año',
        description: 'Alcanzaste 365 días seguidos de racha.'),

    // ── Ayuno consciente — días con el pilar de ayuno completado ────────
    BadgeDefinition(
        badgeId: 'ayuno_10',
        category: BadgeCategory.ayuno,
        level: 1,
        threshold: 10,
        name: 'Ayuno consciente — Bronce',
        description: 'Completaste tu pilar de ayuno 10 días.'),
    BadgeDefinition(
        badgeId: 'ayuno_30',
        category: BadgeCategory.ayuno,
        level: 2,
        threshold: 30,
        name: 'Ayuno consciente — Plata',
        description: 'Completaste tu pilar de ayuno 30 días.'),
    BadgeDefinition(
        badgeId: 'ayuno_75',
        category: BadgeCategory.ayuno,
        level: 3,
        threshold: 75,
        name: 'Ayuno consciente — Oro',
        description: 'Completaste tu pilar de ayuno 75 días.'),
    BadgeDefinition(
        badgeId: 'ayuno_150',
        category: BadgeCategory.ayuno,
        level: 4,
        threshold: 150,
        name: 'Ayuno consciente — Platino',
        description: 'Completaste tu pilar de ayuno 150 días.'),

    // ── Sueño reparador — noches con el pilar de sueño completado ───────
    BadgeDefinition(
        badgeId: 'sueno_10',
        category: BadgeCategory.sueno,
        level: 1,
        threshold: 10,
        name: 'Sueño reparador — Bronce',
        description: 'Completaste tu pilar de sueño 10 noches.'),
    BadgeDefinition(
        badgeId: 'sueno_30',
        category: BadgeCategory.sueno,
        level: 2,
        threshold: 30,
        name: 'Sueño reparador — Plata',
        description: 'Completaste tu pilar de sueño 30 noches.'),
    BadgeDefinition(
        badgeId: 'sueno_75',
        category: BadgeCategory.sueno,
        level: 3,
        threshold: 75,
        name: 'Sueño reparador — Oro',
        description: 'Completaste tu pilar de sueño 75 noches.'),
    BadgeDefinition(
        badgeId: 'sueno_150',
        category: BadgeCategory.sueno,
        level: 4,
        threshold: 150,
        name: 'Sueño reparador — Platino',
        description: 'Completaste tu pilar de sueño 150 noches.'),

    // ── Hidratación constante ────────────────────────────────────────────
    BadgeDefinition(
        badgeId: 'hidratacion_10',
        category: BadgeCategory.hidratacion,
        level: 1,
        threshold: 10,
        name: 'Hidratación constante — Bronce',
        description: 'Alcanzaste tu meta de hidratación 10 días.'),
    BadgeDefinition(
        badgeId: 'hidratacion_30',
        category: BadgeCategory.hidratacion,
        level: 2,
        threshold: 30,
        name: 'Hidratación constante — Plata',
        description: 'Alcanzaste tu meta de hidratación 30 días.'),
    BadgeDefinition(
        badgeId: 'hidratacion_75',
        category: BadgeCategory.hidratacion,
        level: 3,
        threshold: 75,
        name: 'Hidratación constante — Oro',
        description: 'Alcanzaste tu meta de hidratación 75 días.'),
    BadgeDefinition(
        badgeId: 'hidratacion_150',
        category: BadgeCategory.hidratacion,
        level: 4,
        threshold: 150,
        name: 'Hidratación constante — Platino',
        description: 'Alcanzaste tu meta de hidratación 150 días.'),

    // ── Movimiento — días con el pilar de ejercicio completado ──────────
    BadgeDefinition(
        badgeId: 'ejercicio_10',
        category: BadgeCategory.ejercicio,
        level: 1,
        threshold: 10,
        name: 'Movimiento — Bronce',
        description: 'Completaste tu pilar de ejercicio 10 días.'),
    BadgeDefinition(
        badgeId: 'ejercicio_30',
        category: BadgeCategory.ejercicio,
        level: 2,
        threshold: 30,
        name: 'Movimiento — Plata',
        description: 'Completaste tu pilar de ejercicio 30 días.'),
    BadgeDefinition(
        badgeId: 'ejercicio_75',
        category: BadgeCategory.ejercicio,
        level: 3,
        threshold: 75,
        name: 'Movimiento — Oro',
        description: 'Completaste tu pilar de ejercicio 75 días.'),
    BadgeDefinition(
        badgeId: 'ejercicio_150',
        category: BadgeCategory.ejercicio,
        level: 4,
        threshold: 150,
        name: 'Movimiento — Platino',
        description: 'Completaste tu pilar de ejercicio 150 días.'),

    // ── Nutrición consciente — comidas dentro de la ventana circadiana ──
    BadgeDefinition(
        badgeId: 'nutricion_10',
        category: BadgeCategory.nutricion,
        level: 1,
        threshold: 10,
        name: 'Nutrición consciente — Bronce',
        description: 'Completaste tu pilar de nutrición 10 días.'),
    BadgeDefinition(
        badgeId: 'nutricion_30',
        category: BadgeCategory.nutricion,
        level: 2,
        threshold: 30,
        name: 'Nutrición consciente — Plata',
        description: 'Completaste tu pilar de nutrición 30 días.'),
    BadgeDefinition(
        badgeId: 'nutricion_75',
        category: BadgeCategory.nutricion,
        level: 3,
        threshold: 75,
        name: 'Nutrición consciente — Oro',
        description: 'Completaste tu pilar de nutrición 75 días.'),
    BadgeDefinition(
        badgeId: 'nutricion_150',
        category: BadgeCategory.nutricion,
        level: 4,
        threshold: 150,
        name: 'Nutrición consciente — Platino',
        description: 'Completaste tu pilar de nutrición 150 días.'),

    // ── Transformación — días con IMR ≥ 60 (el indicador central) ───────
    BadgeDefinition(
        badgeId: 'imr_7',
        category: BadgeCategory.imr,
        level: 1,
        threshold: 7,
        name: 'Transformación — Bronce',
        description: 'Llegaste a un IMR de 60 o más en 7 días.'),
    BadgeDefinition(
        badgeId: 'imr_30',
        category: BadgeCategory.imr,
        level: 2,
        threshold: 30,
        name: 'Transformación — Plata',
        description: 'Llegaste a un IMR de 60 o más en 30 días.'),
    BadgeDefinition(
        badgeId: 'imr_75',
        category: BadgeCategory.imr,
        level: 3,
        threshold: 75,
        name: 'Transformación — Oro',
        description: 'Llegaste a un IMR de 60 o más en 75 días.'),
    BadgeDefinition(
        badgeId: 'imr_150',
        category: BadgeCategory.imr,
        level: 4,
        threshold: 150,
        name: 'Transformación — Platino',
        description: 'Llegaste a un IMR de 60 o más en 150 días.'),

    // ── Autoconocimiento — check-ins biométricos reales (checkin_sheet) ─
    BadgeDefinition(
        badgeId: 'checkin_4',
        category: BadgeCategory.checkin,
        level: 1,
        threshold: 4,
        name: 'Autoconocimiento — Bronce',
        description: 'Registraste tu peso y medidas 4 veces.'),
    BadgeDefinition(
        badgeId: 'checkin_12',
        category: BadgeCategory.checkin,
        level: 2,
        threshold: 12,
        name: 'Autoconocimiento — Plata',
        description: 'Registraste tu peso y medidas 12 veces.'),
    BadgeDefinition(
        badgeId: 'checkin_26',
        category: BadgeCategory.checkin,
        level: 3,
        threshold: 26,
        name: 'Autoconocimiento — Oro',
        description: 'Registraste tu peso y medidas 26 veces.'),
    BadgeDefinition(
        badgeId: 'checkin_52',
        category: BadgeCategory.checkin,
        level: 4,
        threshold: 52,
        name: 'Autoconocimiento — Platino',
        description: 'Registraste tu peso y medidas 52 veces.'),

    // ── Resiliencia — volver a los 7 días de racha tras una ruptura ─────
    BadgeDefinition(
        badgeId: 'resiliencia_1',
        category: BadgeCategory.resiliencia,
        level: 1,
        threshold: 7,
        name: 'Reinicio',
        description:
            'Volviste a 7 días de racha después de una pausa. Empezar de nuevo también cuenta.'),

    // ── Bienvenida — el primer pilar del primer día ──────────────────────
    BadgeDefinition(
        badgeId: 'bienvenida_1',
        category: BadgeCategory.bienvenida,
        level: 1,
        threshold: 1,
        name: 'Bienvenida',
        description: 'Completaste tu primer pilar en ElenaApp.'),
  ];

  static BadgeDefinition? byId(String badgeId) {
    for (final def in all) {
      if (def.badgeId == badgeId) return def;
    }
    return null;
  }

  static List<BadgeDefinition> forCategory(String category) =>
      all.where((d) => d.category == category).toList();
}
