// 29-jul: el avatar de Perfil pasó de icono fijo a foto del proveedor.
//
// Lo que se protege aquí es la CADENA DE RESPALDO, no la foto. La foto
// es lo fácil; lo que rompe en producción es el caso sin foto (toda
// cuenta de email), el nombre vacío, y la foto que no carga. En los
// tres el avatar tiene que mostrar algo — nunca un círculo en blanco.
//
// `Image.network` no se ejercita en widget tests (el HttpClient de
// pruebas devuelve 400 para cualquier URL), y eso está bien: es
// exactamente el escenario "la foto falló" y confirma que la inicial
// de debajo sigue visible.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_identity_card.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

AppAccount _cuenta({String? photoUrl}) => AppAccount(
      uid: 'u1',
      email: 'a@b.com',
      profileStatus: AppProfileStatus.completeProfile,
      photoUrl: photoUrl,
    );

Widget _montar({required String name, AppAccount? cuenta}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(cuenta)),
    ],
    child: MaterialApp(
      home: Scaffold(body: Center(child: ProfileAvatar(name: name))),
    ),
  );
}

void main() {
  group('ProfileAvatar.initialOf', () {
    test('toma la primera letra en mayúscula', () {
      expect(ProfileAvatar.initialOf('carlos'), 'C');
      expect(ProfileAvatar.initialOf('  ana maría '), 'A');
    });

    test('devuelve vacío cuando no hay nada aprovechable', () {
      expect(ProfileAvatar.initialOf(''), '');
      expect(ProfileAvatar.initialOf('   '), '');
    });

    // Un nombre que empieza por emoji o por letra acentuada no debe
    // partir el grafema por la mitad — de ahí `.characters` y no [0].
    test('no parte grafemas compuestos', () {
      expect(ProfileAvatar.initialOf('Ángela'), 'Á');
      expect(ProfileAvatar.initialOf('👍 test'), '👍');
    });
  });

  group('ProfileAvatar', () {
    testWidgets('sin foto muestra la inicial del nombre', (tester) async {
      await tester.pumpWidget(_montar(name: 'Carlos', cuenta: _cuenta()));
      await tester.pump();

      expect(find.text('C'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('sin foto y sin nombre cae al icono genérico', (tester) async {
      await tester.pumpWidget(_montar(name: '', cuenta: _cuenta()));
      await tester.pump();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('con foto sigue dibujando la inicial por debajo',
        (tester) async {
      await tester.pumpWidget(_montar(
        name: 'Carlos',
        cuenta: _cuenta(photoUrl: 'https://lh3.googleusercontent.com/foto'),
      ));
      await tester.pump();

      // La imagen se monta, pero la inicial NO desaparece: si la carga
      // falla —que es lo que pasa en un test y lo que puede pasar sin
      // red— el avatar tiene que seguir mostrando algo.
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('antes de que el stream de auth emita no revienta',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileAvatar(name: 'Carlos')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
