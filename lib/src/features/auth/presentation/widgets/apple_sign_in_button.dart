// Botón "Continuar con Apple" (App Store 4.8, 2026-11-06).
//
// Solo en iOS. Sigue las pautas de Apple: fondo blanco, logo de Apple y
// texto negro, con la misma altura y forma que el botón de Google y por
// encima de él (igual o más prominente que el resto de logins sociales).
//
// Al entrar bien, `authStateChanges` mueve el router. Cancelar no es un
// error: no se muestra nada.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/data/apple_auth_service.dart';

class AppleSignInButton extends ConsumerStatefulWidget {
  const AppleSignInButton({super.key});

  @override
  ConsumerState<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends ConsumerState<AppleSignInButton> {
  bool _cargando = false;

  Future<void> _entrar() async {
    if (_cargando) return;
    setState(() => _cargando = true);
    try {
      await ref.read(appleAuthServiceProvider).signIn();
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
    if (!AppleAuthService.isAvailable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _cargando ? null : _entrar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: _cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.apple, size: 22, color: Colors.black),
          label: Text(
            _cargando ? 'Conectando…' : 'Continuar con Apple',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
