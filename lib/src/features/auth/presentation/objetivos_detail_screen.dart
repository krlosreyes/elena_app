// 17-jul (2da vuelta, rediseño Perfil): "Mis objetivos" pasa de
// sección siempre expandida a card colapsada + pantalla de detalle —
// ver comentario en biometricos_detail_screen.dart, mismo movimiento.
// ProfileGoalsSection no cambió — solo dónde vive.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_goals_section.dart';

class ObjetivosDetailScreen extends StatelessWidget {
  const ObjetivosDetailScreen({super.key});

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
          'Mis objetivos',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
      ),
      body: const SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            ProfileGoalsSection(),
          ],
        ),
      ),
    );
  }
}
