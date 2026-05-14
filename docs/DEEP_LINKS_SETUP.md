# Deep Links / Universal Links — SPEC-78

**Última actualización:** 13 de mayo de 2026
**Estado:** configuración del lado app lista. **Pendiente del lado del sitio** (responsabilidad del equipo de `metamorfosis-web`).

---

## Qué necesita servir el sitio `metamorfosisreal.com`

### 1. Android — `https://metamorfosisreal.com/.well-known/assetlinks.json`

Archivo JSON estático con la huella SHA-256 del certificado de firma del APK/AAB.

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.metamorfosis.elena.elena_app",
      "sha256_cert_fingerprints": [
        "AB:CD:EF:01:23:45:..."
      ]
    }
  }
]
```

Para obtener el `sha256_cert_fingerprints`:

**Debug build:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release build:**
```bash
keytool -list -v -keystore <path-al-keystore-release> -alias <alias>
```

Copiar la línea `SHA-256:` y pegarla en `sha256_cert_fingerprints` (sin espacios, con `:` entre bytes).

Servir con header HTTP `Content-Type: application/json` y SIN redirección (Android sigue 30x pero los rechaza para verificación).

### 2. iOS — `https://metamorfosisreal.com/.well-known/apple-app-site-association`

Archivo JSON sin extensión `.json` (Apple lo exige así).

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAM_ID.com.metamorfosis.elena.elenaApp"],
        "components": [
          {
            "/": "/app/*",
            "comment": "Captura todas las URLs bajo /app de la app"
          }
        ]
      }
    ]
  }
}
```

- `TEAM_ID`: el identificador de Apple Developer Team (10 caracteres alfanuméricos visible en developer.apple.com → Membership).
- `com.metamorfosis.elena.elenaApp`: bundle identifier del Info.plist (en código: `$(PRODUCT_BUNDLE_IDENTIFIER)`).

Servir con `Content-Type: application/json` y SIN extensión `.json` en la URL. Apple revalida cada ~7 días.

---

## Verificación

### Android
```bash
adb shell pm verify-app-links --re-verify com.metamorfosis.elena.elena_app
adb shell pm get-app-links com.metamorfosis.elena.elena_app
```
Debe mostrar el dominio como `verified`.

### iOS
1. Asegurar que en Xcode → Runner target → Signing & Capabilities está habilitado el capability "Associated Domains" con `applinks:metamorfosisreal.com`.
2. Asegurar que el AppID en developer.apple.com tiene "Associated Domains" activado.
3. Apple usa caché agresiva. Para forzar re-fetch del `apple-app-site-association`: borrar la app del device y re-instalar.

---

## Rutas soportadas por la app

| URL del sitio | Destino en la app |
|---|---|
| `https://metamorfosisreal.com/app` | `/dashboard` si auth, `/login` si no |
| `https://metamorfosisreal.com/app/imr` | `/dashboard` o `/onboarding` según estado |
| `https://metamorfosisreal.com/app/welcome` | `/onboarding` o `/dashboard` según estado |

Otras URLs bajo `/app/*` que no estén mapeadas terminan en `/dashboard` (fallback del redirect público).

---

## Smoke test pre-launch

Una vez que el sitio publique los dos archivos:

1. **Android emulator o device físico:**
   ```bash
   adb shell am start -W -a android.intent.action.VIEW \
     -d "https://metamorfosisreal.com/app/imr" \
     com.metamorfosis.elena.elena_app
   ```

2. **iOS simulator:**
   ```bash
   xcrun simctl openurl booted https://metamorfosisreal.com/app/imr
   ```

3. **Tap manual** en un link real desde un email transaccional.

En los tres casos: la app debe abrir en la pantalla correspondiente sin pasar por el browser.
