# SPEC-193.1 — Alinear Privacy Label / Data Safety con la recolección real

**Estado:** IN-PROGRESS (doc + consola)
**Versión:** 1.0
**Tipo:** Cumplimiento de tiendas. Sub-SPEC de SPEC-193.
**Líder:** Carlos
**Implementación:** Claude (documentación) + Carlos (formularios de consola)
**Depende de:** SPEC-193 (Analytics implementado).

---

## 1. Contexto

El análisis de liderazgo (jun-2026) detectó una inconsistencia: `docs/LAUNCH_LISTINGS.md` declaraba "Analytics" como propósito de recolección, pero el código **no** tenía Firebase Analytics. Declarar recolección que no ocurre (o no declarar la que sí) es causa de rechazo en ambas tiendas.

**SPEC-193 resolvió la inconsistencia por implementación:** ahora la app SÍ recolecta analytics, así que el label es verídico. Esta sub-SPEC cierra el cabo: documenta con precisión qué se recolecta para que el **Data Safety form (Google)** y el **App Privacy questionnaire (Apple)** se llenen de forma exacta y defendible.

## 2. Decisiones

### 2.1 — El label NO cambia; se confirma y se respalda
Las tablas existentes en `LAUNCH_LISTINGS.md` (§1.4 Apple, §2.5 Google) ya declaran User ID + Product Interaction/App interactions + Crash logs con propósito Analytics. Son correctas. Se agrega un **apéndice de trazabilidad** que mapea cada categoría a los eventos reales del catálogo.

### 2.2 — Garantías que se documentan (y que el código cumple)
- **Sin PII en parámetros.** Ningún evento envía email, nombre ni datos de salud crudos. Valores continuos (IMR, %grasa, horas, calidad) van en *buckets* o categorías.
- **Identificador pseudónimo.** `setUserId` usa el uid de Firebase Auth (ya pseudónimo), no email.
- **Mobile-only.** Analytics está deshabilitado en web (`kIsWeb` → skip), igual que Crashlytics.
- **Sin tracking cross-app / sin ATT.** No se usa IDFA ni se comparte con terceros para publicidad → en Apple, "Tracking" = No.

## 3. Lo que NO se hace
- NO se agrega recolección nueva (solo se documenta la de SPEC-193).
- NO se tocan los formularios desde código (los llena Carlos en consola — RF-193.1-02).

## 4. Requisitos

### RF-193.1-01 — Apéndice de trazabilidad en LAUNCH_LISTINGS
Tabla evento → categoría de tienda → dato, afirmando no-PII. (Implementado en `docs/LAUNCH_LISTINGS.md` §7.)

### RF-193.1-02 — Llenado de formularios (Carlos, consola)
- **Google Play Console → Data safety:** confirmar User IDs (Analytics), App interactions (Analytics), Crash logs. Marcar "datos cifrados en tránsito" y "el usuario puede pedir borrado" (ya existe borrado de cuenta in-app).
- **App Store Connect → App Privacy:** Contact Info→Email (App functionality, Account); Identifiers→User ID (Analytics); Usage Data→Product Interaction (Analytics); Diagnostics→Crash Data. **Tracking: No** en todas.
- Verificar que la **política de privacidad publicada** (metamorfosisreal.com/elena/privacy) mencione analytics de producto y el proceso de borrado.

## 5. Criterios de éxito
- El cuestionario de cada tienda coincide 1:1 con el apéndice §7 de LAUNCH_LISTINGS.
- Cero discrepancia entre lo declarado y lo que el código recolecta.

## 6. Estado
- [x] Apéndice de trazabilidad documentado.
- [ ] Formularios de consola llenados (Carlos).
- [ ] Política de privacidad web verificada.
