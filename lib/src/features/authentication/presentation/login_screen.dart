import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/exceptions/exceptions.dart';
import 'login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(loginControllerProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(
      loginControllerProvider,
      (_, state) {
        if (state.hasError) {
          final error = state.error;
          String message = 'Error desconocido';
          if (error is AppException) {
            message = error.message;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
          );
        } else if (state.hasValue && !state.isLoading) {
          // Si el valor es true, necesita onboarding
          if (state.value == true) {
             context.go('/onboarding');
          } else {
             context.go('/dashboard');
          }
        }
      },
    );

    final state = ref.watch(loginControllerProvider);
    final isLoading = state.isLoading;

    // ✅ MEJORA UI/DEUDA TÉCNICA: Se eliminaron los colores Hardcoded (Zombies). 
    // Ahora, los widgets reaccionan al Theme.of(context), blindando la UI a implementaciones 
    // de Material Design 3 dinámicas y Light/Dark mode.
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).scaffoldBackgroundColor, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Logo Héroe con Brillo Neón (Contour Glow) adaptado al Theme
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.7,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 180,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/logo.png',
                            height: 180,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Título Actualizado
                    Text(
                      'Bienvenido a ElenaApp',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 3. Inputs integrados con Themes
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu email';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Email inválido (ej. usuario@gmail.com)';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: colorScheme.secondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    // 4. Botón Principal asíncrono
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? CircularProgressIndicator(color: colorScheme.primary)
                            : const Text('INICIAR SESIÓN'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Link de Registro
                    TextButton(
                      onPressed:
                          isLoading ? null : () => context.push('/register'),
                      child: const Text('Regístrate aquí'),
                    ),
                    const SizedBox(height: 32),
                    
                    // ✅ MEJORA UI/Arquitectura: 
                    // Se ha eliminado el Botón de Google Sign-in que estaba muerto
                    // y provocaba código zombi y deudas arquitectónicas hasta que Identity se habilite formalmente.
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
