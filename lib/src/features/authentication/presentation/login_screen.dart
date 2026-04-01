import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/blueprint_grid.dart';
import '../application/login_controller.dart';
import 'widgets/elena_terminal_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(loginControllerProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    // Listen for errors
    ref.listen<AsyncValue<bool>>(loginControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
      );
    });

    return BlueprintGrid(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo with Glow
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_circular.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppTheme.surface,
                            child: const Icon(Icons.biotech,
                                color: AppTheme.primary, size: 60),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Header
                  Column(
                    children: [
                      Text(
                        'BIENVENID@',
                        style: GoogleFonts.publicSans(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ELENA APP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 2,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Inputs
                  ElenaTerminalInput(
                    controller: _emailController,
                    label: 'Email de Acceso',
                    placeholder: 'sys_user@elena.log',
                    prefixIcon: Icons.terminal,
                    suffixIcon: Icons.alternate_email,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (!value.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElenaTerminalInput(
                    controller: _passwordController,
                    label: 'Clave de Seguridad',
                    placeholder: '********',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: Icons.vpn_key_outlined,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (value.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: loginState.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ).copyWith(
                        shadowColor: WidgetStateProperty.all(
                            AppTheme.primary.withValues(alpha: 0.5)),
                        elevation: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.pressed) ? 2 : 8),
                      ),
                      child: loginState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'INICIAR SESIÓN',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.login_outlined),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Secondary Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'RECUPERAR ACCESO',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'CREAR CUENTA',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Footer Status Bar
                  Column(
                    children: [
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'SISTEMA PROTEGIDO',
                            style: GoogleFonts.robotoMono(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.robotoMono(
                                  fontSize: 8, color: Colors.white38),
                              children: [
                                const TextSpan(text: 'ENVIRONMENT '),
                                TextSpan(
                                  text: 'V 2.4.0-STABLE',
                                  style: TextStyle(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.robotoMono(
                                  fontSize: 8, color: Colors.white38),
                              children: [
                                const TextSpan(text: 'STATUS '),
                                const TextSpan(
                                  text: 'OPERATIONAL',
                                  style: TextStyle(color: Colors.cyanAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
