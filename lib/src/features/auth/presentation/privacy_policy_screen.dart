// SPEC-77: pantalla read-only de la Política de Privacidad.
//
// Accesible desde LoginScreen, RegisterScreen y ProfileScreen.
// Renderiza la lista canonicalizada de `kPrivacyPolicySections`.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/domain/legal_text.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/legal_screen_body.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text(
          'POLÍTICA DE PRIVACIDAD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
      ),
      body: LegalScreenBody(
        sections: kPrivacyPolicySections,
        version: kPrivacyPolicyVersion,
      ),
    );
  }
}
