// Prueba de la lógica pura de seed_demo_reviewer.js (sin Firestore).
// Uso: node scripts/seed_demo_reviewer.selftest.js
const m = require('./seed_demo_reviewer.js');
const assert = require('assert');
class TS { constructor(ms){this.ms=ms} toMillis(){return this.ms} }
const ts = { isTimestamp: v => v instanceof TS, toMillis: v => v.ms, makeTimestamp: ms => new TS(ms) };
const D = m.DAY_MS;
// strings
assert.strictEqual(m.shiftDateString('2026-08-27', 87), '2026-11-22');
assert.strictEqual(m.shiftDateString('2026-08-27T23:10:00.000Z', 87), '2026-11-22T23:10:00.000Z');
assert.strictEqual(m.shiftDateString('2026-08-27T18:05:00.000', 1), '2026-08-28T18:05:00.000');
assert.strictEqual(m.shiftDateString('2026-08-27T18:05:00.123456-05:00', 1), '2026-08-28T18:05:00.123456-05:00');
assert.strictEqual(m.shiftDateString('2026-12-31', 1), '2027-01-01');
assert.strictEqual(m.shiftDateString('16:8', 5), '16:8');
assert.strictEqual(m.shiftDateString('1.0.0', 5), '1.0.0');
assert.strictEqual(m.shiftPath('users/abc/metabolic_cycles/2026-08-27T23:10:00.000Z', 2), 'users/abc/metabolic_cycles/2026-08-29T23:10:00.000Z');
// values
const doc = { startedAt: new TS(1000), nested: { closedAt: new TS(5000), list: ['2026-01-01', 3] }, cycleId: '2026-01-01T00:00:00.000Z', updatedAtMs: 1.7e12, count: 1.7e12, score: 80, flag: true, nil: null };
const out = m.shiftValue(doc, 2, null, ts);
assert.strictEqual(out.startedAt.ms, 1000 + 2*D);
assert.strictEqual(out.nested.closedAt.ms, 5000 + 2*D);
assert.deepStrictEqual(out.nested.list, ['2026-01-03', 3]);
assert.strictEqual(out.cycleId, '2026-01-03T00:00:00.000Z');
assert.strictEqual(out.count, 1.7e12, 'un entero que no es campo de fecha no se toca');
assert.strictEqual(out.score, 80); assert.strictEqual(out.flag, true); assert.strictEqual(out.nil, null);
assert.strictEqual(doc.startedAt.ms, 1000, 'no muta el original');
// shift days
const now = Date.UTC(2026,10,22,21,49);
const anchor = Date.UTC(2026,7,27,1,10); // 85+ días antes
const n = m.computeShiftDays(anchor, now);
assert.ok(anchor + n*D <= now - 2*3600e3 && anchor + (n+1)*D > now - 2*3600e3);
assert.strictEqual(m.computeShiftDays(now, now), 0);
// anchor
const docs = [
 {collection:'metabolic_cycles', data:{startedAt:new TS(10), closedAt:new TS(20)}},
 {collection:'metabolic_cycles', data:{startedAt:new TS(30)}},
 {collection:'fasting_history', data:{startTime:new TS(30), endTime:null, isFasting:true}},
];
assert.deepStrictEqual(m.findAnchor(docs, ts), {kind:'ayuno abierto', ms:30});
assert.deepStrictEqual(m.findAnchor([docs[0]], ts), {kind:'último día metabólico cerrado', ms:20});
console.log('OK — todos los casos pasan; desplazamiento ejemplo:', n, 'días');
