# Roadmap a Producción 10/10 — ElenaApp

**Versión:** 1.0
**Fecha de redacción:** 15-may-2026
**Audiencia:** Líder de proyecto (Carlos), equipo técnico, stakeholders MR.
**Vigencia:** este documento es la referencia operativa única hasta el lanzamiento público y los primeros 6 meses post-launch.

---

## Índice

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Estado actual (baseline)](#2-estado-actual-baseline)
3. [Definición de 10/10 por dimensión](#3-definición-de-1010-por-dimensión)
4. [Roadmap por fases](#4-roadmap-por-fases)
5. [Catálogo de SPECs propuestos](#5-catálogo-de-specs-propuestos)
6. [Métricas y KPIs de éxito](#6-métricas-y-kpis-de-éxito)
7. [Runbook de producción](#7-runbook-de-producción)
8. [Riesgos y planes de mitigación](#8-riesgos-y-planes-de-mitigación)
9. [Glosario operativo](#9-glosario-operativo)
10. [Apéndice de referencias](#10-apéndice-de-referencias)

---

## 1. Resumen ejecutivo

ElenaApp es una app Flutter de salud metabólica con cinco pilares (ayuno, sueño, hidratación, ejercicio, nutrición) unificados por una métrica única (IMR) sustentada en bibliografía científica. La auditoría 360° del 15-may-2026 sitúa el ship-readiness global en **78%** (producto 85%, tecnología 80%, negocio 70%, UX 80%).

Este documento traduce los gaps identificados en un plan ejecutable de **20 SPECs nuevos** distribuidos en **3 fases** que llevan el proyecto a un estado **10/10 sostenible** en las cinco dimensiones auditadas (ingeniería, arquitectura, CTO, CEO, cliente). El cronograma cubre desde hoy hasta tres meses post-lanzamiento.

**Decisiones estratégicas que sustentan este plan:**

- El lanzamiento público objetivo (10-ago-2026) se cumple **siempre y cuando se ejecute soft-launch interno previo** con 50–100 usuarios MR para validar retención y pricing.
- Cerrar todos los SPECs de Fase 1 es **bloqueante** para shippeable. Los de Fase 2 y 3 son post-MVP.
- El equipo se mantiene en Carlos + Claude (par programación, ejecución SPEC-driven). No se contempla escalado de equipo en estos 6 meses.
- El stack se mantiene (Flutter + Firebase + Riverpod). No hay migraciones tecnológicas.

---

## 2. Estado actual (baseline)

| Dimensión | Calificación | Bloqueantes clave |
|---|---|---|
| Ingeniería | 8/10 | SPEC-81 abierto · sin CI/CD · widget tests débiles |
| Arquitectura | 8.5/10 | God widgets en dashboard/profile · hydration mal ubicado · `fasting_history` top-level |
| CTO | 7.5/10 | Sin analytics de negocio · modo offline débil · sin testing real en iOS |
| CEO | 7/10 | Sin paywall · pricing no validado · onboarding sin segmento freemium |
| Cliente | 7.5/10 | Onboarding cero-contexto pendiente · sin HealthKit · empty states pobres |

**Hechos verificados al snapshot:**

- 38 SPECs entre el 76 y 115 (3 ausentes documentados).
- 206 archivos `.dart`, 35.620 líneas en top-14.
- 52 archivos `_test.dart` (cobertura sólida en core, débil en UI).
- 14 módulos funcionales bajo `lib/src/features/`.
- 9 colecciones Firestore activas.
- 2 TODOs/FIXMEs inline → disciplina alta (deuda canalizada a SPECs explícitos).
- Documentación canónica existente: `CONSTITUTION.md`, `IMR_BIBLIOGRAPHY.md`, `CIRCADIAN_BIBLIOGRAPHY.md`, `AUDITORIA_PRODUCCION_COMPLETA.md`, `LAUNCH_LISTINGS.md`.

---

## 3. Definición de 10/10 por dimensión

### Ingeniería 10/10
- CI/CD automatizado (pipeline verde en cada PR).
- Cobertura de tests ≥ 60% global (≥ 80% en core/engine, ≥ 40% en presentation).
- Cero god widgets (ningún archivo `.dart` por encima de 700 líneas en presentation).
- Cero TODOs/FIXMEs inline. Toda deuda referenciada a SPEC numerado abierto.
- Tests E2E (golden + integration) sobre los 5 flujos críticos del usuario.

### Arquitectura 10/10
- Patrón canónico de features uniforme: 5 pilares como features autocontenidas idénticamente estructuradas.
- Una colección por subcolección de usuario (`users/{uid}/*`) — sin top-levels huérfanas.
- Reglas de dominio críticas (atribución temporal, scoring IMR, completitud de pilares) cubiertas por suite de tests de service ≥ 90%.
- Documentación de arquitectura ADR (Architecture Decision Records) versionada bajo `docs/adr/`.

### CTO 10/10
- Observability completa: Crashlytics + Performance + Analytics + dashboard de retención en producción.
- Modo offline funcional para los 3 flujos primarios (registrar comida, iniciar ayuno, ver IMR).
- iOS y Android paridad real verificada en device.
- Costo unitario Firestore por usuario activo medido y proyectado a 10K usuarios.

### CEO 10/10
- Paywall activo con free tier + premium.
- Pricing validado en cohortes reales (no estimado).
- Plan de growth con embudos medidos (instalación → registro → primer pilar → día-7 → suscripción).
- B2B pilot con al menos 1 clínica/coach.

### Cliente 10/10
- Onboarding cero-contexto que cualquier usuario sin background MR puede completar.
- Integración HealthKit y Google Fit (peso, ejercicio, sueño se importan automáticamente).
- Empty states informativos y motivadores en todas las pantallas.
- Glosario / centro de ayuda accesible desde cualquier pantalla.
- Accesibilidad: light/dark, dynamic font sizes, semantic labels.

---

## 4. Roadmap por fases

### Fase 1 — Pre-MVP shippable (15-may → 30-jun, 6 semanas)

**Objetivo:** producto listo para soft-launch interno. No-go condicional sobre cumplimiento de Fase 1.

| SPEC | Título | Días | Bloquea |
|---|---|---|---|
| 81 | Hardening firestore.rules + reCAPTCHA v3 (ya iniciado) | 3 | Producción |
| 116 | CI/CD GitHub Actions (build + test + lint) | 2 | Calidad continua |
| 117 | Widget tests + golden tests críticos | 4 | Estabilidad UI |
| 118 | Tests E2E ayuno multi-día (atribución temporal) | 3 | Confiabilidad scoring |
| 122 | Formalización regla de atribución temporal con tests | 2 | Confiabilidad IMR |
| 125 | TestFlight + Internal Testing Google Play | 2 | Soft-launch |
| 131 | Onboarding cero-contexto (tutorial + datos demo) | 5 | UX inicial |
| 134 | Empty states ricos en pantallas críticas | 3 | UX inicial |

**Entregable:** build firmado en TestFlight + Google Play Internal con 50–100 usuarios MR invitados.

### Fase 2 — Soft-launch a launch público (1-jul → 31-ago, 8 semanas)

**Objetivo:** validar producto-mercado-pricing con cohorte real antes del lanzamiento público.

| SPEC | Título | Días | Bloquea |
|---|---|---|---|
| 123 | Analytics de eventos clave (Firebase Analytics) | 3 | Decisiones data-driven |
| 124 | Modo offline robusto + sync queue | 5 | Retención |
| 127 | Paywall + RevenueCat integration | 5 | Monetización |
| 128 | Trial gratis + flow de conversión | 3 | Onboarding pago |
| 132 | Integración HealthKit + Google Fit | 6 | Fricción de uso |
| 119 | Refactor god widgets (dashboard, profile) | 4 | Mantenibilidad |
| 126 | Observability dashboard | 2 | Operación |

**Entregable:** lanzamiento público en App Store + Play Store con paywall activo.

### Fase 3 — Post-launch growth & escalado (1-sep → 30-nov, 12 semanas)

**Objetivo:** retención, growth, expansión B2B.

| SPEC | Título | Días | Bloquea |
|---|---|---|---|
| 120 | Migrar `fasting_history` a subcollection de user | 3 | Higiene arquitectónica |
| 121 | Mover hydration a feature autocontenida | 2 | Higiene arquitectónica |
| 129 | A/B testing infrastructure (Firebase Remote Config) | 4 | Optimización growth |
| 130 | Email marketing hooks + segmentación | 4 | Re-engagement |
| 133 | Centro de ayuda in-app + glosario | 5 | Soporte |
| 135 | Light theme + accesibilidad | 5 | Inclusión |
| 136 | B2B pilot con clínica/coach (1 cliente) | 10 | Validar B2B |

**Entregable:** 1.000 usuarios pagos · retención día-30 ≥ 25% · 1 cliente B2B firmado.

---

## 5. Catálogo de SPECs propuestos

Cada SPEC sigue el formato del proyecto. Los detalles completos se redactan al iniciar cada uno; aquí se documenta el contrato mínimo.

### Fase 1

#### SPEC-116 · CI/CD con GitHub Actions
- **Problema:** todos los commits pasan por aprobación manual sin checks automáticos. Riesgo de regresiones silenciosas.
- **Solución:** workflow `.github/workflows/ci.yml` que en cada PR ejecuta `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`. En main, además genera APK release y archiva artefacto.
- **Criterios de éxito:** PR no se merge sin verde · build APK release < 8 min.
- **Estimación:** 2 días.

#### SPEC-117 · Widget tests + golden tests críticos
- **Problema:** sin tests visuales para los 5 componentes más iterados.
- **Solución:** suite con golden tests para `PeriodHeroCard`, `FastingHeroDisplay`, `PillarsHeatmap`, `ImrTrendChart`, `_DataGroupCard`. Snapshots versionados en repo.
- **Criterios de éxito:** ningún cambio de pixel involuntario detectado · CI falla si golden cambia sin actualizar snapshot.
- **Estimación:** 4 días.

#### SPEC-118 · Tests E2E ayuno multi-día
- **Problema:** la lógica de atribución temporal ya tuvo 3 iteraciones. Edge cases no cubiertos por tests.
- **Solución:** suite de tests del `PeriodComparisonService` + `dailySummaryProvider` que cubren: ayuno que cruza medianoche, ayuno abandonado prematuramente, ayuno completado exactamente al target, día con dos ayunos consecutivos, persistencia inmediata por completion transition.
- **Criterios de éxito:** ≥ 12 casos de test · cobertura 100% del service.
- **Estimación:** 3 días.

#### SPEC-119 · Refactor god widgets (post-MVP)
- **Problema:** `dashboard_screen.dart` 1874 líneas, `profile_screen.dart` 1543 líneas.
- **Solución:** extraer subwidgets a archivos separados bajo `presentation/widgets/`. `dashboard_screen` queda como orquestador (< 400 líneas). Idem profile.
- **Criterios de éxito:** ningún `.dart` de presentation > 700 líneas · tests pasan sin cambios.
- **Estimación:** 4 días.

#### SPEC-122 · Formalizar regla de atribución temporal del ayuno
- **Problema:** la regla ha pasado por tres revisiones. No hay documento canónico que defina el comportamiento esperado caso por caso.
- **Solución:** documento `docs/RULES_TEMPORAL_ATTRIBUTION.md` con tabla exhaustiva de casos. Suite de tests del service que valida cada uno.
- **Criterios de éxito:** documento aprobado por Carlos · tests verdes para 100% de casos.
- **Estimación:** 2 días.

#### SPEC-125 · TestFlight + Google Play Internal Testing setup
- **Problema:** sin canal formal para distribuir builds a beta testers.
- **Solución:** App Store Connect configurado con TestFlight (50 testers). Google Play Console con Internal Testing track (100 testers). Documentación de invitación.
- **Criterios de éxito:** 50 invitaciones MR enviadas · primer build aprobado en ambos stores.
- **Estimación:** 2 días.

#### SPEC-131 · Onboarding cero-contexto
- **Problema:** el onboarding actual asume que el usuario viene de MR y conoce el concepto IMR. Usuarios cero-contexto se pierden.
- **Solución:** flujo nuevo de primer ingreso con 4 pasos: (a) qué es ElenaApp (1 pantalla), (b) qué es IMR (1 pantalla con animación), (c) llena tus datos básicos (peso, altura, edad), (d) elige protocolo de ayuno guiado.
- **Criterios de éxito:** tester sin contexto MR completa onboarding < 3 min · entiende qué es IMR.
- **Estimación:** 5 días.

#### SPEC-134 · Empty states ricos
- **Problema:** Análisis con 0 días de data, Comidas sin registros, Ejercicio sin actividad — todos muestran espacios vacíos o estados pobres.
- **Solución:** widget `EmptyStateCard` reusable con ilustración + título + descripción + CTA primario. Aplicado en los 5 pilares y en Análisis.
- **Criterios de éxito:** ningún empty state muestra solo "Sin datos" · todos tienen CTA.
- **Estimación:** 3 días.

### Fase 2

#### SPEC-123 · Analytics de eventos clave
- **Problema:** Crashlytics está, pero no medimos comportamiento de negocio.
- **Solución:** integrar Firebase Analytics. Eventos: `app_open`, `signup_complete`, `onboarding_complete`, `fasting_started`, `fasting_completed`, `meal_logged`, `imr_calculated`, `paywall_shown`, `subscription_started`, `subscription_renewed`, `subscription_cancelled`. Dashboard en consola Firebase.
- **Criterios de éxito:** 11 eventos disparándose en producción · dashboard de retención día-1/día-7/día-30.
- **Estimación:** 3 días.

#### SPEC-124 · Modo offline robusto + sync queue
- **Problema:** la app depende de Firestore online. Sin red, los 5 pilares no funcionan.
- **Solución:** habilitar `Firestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: 100MB)`. Implementar queue de escrituras pendientes con retry exponencial. Indicador visual de "offline" en el header.
- **Criterios de éxito:** registrar comida sin red · al reconectar, sync correcto · sin pérdida de data.
- **Estimación:** 5 días.

#### SPEC-127 · Paywall + RevenueCat
- **Problema:** sin monetización implementada.
- **Solución:** integrar RevenueCat (SDK Flutter). Paywall que aparece tras 7 días o tras 1 ayuno completado. Plans: mensual ($4.99 LatAm / $9.99 US) y anual ($39.99 LatAm / $79.99 US). Free tier limitado a 1 pilar + sin análisis histórico.
- **Criterios de éxito:** flujo de compra funcional iOS + Android · suscripciones se persisten · restoration funciona.
- **Estimación:** 5 días.

#### SPEC-128 · Trial gratis + flow de conversión
- **Problema:** sin trial, fricción de pago alta.
- **Solución:** 7 días de trial gratis al registrarse. Notificaciones en día 5 y 7 con CTA de conversión. Banner persistente en Análisis durante trial.
- **Criterios de éxito:** ≥ 20% conversión trial → pago.
- **Estimación:** 3 días.

#### SPEC-132 · Integración HealthKit + Google Fit
- **Problema:** usuario tiene que meter peso, ejercicio, sueño manualmente.
- **Solución:** plugin `health` de Flutter. Lectura de peso (semanal), ejercicio (minutos activos diarios), sueño (horas dormidas). Botón de "Sincronizar" en cada pilar.
- **Criterios de éxito:** ≥ 3 métricas se importan sin intervención · permisos manejados correctamente iOS/Android.
- **Estimación:** 6 días.

#### SPEC-126 · Observability dashboard
- **Problema:** Crashlytics y Analytics existen pero sin vista consolidada.
- **Solución:** dashboard custom en Firebase con widgets: crashes/día, sesión promedio, retención día-7, embudo onboarding, embudo paywall. Alertas Slack para crashes críticos.
- **Criterios de éxito:** dashboard único accesible · alertas configuradas.
- **Estimación:** 2 días.

### Fase 3

#### SPEC-120 · Migrar `fasting_history` a subcollection
- **Problema:** rompe el patrón del resto de pilares.
- **Solución:** Cloud Function de migración que mueve docs a `users/{uid}/fasting_history/`. Código de la app dual-read durante migración, luego solo subcollection.
- **Criterios de éxito:** 100% docs migrados · downtime cero · old collection eliminada después de 30 días de prueba.
- **Estimación:** 3 días.

#### SPEC-121 · Hydration como feature autocontenida
- **Problema:** vive bajo `dashboard/application/hydration_notifier.dart` mientras los otros 4 pilares tienen su carpeta.
- **Solución:** crear `lib/src/features/hydration/` con misma estructura que `fasting/`. Mover archivos. Actualizar imports.
- **Criterios de éxito:** estructura simétrica de los 5 pilares · tests pasan.
- **Estimación:** 2 días.

#### SPEC-129 · A/B testing infrastructure
- **Problema:** sin manera de validar variantes de UI o flujos.
- **Solución:** Firebase Remote Config + wrapper `ExperimentService`. Primer experimento: onboarding 3-pasos vs 5-pasos.
- **Criterios de éxito:** 1 experimento ejecutado · resultados accionables.
- **Estimación:** 4 días.

#### SPEC-130 · Email marketing hooks
- **Problema:** sin canal de re-engagement.
- **Solución:** segmentación basada en eventos Analytics (inactivos 7d, trial sin convertir, racha rota). Webhooks a SendGrid / Customer.io.
- **Criterios de éxito:** 3 campañas activas · open rate ≥ 25%.
- **Estimación:** 4 días.

#### SPEC-133 · Centro de ayuda in-app
- **Problema:** términos clínicos confunden a usuarios cero-contexto.
- **Solución:** pantalla "Ayuda" con glosario (IMR, ayuno, autofagia, etc.), FAQs, link a soporte. Icono `?` accesible desde header de Análisis y Perfil.
- **Criterios de éxito:** 15 entradas mínimo · usuarios encuentran respuestas sin contactar soporte.
- **Estimación:** 5 días.

#### SPEC-135 · Light theme + accesibilidad
- **Problema:** solo dark theme; sin dynamic font sizes; sin semantic labels.
- **Solución:** ThemeData light versionado en `core/theme/`. Soporte a `MediaQuery.textScaleFactor`. Semantic labels en widgets críticos.
- **Criterios de éxito:** toggle dark/light en Perfil · text scale 1.5x funcional · screen reader navega flujos primarios.
- **Estimación:** 5 días.

#### SPEC-136 · B2B pilot con 1 clínica/coach
- **Problema:** modelo B2B no validado.
- **Solución:** versión white-label para 1 cliente piloto. Dashboard de coach que ve cohorte de pacientes. Pricing $20-30/licencia/mes.
- **Criterios de éxito:** 1 cliente firmado · 10 pacientes activos · feedback documentado.
- **Estimación:** 10 días.

---

## 6. Métricas y KPIs de éxito

### Ingeniería

| Métrica | Baseline | Target Fase 1 | Target Fase 3 |
|---|---|---|---|
| Cobertura tests global | ~25% | ≥ 40% | ≥ 60% |
| Cobertura tests core/engine | ~80% | ≥ 90% | ≥ 95% |
| Archivos > 700 líneas en presentation | 5 | ≤ 3 | 0 |
| TODOs/FIXMEs inline | 2 | ≤ 5 | ≤ 5 |
| Build time CI | n/a | < 8 min | < 5 min |

### Producto / UX

| Métrica | Baseline | Target Fase 2 | Target Fase 3 |
|---|---|---|---|
| Tiempo medio onboarding completo | desconocido | < 5 min | < 3 min |
| Crashes/sesión | desconocido | < 0.5% | < 0.1% |
| App rating (App Store + Play) | n/a | n/a | ≥ 4.3 |
| NPS post-30 días | n/a | n/a | ≥ 40 |

### Negocio

| Métrica | Baseline | Target Fase 2 | Target Fase 3 |
|---|---|---|---|
| Usuarios activos diarios (DAU) | 0 | ≥ 50 (soft) | ≥ 500 |
| Retención día-7 | n/a | ≥ 35% | ≥ 45% |
| Retención día-30 | n/a | ≥ 15% | ≥ 25% |
| Conversión trial → pago | n/a | ≥ 15% | ≥ 22% |
| ARPU mensual | n/a | n/a | $4-7 USD |
| Churn mensual | n/a | n/a | ≤ 7% |

### Operación

| Métrica | Baseline | Target Fase 2 | Target Fase 3 |
|---|---|---|---|
| Costo Firestore / usuario / mes | desconocido | medido | < $0.05 USD |
| Tiempo respuesta soporte | n/a | < 24 h | < 8 h |
| Uptime backend (Firebase) | depende GCP | 99.9% | 99.9% |

---

## 7. Runbook de producción

Procedimientos operativos para incidentes comunes. Cuando algo falla en producción, este es el playbook.

### 7.1 Crash spike en Crashlytics

1. Revisar dashboard Crashlytics → grupo de crashes con mayor afectación.
2. Identificar versión afectada (¿es la última release?).
3. Si afecta > 5% de usuarios activos → rollback inmediato (publicar versión anterior en stores).
4. Si afecta < 5% → hotfix en branch `hotfix/SPEC-XXX-crash-Y`, ship en < 24 h.
5. Postmortem en `docs/postmortems/YYYY-MM-DD-crash-XXX.md`.

### 7.2 Firestore costs spike

1. Revisar Cloud Console → Firestore → Usage. Identificar día/hora del spike.
2. Buscar query culpable: `lib/**/*data_source*.dart` y verificar `where` + `orderBy` sin límites.
3. Si una query trae > 1000 docs en cliente → agregar `.limit(N)` o paginación.
4. Si el spike es lectura repetida (hot key) → habilitar caché client-side adicional.
5. Postmortem y SPEC remediation.

### 7.3 Paywall no compra (RevenueCat)

1. Verificar status de RevenueCat dashboard: ¿servicios up?
2. Verificar que productos estén "Ready to Submit" en App Store Connect / Play Console.
3. En iOS: ¿está vigente el sandbox tester account?
4. Logs en Crashlytics: filtro por `revenuecat` en errores.
5. Si suscripción no se restaura: forzar `Purchases.restorePurchases()` desde el botón "Restore".

### 7.4 Sincronización Firestore no actualiza UI

1. Verificar que el provider relevante use `StreamProvider` (no `FutureProvider`).
2. Verificar que `autoDispose` no esté disposando antes de tiempo.
3. Buscar `ref.read` en lugares donde debería ser `ref.watch`.
4. Verificar que el ID del doc sea consistente entre escritura y lectura.

### 7.5 Onboarding no completa (usuarios stuck)

1. Revisar Analytics → embudo onboarding. Identificar paso de drop-off.
2. Si drop-off en "Calcular IMR baseline": verificar que `ScoreEngine.calculateBaseline` no esté lanzando excepción para inputs edge (BMI > 50 o < 15).
3. Si drop-off en "Permisos HealthKit": verificar Info.plist tiene `NSHealthShareUsageDescription`.
4. Hotfix con SPEC para flow recovery.

### 7.6 IMR no actualiza después de registrar pilar

1. Verificar `imrPersistenceProvider` está activo en main.dart (ref.read al inicio).
2. Verificar `daily_summary_persistence_service` está vivo (provider en main).
3. Revisar logs: buscar `[DailySummaryPersistence] Snapshot guardado`.
4. Si no aparece: probable `permission-denied` en Firestore — verificar rules.
5. Forzar refresh manual con `ref.invalidate(imrProvider)`.

### 7.7 Soft-launch testers sin acceso

1. App Store Connect → TestFlight → External Testing → Email de invitación reenviado.
2. Para Google Play → Internal Testing → URL de opt-in.
3. Si invitación expira (90 días iOS): reinvitar.

### 7.8 Deep link no abre la app

1. Verificar `AndroidManifest.xml` tiene `intent-filter` correcto para `metamorfosisreal.com`.
2. Verificar `Info.plist` tiene `LSApplicationQueriesSchemes` + Associated Domains.
3. Verificar `apple-app-site-association` y `assetlinks.json` están servidos en metamorfosisreal.com con headers correctos.
4. Logs de `go_router` redirect.

---

## 8. Riesgos y planes de mitigación

### Riesgo R-01 · Apple/Google lanzan IMR-like
- **Severidad:** Alta
- **Probabilidad:** Media (24 meses)
- **Mitigación:** acelerar lanzamiento. Diferenciar en bibliografía científica + B2B. Plan B: pivotar a B2B-only.

### Riesgo R-02 · Costo Firestore explota con escala
- **Severidad:** Media
- **Probabilidad:** Media
- **Mitigación:** medir costo unitario en Fase 2. Si > $0.10/usuario/mes → migración parcial a BigQuery para analytics histórico.

### Riesgo R-03 · App Store rechaza por temas médicos
- **Severidad:** Alta
- **Probabilidad:** Baja
- **Mitigación:** disclaimer clínico (SPEC-76) ya implementado. Listings (SPEC-94) revisados. Plan B: rephrase "salud metabólica" como "bienestar y hábitos".

### Riesgo R-04 · Retención día-30 < 10%
- **Severidad:** Alta
- **Probabilidad:** Media en soft-launch
- **Mitigación:** SPEC-128 (trial) + SPEC-130 (email re-engagement). Si persiste: revisar onboarding con user testing.

### Riesgo R-05 · Carlos como único líder de proyecto (bus factor)
- **Severidad:** Alta
- **Probabilidad:** Baja
- **Mitigación:** este documento + memoria persistente Claude. SPECs autocontenidos. Documentación arquitectónica creciente.

### Riesgo R-06 · Bibliografía científica desactualizada
- **Severidad:** Media
- **Probabilidad:** Baja
- **Mitigación:** revisión trimestral de `IMR_BIBLIOGRAPHY.md` y `CIRCADIAN_BIBLIOGRAPHY.md`. SPEC anual de actualización.

### Riesgo R-07 · Pricing LatAm no rentable
- **Severidad:** Media
- **Probabilidad:** Media
- **Mitigación:** soft-launch valida pricing. Plan B: focus en US/Europa, LatAm como freemium agresivo.

### Riesgo R-08 · Integración HealthKit rechazada por privacidad
- **Severidad:** Media
- **Probabilidad:** Baja
- **Mitigación:** request scopes mínimos. Privacy manifest detallado. Plan B: solo Google Fit.

---

## 9. Glosario operativo

- **IMR (Índice Metabólico Real):** score 0–100 que agrega los 5 pilares + datos biométricos en una métrica única.
- **Pilar:** dimensión de salud medible. Los 5 son: ayuno, sueño, hidratación, ejercicio, nutrición.
- **MR (Metamorfosis Real):** marca paraguas de la plataforma. ElenaApp es el producto digital.
- **SPEC:** documento de especificación numerado bajo `specs/SPEC-XXX-titulo.md`. Patrón SDD (Spec-Driven Development) del proyecto.
- **Soft-launch:** distribución controlada a 50–100 usuarios antes del lanzamiento público.
- **Atribución temporal:** regla que define a qué día calendario se asigna un evento que cruza medianoche (ayuno, sueño).
- **Shape canónico:** estructura del documento `users/{uid}` definida por SPEC-82, compatible con el sitio web MR.
- **Daily Summary:** snapshot diario del IMR + 5 pilares persistido en `users/{uid}/daily_summary/{YYYYMMDD}`.
- **`completedToday`:** flag in-memory + BD que indica si el usuario completó un ayuno con target alcanzado el día calendario actual.

---

## 10. Apéndice de referencias

### Documentos internos del proyecto

- `CONSTITUTION.md` — principios arquitectónicos no negociables.
- `IMR_BIBLIOGRAPHY.md` — fuentes científicas del algoritmo IMR.
- `docs/CIRCADIAN_BIBLIOGRAPHY.md` — bibliografía circadiana canónica.
- `AUDITORIA_PRODUCCION_COMPLETA.md` — auditoría pre-producción del 31-mar-2026.
- `docs/LAUNCH_LISTINGS.md` — copy aprobado para App Store + Play Store.
- `docs/PRODUCTION_HARDENING.md` — checklist de hardening.
- `docs/DEEP_LINKS_SETUP.md` — configuración Universal Links / App Links.

### SPECs base (lectura previa recomendada)

- SPEC-73 / SPEC-74 — Auth Bridge MR↔App.
- SPEC-82 / SPEC-84 — Shape canónico de usuario.
- SPEC-110 / SPEC-111 — Daily Summary + persistencia.
- SPEC-113 / SPEC-115 — Análisis y rebrand "Hoy".
- SPEC-118 — IMR del día visible.

### Referencias externas relevantes

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Firestore Pricing Calculator](https://cloud.google.com/products/calculator)
- [RevenueCat Flutter SDK](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [Google Fit Android API](https://developers.google.com/fit/android)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## Cómo usar este documento

1. **Antes de iniciar un SPEC:** lee la sección 5 correspondiente. Si el contrato no es suficiente, redacta el SPEC completo siguiendo el formato estándar bajo `specs/`.
2. **Al revisar pull requests:** chequea contra los KPIs de la sección 6.
3. **Cuando algo se rompa en producción:** ve a la sección 7 (Runbook). Si el caso no existe ahí, agrégalo después de resolverlo.
4. **Al planear el siguiente sprint:** consulta la Fase actual en la sección 4.
5. **Para incorporar miembros nuevos:** este documento + `CONSTITUTION.md` es el onboarding obligatorio.

Este documento es **vivo**. Cada vez que se cierra una Fase o se aprende algo crítico en producción, se actualiza con una nueva versión semántica (v1.1, v1.2, …) y se commitea con prefijo `docs(roadmap)`.

---

*Fin del documento. Próxima revisión obligatoria: cierre de Fase 1 (30-jun-2026).*
