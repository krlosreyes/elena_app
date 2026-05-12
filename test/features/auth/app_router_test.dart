// SPEC-73 §CA-73-08: el router redirige UNA SOLA VEZ y no entra en
// loop cuando un usuario con perfil incompleto está en /login.
//
// Esqueleto pendiente: requiere harness de go_router con observador de
// redirects para contar invocaciones. Hasta tener ese harness, el CA-73-08
// se verifica manualmente en device. Skip activo para que la suite no se
// rompa.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CA-73-08 (pendiente harness): usuario NEW autenticado en /login '
    'es redirigido una vez a /onboarding sin loop',
    () {
      // TODO(SPEC-73): implementar con go_router observer.
    },
    skip: true,
  );
}
