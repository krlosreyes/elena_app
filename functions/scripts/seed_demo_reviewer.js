// Rejuvenece los datos de la cuenta demo de App Review (22-nov-2026).
//
// PROBLEMA
// --------
// La cuenta que usa el revisor de Apple (reviewer@demo.elenaapp.com) tiene
// datos reales cargados hace meses. Con el paso del tiempo la app los
// muestra "muertos": un ayuno abierto de +85 días, la semana en cero,
// tarjetas de Progreso vacías. Para el revisor eso es una app rota
// (guía 2.1).
//
// ENFOQUE: mover el tiempo, no inventar datos
// -------------------------------------------
// En vez de fabricar documentos (y arriesgar un campo mal escrito que la
// app ignore en silencio), el script toma los documentos que la PROPIA
// app escribió en esa cuenta y desplaza todas sus fechas N días enteros
// hacia adelante. Como el desplazamiento es en días enteros, se conservan
// la hora del día y el día de la semana; como se mueven todas las fechas
// juntas, ciclos, registros, racha e insignias siguen siendo coherentes
// entre sí.
//
// Se desplaza:
//   - todo campo Timestamp;
//   - toda cadena con fecha ISO ("2026-08-27" o "2026-08-27T21:00:00.000Z");
//   - todo entero con forma de epoch en milisegundos en campos de fecha;
//   - los IDs de documento que son fechas (p. ej. cycleId ISO, día "YYYY-MM-DD"):
//     se crea el documento con el ID nuevo y se borra el viejo.
//
// N se elige para que el ayuno abierto (o, si no hay, el último día
// metabólico cerrado) quede lo más cerca posible de hoy sin pasar al futuro.
//
// SEGURIDAD
// ---------
//   - Solo toca users/{uid} de la cuenta demo, buscada por email. Si el
//     email no existe o no coincide con DEMO_EMAIL, se detiene.
//   - Sin --apply solo INSPECCIONA y muestra el plan. No escribe nada.
//   - Con --apply guarda antes una copia completa en
//     scripts/backups/demo-<fecha>.json, que permite restaurar con --restore.
//
// USO (desde elena_app/functions)
//   GOOGLE_APPLICATION_CREDENTIALS=~/elena-admin-key.json node scripts/seed_demo_reviewer.js
//   GOOGLE_APPLICATION_CREDENTIALS=~/elena-admin-key.json node scripts/seed_demo_reviewer.js --apply
//   GOOGLE_APPLICATION_CREDENTIALS=~/elena-admin-key.json node scripts/seed_demo_reviewer.js --restore scripts/backups/demo-XXXX.json
//
// Correrlo de nuevo antes de cada envío a revisión.

'use strict';

const fs = require('fs');
const path = require('path');

const DEMO_EMAIL = 'reviewer@demo.elenaapp.com';
const DAY_MS = 24 * 60 * 60 * 1000;
/// Margen mínimo entre "ahora" y el inicio del ayuno abierto desplazado.
const MIN_FAST_AGE_MS = 2 * 60 * 60 * 1000;
/// Colecciones que no son de la cuenta (ni se leen ni se tocan).
const SKIP_COLLECTIONS = new Set(['fcm_tokens']);

// ─── Lógica pura (testeable sin Firestore) ──────────────────────────────

const RE_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;
const RE_DATETIME_PARTS =
  /^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})(\.\d{1,9})?(Z|[+-]\d{2}:?\d{2})?$/;
const DATE_KEY = /(At|Time|time|Date|date|Day|day|timestamp|Timestamp)$/;
const EPOCH_MIN = 1.4e12; // 2014
const EPOCH_MAX = 2.2e12; // 2039

function shiftDateString(s, days) {
  const m = RE_DATE.exec(s);
  if (m) {
    const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
    d.setUTCDate(d.getUTCDate() + days);
    return d.toISOString().slice(0, 10);
  }
  const dt = RE_DATETIME_PARTS.exec(s);
  if (dt) {
    // Se desplaza el "reloj de pared" del texto, sin reinterpretar zonas:
    // la fracción y el sufijo de zona (Z, -05:00 o nada) quedan idénticos.
    const [, date, time, frac = '', tz = ''] = dt;
    const t = Date.parse(`${date}T${time}Z`);
    if (Number.isNaN(t)) return s;
    const moved = new Date(t + days * DAY_MS).toISOString(); // YYYY-MM-DDTHH:MM:SS.mmmZ
    return `${moved.slice(0, 19)}${frac}${tz}`;
  }
  return s;
}

/**
 * Desplaza recursivamente un valor de Firestore.
 * `isTimestamp(v)` y `makeTimestamp(ms)` se inyectan para no depender del SDK.
 */
function shiftValue(v, days, key, ts) {
  if (v === null || v === undefined) return v;
  if (ts.isTimestamp(v)) return ts.makeTimestamp(ts.toMillis(v) + days * DAY_MS);
  if (typeof v === 'string') return shiftDateString(v, days);
  if (typeof v === 'number' && Number.isInteger(v) && key && DATE_KEY.test(key) &&
      v > EPOCH_MIN && v < EPOCH_MAX) {
    return v + days * DAY_MS;
  }
  if (Array.isArray(v)) return v.map((x) => shiftValue(x, days, key, ts));
  if (typeof v === 'object' && v.constructor === Object) {
    const out = {};
    for (const [k, x] of Object.entries(v)) out[k] = shiftValue(x, days, k, ts);
    return out;
  }
  return v; // GeoPoint, DocumentReference, Bytes… sin cambios.
}

function shiftDocId(id, days) {
  return shiftDateString(id, days);
}

/// Desplaza cada segmento de una ruta que sea fecha. Si un documento padre
/// cambia de ID, sus subcolecciones viajan con él.
function shiftPath(p, days) {
  return p.split('/').map((seg) => shiftDocId(seg, days)).join('/');
}

/**
 * Días enteros a desplazar. `anchorMs` = inicio del ayuno abierto o, si no
 * hay, cierre del último día metabólico. Se busca el mayor N tal que
 * anchor + N días <= now - margen.
 */
function computeShiftDays(anchorMs, nowMs, minAgeMs = MIN_FAST_AGE_MS) {
  const target = nowMs - minAgeMs;
  if (anchorMs >= target) return 0;
  return Math.floor((target - anchorMs) / DAY_MS);
}

// ─── Firestore ──────────────────────────────────────────────────────────

function sdk() {
  const admin = require('firebase-admin');
  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  }
  const { Timestamp } = admin.firestore;
  return {
    admin,
    db: admin.firestore(),
    ts: {
      isTimestamp: (v) => v instanceof Timestamp,
      toMillis: (v) => v.toMillis(),
      makeTimestamp: (ms) => Timestamp.fromMillis(ms),
    },
  };
}

async function readAll(userRef) {
  const docs = []; // { path, collection, id, data }
  async function walk(ref, prefix) {
    const cols = await ref.listCollections();
    for (const col of cols) {
      if (SKIP_COLLECTIONS.has(col.id)) continue;
      const snap = await col.get();
      for (const d of snap.docs) {
        docs.push({ ref: d.ref, collection: `${prefix}${col.id}`, id: d.id, data: d.data() });
        await walk(d.ref, `${prefix}${col.id}/${d.id}/`);
      }
    }
  }
  await walk(userRef, '');
  return docs;
}

function toMillisLoose(v, ts) {
  if (!v) return null;
  if (ts.isTimestamp(v)) return ts.toMillis(v);
  if (typeof v === 'string') { const t = Date.parse(v); return Number.isNaN(t) ? null : t; }
  return null;
}

function findAnchor(docs, ts) {
  const fasts = docs.filter((d) => d.collection === 'fasting_history' &&
    d.data.endTime == null && d.data.isFasting === true);
  const openStarts = fasts.map((d) => toMillisLoose(d.data.startTime, ts)).filter(Boolean);
  const openCycles = docs.filter((d) => d.collection === 'metabolic_cycles' && !d.data.closedAt)
    .map((d) => toMillisLoose(d.data.startedAt, ts)).filter(Boolean);
  const open = [...openStarts, ...openCycles];
  if (open.length) return { kind: 'ayuno abierto', ms: Math.max(...open) };
  const closes = docs.filter((d) => d.collection === 'metabolic_cycles')
    .map((d) => toMillisLoose(d.data.closedAt, ts)).filter(Boolean);
  if (closes.length) return { kind: 'último día metabólico cerrado', ms: Math.max(...closes) };
  return null;
}

function serialize(v, ts) {
  if (v === null || v === undefined) return v;
  if (ts.isTimestamp(v)) return { __ts: ts.toMillis(v) };
  if (Array.isArray(v)) return v.map((x) => serialize(x, ts));
  if (typeof v === 'object' && v.constructor === Object) {
    const o = {}; for (const [k, x] of Object.entries(v)) o[k] = serialize(x, ts); return o;
  }
  return v;
}

function deserialize(v, ts) {
  if (v === null || v === undefined) return v;
  if (Array.isArray(v)) return v.map((x) => deserialize(x, ts));
  if (typeof v === 'object') {
    if (Object.keys(v).length === 1 && typeof v.__ts === 'number') return ts.makeTimestamp(v.__ts);
    const o = {}; for (const [k, x] of Object.entries(v)) o[k] = deserialize(x, ts); return o;
  }
  return v;
}

async function commitInChunks(db, ops) {
  for (let i = 0; i < ops.length; i += 400) {
    const batch = db.batch();
    for (const op of ops.slice(i, i + 400)) op(batch);
    await batch.commit();
  }
}

async function main() {
  const args = process.argv.slice(2);
  const apply = args.includes('--apply');
  const restoreIdx = args.indexOf('--restore');
  const { admin, db, ts } = sdk();

  const user = await admin.auth().getUserByEmail(DEMO_EMAIL).catch(() => null);
  if (!user || user.email !== DEMO_EMAIL) {
    console.error(`ABORTADO: no existe la cuenta ${DEMO_EMAIL} en este proyecto.`);
    process.exit(1);
  }
  const uid = user.uid;
  const userRef = db.collection('users').doc(uid);
  console.log(`Cuenta demo: ${DEMO_EMAIL}  (uid ${uid})\n`);

  if (restoreIdx >= 0) {
    const file = args[restoreIdx + 1];
    const dump = JSON.parse(fs.readFileSync(file, 'utf8'));
    if (dump.uid !== uid) { console.error('ABORTADO: la copia es de otra cuenta.'); process.exit(1); }
    const current = await readAll(userRef);
    const ops = current.map((d) => (b) => b.delete(d.ref));
    for (const d of dump.docs) {
      ops.push((b) => b.set(db.doc(d.path), deserialize(d.data, ts)));
    }
    if (dump.root) ops.push((b) => b.set(userRef, deserialize(dump.root, ts)));
    await commitInChunks(db, ops);
    console.log(`Restaurados ${dump.docs.length} documentos desde ${file}.`);
    return;
  }

  const rootSnap = await userRef.get();
  const docs = await readAll(userRef);
  const byCol = {};
  for (const d of docs) byCol[d.collection] = (byCol[d.collection] || 0) + 1;
  console.log('Documentos por colección:');
  for (const [c, n] of Object.entries(byCol).sort()) console.log(`  ${c.padEnd(28)} ${n}`);
  if (!docs.length) {
    console.error('\nABORTADO: la cuenta no tiene datos que rejuvenecer.');
    process.exit(1);
  }

  const anchor = findAnchor(docs, ts);
  if (!anchor) {
    console.error('\nABORTADO: no hay ayuno ni días metabólicos para anclar el desplazamiento.');
    process.exit(1);
  }
  const now = Date.now();
  const days = computeShiftDays(anchor.ms, now);
  const anchorAfter = anchor.ms + days * DAY_MS;
  console.log(`\nAncla: ${anchor.kind}, ${new Date(anchor.ms).toISOString()}`);
  console.log(`Desplazamiento: +${days} días  →  queda en ${new Date(anchorAfter).toISOString()} ` +
    `(hace ${((now - anchorAfter) / 3600000).toFixed(1)} h)`);
  if (days === 0) { console.log('\nLos datos ya están al día. Nada que hacer.'); return; }

  const renames = docs.filter((d) => shiftPath(d.ref.path, days) !== d.ref.path).length;
  console.log(`Documentos a actualizar: ${docs.length} (${renames} cambian de ID por ser fechas)`);

  if (!apply) {
    console.log('\nModo inspección: no se escribió nada. Para aplicar, agrega --apply.');
    return;
  }

  const backupDir = path.join(__dirname, 'backups');
  fs.mkdirSync(backupDir, { recursive: true });
  const backupFile = path.join(backupDir, `demo-${new Date(now).toISOString().replace(/[:.]/g, '-')}.json`);
  fs.writeFileSync(backupFile, JSON.stringify({
    uid,
    root: rootSnap.exists ? serialize(rootSnap.data(), ts) : null,
    docs: docs.map((d) => ({ path: d.ref.path, data: serialize(d.data, ts) })),
  }));
  console.log(`\nCopia de seguridad: ${backupFile}`);

  const ops = [];
  // Hijos antes que padres no importa en Firestore; los IDs nuevos se calculan por documento.
  for (const d of docs) {
    const newData = shiftValue(d.data, days, null, ts);
    const newPath = shiftPath(d.ref.path, days);
    const newRef = db.doc(newPath);
    if (newPath !== d.ref.path) {
      ops.push((b) => b.set(newRef, newData));
      ops.push((b) => b.delete(d.ref));
    } else {
      ops.push((b) => b.set(d.ref, newData));
    }
  }
  if (rootSnap.exists) {
    const root = shiftValue(rootSnap.data(), days, null, ts);
    ops.push((b) => b.set(userRef, root));
  }
  await commitInChunks(db, ops);
  console.log(`Listo: ${docs.length} documentos desplazados +${days} días.`);
  console.log('Abre la app con la cuenta demo y revisa Hoy, Progreso y Glucosa.');
}

module.exports = { shiftDateString, shiftValue, shiftDocId, shiftPath, computeShiftDays, findAnchor, DAY_MS };

if (require.main === module) {
  main().catch((e) => { console.error(e); process.exit(1); });
}
