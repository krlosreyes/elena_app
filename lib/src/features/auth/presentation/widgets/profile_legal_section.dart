import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// SPEC-117: grupo legal redesigned como footer plano "presente pero
/// no protagonista". Sin border, sin background coloreado, sin
/// iconos. Solo filas de texto con chevron sutil + divisores
/// delgadísimos. Tipografía secundaria (alpha 0.7) y sub más tenue
/// (alpha 0.4) para que el bloque "respire" abajo en la pantalla.
///
/// SPEC-119: extraído de `_buildLegalGroup` + `_legalRow` +
/// `_legalDivider` en `profile_screen.dart` (ARCH-03). Sin cambios de
/// comportamiento; solo `context` pasa a venir del `build` propio.
class ProfileLegalSection extends StatelessWidget {
  const ProfileLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _legalRow(
          context: context,
          title: 'Condiciones médicas',
          subtitle: 'Poblaciones de riesgo del IMR',
          route: '/profile/disclaimer',
        ),
        _legalDivider(),
        _legalRow(
          context: context,
          title: 'Política de privacidad',
          subtitle: 'Cómo manejamos tus datos',
          route: '/legal/privacy',
        ),
        _legalDivider(),
        _legalRow(
          context: context,
          title: 'Términos de uso',
          subtitle: 'Condiciones del servicio',
          route: '/legal/terms',
        ),
      ],
    );
  }

  Widget _legalRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.24),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _legalDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.04),
    );
  }
}
