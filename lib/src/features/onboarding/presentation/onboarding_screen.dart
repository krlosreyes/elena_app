import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/services/size_mapper_service.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _waistController = TextEditingController();
  final _neckController = TextEditingController();

  // Hardware Base - Valores iniciales coherentes
  int _age = 40;
  double _weight = 80.0;
  double _height = 175.0;
  String _gender = 'M';

  // Tallas
  int _pantSize = 32;
  String _shirtSize = "M";
  bool _isEstimated = true;

  @override
  void initState() {
    super.initState();
    _recalibrate(initial: true);
  }

  void _recalibrate({bool initial = false}) {
    final data = SizeMapperService.inferCrossed(
      pantSize: _pantSize, 
      shirtSize: _shirtSize, 
      gender: _gender
    );
    setState(() {
      _waistController.text = data["waist"]!.toStringAsFixed(1);
      _neckController.text = data["neck"]!.toStringAsFixed(1);
      if (!initial) _isEstimated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                
                _sectionTitle("1. HARDWARE BASE"),
                _buildHorizontalSelector(
                  label: "Edad", 
                  value: "$_age años", 
                  onTap: () => _showPicker(
                    CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(initialItem: _age - 18),
                      onSelectedItemChanged: (v) => setState(() => _age = v + 18),
                      children: List.generate(82, (i) => Center(child: Text("${i + 18}"))),
                    ),
                  ),
                ),
                _buildHorizontalSelector(
                  label: "Estatura", 
                  value: "${_height.round()} cm", 
                  onTap: () => _showPicker(
                    CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(initialItem: _height.round() - 140),
                      onSelectedItemChanged: (v) => setState(() => _height = (v + 140).toDouble()),
                      children: List.generate(80, (i) => Center(child: Text("${i + 140}"))),
                    ),
                  ),
                ),
                _buildHorizontalSelector(
                  label: "Peso actual", 
                  value: "${_weight.round()} kg", 
                  onTap: () => _showPicker(
                    CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(initialItem: _weight.round() - 40),
                      onSelectedItemChanged: (v) => setState(() => _weight = (v + 40).toDouble()),
                      children: List.generate(160, (i) => Center(child: Text("${i + 40}"))),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                _sectionTitle("2. TALLAS USA (INFERENCIA)"),
                _buildSizeSelectors(),

                const SizedBox(height: 32),
                _sectionTitle("3. BIOMETRÍA PROYECTADA"),
                _buildInferredField("Cintura (S1)", _waistController),
                _buildInferredField("Cuello (S3)", _neckController),

                const SizedBox(height: 48),
                _buildSubmitButton(state),
              ],
            ),
            if (state.isLoading) 
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("ELENA", style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, color: Color(0xFF475569), fontSize: 12)),
      const Text("Calibración Biométrica", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      const Text("Configuración del hardware biológico inicial.", style: TextStyle(color: Colors.blueGrey)),
    ],
  );

  Widget _buildHorizontalSelector({required String label, required String value, required VoidCallback onTap}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    ),
  );

  Widget _buildSizeSelectors() => Row(
    children: [
      Expanded(
        child: _buildHorizontalSelector(
          label: "Camisa", 
          value: _shirtSize, 
          onTap: () => _showPicker(
            CupertinoPicker(
              itemExtent: 40,
              onSelectedItemChanged: (v) { setState(() => _shirtSize = ["S", "M", "L", "XL"][v]); _recalibrate(); },
              children: const [Center(child: Text("S")), Center(child: Text("M")), Center(child: Text("L")), Center(child: Text("XL"))],
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildHorizontalSelector(
          label: "Pantalón", 
          value: "$_pantSize", 
          onTap: () => _showPicker(
            CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(initialItem: (_pantSize - 28) ~/ 2),
              onSelectedItemChanged: (v) { setState(() => _pantSize = 28 + (v * 2)); _recalibrate(); },
              children: List.generate(12, (i) => Center(child: Text("${28 + (i * 2)}"))),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildInferredField(String label, TextEditingController controller) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        Text("${controller.text} cm", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ],
    ),
  );

  void _showPicker(Widget picker) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 50, 
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Seleccionar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Listo", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(child: picker),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AsyncValue state) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0F172A),
      minimumSize: const Size(double.infinity, 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    onPressed: state.isLoading ? null : _submit,
    child: const Text("INICIAR METAMORFOSIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
  );

  void _submit() {
    final user = UserModel(
      age: _age,
      gender: _gender,
      weight: _weight,
      height: _height,
      pantSize: _pantSize,
      shirtSize: _shirtSize,
      profile: CircadianProfile(
        wakeUpTime: DateTime.now(), 
        sleepTime: DateTime.now(),
        firstMealGoal: DateTime.now(),
        lastMealGoal: DateTime.now(),
      ),
    );
    ref.read(onboardingControllerProvider.notifier).completeOnboarding(user);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
  );
}