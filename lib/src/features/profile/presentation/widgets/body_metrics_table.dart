import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/user_repository.dart';

class BodyMetricsTable extends ConsumerWidget {
  final UserModel user;
  const BodyMetricsTable({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyLogsAsync = ref.watch(bodyLogsStreamProvider(user.uid));

    return bodyLogsAsync.when(
      data: (logs) {
        final currentData = logs.isNotEmpty ? logs[0] : _getInitialData(user);
        final previousData = logs.length > 1 ? logs[1] : null;

        // Construir filas solo con zonas que tengan datos
        final rows = <_BiometryRow>[];
        _maybeAdd(
          rows,
          'CINTURA',
          currentData['cintura'],
          previousData?['cintura'],
        );
        _maybeAdd(
          rows,
          'CADERA',
          currentData['cadera'],
          previousData?['cadera'],
        );
        _maybeAdd(
          rows,
          'CUELLO',
          currentData['cuello'],
          previousData?['cuello'],
        );
        _maybeAdd(
          rows,
          'BRAZO (D)',
          currentData['brazo'],
          previousData?['brazo'],
        );
        _maybeAdd(rows, 'MUSLO', currentData['muslo'], previousData?['muslo']);

        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título ──────────────────────────────────────
              Text(
                'BIOMETRÍA',
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // ── Leyenda ──────────────────────────────────────
              Row(
                children: [
                  _legendItem(Icons.south, AppTheme.primary, 'MEJORA'),
                  const SizedBox(width: 12),
                  _legendItem(
                    Icons.north,
                    const Color(0xFFFF4444),
                    'RETROCESO',
                  ),
                  const SizedBox(width: 12),
                  _legendItem(Icons.horizontal_rule, Colors.white38, 'ESTABLE'),
                ],
              ),
              const SizedBox(height: 16),

              // ── Cabecera tabla ──────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'ZONA',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'MEDIDA',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        'TREND',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.robotoMono(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filas de datos ──────────────────────────────
              ...rows.map(_buildDataRow),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, st) => Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error cargando biometría: $e',
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Map<String, dynamic> _getInitialData(UserModel user) {
    return {
      'cuello': user.neckCircumferenceCm,
      'cintura': user.waistCircumferenceCm,
      'cadera': user.hipCircumferenceCm,
      'brazo': null,
      'muslo': null,
    };
  }

  void _maybeAdd(
    List<_BiometryRow> rows,
    String label,
    dynamic current,
    dynamic previous,
  ) {
    final double? cVal = (current as num?)?.toDouble();
    if (cVal == null || cVal == 0.0) return; // Solo mostrar si hay dato real
    final double? pVal = (previous as num?)?.toDouble();
    rows.add(_BiometryRow(label: label, current: cVal, previous: pVal));
  }

  Widget _buildDataRow(_BiometryRow row) {
    final trend = _calculateTrend(row.label, row.previous, row.current);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: GoogleFonts.robotoMono(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${row.current.toStringAsFixed(1)} CM',
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 50, child: Center(child: trend)),
        ],
      ),
    );
  }

  Widget _calculateTrend(String label, double? prev, double current) {
    if (prev == null || prev == 0.0 || prev == current) {
      return Icon(Icons.horizontal_rule, color: Colors.white38, size: 16);
    }

    // Para cintura/cadera/cuello: bajar es mejora
    // Para brazo/muslo: subir es mejora (hipertrofia)
    final bool isLimbZone = label.contains('BRAZO') || label.contains('MUSLO');
    final bool isImprovement = isLimbZone ? current > prev : current < prev;

    if (isImprovement) {
      return Icon(Icons.south, color: AppTheme.primary, size: 16);
    } else {
      return Icon(Icons.north, color: const Color(0xFFFF4444), size: 16);
    }
  }

  Widget _legendItem(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.robotoMono(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// Modelo interno para filas
class _BiometryRow {
  final String label;
  final double current;
  final double? previous;
  const _BiometryRow({
    required this.label,
    required this.current,
    this.previous,
  });
}

final bodyLogsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
      return ref.watch(userRepositoryProvider).bodyLogsStream(uid);
    });
