import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/blueprint_grid.dart';
import '../../../core/widgets/elena_header.dart';
import '../../profile/application/user_controller.dart';

import '../application/elena_today_provider.dart';
import '../domain/metabolic_status_evaluator.dart';
import '../domain/metabolic_phase.dart';
import 'widgets/metabolic_pentagon_grid.dart';

class TodayDashboardScreen extends ConsumerWidget {
  const TodayDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elenaTodayProvider);
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    final evaluator = MetabolicStatusEvaluator(state.score.score);
    
    // Identificamos si estamos ante una alerta crítica del motor de decisiones
    final bool isCritical = state.suggestion.contains("CRÍTICA") || state.sleepScore < 40;
    final bool isRepairMode = state.phase == MetabolicPhase.digestiveLock;
    
    // Colorimetría Dinámica según Estado
    final Color mainColor = isCritical 
        ? Colors.redAccent 
        : (isRepairMode ? Colors.indigoAccent : evaluator.color);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlueprintGrid(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                if (user != null) ElenaHeader(title: 'TELEMETRÍA', user: user),
                
                const SizedBox(height: 20),

                // Indicador de Fase o Protocolo
                if (isRepairMode && !isCritical) 
                  const _SleepProtocolCard()
                else if (isCritical)
                  _StatusIndicator(label: "ALERTA DE SISTEMA", color: Colors.redAccent)
                else 
                  _StatusIndicator(label: state.statusLabel, color: mainColor),

                const SizedBox(height: 12),
                
                // Elena Insight con Estética de Autoridad
                _SuggestionCard(
                  text: state.suggestion,
                  isCritical: isCritical,
                  accentColor: mainColor,
                ),

                const SizedBox(height: 10),

                // Contenedor del Pentágono
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: mainColor.withOpacity(0.08)),
                    ),
                    child: const Center(
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: MetabolicPentagonGrid(),
                      ),
                    ),
                  ),
                ),

                // Feedback de hambre (Sarcopenia/Nutrición)
                if (!isRepairMode && state.nutritionScore < 40 && state.fastingScore < 50) 
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: _HungerPanicCard(),
                  ),
                  
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- COMPONENTES DE UI ---

class _StatusIndicator extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusIndicator({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(), 
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10, 
          color: color, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.1
        )
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String text;
  final bool isCritical;
  final Color accentColor;
  
  const _SuggestionCard({
    required this.text, 
    required this.isCritical,
    required this.accentColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.withOpacity(0.08) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? Colors.redAccent.withOpacity(0.3) : accentColor.withOpacity(0.1)
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCritical) 
            const Padding(
              padding: EdgeInsets.only(right: 12, top: 2),
              child: Icon(Icons.emergency_share_outlined, color: Colors.redAccent, size: 20),
            ),
          Expanded(
            child: Text(
              text, 
              style: GoogleFonts.publicSans(
                color: isCritical ? Colors.redAccent[100] : Colors.white, 
                fontSize: 14, 
                height: 1.5,
                fontWeight: isCritical ? FontWeight.w600 : FontWeight.normal,
              )
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepProtocolCard extends StatelessWidget {
  const _SleepProtocolCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.nightlight_round, color: Colors.indigoAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "SUEÑO PROFUNDO · PROTOCOLO DE REPARACIÓN CELULAR ACTIVO",
              style: GoogleFonts.robotoMono(
                color: Colors.indigoAccent, 
                fontWeight: FontWeight.bold, 
                fontSize: 11, 
                height: 1.3
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HungerPanicCard extends StatelessWidget {
  const _HungerPanicCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 20),
          SizedBox(width: 12),
          Text(
            "ALERTA DE HAMBRE: CATABOLISMO DETECTADO", 
            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 11)
          ),
        ],
      ),
    );
  }
}