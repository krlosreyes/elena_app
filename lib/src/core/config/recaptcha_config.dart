// SPEC-81: configuración de reCAPTCHA v3 para AppCheck en web.
//
// La key actual es PLACEHOLDER. Para producción:
//   1. Ir a https://www.google.com/recaptcha/admin
//   2. Registrar un nuevo sitio con tipo "reCAPTCHA v3".
//   3. Agregar los dominios:
//      - localhost (desarrollo local)
//      - metamorfosisreal.com (producción)
//      - elena-app-2026-v1.firebaseapp.com (firebase hosting)
//      - elena-app-2026-v1.web.app (firebase hosting alterno)
//   4. Copiar la Site Key.
//   5. Reemplazar `kRecaptchaSiteKey` con la real.
//   6. Hacer commit + deploy.
//
// La Secret Key NO va en el cliente — solo se usa en backend (Firebase
// la gestiona internamente vía la integración AppCheck → reCAPTCHA).

const String kRecaptchaSiteKey =
    '6LeX-OcpAAAAAI8iG-Y6G9S7v7L3H-O-1-9-O-9';

/// Placeholder bien conocido de la fase de desarrollo. Si la app
/// arranca con esta key, AppCheck en web NO va a verificar contra
/// Google y los requests pueden ser rechazados o aceptados sin
/// protección anti-bot real.
const String _kPlaceholderKey =
    '6LeX-OcpAAAAAI8iG-Y6G9S7v7L3H-O-1-9-O-9';

/// True si la app sigue usando el placeholder. Usado al arranque
/// para mostrar un warning en consola.
bool get recaptchaIsPlaceholder => kRecaptchaSiteKey == _kPlaceholderKey;
