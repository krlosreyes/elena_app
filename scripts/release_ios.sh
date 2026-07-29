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
#   1. Comprueba que onUserDeleted está desplegada.
#   2. Comprueba que la validación está en VERDE, es de este commit y el
#      árbol está limpio.
#   3. Lee el build number actual de pubspec.yaml (version: X.Y.Z+N).
#   4. Lo sube en 1.
#   5. Corre flutter build ipa --release con ese nuevo número.
#   6. Comprueba que el .ipa existe de verdad.
#   7. Solo entonces commitea el bump de pubspec.yaml (para que el número
#      nunca vuelva a bajar ni se repita entre máquinas).
#
# Los pasos 1, 2 y 6 son guardarraíles: cada uno nace de un fallo real que
# ya ocurrió. Están explicados en su sitio, más abajo.
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
echo "1/2  Verificando que onUserDeleted está desplegada..."
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

# ── Guardarraíl: la validación tiene que estar en VERDE y ser de ESTE ──
#    commit, con el árbol limpio.
#
# 29-jul-2026. El 29-jul a las 13:10 `validar.sh` dio ROJO por un error de
# compilación (`Undefined name 'BuildInfo'`) y veinticinco minutos después
# se construyó, commiteó y publicó el build 56. Nada lo impidió: el script
# solo comprobaba `onUserDeleted`.
#
# Esto se repite en el proyecto: el CI estuvo semanas en rojo por el paso
# de formato sin que nadie lo viera, y una auditoría publicó "59,5 % de
# cobertura" leyendo un lcov de una semana antes. El patrón siempre es el
# mismo — una señal de calidad que nadie obliga a mirar en el momento en
# que importa.
#
# Se piden tres cosas, no una:
#   1. que el resumen diga VERDE,
#   2. que sea de ESTE commit (un verde de ayer no dice nada de hoy),
#   3. que no haya cambios sin commitear (lo que se validó tiene que ser
#      lo que se compila; si no, el binario contiene código que no está
#      en git y deja de ser reproducible).
echo "2/2  Verificando que la validación está en verde..."
RESUMEN=".claude-runs/resumen.txt"
HEAD_ACTUAL=$(git rev-parse --short HEAD)

abortar_validacion() {
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "ABORTADO — $1"
  echo ""
  echo "Corre la validación y vuelve a intentarlo:"
  echo "  dart format \$(find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart')"
  echo "  ./scripts/validar.sh --reglas"
  echo ""
  echo "Si necesitas construir igualmente y sabes lo que haces:"
  echo "  SKIP_VALIDACION=1 ./scripts/release_ios.sh"
  echo "════════════════════════════════════════════════════════════"
  [ "${SKIP_VALIDACION:-0}" = "1" ] || exit 1
}

if [ ! -f "$RESUMEN" ]; then
  abortar_validacion "no hay ninguna corrida de validación ($RESUMEN no existe)."
elif ! grep -q "^VERDE —" "$RESUMEN"; then
  abortar_validacion "la última corrida de validación NO está en verde."
elif ! grep -q "HEAD: ${HEAD_ACTUAL}\b" "$RESUMEN"; then
  HEAD_VALIDADO=$(sed -n 's/.*HEAD: \([0-9a-f]*\).*/\1/p' "$RESUMEN" | head -1)
  abortar_validacion "la validación en verde es de otro commit (${HEAD_VALIDADO:-?}), no de ${HEAD_ACTUAL}."
elif [ -n "$(git status --porcelain)" ]; then
  echo ""
  git status --short
  abortar_validacion "hay cambios sin commitear: el binario no sería reproducible desde git."
else
  echo "     ✓ validación en verde sobre ${HEAD_ACTUAL}, árbol limpio."
fi

PUBSPEC="pubspec.yaml"

CURRENT_LINE=$(grep -E '^version: ' "$PUBSPEC")
BASE_VERSION=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+.*/\1/')
CURRENT_BUILD=$(echo "$CURRENT_LINE" | sed -E 's/.*\+([0-9]+)$/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Build number: ${CURRENT_BUILD} -> ${NEW_BUILD} (versión ${BASE_VERSION})"
sed -i '' -E "s/^version: .*/version: ${BASE_VERSION}+${NEW_BUILD}/" "$PUBSPEC"

# 29-jul: se inyectan versión y build para que la app los muestre al pie
# de Perfil (ver lib/src/core/config/build_info.dart). Sin esto no hay
# forma de saber desde el teléfono qué binario tiene instalado, y
# "no se ven los cambios" es indistinguible de "tiene un build viejo".
flutter build ipa --release \
  --dart-define=APP_VERSION="${BASE_VERSION}" \
  --dart-define=BUILD_NUMBER="${NEW_BUILD}"

# `set -e` ya aborta si `flutter build ipa` devuelve un código distinto de
# cero, así que esto NO cubre "el build falló". Cubre el caso más sutil:
# que la herramienta devuelva 0 sin haber dejado un .ipa donde toca — por
# una ruta de salida que cambie entre versiones de Flutter, o por un
# artefacto viejo que quede de una corrida anterior y aparente frescura.
#
# El coste de no comprobarlo es asimétrico: quemar un build number es
# irreversible en App Store Connect, y "Build N listo" sin artefacto es
# indistinguible de un éxito hasta que abres Transporter.
IPA=$(find build/ios/ipa -maxdepth 1 -name '*.ipa' -newer "$PUBSPEC" 2>/dev/null | head -1)
if [ -z "$IPA" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "ABORTADO — flutter terminó sin error pero no hay ningún .ipa"
  echo "nuevo en build/ios/ipa/."
  echo ""
  echo "NO se commitea el bump: el número ${NEW_BUILD} queda libre para"
  echo "el próximo intento. Revisa la salida de Xcode más arriba."
  echo "════════════════════════════════════════════════════════════"
  exit 1
fi

echo ""
echo "Build ${NEW_BUILD} listo en ${IPA} — subilo con Transporter."
echo "Commiteando el bump de pubspec.yaml..."
git add "$PUBSPEC"
git commit -m "chore(release): bump build number a ${NEW_BUILD}"
git push
