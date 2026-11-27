// SPEC-306 — Recalcula el % de grasa de los usuarios existentes con la
// fórmula única compartida con metamorfosisvital.com.co (US Navy métrica,
// motor spec-118-v1) y activa el aviso en la app.
//
// Reglas (iguales a lib/src/core/engine/metabolic_formulas.dart):
//   Hombres: 495 / (1.0324 − 0.19077·log10(cintura − cuello)
//                         + 0.15456·log10(estatura)) − 450
//   Mujeres: 495 / (1.29579 − 0.35004·log10(cintura + cadera − cuello)
//                          + 0.22100·log10(estatura)) − 450
//   Mujeres sin cadera: NO se calcula (bodyFatPercentage = null) y el
//   aviso le pide la medida de cadera.
//   Mínimo 2 %, máximo 60 %. Cintura ≤ cuello en hombres → null.
//
// Por defecto es un ensayo: no escribe nada, imprime los cambios y
// guarda un respaldo JSON de los valores actuales en scripts/backups/.
//
// CÓMO CORRERLO:
//   cd functions
//   GOOGLE_APPLICATION_CREDENTIALS=~/elena-admin-key.json node scripts/spec306_recalcular_grasa.js
//   GOOGLE_APPLICATION_CREDENTIALS=~/elena-admin-key.json node scripts/spec306_recalcular_grasa.js --aplicar

'use strict';

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
}
const db = admin.firestore();
const APPLY = process.argv.includes('--aplicar');
const ENGINE_VERSION = 'spec-118-v1';

const num = (v) => (typeof v === 'number' && Number.isFinite(v) && v > 0 ? v : null);
const log10 = (x) => Math.log(x) / Math.LN10;

function bodyFatNavy({ heightCm, waistCm, neckCm, hipCm, isMale }) {
  if (!heightCm || !waistCm || !neckCm) return null;
  if (isMale) {
    if (waistCm - neckCm <= 0) return null;
    const d = 1.0324 - 0.19077 * log10(waistCm - neckCm) + 0.15456 * log10(heightCm);
    return Math.max(2, 495 / d - 450);
  }
  if (!hipCm) return null;
  if (waistCm + hipCm - neckCm <= 0) return null;
  const d = 1.29579 - 0.35004 * log10(waistCm + hipCm - neckCm) + 0.221 * log10(heightCm);
  return Math.max(2, 495 / d - 450);
}

function read(doc) {
  const d = doc.data() || {};
  const bio = d.bio || {};
  const gender = String(d.gender || d.genderCanonical || '').toUpperCase();
  return {
    isMale: gender === 'M' || gender === 'MALE',
    heightCm: num(d.height) ?? num(bio.heightCm),
    waistCm: num(d.waistCircumference) ?? num(bio.waistCm),
    neckCm: num(d.neckCircumference) ?? num(bio.neckCm),
    hipCm: num(d.hipCircumference) ?? num(bio.hipCm),
    previous: d.bodyFatPercentage ?? bio.bodyFatPct ?? null,
    alreadyDone: d.metabolicEngineVersion === ENGINE_VERSION,
  };
}

async function main() {
  console.log(APPLY ? 'MODO APLICAR — se escribirán cambios.\n' : 'ENSAYO — no se escribe nada.\n');
  const snap = await db.collection('users').get();
  const backup = [];
  const changes = [];
  for (const doc of snap.docs) {
    const u = read(doc);
    if (u.alreadyDone) continue;
    const raw = bodyFatNavy(u);
    const next = raw == null ? null : Math.round(Math.min(60, raw) * 100) / 100;
    const needsHip = !u.isMale && u.hipCm == null;
    backup.push({ uid: doc.id, bodyFatPercentage: u.previous });
    changes.push({ uid: doc.id, sexo: u.isMale ? 'H' : 'M', antes: u.previous, despues: next, needsHip });
  }

  const dir = path.join(__dirname, 'backups');
  fs.mkdirSync(dir, { recursive: true });
  const file = path.join(dir, `spec306_backup_${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
  fs.writeFileSync(file, JSON.stringify(backup, null, 2));
  console.table(changes);
  console.log(`\n${changes.length} usuarios. Respaldo: ${file}`);
  console.log(`Mujeres sin cadera (quedan sin % y verán el aviso): ${changes.filter((c) => c.needsHip).length}`);

  if (!APPLY) {
    console.log('\nNada escrito. Repite con --aplicar para guardar.');
    return;
  }

  let batch = db.batch();
  let n = 0;
  for (const c of changes) {
    const ref = db.collection('users').doc(c.uid);
    batch.update(ref, {
      bodyFatPercentage: c.despues,
      'bio.bodyFatPct': c.despues,
      'bio.leanMassPct': c.despues == null ? null : 100 - c.despues,
      confidenceLevel: c.despues == null ? 'BAJA' : 'ALTA',
      metabolicEngineVersion: ENGINE_VERSION,
      calcUpdateNotice: {
        pending: true,
        needsHip: c.needsHip,
        previous: c.antes,
        next: c.despues,
        at: admin.firestore.FieldValue.serverTimestamp(),
      },
    });
    n++;
    if (n % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  await batch.commit();
  console.log(`\nListo: ${n} usuarios actualizados.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
