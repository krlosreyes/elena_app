#!/usr/bin/env bash
# Corrida de validación completa → deja el resultado en un archivo que Claude
# puede leer directamente, sin que Carlos tenga que pegar 3.000 líneas.
#
# POR QUÉ EXISTE (27-jul-2026)
# ---------------------------
# El entorno de Claude no tiene Flutter ni Dart y no puede instalarlos: su red
# solo alcanza github.com y registry.npmjs.org — pub.dev, storage.googleapis.com
# y dl.google.com están fuera del allowlist, así que ni el SDK de Dart ni
# `pub get` son alcanzables. Tampoco puede escribir en una terminal (los
# terminales se conceden en modo solo-clic).
#
# La consecuencia práctica es que la única forma de que Claude vea un resultado
# real de compilación es que TÚ lances la corrida y él LEA el archivo. Este
# script es ese puente.
#
# USO
#   ./scripts/validar.sh            # analyze + test
#   ./scripts/validar.sh --reglas   # además, la suite de reglas de Firestore
#
# Luego dile a Claude: "ya corrí ./scripts/validar.sh".
# Él lee elena_app/.claude-runs/resumen.txt (compacto) y, si hace falta,
# completo.txt (todo el detalle).

set -uo pipefail
cd "$(dirname "$0")/.."

SALIDA=".claude-runs"
mkdir -p "$SALIDA"
RESUMEN="$SALIDA/resumen.txt"
COMPLETO="$SALIDA/completo.txt"

: > "$COMPLETO"
: > "$RESUMEN"

titulo() { printf '\n\033[1m%s\033[0m\n' "$1"; }
anotar() { echo "$1" >> "$RESUMEN"; }

anotar "CORRIDA DE VALIDACIÓN — $(date '+%Y-%m-%d %H:%M:%S')"
anotar "rama: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')  ·  HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
anotar "flutter: $(flutter --version 2>/dev/null | head -1 || echo 'NO ENCONTRADO')"
anotar ""

# ── 1. ANALYZE ──────────────────────────────────────────────────────────────
titulo "1/3  flutter analyze"
{ echo "═══ FLUTTER ANALYZE ═══"; flutter analyze 2>&1; } >> "$COMPLETO"
ANALYZE_TXT=$(sed -n '/═══ FLUTTER ANALYZE ═══/,/^$/p' "$COMPLETO")
N_ISSUES=$(grep -cE '^\s+(info|warning|error) •' "$COMPLETO" || true)
N_ERRORES=$(grep -cE '^\s+error •' "$COMPLETO" || true)

anotar "── ANALYZE ─────────────────────────────────────────"
anotar "issues: $N_ISSUES   (errores: $N_ERRORES)"
if [ "$N_ISSUES" -gt 0 ]; then
  anotar ""
  grep -E '^\s+(info|warning|error) •' "$COMPLETO" | sed 's/^ */  /' >> "$RESUMEN"
fi
anotar ""

# ── 2. TEST ─────────────────────────────────────────────────────────────────
# `flutter test` escupe muchísimo ruido de AppLogger. Al resumen solo va lo que
# importa: el conteo final y CADA fallo con su motivo. El log completo queda en
# completo.txt por si hay que bajar al detalle.
titulo "2/3  flutter test"
{ echo; echo "═══ FLUTTER TEST ═══"; flutter test 2>&1; } >> "$COMPLETO"

LINEA_FINAL=$(grep -E '^[0-9]{2}:[0-9]{2} \+[0-9]+' "$COMPLETO" | tail -1)
anotar "── TEST ────────────────────────────────────────────"
anotar "${LINEA_FINAL:-sin línea de resumen}"

# Un fallo se identifica por el marcador [E] que imprime el runner.
N_FALLOS=$(grep -c ' \[E\]$' "$COMPLETO" || true)
anotar "fallos: $N_FALLOS"
if [ "$N_FALLOS" -gt 0 ]; then
  anotar ""
  anotar "  TESTS FALLIDOS (con su Expected/Actual):"
  grep -B1 -A6 ' \[E\]$' "$COMPLETO" \
    | grep -vE '^\s*[│┌└├]' \
    | sed 's/^/  /' >> "$RESUMEN"
fi
anotar ""

# ── 3. REGLAS DE FIRESTORE (opcional) ───────────────────────────────────────
if [ "${1:-}" = "--reglas" ]; then
  titulo "3/3  reglas de Firestore (emulador)"
  anotar "── REGLAS FIRESTORE ────────────────────────────────"

  FALTA=""
  # El emulador es un proceso Java: sin JDK ni arranca.
  # OJO con la VERSIÓN, no solo con la presencia: firebase-tools exige JDK 21+
  # desde 2026. Con temurin@17 el `command -v java` pasa, el emulador NO
  # arranca, y —si no se comprueba— la corrida se reporta en verde sin haber
  # ejecutado un solo caso. Comprobado en carne propia el 27-jul.
  #
  # El primer intento de esta comprobación usaba un `sed` con `.*"` glotón que
  # dejaba fuera la fecha del final de la línea: con `openjdk version "17.0.9"
  # 2023-10-17` devolvía `17 2023-10-17`, que no es un entero, así que el
  # `[ -lt ]` erraba, el `2>/dev/null` se tragaba el error y la comprobación
  # nunca marcaba nada. Extraer solo el número tras la comilla es a prueba de
  # formato (`"17.0.9"`, `"21.0.2" ... LTS`, `"1.8.0_401"`).
  if ! command -v java >/dev/null 2>&1; then
    FALTA="$FALTA java"
  else
    JAVA_MAJOR=$(java -version 2>&1 | head -1 | grep -oE '"[0-9]+' | tr -d '"')
    case "$JAVA_MAJOR" in
      ''|*[!0-9]*) FALTA="$FALTA java(version-ilegible)" ;;
      *) [ "$JAVA_MAJOR" -lt 21 ] && FALTA="$FALTA java21(tienes-$JAVA_MAJOR)" ;;
    esac
  fi
  # `test:emulator` invoca `firebase emulators:exec`; el CLI NO está vendored
  # en firestore-tests/node_modules (solo está @firebase/rules-unit-testing).
  command -v firebase >/dev/null 2>&1 || FALTA="$FALTA firebase"

  if [ -n "$FALTA" ]; then
    anotar "SALTADO — falta:$FALTA"
    case "$FALTA" in
      *java21*)   anotar "    brew install --cask temurin@21   # firebase-tools exige 21+"
                  anotar "    Si ya lo instalaste y sigue saliendo esto, manda JAVA_HOME"
                  anotar "    al nuevo:  export JAVA_HOME=\$(/usr/libexec/java_home -v 21)" ;;
      *java*)     anotar "    brew install --cask temurin@21   # 21+ obligatorio" ;;
    esac
    case "$FALTA" in
      *firebase*) anotar "    npm install -g firebase-tools" ;;
    esac
    anotar "  Son los 38 casos que protegen datos de salud y verifican el fix"
    anotar "  de borrado (C-03). No se han ejecutado nunca."
  else
    [ -d firestore-tests/node_modules ] || (cd firestore-tests && npm install >/dev/null 2>&1)
    # `npm test` a secas corre los tests SIN emulador y fallan todos por
    # conexión. El script correcto es `test:emulator`, que los envuelve en
    # `firebase emulators:exec`.
    { echo; echo "═══ REGLAS FIRESTORE ═══"; \
      (cd firestore-tests && npm run test:emulator 2>&1); } >> "$COMPLETO"

    # Si no aparecen los contadores de `node --test`, la suite NO corrió —
    # el emulador pudo no arrancar. Eso NO es "0 fallos": es desconocido, y
    # tratarlo como verde es peor que un rojo. (27-jul: con JDK 17 el
    # emulador abortaba y esta sección reportaba verde sin ejecutar nada.)
    #
    # El prefijo es `ℹ`, no `#`: node --test usa su reporter `spec` por
    # defecto, no TAP. Con el patrón `^# tests` la detección fallaba SIEMPRE
    # y una corrida perfecta (47/47) se reportaba como "no ejecutada" — el
    # error simétrico al verde falso, y también mío.
    if ! grep -qE '^(ℹ|#) tests [0-9]+' "$COMPLETO"; then
      REGLAS_FAIL="NO_CORRIO"
      anotar "NO SE EJECUTÓ — el emulador no llegó a arrancar."
      anotar ""
      anotar "  Motivo detectado:"
      sed -n '/═══ REGLAS FIRESTORE ═══/,$p' "$COMPLETO" \
        | grep -iE '^(Error|.*Error:)' | head -3 | sed 's/^/    /' >> "$RESUMEN"
    else
      REGLAS_FAIL=$(grep -E '^(ℹ|#) fail ' "$COMPLETO" | tail -1 | grep -oE '[0-9]+$' || echo 0)
      grep -E '^(ℹ|#) (tests|pass|fail) ' "$COMPLETO" | tail -3 | sed 's/^/  /' >> "$RESUMEN"
      if [ "$REGLAS_FAIL" != "0" ]; then
        anotar ""
        anotar "  CASOS FALLIDOS:"
        # El reporter `spec` marca los fallos con ✖; TAP usaría `not ok`.
        grep -E '^\s*✖|^not ok ' "$COMPLETO" | sed 's/^/    /' >> "$RESUMEN"
      fi
    fi
  fi
else
  anotar "── REGLAS FIRESTORE ────────────────────────────────"
  anotar "no ejecutadas (usa: ./scripts/validar.sh --reglas)"
fi
anotar ""

# ── VEREDICTO ───────────────────────────────────────────────────────────────
anotar "════════════════════════════════════════════════════"
REGLAS_FAIL="${REGLAS_FAIL:-NO_PEDIDO}"

if [ "$N_ERRORES" -ne 0 ] || [ "$N_FALLOS" -ne 0 ]; then
  anotar "ROJO — $N_ERRORES error(es) de compilación, $N_FALLOS test(s) fallido(s)."
elif [ "$REGLAS_FAIL" = "NO_CORRIO" ]; then
  # Verde en analyze+test pero las reglas no se ejecutaron. NO es verde:
  # el fix de borrado (C-03) sigue sin una sola verificación.
  anotar "INCOMPLETO — analyze y tests en verde, pero las reglas de Firestore"
  anotar "             NO se ejecutaron (ver arriba). El fix de borrado sigue"
  anotar "             sin verificar."
elif [ "$REGLAS_FAIL" = "NO_PEDIDO" ]; then
  anotar "VERDE (parcial) — $N_ISSUES aviso(s) de analyze, 0 errores, 0 tests fallidos."
  anotar "                  Reglas de Firestore no incluidas en esta corrida."
elif [ "$REGLAS_FAIL" -ne 0 ]; then
  anotar "ROJO — analyze y tests en verde, pero $REGLAS_FAIL caso(s) de reglas fallido(s)."
else
  anotar "VERDE — $N_ISSUES aviso(s) de analyze, 0 errores, 0 tests fallidos,"
  anotar "        reglas de Firestore incluidas y en verde."
fi

titulo "Listo"
cat "$RESUMEN"
echo
echo "  resumen  → elena_app/$RESUMEN   (esto es lo que lee Claude)"
echo "  completo → elena_app/$COMPLETO  ($(wc -l < "$COMPLETO" | tr -d ' ') líneas)"
echo
echo "  Dile a Claude: \"ya corrí ./scripts/validar.sh\""
