// Rediseño Perfil (2026-11-04): "Cuenta y datos personales".
//
// Un solo lugar para editar lo que antes era de solo lectura: nombre, edad,
// estatura y sexo, más el acceso (correo, contraseña, Google) y el borrado
// de cuenta. Peso y medidas NO se editan aquí: tienen su bloqueo semanal en
// Perfil › Tu cuerpo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/auth/data/account_email_service.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart'
    show AuthProviderKind;
import 'package:elena_app/src/features/auth/presentation/widgets/profile_danger_zone_actions.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

const _surface = Color(0xFF0C1422);
const _muted = Color(0xFF94A3B8);

/// "krlosreyes2@gmail.com" → "krl•••@gmail.com".
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final local = email.substring(0, at);
  final keep = local.length <= 3 ? 1 : 3;
  return '${local.substring(0, keep)}•••${email.substring(at)}';
}

/// "Carlos Manuel Reyes" → "CR".
String initialsOf(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Cuenta y datos personales',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _AccountBody(user: user),
    );
  }
}

class _AccountBody extends ConsumerStatefulWidget {
  const _AccountBody({required this.user});

  final UserModel user;

  @override
  ConsumerState<_AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends ConsumerState<_AccountBody> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late String _gender;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u.name)..addListener(_changed);
    _age = TextEditingController(text: '${u.age}')..addListener(_changed);
    _height = TextEditingController(text: u.height.round().toString())
      ..addListener(_changed);
    _gender = u.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _dirty {
    final u = widget.user;
    return _name.text.trim() != u.name ||
        _age.text.trim() != '${u.age}' ||
        _height.text.trim() != u.height.round().toString() ||
        _gender != u.gender;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim().replaceAll(',', '.'));
    final messenger = ScaffoldMessenger.of(context);
    if (age == null || height == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Revisa la edad y la estatura.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    final bodyChanged = height.round() != widget.user.height.round() ||
        _gender != widget.user.gender;
    final ok =
        await ref.read(profileControllerProvider.notifier).updateBasicData(
              currentUser: widget.user,
              name: _name.text,
              age: age,
              height: height,
              gender: _gender,
            );
    if (!mounted) return;
    final err = ref.read(profileControllerProvider).errorMessage;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? (bodyChanged
              ? 'Datos guardados. Tu IMR se actualizó con tus nuevos datos.'
              : 'Datos guardados.')
          : (err ?? 'No se pudieron guardar tus datos.')),
      backgroundColor: ok ? const Color(0xFF10B981) : Colors.redAccent,
    ));
    ref.read(profileControllerProvider.notifier).clearFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authStateProvider).valueOrNull;
    final email = account?.email ?? '';
    final providers = ref.read(authRepositoryProvider).currentUserProviders();
    final hasPassword = providers.contains(AuthProviderKind.password);
    final hasGoogle = providers.contains(AuthProviderKind.google);
    final saving = ref.watch(profileControllerProvider.select((s) => s.isSaving));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.metabolicGreen.withValues(alpha: 0.16),
              border: Border.all(color: AppColors.metabolicGreen, width: 2),
            ),
            child: Text(
              initialsOf(_name.text),
              style: const TextStyle(
                color: AppColors.metabolicGreen,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('DATOS BÁSICOS'),
        const SizedBox(height: 10),
        _Field(label: 'Nombre', controller: _name, maxLength: 60),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Edad',
                controller: _age,
                suffix: 'años',
                numeric: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Field(
                label: 'Estatura',
                controller: _height,
                suffix: 'cm',
                numeric: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Sexo biológico',
            style: TextStyle(
                color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              for (final (value, label) in const [
                ('M', 'Masculino'),
                ('F', 'Femenino'),
              ])
                Expanded(
                  child: Semantics(
                    selected: _gender == value,
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = value),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _gender == value
                              ? const Color(0xFF1A2332)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: _gender == value ? Colors.white : _muted,
                            fontSize: 14,
                            fontWeight: _gender == value
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Estatura y sexo se usan para calcular tu composición corporal y '
          'tu IMR.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (!_dirty || saving) ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.metabolicGreen,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF032A22)),
                  )
                : Text(
                    'Guardar cambios',
                    style: TextStyle(
                      color: _dirty
                          ? const Color(0xFF032A22)
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tu peso y tus medidas se actualizan en Perfil › Tu cuerpo, una vez '
          'por semana.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
        ),
        const SizedBox(height: 28),
        const _SectionLabel('ACCESO'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              _AccessRow(
                icon: Icons.mail_outline_rounded,
                title: 'Correo',
                subtitle: email.isEmpty ? '—' : maskEmail(email),
                action: 'Cambiar',
                onTap: email.isEmpty
                    ? null
                    : () => ChangeEmailSheet.show(context, currentEmail: email),
              ),
              const _Divider(),
              _AccessRow(
                icon: Icons.lock_outline_rounded,
                title: 'Contraseña',
                subtitle: hasPassword ? null : 'Entras con Google',
                action: hasPassword ? 'Cambiar' : null,
                onTap: hasPassword && email.isNotEmpty
                    ? () => _resetPassword(context, email)
                    : null,
              ),
              const _Divider(),
              _AccessRow(
                icon: Icons.link_rounded,
                title: 'Cuenta de Google',
                trailing: hasGoogle ? 'Vinculada' : 'No vinculada',
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        const ProfileDangerZoneActions(showLogout: false),
      ],
    );
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cambiar contraseña',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Te enviaremos un enlace a ${maskEmail(email)} para que elijas una '
          'contraseña nueva.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Enviar enlace',
                style: TextStyle(
                    color: AppColors.metabolicGreen,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      messenger.showSnackBar(const SnackBar(
        content: Text('Listo. Revisa tu correo para cambiar tu contraseña.'),
        backgroundColor: Color(0xFF10B981),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(AccountEmailService.messageFor(e)),
        backgroundColor: Colors.redAccent,
      ));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.suffix,
    this.numeric = false,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? suffix;
  final bool numeric;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: numeric ? TextInputType.number : TextInputType.name,
      textCapitalization:
          numeric ? TextCapitalization.none : TextCapitalization.words,
      inputFormatters:
          numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _muted),
        counterText: '',
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.metabolicGreen, width: 1.5),
        ),
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: _muted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null)
                      Text(title,
                          style: const TextStyle(color: _muted, fontSize: 12)),
                    Text(
                      subtitle ?? title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null)
                Text(
                  action!,
                  style: const TextStyle(
                    color: AppColors.metabolicGreen,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (trailing != null)
                Text(trailing!,
                    style: const TextStyle(color: _muted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
        color: Colors.white.withValues(alpha: 0.06),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Cambiar correo
// ─────────────────────────────────────────────────────────────────────────────

class ChangeEmailSheet extends ConsumerStatefulWidget {
  const ChangeEmailSheet({super.key, required this.currentEmail});

  final String currentEmail;

  static Future<void> show(BuildContext context,
      {required String currentEmail}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeEmailSheet(currentEmail: currentEmail),
    );
  }

  @override
  ConsumerState<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends ConsumerState<ChangeEmailSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newEmail = _email.text.trim();
    final v =
        AccountEmailService.validate(newEmail, currentEmail: widget.currentEmail);
    if (v != null) {
      setState(() => _error = v);
      return;
    }
    final controller = ref.read(profileControllerProvider.notifier);
    final method = controller.reauthMethod();
    if (method == AuthProviderKind.password && _password.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña para confirmar.');
      return;
    }
    if (method == null) {
      setState(() => _error =
          'No pudimos confirmar tu identidad. Cierra sesión, vuelve a '
          'entrar e intenta de nuevo.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (method == AuthProviderKind.password) {
        await controller.reauthenticate(_password.text);
      } else {
        final ok = await controller.reauthenticateWithGoogle();
        if (!ok) {
          if (mounted) setState(() => _busy = false);
          return;
        }
      }
      await ref.read(accountEmailServiceProvider).requestEmailChange(newEmail);
      if (mounted) {
        setState(() {
          _busy = false;
          _sent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AccountEmailService.messageFor(e);
        });
      }
    } finally {
      controller.clearFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usesPassword = ref
            .read(profileControllerProvider.notifier)
            .reauthMethod() ==
        AuthProviderKind.password;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: _sent ? _buildSent(context) : _buildForm(usesPassword),
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _buildForm(bool usesPassword) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _handle(),
        const SizedBox(height: 18),
        const Text('Cambiar tu correo',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Actual: ${maskEmail(widget.currentEmail)}',
            style: const TextStyle(color: _muted, fontSize: 14)),
        const SizedBox(height: 18),
        TextField(
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onChanged: (_) => setState(() => _error = null),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: _decoration('Correo nuevo'),
        ),
        if (usesPassword) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            onChanged: (_) => setState(() => _error = null),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _decoration('Tu contraseña, para confirmar que eres tú'),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text('Te pediremos confirmar con Google.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: const TextStyle(color: Color(0xFFF09595), fontSize: 13)),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.metabolicGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.metabolicGreen.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Te enviaremos un enlace al correo nuevo. Tu correo cambia cuando '
            'lo abras; hasta entonces sigues entrando con el actual.',
            style: TextStyle(color: Color(0xFFCFE9E1), fontSize: 13.5, height: 1.45),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.metabolicGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF032A22)),
                  )
                : const Text(
                    'Enviar enlace de confirmación',
                    style: TextStyle(
                      color: Color(0xFF032A22),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: _muted)),
        ),
      ],
    );
  }

  Widget _buildSent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(),
        const SizedBox(height: 22),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.metabolicGreen.withValues(alpha: 0.14),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.metabolicGreen, size: 26),
        ),
        const SizedBox(height: 14),
        const Text('Revisa tu correo nuevo',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'Enviamos un enlace a ${_email.text.trim()}. Ábrelo para terminar '
          'el cambio. Si no lo ves, revisa la carpeta de spam.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Listo',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: AppColors.backgroundDark,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.metabolicGreen, width: 1.5),
        ),
      );
}
