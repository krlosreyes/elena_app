# SPEC-110 — Pantalla Análisis "Hoy": anillo central de IMR + 5 satélites de pilar

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-15
**Tipo:** Feature UI nueva
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §6 (5 pilares). Inspiración: Apple Activity Rings.

---

# 1. Contexto

La pantalla de Análisis quedó en blanco (SPEC-109) lista para rediseño. Carlos validó dirección: adoptamos la metáfora "anillos de actividad" de Apple Fitness pero con 5 pilares y métrica unificada (IMR). Resolución arquitectónica acordada: **anillo central grande con IMR + 5 satélites pequeños** alrededor (uno por pilar), porque 5 anillos concéntricos del mismo centro saturan visualmente.

Alcance de esta SPEC: **solo vista de "Hoy"**. Persistencia diaria y vista calendario quedan para SPEC-111 y SPEC-112. Los días pasados en el strip semanal se muestran con anillos placeholder (sin datos reales) como decisión MVP — el rediseño funciona hoy sin necesidad de cambios al schema de Firestore.

# 2. Diseño visual

```
                    ANÁLISIS · HOY 15 MAY                       
                                                                
   [L]    [M]    [M]    [J]    [V]    [S]    [D]                
    ◌      ◌      ◌      ◌      ⊙      ◌      ◌      ← strip semanal
                                ↑                                
                            día activo                           
                                                                
              ╭─────────────────────────────╮                   
              │  🌙             💧          │                   
              │  Sueño          Hidrat.     │                   
              │     ┌──────────┐            │                   
              │     │   IMR    │            │  ← anillo central  
              │     │    72    │            │     IMR del día    
              │     └──────────┘            │                   
              │  🍴             💪          │                   
              │  Comidas        Ejercicio   │                   
              │              ⏱️             │                   
              │             Ayuno           │                   
              ╰─────────────────────────────╯                   
                                                                
   RACHA ACTIVA · 12 días con IMR ≥ 65                          
                                                                
   PILARES DE HOY                                               
   ┌───────────────────────────────────────────────┐            
   │ ⏱️ Ayuno     16h / 18h     ████████░░  88%   │            
   │ 🌙 Sueño     7h 30m · ★★★★  ██████████ 100%  │            
   │ 💧 Hidratación  2.1 / 2.5 L ████████░░  84%   │            
   │ 💪 Ejercicio  35 / 60 min   ██████░░░░  58%   │            
   │ 🍴 Comidas    3 / 3         ██████████ 100%  │            
   └───────────────────────────────────────────────┘            
```

# 3. Componentes nuevos

| Archivo | Rol |
|---|---|
| `lib/src/features/analysis/domain/daily_summary.dart` | Value object puro: `imrScore` + 5 doubles 0.0..1.0 (% por pilar) + flags de cumplimiento |
| `lib/src/features/analysis/application/daily_summary_provider.dart` | Provider derivado que computa `DailySummary` agregando los providers de pilares + displayedImr |
| `lib/src/features/analysis/presentation/widgets/imr_ring_with_satellites.dart` | Widget visual: CustomPaint del anillo central + Stack con 5 satélites posicionados |
| `lib/src/features/analysis/presentation/widgets/weekly_strip.dart` | Strip horizontal con 7 micro-anillos (L-D). Día actual usa `dailySummary`, otros muestran placeholder en gris |
| `lib/src/features/analysis/presentation/widgets/streak_summary_card.dart` | Card "RACHA ACTIVA" usando `streakProvider` existente |
| `lib/src/features/analysis/presentation/widgets/pillar_progress_row.dart` | Una fila por pilar: icono + label + métricas + barra de progreso |

Y reescritura del shell:
- `lib/src/features/analysis/presentation/analysis_screen.dart` (placeholder → vista compuesta).

# 4. Mapeo de datos por pilar

`DailySummary.compute(...)` agrega lo que ya está en providers:

| Pilar | Fuente | Cálculo del 0..1 |
|---|---|---|
| Ayuno | `fastingProvider.progressPercentage` | clamp(0,1) directo |
| Sueño | `sleepProvider.lastLog` (si es de hoy) | duración/8h * 0.7 + subjectiveQuality/5 * 0.3 (si presente, si no solo duración) |
| Hidratación | `hydrationProvider.todayLiters / target` | clamp(0,1) |
| Ejercicio | `exerciseProvider.todayMinutes / 60` | clamp(0,1) |
| Comidas | `nutritionProvider.progressPercentage` | clamp(0,1) directo |

El IMR del día viene de `displayedImrProvider` (que ya combina baseline + métricas activas, según SPEC-86).

# 5. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `DailySummary` (puro) | `domain/daily_summary.dart` |
| 2 | Tests puros del compute | `test/features/analysis/domain/daily_summary_test.dart` |
| 3 | Crear `dailySummaryProvider` | `application/daily_summary_provider.dart` |
| 4 | Painter del anillo central + helpers de geometría | `widgets/imr_ring_with_satellites.dart` |
| 5 | Strip semanal placeholder | `widgets/weekly_strip.dart` |
| 6 | Card racha activa | `widgets/streak_summary_card.dart` |
| 7 | Fila de pilar | `widgets/pillar_progress_row.dart` |
| 8 | Reescritura del shell | `presentation/analysis_screen.dart` |

# 6. Criterios de aceptación

1. La pantalla Análisis muestra el IMR del día en un anillo central grande con número al centro.
2. Alrededor del anillo central hay 5 satélites (uno por pilar) con icono, color, y arco que refleja % de progreso del día.
3. El strip semanal muestra 7 días con micro-anillos. El día actual usa data real; los otros aparecen como placeholder (anillo gris vacío).
4. La card "RACHA ACTIVA" usa `streakProvider` existente.
5. Cada pilar tiene una fila con métrica concreta (ej. "16h / 18h") + barra de progreso.
6. Cambios en el state de un pilar (ej. iniciar ayuno) se reflejan en la pantalla Análisis en tiempo real (gracias a Riverpod).
7. La BottomNavigationBar conserva navegación entre Dashboard / Análisis / Perfil.
8. `flutter analyze` sin issues nuevos. `flutter test` con +N nuevos del DailySummary.

# 7. Out of scope

- Persistencia de `DailySummary` en Firestore (SPEC-111).
- Vista calendario mensual (SPEC-112).
- Strip semanal con datos históricos reales (depende de SPEC-111).
- Animación de transición entre días.
- Comparación con ayer o promedio.
- Gráficos de tendencia (los widgets `trend_chart.dart`, `insight_card.dart`, `weekly_report_card.dart` siguen huérfanos hasta que el rediseño los necesite).
- Compartir captura del día (botón export del Apple Activity).

# 8. Riesgos

**8.1 5 satélites posicionados visualmente.**
Geometría: cada satélite a un ángulo fijo alrededor del anillo central. 5 ángulos: 0°, 72°, 144°, 216°, 288° (pentágono). Riesgo: en pantallas pequeñas se ven apretados. Mitigación: tamaño responsivo al ancho disponible; si <340px usar 2 columnas en lugar de pentágono.

**8.2 `dailySummaryProvider` rebuilds por cada tick de pulse (10s).**
Heredado del comportamiento de los 5 providers de pilar. Aceptable porque la pantalla no anima.

**8.3 Strip semanal placeholder confuso.**
El usuario podría pensar que faltan datos. Mitigación: anillos en alpha 0.15 con dot en el día actual + tooltip al tap "Los días pasados estarán disponibles cuando habilitemos el histórico (próxima versión)".

# 9. Resultado

(Se completa al cerrar el SPEC.)
