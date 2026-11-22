# SPEC-305 — Fuentes científicas verificables (App Store, guía 1.4.1)

**Estado:** IMPLEMENTED (22-nov-2026) · pendiente de validar con `validar.sh` y en dispositivo
**Origen:** rechazo de App Review a Elena 1.0 (build 84), envío `78f0facb-d56f-48e1-9ba1-48b4edaa03e4`

## 1. Problema

App Review rechazó la 1.0 por la **guía 1.4.1 (Safety — Physical Harm)**:

> The app includes medical information but does not include citations for the medical information. Specifically, the app provides health or medical calculations in the BMI section without citations, such as links to sources for this information. Include citations in the app of the sources … such as links to those sources. The citations should be easy for the user to find.

Lo que encontramos en el código:

| Hallazgo | Por qué incumple |
|---|---|
| `url_launcher` estaba en el pubspec pero no había ni un solo `launchUrl` en `lib/` | Ninguna cita de la app tenía enlace |
| "BASE CIENTÍFICA" en Composición corporal: 10 pt, blanco al 35%, al final de una pantalla detrás del paywall | No es "fácil de encontrar" — el revisor no la vio |
| `FastingEligibility` bloquea o limita el ayuno con cortes de IMC (18.5 y 20) sin citar nada | Es exactamente "health calculations in the BMI section" |
| ~40 citas cortas en insights ("Walker 2017 + AASM") como texto gris sin enlace | Mismo problema, en todos los pilares |
| Citas no verificables o erróneas en texto visible | Ver §4 |

## 2. Objetivo

1. Toda cita visible lleva a una fuente con enlace estable (PubMed, DOI, OMS, DTIC o la editorial).
2. Cada pantalla con un cálculo de salud muestra sus fuentes ahí mismo, legibles.
3. Hay una pantalla única con todas las fuentes, a un toque desde Perfil.
4. Un test impide que vuelva a entrar una cita sin fuente.

## 3. Diseño

### Catálogo — `lib/src/features/science/domain/scientific_source.dart`
Única fuente de verdad: 40 referencias con autores, año, título, revista, URL, categoría y qué respaldan en la app. **Cada enlace se comprobó el 22-nov-2026** contra PubMed E-utilities (autor, año, título) o la página del editor. `resolve(cita)` traduce una cita corta a sus fuentes: separa por `+` y `·`, compara por palabra completa y usa el año para desambiguar (Spiegel 1999 ≠ Spiegel 2004).

### UI — `lib/src/features/science/presentation/`
- `SourcesFooter`: bloque "Fuentes científicas" bajo cada cálculo. Texto de 13,5 pt en color de acento y subrayado, un enlace por fuente y "Ver todas las fuentes de Elena".
- `CitationLink`: la cita corta de un insight pasa a ser un enlace que abre una hoja con sus fuentes. Si la cita no resuelve (p. ej. "Basado en tu progreso"), se pinta como texto normal: nunca un enlace que no lleva a nada.
- `ScientificSourcesScreen` (`/profile/fuentes`): todas las fuentes por pilar, con la línea "Respalda: …". Aclara que el IMR es un índice propio y que Elena no reemplaza al médico.
- Los enlaces se abren en SFSafariViewController (`LaunchMode.inAppBrowserView`), con el navegador externo como respaldo y un aviso si ninguno abre.

### Dónde aparece

| Pantalla | Qué se muestra |
|---|---|
| Perfil ▸ Ajustes ▸ **Fuentes científicas** | Pantalla completa (ruta que se indica a Apple) |
| Perfil ▸ Ayuda y legal | Misma pantalla |
| Composición corporal | `SourcesFooter` (Navy, Ashwell, Kouri, ACE) + "Ver fuentes científicas" **en el muro de pago**, para que un usuario gratuito también las vea |
| Datos biométricos | `SourcesFooter` del % de grasa + cita en la hoja "¿Por qué no puedo editar?" |
| Progreso ▸ Resultados / Score del día | `SourcesFooter` de composición y de los 5 pilares |
| Selector de protocolo, diálogo "Ayuno no recomendado", cribado médico del onboarding, Condiciones médicas | Fuentes del criterio de IMC (OMS 2000) y de contraindicaciones (de Cabo & Mattson 2019) |
| Onboarding — Tu cuerpo hoy | Cita de la fórmula US Navy |
| Glucosa | `SourcesFooter` del umbral de variabilidad (Monnier 2017) |
| Etapas de sueño, insights semanales de los 5 pilares, cierre de ciclo, historial, coaching, transformación, onboarding | Cada cita corta es un `CitationLink` |

## 4. Correcciones de contenido

| Antes | Después | Motivo |
|---|---|---|
| "Frank Suárez (Tipo A/E)" en 4 insights de alimentación | Jenkins 1981/2002, Liu 2000 | Marca registrada y sin revisión por pares; además violaba la decisión del proyecto de no citarlo en UI |
| "Sutton 2018 + Frank Suárez §3" | "Sutton 2018 + Jenkins 2002" | Igual |
| "Huberman 2021" (cafeína) | "Drake 2013" (J Clin Sleep Med) | Podcast, no publicación |
| "Biological Dial" (coaching y aviso de cierre de ventana) | Wright 2013 + Popkin 2010; Gu 2020 + Lopez-Minguez 2018 | Documento interno, no verificable. Se suaviza "destruye la calidad del sueño" a "empeora tu glucosa nocturna", que es lo que dicen los estudios |
| "Cahill, 1966 — NEJM" | "Cahill, 1966 — J Clin Invest" | Revista equivocada (PMID 5926444) |
| "Spiegel, 2009 — JCEM" (cena tarde) | "Gu et al., 2020 — JCEM" | No existe ese Spiegel 2009 en JCEM; Gu 2020 es el ensayo sobre la cena tardía |
| "AHA 2018" | "Piercy 2018" | La guía de actividad física de 2018 es Piercy et al., JAMA |
| "Rangos ACSM" (% de grasa) | "Rangos ACE" | Los umbrales usados (6-13 / 14-17 / 18-24 / ≥25) son las categorías del American Council on Exercise, no del ACSM |
| "Verificá / Asegurá" (insight de ejercicio) | "Cuida / Asegura" | Voseo que se había colado |

## 5. Blindaje (tests)

- `test/features/science/scientific_sources_catalog_test.dart`: ids únicos, https, dominios de una lista revisada, PMID concreto, campos no vacíos, términos normalizados, cada categoría con fuentes, y la resolución de citas (año, separadores, etiquetas que no son cita, citas prohibidas).
- `test/features/science/citation_coverage_test.dart`: barre **todo `lib/`** y falla si (1) un `citation:` tiene una parte sin fuente, (2) un "Autor AAAA" dentro de un texto visible no resuelve, (3) un texto visible usa un respaldo prohibido (Frank Suárez, NaturalSlim, Huberman, Biological Dial, Metabolic Clock), (4) alguna de las 11 pantallas de cálculo deja de mostrar sus fuentes o (5) Perfil pierde la fila "Fuentes científicas".
- `test/features/science/sources_widgets_test.dart`: tocar una fuente abre **su** URL; la cita corta abre una hoja con sus fuentes; una etiqueta que no es cita no se convierte en enlace; aviso si el enlace no abre; la pantalla completa lista todas las fuentes.
- Tests existentes actualizados: `meals_ratio_computer_test` (Jenkins en lugar de Frank Suárez) y `exercise_weekly_computer_test` (Piercy en lugar de AHA).

## 6. Respuesta para App Review

> We have added citations with direct links to the sources for every health calculation in the app. Each calculation (BMI-based fasting eligibility, body fat percentage, waist-to-height ratio, FFMI, daily score, glucose variability and sleep stages) now shows a "Fuentes científicas" (Scientific sources) section directly below it, with a tappable link to each source (PubMed, DOI, WHO). A complete list is available at Profile (Perfil) → Settings (Ajustes) → Fuentes científicas. Short citations inside coaching insights are also tappable and open their sources.

## 7. Pendiente / fuera de alcance

- "Walker 2017" (*Why We Sleep*) sigue como fuente: es divulgación, no un artículo revisado por pares. Conviene sustituirla gradualmente por Watson 2015 / Spiegel 1999 según la afirmación concreta.
- Las notificaciones push no pueden llevar enlaces; sus afirmaciones quedan cubiertas por la pantalla completa.
- No se tocaron los documentos internos de bibliografía (`docs/*_BIBLIOGRAPHY.md`).

## 8. Segunda vuelta (22-nov, tras la auditoría de riesgos)

- **Glucosa:** la app clasifica lecturas con los cortes de la ADA (ayunas 100/126, 2 h 140/200, baja <70) sin mostrar fuente — el mismo motivo del rechazo. Se añaden ADA 2025 cap. 2 (PMID 39651986) y cap. 6 (PMID 39651981) al catálogo, al bloque de fuentes de Glucosa, a la tarjeta de entrada y a la hoja de registro.
- **Blindaje ampliado:** `citation_coverage_test` ahora exige fuentes en TODA pantalla de `presentation/` que use un cálculo de salud (`GlucoseClassifier`, `FastingEligibility`, `BodyCompositionCalc`, `BodyFatCalculator`), no solo en una lista fija.
- **Retos oculto** (`kRetosEnabled = false`): tiene interacción entre usuarios sin reportar/bloquear (guía 1.2). Se quita el acceso, la ruta redirige a Progreso, no se registra el push de zumbidos y no se muestran sus insignias ni el texto de perlas que lo menciona.

## 9. Tercera vuelta (22-nov): enlaces que no abrían

Carlos abrió las fuentes en su iPhone y el enlace de DTIC mostró "Our Site is Getting an Upgrade". Se abrieron los 41 enlaces en un navegador real y se reemplazaron los que no cargaban de forma fiable:

| Antes | Problema | Ahora |
|---|---|---|
| Hodgdon & Beckett 1984 (DTIC, 2 informes) | Servidor en mantenimiento | Hodgdon 1992, NCBI Bookshelf (NIH) + Shake et al. 1993 (PubMed 8437737) |
| Carskadon & Dement 2011 (ScienceDirect) | Verificación anti-bots, capítulo de pago | Ohayon et al. 2004 (PubMed 15586779) |
| Walker 2017 (Open Library) | Verificación humana | Página oficial de la editorial (Simon & Schuster) |
| Lally 2010 (Wiley / CORE) | Controles de Cloudflare, no está en PubMed | Gardner, Lally & Wardle 2012 (PubMed 23211256) |
| Crofts 2015 (Diabesity) | Página llena de anuncios; el comentario del código citaba otro artículo | Petersen & Shulman 2018 (PubMed, ya en el catálogo) |
| EFSA 2010 vía doi.org | Paso intermedio de Wiley | Enlace directo al EFSA Journal |

El test del catálogo ahora prohíbe esos hosts (DTIC, Open Library, ScienceDirect, CORE, Diabesity).
