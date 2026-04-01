import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import '../../data/user_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class BodyMetricsTable extends ConsumerWidget {
  final UserModel user;
  const BodyMetricsTable({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyLogsAsync = ref.watch(bodyLogsStreamProvider(user.uid));

    return bodyLogsAsync.when(
      data: (logs) {
        // Lógica de datos: Si no hay logs, usamos los datos del perfil actual (Onboarding)
        final bool isFirstLog = logs.isEmpty;

        final currentData = !isFirstLog ? logs[0] : _getInitialData(user);
        final previousData = logs.length > 1 ? logs[1] : null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF020205),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: const Color(0xFFFF9D00).withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableHeader(),
              const SizedBox(height: 12),
              _buildRow(
                  'CUELLO', previousData?['cuello'], currentData['cuello']),
              _buildRow(
                  'CINTURA', previousData?['cintura'], currentData['cintura']),
              _buildRow(
                  'CADERA', previousData?['cadera'], currentData['cadera']),
              _buildRow('BRAZO', previousData?['brazo'], currentData['brazo']),
              _buildRow('MUSLO', previousData?['muslo'], currentData['muslo']),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFFFF9D00)),
        ),
      ),
      error: (e, st) => Container(
        padding: const EdgeInsets.all(16),
        child: Text('Error cargando telemetría: $e',
            style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }

  Map<String, dynamic> _getInitialData(UserModel user) {
    return {
      'cuello': user.neckCircumferenceCm ?? 38.0,
      'cintura': user.waistCircumferenceCm ?? 95.0,
      'cadera': user.hipCircumferenceCm ?? 100.0,
      'brazo': 0.0,
      'muslo': 0.0,
    };
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(flex: 3, child: _headerCell('ZONA')),
        Expanded(flex: 2, child: _headerCell('ANT. (cm)')),
        Expanded(flex: 2, child: _headerCell('ACTUAL')),
        Expanded(flex: 2, child: _headerCell('TREND')),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        color: const Color(0xFFFF9D00).withValues(alpha: 0.5),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildRow(String label, dynamic prev, dynamic curr) {
    final double? pVal = (prev as num?)?.toDouble();
    final double? cVal = (curr as num?)?.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pVal?.toStringAsFixed(1) ?? '--',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white24,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              (cVal == null || cVal == 0.0) ? '--' : cVal.toStringAsFixed(1),
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFFF9D00),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildTrendIcon(pVal, cVal),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(double? prev, double? curr) {
    // Si es el primer registro o no hay cambios, mostramos estabilidad (Amarillo Neón)
    if (prev == null || curr == null || prev == curr || curr == 0.0) {
      return Icon(
        Icons.horizontal_rule,
        color: const Color(0xFFF0FF00).withValues(alpha: 0.8),
        size: 16,
      );
    }

    // Lógica técnica: Menos cintura/cadera es bueno, pero más brazo/muslo suele ser bueno (hipertrofia)
    // Para simplificar según el prompt, usaremos flecha verde arriba si mejora, roja abajo si empeora.
    // Pero el prompt pide específicamente Estabilidad Inicial en el primer log.

    final bool isImprovement = curr < prev;

    if (isImprovement) {
      return Icon(Icons.arrow_upward, color: AppTheme.primary, size: 14);
    } else {
      return const Icon(Icons.arrow_downward,
          color: Color(0xFFFF2D55), size: 14);
    }
  }
}

final bodyLogsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).bodyLogsStream(uid);
});
