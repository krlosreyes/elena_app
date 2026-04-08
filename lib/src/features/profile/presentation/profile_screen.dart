import 'package:elena_app/src/core/exceptions/exceptions.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_screen.dart';
import '../../../core/widgets/elena_header.dart';
import '../../authentication/application/auth_controller.dart';
import '../application/user_controller.dart';
import 'widgets/body_metrics_table.dart';
import 'widgets/composition_telemetry_card.dart';
import 'widgets/dynamic_body_avatar.dart';
import 'widgets/measure_update_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  static const Color accentNeon = Color(0xFFFF9D00);
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserStreamProvider);

    // 🛡️ LISTENER DE ERRORES DE AUTENTICACIÓN
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (error, stack) {
          final String message = error is AppException
              ? error.message
              : 'Ocurrió un error inesperado al procesar tu solicitud.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    });

    return userState.when(
      data: (user) {
        if (user == null) {
          return const AppErrorScreen(
            message: 'No se encontraron datos de usuario.',
          );
        }
        return _buildContent(context, user, ref);
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: accentNeon)),
      error: (error, stack) => AppErrorScreen(
        message: 'Error cargando tu perfil. Intenta de nuevo.',
        onRetry: () => ref.invalidate(currentUserStreamProvider),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020205),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // CAPA DE HEADER: PERFIL & ID
                  ElenaHeader(title: 'MI PERFIL', user: user),
                  const SizedBox(height: 10),

                  // 1. BodyAvatarWidget (Silueta Reescalada Dominante)
                  SizedBox(
                    height: 500,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Silueta Central
                        DynamicBodyAvatar(user: user, height: 440),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Nueva Tarjeta de Composición Corporal (CompositionTelemetryCard)
                  CompositionTelemetryCard(user: user),

                  const SizedBox(height: 20),

                  // 3. BodyMetricsTable (Tabla de Perímetros)
                  BodyMetricsTable(user: user),

                  const SizedBox(height: 30),

                  // 4. WeeklyRegisterButton
                  _buildRegisterButton(context, user),

                  const SizedBox(height: 50),

                  // 5. FooterSecurityButtons (Cerrar sesión & Eliminar perfil)
                  _buildSecurityButtons(context, ref),

                  const SizedBox(height: 40),

                  // Footer de Sistema
                  _buildSystemFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context, UserModel user) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => MeasureUpdateDialog.show(context, user),
        icon: Icon(Icons.edit_note, color: AppTheme.primary, size: 20),
        label: Text(
          'REGISTRAR MEDIDAS SEMANALES',
          style: GoogleFonts.robotoMono(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: AppTheme.primary.withValues(alpha: 0.06),
        ),
      ),
    );
  }

  Widget _buildSecurityButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          child: Text(
            'CERRAR SESIÓN',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _showDeleteConfirmation(context, ref),
          child: Text(
            'ELIMINAR PERFIL Y DATOS',
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFFFF2D55).withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F12),
        title: Text(
          '¿ELIMINAR PERFIL?',
          style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFF2D55)),
        ),
        content: Text(
          'Esta acción borrará permanentemente tu historial metabólico.',
          style: GoogleFonts.publicSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).deleteAccount();
            },
            child: const Text(
              'ELIMINAR TODO',
              style: TextStyle(color: Color(0xFFFF2D55)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemFooter() {
    return Column(
      children: [
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 16),
        Text(
          'ANTIGRAVITY // BIOMETRIC_HUD_v2.5',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white10,
            fontSize: 8,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}
