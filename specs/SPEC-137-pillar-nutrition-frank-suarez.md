# SPEC-137 — Pilar Nutrición: clasificación Tipo A / Tipo E y ventana inferida por protocolo

**Estado:** IN_PROGRESS (aprobada por Carlos 2026-05-22)
**Versión:** 1.1
**Fecha:** 2026-05-22 (v1.0) · refinada 2026-05-22 (v1.1, refinamiento del Paso 3 del onboarding) · aprobada 2026-05-22
**Tipo:** Feature funcional MVP — redefinición del pilar Nutrición
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 1 (Pre-MVP shippable) — bloqueante de la promesa "5 pilares con valor real"
**Estimación:** 4–5 días Carlos+Claude
**Marco normativo:** `CONSTITUTION.md`, `docs/CIRCADIAN_BIBLIOGRAPHY.md`, `docs/NUTRITION_BIBLIOGRAPHY.md` (nuevo, ver doc gemelo), `IMR_BIBLIOGRAPHY.md §5` (a actualizar tras esta SPEC).
**Depende de:** SPEC-64 (NutritionLog v2, no se reescribe — se extiende), SPEC-95 (EatingWindowState), SPEC-98 (selector de protocolo).
**Bloquea:** SPEC-138 (telemetría de adherencia A/E, post-MVP).

---

## 1. Contexto y motivación

La promesa de marca de ElenaApp es "5 pilares con fundamentos científicos verificables". Hoy el pilar Nutrición se mide así (verificado al 22-may-2026):

- Atómo de registro: un `NutritionLog` con etiqueta semántica (Desayuno/Almuerzo/Snack/Cena) + flag `withinCircadianWindow` + macros opcionales (SPEC-64).
- Métrica del pilar (`metabolic_state_builder.dart` línea 105-108):
  ```
  glycemicLoad = 0.60 × (mealsLoggedToday / targetMeals) + 0.40 × windowAdherence
  ```
- Peso en el IMR: 12 % del bloque Conducta (`score_engine.dart` línea 204, post-SPEC-70.5).

Eso significa que el "pilar Nutrición" hoy mide **cuántas comidas registró el usuario** y **si caen dentro de su ventana** — es decir, mide el pilar Ayuno con otro nombre. No mide nada nutricional propio.

La crítica fue documentada en el informe del 6-may §5.1, en el informe del 22-may §1, y en el feedback explícito de Carlos al líder de proyecto el 22-may:

> "Cosas que NO es ElenaApp: contador de calorías, escáner de comidas con IA. El pilar Nutrición debe ser simple, fácil de registrar, aportar valor real. No es complicar al usuario."

El método de referencia operacional del usuario MR es Frank Suárez (clasificación Tipo A / Tipo E y dietas 2x1 / 3x1). Los blueprints adjuntados al proyecto (`Minimalist_Fat_Loss_Protocol`, `The_Metabolic_Miracle`, `Metabolic_Blueprint`) operan dentro de ese marco. Sintetizado en `docs/NUTRITION_BIBLIOGRAPHY.md` (creado en esta misma SPEC).

Esta SPEC redefine el pilar Nutrición sobre tres ejes coherentes con la filosofía hormonal — no calórica — del proyecto.

## 2. Decisión de producto (resumen ejecutivo)

1. **La unidad atómica del registro pasa a ser la proporción Tipo A : Tipo E del plato**, expresada como `MealRatio` enum de cinco posiciones (`allA`, `a3e1`, `a2e1`, `a1e1`, `allE`). El usuario clasifica el plato en un solo gesto.
2. **El target de comidas del día se infiere del protocolo de ayuno + ventana circadiana**, no se pide al usuario. Un 20:4 sugiere 1–2 comidas; un 16:8 sugiere 2 + snack opcional; un "Ninguno" sugiere 3 + snack. La app educa cuando el usuario se sale de su propio protocolo.
3. **La métrica diaria visible al usuario es el "Cociente A"** — porcentaje de platos registrados que fueron A-dominantes. El score del pilar nutrición pasa a depender de este cociente (peso 70 %) + adherencia de ventana (peso 30 %).
4. **Los macros opcionales de SPEC-64 NO se eliminan.** Quedan como capa avanzada para usuarios power y para integración futura con HealthKit Dietary. La nullabilidad es la valida `null = no medido` ya documentada en SPEC-64.
5. **El sistema nervioso (Pasivo / Excitado) se captura en el onboarding** y modula la proporción A:E sugerida por defecto. Pasivos arrancan con 2x1; excitados con 3x1 modificado (más proteína blanca, menos grasa).

## 3. Lo que NO se hace (límites duros de scope)

- No se pide al usuario el peso de la comida en gramos.
- No se pide al usuario el número de calorías.
- No se construye base de datos USDA-style de alimentos.
- No se integra reconocimiento de imágenes / scanner IA.
- No se penaliza al usuario por no registrar comidas (no registrar es neutro, no negativo).
- No se prohíben alimentos. La filosofía "nada está prohibido" (Frank Suárez) es invariante de copy.

Cualquier futuro PR que vulnere estos límites debe abrir SPEC nueva con justificación expresa de cambio de criterio.

## 4. Requisitos funcionales

### RF-137-01 — Enum `MealRatio` y modelo de dominio

Crear enum:
```dart
enum MealRatio {
  allA,   // 100% Tipo A (verdes + proteína + grasas saludables)
  a3e1,   // 75/25 — recomendado para diabéticos / pérdida acelerada
  a2e1,   // 67/33 — recomendado para mantenimiento (default)
  a1e1,   // 50/50 — alerta amarilla
  allE,   // 100% Tipo E — solo en día de permitidos
}
```

Helpers asociados:
- `isADominant` = `{allA, a3e1, a2e1}`.
- `aFraction` (double 0.0–1.0): `1.0, 0.75, 0.67, 0.5, 0.0` respectivamente.
- `label` (String localizado): "Todo A", "3 a 1", "2 a 1", "1 a 1", "Todo E".

### RF-137-02 — Extensión de `NutritionLog`

Sobre el modelo existente de SPEC-64, agregar campo:
- `final MealRatio ratio;` — **obligatorio** en construcciones nuevas. Los logs históricos quedan con `MealRatio.a2e1` (default sensible documentado en mapper).
- `final bool isCheatDay;` — `false` por defecto. Cuando el usuario activa el "día de permitidos" del día, todos los logs nuevos del día se marcan `true`.

Los chips opcionales de composición (proteína animal, verduras verdes, almendras, harina blanca, fruta dulce, lácteo, legumbres) se introducen en SPEC-138 — fuera del scope MVP.

### RF-137-03 — Inferencia de target de comidas por protocolo

Crear servicio puro `MealTargetService.targetForProtocol(String protocol, EatingWindowState window)`:

| Protocolo | Ventana | Target comidas | Snack opcional | Razón |
|---|---|---|---|---|
| `"Ninguno"` | ~14 h (06:30 – 20:30) | 3 | Sí (entre comidas, A-dominante) | Adulto sano sin TRF (`docs/CIRCADIAN_BIBLIOGRAPHY.md §4`). |
| `"16:8"` | 8 h (12:30 – 20:30) | 2 (almuerzo + cena) | Sí (frutos secos / Tipo A) | Salta desayuno; sostiene cena social. |
| `"18:6"` | 6 h (14:30 – 20:30) | 2 (comida + cena) | No | Ventana concentrada; tercer plato fragmenta innecesariamente. |
| `"20:4"` | 4 h (16:30 – 20:30) | 1 (con opción 2) | No | One Meal a Day modificado. Una comida principal completa más una ligera previa al cierre. |
| Cualquier otro | windowHours del fallback (14 h) | 3 | Sí | Default sensible idéntico a "Ninguno". |

El target se persiste en `user_model.mealsPerDay` SÓLO si el usuario lo edita manualmente desde Perfil. Si no, se calcula on-the-fly desde el protocolo activo del día. **El usuario nuevo en onboarding ya no responde "¿cuántas comidas al día?"** (RF-137-08).

### RF-137-04 — Cálculo del Cociente A

Nuevo helper en `metabolic_state_builder.dart`:

```dart
double _calculateCocienteA({
  required List<NutritionLog> todayLogs,
  required int targetMeals,
}) {
  if (todayLogs.isEmpty) return 0.0; // no registrar = neutro, ver RF-137-06
  final aDominantCount = todayLogs.where((l) => l.ratio.isADominant).length;
  return (aDominantCount / todayLogs.length).clamp(0.0, 1.0);
}
```

Anidado: si `todayLogs.length < targetMeals`, el cálculo sigue siendo sobre los registrados (no penaliza la falta de registro). El target sirve para el copy de Hoy ("Tu protocolo sugiere 2 comidas, hoy llevas 1"), no para el score.

### RF-137-05 — Score nutricional del IMR

Modificar la firma del input en `metabolic_state_builder.dart`. El campo `nutritionScoreRaw` del `MetabolicState` ahora se calcula así:

```dart
final double cocienteA = _calculateCocienteA(...);
final double windowAdherence = nutrition.windowAdherence;
final double nutritionScoreRaw =
    (0.70 * cocienteA) + (0.30 * windowAdherence);
```

El peso del pilar Nutrición en el IMR (12 % del bloque Conducta, SPEC-70.5) NO se modifica en esta SPEC. La SPEC-53 (rebalanceo macro) sigue siendo decisión separada.

### RF-137-06 — Comportamiento ante "sin registros"

- 0 platos registrados al día: `cocienteA = 0`, `windowAdherence = 0`, `nutritionScoreRaw = 0`. Empty state en Hoy: *"Aún no registraste comidas. Tu próximo plato cuenta hacia tu Cociente A."*. No penaliza la racha de adherencia hasta el cierre del día (23:59 hora local).
- ≥ 1 plato pero `< targetMeals`: copy informativo, no juicio. *"Llevas 1 de 2 comidas sugeridas para tu protocolo 18:6."*.
- ≥ `targetMeals + 1` plato (sobre-registro): copy de validación suave. *"Estás comiendo más de lo que tu protocolo sugiere. ¿Es día de permitidos?"*. Si NO se marcó `isCheatDay`, el plato cuenta normal (no se descuenta).

### RF-137-07 — Día de permitidos (cheat day)

Toggle accesible desde Hoy con copy *"Hoy es mi día de permitidos"*. Al activarlo:
- Todos los logs del día se persisten con `isCheatDay = true`.
- El Cociente A del día NO entra al cálculo de `weeklyAdherence` (queda excluido como outlier consciente).
- La racha del usuario NO se rompe ese día.
- El usuario ve un badge visible *"Día de permitidos activo"*.
- Lockout: solo se puede activar 1 día por semana ISO. Intento de segundo activa muestra dialog *"Ya usaste tu día de permitidos esta semana (Sábado). Si lo necesitas, hablar con tu coach"*.

Limit semanal documentado en `docs/NUTRITION_BIBLIOGRAPHY.md §6` y bloqueado en código (no es solo UI).

### RF-137-08 — Onboarding Paso 3: estructura general (v1.1)

El Paso 3 del onboarding (`onboarding_screen.dart`) pasa a tener tres sub-secciones en este orden estricto, cada una colapsable (la siguiente se expande automáticamente al validar la anterior):

```
PASO 3 — HÁBITOS Y CONOCERTE
├── 3.A · Conócete primero            (5 preguntas SN, ~40 s)
├── 3.B · Tu protocolo de ayuno       (selector + sugerencia visual)
└── 3.C · Condiciones a considerar    (patologías, ya existente)
```

El slider de `mealsPerDay` (líneas 605-615 actuales) **se elimina**. El target de comidas se infiere de §RF-137-03 a partir del protocolo elegido en 3.B.

**Decisión de orden:** el sistema nervioso (3.A) va ANTES del selector de protocolo (3.B) deliberadamente. Razones:

1. Describir tu estado actual es más fácil que comprometerse con un protocolo. El usuario entra en flujo con preguntas neutras antes de decisiones.
2. Conocer el perfil permite a la app SUGERIR un protocolo apropiado en 3.B (un Excitado tolera peor un 20:4 directo).
3. Si el usuario elige un protocolo incongruente, la app puede mostrar un dialog NO bloqueante (§RF-137-08.C) sin condescendencia.

### RF-137-08.A — Las 5 preguntas calibradas

Cinco preguntas con tres opciones cada una (Pasivo, Excitado, no sé). Copy final aprobado para el MVP:

**Pregunta 1 — Energía al despertar**
> "Cuando suena tu alarma en la mañana, ¿cómo te sientes?"
- 🐢 *Lento, me cuesta levantarme* → **Pasivo +1**
- ⚡ *Alerta, listo para empezar* → **Excitado +1**
- 🤷 *No estoy seguro* → 0

**Pregunta 2 — Latencia de sueño**
> "Cuando te acuestas en la noche, ¿qué pasa primero?"
- 😴 *Caigo rendido en menos de 10 minutos* → **Pasivo +1**
- 🧠 *Doy vueltas pensando, tardo en dormirme* → **Excitado +1**
- 🤷 *Depende del día* → 0

**Pregunta 3 — Apetito matutino**
> "En la primera hora después de despertar, tu cuerpo te pide:"
- 🍳 *Comida — tengo hambre real* → **Pasivo +1**
- ☕ *Solo agua o café, sin hambre* → **Excitado +1**
- 🤷 *Varía mucho* → 0

**Pregunta 4 — Tono baseline**
> "En un día normal sin nada importante, lo que más notas en ti es:"
- 🌊 *Calma, a veces cansancio* → **Pasivo +1**
- ⚡ *Tensión, prisa, mente acelerada* → **Excitado +1**
- 🤷 *Tranquilo, ni una cosa ni la otra* → 0

**Pregunta 5 — Tolerancia digestiva a carne roja**
> "Después de comer una porción de carne roja (res, cerdo o cordero), te sientes:"
- 💪 *Satisfecho y con energía* → **Pasivo +1**
- 😴 *Pesado, lento o hinchado* → **Excitado +1**
- 🥗 *No suelo comer carne roja* → 0

**Notas de copy obligatorias** (consistencia con §11 de `NUTRITION_BIBLIOGRAPHY.md`):

- Las preguntas usan "tu", no "usted". Cercanía LatAm.
- Ningún emoji es decorativo: los íconos refuerzan la opción para usuarios que escanean visualmente.
- La opción "no sé" / "no aplica" está siempre presente. El usuario nunca es forzado a elegir entre dos absolutos.
- Sin lenguaje clínico ("simpático", "parasimpático" no aparecen en pantalla).

**Por qué estas 5 y no otras:** cada pregunta mide un eje distinto del tono autonómico (energía AM, latencia de sueño, apetito AM, tono baseline, tolerancia digestiva). La quinta reemplaza la pregunta v1.0 sobre "preferencia" (que mide cultura, no fisiología) por una sobre tolerancia post-prandial (que mide perfil enzimático). Esto está documentado en `NUTRITION_BIBLIOGRAPHY.md §5.1` y §5.2.

### RF-137-08.B — Mecánica de scoring

```dart
final int scorePassive = answers.where((a) => a.classifies == Passive).length;
final int scoreExcited = answers.where((a) => a.classifies == Excited).length;
final int scoreUnknown = answers.where((a) => a.classifies == null).length;

final NervousSystem result;
if (scoreUnknown >= 3) {
  result = NervousSystem.unknown;
} else if (scoreExcited >= 3) {
  result = NervousSystem.excited;
} else {
  result = NervousSystem.passive; // default seguro para empate, 1-1, 2-2
}
```

Reglas:

1. **Si "no sé" ≥ 3** → `unknown`. La app NO clasifica con datos insuficientes.
2. **Si Excitado ≥ 3** → `excited`.
3. **Cualquier otro caso** → `passive` (default seguro — más perfiles toleran el 2x1 que el 3x1).

### RF-137-08.C — Sugerencia visual en el selector de protocolo (3.B)

Después de las 5 preguntas y ANTES de mostrar los chips del selector de protocolo, aparece una tarjeta de contexto. Tres variantes:

**Variante Pasivo:**

> 🌿 **Tu perfil es Pasivo**
> Tu sistema nervioso descansa profundamente y tu metabolismo responde bien a estímulos digestivos densos.
>
> Para tu perfil sugerimos:
> • Protocolo: **16:8** (recomendado) o 18:6 si ya tienes experiencia
> • Plato sugerido: **2 a 1** (2 partes Tipo A + 1 parte Tipo E)
> • Proteínas: rojas permitidas (res, cerdo, cordero)
> • Café matutino: bienvenido

**Variante Excitado:**

> ⚡ **Tu perfil es Excitado**
> Tu sistema nervioso vive más alerta y se beneficia de menos estímulos pesados.
>
> Para tu perfil sugerimos:
> • Protocolo: **16:8** (recomendado, no más estricto al empezar)
> • Plato sugerido: **3 a 1** (3 partes Tipo A + 1 parte Tipo E)
> • Proteínas: blancas (pollo, pavo, pescado)
> • Café: solo antes del mediodía

**Variante Unknown:**

> 🌱 **Aún estamos conociéndote**
> Vamos a empezar con un plan suave que funciona para la mayoría. Puedes refinarlo cuando quieras desde Perfil → Conócete mejor.
>
> Plan inicial:
> • Protocolo: **16:8**
> • Plato sugerido: **2 a 1**

La tarjeta es informativa, no decisora. Los chips de protocolo (Ninguno · 16:8 · 18:6 · 20:4) aparecen inmediatamente debajo y el usuario tiene la palabra final.

### RF-137-08.D — Dialog de incongruencia (no bloqueante)

Disparador: usuario clasificado `excited` que selecciona protocolo `"20:4"` (el más estricto). El selector NO se bloquea — se muestra un dialog modal:

> 🤔 **Una sugerencia honesta**
>
> Las personas con perfil Excitado (sueño superficial, tensión baseline, apetito matutino bajo) suelen tolerar 20:4 mejor después de adaptarse con 16:8 unas semanas.
>
> Empezar directo con 20:4 puede aumentar tu tensión, empeorar tu sueño y romper la adherencia. No es prohibición — es algo que hemos visto.
>
> **[Empezar con 16:8]** — más sostenible
> **[Mantener 20:4]** — sé lo que estoy haciendo

Persistencia tras "Mantener 20:4":

```
users/{uid}.onboarding.protocolWarningAccepted: "20:4-on-excited"
```

Este flag evita que el dialog se repita en futuros cambios del mismo protocolo desde Perfil.

NO se dispara dialog para:
- Pasivo eligiendo cualquier protocolo (todos son razonables).
- Excitado eligiendo Ninguno / 16:8 / 18:6 (progresión razonable).
- Unknown eligiendo cualquier protocolo (no hay base para advertir).

### RF-137-08.E — Opción de skip

En la cabecera de la sub-sección 3.A hay un link discreto, alineado a la derecha:

> *Prefiero responder esto después →*

Tap en el link:
1. Persiste `nervousSystem: unknown`, `nervousSystemDeclared: false`.
2. Continúa al sub-step 3.B con la variante "Unknown" de la sugerencia (16:8 + 2x1).
3. Dispara un recordatorio en el Dashboard (banner amigable, cada 7 días, descartable) hasta que el usuario complete:
   > "Conocemos lo básico de ti. Cinco preguntas más nos dejan personalizar tu plan. **[Responder ahora]** *Más tarde*"

Tras completar las 5 preguntas desde el banner, el flag `nervousSystemDeclared` pasa a `true` y el banner desaparece.

### RF-137-08.F — Persistencia

Campos nuevos en `users/{uid}`:

```
nervousSystem: String              // "passive" | "excited" | "unknown" — default "unknown"
nervousSystemDeclared: bool        // true si el usuario respondió ≥ 3 preguntas — default false
nervousSystemScore: Map<String, int>?
  // { passive: 0-5, excited: 0-5, unknown: 0-5 } para futura recalibración
  // null si nunca respondió
onboarding.protocolWarningAccepted: String?
  // ej. "20:4-on-excited" — null si nunca disparó el dialog
```

Los tres primeros campos también se reflejan en el shape canónico (SPEC-82) bajo `habits.nervousSystem.*` para que el sitio MR pueda leerlos en el futuro.

### RF-137-09 — Dieta sugerida por sistema nervioso

`MealTargetService.suggestedRatio(NervousSystem ns)` devuelve:
- `passive` → `MealRatio.a2e1` (2x1, proteína roja densa permitida).
- `excited` → `MealRatio.a3e1` (3x1 modificado, proteína blanca recomendada).
- `unknown` → `MealRatio.a2e1` (default seguro, mismo que `passive`).

Es solo una sugerencia de UI; el usuario decide cada plato. La sugerencia se manifiesta de dos formas:

1. **En la sheet de registro** (`PlateRatioSheet`): el slider de 5 posiciones arranca con la posición sugerida según el SN del usuario (slider preseleccionado en `a2e1` para pasivos/unknown, en `a3e1` para excitados). El usuario puede moverlo libremente.
2. **En la tarjeta de Hoy**: un tooltip discreto bajo el Cociente A: *"Tu perfil sugiere apuntar a 67% A (2 a 1)"* o *"75% A (3 a 1)"*.

Si el usuario sostiene durante 14 días un Cociente A consistentemente por encima de la sugerencia (ej. excitado que sostiene 80% Cociente A semanas seguidas), la app puede sugerir reevaluar el perfil — pero esto va a SPEC-138 (telemetría post-MVP), fuera del scope MVP.

### RF-137-10 — UI: sheet de registro (3 toques)

Crear `PlateRatioSheet` en `lib/src/features/nutrition/presentation/plate_ratio_sheet.dart`:

- **Toque 1** (apertura desde Hoy): la sheet aparece.
- **Toque 2**: usuario mueve un slider horizontal de 5 posiciones que representa `MealRatio`. Preview visual: un círculo dividido en proporciones A/E con colores (`#22C55E` para A, `#F59E0B` para E). El usuario también puede tocar directamente cualquiera de los 5 chips (radio buttons grandes, 64 dp).
- **Toque 3**: botón "Registrar" persiste. La sheet se cierra. La tarjeta de Hoy refleja el nuevo Cociente A inmediatamente.

Tiempo objetivo: < 8 segundos desde tap inicial hasta cierre de sheet.

Opcional (un cuarto toque, no obligatorio): tap en "Qué incluyó este plato" expande chips de composición — pero esos chips son SPEC-138 y aquí van **comentados como `// TODO SPEC-138`** en código.

### RF-137-11 — UI: tarjeta "Hoy"

Nueva sección en `dashboard_screen.dart`:

```
NUTRICIÓN
Cociente A: 67% · 2 de 3 platos A-dominantes
[ ●●○○○ ] heatmap de los 3 platos esperados del día
[CTA] Registrar plato      [link] Ver semana
```

Sin la palabra "calorías" en ninguna pantalla del MVP. Sin "kcal". Sin "macros" visibles para el usuario que no entró al modo avanzado.

### RF-137-12 — UI: vista semanal heatmap

Nueva pantalla `NutritionWeeklyScreen` (`features/nutrition/presentation/nutrition_weekly_screen.dart`):

- Grilla 7 días × N platos esperados (calculado por `MealTargetService` por día — un día con protocolo 20:4 muestra 1 celda, otro con "Ninguno" muestra 3).
- Cada celda coloreada según `MealRatio` del log persistido en esa franja.
- Header: Cociente A semanal (promedio de los 7 días).
- Badge "Día de permitidos" en la celda del día marcado (un solo día por semana).

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear enum + helpers | `lib/src/features/nutrition/domain/meal_ratio.dart` |
| 2 | Extender modelo | `lib/src/features/nutrition/domain/nutrition_log.dart` |
| 3 | Actualizar mapper Firestore | `lib/src/features/nutrition/data/mappers/nutrition_log_mapper.dart` |
| 4 | Crear servicio puro | `lib/src/features/nutrition/application/meal_target_service.dart` |
| 5 | Crear servicio Cociente A | `lib/src/features/nutrition/application/cociente_a_service.dart` |
| 6 | Modificar builder | `lib/src/core/engine/metabolic_state_builder.dart` (nutritionScoreRaw) |
| 7 | Agregar campo en UserModel | `lib/src/shared/domain/models/user_model.dart` (`nervousSystem` enum) |
| 8 | Migrar onboarding | `lib/src/features/onboarding/presentation/onboarding_screen.dart` (5 preguntas SN) |
| 9 | Crear sheet de registro | `lib/src/features/nutrition/presentation/plate_ratio_sheet.dart` |
| 10 | Tarjeta "Hoy" Nutrición | `lib/src/features/dashboard/presentation/widgets/nutrition_today_card.dart` |
| 11 | Vista semanal | `lib/src/features/nutrition/presentation/nutrition_weekly_screen.dart` |
| 12 | Day-of-permitidos toggle | `lib/src/features/nutrition/application/cheat_day_notifier.dart` |
| 13 | Doc bibliografía | `docs/NUTRITION_BIBLIOGRAPHY.md` |
| 14 | Actualizar bibliografía IMR | `IMR_BIBLIOGRAPHY.md §5` (apuntar a NUTRITION_BIBLIOGRAPHY.md) |

Archivos NO modificados:
- `nutrition_notifier.dart` continúa orquestando logs (solo recibe el nuevo modelo).
- `score_engine.dart` no cambia su firma. Sigue consumiendo `state.nutritionScoreRaw`.
- SPEC-64 (campos macros opcionales) NO se reescribe. Los campos sobreviven.

## 6. Modelo de datos persistente

```
users/{uid}/nutrition_log/{logId}
  - id: String
  - timestamp: Timestamp
  - label: String           // "Desayuno" / "Almuerzo" / "Snack" / "Cena"
  - withinCircadianWindow: bool
  - ratio: String           // "allA" | "a3e1" | "a2e1" | "a1e1" | "allE"
  - isCheatDay: bool        // default false
  // Macros opcionales SPEC-64 (siguen vigentes, nullables)
  - calories: number?
  - protein: number?
  - carbs: number?
  - fat: number?
  - fiber: number?
  - glycemicIndex: number?
  - source: String          // SPEC-70 trazabilidad
```

Campo nuevo en `users/{uid}`:
```
  nervousSystem: String     // "passive" | "excited" — default "passive"
```

## 7. Criterios de aceptación

1. Un usuario con protocolo `"16:8"` que abre la app sin registros del día ve target = 2 comidas en la tarjeta Hoy.
2. Un usuario con protocolo `"20:4"` ve target = 1 comida.
3. Un usuario con `"Ninguno"` ve target = 3 + snack opcional.
4. La sheet `PlateRatioSheet` permite registrar un plato en ≤ 3 toques principales (apertura, selección de ratio, confirmación).
5. El registro persiste `ratio` correctamente en Firestore con el string del enum.
6. El Cociente A del día se calcula correctamente: 2/3 platos A-dominantes = 67 %.
7. El score del pilar nutrición (`nutritionScoreRaw`) refleja la nueva fórmula `0.70 × cocienteA + 0.30 × windowAdherence`.
8. El IMR mostrado en Hoy se mueve dentro de 10 s después de registrar un plato (pulso metabólico).
9. Activar "Día de permitidos" excluye el día del cálculo `weeklyAdherence` y muestra badge.
10. Intentar activar un segundo "Día de permitidos" en la misma semana ISO es bloqueado por dialog (no por silencio).
11. Onboarding nuevo capta sistema nervioso en 5 preguntas y persiste en `users/{uid}.nervousSystem`.
12. Usuario `passive` ve sugerencia default 2x1; `excited` ve 3x1. Solo es sugerencia visual; el slider sigue libre.
13. La vista semanal heatmap muestra correctamente los días con protocolos heterogéneos (si el usuario cambió de 16:8 a 20:4 a mitad de semana, cada día respeta su target).
14. `flutter analyze` sin issues nuevos.
15. `flutter test` mantiene `+650 ~3` baseline + ≥ 15 tests nuevos (ver §8).
16. La palabra "calorías", "kcal", "macros" no aparece en ninguna pantalla del MVP.
17. Disclaimer médico de `SPEC-76` se reafirma al activar primer "Día de permitidos" — *"Este protocolo no aplica si tienes diabetes tipo 1, trastornos alimentarios o estás embarazada"*.

## 8. Plan de pruebas

### Tests puros (dominio)

`test/features/nutrition/domain/meal_ratio_test.dart`:
- 5 valores cubiertos en `MealRatio.values`.
- `isADominant` true para `allA, a3e1, a2e1`, false para `a1e1, allE`.
- `aFraction` retorna los valores esperados.

`test/features/nutrition/application/meal_target_service_test.dart`:
- protocolo `"Ninguno"` → 3.
- `"16:8"` → 2.
- `"18:6"` → 2.
- `"20:4"` → 1.
- Protocolo desconocido → fallback 3.
- Snack opcional solo en `"Ninguno"` y `"16:8"`.

`test/features/nutrition/application/cociente_a_service_test.dart`:
- Lista vacía → 0.0.
- 1 plato `allA` → 1.0.
- 1 plato `allE` → 0.0.
- 2 A-dominantes + 1 E-dominante → 0.67 ±0.01.
- 3 A-dominantes + `isCheatDay=true` en uno → 1.0 (cheat day no se penaliza, se cuenta como normal en ese día — la exclusión es a nivel weekly).

`test/features/nutrition/domain/nutrition_log_mapper_test.dart`:
- Round-trip Firestore → modelo → Firestore preservando `ratio` y `isCheatDay`.
- Log antiguo sin campo `ratio` cae al default `MealRatio.a2e1`.
- Log antiguo sin `isCheatDay` cae a `false`.

### Tests de integración (engine)

`test/core/engine/metabolic_state_builder_nutrition_test.dart`:
- Estado con 3 platos `a2e1` + window 100 % → `nutritionScoreRaw ≈ 0.7 × 1.0 + 0.3 × 1.0 = 1.0`.
- Estado con 1 plato `allE` + window 50 % → `nutritionScoreRaw ≈ 0.7 × 0.0 + 0.3 × 0.5 = 0.15`.
- Estado con 0 platos → `nutritionScoreRaw = 0.0`.

### Tests de UI (widget)

`test/features/nutrition/presentation/plate_ratio_sheet_test.dart`:
- Render con 5 chips visibles.
- Tap en chip cambia selección sin requerir submit.
- "Registrar" llama al notifier con el `MealRatio` esperado.

### Tests E2E (golden)

Snapshot de:
- Tarjeta "Hoy" con Cociente A 67 %.
- Vista semanal con 7 días variados.
- Onboarding step de sistema nervioso.

## 9. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Subjetividad: dos usuarios clasifican el mismo plato distinto | Media | Aceptable. La métrica es comportamental (consistencia individual), no metabólica exacta. La app no compara entre usuarios el Cociente A absoluto. |
| R-02 | Usuario no sabe si un alimento es A o E | Alta en primeros usos | Mini-buscador inline + tabla canónica de `docs/NUTRITION_BIBLIOGRAPHY.md §3` accesible a 1 tap desde la sheet. Onboarding incluye un tutorial corto de 30 s. |
| R-03 | Reviewer de App Store cuestiona Frank Suárez (no es médico titulado) | Alta | Copy expresa "clasificación pedagógica basada en respuesta insulínica observada". Citar evidencia hormonal de IG/CG (Jenkins, Wolever, Brand-Miller) en disclaimer. Frank Suárez NO aparece como cita clínica en `IMR_BIBLIOGRAPHY.md`. Su nombre vive en `NUTRITION_BIBLIOGRAPHY.md` como referente operacional, no como autoridad científica. |
| R-04 | Logs históricos (pre-SPEC-137) sin `ratio` rompen el cálculo | Cierta | Mapper aplica default `MealRatio.a2e1` para logs sin campo. Documentado. El Cociente A retrocomputado de la primera semana puede no ser representativo — se muestra warning en vista semanal. |
| R-05 | Un usuario excitado con protocolo 20:4 tiene cena tarde + ansiedad → mal sueño | Alta | El sistema nervioso modula la sugerencia 2x1/3x1 pero NO bloquea el protocolo de ayuno. El usuario tiene la palabra final. Si el caso clínico aparece en feedback, evaluar bloqueo blando en SPEC futura. |
| R-06 | "Día de permitidos" se usa para enmascarar atracones repetidos | Media | Lockout semana ISO duro en código (no UI). Si el patrón persiste, SPEC futura agrega telemetría de "días E ≥ 50 % aún sin cheat activo" → empuja al usuario a hablar con coach. |
| R-07 | Confusión: usuario MR existente tenía `mealsPerDay = 5` (legacy) | Baja | Migración: si `mealsPerDay > targetByProtocol` se mantiene el valor del usuario; el copy explica que su perfil tiene comidas extras al protocolo recomendado. No se sobrescribe sin consentimiento. |
| R-08 | El campo `nervousSystem` se persiste para usuarios MR sin onboarding nuevo | Cierta | Default `passive` (más conservador) en `canonical_to_legacy_adapter.dart`. Al primer login post-deploy, mostrar prompt suave "Conocernos mejor: 5 preguntas para personalizar tu plan". No bloqueante. |

## 10. Out of scope (explícito)

- Chips de composición de plato (proteína animal, verduras verdes, harinas, etc.) — SPEC-138.
- Integración con HealthKit Dietary (importar logs de macros desde otras apps) — Fase 2 / SPEC-132.
- Recetas sugeridas por sistema nervioso — SPEC-139.
- Recordatorios automáticos de "registrar tu plato" — vive en `notification_scheduler.dart`, SPEC separada.
- B2B: dashboard del coach que ve Cociente A de la cohorte — SPEC-136 (Fase 3).
- Detección automática de candidiasis-pattern — SPEC-140 (post-MVP, requiere check-in semanal de síntomas).
- Re-equilibrio del peso macro del IMR (subir Conducta a 35 %) — SPEC-53, decisión separada.
- Cualquier feature que requiera el usuario ingresar gramos, kcal, marcas comerciales o tomar fotos del plato.

## 11. Aprobación

Esta SPEC requiere visto bueno explícito de Carlos antes de pasar a IN_PROGRESS. Una vez aprobada:

1. Implementación arranca por el dominio (`meal_ratio.dart`, `meal_target_service.dart`, `cociente_a_service.dart`) con tests primero.
2. Persistencia + mapper.
3. Builder + score engine integration.
4. UI (sheet, tarjeta Hoy, vista semanal).
5. Onboarding del sistema nervioso.
6. Doc `NUTRITION_BIBLIOGRAPHY.md` ya entregado en este mismo paquete (ver doc gemelo).

Estimación final: **4–5 días Carlos+Claude**. La SPEC entra al Sprint 1 inmediatamente después de las pendientes de Fase 1 actual (registro reCAPTCHA real, branch protection final).

---

## 12. Changelog

### Aprobación final v1.1 — 2026-05-22

Carlos aprobó las 5 preguntas calibradas (§RF-137-08.A) y el peso 70/30 del score (§RF-137-05). La SPEC pasa de DRAFT a IN_PROGRESS. Las dos cosas que faltaban revisar quedan confirmadas:

- Las 5 preguntas SN tal como están en §RF-137-08.A entran sin cambios al MVP.
- El score nutricional `nutritionScoreRaw = 0.70 × cocienteA + 0.30 × windowAdherence` queda fijado para MVP. Recalibración futura va a SPEC-138 si la telemetría lo justifica.

### v1.1 — 2026-05-22

Refinamiento del Paso 3 del onboarding pedido por Carlos. Cambios respecto a v1.0:

- **Orden fijado**: el sub-step 3.A (sistema nervioso) va ANTES del 3.B (selector de protocolo). Razón documentada en §RF-137-08.
- **Pregunta 5 reemplazada**. La v1.0 preguntaba "¿prefieres carnes rojas o pescado/pollo?" (mide cultura). La v1.1 pregunta "después de comer carne roja, ¿cómo te sientes?" (mide tolerancia digestiva). Más fiable.
- **Tercera opción "no sé"** añadida en las 5 preguntas. Permite no forzar al usuario que duda y desencadena estado `unknown` (no clasifica con datos insuficientes).
- **Estado `unknown`** introducido en el enum `NervousSystem`. Activa la variante "Aún estamos conociéndote" en §RF-137-08.C y default seguro `a2e1` en §RF-137-09.
- **Copy final** de las 5 preguntas aprobado (§RF-137-08.A). Tono LatAm, sin lenguaje clínico, con emoji semántico (no decorativo).
- **Tarjeta de sugerencia visual** (§RF-137-08.C) ANTES de los chips de protocolo, con tres variantes (Pasivo / Excitado / Unknown). Explica el perfil sin diagnosticar, lista sugerencias concretas (protocolo + plato + proteínas + café).
- **Dialog de incongruencia** (§RF-137-08.D) cuando un usuario Excitado elige 20:4. NO bloqueante, con copy honesto, con persistencia del consent (`protocolWarningAccepted`) para no repetirlo.
- **Opción de skip** (§RF-137-08.E): link discreto *"Prefiero responder esto después →"* en la cabecera de 3.A. Persiste `unknown` + `nervousSystemDeclared: false`. Dashboard muestra banner descartable cada 7 días hasta completar.
- **Persistencia ampliada** (§RF-137-08.F): además de `nervousSystem`, se persisten `nervousSystemDeclared`, `nervousSystemScore` (para recalibración futura) y `onboarding.protocolWarningAccepted`. Los tres primeros se reflejan en el shape canónico bajo `habits.nervousSystem.*`.

### v1.0 — 2026-05-22

Versión inicial. Define `MealRatio`, `MealTargetService`, `cocienteAService`, día de permitidos, 5 preguntas SN (con 2 opciones cada una), 12 archivos a tocar, 17 criterios de aceptación, 8 riesgos, 4-5 días de estimación.

---

## 13. Resultado

(Se completa al cerrar la SPEC.)
