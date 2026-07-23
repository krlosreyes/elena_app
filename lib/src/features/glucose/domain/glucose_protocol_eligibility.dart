// Módulo "Tu Glucosa" — gate de activación automática del protocolo
// (propuesta §5.2 y §6.1). Mismo patrón que
// streak/domain/fasting_eligibility.dart: factory pura sobre
// `UserModel.pathologies` — NO se agrega ningún campo nuevo a
// UserModel (@freezed) para detectar la condición, se reutiliza el
// campo que el onboarding ya captura.
//
// Regla de negocio R1 (propuesta §11): protocolActive = true si y solo
// si pathologies contiene "Prediabetes" o "Diabetes T2" Y NO contiene
// "Diabetes con insulina o sulfonilureas" (ese subgrupo ya tiene su
// propio gate de riesgo en FastingEligibility — diabetes tipo 1 o
// insulinodependiente queda fuera de alcance de esta propuesta,
// §5.2, requiere supervisión médica que esta app no reemplaza).

import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart'
    show FastingPathologyFlags;
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Valores de `pathologies` relevantes para el protocolo de glucosa.
/// Ya existían como strings sueltos en `_pathologyOptions` de
/// onboarding_screen.dart ("Prediabetes", "Diabetes T2") — se
/// centralizan acá como constantes para que ambos lados (onboarding y
/// este gate) usen la misma fuente de verdad y no diverjan por un
/// typo.
class GlucosePathologyFlags {
  GlucosePathologyFlags._();

  static const String prediabetes = 'Prediabetes';
  static const String diabetesT2 = 'Diabetes T2';
}

class GlucoseProtocolEligibility {
  /// true si el protocolo debe activarse automáticamente.
  final bool eligible;

  /// Motivo legible, para el copy de la pantalla de consentimiento.
  final String? reason;

  const GlucoseProtocolEligibility({required this.eligible, this.reason});

  factory GlucoseProtocolEligibility.assess(UserModel user) {
    final pathologies = user.pathologies;
    bool has(String flag) => pathologies.contains(flag);

    final hasInsulinDiabetes = has(FastingPathologyFlags.diabetesMedicada);
    final hasPrediabetesOrT2 = has(GlucosePathologyFlags.prediabetes) ||
        has(GlucosePathologyFlags.diabetesT2);

    // Diabetes tipo 1 / insulinodependiente: fuera de alcance (§5.2) —
    // el riesgo de hipoglucemia severa con insulina requiere un
    // protocolo supervisado por un profesional, no automonitoreo
    // guiado por una app de hábitos.
    if (hasInsulinDiabetes) {
      return const GlucoseProtocolEligibility(
        eligible: false,
        reason:
            'Con medicación para la diabetes (insulina o sulfonilureas), el seguimiento de glucosa debe hacerse junto con tu médico — fuera de lo que esta función puede acompañar de forma segura.',
      );
    }

    if (hasPrediabetesOrT2) {
      return const GlucoseProtocolEligibility(
        eligible: true,
        reason:
            'Detectamos que declaraste prediabetes o diabetes tipo 2. Podemos ayudarte a monitorear tu glucosa y entender cómo tus hábitos la afectan.',
      );
    }

    return const GlucoseProtocolEligibility(eligible: false);
  }
}
