# SPEC-168 — Refresh visual Apple Health/Fitness fase 2 (paraguas)

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** SPEC paraguas — 8 sub-specs entregables independientemente
**Líder:** Carlos
**Implementación:** Claude
**Estimación total:** ~3 sprints (entregables incrementales)
**Bibliografía:** Apple Health iOS 17/18 + Apple Fitness, screenshots compartidos por Carlos 2026-06-03

---

## 1. Contexto

SPEC-163/164/165 nos llevaron al 40 % del lenguaje visual Apple. Quedan 8 patrones que Carlos identificó al ver Apple Health/Fitness real. Esta SPEC los agrupa y los descompone en sub-specs implementables por separado.

**Restricción heredada (Carlos, 2026-06-02):** Pantalla Hoy no se toca. Esta SPEC vive 100 % dentro del feature Análisis.

**Pre-condiciones (todas cerradas):**
- SPEC-163 — BarChartCard / LineChartCard base
- SPEC-164 — Agregación adaptativa daily/weekly/monthly
- SPEC-165 — Visual fase 1 (fondo negro, header 34pt, chips D/S/M/6M/A)
- SPEC-167 — Fix yMax sub-pixel

## 2. Sub-specs

| ID | Tema | Sprint | Riesgo | Impacto |
|----|------|--------|--------|---------|
| 168.1 | Eje Y derecha + hero PROMEDIO/TOTAL | inmediato | bajo | alto visual |
| 168.2 | Línea de objetivo dashed | inmediato | bajo | alto coaching |
| 168.8 | Color por estado de barra | inmediato | bajo | alto lectura |
| 168.3 | Indicador "X de N días" en header | siguiente | bajo | medio |
| 168.5 | Card "Tendencias" comparación promedios | siguiente | medio | alto insight |
| 168.4 | Overview "Anteriores" con sparklines | backlog | medio | alto navegación |
| 168.6 | Tracks apilados (Hábitos en 1 card) | backlog | medio | medio |
| 168.7 | Tooltip flotante al tap | backlog | medio | medio drill-down |

## 3. Sprint inmediato — qué entrega

Tras 168.1 + 168.2 + 168.8 implementados:

- Cada card de Análisis verá el eje Y a la derecha como Apple.
- Arriba del chart, bloque hero: `PROMEDIO 177 g` + rango `7 a 13 jul. de 2026`.
- Línea horizontal dashed mostrando el `objetivo` por pilar (16h ayuno, 2.5 L hidratación, 30 min ejercicio, 8 h sueño).
- Barras brillantes los días que se cumplió el objetivo, opacas los días que no.

Visualmente: idéntico a Apple Fitness Actividad pero con nuestros 5 pilares.

## 4. Restricciones globales

- **Idempotencia visual**: los 3 cambios se pueden activar/desactivar por card (param opcional). Si una métrica no tiene objetivo definido, no se pinta línea ni color de estado.
- **No tocar pipelines**: SPEC-168 es solo visual/presentational. Domain layer (providers, repositorios, aggregators) no se mueve.
- **No regresar IMR**: el IMR longitudinal usa LineChartCard. Cualquier cambio a LineChartCard debe preservar exactamente la lectura del IMR.

## 5. Bibliografía

Capturas Apple Health/Fitness compartidas por Carlos 2026-06-03 — Carbohidratos, Anteriores, Actividad (A/6M/M/S/D), Distancia caminata + trote, Tendencias Peso, Peso anual. Patrones identificados y catalogados en §1 de esta SPEC.

## 6. Cierre

- [ ] Sub-specs 168.1, 168.2, 168.8 aprobadas por Carlos
- [ ] Implementadas y validadas en device
- [ ] Sub-specs 168.3, 168.5 redactadas
- [ ] Backlog 168.4, 168.6, 168.7 priorizado
