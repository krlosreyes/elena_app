import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    } else {
      // Finalizar
      ref.read(onboardingControllerProvider.notifier).submit(context);
    }
  }

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
            color: const Color(0xFF009688), // Teal
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), // Blue
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _currentPage == _steps.length - 1 ? 'FINALIZAR' : 'SIGUIENTE',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
