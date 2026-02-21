import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../profile/data/user_repository.dart';
import '../../application/metabolic_checkin_provider.dart';

class MetabolicCheckinWidget extends ConsumerStatefulWidget {
  const MetabolicCheckinWidget({super.key});

  @override
  ConsumerState<MetabolicCheckinWidget> createState() => _MetabolicCheckinWidgetState();
}

class _MetabolicCheckinWidgetState extends ConsumerState<MetabolicCheckinWidget> {
  double _sleepHours = 7.0;
  int _sorenessLevel = 2; // 1=Fresh, 5=Severe
  double _energyLevel = 7.0; // 1-10

  @override
  Widget build(BuildContext context) {
    // Hide if already checked in
    final checkinState = ref.watch(metabolicCheckinProvider).asData?.value;
    if (checkinState != null) return const SizedBox.shrink();
    
    // Get User Name
    final userAsync = ref.watch(currentUserProvider);
    // Safe access to user name
    final userName = userAsync.asData?.value?.name ?? "Atleta";

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "¡Hola $userName! ¿Cómo te sientes hoy?",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sleep
            Text("¿Qué tal dormiste anoche? (${_sleepHours.toStringAsFixed(1)}h aprox.)", style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
            Slider(
              value: _sleepHours,
              min: 3,
              max: 12,
              divisions: 18,
              label: "${_sleepHours}h",
              onChanged: (v) => setState(() => _sleepHours = v),
              activeColor: Colors.blueAccent,
            ),

            // Soreness
            Text("¿Sientes tus músculos cansados o adoloridos? (1=No, 5=Mucho)", style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
            Slider(
              value: _sorenessLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: "$_sorenessLevel",
              onChanged: (v) => setState(() => _sorenessLevel = v.toInt()),
              activeColor: Colors.redAccent,
            ),
            
            // Energy
             Text("¿Qué tantas ganas tienes de comerte el mundo hoy? (1-10)", style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
             Slider(
              value: _energyLevel,
              min: 1,
              max: 10,
              divisions: 9,
              label: "${_energyLevel.toInt()}",
              onChanged: (v) => setState(() => _energyLevel = v),
              activeColor: Colors.amber,
            ),

            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {
                // Submit logic
                ref.read(metabolicCheckinProvider.notifier).submitCheckin(
                  sleepHours: _sleepHours,
                  sorenessLevel: _sorenessLevel,
                  nutritionStatus: 'fed', 
                  energyLevel: _energyLevel,
                );
                
                // Motivational Insight Logic moved to Persistent Banner in DailyWorkoutView
                // No Snackbar needed as per "Elimina el mensaje temporal" request.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("¡Estoy listo, preparemos mi plan!", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
