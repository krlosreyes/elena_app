// Botón "Continuar con Google" (29-jul-2026).
//
// Vive suelto porque aparece en login Y en registro con el mismo
// comportamiento: dos copias divergirían en cuanto alguien tocara una.
//
// SE ENCARGA DE LOS TRES DESENLACES, no solo del feliz:
//
//   1. Entra bien           → el router redirige solo (authStateChanges).
//   2. Cancela              → NO pasa nada. Cancelar no es un error y no
//                             debe pintar rojo; es la interacción más
//                             común después de la exitosa.
//   3. Email ya registrado  → abre el diálogo de vinculación. Es el caso
//                             que sin manejo deja a alguien fuera de su
//                             propia cuenta con un error incomprensible.
//
// El icono es un glifo dibujado, no el logo oficial: las condiciones de
// marca de Google exigen su asset exacto y todavía no está en el
// proyecto. Cuando se añada, se cambia solo aquí.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/link_google_account_dialog.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _cargando = false;

  Future<void> _entrar() async {
    if (_cargando) return;
    setState(() => _cargando = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Si devuelve null, canceló: no se hace nada a propósito.
      // Si entra bien, `authStateChanges` mueve el router — esta pantalla
      // no navega a mano para no competir con el redirect.
    } on GoogleAccountNeedsLinkingException catch (e) {
      if (!mounted) return;
      await showLinkGoogleAccountDialog(
        context,
        email: e.email,
        pendingCredentialToken: e.pendingCredentialToken,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _cargando ? null : _entrar,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _cargando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const _GoogleGlyph(),
        label: Text(
          _cargando ? 'Conectando…' : 'Continuar con Google',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

/// Separador "o" entre el formulario y los proveedores externos.
class AuthDividerOr extends StatelessWidget {
  const AuthDividerOr({super.key});

  @override
  Widget build(BuildContext context) {
    final linea = Expanded(
      child: Divider(color: Colors.white.withValues(alpha: 0.15)),
    );
    return Row(
      children: [
        linea,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ),
        linea,
      ],
    );
  }
}

/// "G" con los cuatro colores de Google. Provisional — ver nota de
/// cabecera sobre el asset oficial.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.metabolicGreen,
          ),
        ),
      ),
    );
  }
}
