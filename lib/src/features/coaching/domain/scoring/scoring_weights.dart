// SPEC-194 Anexo + Adenda circadiana (v1.1) — pesos y constantes del scorer.
//
// ENGINEERING JUDGMENT: punto de partida defendible, recalibrar con la
// telemetría de SPEC-193 (tasa de acciones completadas por tipo/fase).
// La Adenda circadiana SUSTITUYE los pesos macro del Anexo base.
//
// Dart puro (CONSTITUTION §3.1).

// ── Pesos macro (Adenda §2, v1.1) ───────────────────────────────────────────
// circadianImpact (0.30) es el peso positivo más alto: espejo del 0.38 que el
// circadiano tiene en el bloque de conducta del IMR ("el eje", SPEC-70.5).
const double kWUrgency = 0.28;
const double kWRelevance = 0.27;
const double kWCircadian = 0.30;
const double kWConfidence = 0.15;
const double kWFatigue = 0.12;

// ── circadianImpact por situación (Adenda §3 + §8) ──────────────────────────
// Tabla fase × tipo-de-acción que cada candidato circadiano hereda como su
// `circadianImpact` [0,1]. Citas en CIRCADIAN_BIBLIOGRAPHY.
const double kCircProtectBoundary =
    1.00; // proteger 21:30 (mayor daño evitable)
const double kCircEarlyMealBonus = 0.85; // capturar bonus de comer temprano
const double kCircProtectSleep = 0.80; // proteger inicio de sueño
const double kCircPhaseAlignedActivity = 0.75; // actividad en su fase óptima
const double kCircNeutral = 0.30; // acción neutra respecto a la fase
const double kCircCounterPhase =
    0.00; // contra-fase (no se genera como positiva)

// ── Bases de urgencia por tipo (Anexo §2.1) ─────────────────────────────────
const double kUrgencyDeadline = 0.80;
const double kUrgencyPhase = 0.55;
const double kUrgencyHabit = 0.30;
const double kUrgencyProtocol = 0.25;

/// Ventana de aviso (min) para escalar la proximidad de un deadline duro.
const int kUrgencyWindowMin = 120;

// ── Relevancia (Anexo §2.2) ─────────────────────────────────────────────────
const double kRelPillarFit = 0.50;
const double kRelActionability = 0.30;
const double kRelGoal = 0.20;

const double kPillarFitWeakest = 1.0;
const double kPillarFitSecond = 0.6;
const double kPillarFitOther = 0.3;
const double kActionableYes = 1.0;
const double kActionableNo = 0.2;
const double kGoalAligned = 1.0;
const double kGoalUnaligned = 0.5;

// ── Fatiga (Anexo §2.4) ─────────────────────────────────────────────────────
const double kFatiguePerIgnore = 0.34;
const double kFatigueRepeatToday = 0.50;

// ── Selección (Anexo §3) ────────────────────────────────────────────────────
const double kSecondaryThreshold = 0.55;
const double kHardOverrideUrgency = 0.90;
