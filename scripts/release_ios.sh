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
