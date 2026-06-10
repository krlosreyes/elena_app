# SPEC-198 — Trial 14 días + conversión + pricing LatAm/US

**Estado:** IN-PROGRESS (2026-06-09) — inc1 (`PaywallTrigger` puro + `PaywallScreen` con precios localizados del SDK + restaurar + telemetría de conversión; `openPaywall` ahora abre el paywall real) implementado y testeado con `FakeBillingService`. **Pendiente (inc2):** nudges día 5/12 + auto-disparo del paywall vía `PaywallTrigger` (requiere fecha de registro + conteo de ayunos). Trial 14d e intro offer se configuran en tienda (Carlos, `docs/SETUP_BILLING.md`).
**Versión:** 0.1 (draft)
**Tipo:** Monetización — paywall, trial, nudges de conversión, pricing regional.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola C (Monetización) — Semana 4–6.
**Estimación:** ~3 días.
**Depende de:** SPEC-196 (Offerings + compra), SPEC-197 (qué promete el paywall = lo gateado), SPEC-169 (patrón de notificaciones), SPEC-193 (telemetría de conversión).
**Bloquea:** validación de conversión en Ola G (soft-launch).

---

## 1. Contexto

Con cobro (196) y gating (197) listos, falta la **mecánica de conversión**: dejar probar (trial), pedir el pago en el momento de valor demostrado (paywall), recordar (nudges) y cobrar el precio correcto por región. Modelo elegido (doc 05): **freemium con trial + suscripción**, no hard paywall — en health & fitness la conversión trial→pago mediana ronda ~40%.

---

## 2. Decisiones de producto

### 2.1 — Trial de 14 días
Intro offer de 14 días en los productos de tienda (lo aplica RevenueCat vía el producto, no el cliente). 14 es punto de partida seguro; experimentar subiéndolo (17–32 convierte más) queda para iteración.

### 2.2 — Paywall tras valor demostrado, no al arranque
El paywall se ofrece cuando el usuario ya vio valor:
- tras **1 ayuno completado**, **o**
- al **día 7** desde el registro,
lo que ocurra primero. Nunca bloquea el onboarding.

### 2.3 — Pricing regional
| Tier | LatAm | US/EU |
|---|---|---|
| Mensual | US$4.99 | US$9.99 |
| Anual (descuento) | US$39.99 | US$79.99 |

El pricing por región lo resuelve la tienda (price tiers por storefront) + Offerings de RevenueCat; el cliente solo muestra el precio localizado que devuelve el SDK (`package.storeProduct.priceString`). **Nunca se hardcodea el precio en la app.**

### 2.4 — Nudges día 5 y 12
Notificaciones locales (vía `NotificationService`, patrón SPEC-169) recordando el valor y el fin de trial. Tono humano (memoria de tono de notificaciones), sin culpa.

---

## 3. Lo que NO se hace aquí

- **NO** se reimplementa cobro (196) ni gating (197).
- **NO** se hardcodean precios — se leen del SDK.
- **NO** hard paywall (no se bloquea el uso base; se ofrece upgrade).

---

## 4. Arquitectura

```
billing/
 ├── application/
 │    └── paywall_trigger.dart         # decide cuándo ofrecer el paywall (1 ayuno completado | día 7), Dart puro
 └── presentation/
      ├── paywall_screen.dart          # UI: tiers desde Offerings, precios localizados, CTA comprar + restaurar
      └── paywall_controller.dart      # orquesta purchase()/restore() de SPEC-196 + telemetría
notifications: reusa NotificationService (nudges día 5/12)
```

`paywall_trigger` es función pura (recibe: díasDesdeRegistro, ayunosCompletados, yaEsPremium, yaVioPaywallHoy) → bool. Testeable sin UI.

---

## 5. Requisitos funcionales

### RF-198-01 — Productos con trial
Los productos de tienda llevan intro offer de 14 días (config de Carlos en App Store Connect / Play Console). El cliente detecta trial vía `EntitlementSource.trial` (SPEC-196).

### RF-198-02 — `PaywallScreen`
Muestra los packages de la Offering "default" (mensual/anual) con **precio localizado del SDK**, beneficios (lo que SPEC-197 gatea como premium), botón comprar (por package) y **"Restaurar compras"** (RF-196-06). Maneja: compra ok → cierra y desbloquea; cancelada → vuelve sin error; error → mensaje claro.

### RF-198-03 — `paywall_trigger`
Ofrece el paywall cuando `(ayunosCompletados ≥ 1 || díasDesdeRegistro ≥ 7) && !premium && !vistoHoy`. No interrumpe onboarding ni un flujo activo (se muestra al volver al Home).

### RF-198-04 — Hook de `PremiumLock` (SPEC-197)
El `onUpgrade` de cada `PremiumLock` y la tarjeta "desbloquea coaching" abren el `PaywallScreen`.

### RF-198-05 — Nudges día 5 y 12
Programar dos notificaciones locales (día 5: "mira tu tendencia"; día 12: "tu trial termina en 2 días"). Se cancelan si el usuario ya es premium. Tono humano.

### RF-198-06 — Telemetría de conversión (con SPEC-193)
`paywall_shown` (param: trigger=ayuno|dia7|lock), `paywall_dismissed`, `trial_started`, `purchase_completed` (param: product, period), `purchase_restored`, `purchase_failed` (param: reason). Son la base de la métrica de PMF de monetización (Ola G/GATE).

---

## 6. Tests (CONSTITUTION §9)

- **Unit `paywall_trigger`:** dispara con 1 ayuno; con día 7; no si premium; no si visto hoy; no durante onboarding.
- **Widget `PaywallScreen`** (con `FakeBillingService` de SPEC-196): renderiza packages con precios fake, comprar → estado premium, restaurar, cancelar sin romper.
- **Nudges:** se programan al registrarse y se cancelan al volverse premium.

---

## 7. Definición de Hecho

Paywall aparece tras valor demostrado, ofrece mensual/anual con **precios localizados** y trial de 14 días, restaura compras, y programa nudges día 5/12. Conversión instrumentada con telemetría. Validación de tasa de conversión real → Ola G (soft-launch).

---

## 8. Riesgos

- **Paywall intrusivo → churn.** Mitigación: post-valor, no al arranque; freemium, no hard.
- **Precios mal mapeados por región.** Mitigación: nunca hardcodear; leer del SDK; verificar storefronts en sandbox.
- **Rechazo de tienda por falta de "Restaurar".** Mitigación: RF-198-02 lo incluye explícito.
- **Trial sin tarjeta vs con tarjeta** (política de tienda) afecta conversión. Mitigación: documentar la decisión al configurar productos; experimentar en Ola G.
