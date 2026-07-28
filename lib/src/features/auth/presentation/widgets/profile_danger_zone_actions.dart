import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart'
    show ReauthRequiredException;
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
  ///
  /// El diálogo vive en su propio StatefulWidget porque tiene un
  /// `TextEditingController`, y un controller necesita un `State` que lo
  /// libere en `dispose()`. Ver `_DeleteAccountDialog`.
  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    // SPEC-83 fix: el messenger y el router se capturan ANTES de abrir el
    // diálogo. Tras el borrado esta pantalla deja de existir
    // (`currentUserStreamProvider` emite null), así que su BuildContext ya
    // no sirve para mostrar el SnackBar ni para navegar.
    final messenger = ScaffoldMessenger.of(context);
    final goRouter = GoRouter.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    void avisarExito() {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cuenta eliminada. Hasta pronto.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );
      goRouter.go('/login');
    }

    void avisarError(Object e) {
      messenger.showSnackBar(
        SnackBar(
          // B-12 (auditoría 2026-07-27): mostraba `e.toString()` crudo,
          // así que el usuario veía "Exception: …" en pantalla.
          content: Text(presentableError(e)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(
        onConfirm: () async {
          final controller = ref.read(profileControllerProvider.notifier);
          try {
            await controller.deleteAccount();
            avisarExito();
          } on ReauthRequiredException catch (e) {
            // Firebase pide sesión reciente. No se ha borrado nada, y el
            // usuario sigue autenticado: se le pide la contraseña aquí
            // mismo y se reintenta. Antes del 27-jul-2026 el único
            // remedio era un mensaje diciéndole que cerrara sesión y
            // volviera a entrar — flojo para App Store 5.1.1(v), que
            // exige que borrar la cuenta sea sencillo.
            final password = await _pedirPassword(navigator, e.email);
            if (password == null) return; // canceló: no se borra nada
            try {
              await controller.reauthenticate(password);
              await controller.deleteAccount();
              avisarExito();
            } catch (e2) {
              avisarError(e2);
            }
          } catch (e) {
            avisarError(e);
          }
        },
      ),
    );
  }

  /// Pide la contraseña para confirmar identidad. `null` si el usuario
  /// cancela — en ese caso no se intenta nada y no se borra nada.
  Future<String?> _pedirPassword(NavigatorState navigator, String? email) {
    return showDialog<String>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => _ReauthPasswordDialog(email: email),
    );
  }
}

/// Confirmación por escrito para borrar la cuenta.
///
/// POR QUÉ ES UN StatefulWidget (recorrido en Simulador, 27-jul-2026)
/// ------------------------------------------------------------------
/// Antes era un `StatefulBuilder` y el `TextEditingController` se creaba
/// en la función que abría el diálogo. Cada rama lo trataba de una forma,
/// y las dos estaban mal:
///
///   * CANCELAR llamaba a `confirmController.dispose()` ANTES de
///     `Navigator.pop`. El `TextField` seguía montado, la animación de
///     cierre reconstruía el diálogo y leía un controller ya destruido:
///     "A TextEditingController was used after being disposed". El fallo
///     escalaba a `'_dependents.isEmpty': is not true` y se llevaba por
///     delante la pantalla de Perfil entera. No se recuperaba cerrando y
///     reabriendo la app — había que forzar el cierre del proceso.
///   * ELIMINAR CUENTA hacía `pop` y no liberaba nunca: fuga silenciosa.
///
/// Un controller pertenece al `State` que lo crea y se libera en su
/// `dispose()`. Así el framework decide CUÁNDO, que es justo lo que aquí
/// se estaba haciendo a mano y al revés.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.onConfirm});

  /// Se invoca tras cerrar el diálogo. Cierra sobre el messenger y el
  /// router capturados en la pantalla de Perfil, no sobre el context del
  /// diálogo, que ya no existe cuando el borrado termina.
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();
  bool _isEnabled = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
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
            // "Firestore" es vocabulario interno: el usuario no sabe qué
            // es (recorrido en Simulador, 27-jul-2026).
            'Esta acción es permanente. Se eliminarán tu cuenta y todos tus '
            'datos metabólicos de nuestros servidores.',
            style:
                TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          const Text(
            'Escribe ELIMINAR para confirmar:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
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
              final habilitado = val.trim().toUpperCase() == 'ELIMINAR';
              if (habilitado != _isEnabled) {
                setState(() => _isEnabled = habilitado);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR',
              style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        TextButton(
          onPressed: _isEnabled
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm();
                }
              : null,
          child: Text(
            'ELIMINAR CUENTA',
            style: TextStyle(
              color: _isEnabled
                  ? Colors.redAccent
                  : Colors.redAccent.withValues(alpha: 0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pide la contraseña para confirmar identidad antes de borrar la cuenta.
///
/// StatefulWidget por la misma razón que `_DeleteAccountDialog`: tiene un
/// `TextEditingController` y un controller lo libera el `State` que lo
/// crea, en su `dispose()`. La versión anterior de este archivo gestionaba
/// eso a mano dentro de los botones y tumbaba la pantalla de Perfil
/// entera al cancelar.
class _ReauthPasswordDialog extends StatefulWidget {
  const _ReauthPasswordDialog({this.email});

  /// Email de la cuenta, solo para mostrarlo. No es editable: se está
  /// confirmando la identidad de la sesión actual, no iniciando otra.
  final String? email;

  @override
  State<_ReauthPasswordDialog> createState() => _ReauthPasswordDialogState();
}

class _ReauthPasswordDialogState extends State<_ReauthPasswordDialog> {
  final _passwordController = TextEditingController();
  bool _oculta = true;
  bool _tieneTexto = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_tieneTexto) return;
    Navigator.pop(context, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Confirma tu identidad',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.email == null
                ? 'Escribe tu contraseña para completar el borrado.'
                : 'Escribe la contraseña de ${widget.email} para completar '
                    'el borrado.',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            autofocus: true,
            obscureText: _oculta,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirmar(),
            onChanged: (val) {
              final hay = val.isNotEmpty;
              if (hay != _tieneTexto) setState(() => _tieneTexto = hay);
            },
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle:
                  const TextStyle(color: Color(0xFF475569), fontSize: 13),
              filled: true,
              fillColor: AppColors.backgroundDark,
              suffixIcon: IconButton(
                icon: Icon(
                  _oculta
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
                tooltip: _oculta ? 'Mostrar' : 'Ocultar',
                onPressed: () => setState(() => _oculta = !_oculta),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR',
              style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        TextButton(
          onPressed: _tieneTexto ? _confirmar : null,
          child: Text(
            'CONFIRMAR Y BORRAR',
            style: TextStyle(
              color: _tieneTexto
                  ? Colors.redAccent
                  : Colors.redAccent.withValues(alpha: 0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
