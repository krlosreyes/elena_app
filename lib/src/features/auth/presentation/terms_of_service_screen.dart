// SPEC-77: pantalla read-only de los Términos de Uso.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/domain/legal_text.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/legal_screen_body.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text(
          'TÉRMINOS DE USO',
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
        sections: kTermsOfServiceSections,
        version: kTermsOfServiceVersion,
      ),
    );
  }
}
