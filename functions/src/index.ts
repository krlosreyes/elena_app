// ElenaApp — Cloud Functions
// SPEC-207: Borrado en cascada al eliminar cuenta (GDPR Art.17 / LGPD Art.18)
// SPEC-217: Migración fasting_history plana → subcolección users/{uid}/fasting_history
// SPEC-248: Añadidas subcolecciones faltantes: app_state, fasting_checkins,
//           sleep_routines, post_reads (creadas post-SPEC-207)
//
// Trigger onUserDeleted: auth.user().onDeleted — Firebase dispara automáticamente
// cuando el cliente llama user.delete() o cuando se elimina desde la consola.
//
// SPEC-207 colecciones borradas:
//   - users/{uid} y subcolecciones: sleep_history, nutrition_history,
//     hydration_history, exercise_history, biometric_history, metabolic_cycles,
//     daily_summary, streak_history, imr_history, fasting_history (SPEC-217),
//     protocol_adjustments, app_state (SPEC-228), fasting_checkins,
//     sleep_routines, post_reads (SPEC-248)
//   - fasting_history plana (SPEC-50.4 legacy) — por userId query (transición)
//
// SPEC-217 migrateFastingHistory: HTTP one-shot que copia docs de la colección
// plana `fasting_history` a `users/{uid}/fasting_history`. Ejecutar una sola vez
// en producción. Seguro de re-ejecutar (set idempotente por docId).
//
// El borrado usa batches de 400 docs para no superar el límite de 500 de Firestore.
// Se itera con while-loop hasta que no queden docs.

import * as admin from "firebase-admin";
// onUserDeleted es un trigger v1 — no existe en firebase-functions/v2.
// Se importa auth desde v1 y https desde v2 para coexistir en el mismo archivo.
import { auth } from "firebase-functions/v1";
import { EventContext } from "firebase-functions/v1";
import { https } from "firebase-functions/v2";
import { UserRecord } from "firebase-admin/auth";
import {
  Firestore,
  WriteBatch,
  CollectionReference,
  DocumentData,
} from "firebase-admin/firestore";

admin.initializeApp();

// ─── Constantes ─────────────────────────────────────────────────────────────

/** Máximo de docs por batch. Firestore limita a 500; dejamos margen. */
const BATCH_SIZE = 400;

/** Subcolecciones bajo users/{uid} que se eliminan en cascada. */
const USER_SUBCOLLECTIONS = [
  // Pilares
  "sleep_history",
  "nutrition_history",
  "hydration_history",
  "exercise_history",
  // Métricas y progreso
  "biometric_history",
  "metabolic_cycles",
  "daily_summary",
  "streak_history",
  "imr_history",
  // Configuración y coaching
  "protocol_adjustments",
  "app_state",         // SPEC-228: coaching state, cheat_day, sleep_wakeup, migrations
  "fasting_checkins",  // SPEC-248: check-ins de coaching de ayuno
  "sleep_routines",    // SPEC-248: rutinas de coaching de sueño
  "post_reads",        // SPEC-248: historial de artículos leídos (SPEC-205)
  // Ayuno
  "fasting_history",   // SPEC-217: nueva subcolección (reemplaza colección plana)
];

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Borra todos los documentos de una colección en batches.
 * Itera hasta que no queden docs.
 */
async function deleteCollection(
  db: Firestore,
  colRef: CollectionReference<DocumentData>,
): Promise<number> {
  let totalDeleted = 0;
  let snapshot = await colRef.limit(BATCH_SIZE).get();

  while (!snapshot.empty) {
    const batch: WriteBatch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    totalDeleted += snapshot.docs.length;
    snapshot = await colRef.limit(BATCH_SIZE).get();
  }

  return totalDeleted;
}

/**
 * SPEC-207/SPEC-217: Borra documentos de la colección PLANA fasting_history
 * donde userId == uid. Legacy (SPEC-50.4) — eliminar tras validar SPEC-217 inc5.
 *
 * Los nuevos documentos (SPEC-217) ya están en users/{uid}/fasting_history,
 * cubiertos por USER_SUBCOLLECTIONS. Este helper es solo para el legado.
 *
 * TODO-SPEC-217-inc5: eliminar esta función y su call en onUserDeleted
 * cuando la colección plana esté vacía.
 */
async function deleteLegacyFlatFastingHistory(
  db: Firestore,
  uid: string,
): Promise<number> {
  const colRef = db.collection("fasting_history");
  let totalDeleted = 0;
  let snapshot = await colRef.where("userId", "==", uid).limit(BATCH_SIZE).get();

  while (!snapshot.empty) {
    const batch: WriteBatch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    totalDeleted += snapshot.docs.length;
    snapshot = await colRef.where("userId", "==", uid).limit(BATCH_SIZE).get();
  }

  return totalDeleted;
}

/**
 * SPEC-217 inc3: función HTTP one-shot para migrar documentos históricos
 * de la colección plana `fasting_history` a `users/{uid}/fasting_history`.
 *
 * Segura de re-ejecutar (set idempotente por docId).
 * Después de validar: ejecutar inc5 (limpiar colección plana).
 *
 * Uso: POST https://<region>-<project>.cloudfunctions.net/migrateFastingHistory
 */
export const migrateFastingHistory = https.onRequest(async (req, res) => {
  const db = admin.firestore();
  let totalMigrated = 0;
  let totalSkipped = 0;

  const snapshot = await db.collection("fasting_history").get();

  const batchSize = 400;
  let batch: WriteBatch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const userId = data["userId"];
    if (!userId || typeof userId !== "string") {
      totalSkipped++;
      continue;
    }

    const newRef = db
      .collection("users")
      .doc(userId)
      .collection("fasting_history")
      .doc(doc.id);

    batch.set(newRef, data);
    batchCount++;
    totalMigrated++;

    if (batchCount >= batchSize) {
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  const result = { migrated: totalMigrated, skipped: totalSkipped };
  console.log("[SPEC-217] migrateFastingHistory:", result);
  res.json(result);
});

// ─── Cloud Function ──────────────────────────────────────────────────────────

/**
 * SPEC-207: Borra todos los datos del usuario cuando elimina su cuenta.
 *
 * Orden de borrado:
 * 1. Subcolecciones (los datos, primero — para no dejar docs huérfanos)
 * 2. Documento raíz users/{uid}
 * 3. Colección plana fasting_history (query por userId)
 *
 * Si falla algún paso, Firebase reintentará la función hasta 3 veces
 * (comportamiento por defecto de Cloud Functions event-driven).
 */
export const onUserDeleted = auth.user().onDelete(async (user: UserRecord, _context: EventContext) => {
  const uid = user.uid;
  const db = admin.firestore();
  const log = (msg: string) => console.log(`[SPEC-207][uid:${uid}] ${msg}`);

  log("Inicio borrado en cascada");

  // 1. Subcolecciones bajo users/{uid}
  for (const sub of USER_SUBCOLLECTIONS) {
    const colRef = db.collection("users").doc(uid).collection(sub);
    const deleted = await deleteCollection(db, colRef);
    log(`  ${sub}: ${deleted} docs eliminados`);
  }

  // 2. Documento raíz
  try {
    await db.collection("users").doc(uid).delete();
    log("  users/{uid}: doc raíz eliminado");
  } catch (e) {
    // Si ya fue eliminado por otra causa (ej. cliente lo borró), continuar.
    log(`  users/{uid}: no encontrado o ya borrado — ${e}`);
  }

  // 3. fasting_history plana legacy (SPEC-50.4 / SPEC-217 transición).
  //    Los docs nuevos ya van a users/{uid}/fasting_history (USER_SUBCOLLECTIONS).
  //    TODO-SPEC-217-inc5: eliminar cuando colección plana esté vacía.
  const fastingDeleted = await deleteLegacyFlatFastingHistory(db, uid);
  log(`  fasting_history (legacy plana): ${fastingDeleted} docs eliminados`);

  log("Borrado en cascada completado");
});
