#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# check_pure_factories.sh
# ─────────────────────────────────────────────────────────────────────────────
#
# Hace cumplir la "Ley de Factories Puras" promulgada en SPEC-60 y
# absorbida por CONSTITUTION.md §3.1:
#
#   "Ninguna factory `.empty()`, `.initial()`, `.zero()` o equivalente del
#    dominio puede invocar DateTime.now(), Random(), lectura de
#    SharedPreferences, ni cualquier otra fuente de no-determinismo o
#    efecto secundario."
#
# Detecta el patrón:
#   factory <Class>.<empty|initial|zero>(...) ... {
#     ... DateTime.now() | Random( | Uuid() ...
#   }
#
# Uso:
#   bash scripts/check_pure_factories.sh
#   - Salida 0 si no hay violaciones.
#   - Salida 1 si hay violaciones, listándolas con archivo:línea.
#
# Engánchalo a tu pre-commit con:
#   ln -s ../../scripts/check_pure_factories.sh .git/hooks/pre-commit
#
# Excepciones registradas (factories de USO, no de estado vacío):
#   - HydrationLog.glass()  — semánticamente "un vaso ahora", excepción
#     justificada en SPEC-60.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ROOT="${1:-lib/src}"

if [ ! -d "$ROOT" ]; then
  echo "❌ Directorio no encontrado: $ROOT"
  echo "   Uso: bash scripts/check_pure_factories.sh [ruta_lib]"
  exit 2
fi

# Lista blanca de archivos exceptuados explícitamente.
# Extender con cuidado y solo con justificación documentada en la SPEC vigente.
EXCEPTIONS=(
  "lib/src/features/dashboard/domain/hydration_log.dart"
)

is_exception() {
  local file="$1"
  for exc in "${EXCEPTIONS[@]}"; do
    if [ "$file" = "$exc" ]; then
      return 0
    fi
  done
  return 1
}

# Buscar archivos .dart, excluir generados (.freezed.dart, .g.dart).
# Para cada archivo, identificar bloques `factory <Name>.<empty|initial|zero>(...)`
# y verificar si dentro de su cuerpo hay DateTime.now / Random( / Uuid(.
# Implementación con awk: detecta inicio de factory, balancea llaves, escanea cuerpo.

violations=0

while IFS= read -r -d '' file; do
  if is_exception "$file"; then
    continue
  fi

  awk -v file="$file" '
    BEGIN { in_factory = 0; depth = 0; start_line = 0; body = ""; }
    {
      # Detectar inicio de factory empty/initial/zero
      if (in_factory == 0 && match($0, /factory[[:space:]]+[A-Za-z_][A-Za-z0-9_]*\.(empty|initial|zero)[[:space:]]*\(/)) {
        in_factory = 1
        start_line = NR
        body = $0
        # Contar llaves en la línea inicial
        n_open = gsub(/\{/, "{", body)
        n_close = gsub(/\}/, "}", body)
        depth = n_open - n_close
        # Si el cuerpo es expresión-arrow sin {}, mantenerlo en una sola línea.
        if (depth == 0 && body !~ /\{/) {
          # cuerpo en arrow expression — contiene la firma + retorno hasta ;
          while (body !~ /;/) {
            if ((getline next_line) <= 0) break
            body = body "\n" next_line
            NR_save = NR
          }
          # Verificar contenido del body
          check_violation(body, file, start_line)
          in_factory = 0
          next
        }
        # Continuar acumulando hasta cerrar llaves
        while (depth > 0) {
          if ((getline next_line) <= 0) break
          body = body "\n" next_line
          n_open = gsub(/\{/, "{", next_line)
          n_close = gsub(/\}/, "}", next_line)
          depth += n_open - n_close
        }
        check_violation(body, file, start_line)
        in_factory = 0
        body = ""
      }
    }

    function check_violation(body, file, line) {
      if (body ~ /DateTime\.now\(/) {
        printf("%s:%d: factory invokes DateTime.now() — viola SPEC-60\n", file, line)
        exit_code = 1
      }
      if (body ~ /Random\(/) {
        printf("%s:%d: factory invokes Random() — viola SPEC-60\n", file, line)
        exit_code = 1
      }
      if (body ~ /Uuid\(\)/) {
        printf("%s:%d: factory invokes Uuid() — viola SPEC-60\n", file, line)
        exit_code = 1
      }
    }

    END { exit (exit_code ? exit_code : 0) }
  ' "$file" || violations=$((violations + 1))
done < <(find "$ROOT" -type f -name "*.dart" \
            ! -name "*.freezed.dart" \
            ! -name "*.g.dart" \
            -print0)

if [ "$violations" -gt 0 ]; then
  echo ""
  echo "❌ $violations archivo(s) con factories impuras detectados."
  echo "   Ver SPEC-60 del PLAN_SDD_REMEDIACION_v1.x.md."
  echo "   Si una factory requiere DateTime.now() por semántica (no por inicialización),"
  echo "   añádela a EXCEPTIONS en este script con justificación en la SPEC."
  exit 1
fi

echo "✅ Ley de Factories Puras: sin violaciones en $ROOT/"
exit 0
