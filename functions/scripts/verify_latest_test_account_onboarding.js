// Fase 6 (auditoría en vivo, 22-jul) — verificación puntual de la cuenta de
// prueba "Claude" que Carlos preparó para el walkthrough.
//
// CONTEXTO: durante el recorrido en vivo del onboarding, la sesión saltó de
// la pantalla de notificaciones directo al Dashboard, sin que yo viera
// renderizarse Health Sync, las 3 pantallas de Ejercicio (UX-ONBOARD,
// 21-jul) ni Objetivos. El código confirma que el PageView usa
// `NeverScrollableScrollPhysics` (un usuario real no puede swipear para
// saltarse pantallas — solo botones) y que `_handleNext()` avanza un solo
// paso por click, así que no es un bug reproducible por un usuario real.
// La hipótesis más probable es que mi propio gesto de scroll haya caído
// sobre una opción clickeable del quiz "Conócete primero" y disparado
// varios avances automáticos.
//
// IMPORTANTE: `_finalSubmit()` en onboarding_screen.dart escribe SIEMPRE los
// valores del estado local (_exerciseLevel, _exerciseEquipment, etc. y los
// drafts de goalsController), incluso si el usuario nunca tocó esas
// pantallas — porque esas variables tienen defaults. Es decir: este script
// NO puede probar por sí solo si las pantallas se saltaron o no, porque
// incluso en un salto real Firestore va a tener *algún* valor (el default).
// Lo que sí puede hacer es confirmar que la cuenta quedó con datos
// coherentes (sin nulls que rompan otras pantallas) y darte visibilidad de
// qué quedó grabado, para que decidas si hace falta invalidar esta cuenta
// de prueba y recrearla.
//
// QUÉ HACE (SOLO LECTURA — no escribe ni borra nada):
//   1. Busca el usuario de Firebase Auth creado más recientemente.
//   2. Imprime su users/{uid} completo.
//   3. Imprime conteos de sus subcolecciones relevantes (metabolic_cycles,
//      fasting_history, badges).
//
// CÓMO CORRERLO (mismo procedimiento que los scripts anteriores):
//   GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/tu-clave.json" \
//   node scripts/verify_latest_test_account_onboarding.js

'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();
const auth = admin.auth();

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

async function main() {
  console.log('Fase 6 — verificación de la cuenta de prueba más reciente\n');

  const users = await listAllUsers();
  if (users.length === 0) {
    console.log('No hay usuarios en Firebase Auth.');
    return;
  }

  users.sort(
    (a, b) =>
      new Date(b.metadata.creationTime).getTime() -
      new Date(a.metadata.creationTime).getTime(),
  );
  const latest = users[0];

  console.log(`uid: ${latest.uid}`);
  console.log(`email: ${latest.email || 'sin email'}`);
  console.log(`displayName: ${latest.displayName || 'sin nombre'}`);
  console.log(`creationTime: ${latest.metadata.creationTime}`);
  console.log('');

  const userDoc = await db.collection('users').doc(latest.uid).get();
  if (!userDoc.exists) {
    console.log('El documento users/{uid} NO existe todavía.');
  } else {
    console.log('--- users/{uid} (documento completo) ---');
    console.log(JSON.stringify(userDoc.data(), null, 2));
  }

  console.log('\n--- Subcolecciones ---');
  for (const sub of ['metabolic_cycles', 'fasting_history', 'badges']) {
    const snap = await db
      .collection('users')
      .doc(latest.uid)
      .collection(sub)
      .get();
    console.log(`${sub}: ${snap.size} documentos`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error corriendo la verificación:', err);
    process.exit(1);
  });
