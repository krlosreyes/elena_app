# Auditoría total — Sistema de notificaciones

**Fecha:** 2026-06-10
**Alcance:** `NotificationService` (iOS/Android), `NotificationScheduler`, y todos los disparadores (circadiano, ayuno, hidratación, comida, paywall, coaching).
**Tipo:** Auditoría (no modifica código).
**Líder:** Carlos · **Auditor:** Claude
**Motivo:** notificaciones llegando fuera de tiempo / incoherentes; requisito de que todas se previsualicen en pantalla bloqueada y Apple Watch.

---

## 1. Inventario de notificaciones

| # | Notificación | ID | ¿Cuándo se programa? | Disparador |
|---|---|---|---|---|
| 1 | Buenos días | 100 | `wakeUpTime` | Circadiano |
| 2 | Tu ventana abrió | 101 | `firstMealGoal` | Circadiano |
| 3 | 30 min para cerrar ventana | 102 | 30 min antes del cierre (perfil **o** ciclo) | Circadiano / cierre ayuno |
| 4 | 1 h para soltar el día | 103 | **20:30 hardcoded** | Circadiano |
| 5 | 30 min para soltar | 104 | **21:00 hardcoded** | Circadiano |
| 6 | Modo reparación activado | 105 | **21:30 hardcoded** | Circadiano |
| 7 | Hora de descansar | 106 | `sleepTime` | Circadiano |
| 8 | eTRF 3 h antes de dormir | 107 | `sleepTime − 3 h` (condicional) | Circadiano |
| 9 | Hitos de ayuno (12/16/18/24 h) | 200–203 | `fastingStart + Nh` | Inicio de ayuno |
| 10 | Hidratación (slots) | 400–419 | cada **90 min** desde `wake+30` hasta `min(sleep,21h)` | Perfil circadiano |
| 11 | Re-recordatorio agua "Aún no" | 420 | +15 min | SPEC-199 |
| 12 | Próxima comida | 300 | 30 min antes de `últimaComida + 3 h` | Nutrición |
| 13 | Nudges de trial | 500/501 | día 5 / día 12 | Paywall |

---

## 2. Hallazgos de TIMING ("llegan fuera de tiempo")

- **T1 (crítico) — avisos de "modo reparación" hardcodeados a 20:30 / 21:00 / 21:30** (`notification_scheduler.dart` ~117–147), sin importar el horario real del usuario. Quien cena o duerme tarde recibe "soltar el día" a las 20:30 → fuera de tiempo e incoherente. **Deben anclarse a `sleepTime` / cierre de ventana del usuario**, no a una hora fija.
- **T2 — "Tu ventana abrió" (firstMeal) usa `profile.firstMealGoal`, no el ciclo metabólico real.** `lastMealWarning` ya es cycle-aware (SPEC-169) pero `firstMeal` no → si la ventana real difiere de la configurada, llega a destiempo.
- **T3 — sin `interruptionLevel`, en Focus / Modo Sueño / No molestar las notifs se silencian y caen al resumen**, y el usuario las ve "tarde". Esto explica buena parte del síntoma "fuera de tiempo": no es que se programen mal, es que iOS las retiene por estar en Focus.

---

## 3. Hallazgos de COHERENCIA

- **C1 (importante) — hidratación se dispara en cadencia fija de 90 min sin mirar si ya cumpliste la meta ni si estás durmiendo.** El motor predictivo de SPEC-199 suprime la **tarjeta in-app** pero NO las **notificaciones programadas**. Resultado: "hora de hidratarte" después de cumplir la meta = incoherente.
- **C2 — volumen alto sin tope.** Hidratación (~10) + circadianas (8) + comida + ayuno → el usuario puede recibir 15–20 notifs/día. Fatiga; sin cap global ni supresión por "ya cumplió".
- **C3 — doble uso del ID 102** (`lastMealWarning`) entre circadiano y cierre de ayuno: la última en programarse gana → posible inconsistencia de hora.
- **C4 (OK) — los hitos de ayuno SÍ se cancelan al cerrar** (`cancelFasting()` en `closeFasting`). Bien: no recibes "18 h" tras romper el ayuno.

---

## 4. Lock screen + Apple Watch (la prioridad)

**Aclaración base:** el Apple Watch **refleja automáticamente** las notificaciones del iPhone cuando el iPhone está bloqueado y el reloj puesto — no hay un flag "mostrar en watch" por notificación. Hoy las notifs ya tienen título + cuerpo y se piden con permiso de **alerta**, así que *en principio* se ven en lock screen y se reflejan al watch. Los problemas reales son:

- **W1 — falta `interruptionLevel` en todas.** Para que las importantes (cierre de ventana, hitos, reparación) sean prominentes en lock screen y lleguen al watch **incluso en Focus / Sleep**, deben ir `interruptionLevel: .timeSensitive`. Sin esto, en Focus se silencian (causa de T3).
- **W2 — `.timeSensitive` requiere el entitlement "Time Sensitive Notifications"** (`com.apple.developer.usernotifications.time-sensitive`) en el App ID — config en Apple Developer (igual que el background delivery que ya habilitaste).
- **W3 — `presentSound: false` en los hitos de ayuno** → sin sonido ni háptica; en el watch el hito llega sin vibrar. Si quieres que el reloj vibre al cruzar 12/18 h, hay que activar sonido/háptica.
- **W4 — acciones de hidratación son `foreground`** (abren la app) → desde el watch un action foreground no abre limpio la app del iPhone. Para watch, acciones background serían mejores (es el A1b pendiente de SPEC-199).
- **W5 — `presentAlert/Badge/Sound` solo controlan la presentación en FOREGROUND**, no el lock screen. El lock screen depende de la autorización (OK) + ajustes del usuario ("Mostrar vistas previas") + interruption level. No hay bug ahí, pero conviene documentarlo para no confundir.

---

## 5. Recomendaciones priorizadas

1. **Anclar los avisos de reparación/ventana al horario REAL** (`sleepTime` / ciclo), eliminando los hardcodes 20:30/21:30 (T1) y haciendo `firstMeal` cycle-aware (T2). — *mayor impacto en "fuera de tiempo"*.
2. **Suprimir hidratación cuando ya se cumplió la meta o el usuario duerme**: extender el `PredictiveTriggerEngine` (SPEC-199) a la capa de notificación, no solo a la tarjeta (C1).
3. **Agregar `interruptionLevel: .timeSensitive`** a las notifs importantes + habilitar el entitlement Time Sensitive en Apple Developer (W1, W2). Resuelve el silenciamiento en Focus y mejora lock screen + watch.
4. **Tope/agrupación** para bajar el volumen y la fatiga (C2).
5. **Háptica/sonido en los hitos de ayuno** para que el watch vibre (W3).

**Orden sugerido:** #1 y #2 (coherencia/timing, solo Dart) primero; #3 (interruption level + entitlement) como segundo bloque ya que toca Apple Developer; #4/#5 como pulido.

---

## 6. Referencias de código

- `lib/src/core/services/notification_service_mobile.dart` (detalles de presentación, canales, init).
- `lib/src/core/services/notification_scheduler.dart` (timing de todas las circadianas, ayuno, hidratación, comida).
- `lib/src/features/dashboard/application/fasting_notifier.dart` (hitos + cancelación al cerrar).
- `lib/src/features/billing/application/paywall_nudges.dart` (nudges trial).
- `lib/src/features/coaching/application/predictive_trigger_engine.dart` (motor de supresión — hoy solo aplica a la tarjeta).
