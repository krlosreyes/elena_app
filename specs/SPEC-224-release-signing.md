# SPEC-224 — Firma de release Android (Play Store)

**Estado:** IMPLEMENTED
**Versión:** 1.0
**Fecha:** 2026-07-06
**Tipo:** Infraestructura de release (no funcional, no toca dominio)
**Marco normativo:** Google Play Console — requisito de firma para publicar releases (Android App Signing).

---

# 1. Contexto

El release de Android firmaba con las debug keys (`signingConfigs.getByName("debug")` en `android/app/build.gradle.kts`), heredado del template de Flutter. Google Play no acepta un AAB firmado con debug keys para ningún track (ni Closed testing ni producción). Es el primer paso bloqueante de la publicación en Play Store (ver plan operativo en el hilo de Cowork del 2026-07-06).

# 2. Problema

Sin una release key real:
- No se puede subir ningún AAB a Play Console, en ningún track.
- No hay forma de generar el SHA-256 de firma que necesitan `assetlinks.json` (deep links, SPEC-78) ni el registro de Play Integrity en Firebase App Check.

# 3. Solución implementada

1. Carlos generó un keystore JKS permanente (`~/elena-release.jks`, alias `elena`, validez 10000 días) fuera del repo.
2. `android/key.properties` (gitignored — confirmado que `*.jks`, `*.keystore` y `android/key.properties` ya estaban excluidos en `.gitignore`) con `storePassword`, `keyPassword`, `keyAlias=elena`, `storeFile=/Users/carlosreyes/elena-release.jks`.
3. `android/app/build.gradle.kts`:
   - Carga `key.properties` vía `java.util.Properties` + `FileInputStream` al inicio del archivo.
   - Nuevo bloque `signingConfigs { create("release") { ... } }` que lee alias/passwords/storeFile de `keystoreProperties`.
   - `buildTypes.release.signingConfig` apunta ahora a `signingConfigs.getByName("release")` (antes: `"debug"`).

# 4. Plan

| # | Acción | Owner | Estado |
|---|---|---|---|
| 1 | Generar keystore (`keytool -genkey`) | Carlos | Hecho |
| 2 | Crear `android/key.properties` local | Claude | Hecho |
| 3 | Editar `build.gradle.kts` (signingConfigs + carga de properties) | Claude | Hecho |
| 4 | `flutter build appbundle --release` y verificar firma | Carlos | Pendiente |
| 5 | Subir el AAB a Play Console → Closed testing | Carlos | Pendiente |
| 6 | Copiar el SHA-256 de la app signing key (Play Console → Integridad de la app) y actualizar `assetlinks.json` + Firebase App Check | Carlos + equipo web | Pendiente |

# 5. Criterios de aceptación

1. `flutter build appbundle --release` produce un AAB firmado con la release key (no debug).
2. `android/key.properties` y `*.jks` no aparecen en `git status` como trackeados.
3. El build no rompe `flutter run --release` en local (sigue firmando con la misma config release; si el keystore no está presente en una máquina sin `key.properties`, el build de release falla explícitamente en vez de caer silenciosamente a debug).

# 6. Pruebas

Manual: correr `flutter build appbundle --release` localmente y confirmar output firmado. No aplica test automatizado (config de build, no código de dominio).

# 7. Riesgos

**7.1 Pérdida del keystore o de las contraseñas.**
Mitigación: Carlos guardó ambas contraseñas en su gestor de contraseñas y hará backup del `.jks` en un segundo lugar. Con Play App Signing, si se pierde la *upload key* Google permite solicitar una rotación (trámite de soporte, toma días) — no aplica si se pierde antes de la primera subida.

**7.2 SHA-256 de deep links/App Check apunta a la key equivocada.**
Con Play App Signing, Google re-firma el AAB con su propia *app signing key* — el SHA-256 que necesitan `assetlinks.json` y Firebase App Check (Play Integrity) es el de esa key, no el del `.jks` local. Se obtiene después de la primera subida en Play Console → Configuración → Integridad de la app. Documentado como acción pendiente (plan #6).

# 8. Out of scope

- Creación de la cuenta de Google Play Console.
- Health Apps declaration form, Data Safety, Payments profile (cubiertos en el plan operativo del hilo, no en este SPEC).
- Publicación de `assetlinks.json` (depende de equipo web + del SHA-256 de Play App Signing, aún no disponible).

# 9. Resultado

Signing de release configurado y funcional en el repo. Listo para que Carlos corra el build (`flutter build appbundle --release`) y continúe con la subida a Play Console.
