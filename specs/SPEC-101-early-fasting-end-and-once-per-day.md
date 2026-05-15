# SPEC-101 — Confirmación al terminar ayuno antes del 100% + un ayuno completado por día

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** UX + regla de negocio
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §2 (fases del ayuno) y §6 (Regla 1 "Recompensar el rango 16-24h", Regla 2 "Desmitificar el vacío").

---

# 1. Contexto

Hoy el botón rojo "Finalizar Ayuno" termina el ayuno sin fricción, incluso si el usuario lleva apenas 2 horas. Y permite iniciar múltiples ayunos completados el mismo día, que no tiene sentido biológico (un 16:8 no cabe dos veces en 24h).

Carlos pidió:
1. Si el usuario toca "Finalizar Ayuno" antes del 100%, mostrar un diálogo que pregunte si está seguro y le muestre los beneficios obtenidos hasta ese punto.
2. Si confirma, terminar el ayuno e iniciar la ventana de alimentación desde ese momento.
3. Bloquear iniciar más de un ayuno por día — excepción: si el anterior fue cancelado antes del 100%, sí puede iniciar otro.

# 2. Problema

**2.1 Cancelación impulsiva sin información.**
El usuario en fase de transición (12-18h, hambre punzante hormonal) puede tocar "Finalizar" sin darse cuenta de que está a una hora de la quema de grasa activa. La app no le devuelve contexto sobre lo que está dejando atrás.

**2.2 Doble registro de ayuno completado.**
Si alguien terminó su 16:8 a las 12:00 y curiosea con la app a las 21:00, puede tocar "Iniciar Ayuno" y arrancar otro intervalo. Esos dos ayunos en 24h no caben matemáticamente y rompen el cómputo del IMR.

# 3. Solución propuesta

**3.1 Helper puro `FastingBenefits`** (`lib/src/features/dashboard/domain/fasting_benefits.dart`):

Función pura que recibe `(FastingPhase, Duration)` y devuelve la lista de beneficios concretos que el usuario obtuvo hasta ese momento. El copy se deriva de la bibliografía:

| Fase | Beneficios listados |
|---|---|
| postAbsorption (0-12h) | "Niveles de insulina descendieron a basal", "Reservas de glucógeno hepático en uso" |
| transition (12-18h) | "Iniciaste cetogénesis temprana", "Tu cuerpo cambió a quemar grasa", "Pico de adrenalina + GH preserva masa magra" |
| fatBurning (18-24h) | "Cetosis nutricional activa", "Lipólisis sostenida — quemaste grasa real", "Inflamación sistémica reducida" |
| autophagy (24-48h) | "Autofagia activa — macrófagos reciclando organelas", "IGF-1 bajo — pausa de señales de crecimiento" |
| survival (48h+) | "Estado regenerativo profundo", "Renovación celular avanzada" |

Si la fase es `none` (no hubo tiempo suficiente), devuelve `["Iniciaste el bloqueo de insulina"]` como reconocimiento mínimo.

**3.2 Diálogo `EarlyFastingEndDialog`** (`lib/src/features/dashboard/presentation/widgets/early_fasting_end_dialog.dart`):

`AlertDialog` con:
- Título: "¿Terminar el ayuno?"
- Subtitle: "Llevas Xh Ym de tus Zh objetivo (W% completado)".
- Sección "Beneficios obtenidos hasta ahora": lista con checks verdes (de `FastingBenefits.benefitsFor`).
- Nota: "Si terminas ahora, este ayuno NO contará como completado y podrás iniciar otro hoy."
- Botones:
  - "Continuar ayuno" (outline, cierra el diálogo sin acción).
  - "Sí, terminar" (rojo, devuelve `true`).
- API: `EarlyFastingEndDialog.show(context, state) → Future<bool>` (true = confirma terminar, false = cancela).

**3.3 Provider `hasCompletedFastingTodayProvider`** (`lib/src/features/dashboard/application/fasting_history_provider.dart`):

Provider derivado que observa el historial del usuario y emite `true` si hay un ayuno **completado** (`endTime != null` Y `duration >= targetHours`) cuya `endTime` está en el día calendario actual.

Implementación: para no agregar otro stream a Firestore, partimos del `lastFastingIntervalProvider` que ya existe. Si su `endTime` es de hoy Y la duración fue suficiente, retorna `true`. Edge case: si el último intervalo es la ventana actual de comida y antes hubo un ayuno completado, ese caso necesita mirar uno más atrás. Para MVP, agregamos una query simple: el último ayuno cerrado del usuario (filtrado por `isFasting=true` y `endTime != null`).

Más limpio: un nuevo stream `streamLastCompletedFasting(uid)` que devuelve el último `FastingInterval` cerrado tipo ayuno. El provider entonces compara su `endTime` con `today`.

**3.4 Cambios en `dashboard_screen.dart`:**

Botón principal "Finalizar Ayuno" — cambiar el handler:
- Si `state.progressPercentage >= 1.0`: comportamiento actual (`_showManualTimePicker`).
- Si `< 1.0`: invocar `EarlyFastingEndDialog.show`. Si retorna `true`, llamar a `confirmManualFastingEnd(DateTime.now())` directo. Si `false` o `null`, nada.

Botón principal "Iniciar Ayuno":
- Si `hasCompletedFastingTodayProvider == true`: deshabilitar (`onPressed: null`) y al tap mostrar snackbar "Ya completaste tu ayuno de hoy. Vuelve mañana para iniciar el siguiente."
- Si `false`: comportamiento actual.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear helper puro `FastingBenefits` | `lib/src/features/dashboard/domain/fasting_benefits.dart` |
| 2 | Tests puros del helper | `test/features/dashboard/domain/fasting_benefits_test.dart` |
| 3 | Crear diálogo `EarlyFastingEndDialog` | `lib/src/features/dashboard/presentation/widgets/early_fasting_end_dialog.dart` |
| 4 | Stream nuevo en data source: `streamLastCompletedFasting` | `fasting_interval_data_source.dart` + impl Firestore |
| 5 | Repo expone el método | `fasting_interval_repository.dart` + impl |
| 6 | Provider `hasCompletedFastingTodayProvider` | `lib/src/features/dashboard/application/fasting_history_provider.dart` |
| 7 | Refactor del botón principal en Dashboard | `dashboard_screen.dart` |
| 8 | Tests del stream con fake firestore | `firestore_fasting_interval_v1_source_test.dart` |

# 5. Criterios de aceptación

1. Usuario con ayuno al 50% toca "Finalizar Ayuno" → aparece el diálogo con beneficios de su fase.
2. Tap "Continuar ayuno" → diálogo cierra, ayuno sigue activo, no se persiste nada.
3. Tap "Sí, terminar" → `confirmManualFastingEnd(now)` se ejecuta, el state pasa a `isActive=false` con `startTime=now`, ventana de comida abierta a `now`.
4. Usuario con ayuno al 100% toca "Finalizar Ayuno" → NO aparece el diálogo (flow actual con picker).
5. Usuario completó su ayuno hoy → botón "Iniciar Ayuno" deshabilitado, tap → snackbar.
6. Usuario terminó un ayuno **antes** del 100% hoy (abandonado) → botón "Iniciar Ayuno" habilitado.
7. `FastingBenefits.benefitsFor(FastingPhase.postAbsorption, 6h)` retorna al menos 1 beneficio relevante.
8. `flutter analyze` sin issues nuevos.
9. `flutter test` mantiene ≥534 verdes con +M nuevos.

# 6. Pruebas

`fasting_benefits_test.dart` (puros):
- Cada fase retorna ≥1 beneficio.
- Phase `none` → mensaje mínimo "Iniciaste el bloqueo de insulina".
- Las descripciones citan terminología bibliográfica (insulina, autofagia, cetosis).

`firestore_fasting_interval_v1_source_test.dart` (con fake_cloud_firestore):
- `streamLastCompletedFasting` devuelve el último doc con `isFasting=true, endTime!=null`.
- Si no hay ninguno, emite `null`.
- Ignora intervalos abiertos (`endTime==null`).
- Ignora ventanas de comida (`isFasting=false`).

# 7. Riesgos

**7.1 Cálculo de "completado" depende de `targetHours` actual.**
Si el usuario tenía 16:8 al hacer su ayuno y luego cambia a 18:6, `targetHours` del state es 18. Un ayuno de 16h pasado quedaría "no completado" retroactivamente. Mitigación: usar siempre `state.targetHours` actual al evaluar. Edge case raro porque el cambio de protocolo durante un día es poco común (SPEC-98 lo bloquea durante ayuno activo).

**7.2 Doble ayuno legítimo.**
Caso: usuario hace 16:8 cerrando a las 12:00, y por alguna razón quiere hacer otro 16:8 cerrando a las 04:00 del día siguiente. La regla bloquea iniciar uno nuevo el día calendario donde completó. Si el usuario insiste, puede iniciar después de medianoche. Aceptable.

**7.3 Latencia del provider de historial.**
Mientras el provider aún no resolvió, el botón "Iniciar Ayuno" queda habilitado por defecto. Aceptable — si el usuario inicia, hay un intervalo abierto que dispara el flow normal. Si fuera necesario, se puede mostrar loading state pero no es bloqueante.

**7.4 Race con SPEC-99/100.**
El provider depende del schema de FastingInterval. Está alineado con SPEC-97-100. Sin riesgo.

# 8. Out of scope

- Editar la hora de fin del ayuno (solo termina con `now`).
- Notificaciones push "estás a 1h de la quema de grasa" si está a punto de cancelar (SPEC futura).
- Personalizar copy del diálogo por género/edad.
- Auditoría de cancelaciones repetidas (telemetría).
- Permitir override manual "sé lo que hago, déjame iniciar otro" — explicito de Carlos: bloqueo si ya hay completado hoy.

# 9. Resultado

(Se completa al cerrar el SPEC.)
