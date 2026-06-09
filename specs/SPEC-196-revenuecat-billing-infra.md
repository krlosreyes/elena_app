# SPEC-196 — Integración RevenueCat (infra de cobro)

**Estado:** IN-PROGRESS (2026-06-09) — inc1 (capa pura: `BillingService` + `EntitlementStatus` + `FreeBillingService` + providers + `FakeBillingService` + tests) y inc2 (dep `purchases_flutter`, `RevenueCatBillingService`, init en `main.dart` vía `--dart-define`, login/logout en `app.dart`) implementados. **Pendiente:** validación de compra/restauración en sandbox (requiere keys + productos de tienda de Carlos, ver `docs/SETUP_BILLING.md`).
**Versión:** 0.1 (draft)
**Tipo:** Monetización — infraestructura. Habilita cobro; NO define tiers (SPEC-197) ni trial/pricing (SPEC-198).
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola C (Monetización) — Semana 4–6. Depende de Ola A (medición) + Ola B (coaching). "Cobramos por un coach, no por un logger."
**Estimación:** ~4 días.
**Depende de:** SPEC-193 (analytics, para medir conversión), Firebase init (orden en `main.dart`), cuenta RevenueCat + productos de tienda configurados (ver `docs/SETUP_BILLING.md`).
**Bloquea:** SPEC-197 (gating necesita leer entitlements), SPEC-198 (paywall necesita Offerings/compra).

---

## 1. Contexto

Verificado en código (2026-06-09): **no existe infraestructura de cobro.** `pubspec.yaml` no tiene `purchases_flutter`, `in_app_purchase` ni RevenueCat. El listing declara "Free". El producto genera valor pero no puede capturarlo.

Esta SPEC añade **solo la fontanería de cobro**: SDK, init, y un servicio de entitlements reactivo y *provider-agnostic*. La decisión de qué se cobra (gating) y cómo se convierte (trial/paywall) vive en SPEC-197/198 para mantener capas separadas y testeables.

**Por qué RevenueCat y no `in_app_purchase` nativo:** RevenueCat abstrae App Store + Play en una sola API, gestiona el estado de entitlements server-side (sobrevive reinstalaciones y cambios de device), maneja restauración y validación de recibos, y da analytics de conversión sin construir backend. Tier gratuito hasta US$2.5k MTR (luego 1%), suficiente para soft-launch y bastante más allá.

---

## 2. Decisiones de diseño

### 2.1 — Capa de cobro abstracta (`BillingService`)

La app NO depende de `purchases_flutter` directamente fuera de la capa `data`. Se define una interfaz `BillingService` (domain/application) con una implementación `RevenueCatBillingService` (data) y una `FakeBillingService` (tests). Así:

- Los consumidores (gating SPEC-197, paywall SPEC-198) dependen de la abstracción, no del SDK.
- Los tests corren sin red ni SDK nativo.
- Si algún día se cambia de proveedor, solo se reescribe la capa `data`.

### 2.2 — Entitlement único: `premium`

Un solo entitlement (`premium`) en RevenueCat. Free = sin entitlement; Premium = entitlement activo (sea por trial, mensual o anual). El gating (SPEC-197) solo pregunta `isPremium`, no qué producto compró. Simplicidad sobre granularidad en MVP.

### 2.3 — Estado reactivo, no imperativo

`entitlementProvider` expone `EntitlementStatus` como `Stream`/`Provider` que la UI watchea. RevenueCat emite `CustomerInfo` updates (compra, expiración, restauración) → el provider re-emite → la UI reacciona sin polling. Mismo patrón que `currentUserStreamProvider`.

### 2.4 — Identidad ligada al usuario Firebase

Se llama `Purchases.logIn(firebaseUid)` al autenticarse para que el entitlement siga al usuario entre devices (App User ID = Firebase UID). Al cerrar sesión, `Purchases.logOut()`.

---

## 3. Lo que NO se hace aquí (límites)

- **NO se define el gating de features** (SPEC-197).
- **NO se construye el paywall ni el trial** (SPEC-198).
- **NO se cobra de verdad en producción** — esta SPEC se valida en **sandbox**. El cobro real depende de productos aprobados en tienda (trámite de Carlos).
- **NO se configuran los productos/precios** — eso vive en App Store Connect / Play Console / RevenueCat dashboard (ver §6 y `docs/SETUP_BILLING.md`).

---

## 4. Arquitectura

Nueva feature `lib/src/features/billing/`:

```
billing/
 ├── domain/
 │    └── entitlement_status.dart      # value object: isPremium, willRenew, expiration, productId?, source(trial/paid/none)
 ├── application/
 │    ├── billing_service.dart         # interfaz abstracta (initialize, login/logout, offerings, purchase, restore, customerInfoStream)
 │    └── billing_providers.dart       # entitlementProvider (Stream), billingServiceProvider
 └── data/
      └── revenuecat_billing_service.dart  # impl con purchases_flutter (ÚNICO archivo que importa el SDK)

test/features/billing/
 └── fake_billing_service.dart         # impl en memoria para tests + golden de SPEC-198
```

### Flujo
```
main.dart (post-Firebase) → BillingService.initialize(publicKey)
auth login → BillingService.login(firebaseUid)
SDK emite CustomerInfo → entitlementProvider re-emite EntitlementStatus
SPEC-197 gating lee entitlementProvider.isPremium
SPEC-198 paywall usa BillingService.offerings() + purchase(package)
```

---

## 5. Requisitos funcionales

### RF-196-01 — Dependencia e init
Agregar `purchases_flutter` a `pubspec.yaml`. Inicializar en `main.dart` **después** de `Firebase.initializeApp()` y del gate de App Check, con la **public SDK key** por plataforma (iOS/Android). En `kDebugMode`, `Purchases.setLogLevel(LogLevel.debug)`.

### RF-196-02 — `BillingService` (interfaz)
```
abstract class BillingService {
  Future<void> initialize();
  Future<void> login(String appUserId);
  Future<void> logout();
  Stream<EntitlementStatus> customerInfoStream();
  Future<List<BillingPackage>> currentOfferingPackages(); // para SPEC-198
  Future<EntitlementStatus> purchase(BillingPackage pkg);
  Future<EntitlementStatus> restore();
}
```
Contrato: nunca lanza hacia la UI sin envolver; errores de red/usuario-cancela se mapean a tipos de resultado claros (no crashea el paywall).

### RF-196-03 — `EntitlementStatus` (domain)
`{ bool isPremium, bool willRenew, DateTime? expiration, String? activeProductId, EntitlementSource source }` con `source ∈ {none, trial, paid}`. Inmutable, Dart puro, testeable.

### RF-196-04 — `entitlementProvider`
`StreamProvider<EntitlementStatus>` que mapea el `customerInfoStream`. Default mientras carga: `EntitlementStatus.free()`. Sobrevive logout (vuelve a free).

### RF-196-05 — Identidad
Enganchar `login(uid)`/`logout()` al ciclo de auth existente (donde se resuelve `currentUserStreamProvider`). App User ID = Firebase UID.

### RF-196-06 — Restauración
Método `restore()` expuesto (lo consume el botón "Restaurar compras" del paywall SPEC-198). Obligatorio para aprobación de App Store.

### RF-196-07 — Telemetría (con SPEC-193)
Eventos base: `billing_sdk_initialized`, `entitlement_changed` (param: `is_premium`, `source`). Conversión detallada (paywall/trial/purchase) vive en SPEC-198.

---

## 6. Lo que Carlos debe configurar (fuera de código)

Detalle paso a paso en `docs/SETUP_BILLING.md`. Resumen:

1. **Cuenta RevenueCat** (gratis) → crear proyecto → conectar App Store Connect + Play Console.
2. **App Store Connect:** crear productos de suscripción (mensual + anual) en un grupo de suscripción, con precios por región (LatAm/US — SPEC-198).
3. **Play Console:** crear los mismos productos de suscripción.
4. **RevenueCat dashboard:** crear el **entitlement `premium`**, una **Offering** "default" con los packages mensual/anual, y obtener las **public SDK keys** (iOS y Android).
5. **Pasarle a Claude:** las dos public SDK keys + los product IDs. (Las keys públicas no son secretos críticos, pero igual van por canal privado y NO se commitean en claro — se inyectan por `--dart-define` / config.)

**Mío (Claude):** todo el código (§4–5), la `FakeBillingService`, los tests, y la inyección de keys vía `--dart-define`.

---

## 7. Tests (CONSTITUTION §9)

- **Unit `EntitlementStatus`:** mapeo de CustomerInfo→status (premium activo, expirado, trial, free).
- **FakeBillingService:** compra simulada cambia el stream a premium; restore idem; logout vuelve a free.
- **Provider:** `entitlementProvider` emite free por defecto y premium tras compra simulada.
- *(Sandbox manual, no automatizable):* compra + restauración real en device iOS/Android — es la Definición de Hecho.

---

## 8. Definición de Hecho

Compra y restauración funcionales en **sandbox iOS + Android** (cuenta sandbox de prueba), con `entitlementProvider` reflejando premium en vivo. Cero cobro en producción todavía.

---

## 9. Riesgos

- **Dependencia de trámite de tienda.** Sin productos aprobados no hay sandbox completo. Mitigación: `FakeBillingService` desbloquea SPEC-197/198 en paralelo mientras los productos se aprueban.
- **App User ID mal ligado** → entitlements huérfanos. Mitigación: login/logout enganchados al auth real + test.
- **Keys en el repo.** Mitigación: `--dart-define`, nunca hardcodeadas.
