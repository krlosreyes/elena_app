// SPEC-261: sesión del Protocolo de Consumo Consciente.
//
// Value object inmutable que representa una "ocasión" de consumo y su
// acompañamiento en cuatro fases (Antes / Durante / Después / Recuperación).
// No persiste ni observa streams: el notifier lo hace evolucionar.
//
// Filosofía (reducción de daño): el objeto no juzga. Expone el estado y un
// factor de mitigación transparente que la capa de Score puede usar para
// reflejar que gestionar bien el consumo cuesta menos que beber sin plan.

import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';

/// Fase del protocolo. Avanza de forma lineal, salvo `inactive`.
enum ConsumptionPhase { inactive, antes, durante, despues, recuperacion }

class ConsumptionSession {
  final ConsumptionPhase phase;

  /// Presupuesto objetivo de la noche en Unidades Estándar de Alcohol.
  final double budgetStandardUnits;

  /// Consumos registrados en esta sesión.
  final List<DrinkEvent> drinks;

  /// Hora objetivo del último trago (para proteger el sueño). Null hasta
  /// que se calcula desde la hora de dormir del usuario.
  final DateTime? lastCallTarget;

  // ── Acciones de mitigación (Fase A y D) ─────────────────────────────
  final bool hydratedBefore;
  final bool ateBefore;
  final bool recoveryFastPlanned;

  const ConsumptionSession({
    this.phase = ConsumptionPhase.inactive,
    this.budgetStandardUnits = 4.0,
    this.drinks = const [],
    this.lastCallTarget,
    this.hydratedBefore = false,
    this.ateBefore = false,
    this.recoveryFastPlanned = false,
  });

  bool get isActive => phase != ConsumptionPhase.inactive;

  /// Gramos de alcohol acumulados en la sesión.
  double get totalGrams => drinks.fold<double>(0, (sum, d) => sum + d.grams);

  /// UEA acumuladas.
  double get totalStandardUnits => totalGrams / 10.0;

  /// Cuántas UEA quedan dentro del presupuesto (puede ser negativo).
  double get remainingStandardUnits => budgetStandardUnits - totalStandardUnits;

  bool get budgetExceeded => totalStandardUnits > budgetStandardUnits;

  /// Proporción de tragos acompañados de agua (regla 1:1). 0..1.
  double get hydrationRatio {
    if (drinks.isEmpty) return 0;
    final withWater = drinks.where((d) => d.waterChaser).length;
    return withWater / drinks.length;
  }

  /// Factor de mitigación transparente en [0, maxMitigation].
  ///
  /// Combina las acciones de reducción de daño. NO llega nunca a 1: por
  /// honestidad científica el alcohol siempre deja huella. El tope es un
  /// parámetro a calibrar, no un valor final.
  static const double maxMitigation = 0.6;

  double get mitigationFactor {
    double m = 0;
    m += hydratedBefore ? 0.15 : 0;
    m += ateBefore ? 0.15 : 0;
    m += recoveryFastPlanned ? 0.15 : 0;
    m += 0.15 * hydrationRatio; // regla 1:1 en vivo
    m += (!budgetExceeded && drinks.isNotEmpty) ? 0.10 : 0;
    return m.clamp(0.0, maxMitigation);
  }

  ConsumptionSession copyWith({
    ConsumptionPhase? phase,
    double? budgetStandardUnits,
    List<DrinkEvent>? drinks,
    DateTime? lastCallTarget,
    bool? hydratedBefore,
    bool? ateBefore,
    bool? recoveryFastPlanned,
  }) {
    return ConsumptionSession(
      phase: phase ?? this.phase,
      budgetStandardUnits: budgetStandardUnits ?? this.budgetStandardUnits,
      drinks: drinks ?? this.drinks,
      lastCallTarget: lastCallTarget ?? this.lastCallTarget,
      hydratedBefore: hydratedBefore ?? this.hydratedBefore,
      ateBefore: ateBefore ?? this.ateBefore,
      recoveryFastPlanned: recoveryFastPlanned ?? this.recoveryFastPlanned,
    );
  }
}
