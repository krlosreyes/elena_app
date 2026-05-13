# IMR — Bibliografía y trazabilidad de pesos

**SPEC-70 (R2 final) + SPEC-70.5 (recalibración clínica).** Este documento captura el origen de **cada constante y peso** que entra al cómputo del Índice de Resiliencia Metabólica (IMR). Es la materialización de la promesa "fundamentos científicos verificables" del producto.

> ✅ **Validación clínica externa — SPEC-70.5.** Documento revisado por **[Dr/Dra Nombre completo, Especialidad, Institución]** (endocrinología). Las recalibraciones de SPEC-70.5 (bloqueo intestinal 22:30→21:30, peso de Hidratación 20%→10%, peso de Circadiano 28%→38%, threshold de sueño 6.5h→7h) provienen directamente de su revisión. Próxima revisión clínica: **[fecha]**.

Cada entrada lleva un **nivel de confianza** explícito:

- **HIGH** — múltiples ensayos clínicos / meta-análisis convergen en el valor.
- **MEDIUM** — una guía clínica reconocida, un estudio seminal, o **validación clínica externa de SPEC-70.5**.
- **LOW** — derivado por inferencia desde un dominio adyacente o de un único estudio.
- **ENGINEERING JUDGMENT** — heurística del equipo. Sin literatura directa. Marcada para recalibración futura cuando tengamos datos propios o evidencia nueva.

**Cómo leer este doc:** cada peso enlaza a la línea de código donde vive (formato `archivo:línea`). Cualquier cambio al código debe actualizar este documento o se considera deuda. Los comentarios `// SPEC-70: ref §X.Y` en el código apuntan a la sección correspondiente aquí.

**Lo que este documento NO es:** una revisión sistemática de literatura. Es un mapa honesto entre cada decisión numérica y la evidencia que la respalda — y, desde SPEC-70.5, una conversación con un especialista que validó las decisiones agregadas.

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

**Fórmula actual (SPEC-70.5, validada clínicamente):**

`behaviorBlock = 0.38*circadiano + 0.20*sueño + 0.20*ejercicio + 0.12*nutrición + 0.10*hidratación`

*Cambio respecto a SPEC-70: `circadiano` subió de 0.28 a 0.38 absorbiendo los 10 puntos porcentuales que `hidratación` cedió (de 0.20 a 0.10) tras revisión clínica externa.*

### 4.1 — Circadiano: 0.38 (SPEC-70.5)

- **Valor:** 0.38 (antes 0.28 hasta SPEC-70).
- **Confianza:** MEDIUM
- **Justificación:** El alineamiento circadiano es el factor con mayor impacto sobre los demás pilares. La revisión clínica externa lo identificó como **"el eje maestro que regula el hambre y la reparación metabólica"**. SPEC-70.5 transfirió 10 puntos porcentuales desde Hidratación (que se sobreestimaba) a Circadiano (que se subestimaba en relación a su impacto endocrino sistémico).
- **Fuentes:**
  - Panda S. "The Circadian Code." Rodale, 2018.
  - Wehrens SMT et al. "Meal Timing Regulates the Human Circadian System." *Curr Biol* 2017;27(12):1768-1775.e3.
  - **Lopez-Minguez J et al. "Late dinner impairs glucose tolerance in MTNR1B risk allele carriers: A randomized, cross-over study." *Clin Nutr* 2018;37(4):1133-1140.** (Añadido en SPEC-70.5 — soporte específico al bloqueo intestinal 21:30; ver §4.6.)
- **Validación clínica:** SPEC-70.5 ✅
- **Código:** `lib/src/core/engine/score_engine.dart` — `behaviorBlock = (0.38 * circadianScore.clamp(0.0, 1.0)) + ...`

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

### 4.5 — Hidratación: 0.10 (SPEC-70.5)

- **Valor:** 0.10 (antes 0.20 hasta SPEC-70).
- **Confianza:** MEDIUM
- **Justificación:** La deshidratación crónica leve afecta termoregulación, transporte de nutrientes y rendimiento cognitivo, pero la revisión clínica externa observó que **el peso 20% inflaba artificialmente el score de usuarios que solo bebían agua sin moverse**. El especialista lo describió como "excesivo frente al impacto clínico real comparado con ejercicio o sueño".
- **Decisión SPEC-70.5:** reducción a 10%. Los 10 puntos porcentuales liberados se transfieren a Circadiano (§4.1), no a Sueño/Ejercicio que ya están adecuadamente representados a 20% cada uno. Mantener Hidratación con peso > 0 preserva la señal — un usuario que NO se hidrata no es invisible al motor — pero deja de dominar comparativamente.
- **Fuentes:**
  - EFSA Panel on Dietetic Products, Nutrition, and Allergies. "Scientific Opinion on Dietary Reference Values for water." *EFSA Journal* 2010;8(3):1459.
  - Popkin BM, D'Anci KE, Rosenberg IH. "Water, hydration, and health." *Nutr Rev* 2010;68(8):439-58.
- **Validación clínica:** SPEC-70.5 ✅ (dictamen explícito: "20% es excesivo").
- **Código:** `behaviorBlock = ... + (0.10 * sHydration);`

### 4.6 — Bloqueo intestinal: 21:30 (SPEC-70.5)

- **Valor:** Penalización a `circadianScore = 0.5` cuando `lastMealTime` ≥ 21:30. (Antes 22:30 hasta SPEC-70.)
- **Confianza:** MEDIUM (validado por revisión clínica externa).
- **Justificación:** La revisión clínica externa catalogó 22:30 como **"permisivo"** — a esa hora la reparación celular nocturna ya debería estar en marcha, no la digestión activa. El nuevo umbral 21:30 captura el inicio de la cronodisrupción nocturna sin penalizar al usuario que termina de cenar puntual a las 21:00. La sensibilidad a la insulina decae significativamente al anochecer por la interacción melatonina-MTNR1B.
- **Fuentes:**
  - **Lopez-Minguez J, Saxena R, Bandín C, Scheer FA, Garaulet M. "Late dinner impairs glucose tolerance in MTNR1B risk allele carriers: A randomized, cross-over study." *Clin Nutr* 2018;37(4):1133-1140.** (Estudio principal: cenar tarde después de las 21:00 se asocia con aumento medible del riesgo de diabetes tipo 2 y deterioro de tolerancia a glucosa, especialmente en portadores del alelo de riesgo MTNR1B.)
  - Hood S, Amir S. "The aging clock: circadian rhythms and later life." *J Clin Invest* 2017;127(2):437-446.
- **Validación clínica:** SPEC-70.5 ✅ (dictamen explícito: "22:30 es permisivo, movería a 21:30 para reflejar la fisiología real").
- **Código:** `lib/src/core/engine/circadian_engine.dart` — `intestinalLockHour = 21; intestinalLockMinute = 30; intestinalLockMinutes = 1290` y `lib/src/core/engine/score_engine.dart` — `if (mealMinutes >= CircadianRules.intestinalLockMinutes) { circadianScore = 0.5; }`

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

### 7.1 — Sueño ≥ 7.0h (SPEC-70.5)

- **Valor:** 7.0h (antes 6.5h hasta SPEC-70).
- **Confianza:** MEDIUM (validado por revisión clínica externa).
- **Justificación:** AASM Practice Guidelines establecen 7-9h como rango óptimo. La revisión clínica externa fue contundente: **"6.5h es un umbral de supervivencia, no de metamorfosis"**. Por debajo de 7h el eje grelina/leptina se altera de forma medible, y la asociación epidemiológica con obesidad, diabetes tipo 2 e hipertensión es consistente. Para una app que promete "metamorfosis real" el estándar debe ser el rango óptimo, no el umbral de daño detectable.
- **Cambio aplicado en SPEC-70.5:** `evaluateSleep` (StreakEngine) y la penalización de coherencia en `CoherenceEngine.calculate` se sincronizan al mismo umbral 7.0h.
- **Fuentes:** AASM (ya citado §4.2).
- **Validación clínica:** SPEC-70.5 ✅
- **Código:** `lib/src/features/streak/domain/streak_engine.dart` — `evaluateSleep` y `lib/src/core/engine/coherence_engine.dart` — penalización -0.20 cuando `sleepHours < 7.0`.

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

### 9.1 — Macro split 50/25/25 ✅ VALIDADO en SPEC-70.5

Validado clínicamente como "defendible con prioridad en salud cardiovascular". Pendiente: cuando ElenaApp tenga >1000 usuarios con ≥90 días de uso, correr regresión de outcomes percibidos vs componentes del IMR para validar empíricamente. Sigue siendo el siguiente paso natural cuando haya datos.

### 9.2 — Pesos del bloque Conducta ✅ RECALIBRADOS en SPEC-70.5

Pesos previos 28/20/20/12/20 → ahora **38/20/20/12/10** tras revisión clínica externa. La hidratación al 20% se identificó como excesiva; el 10% liberado se transfirió a Circadiano (el "eje maestro"). Ver §4.1 y §4.5 actualizadas.

**Nutrición 0.12 sigue como ENGINEERING JUDGMENT** — deliberadamente bajo hasta que la calidad nutricional (macros, IG) entre al cómputo. SPEC futura cuando macros estén integrados al ScoreEngine.

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

## §10 — Roadmap clínico post-SPEC-70.5

Recomendaciones del especialista para iteraciones futuras del IMR. Ninguna es bloqueante para el lanzamiento; todas son señales de hacia dónde puede crecer el modelo cuando haya capacidad de medirlas.

### 10.1 — Variabilidad de la frecuencia cardíaca (HRV)

**Aporte clínico:** la HRV es el proxy no invasivo más potente del balance del sistema autónomo (simpático/parasimpático). Un usuario con IMR alto pero HRV baja está "forzando" su sistema, no sanándolo — el score sin HRV puede malinterpretarse como recuperación cuando en realidad hay carga alostática elevada.

**Implementación condicional a:** integración con wearables (Apple Watch, Fitbit, Oura, Whoop). Sin sensor, no hay HRV.

**Cuándo abrirlo como SPEC:** cuando ElenaApp construya un puente con HealthKit / Google Fit / API de Whoop. SPEC dedicada porque introduce un canal de datos completamente nuevo.

### 10.2 — Ratio cintura-cadera (WHR) complementando WHtR

**Aporte clínico:** WHR sigue siendo estándar de oro junto al WHtR. Captura la distribución androide vs ginoide de la grasa, especialmente relevante en mujeres post-menopáusicas. Actualmente solo medimos WHtR.

**Costo de implementación:** añadir un campo `hipCircumference` al `UserModel` y ajustar el bloque Estructura para promediarlo con WHtR. Aproximadamente una SPEC del tamaño de SPEC-70.3.

**Cuándo abrirlo:** cuando se quiera mejorar precisión específicamente en cohortes femeninas o mayores de 50.

### 10.3 — Macros nutricionales al cómputo del IMR

**Estado actual:** los macros (calorías, proteína, carbs, grasa, fibra, IG) se persisten desde SPEC-71.3 pero **NO afectan el score**. Por eso Nutrición pesa solo 12% en el bloque Conducta.

**Cuándo abrirlo:** cuando haya suficiente data acumulada (estimación: 3-6 meses tras lanzamiento) para validar correlaciones macros→outcomes en la propia cohorte de ElenaApp. SPEC dedicada que (a) define una métrica de "calidad nutricional" desde los macros, (b) la integra al ScoreEngine, (c) sube el peso de Nutrición a 18-22%, (d) reduce proporcionalmente Circadiano si así lo recomienda la siguiente revisión clínica.

---

## §11 — Poblaciones de riesgo (contraindicaciones)

> ⚠️ El IMR está calibrado para adultos sanos. La revisión clínica externa identificó cuatro poblaciones donde el score **no aplica directamente** o requiere **supervisión médica**. ElenaApp muestra un disclaimer obligatorio durante el onboarding (SPEC-70.8) cubriendo estos casos.

### 11.1 — Diabetes Tipo 1 / pacientes insulinodependientes

El ayuno prolongado y el ejercicio sin ajuste de insulina pueden inducir hipoglucemia severa. El bloque metabólico del IMR (sigmoid de ayuno centrada en 14h) **no es seguro** sin supervisión médica para esta población.

### 11.2 — Historial de Trastornos de la Conducta Alimentaria (TCA)

La gamificación de las horas de ayuno y el seguimiento obsesivo de macros son **triggers documentados de recaída**. Para esta población, las visualizaciones de "racha" y los advisories de "más detalle (mejora tu IMR)" pueden ser dañinas.

### 11.3 — Insuficiencia renal

El peso de la hidratación y las metas implícitas de masa magra (vía FFMI) requieren manejo médico personalizado. La meta diaria de hidratación que la app sugiere puede ser inapropiada para pacientes con restricción hídrica clínica.

### 11.4 — Embarazo y lactancia

Las necesidades metabólicas de estos estados son **de crecimiento, no de resiliencia**. El IMR como métrica de "metamorfosis hacia un fenotipo más sano" no aplica conceptualmente — la fisiología está en otro régimen.

### 11.5 — Sarcopenia severa o fragilidad en mayores de 75

La restricción de ventanas de comida (eTRF) puede comprometer la ingesta proteica necesaria para preservar masa magra. SPEC-70.3 ya ajusta el FFMI baseline por edad, pero la combinación de ayuno + bajo peso magro requiere supervisión.

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

*Última actualización: SPEC-70.5 (recalibración clínica externa). Este documento se mantiene en el repo y vive con el código. Su versionado es git.*

---

## §12 — Métricas canónicas para integración con Metamorfosis Real (SPEC-82)

A partir de SPEC-82, el doc `users/{uid}` persiste un bloque `imr.current` con métricas clínicas estándar que el sitio web Metamorfosis Real consume. Estas métricas se calculan dentro del mismo `ScoreEngine` (sin nuevos inputs) y se exponen como campos derivados de `IMRv2Result`.

### 12.1 — IMC (Índice de Masa Corporal)

- **Fórmula:** `IMC = peso(kg) / altura(m)^2`
- **Confianza:** HIGH
- **Uso:** medida descriptiva clásica de relación peso/talla. Compatible con los rangos OMS (bajo peso <18.5, normal 18.5–24.9, sobrepeso 25–29.9, obesidad ≥30). Se expone en `imr.current.imc` para que el sitio pueda renderizarlo junto al score.
- **Limitación:** el IMC no diferencia masa magra de grasa. Por eso el IMR usa FFMI + WHtR para Estructura — el IMC se persiste como contexto descriptivo, no como input del score.
- **Código:** `lib/src/core/engine/score_engine.dart` — `imc = user.weight / pow(hMeter, 2)` en `calculateIMR` y `calculateBaseline`.

### 12.2 — TMB (Tasa Metabólica Basal) — Mifflin-St Jeor

- **Fórmula:**
  - Hombres: `TMB = 10·peso + 6.25·altura − 5·edad + 5`
  - Mujeres: `TMB = 10·peso + 6.25·altura − 5·edad − 161`
- **Unidades:** kcal/día. `peso` en kg, `altura` en cm, `edad` en años.
- **Confianza:** HIGH
- **Fuente:** Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. "A new predictive equation for resting energy expenditure in healthy individuals." *Am J Clin Nutr* 1990;51(2):241-7.
- **Justificación:** Estándar clínico vigente desde la Academia Americana de Nutrición y Dietética. Más precisa que Harris-Benedict (la ecuación clásica de 1919) en cohortes contemporáneas.
- **Código:** `score_engine.dart` — `tmb = (10*weight) + (6.25*height) - (5*age) + (isMale ? 5 : -161)`.

### 12.3 — ICA / WHtR (Índice Cintura-Altura / Waist-to-Height Ratio)

- **Fórmula:** `ICA = cintura(cm) / altura(cm)`
- **Confianza:** HIGH (mismo cálculo que el `s1` del bloque Estructura, ver §2.3).
- **Notas:** `ICA` y `WHtR` son sinónimos — el sitio Astro espera ambos nombres en `imr.current`. Se persisten como dos campos con el mismo valor para que el frontend no haga renombrado.
- **Código:** `score_engine.dart` — `ica = waistCircumference / height; whtr = ica`.

### 12.4 — FFMI (Fat-Free Mass Index)

- **Fórmula:** `FFMI = masa magra(kg) / altura(m)^2` donde `masa magra = peso × (1 − bodyFat/100)`.
- **Confianza:** HIGH (mismo cálculo que el `s2` del bloque Estructura — ver §2.4).
- **Diferencia con `s2`:** `s2` es el FFMI normalizado al baseline age-stratified (0–1). `imr.current.ffmi` es el FFMI crudo (típicamente 14–25), que el sitio web renderiza como número absoluto.
- **Código:** `score_engine.dart` — `ffmi = leanMass / pow(hMeter, 2)`.

### 12.5 — Metabolic Age (provisional)

- **Fórmula provisional:** `metabolicAge = clamp(age + round(20 × (1 − structureBlock)), age − 10, age + 25)`
- **Confianza:** ENGINEERING JUDGMENT
- **Justificación:** No existe un estándar clínico universal para "edad metabólica". Las balanzas comerciales (Tanita, InBody) usan fórmulas propietarias que combinan FFMI, %grasa, agua corporal y BMR vs. norma poblacional. Nuestra fórmula simplificada deriva la edad metabólica como una función del bloque Estructura: un usuario con Estructura óptima (1.0) tiene edad metabólica = cronológica; uno con Estructura colapsada (0.0) tiene +20 años, con clamp a ±un rango razonable.
- **Limitación reconocida:** es una métrica de signaling, no diagnóstica. Refinable a futuro con data propia (SPEC futura, sin compromiso de fecha).
- **Código:** `score_engine.dart` — `_metabolicAgeFromStructure(age, structureBlock)`.

### 12.6 — IMR Baseline (sin data behavioral)

- **Cuándo aplica:** al finalizar el onboarding. El usuario aún no tiene logs de comida, sueño, ejercicio o hidratación. El `calculateIMR` requiere `state.lastMealTime` no-null para evaluar el bloque Metabolismo y Conducta, así que retorna `IMRv2Result.empty()`. Para no dejar al sitio web Metamorfosis Real con "Sin diagnóstico", `calculateBaseline(user)` produce un score usando SOLO el bloque Estructura.
- **Fórmula baseline:** `raw = 0.50 × structureBlock`. `metabolicScore = 0`, `behaviorScore = 0`, `circadianAlignment = 0`.
- **Cota:** `totalScore ≤ 50` por construcción (estructura óptima × peso 0.50).
- **Confianza:** ENGINEERING JUDGMENT en el corte (50 puntos como máximo de baseline). Es una decisión pragmática: dar al usuario un score visible no cero pero claramente parcial.
- **Código:** `score_engine.dart` — `ScoreEngine.calculateBaseline(UserModel)`. Llamado desde `OnboardingController.completeOnboarding`.

---

## Changelog

- **SPEC-82** (canonical mirror): añade §12 con las fórmulas de las métricas canónicas (IMC, TMB Mifflin-St Jeor, ICA/WHtR, FFMI crudo, metabolicAge provisional) que el sitio web Metamorfosis Real consume vía `imr.current` en el doc `users/{uid}`. El bloque Estructura, Metabolismo y Conducta del IMR no cambian.
- **SPEC-70.5** (recalibración clínica externa): bloqueo intestinal 22:30→21:30, peso Hidratación 20%→10%, peso Circadiano 28%→38%, threshold de sueño en racha 6.5h→7.0h, threshold de penalización de coherencia por sueño 6.5h→7.0h. Validado por **[Dr/Dra Nombre, Especialidad]**. Nuevas §10 (roadmap clínico) y §11 (contraindicaciones).
- **SPEC-70.3**: FFMI baseline age-stratified.
- **SPEC-70.2**: bonus eTRF como sigmoid suave en lugar de salto binario.
- **SPEC-70.1**: UI advisory sobre el peso conservador de Nutrición.
- **SPEC-70** (R2 final): documento inicial de bibliografía.
