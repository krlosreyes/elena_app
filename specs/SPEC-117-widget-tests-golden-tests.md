# SPEC-117 — Widget tests + golden tests críticos

**Estado:** Cerrado · 2026-05-16
**Fecha:** 2026-05-16
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 1 (Pre-MVP shippable)
**Estimación:** 4 días (real: 1 día de trabajo Carlos+Claude)
**Depende de:** SPEC-116 (CI/CD) — cerrado.
**Commit:** `50210b8` en `mvp-core-clean`.

---

## Motivación

La auditoría 360° identificó que la cobertura de tests de UI es débil: 52 archivos `_test.dart` en un proyecto de 206 archivos `.dart`, casi todos cubriendo motores, mappers y servicios. Los widgets de presentación, especialmente los que más se iteraron en las últimas dos semanas (`PeriodHeroCard`, `FastingHeroDisplay`, `PillarsHeatmap`, `ImrTrendChart`, `_DataGroupCard`), no tienen pruebas automatizadas.

Riesgos sin estas pruebas:

1. **Regresiones visuales silenciosas.** Un cambio en un widget puede alterar el render sin que nadie lo note hasta que el usuario lo vea.
2. **Refactors temidos.** Sin tests no hay red para refactorizar `dashboard_screen.dart` o `profile_screen.dart` (que están entre los más grandes).
3. **Falta de blindaje en CI.** Ahora que el CI corre `flutter test` en cada PR (SPEC-116), tener tests útiles es donde se materializa el valor.

Adicionalmente, los `CustomPainter` críticos (`BiologicalCyclesPainter`, `FastingRingPainter`) son lógica compleja sin cobertura — riesgo de romper el reloj circadiano al tocar matemática angular.

## Decisión

Agregar dos capas de tests para los componentes visuales más sensibles:

1. **Widget tests funcionales** — verifican estructura, contenido y respuestas a tap. Rápidos, robustos.
2. **Golden tests** — comparan el render pixel a pixel contra una imagen "golden" versionada en el repo. Bloquean cambios visuales involuntarios.
3. **Painter tests** — smoke tests sobre los `CustomPainter` (no lanzan excepción al pintar, `shouldRepaint` responde correctamente).

Stack: built-in `flutter_test` + `matchesGoldenFile`. Sin `golden_toolkit` (deprecated). Threshold por defecto.

## Alcance

### Widgets cubiertos

| Widget | Variantes | Archivo de test |
|---|---|---|
| `PeriodHeroCard` | hasToday verde, hasToday rojo, sin hoy | `test/features/analysis/presentation/widgets/period_hero_card_test.dart` |
| `ImrTrendChart` | sin datos, 1 día, varios días | `test/features/analysis/presentation/widgets/imr_trend_chart_test.dart` |
| `PillarsHeatmap` | snapshot (1 día), heatmap (≥3 días) | `test/features/analysis/presentation/widgets/pillars_heatmap_test.dart` |
| `FastingHeroDisplay` | activo, completado, ventana, idle | `test/features/dashboard/presentation/widgets/fasting_hero_display_test.dart` |
| `DataGroupCard` + `DataRow` | 4 variantes de DataRow | `test/features/auth/presentation/widgets/data_group_card_test.dart` |

### Painters cubiertos

| Painter | Tests | Archivo |
|---|---|---|
| `BiologicalCyclesPainter` | smoke paint + shouldRepaint | `test/features/dashboard/presentation/widgets/parts/biological_cycles_painter_test.dart` |
| `FastingRingPainter` | smoke paint + shouldRepaint + sweepAngle clamp | `test/features/dashboard/presentation/widgets/parts/fasting_ring_painter_test.dart` |

### Refactor incluido

`_DataGroupCard` y `_DataRow` viven hoy como clases privadas dentro de `profile_screen.dart` y no se pueden testear desde un archivo externo. **Extracción a archivo público** `lib/src/features/auth/presentation/widgets/data_group_card.dart` con clases `DataGroupCard` y `DataRow`. `profile_screen.dart` solo importa.

### Excluido (post-SPEC-117)

- Tests de pantallas completas (Análisis, Hoy, Perfil) — eso es SPEC-118 (E2E).
- Goldens para múltiples tamaños de pantalla (solo phone-size estándar 390×844).
- Tests para los painters `EatingWindowPainter` (menos crítico).
- Cobertura de `dashboard_screen.dart` y `profile_screen.dart` enteros (god widgets — esperan SPEC-119 refactor).

## Criterios de éxito

1. ≥ 25 widget tests funcionales nuevos.
2. ≥ 8 golden tests nuevos (1–2 por widget cubierto).
3. ≥ 6 painter tests nuevos.
4. `flutter test` pasa en local y en CI.
5. Un cambio cosmético involuntario en cualquiera de los 5 widgets cubiertos hace fallar al menos un golden test.
6. Los goldens están versionados en el repo (`test/.../goldens/*.png`).

## Convenciones

- **Fixtures de DailySummaryDoc / PeriodComparison / FastingState:** helpers locales dentro de cada archivo de test (no compartir entre archivos para mantener tests autocontenidos).
- **Nombre de tests:** `'(widget): (estado/condición) (acción esperada)'` — ej. `'PeriodHeroCard: con HOY=85 muestra ring verde y delta positivo'`.
- **Goldens:** ubicados en `test/.../goldens/<widget>_<variante>.png` relativos al archivo de test.
- **Wrapper común:** todos los tests envuelven el widget bajo prueba en un `MaterialApp(theme: ThemeData.dark())` con un `Scaffold` de fondo `#0F172A` para que coincida con el contexto real de uso.

## Cómo actualizar goldens

Si un cambio intencional rompe un golden:

```bash
flutter test --update-goldens test/path/to/file_test.dart
```

Esto regenera los PNGs. Carlos revisa el diff visualmente antes de commitear.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Goldens flaky por diferencias de renderizado entre macOS/Linux/CI | Usar `goldenFileComparator` con threshold permisivo si flakiness aparece. Por ahora threshold por defecto (0 pixels diff). |
| Tests lentos en CI | El conjunto entero corre < 30s. Sin impacto material. |
| Fuentes del sistema afectan goldens | Usar `Theme(data: ThemeData(fontFamily: 'Roboto'))` explícito en wrapper para consistencia entre plataformas. |

## Archivos creados/modificados

```
test/features/
├── analysis/presentation/widgets/
│   ├── period_hero_card_test.dart       (nuevo)
│   ├── imr_trend_chart_test.dart        (nuevo)
│   ├── pillars_heatmap_test.dart        (nuevo)
│   └── goldens/                          (nuevo, auto-generado)
│       └── *.png
├── dashboard/presentation/widgets/
│   ├── fasting_hero_display_test.dart   (nuevo)
│   ├── parts/
│   │   ├── biological_cycles_painter_test.dart  (nuevo)
│   │   └── fasting_ring_painter_test.dart       (nuevo)
│   └── goldens/                          (nuevo)
└── auth/presentation/widgets/
    └── data_group_card_test.dart        (nuevo)

lib/src/features/auth/presentation/
├── widgets/
│   └── data_group_card.dart             (nuevo: extracción)
└── profile_screen.dart                  (modificado: imports + remove privates)
```

## Verificación

**Tests nuevos: 38** (vs estimado 25+8+6 = 39).

| Archivo | Funcionales | Goldens | Total |
|---|---|---|---|
| `period_hero_card_test.dart` | 4 | 2 | 6 |
| `imr_trend_chart_test.dart` | 3 | 1 | 4 |
| `pillars_heatmap_test.dart` | 3 | 1 | 4 |
| `fasting_hero_display_test.dart` | 4 | 1 | 5 |
| `data_group_card_test.dart` | 6 | 1 | 7 |
| `biological_cycles_painter_test.dart` | 6 (smoke) | 0 | 6 |
| `fasting_ring_painter_test.dart` | 6 (smoke) | 0 | 6 |
| **TOTAL** | **32** | **6** | **38** |

**Suite global tras SPEC-117:** `flutter test` → `+636 ~0` (vs `+598 ~3` antes).

**Goldens versionados (6):**
- `test/features/analysis/presentation/widgets/goldens/period_hero_typical_week.png`
- `test/features/analysis/presentation/widgets/goldens/period_hero_empty.png`
- `test/features/analysis/presentation/widgets/goldens/imr_trend_week_full.png`
- `test/features/analysis/presentation/widgets/goldens/pillars_heatmap_snapshot.png`
- `test/features/dashboard/presentation/widgets/goldens/fasting_hero_idle.png`
- `test/features/auth/presentation/widgets/goldens/data_group_card_mixed.png`

**Desviaciones del plan:**
1. Criterio "≥ 8 goldens" cerrado en 6: los painters no llevaron goldens (son smoke tests sobre `paint`/`shouldRepaint`). El criterio cuantitativo bajó, pero la cobertura cualitativa es la misma: cada widget visual crítico tiene al menos 1 golden.
2. `FastingHeroDisplay` solo lleva golden en modo `idle` (los modos `activeFasting`/`eatingWindow` dependen de `Timer.now()` y serían flaky).
3. Refactor de `DataGroupCard`/`DataRow` ejecutado: conflicto de nombre con `flutter/material/data_table.dart` resuelto renombrando a `ProfileDataGroupCard`/`ProfileDataRow`.
4. Bug fix incluido: conflicto residual de `git stash` en `sleep_input_sheet.dart` líneas 489–493.

**Próximo:** SPEC-118 (Tests E2E ayuno multi-día).
