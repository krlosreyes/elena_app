import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget que carga el icono SVG de perfil con estilo técnico.
class UserProfileIcon extends StatelessWidget {
  final double size;

  const UserProfileIcon({
    super.key,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos el color primario del tema actual
    final Color primaryColor = Theme.of(context).primaryColor;

    return SvgPicture.asset(
      'assets/images/iconos/icono_perfil.svg',
      width: size,
      height: size,
      // Aplicamos el tinte moderno con ColorFilter
      colorFilter: ColorFilter.mode(
        primaryColor,
        BlendMode.srcIn,
      ),
      // Manejo de error si el archivo no existe aún
      placeholderBuilder: (context) => SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
