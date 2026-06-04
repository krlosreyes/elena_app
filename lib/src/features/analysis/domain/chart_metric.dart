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
  fastingDays,
  nutritionAPct,
  hydrationPct,
  exerciseMin,
  sleepHours,
}
