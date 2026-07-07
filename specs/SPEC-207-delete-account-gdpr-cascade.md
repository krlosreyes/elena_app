# SPEC-207 — Borrado de cuenta en cascada (GDPR / derecho al olvido)

**Estado:** IMPLEMENTED (2026-06-14) — GDPR delete account cascade + tests. commit d62d31a.
**Versión:** 1.0
**Tipo:** Seguridad / Privacidad — P0 bloqueante para usuarios reales.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~2 h (Cloud Function 1.5 h + cliente 30 min)
**Depende de:** Firebase Auth, Firestore, Cloud Functions Gen 2
**Bloquea:** lanzamiento con usuarios reales

---

## 1. Problema

`deleteAccount()` en `firebase_auth_repository.dart` solo borra `users/{uid}`.
Quedan huérfanos en Firestore:

| Colección | Ruta | Riesgo |
|-----------|------|--------|
| `fasting_history` | plana (`fasting_history/{docId}` con campo `userId`) | **Inaccesible desde árbol del usuario. No puede borrarse en cliente sin query.** |
| `sleep_history` | `users/{uid}/sleep_history/` | subcolección no borrada en cascada |
| `nutrition_history` | `users/{uid}/nutrition_history/` | ídem |
| `hydration_history` | `users/{uid}/hydration_history/` | ídem |
| `exercise_history` | `users/{uid}/exercise_history/` | ídem |
| `biometric_history` | `users/{uid}/biometric_history/` | ídem |
| `metabolic_cycles` | `users/{uid}/metabolic_cycles/` | ídem |
| `daily_summary` | `users/{uid}/daily_summary/` | ídem |
| `streak_history` | `users/{uid}/streak_history/` | ídem |

Datos de salud sensibles (peso, grasa corporal, sueño, hábitos alimenticios) permanecen
en Firestore indefinidamente tras la eliminación de cuenta. Violación del Art. 17 GDPR
("derecho al olvido") y Art. 18 LGPD.

---

## 2. Solución

### inc1 — Cloud Function `onUserDeleted` (backend, principal)

Trigger: `auth.user().onDelete()` en Firebase Cloud Functions Gen 2.

```typescript
// functions/src/index.ts
import { auth } from "firebase-functions/v2";
import { getFirestore, FieldPath } from "firebase-admin/firestore";

export const onUserDeleted = auth.user().onDeleted(async (event) => {
  const uid = event.data.uid;
  const db = getFirestore();

  // 1. Subcolecciones bajo users/{uid}
  const subcollections = [
    "sleep_history",
    "nutrition_history",
    "hydration_history",
    "exercise_history",
    "biometric_history",
    "metabolic_cycles",
    "daily_summary",
    "streak_history",
  ];

  for (const sub of subcollections) {
    await deleteCollection(db, `users/${uid}/${sub}`);
  }

  // 2. Documento raíz del usuario
  await db.doc(`users/${uid}`).delete();

  // 3. fasting_history — colección plana con campo userId
  await deleteCollectionWhere(db, "fasting_history", "userId", uid);
});

async function deleteCollection(db: FirebaseFirestore.Firestore, path: string) {
  const ref = db.collection(path);
  let snapshot = await ref.limit(500).get();
  while (!snapshot.empty) {
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    snapshot = await ref.limit(500).get();
  }
}

async function deleteCollectionWhere(
  db: FirebaseFirestore.Firestore,
  collection: string,
  field: string,
  value: string,
) {
  const ref = db.collection(collection).where(field, "==", value);
  let snapshot = await ref.limit(500).get();
  while (!snapshot.empty) {
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    snapshot = await ref.limit(500).get();
  }
}
```

### inc2 — Best-effort en cliente mientras no está desplegada la función

En `firebase_auth_repository.dart`, antes de `user.delete()`:

```dart
// Best-effort: borrar fasting_history del cliente (puede tardar o fallar en red lenta).
// La Cloud Function (SPEC-207) es la fuente de verdad para el borrado completo.
await _deleteFastingHistoryForUser(user.uid);
```

```dart
Future<void> _deleteFastingHistoryForUser(String uid) async {
  try {
    final query = _firestore
        .collection('fasting_history')
        .where('userId', isEqualTo: uid)
        .limit(500);
    QuerySnapshot snap;
    do {
      snap = await query.get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == 500);
  } catch (e) {
    // No-op: la Cloud Function lo limpia de todas formas.
    AppLogger.warning('[deleteAccount] fasting_history best-effort falló: $e');
  }
}
```

### inc3 — Firestore Security Rules: verificar que subcolecciones exigen auth

```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
match /fasting_history/{docId} {
  allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
}
```

Confirmar que ninguna regla permite lectura cross-user en `fasting_history`.

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `functions/src/index.ts` (nuevo o existente) | Cloud Function `onUserDeleted` |
| `lib/src/features/auth/data/firebase_auth_repository.dart` | `_deleteFastingHistoryForUser` best-effort |
| `firestore.rules` | Verificar/reforzar reglas de `fasting_history` |

---

## 4. Criterios de aceptación

- [ ] Al eliminar cuenta, Firestore confirma (en Emulator o consola) que `users/{uid}` y todas las subcolecciones quedan vacías dentro de 60 s.
- [ ] `fasting_history` sin documentos con `userId == uid` tras la eliminación.
- [ ] Cliente no lanza excepción al llamar `deleteAccount()` en modo offline (best-effort silencia el error de red).
- [ ] Security Rules: un segundo usuario autenticado no puede leer `fasting_history/{docId}` de otro usuario.

---

## 5. Notas

- La Cloud Function debe desplegarse **antes** de dar acceso a usuarios reales. Sin ella, los datos de salud son permanentes.
- `CACHE_SIZE_UNLIMITED` no afecta el borrado: la caché local se limpia al cerrar sesión.
- No se borra la cuenta de Firebase Auth aquí — eso lo hace `user.delete()` en el cliente que ya existe.
