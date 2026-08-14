# SPEC-295 — Recalcular la minuta al editar preferencias (fix)

**Estado:** IMPLEMENTED (dominio + notifier + tests). PENDIENTE analyze/test/simulador de Carlos.
**Fecha:** 2026-08-14
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Bug (reporte de Carlos)

"Hice cambios [en preferencias] y las recomendaciones siguen igual." La minuta NO se recalculaba al editar el repertorio.

## 2. Causa

La detección de "editaste" vivía en memoria (`_seenIntakeStamp` en el notifier). Si el notifier se recreaba, si el cambio se guardaba con la app cerrada, o si el orden de eventos no cuadraba, el plan generado ANTES de la edición se quedaba y nunca se marcaba obsoleto.

## 3. Fix (robusto)

- `domain/meal_plan.dart`: nuevo `intakeStampMs` — la marca (`updatedAt` en ms) del intake con que se generó el plan (+ JSON/copyWith).
- `application/meal_plan_factory.dart`: sella cada plan con `intake.updatedAt.millisecondsSinceEpoch`.
- `application/meal_plan_notifier.dart`: `_handleIntakeChange` ahora compara `plan.intakeStampMs` contra `intake.updatedAt`; si difieren (editaste), **regenera**. Se llama también al cargar el plan del stream, así que funciona aunque el notifier se recree o el cambio venga de otra sesión. Se eliminó `_seenIntakeStamp`.
- Tests: `meal_plan_staleness_test.dart`.

## 4. Nota

La regeneración reemplaza los platos por completo (empieza de cero con tus alimentos nuevos): se pierden los ajustes manuales del día (cambios de ingrediente, cantidades, marcas Comí/Cambié). Si se quiere preservar las comidas ya marcadas, es una mejora aparte (ofrecida a Carlos).

## 5. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition
flutter test test/features/nutrition
```

Simulador: Perfil → Alimentación → cambia alimentos → guardar → volver a la Minuta/dashboard → los platos reflejan lo nuevo.
