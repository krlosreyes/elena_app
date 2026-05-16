# elena_app

[![CI](https://github.com/krlosreyes/elena_app/actions/workflows/ci.yml/badge.svg)](https://github.com/krlosreyes/elena_app/actions/workflows/ci.yml)
[![Build Android](https://github.com/krlosreyes/elena_app/actions/workflows/build-android.yml/badge.svg)](https://github.com/krlosreyes/elena_app/actions/workflows/build-android.yml)

**Sistema de Alineación Biológica — MVP.**

App de salud metabólica de Metamorfosis Real construida sobre 5 pilares (ayuno, sueño, hidratación, ejercicio, nutrición) unificados por una métrica única: el **IMR (Índice Metabólico Real)**.

## Stack

- Flutter `>=3.5.0 <4.0.0`
- Riverpod 2.6 (state management)
- go_router 17 (navegación)
- Firebase 6 (auth, firestore, app check, crashlytics)
- freezed + json_serializable (modelos inmutables)

## Estructura

```
elena_app/                          (repo root - este folder ES el repo git)
├── .github/workflows/              # CI/CD (SPEC-116)
├── lib/                            # Código de la app
├── test/                           # Tests
├── specs/                          # Especificaciones SDD
├── docs/                           # Documentación operativa
└── pubspec.yaml
```

## Documentación clave

- [`CONSTITUTION.md`](CONSTITUTION.md) — principios arquitectónicos.
- [`docs/ROADMAP_PRODUCCION_10_10.md`](docs/ROADMAP_PRODUCCION_10_10.md) — plan a producción.
- [`IMR_BIBLIOGRAPHY.md`](IMR_BIBLIOGRAPHY.md) — bases científicas del IMR.
- [`specs/`](specs/) — historial completo de SPECs (76+).

## Comandos de desarrollo

```bash
# Setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Calidad
flutter analyze
flutter test

# Run en device conectado
flutter run

# Build release
flutter build apk --release --split-per-abi
```

## Modelo de trabajo

Spec-Driven Development (SDD). Cada cambio significativo se documenta en `specs/SPEC-XXX-titulo.md` antes de implementarse. La rama `mvp-core-clean` recibe commits con prefijo `SPEC-XXX:`.

