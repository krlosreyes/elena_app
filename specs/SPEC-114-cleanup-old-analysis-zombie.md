# SPEC-114 — Cleanup del módulo Análisis viejo

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-15
**Tipo:** Limpieza de código zombie
**Marco normativo:** SPEC-93 (precedente de cleanup) y SPECs 109-113 (rediseño completo de Análisis que dejó huérfanos a los antiguos widgets).

---

# 1. Contexto

Tras SPEC-109 (Análisis en blanco) y SPECs 110-113 (rediseño completo con anillo, calendario, tendencia, heatmap, insights), 8 archivos del módulo Análisis quedaron sin referencias inbound vivas. Son los widgets, providers y servicios del Análisis pre-rediseño.

`flutter analyze` muestra warnings de `unused_import` y errores reales en estos archivos porque su código dependía de APIs cambiadas en SPECs posteriores. No afectan compilación de la app (el árbol main no los toca), pero ensucian el repo y confunden a quien lo abra fresh.

# 2. Archivos zombie identificados

Auditoría inbound (excluyendo dumps `doc_text.txt` y `lib_structure.txt`):

| Archivo | Único anclaje | Estado |
|---|---|---|
| `lib/src/features/analysis/presentation/widgets/imr_breakdown_card.dart` | Solo dumps | Zombie |
| `lib/src/features/analysis/presentation/widgets/pillar_summary_row.dart` | Solo dumps | Zombie |
| `lib/src/features/analysis/presentation/widgets/weekly_report_card.dart` | `analysis_providers.dart` (huérfano) | Zombie |
| `lib/src/features/analysis/presentation/providers/analysis_providers.dart` | Solo huérfanos (`imr_detail_sheet`, `weekly_report_card`) | Zombie |
| `lib/src/features/analysis/application/analysis_service.dart` | Solo `analysis_providers.dart` (huérfano) | Zombie |
| `lib/src/features/analysis/application/imr_explanation_service.dart` | Solo huérfanos (`imr_score_card`, `analysis_providers`) | Zombie |
| `lib/src/features/analysis/presentation/imr_detail_sheet.dart` | Nadie | Zombie |
| `lib/src/features/dashboard/presentation/widgets/imr_score_card.dart` | Nadie | Zombie (en dashboard, no analysis, pero parte de la misma cadena) |

# 3. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | `rm` cada uno de los 8 archivos | Lista arriba |
| 2 | Verificar `flutter analyze` después: 0 errors nuevos | — |
| 3 | Verificar `flutter test` sigue verde | — |

# 4. Criterios de aceptación

1. Los 8 archivos eliminados no existen tras el commit.
2. `flutter analyze` reporta menos errores que antes (sin nuevos).
3. `flutter test` mantiene todos los tests verdes.
4. La app sigue compilando y corriendo igual (los archivos NO eran usados por el árbol vivo).

# 5. Riesgos

**5.1 Resucitar alguna idea borrada.**
Si en el futuro el equipo quiere recuperar la lógica de `analysis_service` o `imr_explanation_service`, está en el `git log`. Para una SPEC futura que quiera retomar, hacer `git show <commit>:<path>` y reescribir contra las APIs vigentes.

**5.2 `imr_score_card.dart` viejo del dashboard.**
Pertenece a `features/dashboard/` pero forma parte de la misma cadena zombie. Su eliminación es coherente — el Dashboard actual usa `circadian_clock.dart` para el IMR.

# 6. Out of scope

- Limpieza de warnings `unused_import` en archivos vivos.
- Migrar otros widgets del repo (`exercise/`, `nutrition/`, etc.) — esta SPEC es estrictamente sobre el módulo Análisis pre-rediseño.

# 7. Resultado

(Se completa al cerrar el SPEC.)
