# SPEC-116 — CI/CD con GitHub Actions

**Estado:** En implementación
**Fecha:** 2026-05-15
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 1 (Pre-MVP shippable)
**Estimación:** 2 días
**Bloquea:** calidad continua de Fases 2 y 3

---

## Motivación

Hoy todos los commits pasan por aprobación manual sin checks automáticos. Riesgos:

1. **Regresiones silenciosas.** Un cambio puede romper tests existentes sin que nadie lo note hasta el siguiente run manual.
2. **Falta de gating.** No hay obstáculo objetivo entre código y merge a `main`. Una rama puede mezclarse con código que no compila si nadie corre `flutter analyze` localmente.
3. **Sin trazabilidad del estado de la rama.** No hay badge de CI ni dashboard de salud del repo.
4. **Bloqueante del roadmap.** Sin CI, los SPECs siguientes (golden tests, E2E, paywall) no pueden apoyarse en garantías de no-regresión.

La auditoría 360° del 15-may-2026 marca explícitamente la ausencia de CI/CD como gap de ingeniería (calificación 8/10 → target 10/10).

## Decisión

Implementar **GitHub Actions** con dos workflows:

1. **`ci.yml`** — corre en cada `pull_request` y `push` a `main`. Ejecuta lint + format + analyze + tests. Bloqueante para merge.
2. **`build-android.yml`** — corre solo en `push` a `main`. Genera APK release y publica como artefacto. No bloqueante.

Sin pipeline de iOS por ahora (requiere macOS runner, certificados, provisioning profiles — fuera de Fase 1). Se aborda en SPEC futuro post-launch.

## Alcance

### Incluido

- Workflow `.github/workflows/ci.yml`:
  - Trigger: `pull_request` (todas las ramas) + `push` a `main`.
  - Pasos: checkout, setup Flutter (versión pin), restore cache, `pub get`, `dart run build_runner build --delete-conflicting-outputs`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
  - Stages paralelos no aplican (proyecto pequeño, ejecución secuencial < 8 min).
- Workflow `.github/workflows/build-android.yml`:
  - Trigger: `push` a `main`.
  - Pasos: checkout, setup Flutter, pub get, build_runner, `flutter build apk --release --split-per-abi`.
  - Artifact: los 3 APKs por ABI, retención 30 días.
- `.github/PULL_REQUEST_TEMPLATE.md` con checklist mínimo.
- Badge de CI en `README.md`.

### Excluido (post-SPEC-116)

- Pipeline iOS (requiere macOS runner + signing certs).
- Deploy automático a TestFlight / Play Console (será SPEC-125).
- Tests de integración Firebase (requieren proyecto de staging).
- Análisis de cobertura con codecov (post-Fase 1 cuando SPEC-117 esté listo).

## Contrato técnico

### `ci.yml`

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main, mvp-core-clean]

jobs:
  quality:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
          channel: stable
          cache: true
      - run: flutter --version
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: dart format --set-exit-if-changed $(find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart')
      - run: flutter analyze
      - run: flutter test
```

> **Nota sobre la versión:** la versión Flutter inicial pinned a `3.27.4` causó fallo en el primer run porque trae Dart 3.6.2, incompatible con `flutter_lints ^6.0.0` (requiere Dart ≥ 3.8). Actualizado a `3.32.0` que trae Dart 3.8+. Esto **no** requiere cambios en `pubspec.yaml` — la constraint `sdk: ">=3.5.0 <4.0.0"` ya incluye 3.8.

### `build-android.yml`

```yaml
name: Build Android

on:
  push:
    branches: [main, mvp-core-clean]
  workflow_dispatch:

jobs:
  build-apk:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build apk --release --split-per-abi
      - uses: actions/upload-artifact@v4
        with:
          name: android-apks-${{ github.sha }}
          path: build/app/outputs/flutter-apk/*.apk
          retention-days: 30
```

### PR template

`.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## SPEC asociado
SPEC-XXX

## Resumen
Breve descripción del cambio.

## Checklist
- [ ] El SPEC está actualizado (estado, criterios de éxito).
- [ ] Tests nuevos para cualquier lógica de dominio agregada.
- [ ] `flutter analyze` pasa localmente.
- [ ] `flutter test` pasa localmente.
- [ ] Documentación actualizada si aplica (SPECs, docs/, MEMORY).
- [ ] CI verde antes de pedir review.
```

## Criterios de éxito

1. CI ejecuta correctamente en el primer PR después de mergeado.
2. Tiempo de ejecución del workflow `ci.yml` < 8 minutos.
3. PR no se puede mergear si CI está rojo (rama `main` protegida).
4. Workflow `build-android.yml` produce 3 APKs descargables tras cada merge a `main`.
5. Badge de CI visible en `README.md`.

## Configuración manual requerida (post-merge)

Estas configuraciones son fuera del repo (en la UI de GitHub) y deben hacerse una sola vez:

1. **GitHub repo → Settings → Branches → Branch protection rules → `mvp-core-clean`:**
   - Marcar "Require status checks to pass before merging".
   - Status check requerido: `quality` (el job del workflow `ci.yml`).
   - Marcar "Require branches to be up to date before merging".
   - Marcar "Do not allow bypassing the above settings" (opcional, recomendado).
   - Nota: se protege `mvp-core-clean` porque es la rama de trabajo real del MVP.
     Cuando el flujo cambie a `main` como rama integradora, replicar la regla allí.

2. **Settings → Actions → General:**
   - Verificar "Allow all actions and reusable workflows" o restringir a marketplace (Subosito Flutter Action está en marketplace verificado).

3. **Settings → Actions → Workflow permissions:**
   - "Read and write permissions" para que el job pueda escribir comentarios en PR si se agrega bot futuro.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Flutter version pin se queda viejo | Revisión trimestral. Renovate Bot opcional (Fase 3). |
| Tests `fake_cloud_firestore` flaky en CI | Si aparece flakiness, agregar retry (max 2) solo a stage de tests. |
| `build_runner` lento | Cache de `.dart_tool/` agregado en el workflow vía `subosito/flutter-action@v2 cache: true`. |
| Format check rechaza por código generado | `dart format` excluye `*.g.dart` y `*.freezed.dart` por convención del formatter. Verificar en primer run. |
| CI cuesta minutos GitHub Actions | Plan gratuito incluye 2.000 min/mes. Estimado 50 PRs × 8 min = 400 min/mes. Margen 5x. |

## Plan de rollback

Si el workflow rompe el flujo:

1. Desactivar branch protection rule temporalmente (Settings → Branches).
2. Mergear hotfix sin CI.
3. Investigar el fallo en `Actions → ci`.
4. Reactivar protection rule.

## Estructura de archivos creados/modificados

El repo git está en `elena_app/`. Todos los paths siguientes son
relativos a esa raíz git:

```
.github/
├── workflows/
│   ├── ci.yml                 (nuevo)
│   └── build-android.yml      (nuevo)
└── PULL_REQUEST_TEMPLATE.md   (nuevo)

README.md                      (modificado: badges agregados)
```

**Nota importante sobre la estructura del repo:** el directorio físico
`/Users/carlosreyes/Proyectos/ElenaApp/` contiene `elena_app/` y otros
documentos sueltos (auditorías históricas, etc.). El repo git real
está en `elena_app/` y su URL remota es
`https://github.com/krlosreyes/elena_app.git`. Los comandos de git y
los workflows operan **desde dentro de `elena_app/`**, no desde la
carpeta padre.

## Verificación post-merge

Tras mergear este SPEC, ejecutar manualmente:

1. Crear branch `test/spec-116-verify` con un cambio cosmético (typo en comentario).
2. Push → abrir PR.
3. Verificar que `ci` corra y pase.
4. Mergear → verificar que `build-android` corra y produzca artifacts.
5. Documentar tiempos reales en el SPEC bajo "Verificación".
6. Marcar SPEC como Cerrado.

## Verificación (a completar después del primer run)

- Tiempo CI: _por medir_
- Tiempo build-android: _por medir_
- Artifacts producidos: _por medir_
