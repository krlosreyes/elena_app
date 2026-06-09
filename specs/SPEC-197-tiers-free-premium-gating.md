# SPEC-197 — Tiers Free / Premium + gating

**Estado:** APPROVED-DESIGN — pendiente de implementación (Ola C).
**Versión:** 0.1 (draft)
**Tipo:** Monetización — gating de features por entitlement.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola C (Monetización) — Semana 4–6.
**Estimación:** ~3 días.
**Depende de:** SPEC-196 (`entitlementProvider.isPremium`).
**Bloquea:** SPEC-198 (el paywall promete justo lo que aquí se gatea).

---

## 1. Contexto

Con la infra de cobro (SPEC-196) lista, hay que decidir **qué es gratis y qué es de pago** y aplicarlo en código sin romper la tesis del producto: *dejar probar el valor antes de cobrar*. Un free demasiado pobre ahuyenta; uno demasiado rico no convierte.

---

## 2. Decisión de tiers (reconciliada)

> **Nota de diseño.** El doc de monetización (`05_MONETIZACION`) sugería "Free = 1–2 pilares". La Definición de Hecho del plan (`09_PLAN_DE_ACCION`) dice "Free = registro + IMR del día + 1 acción de coaching/día". **Esta SPEC adopta la segunda** y la precisa abajo: NO castigamos el registro básico de los 5 pilares (capar el logging mata la demostración de valor del IMR), sino que gateamos el *coaching profundo, la longitudinalidad y la automatización*. Carlos: confirmar este criterio antes de implementar.

| Capacidad | Free | Premium |
|---|---|---|
| Registro de los 5 pilares | ✅ | ✅ |
| IMR del día (Score del Día) | ✅ | ✅ |
| Acciones de coaching (Next Best Action) | **1 / día** | ilimitadas + secundaria |
| Feedback de cierre de ciclo (coaching) | ❌ | ✅ |
| IMR longitudinal + histórico de Análisis | ❌ (solo hoy) | ✅ |
| Sync automático de wearables (HealthKit/Health Connect) | ❌ (registro manual) | ✅ |
| Explicabilidad / "saber más" (citas) | ✅ | ✅ |

Racional: Free demuestra el ciclo completo *un toque al día* (registro + IMR + 1 consejo). Premium vende lo que crea hábito y retención: coaching continuo, ver la tendencia, y dejar de teclear (auto-sync).

---

## 3. Lo que NO se hace aquí

- **NO** se construye el paywall ni el trial (SPEC-198) — aquí solo se *gatea* y se expone un hook `requierePremium()` que SPEC-198 conectará al paywall.
- **NO** se toca la infra de cobro (SPEC-196).
- **NO** se gatea el registro de pilares ni el IMR del día (decisión §2).

---

## 4. Arquitectura

```
billing/
 ├── application/
 │    └── feature_gate.dart            # FeatureGate enum + gating puro (premium? / límite diario)
 └── presentation/
      └── premium_lock.dart            # widget envoltorio: muestra contenido o un lock+CTA al paywall (hook SPEC-198)
```

`FeatureGate` es Dart puro y testeable: recibe `EntitlementStatus` (+ contadores de uso del día) y responde `allowed/locked`. La UI usa `PremiumLock` o lee `featureGateProvider`.

### Puntos de gating (callsites)
- **Coaching 1/día:** `coachingSelectionProvider` (o el card) consulta el gate; si free y ya mostró su acción del día (reusa `CoachingFatigueNotifier.shownTodayActionIds` de SPEC-194 RF-2.5), la siguiente queda bloqueada con CTA.
- **Feedback de cierre:** `CycleCoachingFeedbackCard` solo renderiza si premium.
- **Análisis longitudinal/histórico:** la pantalla de Análisis muestra solo "hoy" en free; el histórico/tendencia va tras `PremiumLock`.
- **Auto-sync wearables:** `healthAutoSyncControllerProvider` no corre el ciclo si free (queda registro manual).

---

## 5. Requisitos funcionales

### RF-197-01 — `featureGateProvider`
Provider que combina `entitlementProvider` + contadores de uso (coaching del día) y expone helpers: `bool isPremium`, `bool coachingActionAllowedToday`, `bool analyticsHistoryAllowed`, `bool autoSyncAllowed`, `bool cycleFeedbackAllowed`.

### RF-197-02 — Gate de coaching (1/día en free)
Free ve **1** Next Best Action por día. La segunda (o la del día siguiente sin haber pasado medianoche) se reemplaza por una tarjeta "Desbloquea coaching ilimitado" (CTA a paywall, hook de SPEC-198). Premium: sin límite + secundaria.

### RF-197-03 — Gate de feedback de cierre
`coachingClosureFeedbackProvider`/card solo activos en premium.

### RF-197-04 — Gate de Análisis
Free: IMR del día y vista del día. Histórico, tendencia longitudinal y comparativas tras `PremiumLock`.

### RF-197-05 — Gate de auto-sync
`healthAutoSyncController.runIfDue()` no ejecuta en free. El registro manual de todos los pilares sigue disponible.

### RF-197-06 — `PremiumLock` widget
Envuelve cualquier contenido premium: si premium → muestra el hijo; si free → muestra un overlay sutil + CTA. El CTA llama un callback `onUpgrade` (SPEC-198 lo conecta al paywall). Sin lógica de cobro aquí.

### RF-197-07 — Telemetría
`feature_gate_blocked` (param: `feature`) cuando un free toca un muro. Insumo de conversión (qué muro convierte más) para SPEC-198/GATE.

---

## 6. Tests (CONSTITUTION §9)

- **Unit `FeatureGate`:** free vs premium → allowed/locked por cada capacidad; coaching del día (0 mostradas→permite, 1→bloquea en free, premium siempre permite).
- **Widget `PremiumLock`:** premium muestra el hijo; free muestra lock + dispara `onUpgrade`.
- **Provider:** `featureGateProvider` reacciona a cambios de `entitlementProvider` (free→premium desbloquea en vivo).

---

## 7. Definición de Hecho

Free = registro + IMR del día + 1 acción de coaching/día. Premium = coaching completo (ilimitado + feedback de cierre) + 5 pilares con análisis histórico/longitudinal + sync automático. Gating verificado por tests; al volverse premium, las features se desbloquean en vivo sin reiniciar.

---

## 8. Riesgos

- **Free percibido como inútil o como "todo gratis".** Mitigación: el corte (coaching continuo + tendencia + auto-sync) es exactamente lo que crea hábito; se validará la conversión en Ola G.
- **Gating disperso → fugas.** Mitigación: un único `featureGateProvider` como fuente; los callsites solo preguntan, no deciden.
- **Capar de más mata la demostración de valor.** Mitigación: decisión §2 (no se gatea el registro ni el IMR del día).
