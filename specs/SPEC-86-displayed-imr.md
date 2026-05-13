# SPEC-86 — Dashboard muestra `imr.current` persistido cuando el cálculo local es baseline

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Bugfix de SPEC-82
**Marco normativo:** `CONSTITUTION.md`
**Antecedente:** SPEC-82, SPEC-85.

---

# 1. Contexto

SPEC-85 protegió Firestore de que la app pise el `imr.current` del sitio con un baseline. Pero el dashboard de la app sigue mostrando el cálculo local (`imrProvider`), que devuelve baseline (`metabolicScore == 0 && behaviorScore == 0`) hasta que el usuario carga su primera comida. Resultado UX:

- Sitio web muestra: 52 (cálculo completo del sitio).
- Firestore: 52 (preservado por SPEC-85).
- App dashboard: 37 (baseline local). **Inconsistencia visible al usuario.**

# 2. Problema

Cuando la app no tiene data behavioral, el `imrProvider` produce un score que NO es comparable al que ya está persistido por el sitio (calculado con todos los inputs disponibles). Mostrar el baseline local es engañoso porque hace creer al usuario que su IMR "bajó" cuando en realidad la app aún no ha podido recomputar con todo.

# 3. Solución propuesta

Nuevo `displayedImrProvider` que decide qué score mostrar:

- Si el cálculo local tiene contribución behavioral (`metabolicScore > 0 || behaviorScore > 0`) → muestra el local. La app ahora SÍ tiene más datos que el sitio.
- Si solo hay baseline local → leer `imr.current` persistido. Si existe, mostrarlo. Si no, fallback al baseline local (caso de usuario solo-app sin historial).

Dashboard y Profile usan `displayedImrProvider` para el badge principal. Las tarjetas de detalle (bloques E/M/C) siguen leyendo `imrProvider` directamente porque esos componentes solo existen en el cálculo local.

# 4. Plan

Tres archivos a modificar/extender:

1. `lib/src/shared/domain/repositories/user_profile_repository.dart` — agregar `watchCurrentImr(String userId)`.
2. `lib/src/shared/data/user_profile_repository_impl.dart` — implementar (deriva del stream del doc).
3. `lib/src/core/engine/imr_persistence_provider.dart` — agregar `persistedImrProvider` y `displayedImrProvider` + value class `DisplayedImr`.
4. `lib/src/features/dashboard/presentation/dashboard_screen.dart` — badge principal usa `displayedImrProvider`.
5. `lib/src/features/auth/presentation/profile_screen.dart` — badge identidad usa `displayedImrProvider`.

# 5. Criterios de aceptación

- Usuario MR con `imr.current.imrScore = 52` persistido por el sitio + sin data behavioral local → Dashboard y Profile muestran 52, no 37.
- Mismo usuario tras cargar primera comida → Dashboard muestra el cálculo local (que puede subir o bajar el score según el comportamiento real).
- Usuario que se registra desde la app sin valor previo en Firestore → Dashboard muestra el baseline local (caso sin regresión).
- Las tarjetas de detalle de los bloques E/M/C siguen renderizando con valores del cálculo local (no de Firestore).
- `flutter test` sin regresión.

# 6. Pruebas

Test en `test/core/engine/displayed_imr_provider_test.dart`:

- "local con behavior > 0 → usa local" (escenario usuario activo).
- "local baseline + persistido existe → usa persistido" (escenario MR fresh).
- "local baseline + persistido null → usa local" (escenario solo-app fresh).

# 7. Riesgos

- **`persistedImrProvider` mantiene un stream Firestore abierto.** Costo bajo (un doc read por usuario activo). El stream se desuscribe cuando el provider sale del árbol Riverpod.
- **Edge case:** el usuario cierra la app mientras Firestore aún devuelve el valor viejo (cache). Al reabrir, el stream emite el valor actualizado. Eventualmente consistente.
- **Si el sitio escribe un valor inválido (ej. `imrScore = -5`)**, el dashboard lo mostraría como `-5`. Mitigación: clamp a `[0, 100]` en `DisplayedImr.fromPersisted` antes de exponer.

# 8. Out of scope

- Indicador visual "score del sitio" vs "score de la app" (badge con icono diferente). UX nice-to-have, no crítico.
- Sincronización entre versions del IMR (sitio cambia su fórmula sin avisar). Política operativa: app gana cuando tiene datos completos.

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 416 verdes / 3 skipped / 0 rojos. Los 4 tests específicos del `displayedImrProvider` en verde tras refactor a `container.listen` + `Completer` (patrón inicial `expectLater` + `emitsThrough` tenía race conditions con el loading state del `authStateProvider`).

**Smoke test pendiente:** el usuario MR ahora debería ver el 52 en el badge del Dashboard y Profile (en lugar del 37 baseline local). Cuando cargue su primera comida, el dashboard transita al valor recalculado por la app.

**Desviaciones del plan:**

- El patrón de espera de stream en tests pasó por dos iteraciones (`.future`, `expectLater + emitsThrough`, finalmente `container.listen + Completer`). El último es el más robusto frente al loading state intermedio de Riverpod.
