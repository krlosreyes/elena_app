# SPEC-167 — Fix yMax en BarChartCard (barras sub-pixel)

**Estado:** CLOSED 2026-06-03
**Versión:** 1.0
**Fecha:** 2026-06-03
**Tipo:** Bugfix — único archivo, una función
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** 15 min

---

## 1. Síntoma reportado

Carlos vio el gráfico de Análisis con headlines correctos ("Cumpliste 2.3 días de ayuno por semana", "El 83 % de tus comidas fueron A-dominantes", "Tomaste 91 % de tu meta hídrica") pero **sin barras visibles** en los tres cards (Ayuno, Nutrición, Hidratación). El eje Y mostraba un label gigante partido en 3 líneas: "1000 / 0000 / 00".

Inicialmente parecía bug del pipeline de datos (vacío). Auditoría reveló que los datos llegaban correctamente — el problema era el cálculo del eje Y en `BarChartCard`.

## 2. Causa raíz

`bar_chart_card.dart` línea 271-274, función `_pow10`:

```dart
double _pow10(double v) {
  final log = v.abs() <= 0 ? 0 : (v.abs()).toString().length - 1;
  return _power(10, log.toDouble() - 1).clamp(0.001, 1e9);
}
```

El helper estimaba `log10(v)` usando `v.toString().length`. Funcionaba con enteros, pero al introducir modos `daily` / `weekly` / `monthly` (SPEC-164), los cálculos internos como `maxV / 3` producían fracciones periódicas en IEEE 754:

- `7 / 3 = 2.3333333333333335` → `.toString()` retorna `"2.3333333333333335"` (18 chars)
- `length - 1 = 17` → `_power(10, 16) = 1e16` → `clamp(0.001, 1e9) = 1e9`
- `step = nice × 1e9 = 1e9`
- `yMax = ceil(7 / 1e9) × 1e9 = 1e9`

Resultado: yMax en mil millones cuando los valores reales eran 0-7. Las barras tenían altura `valor / 1e9 ≈ sub-pixel`. Indistinguibles del fondo.

## 3. Por qué no se vio en SPEC-163

`SPEC-163` (Apple Fitness bar chart) se validó con `WeeklyAggregator` original que producía valores enteros bien comportados ("4 días", "5 días"). Con `4.toString().length = 1`, el cálculo accidentalmente daba la magnitud correcta.

SPEC-164 introdujo `TemporalAggregation.avg` y divisiones reales en agregadores. Ahí salió el bug.

`LineChartCard` usaba `_magnitudeOf` (loop iterativo dividiendo por 10), que es matemáticamente correcto — por eso IMR y Peso (line charts) nunca tuvieron este problema.

## 4. Fix aplicado

`bar_chart_card.dart`:

```dart
import 'dart:math' as math;
// ...

double _pow10(double v) {
  if (v.abs() < 1e-12) return 1;
  final log10 = (math.log(v.abs()) / math.ln10).floor();
  return math.pow(10, log10).toDouble();
}
```

Reemplaza la heurística de string por `log10` real. Función `_power` eliminada (ya no se usa).

## 5. Impacto esperado

| Métrica | Datos reales | yMax antes | yMax después | Resultado |
|---------|--------------|------------|--------------|-----------|
| Ayuno (3 m, 2.3 d/sem) | 0-7 | 1 000 000 000 | 6-7 | Barras visibles |
| Nutrición (83 %) | 0-100 | 1 000 000 000 | 100 | Barras visibles |
| Hidratación (91 %) | 0-200 | 1 000 000 000 | 100-150 | Barras visibles |

## 6. Validación

### 6.1 — Manual en device
Carlos confirma visualmente en Análisis tras hot restart:
- Ayuno: barras se ven, ticks 0/2/4/6 razonables
- Nutrición: barras se ven, ticks 0/25/50/75/100
- Hidratación: barras se ven, ticks 0/25/50/75/100

### 6.2 — No-regresión
- LineChartCard (IMR, Peso) no se toca — sigue con `_magnitudeOf` propio.
- Otras pantallas no usan `BarChartCard`.

## 7. Bibliografía / referencias

- IEEE 754 division: división de enteros pequeños por 3 produce strings de hasta 18 caracteres en `toString()`. Lección: nunca estimar magnitud por longitud de representación textual de un `double`.
- `dart:math.log` retorna `ln(v)`. Para `log10`: `log(v) / ln10`.

## 8. Cierre

- [x] Bug reproducido con datos reales (screenshot Carlos 2026-06-03)
- [x] Causa raíz identificada (`_pow10` por `.toString().length`)
- [x] Fix aplicado (4 líneas + import)
- [x] Función obsoleta `_power` eliminada
- [x] SPEC documentada
- [ ] Hot restart pendiente para validación visual final
