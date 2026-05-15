# SPEC-94 — Listings para App Store y Google Play

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Submission pre-launch (operativo + redacción de copy)
**Marco normativo:** Apple App Store Review Guidelines (esp. §5.1.1 privacy, §5.2.1 intellectual property), Google Play Developer Policy (data safety, health & fitness category).

---

# 1. Contexto

El código del MVP está listo para release (Sprint 5 cerrado). Para subir el build a las dos tiendas necesitamos preparar el **listing**: textos descriptivos, palabras clave, iconos, screenshots, disclosures de privacidad, categorías, age rating, URLs de soporte y políticas.

Este SPEC entrega:
1. Un documento operativo (`docs/LAUNCH_LISTINGS.md`) con el copy en español, listo para pegar en App Store Connect y Google Play Console.
2. Una checklist de assets visuales que Carlos debe generar/encargar (iconos en 1024×1024, screenshots por device, feature graphic Android, etc.).
3. Disclosures de privacidad alineadas con lo que la app realmente colecta y trata, consistentes con `legal_text.dart` (Privacy Policy in-app).

# 2. Problema

Sin un listing redactado y coherente:
- Carlos puede inventar copy on-the-fly al subir y generar inconsistencia entre tiendas (mismas palabras clave, mismo posicionamiento).
- Los disclosures de privacidad pueden quedar incompletos o exagerados (riesgo de rechazo en review).
- Los screenshots pueden no respetar las dimensiones exactas que Apple/Google exigen (rechazo automático).
- El age rating puede quedar mal (Health & Fitness con disclaimers clínicos suele ser **4+** Apple / **Everyone** Google, pero hay que justificarlo).

# 3. Solución propuesta

**3.1 Documento operativo `docs/LAUNCH_LISTINGS.md`** con secciones:

- Identidad de la app (nombre comercial, subtítulo, bundle IDs).
- Copy App Store: subtítulo (30 char), promotional text (170 char), descripción (4000 char), palabras clave (100 char), URL marketing, URL soporte, URL privacidad.
- Copy Google Play: título (30 char), descripción corta (80 char), descripción larga (4000 char), categoría, contenido para padres.
- Categorías Apple: Health & Fitness (primaria), Medical (secundaria opcional).
- Categoría Google: Health & Fitness.
- Age rating: justificación y respuestas al cuestionario IARC.
- Disclosures de privacidad (Privacy Nutrition Label Apple + Data Safety Google) alineadas con `legal_text.dart`.
- URLs externas requeridas + cómo servirlas (Firebase Hosting de metamorfosisreal.com con páginas estáticas).

**3.2 Checklist de assets visuales**:

- App icon 1024×1024 (sin transparencia, sin redondeo — Apple lo aplica).
- Screenshots iPhone 6.7" (iPhone 14/15 Pro Max): mínimo 3, máximo 10. 1290×2796 px.
- Screenshots iPhone 6.5" (iPhone 11 Pro Max): 1242×2688 px.
- Screenshots iPad 12.9" si soporta iPad (opcional MVP).
- Screenshots Android phone: 2-8 capturas, mínimo 1080×1920 px.
- Feature graphic Android: 1024×500 px sin texto importante.
- App icon Android: 512×512 PNG.

**3.3 Disclosures de privacidad** alineadas:

- **Sí colectamos**: email (auth), uid Firebase, datos biométricos (peso, altura, cintura, cuello, %grasa derivado), hábitos (ayuno, ejercicio, sueño, hidratación), edad, género.
- **No colectamos**: ubicación, fotos, contactos, micrófono, datos financieros, historial de navegación.
- **Compartimos con terceros**: Firebase (Google) como backend de auth/firestore/crashlytics. Sin venta de datos.
- **Datos sensibles de salud**: Sí — flag obligatorio en ambas tiendas. La app trabaja con datos biométricos.

**3.4 URLs externas**:

- `https://metamorfosisreal.com/elena/privacy` — política de privacidad publicada (la misma de `legal_text.dart` formateada como HTML).
- `https://metamorfosisreal.com/elena/terms` — términos de servicio.
- `https://metamorfosisreal.com/elena/support` — formulario o email de soporte.
- `https://metamorfosisreal.com/elena` — landing/marketing.

Coordinar con equipo web para servirlas.

# 4. Plan

| # | Acción | Owner | Entregable |
|---|---|---|---|
| 1 | Redactar `docs/LAUNCH_LISTINGS.md` con copy en español | Claude | Archivo md |
| 2 | Generar iconos 1024×1024 desde el logo actual | Diseño/Carlos | PNG |
| 3 | Capturar 5 screenshots clave en iPhone 6.7" simulator | Carlos | 5 PNG 1290×2796 |
| 4 | Capturar 5 screenshots Android en Pixel 6 emulator | Carlos | 5 PNG 1080×2400 |
| 5 | Crear feature graphic Android 1024×500 | Diseño | PNG |
| 6 | Coordinar con equipo web las 4 URLs de privacidad/términos/soporte/marketing | Carlos + equipo MR | Páginas en vivo |
| 7 | Crear app en App Store Connect | Carlos | App registrada |
| 8 | Crear app en Google Play Console | Carlos | App registrada |
| 9 | Pegar copy + assets + disclosures en ambas consolas | Carlos | Listings completos |
| 10 | Submit a review | Carlos | App en review |

Paso 1 es el único codeable inmediato. El resto son tareas operativas que Carlos ejecuta en paralelo con apoyo externo.

# 5. Criterios de aceptación

1. `docs/LAUNCH_LISTINGS.md` cubre TODAS las secciones de copy obligatorias en ambas consolas.
2. El copy en español no excede los límites de caracteres de cada campo.
3. Los disclosures de privacidad son **estrictamente consistentes** con `legal_text.dart` (no prometen menos ni más de lo que está documentado in-app).
4. La categoría primaria queda como "Health & Fitness" en ambas tiendas con justificación de por qué NO es "Medical" (importante: Apple es muy estricto con "Medical" — solo aplica para apps que diagnostican).
5. El age rating queda en 4+ (Apple) y Everyone (Google) con justificación en el doc.

# 6. Pruebas

Operativo: no hay tests automatizables. Verificación = revisión manual del doc + pre-flight en consolas (App Store Connect tiene preview antes de submit).

# 7. Riesgos

**7.1 Rechazo por Apple §5.1.1 (privacy disclosures incompletas).**
Mitigación: cada categoría de la Privacy Nutrition Label está en el doc con respuesta exacta. Coincide 1-a-1 con lo que `Firestore` realmente guarda.

**7.2 Rechazo por Google data safety incompleta.**
Mitigación: igual que arriba pero con la taxonomía de Google (más granular). El doc incluye ambas.

**7.3 Rechazo por contenido médico no acreditado.**
Mitigación: la categoría es Health & Fitness, NO Medical. El copy evita términos como "diagnóstico", "tratamiento", "cura". Usa "indicador", "estimación", "guía". El disclaimer in-app (SPEC-76) refuerza esto.

**7.4 URLs de privacidad caídas el día del review.**
Mitigación: Carlos verifica que las 4 URLs respondan 200 antes de hacer submit.

**7.5 Copy en inglés.**
Apple permite localización por idioma. MVP arranca solo en español (audiencia hispana MR). El doc tiene placeholder para inglés si se quiere expandir en V2.

# 8. Out of scope

- Marketing pago (campañas, ads).
- Diseño gráfico del icono o screenshots — el doc lista requirements, no diseña.
- Implementación de las páginas web de privacy/terms/support (equipo web).
- A/B testing de copy.
- Localización a otros idiomas (V2).

# 9. Resultado

(Se completa al cerrar el SPEC.)
