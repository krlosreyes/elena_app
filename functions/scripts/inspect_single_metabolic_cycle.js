// Fase 7 (auditoría en vivo, 22-jul) — inspección puntual del ÚNICO
// documento metabolic_cycles de la cuenta de prueba "Claude"
// (uid 7J0oMyoXOFWAfg5biD5X0Wj7YNm2).
//
// CONTEXTO: durante el walkthrough en vivo, el Dashboard mostró "AYUNO
// COMPLETADO 16h" inmediatamente después de terminar el onboarding, sin
// que el usuario hubiera tocado "Iniciar Ayuno". Rastreé todo
// FastingNotifier (fasting_notifier.dart): el único camino que marca
// `completedToday=true` requiere un documento REAL cerrado en
// users/{uid}/fasting_history — y ya confirmamos que esa subcolección
// está vacía (0 documentos) para esta cuenta. Así que si el Dashboard
// mostró "completado", la explicación más probable vive en el ÚNICO
// documento de metabolic_cycles que sí existe — este script lo imprime
// completo para decidir si es un bootstrap legítimo o un caso más de
// "progreso fabricado" (misma familia que P0-1, 21-jul).
//
// SOLO LECTURA — no escribe ni borra nada.
//
// CÓMO CORRERLO (mismo patrón que los scripts anteriores):
//   GOOGLE_APPLICATION_CREDENTIALS=~/elena-admin-key.json \
//   node scripts/inspect_single_metabolic_cycle.js

'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

const UID = '7J0oMyoXOFWAfg5biD5X0Wj7YNm2';

async function main() {
  console.log(`Inspección de metabolic_cycles para uid ${UID}\n`);

  const snap = await db
    .collection('users')
    .doc(UID)
    .collection('metabolic_cycles')
    .get();

  console.log(`Documentos encontrados: ${snap.size}\n`);

  snap.docs.forEach((doc) => {
    console.log(`--- cycleId: ${doc.id} ---`);
    console.log(JSON.stringify(doc.data(), null, 2));
    console.log('');
  });

  // También el doc de usuario completo por si hay un campo suelto
  // (ej. algo tipo currentCycleSnapshot) que no viva en la subcolección.
  const userDoc = await db.collection('users').doc(UID).get();
  const userData = userDoc.data() || {};
  console.log('--- users/{uid} — campos relacionados a ciclo/ayuno ---');
  for (const key of Object.keys(userData)) {
    if (/cycle|fasting|ayuno/i.test(key)) {
      console.log(`${key}:`, JSON.stringify(userData[key], null, 2));
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error corriendo la inspección:', err);
    process.exit(1);
  });
