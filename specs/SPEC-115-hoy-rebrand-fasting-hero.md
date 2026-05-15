# SPEC-115 — Rebrand "Dashboard" → "Hoy" + Reposicionamiento del IMR

**Estado:** En implementación
**Fecha:** 2026-05-15
**Líder:** Carlos
**Implementación:** Claude

---

## Motivación

La pantalla actualmente etiquetada "Dashboard" cumple tres funciones:
1. **Estado del día actual** (reloj circadiano, fase del ayuno, ventana).
2. **Acciones de registro** (CTAs por pilar).
3. **Comunicación** (banners, sugerencias adaptativas).

Tres problemas:

1. **Nombre genérico.** "Dashboard" arrastra carga de panel de control corporativo. No comunica que es la pantalla del *presente* — eje temporal opuesto a "Análisis" (histórico).

2. **IMR redundante en el centro.** El IMR es una métrica derivada cuya utilidad es interpretativa (tendencia, delta, comparativa). Ya tiene jerarquía visual en Análisis (`PeriodHeroCard` + `ImrTrendChart`). Replicarlo como número grande en el centro del reloj del día:
   - Compite con los CTAs de acción.
   - No es accionable a la escala del día (un `75` no le dice al usuario qué hacer ahora).
   - Sube y baja con cada cambio de pilar sin que el usuario entienda por qué.

3. **El espacio más valioso de la app (centro del círculo) está ocupado por una métrica no accionable.** Ese espacio debería conducir hacia la práctica metabólica principal: el ayuno.

## Decisión

1. Renombrar la pantalla "Dashboard" a **"Hoy"** en el BottomNavigationBar.
2. Reemplazar el componente `IMR SCORE / 75` del centro del `CircadianClock` por un nuevo widget `FastingHeroDisplay` que muestra el estado del ayuno y el próximo hito metabólico relevante.
3. **No tocar Análisis** — el IMR sigue siendo la métrica central ahí.

## Comportamiento de `FastingHeroDisplay`

Tres modos visuales, decididos por el `FastingState` + el `EatingWindowState`:

### Modo A — Ayuno en curso (`isActive == true`)
```
   AYUNO EN CURSO
   
     14:23:47
   
   ⚡ Autofagia en 3h 42m
```

- Label superior: "AYUNO EN CURSO" (pequeño, opaco).
- Cronómetro ascendente HH:MM:SS desde `startTime`, font grande monospace.
- Próximo hito metabólico: usa `FastingState.nextMilestoneLabel` y `timeRemainingForNextMilestone`. Iconografía según fase (water_drop, fire, recycle).

### Modo B — Ayuno completado hoy (`completedToday == true`)
```
   AYUNO COMPLETADO
   
      16h 02m
   
   ✓ Próximo: mañana 17:00
```

- Label superior: "AYUNO COMPLETADO".
- Duración total alcanzada (texto, no cronómetro).
- Próximo ayuno proyectado (texto estático).

### Modo C — En ventana de alimentación (`!isActive && eatingWindow != null && windowEnd > now`)
```
   PRÓXIMO AYUNO
   
      4:27:18
   
   🌙 Cierra ventana 20:30
```

- Label superior: "PRÓXIMO AYUNO".
- Countdown HH:MM:SS hasta `eatingWindow.windowEnd`.
- Etiqueta: hora de cierre programada.

### Modo D — Fallback (sin data útil)
```
   AYUNO
   
   — — : — — : — —
   
   Toca Iniciar Ayuno
```

## Archivos afectados

| Archivo | Cambio |
|---|---|
| `lib/src/features/dashboard/presentation/widgets/fasting_hero_display.dart` | **Nuevo.** Widget que reemplaza la Column del IMR. |
| `lib/src/features/dashboard/presentation/widgets/circadian_clock.dart` | Reemplaza CAPA 3 (IMR SCORE) por `FastingHeroDisplay`. Quita parámetro `score`. |
| `lib/src/features/dashboard/presentation/dashboard_screen.dart` | Llamada al `CircadianClock` sin `score`. BottomNav: label "Hoy". |
| `lib/src/features/analysis/presentation/analysis_screen.dart` | BottomNav: label "Hoy" en index 0. |
| `lib/src/features/auth/presentation/profile_screen.dart` | BottomNav: label "Hoy" en index 0. |

## Lo que NO cambia

- Rutas internas (`/dashboard` se mantiene para no romper deep links).
- Lógica del IMR (cálculo + persistencia + presentación en Análisis).
- 5 anillos de pilares ni cards de soporte.
- Header de la pantalla ("Metamorfosis Real" + saludo + streak).

## Riesgo y rollback

- **Riesgo:** bajo. Solo afecta presentación. Sin migraciones de datos. Sin cambios de scoring ni de persistencia.
- **Rollback:** revertir un commit. El IMR sigue calculándose y persistiéndose igual; revertir solo restaura su presentación en el centro del reloj.

## Criterios de aceptación

1. El BottomNav muestra "Hoy" en lugar de "Dashboard" en las 3 pantallas (Dashboard, Análisis, Perfil).
2. El centro del reloj circadiano nunca muestra "IMR SCORE / 75".
3. Con ayuno activo: cronómetro live HH:MM:SS + próximo hito.
4. Con ayuno completado hoy: duración total + texto del próximo ayuno.
5. En ventana de alimentación: countdown HH:MM:SS al `windowEnd`.
6. Sin estado activo ni completado: placeholder con CTA implícito.
7. El IMR sigue disponible en Análisis con su rediseño SPEC-113.
