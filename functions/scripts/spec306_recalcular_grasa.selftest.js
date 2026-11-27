// Prueba la fórmula del script contra los casos compartidos con el sitio.
//   node scripts/spec306_recalcular_grasa.selftest.js
'use strict';
const fs = require('fs');
const path = require('path');
const src = fs.readFileSync(path.join(__dirname, 'spec306_recalcular_grasa.js'), 'utf8');
const fn = src.slice(src.indexOf('const num ='), src.indexOf('function read('));
// eslint-disable-next-line no-new-func
const bodyFatNavy = new Function(`${fn}; return bodyFatNavy;`)();
const cases = JSON.parse(fs.readFileSync(path.join(__dirname, '../../test/fixtures/metabolic_cases.json'), 'utf8')).cases;
let fails = 0;
for (const c of cases) {
  const i = c.input;
  const got = bodyFatNavy({ heightCm: i.heightCm, waistCm: i.waistCm, neckCm: i.neckCm, hipCm: i.hipCm, isMale: i.gender === 'male' });
  const want = c.expected.bodyFatPct;
  const ok = want == null ? got == null : got != null && Math.abs(got - want) < 0.05;
  if (!ok) fails++;
  console.log(`${ok ? 'OK   ' : 'FALLA'} ${c.name}: ${got == null ? null : got.toFixed(2)} (esperado ${want})`);
}
process.exit(fails ? 1 : 0);
