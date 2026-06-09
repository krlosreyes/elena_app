# Guía de setup de cobro (Ola C) — qué necesitas crear

Acompaña a SPEC-196/197/198. Explica **qué hay que configurar fuera del código** para activar el cobro, y **qué es tuyo (Carlos) vs mío (Claude)**.

> Regla de oro: tú creas cuentas y productos en las consolas; yo escribo todo el código. Mientras los productos se aprueban, yo desbloqueo SPEC-197/198 con una `FakeBillingService`, así no quedamos parados.

---

## El panorama en una frase

Tres consolas hablan entre sí: **App Store Connect** y **Google Play Console** (donde viven los productos y los cobros reales) y **RevenueCat** (la capa que las unifica y le da a la app una sola API). La app solo habla con RevenueCat.

```
App Store Connect ─┐
                   ├─► RevenueCat ─► (public SDK keys) ─► App
Google Play Console ┘
```

---

## Paso a paso (tuyo, Carlos)

### 1. RevenueCat (gratis hasta US$2.5k MTR, luego 1%)
1. Crear cuenta en revenuecat.com y un **proyecto** ("ElenaApp").
2. Conectarlo a App Store Connect (con una API key de App Store) y a Play Console (con una service account de Google). RevenueCat tiene asistentes para ambos.

### 2. App Store Connect (iOS)
1. Crear un **grupo de suscripción** (p. ej. "Elena Premium").
2. Dentro, crear **dos productos auto-renovables**:
   - `elena_premium_monthly`
   - `elena_premium_annual`
3. A cada uno, añadir una **intro offer de 14 días gratis** (el trial de SPEC-198).
4. Fijar **precios por región**: LatAm US$4.99/mes y US$39.99/año; US/EU US$9.99/mes y US$79.99/año (usando los price tiers por territorio).

### 3. Google Play Console (Android)
1. Crear los **mismos dos productos** de suscripción con los **mismos IDs** (`elena_premium_monthly`, `elena_premium_annual`).
2. Misma intro offer de 14 días y mismos precios por región.

### 4. RevenueCat dashboard
1. Crear el **entitlement** `premium`.
2. Crear una **Offering** "default" con dos **packages**: mensual y anual, cada uno apuntando a los productos de tienda.
3. Asociar ambos productos al entitlement `premium`.
4. Copiar las **dos public SDK keys** (una iOS, una Android) desde *Project Settings → API keys*.

### 5. Cuentas sandbox de prueba
- iOS: crear un **Sandbox Tester** en App Store Connect.
- Android: añadir tu cuenta como **tester de licencia** en Play Console.
(Sirven para probar compra/restauración sin cobrar de verdad — la Definición de Hecho de SPEC-196.)

### 6. Pasarme a mí
- Las **2 public SDK keys** (iOS + Android).
- Los **2 product IDs** (si cambiaste los nombres sugeridos).
- Por canal privado. No las pego en el repo en claro; se inyectan por `--dart-define`.

---

## Qué hago yo (Claude)

- Toda la capa de cobro: `purchases_flutter`, init en `main.dart`, `BillingService` + `RevenueCatBillingService`, `entitlementProvider` (SPEC-196).
- `FakeBillingService` + tests, para avanzar SPEC-197/198 **sin esperar** la aprobación de productos.
- El gating de features (SPEC-197) y el paywall + trial + nudges (SPEC-198).
- La inyección de keys vía `--dart-define` (nunca hardcodeadas).

---

## Conceptos rápidos (para que las consolas tengan sentido)

- **Producto:** lo que se vende (mensual/anual), vive en la tienda.
- **Entitlement (`premium`):** "lo que desbloqueas". La app solo pregunta *¿tienes premium?* — no qué producto compraste.
- **Offering / Package:** cómo RevenueCat agrupa los productos para mostrarlos en el paywall (mensual vs anual).
- **MTR (Monthly Tracked Revenue):** ingreso mensual que RevenueCat ve; define su precio (gratis < US$2.5k).
- **Public SDK key:** identifica tu app ante RevenueCat. Es pública (va en el cliente) pero la tratamos con cuidado igual.

---

## Orden recomendado

1. Yo implemento SPEC-196 con `FakeBillingService` → SPEC-197 (gating) → SPEC-198 (paywall), todo testeable sin tienda.
2. En paralelo, tú haces los pasos 1–5 de arriba (RevenueCat + productos + sandbox).
3. Cuando me pases las keys (paso 6), enchufo `RevenueCatBillingService` real y validamos compra/restauración en sandbox.
4. El cobro real en producción se enciende en la Ola G (soft-launch), con los productos ya aprobados.
