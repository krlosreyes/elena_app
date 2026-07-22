// TEST-07 (auditoría pre-producción 2026-07-11).
//
// Cubre `onUserDeleted` (SPEC-207): borrado en cascada, irreversible (GDPR
// Art.17 / LGPD Art.18), de TODAS las subcolecciones listadas en
// USER_SUBCOLLECTIONS (functions/src/index.ts) más la colección plana legacy
// `fasting_history` (SPEC-217 transición). No tenía ningún test.
//
// Estrategia: `firebase-functions-test` en modo offline (sin proyecto real,
// sin red) para envolver el trigger v1 `auth.user().onDelete(...)` y
// invocarlo con un UserRecord fake (`test.auth.makeUserRecord`, API
// verificada leyendo directamente node_modules/firebase-functions-test/lib
// /providers/auth.d.ts tras instalar el paquete real — no se adivinó).
//
// El SDK de Firestore (`admin.firestore()`) se reemplaza con un Firestore
// en memoria hecho a mano (ver `jest.mock('firebase-admin', ...)` abajo)
// que soporta exactamente la superficie de API que usa index.ts:
// collection().doc().collection() anidado, .limit().get(), .where(...)
// .limit().get(), batch.delete()/commit() y doc.delete(). No se usó el
// Firestore Emulator (requeriría levantar `firebase emulators:start`, fuera
// de alcance de un test unitario rápido) ni una librería de terceros de
// mocking (para no depender de su propia superficie de API sin verificar).
//
// Este test SÍ se ejecutó realmente en este sandbox (hay acceso a Node +
// red para `npm install`, a diferencia del lado Flutter/Dart) — no quedó
// como un archivo sin correr.

import * as admin from "firebase-admin";
// El paquete exporta con `export =` (CommonJS puro) y el proyecto no tiene
// esModuleInterop activado (ver functions/tsconfig.json) — un default
// import normal compilaría a un `.default` que no existe. `import ... =
// require(...)` es la forma correcta de consumir `export =` sin interop.
import functionsTest = require("firebase-functions-test");

type DocData = Record<string, unknown>;

interface MockDocRef {
  id: string;
  collection: (sub: string) => MockCollectionRef;
  delete: () => Promise<void>;
  __erase: () => void;
}

interface MockSnapshotDoc {
  id: string;
  data: () => DocData;
  ref: MockDocRef;
}

interface MockSnapshot {
  empty: boolean;
  docs: MockSnapshotDoc[];
}

interface MockQuery {
  limit: (n: number) => MockQuery;
  where: (field: string, op: string, value: unknown) => MockQuery;
  get: () => Promise<MockSnapshot>;
}

interface MockCollectionRef extends MockQuery {
  doc: (id: string) => MockDocRef;
}

// jest.mock() se hoistea automáticamente por encima de los `import` de
// arriba (comportamiento estándar de ts-jest/babel-jest) — por eso es
// seguro definir todo el Firestore fake dentro del factory: para el
// runtime de Jest, esta llamada se ejecuta ANTES de que `import * as admin
// from "firebase-admin"` resuelva el require real.
jest.mock("firebase-admin", () => {
  // Mapa: "users/uid/sleep_history" -> Map<docId, data>
  const store = new Map<string, Map<string, DocData>>();

  // FIRE-08 (21-jul, auditoría técnica): rutas que deben fallar su próximo
  // `.get()` — permite simular un fallo real de Firestore en UNA
  // subcolección específica para probar que `onUserDeleted` sigue
  // borrando el resto en vez de abortar todo el proceso.
  const failPaths = new Set<string>();

  function ensureCollection(path: string): Map<string, DocData> {
    if (!store.has(path)) store.set(path, new Map());
    return store.get(path)!;
  }

  function snapshotFor(
    path: string,
    filter?: (d: DocData) => boolean,
    limitN?: number,
  ): MockSnapshot {
    let entries = Array.from(ensureCollection(path).entries());
    if (filter) entries = entries.filter(([, data]) => filter(data));
    if (limitN !== undefined) entries = entries.slice(0, limitN);
    const docs: MockSnapshotDoc[] = entries.map(([id, data]) => ({
      id,
      data: () => data,
      ref: makeDocRef(path, id),
    }));
    return { empty: docs.length === 0, docs };
  }

  function makeQuery(
    path: string,
    filter?: (d: DocData) => boolean,
    limitN?: number,
  ): MockQuery {
    return {
      limit: (n: number) => makeQuery(path, filter, n),
      where: (field: string, _op: string, value: unknown) => {
        const prev = filter;
        const next = (d: DocData) => (prev ? prev(d) : true) && d[field] === value;
        return makeQuery(path, next, limitN);
      },
      get: () => {
        if (failPaths.has(path)) {
          return Promise.reject(new Error(`mock forced failure for ${path}`));
        }
        return Promise.resolve(snapshotFor(path, filter, limitN));
      },
    };
  }

  function makeDocRef(collectionPath: string, id: string): MockDocRef {
    const erase = () => {
      ensureCollection(collectionPath).delete(id);
    };
    return {
      id,
      collection: (sub: string) => makeCollectionRef(`${collectionPath}/${id}/${sub}`),
      delete: () => {
        erase();
        return Promise.resolve();
      },
      __erase: erase,
    };
  }

  function makeCollectionRef(path: string): MockCollectionRef {
    const query = makeQuery(path);
    return {
      ...query,
      doc: (id: string) => makeDocRef(path, id),
    };
  }

  function makeBatch() {
    const ops: Array<() => void> = [];
    return {
      delete: (ref: MockDocRef) => {
        ops.push(ref.__erase);
      },
      commit: () => {
        ops.forEach((op) => op());
        ops.length = 0;
        return Promise.resolve();
      },
    };
  }

  const db = {
    collection: (name: string) => makeCollectionRef(name),
    batch: () => makeBatch(),
  };

  const firestoreFn = Object.assign(() => db, {
    Timestamp: {
      fromDate: (d: Date) => ({ toMillis: () => d.getTime() }),
      now: () => ({ toMillis: () => Date.now() }),
    },
  });

  return {
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    auth: jest.fn(() => ({
      setCustomUserClaims: jest.fn().mockResolvedValue(undefined),
    })),
    // Helpers de test, no forman parte de la API real de firebase-admin.
    __seed: (path: string, id: string, data: DocData) => {
      ensureCollection(path).set(id, data);
    },
    __count: (path: string) => ensureCollection(path).size,
    // FIRE-08: fuerza que el próximo (y siguientes) `.get()` de esta ruta
    // rechace, simulando un fallo real de Firestore en esa subcolección.
    __failPath: (path: string) => failPaths.add(path),
    __clearFailPaths: () => failPaths.clear(),
  };
});

// Import diferido: debe ir después de jest.mock (aunque, por el hoisting
// de arriba, en tiempo de ejecución da igual el orden textual).
// eslint-disable-next-line @typescript-eslint/no-var-requires
const indexModule = require("./index") as typeof import("./index");

type MockAdmin = typeof admin & {
  __seed: (path: string, id: string, data: DocData) => void;
  __count: (path: string) => number;
  __failPath: (path: string) => void;
  __clearFailPaths: () => void;
};

const mockAdmin = admin as unknown as MockAdmin;

const test = functionsTest();

const TEST_UID = "user_test_uid_1";

/** Copia local de USER_SUBCOLLECTIONS (index.ts no la exporta). Si se agrega
 * una subcolección nueva ahí y no aquí, este test seguirá pasando pero dejará
 * de cubrir la nueva — ver nota en el informe de la tarea. */
const USER_SUBCOLLECTIONS = [
  "sleep_history",
  "nutrition_history",
  "hydration_history",
  "exercise_history",
  "biometric_history",
  "metabolic_cycles",
  "daily_summary",
  "streak_history",
  "imr_history",
  "protocol_adjustments",
  "app_state",
  "fasting_checkins",
  "sleep_routines",
  "post_reads",
  "fasting_history",
];

describe("onUserDeleted (SPEC-207 borrado en cascada)", () => {
  afterAll(() => {
    test.cleanup();
  });

  it("borra todos los documentos de las 15 subcolecciones de users/{uid}", async () => {
    // Seed: 2 documentos fake en cada subcolección.
    for (const sub of USER_SUBCOLLECTIONS) {
      const path = `users/${TEST_UID}/${sub}`;
      mockAdmin.__seed(path, "doc1", { dummy: true });
      mockAdmin.__seed(path, "doc2", { dummy: true });
      expect(mockAdmin.__count(path)).toBe(2);
    }

    // Seed: documento en la colección plana legacy fasting_history,
    // indexado por userId (SPEC-217 transición).
    mockAdmin.__seed("fasting_history", "legacy1", { userId: TEST_UID });
    mockAdmin.__seed("fasting_history", "otro-usuario", { userId: "otro-uid" });

    const wrapped = test.wrap(indexModule.onUserDeleted);
    const fakeUser = test.auth.makeUserRecord({ uid: TEST_UID });

    await wrapped(fakeUser);

    for (const sub of USER_SUBCOLLECTIONS) {
      const path = `users/${TEST_UID}/${sub}`;
      expect(mockAdmin.__count(path)).toBe(0);
    }

    // La colección plana legacy: solo se borra el doc del usuario borrado,
    // el de otro usuario debe sobrevivir.
    expect(mockAdmin.__count("fasting_history")).toBe(1);
  });

  it("no falla si el usuario no tenía ningún documento (cuenta recién creada)", async () => {
    const emptyUid = "user_sin_datos";
    const wrapped = test.wrap(indexModule.onUserDeleted);
    const fakeUser = test.auth.makeUserRecord({ uid: emptyUid });

    await expect(wrapped(fakeUser)).resolves.not.toThrow();
  });

  // FIRE-08 (21-jul, auditoría técnica): antes de este fix, un fallo en
  // UNA subcolección abortaba el for-loop completo — el resto de
  // subcolecciones, el doc raíz y la limpieza legacy nunca se
  // intentaban en esa invocación. Este test prueba el comportamiento
  // corregido: el fallo se aísla, el resto SÍ se borra, y la función
  // relanza un error agregado (para que Cloud Functions reintente).
  it("FIRE-08: si una subcolección falla, borra igual el resto y relanza un error agregado", async () => {
    const uid = "user_fallo_parcial";
    const failingPath = `users/${uid}/sleep_history`;
    const okPath = `users/${uid}/hydration_history`;

    mockAdmin.__seed(failingPath, "d1", { dummy: true });
    mockAdmin.__seed(okPath, "d1", { dummy: true });
    mockAdmin.__failPath(failingPath);

    const wrapped = test.wrap(indexModule.onUserDeleted);
    const fakeUser = test.auth.makeUserRecord({ uid });

    try {
      await expect(wrapped(fakeUser)).rejects.toThrow(/fallo parcial/);

      // La subcolección SANA debió borrarse igual — el fallo de
      // sleep_history no debe bloquear hydration_history.
      expect(mockAdmin.__count(okPath)).toBe(0);
      // La subcolección que falló, en cambio, conserva su documento
      // (el mock nunca llegó a borrarlo porque `.get()` rechazó).
      expect(mockAdmin.__count(failingPath)).toBe(1);
    } finally {
      // No contaminar los tests siguientes con esta ruta marcada
      // como fallida permanentemente.
      mockAdmin.__clearFailPaths();
    }
  });
});
