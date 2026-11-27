# SPEC-307 — Onboarding con datos reales

Estado: IMPLEMENTED (27-nov-2026) · Versión: Elena 1.0.1

## Problema
- Fecha 1980, 180 cm y 85 kg aparecían precargados como si fueran del usuario.
- El cuello de las mujeres se estimaba con las tallas de hombre.
- No se pedía la cadera.
- Las metas se calculaban una sola vez, con los valores por defecto (85 kg), y no se recalculaban (`ensureInitialized` salía sin hacer nada).
- Se pedía "Comidas al día" (3) y luego la app mostraba otra cifra (2 con 16:8).

## Cambios
- Nacimiento, estatura, peso y (mujeres) cadera muestran "Toca para ingresar" y bloquean "Siguiente" hasta confirmarlos.
- Cuello femenino inferido con tabla femenina (31–37 cm).
- `OnboardingGoalsController.ensureInitialized` recalcula si cambian las medidas, sin pisar metas que el usuario ajustó.
- "Comidas al día" se muestra derivado del protocolo (`MealTargetService`), igual que en Hoy.
- Sin % de grasa coherente se guarda null con confianza BAJA (antes 15/25 %).
- Prefill desde el sitio incluye `bio.hipCm`.
