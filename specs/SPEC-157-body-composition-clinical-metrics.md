# SPEC-157 — BodyCompositionTrendChart: WHTR + Masa magra

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Extensión de SPEC-152 — agrega 2 métricas clínicas relevantes
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 30-45 min
**Marco normativo:** `CONSTITUTION.md`. Extiende SPEC-152 sin romper API existente.

---

## 1. Contexto

Auditoría 2026-06-02 identificó dos métricas computadas que `BiometricCheckIn` ya expone vía getters pero la app no visualiza:

- **WHTR** (Waist-to-Height Ratio) — estándar internacional de riesgo cardiometabólico. ≤0.50 saludable, >0.50 riesgo aumentado, >0.56 riesgo metabólico alto (Ashwell 2012, NHS, OMS).
- **Masa magra** (kg) — mejor predictor del estado metabólico que el peso bruto. Su preservación durante pérdida de peso es la diferencia entre cambio sostenible y rebote.

`BiometricCheckIn` ya tiene los getters `whtr(heightCm)` y `leanMass`. SPEC-152 solo expuso peso/cintura/%grasa. Esta SPEC agrega los dos restantes al mismo widget.

## 2. Decisión de diseño

### 2.1 — Agregar dos tabs al selector existente

El widget actual tiene 3 tabs (Peso / Cintura / Grasa). Pasa a 5 con:

```
[Peso] [Cintura] [Grasa] [WHTR] [Masa magra]   30d 60d 90d
```

Si la fila no entra en la pantalla, se hace `SingleChildScrollView` horizontal — patrón Apple Health.

### 2.2 — `BodyCompositionMetric` extendido

Dos nuevos casos en el enum:

- `BodyCompositionMetric.whtr` — unidad "ratio", color índigo, formato 2 decimales.
- `BodyCompositionMetric.leanMassKg` — unidad "kg", color teal claro, formato 1 decimal.

### 2.3 — Cambio de firma de `selectValue`

Para WHTR necesitamos `userHeightCm` (no está en `BiometricCheckIn`). Cambiamos la firma a:

```dart
double? selectValue(BiometricCheckIn ci, {double? heightCm});
```

Las 3 métricas existentes ignoran `heightCm`. WHTR lo requiere y retorna null si es null. Masa magra no lo necesita.

### 2.4 — Widget watchea `currentUserStreamProvider`

Para tener acceso a `user.height` que pasamos a `selectValue`. Si el user es null o height es 0, las tabs WHTR muestran empty state.

### 2.5 — Empty state específico

Para WHTR y Masa magra, agregamos copy específico al `emptyStateMessage` del enum:

- WHTR: "Registrá tu cintura para ver tu índice cintura/altura."
- Masa magra: "Registrá tu % de grasa para ver la masa magra."

### 2.6 — Indicador visual de zona en WHTR (opcional MVP)

WHTR tiene zonas clínicas. **Decidimos NO mostrar zonas en MVP** para mantener consistencia visual con las otras métricas (sin bandas, solo línea). Si emerge demanda futura, SPEC-157.1 con bandas de color (rojo/ámbar/verde).

## 3. Cambios técnicos

### 3.1 — `body_composition_metric.dart`

- Agregar `whtr` y `leanMassKg` al enum.
- Extender `label`, `unit`, `selectValue` (con `heightCm` opcional), `accentColor`, `emptyStateMessage`, `formatValue`, `deltaCopyFor`.

### 3.2 — `body_composition_trend_chart.dart`

- `ConsumerStatefulWidget` watchea `currentUserStreamProvider` (ya es Consumer).
- Pasa `user?.height` a `_metric.selectValue(ci, heightCm: ...)`.
- El `Row` de tabs queda envuelto en `SingleChildScrollView(scrollDirection: Axis.horizontal)` para acomodar 5 tabs.

### 3.3 — Tests

Extender `body_composition_metric_test.dart` con:
- `whtr.selectValue` retorna `cintura / heightCm` cuando ambos presentes.
- `whtr.selectValue` retorna null si height es null o cintura es null.
- `leanMassKg.selectValue` retorna `weight * (1 - bf/100)` cuando bf presente.
- `leanMassKg.selectValue` retorna null si bf es null.
- Labels y unidades nuevos.

## 4. Criterios de aceptación

1. El widget muestra 5 tabs en lugar de 3.
2. Cada tab nueva (WHTR, Masa magra) funciona con datos suficientes.
3. Cuando falta data (cintura para WHTR, %grasa para masa magra), empty state específico.
4. La fila de tabs hace scroll horizontal si no entra en pantalla.
5. Tests cubren los selectores nuevos y sus null cases.

### 4.1 — Sobre tests

Pure Dart. Sin widget test.

## 5. Out of scope

- **Bandas de color por zona en WHTR:** SPEC-157.1 si emerge demanda.
- **WHR** (Waist-to-Hip Ratio) — requiere registrar cadera, no está en `BiometricCheckIn` actualmente.
- **Indicador clínico textual** ("Estás en zona X") debajo del valor — útil pero out of MVP.

## 6. Rollout

Sin breaking changes — `selectValue` con `heightCm` opcional no rompe callers existentes.

## 7. Changelog

### v1.0 — 2026-06-02

Aprovecha getters ya existentes en `BiometricCheckIn` (`whtr`, `leanMass`) para exponer dos métricas clínicas estándar. Cuarta entrega de Ola 2 hoy.
