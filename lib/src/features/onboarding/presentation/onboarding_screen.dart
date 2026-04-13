import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/onboarding/application/onboarding_controller.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // --- PASO 1: HARDWARE ---
  DateTime _birthDate = DateTime(1980, 1, 1);
  double _weight = 85.0;
  double _height = 180.0;
  String _gender = 'M';
  double _waist = 94.0; 
  double _neck = 40.0;  
  int _pantSize = 34;
  String _shirtSize = "L";

  // --- PASO 2: RITMOS ---
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _firstMealGoal = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lastMealGoal = const TimeOfDay(hour: 18, minute: 0);
  
  // --- PASO 3: PROTOCOLO ---
  int _mealsPerDay = 3;
  String _fastingProtocol = "Ninguno";
  List<String> _pathologies = ["Ninguna"];

  final List<String> _pathologyOptions = [
    "Ninguna", "Prediabetes", "Diabetes T2", "Hipertensión", 
    "Hígado Graso", "Hipotiroidismo", "SOP", "Anemia", "Resistencia Insulina"
  ];

  void _inferMedidas() {
    setState(() {
      double baseWaist = _pantSize * 2.54;
      _waist = _gender == 'M' ? baseWaist + 5.0 : baseWaist + 2.0;
      switch (_shirtSize) {
        case "S": _neck = 36.0; break;
        case "M": _neck = 39.0; break;
        case "L": _neck = 42.0; break;
        case "XL": _neck = 45.0; break;
        default: _neck = 40.0;
      }
    });
  }

  DateTime _timeToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  color: const Color(0xFF10B981),
                  minHeight: 6,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepBiometry(isDark),
                  _buildStepCircadian(isDark),
                  _buildStepHabits(isDark),
                ],
              ),
            ),
            _buildBottomNavigation(state, isDark),
          ],
        ),
      ),
    );
  }

  // --- PASO 1: BIOMETRÍA ---
  Widget _buildStepBiometry(bool isDark) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      _header("Hardware Base", "Identidad y Antropometría", isDark),
      _simpleSelector("Nacimiento", DateFormat('dd/MM/yyyy').format(_birthDate), () async {
        final date = await showDatePicker(context: context, initialDate: _birthDate, firstDate: DateTime(1940), lastDate: DateTime.now());
        if (date != null) setState(() => _birthDate = date);
      }, isDark),
      _simpleSelector("Sexo", _gender == 'M' ? "Masculino" : "Femenino", () => _showSimpleOptions("Sexo", ["Masculino", "Femenino"], (v) { setState(() => _gender = v == "Masculino" ? 'M' : 'F'); _inferMedidas(); }, isDark), isDark),
      _stepperSelector(label: "Estatura", value: _height, unit: " cm", min: 140, max: 220, onChanged: (v) => setState(() => _height = v), isDark: isDark),
      _stepperSelector(label: "Peso", value: _weight, unit: " kg", min: 40, max: 200, onChanged: (v) => setState(() => _weight = v), isDark: isDark),
      
      _sectionTitle("TALLAS (INFERENCIA)", isDark),
      Row(children: [
        Expanded(child: _simpleSelector("Camisa", _shirtSize, () => _showSimpleOptions("Camisa", ["S", "M", "L", "XL"], (v) { setState(() => _shirtSize = v); _inferMedidas(); }, isDark), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _stepperSelector(label: "Pant.", value: _pantSize.toDouble(), unit: "", min: 28, max: 50, onChanged: (v) { setState(() => _pantSize = v.toInt()); _inferMedidas(); }, isDark: isDark)),
      ]),

      _sectionTitle("MEDIDAS CRÍTICAS IMR", isDark),
      _stepperSelector(label: "Cintura", value: _waist, unit: " cm", min: 50, max: 150, onChanged: (v) => setState(() => _waist = v), isDark: isDark),
      _stepperSelector(label: "Cuello", value: _neck, unit: " cm", min: 20, max: 60, onChanged: (v) => setState(() => _neck = v), isDark: isDark),
    ],
  );

  // --- PASO 2: RITMOS ---
  Widget _buildStepCircadian(bool isDark) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      _header("Ritmo Circadiano", "Sincronización horaria", isDark),
      _simpleSelector("Despertar", _wakeUpTime.format(context), () async {
        final time = await showTimePicker(context: context, initialTime: _wakeUpTime);
        if (time != null) setState(() => _wakeUpTime = time);
      }, isDark),
      _simpleSelector("Dormir", _sleepTime.format(context), () async {
        final time = await showTimePicker(context: context, initialTime: _sleepTime);
        if (time != null) setState(() => _sleepTime = time);
      }, isDark),
      _sectionTitle("VENTANA DE ALIMENTACIÓN", isDark),
      _simpleSelector("Primera Comida", _firstMealGoal.format(context), () async {
        final time = await showTimePicker(context: context, initialTime: _firstMealGoal);
        if (time != null) setState(() => _firstMealGoal = time);
      }, isDark),
      _simpleSelector("Última Comida", _lastMealGoal.format(context), () async {
        final time = await showTimePicker(context: context, initialTime: _lastMealGoal);
        if (time != null) setState(() => _lastMealGoal = time);
      }, isDark),
    ],
  );

  // --- PASO 3: HÁBITOS ---
  Widget _buildStepHabits(bool isDark) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      _header("Protocolo", "Hábitos metabólicos", isDark),
      _stepperSelector(label: "Comidas al día", value: _mealsPerDay.toDouble(), unit: "", min: 1, max: 6, onChanged: (v) => setState(() => _mealsPerDay = v.toInt()), isDark: isDark),
      _simpleSelector("Ayuno", _fastingProtocol, () => _showSimpleOptions("Ayuno", ["Ninguno", "16:8", "18:6", "20:4"], (v) => setState(() => _fastingProtocol = v), isDark), isDark),
      _simpleSelector("Patologías", _pathologies.join(", "), () => _showMultiSelectPathologies(isDark), isDark),
    ],
  );

  void _finalSubmit() async {
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) return;

    final age = DateTime.now().year - _birthDate.year;

    // CORRECCIÓN: Ahora pasamos los nuevos campos al modelo Freezed
    final user = UserModel(
      id: authUser.id, 
      name: authUser.name, 
      age: age, 
      gender: _gender, 
      weight: _weight, 
      height: _height,
      waistCircumference: _waist, 
      neckCircumference: _neck, 
      pantSize: _pantSize, 
      shirtSize: _shirtSize,
      mealsPerDay: _mealsPerDay,      // <-- AGREGADO
      fastingProtocol: _fastingProtocol, // <-- AGREGADO
      pathologies: _pathologies,      // <-- AGREGADO
      profile: CircadianProfile(
        wakeUpTime: _timeToDateTime(_wakeUpTime),
        sleepTime: _timeToDateTime(_sleepTime),
        firstMealGoal: _timeToDateTime(_firstMealGoal),
        lastMealGoal: _timeToDateTime(_lastMealGoal),
      ),
    );

    try {
      await ref.read(onboardingControllerProvider.notifier).completeOnboarding(user);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      debugPrint("❌ Error en Onboarding Submit: $e");
    }
  }

  // --- HELPERS UI ---

  Widget _stepperSelector({required String label, required double value, required String unit, required double min, required double max, required Function(double) onChanged, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 14)),
        Row(children: [
          _circleButton(Icons.remove, () => value > min ? onChanged(value - 1) : null, isDark),
          SizedBox(width: 65, child: Center(child: Text("${value.toInt()}$unit", style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16)))),
          _circleButton(Icons.add, () => value < max ? onChanged(value + 1) : null, isDark),
        ])
      ]),
    );
  }

  Widget _simpleSelector(String label, String value, VoidCallback onTap, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 14)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981), fontSize: 15))]))),
  );

  Widget _circleButton(IconData icon, VoidCallback? onTap, bool isDark) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)), child: Icon(icon, size: 18, color: onTap == null ? Colors.grey : (isDark ? Colors.white : const Color(0xFF0F172A)))));

  Widget _buildBottomNavigation(AsyncValue state, bool isDark) => Container(
    padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.white, border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)))),
    child: Row(children: [
      if (_currentStep > 0) Expanded(child: TextButton(onPressed: () { setState(() { _currentStep--; _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutExpo); }); }, child: Text("ATRÁS", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        onPressed: state.isLoading ? null : _handleNext,
        child: Text(_currentStep == 2 ? "FINALIZAR" : "SIGUIENTE", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      )),
    ]),
  );

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutExpo);
    } else { _finalSubmit(); }
  }

  void _showSimpleOptions(String title, List<String> options, Function(String) onSelect, bool isDark) {
    showModalBottomSheet(context: context, backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => Container(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A))), const SizedBox(height: 12), ...options.map((opt) => ListTile(title: Center(child: Text(opt, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600))), onTap: () { onSelect(opt); Navigator.pop(ctx); })).toList()])));
  }

  void _showMultiSelectPathologies(bool isDark) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: Text("Diagnósticos", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w900)), content: StatefulBuilder(builder: (ctx, setModalState) => SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: _pathologyOptions.map((p) => CheckboxListTile(title: Text(p, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))), value: _pathologies.contains(p), activeColor: const Color(0xFF10B981), onChanged: (val) { setModalState(() { if (p == "Ninguna") { _pathologies = ["Ninguna"]; } else { _pathologies.remove("Ninguna"); val! ? _pathologies.add(p) : _pathologies.remove(p); if (_pathologies.isEmpty) _pathologies = ["Ninguna"]; } }); setState(() {}); })).toList()))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))))]));
  }

  Widget _header(String title, String sub, bool isDark) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: -1)), Text(sub, style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)), const SizedBox(height: 24)]);
  Widget _sectionTitle(String title, bool isDark) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 1.5)));
}