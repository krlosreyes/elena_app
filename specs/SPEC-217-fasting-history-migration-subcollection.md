# SPEC-217 — Migrar fasting_history a subcolección users/{uid}/fasting_history

**Estado:** APPROVED-DESIGN (2026-06-14)
**Versión:** 1.0
**Tipo:** Deuda técnica P2 — Colección plana diverge del patrón de todos los demás pilares.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~3 h (Cloud Function de migración + cliente + rules)
**Depende de:** SPEC-207 (GDPR — debe ejecutarse primero para que el borrado sea correcto)
**Nota:** Este SPEC es Ola 2+. No bloquea el lanzamiento inicial pero debe ejecutarse antes
de tener usuarios de larga data para evitar migraciones complejas más adelante.

---

## 1. Problema

Todos los pilares siguen el patrón `users/{uid}/{pilar}_history/{docId}`.
El ayuno usa `fasting_history/{docId}` con un campo `userId` en el documento.

| Pilar | Ruta |
|-------|------|
| Sueño | `users/{uid}/sleep_history/{docId}` ✓ |
| Nutrición | `users/{uid}/nutrition_history/{docId}` ✓ |
| Hidratación | `users/{uid}/hydration_history/{docId}` ✓ |
| Ejercicio | `users/{uid}/exercise_history/{docId}` ✓ |
| **Ayuno** | `fasting_history/{docId}` con `userId` ✗ |

Esta divergencia causa:
1. **GDPR:** No se puede borrar en cascada desde `users/{uid}`. Requiere query extra.
2. **Security Rules complejas:** No puede usar el path `{uid}` para autorizar; necesita
   `resource.data.userId == request.auth.uid` (más costoso y más fácil de olvidar).
3. **Riesgo de filtración cross-user:** Si las rules de `fasting_history` son incorrectas,
   un usuario puede leer los ayunos de otro (no pasa con las subcolecciones).
4. **Inconsistencia de código:** `FastingIntervalRepositoryImpl` tiene lógica especial
   de filtrado por `userId` que el resto no necesita.

---

## 2. Solución

### inc1 — Actualizar el source de Firestore (cliente)

```dart
// firestore_fasting_interval_v1_source.dart
// ANTES
CollectionReference _col() => _db.collection('fasting_history');

// DESPUÉS
CollectionReference _col(String userId) =>
    _db.collection('users').doc(userId).collection('fasting_history');
```

Eliminar el filtro `where('userId', isEqualTo: userId)` de todas las queries —
la subcolección ya está aislada por `uid`.

### inc2 — Nuevos documentos sin campo `userId` (ya no necesario)

El mapper puede dejar de escribir `userId` en los documentos nuevos (o mantenerlo
por retrocompatibilidad durante la migración).

### inc3 — Cloud Function de migración de datos históricos

```typescript
// functions/src/migrate_fasting_history.ts
// Función one-shot: copiar fasting_history plana a users/{uid}/fasting_history
export const migrateFastingHistory = https.onRequest(async (req, res) => {
  const db = getFirestore();
  const snapshot = await db.collection('fasting_history').get();
  const batches: WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const userId = data.userId;
    if (!userId) continue;

    const newRef = db
      .collection('users').doc(userId)
      .collection('fasting_history').doc(doc.id);
    batch.set(newRef, data);
    count++;

    if (count % 400 === 0) {
      batches.push(batch);
      batch = db.batch();
    }
  }
  batches.push(batch);

  for (const b of batches) await b.commit();

  res.json({ migrated: count });
});
```

### inc4 — Actualizar Security Rules

```
// ANTES
match /fasting_history/{docId} {
  allow read, write: if request.auth != null
      && request.auth.uid == resource.data.userId;
}

// DESPUÉS (mantener regla vieja durante transición, luego eliminar)
match /users/{uid}/fasting_history/{docId} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

### inc5 — Eliminar colección plana después de verificar migración

Una vez validado que todos los documentos existen en las subcolecciones:
```typescript
// Función de limpieza (ejecutar 7 días después de la migración)
await deleteCollection(db, 'fasting_history');
```

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/dashboard/data/sources/firestore_fasting_interval_v1_source.dart` | Ruta a subcolección |
| `firestore.rules` | Añadir regla subcolección, mantener regla plana durante transición |
| `functions/src/index.ts` | Función de migración one-shot |

---

## 4. Criterios de aceptación

- [ ] Nuevos documentos de ayuno se crean en `users/{uid}/fasting_history/`.
- [ ] Lectura de ayunos históricos funciona correctamente desde la subcolección.
- [ ] SPEC-207 `deleteAccount` ya no necesita query especial de `fasting_history` plana.
- [ ] Security Rules: un usuario no puede leer la `fasting_history` de otro.
- [ ] 0 documentos en `fasting_history` plana después de la limpieza.

---

## 5. Plan de rollback

Si la migración falla: la colección plana sigue intacta (la migración es copia, no move).
El cliente puede volver a la ruta plana con un cambio de una línea.
