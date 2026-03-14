import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../dashboard/presentation/widgets/fasting_card.dart';
import '../../progress/presentation/widgets/fasting_chart_card.dart';
import '../../imx/presentation/widgets/imx_telemetry_board.dart';

class FastingScreen extends ConsumerWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Text(
          'GESTIÓN DE AYUNO',
          style: GoogleFonts.firaCode(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Timer Card (Full Widget)
            FastingCard(),
            
            const SizedBox(height: 20),
            
            // 2. Statistics Card
            const FastingChartCard(),
            
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }
}
