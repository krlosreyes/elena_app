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
  bodyFatPct;

  /// Label corto para mostrar en la tab.
  String get label {
    switch (this) {
      case BodyCompositionMetric.weight:
        return 'Peso';
      case BodyCompositionMetric.waistCm:
        return 'Cintura';
      case BodyCompositionMetric.bodyFatPct:
        return 'Grasa';
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
    }
  }

  /// Extrae el valor de la métrica para un check-in dado. Null si
  /// la métrica no se registró ese día.
  double? selectValue(BiometricCheckIn ci) {
    switch (this) {
      case BodyCompositionMetric.weight:
        return ci.weight;
      case BodyCompositionMetric.waistCm:
        return ci.waistCircumference;
      case BodyCompositionMetric.bodyFatPct:
        return ci.bodyFatPercentage;
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
    }
  }

  /// Formatea el valor con la precisión adecuada (peso/cintura: 1 dec,
  /// grasa: 1 dec).
  String formatValue(double value) {
    return value.toStringAsFixed(1);
  }

  /// Para el copy del delta: "ganaste / perdiste / subió / bajó".
  /// SPEC-152 §2.4: copy NEUTRO, sin valoración moral. Color es el
  /// que comunica intención (ámbar = sube, verde = baja).
  String deltaCopyFor(double signedDelta) {
    if (signedDelta == 0) return 'Sin cambios';
    final abs = signedDelta.abs();
    final formatted = abs.toStringAsFixed(1);
    final sign = signedDelta < 0 ? 'menos' : 'más';
    return '$formatted $unit $sign';
  }
}
