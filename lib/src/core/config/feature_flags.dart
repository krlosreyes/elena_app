// Feature flags del proyecto — punto único de fuente.
//
// Cada flag es un `bool const` documentado con la SPEC que lo introduce,
// la condición de habilitación y el riesgo de activarlo sin completar
// el resto del pipeline (validación clínica, telemetría, etc.).
//
// Convención: el default es SIEMPRE el comportamiento "seguro" — el
// que no rompe nada existente. Activar un flag es una decisión
// explícita por commit, no un toggle de runtime.

/// SPEC-141 §RF-141-13 (2026-06-05): habilita el IMR longitudinal
/// como score visible en el badge de Profile.
///
/// **Default: false** — el badge sigue mostrando el IMR diario legacy
/// (`displayedImrProvider`) hasta que el especialista clínico que firmó
/// SPEC-70.5 valide los 4 pesos macro (40 Estructura / 35 BehaviorTrend
/// / 15 Adherence / 10 Coherence).
///
/// **Activar a true cuando:**
/// 1. El especialista firma la validación clínica externa (SPEC-141 §11).
/// 2. El sitio Astro Metamorfosis Real está preparado para leer
///    `imr.current.schemaVersion = 2` (consume `imrScore` directamente,
///    no rompe si vienen los subscores nuevos).
/// 3. Telemetría interna de Carlos confirma que el longitudinal se
///    estabiliza en valores razonables (~50-75 para perfiles activos,
///    no se queda en 0 ni hace saltos > 15 puntos por snapshot).
///
/// **Riesgo de activarlo sin (1):** el badge muestra un número
/// no-validado al usuario. Es OK si lo acompañamos del disclaimer
/// "Validación clínica pendiente" (ya incluido cuando el flag es true).
///
/// **Estado al 2026-06-05:** false. El cálculo + persistencia están
/// activos en background (Bloques A-C), solo falta la firma para que
/// la UI lo muestre.
const bool kEnableLongitudinalImr = false;
