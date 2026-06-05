# SPEC-148 — Comparativa de transformación 30 días

**Estado:** CLOSED 2026-06-05
**Versión:** 1.0
**Tipo:** Análisis longitudinal — narrativa del cambio metabólico del usuario en 30 días
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 3 §4 (`docs/PLAN_DELIVERY_2026_06_04.md` + memoria `strategic-pivot-passive-to-active-coaching`)
**Estimación:** ~1 día (computer + provider + widget + integración + tests)
**Marco normativo:** `IMR_BIBLIOGRAPHY.md` §13.6 (cadencia longitudinal) + memoria `notification-tone-human-not-clinical` (tono humano)
**Depende de:** SPEC-143 (`biometric_history`), SPEC-152 (`BodyCompositionTrendChart`), SPEC-141 (`imr_history` con snapshots), SPEC-153 (period_comparison patrón).
**Bloquea:** nada inmediato. Es feature aditiva en Análisis.

---

## 1. Contexto

El pivot 2026-06-01 (passive logging → active coaching) establece que la app debe **narrar el cambio del usuario**, no solo mostrar el estado actual. SPEC-152 (BodyCompositionTrendChart) entregó una serie continua de composición corporal; SPEC-153 (WeeklyCoachingCard) entregó coaching semana vs semana anterior. **Falta la pieza puente**: la pantalla que dice *"hace 30 días vs ahora"* con todos los indicadores juntos y una narrativa que celebre la transformación.

### 1.1 — El bug de UX que resuelve

Hoy el usuario tiene que cruzar 3 pantallas mentalmente:
- **Perfil** → IMR actual (sin saber dónde estaba hace un mes)
- **Análisis → Resultados** → peso actual + composición (sin contraste contra el pasado)
- **Análisis → Pilares** → adherencia semana vs semana anterior (solo 7 vs 7 días)

El usuario que abrió la app por primera vez hace 28 días no tiene forma de ver *"de dónde vengo, dónde estoy"*. El pivot "active coaching" requiere que ese contraste sea visible en una sola lectura.

### 1.2 — Por qué 30 días y no 7

- **7 días = adherencia semanal** (SPEC-153 ya lo cubre).
- **30 días = adaptación metabólica real**. Petersen-Shulman 2018 (Physiol Rev) establece que el turnover de HOMA-IR, triglicéridos y composición se mueve en escala 2-4 semanas. 30 días es el límite superior conservador donde un cambio empieza a ser causal, no estadístico.
- **Alineado con la cadencia del IMR longitudinal** (SPEC-141, snapshots semanales) — 4 snapshots cubren los 30 días.

## 2. Decisión de producto

### 2.1 — Componente único: `TransformationCard`

Una sola card grande en Análisis → tab **Resultados** (sección superior) que muestra:

```
┌───────────────────────────────────────────────────┐
│  HACE 30 DÍAS                    HOY              │
│                                                   │
│  Peso       85.2 kg              84.0 kg  ↓1.2    │
│  IMR        58                   64       ↑6      │
│  Cintura    96 cm                94 cm    ↓2      │
│  % Grasa    24%                  22.5%    ↓1.5    │
│  Sueño      6.2 h prom           6.8 h    ↑0.6    │
│  Ayuno      4/7 días             6/7 días ↑       │
│                                                   │
│  ── Tu interpretación ─────────────────────────── │
│  Tu sueño + ayuno consistentes están bajando      │
│  visceral. Sigue así un mes más y el cambio se    │
│  estabiliza. · Petersen-Shulman 2018              │
└───────────────────────────────────────────────────┘
```

### 2.2 — Indicadores incluidos (en orden)

| Indicador | Fuente | Cálculo |
|---|---|---|
| **Peso** | `biometric_history` | último valor 30d atrás vs último |
| **IMR longitudinal** | `imr_history/{weekISO}` | snapshot 4-5 semanas atrás vs último |
| **Cintura** | `biometric_history` | último valor 30d atrás vs último |
| **% grasa** | `biometric_history` | último valor 30d atrás vs último |
| **Sueño promedio** | StreakEntry (30d window) | promedio sleepHours en 30d vs los 30d previos |
| **Ayuno cumplido** | StreakEntry | días con `fastingMagnitude ≥ 0.80` |

### 2.3 — Narrativa humana adaptativa

El bloque "Tu interpretación" es un copy generado por `TransformationNarrator` (función pura) que selecciona del pool ~12 frases según los deltas más significativos. Misma vibra que `CycleFeedback` (SPEC-149) y `WeeklyCoachingCard` (SPEC-153). Tono humano-cercano (memoria `notification-tone-human-not-clinical`) con cita corta.

**Patrones identificables:**
- Bajada de peso > 1kg + ayuno consistente → "Tu ayuno está haciendo el trabajo, lo ves en la balanza."
- IMR subió + sueño mejoró → "El sueño está empujando tu base metabólica hacia arriba."
- Cintura bajó pero % grasa estable → "Estás perdiendo visceral antes que masa magra — eso es lo deseable."
- Peso estable + ayuno alto → "Tu peso no se mueve aún pero la composición sí está cambiando, mira cintura y %grasa."
- Todo estable → "30 días sin cambio visible no es estancamiento — la próxima ola de cambio se prepara abajo." + cita Mattson.

### 2.4 — Manejo de datos insuficientes

Si el usuario tiene < 30 días en la app o le falta el dato base (no hay biometría hace 30d):
- Mostrar la card pero el indicador faltante aparece como `—` (dash) con sublabel "Necesitamos más tiempo".
- Si NINGÚN indicador tiene baseline 30d, la card no se renderiza. En su lugar, un placeholder cálido: *"En 30 días tu transformación va a tener su primera foto comparable. Seguí registrando."*

## 3. Lo que NO se hace (límites duros)

- **NO se inventa el delta cuando falta el dato base.** Si no hay biometría hace 30d, el peso queda `—`. Nunca extrapolar.
- **NO se promete outcomes clínicos.** El copy del interpretador habla de tendencias, no diagnósticos. *"Estás bajando visceral"* OK; *"reduciste 5 años de edad metabólica"* NO.
- **NO se introduce nuevo input del usuario.** Todo se computa con datos que SPEC-143, SPEC-141 y los StreakEntry ya persisten.
- **NO se persiste la comparativa.** Es re-computada en cada apertura de Análisis — barata (<10ms con `biometric_history.watchRecent`).
- **NO se hace cross-pilar profundo** (eso queda para SPEC-147.1 si Carlos lo pide). La interpretación es por indicador, una frase global.
- **NO se grafica.** Es comparativa de DOS puntos (hace 30d vs hoy), no una serie continua. Las series viven en SPEC-152 y SPEC-168.
- **NO se cambia la pantalla de Perfil.** El IMR longitudinal sigue ahí (SPEC-141); SPEC-148 no replica el badge.

## 4. Requisitos funcionales

### RF-148-01 — `TransformationSnapshot` value object

Nuevo `lib/src/features/analysis/domain/transformation_snapshot.dart`:

```dart
/// Snapshot de un indicador en dos puntos temporales — 30d atrás vs hoy.
class TransformationDelta<T extends num> {
  final T? past;        // null si no hay dato a 30d
  final T? current;     // null si no hay dato actual
  final String label;   // 'Peso', 'IMR', etc.
  final String unit;    // 'kg', '', 'cm', '%', 'h prom', 'd/7'

  T? get delta {
    if (past == null || current == null) return null;
    return (current! - past!) as T;
  }
}

class TransformationSnapshot {
  final TransformationDelta<double> weightKg;
  final TransformationDelta<int> imr;
  final TransformationDelta<double> waistCm;
  final TransformationDelta<double> bodyFatPct;
  final TransformationDelta<double> sleepHoursAvg;
  final TransformationDelta<int> fastingDaysOf7;
  // Lista de deltas que se pueden mostrar (delta != null).
  Iterable<TransformationDelta> get visible;
  bool get isEmpty => visible.isEmpty;
}
```

### RF-148-02 — `TransformationComputer`

Pure Dart. Recibe los inputs ya cargados (biometricHistory, imrHistory, streakHistory) y devuelve `TransformationSnapshot`.

```dart
class TransformationComputer {
  static TransformationSnapshot compute({
    required List<BiometricCheckIn> biometricHistory,
    required List<Map<String, dynamic>> imrHistory, // imr_history docs
    required List<StreakEntry> streakHistory,
    required DateTime now,
  });
}
```

Lógica clave:
- Para biometría: tomar el último doc en `[now-35d, now-25d]` como "past" (ventana flexible ±5d para no perder el delta si Carlos no se mide exactamente cada 30d). Y el último doc en `[now-7d, now]` como "current".
- Para IMR: del `imr_history` (snapshots semanales SPEC-141), tomar el de hace 4-5 semanas vs el último.
- Para sueño promedio: promediar `sleepQualityScore × 8` (proxy de horas) sobre las últimas 30 entradas vs las 30 anteriores.
- Para ayuno: contar días con `fastingMagnitude ≥ 0.80` en últimos 7 vs días equivalentes hace 30d.

### RF-148-03 — `TransformationNarrator`

Pure Dart. Recibe `TransformationSnapshot` y elige UN copy del pool según prioridad (igual patrón que `CycleFeedbackGenerator._pickInsight`).

Pool inicial v1.0 (12 copies, todos con cita):
- 4 copies de progreso claro (peso ↓ + ayuno alto, IMR ↑ + sueño mejor, etc.)
- 3 copies de "cambio silente" (peso estable + cintura ↓, etc.)
- 2 copies de "estancamiento legítimo" (todo estable, sigue empujando)
- 2 copies de retroceso (peso ↑ + sueño ↓) con tono **sin culpa**, foco en próximo paso.
- 1 copy default cuando ninguna regla matchea fuerte.

### RF-148-04 — `transformationSnapshotProvider`

Riverpod provider que combina los 3 streams y mantiene el snapshot actualizado.

```dart
final transformationSnapshotProvider = Provider<TransformationSnapshot?>((ref) {
  // Watch biometric_history (últimos 35d), imr_history (últimas 6 semanas),
  // streak history (últimos 60 días). Si alguno está loading → null.
});
```

### RF-148-05 — `TransformationCard` widget

Stateless. Render del layout de §2.1 con widget composition. Sin Riverpod adentro (recibe `snapshot: TransformationSnapshot` + `narrative: String` + `citation: String?`).

### RF-148-06 — Integración en `analysis_screen.dart`

Mount al inicio del tab **Resultados** — antes del `BodyCompositionTrendChart`. Watch del provider. Si `snapshot == null` (loading) → skeleton. Si `snapshot.isEmpty` → placeholder cálido (§2.4).

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `TransformationSnapshot` + `TransformationDelta` | `lib/src/features/analysis/domain/transformation_snapshot.dart` (nuevo) |
| 2 | Crear `TransformationComputer` | `lib/src/features/analysis/application/transformation_computer.dart` (nuevo) |
| 3 | Crear `TransformationNarrator` (pool ~12 copies) | `lib/src/features/analysis/application/transformation_narrator.dart` (nuevo) |
| 4 | Provider Riverpod | `lib/src/features/analysis/application/transformation_provider.dart` (nuevo) |
| 5 | Widget `TransformationCard` | `lib/src/features/analysis/presentation/widgets/transformation_card.dart` (nuevo) |
| 6 | Integrar en tab Resultados | `lib/src/features/analysis/presentation/analysis_screen.dart` (1 cambio) |
| 7 | Tests del computer + narrator | `test/features/analysis/application/transformation_*_test.dart` (2 archivos nuevos) |
| 8 | Widget tests del card | `test/features/analysis/presentation/transformation_card_test.dart` (nuevo) |

## 6. Criterios de aceptación

1. Usuario con 35+ días en la app: ve los 6 indicadores con valores numéricos + delta.
2. Usuario con 10 días: la card no se renderiza, aparece el placeholder *"En 30 días…"*.
3. Usuario sin biometría a 30d pero con IMR snapshot: peso/cintura/%grasa aparecen como `—`; IMR, sueño y ayuno sí.
4. La interpretación elegida del pool coincide con el delta dominante (peso ↓ → copy de "progreso visible").
5. Sin biometría reciente (>7d): peso "current" usa el último valor disponible (el repo retorna el último ordenado por fecha desc) y el sublabel del valor dice "hace X días".
6. La cita siempre se renderiza al pie de la interpretación, formato `· Autor Año`.
7. Tono del copy revisable contra el filtro de memoria `notification-tone-human-not-clinical`: sin culpa, segunda persona, reconoce esfuerzo.
8. `flutter analyze` sin warnings nuevos.
9. `flutter test` mantiene baseline + ≥18 tests nuevos (computer + narrator + widget).

## 7. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | El IMR longitudinal no está activo (feature flag SPEC-141 false). El delta del IMR usaría `imr_history` que sí se persiste, pero la zona del badge puede no coincidir con lo que el usuario ve en Perfil. | Media | El delta del IMR SIEMPRE viene de `imr_history` (snapshot semanal). El badge de Perfil sigue mostrando legacy hasta firma clínica. Documentar discrepancia esperada en copy: `"IMR semanal"` en vez de `"IMR"` cuando el flag está OFF. |
| R-02 | El usuario que pesa todos los días tiene "past" muy cerca de "current" → delta muy chico, parece estancamiento. | Baja | La ventana de "past" busca el último doc dentro de `[now-35d, now-25d]`, no el último doc; tolera la cadencia semanal del usuario sin recoger ruido diario. |
| R-03 | Copy del narrator suena clínico o repetitivo. | Media | Pool de 12 copies + cooldown via `recentInsightId` (mismo patrón SPEC-149). Carlos valida el pool antes de aprobar Bloque A. |
| R-04 | Usuario en estancamiento real (todo plano) se desmoraliza al ver "—" en todos los indicadores. | Media | Placeholder cálido (§2.4) en vez de tabla vacía. Copy específico para "todo estable" reconoce el esfuerzo sin engaño. |

## 8. Out of scope (explícito)

- **Comparativas de 60d, 90d, 6m, 1y.** v1.0 es solo 30d. Si telemetría justifica, SPEC-148.2 agrega selector.
- **Visualización gráfica de la transformación** (serie continua). Las series viven en SPEC-152 + SPEC-168; SPEC-148 es solo dos puntos.
- **Compartir la comparativa** (export imagen, social). Va a SPEC-148.share.
- **Notificación cuando hay un delta significativo** ("¡bajaste 1kg!"). Combinable con SPEC-169 + SPEC-179 en SPEC-148.notif.
- **Cambio del WeeklyCoachingCard** (SPEC-153). Sigue ahí — son cards distintas.

## 9. Cierre

- [ ] `TransformationSnapshot` + `TransformationDelta` + tests.
- [ ] `TransformationComputer` + tests con casos edge (sin biometría, sin imr_history, etc.).
- [ ] `TransformationNarrator` con pool ~12 + tests de selección por prioridad.
- [ ] `transformationSnapshotProvider`.
- [ ] `TransformationCard` widget + widget tests.
- [ ] Integración tab Resultados.
- [ ] Validación visual Carlos en iPhone.
- [ ] Memoria proyecto actualizada con SPEC-148 CLOSED.

## 10. Cierre 2026-06-05

Implementación completada en 4 bloques. Sin cambios visuales hasta el mount en Bloque C.

- [x] **A** — `TransformationDelta<T>` + `TransformationSnapshot` con `visible`/`isEmpty` + `TransformationComputer` con ventanas flexibles. 15 tests del computer.
- [x] **B** — `TransformationNarrator` con pool de 11 copies categorizados (progreso/silente/estancamiento/retroceso) + default. Cooldown vía `recentIds`. 15 tests.
- [x] **C** — `transformationSnapshotProvider` (autoDispose combina 3 streams) + `watchImrHistory` agregado al `UserProfileRepository` + `TransformationCardLive`/`TransformationCard` widgets + integración en `analysis_screen.dart` antes de la sección "Resultados".
- [x] **D** — 7 widget tests del `TransformationCard` (render completo, headers, valores, delta pills, narrativa con/sin cita, "—" para missing).

Total: **37 tests nuevos**. Cero cambios en SPECs previas.

**Validación pendiente:** visual en iPhone — Carlos debe ver la card aparecer al abrir Análisis → tab Resultados, con la copy correcta según los datos reales de su semana.

## 11. Changelog

### v1.0 — 2026-06-05

Documento inicial. Card comparativa multi-indicador 30d con narrativa humana, sin gráfico (eso ya está en SPEC-152). Reusa `biometric_history` (SPEC-143) + `imr_history` (SPEC-141) sin agregar persistencia nueva. Pool de 12 copies del narrator con cooldown. Placeholder cálido cuando no hay 30d de datos.
