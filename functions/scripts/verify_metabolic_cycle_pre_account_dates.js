// PROD-01/02/03a (auditoría técnica 21-jul, P0 sin fix dedicado — ver
// Addendum_Auditoria_ElenaApp_2026-07-22.docx §1 y §8): el síntoma
// reportado por Carlos fue un ciclo metabólico cerrado instantáneamente
// en "0/100" en una cuenta recién creada, con "Tu semana" mostrando
// fechas ANTERIORES a la creación de la cuenta y un ayuno de "142h".
// Ninguna revisión de código encontró una causa raíz atribuible —
// la única forma de confirmar si el síntoma sigue vivo es mirar los
// datos reales.
//
// QUÉ HACE (SOLO LECTURA — no escribe ni borra nada):
//   Para cada usuario (Firebase Auth):
//     1. Lee la fecha de creación de la cuenta (metadata.creationTime).
//     2. Revisa users/{uid}/metabolic_cycles — marca cualquier ciclo
//        cuyo startedAt sea ANTERIOR a la creación de la cuenta (el
//        síntoma exacto reportado: "fechas pre-cuenta").
//     3. Revisa users/{uid}/fasting_history — mismo chequeo sobre
//        startTime, y además marca cualquier intervalo con duración
//        sospechosamente larga (>72h) que podría explicar un "142h".
//     4. Marca cualquier ciclo cerrado con dailyScore=0 Y una duración
//        total (closedAt - startedAt) menor a 5 minutos — el patrón de
//        "cierre instantáneo".
//
// CÓMO CORRERLO (mismo procedimiento que verify_fasting_history_migration.js):
//   GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/tu-clave.json" \
//   node scripts/verify_metabolic_cycle_pre_account_dates.js
//
// QUÉ NO HACE: no borra, no modifica, no decide — solo junta evidencia
// para confirmar si PROD-01/02/03a sigue vivo en el HEAD actual.

'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();
const auth = admin.auth();

function toDate(v) {
  if (v == null) return null;
  if (typeof v.toDate === 'function') return v.toDate();
  return new Date(v);
}

async function listAllUsers() {
  const users = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    users.push(...page.users);
    pageToken = page.pageToken;
  } while (pageToken);
  return users;
}

async function checkUser(user) {
  const uid = user.uid;
  const createdAt = user.metadata.creationTime
    ? new Date(user.metadata.creationTime)
    : null;

  const findings = [];

  if (!createdAt) {
    findings.push({ type: 'sin-fecha-creacion', detail: 'No se pudo leer metadata.creationTime' });
    return { uid, createdAt, findings };
  }

  // ── metabolic_cycles ──────────────────────────────────────────────
  const cyclesSnap = await db
    .collection('users')
    .doc(uid)
    .collection('metabolic_cycles')
    .get();

  for (const doc of cyclesSnap.docs) {
    const d = doc.data();
    const startedAt = toDate(d.startedAt);
    const closedAt = toDate(d.closedAt);

    if (startedAt && startedAt < createdAt) {
      findings.push({
        type: 'ciclo-fecha-pre-cuenta',
        cycleId: doc.id,
        startedAt: startedAt.toISOString(),
        createdAt: createdAt.toISOString(),
      });
    }

    if (closedAt && startedAt) {
      const totalMinutes = (closedAt.getTime() - startedAt.getTime()) / 60000;
      if (d.dailyScore === 0 && totalMinutes < 5) {
        findings.push({
          type: 'cierre-instantaneo-0-100',
          cycleId: doc.id,
          startedAt: startedAt.toISOString(),
          closedAt: closedAt.toISOString(),
          totalMinutes: totalMinutes.toFixed(2),
        });
      }
    }
  }

  // ── fasting_history (subcolección migrada, SPEC-217) ─────────────
  const fastingSnap = await db
    .collection('users')
    .doc(uid)
    .collection('fasting_history')
    .get();

  for (const doc of fastingSnap.docs) {
    const d = doc.data();
    const startTime = toDate(d.startTime);
    const endTime = toDate(d.endTime);

    if (startTime && startTime < createdAt) {
      findings.push({
        type: 'ayuno-fecha-pre-cuenta',
        docId: doc.id,
        startTime: startTime.toISOString(),
        createdAt: createdAt.toISOString(),
      });
    }

    if (startTime && endTime) {
      const hours = (endTime.getTime() - startTime.getTime()) / 3600000;
      if (hours > 72) {
        findings.push({
          type: 'ayuno-duracion-sospechosa',
          docId: doc.id,
          startTime: startTime.toISOString(),
          endTime: endTime.toISOString(),
          hours: hours.toFixed(1),
        });
      }
    }
  }

  return { uid, createdAt, findings };
}

async function main() {
  console.log('PROD-01/02/03a — verificación de fechas pre-cuenta / cierre instantáneo\n');

  const users = await listAllUsers();
  console.log(`Usuarios encontrados (Firebase Auth): ${users.length}\n`);

  let usersWithFindings = 0;
  let totalFindings = 0;

  for (const user of users) {
    const result = await checkUser(user);
    if (result.findings.length > 0) {
      usersWithFindings++;
      totalFindings += result.findings.length;
      console.log(`─── uid ${result.uid} (email: ${user.email || 'sin email'}) ───`);
      console.log(`  Cuenta creada: ${result.createdAt ? result.createdAt.toISOString() : 'desconocido'}`);
      result.findings.forEach((f) => {
        console.log(`  [${f.type}]`, JSON.stringify(f));
      });
      console.log('');
    }
  }

  console.log('─── Resultado ───────────────────────────────────────');
  console.log(`Usuarios revisados:        ${users.length}`);
  console.log(`Usuarios con hallazgos:    ${usersWithFindings}`);
  console.log(`Hallazgos totales:         ${totalFindings}`);

  console.log('\n─── Veredicto ───────────────────────────────────────');
  if (totalFindings === 0) {
    console.log(
      'No se encontró ningún ciclo/ayuno con fecha pre-cuenta ni cierre ' +
        'instantáneo en 0/100 en ningún usuario. El síntoma reportado el ' +
        '21-jul no está presente en los datos actuales — probablemente ya ' +
        'fue corregido por alguno de los commits locales de esa sesión, o ' +
        'el build probado en el simulador no reflejaba el HEAD real.',
    );
  } else {
    console.log(
      'Hay evidencia real del síntoma — revisar los uid/cycleId listados ' +
        'arriba. El campo "type" indica cuál de los 3 patrones se detectó.',
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error corriendo la verificación:', err);
    process.exit(1);
  });
