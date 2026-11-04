// Rediseño Perfil (2026-11-04): secciones que salen de la pantalla principal
// para bajar la saturación. Son configuraciones que se tocan una vez, no
// todos los días.
//
//   /profile/salud  — Apple Salud, protocolo de glucosa, condiciones.
//   /profile/ayuda  — guía de uso, privacidad y términos.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/glucose_protocol_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_legal_section.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/health_sync/presentation/health_sync_card.dart';

class _SectionScaffold extends StatelessWidget {
  const _SectionScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: children,
      ),
    );
  }
}

class ProfileHealthScreen extends StatelessWidget {
  const ProfileHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SectionScaffold(
      title: 'Salud y Apple Salud',
      children: [
        HealthSyncCard(),
        SizedBox(height: 14),
        ProfileSettingsGroup(
          children: [
            GlucoseProtocolEntryCard(),
            ProfileHealthConditionsCard(),
          ],
        ),
      ],
    );
  }
}

class ProfileHelpScreen extends StatelessWidget {
  const ProfileHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: 'Ayuda y legal',
      children: [
        ProfileSettingsGroup(
          children: [
            const ProfileHelpGuideCard(),
            ProfileRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Política de privacidad',
              onTap: () => context.push('/legal/privacy'),
            ),
            ProfileRow(
              icon: Icons.description_outlined,
              title: 'Términos de uso',
              onTap: () => context.push('/legal/terms'),
            ),
          ],
        ),
      ],
    );
  }
}
