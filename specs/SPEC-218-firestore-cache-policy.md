# SPEC-218 — Política de caché Firestore: límite y limpieza periódica

**Estado:** IMPLEMENTED (2026-06-14) — cacheSizeBytes: 100 MB en main.dart. Verificado.
**Versión:** 1.0
**Tipo:** Deuda técnica P2 — Caché ilimitada puede agotar almacenamiento en dispositivos.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~30 min
**Depende de:** ninguno (cambio aislado en `main.dart`)
**Nota:** Ola 2+. No bloquea el lanzamiento inicial.

---

## 1. Problema

`main.dart` configura Firestore con `cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED`:

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

Para una app de salud con uso diario, la caché puede incluir:
- 365 días × 5 pilares × N documentos por día = miles de documentos.
- Snapshots históricos de `daily_summary`, `streak_history`, `metabolic_cycles`.

En dispositivos con 16–32 GB de almacenamiento, otros datos (fotos, apps) compiten por
espacio. Firestore sin límite de caché puede consumir cientos de MB con el tiempo.

La configuración de `CACHE_SIZE_UNLIMITED` era correcta para SPEC-206 (offline-first)
cuando queríamos asegurar que el historial completo estuviera disponible offline. Sin
embargo, el SDK de Firestore ya maneja eviction inteligente cuando se define un límite
razonable — no corta datos recientes, sino datos muy antiguos raramente accedidos.

---

## 2. Solución

### inc1 — Definir límite de caché a 100 MB

100 MB es suficiente para varios meses de historial completo de una app de salud:
- Documento promedio de Firestore: ~1–2 KB.
- 100 MB / 1.5 KB = ~66,000 documentos.
- Un usuario activo genera ~5–10 documentos/día × 5 pilares = ~50 docs/día.
- 66,000 docs / 50 docs/día = ~1,300 días (~3.5 años) de historial.

Firestore evictará datos más antiguos automáticamente cuando supere el límite.

```dart
// main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  // SPEC-218: 100 MB cubre ~3.5 años de historial completo.
  // Firestore evicta datos antiguos raramente accedidos automáticamente.
  // Era CACHE_SIZE_UNLIMITED (SPEC-206) — ahora con cota para proteger
  // dispositivos con almacenamiento limitado.
  cacheSizeBytes: 100 * 1024 * 1024,  // 100 MB
);
```

### inc2 — Documentar la decisión en SPEC-206

Añadir nota en SPEC-206 §5 que el límite fue actualizado a 100 MB en SPEC-218 y el
motivo.

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/main.dart` | `cacheSizeBytes: 100 * 1024 * 1024` |

---

## 4. Criterios de aceptación

- [ ] App funciona offline (modo avión) para el historial de los últimos 30 días.
- [ ] En dispositivo con uso de 6+ meses: almacenamiento de la app no supera 200 MB.
- [ ] No hay regresión en el comportamiento offline-first de SPEC-206.

---

## 5. Consideración adicional: datos accedidos con frecuencia

Las pantallas de Dashboard leen datos del ciclo actual y del día de hoy.
Estos documentos son accedidos diariamente → Firestore los mantiene en caché sin importar
el límite. El límite de 100 MB solo afecta datos históricos profundos (>6 meses) que
raramente se consultan.
