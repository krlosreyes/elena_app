import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// SPEC-116: sin border coloreado. El badge IMR ya comunica el
/// estado clínico.
///
/// SPEC-119: extraído de `_buildIdentityCard` en `profile_screen.dart`
/// (ARCH-03). `_zoneColor(zone)` (un delegador de una línea a
/// `AppColors.imrZoneColor(zone)`) se inlineó — mismo valor, sin
/// cambio de comportamiento.
///
/// 17-jul (Propuesta "un Perfil que da orgullo abrir", P0): el
/// subtítulo mostraba la condición clínica del usuario (ej.
/// "Prediabetes") o, en su defecto, "Expediente metabólico" — lo
/// primero que alguien leía sobre sí mismo era un diagnóstico o una
/// palabra de archivo médico, no algo cálido. Se reemplaza por "Tu
/// perfil metabólico", siempre igual, sin condicionar al estado
/// clínico. Las condiciones médicas (`user.pathologies`) NO se
/// pierden — siguen siendo dato real usado en `fasting_eligibility.dart`
/// para elegibilidad de protocolos — solo se reubicaron como fila de
/// solo-lectura dentro de "Datos biométricos" (ver profile_screen.dart),
/// que es su lugar clínico correcto, no la primera línea de identidad.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.user,
    required this.imrResult,
  });

  final UserModel user;
  final DisplayedImr imrResult;

  @override
  Widget build(BuildContext context) {
    final zoneColor = AppColors.imrZoneColor(imrResult.zone);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          // Avatar
          ProfileAvatar(name: user.name),
          const SizedBox(width: 14),
          // Nombre + patologías
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tu perfil metabólico',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Fix P1 (validación de ejecución real, 23-jul-2026): este
          // anillo con el número de IMR competía visualmente con Score
          // del día por ser "la métrica principal" apenas se abría
          // Perfil, agravando la confusión de "¿cuál número miro?" ya
          // reportada en Progreso (ver ResultsEntryCard). Se reemplaza
          // el número siempre visible por un indicador compacto que
          // navega al detalle — el IMR completo (con su explicación y
          // el badge de "estimado" si aplica) sigue viviendo en
          // ResultadosDetailScreen, no desaparece, solo deja de ocupar
          // el primer plano de la vista de identidad.
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/analysis/resultados'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: zoneColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.query_stats_rounded, color: zoneColor, size: 18),
                  const SizedBox(height: 3),
                  Text(
                    'Ver IMR',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: zoneColor,
                      letterSpacing: 0.2,
                    ),
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

/// Avatar del Perfil (29-jul).
///
/// Antes era un `Icons.person_rounded` fijo: entraras con Google o con
/// email, veías el mismo monigote gris. Ahora hay tres niveles, y cada
/// uno es el respaldo del anterior:
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
  static String initialOf(String name) {
    final limpio = name.trim();
    if (limpio.isEmpty) return '';
    return limpio.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `valueOrNull` y no `value`: si el stream de auth todavía no emitió
    // (arranque en frío), esto debe ser null y caer a la inicial, no
    // lanzar. Perfil ya se está pintando con el UserModel de Firestore.
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
              // inicial de abajo, que es mejor que un spinner de 52 px.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              semanticLabel: 'Foto de perfil',
            ),
        ],
      ),
    );
  }
}

/// SPEC-141 §RF-141-13 (2026-06-05): banner visible cuando el badge
/// está mostrando el IMR longitudinal (feature flag ON). Sin firma
/// clínica todavía → mostrar disclaimer transparente.
///
/// SPEC-119: extraído de `_buildLongitudinalDisclaimer` en
/// `profile_screen.dart` (ARCH-03). Sin parámetros, sin cambios.
class ProfileLongitudinalDisclaimer extends StatelessWidget {
  const ProfileLongitudinalDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.science_outlined,
            color: Color(0xFFF59E0B),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'IMR longitudinal en validación clínica — '
              'tu número refleja tendencia, no diagnóstico.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
