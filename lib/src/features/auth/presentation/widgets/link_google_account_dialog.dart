// Vinculación de Google con una cuenta existente (29-jul-2026).
//
// EL CASO
// -------
// Alguien se registró hace meses con `suyo@gmail.com` y contraseña. Hoy
// toca "Continuar con Google" con ese mismo correo. Firebase no puede
// decidir solo: son dos credenciales para una identidad, y hasta que no
// se demuestre que ambas son de la misma persona no debe unirlas.
//
// Sin este diálogo, lo que ve es un error de Firebase incomprensible y
// se queda fuera de su propia cuenta. La otra salida —crear una segunda
// cuenta con el mismo correo— sería peor: partiría su historial en dos
// sin que se entere.
//
// POR QUÉ SE PIDE LA CONTRASEÑA
// -----------------------------
// Es la prueba de propiedad. Sin ella, cualquiera con una cuenta de
// Google del mismo correo podría apropiarse de la cuenta de Elena. No es
// fricción gratuita: es lo único que separa vincular de suplantar.
//
// Se usa StatefulWidget con su propio controller (patrón de
// `_DeleteAccountDialog`): el bug del 27-jul fue justamente un
// `TextEditingController` liberado antes de `Navigator.pop`, que tumbaba
// la pantalla entera al cancelar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Devuelve `true` si quedaron vinculadas.
Future<bool> showLinkGoogleAccountDialog(
  BuildContext context, {
  required String email,
  required String pendingCredentialToken,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LinkGoogleAccountDialog(
      email: email,
      pendingCredentialToken: pendingCredentialToken,
    ),
  );
  return resultado ?? false;
}

class _LinkGoogleAccountDialog extends ConsumerStatefulWidget {
  const _LinkGoogleAccountDialog({
    required this.email,
    required this.pendingCredentialToken,
  });

  final String email;
  final String pendingCredentialToken;

  @override
  ConsumerState<_LinkGoogleAccountDialog> createState() =>
      _LinkGoogleAccountDialogState();
}

class _LinkGoogleAccountDialogState
    extends ConsumerState<_LinkGoogleAccountDialog> {
  final _controller = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _vincular() async {
    if (_enviando) return;
    setState(() {
      _enviando = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      await ref.read(authRepositoryProvider).linkPendingGoogleCredential(
            pendingCredentialToken: widget.pendingCredentialToken,
            password: _controller.text,
          );
      if (!mounted) return;
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text(
        'Ya tienes cuenta con este correo',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirma tu contraseña de ${widget.email} una vez y dejamos '
            'las dos formas de entrar unidas. Después podrás entrar como '
            'prefieras, con la misma cuenta y el mismo historial.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            enabled: !_enviando,
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _vincular(),
            decoration: InputDecoration(
              labelText: 'Tu contraseña',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          // Cancelar no vincula nada y no borra nada: sigue pudiendo
          // entrar con su contraseña como siempre.
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: _enviando ? null : _vincular,
          child: _enviando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'VINCULAR',
                  style: TextStyle(
                    color: AppColors.metabolicGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
