/// Fases biológicas extendidas según el mapa cronológico del ayuno real.
///
/// SPEC-221 (2026-06-17): este es el enum CANÓNICO de fases de ayuno.
/// El OrchestratorEngine mantiene su propio `FastingPhase` en
/// `biological_phases.dart` por compatibilidad con Freezed (pendiente
/// de unificación completa tras correr `build_runner`). Usa
/// [orchestratorBand] para mapear a las 4 bandas del orchestrator.
enum FastingPhase {
  none, // Estado inicial/Alimentación
  postAbsorption, // 0-12h: Descenso de insulina
  transition, // 12-18h: Gluconeogénesis
  fatBurning, // 18-24h: Cetosis nutricional
  autophagy, // 24-48h: Reciclaje celular
  survival; // 48h+: Conservación profunda

  /// Nombre para UI del dashboard y notificaciones.
  String get displayName => switch (this) {
        none => 'Alimentación',
        postAbsorption => 'Post-absorción',
        transition => 'Transición',
        fatBurning => 'Quema de grasa',
        autophagy => 'Autofagia',
        survival => 'Conservación',
      };

  /// Descripción breve para tooltips o cards de coaching.
  String get description => switch (this) {
        none => 'Tu cuerpo usa la energía de lo que comiste.',
        postAbsorption =>
          'La insulina baja, tu cuerpo empieza a usar reservas.',
        transition =>
          'Tu hígado produce glucosa; la oxidación de grasa aumenta.',
        fatBurning => 'Cetosis nutricional: la grasa es tu fuente principal.',
        autophagy => 'Reciclaje celular profundo. Tu cuerpo se repara.',
        survival => 'Conservación profunda. Solo con supervisión médica.',
      };

  /// SPEC-221: Banda simplificada que mapea al OrchestratorEngine.
  ///
  /// El orchestrator opera con 4 estados internos. Este getter permite
  /// que cualquier consumer pase de la fase canónica (6 valores) a la
  /// banda del orchestrator (4 valores) sin conocer los umbrales.
  ///
  /// Mapeo:
  ///   none / postAbsorption  → 'early' (alerta en el orchestrator)
  ///   transition             → 'gluconeogenesis'
  ///   fatBurning             → 'ketosis' (cetosis)
  ///   autophagy / survival   → 'deepFasting' (autofagia)
  String get orchestratorBand => switch (this) {
        none || postAbsorption => 'early',
        transition => 'gluconeogenesis',
        fatBurning => 'ketosis',
        autophagy || survival => 'deepFasting',
      };

  // ───────────────────────────────────────────────────────────────────
  // FUENTE ÚNICA DE VERDAD DE LOS HITOS (auditoría 2026-07-27, C-01)
  //
  // Antes de este bloque existían CINCO definiciones divergentes de la
  // misma taxonomía: los comentarios del enum, `determinePhase`,
  // `metabolicMilestone`, `nextMilestoneLabel`,
  // `fasting_consciousness_card._formatNextMilestone` y
  // `fasting_hero_display._friendlyMilestone`. El resultado observado en
  // ejecución era que, a los 17 minutos de ayuno, el anillo del Dashboard
  // anunciaba "Quema de grasa en 11h 43m" y la tarjeta de abajo
  // "Descenso de insulina en 11h 42m" — dos afirmaciones fisiológicas
  // distintas para el mismo instante, y ninguna coincidente con este enum,
  // que sitúa la cetosis nutricional entre las 18 y 24 horas.
  //
  // A partir de aquí, umbrales y nombres viven SOLO en el dominio. Ningún
  // widget puede volver a inventarse los suyos: los tres getters de abajo
  // son la única vía.
  // ───────────────────────────────────────────────────────────────────

  /// Horas de ayuno acumuladas a las que se ENTRA en esta fase.
  ///
  /// Es el umbral que `determinePhase` usa para clasificar y el que
  /// `timeRemainingForNextMilestone` usa para contar hacia atrás. Los
  /// valores son los de IMR_BIBLIOGRAPHY.md (Mattson 2017, Anton 2018).
  Duration get startsAt => switch (this) {
        none || postAbsorption => Duration.zero,
        transition => const Duration(hours: 12),
        fatBurning => const Duration(hours: 18),
        autophagy => const Duration(hours: 24),
        survival => const Duration(hours: 48),
      };

  /// Fase siguiente en el mapa cronológico, **a efectos de anuncio al
  /// usuario**. `null` cuando ya no hay hito que prometer.
  ///
  /// `autophagy.next` es deliberadamente `null` y NO `survival`: un ayuno
  /// de 48h o más requiere supervisión médica (ver [description] de
  /// `survival`), así que la app no debe empujar hacia él presentándolo
  /// como la próxima meta. Esto además preserva el comportamiento previo,
  /// donde a partir de las 24h no se anunciaba ningún hito nuevo.
  FastingPhase? get next => switch (this) {
        none => postAbsorption,
        postAbsorption => transition,
        transition => fatBurning,
        fatBurning => autophagy,
        autophagy || survival => null,
      };

  /// Nombre del hito con el que se ANUNCIA la entrada a esta fase.
  ///
  /// Se usa siempre en construcciones del tipo "«X» en 3h 20m", es decir
  /// hablando de una fase que el usuario todavía NO alcanzó. Para nombrar
  /// la fase en la que ya está, usar [currentStateName].
  String get milestoneName => switch (this) {
        none => 'Estado anabólico',
        postAbsorption => 'Descenso de insulina',
        transition => 'Inicio de cetogénesis',
        fatBurning => 'Quema de grasa',
        autophagy => 'Autofagia',
        survival => 'Regeneración celular',
      };

  /// Nombre de la fase EN CURSO, para construcciones del tipo "estás en X".
  ///
  /// Difiere de [milestoneName] en el matiz temporal: "Autofagia" es el
  /// hito que se alcanza, "Autofagia Activa" es el estado en el que se
  /// está. Mantiene la capitalización histórica porque hay tests que la
  /// afirman literalmente (fasting_e2e_temporal_test.dart).
  String get currentStateName => switch (this) {
        none => 'Estado Anabólico',
        postAbsorption => 'Descenso de Insulina',
        transition => 'Inicio de Cetogénesis',
        fatBurning => 'Quema de Grasa',
        autophagy => 'Autofagia Activa',
        survival => 'Regeneración Celular',
      };
}

/// SPEC-183 (2026-06-05): origen de la activación del ayuno.
///
/// Permite al `metabolicCycleEvaluatorProvider` distinguir entre una
/// transición `isActive: false → true` causada por bootstrap (Firestore
/// restaurando state) versus una causada por acción consciente del
/// usuario (`startFastingManual`).
///
/// Solo las transiciones con `userInitiated` deben disparar la creación
/// de un ciclo metabólico nuevo. Las de `bootstrap` son continuaciones
/// de un estado previo y no deben crear ciclos automáticos.
///
/// El campo NO se persiste en Firestore — vive en memoria por sesión.
enum FastingActivationSource {
  /// Estado inicial — `isActive: false`. Sin transición todavía.
  none,

  /// El listener restauró el state desde Firestore al boot de la app.
  /// El usuario NO presionó nada en esta sesión.
  bootstrap,

  /// El usuario presionó "iniciar ayuno" en la UI (tap consciente).
  userInitiated,

  /// SPEC-260 (2026-07-30): el usuario REGISTRÓ un ayuno que ya venía en
  /// curso ("empecé anoche, lo registro al despertar"), eligiendo la hora
  /// pasada. NO es el inicio de un día metabólico nuevo, sino la
  /// corrección de una omisión — por eso el evaluador NO debe cerrar el
  /// ciclo previo ni disparar `triggerDailyReset`. El anclado del ciclo
  /// lo hace `FastingNotifier.registerOngoingFast` directamente vía
  /// `MetabolicCycleService.reanchorOpenCycle`, preservando los pilares.
  ongoingRegistration,
}

class FastingState {
  final DateTime? startTime;
  final Duration duration;
  final FastingPhase phase;
  final String circadianPhase;
  final Duration timeUntilLock;
  final bool isActive;
  final String fastingProtocol; // ej: "16:8", "18:6"

  // --- PROACTIVIDAD: ALERTA DE VENTANA CRÍTICA ---
  final bool nearSleepWarning;

  // --- ESTADOS DE CONFIRMACIÓN MANUAL ---
  final bool isWaitingForFastingEnd;
  final bool isWaitingForFeedingEnd;
  final bool isSaving;

  /// SPEC-113.bugfix: true si el usuario cerró HOY un ayuno que alcanzó
  /// su targetHours. Permite que `progressPercentage` se mantenga en
  /// 1.0 después de cerrar la ventana (antes caía a 0.0 porque
  /// `isActive` pasaba a false). Se limpia en `resetDaily`.
  ///
  /// Nullable para sobrevivir hot-reload: en runs donde el state
  /// previo no tenía este campo, el getter lo leía como `null` y
  /// crasheaba con `Null is not a subtype of bool`. Tratamos `null`
  /// como `false` en el getter.
  final bool? completedToday;

  /// SPEC-183: origen de la activación del ayuno. Default `none`.
  /// Ver `FastingActivationSource` para detalles. Solo el evaluator
  /// del ciclo metabólico consume este campo — la UI lo ignora.
  final FastingActivationSource activationSource;

  /// Fix anillo de ayuno (2026-06-09): fracción [0..1] del target que
  /// el usuario alcanzó en el ayuno que cerró HOY, incluido el cierre
  /// TEMPRANO (antes del target). Sin esto, cerrar un ayuno 2h antes
  /// dejaba el anillo en 0% (porque `isActive` pasa a false y
  /// `completedToday` solo se marca cuando se alcanza el target).
  /// Con esto, el anillo muestra el % real logrado.
  ///
  /// Nullable y tratado como 0.0 en el getter por la misma razón que
  /// `completedToday`: sobrevivir hot-reload de un state previo sin el
  /// campo sin crashear con `Null is not a subtype of double`.
  final double? closedProgressToday;

  FastingState({
    this.startTime,
    this.duration = Duration.zero,
    this.phase = FastingPhase.none,
    this.circadianPhase = "Iniciando...",
    this.timeUntilLock = Duration.zero,
    this.isActive = false,
    this.fastingProtocol = "16:8",
    this.nearSleepWarning = false,
    this.isWaitingForFastingEnd = false,
    this.isWaitingForFeedingEnd = false,
    this.isSaving = false,
    this.completedToday,
    this.activationSource = FastingActivationSource.none,
    this.closedProgressToday,
  });

  factory FastingState.initial() => FastingState();

  /// --- LÓGICA DE PROGRESO Y TARGET ---

  int get targetHours {
    final cleanProtocol =
        fastingProtocol.contains(':') ? fastingProtocol.split(':').first : "16";
    return int.tryParse(cleanProtocol) ?? 16;
  }

  double get progressPercentage {
    // Blindaje (2026-06-11): un ayuno ACTIVO siempre refleja su progreso EN
    // VIVO. `completedToday`/`closedProgressToday` pertenecen al ayuno ANTERIOR
    // ya cerrado; si el usuario inicia uno nuevo el mismo día, esos flags NO
    // deben pisar el progreso del ayuno en curso (bug: anillo pegado en 100%
    // al iniciar el siguiente ayuno). El orden de precedencia es deliberado:
    //   1. Ayuno activo → % en vivo (manda sobre cualquier flag de cierre).
    //   2. Cerrado HOY al 100% → 1.0.
    //   3. Cerrado HOY (incl. cierre temprano) → % logrado.
    //   4. Sin ayuno hoy → 0.
    if (isActive) {
      if (targetHours == 0) return 0.0;
      final double percent = duration.inSeconds / (targetHours * 3600);
      return percent.clamp(0.0, 1.0);
    }
    // SPEC-113.bugfix: ayuno cerrado completo HOY queda en 100% aunque ya no
    // haya intervalo activo. `== true` es null-safe contra hot-reload.
    if (completedToday == true) return 1.0;
    // Fix anillo (2026-06-09): cierre TEMPRANO preserva el % logrado.
    return (closedProgressToday ?? 0.0).clamp(0.0, 1.0);
  }

  /// Clasifica una duración en su fase. Los umbrales NO se repiten aquí:
  /// se derivan de `FastingPhase.startsAt` (auditoría 2026-07-27, C-01),
  /// de modo que mover un umbral en el enum mueve también la
  /// clasificación, el countdown y todas las etiquetas a la vez.
  static FastingPhase determinePhase(Duration duration) {
    // Recorrido de la fase más avanzada a la más temprana: la primera
    // cuyo umbral de entrada ya se cruzó es la fase actual.
    for (final phase in const [
      FastingPhase.survival,
      FastingPhase.autophagy,
      FastingPhase.fatBurning,
      FastingPhase.transition,
    ]) {
      if (duration >= phase.startsAt) return phase;
    }
    return FastingPhase.postAbsorption;
  }

  /// Nombre de la fase EN CURSO. Delega en el enum canónico.
  String get metabolicMilestone => phase.currentStateName;

  /// COMUNICACIÓN SEMÁNTICA DE ALERTA
  String? get metabolicAlert {
    if (nearSleepWarning && !isActive) {
      return "CIERRE DE VENTANA OBLIGATORIO: < 3H PARA REPARACIÓN";
    }
    return null;
  }

  /// Fase que el usuario alcanzará a continuación, o `null` si ya no hay
  /// hito que anunciar. Única fuente para cualquier UI que quiera decir
  /// "próximo hito" (auditoría 2026-07-27, C-01).
  ///
  /// Corrige un error de índice histórico: con el ayuno por debajo de las
  /// 12h, el código anterior anunciaba "Descenso de insulina" como lo que
  /// venía, cuando el descenso de insulina es la fase en la que el usuario
  /// YA está. Lo que viene a las 12h es el inicio de cetogénesis.
  FastingPhase? get nextPhase => isActive ? phase.next : null;

  String get nextMilestoneLabel {
    if (!isActive) {
      return nearSleepWarning
          ? "ATENCIÓN: RIESGO DE INSULINA NOCTURNA"
          : "META: INICIAR AYUNO";
    }
    final next = nextPhase;
    if (next == null) return "FASE DE REGENERACIÓN PROFUNDA";
    return "SIGUIENTE ETAPA: ${next.milestoneName.toUpperCase()} "
        "(${next.startsAt.inHours}H)";
  }

  Duration get timeRemainingForNextMilestone {
    if (!isActive) {
      final remaining = const Duration(hours: 8) - duration;
      return remaining.isNegative ? Duration.zero : remaining;
    }
    final next = nextPhase;
    if (next == null) return Duration.zero;
    final remaining = next.startsAt - duration;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  FastingState copyWith({
    DateTime? startTime,
    Duration? duration,
    FastingPhase? phase,
    String? circadianPhase,
    Duration? timeUntilLock,
    bool? isActive,
    String? fastingProtocol,
    bool? nearSleepWarning,
    bool? isWaitingForFastingEnd,
    bool? isWaitingForFeedingEnd,
    bool? isSaving,
    bool? completedToday,
    FastingActivationSource? activationSource,
    double? closedProgressToday,
  }) {
    return FastingState(
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      phase: phase ?? this.phase,
      circadianPhase: circadianPhase ?? this.circadianPhase,
      timeUntilLock: timeUntilLock ?? this.timeUntilLock,
      isActive: isActive ?? this.isActive,
      fastingProtocol: fastingProtocol ?? this.fastingProtocol,
      nearSleepWarning: nearSleepWarning ?? this.nearSleepWarning,
      isWaitingForFastingEnd:
          isWaitingForFastingEnd ?? this.isWaitingForFastingEnd,
      isWaitingForFeedingEnd:
          isWaitingForFeedingEnd ?? this.isWaitingForFeedingEnd,
      isSaving: isSaving ?? this.isSaving,
      completedToday: completedToday ?? this.completedToday,
      activationSource: activationSource ?? this.activationSource,
      closedProgressToday: closedProgressToday ?? this.closedProgressToday,
    );
  }
}
