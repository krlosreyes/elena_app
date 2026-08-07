# SPEC-275 — Re-encuesta del intake + variedad/rotación + recetario

**Estado:** IMPLEMENTED — política de re-encuesta (pura + test + banner) y variedad en el motor (param `avoidFoodIds` + test). Recetario / lista de mercado = follow-up de contenido (§5). PENDIENTE de `flutter analyze` + `flutter test`.
**Versión:** 1.0
**Fecha:** 2026-08-07
**Autor:** Claude (líder de proyecto / full-stack) + Carlos (aprobación)
**Pilar:** Nutrición
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-270..274. **Cierra** la reestructuración del pilar.

## 1. Contexto

Última pieza: que la minuta EVOLUCIONE con la persona. Dos mecanismos de la propuesta (§4/§9): re-encuestar el retrato dietético con una cadencia científica, y dar variedad para no repetir el mismo plato.

## 2. Re-encuesta del intake

`IntakeResurveyPolicy` (dominio, PURO): decide si el intake está "vencido" comparando `intake.updatedAt` con ahora. Cadencia (decisión de Carlos, §9): **4 semanas en fase activa, 12 en mantenimiento**. Fundamento: hábito ~66 días (Lally 2010) + adaptación metabólica/mesetas 2–8 semanas.

Cableado: la pantalla de la Minuta (SPEC-273) muestra un **banner "Actualiza cómo comes hoy"** cuando la política marca vencido, con botón que abre el onboarding del pilar (`/nutrition/intake`). Guardar el intake actualiza `updatedAt` y reinicia el reloj.

## 3. Variedad / rotación

El motor (SPEC-272) recibe un parámetro opcional `avoidFoodIds` (por defecto vacío → determinismo intacto). Al elegir alternativas y al garantizar proteína/vegetal/grasa, **prefiere alimentos que NO estén en ese set** (p. ej. los de ayer). Regla de oro: **la variedad nunca sacrifica la calidad** — si todos los candidatos buenos están evitados, igual entrega el mejor plato posible.

## 4. Archivos

Nuevos:

- `lib/src/features/nutrition/domain/intake_resurvey_policy.dart`
- `test/features/nutrition/domain/intake_resurvey_policy_test.dart`
- `test/features/nutrition/domain/meal_plan_generator_variety_test.dart`
- `specs/SPEC-275-reencuesta-variedad-recetario.md`

Modificados:

- `lib/src/features/nutrition/domain/meal_plan_generator.dart` — param `avoidFoodIds` + helper `_pick` (variedad guardada).
- `lib/src/features/nutrition/presentation/meal_plan_screen.dart` — banner de re-encuesta.

## 5. Follow-up (no incluido, a propósito)

- **Recetario y lista de mercado**: requieren estructurar las recetas de *El Milagro Metabólico* (desayunos/platos fuertes/postres) como datos — es una tarea de curación de contenido, no de código. Se hará cuando tengamos el recetario digitalizado.
- **Rotación con historial real**: la capacidad `avoidFoodIds` ya existe y está testeada; falta que el notifier lea el plan de ayer y pase sus foodIds al motor (una lectura extra a `mealPlans/{ayer}`). Se puede activar en cualquier momento sin tocar el motor.
- **Fase (activa vs mantenimiento)**: por ahora la política usa `active` por defecto; derivar la fase del progreso del usuario es un ajuste posterior.

## 6. Tests

`intake_resurvey_policy_test.dart`: umbrales 4/12 semanas (27 no vence, 28 sí; 83 no, 84 sí), `daysUntilDue`, intervalos por fase.
`meal_plan_generator_variety_test.dart`: evitar la proteína de ayer produce otra distinta; sin `avoid` el resultado es idéntico (determinismo); si todo está evitado igual entrega plato completo.

Verificación (Carlos):

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
flutter run
```

## 7. Cierre

Con SPEC-275, la reestructuración del pilar de Alimentación queda completa a nivel de diseño y motor: retrato dietético (270) → datos de la minuta (271) → motor determinístico (272) → UI + ciclo diario (273) → score por adherencia (274/274.2) → evolución (275). Lo que resta es contenido (recetario) y afinación con datos reales de uso.
