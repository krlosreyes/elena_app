import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_controller.dart';

class StepBody extends ConsumerStatefulWidget {
  const StepBody({super.key});

  @override
  ConsumerState<StepBody> createState() => _StepBodyState();
}

class _StepBodyState extends ConsumerState<StepBody> {
  bool _isMetric = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Medidas Corporales',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUnitToggle('Kg / Cm', true),
              const SizedBox(width: 8),
              _buildUnitToggle('Lbs / In', false),
            ],
          ),
          const SizedBox(height: 32),
          _buildPremiumSlider(
            context: context,
            icon: Icons.height,
            title: 'Altura',
            metricValue: user.heightCm,
            metricMin: 100,
            metricMax: 220,
            divisions: 120,
            metricUnit: 'cm',
            onMetricChanged: (val) {
              ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(heightCm: val));
            },
            fractionDigits: 0,
          ),
          const SizedBox(height: 16),
          _buildPremiumSlider(
            context: context,
            icon: Icons.monitor_weight,
            title: 'Peso Actual',
            metricValue: user.currentWeightKg,
            metricMin: 30,
            metricMax: 150,
            divisions: 240,
            metricUnit: 'kg',
            isWeight: true,
            onMetricChanged: (val) {
              ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(currentWeightKg: val));
            },
          ),
          const SizedBox(height: 16),
          _buildPremiumSlider(
            context: context,
            icon: Icons.straighten,
            title: 'Circunferencia de Cintura',
            metricValue: user.waistCircumferenceCm,
            metricMin: 50,
            metricMax: 150,
            divisions: 200,
            metricUnit: 'cm',
            onMetricChanged: (val) {
              ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(waistCircumferenceCm: val));
            },
          ),
          const SizedBox(height: 16),
          _buildPremiumSlider(
            context: context,
            icon: Icons.accessibility_new,
            title: 'Circunferencia de Cadera',
            metricValue: user.hipCircumferenceCm ?? 90.0,
            metricMin: 60,
            metricMax: 160,
            divisions: 200,
            metricUnit: 'cm',
            onMetricChanged: (val) {
              ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(hipCircumferenceCm: val));
            },
          ),
          const SizedBox(height: 16),
          _buildPremiumSlider(
            context: context,
            icon: Icons.face,
            title: 'Circunferencia de Cuello',
            metricValue: user.neckCircumferenceCm,
            metricMin: 25,
            metricMax: 60,
            divisions: 140,
            metricUnit: 'cm',
            onMetricChanged: (val) {
              ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(neckCircumferenceCm: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(String label, bool metricMode) {
    final isSelected = _isMetric == metricMode;
    return InkWell(
      onTap: () => setState(() => _isMetric = metricMode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009688) : Colors.transparent,
          border: Border.all(color: const Color(0xFF009688)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF009688),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSlider({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double metricValue,
    required double metricMin,
    required double metricMax,
    required int divisions,
    required String metricUnit,
    required Function(double) onMetricChanged,
    int fractionDigits = 1,
    bool isWeight = false,
  }) {
    final double conversionFactor = isWeight ? 2.20462 : 0.393701;
    final String displayUnit = _isMetric ? metricUnit : (isWeight ? 'lbs' : 'in');
    
    final double displayMin = _isMetric ? metricMin : metricMin * conversionFactor;
    final double displayMax = _isMetric ? metricMax : metricMax * conversionFactor;
    double displayValue = _isMetric ? metricValue : metricValue * conversionFactor;
    displayValue = displayValue.clamp(displayMin, displayMax);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF009688).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF009688), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                '${displayValue.toStringAsFixed(fractionDigits)} $displayUnit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF009688),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF009688),
              inactiveTrackColor: Colors.grey[800],
              thumbColor: const Color(0xFF009688),
              overlayColor: const Color(0xFF009688).withOpacity(0.2),
              trackHeight: 6.0,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: displayValue,
              min: displayMin,
              max: displayMax,
              divisions: divisions,
              label: displayValue.toStringAsFixed(fractionDigits),
              onChanged: (val) {
                 final newMetricValue = _isMetric ? val : val / conversionFactor;
                 onMetricChanged(newMetricValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}
