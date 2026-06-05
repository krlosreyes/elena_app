# Bibliografía de Nutrición — Bases del pilar Nutrición de ElenaApp

**Última actualización:** 22 de mayo de 2026
**Marco normativo:** `CONSTITUTION.md` — todo fundamento de producto debe ser verificable.
**Documentos hermanos:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` (cronograma circadiano), `IMR_BIBLIOGRAPHY.md` (pesos del score), `specs/SPEC-137-pillar-nutrition-frank-suarez.md` (implementación).

Este documento canoniza el marco operacional del pilar Nutrición de ElenaApp. Toda SPEC, copy o lógica de score que toque nutrición debe consultarlo y citar la sección correspondiente.

Documentos fuente (versionados en `docs/references/`):

1. **`Minimalist_Fat_Loss_Protocol.pdf`** — protocolo simplificado al estilo Frank Suárez (sin contar calorías).
2. **`The_Metabolic_Miracle.pdf`** — síntesis del paradigma hormonal vs calórico.
3. **`Metabolic_Blueprint.pdf`** — variante operacional del mismo método.

Referencias externas:

- Frank Suárez. *El Poder del Metabolismo* (Metabolic Press, 2007). Capítulos sobre Tipo A / Tipo E y sistema nervioso pasivo / excitado.
- Frank Suárez. *Diabetes Sin Problemas* (Metabolic Press, 2011). Dieta 3x1 para diabetes.
- Frank Suárez. *Metabolismo Ultra Poderoso* (Metabolic Press, 2014).
- Frank Suárez. *Recetas El Poder del Metabolismo* (Metabolic Press, 2017).
- Jenkins DJ et al. "Glycemic index of foods: a physiological basis for carbohydrate exchange." *Am J Clin Nutr* 1981; 34(3):362-6.
- Wolever TM, Jenkins DJ, Jenkins AL, Josse RG. "The glycemic index: methodology and clinical implications." *Am J Clin Nutr* 1991; 54(5):846-54.
- Brand-Miller JC, Foster-Powell K, Holt S. *The Low GI Handbook*. Da Capo Press, 2010.
- Liu S, Manson JE et al. "A prospective study of dietary glycemic load, carbohydrate intake, and risk of coronary heart disease in US women." *Am J Clin Nutr* 2000; 71(6):1455-61.
- Hall KD et al. "Calorie for calorie, dietary fat restriction results in more body fat loss than carbohydrate restriction in people with obesity." *Cell Metab* 2015; 22(3):427-36 (contra-evidencia citada para honestidad metodológica).

---

## §1 — Principios fundacionales

### §1.1 — Modelo hormonal, no calórico

Coherente con `CIRCADIAN_BIBLIOGRAPHY.md §1.1`. La métrica primaria del pilar no son calorías ni gramos, es la **respuesta insulínica del plato**. Un plato de 600 kcal de salmón con verduras y aguacate moviliza muy distinta cantidad de insulina que un plato de 600 kcal de pasta blanca con tomate. La app no puede medir insulina directamente, pero sí la proxy operacional más simple del marco hormonal: la **proporción Tipo A : Tipo E** que predomina en el plato.

> "Lo que engorda es la insulina, no las calorías." — Frank Suárez, *El Poder del Metabolismo* §3.

### §1.2 — Simplicidad como condición de adherencia

La complejidad mata la constancia. La app no pide al usuario:

- contar calorías
- contar gramos
- pesar comida
- escanear códigos de barras
- usar reconocimiento de imágenes
- elegir de una base de datos de 200 000 alimentos
- registrar marca comercial

La app pide al usuario una sola cosa por plato: **¿más Tipo A o más Tipo E?** Esto se decide en menos de 5 segundos.

> "Elige 10 recetas que te gusten. Repítelas. La voluntad es un recurso limitado." — *Minimalist Fat Loss Protocol* §4.

### §1.3 — Nada está prohibido

La filosofía de Frank Suárez —reforzada por el *Minimalist Fat Loss Protocol* y todos los blueprints adjuntos— es que **ningún alimento está prohibido**. La salud metabólica se construye en la proporción, no en la exclusión. La app nunca debe usar el lenguaje "prohibido", "malo", "trampa" sobre un alimento. Usa "Tipo E", "menos frecuente", "menor proporción".

> "Nada está prohibido. Usted puede comer de todo y adelgazar. Es cuestión de proporciones." — Pregúntale a Frank, *Alimentos que te Engordan y Adelgazan* (2017).

### §1.4 — La marca habla el idioma del usuario MR

El suscriptor de Metamorfosis Real conoce la nomenclatura Tipo A / Tipo E porque el método off-app la usa. La app debe usar el mismo lenguaje. Cambiarlo por "alta glicemia / baja glicemia" o "lento / rápido" rompe la continuidad entre la consulta y la app.

La defensa científica frente a reviewers de App Store y prensa NO es Frank Suárez (no es médico titulado), es la **literatura de índice glucémico y carga glucémica** (§4 abajo). Frank Suárez vive en el copy del producto; la literatura peer-reviewed vive en `IMR_BIBLIOGRAPHY.md`.

---

## §2 — Clasificación canónica Tipo A / Tipo E

Las listas siguientes son la fuente de verdad para clasificar inputs del usuario y para alimentar el mini-buscador inline de `PlateRatioSheet`. Cualquier cambio requiere SPEC.

### §2.1 — Alimentos Tipo A (Adelgazan, baja insulina)

| Categoría | Ejemplos canónicos |
|---|---|
| Carnes rojas | Res, cerdo, cordero |
| Aves | Pollo, pavo, codorniz |
| Pescados | Salmón, atún, merluza, sardina, anchoa |
| Mariscos | Camarón, calamar, mejillón, ostra, pulpo |
| Huevos | Huevo de gallina, codorniz, pato |
| Quesos | Quesos en general (la grasa NO los convierte en E) |
| Verduras | Espinaca, brócoli, rúcula, lechuga, kale, acelga, repollo, coliflor, calabacín, pepino, apio, espárrago, alcachofa, berenjena |
| Verduras con almidón moderado | Zanahoria, betarraga (con moderación), tomate, pimentón |
| Frutos secos | Almendra, nuez, pistacho, avellana, macadamia |
| Semillas | Chía, lino, sésamo, calabaza, girasol |
| Frutas bajas | Fresa, frambuesa, mora, arándano, manzana verde, palta / aguacate, tomate |
| Grasas saludables | Aceite de oliva extra virgen, aceite de coco, mantequilla orgánica, ghee |
| Yogur natural | Yogur plain sin endulzar |
| Bebidas | Agua, agua con gas, té, café (sin azúcar), infusiones, jugos de vegetales |

### §2.2 — Alimentos Tipo E (Engordan, alta insulina)

| Categoría | Ejemplos canónicos |
|---|---|
| Harinas refinadas | Pan blanco, pan integral, tortilla de harina, galletas, pizza, pastas |
| Granos | Arroz blanco, arroz integral, maíz, quinoa, cebada, avena (con moderación), trigo |
| Tubérculos | Papa, batata, yuca, yautía, ñame, malanga, ocumo |
| Frutas tropicales dulces | Mango, banana / plátano amarillo, piña, papaya, sandía, melón, uva, dátil, higo |
| Frutas secas concentradas | Pasas, ciruela seca, dátil seco |
| Lácteos | Leche entera, descremada, deslactosada, yogur endulzado, queso crema endulzado, helado |
| Azúcares y similares | Azúcar blanca, azúcar morena, miel, sirope, panela, dulce de leche, mermelada |
| Procesados dulces | Chocolate con leche, galletas, pasteles, donas, cereales de caja, granola comercial |
| Bebidas dulces | Refrescos, jugos de fruta, bebidas deportivas azucaradas, frapés, malteadas |
| Alcohol | Cerveza, vino dulce, licores y cocteles (el alcohol detiene la quema de grasa — *Minimalist Fat Loss Protocol §2*) |

### §2.3 — Notas operativas para la app

- **El criterio del usuario es válido.** Si duda, el mini-buscador inline le orienta. Si insiste en clasificar pasta integral como A (porque la siente "menos dulce"), la app no lo corrige a la fuerza; sí muestra una nota informativa.
- **Combinaciones**: un sandwich de pan integral con pollo y palta NO es A automáticamente porque la base es pan. El usuario debe poder evaluar el plato en su conjunto. La sheet ofrece pista visual: "el componente más grande del plato determina la proporción".
- **Bebidas alcohólicas**: el alcohol se clasifica E aunque tenga pocas calorías. Aporta 7 kcal/g sin nutrientes y detiene la quema de grasa.
- **Endulzantes 0 cal**: estevia, eritritol, monk fruit se consideran neutros (no A ni E) en el MVP. Los aspartame/sucralosa están en discusión clínica abierta; la app no los clasifica E pero sí incluye nota informativa.
- **Día de permitidos** (§6): el cheat day no anula la clasificación. Un plato en cheat day sigue siendo `allE` o `a1e1`. Lo que cambia es que el día completo se excluye del cálculo semanal de adherencia.

---

## §3 — Dietas operacionales 2x1 y 3x1

### §3.1 — 2x1 (mantenimiento o pérdida moderada)

Plato dividido en 3 partes: **2/3 alimentos Tipo A + 1/3 alimentos Tipo E**.

Ejemplos canónicos del plato 2x1:
- 2 partes pollo + verduras verdes / 1 parte arroz integral.
- 2 partes pescado + ensalada / 1 parte papa al horno.
- 2 partes huevo + palta + tomate / 1 parte pan integral tostado.

En la app: `MealRatio.a2e1`. Es el default sugerido para usuarios con sistema nervioso pasivo.

### §3.2 — 3x1 (pérdida acelerada o perfil diabético)

Plato dividido en 4 partes: **3/4 alimentos Tipo A + 1/4 alimento Tipo E**.

Ejemplos canónicos del plato 3x1:
- 3 partes salmón + brócoli + ensalada / 1 parte arroz integral.
- 3 partes pollo + verduras verdes + nueces / 1 parte fruta.

En la app: `MealRatio.a3e1`. Es el default sugerido para usuarios con sistema nervioso excitado, diabéticos tipo 2 declarados, o pérdida acelerada.

### §3.3 — Variantes en el enum `MealRatio`

| Enum | Proporción A | Lectura cualitativa | Color sugerido UI |
|---|---|---|---|
| `allA` | 100 % | Plato perfecto — todo Tipo A | Verde saturado |
| `a3e1` | 75 % | 3x1 — recomendado para pérdida | Verde |
| `a2e1` | 67 % | 2x1 — mantenimiento estándar | Verde claro |
| `a1e1` | 50 % | Mitad y mitad — alerta amarilla | Amarillo |
| `allE` | 0 % | Día de permitidos o decisión consciente | Naranja |

El usuario nunca ve "0/1/2/3/4" — ve "Todo A · 3 a 1 · 2 a 1 · 1 a 1 · Todo E".

---

## §4 — Defensa científica del modelo A / E

Para usuarios curiosos, prensa, reviewers de tienda y publicación científica futura. La clasificación Tipo A / E coincide en ~90 % con la literatura de **índice glucémico (IG)** y **carga glucémica (CG)**.

### §4.1 — Índice glucémico (Jenkins 1981)

Mide qué tan rápido sube la glucosa en sangre tras consumir un alimento, en una escala 0–100, relativa a la glucosa pura (= 100). Alimentos:

- IG bajo (< 55): la mayoría de los Tipo A — vegetales, proteínas, frutos secos, frutas bajas (fresa, manzana, palta).
- IG medio (55–70): zonas grises — arroz integral, avena, plátano verde.
- IG alto (> 70): la mayoría de los Tipo E — pan blanco, papa, sandía, azúcar.

### §4.2 — Carga glucémica (Salmerón 1997, Wolever 1990)

Refina IG considerando porción típica: `CG = (IG × g_carbohidrato_de_la_porción) / 100`.

La carga glucémica es **más predictiva del impacto insulínico real** que el IG aislado. Una sandía tiene IG alto (~76) pero CG baja por porción típica (~5). Una pasta integral tiene IG medio (~50) pero CG alta por porción típica (~25).

La regla operacional A/E sintetiza ambos: clasifica como E aquellos alimentos que, en porción típica, generan CG ≥ 10. Como A, los que generan CG < 10 o no contienen carbohidratos significativos (proteínas, grasas saludables).

### §4.3 — Evidencia de outcomes en cohortes

- Liu, Manson et al. (*Am J Clin Nutr* 2000, Nurses' Health Study n=75 521): dietas de alta CG asociadas con RR 1.98 de enfermedad coronaria vs CG baja.
- Brand-Miller et al. (*Diabetes Care* 2003, meta-análisis n=14 estudios): dietas de baja CG mejoran HbA1c en 0.43% en diabéticos tipo 2.
- Ludwig et al. (*Pediatrics* 1999): dietas altas en CG aumentan apetito subsiguiente, mecanismo conductual del sobre-consumo.

### §4.4 — Contra-evidencia honesta

No toda la literatura es congruente con la primacía hormonal. Hall et al. (*Cell Metab* 2015) en estudio metabólicamente controlado encontró pérdida de grasa ligeramente mayor con restricción de grasa que con restricción de carbohidratos a calorías iguales. Su conclusión: las calorías sí importan; la composición de macros refina pero no domina en condiciones controladas.

**Resolución de la app**: el contexto real del usuario no es metabólico-controlado. La adherencia gana. Una regla simple de proporción A:E que el usuario sostiene durante 12 meses produce mejores outcomes que una contabilidad calórica precisa que abandona en la semana 4. La evidencia de adherencia (Dansinger *JAMA* 2005, n=4 dietas comparadas) es lo que la app prioriza.

---

## §5 — Sistema nervioso: Pasivo vs Excitado

Concepto operacional de Frank Suárez —no presente en la literatura clínica peer-reviewed con esos nombres, pero sí en la literatura de **dominancia parasimpática vs simpática** y **cronotipos metabólicos**.

### §5.1 — Sistema nervioso Pasivo (parasimpático dominante)

Características:
- Metabolismo lento.
- Energía baja, sobre todo en la mañana.
- Apetito matutino fuerte.
- Duerme rápido pero sueño no siempre reparador.
- Tolera y disfruta carnes rojas, grasas densas.
- Tiende a fatiga crónica.

Recomendación operacional:
- Dieta **2x1** estándar.
- Proteínas rojas permitidas (res, cerdo, cordero).
- Grasas saludables generosas (aguacate, aceite oliva, frutos secos).
- Estimulantes moderados (café matutino).
- Ejercicio intenso en la franja de pico físico (15-17h, *CIRCADIAN_BIBLIOGRAPHY §3*).

### §5.2 — Sistema nervioso Excitado (simpático dominante)

Características:
- Metabolismo acelerado-tenso.
- Ansiedad, taquicardia ocasional.
- Insomnio o sueño superficial.
- Apetito matutino débil.
- Carnes rojas y grasas pesadas le caen mal.
- Prefiere pescado, pollo, vegetales.

Recomendación operacional:
- Dieta **3x1 modificada** (más vegetariana).
- Proteínas blancas (pollo, pavo, pescado).
- Bajo en grasas pesadas (menos cerdo, evitar fritos).
- Evitar estimulantes en la tarde (café antes de las 12:00).
- Ejercicio cardiovascular suave en pico físico.

### §5.3 — Captura en onboarding

5 preguntas binarias (ver SPEC-137 §RF-137-08). Score 0–5. ≥3 → Excitado; <3 → Pasivo. Empate → Pasivo por defecto seguro.

El sistema nervioso persiste como `users/{uid}.nervousSystem` y modula la **sugerencia visual** del slider en `PlateRatioSheet`, no obliga al usuario.

### §5.4 — Honestidad metodológica

La clasificación Pasivo / Excitado de Frank Suárez es un constructo operacional educativo, no un diagnóstico clínico. La app NO afirma que el usuario "es" excitado o pasivo a nivel fisiológico — afirma que **una recomendación específica le sirve mejor**. El copy es explícitamente blando: *"Las personas con tu patrón suelen rendir mejor con X"*, no *"Tú eres X"*.

---

## §6 — Día de permitidos (cheat day) como válvula de escape

### §6.1 — Justificación

Tanto el *Minimalist Fat Loss Protocol* (§7) como el método de Frank Suárez (capítulo "Tu salida psicológica") sostienen que **una dieta sostenible necesita una válvula de escape semanal**. La presión continua de adherencia produce abandono por culpa.

> "La disciplina compra tu libertad. 6 días disciplina + 1 día libertad total = sostenibilidad psicológica." — *Minimalist Fat Loss Protocol §7*.

### §6.2 — Reglas operacionales en ElenaApp

1. **Un solo día de permitidos por semana ISO**. Lockout duro en código (no UI). Intento de segundo activa muestra dialog de respeto a la regla.
2. El día de permitidos **NO se penaliza en el cálculo `weeklyAdherence`** del usuario. Queda excluido como outlier consciente.
3. La racha del usuario **NO se rompe** ese día.
4. El usuario **debe activarlo antes** del primer plato del día, no retroactivamente. Esto evita el patrón "después de comer pizza marco el día como permitidos".
5. Sigue mostrando un badge visible "Día de permitidos activo" durante todo el día.
6. **Disclaimer obligatorio en primera activación** (`SPEC-76` reafirma): el día de permitidos no aplica si el usuario declaró diabetes tipo 1, trastorno alimentario activo, embarazo / lactancia, o insuficiencia renal.

### §6.3 — Riesgo de uso patológico

Si el usuario marca día E ≥ 50 % aún sin activar cheat day, en ≥ 3 días alternos por semana, eso se considera un patrón disfuncional. La app debe (en SPEC-140 post-MVP) detectar este patrón y sugerir conversación con coach humano. NUNCA juzgar.

---

## §7 — Inferencia de comidas por protocolo de ayuno

La nutrición está acoplada al pilar Ayuno. Un usuario con protocolo 20:4 NO debería tener 3 comidas — no hay tiempo físico dentro de su ventana de 4 horas. La app infiere el target de comidas del día desde el protocolo activo, no se lo pregunta al usuario.

### §7.1 — Tabla canónica de inferencia

Cubre los **8 protocolos** que el proyecto persiste tras SPEC-98 en
`UserModel.fastingProtocol`. Todos los cierres trabajan hacia atrás
desde las 20:30 (regla invariante por el bloqueo intestinal a 22:00,
ver `CIRCADIAN_BIBLIOGRAPHY.md §3`).

| Protocolo | Ventana de comida | Target comidas | Snack opcional | Justificación |
|---|---|---|---|---|
| **Ninguno** (sin TRF) | 06:30 – 20:30 (~14 h) | 3 | Sí (A-dominante entre comidas) | Adulto sano sin restricción temporal. Educativo. |
| **12:12** (Principiante) | 08:30 – 20:30 (12 h) | 3 | Sí | Entrada cómoda al TRF sin romper rutinas sociales. Misma cardinalidad que "Ninguno" porque la ventana sigue siendo amplia. |
| **14:10** (Principiante) | 10:30 – 20:30 (10 h) | 2 | Sí | Punto medio. Salta o liviana el desayuno; sostiene almuerzo + cena + 1 snack. |
| **16:8** (Intermedio) | 12:30 – 20:30 (8 h) | 2 (almuerzo + cena) | Sí | El más popular. Salta desayuno, mantiene cena social. |
| **18:6** (Intermedio) | 14:30 – 20:30 (6 h) | 2 (comida + cena) | No | Ventana concentrada. Un tercer plato fragmenta digestión. |
| **20:4** (Avanzado) | 16:30 – 20:30 (4 h) | 1 (+1 opcional) | No | OMAD modificado. Una comida principal completa más una ligera previa al cierre, si hay hambre real. |
| **22:2** (Avanzado) | 18:30 – 20:30 (2 h) | 1 | No | Ventana mínima sostenible. Una sola comida principal densa nutricionalmente. |
| **OMAD** (Experto) | ~1 h variable | 1 | No | Una sola comida al día. Estricto para usuarios con experiencia y supervisión recomendada. |

**Regla operacional de la cardinalidad:**

- Ventana ≥ 12 h → 3 comidas (Ninguno, 12:12).
- Ventana entre 6 h y 10 h → 2 comidas (14:10, 16:8, 18:6).
- Ventana ≤ 4 h → 1 comida (20:4, 22:2, OMAD).

**Regla operacional del snack:** se permite si el espaciado entre
comidas principales es ≥ 4 h y la ventana de comida es ≥ 8 h (no
fragmenta digestión, no rompe el bloqueo intestinal). Tres protocolos
superan ambos umbrales: Ninguno, 12:12, 14:10, 16:8.

Coherente con `docs/CIRCADIAN_BIBLIOGRAPHY.md §4` (apertura/cierre
canónicos). El cierre 20:30 es invariante por el bloqueo intestinal a
22:00.

### §7.2 — Manejo de ventana extendida

Si el usuario cierra su ayuno antes del `firstMealGoal` esperado (por hambre real o ruptura consciente), la app NO recalcula el target hacia arriba. Mantiene el target original del protocolo. El plato extra cuenta hacia el Cociente A normal.

Si el usuario abre su ventana en exacto `firstMealGoal` y come una sola comida grande temprana, la app ve `mealsLoggedToday = 1 < target = 2 ó 3`, muestra copy informativo en Hoy: *"Llevas 1 de 2 comidas sugeridas. ¿Vas a cerrar ya tu ventana?"*. No es crítico; es contexto.

### §7.3 — Sobre-registro (más comidas que target)

Caso 1: el usuario marcó día de permitidos. Cualquier número de platos es aceptable. No se levanta alerta.

Caso 2: el usuario NO marcó día de permitidos. El sobre-registro suave (target + 1) muestra copy *"Estás comiendo más de lo que tu protocolo sugiere. ¿Es día de permitidos?"*. No se descuenta del Cociente A. Solo se ofrece la pregunta.

Caso 3: sobre-registro persistente sin marcar día de permitidos (target + 2 o más, ≥ 2 días por semana) → telemetría de SPEC-138 (post-MVP) lo detecta y sugiere ajuste de protocolo (*"¿Tu protocolo 20:4 te queda corto? Tal vez 18:6 sea más sostenible para ti"*).

### §7.4 — Cambios de protocolo intra-semana

Si el usuario cambió de 16:8 a 20:4 a mitad de semana, la vista semanal heatmap respeta el target de cada día individualmente (lunes-jueves muestra 2 celdas, viernes-domingo muestra 1 celda). El Cociente A semanal se calcula como promedio ponderado de los días.

---

## §8 — Hidratación dentro del marco nutricional

El pilar Hidratación tiene SPEC propio (vive en `lib/src/features/dashboard/application/hydration_notifier.dart`), pero comparte filosofía con Nutrición.

### §8.1 — Regla canónica Frank Suárez

> "Tome una cantidad de agua equivalente a la mitad de su peso corporal en libras, expresada en onzas, cada día." — *El Poder del Metabolismo* §8.

Equivalencia operacional: `litros_dia ≈ peso_kg × 0.033` (un usuario de 75 kg → ~2.5 L/día).

### §8.2 — Prohibición operacional: no beber calorías

Coherente con *Minimalist Fat Loss Protocol §2*. Las bebidas con calorías líquidas (jugos, refrescos, alcohol, batidos comerciales) NO cuentan como hidratación en la app. Solo agua (con o sin gas), té, café sin azúcar, infusiones y caldo de verduras cuentan al objetivo de hidratación.

### §8.3 — Endulzantes 0 cal en bebidas

Los endulzantes con discusión clínica abierta (aspartame, sucralosa) NO cuentan hacia hidratación negativa pero tampoco hacia positiva. La bebida con esos endulzantes es neutra en el contador. Estevia, eritritol y monk fruit sí cuentan como neutro positivo.

---

## §9 — Candidiasis intestinal (hongo cándida)

Concepto del corpus de Frank Suárez con anclaje clínico parcial (la candidiasis intestinal está reconocida, su rol en antojos extremos es debatido en la literatura peer-reviewed).

### §9.1 — Síntomas auto-reportables

- Antojos extremos por dulce o almidón.
- Niebla mental post-comida.
- Gases / hinchazón frecuentes.
- Fatiga crónica.
- Infecciones por hongos recurrentes.

### §9.2 — Detección por patrón en la app

Out of scope MVP (SPEC-140 post-launch). La idea es: si el usuario registra ≥ 4 platos E-dominantes en 3 días seguidos + reporta ≥ 3 de los síntomas arriba en check-in semanal, la app sugiere lectura del artículo MR sobre cándida. No diagnostica. No medica.

### §9.3 — Protocolo de Frank Suárez (referencia, no en MVP)

Reducción agresiva de Tipo E (3x1 o más estricto) + suplementos antifúngicos naturales + probióticos. Como ElenaApp NO recomienda suplementos, esta dimensión queda fuera del producto. Solo se conecta al usuario con contenido educativo MR.

---

## §10 — Hipotiroidismo y metabolismo lento

Otro concepto frecuente en el corpus Frank Suárez. La literatura clínica reconoce hipotiroidismo subclínico como factor de metabolismo bajo (TSH ligeramente elevada con T3/T4 normales).

### §10.1 — Implicación de la app

Si el usuario declara hipotiroidismo en `pathologies` del onboarding, la app:
1. Marca `nervousSystem` con sesgo a Pasivo si la captura quedó borderline.
2. Sugiere protocolo de ayuno conservador (16:8 máximo, no 20:4).
3. Activa disclaimer adicional: *"Tu pilar Nutrición debe complementarse con seguimiento médico de TSH. Esta app no reemplaza la consulta."*.

No hay lógica nueva en SPEC-137; estas reglas viven en el módulo de onboarding y disclaimer (`SPEC-76` versionado).

---

## §11 — Reglas de copy del pilar Nutrición

Toda copy de UI relacionada con nutrición debe cumplir:

1. **NUNCA** usar "calorías", "kcal", "macros" en pantallas visibles del usuario MVP.
2. **NUNCA** usar "prohibido", "no debes comer", "trampa", "fallaste".
3. **SÍ** usar "Tipo A", "Tipo E", "Cociente A", "día de permitidos", "tu protocolo sugiere".
4. **NUNCA** comparar al usuario con otros usuarios ("estás por debajo del promedio").
5. **SÍ** comparar al usuario consigo mismo ("esta semana llevas 6 % menos Cociente A que la anterior").
6. **NUNCA** diagnosticar ("tienes resistencia a la insulina"). **SÍ** sugerir ("esto sugiere que un 3x1 más estricto podría servirte").
7. **NUNCA** prometer pérdida de peso específica ("perderás 5 kg en 30 días").

Cualquier violación de estas reglas es bug.

---

## §12 — Mapeo SPEC → Sección

Para futuras SPECs, referencia obligatoria:

| SPEC | Sección de este doc |
|---|---|
| SPEC-137 (esta) | §1, §2, §3, §6, §7 |
| SPEC-138 (chips composición) | §2.3 |
| SPEC-139 (recetas) | §3, §5 |
| SPEC-140 (cándida detection) | §9 |
| SPEC-67 (hidratación al IMR) | §8 |
| SPEC-76 (disclaimer) | §10 |
| SPEC-136 (B2B coach) | todas |

---

## §13 — Pendiente / a revisar

Items que requieren validación clínica externa antes de ship a producción:

- [ ] **Lista canónica de §2** debe ser revisada por endocrinólogo / nutricionista del comité científico MR antes del soft-launch del 10-ago-2026.
- [ ] **Captura de sistema nervioso (§5.3)** — 5 preguntas deben validarse con piloto N=20 antes de incluir en onboarding público.
- [ ] **Inferencia de target por protocolo (§7.1)** — actualizar si el comité médico recomienda otros números.
- [ ] **Disclaimer cándida (§9)** — wording legal final.

---

## §15 — Intervalo entre comidas (SPEC-137 E.5)

Toda la regla operacional vive en `lib/src/features/nutrition/domain/meal_interval_rules.dart`. Esta sección documenta el respaldo.

### §15.1 — Fundamento hormonal

El pico de insulina post-prandial ocurre 30-60 min después de comer en personas metabólicamente sanas. El retorno a baseline tarda **2-3 horas** en respuestas estándar a comidas mixtas (Crapo PA et al., *Diabetes* 1976; van Cauter E et al., *J Clin Invest* 1992).

Comer cada **<2 horas** mantiene insulina elevada de forma crónica incluso con carga glucémica baja por plato individual (Wolever TMS, *Br J Nutr* 2003). La hiperinsulinemia sostenida promueve resistencia a insulina por downregulation de receptores (DeFronzo RA, *Diabetes Care* 2009).

### §15.2 — Flexibilidad metabólica

Galgani JE et al. (*Am J Physiol Endocrinol Metab* 2008) y la síntesis de Mattson MP (*Ageing Res Rev* 2017) documentan que los periodos de **≥3 horas** sin ingesta son lo que permite al cuerpo transitar del modo "glucosa" al modo "lipólisis" como combustible primario. El patrón de "grazing" (picar cada hora) bloquea ese tránsito y se asocia a peor sensibilidad a insulina y mayor adiposidad visceral.

Coincide con el corpus operacional de Frank Suárez (ya documentado en `reference_frank_suarez.md`), que recomendaba 3-4 h entre comidas por la misma razón fisiológica.

### §15.3 — Regla operacional ElenaApp

| Intervalo desde última comida | Comportamiento |
|---|---|
| < 2 h | **Bloqueado**. La app rechaza el registro con dialog explicativo. El usuario debe esperar al menos hasta `lastMealAt + 2h`. |
| 2 – 3 h | **Warning**. Dialog con dos botones: "Esperar" (cancela) o "Registrar igual" (decisión consciente, registra con `forceLog: true`). |
| ≥ 3 h | **OK**. Sin restricción. |
| Primera comida del día | OK por defecto. |
| Última comida hace ≥ 18 h | Tratado como primera comida (el ayuno nocturno reseteó la insulina baseline). |
| Día de permitidos activo | Suspende todas las reglas. Decisión consciente del usuario, respetamos. |

### §15.4 — Notificación 30 min antes

Cada vez que el usuario registra una comida (fuera de día de permitidos), la app agenda dos canales en paralelo:

1. **Banner in-app** en el Dashboard (`NextMealBanner`): aparece cuando estamos dentro de los 30 min previos a `lastMealAt + 3h` y desaparece al pasar ese momento o al registrar la siguiente comida. Refresca cada 10 s vía `metabolicPulseProvider`.
2. **Push local del SO** (`NotificationScheduler.scheduleNextMealReminder`): one-shot agendado para `lastMealAt + 2.5h` con copy *"Tu próxima comida es a las HH:MM. Alístate."*. Se reemplaza cada vez que el usuario registra una nueva comida.

Si el usuario elimina su último log, la app re-agenda contra la comida anterior o cancela si no queda ninguna.

### §15.5 — Honestidad metodológica

Las constantes 2h (bloqueo) y 3h (recomendado) son **decisiones operacionales del producto** basadas en el rango central de la literatura. No son un dogma — un usuario puede tener metabolismo diferente. La opción "Registrar igual" en el warning respeta esa heterogeneidad biológica. El bloqueo absoluto solo aplica al caso extremo <2h, que la literatura sí soporta como patológico universal (hiperinsulinemia crónica).

Si el equipo médico (revisión clínica) considera ajustar los umbrales, todos viven en `MealIntervalRules` — un solo punto de modificación.

---

## §16 — SPEC-138 — Clasificación NOVA (ultraprocesados)

**Añadido 2026-06-05** como segundo eje del pilar Nutrición, ortogonal al `qualityScore` continuo (que mide respuesta metabólica). NOVA mide grado de procesamiento industrial.

### §16.1 — Marco normativo

Fuente primaria: **Monteiro CA, Cannon G, Lawrence M, Costa Louzada ML, Pereira Machado P.** *Ultra-processed foods, diet quality, and health using the NOVA classification system.* FAO, Rome, 2019. Resumen operacional en **Monteiro et al., Public Health Nutrition 22(5):936-941, 2019**.

Define cuatro grupos:

1. **NOVA 1 — No procesados o mínimamente procesados.** Partes comestibles de plantas o animales y procesos físicos (secado, triturado, refrigeración) que no añaden sustancias.
2. **NOVA 2 — Ingredientes culinarios procesados.** Sustancias derivadas de NOVA 1 por prensado, refinado o molienda usadas en cocina.
3. **NOVA 3 — Alimentos procesados.** Combinación NOVA 1 + NOVA 2 con sal, azúcar, fermentación o ahumado tradicional. Reconocibles.
4. **NOVA 4 — Ultraprocesados (UPF).** Formulaciones industriales con ingredientes no culinarios (proteína hidrolizada, dextrosa, suero modificado), aditivos cosméticos (saborizantes, colorantes, emulsionantes, espumantes) y técnicas industriales (extrusión, hidrogenación, moldeado).

### §16.2 — Evidencia clínica de impacto sobre salud metabólica

- **Hall KD et al., 2019.** *Ultra-Processed Diets Cause Excess Calorie Intake and Weight Gain.* Cell Metabolism 30(1):67-77. RCT cruzado n=20, NIH Clinical Center, 4 semanas. Dieta UPF iguales en macros/fibra → consumo +508 kcal/día y peso +0.9 kg en 14 días. Reversible al volver a NOVA 1.
- **Srour B et al., 2019.** *Ultra-Processed Food Consumption and Risk of Mortality Among Middle-aged Adults in France.* JAMA Internal Medicine 179(4):490-498. NutriNet-Santé n=44,551, mediana 7.1 años. **+14% mortalidad por cada 10% más de UPF en la dieta** (HR 1.14, IC 95% 1.04-1.27).
- **Rico-Campà A et al., 2019.** *Association between consumption of ultra-processed foods and all-cause mortality.* BMJ 365:l1949. Cohorte SUN n=19,899, mediterránea. Patrón consistente con Srour: HR 1.18 para alto consumo.
- **Chassaing B et al., 2015.** *Dietary emulsifiers impact the mouse gut microbiota promoting colitis and metabolic syndrome.* Nature 519:92-96. Mecanismo: emulsionantes (polisorbato-80, CMC) alteran microbioma → inflamación crónica de bajo grado.
- **Monteiro CA, 2018.** *Ultra-processed foods: international consensus on definition.* BMJ Editorial. Consenso para política pública usando NOVA.

### §16.3 — Coherencia con marco metabólico de ElenaApp

UPF impactan el IMR por **tres vías independientes**:

1. **Insulínica.** Picos repetidos por densidad calórica + ausencia de matriz. Ya cubierta parcialmente por `qualityScore`.
2. **Microbiota.** Emulsionantes y conservantes alteran flora (Chassaing 2015). NO cubierta por `qualityScore`.
3. **Palatabilidad hiperestimulante.** Sobreconsumo crónico (Hall 2019). NO cubierta por `qualityScore`.

Por eso `qualityScore` y NOVA son **ortogonales**: leche entera tiene `qualityScore=50` y `NOVA=1`; margarina tiene `qualityScore=30` y `NOVA=4`. Ambas "media" en respuesta insulínica, pero NOVA discrimina el riesgo metabólico estructural.

### §16.4 — Aplicación en código

| Capa | Artefacto | Función |
|------|-----------|---------|
| Catálogo | `Food.nova: NovaGroup` | Metadato por alimento (default NOVA 1) |
| Plato | `PlateBuilder.upfSharePercent` | % de slots NOVA 4 en plato actual |
| Persistencia | `NutritionLog.upfSlots / totalSlots` | Almacena para agregación posterior |
| Diario | `dailyUpfShareProvider` | Agrega por ciclo metabólico (cycle-aware, SPEC-149) |
| Semanal | `weeklyUpfShareProvider` | Agrega últimos 7 días |
| Coaching | `upfCoachingPool` | Insight en `CycleFeedback` cuando `weekly > 40%` |
| Tendencia | `TransformationSnapshot.upfShareDelta` | Delta 30d en `TransformationCard` (SPEC-148) |

### §16.5 — Umbral de alerta y su justificación

**40% UPF semanal** activa insight de coaching. Razón científica: Hall 2019 documentó +508 kcal/día con dieta ~60% UPF; 40% es un punto razonable **antes** de aproximarse al rango de exceso calórico documentado. Buffer protector, no umbral arbitrario.

**25% UPF semanal** activa visualización permanente en Hoy. Razón: por debajo de 25% el patrón es ocasional (cheat day-like) y no amerita panel persistente que sature UI.

Estos umbrales viven en `lib/src/features/nutrition/application/upf_thresholds.dart` para revisión clínica unitaria.

### §16.6 — Clasificación de los alimentos del catálogo

Asignación 2026-06-05. Cada NOVA 3 y NOVA 4 está documentado en el catálogo (`food_catalog.dart`) con comentario inline citando esta sección. NOVA 1 es default implícito.

**NOVA 4 (ultraprocesados, 13 items):** galletas, galletas_dulces, galletas_saladas, cereal, gaseosa, cocacola, margarina, mayonesa, salchicha, chocolate_caliente, pizza, hamburguesa, salchipapa, sandwich, empanada.

**NOVA 3 (procesados, 13 items):** jamon, queso_campesino, yogur_griego, suero_costeno, aceite_vegetal, queso_amarillo, queso_crema, crema_de_leche, tocino, chicharron, chorizo, pan, pan_integral, chocolate.

**NOVA 2 (ingredientes culinarios, 7 items):** mantequilla, manteca, azucar, panela, miel.

**NOVA 1 (el resto, ~52 items):** todas las carnes/pescados/huevo frescos, verduras, frutas, legumbres, frutos secos, semillas, leche pasteurizada, café, jugos caseros.

### §16.7 — Decisiones de criterio (no triviales)

- **Pizza, hamburguesa, sandwich, salchipapa, empanada = NOVA 4** (decisión estricta, Carlos 2026-06-05). Monteiro 2019 §Tabla 1 lista "pizzas, burgers, hot-dogs" como ejemplos canon. Versión casera con ingredientes propios del catálogo registra los componentes individuales (queso+pan+tomate) y la clasificación cae naturalmente.
- **Pan blanco/integral = NOVA 3.** Sin emulsionantes ni dextrosa industrial reconocibles. Si el pan tiene mejorantes (pan de molde industrial) sería NOVA 4 pero el catálogo no discrimina marcas — interpretación benigna conservadora.
- **Leche pasteurizada = NOVA 1.** Monteiro 2019 explícito sobre pasteurización como proceso NOVA 1.
- **Chocolate = NOVA 3.** Chocolate amargo en barra. Versiones con leche y azúcar industrial entrarían en NOVA 4 pero el catálogo no discrimina; conservador NOVA 3.
- **Salchicha = NOVA 4, chorizo artesanal = NOVA 3.** Monteiro 2019 cita "sausages" en UPF cuando son reconstituidas con emulsionantes; chorizo tradicional curado entra en NOVA 3.

### §16.8 — UPF NO entra al IMR

Decisión explícita 2026-06-05: el UPF% **no** alimenta la fórmula del IMR (semanal ni diario). Solo se usa para:

1. Insight en `CycleFeedback` cuando supera umbral.
2. Delta narrado en `TransformationCard` 30d.
3. Chip silencioso en `PlateRatioSheet`.

Razones:

- Evita doble penalización (qualityScore ya refleja el impacto insulínico).
- Mantiene `IMR_BIBLIOGRAPHY.md` estable — la fórmula del IMR sigue siendo defendible sin renegociar pesos.
- Distancia UPF de cualquier carga moral sobre el score.

### §16.9 — Tono de los copies (no estigmatizar)

Aplicar memoria interna `notification-tone-human-not-clinical`. Copies validados:

- "Tu cuerpo lo agradece cuando le das menos comida industrial."
- "Está bien tener tu día con algo de eso. El patrón importa más que el plato puntual."
- "Notamos menos ultraprocesado esta semana. Eso se nota en cómo te sentís."

Pool definitivo en `lib/src/features/nutrition/application/upf_coaching_pool.dart`. Toda cita usa formato corto "· Monteiro 2019 · Hall 2019" al pie del copy.

---

## §14 — Cómo usar este documento

1. Al redactar SPEC nueva de nutrición: citar la sección aplicable de §1-§10. Si el caso no está cubierto, abrir issue para extender este doc primero.
2. Al revisar PR de copy nutricional: validar contra §11. Cualquier "kcal" o "prohibido" se rechaza.
3. Al entrenar a un nuevo colaborador del producto: este doc + `CONSTITUTION.md` + `CIRCADIAN_BIBLIOGRAPHY.md` es el onboarding obligatorio.
4. Al responder objeción de App Store / prensa sobre "Frank Suárez no es médico": apuntar a §4 (defensa por IG/CG) y §5.4 (honestidad metodológica).

Este documento es **vivo**. Cualquier hallazgo clínico nuevo, feedback del comité médico, o aprendizaje de usuario que contradiga lo escrito → propone PR con justificación. Versionado semántico (v1.1, v1.2, ...) con prefijo de commit `docs(nutrition)`.

---

*Próxima revisión obligatoria: cierre de SPEC-137 (implementación), luego pre-soft-launch del 10-ago-2026.*
