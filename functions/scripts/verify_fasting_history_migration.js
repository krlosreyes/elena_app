// FIRE-06 (auditoría técnica 21-jul, P1): verificación de integridad
// de la migración SPEC-217/SPEC-222 antes de considerar cualquier
// borrado de la colección plana `fasting_history`.
//
// QUÉ HACE (SOLO LECTURA — no escribe ni borra nada):
//   1. Cuenta cuántos documentos hay en la colección plana `fasting_history`.
//   2. Para una muestra de esos documentos, busca su equivalente en
//      `users/{userId}/fasting_history/{docId}` (mismo docId — el
//      migrador usa `subCol.doc(doc.id)`, ver
//      lib/src/features/fasting/data/fasting_history_migrator.dart).
//   3. Compara los campos clave (startTime, endTime, isFasting) entre
//      ambas copias.
//   4. Imprime un reporte: cuántos coinciden, cuántos faltan en la
//      subcolección, y cuántos tienen datos distintos.
//
// CÓMO CORRERLO:
//   1. Necesitás credenciales de administrador del proyecto. La forma
//      más simple: Firebase Console → Configuración del proyecto →
//      Cuentas de servicio → "Generar nueva clave privada" → guardá el
//      JSON en un lugar seguro FUERA del repo (nunca lo commitees).
//   2. Corré, desde la carpeta functions/ (ya tiene firebase-admin
//      instalado en node_modules):
//
//        GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/tu-clave.json" \
//        node scripts/verify_fasting_history_migration.js
//
//   3. Parámetros opcionales por variable de entorno:
//        SAMPLE_SIZE=500   (default 500 — cuántos docs comparar en detalle)
//        PAGE_SIZE=450     (default 450 — mismo tamaño de página que el
//                           migrador, para no cargar memoria de más)
//
// QUÉ NO HACE:
//   - No borra nada, en ninguna de las dos colecciones.
//   - No modifica reglas ni Cloud Functions.
//   - No decide nada — solo junta evidencia para que la decisión de
//     cerrar FIRE-06 (borrar colección plana + regla + migrador) se
//     tome con datos reales, no a ciegas.

'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

const SAMPLE_SIZE = parseInt(process.env.SAMPLE_SIZE || '500', 10);
const PAGE_SIZE = parseInt(process.env.PAGE_SIZE || '450', 10);

function tsToIso(v) {
  if (v == null) return null;
  if (typeof v.toDate === 'function') return v.toDate().toISOString();
  return String(v);
}

async function countLegacyDocs() {
  const snap = await db.collection('fasting_history').count().get();
  return snap.data().count;
}

/**
 * Trae una muestra de hasta `sampleSize` documentos de la colección
 * plana, paginando de a `PAGE_SIZE` (mismo patrón que el migrador) para
 * no traer todo a memoria si la colección es grande.
 */
async function sampleLegacyDocs(sampleSize) {
  const docs = [];
  let lastDoc = null;

  while (docs.length < sampleSize) {
    let query = db
      .collection('fasting_history')
      .orderBy('__name__')
      .limit(PAGE_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const page = await query.get();
    if (page.empty) break;

    for (const doc of page.docs) {
      docs.push(doc);
      if (docs.length >= sampleSize) break;
    }
    lastDoc = page.docs[page.docs.length - 1];
    if (page.docs.length < PAGE_SIZE) break;
  }

  return docs;
}

function compareFields(legacy, migrated) {
  const diffs = [];
  const fieldsToCompare = ['startTime', 'endTime', 'isFasting'];
  for (const field of fieldsToCompare) {
    const a = legacy[field];
    const b = migrated[field];
    const aIso = a && typeof a.toDate === 'function' ? tsToIso(a) : a;
    const bIso = b && typeof b.toDate === 'function' ? tsToIso(b) : b;
    if (JSON.stringify(aIso) !== JSON.stringify(bIso)) {
      diffs.push({ field, legacy: aIso, migrated: bIso });
    }
  }
  return diffs;
}

async function main() {
  console.log('FIRE-06 — verificación de integridad fasting_history\n');

  const totalLegacy = await countLegacyDocs();
  console.log(`Total de documentos en la colección plana: ${totalLegacy}`);

  if (totalLegacy === 0) {
    console.log(
      '\nLa colección plana está vacía. FIRE-06 se puede cerrar: ' +
        'ya se puede borrar la regla de Firestore, el migrador y su ' +
        'invocación en FastingNotifier._init().',
    );
    return;
  }

  const sampleSize = Math.min(SAMPLE_SIZE, totalLegacy);
  console.log(`Comparando una muestra de ${sampleSize} documentos...\n`);

  const legacyDocs = await sampleLegacyDocs(sampleSize);

  let matched = 0;
  let missing = 0;
  let mismatched = 0;
  const missingDetails = [];
  const mismatchDetails = [];
  const usersSeen = new Set();
  let skippedNoUserId = 0;

  for (const doc of legacyDocs) {
    const legacyData = doc.data();
    const userId = legacyData.userId;
    if (!userId) {
      skippedNoUserId++;
      continue;
    }
    usersSeen.add(userId);

    const migratedSnap = await db
      .collection('users')
      .doc(userId)
      .collection('fasting_history')
      .doc(doc.id)
      .get();

    if (!migratedSnap.exists) {
      missing++;
      missingDetails.push({ docId: doc.id, userId });
      continue;
    }

    const diffs = compareFields(legacyData, migratedSnap.data());
    if (diffs.length > 0) {
      mismatched++;
      mismatchDetails.push({ docId: doc.id, userId, diffs });
    } else {
      matched++;
    }
  }

  console.log('─── Resultado ───────────────────────────────────────');
  console.log(`Documentos comparados:     ${legacyDocs.length}`);
  console.log(`Usuarios distintos:        ${usersSeen.size}`);
  console.log(`Coinciden exactamente:     ${matched}`);
  console.log(`Faltan en subcolección:    ${missing}`);
  console.log(`Datos distintos:           ${mismatched}`);
  if (skippedNoUserId > 0) {
    console.log(`Sin userId (omitidos):     ${skippedNoUserId}`);
  }

  if (missing > 0) {
    console.log('\nEjemplos de documentos faltantes (máx 20):');
    missingDetails.slice(0, 20).forEach((m) => {
      console.log(`  - doc ${m.docId} (userId ${m.userId})`);
    });
  }

  if (mismatched > 0) {
    console.log('\nEjemplos de documentos con datos distintos (máx 20):');
    mismatchDetails.slice(0, 20).forEach((m) => {
      console.log(`  - doc ${m.docId} (userId ${m.userId})`);
      m.diffs.forEach((d) => {
        console.log(
          `      ${d.field}: plana=${JSON.stringify(d.legacy)} vs subcolección=${JSON.stringify(d.migrated)}`,
        );
      });
    });
  }

  console.log('\n─── Veredicto ───────────────────────────────────────');
  if (missing === 0 && mismatched === 0) {
    console.log(
      `Los ${legacyDocs.length} documentos de la muestra migraron ` +
        'correctamente. Si esta muestra te da confianza suficiente ' +
        '(o si preferís correr con SAMPLE_SIZE más alto / igual al ' +
        `total de ${totalLegacy} para verificar el 100%), FIRE-06 queda ` +
        'listo para pasar a la fase de borrado: regla de Firestore + ' +
        'FastingHistoryMigrator + su invocación en FastingNotifier._init().',
    );
  } else {
    console.log(
      'Hay documentos faltantes o con diferencias — NO borrar la ' +
        'colección plana todavía. Investigar los casos listados arriba ' +
        '(probable causa: usuarios que nunca volvieron a abrir la app ' +
        'desde SPEC-217, o un batch que falló a mitad de camino).',
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error corriendo la verificación:', err);
    process.exit(1);
  });
