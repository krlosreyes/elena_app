# Launch Listings — App Store + Google Play (SPEC-94)

**Última actualización:** 14 de mayo de 2026

Documento operativo con el copy en español listo para pegar en las consolas oficiales. Sigue el orden de los formularios en App Store Connect y Google Play Console.

---

## 0. Identidad de la app

| Campo | Valor |
|---|---|
| Nombre comercial | Elena App |
| Tagline interna | Sistema de Alineación Biológica |
| Bundle ID iOS / applicationId Android | `com.metamorfosis.elena.elena_app` |
| Desarrollador / Publisher | Metamorfosis Real |
| Idioma primario MVP | Español (Latinoamérica) |
| Sitio web | https://metamorfosisreal.com/elena |
| Email de soporte | soporte@metamorfosisreal.com |
| Email de contacto legal | legal@metamorfosisreal.com |

---

## 1. App Store Connect (Apple)

### 1.1 App Information

**Nombre (App Name)** — máx. 30 char
```
Elena App
```

**Subtítulo (Subtitle)** — máx. 30 char
```
Tu salud metabólica real
```

**Categoría primaria**
```
Health & Fitness
```

**Categoría secundaria** (opcional)
```
Lifestyle
```

**Content Rights** (¿usa contenido de terceros?)
```
No
```

### 1.2 Pricing and Availability

```
Free
Disponible en todos los países donde Metamorfosis Real ya tiene base de usuarios
(empezar con: México, Colombia, Argentina, Chile, Perú, España, Estados Unidos)
```

### 1.3 App Privacy

**Privacy Policy URL**
```
https://metamorfosisreal.com/elena/privacy
```

**Privacy Choices URL** (opcional)
```
https://metamorfosisreal.com/elena/privacy#choices
```

### 1.4 Privacy Nutrition Label

Para cada categoría, marcar **Sí colectamos / Sí compartimos / Está vinculado al usuario**.

| Categoría | Colecta | Vinculado al usuario | Tracking | Propósito |
|---|---|---|---|---|
| Contact Info → Email Address | ✅ | ✅ | ❌ | App functionality, Account management |
| Health & Fitness → Health | ✅ | ✅ | ❌ | App functionality |
| Health & Fitness → Fitness | ✅ | ✅ | ❌ | App functionality |
| Identifiers → User ID | ✅ | ✅ | ❌ | App functionality, Analytics |
| Usage Data → Product Interaction | ✅ | ✅ | ❌ | Analytics |
| Diagnostics → Crash Data | ✅ | ❌ (anonimizado) | ❌ | App functionality |
| Diagnostics → Performance Data | ❌ | — | — | — |
| Location | ❌ | — | — | — |
| Financial Info | ❌ | — | — | — |
| Contacts | ❌ | — | — | — |
| Search History | ❌ | — | — | — |
| Browsing History | ❌ | — | — | — |
| Sensitive Info | ❌ | — | — | — |

**Notas para el formulario:**
- Health (Apple) cubre: peso, altura, %grasa, biometría general, condiciones declaradas, hábitos de ayuno/sueño/hidratación.
- Fitness (Apple) cubre: minutos de ejercicio, tipo de actividad.
- Crash Data va sin vincular al usuario porque SPEC-80 scrubea email/uid del payload antes de enviar a Crashlytics.

### 1.5 Descripción

**Promotional Text** — máx. 170 char (editable sin re-review)
```
Tu salud metabólica explicada en un solo número: el IMR. Basado en ciencia, sin pseudociencia. Para usuarios que ya entrenan con Metamorfosis Real.
```

**Descripción** — máx. 4000 char
```
Elena App es el compañero móvil del método Metamorfosis Real para optimizar tu salud metabólica desde cinco pilares verificables: ayuno, ejercicio, nutrición, sueño e hidratación.

▸ ¿QUÉ ES EL IMR?
El Indicador Metabólico Real (IMR) es una puntuación entre 0 y 100 que resume tu estado metabólico actual a partir de variables que tú aportas: edad, género, peso, estatura, circunferencias de cintura y cuello, hábitos de ayuno, sueño y ejercicio. La fórmula está construida sobre bibliografía revisada (Mattson 2017, Browning 2010, Kyle 2003) y se actualiza conforme registras tu día.

▸ ¿QUÉ HACE LA APP?
- Calcula tu IMR base al terminar el onboarding y lo actualiza cuando registras una comida, una sesión de ejercicio, agua o un episodio de ayuno.
- Te muestra tu cronograma circadiano: ventana de comida ideal, hora de despertar, hora de dormir, ayuno objetivo.
- Estima tu composición corporal (% grasa estimada con fórmula US Navy) sin pedirte que adivines: solo medidas objetivas.
- Te recomienda protocolos de ayuno (16:8, 18:6, 20:4) según tu perfil y patologías declaradas.
- Sincroniza con tu cuenta existente de metamorfosisreal.com — si ya eres parte de la comunidad, entras con el mismo email y contraseña.

▸ PARA QUIÉN ES (Y PARA QUIÉN NO)
Elena App está diseñada para adultos sanos que quieren entender y optimizar su metabolismo. No reemplaza una consulta médica. Antes de empezar mostramos un disclaimer clínico que enumera condiciones donde no debes seguir las recomendaciones de la app sin supervisión profesional: diabetes tipo 1, trastornos de la conducta alimentaria, embarazo o lactancia, insuficiencia renal, sarcopenia diagnosticada después de los 75 años.

▸ TU PRIVACIDAD
Tus datos viven en Firebase (Google Cloud) bajo nuestras reglas de seguridad. No vendemos información a terceros. Puedes solicitar la eliminación completa de tu cuenta desde el menú de perfil en cualquier momento. Los crashes que reportamos están anonimizados — el email y el identificador único nunca viajan en texto plano.

▸ REQUISITOS
- iOS 14 o superior.
- Cuenta de Metamorfosis Real (gratis crear desde la app o el sitio web).

Elena App es una herramienta de educación y seguimiento, no un dispositivo médico. Para condiciones específicas, consulta a tu profesional de la salud.
```

**Palabras clave (Keywords)** — máx. 100 char total, separadas por coma
```
metabolismo,ayuno,salud,fitness,nutrición,IMR,grasa corporal,circadiano,metamorfosis,bienestar
```
(99 caracteres incluyendo comas)

**Support URL**
```
https://metamorfosisreal.com/elena/support
```

**Marketing URL** (opcional)
```
https://metamorfosisreal.com/elena
```

### 1.6 Age Rating

Responder al cuestionario:

| Pregunta | Respuesta |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | **Infrequent/Mild** |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Unrestricted Web Access | No |
| Gambling and Contests | No |

**Resultado esperado:** 4+

**Justificación de "Medical/Treatment Information: Infrequent/Mild":** la app muestra disclaimer clínico al inicio + contraindicaciones documentadas. No prescribe ni diagnostica. Es educacional/de seguimiento.

### 1.7 App Review Information

**First Name / Last Name** — datos reales del contacto técnico.

**Phone / Email** — datos del contacto técnico que responde durante review.

**Demo Account** — REQUERIDO. Crear una cuenta de prueba con onboarding completo:
```
Email: demo-applereview@metamorfosisreal.com
Password: (generar uno temporal y rotarlo después del review)
```

**Notes** — texto libre para el reviewer:
```
Elena App es la app móvil del método Metamorfosis Real (metamorfosisreal.com).
Permite a usuarios registrados en el sitio web ingresar con sus credenciales para hacer seguimiento metabólico desde 5 pilares (ayuno, ejercicio, nutrición, sueño, hidratación).

Cuenta demo:
- Email: demo-applereview@metamorfosisreal.com
- Password: (ver campo Demo Account)
- Esta cuenta tiene el onboarding completo y datos sintéticos.

Para probar el onboarding desde cero, pueden registrar un nuevo email.
No requiere ningún hardware externo ni HealthKit (V2).

La app muestra un disclaimer clínico obligatorio antes del onboarding que enumera condiciones donde no se debe usar sin supervisión médica. Esto está documentado en la sección "Privacy & Health Disclaimer" de la política de privacidad.
```

---

## 2. Google Play Console (Android)

### 2.1 Store listing

**App name** — máx. 30 char
```
Elena App
```

**Short description** — máx. 80 char
```
Tu salud metabólica explicada en un número. Basada en ciencia, no en moda.
```
(74 caracteres)

**Full description** — máx. 4000 char
```
Elena App es la app móvil del método Metamorfosis Real para optimizar tu salud metabólica desde cinco pilares verificables: ayuno, ejercicio, nutrición, sueño e hidratación.

▸ ¿Qué es el IMR?
El Indicador Metabólico Real (IMR) es una puntuación entre 0 y 100 que resume tu estado metabólico actual. Se calcula a partir de medidas objetivas que tú aportas — edad, género, peso, estatura, circunferencias de cintura y cuello, hábitos de ayuno, sueño y ejercicio — usando una fórmula construida sobre bibliografía revisada (Mattson 2017, Browning 2010, Kyle 2003).

▸ ¿Qué hace la app?
• Calcula tu IMR base al terminar el onboarding.
• Actualiza el IMR cuando registras una comida, ejercicio, agua o cierras un ayuno.
• Te muestra tu cronograma circadiano: ventana de comida, despertar, dormir, ayuno objetivo.
• Estima tu composición corporal con la fórmula US Navy — sin pedirte que adivines tu % grasa.
• Te recomienda protocolos de ayuno (16:8, 18:6, 20:4) según tu perfil y patologías declaradas.
• Sincroniza con tu cuenta de metamorfosisreal.com — si ya eres parte de la comunidad, entras con el mismo email.

▸ Para quién es (y para quién no)
Elena App está diseñada para adultos sanos que quieren entender y optimizar su metabolismo. No reemplaza una consulta médica. Antes de empezar te mostramos un disclaimer clínico que enumera condiciones donde no debes seguir las recomendaciones sin supervisión profesional: diabetes tipo 1, trastornos de conducta alimentaria, embarazo o lactancia, insuficiencia renal, sarcopenia diagnosticada >75 años.

▸ Tu privacidad
Tus datos viven en Firebase (Google Cloud) bajo reglas de seguridad estrictas. No vendemos información a terceros. Puedes eliminar tu cuenta completa desde el menú de perfil en cualquier momento. Los reportes de errores están anonimizados — tu email y tu identificador nunca viajan en texto plano.

▸ Requisitos
• Android 8.0 (API 26) o superior.
• Cuenta de Metamorfosis Real (gratis crearla desde la app o el sitio web).

Elena App es una herramienta de educación y seguimiento, no un dispositivo médico. Para condiciones específicas, consulta a tu profesional de la salud.
```

**App icon** — 512×512 PNG, sin transparencia.

**Feature graphic** — 1024×500 PNG.

**Phone screenshots** — entre 2 y 8, mínimo 320 px de lado corto. Recomendado 1080×2400 px.

**Video promocional** (opcional) — link a YouTube.

### 2.2 Categorization

**App category**
```
Health & Fitness
```

**Tags** — hasta 5
```
Health, Fitness, Lifestyle, Tracker, Wellness
```

### 2.3 Contact details

```
Email: soporte@metamorfosisreal.com
Phone: (opcional, dejar vacío si no quieres exponer un número)
Website: https://metamorfosisreal.com/elena
```

### 2.4 Privacy policy

```
URL: https://metamorfosisreal.com/elena/privacy
```

### 2.5 Data safety

Para el formulario de Google, marcar lo siguiente:

**¿La app recopila o comparte alguno de los tipos de datos del usuario requeridos?**
```
Sí
```

**¿Todos los datos del usuario recopilados por la app están cifrados en tránsito?**
```
Sí (Firebase usa TLS 1.2+ por defecto)
```

**¿Proporciona a los usuarios una forma de solicitar la eliminación de sus datos?**
```
Sí (botón "Eliminar cuenta" en el perfil)
```

**Tipos de datos colectados:**

| Categoría | Tipo de dato | Recopilado | Compartido | Propósito | Obligatorio |
|---|---|---|---|---|---|
| Personal info | Email address | ✅ | ❌ | Account management, App functionality | Sí |
| Personal info | User IDs | ✅ | ❌ | Account management, Analytics | Sí |
| Personal info | Name | ✅ | ❌ | App functionality | Opcional |
| Health and fitness | Health info | ✅ | ❌ | App functionality | Sí |
| Health and fitness | Fitness info | ✅ | ❌ | App functionality | Sí |
| App activity | App interactions | ✅ | ❌ | Analytics, App functionality | Opcional |
| App info and performance | Crash logs | ✅ | ❌ | Analytics, App functionality | Sí |
| App info and performance | Diagnostics | ❌ | — | — | — |

**Información sobre seguridad de datos** (texto público):
```
Tus datos se almacenan en servidores de Firebase (Google Cloud), cifrados en tránsito y en reposo. La app no comparte datos con terceros con fines comerciales. Los reportes de errores se anonimizan antes de enviarse — emails e identificadores únicos se sustituyen por placeholders.
```

### 2.6 Content rating

Cuestionario IARC:

| Pregunta | Respuesta |
|---|---|
| ¿La app contiene violencia? | No |
| ¿Contenido sexual? | No |
| ¿Lenguaje vulgar? | No |
| ¿Drogas, alcohol o tabaco? | No |
| ¿Apuestas? | No |
| ¿Genera/comparte ubicación del usuario? | No |
| ¿Permite interacción entre usuarios? | No |
| ¿Información médica? | Sí (la app calcula indicadores de salud y muestra recomendaciones genéricas) |

**Resultado esperado:** Everyone (E) / PEGI 3 / USK 0.

### 2.7 Target audience and content

```
Edades objetivo: 18 y mayores
La app NO está dirigida a niños.
```

### 2.8 News app declaration

```
No, esta app no es una app de noticias.
```

### 2.9 COVID-19 contact tracing

```
No
```

### 2.10 Government app declaration

```
No
```

---

## 3. Checklist de assets visuales

- [ ] Icono cuadrado 1024×1024 (Apple) — sin transparencia, sin pre-redondeo
- [ ] Icono cuadrado 512×512 (Google) — PNG con o sin transparencia
- [ ] 5 screenshots iPhone 6.7" (1290×2796 px): Onboarding paso 1, Dashboard con IMR, Pantalla de ayuno, Pantalla de protocolo, Perfil
- [ ] 5 screenshots Android (1080×2400 px): mismos que iPhone, adaptados
- [ ] Feature graphic Android 1024×500 px (logo + tagline "Tu salud metabólica real")
- [ ] App Preview Video iPhone (opcional MVP, 15-30 segundos)
- [ ] Promo video YouTube Android (opcional MVP)

**Tips de captura:**
- Usar Demo Account con datos completos antes de capturar.
- Tomar las pantallas con el simulator/emulator (no con tu device personal — el status bar puede tener notificaciones que arruinan la captura).
- iOS: `xcrun simctl io booted screenshot screenshot.png` desde el terminal con el simulator abierto.
- Android: en el emulator, ⌘+S guarda screenshot directamente.

---

## 4. URLs requeridas — coordinación con equipo web

Antes de hacer submit, las 4 URLs deben responder 200 y mostrar contenido coherente con la app:

| URL | Contenido | Origen |
|---|---|---|
| `https://metamorfosisreal.com/elena/privacy` | Política de privacidad publicada | Convertir `lib/src/features/auth/domain/legal_text.dart` (kPrivacyPolicy) a HTML |
| `https://metamorfosisreal.com/elena/terms` | Términos de servicio | Convertir `lib/src/features/auth/domain/legal_text.dart` (kTermsOfService) a HTML |
| `https://metamorfosisreal.com/elena/support` | Formulario o email de soporte | Página simple con `soporte@metamorfosisreal.com` y FAQ básica |
| `https://metamorfosisreal.com/elena` | Landing/marketing | Página simple con tagline, screenshots, badges de App Store y Google Play |

**Recordatorio SPEC-78 (deep links):** además necesitan estar publicados:
- `https://metamorfosisreal.com/.well-known/assetlinks.json`
- `https://metamorfosisreal.com/.well-known/apple-app-site-association`

Ver `docs/DEEP_LINKS_SETUP.md` para el contenido exacto de los `.well-known/`.

---

## 5. Orden recomendado de submission

1. Coordinar con equipo web las 4 URLs + los 2 `.well-known/` (puede tomar 1-3 días).
2. Generar todos los assets visuales (iconos + 10 screenshots + feature graphic). 1 día con diseñador.
3. Construir build release Android (`flutter build appbundle --release`) y subir a Google Play Console → Internal testing track primero.
4. Construir build release iOS (`flutter build ipa --release`) y subir a App Store Connect → TestFlight primero.
5. Probar con 3-5 testers en TestFlight + Internal Testing por 48 horas.
6. Solo cuando los testers den OK, pegar todo el copy de este doc en ambas consolas.
7. Submit a review.
   - Apple: 24-72 horas típicas para Health & Fitness con disclaimer.
   - Google: 2-12 horas típicas.
8. Si ambas aprueban → publicar simultáneamente.
9. Email a base MR anunciando con los links de descarga.

---

## 6. Post-launch — primeras 2 semanas

- Triage diario de Crashlytics (Firebase Console). Cualquier crash con >5 instancias → SPEC reactivo.
- Revisar primeras 10 reviews de cada tienda para detectar bugs o confusiones de UX no anticipadas.
- Monitorear el panel App Check en Firebase Console: si los Verified counts no suben, hay problema con reCAPTCHA en web o con Play Integrity / App Attest en mobile.
- Si Apple o Google piden cambios en review, redactar respuesta dentro de las primeras 24 horas (los reviewers cierran tickets viejos sin respuesta).
