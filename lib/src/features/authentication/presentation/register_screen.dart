import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/exceptions/exceptions.dart';
import 'register_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(registerControllerProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      registerControllerProvider,
      (_, state) {
        if (state.hasError) {
          final error = state.error;
          String message = 'Error desconocido';
          if (error is AppException) {
            message = error.message;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        } else if (state.hasValue && !state.isLoading) {
          // Successful registration navigates to onboarding
          context.go('/onboarding');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cuenta creada. ¡Completemos tu perfil!'),
                backgroundColor: Colors.green),
          );
        }
      },
    );

    final state = ref.watch(registerControllerProvider);
    final isLoading = state.isLoading;

    // Colores Dark Telemetry
    const backgroundColor = Color(0xFF050505);
    const backgroundGradientEnd = Color(0xFF121A1A);
    const neonGreen = Color(0xFF00FFB2);
    const neonCyan = Color(0xFF00E5FF);
    const inputBackground = Color(0xFF151515);
    const borderInactive = Color(0xFF2A2A2A);
    const hintColor = Color(0xFF777777);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, backgroundGradientEnd],
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
                    // 1. Logo Héroe con Brillo Neón (Contour Glow)
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
                                color: neonCyan,
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

                    // 2. Título
                    const Text(
                      'Crea tu cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 3. Inputs con Tema
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o Apodo',
                        labelStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.person_outline, color: neonCyan),
                        filled: true,
                        fillColor: inputBackground,
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderInactive),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: neonGreen, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.email_outlined, color: neonCyan),
                        filled: true,
                        fillColor: inputBackground,
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderInactive),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: neonGreen, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu email';
                        }
                        if (!value.contains('@')) {
                          return 'Email inválido';
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
                        labelStyle: const TextStyle(color: hintColor),
                        prefixIcon: const Icon(Icons.lock_outline, color: neonCyan),
                        filled: true,
                        fillColor: inputBackground,
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: borderInactive),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: neonGreen, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: neonCyan,
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
                    const SizedBox(height: 32),

                    // 4. Botón Principal con Tema Tensor
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: neonGreen,
                          shadowColor: Colors.transparent,
                          side: const BorderSide(color: neonGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: neonGreen)
                            : const Text('COMENZAR MI CAMBIO'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Enlace Login
                    TextButton(
                      onPressed: isLoading ? null : () => context.go('/login'),
                      child: const Text(
                        '¿Ya tienes cuenta? Ingresa aquí',
                        style: TextStyle(
                          color: neonCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  ), // Column
                ), // Form
              ), // ConstrainedBox
            ), // SingleChildScrollView
          ), // Center
        ), // SafeArea
      ), // Container
    ); // Scaffold
  }
}
