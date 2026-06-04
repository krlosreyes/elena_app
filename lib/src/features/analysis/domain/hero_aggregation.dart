// SPEC-168.1 (2026-06-03): tipo de agregación del bloque hero que
// aparece arriba del chart (label + valor grande + unit + fecha-range).
//
// Apple Health/Fitness usa siempre uno de cuatro:
//   - PROMEDIO (avg): "PROMEDIO 177 g"      → métricas continuas, %, h, kg.
//   - TOTAL    (sum): "TOTAL 35 d"          → conteo, eventos cumplidos.
//   - ÚLTIMO   (last): "ÚLTIMO 76.4 kg"     → snapshot puntual (peso reciente).
//   - MÁXIMO   (max): "MÁXIMO 240 g"        → uso raro, picos.
//
// Pure Dart — sin Flutter ni Riverpod.

enum HeroAggregation { avg, sum, last, max }

/// Label en MAYÚSCULAS que se renderiza arriba del valor numérico.
String labelForHeroAggregation(HeroAggregation a) {
  switch (a) {
    case HeroAggregation.avg:
      return 'PROMEDIO';
    case HeroAggregation.sum:
      return 'TOTAL';
    case HeroAggregation.last:
      return 'ÚLTIMO';
    case HeroAggregation.max:
      return 'MÁXIMO';
  }
}
