import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Acceso")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Text("Ingresa tu email para recibir un enlace de restauración."),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).sendPasswordResetEmail(emailController.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enlace enviado si el correo existe.")));
                    Navigator.pop(context);
                  }
                },
                child: const Text("ENVIAR ENLACE"),
              ),
            )
          ],
        ),
      ),
    );
  }
}