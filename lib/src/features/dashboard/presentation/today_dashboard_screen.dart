import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/blueprint_grid.dart';
import '../../../core/widgets/elena_header.dart';
import '../../profile/application/user_controller.dart';

import '../application/elena_today_provider.dart';
import '../domain/metabolic_status_evaluator.dart';
import '../domain/metabolic_phase.dart';
import '../data/metabolic_history_repository.dart';
import 'widgets/metabolic_pentagon_grid.dart';

class TodayDashboardScreen extends ConsumerWidget {
  const TodayDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elenaTodayProvider);
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    final evaluator = MetabolicStatusEvaluator(state.score.score);
    final bool isRepairMode = state.phase == MetabolicPhase.digestiveLock;
    final Color phaseColor = isRepairMode ? Colors.indigoAccent : evaluator.color;

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

                if (isRepairMode) 
                  const _SleepProtocolCard()
                else 
                  _StatusIndicator(label: state.statusLabel, color: phaseColor),

                const SizedBox(height: 12),
                
                _SuggestionCard(
                  text: state.suggestion,
                  borderColor: isRepairMode ? Colors.indigoAccent.withOpacity(0.5) : null,
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    decoration: BoxDecoration(
                      color: isRepairMode ? Colors.indigo.withOpacity(0.05) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isRepairMode ? Colors.indigoAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
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

                if (!isRepairMode && state.nutritionScore < 40 && state.fastingScore < 50) 
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _HungerPanicCard(ref: ref),
                  ),

                // BOTÓN DE DEBUG: INYECCIÓN DE DATOS
                Center(
                  child: TextButton.icon(
                    onPressed: () => _injectMockData(ref),
                    icon: const Icon(Icons.bug_report_outlined, size: 14, color: Colors.white10),
                    label: const Text(
                      "INYECTAR TELEMETRÍA 7D",
                      style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                  
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Función de Inyección Técnica
  Future<void> _injectMockData(WidgetRef ref) async {
    final user = ref.read(currentUserStreamProvider).valueOrNull;

    if (user != null) {
      final now = DateTime.now();
      final mockScores = [85.0, 72.0, 90.0, 45.0, 38.0, 60.0, 32.0];
      
      for (int i = 0; i < mockScores.length; i++) {
        final date = now.subtract(Duration(days: (mockScores.length - 1) - i));
        final dateId = date.toIso8601String().split('T')[0];
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('metabolic_history')
            .doc(dateId)
            .set({
          'score': mockScores[i],
          'day': _getWeekdayInitial(date.weekday),
          'timestamp': Timestamp.fromDate(date),
        });
      }
      debugPrint("Ecosistema: Telemetría inyectada correctamente.");
    }
  }

  String _getWeekdayInitial(int day) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[day - 1];
  }
}

// --- Componentes de UI ---

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
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, letterSpacing: 1.1)
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String text;
  final Color? borderColor;
  const _SuggestionCard({required this.text, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.nightlight_round, color: Colors.indigoAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "SUEÑO PROFUNDO · PROTOCOLO DE REPARACIÓN CELULAR ACTIVO",
              style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _HungerPanicCard extends StatelessWidget {
  final WidgetRef ref;
  const _HungerPanicCard({required this.ref});
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
          Icon(Icons.warning_amber, color: Colors.orangeAccent),
          SizedBox(width: 12),
          Text("ALERTA DE HAMBRE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}