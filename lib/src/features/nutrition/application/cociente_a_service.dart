// SPEC-137: cálculo del Cociente A diario.
//
// El Cociente A es la métrica visible al usuario y el insumo primario
// del bloque Nutrición del IMR (peso 70% del nutritionScoreRaw,
// §RF-137-05).
//
// Definición: porcentaje de platos REGISTRADOS hoy que son A-dominantes
// (`MealRatio.isADominant == true`). Es decir, Todo A + 3 a 1 + 2 a 1
// cuentan; 1 a 1 y Todo E no.
//
// CRÍTICO — el denominador es el conteo de platos REGISTRADOS, no el
// target del protocolo. Esto evita penalizar al usuario por no registrar.
// Si el target del protocolo es 2 y el usuario registró solo 1 plato
// A-dominante, el Cociente A del día es 100%, no 50%. El target sirve
// para copy informativo en la tarjeta de Hoy ("Llevas 1 de 2"), no
// para el score.
//
// Casos de borde documentados en los tests.

import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// Servicio puro que calcula el Cociente A de un día.
class CocienteAService {
  const CocienteAService();

  /// Calcula el Cociente A (0.0 – 1.0) sobre la lista de logs del día.
  ///
  /// Si la lista está vacía retorna 0.0 — la falta de registro NO
  /// penaliza el cálculo, pero tampoco aporta. El score nutricional
  /// completo se ve afectado por la window adherence (otro 30%) según
  /// §RF-137-05; aquí solo computamos la componente A.
  ///
  /// El parámetro `includeCheatDay` controla si los logs marcados como
  /// día de permitidos cuentan o no. En el cálculo diario (Hoy) sí
  /// cuentan (el usuario quiere ver el reflejo de lo que comió). Para
  /// `weeklyAdherence`, los días completos marcados como cheat se
  /// excluyen — eso vive en otro servicio.
  double calculate(
    List<NutritionLog> todayLogs, {
    bool includeCheatDay = true,
  }) {
    final filtered = includeCheatDay
        ? todayLogs
        : todayLogs.where((l) => !l.isCheatDay).toList();

    if (filtered.isEmpty) return 0.0;

    final aDominantCount = filtered.where((l) => l.ratio.isADominant).length;
    return (aDominantCount / filtered.length).clamp(0.0, 1.0);
  }

  /// Conteo de platos A-dominantes para mostrar en copy ("2 de 3 platos
  /// A-dominantes"). Util para la tarjeta de Hoy.
  int aDominantCount(List<NutritionLog> todayLogs) =>
      todayLogs.where((l) => l.ratio.isADominant).length;

  /// True si el día tiene al menos un log marcado como cheat day. Si
  /// hay platos del día con isCheatDay=true, asumimos que el día
  /// completo está bajo el régimen del cheat day (RF-137-07: el toggle
  /// se activa para el día entero).
  bool isCheatDay(List<NutritionLog> todayLogs) =>
      todayLogs.any((l) => l.isCheatDay);
}
