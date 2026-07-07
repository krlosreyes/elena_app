# SPEC-213 — Lifecycle correcto del servicio de billing (RevenueCat)

**Estado:** IMPLEMENTED (2026-06-14) — StreamController lifecycle fixed. commit 483d444.
**Versión:** 1.0
**Tipo:** Bug P1 — Memory leak: StreamController y listener de RevenueCat nunca se cierran.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~20 min
**Depende de:** `billing_providers.dart`, `revenuecat_billing_service.dart`

---

## 1. Problema

`RevenueCatBillingService` tiene:
- Un `StreamController<EntitlementStatus>.broadcast()` que nunca se cierra.
- Un listener de RevenueCat (`Purchases.addCustomerInfoUpdateListener`) que nunca se remueve.
- Un método `dispose()` que existe en la clase pero **nunca es llamado** desde ningún lado.

El servicio se inyecta como `overrideWithValue` en `ProviderScope` de `main.dart`:
```dart
billingServiceProvider.overrideWithValue(billingService)
```

`overrideWithValue` en Riverpod no registra `onDispose` automáticamente.
Riverpod no sabe cómo destruir este objeto.

**Síntomas observados:**
- En hot-restart (debug): `Bad state: Cannot add event after closing` o eventos después
  del restart.
- En producción con múltiples sesiones: listener de RevenueCat duplicado acumulándose.

---

## 2. Solución

### inc1 — Convertir a `Provider` con `ref.onDispose`

En lugar de `overrideWithValue`, crear el servicio dentro del provider para que Riverpod
gestione su ciclo de vida:

```dart
// billing_providers.dart
final billingServiceProvider = Provider<RevenueCatBillingService>((ref) {
  final service = RevenueCatBillingService();
  ref.onDispose(service.dispose);  // Riverpod llama dispose() al destruir el provider
  return service;
});
```

### inc2 — Eliminar el `overrideWithValue` de `main.dart`

```dart
// main.dart — ANTES
runApp(
  ProviderScope(
    overrides: [
      billingServiceProvider.overrideWithValue(billingService),
    ],
    child: const MyApp(),
  ),
);

// main.dart — DESPUÉS
// No se necesita override: el provider crea e inicializa el servicio internamente.
runApp(
  ProviderScope(
    child: const MyApp(),
  ),
);
```

### inc3 — Mover la inicialización de RevenueCat al constructor/método `init` del servicio

Si `RevenueCatBillingService` requiere configuración asíncrona (API key, etc.), usar
el patrón:

```dart
// revenuecat_billing_service.dart
class RevenueCatBillingService {
  RevenueCatBillingService() {
    _init();  // Llamado en construcción, no desde main
  }

  void _init() {
    // Configurar Purchases.configure(...) aquí
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
  }

  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _controller.close();
  }
  // ...
}
```

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/billing/application/billing_providers.dart` | Convertir a `Provider` con `ref.onDispose` |
| `lib/main.dart` | Eliminar `overrideWithValue` de billing |
| `lib/src/features/billing/data/revenuecat_billing_service.dart` | Mover init a constructor, implementar `dispose()` correctamente |

---

## 4. Criterios de aceptación

- [ ] Hot-restart en debug sin `Bad state: Cannot add event after closing`.
- [ ] Un solo listener de RevenueCat activo en cualquier momento (verificable con logs
  de RevenueCat SDK en debug).
- [ ] `billingServiceProvider` retorna instancia válida en primer uso sin necesidad de
  inicialización manual en `main.dart`.
