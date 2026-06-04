// SPEC-168.0.D (2026-06-03): identificadores de las métricas que se
// renderizan en los charts del Análisis. Sirven como llave del provider
// `goalForChartProvider` para mapear cada chart a su goal asociado y a
// la unidad correcta de visualización.
//
// Pure Dart — sin Flutter ni Riverpod. No tiene métodos: es un enum
// referencial estable. Si se agrega un nuevo chart, agregar aquí.

enum ChartMetric {
  imr,
  weight,
  // SPEC-168.4.2 (2026-06-03): % de grasa corporal del usuario. La
  // serie viene del biometricRepository (`bodyFatPercentage` opcional
  // en BiometricCheckIn). Los check-ins sin BF se filtran.
  bodyFatPct,
  // SPEC-168.5.2 (2026-06-03): Ayuno ahora se mide en horas de ayuno
  // (avg), no en días cumplidos. La línea de objetivo es el targetHours
  // del protocolo activo (16/18/20). El goal `fastingDaysPerWeek` del
  // usuario sigue existiendo en el sistema de goals (Perfil), pero ya
  // no alimenta este chart.
  fastingHours,
  nutritionAPct,
  // SPEC-168.5.3 (2026-06-03): Hidratación pasa a litros por día. El
  // target es el goal del usuario hydrationLitersPerDay tal cual, sin
  // conversion a %.
  hydrationLiters,
  exerciseMin,
  sleepHours,
}
