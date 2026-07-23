// Módulo "Tu Glucosa" — clasificación de una lectura según los
// umbrales de la ADA (propuesta §12.1, fuente primaria: ADA, Standards
// of Care in Diabetes—2025, y AAFP sobre IFG/IGT). Función pura,
// testeable, sin dependencias de Flutter/Riverpod — mismo patrón que
// FastingEligibility / StreakEngine.
//
// Riesgo explícito que esta clase debe respetar (propuesta §14): NO es
// un diagnóstico. `label` nunca dice "tenés diabetes" — dice "alto,
// considerá consultar a tu médico". La diferencia de tono es
// deliberada y no debe relajarse en ninguna pantalla que consuma esto.

import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';

enum GlucoseClassification { bajo, enRango, elevado, alto, sinUmbral }

extension GlucoseClassificationLabel on GlucoseClassification {
  /// Texto corto para chips/badges — nunca usa la palabra "diagnóstico".
  String get label {
    switch (this) {
      case GlucoseClassification.bajo:
        return 'Bajo';
      case GlucoseClassification.enRango:
        return 'En rango';
      case GlucoseClassification.elevado:
        return 'Elevado';
      case GlucoseClassification.alto:
        return 'Alto — considerá consultar a tu médico';
      case GlucoseClassification.sinUmbral:
        return '';
    }
  }
}

class GlucoseClassifier {
  GlucoseClassifier._();

  /// Clasifica [valueMgDl] según [context], siguiendo exactamente los
  /// umbrales ADA de la propuesta §12.1:
  ///   Ayunas:        <100 rango, 100-125 elevado, ≥126 alto, <70 bajo.
  ///   Postprandial(2h): <140 rango, 140-199 elevado, ≥200 alto.
  ///   Antes de dormir: sin umbral diagnóstico propio de la ADA — se
  ///     devuelve `sinUmbral` a propósito, NUNCA se inventa un criterio
  ///     clínico que no existe (propuesta §12.1, nota explícita).
  ///   Otros contextos (antesDeComer, postprandial1h, otro): igual que
  ///     antes de dormir — no hay un umbral ADA específico para esos
  ///     momentos, se presenta como dato de tendencia sin etiqueta.
  static GlucoseClassification classify(
    int valueMgDl,
    GlucoseReadingContext context,
  ) {
    switch (context) {
      case GlucoseReadingContext.ayunas:
        if (valueMgDl < 70) return GlucoseClassification.bajo;
        if (valueMgDl < 100) return GlucoseClassification.enRango;
        if (valueMgDl <= 125) return GlucoseClassification.elevado;
        return GlucoseClassification.alto;
      case GlucoseReadingContext.postprandial2h:
        if (valueMgDl < 70) return GlucoseClassification.bajo;
        if (valueMgDl < 140) return GlucoseClassification.enRango;
        if (valueMgDl <= 199) return GlucoseClassification.elevado;
        return GlucoseClassification.alto;
      case GlucoseReadingContext.antesDeComer:
      case GlucoseReadingContext.postprandial1h:
      case GlucoseReadingContext.antesDeDormir:
      case GlucoseReadingContext.otro:
        return GlucoseClassification.sinUmbral;
    }
  }

  /// R9: valores fuera de rango fisiológico plausible que ameritan
  /// confirmación explícita antes de guardar y, si corresponde, un
  /// aviso (sin alarmismo) de contactar a un profesional de salud.
  /// <70 se marca como posible hipoglucemia; >250 como posible
  /// hiperglucemia significativa — umbrales de la propuesta §9.1/R9,
  /// no diagnósticos.
  static bool warrantsMedicalAdviceNote(int valueMgDl) =>
      valueMgDl < 70 || valueMgDl > 250;

  /// R9: fuera del rango fisiológico plausible de un glucómetro
  /// doméstico — pide confirmación antes de persistir.
  static bool isOutsidePlausibleRange(int valueMgDl) =>
      valueMgDl < kGlucoseMinPlausibleMgDl ||
      valueMgDl > kGlucoseMaxPlausibleMgDl;
}
