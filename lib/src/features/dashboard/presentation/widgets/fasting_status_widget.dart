import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../fasting/application/fasting_controller.dart';
import '../../../authentication/data/auth_repository.dart';

class FastingStatusWidget extends ConsumerWidget {
  const FastingStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingStateAsync = ref.watch(fastingControllerProvider);
    final fastingData = fastingStateAsync.valueOrNull;

    if (fastingData == null) return const SizedBox.shrink();

    final bool isFasting = fastingData.currentPhase == phaseFasting;
    final Color statusColor =
        isFasting ? const Color(0xFF00FF90) : const Color(0xFFFFE600);

    final startTime =
        isFasting ? fastingData.startTime : fastingData.feedingStartTime;
    final endTime = startTime?.add(
      Duration(
          hours: isFasting
              ? fastingData.plannedHours
              : (24 - fastingData.plannedHours)),
    );

    String formatTime(DateTime? dt) {
      if (dt == null) return "--:--";
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fila 1 (Estado)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPress: () async {
                final uid = ref.read(authRepositoryProvider).currentUser?.uid;
                if (uid == null) return;
                final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
                final snapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('daily_logs')
                    .where('date', isEqualTo: todayId)
                    .get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('daily_logs')
                    .doc(todayId)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PROTOCOL E-01: SYSTEM RESET SUCCESSFUL'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(
                isFasting ? "ESTÁS AYUNANDO" : "VENTANA ABIERTA",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Fila 2 (Tiempos)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "INICIO: ",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white.withAlpha(180),
              ),
            ),
            Text(
              formatTime(startTime),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 32),
            Text(
              "FIN: ",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white.withAlpha(180),
              ),
            ),
            Text(
              formatTime(endTime),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
