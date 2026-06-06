# SPEC-191 — `sleepTime` / `wakeUpTime` aislados al rol "metadato informativo"

**Estado:** DRAFT v1.0 — auto-aprobado (documental, sin refactor estructural)
**Severidad:** P2 (clarificación de modelo, no fix de bug)
**Origen:** Decisión estratégica de Carlos 2026-06-05 (Tier 3 del refactor "cero reloj").
**Relacionado con:** SPEC-184 (Constitución §1), SPEC-189 (Tier 1), SPEC-190 (Tier 2).

---

## 1. Resumen ejecutivo

Auditoría completa de los 11 archivos que usan `UserProfile.sleepTime` / `wakeUpTime`. **Hallazgo principal: ninguno los usa para definir el día metabólico.** Todos los usos actuales son legítimos según §1 (cero reloj) porque caen en una de estas 5 categorías "metadato informativo del usuario":

| Categoría | Archivos | Uso |
|-----------|----------|-----|
| **Overlay UI** | `sleep_notifier.dart:112-115` (`updateSleepConsciousness`) | Mostrar "buenos días" cuando estás en ventana de despertar configurada |
| **Notificaciones programadas** | `notification_scheduler.dart:48-49, 146-147, 164-165, 388-389` | Agendar push a la hora que el usuario eligió |
| **Estimación heurística** | `goal_suggestion_engine.dart:309-311` (`_estimateSleepHours`) | Sugerir goal de horas de sueño |
| **UI de edición** | `profile_screen.dart:143-148`, `onboarding_screen.dart:126-127` | Que el usuario configure sus horas |
| **Fallback `fellAsleep` en SleepLog manual** | `fasting_notifier.dart:398`, `sleep_notifier.dart:160` (`confirmManualWakeUp`) | Inferir hora de dormida si el usuario hace "wake up" manual sin haber registrado el sleep |

**Conclusión:** no hay código que eliminar ni que migrar. SPEC-191 es **documental**: marca cada uso con un comentario que clarifica el rol y por qué no viola §1.

---

## 2. El test ácido del modelo

Para cualquier uso futuro de `sleepTime/wakeUpTime`, aplicar este test:

> **¿Este código está definiendo "cuándo empieza o termina el día metabólico" basándose en estos campos?**
>
> - **Sí** → viola §1. Refactor obligatorio. Usar `cycle.startedAt` / `cycle.closedAt` en su lugar.
> - **No** → uso legítimo. Documentar con comentario inline citando esta SPEC.

---

## 3. Cambios concretos

### 3.1 — Documentación inline (5 callsites)

Añadir comentarios `// SPEC-191:` en los 5 archivos de la tabla §1 explicando por qué su uso es legítimo bajo §1 de la constitución.

### 3.2 — Constitución §7

Añadir entrada SPEC-191 en histórico.

### 3.3 — Sección nueva en constitución (`§9 — `sleepTime`/`wakeUpTime`: el test ácido`)

Insertar el test ácido del §2 de esta SPEC en la constitución para que sirva de checklist para PRs futuros.

---

## 4. Lo que NO se hace

- **No se elimina** el campo `UserProfile.sleepTime` ni `wakeUpTime` del esquema. Sigue siendo metadato útil para personalización.
- **No se cambia** ninguna lógica de notificaciones ni overlay.
- **No se modifica** el goal_suggestion_engine.
- **No se toca** el fallback de `confirmManualWakeUp` — es heurístico razonable mientras HealthKit no devuelva el `fellAsleep`. Si en el futuro queremos eliminar esa heurística, sería SPEC aparte.

---

## 5. Plan de entrega

- **Bloque único** (~15 min): añadir comentarios `// SPEC-191:` en los 5 callsites + actualizar §7 y agregar §9 a la constitución + commit.

---

## 6. Decisión

Como no hay refactor estructural, esta SPEC se auto-aprueba. Si Carlos quiere ajustes al test ácido o al copy de §9, decir antes de cerrar.

---

## 7. Referencias internas

- `docs/METABOLIC_DAY_CONSTITUTION.md §1` (cero reloj)
- `specs/SPEC-189-*.md` (Tier 1 — operación sin reloj)
- `specs/SPEC-190-*.md` (Tier 2 — analítica por ciclos)
