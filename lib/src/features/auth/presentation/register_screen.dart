import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/utils/error_presentation.dart';
import 'package:elena_app/src/features/auth/application/auth_controller.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/legal_footer.dart';

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
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(presentableError(err)),
              backgroundColor: Colors.redAccent),
        ),
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Crear Cuenta",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Text("Únete al Ecosistema Metamorfosis Real"),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: "Nombre Completo",
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "Campo requerido" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: (val) => (val == null || !val.contains('@'))
                      ? "Email inválido"
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  // B-15: `newPassword` es lo que hace que iOS ofrezca
                  // GENERAR y guardar una contraseña fuerte en el alta.
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  // B-17 (auditoría 2026-07-27): el requisito de 8 caracteres
                  // solo se revelaba DESPUÉS de fallar la validación. Mostrarlo
                  // como texto de ayuda evita el fallo en vez de explicarlo.
                  decoration: const InputDecoration(
                      labelText: "Contraseña",
                      helperText: "Mínimo 8 caracteres",
                      prefixIcon: Icon(Icons.lock_outline)),
                  // SEC-06 (auditoría 2026-07-11): subido de 6 a 8 caracteres
                  // para que una contraseña NUEVA cumpla el mismo mínimo que
                  // ya exigía set_password_screen.dart (flujo de magic link).
                  // Esto NO afecta a usuarios ya registrados con 6-7
                  // caracteres — ver login_screen.dart, que a propósito NO
                  // se tocó (cambiar su validador rompería el login de
                  // cuentas existentes).
                  validator: (val) => (val == null || val.length < 8)
                      ? "Mínimo 8 caracteres"
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                      labelText: "Confirmar Contraseña",
                      prefixIcon: Icon(Icons.lock_reset)),
                  // B-20 (auditoría 2026-07-27): con el formulario vacío, este
                  // validador comparaba '' contra '' → iguales → sin error.
                  // Los otros tres campos se marcaban en rojo y este quedaba
                  // en verde estando vacío, dando la impresión falsa de que
                  // era el único correcto.
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Confirma tu contraseña";
                    }
                    if (val != _passwordController.text) {
                      return "Las contraseñas no coinciden";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.metabolicGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("REGISTRARME",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),

                // 29-jul: registrarse con Google. Es el MISMO botón que
                // en login — Google no distingue "registro" de "entrada",
                // crea la cuenta si no existe. Ponerlo también aquí evita
                // que quien llegó a esta pantalla tenga que volver atrás
                // para usarlo.
                const SizedBox(height: 20),
                const AuthDividerOr(),
                const SizedBox(height: 16),
                const GoogleSignInButton(),

                // SPEC-77: footer legal antes de continuar.
                const LegalFooter(actionVerb: 'registrarte'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
