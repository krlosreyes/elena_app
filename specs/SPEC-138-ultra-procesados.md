# SPEC-138 — Indicador de Ultra-Procesados (UPF)

**Estado:** DRAFT v1.0 — pendiente aprobación de Carlos
**Pilar:** Nutrición
**Autor:** Equipo Claude + Carlos
**Fecha:** 2026-06-05
**Relacionado con:** SPEC-137 (Cociente A), SPEC-148 (Transformation 30d), SPEC-169 (notificaciones), [[feedback_pillar_nutrition]], [[reference_frank_suarez]]

---

## 1. Resumen ejecutivo

Añadimos a ElenaApp un segundo eje de evaluación nutricional —**grado de procesamiento NOVA**— complementario al `qualityScore` continuo que ya existe. El usuario obtiene una métrica clara y trazable: **% UPF semanal** (porcentaje de su plato que vino de ultraprocesados). Con esa métrica disparamos coaching adaptativo y un delta en la Transformation Card 30d.

**Criterios duros respetados** (memoria [[feedback_pillar_nutrition]]):

- ❌ NO es contador de calorías.
- ❌ NO es scanner IA / OCR / cámara.
- ❌ NO requiere DB externa de ingredientes ni APIs nutricionales pagas.
- ✅ Manual, simple, hormonal, < 10 segundos por registro adicional (de hecho **0 segundos extra** — la clasificación NOVA viaja con el `Food` del catálogo).

---

## 2. Marco científico

### 2.1 Sistema NOVA (Monteiro 2019)

NOVA clasifica alimentos en 4 grupos según procesamiento industrial, no por composición nutricional:

| NOVA | Definición | Ejemplos en el catálogo |
|------|------------|--------------------------|
| **1** | Sin procesar / mínimamente procesados | pollo, huevo, espinaca, manzana, aguacate, almendras |
| **2** | Ingredientes culinarios procesados | aceite de oliva, mantequilla, azúcar, miel, panela |
| **3** | Procesados (combinación NOVA1+NOVA2 con técnica artesanal) | queso campesino, jamón sin nitritos, pan integral artesanal |
| **4** | **Ultraprocesados (UPF)** — formulaciones industriales con aditivos cosméticos y/o ingredientes no culinarios | galletas, gaseosa, margarina, salchicha, cereal de caja, hamburguesa industrial |

### 2.2 Evidencia clínica de impacto

- **Hall 2019** (NIH Clinical Center, RCT cruzado, n=20): dieta UPF vs minimamente procesados iguales en macros → grupo UPF consumió **+508 kcal/día** y **subió 0.9 kg en 2 semanas**.
- **Srour 2019** (NutriNet-Santé, n=44,551): cada 10% más de UPF → **+14% riesgo mortalidad total**.
- **Rico-Campà 2019** (SUN cohort, n=19,899): mismo patrón en cohortes mediterráneas.
- **Monteiro 2018** (BMJ Editorial): consenso internacional para usar NOVA en políticas de salud pública.

### 2.3 Coherencia con marco metabólico de ElenaApp

UPF impactan el IMR por tres vías independientes ya modeladas:

1. **Insulínica** — disrupción de saciedad y picos repetidos. Cubierta parcialmente por `qualityScore` actual.
2. **Microbiota** — emulsionantes y conservantes alteran microbioma (Chassaing 2015). NO cubierta aún.
3. **Densidad calórica + palatabilidad hiperestimulante** — sobreconsumo crónico (Hall 2019). NO cubierta aún.

El qualityScore (eje insulínico) **no es suficiente** porque un alimento como leche entera (score 50) y margarina (score 30) son ambos "media" pero NOVA los discrimina (NOVA 1 vs NOVA 4).

---

## 3. Alcance del SPEC

### 3.1 Dentro de alcance

- **RF-138-01:** campo `nova: int (1..4)` en `Food` del catálogo.
- **RF-138-02:** clasificación NOVA de los 80 alimentos existentes (anexo §6).
- **RF-138-03:** métrica derivada `upfSharePercent` (slots NOVA 4 / total slots × 100) calculada a nivel de plato (`PlateBuilder.upfShare`), día (`dailyUpfShareProvider`) y semana (`weeklyUpfShareProvider`).
- **RF-138-04:** badge sutil en el plato cuando se agrega un alimento NOVA 4 (sin bloquear ni avergonzar — copy humano-cercano alineado con [[notification-tone-human-not-clinical]]).
- **RF-138-05:** insight en `CycleFeedback` cuando `weeklyUpfShare > 40%` con cita Monteiro 2019 / Hall 2019.
- **RF-138-06:** delta UPF en `TransformationSnapshot` (SPEC-148): si la franja anterior tenía 55% y la actual 30%, narrar el cambio.
- **RF-138-07:** persistencia en Firestore — agregar campo `upfSlots: int?` a `nutrition_logs/{id}` (nullable para retrocompat).
- **RF-138-08:** tests unitarios + widget para los 4 puntos anteriores.

### 3.2 Fuera de alcance (postpuesto a 138.next o descartado)

- ❌ Scanner OCR / cámara / IA visual de etiquetas (criterio "no scanner").
- ❌ Integración con OpenFoodFacts u otra DB externa (criterio "simple").
- ❌ Cuantificación de aditivos individuales (E-numbers).
- ❌ Recomendar marcas concretas.
- ❌ Personalización por sensibilidad individual a aditivos (requeriría onboarding clínico).

### 3.3 No-objetivos

- **NO penalizar al usuario.** El UPF% es información para que el usuario decida, no para gamificarle vergüenza. El copy es "tu cuerpo lee", no "comiste mal".
- **NO cambiar el `qualityScore` existente.** UPF es eje ortogonal. La penalización metabólica ya está cubierta por el score; lo nuevo es nombrar el patrón.
- **NO contaminar el IMR semanal con un coeficiente UPF directo en la fórmula.** El UPF llega al IMR sólo vía qualityScore (que ya lo refleja parcialmente) y vía insight de coaching. El score numérico del IMR no cambia.

---

## 4. Diseño técnico

### 4.1 Modelo de datos

```dart
// food_catalog.dart — extender Food sin romper callers existentes
class Food {
  final String id;
  final String name;
  final FoodCategory category;
  final int qualityScore;
  final int nova;           // NUEVO — 1..4 (default 1 = no procesado)
  final List<String> searchAliases;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.qualityScore,
    this.nova = 1,           // default seguro: si no se anota, asume no procesado
    this.searchAliases = const [],
  });

  bool get isUltraProcessed => nova == 4;
}
```

```dart
// plate_builder.dart — derivación nueva
extension PlateUpfShare on PlateBuilder {
  /// Porcentaje de slots ocupados por alimentos NOVA 4.
  /// 0 si plato vacío.
  int get upfSharePercent {
    if (totalSlots == 0) return 0;
    final upfSlots = items
        .where((f) => f.isUltraProcessed)
        .fold(0, (sum, f) => sum + f.category.slots);
    return ((upfSlots / totalSlots) * 100).round();
  }
}
```

```dart
// nutrition_log.dart — campo opcional persistido
class NutritionLog {
  // ... campos existentes
  final int? upfSlots;        // slots NOVA 4 del plato. null = log pre-SPEC-138.
  final int? totalSlots;      // slots totales del plato. null = log pre-SPEC-138.
}
```

### 4.2 Providers (Riverpod)

```dart
// nutrition/application/upf_share_provider.dart — NUEVO
final dailyUpfShareProvider = Provider.autoDispose<int>((ref) {
  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  final logs = ref.watch(nutritionLogsForCycleProvider(cycle?.startedAt)).valueOrNull ?? [];
  return _computeUpfShare(logs);
});

final weeklyUpfShareProvider = Provider.autoDispose<int>((ref) {
  final logs = ref.watch(nutritionLogsLast7DaysProvider).valueOrNull ?? [];
  return _computeUpfShare(logs);
});

int _computeUpfShare(List<NutritionLog> logs) {
  final upf = logs.fold(0, (s, l) => s + (l.upfSlots ?? 0));
  final total = logs.fold(0, (s, l) => s + (l.totalSlots ?? 0));
  if (total == 0) return 0;
  return ((upf / total) * 100).round();
}
```

### 4.3 UI

**PlateRatioSheet** — al añadir un alimento NOVA 4, mostrar chip sutil al lado del `_QualityBadge`:

```
[icon] Hay ultraprocesado en tu plato
       Tu cuerpo lo procesa distinto. Está OK puntualmente.
```

**Hoy / Coach** — cuando `weeklyUpfShareProvider > 40` aparece insight tier "atención":

```
Esta semana 47% de tu plato vino de ultraprocesados.
Tu cuerpo lee patrón, no episodio.
· Monteiro 2019 · Hall 2019
```

**Transformation Card 30d** — nuevo `Delta<int> upfShareDelta` en `TransformationSnapshot`. Narrar mejoras grandes ("bajaste de 55% a 28% en 30 días"). No narrar empeoramientos (criterio motivacional).

### 4.4 Pool de copies (humano-cercano)

Aplicar memoria [[notification-tone-human-not-clinical]]. Ejemplos:

- "Tu cuerpo lo agradece cuando le das menos comida industrial." (UPF↓)
- "Notamos que esta semana hubo menos ultraprocesado. Eso se nota en cómo te sentís." (mejora)
- "Está bien tener tu día con algo de eso. El patrón importa más que el plato puntual." (cheat day con UPF)
- "Hoy comiste más industrial que el promedio. Mañana es otro día, sin culpa." (día alto, NO acumulativo)

Pool full en `lib/src/features/nutrition/application/upf_coaching_pool.dart` con 8-10 copies + cita bibliográfica.

---

## 5. Persistencia

### 5.1 Firestore — extensión sin breaking change

Documento `users/{uid}/nutrition_logs/{id}`:

```json
{
  "timestamp": ...,
  "ratio": "a3e1",
  "isCheatDay": false,
  "upfSlots": 1,           // NUEVO opcional
  "totalSlots": 5          // NUEVO opcional
}
```

Mapper en `firestore_user_profile_v1_source.dart` lee con `?? null`. Logs históricos sin estos campos se ignoran en `weeklyUpfShareProvider` (denominator = 0 si no hay datos NOVA confiables → UI muestra placeholder "Aún no tenemos suficiente lectura UPF").

### 5.2 Sin migración hacia atrás

No re-clasificamos logs anteriores. La memoria UPF arranca el día que el usuario actualiza la app y se llena progresivamente. Cuando hay ≥ 14 días con datos UPF → habilitar comparativas de Transformation Card.

---

## 6. Anexo — Clasificación NOVA de los 80 alimentos

Asignación inicial (revisar con Carlos antes de codificar). Marcados solo los NOVA 3 y NOVA 4; el resto se interpreta como NOVA 1 (default).

### NOVA 4 — ULTRAPROCESADOS (10 items)

| id | name | qualityScore actual |
|----|------|--------------------:|
| galletas | Galletas | 5 |
| galletas_dulces | Galletas dulces | 3 |
| cereal | Cereal | 10 |
| salchicha | Salchicha | 50 |
| margarina | Margarina | 30 |
| gaseosa | Gaseosa | 0 |
| cocacola | Coca-Cola | 0 |
| chocolate_caliente | Chocolate caliente | 5 |
| jugo_leche | Jugo en leche | 10 |
| mayonesa | Mayonesa | 50 |

### NOVA 3 — PROCESADOS (12 items)

| id | name |
|----|------|
| jamon | Jamón |
| tocino | Tocino |
| chorizo | Chorizo |
| chicharron | Chicharrón |
| queso_amarillo | Queso amarillo |
| queso_crema | Queso crema |
| pan | Pan |
| pan_integral | Pan integral |
| pasta | Pasta |
| galletas_saladas | Galletas saladas |
| pizza | Pizza |
| hamburguesa | Hamburguesa |
| salchipapa | Salchipapa |
| empanada | Empanada |
| sandwich | Sandwich |
| aceite_vegetal | Aceite vegetal |

### NOVA 2 — INGREDIENTES CULINARIOS (≈6 items)

aceite_oliva, aceite_coco, mantequilla, manteca, azucar, panela, miel, chocolate.

### NOVA 1 — el resto (≈48 items)

Todas las carnes, pescados, huevo, verduras, frutas, legumbres, frutos secos, semillas, lácteos no procesados.

> **Nota de criterio:** Pizza y Hamburguesa están en NOVA 3 cuando son artesanales y NOVA 4 cuando son industriales. Como el catálogo no distingue origen, las dejamos NOVA 3 (interpretación benigna) y la cita en el insight aclara "si fue industrial cuenta como UPF". **Pendiente decisión de Carlos: ¿NOVA 3 conservador o NOVA 4 estricto?**

---

## 7. Tests

- **`food_catalog_nova_test.dart`** — los 80 alimentos tienen NOVA asignado válido (1-4).
- **`plate_builder_upf_test.dart`** — 7 escenarios: plato vacío, todo NOVA 1, 1 ultraprocesado en plato mixto, 100% UPF, cheat day no afecta cálculo, slots cuentan no items, redondeo.
- **`upf_share_provider_test.dart`** — agregación semanal con logs sin campo (pre-138).
- **`upf_coaching_pool_test.dart`** — selección rotativa con cooldown.
- **`transformation_snapshot_upf_test.dart`** — delta UPF se incluye si hay ≥14 días.
- **Widget test** — chip "ultraprocesado en tu plato" aparece al añadir Galletas.
- **Widget test** — insight semanal sólo aparece con UPF% > 40.

Cobertura objetivo: ≥ 80% sobre archivos nuevos.

---

## 8. Plan de entrega (4 bloques)

1. **Bloque A — Modelo** (~30 min): extender `Food`, clasificar 80 alimentos, tests catálogo + builder.
2. **Bloque B — Persistencia** (~25 min): `upfSlots/totalSlots` en NutritionLog, mapper Firestore, log al submit en `nutrition_notifier.dart`.
3. **Bloque C — Providers + Coaching** (~30 min): daily/weekly providers, pool de copies, insight en CycleFeedback.
4. **Bloque D — UI + Transformation** (~25 min): chip en PlateRatioSheet, delta UPF en TransformationCard, smoke tests visuales.

Tiempo total estimado: **~2h** en una sesión. **NO requiere DB externa ni migración.**

---

## 9. Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Usuario confunde UPF% con qualityScore | Copy claro: "qué tan industrial" vs "cómo lo lee tu cuerpo". Onboarding tip en primer disparo. |
| Pizza/Hamburguesa clasificadas ambiguamente | Decisión explícita en §6 + nota en copy de insight ("si fue industrial..."). |
| Logs pre-SPEC sin datos NOVA → falso UPF% bajo | Provider exige ≥ 14 días con datos. Placeholder "estamos aprendiendo tu patrón". |
| Penalizar moralmente al usuario | Pool de copies pasa por filtro [[notification-tone-human-not-clinical]]. NO se muestra "te bajamos puntos por UPF". |
| Doble penalización (qualityScore + UPF) en IMR | Decisión explícita: UPF NO entra al IMR. Solo a insights y narrador. |

---

## 10. Preguntas abiertas para Carlos

1. **Umbral del insight semanal:** propongo 40%. ¿Subir a 50%? ¿Bajar a 30%?
2. **Pizza/Hamburguesa NOVA 3 vs NOVA 4:** ¿interpretación conservadora o estricta?
3. **Chip en el plato:** ¿inline (debajo del `_QualityBadge`) o como toast no-bloqueante? Mi preferencia es inline silencioso.
4. **¿Mostrar UPF% en Hoy de forma permanente?** Mi recomendación: solo si > 25%, para no saturar UI con métricas técnicas.
5. **Bloque que querés que arranquemos primero**, o ¿vamos lineal A → D?

---

## 11. Decisión

Para implementar, requiero `ok recomendación` o ajustes específicos. Si querés que ejecute con tus ajustes, marca §10 punto a punto.

---

## Referencias

- Monteiro CA et al. *Ultra-processed foods: what they are and how to identify them.* Public Health Nutrition 22(5):936-941, 2019.
- Hall KD et al. *Ultra-processed diets cause excess calorie intake and weight gain.* Cell Metabolism 30(1):67-77, 2019.
- Srour B et al. *Ultra-processed food consumption and risk of mortality.* JAMA Internal Medicine 179(4):490-498, 2019.
- Rico-Campà A et al. *Association between consumption of ultra-processed foods and all-cause mortality.* BMJ 365:l1949, 2019.
- Chassaing B et al. *Dietary emulsifiers impact the mouse gut microbiota.* Nature 519:92-96, 2015.
- Monteiro CA. *NOVA. The star shines bright.* World Nutrition 7(1-3):28-38, 2016.
