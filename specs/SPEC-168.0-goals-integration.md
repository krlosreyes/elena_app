# SPEC-168.0 — Goals Integration (paraguas)

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** SPEC paraguas — conectar infraestructura de Goals ya existente al flujo de UX
**Líder:** Carlos
**Implementación:** Claude
**Estimación total:** ~2 sprints
**Padre:** SPEC-168
**Bloquea:** SPEC-168.2 (línea de objetivo), SPEC-168.8 (color por estado)

---

## 1. Contexto

ElenaApp ya construyó toda la infraestructura de metas (SPEC-14 base + SPEC-154 dashboard) pero está **inactiva en UX**:

- Existe `UserGoal` con 6 tipos cubriendo 5 pilares + composición corporal.
- Existe `GoalSuggestionEngine` con cálculos científicos (ACSM, OMS, NIH/Huberman, fisiología hidratación).
- Existe `GoalRepository`, `GoalNotifier`, `GoalSetupScreen`.
- Existe `goalsProgressDashboard` mostrando progreso en Análisis.

Falta:

1. El **onboarding no cierra con goals** — el usuario llega al dashboard sin metas configuradas.
2. **No hay entrada visible** a `/goals/setup` desde Perfil.
3. **Nutrición no tiene GoalType** — solo `mealsPerDay` (no operacional).
4. **Los charts de Análisis** (SPEC-168.2 línea de objetivo, .8 color por estado) necesitan acceso al target en la unidad del chart.

Decisión de líder (Carlos, 2026-06-03):

> "El editar los objetivos en el onboarding debe mostrarle al usuario nuestra recomendación y la posibilidad de editarlos. No simplemente permitirle establecerlos — debemos decirle 'para ti estos objetivos y por qué', pero los puede modificar."

El onboarding debe ser **coaching desde el día uno**, no un formulario en blanco.

## 2. Principio rector

Toda interacción del usuario con sus metas debe seguir el patrón:

> **Para ti recomendamos X** *(número específico, calculado con tus datos)*
> **Por qué:** *rationale científico con los números del usuario, no copy genérico*
> **Puedes ajustarlo** [slider ±25 %]

Esto aplica en onboarding, en edición desde Perfil, y en cualquier nudge de recalibración futura.

## 3. Sub-sub-specs

| ID | Tema | Estimación | Bloquea |
|----|------|-----------|---------|
| **168.0.A** | Paso 5 "Tus objetivos" en onboarding | ~2 h | — |
| **168.0.B** | Botón "Editar mis objetivos" en Perfil | ~30 min | — |
| **168.0.C** | GoalType.nutritionADominantPercent + suggestion | ~1 h | 168.2 (Nutrición) |
| **168.0.D** | goalForChartProvider con conversión de unidad | ~1 h | 168.2 + 168.8 |
| **168.0.E** | Loop de recalibración con avance (backlog Ola 3) | ~1 día | — |

## 4. Orden de ejecución

Sprint **inmediato 1** (paralelizable):
- `168.0.B` (botón Perfil — 30 min, riesgo cero, libera edición ya)
- `168.0.C` (GoalType Nutrición — el `GoalSuggestionEngine` necesita el caso nuevo antes de `.A` y `.D`)
- `168.0.D` (helper de conversión — pure Dart, independiente)
- `168.1` (eje + hero, independiente, paralelizable)

Sprint **inmediato 2** (depende de .C y .D):
- `168.0.A` (onboarding paso 5 — usa GoalSetupScreen actualizado por .C)
- `168.2` (línea de objetivo — usa goalForChartProvider de .D)
- `168.8` (color por estado — usa goalForChartProvider de .D)

Backlog:
- `168.0.E` (recalibración automática) → Ola 3 coaching adaptativo

## 5. Restricciones globales

- **No alterar GoalRepository ni Firestore schema base** — sí extender `GoalType` enum y agregar campos derivados.
- **Migration backward-compat**: usuarios existentes con `goals` map en Firestore deben seguir cargando sin error. El nuevo `GoalType.nutritionADominantPercent` aparece como "no configurado" hasta que el usuario lo active.
- **fastingProtocol** sigue separado en `UserModel` — el goal `fastingDaysPerWeek` lo complementa pero no lo reemplaza. Carlos lo decide más adelante si quieren unificar.
- **Hoy no se toca** (regla heredada de SPEC-168 paraguas).

## 6. Cierre

- [ ] Sub-sub-specs .A, .B, .C, .D redactadas y aprobadas
- [ ] Implementación sprint inmediato 1
- [ ] Implementación sprint inmediato 2
- [ ] Validación visual Carlos en device (onboarding completo + edición desde Perfil + chart con línea de objetivo real)
- [ ] Backlog .E priorizado en Ola 3
