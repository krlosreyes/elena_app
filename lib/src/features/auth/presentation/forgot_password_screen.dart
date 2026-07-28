import 'dart:async';

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
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_isSending) return;
    // B-13 (auditoría 2026-07-27): esta pantalla no validaba NADA. Un campo
    // vacío o con una errata llamaba igual a Firebase, la excepción caía en
    // el catch silencioso de más abajo y el usuario recibía el mismo
    // "Enlace enviado si el correo existe." — un falso positivo. Se queda
    // esperando un correo que nunca pidió nadie.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);

    // SEC-01 (auditoría 2026-07-11): antes esta llamada no tenía try/catch.
    // Si el correo no existía, Firebase Auth lanza una excepción que
    // interrumpía la función ANTES de mostrar el SnackBar/hacer pop —
    // es decir, un correo existente y uno inexistente producían
    // resultados visibles distintos en la UI, lo cual es un vector de
    // enumeración de cuentas. El resultado visible sigue siendo idéntico
    // en ambos casos, sin importar el motivo del error.
    //
    // B-13: lo que SÍ se distingue ahora es el fallo de RED. No filtra si
    // la cuenta existe —un error de conectividad es independiente del
    // correo tecleado— y evita el peor resultado de los dos: que alguien
    // sin conexión crea que el enlace salió y se quede esperando.
    var huboFalloDeRed = false;
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text.trim());
    } on TimeoutException {
      huboFalloDeRed = true;
    } catch (e) {
      // Intencional: no se distingue el motivo del error frente al
      // usuario para no filtrar si el correo existe o no en el sistema.
      // Única excepción, por el motivo de arriba: los errores de red.
      huboFalloDeRed = _esFalloDeRed(e);
    }

    if (!mounted) return;
    setState(() => _isSending = false);

    if (huboFalloDeRed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin conexión. No pudimos enviar el enlace: revisa tu internet '
            'e intenta de nuevo.',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enlace enviado si el correo existe.")));
    Navigator.pop(context);
  }

  /// Detecta un fallo de conectividad sin acoplarse al tipo concreto de
  /// excepción de Firebase (que varía por plataforma).
  static bool _esFalloDeRed(Object e) {
    final texto = e.toString().toLowerCase();
    return texto.contains('network') ||
        texto.contains('unavailable') ||
        texto.contains('sin conexión') ||
        texto.contains('timeout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Acceso")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                  "Ingresa tu email para recibir un enlace de restauración."),
              const SizedBox(height: 24),
              // B-13 / B-15: teclado de email y autofill. Sin `autofillHints`,
              // el llavero de iOS no ofrece el correo guardado, así que el
              // usuario que llega aquí porque no recuerda su contraseña
              // tampoco tiene ayuda para el correo.
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                onFieldSubmitted: (_) => _sendResetLink(),
                decoration: const InputDecoration(
                    labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                validator: (val) {
                  final v = (val ?? '').trim();
                  if (v.isEmpty) return "Ingresa tu email";
                  // Mismo criterio laxo que login_screen: validar de más un
                  // correo real y dejar fuera a un usuario legítimo sería peor
                  // que dejar pasar uno mal escrito, que Firebase rechaza.
                  if (!v.contains('@') || !v.contains('.')) {
                    return "Email no válido";
                  }
                  return null;
                },
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
      ),
    );
  }
}
