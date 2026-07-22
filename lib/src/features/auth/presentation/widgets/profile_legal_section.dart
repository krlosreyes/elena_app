import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';

/// SPEC-117: grupo legal — footer plano original.
///
/// 20-jul: Carlos pidió que "Legal" tenga la misma visual que
/// "Configuración" (BiometricosEntryCard y hermanas) para que el Perfil
/// se sienta coherente de arriba a abajo — antes esta sección era una
/// lista plana sin card/border/color, y quedaba visualmente "suelta"
/// respecto al resto. Mismo patrón: card con borde de color, icono en
/// caja redondeada, título + subtítulo, chevron. Reutiliza
/// `_LegalEntryCard` interno (no vale la pena un archivo nuevo por 3
/// items que solo se usan acá).
class ProfileLegalSection extends StatelessWidget {
  const ProfileLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LegalEntryCard(
          icon: Icons.health_and_safety_outlined,
          color: const Color(0xFFF87171),
          title: 'Condiciones médicas',
          subtitle: 'Poblaciones de riesgo del IMR',
          onTap: () => context.push('/profile/disclaimer'),
        ),
        const SizedBox(height: 10),
        _LegalEntryCard(
          icon: Icons.privacy_tip_outlined,
          color: const Color(0xFF2DD4BF),
          title: 'Política de privacidad',
          subtitle: 'Cómo manejamos tus datos',
          onTap: () => context.push('/legal/privacy'),
        ),
        const SizedBox(height: 10),
        _LegalEntryCard(
          icon: Icons.description_outlined,
          color: const Color(0xFF94A3B8),
          title: 'Términos de uso',
          subtitle: 'Condiciones del servicio',
          onTap: () => context.push('/legal/terms'),
        ),
      ],
    );
  }
}

/// 20-jul: mismo pedido de coherencia visual aplicado a "Guía de la
/// app" (sección Ayuda) — antes era un `InkWell` inline sin card en
/// `profile_screen.dart`. Se extrae acá para reusar `_LegalEntryCard`
/// y mantener la lógica de reset+activate del tour en un solo lugar.
class ProfileHelpGuideCard extends ConsumerWidget {
  const ProfileHelpGuideCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LegalEntryCard(
      icon: Icons.explore_outlined,
      color: AppColors.metabolicGreen,
      title: 'Guía de la app',
      subtitle: 'Vuelve a ver el tour interactivo',
      onTap: () async {
        await ref.read(appTourProvider.notifier).forceReset();
        await ref.read(appTourProvider.notifier).tryActivate();
        if (context.mounted) context.go('/dashboard');
      },
    );
  }
}

/// Card compacta compartida por Legal y Ayuda — mismo patrón visual que
/// `BiometricosEntryCard`/`RitmosEntryCard`/etc: container con borde de
/// color, icono en caja redondeada, título + subtítulo, chevron.
class _LegalEntryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LegalEntryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
