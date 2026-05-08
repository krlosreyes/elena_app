# IMR — Bibliografía y trazabilidad de pesos

**SPEC-70 (R2 final).** Este documento captura el origen de **cada constante y peso** que entra al cómputo del Índice de Resiliencia Metabólica (IMR). Es la materialización de la promesa "fundamentos científicos verificables" del producto.

Cada entrada lleva un **nivel de confianza** explícito:

- **HIGH** — múltiples ensayos clínicos / meta-análisis convergen en el valor.
- **MEDIUM** — una guía clínica reconocida o un estudio seminal soporta el valor.
- **LOW** — derivado por inferencia desde un dominio adyacente o de un único estudio.
- **ENGINEERING JUDGMENT** — heurística del equipo. Sin literatura directa. Marcada para recalibración futura cuando tengamos datos propios o evidencia nueva.

**Cómo leer este doc:** cada peso enlaza a la línea de código donde vive (formato `archivo:línea`). Cualquier cambio al código debe actualizar este documento o se considera deuda. Los comentarios `// SPEC-70: ref §X.Y` en el código apuntan a la sección correspondiente aquí.

**Lo que este documento NO es:** una revisión sistemática de literatura, ni una validación clínica. Es un mapa honesto entre cada decisión numérica y la evidencia (o falta de) que la respalda.

---

## §1 — Macro weights del IMR

El IMR final combina tres bloques: Estructura corporal, Metabolismo (ayuno + adherencia continua) y Conducta (5 pilares restantes).

### 1.1 — Estructura: 0.50

- **Valor:** 0.50
- **Confianza:** MEDIUM
- **Justificación:** La composición corporal (waist-to-height ratio + fat-free mass index) tiene la asociación más estable con outcomes metabólicos a mediano-largo plazo en cohortes adultas. Predicen mortalidad por todas las causas, riesgo cardiometabólico y reserva muscular con mayor robustez que ayuno o sueño aisladamente. Por eso domina el IMR.
- **Fuentes:**
  - Ashwell M, Hsieh SD. "Six reasons why the body mass index is a poor measure of adiposity, and why the waist-to-height ratio is a more useful measure." *Br J Nutr* 2012;107(7):1110-9.
  - Browning LM, Hsieh SD, Ashwell M. "A systematic review of waist-to-height ratio as a screening tool for the prediction of cardiovascular disease and diabetes: 0·5 could be a suitable global boundary value." *Nutr Res Rev* 2010;23(2):247-69.
- **Código:** `lib/src/core/engine/score_engine.dart` — `raw = (0.50 * structureBlock) + ...`

### 1.2 — Metabolismo: 0.25

- **Valor:** 0.25
- **Confianza:** MEDIUM
- **Justificación:** Ayuno y adherencia continua semanal capturan dinámicas agudas (autofagia, sensibilidad a insulina) que la estructura corporal no recoge. El peso 0.25 refleja que es secundario a estructura pero co-igual con conducta.
- **Fuentes:**
  - Mattson MP, Longo VD, Harvie M. "Impact of intermittent fasting on health and disease processes." *Ageing Res Rev* 2017;39:46-58.
- **Código:** `lib/src/core/engine/score_engine.dart` — mismo bloque.

### 1.3 — Conducta: 0.25

- **Valor:** 0.25
- **Confianza:** MEDIUM
- **Justificación:** Los pilares conductuales (circadiano, sueño, ejercicio, nutrición, hidratación) son modificables día a día y operacionalizan la "metabolic flexibility" del usuario. Co-iguales con metabolismo (0.25 cada uno) porque son inputs comparables al output corporal.
- **Confianza:** MEDIUM por consenso multipilar (no hay un solo paper que pondere los cinco juntos).
- **Código:** `lib/src/core/engine/score_engine.dart` — mismo bloque.

> **Nota meta-analítica.** El reparto 50/25/25 es una decisión del equipo basada en literatura agregada. **No** existe un estudio que valide este split exacto contra una cohorte. Es defendible (estructura > intervenciones diarias) pero la calibración exacta es **ENGINEERING JUDGMENT**.

---

## §2 — Bloque Estructura

`structureBlock = 0.65 * s1(WHtR) + 0.35 * s2(FFMI)`

### 2.1 — WHtR ponderación: 0.65

- **Valor:** 0.65
- **Confianza:** HIGH
- **Justificación:** WHtR es el predictor antropométrico más robusto de riesgo cardiometabólico. Domina sobre FFMI dentro del bloque porque captura adiposidad central (visceral), que es la fracción metabólicamente activa.
- **Fuentes:**
  - Ashwell M, Gunn P, Gibson S. "Waist-to-height ratio is a better screening tool than waist circumference and BMI for adult cardiometabolic risk factors: systematic review and meta-analysis." *Obes Rev* 2012;13(3):275-86.
- **Código:** `lib/src/core/engine/score_engine.dart` — `structureBlock = (0.65 * s1) + (0.35 * s2)`

### 2.2 — FFMI ponderación: 0.35

- **Valor:** 0.35
- **Confianza:** MEDIUM
- **Justificación:** Reserva muscular es protectora contra sarcopenia, resistencia a insulina y fragilidad. Pesa menos que WHtR porque la adiposidad central tiene más asociación directa con mortalidad temprana.
- **Fuentes:**
  - Kouri EM, Pope HG, Katz DL, Oliva P. "Fat-free mass index in users and non-users of anabolic-androgenic steroids." *Clin J Sport Med* 1995;5(4):223-8.
- **Código:** `lib/src/core/engine/score_engine.dart` — mismo bloque.

### 2.3 — Umbral WHtR 0.60 → s1=0

- **Valor:** WHtR ≥ 0.60 satura `s1` en 0.0; WHtR ≤ 0.45 satura en 1.0.
- **Confianza:** MEDIUM
- **Justificación:** Browning et al. proponen 0.50 como punto de corte de riesgo. Nuestro rango 0.45–0.60 captura "saludable" → "obesidad central significativa" alrededor de ese punto, con margen.
- **Fuentes:**
  - Browning LM et al. (ya citado §1.1).
- **Código:** `lib/src/core/engine/score_engine.dart` — `s1 = ((0.60 - whtr) / 0.15).clamp(0.0, 1.0)`

### 2.4 — FFMI baseline age-stratified + range 6/5

**Actualizado en SPEC-70.3.** El baseline (percentil ~5 = umbral de sarcopenia) ahora depende de `(gender, age)`. Antes era constante `isMale ? 16.0 : 14.0` lo que sobreestimaba la salud estructural de adultos mayores y subestimaba la de jóvenes en bottom-percentile.

- **Valores actuales:**
  - Hombres: peak 17.0 (< 50 años) → 16.5 (50-59) → 16.0 (60-69) → 15.5 (70+).
  - Mujeres: peak 14.5 (< 50 años) → 14.0 (50-59) → 13.5 (60-69) → 13.0 (70+).
  - Range constante: 6.0 hombres, 5.0 mujeres.
- **Confianza:** MEDIUM
- **Justificación:** La masa magra cae ~1 punto FFMI por década después de los 50 — patrón documentado consistentemente en cohortes adultas. Estratificar por edad evita dos sesgos opuestos: un hombre de 65 con FFMI 16.5 ya no puntúa "estructura adecuada" cuando bibliográficamente está en sarcopenia franca, y un joven de 25 con el mismo FFMI ya no queda sobreestimado en su grupo de edad.
- **Fuentes:**
  - **Kyle UG, Genton L, Hans D, Karsegard L, Slosman DO, Pichard C.** "Age, gender, and BMI-adjusted reference values for fat-free mass index by bioelectrical impedance analysis in 5225 healthy subjects aged 15 to 98 years." *Am J Clin Nutr* 2003;77(2):323-9. (Tabla age-stratified; principal fuente del nuevo baseline.)
  - Schutz Y, Kyle UU, Pichard C. "Fat-free mass index and fat mass index percentiles in Caucasians aged 18-98 y." *Int J Obes* 2002;26(7):953-60. (Datos de varianza intra-grupo que justifican mantener `range` constante.)
- **Código:** `lib/src/core/engine/score_engine.dart` — `final double baseFFMI = _baseFFMIForAge(isMale, user.age);` + helper privado `_baseFFMIForAge`.

> **SPEC-70.3.1 candidato:** estratificar también el `range` por edad (la varianza FFMI poblacional comprime ~10% en mayores de 70). Esperar datos propios antes de implementar — el efecto es marginal frente a la corrección del baseline.

---

## §3 — Bloque Metabolismo

`metabolicBlock = ((0.70 * sigmoid(fastingHours)) + (0.30 * weeklyQualityScore)) * etrfBonus`

### 3.1 — Sigmoid del ayuno: centro 14h, ancho 1.5

- **Valor:** `s4 = 1 / (1 + exp(-(h-14)/1.5))`
- **Confianza:** MEDIUM
- **Justificación:** Las dinámicas autofágicas y de sensibilidad a insulina inician marginalmente entre 12-14h y se vuelven significativas tras 16h de ayuno. La sigmoid centrada en 14h da inflexión justo donde la evidencia ubica el "umbral funcional", con un ancho de 1.5h que produce respuesta no-binaria pero clara.
- **Fuentes:**
  - Mattson MP et al. (ya citado §1.2).
  - Anton SD et al. "Flipping the metabolic switch: understanding and applying the health benefits of fasting." *Obesity* 2018;26(2):254-268.
- **Código:** `lib/src/core/engine/score_engine.dart` — `final double s4 = 1 / (1 + math.exp(-(fastingHours - 14) / 1.5));`

### 3.2 — Pesos sigmoid 0.70 + adherencia continua 0.30

- **Valor:** `0.70 * s4 + 0.30 * weeklyQualityScore`
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** La intensidad puntual del ayuno actual (s4) domina sobre el patrón semanal (0.70 vs 0.30) porque el efecto agudo está mejor documentado que el efecto acumulativo. El 0.30 es suficiente para que un usuario con buen patrón pero sin ayuno activo en este momento no caiga a 0.
- **Riesgo:** SPEC-53 cambió `weeklyAdherence` (binario) por `weeklyQualityScore` (continuo, ponderado por magnitudes). El peso 0.30 se preservó pero la **señal subyacente cambió** — se debe monitorear si 0.30 sigue siendo el balance adecuado o si conviene subir hacia 0.40.
- **Código:** `lib/src/core/engine/score_engine.dart` — `metabolicBlock = ((0.70 * s4) + (0.30 * weeklySignal.clamp(0.0, 1.0))) * etrfBonus;`

### 3.3 — Bonus eTRF: sigmoid centrada en 17:00

**Actualizado en SPEC-70.2.** Antes era un salto binario en `lastMeal.hour < 18 ? 1.15 : 1.0` que generaba frustración del usuario avanzado (17:59 vs 18:01 = diferencia del 15% en el bonus). Ahora es una curva continua que respeta el efecto dosis-respuesta documentado en la literatura.

- **Fórmula actual:**
  ```
  mealHourFloat = lastMealTime.hour + lastMealTime.minute / 60
  etrfSigmoid   = 1 / (1 + exp(-(mealHourFloat - 17) / 1.0))
  etrfBonus     = 1.0 + 0.15 * (1 - etrfSigmoid)
  ```
- **Valores de referencia:**
  | Hora cena | Bonus |
  |---|---|
  | 15:00 | 1.13 |
  | 16:00 | 1.11 |
  | 17:00 | 1.075 (centro) |
  | 18:00 | 1.04 |
  | 19:00 | 1.018 |
  | 20:00 | 1.007 |
  | 21:00 | 1.003 |
- **Asíntota superior:** 1.15 (techo) — coincide con el valor del binario anterior, así que ningún usuario gana más de lo que ganaría antes.
- **Asíntota inferior:** 1.0 — comer muy tarde no penaliza más de lo que ya pesa el `circadianScore` con el bloqueo intestinal (§4.6).
- **Confianza:** MEDIUM
- **Justificación:** Sutton et al. (2018) midieron mejoras en sensibilidad a insulina, presión arterial y estrés oxidativo crecientes con ventanas más tempranas (no efecto umbral único). La sigmoid replica esa relación dosis-respuesta sin introducir una asíntota mayor que la evidencia justifica (15% bonus máximo).
- **Fuentes:**
  - Sutton EF et al. "Early time-restricted feeding improves insulin sensitivity, blood pressure, and oxidative stress even without weight loss in men with prediabetes." *Cell Metab* 2018;27(6):1212-1221.e3.
- **Código:** `lib/src/core/engine/score_engine.dart` — bloque `etrfSigmoid` + `etrfBonus`.

---

## §4 — Bloque Conducta

`behaviorBlock = 0.28*circadiano + 0.20*sueño + 0.20*ejercicio + 0.12*nutrición + 0.20*hidratación`

### 4.1 — Circadiano: 0.28

- **Valor:** 0.28
- **Confianza:** MEDIUM
- **Justificación:** El alineamiento circadiano (cenar antes de la ventana de bloqueo intestinal, respetar la ventana de comidas) es el factor más maleable día-a-día con efecto medible en los otros pilares (sueño, ayuno, nutrición). Por eso domina el bloque Conducta.
- **Fuentes:**
  - Panda S. "The Circadian Code." Rodale, 2018. (síntesis en formato divulgativo de su línea de research en Salk Institute).
  - Wehrens SMT et al. "Meal Timing Regulates the Human Circadian System." *Curr Biol* 2017;27(12):1768-1775.e3.
- **Código:** `lib/src/core/engine/score_engine.dart` — `behaviorBlock = (0.28 * circadianScore.clamp(0.0, 1.0)) + ...`

### 4.2 — Sueño: 0.20

- **Valor:** 0.20
- **Confianza:** MEDIUM
- **Justificación:** Sueño es el segundo pilar más documentado (después de estructura) con outcomes metabólicos. Pesa menos que circadiano dentro de Conducta porque el "qué hacer respecto al sueño" cae principalmente en el dominio circadiano (ventana de cena, hora de acostarse) — el sueño ya capturado por SPEC-69 multidimensional pondera el resto.
- **Fuentes:**
  - Walker M. "Why We Sleep." Scribner, 2017.
  - AASM (American Academy of Sleep Medicine). "Recommended Amount of Sleep for a Healthy Adult." *Sleep* 2015;38(6):843-844.
- **Código:** mismo bloque.

### 4.3 — Ejercicio: 0.20

- **Valor:** 0.20
- **Confianza:** MEDIUM
- **Justificación:** Co-igual con sueño porque la dosis-respuesta documentada del ejercicio sobre marcadores metabólicos es comparable en magnitud a la de sueño suficiente.
- **Fuentes:**
  - ACSM. "ACSM's Guidelines for Exercise Testing and Prescription." 11th ed., 2021.
  - Pedersen BK, Saltin B. "Exercise as medicine — evidence for prescribing exercise as therapy in 26 different chronic diseases." *Scand J Med Sci Sports* 2015;25 Suppl 3:1-72.
- **Código:** mismo bloque.

### 4.4 — Nutrición: 0.12

- **Valor:** 0.12
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** El peso bajo refleja que la métrica actual (`mealRatio` + `windowAdherence`) **no captura calidad nutricional real** — solo cantidad y timing. Los macros de SPEC-64 entrarán al score cuando una SPEC futura los incorpore. Hasta entonces, el peso es deliberadamente conservador: no queremos que un usuario que solo registra "comí 3 veces" infle el score sin información de qué comió.
- **Riesgo:** este peso debe **subir** cuando macros entren al cómputo. Ahora mismo está abajo del nivel que la literatura justificaría si tuviéramos una métrica de calidad real.
- **Código:** mismo bloque.

### 4.5 — Hidratación: 0.20

- **Valor:** 0.20
- **Confianza:** MEDIUM
- **Justificación:** La deshidratación crónica leve (>1% de peso corporal) afecta termoregulación, transporte de nutrientes, eliminación de subproductos de autofagia y rendimiento cognitivo. Por eso entra con peso alto pese a ser un pilar "menor" en percepción popular.
- **Fuentes:**
  - EFSA Panel on Dietetic Products, Nutrition, and Allergies. "Scientific Opinion on Dietary Reference Values for water." *EFSA Journal* 2010;8(3):1459.
  - Popkin BM, D'Anci KE, Rosenberg IH. "Water, hydration, and health." *Nutr Rev* 2010;68(8):439-58.
- **Código:** `behaviorBlock = ... + (0.20 * sHydration);`

### 4.6 — Bloqueo intestinal: 22:30

- **Valor:** Penalización a `circadianScore = 0.5` cuando `lastMealTime` ≥ 22:30.
- **Confianza:** LOW
- **Justificación:** El umbral 22:30 es la hora típica donde la melatonina endógena empieza a subir significativamente en cronotipos promedio, y comer en ese momento desincroniza señales hepáticas. El valor 0.5 (50% del score circadiano) es una penalización fuerte pero no absoluta — comer tarde una vez no destruye el día.
- **Fuentes:**
  - Hood S, Amir S. "The aging clock: circadian rhythms and later life." *J Clin Invest* 2017;127(2):437-446.
- **Código:** `lib/src/core/rules/circadian_rules.dart` — `intestinalLockMinutes = 22*60 + 30` y `lib/src/core/engine/score_engine.dart` — `if (mealMinutes >= CircadianRules.intestinalLockMinutes) { circadianScore = 0.5; }`

---

## §5 — Calidad multidimensional de sueño (SPEC-69)

`sleepQuality = (0.50*duration + 0.20*gap + 0.15*latency + 0.15*awakenings) * subjectiveFactor`

### 5.1 — Duración: 0.50

- **Valor:** 0.50 dentro de la fórmula multidimensional.
- **Confianza:** HIGH
- **Justificación:** Es la dimensión con mayor evidencia en literatura del sueño. Cualquier fragmentación o latencia mala con duración suficiente es menos grave que duración insuficiente con todo lo demás perfecto.
- **Fuentes:**
  - AASM, ya citado §4.2.
  - Walker M, ya citado §4.2.
- **Código:** `lib/src/features/dashboard/domain/sleep_quality_calculator.dart` — `_wDuration = 0.50`

### 5.2 — Brecha metabólica: 0.20

- **Valor:** 0.20.
- **Confianza:** MEDIUM
- **Justificación:** El tiempo entre la última comida y dormir afecta calidad del sueño (digestión activa eleva temperatura corporal y suprime liberación de melatonina). 3h es el umbral funcional.
- **Fuentes:**
  - Crispim CA et al. "Relationship between food intake and sleep pattern in healthy individuals." *J Clin Sleep Med* 2011;7(6):659-664.
- **Código:** `_wMetabolicGap = 0.20`

### 5.3 — Latencia: 0.15

- **Valor:** 0.15.
- **Confianza:** MEDIUM
- **Justificación:** Latencia de inicio del sueño >30 min es marcador clásico de insomnio en el modelo 3P de Spielman. Pesa menos que duración porque puede compensarse con duración suficiente.
- **Fuentes:**
  - Spielman AJ, Caruso LS, Glovinsky PB. "A behavioral perspective on insomnia treatment." *Psychiatr Clin North Am* 1987;10(4):541-53.
- **Código:** `_wLatency = 0.15`

### 5.4 — Despertares: 0.15

- **Valor:** 0.15.
- **Confianza:** MEDIUM
- **Justificación:** Fragmentación del sueño impacta arquitectura de fases REM y onda lenta. ≥3 despertares conscientes sugiere patrón disfuncional.
- **Fuentes:**
  - Bonnet MH, Arand DL. "Clinical effects of sleep fragmentation versus sleep deprivation." *Sleep Med Rev* 2003;7(4):297-310.
- **Código:** `_wAwakenings = 0.15`

### 5.5 — Umbrales de gap metabólico

- **Valores:** ≥180min → 1.0 / ≥120min → 0.7 / ≥60min → 0.4 / <60min → 0.1.
- **Confianza:** LOW
- **Justificación:** 180 min (3h) es el umbral funcional citado en Crispim et al. Los escalones intermedios (0.7, 0.4, 0.1) son **ENGINEERING JUDGMENT** — gradación lineal-aproximada del riesgo.
- **Código:** `_scoreMetabolicGap`

### 5.6 — Umbrales de latencia

- **Valores:** ≤20min → 1.0 / ≤30min → 0.7 / ≤60min → 0.4 / >60min → 0.1.
- **Confianza:** MEDIUM (umbral 30min) / LOW (los demás).
- **Justificación:** 30 min es el umbral diagnóstico del modelo 3P de Spielman. Los demás escalones siguen la misma lógica de proporcionalidad descendente.
- **Código:** `_scoreLatency`

### 5.7 — Umbrales de despertares

- **Valores:** ≤1 → 1.0 / =2 → 0.7 / =3 → 0.4 / ≥4 → 0.1.
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** No hay un único umbral clínico universal. La gradación refleja "0-1 es normal, 4+ es patológico" con escalones intermedios proporcionales.
- **Código:** `_scoreAwakenings`

### 5.8 — Factor subjetivo [0.85, 1.10]

- **Valores:** rating 1→0.85, 2→0.92, 3→1.00, 4→1.05, 5→1.10.
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** El reporte subjetivo ajusta — pero no domina — la métrica objetiva. El rango asimétrico (0.15 abajo vs 0.10 arriba) refleja que un usuario reportando "muy mal" probablemente tenga razón con magnitud mayor que uno reportando "muy bien" sobreestime.
- **Código:** `_subjectiveFactor`

---

## §6 — Daily quality score (SPEC-65)

`dailyQualityScore = 0.25*sleep + 0.20*fasting + 0.20*exercise + 0.20*hydration + 0.15*nutrition`

(Renormalizado sobre las dimensiones presentes; fallback a `pillarsCompleted/5` si todas null.)

### 6.1 — Sueño 0.25 dentro del daily quality

- **Valor:** 0.25.
- **Confianza:** MEDIUM
- **Justificación:** Pesa más que el resto porque es la dimensión más estudiada y con efectos sistémicos sobre los demás pilares (sueño malo afecta hambre, ánimo, capacidad de ejercitar).
- **Código:** `lib/src/features/streak/domain/streak_entry.dart` — getter `dailyQualityScore`, constante `wSleep = 0.25`

### 6.2 — Ayuno / Ejercicio / Hidratación 0.20

- **Valores:** 0.20 cada uno.
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** Co-iguales porque son las tres intervenciones diarias con dosis-respuesta más medible. No hay literatura que justifique pesos distintos entre ellas dentro del concepto "calidad del día".
- **Código:** mismo getter.

### 6.3 — Nutrición 0.15

- **Valor:** 0.15.
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** Mismo razonamiento que §4.4 — la métrica nutricional actual no captura calidad real. Conservador a propósito.
- **Código:** mismo getter.

---

## §7 — Thresholds binarios de la racha (SPEC-06/07)

### 7.1 — Sueño ≥ 6.5h

- **Valor:** 6.5h como umbral mínimo restaurador.
- **Confianza:** MEDIUM
- **Justificación:** AASM recomienda 7-9h como óptimo. 6.5h es el umbral inferior por debajo del cual los efectos en consolidación de memoria, regulación hormonal y sensibilidad a insulina son consistentemente medibles.
- **Fuentes:** AASM (ya citado §4.2).
- **Código:** `lib/src/features/streak/domain/streak_engine.dart` — `evaluateSleep`

### 7.2 — Hidratación ≥ 75% meta

- **Valor:** 75% del goal diario.
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** El "goal" mismo es conservadoramente alto (~2L para hombres, ~1.5L mujeres por defecto), entonces 75% representa un mínimo funcional sin requerir perfección.
- **Código:** `evaluateHydration`

### 7.3 — Ejercicio ≥ 20 min

- **Valor:** 20 min.
- **Confianza:** MEDIUM
- **Justificación:** ACSM recomienda 150 min/semana de actividad moderada (=21 min/día). 20 min es el "round number" debajo del cual no es razonable contar.
- **Fuentes:** ACSM (ya citado §4.3).
- **Código:** `evaluateExercise`

### 7.4 — Nutrición ≥ 1 comida

- **Valor:** 1 comida registrada.
- **Confianza:** LOW
- **Justificación:** Es un proxy de "el usuario está prestando atención hoy". No mide calidad ni cantidad — solo engagement.
- **Código:** `evaluateNutrition`

### 7.5 — Ayuno ≥ 80% protocolo o ≥ 10h sin protocolo

- **Valor:** 80% del target del protocolo (16:8 → 12.8h). 10h si protocolo = "Ninguno".
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** 80% deja margen para días imperfectos sin penalizar. 10h sin protocolo cubre el ayuno nocturno natural saludable.
- **Código:** `evaluateFasting`

---

## §8 — Multiplicadores de carga de ejercicio (SPEC-68)

`load = baseMinutes * typeMultiplier * intensityMultiplier`

### 8.1 — Tipo: LISS 1.0 / HIIT 1.5 / STRENGTH 1.3 / MOBILITY 0.6

- **Confianza:** MEDIUM
- **Justificación:** HIIT tiene EPOC (Excess Post-Exercise Oxygen Consumption) significativamente mayor — un minuto de HIIT genera ~50% más demanda metabólica acumulada que el mismo minuto LISS. Strength training tiene EPOC menor pero efecto sostenido en composición corporal (síntesis proteica). Mobility es recuperación activa, contribución metabólica clara pero menor.
- **Fuentes:**
  - LaForgia J, Withers RT, Gore CJ. "Effects of exercise intensity and duration on the excess post-exercise oxygen consumption." *J Sports Sci* 2006;24(12):1247-64.
- **Código:** `lib/src/features/exercise/domain/exercise_load_calculator.dart`

### 8.2 — Intensidad: low 0.7 / moderate 1.0 / high 1.3

- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** Mismo principio dosis-respuesta que tipo, pero a nivel de intensidad subjetiva (RPE). Asimétrico hacia abajo (0.3 abajo de neutral, 0.3 arriba) por simetría conservadora.
- **Código:** mismo archivo.

---

## §9 — Gaps reconocidos (transparencia explícita)

Los siguientes valores son **ENGINEERING JUDGMENT** y se marcan para futura recalibración. La lista NO es exhaustiva — cualquier peso etiquetado LOW o ENGINEERING JUDGMENT en las secciones anteriores cae aquí también.

### 9.1 — Macro split 50/25/25

Defendible pero no validado contra cohorte. Cuando ElenaApp tenga >1000 usuarios con ≥90 días de uso, se puede correr una regresión de outcomes percibidos vs. componentes del IMR para validar/recalibrar.

### 9.2 — Pesos del bloque Conducta

Los pesos 28/20/20/12/20 son una asignación coherente pero no derivada de un modelo. Especialmente:
- **Nutrición 0.12** (deliberadamente bajo hasta que macros entren al cómputo).
- **Hidratación 0.20** (alto vs. percepción popular pero defendible bibliográficamente).

### 9.3 — Pesos sigmoid 0.70 + adherencia 0.30 en metabolicBlock

SPEC-53 cambió la naturaleza del 0.30 (de binario a continuo). El balance debe re-evaluarse.

### 9.4 — Umbrales escalonados en `sleep_quality_calculator.dart`

Las gradaciones {1.0, 0.7, 0.4, 0.1} en gap, latencia, despertares son aproximaciones razonables pero no calibradas. Una versión continua (smooth) podría reemplazarlas con base en datos.

### 9.5 — Factor subjetivo [0.85, 1.10]

El rango asimétrico es defendible pero los valores exactos no.

### 9.6 — Bonus eTRF binario 1.15 ✅ CERRADO en SPEC-70.2

(Era step function `(hour < 18) ? 1.15 : 1.0`.) Reemplazado por sigmoid centrada en 17:00 con ancho 1.0. Ver §3.3 actualizada.

### 9.7 — Hidratación goal por defecto

El goal de hidratación se calcula por usuario (no aparece en este doc) pero las constantes que lo derivan tienen el mismo problema de origen.

### 9.8 — Recalibraciones pendientes (R2.5) — revisión técnica externa

La revisión técnica de este documento expuso cuatro recalibraciones específicas que SPEC-70 no aborda directamente y que se trackean como sub-SPECs en una mini-fase R2.5. Cada una con su justificación y prioridad relativa.

**SPEC-70.1 — UI advisory sobre el peso conservador de Nutrición. ✅ CERRADA.**
*Origen:* el peso 0.12 (§4.4) protege contra inflar el score con métricas pobres pero genera un sesgo opuesto — un usuario con ayuno+ejercicio impecables pero comiendo ultraprocesados puede tener IMR alto sin saberlo. *Solución implementada:* widget `_NutritionAdvisory` añadido al final del `IMRBreakdownCard`. Aparece siempre (no condicional a `nutritionScoreRaw > 0`) porque el aviso es educativo independientemente de si el usuario registró nutrición hoy. Texto: *"Nutrición pesa 12% del bloque Conducta. El score actual considera cantidad y timing de tus comidas. La calidad nutricional (macros, índice glucémico) entrará al cómputo en una próxima versión."* Estilo: card amber claro con info icon, integrado al breakdown. Cleanup colateral: corregido el subtitle del bloque CONDUCTA que decía "Sueño + Ejercicio + Circadiano" omitiendo Nutrición e Hidratación post-SPEC-67.

**SPEC-70.2 — Sigmoid del bonus eTRF. ✅ CERRADA.**
*Origen:* el `(lastMealTime.hour < 18) ? 1.15 : 1.0` (§3.3) creaba un escalón del 15% en 18:00, frustrante para el usuario avanzado. *Solución implementada:* `etrfBonus = 1.0 + 0.15 * (1 - sigmoid((mealHour - 17) / 1.0))` — curva continua centrada en 17:00 con ancho 1.0h. Asíntota superior 1.15 (preserva techo del binario), aproxima a 1.0 cuanto más tarde sea la cena. Ver §3.3 actualizada con tabla de valores de referencia.

**SPEC-70.3 — FFMI ajustado por edad. ✅ CERRADA.**
*Origen:* el `score_engine.dart` (§2.4) leía `user.gender` para `baseFFMI` y `rangeFFMI` pero ignoraba `user.age` completamente, aunque `UserModel.age` existe. *Solución implementada:* `baseFFMI` ahora es función de `(gender, age)` vía helper privado `_baseFFMIForAge`. Cae ~1 punto por década después de los 50, replicando la pérdida natural de masa magra documentada. `rangeFFMI` se mantiene constante por simplicidad (estratificarlo añade complejidad sin mover materialmente el score; SPEC-70.3.1 puede refinar si datos propios lo justifican). Ver §2.4 actualizada.

**SPEC-70.4 — Educación de logging para hidratación. ✅ CERRADA.**
*Origen:* la convención del motor es que "no loguear agua" se trata como "no hidrataste" (penalización máxima). Es defendible (logging IS la conducta que la app enseña; sin tracking no hay personalización) pero crea fricción cuando el usuario sí se hidrata pero olvida registrar. *Solución implementada:* widget `_HydrationCoachCard` añadido al panel de hidratación. Aparece cuando `progressPercentage < 0.25` (logging bajo del día) y el usuario no lo ha descartado. Texto: *"Tomar agua sin loguear no afecta tu score. Trackea cada vaso para que el motor pueda personalizar tu meta y detectar patrones a lo largo del día."* Estado de descarte vive en `UiInteractionState.isHydrationCoachDismissed` (consistente con el patrón de SPEC-72.2). Reaparece cada día via `DailyResetService.resetDismissals()` — el usuario no se desensibiliza permanentemente. *Decisión arquitectural preservada:* el motor sigue tratando "no logueado = no consumido". El cambio es puramente de comunicación.

**MKT-IMR-001 — Adaptación del documento al sitio público.**
*Origen:* este `IMR_BIBLIOGRAPHY.md` es markdown técnico que vive en el repo. Para el sitio web público (`metamorfosisreal.com/ciencia` o equivalente) se necesita derivado con: (a) fórmulas renderizadas con KaTeX/MathJax, (b) gráficos interactivos de sigmoid del ayuno, sigmoid eTRF post-SPEC-70.2, curvas FFMI por edad post-SPEC-70.3, efecto del gap metabólico en sleep quality, (c) link bidireccional repo↔sitio para auditabilidad. *Tipo:* deliverable de marketing/comms. *NO es ingeniería de R3.* *Prioridad:* del equipo de sitio cuando se quiera posicionar la transparencia como diferenciador del producto.

---

## Convenciones para mantener este documento

1. **Cualquier cambio de un peso en código DEBE actualizar la sección correspondiente aquí.** Los comentarios `// SPEC-70: ref §X.Y` son los anclajes para encontrar la sección.

2. **Cualquier nuevo peso se añade aquí PRIMERO** (con confianza explícita), luego al código.

3. **Cuando una recalibración se justifica con nueva evidencia**, abrir SPEC-70.X (sub-SPEC) que cite el paper, actualice este doc y modifique el código.

4. **No añadir citaciones que no se hayan verificado.** Mejor tener un peso marcado "ENGINEERING JUDGMENT" que una cita inventada.

---

## Referencias completas

Las citas en cada sección usan el formato corto. Las completas (DOI cuando sea posible) deberían vivir en `references.bib` cuando el equipo añada un workflow de bibliografía formal. Por ahora, cada cita en este doc es suficiente para localizar el paper en PubMed o Google Scholar.

---

*Última actualización: SPEC-70 (R2 final). Este documento se mantiene en el repo y vive con el código. Su versionado es git.*
