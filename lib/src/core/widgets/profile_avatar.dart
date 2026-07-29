import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Avatar del usuario — fuente única para Perfil y para el header del
/// Dashboard (29-jul).
///
/// Vive en `core/widgets` y no en `features/auth` porque lo consumen dos
/// features distintas. El import de `auth_providers` desde core sigue el
/// mismo patrón que ya usan `imr_persistence_provider` y
/// `weekly_imr_staleness_trigger`.
///
/// Antes había DOS avatares con reglas distintas: Perfil mostraba un
/// `Icons.person_rounded` fijo, y `ElenaHeader` calculaba su inicial con
/// `user.name[0]` — que parte por la mitad cualquier nombre que empiece
/// por letra acentuada o emoji, porque indexa unidades UTF-16, no
/// grafemas. Se unifican los dos en este widget.
///
/// Tres niveles, cada uno respaldo del anterior:
///
///   1. la foto del proveedor (`AppAccount.photoUrl`, hoy solo Google),
///   2. la inicial del nombre, si no hay foto o si la foto falla,
///   3. el icono genérico, si tampoco hay nombre.
///
/// El orden importa: `Image.network` puede fallar por red, por un 403 de
/// Google o porque el usuario quitó su foto, y en cualquiera de esos
/// casos el avatar NO puede quedarse en blanco. Por eso la inicial se
/// dibuja SIEMPRE por debajo (en el `Stack`) y la imagen se pinta encima
/// cuando y si carga — así no hay hueco, ni spinner, ni salto de layout.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, required this.name, this.size = 52});

  final String name;
  final double size;

  /// Primera letra del nombre, en mayúscula. Vacío si no hay nada
  /// aprovechable — un nombre en blanco o compuesto solo de espacios.
  ///
  /// `.characters` y no `[0]`: "Ángela" en UTF-16 puede empezar por una
  /// 'A' seguida de un acento combinante, y `[0]` devolvería la letra
  /// sin tilde o, peor, media pareja subrogada en un emoji.
  static String initialOf(String name) {
    final limpio = name.trim();
    if (limpio.isEmpty) return '';
    return limpio.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `valueOrNull` y no `value`: si el stream de auth todavía no emitió
    // (arranque en frío), esto debe ser null y caer a la inicial, no
    // lanzar. Quien nos monta ya tiene el nombre del UserModel.
    final photoUrl = ref.watch(authStateProvider).valueOrNull?.photoUrl;
    final inicial = initialOf(name);

    final Widget respaldo = inicial.isEmpty
        ? Icon(Icons.person_rounded,
            color: AppColors.metabolicGreen, size: size * 0.5)
        : Text(
            inicial,
            style: TextStyle(
              color: AppColors.metabolicGreen,
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
        color: AppColors.metabolicGreen.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Center(child: respaldo),
          if (photoUrl != null && photoUrl.isNotEmpty)
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              // Sin `loadingBuilder` a propósito: mientras carga se ve la
              // inicial de abajo, que es mejor que un spinner diminuto.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              semanticLabel: 'Foto de perfil',
            ),
        ],
      ),
    );
  }
}
