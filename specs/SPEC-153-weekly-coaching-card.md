# SPEC-153 — WeeklyCoachingCard: reemplazo del PillarsHeatmap

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Rediseño de Ola 2 — convierte un dashboard frío en un coaching block
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 2 sesiones
**Marco normativo:** `CONSTITUTION.md`. Reemplaza `PillarsHeatmap` (SPEC-113 v1) en Análisis.

---

## 1. Contexto

Durante validación 2026-06-02 Carlos vio el `PillarsHeatmap` actual y lo calificó honestamente como "un asco". Diagnóstico técnico de por qué falla:

1. **El gradiente de alpha no comunica.** El mapeo `0.18 + 0.82 * p` hace que celdas con 27% y 71% se vean casi iguales — el ojo no distingue.
2. **El legend miente.** Dice "sin registro / bajo / pleno" (3 buckets) pero las celdas pintan en continuo. Inconsistencia visual.
3. **Información sin acción.** Te dice "Sueño 48%". ¿Y? No hay sugerencia, sin contexto, sin acción. Es dashboard de admin, no coach.
4. **Sin jerarquía narrativa.** No hay foco visual — ¿la columna PROM? ¿la última celda? ¿el patrón? Todo compite.
5. **Headers ambiguos.** Día 28-3 sin nombre de mes en cada columna. "MAY-JUN 2026" en el header no soluciona la ambigüedad celda a celda.

Conclusión: SPEC-113 priorizó "mostrar la data cruda" — opuesto al pivot del 2026-06-01 (active coaching, no passive logging).

## 2. Decisión de diseño

### 2.1 — Un widget de coaching, no un dashboard

```
┌─────────────────────────────────────────────┐
│ TU SEMANA                       MAY 28-JUN 3│
│                                              │
│  Ayuno         ▓░░░░░░  27%  ↓18% vs prev   │ ← rojo
│  Sueño         ▓▓░░░░░  48%  ↑5%             │ ← ámbar
│  Hidrat.       ▓▓▓▓▓░░  83%  ↑12%            │ ← verde
│  Ejerc.        ▓▓▓▓░░░  71%  =                │ ← gris
│  Comidas       ▓▓▓▓░░░  71%  ↓3%             │ ← rojo claro
│                                              │
│  ─────────────────────────────────────────   │
│                                              │
│  💡 Tu ayuno es el pilar que más arrastra. │ ← insight automático
│     Cayó 18% vs la semana anterior.         │
│                                              │
│  → Marcá el inicio del próximo ayuno entre │ ← acción concreta
│     19:00–21:00.                            │
│     Mattson 2017 + Sutton 2018              │ ← cita científica
└─────────────────────────────────────────────┘
```

### 2.2 — Barras discretas, no gradiente continuo

7 niveles de relleno (cada 14.3% es un tick). Lectura inmediata. El número grande al lado refuerza.

### 2.3 — Deltas vs período anterior, con color y signo

- **↓ rojo** baja >5% — pilar en deterioro
- **↑ verde** sube >5% — pilar mejorando
- **=** gris claro — sin cambio significativo (±5%)

Color comunica dirección, NÚMERO refuerza magnitud.

### 2.4 — Algoritmo del "pilar débil"

Función pura `WeeklyCoachingComputer.pickWeakPillar`:

1. Si hay un pilar con caída >10% vs anterior → ese es el débil (aunque su promedio absoluto sea alto, lo que importa es el deterioro).
2. Si no hay caídas, el débil es el de menor promedio actual.
3. Si todos están ≥80%, no hay débil — mensaje motivacional ("Estás sostenido, seguí así").
4. Si hay 0 docs en el período actual, no hay insight (empty state simple).

### 2.5 — Pool de insights + citas por pilar

Cada pilar débil tiene un insight + acción + cita estable. Misma bibliografía que `CycleClosureCard` (SPEC-149 §RF-149-09) para consistencia narrativa.

| Pilar | Insight | Acción | Cita |
|---|---|---|---|
| Ayuno | "Tu ayuno está corto. La autofagia profunda requiere ≥16h." | "Marcá el inicio del próximo ayuno entre 19:00–21:00." | Mattson 2017 + Sutton 2018 |
| Sueño | "Tu sueño es el que más arrastra. <7h compromete reparación metabólica." | "Apuntá a apagar pantallas 1h antes de tu hora objetivo de dormir." | Walker 2017 + AASM |
| Hidratación | "Tu hidratación está bajo el target. 35ml/kg es la base mínima." | "Bebé un vaso de agua cada 90 min hasta las 21:00." | EFSA 2010 + Popkin 2010 |
| Ejercicio | "Tu ejercicio está bajo. Sin movimiento, la insulina no se regula bien." | "Sumá 20 min de caminata después de la comida más grande." | AHA 2018 + Mattson 2017 |
| Comidas | "Tu adherencia a la ventana de comida cayó. Cerrar tarde rompe el ritmo circadiano." | "Cerrá tu ventana antes de las 21:00 para alinear con tu cortisol." | Lopez-Minguez 2018 |

### 2.6 — Período mostrado

Por defecto la card muestra **los últimos 7 días**, no el período de la pestaña arriba. Razón: el coaching semanal es semanal — no tiene sentido decir "tu pilar débil de los últimos 3 meses" porque el período es demasiado largo para una acción inmediata.

Si en una iteración futura el usuario pide otras ventanas, agregamos selector. MVP: 7 días.

## 3. Cambios técnicos

### 3.1 — Nuevo dominio `WeeklyCoachingInsight`

`lib/src/features/analysis/domain/weekly_coaching_insight.dart`:
- Enum `WeakPillar` con `label`, `insightText`, `suggestedAction`, `citation`.
- Class `WeeklyCoachingInsight` con 5 promedios actuales, 5 deltas (nullable), `weakest` (opcional), `insightHeadline`/`suggestedAction`/`citation` derivados.
- `factory WeeklyCoachingInsight.empty()` cuando no hay docs.

### 3.2 — `WeeklyCoachingComputer`

`lib/src/features/analysis/application/weekly_coaching_computer.dart`:
- Función estática `compute(current, previous) → WeeklyCoachingInsight`.
- Lógica del §2.4.
- Pure Dart, sin Riverpod ni Flutter.

### 3.3 — Provider

`lib/src/features/analysis/application/weekly_coaching_provider.dart`:
- Provider que consume los `daily_summary` de los últimos 7 días + los 7 anteriores.
- Devuelve `WeeklyCoachingInsight`.

### 3.4 — Widget `WeeklyCoachingCard`

`lib/src/features/analysis/presentation/widgets/weekly_coaching_card.dart`:
- ConsumerWidget que watchea `weeklyCoachingProvider`.
- Header "TU SEMANA" + rango de fechas.
- 5 filas (pilar + barra discreta + % + delta con icono y color).
- Separador.
- Bloque insight (lightbulb + headline + acción + cita) — solo si hay débil.
- Si no hay débil (todo ≥80%), mensaje motivacional "Estás sostenido esta semana, seguí así".
- Empty state si 0 docs.

### 3.5 — Integración en `analysis_screen.dart`

Reemplazar `PillarsHeatmap` por `WeeklyCoachingCard`. El widget viejo queda en disco pero sin uso — lo dejamos para no romper imports de tests si los hay. Si en una iteración futura se decide eliminarlo, SPEC-153.1.

## 4. Criterios de aceptación

1. La pantalla Análisis muestra `WeeklyCoachingCard` donde antes vivía el heatmap.
2. Cada pilar muestra: nombre, barra discreta de 7 niveles, % redondeado, delta con flecha y color.
3. El delta usa rojo (↓>5%), verde (↑>5%), gris (=) según §2.3.
4. El insight automático aparece cuando hay un pilar débil — texto + acción + cita.
5. Si todos los pilares ≥80%, mensaje motivacional sin acción específica.
6. Si no hay docs en los últimos 7 días, empty state simple.
7. Tests cubren: pickWeakPillar (4 ramas), formato de deltas, generación de insight, empty state.

### 4.1 — Sobre tests

- `WeeklyCoachingComputer.compute` es pure Dart → tests cubren todas las ramas del §2.4.
- `WeakPillar.insightText/.suggestedAction/.citation` testeable como expectations.
- Widget test NO — frágil. Validación visual.

## 5. Out of scope (explícito)

- **Selector de ventana (7d/14d/30d):** MVP fijo 7d. Iteración futura si emerge demanda.
- **Múltiples insights simultáneos** (ej: 2 pilares débiles): UNO solo, el más urgente. La regla §2.4 prioriza caída > promedio bajo.
- **Tracking de cuáles insights ya vio el usuario** (anti-repetición): no en MVP. Si emerge problema, SPEC separada.
- **Eliminar `PillarsHeatmap`:** queda en disco sin uso. SPEC-153.1 si se decide limpiar.

## 6. Rollout

Sin breaking changes. Sin migración. Push directo a `mvp-core-clean` + validación visual.

## 7. Changelog

### v1.0 — 2026-06-02

Rediseño después de feedback honesto de Carlos. Reemplaza el heatmap frío por un coaching block que dice qué importa y qué hacer.
