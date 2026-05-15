# SPEC-105 — Bloquear card de Comidas mientras hay ayuno activo

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Regla de negocio + UX defensivo
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §2 (cronología del ayuno) — comer durante el ayuno rompe el bloqueo de insulina, la cetogénesis y el cómputo del IMR.

---

# 1. Contexto

Hoy si el usuario tiene un ayuno activo, la card de "Nutrición Científica" sigue funcional. Puede tocar "Registrar Desayuno" o "Registrar comida pasada" y persistir comidas que contradicen su propio ayuno. Eso:
- Rompe el protocolo (no es un ayuno real si come).
- Contamina el cómputo del IMR (el bloque metabólico asume insulina deprimida).
- Confunde al usuario sobre si "estoy ayunando" significa algo.

Carlos pidió: bloquear la card de Comidas durante ayuno activo, con visual tenue + diálogo educativo si el usuario insiste en tocarla.

# 2. Solución

**2.1 Card de Comidas en estado pausado.**
- Opacity 0.5 a todo el contenido cuando `fastingState.isActive == true`.
- Banner superior visible y siempre opaco: `🔒 Pausado durante ayuno activo`.
- Los tres botones (`Registrar Desayuno`, `Registrar comida pasada`, `Deshacer última comida`) con `onPressed: null` (visualmente disabled).
- Tap sobre la card abre el diálogo educativo `MealsLockedDuringFastingDialog`.

**2.2 PillarRing de Comidas dimmed.**
- Cuando `fastingState.isActive == true`, el PillarRing de Comidas en la fila "PILARES HOY" recibe alpha reducido (50%) para señal visual consistente.
- Sigue tappable — el usuario PUEDE seleccionarlo para ver la card en estado pausado y entender qué pasa.

**2.3 Diálogo `MealsLockedDuringFastingDialog`.**
- Título: "Estás en ayuno activo"
- Mensaje: "Registrar una comida ahora rompería tu protocolo de ayuno y contaminaría el cómputo de tu IMR. Para registrar comidas, primero termina tu ayuno desde la tarjeta de Ayuno."
- Botón primario: "Ir a tarjeta de Ayuno" → cambia `_selectedPillar = ayuno`.
- Botón secundario: "Entendido" → cierra el diálogo.

# 3. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear diálogo | `lib/src/features/dashboard/presentation/widgets/meals_locked_dialog.dart` |
| 2 | Pasar `isFastingActive` a `_buildComidasCard` y aplicar opacity + banner + handlers bloqueados | `dashboard_screen.dart` |
| 3 | Bajar alpha del PillarRing de Comidas cuando ayuno activo | `dashboard_screen.dart` |

# 4. Criterios de aceptación

1. Con ayuno activo y card Comidas seleccionada → banner visible "🔒 Pausado durante ayuno activo".
2. Contenido del card con opacity 0.5.
3. Tap en cualquier parte de la card → diálogo educativo.
4. Tap en "Ir a tarjeta de Ayuno" → cambia el pilar seleccionado y cierra el diálogo.
5. PillarRing de Comidas con alpha 0.5 cuando ayuno activo (sigue tappable).
6. Cuando se finaliza el ayuno (`isActive = false`), card y PillarRing vuelven a su estado normal automáticamente.
7. `flutter analyze` y `flutter test` sin regresiones.

# 5. Riesgos

**5.1 Usuario quiere registrar una comida pasada que sí fue válida** (ej. cerró su ayuno hace 10 min pero la app no se enteró).
Mitigación: el botón "Corregir hora de inicio del ayuno" (SPEC-97) ya cubre el caso inverso. Si el usuario terminó su ayuno, debe finalizarlo formalmente antes de registrar comida — eso es el flujo correcto. No es restricción excesiva.

**5.2 Diálogo demasiado intrusivo si el usuario solo quiere mirar la card.**
Mitigación: solo se dispara al tocar los botones o el área central del card (donde están los botones). El header con banner queda visible y el usuario puede ver el estado sin disparar el diálogo.

# 6. Out of scope

- Aplicar la misma regla a Hidratación durante ayuno (el agua sí es permitida en ayuno — no aplica).
- Notificación push "estás cerca de terminar tu ayuno" antes de que el usuario intente registrar comida.
- Permitir registrar bebidas "permitidas en ayuno" (café negro, té) — flujo distinto, fuera de scope.

# 7. Resultado

(Se completa al cerrar el SPEC.)
