#!/bin/bash
# Script de validación post-implementación — auditoría pre-producción 2026-07-11.
# Correr desde la raíz de elena_app/ en una Mac con Flutter, Xcode y Firebase CLI.
set -e

echo '== 1. Dependencias =='
flutter pub get

echo '== 2. Análisis estático =='
# --no-fatal-infos: los 'info' (p.ej. deprecated_member_use de riverpod .stream,
# que se retira recién en Riverpod 3.0 — hoy el proyecto usa 2.6.1) no deben
# frenar el pipeline. Warnings y errores SÍ siguen siendo fatales (default).
flutter analyze --no-fatal-infos

echo '== 3. Tests unitarios + widget (con coverage) =='
flutter test --coverage --reporter expanded

echo '== 4. Build Android release (con ProGuard/R8 nuevo) =='
flutter build appbundle --release

echo '== 5. Build iOS release =='
flutter build ios --release --no-codesign

echo '== 6. Tests de reglas de Firestore (requiere Firebase CLI + Java) =='
cd firestore-tests && npm install && npm run test:emulator && cd ..

echo 'Validación completa. Si todo lo anterior salió en verde, revisar la'
echo 'sección 5 (Riesgos restantes) del informe final para los pasos'
echo 'manuales que aún faltan (smoke test de compra sandbox, sync'
echo 'HealthKit/Health Connect en device real).'
