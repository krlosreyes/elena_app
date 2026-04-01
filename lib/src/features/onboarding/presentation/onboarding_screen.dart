import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/blueprint_grid.dart';
import '../../../core/widgets/technical_wheel_picker.dart';
import '../../../domain/logic/elena_brain.dart';
import '../../../shared/domain/models/user_food_preferences.dart';
import '../../authentication/application/auth_controller.dart';
import '../../nutrition/application/food_service.dart' as food_service;
import '../../nutrition/domain/entities/food_model.dart';
import '../application/onboarding_controller.dart';
import 'widgets/searchable_food_dropdown.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initOnboarding();
    });
  }

  void _initOnboarding() {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user != null) {
      ref
          .read(onboardingControllerProvider.notifier)
          .init(user.uid, user.email ?? '', user.displayName ?? '');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = ref.read(onboardingFoodPreferencesProvider);
      debugPrint(
        'UI: Iniciando submit. Prefs detectadas: Proteins=${prefs.proteins.length}, Fats=${prefs.fats.length}, Veggies=${prefs.vegetables.length}, Carbs=${prefs.carbs.length}',
      );
      debugPrint('UI: IDs Proteínas: ${prefs.proteins}');
      debugPrint('UI: IDs Grasas: ${prefs.fats}');
      debugPrint('UI: IDs Vegetales: ${prefs.vegetables}');
      debugPrint('UI: IDs Carbohidratos: ${prefs.carbs}');

      await ref.read(onboardingControllerProvider.notifier).submit(prefs);

      if (mounted) {
        debugPrint('UI: Onboarding finalizado con éxito. Navegando a /');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando el protocolo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlueprintGrid(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Simplified Top Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentStep > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white54,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      _currentStep == 0
                          ? 'BIOMETRÍA'
                          : _currentStep == 1
                          ? 'SINCRONIZACIÓN'
                          : _currentStep == 2
                          ? 'BIOTIPOLOGÍA'
                          : 'PREFERENCIAS',
                      style: GoogleFonts.orbitron(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: const [
                    BiologicalDataStep(),
                    HabitsAndLifestyleStep(),
                    GoalsAndPreferencesStep(),
                    NutritionPreferencesStep(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isPast = index < _currentStep;
          final isActive = index == _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 3,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary
                    : (isPast
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'SYS_INPUT: ${_currentStep == 0
                      ? "BIOMETRICS"
                      : _currentStep == 1
                      ? "CIRCADIAN_SYNC"
                      : _currentStep == 2
                      ? "METABOLIC_STATUS"
                      : "FOOD_PREFS"}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.primary.withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'VERIFICADO POR BIO-ENGINE',
                style: GoogleFonts.robotoMono(
                  color: Colors.white24,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSubmitting
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : AppTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 8,
                shadowColor: AppTheme.primary.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _currentStep < 3
                        ? 'CONTINUAR PROTOCOLO'
                        : 'FINALIZAR PROTOCOLO',
                    style: GoogleFonts.publicSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BiologicalDataStep extends ConsumerStatefulWidget {
  const BiologicalDataStep({super.key});

  @override
  ConsumerState<BiologicalDataStep> createState() => _BiologicalDataStepState();
}

mixin OnboardingUIHelpers<T extends StatefulWidget> on State<T> {
  Widget buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.robotoMono(
        color: const Color(0xFF94A3B8), // Steel Gray
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.transparent
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              color: isSelected ? AppTheme.primary : Colors.white24,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBigInput({
    required String placeholder,
    required String value,
    required VoidCallback onTap,
    IconData? suffixIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  value.isEmpty || value == '0' ? placeholder : value,
                  style: GoogleFonts.robotoMono(
                    color: value.isEmpty || value == '0'
                        ? Colors.white12
                        : Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            if (suffixIcon != null)
              Icon(suffixIcon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget buildHelperText(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.publicSans(
            color: Colors.white24,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void showNumericDialog(
    String title,
    double currentValue,
    Function(double) onSave, {
    double min = 30,
    double max = 300,
    double step = 1,
    String unit = 'cm',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TechnicalWheelPicker(
        title: title,
        initialValue: currentValue,
        min: min,
        max: max,
        step: step,
        unit: unit,
        onValueSelected: onSave,
      ),
    );
  }
}

class _BiologicalDataStepState extends ConsumerState<BiologicalDataStep>
    with OnboardingUIHelpers {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'OPT_CORE: BIOMETRY_PROTOCOL',
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RECOPISTANDO PARÁMETROS ANTROPOMÉTRICOS BASE',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white10,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 1. SEXO BIOLÓGICO
          buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel('1. SEXO BIOLÓGICO'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildOption(
                        label: 'M (Masculino)',
                        isSelected: user.gender == Gender.male,
                        onTap: () =>
                            _updateUser(user.copyWith(gender: Gender.male)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: buildOption(
                        label: 'F (Femenino)',
                        isSelected: user.gender == Gender.female,
                        onTap: () =>
                            _updateUser(user.copyWith(gender: Gender.female)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildHelperText('Fundamental para tasas metabólicas'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. FECHA DE NACIMIENTO
          buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel('2. FECHA DE NACIMIENTO'),
                const SizedBox(height: 16),
                buildBigInput(
                  placeholder: 'mm/dd/yyyy',
                  value: (user.birthDate == null)
                      ? ''
                      : _formatDate(user.birthDate!),
                  onTap: () => _showDatePicker(
                    context,
                    user.birthDate ?? DateTime(2000),
                  ),
                  suffixIcon: Icons.calendar_today,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 & 4 Grid
          Row(
            children: [
              Expanded(
                child: buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabel('3. ESTATURA (CM)'),
                      const SizedBox(height: 16),
                      buildBigInput(
                        placeholder: '170',
                        value: user.heightCm > 0
                            ? user.heightCm.toInt().toString()
                            : '',
                        onTap: () => showNumericDialog(
                          'Estatura',
                          user.heightCm > 0 ? user.heightCm : 170,
                          (v) => _updateUser(user.copyWith(heightCm: v)),
                          min: 100,
                          max: 250,
                          unit: 'cm',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabel('4. PESO INICIAL (KG)'),
                      const SizedBox(height: 16),
                      buildBigInput(
                        placeholder: '70',
                        value: user.currentWeightKg > 0
                            ? user.currentWeightKg.toStringAsFixed(1)
                            : '',
                        onTap: () => showNumericDialog(
                          'Peso Actual',
                          user.currentWeightKg > 0 ? user.currentWeightKg : 70,
                          (v) => _updateUser(user.copyWith(currentWeightKg: v)),
                          min: 30,
                          max: 250,
                          step: 0.1,
                          unit: 'kg',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5 & 6 Grid
          Row(
            children: [
              Expanded(
                child: buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabel('5. P. CINTURA (CM)'),
                      const SizedBox(height: 16),
                      buildBigInput(
                        placeholder: '85',
                        value: user.waistCircumferenceCm != null
                            ? user.waistCircumferenceCm!.toInt().toString()
                            : '',
                        onTap: () => showNumericDialog(
                          'Cintura',
                          user.waistCircumferenceCm ?? 85,
                          (v) => _updateUser(
                            user.copyWith(waistCircumferenceCm: v),
                          ),
                          min: 40,
                          max: 200,
                          unit: 'cm',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabel('6. P. CUELLO (CM)'),
                      const SizedBox(height: 16),
                      buildBigInput(
                        placeholder: '38',
                        value: user.neckCircumferenceCm != null
                            ? user.neckCircumferenceCm!.toInt().toString()
                            : '',
                        onTap: () => showNumericDialog(
                          'Cuello',
                          user.neckCircumferenceCm ?? 38,
                          (v) => _updateUser(
                            user.copyWith(neckCircumferenceCm: v),
                          ),
                          min: 20,
                          max: 70,
                          unit: 'cm',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7. P. Cadera
          buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel('7. P. CADERA (CM)'),
                const SizedBox(height: 16),
                buildBigInput(
                  placeholder: '100',
                  value: user.hipCircumferenceCm != null
                      ? user.hipCircumferenceCm!.toInt().toString()
                      : '',
                  onTap: () => showNumericDialog(
                    'Cadera',
                    user.hipCircumferenceCm ?? 100,
                    (v) => _updateUser(user.copyWith(hipCircumferenceCm: v)),
                    min: 50,
                    max: 200,
                    unit: 'cm',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'LOG_EVENT: BIOMETRIC_INITIALIZATION_COMPLETE',
              style: GoogleFonts.robotoMono(
                color: Colors.white10,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  void _updateUser(UserModel newUser) {
    ref.read(onboardingControllerProvider.notifier).updateUser(newUser);
  }

  String _formatDate(DateTime date) {
    return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: Color(0xFF161616),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final current = ref.read(onboardingControllerProvider);
      if (current != null) {
        _updateUser(current.copyWith(birthDate: picked));
      }
    }
  }
}

class HabitsAndLifestyleStep extends ConsumerStatefulWidget {
  const HabitsAndLifestyleStep({super.key});

  @override
  ConsumerState<HabitsAndLifestyleStep> createState() =>
      _HabitsAndLifestyleStepState();
}

class _HabitsAndLifestyleStepState
    extends ConsumerState<HabitsAndLifestyleStep> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const SizedBox();

    void updateUser(UserModel newUser) {
      ref.read(onboardingControllerProvider.notifier).updateUser(newUser);
    }

    Future<void> pickTime(String currentVal, Function(String) onUpdate) async {
      TimeOfDay initialTime = TimeOfDay.now();
      try {
        final lower = currentVal.toLowerCase();
        final isPM = lower.contains('pm');
        final cleaned = currentVal.replaceAll(RegExp(r'[^0-9:]'), '');
        final parts = cleaned.split(':');
        if (parts.length == 2) {
          int h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          if (isPM && h < 12) h += 12;
          if (!isPM && h == 12) h = 0;
          initialTime = TimeOfDay(hour: h, minute: m);
        }
      } catch (_) {}

      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: Color(0xFF161616),
            ),
          ),
          child: child!,
        ),
      );

      if (picked != null && mounted) {
        String pd = picked.period == DayPeriod.am ? 'AM' : 'PM';
        int h = picked.hourOfPeriod;
        if (h == 0) h = 12;
        final formatted =
            '${h.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $pd';
        onUpdate(formatted);
      }
    }

    double calculateSleepHours(String? bed, String? wake) {
      return ElenaBrain.calculateSleepHours(bed, wake);
    }

    Widget sectionTitle(IconData icon, String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    Widget inputColumn(String label, String? value, VoidCallback onTap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.publicSans(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                value ?? '--:--',
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Sincronizacion Circadiana Header (REFINED)
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'OPT_CORE: CIRCADIAN_SYNC',
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ESTABLECIENDO RITMOS BIOLÓGICOS Y VENTANA METABÓLICA',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white10,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // INICIO/FIN DE JORNADA
          sectionTitle(Icons.schedule, 'INICIO/FIN DE JORNADA'),
          Row(
            children: [
              Expanded(
                child: inputColumn(
                  'DESPERTAR',
                  user.wakeUpTime,
                  () => pickTime(user.wakeUpTime ?? '06:00 AM', (v) {
                    final newSleep = calculateSleepHours(user.bedTime, v);
                    updateUser(
                      user.copyWith(wakeUpTime: v, averageSleepHours: newSleep),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: inputColumn(
                  'DESCANSO',
                  user.bedTime,
                  () => pickTime(user.bedTime ?? '10:00 PM', (v) {
                    final newSleep = calculateSleepHours(v, user.wakeUpTime);
                    updateUser(
                      user.copyWith(bedTime: v, averageSleepHours: newSleep),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // HORAS DE DESCANSO
          sectionTitle(Icons.nightlight_round, 'HORAS DE DESCANSO'),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Media de sueño diaria',
                  style: GoogleFonts.publicSans(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      (user.averageSleepHours ??
                              calculateSleepHours(
                                user.bedTime,
                                user.wakeUpTime,
                              ))
                          .toStringAsFixed(1),
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HRS',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // VENTANA DE ALIMENTACIÓN
          sectionTitle(Icons.restaurant, 'VENTANA DE ALIMENTACIÓN'),
          Row(
            children: [
              Expanded(
                child: inputColumn(
                  'PRIMERA INGESTA',
                  user.usualFirstMealTime,
                  () => pickTime(
                    user.usualFirstMealTime ?? '07:00 AM',
                    (v) => updateUser(user.copyWith(usualFirstMealTime: v)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: inputColumn(
                  'ÚLTIMA INGESTA',
                  user.usualLastMealTime,
                  () => pickTime(
                    user.usualLastMealTime ?? '08:00 PM',
                    (v) => updateUser(user.copyWith(usualLastMealTime: v)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FRECUENCIA DE PICOTEO
          sectionTitle(Icons.fastfood, 'FRECUENCIA DE PICOTEO'),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF161616),
                builder: (c) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text(
                          'Nunca',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          updateUser(
                            user.copyWith(snackingHabit: SnackingHabit.never),
                          );
                          Navigator.pop(c);
                        },
                      ),
                      ListTile(
                        title: const Text(
                          'Ocasionalmente',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          updateUser(
                            user.copyWith(
                              snackingHabit: SnackingHabit.sometimes,
                            ),
                          );
                          Navigator.pop(c);
                        },
                      ),
                      ListTile(
                        title: const Text(
                          'Frecuente',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          updateUser(
                            user.copyWith(
                              snackingHabit: SnackingHabit.frequent,
                            ),
                          );
                          Navigator.pop(c);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    user.snackingHabit == SnackingHabit.never
                        ? 'Nunca'
                        : user.snackingHabit == SnackingHabit.sometimes
                        ? 'Ocasionalmente'
                        : 'Frecuente',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // NIVEL DE ACTIVIDAD
          sectionTitle(Icons.fitness_center, 'NIVEL DE ACTIVIDAD'),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF161616),
                builder: (c) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text(
                          'Sedentario (Poca actividad)',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          updateUser(
                            user.copyWith(
                              activityLevel: ActivityLevel.sedentary,
                            ),
                          );
                          Navigator.pop(c);
                        },
                      ),
                      ListTile(
                        title: const Text(
                          'Ligero (1-3 días/semana)',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          updateUser(
                            user.copyWith(activityLevel: ActivityLevel.light),
                          );
                          Navigator.pop(c);
                        },
                      ),
                      ListTile(
                        title: const Text(
                          'Moderado (3-5 días/semana)',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          updateUser(
                            user.copyWith(
                              activityLevel: ActivityLevel.moderate,
                            ),
                          );
                          Navigator.pop(c);
                        },
                      ),
                      ListTile(
                        title: const Text(
                          'Intenso (Atleta)',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          updateUser(
                            user.copyWith(activityLevel: ActivityLevel.heavy),
                          );
                          Navigator.pop(c);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    user.activityLevel == ActivityLevel.sedentary
                        ? 'Sedentario'
                        : user.activityLevel == ActivityLevel.light
                        ? 'Ligero'
                        : user.activityLevel == ActivityLevel.moderate
                        ? 'Moderado'
                        : 'Intenso',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              'LOG_EVENT: CIRCADIAN_PARAMETERS_SET',
              style: GoogleFonts.robotoMono(
                color: Colors.white10,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class GoalsAndPreferencesStep extends ConsumerStatefulWidget {
  const GoalsAndPreferencesStep({super.key});

  @override
  ConsumerState<GoalsAndPreferencesStep> createState() =>
      _GoalsAndPreferencesStepState();
}

class _GoalsAndPreferencesStepState
    extends ConsumerState<GoalsAndPreferencesStep>
    with OnboardingUIHelpers {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const SizedBox();

    void updateUser(UserModel newUser) {
      ref.read(onboardingControllerProvider.notifier).updateUser(newUser);
    }

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: GoogleFonts.robotoMono(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    Widget buildChip(
      String label,
      bool isSelected, {
      VoidCallback? onTap,
      bool isAdd = false,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isAdd ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isAdd
                ? Colors.transparent
                : (isSelected
                      ? AppTheme.primary.withValues(alpha: 0.2)
                      : const Color(0xFF12151C)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isAdd
                  ? Colors.white24
                  : (isSelected ? AppTheme.primary : const Color(0xFF1E2432)),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.publicSans(
              color: isSelected
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    Widget buildSegmentButton(
      String label,
      bool isSelected,
      VoidCallback onTap,
    ) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFF12151C),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFF1E2432),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              color: isSelected ? Colors.black : const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    void togglePathology(String slug) {
      List<String> current = List.from(user.pathologies);

      if (slug == 'none') {
        current = ['none'];
      } else {
        current.remove('none');
        if (current.contains(slug)) {
          current.remove(slug);
        } else {
          current.add(slug);
        }
      }
      updateUser(user.copyWith(pathologies: current));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'SYS_CORE: METABOLIC_PROFILE',
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'INICIALIZANDO ESCANEO DE BIOTIPOLOGÍA Y PREFERENCIAS',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white10,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          sectionTitle('¿PADECES ALGUNA DE ESTAS PATOLOGÍAS?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              buildChip(
                'Síndrome Metabólico',
                user.pathologies.contains('metabolicSyndrome'),
                onTap: () => togglePathology('metabolicSyndrome'),
              ),
              buildChip(
                'Diabetes Tipo 2',
                user.pathologies.contains('diabetes'),
                onTap: () => togglePathology('diabetes'),
              ),
              buildChip(
                'Prediabetes',
                user.pathologies.contains('prediabetes'),
                onTap: () => togglePathology('prediabetes'),
              ),
              buildChip(
                'Hipertensión',
                user.pathologies.contains('hypertension'),
                onTap: () => togglePathology('hypertension'),
              ),
              buildChip(
                'Anemia',
                user.pathologies.contains('anemia'),
                onTap: () => togglePathology('anemia'),
              ),
              buildChip(
                'Ninguna',
                user.pathologies.contains('none'),
                onTap: () => togglePathology('none'),
              ),
              buildChip('+', false, isAdd: true),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              sectionTitle('NIVEL DE VITALIDAD PERCIBIDA'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (user.energyLevel1To10 ?? 7).toString().padLeft(2, '0'),
                    style: GoogleFonts.robotoMono(
                      color: AppTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3.0, left: 2),
                    child: Text(
                      '/10',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: const Color(0xFF161616),
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: (user.energyLevel1To10 ?? 7).toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                updateUser(user.copyWith(energyLevel1To10: val.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MIN',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white24,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'MAX',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white24,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          sectionTitle('EXPERIENCIA EN AYUNO'),
          Row(
            children: [
              Expanded(
                child: buildSegmentButton(
                  'PRINCIPIANTE',
                  user.fastingExperience == FastingExperience.beginner,
                  () => updateUser(
                    user.copyWith(
                      fastingExperience: FastingExperience.beginner,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSegmentButton(
                  'INTERMEDIO',
                  user.fastingExperience == FastingExperience.intermediate,
                  () => updateUser(
                    user.copyWith(
                      fastingExperience: FastingExperience.intermediate,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSegmentButton(
                  'PRO',
                  user.fastingExperience == FastingExperience.advanced,
                  () => updateUser(
                    user.copyWith(
                      fastingExperience: FastingExperience.advanced,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '[Consejo] Declarar el\n"Síndrome Metabólico" activa protocolos\nde restricción de fructosa y control\nde carga glucémica estricto en las\nrecomendaciones diarias.',
                    style: GoogleFonts.robotoMono(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              'LOG_EVENT: METABOLIC_BASELINE_ESTABLISHED',
              style: GoogleFonts.robotoMono(
                color: Colors.white10,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class NutritionPreferencesStep extends ConsumerStatefulWidget {
  const NutritionPreferencesStep({super.key});

  @override
  ConsumerState<NutritionPreferencesStep> createState() =>
      _NutritionPreferencesStepState();
}

class _NutritionPreferencesStepState
    extends ConsumerState<NutritionPreferencesStep>
    with OnboardingUIHelpers {
  late final Map<String, List<FoodModel>> _categorizedFoods;
  bool _foodsLoaded = false;

  @override
  void initState() {
    super.initState();
    _categorizedFoods = {};
    _loadMasterFoods();
  }

  void _loadMasterFoods() async {
    try {
      debugPrint('[ONBOARDING DEBUG] 🔄 Starting _loadMasterFoods()...');

      // Fetch all foods from master_food_db and group by category
      final foodService = ref.read(food_service.foodServiceProvider);

      debugPrint('[ONBOARDING DEBUG] 📡 Querying master_food_db...');

      // Fetch each category using plain-text categories (no emojis in queries)
      // FoodService handles the mapping internally
      // Query for protein categories - use plain-text 'Proteinas'
      final proteinsFish = await foodService.getFoodsByCategory('Proteinas');
      final proteinBeef = await foodService.getFoodsByCategory('Proteinas');
      final proteinPoultry = await foodService.getFoodsByCategory(
        'Proteinas',
      );
      final proteinsData = [...proteinsFish, ...proteinBeef, ...proteinPoultry];

      // Query for fat categories - use plain-text 'Grasas'
      final fatsAvocado = await foodService.getFoodsByCategory('Grasas');
      final fatsOil = await foodService.getFoodsByCategory('Grasas');
      final fatsNuts = await foodService.getFoodsByCategory('Grasas');
      final fatsMCT = await foodService.getFoodsByCategory('Grasas');
      final fatsData = [...fatsAvocado, ...fatsOil, ...fatsNuts, ...fatsMCT];

      // Query for vegetable categories - use plain-text 'Vegetales'
      final vegGreens = await foodService.getFoodsByCategory('Vegetales');
      final vegCrucif = await foodService.getFoodsByCategory('Vegetales');
      final vegPeppers = await foodService.getFoodsByCategory('Vegetales');
      final vegMushrooms = await foodService.getFoodsByCategory('Vegetales');
      final vegData = [
        ...vegGreens,
        ...vegCrucif,
        ...vegPeppers,
        ...vegMushrooms,
      ];

      // Query for carb categories - use plain-text 'Carbohidratos'
      final carbRice = await foodService.getFoodsByCategory('Carbohidratos');
      final carbPotatoes = await foodService.getFoodsByCategory(
        'Carbohidratos',
      );
      final carbCorn = await foodService.getFoodsByCategory('Carbohidratos');
      final carbSweet = await foodService.getFoodsByCategory(
        'Carbohidratos',
      );
      final carbFruit = await foodService.getFoodsByCategory(
        'Carbohidratos',
      );
      final carbsData = [
        ...carbRice,
        ...carbPotatoes,
        ...carbCorn,
        ...carbSweet,
        ...carbFruit,
      ];

      debugPrint(
        '[ONBOARDING DEBUG] ✅ Firestore query results: proteins=${proteinsData.length}, fats=${fatsData.length}, vegetables=${vegData.length}, carbs=${carbsData.length}',
      );

      // CHECK IF DATABASE IS EMPTY (SELF-HEALING SEEDING)
      if (proteinsData.isEmpty &&
          fatsData.isEmpty &&
          vegData.isEmpty &&
          carbsData.isEmpty) {
        debugPrint(
          '[ONBOARDING DEBUG] 🚨 Empty DB detected in Firestore. Attempting self-healing seed...',
        );

        try {
          // Attempt to seed from local dataset
          // TODO: Seed is handled by FoodRepository initialization
          // await foodRepository.seedInitialNutritionData();

          // Wait a second for persistence to settle if needed, then re-query
          await Future.delayed(const Duration(milliseconds: 800));

          // Re-query with plain-text categories (no emojis)
          final newProteinsFish = await foodService.getFoodsByCategory(
            'Proteinas',
          );
          final newProteinBeef = await foodService.getFoodsByCategory(
            'Proteinas',
          );
          final newProteinPoultry = await foodService.getFoodsByCategory(
            'Proteinas',
          );
          final newProteins = [
            ...newProteinsFish,
            ...newProteinBeef,
            ...newProteinPoultry,
          ];

          final newFatsAvocado = await foodService.getFoodsByCategory(
            'Grasas',
          );
          final newFatsOil = await foodService.getFoodsByCategory('Grasas');
          final newFatsNuts = await foodService.getFoodsByCategory('Grasas');
          final newFatsMCT = await foodService.getFoodsByCategory('Grasas');
          final newFats = [
            ...newFatsAvocado,
            ...newFatsOil,
            ...newFatsNuts,
            ...newFatsMCT,
          ];

          final newVegGreens = await foodService.getFoodsByCategory(
            'Vegetales',
          );
          final newVegCrucif = await foodService.getFoodsByCategory(
            'Vegetales',
          );
          final newVegPeppers = await foodService.getFoodsByCategory(
            'Vegetales',
          );
          final newVegMushrooms = await foodService.getFoodsByCategory(
            'Vegetales',
          );
          final newVegetables = [
            ...newVegGreens,
            ...newVegCrucif,
            ...newVegPeppers,
            ...newVegMushrooms,
          ];

          final newCarbRice = await foodService.getFoodsByCategory(
            'Carbohidratos',
          );
          final newCarbPotatoes = await foodService.getFoodsByCategory(
            'Carbohidratos',
          );
          final newCarbCorn = await foodService.getFoodsByCategory(
            'Carbohidratos',
          );
          final newCarbSweet = await foodService.getFoodsByCategory(
            'Carbohidratos',
          );
          final newCarbFruit = await foodService.getFoodsByCategory(
            'Carbohidratos',
          );
          final newCarbs = [
            ...newCarbRice,
            ...newCarbPotatoes,
            ...newCarbCorn,
            ...newCarbSweet,
            ...newCarbFruit,
          ];

          if (newProteins.isNotEmpty ||
              newFats.isNotEmpty ||
              newVegetables.isNotEmpty ||
              newCarbs.isNotEmpty) {
            debugPrint(
              '[ONBOARDING DEBUG] ✅ Self-healing success. Data found.',
            );
            setState(() {
              // ✅ DEDUPLICATION: Remove duplicate food IDs at UI layer
              _categorizedFoods['protein'] = _deduplicateFoods(newProteins);
              _categorizedFoods['fat'] = _deduplicateFoods(newFats);
              _categorizedFoods['vegetable'] = _deduplicateFoods(newVegetables);
              _categorizedFoods['carb'] = _deduplicateFoods(newCarbs);
              _foodsLoaded = true;
            });
            return;
          }
        } catch (seedError) {
          debugPrint(
            '[ONBOARDING DEBUG] ❌ Self-healing seed failed: $seedError',
          );
        }

        // LAST RESORT FALLBACK
        debugPrint(
          '[ONBOARDING DEBUG] 🚨 ALL FIREBASE ROUTES FAILED. Using HARDCODED LOCAL SEEDS.',
        );
        final fallbackFoods = _getHardcodedSeeds();
        setState(() {
          _categorizedFoods['protein'] = _deduplicateFoods(
            fallbackFoods
                .where(
                  (f) =>
                      f.category.toLowerCase().contains('proteina') ||
                      f.category.toLowerCase().contains('protein'),
                )
                .toList(),
          );
          _categorizedFoods['fat'] = _deduplicateFoods(
            fallbackFoods
                .where(
                  (f) =>
                      f.category.toLowerCase().contains('grasa') ||
                      f.category.toLowerCase().contains('fat'),
                )
                .toList(),
          );
          _categorizedFoods['carb'] = _deduplicateFoods(
            fallbackFoods
                .where(
                  (f) =>
                      f.category.toLowerCase().contains('carbs') ||
                      f.category.toLowerCase().contains('carb'),
                )
                .toList(),
          );
          _foodsLoaded = true;
        });
      } else {
        // Use Firestore data
        setState(() {
          // ✅ DEDUPLICATION: Remove duplicate food IDs at UI layer
          _categorizedFoods['protein'] = _deduplicateFoods(proteinsData);
          _categorizedFoods['fat'] = _deduplicateFoods(fatsData);
          _categorizedFoods['vegetable'] = _deduplicateFoods(vegData);
          _categorizedFoods['carb'] = _deduplicateFoods(carbsData);
          _foodsLoaded = true;
        });

        debugPrint(
          '[ONBOARDING DEBUG] ✅ Foods loaded from Firestore: ${proteinsData.length} proteins, ${fatsData.length} fats, ${vegData.length} vegetables, ${carbsData.length} carbs',
        );
      }
    } catch (e) {
      debugPrint('[ONBOARDING DEBUG] ❌ Error loading master foods: $e');
      debugPrint('[ERROR] Exception in _loadMasterFoods: $e');

      // FALLBACK TO HARDCODED SEEDS ON ERROR
      debugPrint(
        '[ONBOARDING DEBUG] 🚨 ERROR FALLBACK: Using hardcoded seeds due to exception.',
      );
      final fallbackFoods = _getHardcodedSeeds();
      setState(() {
        _categorizedFoods['protein'] = _deduplicateFoods(
          fallbackFoods
              .where(
                (f) =>
                    f.category.toLowerCase().contains('proteina') ||
                    f.category.toLowerCase().contains('protein') ||
                    f.name.contains('Pollo') ||
                    f.name.contains('Huevo') ||
                    f.name.contains('Carne') ||
                    f.name.contains('Salmón'),
              )
              .toList(),
        );
        _categorizedFoods['fat'] = _deduplicateFoods(
          fallbackFoods
              .where(
                (f) =>
                    f.category.toLowerCase().contains('grasa') ||
                    f.category.toLowerCase().contains('fat') ||
                    f.name.contains('Aguacate') ||
                    f.name.contains('Aceite') ||
                    f.name.contains('Nueces'),
              )
              .toList(),
        );
        _categorizedFoods['vegetable'] = _deduplicateFoods(
          fallbackFoods
              .where(
                (f) =>
                    f.category.toLowerCase().contains('vegetal') ||
                    f.category.toLowerCase().contains('veg') ||
                    f.name.contains('Brócoli') ||
                    f.name.contains('Espinaca'),
              )
              .toList(),
        );
        _categorizedFoods['carb'] = _deduplicateFoods(
          fallbackFoods
              .where(
                (f) =>
                    f.category.toLowerCase().contains('carbs') ||
                    f.category.toLowerCase().contains('carb') ||
                    f.name.contains('Arroz') ||
                    f.name.contains('Batata') ||
                    f.name.contains('Pan'),
              )
              .toList(),
        );
        _foodsLoaded = true;
      });
    }
  }

  /// Get hardcoded seed foods for fallback
  List<FoodModel> _getHardcodedSeeds() {
    // Curated slice of FoodMasterList for last-resort recovery
    return [
      FoodModel(
        id: 'hc-pollo',
        name: 'Pechuga de Pollo',
        nameLowercase: 'pechuga de pollo',
        category: 'Proteína 🥩',
        protein: 31.0,
        fat: 3.6,
        netCarbs: 0.0,
        calories: 165.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Proteína magra de alta biodisponibilidad.',
        impact: 'sarcopenia',
        level: 3,
        searchTags: ['pollo', 'proteina'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-huevo',
        name: 'Huevo Entero',
        nameLowercase: 'huevo entero',
        category: 'Proteína 🥩',
        protein: 13.0,
        fat: 11.0,
        netCarbs: 1.1,
        calories: 155.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Mejor perfil de aminoácidos + colina.',
        impact: 'sarcopenia',
        level: 3,
        searchTags: ['huevo', 'proteina'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-salmon',
        name: 'Salmón Salvaje',
        nameLowercase: 'salmón salvaje',
        category: 'Proteína 🐟',
        protein: 20.0,
        fat: 13.0,
        netCarbs: 0.0,
        calories: 208.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Alto en Omega-3 antiinflamatorio.',
        impact: 'sarcopenia',
        level: 3,
        searchTags: ['salmon', 'omega3'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-aguacate',
        name: 'Aguacate Hass',
        nameLowercase: 'aguacate hass',
        category: 'Grasas 🥑',
        protein: 2.0,
        fat: 15.0,
        netCarbs: 1.8,
        calories: 160.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Grasa monoinsaturada cardiosaludable.',
        impact: 'energía',
        level: 1,
        searchTags: ['aguacate', 'grasas'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-aceite-oliva',
        name: 'Aceite de Oliva EV',
        nameLowercase: 'aceite de oliva ev',
        category: 'Grasas 🫒',
        protein: 0.0,
        fat: 100.0,
        netCarbs: 0.0,
        calories: 884.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Polifenoles potentes y grasas puras.',
        impact: 'inflamación',
        level: 1,
        searchTags: ['aceite', 'oliva'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-nueces',
        name: 'Nueces de Nogal',
        nameLowercase: 'nueces de nogal',
        category: 'Grasas 🥜',
        protein: 15.2,
        fat: 65.2,
        netCarbs: 7.0,
        calories: 654.0,
        serving: 100.0,
        imrScore: 9,
        tip: 'Apoyo cognitivo y grasas poliinsaturadas.',
        impact: 'energía',
        level: 2,
        searchTags: ['nueces', 'grasas'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-arroz',
        name: 'Arroz Integral',
        nameLowercase: 'arroz integral',
        category: 'Carbohidratos 🍚',
        protein: 2.6,
        fat: 0.9,
        netCarbs: 23.0,
        calories: 111.0,
        serving: 100.0,
        imrScore: 8,
        tip: 'Energía de liberación lenta.',
        impact: 'energía',
        level: 2,
        searchTags: ['arroz', 'carbs'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-batata',
        name: 'Batata / Camote',
        nameLowercase: 'batata / camote',
        category: 'Carbohidratos 🥔',
        protein: 1.6,
        fat: 0.1,
        netCarbs: 17.0,
        calories: 86.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Carbohidrato complejo rico en Vitamina A.',
        impact: 'energía',
        level: 1,
        searchTags: ['batata', 'carbs'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-brocoli',
        name: 'Brócoli',
        nameLowercase: 'brócoli',
        category: 'Vegetales 🥦',
        protein: 2.8,
        fat: 0.4,
        netCarbs: 4.0,
        calories: 34.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Superalimento crucífero desintoxicante.',
        impact: 'hormonal',
        level: 3,
        searchTags: ['brocoli', 'vegetales'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodModel(
        id: 'hc-espinaca',
        name: 'Espinaca',
        nameLowercase: 'espinaca',
        category: 'Vegetales 🥬',
        protein: 2.9,
        fat: 0.4,
        netCarbs: 1.4,
        calories: 23.0,
        serving: 100.0,
        imrScore: 10,
        tip: 'Densidad nutricional y nitratos naturales.',
        impact: 'inflamación',
        level: 3,
        searchTags: ['espinaca', 'vegetales'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(onboardingFoodPreferencesProvider);
    final proteinCount = prefs.proteins.length;
    final fatCount = prefs.fats.length;
    final carbCount = prefs.carbs.length;
    final isValid =
        proteinCount > 0 && fatCount > 0 && carbCount > 0; // At least 1 of each

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'SYS_CORE: NUTRITION_OPTIMIZER',
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SELECCIONA TUS ALIMENTOS PREFERIDOS',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white10,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (!_foodsLoaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            // PROTEÍNAS DROPDOWN
            SearchableFoodDropdown(
              title: 'Fuentes de Proteína',
              emoji: '🥩',
              foods: _categorizedFoods['protein'] ?? [],
              selectedIds: prefs.proteins,
              onFoodSelected: (food) {
                _toggleFoodSelection(
                  food,
                  'protein',
                  ref: ref,
                  context: context,
                );
              },
            ),
            const SizedBox(height: 12),
            if (prefs.proteins.isNotEmpty)
              _buildSelectedChips(
                selectedFoodIds: prefs.proteins,
                allFoods: _categorizedFoods['protein'] ?? [],
                category: 'protein',
              ),
            const SizedBox(height: 24),

            // GRASAS DROPDOWN
            SearchableFoodDropdown(
              title: 'Grasas Saludables',
              emoji: '🧈',
              foods: _categorizedFoods['fat'] ?? [],
              selectedIds: prefs.fats,
              onFoodSelected: (food) {
                _toggleFoodSelection(food, 'fat', ref: ref, context: context);
              },
            ),
            const SizedBox(height: 12),
            if (prefs.fats.isNotEmpty)
              _buildSelectedChips(
                selectedFoodIds: prefs.fats,
                allFoods: _categorizedFoods['fat'] ?? [],
                category: 'fat',
              ),
            const SizedBox(height: 24),

            // VEGETALES DROPDOWN
            SearchableFoodDropdown(
              title: 'Vegetales & Especias',
              emoji: '🥦',
              foods: _categorizedFoods['vegetable'] ?? [],
              selectedIds: prefs.vegetables,
              onFoodSelected: (food) {
                _toggleFoodSelection(
                  food,
                  'vegetable',
                  ref: ref,
                  context: context,
                );
              },
            ),
            const SizedBox(height: 12),
            if (prefs.vegetables.isNotEmpty)
              _buildSelectedChips(
                selectedFoodIds: prefs.vegetables,
                allFoods: _categorizedFoods['vegetable'] ?? [],
                category: 'vegetable',
              ),
            const SizedBox(height: 24),

            // CARBOHIDRATOS DROPDOWN
            SearchableFoodDropdown(
              title: 'Carbohidratos Elegidos',
              emoji: '🌾',
              foods: _categorizedFoods['carb'] ?? [],
              selectedIds: prefs.carbs,
              onFoodSelected: (food) {
                _toggleFoodSelection(food, 'carb', ref: ref, context: context);
              },
            ),
            const SizedBox(height: 12),
            if (prefs.carbs.isNotEmpty)
              _buildSelectedChips(
                selectedFoodIds: prefs.carbs,
                allFoods: _categorizedFoods['carb'] ?? [],
                category: 'carb',
              ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flash_on, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '[Sync] Tus sugerencias de comidas se rotarán priorizando los elementos marcados en estas listas para máxima adherencia.',
                      style: GoogleFonts.robotoMono(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isValid)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecciona al menos 1 de cada categoría',
                        style: GoogleFonts.publicSans(
                          color: Colors.redAccent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 60),
          ],
        ],
      ),
    );
  }

  /// 🔄 DEDUPLICATION: Remove duplicate foods by ID
  /// Last occurrence wins if duplicates exist
  List<FoodModel> _deduplicateFoods(List<FoodModel> foods) {
    final seen = <String>{};
    final deduped = <FoodModel>[];
    for (final food in foods.reversed) {
      if (seen.add(food.id)) {
        deduped.add(food);
      }
    }
    return deduped.reversed.toList();
  }

  // Build selected food chips for display below dropdowns
  Widget _buildSelectedChips({
    required List<String> selectedFoodIds,
    required List<FoodModel> allFoods,
    required String category,
  }) {
    final selectedFoods = allFoods
        .where((food) => selectedFoodIds.contains(food.id))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: selectedFoods.map((food) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              border: Border.all(color: AppTheme.primary, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  food.name,
                  style: GoogleFonts.publicSans(
                    color: const Color(0xFFE0E0E0),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _toggleFoodSelection(
                    food,
                    category,
                    ref: ref,
                    context: context,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppTheme.primary,
                    size: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Toggle food selection with haptic feedback
  void _toggleFoodSelection(
    FoodModel food,
    String category, {
    required WidgetRef ref,
    required BuildContext context,
  }) {
    // Haptic feedback is already called in FilterChip.onSelected
    // This keeps the method for any additional logic needed

    final current = ref.read(onboardingFoodPreferencesProvider);
    List<String> items;

    switch (category) {
      case 'protein':
        items = current.proteins.toList();
        break;
      case 'fat':
        items = current.fats.toList();
        break;
      case 'vegetable':
        items = current.vegetables.toList();
        break;
      case 'carb':
        items = current.carbs.toList();
        break;
      default:
        items = [];
    }

    // Toggle: add if not present, remove if present
    if (items.contains(food.id)) {
      items.remove(food.id);
    } else {
      items.add(food.id);
    }

    // Update state
    late UserFoodPreferences newPrefs;
    switch (category) {
      case 'protein':
        newPrefs = current.copyWith(proteins: items);
        break;
      case 'fat':
        newPrefs = current.copyWith(fats: items);
        break;
      case 'vegetable':
        newPrefs = current.copyWith(vegetables: items);
        break;
      case 'carb':
        newPrefs = current.copyWith(carbs: items);
        break;
    }

    ref.read(onboardingFoodPreferencesProvider.notifier).state = newPrefs;

    // Feedback
    final action = items.contains(food.id) ? '✅ Agregado' : '❌ Removido';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: ${food.name}'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: items.contains(food.id)
            ? AppTheme.primary
            : Colors.white24,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
