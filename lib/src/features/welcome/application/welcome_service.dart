// SPEC-48: capa application del feature welcome.
//
// Antes: esta clase contenía métodos estáticos que importaban
// `cloud_firestore` y `shared_preferences` directamente — violaba
// CONSTITUTION.md §3.2 ("APPLICATION… NO accede directamente a Firestore").
//
// Ahora: el acceso a Firestore vive en
// `features/welcome/data/firebase_welcome_repository.dart`. Este archivo
// solo expone el provider reactivo `welcomeSeenProvider` que la UI
// consume con un `userId`.
//
// `welcome_flow_screen.dart` lee `welcomeRepositoryProvider` directamente
// para invocar `markWelcomeSeen` cuando el usuario completa el flujo.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/welcome/data/firebase_welcome_repository.dart';

/// Provider reactivo que indica si `userId` ya completó/saltó la guía.
/// Útil en widgets que necesitan reaccionar a cambios del flag.
final welcomeSeenProvider = FutureProvider.family<bool, String>(
  (ref, userId) async {
    final repo = ref.watch(welcomeRepositoryProvider);
    return repo.hasSeenWelcome(userId);
  },
);
