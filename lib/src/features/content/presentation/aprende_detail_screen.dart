// 17-jul: pantalla de detalle de "Aprende con Elena" (antes "Para ti",
// SPEC-205) — ver comentario en aprende_entry_card.dart. Mismo AppBar
// simple estilo BadgesScreen/RachaDetailScreen. El contenido no cambió,
// solo se movió detrás de un tap: ForYouSection ya maneja sus propios
// estados de loading/vacío/error.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/content/presentation/for_you_section.dart';

class AprendeDetailScreen extends StatelessWidget {
  const AprendeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Aprende con Elena',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: const [
            ForYouSection(),
          ],
        ),
      ),
    );
  }
}
