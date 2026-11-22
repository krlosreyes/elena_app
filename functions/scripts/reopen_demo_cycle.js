// Reabre el día metabólico del ayuno en curso de la cuenta demo (22-nov-2026).
//
// Contexto: seed_demo_reviewer.js descartó el día metabólico que empezó
// con el ayuno abierto, porque la app lo había cerrado sola dos días
// después (fallbackAbsolute) aunque el ayuno siguiera abierto. Quedó un
// ayuno sin su día metabólico.
//
// Este script toma ese documento de la copia de seguridad y lo escribe
// como ABIERTO, igual que lo escribe la app al iniciar un ayuno:
// cycleId + startedAt (desplazados los mismos días), fastingProtocol y meta.
// Sin closedAt, closureReason, score, magnitudes ni feedback.
//
// Comprobaciones antes de escribir:
//   - la cuenta es reviewer@demo.elenaapp.com;
//   - no hay ya un día metabólico abierto;
//   - el inicio desplazado coincide con el inicio del ayuno abierto actual.
//
// USO (desde elena_app/functions)
//   GOOGLE_APPLICATION_CREDENTIALS=~/elena-admin-key.json node scripts/reopen_demo_cycle.js scripts/backups/demo-XXXX.json
//   …y con --apply para escribir.

'use strict';

const fs = require('fs');
const admin = require('firebase-admin');
const { shiftDocId, DAY_MS } = require('./seed_demo_reviewer.js');

const DEMO_EMAIL = 'reviewer@demo.elenaapp.com';
const CLOSURE_FIELDS = ['closedAt', 'closureReason', 'fastingDurationHours',
  'feedingWindowHours', 'dailyScore', 'pillarsCompleted', 'magnitudes',
  'feedback', 'liveScore'];

async function main() {
  const [file] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
  const apply = process.argv.includes('--apply');
  if (!file) { console.error('Indica el archivo de copia: scripts/backups/demo-….json'); process.exit(1); }

  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();
  const { Timestamp } = admin.firestore;

  const user = await admin.auth().getUserByEmail(DEMO_EMAIL);
  const dump = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (dump.uid !== user.uid) { console.error('ABORTADO: la copia es de otra cuenta.'); process.exit(1); }
  const userRef = db.collection('users').doc(user.uid);

  // Ayuno abierto actual (ya desplazado).
  const fasts = await userRef.collection('fasting_history').where('endTime', '==', null).get();
  const open = fasts.docs.map((d) => d.data()).filter((d) => d.isFasting === true);
  if (open.length !== 1) { console.error(`ABORTADO: se esperaba 1 ayuno abierto, hay ${open.length}.`); process.exit(1); }
  const fastStart = open[0].startTime.toMillis();

  // ¿Ya hay un día metabólico abierto?
  const cycles = await userRef.collection('metabolic_cycles').get();
  const alreadyOpen = cycles.docs.filter((d) => d.data().startedAt && !d.data().closedAt);
  if (alreadyOpen.length) { console.log(`Ya hay un día metabólico abierto (${alreadyOpen[0].id}). Nada que hacer.`); return; }

  // Documento original en la copia: el que empezó con el ayuno abierto.
  const origFast = dump.docs.find((d) => d.path.includes('/fasting_history/') &&
    d.data.endTime == null && d.data.isFasting === true);
  const origStart = origFast.data.startTime.__ts;
  const days = Math.round((fastStart - origStart) / DAY_MS);
  const orig = dump.docs.find((d) => d.path.includes('/metabolic_cycles/') &&
    d.data.startedAt && Math.abs(d.data.startedAt.__ts - origStart) < 1000);
  if (!orig) { console.error('ABORTADO: no encontré en la copia el día metabólico de ese ayuno.'); process.exit(1); }

  const newId = shiftDocId(orig.data.cycleId, days);
  const data = { ...orig.data };
  for (const f of CLOSURE_FIELDS) delete data[f];
  data.cycleId = newId;
  data.startedAt = Timestamp.fromMillis(orig.data.startedAt.__ts + days * DAY_MS);

  console.log(`Ayuno abierto desde:   ${new Date(fastStart).toISOString()}`);
  console.log(`Día metabólico nuevo:  ${newId}  (desplazado +${days} días)`);
  console.log(`Campos: ${Object.keys(data).sort().join(', ')}`);
  if (Math.abs(data.startedAt.toMillis() - fastStart) > 1000) {
    console.error('ABORTADO: el inicio del día metabólico no coincide con el del ayuno.'); process.exit(1);
  }
  if (!apply) { console.log('\nModo inspección: no se escribió nada. Agrega --apply para escribir.'); return; }
  await userRef.collection('metabolic_cycles').doc(newId).set(data);
  console.log('\nListo: día metabólico reabierto.');
}

main().catch((e) => { console.error(e); process.exit(1); });
