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
        postAbsorption => 'La insulina baja, tu cuerpo empieza a usar reservas.',
        transition => 'Tu hígado produce glucosa; la oxidación de grasa aumenta.',
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

  static FastingPhase determinePhase(Duration duration) {
    final hours = duration.inHours;
    if (hours < 12) return FastingPhase.postAbsorption;
    if (hours < 18) return FastingPhase.transition;
    if (hours < 24) return FastingPhase.fatBurning;
    if (hours < 48) return FastingPhase.autophagy;
    return FastingPhase.survival;
  }

  String get metabolicMilestone {
    switch (phase) {
      case FastingPhase.none:
        return "Estado Anabólico";
      case FastingPhase.postAbsorption:
        return "Descenso de Insulina";
      case FastingPhase.transition:
        return "Inicio de Cetogénesis";
      case FastingPhase.fatBurning:
        return "Quema de Grasa";
      case FastingPhase.autophagy:
        return "Autofagia Activa";
      case FastingPhase.survival:
        return "Regeneración Celular";
    }
  }

  /// COMUNICACIÓN SEMÁNTICA DE ALERTA
  String? get metabolicAlert {
    if (nearSleepWarning && !isActive) {
      return "CIERRE DE VENTANA OBLIGATORIO: < 3H PARA REPARACIÓN";
    }
    return null;
  }

  String get nextMilestoneLabel {
    if (isActive) {
      if (duration.inHours < 12) {
        return "SIGUIENTE ETAPA: DESCENSO DE INSULINA (12H)";
      }
      if (duration.inHours < 18) return "SIGUIENTE ETAPA: QUEMA DE GRASA (18H)";
      if (duration.inHours < 24) return "SIGUIENTE ETAPA: AUTOFAGIA (24H)";
      return "FASE DE REGENERACIÓN PROFUNDA";
    } else {
      return nearSleepWarning
          ? "ATENCIÓN: RIESGO DE INSULINA NOCTURNA"
          : "META: INICIAR AYUNO";
    }
  }

  Duration get timeRemainingForNextMilestone {
    if (isActive) {
      if (duration.inHours < 12) return const Duration(hours: 12) - duration;
      if (duration.inHours < 18) return const Duration(hours: 18) - duration;
      if (duration.inHours < 24) return const Duration(hours: 24) - duration;
      return Duration.zero;
    } else {
      final remaining = const Duration(hours: 8) - duration;
      return remaining.isNegative ? Duration.zero : remaining;
    }
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
