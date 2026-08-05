# Propuesta — Perlas + Zumbidos en Retos (SPEC-264, borrador)

**Estado:** propuesta para revisión. NO implementado.
**Fecha:** 2026-08-05.
**Contexto:** extiende SPEC-263 (Retos de constancia) y SPEC-262 (gamificación).
**Pedido de Carlos:** renombrar "estrellas" → "perlas"; que las perlas dejen de
comprar congeladores y sirvan para **interacciones sociales dentro de los
retos**; agregar un "zumbido" estilo MSN Messenger para animar a un competidor
que se está quedando colgado en un pilar.

---

## 0. Resumen ejecutivo

Dos cambios encadenados:

- **Parte A — Perlas.** Renombrar la moneda y **desacoplarla de los
  congeladores**. Los congeladores pasan a ganarse SOLO por constancia (ya
  existe ese camino), lo que de paso **elimina el patrón "paga para proteger tu
  racha"** que marqué como riesgoso. Las perlas quedan libres para un propósito
  nuevo: la economía **social** de los retos.

- **Parte B — Zumbidos.** Dentro de un reto activo, un competidor puede enviar
  a otro una **interacción** (zumbido, porra, 🔥) que le llega como
  notificación "de esa persona" (modelo Duolingo). Cuesta perlas. Sirve para
  reactivar a quien se está quedando atrás — sin exponer datos de salud y con
  guardarraíles de bienestar estrictos.

La investigación (ver §5) valida el mecanismo pero obliga a diseñarlo con
cuidado: el nudge social sube la adherencia, pero la culpa/vergüenza en apps de
dieta hace daño. Por eso la propuesta es **solo aliento, catálogo cerrado, sin
texto libre, con opt-out**.

---

## 1. Parte A — Perlas (rename + repropósito)

### 1.1 Rename
- "Estrellas" → "Perlas" en todo el copy y el ícono (de ⭐ a una perla; a nivel
  Flutter, algo como `Icons.blur_circular` / `Icons.grain` teñido nacarado, o
  un asset propio).
- El **cómo se ganan NO cambia**: siguen saliendo de registrar hábitos reales
  (agua, comida, cerrar ayuno, etc.). Es solo nombre + destino del gasto.

### 1.2 Desacople de congeladores
- Hoy: congeladores se ganan gratis cada 6 días que califican **o** se compran
  con estrellas en la Tienda.
- Propuesta: **congeladores solo se ganan por constancia** (los 6 días). Se
  quita la compra.
  - **Por qué:** le da a las perlas un propósito único y claro (social), y
    elimina el "paga para no perder tu racha" — un dark pattern que además la
    evidencia de bienestar desaconseja (§5).
- La "Tienda" se reorganiza: la fila de compra de congeladores se retira (o
  queda como texto informativo "se ganan siendo constante"); aparece una nueva
  sección **"Interacciones"** donde se gastan perlas (Parte B).

---

## 2. Parte B — Zumbidos e interacciones de reto

### 2.1 Concepto
Dentro de un reto activo, cada miembro puede enviar a otro una interacción de un
**catálogo cerrado**. Llega como push "de {nombre}", con animación + vibración
al abrir (el "buzz" de MSN), y un botón directo al pilar pendiente.

Catálogo inicial propuesto (precio en perlas, a calibrar):

| Interacción | Copy (ejemplo) | Precio | Tono |
|---|---|---|---|
| Porra 👏 | "¡{nombre} te está echando porras!" | gratis / 2 | Aliento |
| Zumbido ⚡ | "¡{nombre} te dio un zumbido! No pierdas el ritmo hoy 💪" | 5 | Aliento activador |
| Fuego 🔥 | "¡{nombre} reconoce tu racha! 🔥" | 3 | Reconocimiento |
| Choque de manos 🤝 | (al cierre del reto) "¡{nombre} te dio la mano!" | 3 | Cierre |

> Deliberadamente **no** hay "smack talk" ofensivo ni texto libre. Ver §2.3.

### 2.2 Privacidad — cómo animar a quien va colgado sin filtrar salud
Las reglas de SPEC-263 **no exponen los pilares de otro**: cada quien solo lee
su propio `streak_history`; del resto solo ve el puntaje (días). Para que el
zumbido sea *contextual* ("anima a quien hoy va colgado") sin romper eso:

- El **propio cliente** publica en su doc de score un booleano `cumplioHoy`
  (mismo grano que su puntaje, que ya publica de sí mismo). Los demás ven "hoy
  aún no cumplió" — un sí/no, **no qué pilar ni ningún dato crudo**.
- Con eso la UI del tablero puede resaltar "va colgado hoy" y ofrecer el
  zumbido, sin que nadie vea peso, comida ni pilares.
- **Alternativa más conservadora:** sin flag; se puede animar a cualquiera en
  cualquier momento (no contextual). Cero exposición, algo menos "inteligente".

Recomendación: el flag `cumplioHoy`. Es el mismo grano que el score y no añade
sensibilidad real.

### 2.3 Guardarraíles de bienestar (no negociables)
Elena es una app de salud con ayuno y nutrición de por medio; la evidencia (§5)
muestra que culpa/vergüenza/comparación disparan conductas de riesgo. Por eso:

1. **Catálogo cerrado, sin texto libre.** Apple documentó trolling con mensajes
   personalizados; acá todos los mensajes son predefinidos y positivos.
2. **Solo aliento, nunca vergüenza.** Nada de "vas perdiendo" ni "no seas
   flojo". Nunca mensajes sobre peso/cuerpo. El zumbido anima la **constancia
   general**, no señala el pilar de comida/ayuno de forma que presione la
   conducta alimentaria.
3. **Opt-out.** Ajuste para dejar de recibir interacciones (Duolingo lo ofrece;
   parte de los usuarios lo agradecen).
4. **Anti-abuso:** cooldown por par emisor→receptor (p. ej. 1 zumbido/día) y
   cap de recepción diaria (p. ej. 3), respetando horas de silencio.
5. **Solo dentro de un reto activo** y entre miembros de ese reto.

### 2.4 Entrega técnica
- **Datos:** `challenges/{code}/nudges/{autoId}` con
  `{fromUid, fromName, toUid, type, createdAt}`. Reglas: `create` si eres
  miembro y `fromUid == auth.uid` y `toUid != auth.uid`; `read` para miembros;
  sin `update`. Gasto de perlas: descuento offline-first en el cliente al enviar
  (igual que la compra actual).
- **Push:** un cliente NO puede enviar push a otro. Requiere una **Cloud
  Function** `onCreate` sobre `nudges/*` que dispara **FCM** al `toUid`,
  respetando su opt-out y el rate-limit. Es la pieza de más peso (toca
  `functions/`).
  - **Opción v1 sin backend:** el zumbido se muestra **in-app** cuando el
    receptor abre la app (banner + animación), sin push. Evita la Cloud
    Function en la primera versión; el push se agrega en una fase 2.
- **Opt-out:** flag en el perfil/gamification (`receiveNudges: bool`), respetado
  por la Cloud Function.

---

## 3. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Acoso / vergüenza | Catálogo cerrado positivo, sin texto libre, opt-out |
| Presión que gatilla TCA (foco comida/ayuno) | Nunca peso/cuerpo; anima constancia general; opt-out; el flag es "cumplió hoy sí/no", no el detalle del pilar |
| Spam / fatiga de notificaciones | Cooldown por par + cap diario + horas de silencio |
| Fuga de privacidad | Flag booleano de mismo grano que el score; cero datos de salud crudos entre usuarios |
| Complejidad backend (FCM) | v1 in-app sin push; Cloud Function en fase posterior con feature flag |

---

## 4. Fases de implementación (si se aprueba)

1. **Perlas.** Rename estrellas→perlas (copy+icono) y desacople de congeladores
   (solo por constancia). Bajo riesgo, rápido. Tests.
2. **Interacciones (dominio + datos).** Catálogo, gasto de perlas offline-first,
   `nudges` + reglas Firestore, flag `cumplioHoy`. Tests.
3. **UI.** Botón "animar/zumbar" junto a cada competidor en el tablero; pantalla
   de recepción con animación/haptic + CTA al pilar; sección "Interacciones".
4. **Push (opcional / fase aparte).** Cloud Function → FCM al receptor, opt-out,
   rate-limit. Requiere trabajo en `functions/`.
5. **Docs + QA + métrica.** Medir si sube la constancia (Duolingo reportó +22%
   con el nudge de amigos).

---

## 5. Investigación que respalda el diseño

- **Duolingo (friend nudge):** el nudge se empaqueta como viniendo *del amigo*,
  no de la app; sube la finalización diaria de lección +22%; ofrece opt-out
  porque parte de los usuarios se sienten presionados. → Modelo a copiar:
  "de tu amigo" + opt-out.
- **Apple Fitness (cheers / smack talk):** mensajes preset de aliento **y**
  "smack talk"; los personalizados abrieron la puerta a trolling. → Copiar los
  cheers preset; **evitar** el texto libre.
- **Apps de dieta/fitness y bienestar:** revisión de 38 estudios asocia su uso
  con más síntomas de conducta alimentaria alterada; features de culpa
  (presupuestos excedidos, visualizaciones "en rojo") y comparación social
  generan culpa/vergüenza. → Guardarraíl central: **solo aliento, nunca
  vergüenza, nada de peso/cuerpo**.

Fuentes:
- Duolingo Friend Streak / nudges — blog.duolingo.com, deconstructoroffun.
- Apple Fitness+ SharePlay / smack talk — cultofmac.com; trolling: refinery29.com.
- Fitness apps y conducta alimentaria — news-medical.net, bioengineer.org,
  Cambridge BJPsych Open, ScienceDirect.

---

## 6. Decisiones (LOCKED — 2026-08-05, Carlos)

1. **Tono:** solo positivos (porras/ánimo/reconocimiento). Sin pique ni burla.
2. **Alcance v1:** in-app (el zumbido aparece al abrir la app). Push vía Cloud
   Function/FCM queda para una fase 2 posterior.
3. **Contextual:** con flag `cumplioHoy` (sí/no) que cada quien publica de sí
   mismo. La app resalta a quien va colgado hoy; sin exponer pilares ni datos.
4. **Congeladores:** 100% por constancia. Se quita la compra.

## 7. Secuencia de construcción aprobada

- **F1 — Perlas + Tienda de interacciones (juntas).** Rename estrellas→perlas de
  cara al usuario (copy + ícono); NO se tocan las claves persistidas en Firestore
  (`stars`, etc.) ni `StarAction`/`awardStar` para no romper datos ni disparar un
  refactor masivo. Se quita la compra de congeladores (pasan a earn-only) y la
  Tienda pasa a vender interacciones — por eso F1 incluye el catálogo, si no la
  Tienda queda vacía.
- **F2 — Zumbidos (dominio + datos + reglas).** Catálogo, gasto de perlas
  offline-first, `challenges/{code}/nudges/*`, flag `cumplioHoy`, reglas + tests.
- **F3 — UI in-app.** Botón animar/zumbar en el tablero (resalta a quien va
  colgado), bandeja/animación de recepción al abrir la app + CTA al pilar.
- **F4 — (posterior) Push real.** Cloud Function → FCM + opt-out + rate-limit.
- **F5 — Docs + QA + métrica de constancia.**

---

## 8. Addendum — "Modo anillos" (competidores se ven, estilo Apple Fitness)

Carlos pidió que, como en Apple Fitness, un competidor **pueda ver los anillos
(el avance) de los demás**. Esto cambia el modelo de visibilidad de SPEC-263
(que solo mostraba "días" y un flag "cumplió hoy").

### 8.1 Cómo lo hace Apple (referencia)
- Puntaje = 1 punto por cada **% que sumas a tus anillos** por día; tope 600/día;
  competencia de 7 días (máx 4.200). Gana quien más puntos acumule.
- El % es **relativo a la meta de cada quien** → competencia justa entre
  distintos niveles.
- El rival ve tus **anillos** (Move/Ejercicio/De pie), pasos y distancia, y
  recibe avisos cuando cierras metas. **No puedes ocultarte de alguien contra
  quien compites.**
- Apple **nunca** comparte datos finos de salud (ritmo cardíaco, etc.): comparte
  el **anillo (el logro)**, no el dato crudo.

### 8.2 Adaptación a Elena — 5 pilares = 5 anillos
Cada competidor ve, de los demás, **los 5 pilares del día como 5 anillos**
(ayuno, ejercicio, nutrición, sueño, hidratación): cumplido / a medias / vacío.
Se comparte el **estado del pilar (logro)**, nunca el dato crudo — ni peso, ni
calorías, ni qué comió, ni horas exactas. Es el paralelo directo de "comparto el
anillo, no el ritmo cardíaco".

> Nota de bienestar: mostrar el pilar de **nutrición/ayuno** cumplido-sí/no
> expone algo más que el modelo anterior. Se mantiene a nivel de LOGRO (cerró el
> anillo o no), nunca detalle, y el tono de las interacciones sigue siendo de
> aliento (§2.3). Ver decisión D6 sobre ocultar pilares sensibles.

### 8.3 Puntaje — dos opciones
- **A) Constancia binaria (actual):** 1 punto por día que califica. Los anillos
  serían **solo visuales** (ves quién va cumpliendo), el puntaje no cambia.
- **B) Puntos por pilar (estilo Apple):** cada pilar cerrado suma (p. ej. 1 punto
  por pilar → máx 5/día; o % por pilar). Premia también los días parciales y
  hace que **cada anillo cerrado valga un punto** — el mapeo Apple exacto. Sigue
  siendo constancia (no peso). **Supersede** el `consistencyPoints` de SPEC-263.

Recomendación: **B**, porque hace que los anillos y el puntaje sean lo mismo
(cerrás anillo → sumás), que es lo que hace adictiva la mecánica de Apple.

### 8.4 Impacto en datos
Cada quien publica en su `scores/{uid}` (auto-publicado, sin leer datos ajenos):
`{ uid, displayName, points, todayRings: {ayuno,ejercicio,nutricion,sueno,
hidratacion}, updatedAt }`, donde cada anillo es cumplido/parcial/vacío. Historia
semanal de anillos: opcional (vista expandida por competidor).

### 8.5 Decisiones nuevas (LOCKED — 2026-08-05, Carlos)
- **D5 — Puntaje:** **B, puntos por pilar** (estilo Apple). Cada pilar cerrado
  suma. **Supersede** el `consistencyPoints` binario de SPEC-263.
- **D6 — Privacidad de pilares:** **los 5 anillos siempre visibles** al rival
  (estilo Apple, no te ocultas). Siempre a nivel de logro (cerró/no), nunca dato
  crudo.
- **D7 — Metas relativas:** no se incluye en v1 (los pilares son casi iguales
  para todos; la normalización de Apple casi no aplica).

## 9. ¿Esto motiva y genera adherencia? (análisis de evidencia)

**Veredicto corto:** sí, con condiciones. La competencia social sube la
adherencia MIENTRAS el reto está activo — y es la palanca más fuerte de las que
hay— pero el efecto se desvanece al terminar, y las recompensas extrínsecas
pueden volverse contraproducentes si se convierten en el fin. El diseño tiene
que apuntar a que el hábito quede, no solo a ganar la semana.

### 9.1 Lo que respalda construirlo
- **La competencia es la que más funciona.** El ensayo STEP UP (Patel, *JAMA
  Internal Medicine*, 602 adultos, 24 semanas) comparó tres diseños con
  incentivos sociales: apoyo, colaboración y **competencia** — y la competencia
  fue la más efectiva: **+920 pasos/día vs control**. Justo el modelo del reto.
  Usaron **clusters de 3** con tabla semanal (grupos chicos, no rankings
  masivos).
- **Duolingo:** el nudge "de tu amigo" sube +22% la finalización diaria.
- **Meta-análisis:** la gamificación aumenta la actividad física de forma
  significativa frente a controles con y sin intervención; también mueve peso e
  IMC. La mecánica sirve.

### 9.2 Las advertencias honestas
- **El efecto se desvanece al terminar.** En los seguimientos (~14 semanas
  después) el efecto cae a muy pequeño. La adherencia DURANTE > la adherencia
  DESPUÉS.
- **Efecto novedad.** Sube al principio y decae cuando la novedad se gasta;
  puntos e insignias se "desensibilizan".
- **Sobrejustificación.** Premiar con extrínsecos (perlas/puntos) algo que la
  persona ya quería hacer puede debilitar su motivación interna. Matiz clave:
  *las recompensas INFORMATIVAS (que señalan progreso) fortalecen la motivación
  intrínseca; las CONTROLADORAS (paga-para-ganar) la debilitan.*
- **El de abajo se desmotiva.** La comparación social puede hundir a quien va
  último; en apps de dieta, además, dispara culpa/vergüenza (§5).

### 9.3 Qué hace que PEGUE (y valida decisiones ya tomadas)
1. **Competencias cortas y recurrentes**, no una sola larga. El modelo de 7 días
   de Apple/STEP UP calza con la curva de novedad. → Empujar el preset de **7
   días** como default (ya lo ofrecemos).
2. **Recompensas informativas, no controladoras.** Anillos, racha y "cerraste
   4/5 pilares" señalan progreso. → Ya decidimos **congeladores por constancia
   (no compra)**: eso es exactamente "informativo, no pay-to-win". ✔
3. **Anclar a la motivación intrínseca:** amarrar el juego al beneficio real
   (IMR, sentirse mejor) para que, cuando la novedad caiga, quede la razón de
   fondo. Elena ya tiene ese ancla (IMR + coaching).
4. **Proteger al que va perdiendo:** grupos chicos, **zumbidos solo positivos**
   (ya decidido ✔), y celebrar el progreso personal, no solo el ranking.
5. **Medirlo.** Instrumentar adherencia (días/pilares cerrados) de quien está en
   un reto vs quien no — como Duolingo (+22%) y STEP UP. Sin métrica, no sabemos
   si funciona en NUESTROS usuarios.

### 9.4 Conclusión para el producto
Construirlo tiene respaldo, pero el objetivo no es "que compitan" sino "que el
reto sea un empujón temporal que instale el hábito". Por eso: retos cortos y
recurrentes, recompensas que informan progreso (no que se compran), tono
positivo, y una métrica de adherencia desde el día 1 para validar el lift real y
no vivir del efecto novedad.

### 8.6 Consecuencias de D5/D6 sobre el build
- El dominio de puntaje cambia: `challenge_scoring.dart` pasa de "contar días que
  califican" a **sumar pilares cerrados** en la ventana. Hay que ajustar
  `consistencyPoints` (o reemplazarlo por `pillarPoints`) y sus tests.
- `scores/{uid}` incluye `todayRings` (5 pilares del día, cerrado/parcial/vacío)
  además de `points`. Se auto-publica; nadie lee datos ajenos.
- El tablero muestra, por competidor, los 5 anillos del día + puntos.

---

## 10. Retención post-reto — revancha, marcador e insignias

Ataca directo el punto débil del §9: que el hábito se caiga al terminar el reto.

### 10.1 Por qué esto SÍ ataca el problema (evidencia)
- **Formar un hábito toma ~66 días** de repetición consistente (Lally et al.;
  mediana 66, rango 18-254; las primeras repeticiones pesan más; saltarse un día
  no lo arruina). → Un reto de 7-30 días **no alcanza** a cementar el hábito. La
  **revancha encadena repeticiones** hacia ese umbral. Es el argumento
  científico del rematch.
- **Los ciclos recurrentes son EL motor de retención.** Duolingo (ligas
  semanales) bajó churn 47%→28%; Strava (Challenges) subió la retención a 90
  días de 18%→32% y +28% de usuarios activos. "El miedo a bajar motiva más que
  la esperanza de subir"; los resets crean urgencia sin jerarquía permanente;
  la "envidia benigna" (ver al par avanzar) impulsa el cambio.
- **Insignias:** suben motivación intrínseca y finalización/retención; rinden
  mejor como **hitos significativos** (no spam) y pegan distinto según el tipo de
  jugador (Achiever intrínseco, Player coleccionista).

### 10.2 Diseño
**A) Revancha (rematch).** Al cerrar un reto, un banner "Otra vuelta" clona el
reto con los mismos miembros y un período nuevo (default **7 días**). **Opt-in**
(no forzado: el objetivo es encadenar, no atar a la fuerza). Es la pieza que
mantiene la repetición viva hacia los 66 días.

**B) Marcador persistente (head-to-head).** Un récord acumulado por usuario:
retos jugados, ganados y rivalidades recurrentes (victorias entre los mismos).
Convierte retos sueltos en una **rivalidad continua** — el motor de "envidia
benigna". Dato agregado y auto-publicado (`retosJugados`, `retosGanados`, …).

**C) Insignias de reto — integradas al sistema existente (no reinventar).**
Elena ya tiene 38 insignias en 10 categorías (`BadgeCategory`, whitelist cerrada
validada en `firestore.rules`, `allow create` únicamente, `badgeId`
determinístico, `BadgeEngine` por umbral). Se agrega una categoría **`retos`**
con hitos: *Primer reto* (participar), *Terminar un reto*, *Ganar*, *Ganar 3*,
*Ganar 10*, y **"Revancha"** (encadenar N retos seguidos — premia la constancia
recurrente, que es justo lo que forma el hábito).
- Integración: sumar `retos` a `BadgeCategory.all` **y** a la whitelist de
  categorías en `firestore.rules`; nuevas `BadgeDefinition` por umbral; otorgar
  al cierre del reto con el `BadgeEngine` existente.
- Diseñadas como **hitos informativos de constancia real (no pay-to-win)** — lo
  que la evidencia (§9) dice que fortalece la motivación intrínseca.

### 10.3 Guardarraíles
- Revancha **opt-in**; encadenar es la meta, no la obligación.
- El "miedo a bajar" motiva, pero en salud lo mantenemos **solidario**: sin
  castigar ni avergonzar al que pierde; se celebra el progreso personal, no solo
  el ranking.
- Insignias significativas, no spameadas.

### 10.4 Impacto en el build
- F2/F3 suman **cierre de reto** (detectar fin → ganador → otorgar insignia +
  actualizar récord) y **revancha** (clonar reto con mismos miembros).
- Toca el **sistema de insignias**: categoría nueva `retos` en el dominio y en
  la whitelist de `firestore.rules` + definiciones por umbral + tests.

### 10.5 Decisiones (LOCKED — 2026-08-05, Carlos)
- **D8 — Revancha:** **banner opt-in al cierre** del reto (mismos rivales, 7
  días nuevos, un toque). Nadie queda obligado.
- **D9 — Marcador:** **v1 ligero** (retos jugados/ganados por usuario). El
  head-to-head rival-por-rival queda para fase posterior.
- **D10 — Insignias de reto (categoría `retos`):** entran las cuatro familias:
  *Primer reto* (participar), *Terminar un reto*, *Ganar* (1/3/10) y *Revancha*
  (encadenar N retos seguidos).
