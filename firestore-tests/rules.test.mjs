// TEST-02 (auditoria pre-produccion 2026-07-11).
//
// Tests de `firestore.rules` contra el emulador de Firestore. Cubren los
// dos hallazgos de seguridad corregidos en esta misma auditoria (FB-01,
// FB-02) mas los invariantes de aislamiento por usuario que ya existian
// pero nunca tuvieron un test automatizado.
//
// NO CORREN dentro de `flutter test` -- son un paquete Node separado
// porque `@firebase/rules-unit-testing` habla directo con el emulador de
// Firestore (protocolo HTTP/gRPC), sin pasar por Dart.
//
// Como correrlos (requiere Firebase CLI y Java para el emulador; NO se
// pudo ejecutar dentro del sandbox de esta sesion -- ver nota en el
// informe de auditoria sobre restricciones de red del entorno):
//
//   cd firestore-tests
//   npm install
//   npm run test:emulator
//
// (equivalente manual: `firebase emulators:exec --only firestore "npm test"`
// desde este mismo directorio, con el emulador de Firestore instalado.)

import { readFileSync } from 'node:fs';
import { before, after, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'elena-app-2026-v1-test';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  if (testEnv) await testEnv.clearFirestore();
});

// Helper: escribe un doc saltandose las reglas (simula datos ya existentes
// en la base, ej. el doc de otro usuario que un atacante intentaria leer).
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await fn(context.firestore());
  });
}

describe('users/{userId} — aislamiento por dueño', () => {
  it('el dueño puede leer y escribir su propio doc', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      db.collection('users').doc('userA').set({ id: 'userA', weight: 80 }),
    );
    await assertSucceeds(db.collection('users').doc('userA').get());
  });

  it('otro usuario autenticado NO puede leer el doc de userA', async () => {
    await seed((db) => db.collection('users').doc('userA').set({ weight: 80 }));
    const db = testEnv.authenticatedContext('userB').firestore();
    await assertFails(db.collection('users').doc('userA').get());
  });

  it('otro usuario autenticado NO puede escribir en el doc de userA', async () => {
    const db = testEnv.authenticatedContext('userB').firestore();
    await assertFails(
      db.collection('users').doc('userA').set({ weight: 999 }),
    );
  });

  it('un usuario no autenticado no puede leer ni escribir', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection('users').doc('userA').get());
    await assertFails(db.collection('users').doc('userA').set({ weight: 1 }));
  });

  it('escribir `id` distinto al uid del path es rechazado', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('users').doc('userA').set({ id: 'userB', weight: 80 }),
    );
  });
});

describe('FB-01 — imr_history: validacion de rango ya NO es bypasseable', () => {
  it('totalScore dentro de [0,100] con weekISO correcto: permitido', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      db
        .collection('users')
        .doc('userA')
        .collection('imr_history')
        .doc('2026-W28')
        .set({ weekISO: '2026-W28', totalScore: 87 }),
    );
  });

  it('totalScore > 100 es rechazado (antes del fix, el catch-all lo permitia)', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db
        .collection('users')
        .doc('userA')
        .collection('imr_history')
        .doc('2026-W28')
        .set({ weekISO: '2026-W28', totalScore: 150 }),
    );
  });

  it('totalScore negativo es rechazado', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db
        .collection('users')
        .doc('userA')
        .collection('imr_history')
        .doc('2026-W28')
        .set({ weekISO: '2026-W28', totalScore: -5 }),
    );
  });

  it('weekISO que no coincide con el ID del doc es rechazado', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db
        .collection('users')
        .doc('userA')
        .collection('imr_history')
        .doc('2026-W28')
        .set({ weekISO: '2026-W99', totalScore: 50 }),
    );
  });
});

describe('FB-01 — metabolic_cycles: validacion de rango ya NO es bypasseable', () => {
  it('dailyScore dentro de [0,100] con cycleId correcto: permitido', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      db
        .collection('users')
        .doc('userA')
        .collection('metabolic_cycles')
        .doc('2026-07-11T00:00:00Z')
        .set({ cycleId: '2026-07-11T00:00:00Z', dailyScore: 72 }),
    );
  });

  it('dailyScore > 100 es rechazado', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db
        .collection('users')
        .doc('userA')
        .collection('metabolic_cycles')
        .doc('2026-07-11T00:00:00Z')
        .set({ cycleId: '2026-07-11T00:00:00Z', dailyScore: 999 }),
    );
  });

  it('sin dailyScore (campo opcional ausente) es permitido', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      db
        .collection('users')
        .doc('userA')
        .collection('metabolic_cycles')
        .doc('2026-07-11T00:00:00Z')
        .set({ cycleId: '2026-07-11T00:00:00Z' }),
    );
  });
});

describe('FIRE-04 — badges: inmutabilidad de insignias otorgadas', () => {
  // 21-jul (auditoria tecnica Staff Engineer): la regla de badges (unica
  // via = `create`, sin `update` ni `delete`) nunca tuvo test de
  // regresion pese a ser el invariante mas importante del ruleset: una
  // insignia otorgada es un HECHO PERMANENTE (ver comentario en
  // firestore.rules linea 94). Sin este test, un cambio futuro en la
  // regla general de `allow create, update`/`allow delete` (lineas
  // ~144-149) podria neutralizar la inmutabilidad sin que nada lo
  // detecte -- exactamente el riesgo que documenta la nota de FB-01
  // sobre reglas mas laxas pisando reglas mas especificas.
  const validBadge = {
    badgeId: 'ayuno_7_dias',
    category: 'ayuno',
  };

  it('el dueño puede crear una insignia con badgeId y category validos', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias').set(validBadge),
    );
  });

  it('badgeId del payload distinto al del path es rechazado', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias')
        .set({ ...validBadge, badgeId: 'otro_id' }),
    );
  });

  it('category fuera de la whitelist cerrada es rechazada', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias')
        .set({ ...validBadge, category: 'categoria_inventada' }),
    );
  });

  it('una insignia ya creada NO puede modificarse (update rechazado)', async () => {
    await seed((db) =>
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias').set(validBadge),
    );
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias').update({ category: 'racha' }),
    );
  });

  it('una insignia ya creada NO puede borrarse (delete rechazado)', async () => {
    await seed((db) =>
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias').set(validBadge),
    );
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias').delete(),
    );
  });

  it('otro usuario autenticado no puede leer ni crear insignias ajenas', async () => {
    await seed((db) =>
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias').set(validBadge),
    );
    const db = testEnv.authenticatedContext('userB').firestore();
    await assertFails(
      db.collection('users').doc('userA').collection('badges')
        .doc('ayuno_7_dias').get(),
    );
    await assertFails(
      db.collection('users').doc('userA').collection('badges')
        .doc('otra_insignia').set(validBadge),
    );
  });
});

describe('FB-02 — catalogos globales: solo admin puede escribir', () => {
  for (const col of ['master_food_db', 'master_exercises_db', 'user_food_suggestions']) {
    it(`${col}: usuario autenticado sin claim admin NO puede escribir`, async () => {
      const db = testEnv.authenticatedContext('userA').firestore();
      await assertFails(db.collection(col).doc('doc1').set({ name: 'x' }));
    });

    it(`${col}: usuario autenticado sin claim admin SI puede leer`, async () => {
      await seed((db) => db.collection(col).doc('doc1').set({ name: 'x' }));
      const db = testEnv.authenticatedContext('userA').firestore();
      await assertSucceeds(db.collection(col).doc('doc1').get());
    });

    it(`${col}: usuario con claim admin=true SI puede escribir`, async () => {
      const db = testEnv
        .authenticatedContext('admin1', { admin: true })
        .firestore();
      await assertSucceeds(db.collection(col).doc('doc1').set({ name: 'x' }));
    });

    it(`${col}: usuario no autenticado no puede leer ni escribir`, async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(db.collection(col).doc('doc1').get());
      await assertFails(db.collection(col).doc('doc1').set({ name: 'x' }));
    });
  }
});

describe('fasting_history (legacy plana) — aislamiento por userId', () => {
  it('el dueño puede crear su propio doc', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      db.collection('fasting_history').doc('log1').set({ userId: 'userA' }),
    );
  });

  it('otro usuario no puede leer el doc de userA', async () => {
    await seed((db) =>
      db.collection('fasting_history').doc('log1').set({ userId: 'userA' }),
    );
    const db = testEnv.authenticatedContext('userB').firestore();
    await assertFails(db.collection('fasting_history').doc('log1').get());
  });

  it('un usuario no puede crear un doc con userId de otro', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('fasting_history').doc('log1').set({ userId: 'userB' }),
    );
  });
});

describe('metamorfosis_posts — lectura publica, escritura de contenido bloqueada', () => {
  it('cualquiera (incluso sin auth) puede leer', async () => {
    await seed((db) =>
      db.collection('metamorfosis_posts').doc('p1').set({
        title: 'x',
        analytics: { views: 0 },
      }),
    );
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(db.collection('metamorfosis_posts').doc('p1').get());
  });

  it('un usuario autenticado NO puede crear un post nuevo', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('metamorfosis_posts').doc('p2').set({
        title: 'hack',
        analytics: { views: 0 },
      }),
    );
  });

  it('un usuario autenticado puede incrementar `analytics.views` (nunca bajarlo)', async () => {
    await seed((db) =>
      db.collection('metamorfosis_posts').doc('p1').set({
        title: 'x',
        analytics: { views: 5 },
      }),
    );
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      db
        .collection('metamorfosis_posts')
        .doc('p1')
        .update({ 'analytics.views': 6 }),
    );
    await assertFails(
      db
        .collection('metamorfosis_posts')
        .doc('p1')
        .update({ 'analytics.views': 4 }),
    );
  });
});

describe('catch-all — coleccion no declarada queda denegada por defecto', () => {
  it('una coleccion inventada, sin match propio, deniega todo', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      db.collection('coleccion_que_no_existe_en_las_rules').doc('x').set({ a: 1 }),
    );
  });
});
