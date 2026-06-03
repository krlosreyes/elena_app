// SPEC-152: enum de las métricas biométricas que el widget de tendencia
// puede graficar. Una por tab. El widget rota entre ellas con un selector
// arriba del chart.
//
// El acceso al valor numérico de cada métrica se expone como `selectValue`
// para que el chart no tenga que conocer la forma interna del
// BiometricCheckIn — desacopla domain de UI.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';

enum BodyCompositionMetric {
  weight,
  waistCm,
  bodyFatPct,
  // SPEC-157: métricas clínicas computadas que ya viven como getters
  // en BiometricCheckIn pero no se visualizaban.
  whtr,
  leanMassKg;

  /// Label corto para mostrar en la tab.
  String get label {
    switch (this) {
      case BodyCompositionMetric.weight:
        return 'Peso';
      case BodyCompositionMetric.waistCm:
        return 'Cintura';
      case BodyCompositionMetric.bodyFatPct:
        return 'Grasa';
      case BodyCompositionMetric.whtr:
        return 'WHTR';
      case BodyCompositionMetric.leanMassKg:
        return 'Masa magra';
    }
  }

  /// Unidad para acompañar el valor grande.
  String get unit {
    switch (this) {
      case BodyCompositionMetric.weight:
        return 'kg';
      case BodyCompositionMetric.waistCm:
        return 'cm';
      case BodyCompositionMetric.bodyFatPct:
        return '%';
      case BodyCompositionMetric.whtr:
        return ''; // ratio adimensional
      case BodyCompositionMetric.leanMassKg:
        return 'kg';
    }
  }

  /// Extrae el valor de la métrica para un check-in dado. Null si
  /// la métrica no se registró ese día (o si falta data dependiente
  /// como `heightCm` para WHTR).
  ///
  /// SPEC-157: `heightCm` solo lo usa WHTR. Las otras métricas lo
  /// ignoran. Pasamos opcional para no romper llamadas existentes.
  double? selectValue(BiometricCheckIn ci, {double? heightCm}) {
    switch (this) {
      case BodyCompositionMetric.weight:
        return ci.weight;
      case BodyCompositionMetric.waistCm:
        return ci.waistCircumference;
      case BodyCompositionMetric.bodyFatPct:
        return ci.bodyFatPercentage;
      case BodyCompositionMetric.whtr:
        if (heightCm == null || heightCm <= 0) return null;
        if (ci.waistCircumference == null) return null;
        return ci.waistCircumference! / heightCm;
      case BodyCompositionMetric.leanMassKg:
        return ci.leanMass;
    }
  }

  /// Color de acento del trazo del chart cuando esta métrica está
  /// seleccionada. Coherente con el theme de la app.
  Color get accentColor {
    switch (this) {
      case BodyCompositionMetric.weight:
        return AppColors.metabolicGreen;
      case BodyCompositionMetric.waistCm:
        return const Color(0xFF60A5FA); // azul claro
      case BodyCompositionMetric.bodyFatPct:
        return const Color(0xFFF59E0B); // ámbar
      case BodyCompositionMetric.whtr:
        return const Color(0xFFA78BFA); // violeta
      case BodyCompositionMetric.leanMassKg:
        return const Color(0xFF2DD4BF); // teal claro
    }
  }

  /// Copy del empty state cuando esta métrica no tiene datos.
  String get emptyStateMessage {
    switch (this) {
      case BodyCompositionMetric.weight:
        return 'Registrá tu peso para ver la tendencia.';
      case BodyCompositionMetric.waistCm:
        return 'Registrá tu cintura para ver la tendencia.';
      case BodyCompositionMetric.bodyFatPct:
        return 'Registrá tu % de grasa para ver la tendencia.';
      case BodyCompositionMetric.whtr:
        return 'Registrá tu cintura para ver tu índice cintura/altura.';
      case BodyCompositionMetric.leanMassKg:
        return 'Registrá tu % de grasa para ver la masa magra.';
    }
  }

  /// Formatea el valor con la precisión adecuada.
  /// WHTR usa 2 decimales (rango típico 0.40–0.65); el resto usa 1.
  String formatValue(double value) {
    if (this == BodyCompositionMetric.whtr) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(1);
  }

  /// Para el copy del delta: "1.2 kg menos", "0.02 más", etc.
  /// SPEC-152 §2.4: copy NEUTRO, sin valoración moral. Color es el
  /// que comunica intención (ámbar = sube, verde = baja).
  String deltaCopyFor(double signedDelta) {
    if (signedDelta == 0) return 'Sin cambios';
    final abs = signedDelta.abs();
    final formatted = this == BodyCompositionMetric.whtr
        ? abs.toStringAsFixed(2)
        : abs.toStringAsFixed(1);
    final sign = signedDelta < 0 ? 'menos' : 'más';
    if (unit.isEmpty) {
      return '$formatted $sign';
    }
    return '$formatted $unit $sign';
  }
}
