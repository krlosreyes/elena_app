# SPEC-93 — Cleanup de código zombie pre-launch

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Limpieza de repositorio (no funcional)
**Marco normativo:** `CONSTITUTION.md` §"código sin dueño es deuda técnica".

---

# 1. Contexto

`flutter analyze` reporta 107 issues. Tras la verificación SPEC-92, identificamos que **~50 son errores reales en archivos huérfanos** — código que vive en `lib/` pero al que no apunta ninguna referencia inbound desde rutas, providers, widgets activos, ni la suite de tests. El árbol de tests pasa 490 verdes porque estos archivos nunca se compilan en la ejecución real.

Son restos de iteraciones previas (intentos de analytics widgets, drawers de detalle de pilar, sheet de fases biológicas, etc.) que quedaron sin terminar y referencian APIs que ya no existen en los modelos vigentes (`ExerciseLog`, `NutritionLog`, `SleepNotifier`, `Gender`, `PhaseInfo`, etc.).

Antes del lanzamiento queremos:
1. **Dejar el repo limpio para mantenimiento futuro** — cualquier dev que abra el proyecto recibe 107 ruidos de analyze antes de entender qué importa.
2. **Eliminar la posibilidad de que un commit accidental "active" estos archivos** y rompa el árbol de tests.
3. **Reducir la superficie del bundle final** (aunque tree-shaking elimina dead code en release, mantenerlos genera confusión y eternaliza la deuda).

# 2. Problema

`flutter analyze` reporta los siguientes errores reales en archivos sin referentes inbound:

| Archivo | Errors | Quién lo importa |
|---|---|---|
| `lib/src/core/orchestrator/phase_info_mapper.dart` | 8 | Solo `phase_info_sheet.dart` y `phase_info_card.dart` (ambos huérfanos) |
| `lib/src/core/widgets/phase_info_sheet.dart` | 0 (pero huérfano) | Nadie |
| `lib/src/core/widgets/app_error_screen.dart` | 2 | Nadie |
| `lib/src/features/dashboard/presentation/widgets/phase_info_card.dart` | 1 | Nadie |
| `lib/src/features/dashboard/presentation/widgets/pillar_detail_panel.dart` | 7 | Solo `pillar_interactive_section.dart` (huérfano) |
| `lib/src/features/dashboard/presentation/widgets/pillar_interactive_section.dart` | 1 warning | Nadie |
| `lib/src/features/dashboard/domain/fasting_protocol_advisor.dart` | 1 | Nadie |
| `lib/src/features/exercise/application/exercise_intensity_notifier.dart` | 10 | Nadie |
| `lib/src/features/exercise/presentation/widgets/exercise_analytics_widget.dart` | 8 | Nadie |
| `lib/src/features/nutrition/application/nutrition_validator_notifier.dart` | 3 | Nadie |
| `lib/src/features/nutrition/presentation/widgets/macro_analytics_widget.dart` | 9 | Nadie |
| `lib/src/features/profile/presentation/body_composition_editor_sheet.dart` | 4 | Nadie (queda explícito out-of-scope en SPEC-92) |

**Total:** 12 archivos huérfanos, ~54 errors de analyze que desaparecen al eliminarlos.

Adicionalmente:
- `analysis_options.yaml` tiene dos bloques `analyzer:` (línea 12 y línea 35) → YAML duplicate key. El segundo bloque excluye `lib/src/legacy/**` que **no existe** en el repo. Hay que fusionarlos.

# 3. Solución propuesta

**3.1 Eliminar los 12 archivos zombie.** Operación quirúrgica — un `rm` por archivo. No requiere migración de datos ni cambios en producción porque el código no se ejecuta.

**3.2 Fusionar y limpiar `analysis_options.yaml`.** Un solo bloque `analyzer:` con `errors: invalid_annotation_target: ignore`. El `exclude` apuntando a folder inexistente se elimina (si en el futuro quieren excluir algo, lo agregan).

**3.3 No tocar tests existentes.** Como los archivos zombie no participan en la suite, no hay tests que ajustar.

**3.4 No expandir scope.** Issues "preexistentes" tipo `unused_import`, `prefer_const`, `deprecated_member_use` quedan **fuera** de esta SPEC — limpieza separada si se quiere, pero requiere tocar ~30+ archivos vivos y no aporta valor pre-launch.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Eliminar | `lib/src/core/orchestrator/phase_info_mapper.dart` |
| 2 | Eliminar | `lib/src/core/widgets/phase_info_sheet.dart` |
| 3 | Eliminar | `lib/src/core/widgets/app_error_screen.dart` |
| 4 | Eliminar | `lib/src/features/dashboard/presentation/widgets/phase_info_card.dart` |
| 5 | Eliminar | `lib/src/features/dashboard/presentation/widgets/pillar_detail_panel.dart` |
| 6 | Eliminar | `lib/src/features/dashboard/presentation/widgets/pillar_interactive_section.dart` |
| 7 | Eliminar | `lib/src/features/dashboard/domain/fasting_protocol_advisor.dart` |
| 8 | Eliminar | `lib/src/features/exercise/application/exercise_intensity_notifier.dart` |
| 9 | Eliminar | `lib/src/features/exercise/presentation/widgets/exercise_analytics_widget.dart` |
| 10 | Eliminar | `lib/src/features/nutrition/application/nutrition_validator_notifier.dart` |
| 11 | Eliminar | `lib/src/features/nutrition/presentation/widgets/macro_analytics_widget.dart` |
| 12 | Eliminar | `lib/src/features/profile/presentation/body_composition_editor_sheet.dart` |
| 13 | Limpiar `analyzer:` duplicado | `analysis_options.yaml` |

# 5. Criterios de aceptación

1. `flutter analyze` después del cleanup reporta **<70 issues** (eliminados ~54 errors + el duplicate_mapping_key).
2. `flutter analyze` no reporta **NINGÚN** error nuevo. Solo deben quedar warnings/infos preexistentes (deprecated APIs, unused imports en archivos vivos).
3. `flutter test` mantiene 490+ verdes (los archivos eliminados no estaban en el árbol de tests, así que no rompe nada).
4. `git diff --stat` debe mostrar 13 archivos modificados/eliminados, con `delete:` para los 12 zombie y un cambio menor en `analysis_options.yaml`.

# 6. Pruebas

Antes y después:
```bash
flutter analyze 2>&1 | grep -cE "error|warning|info"   # antes: ~107
flutter test                                            # antes: 490 verdes
```

No se agregan tests nuevos (no hay funcionalidad nueva — solo eliminación).

# 7. Riesgos

**7.1 Eliminar algo que el sitio web Metamorfosis Real lee.**
NO aplica: estos archivos viven dentro de `lib/` (frontend Flutter), no en `firestore.rules` ni en colecciones. El sitio web no los consume.

**7.2 Eliminar algo que se re-active en una rama paralela.**
Bajo. Carlos confirmó que el branch activo es `mvp-core-clean`; cualquier rama con estos archivos hubiera tenido conflictos de import ya. Si en el futuro se quisiera resucitar un "analytics widget" o "phase info sheet", se rescata desde `git log` y se reescribe contra las APIs vigentes (no contra las que estos archivos asumían).

**7.3 Eliminar `body_composition_editor_sheet.dart` cuando alguien quiera referenciarlo.**
SPEC-92 ya documentó que es huérfano y out-of-scope. El editor activo es `EditBiometryValueSheet` (auth feature). Limpieza coherente con SPEC-92.

**7.4 Pérdida de "intent" histórico.**
Estos archivos contenían ideas válidas (analytics de macros, panel de detalle por pilar, validator con UI feedback). El `git log` y `git show <commit>:<path>` preservan la historia. Si el equipo quiere revivir alguna idea, está disponible.

# 8. Out of scope

- Limpiar `unused_import` y `prefer_const` en archivos vivos (~30 ocurrencias).
- Migrar `dialogBackgroundColor → DialogThemeData.backgroundColor` (~7 ocurrencias).
- Migrar `androidProvider / appleProvider / webProvider → providerAndroid / providerApple / providerWeb` en AppCheck (deprecation reciente de `firebase_app_check`).
- Refactor de cualquier archivo vivo.
- Tocar `lib_structure.txt` (parece ser un dump generado; no afecta el build).

# 9. Resultado

(Se completa al cerrar el SPEC.)
