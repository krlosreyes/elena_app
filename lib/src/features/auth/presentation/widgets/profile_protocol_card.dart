import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

/// Card del protocolo de ayuno: protocolo activo + detalle inline
/// (h ayuno · h ventana) + link sutil a la pantalla "Hoy" donde se
/// edita el protocolo.
///
/// SPEC-119: extraído de `_buildProtocolCard` en `profile_screen.dart`
/// (ARCH-03). `widget.user.fastingProtocol` pasa a ser el parámetro
/// `protocol`; el resto del cuerpo es idéntico.
class ProfileProtocolCard extends StatelessWidget {
  const ProfileProtocolCard({super.key, required this.protocol});

  final String protocol;

  @override
  Widget build(BuildContext context) {
    final parts = protocol.split(':');
    final fastingHours =
        parts.isNotEmpty ? (int.tryParse(parts.first) ?? 16) : 16;
    final feedingHours = parts.length > 1 ? (int.tryParse(parts[1]) ?? 8) : 8;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activo',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  protocol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Text(
              '${fastingHours}h ayuno · ${feedingHours}h ventana',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.borderSubtle,
          ),
          InkWell(
            // SPEC-116: query param `pillar=ayuno` para que el
            // Dashboard abra directamente con la card de Ayuno
            // seleccionada (el chip de protocolo vive ahí).
            onTap: () => context.go('/dashboard?pillar=ayuno'),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Cambiar protocolo',
                    style: TextStyle(
                      color: AppColors.metabolicGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.metabolicGreen.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
