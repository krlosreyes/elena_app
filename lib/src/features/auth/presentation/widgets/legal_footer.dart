// SPEC-77: footer reutilizable con los links a Política de Privacidad
// y Términos de Uso. Usado por LoginScreen y RegisterScreen.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class LegalFooter extends StatelessWidget {
  /// Verbo de la acción (ej. 'iniciar sesión', 'registrarte').
  final String actionVerb;

  const LegalFooter({super.key, required this.actionVerb});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.5,
          ),
          children: [
            TextSpan(text: 'Al $actionVerb aceptas nuestros '),
            TextSpan(
              text: 'Términos de uso',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => GoRouter.of(context).push('/legal/terms'),
            ),
            const TextSpan(text: ' y la '),
            TextSpan(
              text: 'Política de privacidad',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => GoRouter.of(context).push('/legal/privacy'),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
