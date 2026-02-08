import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../authentication/data/auth_repository.dart';
import 'onboarding_controller.dart';
import 'steps/step_bio.dart';
import 'steps/step_body.dart';
import 'steps/step_metabolic.dart';
import 'steps/step_circadian.dart';
import 'steps/step_clinical.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _steps = const [
    StepBio(),
    StepBody(),
    StepMetabolic(),
    StepCircadian(),
    StepClinical(),
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador con datos del usuario actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authUser = ref.read(authRepositoryProvider).currentUser;
      if (authUser != null) {
        ref.read(onboardingControllerProvider.notifier).init(
              authUser.uid,
              authUser.email ?? '',
              authUser.displayName ?? 'Usuario',
            );
      }
    });
  }

  // Se reemplazó en el paso anterior junto con el build,
  // pero necesito eliminar la definición duplicada antigua si existe.
  // Actually, I am replacing the `_nextPage` call in `build`, but I need to replace the definition too.
  // The previous replace covered the build method calling `_nextPage`.
  // Wait, I replaced the build method body but `_nextPage` definition was mostly ABOVE/BELOW.
  // My previous replace instruction targeted lines 95-131 (body build), but added `_nextPage` definition at the end.
  // So I have a duplicate `_nextPage` at lines 46-59. I must delete it.


  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si el controlador aún no ha inicializado el usuario, mostramos carga
    final userState = ref.watch(onboardingControllerProvider);
    if (userState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = (_currentPage + 1) / _steps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura tu Perfil'),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevPage,
              )
            : null,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: Theme.of(context).colorScheme.secondary,
            minHeight: 6,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _steps,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextPage,
                // Style inherited from Theme
                child: Text(
                  _currentPage == _steps.length - 1 ? 'FINALIZAR' : 'SIGUIENTE',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _nextPage() async {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    } else {
      // Finalizar - Fix de navegación
      try {
         await ref.read(onboardingControllerProvider.notifier).submit();
         if (mounted) {
           context.go('/dashboard');
         }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error guardando datos: $e'), backgroundColor: Colors.red),
           );
        }
      }
    }
  }
}
