// SPEC-299 — Avatar de un participante del reto para el tablero.
//
// A diferencia de `core/widgets/profile_avatar.dart` (que lee la foto de MI
// sesión de auth), este pinta el avatar de CUALQUIER participante a partir de
// los datos publicados en su `ChallengeScore` (nombre + photoUrl). Tres niveles,
// cada uno respaldo del anterior: foto → inicial del nombre → icono genérico.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class ChallengeAvatar extends StatelessWidget {
  const ChallengeAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 38,
    this.highlight = false,
  });

  final String name;
  final String? photoUrl;
  final double size;

  /// Aro de acento (para marcar "tú" o el líder).
  final bool highlight;

  static String _initialOf(String name) {
    final limpio = name.trim();
    if (limpio.isEmpty) return '';
    return limpio.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final inicial = _initialOf(name);
    final Widget respaldo = inicial.isEmpty
        ? Icon(Icons.person_rounded, color: AppColors.accent, size: size * 0.5)
        : Text(
            inicial,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
            ),
          );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent.withValues(alpha: 0.14),
        border:
            highlight ? Border.all(color: AppColors.accent, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Center(child: respaldo),
          if (photoUrl != null && photoUrl!.isNotEmpty)
            Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              semanticLabel: 'Foto de $name',
            ),
        ],
      ),
    );
  }
}
