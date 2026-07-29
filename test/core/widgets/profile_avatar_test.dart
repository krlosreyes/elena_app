// 29-jul: el avatar del usuario pasó de dos implementaciones distintas
// (un icono fijo en Perfil, una inicial calculada a mano en el header
// del Dashboard) a un único `ProfileAvatar` con la foto del proveedor.
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

import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/core/widgets/profile_avatar.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

AppAccount _cuenta({String? photoUrl}) => AppAccount(
      uid: 'u1',
      email: 'a@b.com',
      profileStatus: AppProfileStatus.completeProfile,
      photoUrl: photoUrl,
    );

UserModel _usuario(String nombre) => UserModel(
      id: 'u1',
      name: nombre,
      age: 35,
      gender: 'M',
      weight: 80,
      height: 180,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 6),
        sleepTime: DateTime(2026, 1, 1, 22),
        firstMealGoal: DateTime(2026, 1, 1, 8),
        lastMealGoal: DateTime(2026, 1, 1, 18),
      ),
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
    // Esto es exactamente lo que hacía mal el header del Dashboard.
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

  // El header del Dashboard tenía su PROPIA copia del avatar. Este test
  // existe para que no vuelva a divergir: si alguien reintroduce un
  // CircleAvatar acá, la foto de Google deja de verse en el Dashboard y
  // nadie se entera hasta que un usuario lo reporta.
  group('ElenaHeader', () {
    testWidgets('usa el ProfileAvatar compartido, no su propia copia',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_cuenta())),
            currentUserStreamProvider
                .overrideWith((ref) => Stream.value(_usuario('Carlos'))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ElenaHeader(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
    });
  });
}
