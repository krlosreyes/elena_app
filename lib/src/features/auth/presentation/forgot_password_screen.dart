import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  // ARCH-01 (auditoría 2026-07-11): el controller vivía en build() de un
  // ConsumerWidget sin estado — se recreaba en cada rebuild y nunca se
  // liberaba (leak + pérdida de texto ingresado ante un rebuild externo).
  // Se movió el widget a ConsumerStatefulWidget para que el controller
  // tenga un ciclo de vida propio, gestionado en initState()/dispose().
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    // SEC-01 (auditoría 2026-07-11): antes esta llamada no tenía try/catch.
    // Si el correo no existía, Firebase Auth lanza una excepción que
    // interrumpía la función ANTES de mostrar el SnackBar/hacer pop —
    // es decir, un correo existente y uno inexistente producían
    // resultados visibles distintos en la UI, lo cual es un vector de
    // enumeración de cuentas. Ahora el resultado visible es idéntico en
    // ambos casos, sin importar el motivo del error.
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text.trim());
    } catch (_) {
      // Intencional: no se distingue el motivo del error frente al
      // usuario para no filtrar si el correo existe o no en el sistema.
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Enlace enviado si el correo existe.")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Acceso")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Text(
                "Ingresa tu email para recibir un enlace de restauración."),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendResetLink,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("ENVIAR ENLACE"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
