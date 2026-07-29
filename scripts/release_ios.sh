#!/bin/bash
# Automatiza el bump del build number antes de compilar para App Store
# Connect. Nace del error recurrente "La versión del paquete debe ser
# superior a la versión cargada anteriormente" (22-jul) — cada intento
# fallido de subida (rechazo de revisión, error de conectividad, etc.)
# deja un build number "quemado" en App Store Connect que pubspec.yaml
# no sabe que existe, así que había que ir editando +38 -> +39 a mano
# cada vez.
#
# Qué hace:
#   1. Lee el build number actual de pubspec.yaml (version: X.Y.Z+N).
#   2. Lo sube en 1.
#   3. Corre flutter build ipa --release con ese nuevo número.
#   4. Si el build compila OK, commitea el bump de pubspec.yaml (para
#      que el número nunca vuelva a bajar ni se repita entre máquinas).
#
# Uso:
#   ./scripts/release_ios.sh
#
# Notas:
#   - No toca major.minor.patch (1.0.0) — solo el build number. Si hay
#     que subir versión de producto, editar pubspec.yaml a mano primero
#     (ej. 1.1.0+1) y después correr este script para los builds
#     siguientes de esa versión.
#   - No hace flutter clean/pod install — si el build falla con un
#     error de módulo de Xcode ("module ... not found"), correr antes:
#       flutter clean && flutter pub get && cd ios && pod install && cd ..
#   - No hace el upload a App Store Connect — eso sigue siendo manual
#     (Transporter o Xcode Organizer) para no automatizar un paso
#     irreversible sin supervisión.

set -euo pipefail
cd "$(dirname "$0")/.."

# ── Guardarraíl: onUserDeleted tiene que estar DESPLEGADA ──────────────
#
# 29-jul-2026. `deleteAccount()` en el cliente borra la cuenta de Auth y
# ya NO borra Firestore: el borrado en cascada lo hace `onUserDeleted` en
# servidor (ver el comentario largo en firebase_auth_repository.dart).
#
# El 27-jul se hizo ese cambio verificando que el código de la función
# cubría estrictamente más que el cliente. Lo que NO se verificó es que
# estuviera desplegada. No lo estaba — llevaba desde siempre sin subir, y
# durante dos días el borrado de cuenta eliminó usuarios de Auth dejando
# todos sus datos huérfanos en Firestore. Incumplimiento de GDPR Art.17
# que no daba ninguna señal: la app no falla, el usuario ve "cuenta
# eliminada", y los datos se quedan.
#
# Un guardarraíl que existe en el repo y no en producción no protege
# nada. Por eso esto se comprueba antes de construir una build: no se
# publica una app cuyo borrado de cuenta depende de una función que no
# está arriba.
#
# NOTA DE COSTES: desplegar functions obliga a tener el proyecto en plan
# Blaze. Es una dependencia de facturación, no solo técnica.
echo "0/2  Verificando que onUserDeleted está desplegada..."
if ! command -v firebase >/dev/null 2>&1; then
  echo ""
  echo "ERROR: no se encuentra el CLI de firebase, así que no se puede"
  echo "comprobar si onUserDeleted está desplegada. Instálalo con:"
  echo "  npm install -g firebase-tools"
  echo ""
  echo "Si necesitas construir igualmente y sabes lo que haces:"
  echo "  SKIP_FUNCTIONS_CHECK=1 ./scripts/release_ios.sh"
  [ "${SKIP_FUNCTIONS_CHECK:-0}" = "1" ] || exit 1
elif ! firebase functions:list 2>/dev/null | grep -q "onUserDeleted"; then
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "ABORTADO — onUserDeleted NO está desplegada."
  echo ""
  echo "Borrar una cuenta eliminaría el usuario de Auth y dejaría TODOS"
  echo "sus datos en Firestore. Es el gap de GDPR Art.17 del 27-jul."
  echo ""
  echo "Despliégala antes de construir:"
  echo "  firebase deploy --only functions:onUserDeleted"
  echo "════════════════════════════════════════════════════════════"
  [ "${SKIP_FUNCTIONS_CHECK:-0}" = "1" ] || exit 1
else
  echo "     ✓ onUserDeleted está arriba."
fi

PUBSPEC="pubspec.yaml"

CURRENT_LINE=$(grep -E '^version: ' "$PUBSPEC")
BASE_VERSION=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+.*/\1/')
CURRENT_BUILD=$(echo "$CURRENT_LINE" | sed -E 's/.*\+([0-9]+)$/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Build number: ${CURRENT_BUILD} -> ${NEW_BUILD} (versión ${BASE_VERSION})"
sed -i '' -E "s/^version: .*/version: ${BASE_VERSION}+${NEW_BUILD}/" "$PUBSPEC"

flutter build ipa --release

echo ""
echo "Build ${NEW_BUILD} listo en build/ios/ipa/ — subilo con Transporter."
echo "Commiteando el bump de pubspec.yaml..."
git add "$PUBSPEC"
git commit -m "chore(release): bump build number a ${NEW_BUILD}"
git push
