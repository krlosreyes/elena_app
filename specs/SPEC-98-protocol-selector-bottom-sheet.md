# SPEC-98 — Selector de protocolo de ayuno en Dashboard (bottom sheet educativo)

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Refactor UX + extensión de OptimalScheduleCalculator
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §2, §6 (Regla 2 "Desmitificar el vacío"); SPEC-96.

---

# 1. Contexto

Hoy el selector de protocolo vive en el Perfil (Profile screen) como un grid 2×4 con 8 protocolos: Ninguno, 12:12, 14:10, 16:8, 18:6, 20:4, 22:2, OMAD. El usuario tiene que navegar al Perfil para cambiarlo, que es justo el flujo opuesto a donde lo necesita (monitorea su ayuno desde el Dashboard).

Carlos pidió:
1. Mover el selector a la card "Ayuno Consciente" del Dashboard.
2. Investigar componentes UX que faciliten esta función.
3. Quitar el selector del Perfil.

Adicionalmente: el `OptimalScheduleCalculator` (SPEC-96) solo conoce 4 protocolos (`Ninguno, 16:8, 18:6, 20:4`). Los otros 4 (12:12, 14:10, 22:2, OMAD) están en el grid del perfil pero no en la lógica circadiana. Hay que cerrar ese gap.

# 2. Problema

**2.1 Friction UX.**
Para cambiar protocolo el usuario debe: Dashboard → bottom nav Perfil → scroll → tap protocolo → volver. Son 4-5 interacciones cuando debería ser 1-2.

**2.2 La card del Dashboard no menciona el protocolo activo de forma editable.**
El texto "16:8" aparece como label estático junto al cronómetro. No invita a cambiar.

**2.3 El selector del perfil ocupa pantalla.**
Grid 2×4 + card "Recomendado para ti" + descripciones (~250 líneas de código + 60% de la pantalla del perfil) para algo que el usuario configura pocas veces.

**2.4 Gap en OptimalScheduleCalculator.**
Los protocolos `12:12, 14:10, 22:2, OMAD` no tienen entrada en `_windowHoursByProtocol`. Caen al default 16:8 silenciosamente — incoherencia.

# 3. Solución propuesta

**3.1 Nuevo widget `ProtocolSelectorSheet`** (`lib/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart`).

Material 3 Modal Bottom Sheet con:
- Handle visual (4×40 px).
- Título: "Elige tu protocolo de ayuno".
- Lista vertical de 8 items.
- Cada item:
  - Container con borde tenue + radius 14.
  - Nombre del protocolo (bold, 18pt).
  - Chip de nivel con color: Principiante (cyan), Intermedio (verde), Avanzado (naranja), Extremo (rojo).
  - Descripción 1-2 líneas (la misma que vive hoy en `_buildRecommendedProtocolCard`).
  - Border + glow verde cuando es el actual.
  - Badge "Recomendado" cuando el sistema lo sugiere.
- Tap en item → `Navigator.pop(context, protocol)` con el seleccionado.
- API: `ProtocolSelectorSheet.show(BuildContext, {required String currentProtocol, String? recommended}) → Future<String?>`.

**3.2 Card "Ayuno Consciente" rediseñada.**

Cuando `fastingState.isActive == false`:
- Chip clickable "Protocolo · 16:8 ▸" entre el título "Ayuno Consciente" y la barra de progreso.
- Tap → abre `ProtocolSelectorSheet`.
- Al seleccionar, llama a `profileControllerProvider.updateFastingProtocol`.

Cuando `fastingState.isActive == true`:
- Mismo chip pero **deshabilitado visualmente** (alpha 0.4, sin icon ▸).
- Tap muestra snackbar: "No puedes cambiar protocolo durante un ayuno activo. Finaliza primero."

**3.3 Quitar del Perfil.**

Eliminar de `profile_screen.dart`:
- Sección "PROTOCOLO DE AYUNO" + subtítulo.
- `_buildProtocolSelector()` (~70 líneas).
- `_buildRecommendedProtocolCard()` (~70 líneas).
- Estado local `_fastingProtocol` y `_selectFastingProtocol()`.
- `_recommendedProtocol()`.

El protocolo sigue siendo visible en el Perfil **como read-only** (un row tipo `_readOnlyTile('Protocolo', user.fastingProtocol)`) para que el usuario sepa cuál tiene activo desde ese contexto. Para cambiarlo va al Dashboard.

**3.4 Extender `OptimalScheduleCalculator`.**

Agregar al map `_windowHoursByProtocol`:
```dart
'12:12': 12,
'14:10': 10,
'22:2': 2,
'OMAD': 1,   // Una comida al día. Ventana técnica de ~1h.
```

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear widget bottom sheet | `lib/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart` |
| 2 | Extender `OptimalScheduleCalculator` con los 4 protocolos faltantes | `lib/src/features/dashboard/domain/optimal_schedule.dart` |
| 3 | Tests del calculator con los nuevos protocolos | `test/features/dashboard/domain/optimal_schedule_test.dart` |
| 4 | Rediseñar card "Ayuno Consciente" — chip + handler | `lib/src/features/dashboard/presentation/dashboard_screen.dart` |
| 5 | Quitar selector del Perfil, dejar read-only tile | `lib/src/features/auth/presentation/profile_screen.dart` |

# 5. Criterios de aceptación

1. Tap en el chip "Protocolo · 16:8 ▸" del Dashboard abre el bottom sheet.
2. El bottom sheet muestra los 8 protocolos con descripciones y nivel.
3. El protocolo actual se distingue visualmente.
4. El sistema sugiere un "Recomendado" si aplica.
5. Tap en un protocolo persiste el cambio y cierra el sheet.
6. Si hay ayuno activo, el chip se ve deshabilitado y el snackbar lo explica.
7. `OptimalScheduleCalculator.forProtocol('12:12').windowStart` → `08:30`.
8. `OptimalScheduleCalculator.forProtocol('14:10').windowStart` → `10:30`.
9. `OptimalScheduleCalculator.forProtocol('22:2').windowStart` → `18:30`.
10. `OptimalScheduleCalculator.forProtocol('OMAD').windowStart` → `19:30`.
11. El Perfil ya no tiene grid de protocolos. Aparece el protocolo activo como read-only.
12. `flutter analyze` sin issues nuevos. `flutter test` mantiene ≥526 verdes con +M nuevos.

# 6. Pruebas

`optimal_schedule_test.dart` (actualizados):
- `forProtocol('12:12')` → windowHours=12, windowStart=08:30, fastingHours=12.
- `forProtocol('14:10')` → windowHours=10, windowStart=10:30.
- `forProtocol('22:2')` → windowHours=2, windowStart=18:30, fastingHours=22.
- `forProtocol('OMAD')` → windowHours=1, windowStart=19:30, fastingHours=23.

UI/integration tests del sheet quedan fuera (Cowork-side smoke).

# 7. Riesgos

**7.1 OMAD con ventana de 1h puede sentirse claustrofóbico en la UI del reloj.**
El sweep del arco se vuelve muy pequeño visualmente. Mitigación: aceptable — OMAD ES extremo. Si en el feedback inicial molesta, se ajusta a un default visual mínimo (ej. 2h).

**7.2 Usuarios con protocolo desconocido persistido (de versiones anteriores).**
Caen al default 16:8 del calculator. No rompe, solo no es óptimo. Aceptable porque la migración es retro-compatible.

**7.3 Cambiar protocolo mientras hay ayuno activo.**
Bloqueado en UI. El usuario podría querer extender un protocolo en curso ("ya llevo 14h, voy a extender a 18:6"). Aceptable post-MVP — la fricción ahora es deliberada para evitar corrupción de historial.

**7.4 Coherencia con SPEC-96 al cambiar protocolo.**
Cuando el usuario cambia protocolo desde el dashboard, el `eatingWindowProvider` recomputa automáticamente con la nueva ventana óptima — sin necesidad de tocar `firstMealGoal/lastMealGoal` del perfil. El usuario verá el reloj actualizado en el siguiente pulse (10s máx).

# 8. Out of scope

- Animación de transición entre protocolos en el reloj.
- Recomendador inteligente (heurística "te sugerimos avanzar a 18:6 porque ya llevas 30 días en 16:8").
- Histórico de cambios de protocolo.
- A/B testing de copy en las descripciones.

# 9. Resultado

(Se completa al cerrar el SPEC.)
