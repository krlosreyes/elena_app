#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_tests.sh — Orquestador de calidad para CI/local
# ─────────────────────────────────────────────────────────────────────────────
#
# SPEC-66 v2: ejecuta toda la suite de tests + las verificaciones de invariante
# del proyecto, retornando exit 0 si todo pasa, exit ≥1 si algo falla.
#
# Uso local:
#   bash scripts/run_tests.sh
#
# En CI:
#   - name: Run tests
#     run: bash scripts/run_tests.sh
#
# Pasos:
#   1. Ley de Factories Puras (SPEC-60).
#   2. flutter pub get (asegura dependencias).
#   3. flutter test (la suite completa).
#
# Notas:
#   - flutter analyze NO se ejecuta aquí porque el baseline aún tiene ~495
#     issues que no son introducidos por PRs nuevos. SPEC-72 los limpiará y
#     entonces este script añadirá `flutter analyze --fatal-warnings`.
#   - build_runner se ejecuta MANUALMENTE cuando se modifican modelos
#     Freezed/json_serializable; este script asume que los .g.dart están
#     actualizados.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
echo "🚀 Suite de calidad para Elena App ($ROOT)"
echo ""

echo "▶ 1/3 Ley de Factories Puras (SPEC-60)..."
bash scripts/check_pure_factories.sh
echo ""

echo "▶ 2/3 flutter pub get..."
flutter pub get >/dev/null
echo "   ✓ Dependencias resueltas."
echo ""

echo "▶ 3/3 flutter test..."
flutter test
echo ""

echo "✅ Todas las verificaciones pasaron."
