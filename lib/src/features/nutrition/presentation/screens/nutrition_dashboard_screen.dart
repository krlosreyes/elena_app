import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/nutrition_service.dart';
import '../widgets/macro_metrics_card.dart';
import '../widgets/visual_plate_widget.dart';
import '../widgets/science_disclaimer_widget.dart';

// Temporary until authentication provider is properly exposed or passed
// In a real scenario, we get this from AuthRepository or UserProvider
const String _tempUserName = "David"; 

class NutritionDashboardScreen extends ConsumerWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionPlanAsync = ref.watch(nutritionPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Nutrición",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: nutritionPlanAsync.when(
        data: (plan) {
          if (plan == null) {
            return _buildEmptyState(ref);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Hola $_tempUserName,",
                   style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandDark,
                  ),
                ),
                Text(
                  "Este es tu plan metabólico de precisión.",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Visual Plate
                Center(
                  child: SizedBox(
                    width: 280,
                    child: VisualPlateWidget(plate: plan.visualPlate),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Legend
                const _PlateLegend(),
                
                const SizedBox(height: 32),
                
                // Macros
                MacroMetricsCard(
                  macros: plan.macroTargets,
                  baseMetrics: plan.baseMetrics,
                ),
                
                const SizedBox(height: 24),
                
                // Disclaimer
                const ScienceDisclaimerWidget(),
                
                 const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              Text("Error cargando plan: $err"),
              TextButton(
                onPressed: () => ref.invalidate(nutritionPlanProvider),
                child: const Text("Reintentar"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No tienes un plan activo",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Configura tus datos para generar uno.",
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Trigger calculation - usually this would open a form
              // For now, we simulation generation with static data for prompt purposes if needed,
              // or just show this state.
              ref.read(nutritionServiceProvider.notifier).generateAndSavePlan(
                weightKg: 80, // Default/Mock for now
                bodyFatPercentage: 20,
                activityLevel: 'moderate',
                gender: 'male',
                goal: 'maintain',
              );
            },
            child: const Text("Generar Plan Demo"),
          ),
        ],
      ),
    );
  }
}

class _PlateLegend extends StatelessWidget {
  const _PlateLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem(color: const Color(0xFF81C784), label: "Vegetales (50%)"),
        _LegendItem(color: const Color(0xFFE57373), label: "Proteína (25%)"),
        _LegendItem(color: const Color(0xFFFFD54F), label: "Carbos (25%)"),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
