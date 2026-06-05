# SPEC-170 — Header dual HOY + IMR

**Estado:** CLOSED 2026-06-04
**Versión:** 1.0
**Tipo:** Visualización — segunda ola del pivot active coaching
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2.5 §3.3 (doc `docs/PLAN_DELIVERY_2026_06_04.md`)
**Estimación:** ~1 día (widget nuevo + integración + ExplainerSheet + tests)
**Marco normativo:** `IMR_BIBLIOGRAPHY.md` §6 (Score del Día) + §13 (Día Metabólico), memoria `notification-tone-human-not-clinical`
**Depende de:** SPEC-140 (Score del Día), SPEC-141 design (IMR), SPEC-171 (display provider cíclico).
**Bloquea:** nada inmediato.

---

## 1. Contexto

Hoy el usuario ve **dos métricas distintas en dos lugares distintos** y no entiende la relación entre ellas:

- **Score del Día** (motivacional, 0-100, llega a 100, se mueve a diario): número grande "87" en el header del Dashboard (card "TU DÍA"). Refleja "cómo viviste hoy".
- **IMR** (longitudinal, no llega a 100 fácil, se mueve en semanas): badge en Perfil + número en Análisis. Refleja "tu estado metabólico de fondo".

Sin contraste explícito, el número grande del Dashboard se siente arbitrario. El usuario pregunta "¿por qué hay dos números?" y la app no responde.

### 1.1 — Por qué importa para el pivot

El pivot estratégico (memoria `strategic-pivot-passive-to-active-coaching`) requiere que el usuario entienda **qué métrica está optimizando con cada acción**. Sin el contraste HOY vs IMR, no puede traducir esfuerzo en feedback comprensible.

SPEC-140 ya estableció la promesa "el Score del Día llega a 100" — pero esa promesa solo tiene sentido si el usuario sabe que existe **otra métrica** (IMR) que NO está pensada para llegar a 100. Sin esa diferenciación visible, el promedio de los dos números los devalúa a ambos.

## 2. Decisiones de producto

### 2.1 — Dos rings adyacentes en el header

Reemplazar el número 36pt "87 /100" de la fila 2 del card "TU DÍA" con **dos rings grandes lado a lado**:

```
TU DÍA                                          ⓘ

   ╭───╮             ╭───╮
   │ 87│             │ 64│
   ╰───╯             ╰───╯
   HOY                IMR
   ↑5 vs ayer         tu base

──────────────────────────────────────────────
[Ayuno] [Sueño] [Hidra] [Ejerc] [Comidas]
```

- **Ring izquierdo HOY** — verde (accent del Score del Día). Score 0-100. Progreso del ring = score/100.
- **Ring derecho IMR** — color secundario (cyan, accent del IMR). Score 0-100 del `displayedImrProvider`. Progreso del ring = score/100.
- Cada ring ~64-72 px (más grande que los PillarRing de 56px para diferenciar visualmente).
- Labels "HOY" e "IMR" en mayúsculas debajo de cada ring.
- Sub-label de delta opcional debajo: "↑5 vs ayer" para HOY (del `displayDailyScoreDeltaProvider`), "tu base" o "↑2 vs sem pasada" para IMR.

### 2.2 — Sin ring concéntricos (decisión Carlos)

Carlos rechazó el patrón concéntrico ("HOY afuera, IMR adentro") en la pregunta inicial. Razón: dos métricas semánticamente distintas merecen entidades visuales distintas, no anidadas. El concéntrico sugeriría jerarquía (afuera "engloba" adentro) cuando no es el caso.

### 2.3 — IMR sin delta inicialmente

Para MVP el ring IMR muestra solo el score + sub-label "tu base". No mostramos delta vs semana pasada porque:

- `progressProvider.imrDelta` compara baseline vs última semana (no semana vs semana — no es lo que queremos).
- SPEC-141 (IMR longitudinal con deltas semanales correctos) sigue diferida a Ola 3.
- Mostrar un delta de IMR engañoso es peor que no mostrar.

Si tras validación el sub-label "tu base" se siente vacío, SPEC-170.1 evalúa agregar "↑2 vs sem" con el provider correcto (requiere SPEC-141 implementado).

### 2.4 — Un único ExplainerSheet humano-cercano

El ⓘ del header existente (`showDailyScoreExplainerSheet`) se extiende para cubrir ambos. Title y body actualizados con tono cálido (memoria `notification-tone-human-not-clinical`):

> **Tus dos números**
>
> **HOY** refleja cómo viviste hoy. Puede llegar a 100 si cumpliste tus 5 pilares — está pensado para celebrarte cuando te lo ganaste.
>
> **IMR** es tu base metabólica de fondo. Se mueve más lento, en semanas y meses. Esto es lo que importa cuando hablamos de cambios reales en tu cuerpo.
>
> Los dos son tuyos. HOY te dice "hoy cumpliste", IMR te dice "estás cambiando".
>
> *Fuentes: IMR_BIBLIOGRAPHY §6 (Score del Día) y §13 (Día Metabólico).*

Tap en cualquiera de los rings o en el ⓘ abre el mismo sheet.

### 2.5 — Tono humano-cercano en sub-labels

Sub-label de IMR es "**tu base**" (íntimo, propietario), NO "Score longitudinal" (clínico). Cuando agregue delta en futuro, será "↑2 desde la semana pasada" no "ΔIMR: +2 sd".

### 2.6 — Sin cambio en los 5 PillarRing chicos

Los 5 rings de pilares debajo del divider quedan idénticos. Solo cambia el bloque superior.

## 3. Lo que NO se hace (límites duros)

- **NO ring concéntricos** (decisión Carlos).
- **NO se modifica `displayedImrProvider`** ni la fórmula del IMR.
- **NO se implementa delta semanal del IMR** (depende de SPEC-141 diferida).
- **NO se reescribe `showDailyScoreExplainerSheet`** desde cero — solo se extiende el contenido para cubrir ambos.
- **NO se toca el ExplainerSheet del IMR en Perfil/Análisis** (ese sigue siendo el técnico para Carlos, no para el usuario final).
- **NO se cambia la frase motivacional `_dailyScoreMotivation`** — sigue debajo de los rings.

## 4. Requisitos funcionales

### RF-170-01 — `DualScoreRing` widget

Nuevo `lib/src/features/dashboard/presentation/widgets/dual_score_ring.dart`. Stateless puro, sin Riverpod, testeable directo:

```dart
class DualScoreRing extends StatelessWidget {
  const DualScoreRing({
    super.key,
    required this.dailyScore,
    required this.dailyDelta,
    required this.imrScore,
    required this.onTap,
  });

  final int dailyScore;        // 0-100
  final int? dailyDelta;       // null si no hay día previo
  final int imrScore;          // 0-100
  final VoidCallback onTap;    // abre ExplainerSheet

  @override
  Widget build(BuildContext context) { ... }
}
```

Layout interno:
- `Row` con `MainAxisAlignment.spaceAround` (o `spaceEvenly`).
- Dos columnas: cada una con `_BigScoreRing(score, color, label, sublabel)`.
- HOY: color `AppColors.metabolicGreen`, label "HOY", sublabel `↑$delta vs ayer` o ` ` (no se muestra si null).
- IMR: color `AppColors.metabolicCyan` (verificar nombre exacto), label "IMR", sublabel "tu base".

`_BigScoreRing` interno reusa el patrón visual de `PillarRing` pero más grande (72px) y con el número EN EL CENTRO en vez del icono.

### RF-170-02 — ExplainerSheet extendido

Modificar `showDailyScoreExplainerSheet` (ubicación a confirmar en auditoría): contenido nuevo con la copy de §2.4 + cita SPEC-140 / §13. Título cambia de "Score del Día" a "Tus dos números".

### RF-170-03 — Integración en `dashboard_screen.dart`

Reemplazar las líneas 426-474 (Fila 2 actual con número grande, /100, delta, frase motivacional) con:

```dart
DualScoreRing(
  dailyScore: dailyScore,
  dailyDelta: delta,
  imrScore: ref.watch(displayedImrProvider).score,
  onTap: () => showDailyScoreExplainerSheet(context),
),
```

La frase motivacional `_dailyScoreMotivation` queda **abajo del DualScoreRing**, no al lado. Es la única fila independiente.

### RF-170-04 — Tests

`test/features/dashboard/presentation/widgets/dual_score_ring_test.dart`:

- Render con ambos scores y delta positivo → muestra "HOY 87 ↑5", "IMR 64 tu base".
- Render con delta null → HOY sin sublabel de delta.
- Render con dailyScore 100 → ring HOY al 100% (full).
- Render con imrScore 0 → ring IMR al 0%.
- Tap dispara onTap callback.
- Render con delta negativo → "HOY 75 ↓3 vs ayer".

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `DualScoreRing` widget | `lib/src/features/dashboard/presentation/widgets/dual_score_ring.dart` (nuevo) |
| 2 | Reemplazar fila 2 del header con DualScoreRing | `lib/src/features/dashboard/presentation/dashboard_screen.dart` (líneas ~426-474) |
| 3 | Extender ExplainerSheet con copy HOY+IMR | `lib/src/features/streak/presentation/daily_score_explainer_sheet.dart` (a confirmar) |
| 4 | Widget tests del DualScoreRing | `test/features/dashboard/presentation/widgets/dual_score_ring_test.dart` (nuevo) |

## 6. Criterios de aceptación

1. Header del Dashboard muestra dos rings adyacentes claramente diferenciados por color.
2. Cada ring muestra su score numérico en el centro y un label debajo (HOY, IMR).
3. HOY muestra delta vs ayer cuando hay día previo; no muestra nada cuando no lo hay.
4. IMR muestra sub-label "tu base".
5. Tap en cualquiera de los rings abre un único ExplainerSheet con copy humano-cercano que explica ambos.
6. Frase motivacional `_dailyScoreMotivation` sigue apareciendo en su línea propia.
7. Los 5 PillarRing chicos debajo quedan inalterados.
8. `flutter analyze` sin issues nuevos.
9. ≥6 widget tests verdes.

## 7. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | "IMR 64" sin contexto puede sentirse bajo y desmotivar | Media | Sub-label "tu base" + ExplainerSheet aclaran que IMR no llega a 100 fácilmente. Ese es el punto del contraste con HOY. |
| R-02 | Dos rings de 72px pueden no caber en pantallas chicas (iPhone SE) | Baja | LayoutBuilder con clamp a 64px si ancho < 360. |
| R-03 | El sub-label "tu base" puede sonar genérico | Baja | Aceptado para MVP. Si Carlos valida visual y se siente off, iteramos a "tu fondo" o "tu tendencia". |
| R-04 | Eliminar el "/100" puede romper la promesa SPEC-140 ("el 100 es alcanzable") | Media | El ring HOY es un círculo lleno cuando score = 100 — la promesa visual queda. Si Carlos prefiere, agregamos `/100` como tick discreto al ring. |

## 8. Out of scope (explícito)

- Delta semanal real del IMR (requiere SPEC-141 implementado).
- Animación de transición del ring HOY al cerrar ciclo (puede ir a SPEC-170.1).
- Cambio del ExplainerSheet del IMR en Perfil/Análisis (sigue siendo el técnico).
- Cambio del color del IMR si Carlos siente que cyan/verde compiten visualmente.

## 9. Cierre

Implementación completada (~45 min, 3 bloques A-C):

- [x] **A** — `DualScoreRing` widget creado en `lib/src/features/dashboard/presentation/widgets/dual_score_ring.dart`. Stateless puro con LayoutBuilder responsive (72px / 60px en pantallas <360).
- [x] **B** — `dashboard_screen.dart` reemplazó la Fila 2 (número 36pt + /100 + delta + frase) por el DualScoreRing + frase centrada debajo. Método `_buildDailyScoreDelta` retirado (código muerto). ExplainerSheet `daily_score_explainer_sheet.dart` reescrito con copy "Tus dos números" y nuevo widget `_ScoreSection` para HOY/IMR con barras de acento color.
- [x] **C** — 9 widget tests del DualScoreRing en `test/features/dashboard/presentation/widgets/dual_score_ring_test.dart` (render con/sin delta, deltas +/0/-, score 0 y 100, tap callback).
- [ ] Validación visual en iPhone (Carlos — pendiente próxima sesión cuando corra la app).

## 10. Changelog

### v1.0 — 2026-06-04

Documento inicial. Reemplazo del número grande HOY del card "TU DÍA" por dos rings adyacentes HOY + IMR con ExplainerSheet humano-cercano único. MVP sin delta del IMR (diferido hasta SPEC-141).
