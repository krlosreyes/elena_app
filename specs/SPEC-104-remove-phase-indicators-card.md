# SPEC-104 — Eliminar card "FASE / BLOQUEO / ALINEACIÓN" del Dashboard

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Limpieza UX
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §6 (Regla 4 "Seguridad ante todo") + filosofía de Elena (menos densidad = más foco).

---

# 1. Contexto

Debajo del `CircadianClock` en el Dashboard existe una card horizontal con 3 indicadores:
- **FASE ACTUAL · COGNITIVO**
- **BLOQUEO INTESTINAL · 12h 02m**
- **ALINEACIÓN · 100%**

Carlos pidió análisis y decidió eliminarla por completo.

# 2. Justificación

**FASE ACTUAL.** Redundante. El anillo de fases del reloj (`BiologicalCyclesPainter`) ya muestra cuál fase circadiana está activa con color saturado y texto. El indicador "now" cae visualmente sobre ese arco. Repetirlo textualmente abajo no aporta información.

**BLOQUEO INTESTINAL.** Información correcta pero formato sub-óptimo. Un contador pasivo de 12h02m no provoca acción ahora. Su valor real está cuando bajan a <3h — momento donde debería ser una **alerta condicional**, no un widget fijo. Esta migración a alerta vive en SPEC futura, no aquí.

**ALINEACIÓN 100%.** Contradictoria. El usuario ve "ALINEACIÓN 100%" simultáneamente con un IMR de 30 ("DETERIORADO"). Sin desglose de qué mide, el 100% se lee como trofeo decorativo y el contraste con el IMR confunde más de lo que comunica.

**Costo de oportunidad:** la card consume ~15% de altura útil de pantalla mobile sin generar acción ni comprensión clara. Es deuda visual.

# 3. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Eliminar invocación a `_buildPhaseIndicators` en el dashboard | `dashboard_screen.dart` |
| 2 | Eliminar métodos `_buildPhaseIndicators` y `_phaseIndicatorTile` | `dashboard_screen.dart` |
| 3 | Eliminar widget huérfano `CircadianMiniCard` (sin referencias inbound) | `widgets/circadian_mini_card.dart` |

# 4. Criterios de aceptación

1. Tras el cambio, debajo del reloj aparece directamente el bloque "PILARES HOY" / card del pilar seleccionado.
2. `flutter analyze` sin warnings nuevos (los imports y métodos huérfanos quedan limpios).
3. `flutter test` sin regresiones — la card eliminada no participaba en tests.

# 5. Riesgos

**5.1 Información perdida.** El usuario ya no ve "12h02m de bloqueo intestinal" siempre presente. Mitigación: SPEC futura agrega alerta condicional cuando faltan <3h (más útil que un widget pasivo siempre visible).

**5.2 `BiologicalCyclesPainter` ya comunica fase activa.** El usuario que dependía de la card para identificar fase ahora la lee del anillo del reloj. Educación implícita por consistencia visual.

# 6. Out of scope

- Alerta condicional de bloqueo intestinal (SPEC futura).
- Métrica de alineación accionable (requiere desglose por pilar, SPEC mayor).

# 7. Resultado

(Se completa al cerrar el SPEC.)
