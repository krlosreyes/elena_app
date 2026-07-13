# SPEC-205 — Feed de artículos personalizado ("Para ti")

**Estado:** IMPLEMENTED (2026-06-11) — inc1 datos + inc2 matching + inc3 UI/lector + inc4 quiz/engagement (vistas + lecturas). Render con `MarkdownLite` propio (sin dependencia `flutter_markdown`; tablas en texto plano). Pendiente: validación en device + desplegar índice Firestore.
**Versión:** 0.1 (draft)
**Tipo:** Engagement / contenido — reemplaza el valor débil de "Tus tendencias" (SPEC-201) por contenido educativo emparejado al estado del usuario.
**Líder:** Carlos
**Implementación:** Claude
**Depende de:** SPEC-201 (motor de observaciones — se reutiliza para elegir el pilar relevante), colección Firestore `metamorfosis_posts` (ya poblada).
**Bloquea:** que el espacio de la pantalla Análisis aporte valor real (educación accionable) en vez de estadísticas auto-evidentes.

---

## 1. Contexto y problema

La sección **"Tus tendencias"** (SPEC-201, `ObservationDetector`) muestra observaciones auto-referenciales del tipo *"Tu hidratación esta semana está por encima de tu promedio. 4.0L vs 2.4L."* Carlos (2026-06-11): **no aporta** — le dice al usuario un número que ya sabía, sin insight nuevo ni acción significativa.

Diagnóstico: son descripciones aisladas de una métrica vs su propio promedio. No conectan el dato con un *"y entonces qué hago"* ni con la fundamentación científica de la marca.

Referentes (investigación 2026): las mejores secciones de insight no celebran logros ni repiten cifras — conectan el dato del usuario con **contenido accionable**. Levels conecta un bajón de energía con un pico de glucosa y un artículo que lo explica; el cambio de conducta viene del *feedback loop con guía*, no del dato crudo.

**Oportunidad descubierta:** la colección `metamorfosis_posts` ya trae artículos científicos completos, con imagen, tag de pilar, referencias y quiz. Es la materia prima ideal para convertir ese espacio en un **feed de aprendizaje personalizado**.

---

## 2. Decisión de producto (aprobada)

> El espacio pasa a **"Para ti"**: combina **1 observación de dato fuerte** + **artículos emparejados al estado del usuario**, con lector in-app y quiz.

- **Combinar, no reemplazar del todo**: se conserva la mejor observación de dato arriba (línea de contexto: *"Tu ejercicio viene bajo esta semana"*), y debajo el artículo del pilar correspondiente (*"Esto te puede ayudar →"*).
- **v1 completa**: tarjetas + lector in-app del `content` (Markdown) + referencias + **quiz** al final.
- **Pilares**: `ayuno` / `sueno` / `hidratacion` / `ejercicio` / `nutricion` (confirmado por Carlos que el campo `pillar` usa estos strings).

---

## 3. Modelo de datos — colección `metamorfosis_posts`

Documento real (confirmado 2026-06-11):

| Campo | Tipo | Uso en la app |
|---|---|---|
| `title` | string | Título de la tarjeta y del lector. |
| `slug` | string | Identificador legible / deep-link futuro. |
| `pillar` | string | **Clave de matching** (`ayuno`/`sueno`/`hidratacion`/`ejercicio`/`nutricion`). |
| `content` | string (Markdown) | Cuerpo del artículo, se renderiza in-app. |
| `images` | array<string> | `images[0]` = miniatura (Firebase Storage). |
| `references` | array<string> | Citas científicas → sello "con respaldo científico" + pie del lector. |
| `quiz` | array<map> | `{ question, options[], correctAnswer:int }` → "Pon a prueba lo que aprendiste". |
| `status` | string | Filtrar `== "published"`. |
| `publishedAt` | string (ISO) | Orden descendente + fallback "recientes". |
| `createdAt` / `updatedAt` | string (ISO) | Auditoría (no se muestra). |
| `analytics` | map | `{ views, clicks, conversions }` (int) → se incrementa al abrir. |
| `metadata` | map | `{ slug, title }` (redundante con campos top-level). |

**Modelo Dart `Post`** (dominio): `id, title, slug, pillar (enum PillarTag), contentMarkdown, imageUrl (images.firstOrNull), references<String>, quiz<QuizQuestion>, publishedAt (DateTime), status`. Parser tolerante (campos opcionales → defaults; `pillar` desconocido → `PillarTag.general`).

`QuizQuestion`: `{ question, options<String>, correctIndex }`.

> **Nota:** ningún campo nuevo en Firestore es necesario para v1. El editorial ya tagea `pillar`.

---

## 4. Arquitectura

### 4.1 Repositorio — `PostRepository`
- `Future<List<Post>> fetchPublished({int limit = 30})`: `collection('metamorfosis_posts').where('status','==','published').orderBy('publishedAt', descending:true).limit(limit)`.
- **Caché**: persistir el último fetch (SharedPreferences/JSON o caché de Firestore) para verse **offline**. TTL suave (ej. 6h) — refresca en background, sirve caché al instante.
- **Índice Firestore**: compuesto `status (==) + publishedAt (desc)`. Agregar a `firestore.indexes.json` (checklist SPEC-145 §3.4) **antes** de mergear.

### 4.2 Selección personalizada — `personalizedFeedProvider`
Reutiliza el motor de SPEC-201 para no duplicar lógica:
1. `ObservationDetector.detect(...)` → toma la observación más fuerte y su `pillar` objetivo (el pilar "débil"/relevante).
2. **Para ti**: el post más reciente de ese `pillar` que el usuario **no haya leído**.
3. **Recientes**: 2 posts adicionales, diversificando pilar (excluir el ya elegido y los leídos). Fallback a los más recientes si no hay señal de datos (período de calentamiento / pocos días).
4. Si no hay observación fuerte → 3 posts recientes sin línea de contexto.

Salida: `PersonalizedFeed { Observation? context, Post? forYou, List<Post> more }`.

### 4.3 Tracking de lectura — por usuario
- `users/{uid}/post_reads/{postId}` (o un set `readPostIds` en el doc de usuario) con `readAt`. Evita repetir y afina la personalización.
- Al abrir un post: marcar leído + incrementar `analytics.views` (FieldValue.increment(1)) en el doc del post. `analytics.clicks` en el tap de la tarjeta.

---

## 5. UI

### 5.1 Sección "Para ti" (pantalla Análisis, reemplaza "Tus tendencias")
- **Header**: "Para ti".
- **Línea de contexto** (si hay observación): texto corto del dato fuerte + microcopy *"Esto te puede ayudar"*.
- **Tarjeta destacada (forYou)**: miniatura `images[0]`, título, **chip del pilar**, tiempo de lectura estimado (≈ `wordCount(content)/200` min), sello *"🔬 con respaldo científico"* si `references` no está vacío.
- **2 tarjetas "Recientes"**: versión compacta (miniatura + título + chip).
- **Estados**: cargando (skeleton), vacío/sin red (mensaje digno + miniaturas de caché si existen).

### 5.2 Lector in-app — `PostReaderScreen`
- Imagen de portada (`images[0]`), título, chip de pilar, tiempo de lectura.
- `content` renderizado en **Markdown** (tablas, blockquotes, listas, ✅/❌). Requiere `flutter_markdown` (o equivalente) — confirmar dependencia.
- **Referencias** al pie en bloque "Fuentes".
- **Quiz** al final: card "Pon a prueba lo que aprendiste" → preguntas de `quiz`, feedback inmediato (correcto/incorrecto vs `correctAnswer`), microcelebración al completar. (Opcional v1.1: registrar resultado del quiz para gamificación/IMR — fuera de alcance v1.)

---

## 6. Por qué aporta valor (vs SPEC-201 solo)

- Pasa de *"4L vs 2.4L"* (auto-evidente) a *"tu problema de hoy + el contenido que lo resuelve"*.
- Respaldo científico visible (`references`) → refuerza "fundamentos científicos y verificables".
- Quiz → aprendizaje activo y engagement, no consumo pasivo.
- Reutiliza contenido editorial ya producido y el motor de observaciones ya existente.

---

## 7. Plan incremental

1. **inc1 — Datos**: `Post`/`QuizQuestion` models + `PostRepository` (fetch published + caché offline) + índice Firestore + tests de parser/repo (con fakes).
2. **inc2 — Selección**: `personalizedFeedProvider` (matching por pilar reusando `ObservationDetector`, dedup de leídos, fallback). Tests de matching.
3. **inc3 — UI feed**: sección "Para ti" en Análisis reemplazando "Tus tendencias" + estados loading/empty/offline.
4. **inc4 — Lector + quiz**: `PostReaderScreen` (Markdown + referencias + quiz) + tracking de lectura + increment de `analytics`.

---

## 8. Tests
- Parser `Post.fromMap` con doc real (campos faltantes, `pillar` desconocido, `images` vacío, `quiz` vacío).
- `personalizedFeedProvider`: elige el pilar de la observación más fuerte; excluye leídos; fallback a recientes sin señal.
- Tiempo de lectura: cálculo determinístico.
- Quiz: marca correcto/incorrecto según `correctAnswer`.
- Robustez: sin red → sirve caché; sin posts → estado vacío.

---

## 9. Pendientes / a confirmar
- Dependencia de render Markdown (`flutter_markdown` u otra) — aprobar antes de inc4.
- ¿Cuántos docs hay en `metamorfosis_posts`? Si crece mucho, paginar el fetch.
- ¿Todos los pilares tienen al menos 1 post publicado? Si falta alguno, el matching cae a "recientes" para ese pilar (degradación correcta).
- ¿El resultado del quiz alimenta IMR/gamificación? → diferido a v1.1.

---

## 10. Fix: imágenes de artículos no cargaban (2026-07-13)

**Síntoma reportado por Carlos** (screenshot): en "Para ti" (Dashboard) todos los artículos mostraban el emoji del pilar (💧 Hidratación, 🥦 Nutrición) en vez de la imagen real, tanto en la tarjeta destacada como en las compactas.

**Mecanismo confirmado por lectura de código:** `_Thumb` (`post_card.dart`) y la portada de `PostReaderScreen` usan `Image.network(url, errorBuilder: (...) => placeholder)`. Ese `errorBuilder` se traga CUALQUIER fallo de carga (URL inválida, 403, esquema no-http, etc.) sin loguear nada — el síntoma es indistinguible entre "no hay imagen" y "la imagen falló al cargar".

**Causa raíz más probable (no verificable desde el sandbox, sin acceso a Firestore/Storage de producción):** el doc real de ejemplo (`post_test.dart`, capturado 2026-06-11) guarda `images[0]` como `https://storage.googleapis.com/<bucket>/<ruta>` — la URL directa de la API de Cloud Storage, que requiere que el objeto/bucket tenga lectura pública (IAM `allUsers`) para que un `GET` anónimo (como el que hace `Image.network`, sin el SDK de Firebase Storage — la app no tiene `firebase_storage` como dependencia) funcione. Dos escenarios posibles, ambos con el mismo síntoma (fallo del 100% de las imágenes, no algunas):
1. El editorial guarda la referencia `gs://bucket/ruta` (formato interno del SDK de Storage) en vez de una URL http — `Image.network` ni siquiera puede intentar un request válido con ese esquema.
2. El bucket/objeto de Storage no tiene lectura pública habilitada, y el `GET` anónimo devuelve 403.

**Fix aplicado (código, este repo):**
- `Post.fromMap` ahora tolera `images[]` con Maps (`{url:...}`/`{src:...}`/`{downloadUrl:...}`) además de strings planos — un Map ahí antes producía `.toString()` → `"Instance of '_Map'"`, una URL inválida garantizada.
- `Post.fromMap` normaliza automáticamente `gs://bucket/ruta` al endpoint público de descarga `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<ruta-encoded>?alt=media`, que si el bucket tiene Storage Security Rules de lectura pública para esa ruta, sí es fetcheable por `Image.network`.
- `_Thumb` (post_card.dart) y la portada de `PostReaderScreen` ahora loguean vía `AppLogger.warning` (llega a Crashlytics en release) la URL exacta que falló, en vez de tragarse el error — así un fallo futuro es diagnosticable en vez de invisible para siempre detrás del placeholder.

**Lo que el código NO puede resolver, pendiente de verificación por Carlos:**
- Si el escenario real es "bucket/objeto sin lectura pública" (no `gs://` sino ya una URL https que igual da 403), el fix de normalización no alcanza — hay que revisar las Storage Security Rules del proyecto en Firebase Console (`allow read: if true` para la ruta de `posts/`, o equivalente) y/o el ACL del bucket. Este repo no tiene `storage.rules` versionado, así que esa config vive solo en consola.
- Confirmar en Firestore (`metamorfosis_posts`) qué shape tiene `images[]` realmente en producción hoy, para saber cuál de los dos escenarios aplica.

**Why:** Carlos pidió una "corrección completa para que no se pierda la imagen original del artículo" — el código ahora es robusto ante los 2 shapes de datos rotos más probables Y hace visible cualquier fallo restante (antes invisible), pero la causa raíz final depende de una config de infraestructura (Storage) que no es auditable desde el sandbox.

**How to apply:** si el bug persiste después de este fix, el primer paso es mirar los logs/Crashlytics por el mensaje `"Imagen de artículo no cargó"` — va a traer la URL exacta que falló, lo que dice de inmediato si es un problema de shape de dato o de permisos de Storage.
