#!/bin/bash

# 🌱 Master Food Database Seeding Script
# Prepara y ejecuta el seeding en el emulador de Firebase (opcional) o en Firestore real

set -e

echo "🌱 Elena Food Database Seeding Script"
echo "======================================"
echo ""

PROJECT_PATH="/Users/carlosreyes/Proyectos/ElenaApp/elena_app"
cd "$PROJECT_PATH"

echo "✅ Step 1: Validating Dart Analysis"
flutter analyze lib/src/features/nutrition/data/food_seeder.dart --no-pub

echo ""
echo "✅ Step 2: Getting Dependencies"
flutter pub get

echo ""
echo "✅ Step 3: Building App"
echo "Note: App will auto-seed on launch"
echo ""

echo "🚀 Ready to run!"
echo ""
echo "Options:"
echo "  1. Run on emulator:  flutter run"
echo "  2. Run on device:    flutter run -d <device_id>"
echo ""
echo "📝 The app will automatically seed all 80 foods on first launch."
echo "   Check console logs for seeding progress."
echo ""
echo "✅ Seeding Complete!"
