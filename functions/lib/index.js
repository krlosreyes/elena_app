"use strict";
// ElenaApp — Cloud Functions
// SPEC-207: Borrado en cascada al eliminar cuenta (GDPR Art.17 / LGPD Art.18)
// SPEC-217: Migración fasting_history plana → subcolección users/{uid}/fasting_history
// SPEC-248: Añadidas subcolecciones faltantes: app_state, fasting_checkins,
//           sleep_routines, post_reads (creadas post-SPEC-207)
// SEC-02 (auditoría 2026-07-11): trigger onUserCreated que fija trialExpiresAt
//         como custom claim server-side, inmune a manipulación del reloj local.
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserDeleted = exports.onUserCreated = exports.migrateFastingHistory = void 0;
const admin = require("firebase-admin");
// onUserDeleted es un trigger v1 — no existe en firebase-functions/v2.
// Se importa auth desde v1 y https desde v2 para coexistir en el mismo archivo.
const v1_1 = require("firebase-functions/v1");
const v2_1 = require("firebase-functions/v2");
admin.initializeApp();
// ─── Constantes ─────────────────────────────────────────────────────────────
/** Máximo de docs por batch. Firestore limita a 500; dejamos margen. */
const BATCH_SIZE = 400;
/**
 * SEC-02: duración del trial en días. Debe mantenerse sincronizada
 * manualmente con `kTrialDurationDays` en
 * lib/src/features/billing/application/feature_gate.dart (Dart no puede
 * importar este valor de TypeScript ni viceversa). Si se cambia acá,
 * cambiar también allá.
 */
const TRIAL_DURATION_DAYS = 14;
const TRIAL_DURATION_MILLIS = TRIAL_DURATION_DAYS * 24 * 60 * 60 * 1000;
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
    "app_state", // SPEC-228: coaching state, cheat_day, sleep_wakeup, migrations
    "fasting_checkins", // SPEC-248: check-ins de coaching de ayuno
    "sleep_routines", // SPEC-248: rutinas de coaching de sueño
    "post_reads", // SPEC-248: historial de artículos leídos (SPEC-205)
    // Ayuno
    "fasting_history", // SPEC-217: nueva subcolección (reemplaza colección plana)
];
// ─── Helpers ────────────────────────────────────────────────────────────────
/**
 * Borra todos los documentos de una colección en batches.
 * Itera hasta que no queden docs.
 */
async function deleteCollection(db, colRef) {
    let totalDeleted = 0;
    let snapshot = await colRef.limit(BATCH_SIZE).get();
    while (!snapshot.empty) {
        const batch = db.batch();
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
async function deleteLegacyFlatFastingHistory(db, uid) {
    const colRef = db.collection("fasting_history");
    let totalDeleted = 0;
    let snapshot = await colRef.where("userId", "==", uid).limit(BATCH_SIZE).get();
    while (!snapshot.empty) {
        const batch = db.batch();
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
 * FB-05 (auditoría independiente 2026-07-11): esta función quedó desplegada
 * de forma permanente como endpoint HTTP público sin ninguna autenticación —
 * cualquiera con la URL podía invocarla en bucle (costo arbitrario / DoS de
 * facturación) o forzar recomputación masiva. Se exige ahora un secreto
 * compartido en el header `x-migration-secret`, configurado vía
 * `firebase functions:config:set migration.secret="..."` o la variable de
 * entorno `MIGRATION_SECRET` del entorno de despliegue. Dado que la
 * migración SPEC-217 inc3 ya se ejecutó en producción, lo recomendado a
 * mediano plazo (TODO-SPEC-217-inc5) es eliminar este export por completo.
 *
 * Uso: POST https://<region>-<project>.cloudfunctions.net/migrateFastingHistory
 *      Header: x-migration-secret: <MIGRATION_SECRET>
 */
exports.migrateFastingHistory = v2_1.https.onRequest(async (req, res) => {
    const expectedSecret = process.env.MIGRATION_SECRET;
    const providedSecret = req.get("x-migration-secret");
    if (!expectedSecret || providedSecret !== expectedSecret) {
        res.status(403).json({ error: "forbidden" });
        return;
    }
    const db = admin.firestore();
    let totalMigrated = 0;
    let totalSkipped = 0;
    const snapshot = await db.collection("fasting_history").get();
    const batchSize = 400;
    let batch = db.batch();
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
// ─── SEC-02: trial server-side ──────────────────────────────────────────────
/**
 * SEC-02 (auditoría 2026-07-11): el trial de 14 días se calculaba 100% en el
 * cliente comparando `DateTime.now()` contra `createdAt` (ver
 * lib/src/features/billing/application/billing_providers.dart). Un usuario
 * puede atrasar el reloj del dispositivo —o reinstalar la app, que borra el
 * high-water-mark de SharedPreferences— para congelar o resetear el trial
 * indefinidamente.
 *
 * Este trigger corre en el servidor al crear la cuenta (inmune a manipulación
 * de reloj del cliente) y fija `trialExpiresAt` como custom claim del usuario:
 * `createdAt` (hora de Auth, no del dispositivo) + TRIAL_DURATION_DAYS.
 *
 * El claim queda expuesto en el ID token del usuario
 * (`getIdTokenResult().claims.trialExpiresAt`, en milisegundos epoch), pero
 * los custom claims solo se reflejan en el token la PRÓXIMA vez que se
 * refresca (fuerza de refresco: `getIdTokenResult(true)`) — el token emitido
 * en el instante mismo del signup puede no incluirlo todavía si el cliente
 * lo pide antes de que este trigger termine de correr. El wiring del lado
 * cliente para consumir este claim queda pendiente (ver nota en
 * billing_providers.dart) — requiere manejar ese caso de carrera con un
 * refresh forzado y fallback al cálculo local mientras el claim no exista
 * (p.ej. cuentas creadas antes de desplegar este trigger).
 *
 * No falla el flujo de creación de cuenta si `setCustomUserClaims` falla:
 * solo se loguea el error. El cliente sigue teniendo su cálculo local como
 * fallback (ver billing_providers.dart) mientras no se conecte a este claim.
 */
exports.onUserCreated = v1_1.auth.user().onCreate(async (user, _context) => {
    const uid = user.uid;
    const log = (msg) => console.log(`[SEC-02][uid:${uid}] ${msg}`);
    const createdAtTimestamp = user.metadata.creationTime
        ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime))
        : admin.firestore.Timestamp.now();
    const trialExpiresAtMillis = createdAtTimestamp.toMillis() + TRIAL_DURATION_MILLIS;
    try {
        await admin.auth().setCustomUserClaims(uid, { trialExpiresAt: trialExpiresAtMillis });
        log(`trialExpiresAt claim seteado: ${trialExpiresAtMillis} (createdAt + ${TRIAL_DURATION_DAYS}d)`);
    }
    catch (e) {
        log(`error seteando custom claim trialExpiresAt — ${e}`);
    }
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
exports.onUserDeleted = v1_1.auth.user().onDelete(async (user, _context) => {
    const uid = user.uid;
    const db = admin.firestore();
    const log = (msg) => console.log(`[SPEC-207][uid:${uid}] ${msg}`);
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
    }
    catch (e) {
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
//# sourceMappingURL=index.js.map