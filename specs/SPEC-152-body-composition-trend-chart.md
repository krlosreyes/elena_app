# SPEC-152 — BodyCompositionTrendChart: tendencia biométrica en Análisis

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Primera entrega de Ola 2 — resuelve deuda "Análisis vacía"
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 1-2 sesiones
**Marco normativo:** `CONSTITUTION.md`. Consume datos persistidos por SPEC-143.

---

## 1. Contexto

Durante validación del 2026-06-02, Carlos confirmó que la pantalla Análisis no muestra biometría. SPEC-143 cerrada hace meses persiste peso/cintura/cuello/%grasa correctamente — la deuda es solo de visualización. Esta SPEC añade el primer widget visible de Ola 2 que **convierte a Elena en un coach que muestra tu cambio real**, no solo registra.

El widget vive en `analysis_screen.dart` debajo del `PillarsHeatmap` existente.

## 2. Decisión de diseño UX

### 2.1 — Una métrica a la vez, no superposición

Peso (60-100 kg), cintura (70-110 cm) y %grasa (15-35%) tienen escalas radicalmente distintas. Superponerlas en un mismo eje Y normaliza a porcentajes (confuso) o usa dos ejes Y (Apple los desaconseja por clutter visual). **Decisión:** tabs de selección de métrica + selector temporal independiente. Patrón visual Apple Health / Whoop.

### 2.2 — Layout del widget

```
┌──────────────────────────────────────────┐
│ COMPOSICIÓN CORPORAL                     │
│                                          │
│ [Peso] [Cintura] [Grasa]   30d 60d 90d  │ ← Tabs + selector
│                                          │
│   84.2 kg                                │ ← Valor actual grande
│   ▼ 2.4 kg en 30 días                    │ ← Delta + período
│                                          │
│   ┌────────────────────────────────┐    │
│   │  ╱╲                            │    │ ← Line chart simple
│   │ ╱  ╲___       ╱─               │    │
│   │       ╲──────╱                 │    │
│   └────────────────────────────────┘    │
│   30 días atrás            hoy           │
└──────────────────────────────────────────┘
```

### 2.3 — Empty state explícito por métrica

Cada métrica puede estar vacía independiente (ej: tiene peso pero no cintura). El empty state es por tab:
- "Registrá tu cintura para ver la tendencia" + CTA al `BiometricCheckInSheet`.

Si el período seleccionado tiene <2 puntos, mostrar mensaje "Necesitamos al menos 2 mediciones — registrate otra vez".

### 2.4 — Delta y signo

- **Peso/cintura:** ↓ verde indica baja (deseado), ↑ ámbar indica subida.
- **% grasa:** ↓ verde indica baja, ↑ ámbar indica subida.

No asumimos "menos es mejor siempre" — Carlos puede tener objetivo de subir masa. Pero como MVP el copy es neutro: "ganaste 1.2 kg" / "perdiste 1.2 kg" sin valoración moral. Color solo señaliza dirección.

## 3. Cambios técnicos

### 3.1 — Provider derivado del watchHistory

`lib/src/features/analysis/application/biometric_trend_provider.dart` (nuevo):

```dart
/// Stream de BiometricCheckIn de los últimos N días, ascendente por
/// fecha (más antiguo primero — orden de plot natural).
final biometricTrendProvider = StreamProvider.family
    .autoDispose<List<BiometricCheckIn>, int>((ref, days) {
  // family int = días de ventana (30/60/90)
  ...
});
```

Lee de `biometricRepositoryProvider.watchHistory(uid, limit: 365)` y filtra/ordena en client. No genera I/O extra — la query base ya está suscrita por `progress_notifier`.

### 3.2 — Value object `BodyCompositionMetric`

```dart
enum BodyCompositionMetric { weight, waistCm, bodyFatPct }

extension on BodyCompositionMetric {
  String get label;
  String get unit;
  double? selectValue(BiometricCheckIn ci);
  Color get accentColor;
}
```

### 3.3 — Widget `BodyCompositionTrendChart`

`lib/src/features/analysis/presentation/widgets/body_composition_trend_chart.dart` (nuevo):

- `ConsumerStatefulWidget` por el estado local (tab activo, período).
- Header con tabs (peso/cintura/grasa) + selector 30/60/90.
- Valor actual + delta calculado vs primer punto del período.
- Mini line chart con `CustomPaint` — single series, axis dinámico al rango de la métrica.
- Empty state según §2.3.

### 3.4 — `CustomPaint` mínimo

`BodyCompositionTrendPainter` extends `CustomPainter`:
- Eje Y dinámico: `min(values) - padding`, `max(values) + padding`.
- Eje X: índice del log (no fecha real — distribución uniforme, suficiente para MVP).
- Línea + puntos. Sin grid, sin labels — minimalismo.
- Color del accent según métrica seleccionada.

Si en una iteración futura se quiere fecha real en X, refactor a `fl_chart` (pubspec actualmente no lo tiene). MVP sin dependencia nueva.

### 3.5 — Integración en `analysis_screen.dart`

Después del `PillarsHeatmap`, antes del `INSIGHTS` header:

```dart
const SizedBox(height: 14),
const BodyCompositionTrendChart(),
const SizedBox(height: 18),
Padding(...header INSIGHTS...)
```

## 4. Criterios de aceptación

1. La pantalla Análisis muestra el widget debajo del heatmap de pilares.
2. Tabs Peso/Cintura/Grasa cambian la serie visualizada sin recargar la pantalla.
3. Selector 30/60/90 días filtra los puntos del chart.
4. Valor grande arriba refleja el último punto disponible.
5. Delta muestra diferencia vs primer punto del período + signo (↓ verde, ↑ ámbar) según baja/sube.
6. Si una métrica tiene 0 o 1 puntos en el período, empty state con CTA al check-in sheet.
7. Chart se renderiza sin errores con 2 puntos mínimo y con 90 puntos máximo.

### 4.1 — Sobre tests

- Test unitario de `BodyCompositionMetric` value object (selectValue por cada métrica).
- Test del provider derivado con `BiometricCheckIn` fake (orden + filtro por días).
- Test del cálculo de delta (primer vs último).
- **NO** widget test del CustomPaint — frágil y de bajo valor. Validación visual.

Validación visual: capturar el chart con 2, 5, 30 puntos en cada métrica.

## 5. Out of scope (explícito)

- **Fecha real en eje X:** MVP usa índice. Mejora futura si se justifica.
- **Comparativa antes/después con foto:** SPEC-148 (Ola 3).
- **Forecast / proyección:** fuera de scope total.
- **Múltiples métricas simultáneas:** rechazado en §2.1.
- **Persistir tab/período seleccionado entre sesiones:** estado solo en memoria.

## 6. Rollout

Sin breaking changes. Sin migración. Push directo a `mvp-core-clean` + validación visual junto con las demás SPECs pendientes.

## 7. Changelog

### v1.0 — 2026-06-02

Primera entrega de Ola 2. Resuelve la deuda "Análisis vacía" registrada en SPEC-143 §13.7. Sin dependencias nuevas en pubspec.
