import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/core/utils/error_presentation.dart';

/// SPEC-116: logout y delete account pasan a text buttons sutiles
/// (estilo Apple Settings). El logout era verde sólido — pelea por
/// atención con CTAs primarios. Ahora ambos botones son textuales,
/// ancho completo pero sin fill, con el delete en rojo opaco como
/// señal de acción crítica.
///
/// SPEC-119: extraído de `_buildLogoutTextButton` + `_confirmLogout` +
/// `_buildDeleteAccountTextButton` + `_confirmDeleteAccount` en
/// `profile_screen.dart` (ARCH-03). Lógica de sign out / delete
/// account intacta, solo cambió de vivir en `_ProfileBodyState` a un
/// `ConsumerWidget` propio.
class ProfileDangerZoneActions extends ConsumerWidget {
  const ProfileDangerZoneActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildLogoutTextButton(context, ref),
        const SizedBox(height: 4),
        _buildDeleteAccountTextButton(context, ref),
      ],
    );
  }

  Widget _buildLogoutTextButton(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => _confirmLogout(context, ref),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: Colors.white.withValues(alpha: 0.85),
      ),
      child: const Text(
        'Cerrar sesión',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDeleteAccountTextButton(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => _confirmDeleteAccount(context, ref),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: Colors.redAccent.withValues(alpha: 0.85),
      ),
      child: const Text(
        'Eliminar cuenta',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // CA-02-03: Firebase cierra sesión y el guard redirige a /login
              await ref.read(profileControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('CERRAR SESIÓN',
                style: TextStyle(
                    color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Diálogo de doble confirmación con campo de texto "ELIMINAR" (CA-02-04)
  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    bool isEnabled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text('Eliminar cuenta',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción es permanente. Se eliminarán tu cuenta y todos tus datos metabólicos de Firestore.',
                style: TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text(
                'Escribe ELIMINAR para confirmar:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'ELIMINAR',
                  hintStyle:
                      const TextStyle(color: Color(0xFF475569), fontSize: 13),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                onChanged: (val) {
                  setModalState(() {
                    isEnabled = val.trim().toUpperCase() == 'ELIMINAR';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('CANCELAR',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: isEnabled
                  ? () async {
                      Navigator.pop(ctx);
                      // SPEC-83 fix: capturar el messenger ANTES del
                      // await para no depender del context tras el
                      // delete (la pantalla deja de existir cuando
                      // currentUserStreamProvider emite null).
                      final messenger = ScaffoldMessenger.of(context);
                      final goRouter = GoRouter.of(context);
                      try {
                        await ref
                            .read(profileControllerProvider.notifier)
                            .deleteAccount();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cuenta eliminada. Hasta pronto.',
                            ),
                            backgroundColor: Color(0xFF10B981),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        goRouter.go('/login');
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            // B-12 (auditoría 2026-07-27): mostraba
                            // `e.toString()` crudo, así que el usuario
                            // veía "Exception: Por seguridad, tu sesión
                            // es muy antigua…" al fallar el borrado.
                            content: Text(presentableError(e)),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  : null,
              child: Text(
                'ELIMINAR CUENTA',
                style: TextStyle(
                  color: isEnabled
                      ? Colors.redAccent
                      : Colors.redAccent.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
